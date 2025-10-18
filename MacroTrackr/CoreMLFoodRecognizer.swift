import SwiftUI
import UIKit
import Vision
import CoreML
import Combine

// MARK: - Core ML Food Recognition
class CoreMLFoodRecognizer: ObservableObject {
    @Published var isProcessing = false
    
    private let foodKeywords = [
        "food", "meal", "dish", "plate", "bowl", "cup", "glass",
        "fruit", "apple", "banana", "orange", "grape", "berry", "strawberry",
        "vegetable", "carrot", "broccoli", "lettuce", "tomato", "onion", "pepper",
        "meat", "chicken", "beef", "pork", "fish", "salmon", "tuna", "turkey",
        "bread", "toast", "bagel", "sandwich", "burger", "pizza", "pasta",
        "rice", "noodles", "cereal", "oatmeal", "yogurt", "cheese", "egg",
        "soup", "salad", "cake", "cookie", "pie", "chocolate", "ice cream",
        "drink", "coffee", "tea", "juice", "soda", "beer", "wine", "water"
    ]
    
    func recognizeFood(in image: UIImage, completion: @escaping (String, Double) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("Unknown Food", 0.0)
            return
        }
        
        // Perform multiple recognition tasks for better accuracy
        let dispatchGroup = DispatchGroup()
        var results: [(String, Double)] = []
        
        // 1. Image Classification (built-in Vision)
        dispatchGroup.enter()
        classifyImage(cgImage: cgImage) { classification, confidence in
            results.append((classification, confidence))
            dispatchGroup.leave()
        }
        
        // 2. Object Detection (find food items in image)
        dispatchGroup.enter()
        detectObjects(cgImage: cgImage) { detectedItems, confidence in
            if let topItem = detectedItems.first {
                results.append((topItem, confidence))
            }
            dispatchGroup.leave()
        }
        
        // Process results when all tasks complete
        dispatchGroup.notify(queue: .main) {
            let bestResult = self.selectBestResult(from: results)
            completion(bestResult.0, bestResult.1)
        }
    }
    
    // MARK: - Image Classification
    private func classifyImage(cgImage: CGImage, completion: @escaping (String, Double) -> Void) {
        let request = VNClassifyImageRequest { request, error in
            guard let observations = request.results as? [VNClassificationObservation], error == nil else {
                completion("Unknown Food", 0.0)
                return
            }
            
            // Filter for food-related items
            let foodObservations = observations.filter { observation in
                self.foodKeywords.contains { keyword in
                    observation.identifier.lowercased().contains(keyword.lowercased())
                }
            }
            
            // Get the best food-related result or fallback to top result
            let bestObservation = foodObservations.first ?? observations.first
            let foodName = self.processFoodName(bestObservation?.identifier ?? "Unknown Food")
            
            completion(foodName, Double(bestObservation?.confidence ?? 0.0))
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [.ciContext: CIContext()])
        try? handler.perform([request])
    }
    
    // MARK: - Object Detection
    private func detectObjects(cgImage: CGImage, completion: @escaping ([String], Double) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion([], 0.0)
                return
            }
            
            // Get text from detected observations and look for food keywords
            let detectedItems = observations.compactMap { observation in
                observation.topCandidates(1).first?.string.lowercased()
            }.compactMap { text in
                self.foodKeywords.first { text.contains($0.lowercased()) }
            }
            
            let avgConfidence = observations.isEmpty ? 0.0 : 
                Double(observations.map { $0.confidence }.reduce(0, +) / Float(observations.count))
            
            completion(Array(Set(detectedItems)), avgConfidence)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [.ciContext: CIContext()])
        try? handler.perform([request])
    }
    
    // MARK: - Helper Methods
    private func selectBestResult(from results: [(String, Double)]) -> (String, Double) {
        // Prefer higher confidence results and food-specific items
        let sortedResults = results.sorted { first, second in
            let firstIsFood = isFoodItem(first.0)
            let secondIsFood = isFoodItem(second.0)
            
            if firstIsFood && !secondIsFood {
                return true
            } else if !firstIsFood && secondIsFood {
                return false
            } else {
                return first.1 > second.1
            }
        }
        
        return sortedResults.first ?? ("Unknown Food", 0.0)
    }
    
    private func isFoodItem(_ item: String) -> Bool {
        return foodKeywords.contains { keyword in
            item.lowercased().contains(keyword.lowercased())
        }
    }
    
    private func processFoodName(_ name: String) -> String {
        let processed = name.replacingOccurrences(of: "_", with: " ")
            .split(separator: ",")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? name
        
        // Capitalize first letter of each word
        return processed.split(separator: " ").map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }
}

// MARK: - Advanced Core ML Model Handler
class AdvancedCoreMLFoodRecognizer: ObservableObject {
    @Published var isProcessing = false
    private var mlModel: MLModel?
    var isModelLoaded = false
    
    init() {
        loadCustomModel()
    }
    
    // MARK: - Custom Model Loading
    private func loadCustomModel() {
        // Try to load a custom food recognition model
        // Priority order: GoogleFood101 (custom trained) -> Food101 (pre-trained) -> ResNet50 -> MobileNetV2 -> Vision framework fallback
        
        let modelNames = ["GoogleFood101", "Food101", "ResNet50", "MobileNetV2", "FoodRecognitionModel"]
        
        for modelName in modelNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                do {
                    mlModel = try MLModel(contentsOf: modelURL)
                    isModelLoaded = true
                    print("✅ Loaded Core ML model: \(modelName)")
                    return
                } catch {
                    print("⚠️ Failed to load \(modelName): \(error)")
                }
            } else if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
                do {
                    mlModel = try MLModel(contentsOf: modelURL)
                    isModelLoaded = true
                    print("✅ Loaded Core ML model: \(modelName)")
                    return
                } catch {
                    print("⚠️ Failed to load \(modelName): \(error)")
                }
            }
        }
        
        print("ℹ️ No custom Core ML models found, using enhanced Vision framework")
    }
    
    func recognizeFoodAdvanced(in image: UIImage, completion: @escaping (String, Double, MacroNutrition?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("Unknown Food", 0.0, nil)
            return
        }
        
        if isModelLoaded && mlModel != nil {
            // Use custom Core ML model
            recognizeWithCustomModel(cgImage: cgImage, completion: completion)
        } else {
            // Fallback to enhanced Vision framework
            recognizeWithVisionFramework(cgImage: cgImage, completion: completion)
        }
    }
    
    // MARK: - Custom Model Recognition
    private func recognizeWithCustomModel(cgImage: CGImage, completion: @escaping (String, Double, MacroNutrition?) -> Void) {
        guard let model = mlModel else {
            completion("Unknown Food", 0.0, nil)
            return
        }
        
        do {
            // Preprocess image for model input (most models expect 224x224 or 299x299)
            let pixelBuffer = try preprocessImage(cgImage: cgImage)
            
            // Create input - most Core ML image models use "image" as input key
            let input = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: pixelBuffer)])
            
            // Make prediction
            let prediction = try model.prediction(from: input)
            
            // Extract results - try common output keys
            var className: String = "Unknown Food"
            var confidence: Double = 0.0
            
            // Try different common output keys (Food-101 specific keys first)
            let possibleOutputKeys = ["classLabel", "label", "prediction", "output", "topLabel"]
            let possibleProbabilityKeys = ["classLabelProbs", "probabilities", "softmax", "confidence", "topProbability"]
            
            for key in possibleOutputKeys {
                if let classFeature = prediction.featureValue(for: key) {
                    let stringValue = classFeature.stringValue
                    if !stringValue.isEmpty {
                        className = stringValue
                        break
                    }
                }
            }
            
            for key in possibleProbabilityKeys {
                if let probFeature = prediction.featureValue(for: key) {
                    if let probDict = probFeature.dictionaryValue as? [String: Double] {
                        confidence = probDict[className] ?? 0.0
                        break
                    } else if let probArray = probFeature.multiArrayValue {
                        // Handle array outputs - find max value manually
                        var maxValue: Float = 0.0
                        let count = probArray.count
                        for i in 0..<count {
                            let value = probArray[i].floatValue
                            if value > maxValue {
                                maxValue = value
                            }
                        }
                        confidence = Double(maxValue)
                        break
                    }
                }
            }
            
            // If we didn't find confidence, try to get the top result
            if confidence == 0.0 {
                for key in possibleProbabilityKeys {
                    if let probFeature = prediction.featureValue(for: key) {
                        if let probDict = probFeature.dictionaryValue as? [String: Double] {
                            let sortedProbs = probDict.sorted { $0.value > $1.value }
                            if let topResult = sortedProbs.first {
                                className = topResult.key
                                confidence = topResult.value
                                break
                            }
                        }
                    }
                }
            }
            
            // Process Food-101 class names (remove underscores, format properly)
            let processedClassName = processFoodClassName(className)
            let nutrition = estimateNutritionForFood(processedClassName)
            
            DispatchQueue.main.async {
                completion(processedClassName, confidence, nutrition)
            }
            
        } catch {
            print("Custom model prediction failed: \(error)")
            // Fallback to Vision framework
            recognizeWithVisionFramework(cgImage: cgImage, completion: completion)
        }
    }
    
    private func recognizeWithVisionFramework(cgImage: CGImage, completion: @escaping (String, Double, MacroNutrition?) -> Void) {
        let recognizer = CoreMLFoodRecognizer()
        
        recognizer.recognizeFood(in: UIImage(cgImage: cgImage)) { foodName, confidence in
            // Get nutrition estimation from the recognized food
            let nutrition = self.estimateNutritionForFood(foodName)
            completion(foodName, confidence, nutrition)
        }
    }
    
    // MARK: - Food Class Name Processing
    private func processFoodClassName(_ className: String) -> String {
        // Food-101 dataset uses class names like "apple_pie", "beef_carpaccio", etc.
        // Convert to more readable format: "Apple Pie", "Beef Carpaccio"
        
        let processed = className
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { word in
                // Capitalize each word
                word.capitalized
            }
            .joined(separator: " ")
        
        return processed.isEmpty ? className : processed
    }
    
    // MARK: - Nutrition Estimation
    private func estimateNutritionForFood(_ foodName: String) -> MacroNutrition {
        return MacroNutrition(
            calories: estimateCalories(for: foodName),
            protein: estimateProtein(for: foodName),
            carbohydrates: estimateCarbs(for: foodName),
            fat: estimateFat(for: foodName),
            sugar: estimateCarbs(for: foodName) * 0.3,
            fiber: estimateCarbs(for: foodName) * 0.1
        )
    }
    
    // MARK: - Image Preprocessing Helper
    private func preprocessImage(cgImage: CGImage) throws -> CVPixelBuffer {
        // Most Core ML models expect either 224x224 or 299x299 input
        // We'll use 224x224 as it's more common for food recognition models
        let targetSize = CGSize(width: 224, height: 224)
        
        guard let pixelBuffer = imageToPixelBuffer(image: UIImage(cgImage: cgImage), size: targetSize) else {
            throw CoreMLError.imagePreprocessingFailed
        }
        
        return pixelBuffer
    }
}

// MARK: - Helper Functions for Image Processing
private func imageToPixelBuffer(image: UIImage, size: CGSize) -> CVPixelBuffer? {
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                                   kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        return nil
    }
    
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
    
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    guard let context = CGContext(data: pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
        return nil
    }
    
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1.0, y: -1.0)
    
    UIGraphicsPushContext(context)
    image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    UIGraphicsPopContext()
    
    return buffer
}

// MARK: - Core ML Error Types
enum CoreMLError: Error {
    case imagePreprocessingFailed
    case modelPredictionFailed
    case invalidModelOutput
    
    var localizedDescription: String {
        switch self {
        case .imagePreprocessingFailed:
            return "Failed to preprocess image for Core ML model"
        case .modelPredictionFailed:
            return "Core ML model prediction failed"
        case .invalidModelOutput:
            return "Invalid model output"
        }
    }
}
