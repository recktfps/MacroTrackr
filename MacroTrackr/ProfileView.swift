import SwiftUI
import Supabase
import PhotosUI
import WidgetKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @State private var showingSettings = false
    @State private var showingGoals = false
    @State private var showingFriends = false
    @State private var showingPrivacySettings = false
    @State private var userProfile: UserProfile?
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderView(profile: userProfile, onProfileUpdated: {
                        loadUserProfile()
                    })
                    
                    // Quick Stats
                    QuickStatsView()
                    
                    // Action Buttons
                    ActionButtonsView(
                        showingGoals: $showingGoals,
                        showingFriends: $showingFriends,
                        showingPrivacySettings: $showingPrivacySettings,
                        onAddWidget: addWidgetToHomeScreen
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
            PrivacySettingsView(
                userProfile: userProfile,
                onProfileUpdated: {
                    loadUserProfile()
                }
            )
        }
    }
    
    private func loadUserProfile() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                // Fetch user profile from Supabase
                let profiles: [UserProfile] = try await dataManager.supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .execute()
                    .value
                
                if let profile = profiles.first {
                    await MainActor.run {
                        self.userProfile = profile
                        self.isLoading = false
                    }
                } else {
                    // Create default profile if none exists
                    let profile = UserProfile(
                        id: userId.uuidString,
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
            } catch {
                print("Error loading user profile: \(error)")
                // Fallback to default profile
                let profile = UserProfile(
                    id: userId.uuidString,
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
    }
    
    private func signOut() {
        Task {
            try? await authManager.signOut()
        }
    }
    
    private func addWidgetToHomeScreen() {
        // Show instructions for adding widget
        let alert = UIAlertController(
            title: "Add Widget",
            message: "To add the MacroTrackr widget to your home screen:\n\n1. Long press on your home screen\n2. Tap the + button\n3. Search for 'MacroTrackr'\n4. Select the widget size you want\n5. Tap 'Add Widget'",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let profile: UserProfile?
    let onProfileUpdated: () -> Void
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isUploading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image with Edit Button
            ZStack {
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
                
                // Edit Button Overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
                .frame(width: 100, height: 100)
            }
            
            // Name and Email
            VStack(spacing: 4) {
                Text(profile?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("@\(profile?.displayName ?? "")")
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
            
            // Upload Progress
            if isUploading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                    }
                    await uploadProfileImage(image)
                }
            }
        }
        .alert("Profile Picture", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        guard let userId = authManager.currentUser?.id.uuidString else { return }
        
        await MainActor.run {
            isUploading = true
        }
        
        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
            }
            
            // Upload to Supabase Storage
            let imageURL = try await dataManager.uploadProfileImage(imageData, userId: userId)
            
            // Update user profile in database
            try await dataManager.updateUserProfile(userId: userId, profileImageURL: imageURL)
            
            await MainActor.run {
                isUploading = false
                alertMessage = "Profile picture updated successfully!"
                showingAlert = true
                onProfileUpdated() // Refresh the profile
            }
        } catch {
            await MainActor.run {
                isUploading = false
                alertMessage = "Failed to update profile picture: \(error.localizedDescription)"
                showingAlert = true
            }
        }
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
    let onAddWidget: () -> Void
    
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
            
            ActionButton(
                title: "Add Widget",
                subtitle: "Add MacroTrackr to your home screen",
                icon: "plus.rectangle.on.rectangle",
                color: .orange
            ) {
                onAddWidget()
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


struct GoalsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var goals = MacroGoals()
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Calorie Goal") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("2000", value: $goals.calories, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Macronutrient Goals") {
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("150", value: $goals.protein, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Carbohydrates")
                        Spacer()
                        TextField("250", value: $goals.carbohydrates, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("65", value: $goals.fat, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sugar")
                        Spacer()
                        TextField("30", value: $goals.sugar, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Fiber")
                        Spacer()
                        TextField("25", value: $goals.fiber, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundColor(.secondary)
                    }
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
                        saveGoals()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadCurrentGoals()
        }
        .alert("Goals", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentGoals() {
        guard let userId = authManager.currentUser?.id.uuidString else { return }
        
        Task {
            do {
                let profiles: [UserProfile] = try await dataManager.supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .execute()
                    .value
                
                if let profile = profiles.first {
                    await MainActor.run {
                        self.goals = profile.dailyGoals
                    }
                }
            } catch {
                print("Error loading goals: \(error)")
            }
        }
    }
    
    private func saveGoals() {
        guard let userId = authManager.currentUser?.id.uuidString else { return }
        
        isLoading = true
        
        Task {
            do {
                try await dataManager.supabase
                    .from("profiles")
                    .update([
                        "daily_goals": AnyJSON.object([
                            "calories": AnyJSON.double(goals.calories),
                            "protein": AnyJSON.double(goals.protein),
                            "carbohydrates": AnyJSON.double(goals.carbohydrates),
                            "fat": AnyJSON.double(goals.fat),
                            "sugar": AnyJSON.double(goals.sugar),
                            "fiber": AnyJSON.double(goals.fiber)
                        ]),
                        "updated_at": AnyJSON.string(Date().ISO8601Format())
                    ])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Goals saved successfully!"
                    showingAlert = true
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to save goals: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Friends View
struct FriendsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Segmented Control
                Picker("Friends Tab", selection: $selectedTab) {
                    Text("Users").tag(0)
                    Text("Friends").tag(1)
                    Text("Requests").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case 0:
                    UsersListView(searchText: $searchText)
                case 1:
                    FriendsListView()
                case 2:
                    FriendRequestsView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search users...")
        .onAppear {
            guard let userId = authManager.currentUser?.id.uuidString else { return }
            Task {
                await dataManager.loadAllUsers(for: userId)
                await dataManager.loadFriends(for: userId)
                await dataManager.loadFriendRequests(for: userId)
            }
        }
    }
}

// MARK: - Users List View
struct UsersListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var searchText: String
    
    private var filteredUsers: [UserWithFriendshipInfo] {
        if searchText.isEmpty {
            return dataManager.allUsers
        } else {
            return dataManager.allUsers.filter { user in
                user.user.displayName.localizedCaseInsensitiveContains(searchText) ||
                false // Email search removed for privacy
            }
        }
    }
    
    var body: some View {
        if searchText.isEmpty {
            List(filteredUsers) { userInfo in
                UserRowView(userInfo: userInfo)
            }
        } else if filteredUsers.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("No users found")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("No users match '\(searchText)'. Try a different search term.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if searchText.count >= 3 {
                    Text("Tip: Search by display name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(filteredUsers) { userInfo in
                UserRowView(userInfo: userInfo)
            }
        }
    }
}

// MARK: - User Row View
struct UserRowView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userInfo: UserWithFriendshipInfo
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var buttonText: String {
        if userInfo.friendshipStatus == .friends {
            return "Friends"
        } else if userInfo.friendshipStatus == .pendingOutgoing {
            return "Pending"
        } else if userInfo.friendshipStatus == .pendingIncoming {
            return "Accept"
        } else {
            return "Add"
        }
    }
    
    private var buttonColor: Color {
        if userInfo.friendshipStatus == .friends {
            return .green
        } else if userInfo.friendshipStatus == .pendingOutgoing {
            return .orange
        } else if userInfo.friendshipStatus == .pendingIncoming {
            return .blue
        } else {
            return .blue
        }
    }
    
    var body: some View {
        HStack {
            // Profile Image
            AsyncImage(url: URL(string: userInfo.user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(userInfo.user.displayName)
                    .font(.headline)
                
                if userInfo.mutualFriendsCount > 0 {
                    Text("\(userInfo.mutualFriendsCount) mutual friend\(userInfo.mutualFriendsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                handleUserAction()
            }) {
                Text(buttonText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(buttonColor)
                    .cornerRadius(8)
            }
            .disabled(userInfo.friendshipStatus == .friends || userInfo.friendshipStatus == .pendingOutgoing)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleUserAction() {
        guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
        
        Task {
            do {
                switch userInfo.friendshipStatus {
                case .notFriends:
                    try await dataManager.sendFriendRequest(fromUserId: currentUserId, toDisplayName: userInfo.user.displayName)
                    // Refresh the user list to update button states
                    await dataManager.loadAllUsers(for: currentUserId)
                    await dataManager.loadFriendRequests(for: currentUserId)
                case .pendingIncoming:
                    // Find the friend request and accept it
                    if let request = dataManager.pendingFriendRequests.first(where: { $0.fromUserId == userInfo.user.id }) {
                        try await dataManager.respondToFriendRequest(requestId: request.id, status: .accepted, currentUserId: currentUserId)
                        // Refresh the user list and friend requests
                        await dataManager.loadAllUsers(for: currentUserId)
                        await dataManager.loadFriendRequests(for: currentUserId)
                        await dataManager.loadFriends(for: currentUserId)
                    }
                default:
                    break
                }
            } catch {
                print("Error handling user action: \(error)")
                await MainActor.run {
                    if let nsError = error as NSError? {
                        alertMessage = nsError.localizedDescription
                    } else {
                        alertMessage = "An error occurred. Please try again."
                    }
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List(dataManager.friends) { friend in
            HStack {
                AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.headline)
                    
                    Text("Friend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Friends")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Friend Requests View
struct FriendRequestsView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var requestUserProfiles: [String: UserProfile] = [:]
    
    var body: some View {
        List(dataManager.pendingFriendRequests) { request in
            FriendRequestRowView(
                request: request,
                userProfile: requestUserProfiles[request.fromUserId],
                onAccept: { acceptRequest(request) },
                onDecline: { declineRequest(request) }
            )
        }
        .onAppear {
            loadRequestUserProfiles()
        }
    }
    
    private func loadRequestUserProfiles() {
        Task {
            for request in dataManager.pendingFriendRequests {
                do {
                    let profiles: [UserProfile] = try await dataManager.supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: request.fromUserId)
                        .execute()
                        .value
                    
                    if let profile = profiles.first {
                        await MainActor.run {
                            requestUserProfiles[request.fromUserId] = profile
                        }
                    }
                } catch {
                    print("Error loading user profile for request: \(error)")
                }
            }
        }
    }
    
    private func acceptRequest(_ request: FriendRequest) {
        guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
        
        Task {
            try? await dataManager.respondToFriendRequest(requestId: request.id, status: .accepted, currentUserId: currentUserId)
            await dataManager.loadFriendRequests(for: currentUserId)
            await dataManager.loadFriends(for: currentUserId)
        }
    }
    
    private func declineRequest(_ request: FriendRequest) {
        guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
        
        Task {
            try? await dataManager.respondToFriendRequest(requestId: request.id, status: .declined, currentUserId: currentUserId)
            await dataManager.loadFriendRequests(for: currentUserId)
        }
    }
}

// MARK: - Friend Request Row View
struct FriendRequestRowView: View {
    let request: FriendRequest
    let userProfile: UserProfile?
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: userProfile?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userProfile?.displayName ?? "Unknown User")
                    .font(.headline)
                
                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Accept") {
                    onAccept()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(8)
                
                Button("Decline") {
                    onDecline()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPrivate: Bool = false
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    let userProfile: UserProfile?
    var onProfileUpdated: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Visibility")) {
                    Toggle("Private Profile", isOn: $isPrivate)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Text("When enabled, your profile, meals, and stats will only be visible to your friends.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Data Sharing")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anonymous Usage Analytics")
                            .font(.headline)
                        
                        Text("Help improve MacroTrackr by sharing anonymous usage data. This data cannot be used to identify you.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Enable Analytics", isOn: .constant(false))
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                Section(header: Text("Friends & Social")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Friend Requests")
                            .font(.headline)
                        
                        Text("Allow other users to send you friend requests.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Allow Friend Requests", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                Section(header: Text("Account Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Information")
                            .font(.headline)
                        
                        Text("Control what information is visible on your profile.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        NavigationLink("Edit Profile") {
                            Text("Profile editing would be implemented here")
                                .navigationTitle("Edit Profile")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
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
                        savePrivacySettings()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Privacy Settings", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentSettings() {
        guard let userProfile = userProfile else { return }
        isPrivate = userProfile.isPrivate
    }
    
    private func savePrivacySettings() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                try await dataManager.updateUserProfile(
                    userId: userId.uuidString,
                    isPrivate: isPrivate
                )
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Privacy settings updated successfully"
                    showingAlert = true
                    onProfileUpdated?()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to update privacy settings: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}
