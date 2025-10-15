import SwiftUI
import Supabase

struct SearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var searchResults: [Meal] = []
    @State private var isLoading = false
    @State private var selectedMealType: MealType? = nil
    @State private var showingAddConfirmation = false
    @State private var confirmationMessage = ""
    @State private var editingMeal: Meal? = nil
    
    var sortedResults: [Meal] {
        var results = searchResults
        
        // Filter by meal type if selected
        if let mealType = selectedMealType {
            results = results.filter { $0.mealType == mealType }
        }
        
        // Sort: favorites first, then by name
        return results.sorted { meal1, meal2 in
            if meal1.isFavorite != meal2.isFavorite {
                return meal1.isFavorite
            }
            return meal1.name < meal2.name
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search meals, ingredients...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SearchFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Meal Type Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedMealType == nil) {
                            selectedMealType = nil
                            performSearch()
                        }
                        ForEach(MealType.allCases, id: \.self) { type in
                            FilterChip(title: type.displayName, isSelected: selectedMealType == type) {
                                selectedMealType = type
                                performSearch()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Search Results
                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try different keywords or check your spelling")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Search Your Meals")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Find previous meals by name, ingredients, or nutrition info")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        // Favorites Section
                        let favorites = sortedResults.filter { $0.isFavorite }
                        if !favorites.isEmpty {
                            Section(header: Text("Favorites ⭐").font(.headline)) {
                                ForEach(favorites) { meal in
                                    SearchResultRow(meal: meal, onAddToToday: {
                                        addMealToToday(meal)
                                    }, onEdit: {
                                        editingMeal = meal
                                    }, onToggleFavorite: {
                                        toggleFavorite(meal)
                                    })
                                }
                            }
                        }
                        
                        // Regular Meals Section
                        let regularMeals = sortedResults.filter { !$0.isFavorite }
                        if !regularMeals.isEmpty {
                            Section(header: favorites.isEmpty ? nil : Text("Other Meals").font(.headline)) {
                                ForEach(regularMeals) { meal in
                                    SearchResultRow(meal: meal, onAddToToday: {
                                        addMealToToday(meal)
                                    }, onEdit: {
                                        editingMeal = meal
                                    }, onToggleFavorite: {
                                        toggleFavorite(meal)
                                    })
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .overlay(
                // Confirmation Toast
                VStack {
                    if showingAddConfirmation {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(confirmationMessage)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .animation(.spring(), value: showingAddConfirmation)
            )
        }
        .sheet(item: $editingMeal) { meal in
            EditMealView(meal: meal)
                .onDisappear {
                    performSearch() // Refresh results after editing
                }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                searchResults = dataManager.savedMeals
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            if !searchText.isEmpty {
                performSearch()
            }
        }
        .onAppear {
            // Load saved meals when view appears
            if let userId = authManager.currentUser?.id.uuidString {
                Task {
                    await dataManager.loadSavedMeals(for: userId)
                    await MainActor.run {
                        if searchText.isEmpty {
                            searchResults = dataManager.savedMeals
                        }
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        Task {
            do {
                guard let userId = authManager.currentUser?.id.uuidString else {
                    await MainActor.run {
                        self.searchResults = []
                        self.isLoading = false
                    }
                    return
                }
                
                let results = try await dataManager.searchMeals(query: searchText, filter: selectedFilter, userId: userId)
                
                await MainActor.run {
                    self.searchResults = results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isLoading = false
                }
                print("Search error: \(error)")
            }
        }
    }
    
    
    private func addMealToToday(_ meal: Meal) {
        guard let userId = authManager.currentUser?.id else { return }
        
        let todayMeal = Meal(
            id: UUID().uuidString,
            userId: userId.uuidString,
            name: meal.name,
            imageURL: meal.imageURL,
            ingredients: meal.ingredients,
            cookingInstructions: meal.cookingInstructions,
            macros: meal.macros,
            createdAt: Date(),
            mealType: meal.mealType
        )
        
        Task {
            try? await dataManager.addMeal(todayMeal)
            await MainActor.run {
                confirmationMessage = "\(meal.name) added to today!"
                showingAddConfirmation = true
                
                // Auto-dismiss after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingAddConfirmation = false
                }
            }
        }
    }
    
    private func toggleFavorite(_ meal: Meal) {
        Task {
            var updatedMeal = meal
            updatedMeal.isFavorite.toggle()
            try? await dataManager.updateMeal(updatedMeal)
            
            // Refresh search results
            performSearch()
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}


// MARK: - Search Result Row
struct SearchResultRow: View {
    let meal: Meal
    let onAddToToday: () -> Void
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Meal Image
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
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Meal Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if meal.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(meal.mealType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !meal.ingredients.isEmpty {
                    Text(meal.ingredients.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    MacroBadge(label: "Cal", value: "\(Int(meal.macros.calories))", color: .orange)
                    MacroBadge(label: "P", value: "\(Int(meal.macros.protein))g", color: .red)
                    MacroBadge(label: "C", value: "\(Int(meal.macros.carbohydrates))g", color: .blue)
                    MacroBadge(label: "F", value: "\(Int(meal.macros.fat))g", color: .green)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                // Favorite Button
                Button(action: onToggleFavorite) {
                    Image(systemName: meal.isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(meal.isFavorite ? .yellow : .gray)
                }
                
                // Edit Button
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                // Add to Today Button
                Button(action: onAddToToday) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView()
        .environmentObject(DataManager())
        .environmentObject(AuthenticationManager())
}
