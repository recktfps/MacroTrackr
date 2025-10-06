import SwiftUI
import Supabase

@main
struct MacroTrackrApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var dataManager = DataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
                .onAppear {
                    authManager.checkAuthStatus()
                }
        }
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://adnjakimzfidaolaxmck.supabase.co")!,
        supabaseKey: "sb_publishable_VY1OkpLC8zEUuOkiPgxPoQ_9d0eVE9_"
    )
    
    func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    self.isAuthenticated = session.user != nil
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
        
        if let user = response.user {
            // Create user profile
            let profile = UserProfile(
                id: user.id,
                displayName: displayName,
                email: email,
                dailyGoals: MacroGoals(),
                isPrivate: false,
                createdAt: Date()
            )
            
            try await supabase.database
                .from("profiles")
                .insert(profile)
                .execute()
        }
        
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUser = user
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
    
    func loadTodayMeals(for userId: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let meals: [Meal] = try await supabase.database
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
            let meals: [Meal] = try await supabase.database
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
        try await supabase.database
            .from("meals")
            .insert(meal)
            .execute()
        
        await loadTodayMeals(for: meal.userId)
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
        
        try await supabase.database
            .from("saved_meals")
            .insert(savedMeal)
            .execute()
        
        await loadSavedMeals(for: meal.userId)
    }
}
