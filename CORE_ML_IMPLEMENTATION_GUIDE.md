# Core ML Implementation Guide for MacroTrackr

This guide explains how to implement and enhance Core ML machine learning capabilities in your MacroTrackr app for food recognition.

## 🎯 Current Implementation

Your app already has a solid Core ML foundation with these features:

### 1. **Enhanced Vision Framework Integration**
- Uses Apple's built-in Vision framework for image classification
- Implements object detection for better food identification
- Processes multiple recognition methods simultaneously for improved accuracy

### 2. **Food Recognition Pipeline**
```swift
CoreMLFoodRecognizer -> classifyImage() + detectObjects() -> selectBestResult()
```

### 3. **Nutrition Estimation**
- Automatic nutrition estimation based on recognized food items
- Uses predefined nutrition tables for common foods
- Integrates seamlessly with your meal logging system

## 🚀 How to Enhance Core ML Implementation

### **Option 1: Use Apple's Create ML (Recommended for Beginners)**

1. **Create a Food Recognition Model**:
   ```bash
   # Create ML is included with Xcode
   # Launch Create ML app from Xcode -> Open Developer Tool
   ```

2. **Train Your Model**:
   - Collect food images (at least 100 per category)
   - Categories: fruits, vegetables, proteins, carbs, etc.
   - Use "Image Classification" template
   - Train for food-specific recognition

3. **Export and Add to Xcode**:
   - Export as `.mlmodel` file
   - Drag into your Xcode project
   - Model will be automatically compiled to `.mlmodelc`

### **Option 2: Use Pre-trained Models**

#### **Food101 Model (Popular Choice)**:
1. Download from [Apple's Model Gallery](https://developer.apple.com/machine-learning/models/)
2. Add to your project
3. Update the `AdvancedCoreMLFoodRecognizer` class:

```swift
// In loadCustomModel() function
guard let modelURL = Bundle.main.url(forResource: "Food101", withExtension: "mlmodelc") else {
    print("Custom Core ML model not found, using Vision framework")
    return
}

do {
    mlModel = try MLModel(contentsOf: modelURL)
    isModelLoaded = true
    print("Food101 model loaded successfully")
} catch {
    print("Failed to load Food101 model: \(error)")
}
```

### **Option 3: Custom Model Implementation**

To implement your custom model, update the `recognizeWithCustomModel` function:

```swift
private func recognizeWithCustomModel(cgImage: CGImage, completion: @escaping (String, Double, MacroNutrition?) -> Void) {
    guard let model = mlModel else {
        completion("Unknown Food", 0.0, nil)
        return
    }
    
    do {
        // 1. Preprocess image
        let pixelBuffer = try preprocessImage(cgImage: cgImage)
        
        // 2. Create input (adapt based on your model)
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "image": MLFeatureValue(pixelBuffer: pixelBuffer)
        ])
        
        // 3. Make prediction
        let prediction = try model.prediction(from: input)
        
        // 4. Process output (adapt based on your model's output structure)
        if let classificationOutput = prediction.featureValue(for: "classLabel"),
           let className = classificationOutput.stringValue,
           let confidenceOutput = prediction.featureValue(for: "classLabelProbs"),
           let confidenceDict = confidenceOutput.dictionaryValue as? [String: Double] {
            
            let confidence = confidenceDict[className] ?? 0.0
            let nutrition = estimateNutritionForFood(className)
            
            DispatchQueue.main.async {
                completion(className, confidence, nutrition)
            }
        }
        
    } catch {
        print("Custom model prediction failed: \(error)")
        completion("Unknown Food", 0.0, nil)
    }
}
```

## 🔧 Implementation Steps

### **Step 1: Add Your Model to Xcode**

1. **Download or create a `.mlmodel` file**
2. **Drag it into your Xcode project** (ensure "Add to target" is checked)
3. **Build the project** - Xcode automatically compiles it to `.mlmodelc`

### **Step 2: Update Model Loading**

Uncomment and modify the `loadCustomModel()` function in `BarcodeScannerView.swift`:

```swift
private func loadCustomModel() {
    guard let modelURL = Bundle.main.url(forResource: "YOUR_MODEL_NAME", withExtension: "mlmodelc") else {
        print("Custom Core ML model not found, using Vision framework")
        return
    }
    
    do {
        mlModel = try MLModel(contentsOf: modelURL)
        isModelLoaded = true
        print("Custom Core ML model loaded successfully")
    } catch {
        print("Failed to load custom Core ML model: \(error)")
    }
}
```

### **Step 3: Handle Model Input/Output**

Different models have different input/output requirements. Check your model's specification and adapt accordingly:

```swift
// Common input preprocessing for image models
private func preprocessImage(cgImage: CGImage) throws -> CVPixelBuffer {
    let image = UIImage(cgImage: cgImage)
    
    // Most models expect 224x224 or 299x299 input size
    let targetSize = CGSize(width: 224, height: 224) // Adjust based on your model
    
    guard let pixelBuffer = imageToPixelBuffer(image: image, size: targetSize) else {
        throw CoreMLError.imagePreprocessingFailed
    }
    
    return pixelBuffer
}
```

## 🎨 Advanced Features You Can Add

### **1. Multiple Food Detection**
```swift
// Detect multiple food items in one image
private func detectMultipleFoods(cgImage: CGImage, completion: @escaping ([DetectedFood]) -> Void) {
    let request = VNRecognizeObjectsRequest { request, error in
        // Process multiple detections
        // Return array of DetectedFood objects
    }
}
```

### **2. Portion Size Estimation**
```swift
// Use object detection to estimate portion sizes
private func estimatePortionSize(detectedFood: DetectedFood, imageSize: CGSize) -> Double {
    // Analyze bounding box size relative to image
    // Estimate serving size based on visual cues
}
```

### **3. Real-time Camera Processing**
```swift
// Process live camera feed for real-time food recognition
class LiveFoodRecognition: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process each frame for food recognition
    }
}
```

## 📱 Testing Your Implementation

### **1. Test with Sample Images**
- Take photos of common foods
- Verify recognition accuracy
- Test edge cases (multiple foods, different lighting)

### **2. Performance Optimization**
```swift
// Use background queue for processing
DispatchQueue.global(qos: .userInitiated).async {
    // Core ML processing
    DispatchQueue.main.async {
        // Update UI with results
    }
}
```

### **3. Error Handling**
```swift
// Robust error handling for production
do {
    let result = try model.prediction(from: input)
    // Process result
} catch {
    print("Model prediction failed: \(error)")
    // Fallback to Vision framework or show error
}
```

## 🔍 Popular Food Recognition Models

1. **Food101** - 101 food categories
2. **iNaturalist** - General object recognition with food categories
3. **Custom Create ML models** - Train on your specific data
4. **TensorFlow Lite models** - Convert to Core ML format

## 🚨 Important Considerations

### **Performance**
- Core ML models run on-device (good for privacy)
- Larger models = slower inference but better accuracy
- Consider model size vs. accuracy trade-offs

### **Privacy**
- All processing happens locally
- No images sent to external servers
- Perfect for health/food apps

### **Battery Usage**
- Heavy inference can drain battery
- Cache results when possible
- Use lower precision models for better battery life

## 📚 Resources

- [Apple Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Create ML Documentation](https://developer.apple.com/documentation/createml)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)
- [Core ML Model Gallery](https://developer.apple.com/machine-learning/models/)

## 🎉 Your Current Setup

Your app is already well-equipped with:
- ✅ Vision framework integration
- ✅ Multi-method recognition
- ✅ Nutrition estimation
- ✅ Error handling and fallbacks
- ✅ Ready-to-use custom model integration

Just add your preferred `.mlmodel` file and uncomment the custom model loading code to get started!
