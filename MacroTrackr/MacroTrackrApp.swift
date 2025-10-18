import SwiftUI
import Combine
import Supabase
import Kingfisher
import AuthenticationServices
import PhotosUI
import UserNotifications
import UIKit
import AVFoundation
import Vision
import WidgetKit

// Full MacroTrackr app with Supabase and Kingfisher
@main
struct MacroTrackrApp: SwiftUI.App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var dataManager = DataManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
                    .environmentObject(notificationManager)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                    .onAppear {
                        authManager.checkAuthStatus()
                    }
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(notificationManager)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                    .onAppear {
                        authManager.checkAuthStatus()
                    }
            }
        }
    }
    
    init() {
        // Check authentication status when app launches
        // This will be handled when the view appears
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User?
    @Published var isLoading = false
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String)!,
        supabaseKey: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
    )
    
    private var appleSignInDelegate: AppleSignInDelegate?
    private var presentationContextProvider: AppleSignInPresentationContextProvider?
    
    func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    self.isAuthenticated = true
                    self.currentUser = session.user
                }
                // Try to create profile if it doesn't exist
                try await createUserProfileIfNeeded()
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signUp(email: email, password: password)
        
        // Create user profile - this will be handled by the database trigger or we'll create it after sign in
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = response.user
        }
        
        // Store display name for later profile creation
        UserDefaults.standard.set(displayName, forKey: "pendingDisplayName")
    }
    
    private func createUserProfileIfNeeded() async throws {
        guard let user = currentUser else { return }
        
        // Check if profile already exists
        let existingProfiles: [UserProfile] = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: user.id.uuidString)
            .execute()
            .value
        
        if existingProfiles.isEmpty {
            // Create profile if it doesn't exist
            let displayName = UserDefaults.standard.string(forKey: "pendingDisplayName") ?? "User"
            UserDefaults.standard.removeObject(forKey: "pendingDisplayName")
            
            let profile = UserProfile(
                id: user.id.uuidString,
                displayName: displayName,
                email: user.email ?? "",
                dailyGoals: MacroGoals(),
                isPrivate: false,
                createdAt: Date()
            )
            
            try await supabase
                .from("profiles")
                .insert(profile)
                .execute()
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signIn(email: email, password: password)
        
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = response.user
        }
        
        // Try to create profile if it doesn't exist
        try await createUserProfileIfNeeded()
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            appleSignInDelegate = AppleSignInDelegate(continuation: continuation)
            presentationContextProvider = AppleSignInPresentationContextProvider()
            controller.delegate = appleSignInDelegate
            controller.presentationContextProvider = presentationContextProvider
            controller.performRequests()
        }
        
        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthenticationError.appleSignInFailed
        }
        
        do {
            let authResponse = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityTokenString,
                    nonce: nil
                )
            )
            
            // Create or update user profile
            let user = authResponse.user
            
            let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let profile = UserProfile(
                id: user.id.uuidString,
                displayName: displayName.isEmpty ? "Apple User" : displayName,
                email: user.email ?? "",
                dailyGoals: MacroGoals(),
                isPrivate: false,
                createdAt: Date()
            )
            
            try await supabase
                .from("profiles")
                .upsert(profile)
                .execute()
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = authResponse.user
            }
        } catch {
            // Handle the specific error about provider not being enabled
            let errorDescription = error.localizedDescription
            if errorDescription.contains("Provider (issuer") || errorDescription.contains("appleid.apple.com") {
                throw AuthenticationError.appleProviderNotEnabled
            }
            
            // Re-throw the original error if it's not the specific provider error
            throw error
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true // Default to dark mode
    
    private let userDefaults = UserDefaults.standard
    private let darkModeKey = "isDarkModeEnabled"
    
    init() {
        // Load saved preference, default to dark mode if not set
        self.isDarkMode = userDefaults.object(forKey: darkModeKey) as? Bool ?? true
        
        // Apply the theme after a small delay to ensure the UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.applyTheme()
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        savePreference()
        applyTheme()
    }
    
    func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        savePreference()
        applyTheme()
    }
    
    private func savePreference() {
        userDefaults.set(isDarkMode, forKey: darkModeKey)
    }
    
    func applyTheme() {
        DispatchQueue.main.async {
            // Update the app's color scheme for all windows
            for windowScene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
                }
            }
        }
    }
}

// MARK: - Apple Sign In Support
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found for Apple Sign In")
        }
        return window
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @Published var isNotificationEnabled = false
    @Published var mealReminderEnabled = true
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
            }
            
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendMealLoggedNotification(mealName: String) {
        guard isNotificationEnabled && mealReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Meal Logged! 🍽️"
        content.body = "Great job logging \(mealName). Keep tracking your nutrition!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "meal-logged-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Send immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    func scheduleMealReminder() {
        guard isNotificationEnabled && mealReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Don't Forget to Log! 📱"
        content.body = "Remember to log your meals to stay on track with your nutrition goals."
        content.sound = .default
        
        // Schedule for 2 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 14
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "meal-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule meal reminder: \(error)")
            }
        }
    }
}

// MARK: - Data Manager
class DataManager: ObservableObject {
    @Published var todayMeals: [Meal] = []
    @Published var savedMeals: [Meal] = []
    @Published var friends: [UserProfile] = []
    @Published var allUsers: [UserWithFriendshipInfo] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var pendingFriendRequests: [FriendRequest] = []
    @Published var ingredients: [Ingredient] = []
    @Published var userIngredientPresets: [UserIngredientPreset] = []
    @Published var publicRecipes: [RecipeCollection] = []
    @Published var userRecipes: [RecipeCollection] = []
    @Published var isLoading = false
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String)!,
        supabaseKey: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
    )
    
    // Realtime subscriptions
    private var friendRequestsSubscription: Task<Void, Never>?
    private var mealsSubscription: Task<Void, Never>?
    
    deinit {
        friendRequestsSubscription?.cancel()
        mealsSubscription?.cancel()
    }
    
    func loadTodayMeals(for userId: String) async {
        await loadMealsForDate(userId: userId, date: Date())
    }
    
    func loadMealsForDate(userId: String, date: Date) async {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let meals: [Meal] = try await supabase
                .from("meals")
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: startOfDay)
                .lt("created_at", value: endOfDay)
                .execute()
                .value
            
            await MainActor.run {
                self.todayMeals = meals
            }
        } catch {
            print("Error loading meals for date: \(error)")
        }
    }
    
    func loadSavedMeals(for userId: String) async {
        do {
            let meals: [Meal] = try await supabase
                .from("saved_meals")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            await MainActor.run {
                self.savedMeals = meals
            }
        } catch {
            print("Error loading saved meals: \(error)")
        }
    }
    
    func loadUserMeals(for userId: String, limit: Int = 50) async -> [Meal] {
        do {
            let meals: [Meal] = try await supabase
                .from("meals")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return meals
        } catch {
            print("Error loading user meals: \(error)")
            return []
        }
    }
    
    func loadUserMealsForDate(for userId: String, date: Date) async -> [Meal] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let meals: [Meal] = try await supabase
                .from("meals")
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: startOfDay)
                .lt("created_at", value: endOfDay)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return meals
        } catch {
            print("Error loading user meals for date: \(error)")
            return []
        }
    }
    
    func addMeal(_ meal: Meal) async throws {
        do {
            // Ensure we have a valid user ID for the insert
            var mealToInsert = meal
            guard !mealToInsert.userId.isEmpty else {
                throw NSError(domain: "MealError", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: "User ID is required to save meal"
                ])
            }
            
            try await supabase
                .from("meals")
                .insert(mealToInsert)
                .execute()
            
            await loadTodayMeals(for: meal.userId)
            await updateWidgetData(userId: meal.userId) // Update widget when new meal is added
        } catch {
            print("Error adding meal: \(error)")
            // Provide more specific error message for row-level security policy
            if error.localizedDescription.contains("row-level security policy") {
                throw NSError(domain: "MealError", code: 403, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to save meal. Please ensure you are logged in and try again."
                ])
            } else {
                throw error
            }
        }
    }
    
    func updateMeal(_ meal: Meal) async throws {
        try await supabase
            .from("meals")
            .update([
                "name": AnyJSON.string(meal.name),
                "meal_type": AnyJSON.string(meal.mealType.rawValue),
                "macros": AnyJSON.object([
                    "calories": AnyJSON.double(meal.macros.calories),
                    "protein": AnyJSON.double(meal.macros.protein),
                    "carbohydrates": AnyJSON.double(meal.macros.carbohydrates),
                    "fat": AnyJSON.double(meal.macros.fat),
                    "sugar": AnyJSON.double(meal.macros.sugar),
                    "fiber": AnyJSON.double(meal.macros.fiber)
                ]),
                "ingredients": AnyJSON.array(meal.ingredients.map { AnyJSON.string($0) }),
                "cooking_instructions": AnyJSON.string(meal.cookingInstructions ?? ""),
                "image_url": meal.imageURL.map { AnyJSON.string($0) } ?? AnyJSON.null,
                "updated_at": AnyJSON.string(Date().ISO8601Format())
            ])
            .eq("id", value: meal.id)
            .execute()
        
        await loadTodayMeals(for: meal.userId)
        await updateWidgetData(userId: meal.userId)
    }
    
    func deleteMeal(mealId: String, userId: String) async throws {
        try await supabase
            .from("meals")
            .delete()
            .eq("id", value: mealId)
            .execute()
        
        await loadTodayMeals(for: userId)
        await updateWidgetData(userId: userId)
    }
    
    func uploadImage(_ imageData: Data, fileName: String, userId: String) async throws -> String {
        let path = "\(userId)/\(fileName)"
        let uploadResponse = try await supabase.storage
            .from("meal-images")
            .upload(path, data: imageData)
        
        let publicURL = try supabase.storage
            .from("meal-images")
            .getPublicURL(path: uploadResponse.path)
        
        return publicURL.absoluteString
    }
    
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        let fileName = "\(userId)/profile.jpg"
        
        print("Attempting to upload profile image for user: \(userId)")
        
        // First, try to delete existing profile image if it exists
        do {
            try await supabase.storage
                .from("profile-images")
                .remove(paths: [fileName])
            print("Deleted existing profile image")
        } catch {
            print("No existing profile image to delete: \(error)")
        }
        
        do {
            let uploadResponse = try await supabase.storage
                .from("profile-images")
                .upload(fileName, data: imageData, options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                ))
            
            print("Successfully uploaded profile image: \(uploadResponse.path)")
            
            let publicURL = try supabase.storage
                .from("profile-images")
                .getPublicURL(path: uploadResponse.path)
            
            print("Generated public URL: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            print("Upload failed with error: \(error)")
            throw NSError(domain: "UploadError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to upload profile image: \(error.localizedDescription)"
            ])
        }
    }
    
    func saveMeal(_ meal: Meal) async throws {
        let savedMeal = SavedMeal(
            id: UUID().uuidString,
            userId: meal.userId,
            originalMealId: meal.id,
            name: meal.name,
            imageURL: meal.imageURL,
            ingredients: meal.ingredients,
            cookingInstructions: meal.cookingInstructions,
            macros: meal.macros,
            isFavorite: false,
            createdAt: Date()
        )
        
        try await supabase
            .from("saved_meals")
            .insert(savedMeal)
            .execute()
        
        await loadSavedMeals(for: meal.userId)
    }
    
    // MARK: - Friend Request Methods
    
    func sendFriendRequest(fromUserId: String, toDisplayName: String) async throws {
        print("Sending friend request from \(fromUserId) to \(toDisplayName)")
        
        do {
            // First, find the user by display name
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("display_name", value: toDisplayName)
                .execute()
                .value
            
            print("Found \(profiles.count) users with display name: \(toDisplayName)")
            
            guard let targetUser = profiles.first else {
                print("User not found: \(toDisplayName)")
                throw NSError(domain: "FriendRequestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User '\(toDisplayName)' not found"])
            }
            
            // Don't allow sending friend request to self
            if fromUserId == targetUser.id {
                print("Cannot send friend request to self")
                throw NSError(domain: "FriendRequestError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot send friend request to yourself"])
            }
            
            print("Target user found: \(targetUser.id)")
            
            // Check if already friends
            let existingFriendship: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("and(user_id_1.eq.\(fromUserId),user_id_2.eq.\(targetUser.id)),and(user_id_1.eq.\(targetUser.id),user_id_2.eq.\(fromUserId))")
                .execute()
                .value
            
            print("Found \(existingFriendship.count) existing friendships")
            
            if !existingFriendship.isEmpty {
                print("Already friends with this user")
                throw NSError(domain: "FriendRequestError", code: 409, userInfo: [NSLocalizedDescriptionKey: "Already friends with \(toDisplayName)"])
            }
            
            // Check for existing requests
            let existingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .or("and(from_user_id.eq.\(fromUserId),to_user_id.eq.\(targetUser.id)),and(from_user_id.eq.\(targetUser.id),to_user_id.eq.\(fromUserId))")
                .execute()
                .value
            
            // Handle different scenarios
            if let existingRequest = existingRequests.first {
                if existingRequest.fromUserId == fromUserId {
                    // User already sent a request
                    throw NSError(domain: "FriendRequestError", code: 409, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"])
                } else if existingRequest.toUserId == fromUserId {
                    // User received a request from this person - accept it instead
                    try await respondToFriendRequest(requestId: existingRequest.id, status: .accepted, currentUserId: fromUserId)
                    return
                }
            }
            
            // Create new friend request
            let friendRequest = FriendRequest(
                id: UUID().uuidString,
                fromUserId: fromUserId,
                toUserId: targetUser.id,
                status: .pending,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await supabase
                .from("friend_requests")
                .insert(friendRequest)
                .execute()
            
            await loadFriendRequests(for: fromUserId)
        } catch {
            // Handle database constraint violations
            let errorString = "\(error)"
            
            if errorString.contains("23505") || errorString.contains("duplicate key") {
                throw NSError(domain: "FriendRequestError", code: 409, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent to this user"])
            } else if let nsError = error as NSError? {
                throw nsError
            } else {
                throw NSError(domain: "FriendRequestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to send friend request. Please try again."])
            }
        }
    }
    
    func loadFriendRequests(for userId: String) async {
        do {
            // Load outgoing requests
            let outgoingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .eq("from_user_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value
            
            // Load incoming requests
            let incomingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .eq("to_user_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value
            
            await MainActor.run {
                self.friendRequests = outgoingRequests
                self.pendingFriendRequests = incomingRequests
            }
        } catch {
            print("Error loading friend requests: \(error)")
        }
    }
    
    func respondToFriendRequest(requestId: String, status: FriendRequestStatus, currentUserId: String) async throws {
        // Update the friend request status
        try await supabase
            .from("friend_requests")
            .update(["status": status.rawValue, "updated_at": Date().ISO8601Format()])
            .eq("id", value: requestId)
            .execute()
        
        if status == .accepted {
            // Get the friend request details
            let requests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .eq("id", value: requestId)
                .execute()
                .value
            
            guard requests.first != nil else { return }
            
            // Create friendship using the database trigger instead of direct insert
            // The handle_accepted_friend_request trigger will create the friendship
            // This avoids RLS policy issues
            print("Friend request accepted, trigger should create friendship")
        }
        
        // Reload friend requests
        await loadFriendRequests(for: currentUserId)
    }
    
    func loadAllUsers(for currentUserId: String) async {
        do {
            // Load all profiles except current user
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .neq("id", value: currentUserId)
                .execute()
                .value
            
            // Load friendships for current user
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id_1.eq.\(currentUserId),user_id_2.eq.\(currentUserId)")
                .execute()
                .value
            
            // Load friend requests
            let outgoingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .eq("from_user_id", value: currentUserId)
                .eq("status", value: "pending")
                .execute()
                .value
            
            let incomingRequests: [FriendRequest] = try await supabase
                .from("friend_requests")
                .select()
                .eq("to_user_id", value: currentUserId)
                .eq("status", value: "pending")
                .execute()
                .value
            
            // Create UserWithFriendshipInfo objects
            var usersWithInfo: [UserWithFriendshipInfo] = []
            
            for profile in profiles {
                let friendshipStatus: FriendshipStatus
                
                if profile.id == currentUserId {
                    friendshipStatus = .selfUser
                } else if friendships.contains(where: { $0.userId1 == profile.id || $0.userId2 == profile.id }) {
                    friendshipStatus = .friends
                } else if outgoingRequests.contains(where: { $0.toUserId == profile.id }) {
                    friendshipStatus = .pendingOutgoing
                } else if incomingRequests.contains(where: { $0.fromUserId == profile.id }) {
                    friendshipStatus = .pendingIncoming
                } else {
                    friendshipStatus = .notFriends
                }
                
                // Calculate mutual friends
                let mutualFriendsCount = await calculateMutualFriends(currentUserId: currentUserId, otherUserId: profile.id)
                let mutualFriends = await getMutualFriends(currentUserId: currentUserId, otherUserId: profile.id)
                
                let userWithInfo = UserWithFriendshipInfo(
                    user: profile,
                    friendshipStatus: friendshipStatus,
                    mutualFriendsCount: mutualFriendsCount,
                    mutualFriends: mutualFriends
                )
                
                usersWithInfo.append(userWithInfo)
            }
            
            await MainActor.run {
                self.allUsers = usersWithInfo
            }
        } catch {
            print("Error loading all users: \(error)")
        }
    }
    
    private func calculateMutualFriends(currentUserId: String, otherUserId: String) async -> Int {
        do {
            // Get current user's friends
            let currentUserFriendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id_1.eq.\(currentUserId),user_id_2.eq.\(currentUserId)")
                .execute()
                .value
            
            let currentUserFriends = Set(currentUserFriendships.map { friendship in
                friendship.userId1 == currentUserId ? friendship.userId2 : friendship.userId1
            })
            
            // Get other user's friends
            let otherUserFriendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id_1.eq.\(otherUserId),user_id_2.eq.\(otherUserId)")
                .execute()
                .value
            
            let otherUserFriends = Set(otherUserFriendships.map { friendship in
                friendship.userId1 == otherUserId ? friendship.userId2 : friendship.userId1
            })
            
            // Find intersection
            let mutualFriends = currentUserFriends.intersection(otherUserFriends)
            return mutualFriends.count
        } catch {
            print("Error calculating mutual friends: \(error)")
            return 0
        }
    }
    
    private func getMutualFriends(currentUserId: String, otherUserId: String) async -> [UserProfile] {
        do {
            // Get current user's friends
            let currentUserFriendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id_1.eq.\(currentUserId),user_id_2.eq.\(currentUserId)")
                .execute()
                .value
            
            let currentUserFriends = Set(currentUserFriendships.map { friendship in
                friendship.userId1 == currentUserId ? friendship.userId2 : friendship.userId1
            })
            
            // Get other user's friends
            let otherUserFriendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id_1.eq.\(otherUserId),user_id_2.eq.\(otherUserId)")
                .execute()
                .value
            
            let otherUserFriends = Set(otherUserFriendships.map { friendship in
                friendship.userId1 == otherUserId ? friendship.userId2 : friendship.userId1
            })
            
            // Find intersection
            let mutualFriendIds = currentUserFriends.intersection(otherUserFriends)
            
            if mutualFriendIds.isEmpty {
                return []
            }
            
            // Get profiles for mutual friends
            let mutualFriendProfiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: Array(mutualFriendIds))
                .execute()
                .value
            
            return mutualFriendProfiles
        } catch {
            print("Error getting mutual friends: \(error)")
            return []
        }
    }
    
    func loadFriends(for userId: String) async {
        do {
            let friendships: [Friendship] = try await supabase
                .from("friendships")
                .select()
                .or("user_id_1.eq.\(userId),user_id_2.eq.\(userId)")
                .execute()
                .value
            
            let friendIds = friendships.map { friendship in
                friendship.userId1 == userId ? friendship.userId2 : friendship.userId1
            }
            
            if friendIds.isEmpty {
                await MainActor.run {
                    self.friends = []
                }
                return
            }
            
            let friendProfiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: friendIds)
                .execute()
                .value
            
            await MainActor.run {
                self.friends = friendProfiles
            }
        } catch {
            print("Error loading friends: \(error)")
        }
    }
    
    func updateUserProfile(userId: String, profileImageURL: String) async throws {
        try await supabase
            .from("profiles")
            .update(["profile_image_url": profileImageURL, "updated_at": Date().ISO8601Format()])
            .eq("id", value: userId)
            .execute()
    }
    
    func updateUserProfile(userId: String, isPrivate: Bool) async throws {
        try await supabase
            .from("profiles")
            .update([
                "is_private": AnyJSON.bool(isPrivate),
                "updated_at": AnyJSON.string(Date().ISO8601Format())
            ])
            .eq("id", value: userId)
            .execute()
    }
    
    func updateUserProfile(userId: String, displayName: String) async throws {
        try await supabase
            .from("profiles")
            .update([
                "display_name": displayName,
                "updated_at": Date().ISO8601Format()
            ])
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Ingredient Management
    func loadIngredients() async {
        // First, try to load from local storage
        let localIngredients = LocalIngredientsManager.loadIngredients()
        
        if !localIngredients.isEmpty {
            await MainActor.run {
                self.ingredients = localIngredients
            }
        } else {
            // If no local ingredients, load fallback while downloading
            await MainActor.run {
                self.ingredients = getFallbackIngredients()
            }
        }
        
        // Check if we should update ingredients
        if LocalIngredientsManager.shouldUpdateIngredients() || localIngredients.isEmpty {
            await downloadUSDAIngredients()
        }
    }
    
    func downloadUSDAIngredients() async {
        guard USDADatabaseService.hasValidAPIKey else {
            print("USDA API key not configured - using local ingredients only")
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let downloadedIngredients = try await USDADatabaseService.downloadPopularIngredients()
            LocalIngredientsManager.saveIngredients(downloadedIngredients)
            
            await MainActor.run {
                self.ingredients = downloadedIngredients
                self.isLoading = false
            }
        } catch APIError.missingAPIKey {
            print("USDA API key issue: Missing API key")
            await MainActor.run {
                self.isLoading = false
                // Keep local ingredients if download fails
                if self.ingredients.isEmpty {
                    self.ingredients = getFallbackIngredients()
                }
            }
        } catch APIError.invalidAPIKey {
            print("USDA API key issue: Invalid API key")
            await MainActor.run {
                self.isLoading = false
                // Keep local ingredients if download fails
                if self.ingredients.isEmpty {
                    self.ingredients = getFallbackIngredients()
                }
            }
        } catch {
            print("Error downloading USDA ingredients: \(error)")
            await MainActor.run {
                self.isLoading = false
                // Keep local ingredients if download fails
                if self.ingredients.isEmpty {
                    self.ingredients = getFallbackIngredients()
                }
            }
        }
    }
    
    func searchUSDAFoods(query: String) async -> [Ingredient] {
        guard USDADatabaseService.hasValidAPIKey else {
            print("USDA API key not configured - cannot search online")
            return []
        }
        
        do {
            return try await USDADatabaseService.searchFoods(query: query)
        } catch APIError.missingAPIKey {
            print("USDA API key issue: Missing API key")
            return []
        } catch APIError.invalidAPIKey {
            print("USDA API key issue: Invalid API key")
            return []
        } catch {
            print("Error searching USDA foods: \(error)")
            return []
        }
    }
    
    func loadUserIngredientPresets(for userId: String) async {
        do {
            let presets: [UserIngredientPreset] = try await supabase
                .from("user_ingredient_presets")
                .select()
                .eq("user_id", value: userId)
                .order("name")
                .execute()
                .value
            
            await MainActor.run {
                self.userIngredientPresets = presets
            }
        } catch {
            print("Error loading user ingredient presets: \(error)")
        }
    }
    
    func searchIngredients(query: String) -> [Ingredient] {
        let lowercasedQuery = query.lowercased()
        return ingredients.filter { ingredient in
            ingredient.name.lowercased().contains(lowercasedQuery)
        }
    }
    
    func lookupBarcode(_ barcode: String) async -> BarcodeScanResult? {
        do {
            return try await BarcodeLookupService.lookupProduct(barcode: barcode)
        } catch {
            print("Error looking up barcode: \(error)")
            return nil
        }
    }
    
    func getRecentIngredients() -> [Ingredient] {
        return LocalIngredientsManager.loadRecentIngredients()
    }
    
    func addRecentIngredient(_ ingredient: Ingredient) {
        LocalIngredientsManager.addRecentIngredient(ingredient)
    }
    
    func saveUserIngredientPreset(_ preset: UserIngredientPreset) async throws {
        try await supabase
            .from("user_ingredient_presets")
            .insert(preset)
            .execute()
        
        await loadUserIngredientPresets(for: preset.userId)
    }
    
    func deleteUserIngredientPreset(presetId: String, userId: String) async throws {
        try await supabase
            .from("user_ingredient_presets")
            .delete()
            .eq("id", value: presetId)
            .execute()
        
        await loadUserIngredientPresets(for: userId)
    }
    
    // MARK: - Recipe Collections
    func loadPublicRecipes() async {
        do {
            let recipes: [RecipeCollection] = try await supabase
                .from("recipe_collections")
                .select()
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .limit(100)
                .execute()
                .value
            
            await MainActor.run {
                self.publicRecipes = recipes
            }
        } catch {
            print("Error loading public recipes: \(error)")
        }
    }
    
    func loadUserRecipes(for userId: String) async {
        do {
            let recipes: [RecipeCollection] = try await supabase
                .from("recipe_collections")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.userRecipes = recipes
            }
        } catch {
            print("Error loading user recipes: \(error)")
        }
    }
    
    func saveRecipe(_ recipe: RecipeCollection) async throws {
        try await supabase
            .from("recipe_collections")
            .insert(recipe)
            .execute()
        
        await loadUserRecipes(for: recipe.userId)
        await loadPublicRecipes() // Update public recipes too
    }
    
    func rateRecipe(recipeId: String, userId: String, rating: Int, review: String? = nil) async throws {
        let recipeRating = RecipeRating(
            id: UUID().uuidString,
            recipeId: recipeId,
            userId: userId,
            rating: rating,
            review: review
        )
        
        try await supabase
            .from("recipe_ratings")
            .insert(recipeRating)
            .execute()
    }
    
    func getRecipeRatings(for recipeId: String) async -> [RecipeRating] {
        do {
            return try await supabase
                .from("recipe_ratings")
                .select()
                .eq("recipe_id", value: recipeId)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            print("Error loading recipe ratings: \(error)")
            return []
        }
    }
    
    private func getFallbackIngredients() -> [Ingredient] {
        return [
            Ingredient(id: "1", name: "Chicken Breast", macros: MacroNutrition(calories: 165, protein: 31, carbohydrates: 0, fat: 3.6), category: .protein),
            Ingredient(id: "2", name: "Brown Rice", macros: MacroNutrition(calories: 112, protein: 2.6, carbohydrates: 22, fat: 0.9), category: .grains),
            Ingredient(id: "3", name: "Avocado", macros: MacroNutrition(calories: 160, protein: 2, carbohydrates: 9, fat: 15), category: .fats),
            Ingredient(id: "4", name: "Spinach", macros: MacroNutrition(calories: 7, protein: 0.9, carbohydrates: 1.1, fat: 0.1), category: .vegetables),
            Ingredient(id: "5", name: "Eggs", macros: MacroNutrition(calories: 68, protein: 6, carbohydrates: 0.4, fat: 4.6), category: .protein),
            Ingredient(id: "6", name: "Banana", macros: MacroNutrition(calories: 89, protein: 1.1, carbohydrates: 23, fat: 0.3), category: .fruits),
            Ingredient(id: "7", name: "Olive Oil", macros: MacroNutrition(calories: 119, protein: 0, carbohydrates: 0, fat: 13.5), category: .fats),
            Ingredient(id: "8", name: "Greek Yogurt", macros: MacroNutrition(calories: 59, protein: 10, carbohydrates: 3.6, fat: 0.4), category: .dairy)
        ]
    }
    
    // MARK: - Widget Data Sharing
    func updateWidgetData(userId: String) async {
        
        // Load today's meals and user goals
        await loadTodayMeals(for: userId)
        
        // Calculate today's totals
        let todayTotals = todayMeals.reduce(MacroNutrition()) { total, meal in
            MacroNutrition(
                calories: total.calories + meal.macros.calories,
                protein: total.protein + meal.macros.protein,
                carbohydrates: total.carbohydrates + meal.macros.carbohydrates,
                fat: total.fat + meal.macros.fat,
                sugar: total.sugar + meal.macros.sugar,
                fiber: total.fiber + meal.macros.fiber
            )
        }
        
        // Load user goals
        do {
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            if let profile = profiles.first {
                await saveWidgetData(macros: todayTotals, goals: profile.dailyGoals)
            }
        } catch {
            print("Error loading user goals for widget: \(error)")
        }
    }
    
    private func saveWidgetData(macros: MacroNutrition, goals: MacroGoals) async {
        let appGroupID = "group.com.macrotrackr.shared"
        
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            print("Widget: Failed to access shared container")
            return
        }
        
        do {
            // Save macros
            let macrosData = try JSONEncoder().encode(macros)
            let macrosURL = sharedContainer.appendingPathComponent("today_macros.json")
            try macrosData.write(to: macrosURL)
            
            // Save goals
            let goalsData = try JSONEncoder().encode(goals)
            let goalsURL = sharedContainer.appendingPathComponent("user_goals.json")
            try goalsData.write(to: goalsURL)
            
            // Request widget timeline update
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Widget: Failed to save shared data: \(error)")
        }
    }
    
    // MARK: - Realtime Subscriptions
    func subscribeToFriendRequests(userId: String) {
        friendRequestsSubscription = Task {
            let channel = supabase.channel("friend_requests_\(userId)")
            
            let insertions = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "friend_requests",
                filter: "to_user_id=eq.\(userId)"
            )
            
            let updates = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "friend_requests",
                filter: "from_user_id=eq.\(userId)"
            )
            
            do {
                try await channel.subscribeWithError()
            } catch {
                print("Failed to subscribe to friend requests: \(error)")
            }
            
            for await _ in insertions {
                print("New friend request received!")
                await loadFriendRequests(for: userId)
            }
            
            for await _ in updates {
                print("Friend request updated!")
                await loadFriendRequests(for: userId)
            }
        }
    }
    
    func subscribeToMeals(userId: String) {
        mealsSubscription = Task {
            let channel = supabase.channel("meals_\(userId)")
            
            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "meals",
                filter: "user_id=eq.\(userId)"
            )
            
            do {
                try await channel.subscribeWithError()
            } catch {
                print("Failed to subscribe to meals: \(error)")
            }
            
            for await _ in changes {
                print("Meals updated - reloading...")
                await loadTodayMeals(for: userId)
                await updateWidgetData(userId: userId)
            }
        }
    }
    
    func unsubscribeFromRealtime() {
        friendRequestsSubscription?.cancel()
        mealsSubscription?.cancel()
    }
    
    // MARK: - Search Functionality
    func searchMeals(query: String, filter: SearchFilter = .all, userId: String) async throws -> [Meal] {
        
        var searchQuery = supabase
            .from("meals")
            .select("*")
            .eq("user_id", value: userId)
        
        // Apply search filter
        if !query.isEmpty {
            switch filter {
            case .all:
                searchQuery = searchQuery.or("name.ilike.%\(query)%,ingredients.ilike.%\(query)%")
            case .meals:
                searchQuery = searchQuery.ilike("name", pattern: "%\(query)%")
            case .ingredients:
                searchQuery = searchQuery.ilike("ingredients", pattern: "%\(query)%")
            case .favorites:
                searchQuery = searchQuery.eq("is_favorite", value: true)
                    .or("name.ilike.%\(query)%,ingredients.ilike.%\(query)%")
            }
        } else if filter == .favorites {
            searchQuery = searchQuery.eq("is_favorite", value: true)
        }
        
        let meals: [Meal] = try await searchQuery
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return meals
    }
}

// MARK: - Search Filter Enum
enum SearchFilter: CaseIterable {
    case all, meals, ingredients, favorites
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .meals: return "Meals"
        case .ingredients: return "Ingredients"
        case .favorites: return "Favorites"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Today")
                }
                .tag(0)
            
            AddMealView(selectedDate: nil)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Meal")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            if let userId = authManager.currentUser?.id.uuidString {
                Task {
                    await dataManager.loadTodayMeals(for: userId)
                    await dataManager.loadSavedMeals(for: userId)
                    await dataManager.loadFriendRequests(for: userId)
                    await dataManager.loadFriends(for: userId)
                    await dataManager.loadAllUsers(for: userId)
                    await dataManager.loadIngredients()
                    await dataManager.loadUserIngredientPresets(for: userId)
                    // Update widget data with actual user progress (including zeros)
                    await dataManager.updateWidgetData(userId: userId)
                }
                // Subscribe to realtime updates
                dataManager.subscribeToFriendRequests(userId: userId)
                dataManager.subscribeToMeals(userId: userId)
            }
        }
        .onDisappear {
            // Cleanup realtime subscriptions
            dataManager.unsubscribeFromRealtime()
        }
        .onAppear {
            authManager.checkAuthStatus()
            notificationManager.requestPermission()
            themeManager.applyTheme()
        }
    }
}

// MARK: - USDA FoodData Central API Service
class USDADatabaseService {
    private static let baseURL = "https://api.nal.usda.gov/fdc/v1"
    
    // Try to get API key from environment
    private static var apiKey: String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String, !key.isEmpty, key != "YOUR_API_KEY_HERE" {
            return key
        }
        return nil // No valid API key found
    }
    
    static var hasValidAPIKey: Bool {
        return apiKey != nil
    }
    
    // Popular food categories to download
    private static let popularSearches = [
        "chicken", "beef", "pork", "fish", "salmon", "tuna", "eggs", "milk", "cheese", "yogurt",
        "rice", "pasta", "bread", "potato", "sweet potato", "broccoli", "spinach", "tomato",
        "apple", "banana", "orange", "strawberry", "blueberry", "avocado", "almond", "walnut",
        "olive oil", "coconut oil", "butter", "honey", "oatmeal", "quinoa"
    ]
    
    static func downloadPopularIngredients() async throws -> [Ingredient] {
        guard hasValidAPIKey else {
            throw APIError.missingAPIKey
        }
        
        var allIngredients: [Ingredient] = []
        
        // Download ingredients for popular foods
        for searchTerm in popularSearches.prefix(20) { // Limit to prevent too many requests
            do {
                let ingredients = try await searchFoods(query: searchTerm)
                allIngredients.append(contentsOf: ingredients)
                
                // Small delay between requests to be respectful
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } catch APIError.missingAPIKey {
                // Don't continue if API key issues
                throw APIError.missingAPIKey
            } catch APIError.invalidAPIKey {
                // Don't continue if API key issues
                throw APIError.invalidAPIKey
            } catch {
                print("Failed to fetch ingredients for '\(searchTerm)': \(error)")
                continue
            }
        }
        
        // Remove duplicates and limit to reasonable number
        let uniqueIngredients = Array(Set(allIngredients.map { $0.name }))
            .compactMap { name in
                allIngredients.first { $0.name == name }
            }
        
        return Array(uniqueIngredients.prefix(500)) // Limit to 500 most relevant ingredients
    }
    
    static func searchFoods(query: String) async throws -> [Ingredient] {
        guard let apiKey = apiKey else {
            throw APIError.missingAPIKey
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/foods/search?query=\(encodedQuery)&api_key=\(apiKey)&dataType=Foundation&pageSize=10")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        // Handle API key errors
        if httpResponse.statusCode == 401 {
            throw APIError.invalidAPIKey
        } else if httpResponse.statusCode != 200 {
            throw APIError.invalidResponse
        }
        
        let usdaResponse = try JSONDecoder().decode(USDAApiResponse.self, from: data)
        let ingredients = usdaResponse.foods.compactMap { food in
            convertUSDAFoodToIngredient(food)
        }
        
        return ingredients
    }
    
    private static func convertUSDAFoodToIngredient(_ usdaFood: USDAFood) -> Ingredient? {
        // Extract nutrition data from USDA food
        var calories = 0.0
        var protein = 0.0
        var carbohydrates = 0.0
        var fat = 0.0
        var sugar = 0.0
        var fiber = 0.0
        
        // Map USDA nutrient IDs to our macro values
        for foodNutrient in usdaFood.foodNutrients {
            switch foodNutrient.nutrient.id {
            case 1008: // Energy (kcal)
                calories = foodNutrient.amount
            case 1003: // Protein
                protein = foodNutrient.amount
            case 1005: // Carbohydrates
                carbohydrates = foodNutrient.amount
            case 1004: // Fat
                fat = foodNutrient.amount
            case 2000: // Sugars
                sugar = foodNutrient.amount
            case 1079: // Fiber
                fiber = foodNutrient.amount
            default:
                break
            }
        }
        
        // Only include foods with meaningful nutrition data
        guard calories > 0 || protein > 0 || carbohydrates > 0 || fat > 0 else {
            return nil
        }
        
        // Clean up food description
        let cleanName = cleanFoodName(usdaFood.description)
        
        // Determine category based on food name and nutrients
        let category = categorizeFood(cleanName, calories: calories, protein: protein, carbohydrates: carbohydrates, fat: fat)
        
        let macros = MacroNutrition(
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            sugar: sugar,
            fiber: fiber
        )
        
        return Ingredient(
            id: "usda_\(usdaFood.fdcId)",
            name: cleanName,
            macros: macros,
            category: category,
            createdAt: Date()
        )
    }
    
    private static func cleanFoodName(_ name: String) -> String {
        // Remove brand names and extra details to get cleaner ingredient names
        var cleanName = name
        
        // Remove common prefixes/suffixes
        let removePatterns = [
            "\\(.*\\)", // Remove text in parentheses
            ", raw", ", cooked", ", roasted", ", grilled",
            ", fresh", ", frozen", ", canned",
            ", without salt", ", with salt",
            ", USDA", ", generic"
        ]
        
        for pattern in removePatterns {
            cleanName = cleanName.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        // Capitalize properly
        return cleanName.trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
    
    private static func categorizeFood(_ name: String, calories: Double, protein: Double, carbohydrates: Double, fat: Double) -> IngredientCategory {
        let lowercasedName = name.lowercased()
        
        // Protein-rich foods
        if protein > carbohydrates && protein > fat {
            return .protein
        }
        
        // Category based on food name keywords
        if lowercasedName.contains("chicken") || lowercasedName.contains("beef") || lowercasedName.contains("pork") ||
           lowercasedName.contains("fish") || lowercasedName.contains("salmon") || lowercasedName.contains("tuna") ||
           lowercasedName.contains("turkey") || lowercasedName.contains("lamb") || lowercasedName.contains("egg") {
            return .protein
        }
        
        if lowercasedName.contains("rice") || lowercasedName.contains("bread") || lowercasedName.contains("pasta") ||
           lowercasedName.contains("potato") || lowercasedName.contains("oats") || lowercasedName.contains("quinoa") {
            return .grains
        }
        
        if lowercasedName.contains("apple") || lowercasedName.contains("banana") || lowercasedName.contains("orange") ||
           lowercasedName.contains("berry") || lowercasedName.contains("fruit") {
            return .fruits
        }
        
        if lowercasedName.contains("broccoli") || lowercasedName.contains("spinach") || lowercasedName.contains("carrot") ||
           lowercasedName.contains("tomato") || lowercasedName.contains("onion") || lowercasedName.contains("pepper") {
            return .vegetables
        }
        
        if lowercasedName.contains("milk") || lowercasedName.contains("cheese") || lowercasedName.contains("yogurt") ||
           lowercasedName.contains("butter") || lowercasedName.contains("cream") {
            return .dairy
        }
        
        if lowercasedName.contains("oil") || lowercasedName.contains("avocado") || lowercasedName.contains("nut") ||
           lowercasedName.contains("seed") && fat > 10 {
            return .fats
        }
        
        // Default based on macronutrients
        if carbohydrates > protein && carbohydrates > fat {
            return .carbs
        } else if fat > protein && fat > carbohydrates {
            return .fats
        } else {
            return .other
        }
    }
}

// MARK: - Barcode Lookup Service
class BarcodeLookupService {
    // Using OpenFoodFacts API (free and comprehensive)
    private static let baseURL = "https://world.openfoodfacts.org/api/v0/product"
    
    static func lookupProduct(barcode: String) async throws -> BarcodeScanResult {
        let url = URL(string: "\(baseURL)/\(barcode).json")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let openFoodFactsResponse = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        
        guard openFoodFactsResponse.status == 1,
              let product = openFoodFactsResponse.product else {
            throw APIError.invalidResponse
        }
        
        // Extract nutrition information
        let nutrition = extractNutrition(from: product)
        
        return BarcodeScanResult(
            barcode: barcode,
            productName: product.productName ?? "Unknown Product",
            brand: product.brands,
            imageURL: product.imageURL,
            nutrition: nutrition,
            servingSize: product.servingSize
        )
    }
    
    private static func extractNutrition(from product: OpenFoodFactsProduct) -> MacroNutrition {
        let nutriments = product.nutriments
        
        return MacroNutrition(
            calories: nutriments?["energy-kcal_100g"] ?? nutriments?["energy_100g"] ?? 0,
            protein: nutriments?["proteins_100g"] ?? 0,
            carbohydrates: nutriments?["carbohydrates_100g"] ?? 0,
            fat: nutriments?["fat_100g"] ?? 0,
            sugar: nutriments?["sugars_100g"] ?? 0,
            fiber: nutriments?["fiber_100g"] ?? 0
        )
    }
}

// MARK: - OpenFoodFacts API Models
private struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

private struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let brands: String?
    let imageURL: String?
    let servingSize: String?
    let nutriments: [String: Double]?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case servingSize = "serving_size"
        case nutriments
    }
}

enum APIError: Error {
    case invalidResponse
    case decodingError
    case networkError
    case missingAPIKey
    case invalidAPIKey
    
    var localizedDescription: String {
        switch self {
        case .missingAPIKey:
            return "USDA API key is missing. Please add USDA_API_KEY to your build settings."
        case .invalidAPIKey:
            return "USDA API key is invalid. Please check your API key."
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response data"
        case .networkError:
            return "Network connection error"
        }
    }
}
