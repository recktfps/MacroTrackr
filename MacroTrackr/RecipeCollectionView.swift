import SwiftUI
import Supabase

// MARK: - Recipe Collection View
struct RecipeCollectionView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Recipe View", selection: $selectedTab) {
                    Text("Community").tag(0)
                    Text("My Recipes").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    CommunityRecipesView()
                } else {
                    MyRecipesView()
                }
                
                Spacer()
            }
            .navigationTitle("Recipe Collections")
            .onAppear {
                Task {
                    await dataManager.loadPublicRecipes()
                    if let userId = authManager.currentUser?.id.uuidString {
                        await dataManager.loadUserRecipes(for: userId)
                    }
                }
            }
        }
    }
}

// MARK: - Community Recipes View
struct CommunityRecipesView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List(dataManager.publicRecipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                RecipeRowView(recipe: recipe)
            }
        }
        .refreshable {
            await dataManager.loadPublicRecipes()
        }
    }
}

// MARK: - My Recipes View
struct MyRecipesView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        List(dataManager.userRecipes) { recipe in
            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                RecipeRowView(recipe: recipe)
            }
        }
    }
}

// MARK: - Recipe Row View
struct RecipeRowView: View {
    let recipe: RecipeCollection
    
    var body: some View {
        HStack {
            // Recipe image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Text("📷")
                        .font(.title)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = recipe.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(recipe.servingSize) servings")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(recipe.macros.calories)) cal")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    let recipe: RecipeCollection
    @State private var userRating: Int = 0
    @State private var review: String = ""
    @State private var showingRatingSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Text("📷")
                            .font(.system(size: 60))
                    )
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let description = recipe.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("\(recipe.servingSize) servings", systemImage: "person.2")
                            Spacer()
                            if let prepTime = recipe.prepTime {
                                Label("\(prepTime) min prep", systemImage: "clock")
                            }
                            if let cookTime = recipe.cookTime {
                                Label("\(cookTime) min cook", systemImage: "timer")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Nutrition info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrition (per serving)")
                            .font(.headline)
                        
                        HStack {
                            VStack {
                                Text("\(Int(recipe.macros.calories))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("Calories")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(Int(recipe.macros.protein))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                Text("Protein")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(Int(recipe.macros.carbohydrates))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Carbs")
                                    .font(.caption2)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("\(Int(recipe.macros.fat))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Fat")
                                    .font(.caption2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            HStack {
                                Text("•")
                                    .foregroundColor(.blue)
                                Text(ingredient)
                                Spacer()
                            }
                        }
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        
                        ForEach(recipe.instructions.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text(recipe.instructions[index])
                                Spacer()
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    
                    // Rating section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rate This Recipe")
                            .font(.headline)
                        
                        Button("Leave Rating & Review") {
                            showingRatingSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRatingSheet) {
            RecipeRatingSheet(recipe: recipe, userRating: $userRating, review: $review)
        }
    }
}

// MARK: - Recipe Rating Sheet
struct RecipeRatingSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    let recipe: RecipeCollection
    @Binding var userRating: Int
    @Binding var review: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Rate \(recipe.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack {
                    Text("Rating")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                userRating = star
                            }) {
                                Image(systemName: star <= userRating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Review (Optional)")
                        .font(.headline)
                    
                    TextEditor(text: $review)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.3), width: 1)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            if let userId = authManager.currentUser?.id.uuidString {
                                try? await dataManager.rateRecipe(
                                    recipeId: recipe.id,
                                    userId: userId,
                                    rating: userRating,
                                    review: review.isEmpty ? nil : review
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(userRating == 0)
                }
            }
        }
    }
}
