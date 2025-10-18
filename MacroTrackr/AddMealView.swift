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
    @State private var ingredientMacros: [MacroNutrition] = [MacroNutrition()]
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
    @State private var showingIngredientPicker = false
    @State private var calculateMacrosFromIngredients = false
    @State private var searchText = ""
    @State private var showingBarcodeScanner = false
    @State private var isRecognizingFood = false
    @State private var quantityText = ""
    @FocusState private var isQuantityFocused: Bool
    
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
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(
                onBarcodeScanned: { barcode in
                    Task {
                        await handleBarcodeScan(barcode)
                    }
                },
                onDismiss: {
                    showingBarcodeScanner = false
                }
            )
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
                        self.isRecognizingFood = true
                    }
                    
                    // Use Core ML to recognize food in the image
                    await recognizeFoodInImage(image)
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
            updateQuantityTextFromValue()
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
                    
                    HStack(spacing: 4) {
                        TextField("1", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($isQuantityFocused)
                            .onTapGesture {
                                if quantity == 1.0 {
                                    quantityText = ""
                                }
                            }
                            .onChange(of: quantityText) { _, newValue in
                                if let doubleValue = Double(newValue) {
                                    quantity = doubleValue
                                    calculateTotalMacros()
                                } else if newValue.isEmpty {
                                    quantity = 1.0
                                    calculateTotalMacros()
                                }
                            }
                            .onChange(of: isQuantityFocused) { _, focused in
                                if focused && quantity == 1.0 {
                                    quantityText = ""
                                } else if !focused && quantityText.isEmpty {
                                    quantity = 1.0
                                    calculateTotalMacros()
                                }
                            }
                            .onChange(of: quantity) { _, newValue in
                                if !isQuantityFocused {
                                    updateQuantityTextFromValue()
                                }
                            }
                            .onAppear {
                                updateQuantityTextFromValue()
                            }
                        
                        Text("serving\(quantity == 1.0 ? "" : "s")")
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                    }
                }
                
                Text(String(format: "This will multiply all nutrition values by %.1f", quantity))
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
                        
                        Button(action: {
                            showingBarcodeScanner = true
                        }) {
                            Label("Scan Barcode", systemImage: "barcode.viewfinder")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
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
            // Macro calculation toggle
            Toggle("Calculate macros from ingredients", isOn: $calculateMacrosFromIngredients)
            
            ForEach(ingredients.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Ingredient \(index + 1)", text: $ingredients[index])
                        Button(action: {
                            showingIngredientPicker = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                        }
                        
                        if ingredients.count > 1 {
                            Button(action: {
                                ingredients.remove(at: index)
                                if ingredientMacros.count > index {
                                    ingredientMacros.remove(at: index)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if calculateMacrosFromIngredients && !ingredients[index].isEmpty && index < ingredientMacros.count {
                        Text("Ingredient macros (per serving):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Calories", value: Binding(
                                get: { index < ingredientMacros.count ? ingredientMacros[index].calories : 0 },
                                set: { if index < ingredientMacros.count { ingredientMacros[index].calories = $0 } }
                            ), format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            TextField("Protein", value: Binding(
                                get: { index < ingredientMacros.count ? ingredientMacros[index].protein : 0 },
                                set: { if index < ingredientMacros.count { ingredientMacros[index].protein = $0 } }
                            ), format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            TextField("Carbs", value: Binding(
                                get: { index < ingredientMacros.count ? ingredientMacros[index].carbohydrates : 0 },
                                set: { if index < ingredientMacros.count { ingredientMacros[index].carbohydrates = $0 } }
                            ), format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            TextField("Fat", value: Binding(
                                get: { index < ingredientMacros.count ? ingredientMacros[index].fat : 0 },
                                set: { if index < ingredientMacros.count { ingredientMacros[index].fat = $0 } }
                            ), format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }
            
            Button(action: {
                ingredients.append("")
                ingredientMacros.append(MacroNutrition())
            }) {
                Label("Add Ingredient", systemImage: "plus.circle")
                    .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showingIngredientPicker) {
            IngredientPickerView(
                searchText: $searchText,
                onIngredientSelected: { ingredient in
                    // Track this ingredient as recently used
                    dataManager.addRecentIngredient(ingredient)
                    
                    if let lastIndex = ingredients.lastIndex(where: { $0.isEmpty }) {
                        ingredients[lastIndex] = ingredient.name
                        // Ensure ingredientMacros array is large enough
                        if lastIndex < ingredientMacros.count {
                            ingredientMacros[lastIndex] = ingredient.macros
                        } else {
                            // Pad with empty macros if needed
                            while ingredientMacros.count <= lastIndex {
                                ingredientMacros.append(MacroNutrition())
                            }
                            ingredientMacros[lastIndex] = ingredient.macros
                        }
                    } else {
                        ingredients.append(ingredient.name)
                        ingredientMacros.append(ingredient.macros)
                    }
                    showingIngredientPicker = false
                }
            )
        }
        .onChange(of: calculateMacrosFromIngredients) { _, _ in
            updateMacrosFromIngredients()
        }
        .onChange(of: ingredientMacros) { _, _ in
            if calculateMacrosFromIngredients {
                updateMacrosFromIngredients()
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
        Group {
            if !calculateMacrosFromIngredients {
                Section("Nutrition Information (per unit)") {
                    MacroInputField(title: "Calories", value: $baseMacros.calories, unit: "kcal")
                    MacroInputField(title: "Protein", value: $baseMacros.protein, unit: "g")
                    MacroInputField(title: "Carbohydrates", value: $baseMacros.carbohydrates, unit: "g")
                    MacroInputField(title: "Fat", value: $baseMacros.fat, unit: "g")
                    MacroInputField(title: "Sugar", value: $baseMacros.sugar, unit: "g")
                    MacroInputField(title: "Fiber", value: $baseMacros.fiber, unit: "g")
                }
            }
        }
    }
    
    private var totalNutritionSection: some View {
        Section(String(format: "Total Nutrition (%.1f servings)", quantity)) {
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
        ingredientMacros = [MacroNutrition()]
        cookingInstructions = ""
        baseMacros = MacroNutrition()
        quantity = 1.0
        quantityText = ""
        macros = MacroNutrition()
        calculateMacrosFromIngredients = false
    }
    
    private func calculateTotalMacros() {
        if calculateMacrosFromIngredients {
            updateMacrosFromIngredients()
        } else {
            macros = MacroNutrition(
                calories: baseMacros.calories * quantity,
                protein: baseMacros.protein * quantity,
                carbohydrates: baseMacros.carbohydrates * quantity,
                fat: baseMacros.fat * quantity,
                sugar: baseMacros.sugar * quantity,
                fiber: baseMacros.fiber * quantity
            )
        }
    }
    
    private func updateMacrosFromIngredients() {
        let totalIngredientMacros = ingredientMacros.reduce(MacroNutrition()) { total, ingredientMacro in
            MacroNutrition(
                calories: total.calories + ingredientMacro.calories,
                protein: total.protein + ingredientMacro.protein,
                carbohydrates: total.carbohydrates + ingredientMacro.carbohydrates,
                fat: total.fat + ingredientMacro.fat,
                sugar: total.sugar + ingredientMacro.sugar,
                fiber: total.fiber + ingredientMacro.fiber
            )
        }
        
        macros = MacroNutrition(
            calories: totalIngredientMacros.calories * quantity,
            protein: totalIngredientMacros.protein * quantity,
            carbohydrates: totalIngredientMacros.carbohydrates * quantity,
            fat: totalIngredientMacros.fat * quantity,
            sugar: totalIngredientMacros.sugar * quantity,
            fiber: totalIngredientMacros.fiber * quantity
        )
    }
    
    private func updateQuantityTextFromValue() {
        if quantity == 1.0 {
            quantityText = ""
        } else {
            // Handle both integers and decimals properly
            if quantity.truncatingRemainder(dividingBy: 1) == 0 {
                quantityText = String(format: "%.0f", quantity)
            } else {
                quantityText = String(format: "%.1f", quantity)
            }
        }
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
        updateQuantityTextFromValue()
        calculateTotalMacros()
    }
    
    private func handleBarcodeScan(_ barcode: String) async {
        isLoading = true
        showingBarcodeScanner = false
        
        do {
            if let barcodeResult = await dataManager.lookupBarcode(barcode) {
                await MainActor.run {
                    // Apply barcode scan results to the form
                    if mealName.isEmpty {
                        mealName = barcodeResult.productName
                    }
                    
                    // Use nutrition per 100g as base macros
                    baseMacros = barcodeResult.nutrition
                    quantity = 1.0
                    updateQuantityTextFromValue()
                    calculateTotalMacros()
                    
                    isLoading = false
                    
                    // Show success message
                    alertMessage = "Product found: \(barcodeResult.productName)"
                    showingAlert = true
                }
            } else {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Product not found in database"
                    showingAlert = true
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertMessage = "Error looking up product: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func recognizeFoodInImage(_ image: UIImage) async {
        // Use the advanced recognizer that can work with custom models
        let advancedRecognizer = AdvancedCoreMLFoodRecognizer()
        
        advancedRecognizer.recognizeFoodAdvanced(in: image) { foodName, confidence, nutrition in
            Task { @MainActor in
                self.isRecognizingFood = false
                
                if confidence > 0.3 { // Only apply if confidence is reasonable
                    if self.mealName.isEmpty {
                        self.mealName = foodName
                    }
                    
                    // Use provided nutrition or estimate if not available
                    let estimatedNutrition = nutrition ?? MacroNutrition(
                        calories: estimateCalories(for: foodName),
                        protein: estimateProtein(for: foodName),
                        carbohydrates: estimateCarbs(for: foodName),
                        fat: estimateFat(for: foodName),
                        sugar: estimateCarbs(for: foodName) * 0.3,
                        fiber: estimateCarbs(for: foodName) * 0.1
                    )
                    
                    // Update base macros if they're currently empty
                    if self.baseMacros.calories == 0 && self.baseMacros.protein == 0 && 
                       self.baseMacros.carbohydrates == 0 && self.baseMacros.fat == 0 {
                        self.baseMacros = estimatedNutrition
                        self.calculateTotalMacros()
                    }
                    
                    // Show success message with confidence and model info
                    let confidencePercentage = Int(confidence * 100)
                    let modelInfo = advancedRecognizer.isModelLoaded ? " (Custom Model)" : " (Vision Framework)"
                    self.alertMessage = "Recognized: \(foodName) (\(confidencePercentage)% confidence\(modelInfo))\nEstimated nutrition applied."
                    self.showingAlert = true
                } else {
                    // Low confidence - just set name if empty
                    if self.mealName.isEmpty {
                        self.mealName = foodName
                    }
                    self.alertMessage = "Recognized: \(foodName) (low confidence)\nPlease verify and adjust nutrition values."
                    self.showingAlert = true
                }
            }
        }
    }
}

// MARK: - Macro Input Field
struct MacroInputField: View {
    let title: String
    @Binding var value: Double
    let unit: String
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: $textValue)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .focused($isFocused)
                    .onTapGesture {
                        if value == 0 {
                            textValue = ""
                        }
                    }
                    .onChange(of: textValue) { _, newValue in
                        // Update the binding value when text changes
                        if let doubleValue = Double(newValue) {
                            value = doubleValue
                        } else if newValue.isEmpty {
                            value = 0
                        }
                    }
                    .onChange(of: isFocused) { _, focused in
                        if focused && value == 0 {
                            textValue = ""
                        }
                    }
                    .onAppear {
                        updateTextFromValue()
                    }
                    .onChange(of: value) { _, newValue in
                        if !isFocused {
                            updateTextFromValue()
                        }
                    }
                
                Text(unit)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
            }
        }
    }
    
    private func updateTextFromValue() {
        if value == 0 {
            textValue = ""
        } else {
            // Handle both integers and decimals properly
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                textValue = String(format: "%.0f", value)
            } else {
                textValue = String(format: "%.1f", value)
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

// MARK: - Ingredient Picker View
struct IngredientPickerView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var searchText: String
    let onIngredientSelected: (Ingredient) -> Void
    
    @State private var filteredIngredients: [Ingredient] = []
    @State private var selectedCategory: IngredientCategory? = nil
    @State private var isSearchingOnline = false
    @State private var onlineSearchResults: [Ingredient] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search ingredients...", text: $searchText)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            Task {
                                await searchOnline()
                            }
                        }) {
                            if isSearchingOnline {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                            }
                        }
                        .disabled(isSearchingOnline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("All") {
                            selectedCategory = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(20)
                        
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                selectedCategory = category
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Ingredients list
                List {
                    // Recent ingredients (show when not searching)
                    if searchText.isEmpty {
                        let recentIngredients = dataManager.getRecentIngredients()
                        if !recentIngredients.isEmpty {
                            Section("Recently Used") {
                                ForEach(recentIngredients) { ingredient in
                                    ingredientRow(ingredient)
                                }
                            }
                        }
                    }
                    
                    // Local ingredients
                    if !filteredIngredients.isEmpty {
                        Section("Local Ingredients") {
                            ForEach(filteredIngredients) { ingredient in
                                ingredientRow(ingredient)
                            }
                        }
                    }
                    
                    // Online search results
                    if !onlineSearchResults.isEmpty {
                        Section("Online Results") {
                            ForEach(onlineSearchResults) { ingredient in
                                ingredientRow(ingredient)
                            }
                        }
                    }
                    
                    // Empty state
                    if filteredIngredients.isEmpty && onlineSearchResults.isEmpty && !searchText.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No ingredients found")
                                    .foregroundColor(.secondary)
                                Text("Try searching online or use a different term")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Select Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await dataManager.loadIngredients()
                    updateFilteredIngredients()
                }
            }
            .onChange(of: searchText) { _, _ in
                updateFilteredIngredients()
                // Clear online results when search text changes
                if onlineSearchResults.isEmpty {
                    // Only clear if we haven't loaded online results yet
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                updateFilteredIngredients()
            }
        }
    }
    
    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        Button(action: {
            onIngredientSelected(ingredient)
        }) {
            HStack {
                Text(ingredient.category.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("\(Int(ingredient.macros.calories)) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(ingredient.macros.protein))g protein")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(ingredient.macros.carbohydrates))g carbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(ingredient.macros.fat))g fat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func updateFilteredIngredients() {
        var ingredients = dataManager.ingredients
        
        if !searchText.isEmpty {
            ingredients = dataManager.searchIngredients(query: searchText)
        }
        
        if let category = selectedCategory {
            ingredients = ingredients.filter { $0.category == category }
        }
        
        filteredIngredients = ingredients
        
        // Clear online results when updating local filter
        if searchText.isEmpty {
            onlineSearchResults = []
        }
    }
    
    private func searchOnline() async {
        guard !searchText.isEmpty else { return }
        
        isSearchingOnline = true
        
        do {
            let results = await dataManager.searchUSDAFoods(query: searchText)
            await MainActor.run {
                onlineSearchResults = results.filter { result in
                    // Avoid duplicates with local ingredients
                    !filteredIngredients.contains { $0.name.lowercased() == result.name.lowercased() }
                }
                isSearchingOnline = false
            }
        } catch {
            await MainActor.run {
                isSearchingOnline = false
            }
        }
    }
}
