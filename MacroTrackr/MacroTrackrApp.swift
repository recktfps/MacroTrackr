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
        
        let user = response.user
        
        // Create user profile
        let profile = UserProfile(
            id: user.id.uuidString,
            displayName: displayName,
            email: email,
            dailyGoals: MacroGoals(),
            isPrivate: false,
            createdAt: Date()
        )
        
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
        
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = response.user
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
    @Published var isLoading = false
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://adnjakimzfidaolaxmck.supabase.co")!,
        supabaseKey: "sb_publishable_VY1OkpLC8zEUuOkiPgxPoQ_9d0eVE9_"
    )
    
    // Realm for local caching
    private let realm = try! Realm()
    
    func loadTodayMeals(for userId: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let meals: [Meal] = try await supabase
                .from("meals")
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: today)
                .lt("created_at", value: tomorrow)
                .execute()
                .value
            
            await MainActor.run {
                self.todayMeals = meals
            }
        } catch {
            print("Error loading today's meals: \(error)")
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
    }
    
    func uploadImage(_ imageData: Data, fileName: String) async throws -> String {
        let uploadResponse = try await supabase.storage
            .from("meal-images")
            .upload(fileName, data: imageData)
        
        let publicURL = try supabase.storage
            .from("meal-images")
            .getPublicURL(path: uploadResponse.path)
        
        return publicURL.absoluteString
    }
    
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        let fileName = "profile-\(userId).jpg"
        return try await uploadImage(imageData, fileName: fileName)
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
            
            AddMealView()
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
                }
            }
        }
        .onAppear {
            authManager.checkAuthStatus()
            notificationManager.requestPermission()
        }
    }
}
