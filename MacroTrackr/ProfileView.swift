import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSettings = false
    @State private var showingGoals = false
    @State private var showingFriends = false
    @State private var showingPrivacySettings = false
    @State private var userProfile: UserProfile?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderView(profile: userProfile)
                    
                    // Quick Stats
                    QuickStatsView()
                    
                    // Action Buttons
                    ActionButtonsView(
                        showingGoals: $showingGoals,
                        showingFriends: $showingFriends,
                        showingPrivacySettings: $showingPrivacySettings
                    )
                    
                    // Favorite Meals
                    if !dataManager.savedMeals.filter(\.isFavorite).isEmpty {
                        FavoriteMealsSection()
                    }
                    
                    // Settings Section
                    SettingsSection(showingSettings: $showingSettings)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        signOut()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            loadUserProfile()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingGoals) {
            GoalsView()
        }
        .sheet(isPresented: $showingFriends) {
            FriendsView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }
    
    private func loadUserProfile() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            // In a real implementation, this would fetch from Supabase
            let profile = UserProfile(
                id: userId,
                displayName: "User",
                email: authManager.currentUser?.email ?? "",
                dailyGoals: MacroGoals(),
                isPrivate: false,
                createdAt: Date()
            )
            
            await MainActor.run {
                self.userProfile = profile
                self.isLoading = false
            }
        }
    }
    
    private func signOut() {
        Task {
            try? await authManager.signOut()
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let profile: UserProfile?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: profile?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            // Name and Email
            VStack(spacing: 4) {
                Text(profile?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(profile?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Privacy Status
            HStack {
                Image(systemName: profile?.isPrivate == true ? "lock.fill" : "globe")
                    .foregroundColor(.secondary)
                Text(profile?.isPrivate == true ? "Private Profile" : "Public Profile")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Quick Stats View
struct QuickStatsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var totalMeals: Int {
        dataManager.savedMeals.count
    }
    
    private var favoriteMeals: Int {
        dataManager.savedMeals.filter(\.isFavorite).count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(title: "Total Meals", value: "\(totalMeals)", icon: "fork.knife")
            StatItem(title: "Favorites", value: "\(favoriteMeals)", icon: "heart.fill")
            StatItem(title: "Days Active", value: "7", icon: "calendar")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    @Binding var showingGoals: Bool
    @Binding var showingFriends: Bool
    @Binding var showingPrivacySettings: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Daily Goals",
                subtitle: "Set your macro targets",
                icon: "target",
                color: .blue
            ) {
                showingGoals = true
            }
            
            ActionButton(
                title: "Friends",
                subtitle: "Connect and share meals",
                icon: "person.2.fill",
                color: .green
            ) {
                showingFriends = true
            }
            
            ActionButton(
                title: "Privacy Settings",
                subtitle: "Control your data visibility",
                icon: "lock.shield.fill",
                color: .purple
            ) {
                showingPrivacySettings = true
            }
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Favorite Meals Section
struct FavoriteMealsSection: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var favoriteMeals: [Meal] {
        dataManager.savedMeals.filter(\.isFavorite)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Favorite Meals")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favoriteMeals.prefix(5)) { meal in
                        FavoriteMealCard(meal: meal)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Favorite Meal Card
struct FavoriteMealCard: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: meal.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 120, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(meal.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
        }
        .frame(width: 120)
    }
}

// MARK: - Settings Section
struct SettingsSection: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ActionButton(
                title: "Settings",
                subtitle: "App preferences and configuration",
                icon: "gearshape.fill",
                color: .gray
            ) {
                showingSettings = true
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var hapticFeedbackEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Preferences") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section("Data") {
                    Button("Export Data") {
                        // Export functionality
                    }
                    
                    Button("Clear Cache") {
                        // Clear cache functionality
                    }
                    .foregroundColor(.orange)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    
                    Button("Terms of Service") {
                        // Open terms of service
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Goals View
struct GoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var goals = MacroGoals()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Macro Goals") {
                    MacroGoalField(title: "Calories", value: $goals.calories, unit: "kcal")
                    MacroGoalField(title: "Protein", value: $goals.protein, unit: "g")
                    MacroGoalField(title: "Carbohydrates", value: $goals.carbohydrates, unit: "g")
                    MacroGoalField(title: "Fat", value: $goals.fat, unit: "g")
                    MacroGoalField(title: "Sugar", value: $goals.sugar, unit: "g")
                    MacroGoalField(title: "Fiber", value: $goals.fiber, unit: "g")
                }
            }
            .navigationTitle("Daily Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save goals
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Macro Goal Field
struct MacroGoalField: View {
    let title: String
    @Binding var value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                
                Text(unit)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
            }
        }
    }
}

// MARK: - Friends View
struct FriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var friends: [UserProfile] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search users...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Friends List
                List(friends) { friend in
                    FriendRowView(friend: friend)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let friend: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("View") {
                // View friend's profile
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPrivate = false
    @State private var allowFriendRequests = true
    @State private var shareMealsWithFriends = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Privacy") {
                    Toggle("Private Profile", isOn: $isPrivate)
                    
                    Text("When enabled, your profile and stats will only be visible to your friends.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Social Features") {
                    Toggle("Allow Friend Requests", isOn: $allowFriendRequests)
                    Toggle("Share Meals with Friends", isOn: $shareMealsWithFriends)
                }
                
                Section("Data Sharing") {
                    Toggle("Anonymous Usage Analytics", isOn: .constant(false))
                    
                    Text("Help improve the app by sharing anonymous usage data. Your personal information is never shared.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save privacy settings
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
}
