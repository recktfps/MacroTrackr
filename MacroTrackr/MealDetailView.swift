import SwiftUI

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    @State private var isFavorite = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Meal Image
                    if let imageURL = meal.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Meal Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(meal.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button(action: {
                                    isFavorite.toggle()
                                    // Update favorite status
                                }) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .font(.title2)
                                        .foregroundColor(isFavorite ? .red : .secondary)
                                }
                            }
                            
                            HStack {
                                Image(systemName: meal.mealType.icon)
                                    .foregroundColor(.blue)
                                Text(meal.mealType.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(DateFormatter.mealDetailFormatter.string(from: meal.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Macro Information
                        MacroDetailSection(macros: meal.macros)
                        
                        // Ingredients Section
                        if !meal.ingredients.isEmpty {
                            IngredientsSection(ingredients: meal.ingredients)
                        }
                        
                        // Cooking Instructions Section
                        if let instructions = meal.cookingInstructions, !instructions.isEmpty {
                            CookingInstructionsSection(instructions: instructions)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit") {
                            showingEditView = true
                        }
                        
                        Button("Add to Today") {
                            addToToday()
                        }
                        
                        Button("Share") {
                            showingShareSheet = true
                        }
                        
                        Button("Save as Favorite") {
                            saveAsFavorite()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            isFavorite = meal.isFavorite
        }
        .sheet(isPresented: $showingEditView) {
            EditMealView(meal: meal)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(meal: meal)
        }
    }
    
    private func addToToday() {
        guard let userId = meal.userId as String? else { return }
        
        let todayMeal = Meal(
            id: UUID().uuidString,
            userId: userId,
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
    
    private func saveAsFavorite() {
        Task {
            try? await dataManager.saveMeal(meal)
        }
    }
}

// MARK: - Macro Detail Section
struct MacroDetailSection: View {
    let macros: MacroNutrition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MacroDetailCard(
                    title: "Calories",
                    value: macros.calories,
                    unit: "kcal",
                    color: .orange
                )
                
                MacroDetailCard(
                    title: "Protein",
                    value: macros.protein,
                    unit: "g",
                    color: .red
                )
                
                MacroDetailCard(
                    title: "Carbs",
                    value: macros.carbohydrates,
                    unit: "g",
                    color: .blue
                )
                
                MacroDetailCard(
                    title: "Fat",
                    value: macros.fat,
                    unit: "g",
                    color: .green
                )
                
                MacroDetailCard(
                    title: "Sugar",
                    value: macros.sugar,
                    unit: "g",
                    color: .pink
                )
                
                MacroDetailCard(
                    title: "Fiber",
                    value: macros.fiber,
                    unit: "g",
                    color: .brown
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Macro Detail Card
struct MacroDetailCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(Int(value))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Ingredients Section
struct IngredientsSection: View {
    let ingredients: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(ingredients.indices, id: \.self) { index in
                HStack {
                    Text("•")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    
                    Text(ingredients[index])
                        .font(.body)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Cooking Instructions Section
struct CookingInstructionsSection: View {
    let instructions: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cooking Instructions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(instructions)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Edit Meal View
struct EditMealView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var editedMeal: Meal
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(meal: Meal) {
        self.meal = meal
        self._editedMeal = State(initialValue: meal)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Details") {
                    TextField("Meal Name", text: $editedMeal.name)
                    
                    Picker("Meal Type", selection: $editedMeal.mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("Ingredients") {
                    ForEach(editedMeal.ingredients.indices, id: \.self) { index in
                        TextField("Ingredient \(index + 1)", text: $editedMeal.ingredients[index])
                    }
                }
                
                Section("Cooking Instructions") {
                    TextEditor(text: Binding(
                        get: { editedMeal.cookingInstructions ?? "" },
                        set: { editedMeal.cookingInstructions = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                }
                
                Section("Nutrition") {
                    MacroInputField(title: "Calories", value: $editedMeal.macros.calories, unit: "kcal")
                    MacroInputField(title: "Protein", value: $editedMeal.macros.protein, unit: "g")
                    MacroInputField(title: "Carbs", value: $editedMeal.macros.carbohydrates, unit: "g")
                    MacroInputField(title: "Fat", value: $editedMeal.macros.fat, unit: "g")
                    MacroInputField(title: "Sugar", value: $editedMeal.macros.sugar, unit: "g")
                    MacroInputField(title: "Fiber", value: $editedMeal.macros.fiber, unit: "g")
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveChanges() {
        // In a real implementation, this would update the meal in the database
        dismiss()
    }
}

// MARK: - Share Sheet
struct ShareSheet: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Meal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    if let imageURL = meal.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meal.name)
                            .font(.headline)
                        
                        Text("\(Int(meal.macros.calories)) kcal • \(Int(meal.macros.protein))g protein")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(spacing: 12) {
                    ShareButton(
                        title: "Share to Social Media",
                        icon: "square.and.arrow.up",
                        color: .blue
                    ) {
                        // Share to social media
                    }
                    
                    ShareButton(
                        title: "Copy Recipe",
                        icon: "doc.on.doc",
                        color: .green
                    ) {
                        // Copy recipe text
                    }
                    
                    ShareButton(
                        title: "Send to Friend",
                        icon: "person.2.fill",
                        color: .purple
                    ) {
                        // Send to friend
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share")
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

// MARK: - Share Button
struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
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

// MARK: - Date Formatter
extension DateFormatter {
    static let mealDetailFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    MealDetailView(meal: Meal(
        id: "1",
        userId: "user1",
        name: "Grilled Chicken Breast",
        imageURL: nil,
        ingredients: ["Chicken breast", "Olive oil", "Salt", "Pepper"],
        cookingInstructions: "Season chicken with salt and pepper. Heat olive oil in pan. Cook chicken for 6-7 minutes per side until golden brown and cooked through.",
        macros: MacroNutrition(calories: 165, protein: 31, carbohydrates: 0, fat: 3.6, sugar: 0, fiber: 0),
        createdAt: Date(),
        mealType: .dinner
    ))
    .environmentObject(DataManager())
}
