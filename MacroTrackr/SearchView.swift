import SwiftUI
import Supabase

struct SearchView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var searchResults: [Meal] = []
    @State private var isLoading = false
    
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
                    List(searchResults) { meal in
                        SearchResultRow(meal: meal) {
                            addMealToToday(meal)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                searchResults = []
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            if !searchText.isEmpty {
                performSearch()
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
        }
    }
}


// MARK: - Search Result Row
struct SearchResultRow: View {
    let meal: Meal
    let onAddToToday: () -> Void
    
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
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
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
            
            // Add to Today Button
            Button(action: onAddToToday) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
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
