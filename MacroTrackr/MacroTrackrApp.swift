import SwiftUI
import Combine
import Supabase
import Kingfisher
import RealmSwift
import AuthenticationServices
import PhotosUI
import UserNotifications
import UIKit
import AVFoundation
import Vision
import WidgetKit

// Full MacroTrackr app with Supabase, Kingfisher, and Realm
@main
struct MacroTrackrApp: SwiftUI.App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var dataManager = DataManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(dataManager)
                    .environmentObject(notificationManager)
            } else {
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(notificationManager)
            }
        }
    }
    
    init() {
        // Check authentication status when app launches
        Task {
            await authManager.checkAuthStatus()
        }
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
    @Published var isLoading = false
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://adnjakimzfidaolaxmck.supabase.co")!,
        supabaseKey: "sb_publishable_VY1OkpLC8zEUuOkiPgxPoQ_9d0eVE9_"
    )
    
    // Realm for local caching
    private let realm = try! Realm()
    
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
    
    func addMeal(_ meal: Meal) async throws {
        try await supabase
            .from("meals")
            .insert(meal)
            .execute()
        
        await loadTodayMeals(for: meal.userId)
        await updateWidgetData(userId: meal.userId) // Update widget when new meal is added
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
                filter: PostgresFilter(column: "to_user_id", value: userId)
            )
            
            let updates = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "friend_requests",
                filter: PostgresFilter(column: "from_user_id", value: userId)
            )
            
            await channel.subscribeWithError()
            
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
                filter: PostgresFilter(column: "user_id", value: userId)
            )
            
            await channel.subscribeWithError()
            
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
        }
    }
}
