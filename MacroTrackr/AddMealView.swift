import SwiftUI
import PhotosUI
import Supabase
import AVFoundation
import Vision
import Combine

struct AddMealView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date?
    @State private var mealName = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedImage: PhotosPickerItem?
    @State private var mealImage: UIImage?
    @State private var ingredients: [String] = [""]
    @State private var cookingInstructions = ""
    @State private var macros = MacroNutrition()
    @State private var baseMacros = MacroNutrition() // Store the base macros per unit
    @State private var quantity: Double = 1.0
    @State private var showingImagePicker = false
    @State private var showingFoodScanner = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var saveAsPreset = false
    
    var body: some View {
        NavigationView {
            Form {
                mealDetailsSection
                quantitySection
                photoSection
                ingredientsSection
                cookingInstructionsSection
                nutritionInputSection
                totalNutritionSection
                saveAsPresetSection
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveMeal()
                            // Dismiss the view after successful save
                            await MainActor.run {
                                dismiss()
                            }
                        }
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
        .onChange(of: quantity) { _, _ in
            calculateTotalMacros()
        }
        .onChange(of: baseMacros) { _, _ in
            calculateTotalMacros()
        }
        .onAppear {
            calculateTotalMacros()
        }
    }
    
    // MARK: - Computed Properties for Sections
    private var mealDetailsSection: some View {
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
    }
    
    private var quantitySection: some View {
        Section("Quantity") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Quantity")
                        .font(.headline)
                    
                    Spacer()
                    
                    Stepper(value: $quantity, in: 1...100, step: 1) {
                        Text(String(format: "%.0f", quantity))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                Text(String(format: "This will multiply all nutrition values by %.0f", quantity))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var photoSection: some View {
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
                    VStack(spacing: 12) {
                        PhotosPicker(
                            selection: $selectedImage,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Choose Photo from Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showingFoodScanner = true
                        }) {
                            Label("Scan Food with AI", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
    
    private var ingredientsSection: some View {
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
    }
    
    private var cookingInstructionsSection: some View {
        Section("Cooking Instructions") {
            TextEditor(text: $cookingInstructions)
                .frame(minHeight: 100)
        }
    }
    
    private var nutritionInputSection: some View {
        Section("Nutrition Information (per unit)") {
            MacroInputField(title: "Calories", value: $baseMacros.calories, unit: "kcal")
            MacroInputField(title: "Protein", value: $baseMacros.protein, unit: "g")
            MacroInputField(title: "Carbohydrates", value: $baseMacros.carbohydrates, unit: "g")
            MacroInputField(title: "Fat", value: $baseMacros.fat, unit: "g")
            MacroInputField(title: "Sugar", value: $baseMacros.sugar, unit: "g")
            MacroInputField(title: "Fiber", value: $baseMacros.fiber, unit: "g")
        }
    }
    
    private var totalNutritionSection: some View {
        Section(String(format: "Total Nutrition (%.0f units)", quantity)) {
            HStack {
                Text("Calories")
                Spacer()
                Text("\(Int(macros.calories)) kcal")
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            HStack {
                Text("Protein")
                Spacer()
                Text("\(Int(macros.protein)) g")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            
            HStack {
                Text("Carbohydrates")
                Spacer()
                Text("\(Int(macros.carbohydrates)) g")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Fat")
                Spacer()
                Text("\(Int(macros.fat)) g")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Sugar")
                Spacer()
                Text("\(Int(macros.sugar)) g")
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
            }
            
            HStack {
                Text("Fiber")
                Spacer()
                Text("\(Int(macros.fiber)) g")
                    .fontWeight(.semibold)
                    .foregroundColor(.brown)
            }
        }
    }
    
    private var saveAsPresetSection: some View {
        Section {
            Toggle(isOn: $saveAsPreset) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save as Preset")
                        .font(.headline)
                    Text("Add to your saved meals library for quick access later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func resetForm() {
        mealName = ""
        selectedMealType = .breakfast
        mealImage = nil
        selectedImage = nil
        ingredients = [""]
        cookingInstructions = ""
        baseMacros = MacroNutrition()
        quantity = 1.0
        macros = MacroNutrition()
    }
    
    private func calculateTotalMacros() {
        macros = MacroNutrition(
            calories: baseMacros.calories * quantity,
            protein: baseMacros.protein * quantity,
            carbohydrates: baseMacros.carbohydrates * quantity,
            fat: baseMacros.fat * quantity,
            sugar: baseMacros.sugar * quantity,
            fiber: baseMacros.fiber * quantity
        )
    }
    
    private func saveMeal() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            // Upload image if present
            var imageURL: String?
            if let mealImage = mealImage {
                imageURL = try await uploadImage(mealImage)
            }
            
                // Always add to daily meals log
                let displayName = quantity == 1.0 ? mealName : String(format: "%.1f × %@", quantity, mealName)
                
                let meal = Meal(
                    id: UUID().uuidString,
                    userId: userId.uuidString,
                    name: displayName,
                    imageURL: imageURL,
                    ingredients: ingredients.filter { !$0.isEmpty },
                    cookingInstructions: cookingInstructions.isEmpty ? nil : cookingInstructions,
                    macros: macros,
                    createdAt: selectedDate ?? Date(),
                    mealType: selectedMealType
                )
            
            try await dataManager.addMeal(meal)
            
            // Optionally save as preset for future use
            if saveAsPreset {
                try await dataManager.saveMeal(meal)
            }
            
            await MainActor.run {
                isLoading = false
                resetForm()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let userId = authManager.currentUser?.id.uuidString else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        return try await dataManager.uploadImage(imageData, fileName: "\(UUID().uuidString).jpg", userId: userId)
    }
    
    private func applyScanResult(_ result: FoodScanResult) {
        // Apply scanned food results to the form
        if mealName.isEmpty {
            mealName = result.foodName
        }
        baseMacros = result.estimatedNutrition
        quantity = 1.0 // Reset to 1 unit when applying scan result
        calculateTotalMacros()
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
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isScanning {
                    Text("Scanning food...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("AI Food Scanner")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("This feature will analyze your food and estimate nutritional values")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Start Scanning") {
                            startScanning()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                if let result = scanResult {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scan Result:")
                            .font(.headline)
                        
                        Text("Food: \(result.foodName)")
                            .font(.subheadline)
                        
                        Text("Estimated Calories: \(Int(result.estimatedNutrition.calories))")
                            .font(.subheadline)
                        
                        Text("Estimated Protein: \(Int(result.estimatedNutrition.protein))g")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scan Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if scanResult != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Use Result") {
                            onScanComplete(scanResult)
                            dismiss()
                        }
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
    
    private func startScanning() {
        isScanning = true
        
        // Simulate scanning process
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Mock scan result - in real implementation, this would use Vision framework
            let mockResult = FoodScanResult(
                foodName: "Grilled Chicken Breast",
                confidence: 0.85,
                estimatedNutrition: MacroNutrition(
                    calories: 231,
                    protein: 43.5,
                    carbohydrates: 0,
                    fat: 5.0,
                    sugar: 0,
                    fiber: 0
                ),
                imageData: nil
            )
            
            isScanning = false
            scanResult = mockResult
        }
    }
}
