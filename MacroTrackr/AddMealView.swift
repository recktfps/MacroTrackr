import SwiftUI
import PhotosUI
import Supabase

struct AddMealView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var mealName = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedImage: PhotosPickerItem?
    @State private var mealImage: UIImage?
    @State private var ingredients: [String] = [""]
    @State private var cookingInstructions = ""
    @State private var macros = MacroNutrition()
    @State private var showingImagePicker = false
    @State private var showingFoodScanner = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Details") {
                    TextField("Meal Name", text: $mealName)
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Photo") {
                    VStack(spacing: 16) {
                        if let mealImage = mealImage {
                            Image(uiImage: mealImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    Button("Remove") {
                                        self.mealImage = nil
                                    }
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(8),
                                    alignment: .topTrailing
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                        Text("Add Photo")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        
                        HStack(spacing: 16) {
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Label("Choose Photo", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showingFoodScanner = true
                            }) {
                                Label("AI Estimator", systemImage: "camera.viewfinder")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .onChange(of: selectedImage) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                self.mealImage = image
                            }
                        }
                    }
                }
                
                Section("Ingredients") {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            TextField("Ingredient \(index + 1)", text: $ingredients[index])
                            
                            if ingredients.count > 1 {
                                Button(action: {
                                    ingredients.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        ingredients.append("")
                    }) {
                        Label("Add Ingredient", systemImage: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Cooking Instructions") {
                    TextEditor(text: $cookingInstructions)
                        .frame(minHeight: 100)
                }
                
                Section("Nutrition Information") {
                    MacroInputField(title: "Calories", value: $macros.calories, unit: "kcal")
                    MacroInputField(title: "Protein", value: $macros.protein, unit: "g")
                    MacroInputField(title: "Carbohydrates", value: $macros.carbohydrates, unit: "g")
                    MacroInputField(title: "Fat", value: $macros.fat, unit: "g")
                    MacroInputField(title: "Sugar", value: $macros.sugar, unit: "g")
                    MacroInputField(title: "Fiber", value: $macros.fiber, unit: "g")
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        resetForm()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .disabled(mealName.isEmpty || isLoading)
                }
            }
        }
        .sheet(isPresented: $showingFoodScanner) {
            FoodScannerView { scanResult in
                if let result = scanResult {
                    applyScanResult(result)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func resetForm() {
        mealName = ""
        selectedMealType = .breakfast
        mealImage = nil
        selectedImage = nil
        ingredients = [""]
        cookingInstructions = ""
        macros = MacroNutrition()
    }
    
    private func saveMeal() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        Task {
            do {
                // Upload image if present
                var imageURL: String?
                if let mealImage = mealImage {
                    imageURL = try await uploadImage(mealImage)
                }
                
                let meal = Meal(
                    id: UUID().uuidString,
                    userId: userId.uuidString,
                    name: mealName,
                    imageURL: imageURL,
                    ingredients: ingredients.filter { !$0.isEmpty },
                    cookingInstructions: cookingInstructions.isEmpty ? nil : cookingInstructions,
                    macros: macros,
                    createdAt: Date(),
                    mealType: selectedMealType
                )
                
                try await dataManager.addMeal(meal)
                
                await MainActor.run {
                    resetForm()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        // In a real app, you would upload to Supabase Storage or another service
        // For now, we'll return a placeholder URL
        return "https://example.com/meal-image.jpg"
    }
    
    private func applyScanResult(_ result: FoodScanResult) {
        // Apply scanned food results to the form
        if mealName.isEmpty {
            mealName = result.foodName
        }
        macros = result.estimatedNutrition
    }
}

// MARK: - Macro Input Field
struct MacroInputField: View {
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

// MARK: - Food Scanner View
struct FoodScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onScanComplete: (FoodScanResult?) -> Void
    @State private var isScanning = false
    @State private var scanResult: FoodScanResult?
    
    var body: some View {
        NavigationView {
            VStack {
                if isScanning {
                    CameraView { result in
                        scanResult = result
                        isScanning = false
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Food Scanner")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Point your camera at food to automatically detect and estimate nutrition information")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Start Scanning") {
                            isScanning = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
                
                if let result = scanResult {
                    ScanResultView(result: result) {
                        onScanComplete(result)
                        dismiss()
                    } onCancel: {
                        onScanComplete(nil)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Scan Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onScanComplete(nil)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Camera View (Placeholder)
struct CameraView: View {
    let onResult: (FoodScanResult) -> Void
    
    var body: some View {
        VStack {
            Text("Camera View")
                .font(.title)
            
            Text("In a real implementation, this would show the camera preview and use Vision framework to detect food")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Simulate Scan") {
                // Simulate a scan result
                let mockResult = FoodScanResult(
                    foodName: "Chicken Breast",
                    confidence: 0.85,
                    estimatedNutrition: MacroNutrition(calories: 165, protein: 31, carbohydrates: 0, fat: 3.6, sugar: 0, fiber: 0)
                )
                onResult(mockResult)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(.white)
    }
}

// MARK: - Scan Result View
struct ScanResultView: View {
    let result: FoodScanResult
    let onAccept: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scan Results")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(result.foodName)
                        .font(.headline)
                    Spacer()
                    Text("\(Int(result.confidence * 100))% confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Estimated nutrition")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    MacroBadge(label: "Calories", value: "\(Int(result.estimatedNutrition.calories))", color: .orange)
                    MacroBadge(label: "Protein", value: "\(Int(result.estimatedNutrition.protein))g", color: .red)
                    MacroBadge(label: "Carbs", value: "\(Int(result.estimatedNutrition.carbohydrates))g", color: .blue)
                    MacroBadge(label: "Fat", value: "\(Int(result.estimatedNutrition.fat))g", color: .green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Use This Data") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

#Preview {
    AddMealView()
        .environmentObject(DataManager())
        .environmentObject(AuthenticationManager())
}
