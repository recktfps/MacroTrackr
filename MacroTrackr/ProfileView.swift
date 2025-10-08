import SwiftUI
import Supabase
import PhotosUI

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
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var showingAddFriend = false
    @State private var friendDisplayName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("Users").tag(0)
                    Text("Friends").tag(1)
                    Text("Requests").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
                .padding(.horizontal)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // All Users Tab
                    UsersListView(searchText: searchText)
                        .tag(0)
                    
                    // Friends Tab
                    FriendsListView(friends: dataManager.friends, searchText: searchText)
                        .tag(1)
                    
                    // Friend Requests Tab
                    FriendRequestsListView(
                        pendingRequests: dataManager.pendingFriendRequests,
                        outgoingRequests: dataManager.friendRequests
                    )
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Add Friend") {
                        showingAddFriend = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Add Friend", isPresented: $showingAddFriend) {
                TextField("Display Name", text: $friendDisplayName)
                Button("Send Request") {
                    sendFriendRequest()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your friend's display name to send a friend request.")
            }
            .alert("Friend Request", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        guard let userId = authManager.currentUser?.id.uuidString else { return }
        
        Task {
            await dataManager.loadAllUsers(for: userId)
            await dataManager.loadFriends(for: userId)
            await dataManager.loadFriendRequests(for: userId)
        }
    }
    
    private func sendFriendRequest() {
        guard !friendDisplayName.isEmpty else {
            alertMessage = "Please enter a display name."
            showingAlert = true
            return
        }
        
        guard let userId = authManager.currentUser?.id.uuidString else {
            alertMessage = "User not authenticated."
            showingAlert = true
            return
        }
        
        Task {
            do {
                try await dataManager.sendFriendRequest(fromUserId: userId, toDisplayName: friendDisplayName)
                await MainActor.run {
                    alertMessage = "Friend request sent to \(friendDisplayName)!"
                    showingAlert = true
                    friendDisplayName = ""
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
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
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dataManager: DataManager
    @State private var isPrivate = false
    @State private var allowFriendRequests = true
    @State private var shareMealsWithFriends = true
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
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
                        self.isPrivate = profile.isPrivate
                        // Note: allowFriendRequests and shareMealsWithFriends would need to be added to the UserProfile model
                        // For now, we'll use defaults
                    }
                }
            } catch {
                print("Error loading privacy settings: \(error)")
            }
        }
    }
    
    private func savePrivacySettings() {
        guard let userId = authManager.currentUser?.id.uuidString else { return }
        
        isLoading = true
        
        Task {
            do {
                try await dataManager.supabase
                    .from("profiles")
                    .update([
                        "is_private": AnyJSON.bool(isPrivate),
                        "updated_at": AnyJSON.string(Date().ISO8601Format())
                    ])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Privacy settings saved successfully!"
                    showingAlert = true
                    
                    // Dismiss after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Failed to save privacy settings: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Users List View
struct UsersListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let searchText: String
    
    var filteredUsers: [UserWithFriendshipInfo] {
        if searchText.isEmpty {
            return dataManager.allUsers
        } else {
            return dataManager.allUsers.filter { user in
                user.user.displayName.localizedCaseInsensitiveContains(searchText) ||
                user.user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(filteredUsers) { userInfo in
            NavigationLink(destination: UserProfileView(userInfo: userInfo)) {
                UserRowView(userInfo: userInfo)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    let friends: [UserProfile]
    let searchText: String
    
    var filteredFriends: [UserProfile] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.displayName.localizedCaseInsensitiveContains(searchText) ||
                friend.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(filteredFriends) { friend in
            NavigationLink(destination: UserProfileView(userInfo: UserWithFriendshipInfo(
                user: friend,
                friendshipStatus: .friends,
                mutualFriendsCount: 0,
                mutualFriends: []
            ))) {
                FriendRowView(friend: friend)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Friend Requests List View
struct FriendRequestsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let pendingRequests: [FriendRequest]
    let outgoingRequests: [FriendRequest]
    
    var body: some View {
        List {
            if !pendingRequests.isEmpty {
                Section("Incoming Requests") {
                    ForEach(pendingRequests) { request in
                        FriendRequestRowView(request: request, isIncoming: true)
                    }
                }
            }
            
            if !outgoingRequests.isEmpty {
                Section("Sent Requests") {
                    ForEach(outgoingRequests) { request in
                        FriendRequestRowView(request: request, isIncoming: false)
                    }
                }
            }
            
            if pendingRequests.isEmpty && outgoingRequests.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "person.2")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Friend Requests")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Send friend requests to connect with other users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - User Row View
struct UserRowView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userInfo: UserWithFriendshipInfo
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: userInfo.user.profileImageURL ?? "")) { image in
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
                Text(userInfo.user.displayName)
                    .font(.headline)
                
                Text(userInfo.user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if userInfo.mutualFriendsCount > 0 {
                    Text("\(userInfo.mutualFriendsCount) mutual friends")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            FriendStatusButton(userInfo: userInfo)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Friend Status Button
struct FriendStatusButton: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userInfo: UserWithFriendshipInfo
    
    var body: some View {
        Button(action: handleFriendAction) {
            Text(buttonText)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(buttonColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(userInfo.friendshipStatus == .selfUser)
    }
    
    private var buttonText: String {
        switch userInfo.friendshipStatus {
        case .notFriends:
            return "Add"
        case .pendingOutgoing:
            return "Pending"
        case .pendingIncoming:
            return "Accept"
        case .friends:
            return "Friends"
        case .selfUser:
            return "You"
        }
    }
    
    private var buttonColor: Color {
        switch userInfo.friendshipStatus {
        case .notFriends:
            return .blue
        case .pendingOutgoing:
            return .orange
        case .pendingIncoming:
            return .green
        case .friends:
            return .green
        case .selfUser:
            return .gray
        }
    }
    
    private func handleFriendAction() {
        guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
        
        switch userInfo.friendshipStatus {
        case .notFriends:
            Task {
                do {
                    try await dataManager.sendFriendRequest(fromUserId: currentUserId, toDisplayName: userInfo.user.displayName)
                    // Refresh data after sending request
                    await dataManager.loadAllUsers(for: currentUserId)
                    await dataManager.loadFriendRequests(for: currentUserId)
                } catch {
                    await MainActor.run {
                        // Show user-friendly error message
                        let errorMessage = getFriendlyErrorMessage(from: error)
                        // You could add a state variable to show alerts here if needed
                        print("Friend request error: \(errorMessage)")
                    }
                }
            }
        case .pendingIncoming:
            // Find the incoming request and accept it
            if let request = dataManager.pendingFriendRequests.first(where: { $0.fromUserId == userInfo.user.id }) {
                Task {
                    do {
                        try await dataManager.respondToFriendRequest(requestId: request.id, status: .accepted, currentUserId: currentUserId)
                        // Refresh data after accepting request
                        await dataManager.loadAllUsers(for: currentUserId)
                        await dataManager.loadFriends(for: currentUserId)
                        await dataManager.loadFriendRequests(for: currentUserId)
                    } catch {
                        await MainActor.run {
                            print("Error accepting friend request: \(error.localizedDescription)")
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    private func getFriendlyErrorMessage(from error: Error) -> String {
        if let nsError = error as NSError? {
            switch nsError.code {
            case 404:
                return "User not found. Please check the display name."
            case 409:
                if nsError.localizedDescription.contains("already sent") {
                    return "Friend request already sent to this user."
                } else if nsError.localizedDescription.contains("Already friends") {
                    return "You are already friends with this user."
                } else {
                    return "A friend request already exists with this user."
                }
            default:
                return "Unable to send friend request. Please try again."
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Friend Request Row View
struct FriendRequestRowView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let request: FriendRequest
    let isIncoming: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isIncoming ? "Friend Request" : "Request Sent")
                    .font(.headline)
                
                Text(request.id) // In a real app, you'd fetch the user's display name
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isIncoming {
                HStack(spacing: 8) {
                    Button("Decline") {
                        Task {
                            guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
                            try? await dataManager.respondToFriendRequest(requestId: request.id, status: .declined, currentUserId: currentUserId)
                            // Refresh data after declining request
                            await dataManager.loadAllUsers(for: currentUserId)
                            await dataManager.loadFriendRequests(for: currentUserId)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    
                    Button("Accept") {
                        Task {
                            guard let currentUserId = authManager.currentUser?.id.uuidString else { return }
                            try? await dataManager.respondToFriendRequest(requestId: request.id, status: .accepted, currentUserId: currentUserId)
                            // Refresh data after accepting request
                            await dataManager.loadAllUsers(for: currentUserId)
                            await dataManager.loadFriends(for: currentUserId)
                            await dataManager.loadFriendRequests(for: currentUserId)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            } else {
                Text("Pending")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Profile View
struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userInfo: UserWithFriendshipInfo
    @State private var showingMutualFriends = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: userInfo.user.profileImageURL ?? "")) { image in
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
                    
                    VStack(spacing: 4) {
                        Text(userInfo.user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(userInfo.user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    FriendStatusButton(userInfo: userInfo)
                }
                .padding()
                
                // Mutual Friends Section
                if userInfo.mutualFriendsCount > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Mutual Friends")
                                .font(.headline)
                            Spacer()
                            Button("View All") {
                                showingMutualFriends = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(userInfo.mutualFriends.prefix(5)) { friend in
                                    VStack(spacing: 4) {
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
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        
                                        Text(friend.displayName)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                                
                                if userInfo.mutualFriendsCount > 5 {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(.systemGray4))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("+\(userInfo.mutualFriendsCount - 5)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                            )
                                        
                                        Text("More")
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Stats Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(userInfo.user.favoriteMeals.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Favorite Meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("7")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Days Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingMutualFriends) {
            MutualFriendsView(mutualFriends: userInfo.mutualFriends)
        }
    }
}

// MARK: - Mutual Friends View
struct MutualFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    let mutualFriends: [UserProfile]
    
    var body: some View {
        NavigationView {
            List(mutualFriends) { friend in
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
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.displayName)
                            .font(.headline)
                        
                        Text(friend.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Mutual Friends")
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

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DataManager())
}
