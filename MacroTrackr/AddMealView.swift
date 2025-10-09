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
    @State private var showingImagePicker = false
    @State private var showingFoodScanner = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var saveAsPreset = false
    
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
                            dismiss()
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
                let meal = Meal(
                    id: UUID().uuidString,
                    userId: userId.uuidString,
                    name: mealName,
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

// MARK: - Camera View
struct CameraView: View {
    let onResult: (FoodScanResult) -> Void
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
            
            // Overlay with scanning UI
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Point camera at food")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    
                    HStack(spacing: 20) {
                        Button("Capture & Analyze") {
                            captureAndAnalyze()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Simulate") {
                            simulateScan()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
    }
    
    private func captureAndAnalyze() {
        cameraManager.capturePhoto { image in
            if let image = image {
                analyzeFood(image: image)
            }
        }
    }
    
    private func simulateScan() {
        // Simulate a scan result with random food
        let foods = [
            ("Chicken Breast", MacroNutrition(calories: 165, protein: 31, carbohydrates: 0, fat: 3.6, sugar: 0, fiber: 0)),
            ("Apple", MacroNutrition(calories: 95, protein: 0.5, carbohydrates: 25, fat: 0.3, sugar: 19, fiber: 4)),
            ("Salmon", MacroNutrition(calories: 206, protein: 22, carbohydrates: 0, fat: 12, sugar: 0, fiber: 0)),
            ("Rice", MacroNutrition(calories: 130, protein: 2.7, carbohydrates: 28, fat: 0.3, sugar: 0, fiber: 0.4)),
            ("Broccoli", MacroNutrition(calories: 55, protein: 4.3, carbohydrates: 11, fat: 0.6, sugar: 2.6, fiber: 5.1))
        ]
        
        let randomFood = foods.randomElement()!
        let mockResult = FoodScanResult(
            foodName: randomFood.0,
            confidence: Double.random(in: 0.7...0.95),
            estimatedNutrition: randomFood.1
        )
        onResult(mockResult)
    }
    
    private func analyzeFood(image: UIImage) {
        // In a real implementation, this would use Vision framework
        // For now, we'll simulate with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let mockResult = FoodScanResult(
                foodName: "Detected Food",
                confidence: 0.82,
                estimatedNutrition: MacroNutrition(calories: 200, protein: 15, carbohydrates: 30, fat: 8, sugar: 5, fiber: 3)
            )
            onResult(mockResult)
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var isSessionRunning = false
    private var photoCompletion: ((UIImage?) -> Void)?
    
    // ObservableObject requirement
    @Published var isSessionActive = false
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(videoDeviceInput)
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.startSession()
                }
            }
        }
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            self.isSessionRunning = true
            DispatchQueue.main.async {
                self.isSessionActive = true
            }
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
            self.isSessionRunning = false
            DispatchQueue.main.async {
                self.isSessionActive = false
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let completion = photoCompletion else { return }
        
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        completion(image)
        photoCompletion = nil
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame when view size changes
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
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
            AddMealView(selectedDate: nil)
        .environmentObject(DataManager())
        .environmentObject(AuthenticationManager())
}
