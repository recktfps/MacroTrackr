import Foundation
import SwiftUI

// MARK: - Core Data Models
struct UserProfile: Codable, Identifiable {
    let id: String
    let displayName: String
    let email: String
    var dailyGoals: MacroGoals
    var isPrivate: Bool
    let createdAt: Date
    var favoriteMeals: [String] = []
    var profileImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case dailyGoals = "daily_goals"
        case isPrivate = "is_private"
        case createdAt = "created_at"
        case favoriteMeals = "favorite_meals"
        case profileImageURL = "profile_image_url"
    }
}

struct MacroGoals: Codable {
    var calories: Double = 2000
    var protein: Double = 150
    var carbohydrates: Double = 250
    var fat: Double = 65
    var sugar: Double = 50
    var fiber: Double = 25
    
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbohydrates, fat, sugar, fiber
    }
}

struct MacroNutrition: Codable, Equatable {
    var calories: Double = 0
    var protein: Double = 0
    var carbohydrates: Double = 0
    var fat: Double = 0
    var sugar: Double = 0
    var fiber: Double = 0
    
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbohydrates, fat, sugar, fiber
    }
}

struct Meal: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var imageURL: String?
    var ingredients: [String]
    var cookingInstructions: String?
    var macros: MacroNutrition
    let createdAt: Date
    var mealType: MealType = .snack
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case imageURL = "image_url"
        case ingredients
        case cookingInstructions = "cooking_instructions"
        case macros
        case createdAt = "created_at"
        case mealType = "meal_type"
        case isFavorite = "is_favorite"
    }
    
    init(id: String, userId: String, name: String, imageURL: String? = nil, ingredients: [String] = [], cookingInstructions: String? = nil, macros: MacroNutrition, createdAt: Date, mealType: MealType = .snack, isFavorite: Bool = false) {
        self.id = id
        self.userId = userId
        self.name = name
        self.imageURL = imageURL
        self.ingredients = ingredients
        self.cookingInstructions = cookingInstructions
        self.macros = macros
        self.createdAt = createdAt
        self.mealType = mealType
        self.isFavorite = isFavorite
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        cookingInstructions = try container.decodeIfPresent(String.self, forKey: .cookingInstructions)
        macros = try container.decode(MacroNutrition.self, forKey: .macros)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        mealType = try container.decodeIfPresent(MealType.self, forKey: .mealType) ?? .snack
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(cookingInstructions, forKey: .cookingInstructions)
        try container.encode(macros, forKey: .macros)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(mealType, forKey: .mealType)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
}

struct SavedMeal: Codable, Identifiable {
    let id: String
    let userId: String
    let originalMealId: String
    var name: String
    var imageURL: String?
    var ingredients: [String]
    var cookingInstructions: String?
    var macros: MacroNutrition
    var isFavorite: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case originalMealId = "original_meal_id"
        case name
        case imageURL = "image_url"
        case ingredients
        case cookingInstructions = "cooking_instructions"
        case macros
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
    }
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "heart.fill"
        }
    }
}

// MARK: - Macro Progress Model
struct MacroProgress: Codable {
    var caloriesProgress: Double = 0
    var proteinProgress: Double = 0
    var carbohydratesProgress: Double = 0
    var fatProgress: Double = 0
    var sugarProgress: Double = 0
    var fiberProgress: Double = 0
    
    enum CodingKeys: String, CodingKey {
        case caloriesProgress, proteinProgress, carbohydratesProgress, fatProgress, sugarProgress, fiberProgress
    }
}

// MARK: - Detected Food Model
struct DetectedFood: Identifiable {
    let id: String
    let name: String
    let confidence: Float
    let estimatedCalories: Double
    let estimatedProtein: Double
    let estimatedCarbs: Double
    let estimatedFat: Double
    
    var estimatedSugar: Double {
        estimatedCarbs * 0.3 // Rough estimate
    }
    
    var estimatedFiber: Double {
        estimatedCarbs * 0.1 // Rough estimate
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    static let mealDetailFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Nutrition Estimation Functions
func estimateCalories(for foodName: String) -> Double {
    let name = foodName.lowercased()
    
    if name.contains("apple") || name.contains("fruit") {
        return 80
    } else if name.contains("chicken") || name.contains("meat") {
        return 200
    } else if name.contains("bread") || name.contains("pasta") {
        return 250
    } else if name.contains("pizza") {
        return 300
    } else if name.contains("salad") || name.contains("vegetable") {
        return 50
    } else if name.contains("fish") {
        return 180
    }
    
    return 150 // Default estimate
}

func estimateProtein(for foodName: String) -> Double {
    let name = foodName.lowercased()
    
    if name.contains("chicken") || name.contains("meat") || name.contains("fish") {
        return 25
    } else if name.contains("bread") || name.contains("pasta") {
        return 8
    } else if name.contains("pizza") {
        return 12
    } else if name.contains("apple") || name.contains("fruit") {
        return 1
    } else if name.contains("salad") || name.contains("vegetable") {
        return 3
    }
    
    return 10 // Default estimate
}

func estimateCarbs(for foodName: String) -> Double {
    let name = foodName.lowercased()
    
    if name.contains("bread") || name.contains("pasta") {
        return 45
    } else if name.contains("pizza") {
        return 35
    } else if name.contains("apple") || name.contains("fruit") {
        return 20
    } else if name.contains("salad") || name.contains("vegetable") {
        return 10
    } else if name.contains("chicken") || name.contains("meat") || name.contains("fish") {
        return 2
    }
    
    return 25 // Default estimate
}

func estimateFat(for foodName: String) -> Double {
    let name = foodName.lowercased()
    
    if name.contains("pizza") {
        return 12
    } else if name.contains("chicken") || name.contains("meat") || name.contains("fish") {
        return 8
    } else if name.contains("bread") || name.contains("pasta") {
        return 2
    } else if name.contains("apple") || name.contains("fruit") {
        return 0.5
    } else if name.contains("salad") || name.contains("vegetable") {
        return 0.5
    }
    
    return 5 // Default estimate
}

// MARK: - Food Scan Result
struct FoodScanResult: Identifiable, Codable {
    let id: UUID
    let foodName: String
    let confidence: Double
    let estimatedNutrition: MacroNutrition
    let imageData: Data?
    let scanDate: Date
    
    init(foodName: String, confidence: Double, estimatedNutrition: MacroNutrition, imageData: Data? = nil) {
        self.id = UUID()
        self.foodName = foodName
        self.confidence = confidence
        self.estimatedNutrition = estimatedNutrition
        self.imageData = imageData
        self.scanDate = Date()
    }
}

// MARK: - Barcode Scan Result
struct BarcodeScanResult: Identifiable, Codable {
    let id: UUID
    let barcode: String
    let productName: String
    let brand: String?
    let imageURL: String?
    let nutrition: MacroNutrition
    let servingSize: String?
    let scanDate: Date
    
    init(barcode: String, productName: String, brand: String? = nil, imageURL: String? = nil, nutrition: MacroNutrition, servingSize: String? = nil) {
        self.id = UUID()
        self.barcode = barcode
        self.productName = productName
        self.brand = brand
        self.imageURL = imageURL
        self.nutrition = nutrition
        self.servingSize = servingSize
        self.scanDate = Date()
    }
}

// MARK: - Recipe Collection Models
struct RecipeCollection: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let imageURL: String?
    let ingredients: [String]
    let instructions: [String]
    let servingSize: Int
    let prepTime: Int? // in minutes
    let cookTime: Int? // in minutes
    let macros: MacroNutrition
    let tags: [String]
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case imageURL = "image_url"
        case ingredients
        case instructions
        case servingSize = "serving_size"
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case macros
        case tags
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: String, userId: String, name: String, description: String? = nil, imageURL: String? = nil, ingredients: [String], instructions: [String], servingSize: Int, prepTime: Int? = nil, cookTime: Int? = nil, macros: MacroNutrition, tags: [String] = [], isPublic: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.ingredients = ingredients
        self.instructions = instructions
        self.servingSize = servingSize
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.macros = macros
        self.tags = tags
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct RecipeRating: Codable, Identifiable {
    let id: String
    let recipeId: String
    let userId: String
    let rating: Int // 1-5 stars
    let review: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case userId = "user_id"
        case rating
        case review
        case createdAt = "created_at"
    }
    
    init(id: String, recipeId: String, userId: String, rating: Int, review: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.recipeId = recipeId
        self.userId = userId
        self.rating = rating
        self.review = review
        self.createdAt = createdAt
    }
}

// MARK: - Friend Request
struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let status: FriendRequestStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
}

// MARK: - Friendship
struct Friendship: Identifiable, Codable {
    let id: String
    let userId1: String
    let userId2: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId1 = "user_id_1"
        case userId2 = "user_id_2"
        case createdAt = "created_at"
    }
}

// MARK: - User with Friendship Info
struct UserWithFriendshipInfo: Identifiable, Codable {
    let user: UserProfile
    let friendshipStatus: FriendshipStatus
    let mutualFriendsCount: Int
    let mutualFriends: [UserProfile]
    
    var id: String { user.id }
}

enum FriendshipStatus: String, Codable, CaseIterable {
    case notFriends = "not_friends"
    case pendingOutgoing = "pending_outgoing"
    case pendingIncoming = "pending_incoming"
    case friends = "friends"
    case selfUser = "self_user"
}

// MARK: - Daily Stats
struct DailyStats: Identifiable, Codable {
    let id: UUID
    let date: Date
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let totalSugar: Double
    let goalCalories: Double
    let goalProtein: Double
    let goalCarbs: Double
    let goalFat: Double
    let goalSugar: Double
    let mealCount: Int
    
    init(date: Date, totalCalories: Double, totalProtein: Double, totalCarbs: Double, totalFat: Double, totalSugar: Double, goalCalories: Double, goalProtein: Double, goalCarbs: Double, goalFat: Double, goalSugar: Double, mealCount: Int) {
        self.id = UUID()
        self.date = date
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.totalSugar = totalSugar
        self.goalCalories = goalCalories
        self.goalProtein = goalProtein
        self.goalCarbs = goalCarbs
        self.goalFat = goalFat
        self.goalSugar = goalSugar
        self.mealCount = mealCount
    }
    
    var caloriesProgress: Double {
        guard goalCalories > 0 else { return 0 }
        return min(totalCalories / goalCalories, 1.0)
    }
    
    var proteinProgress: Double {
        guard goalProtein > 0 else { return 0 }
        return min(totalProtein / goalProtein, 1.0)
    }
    
    var carbsProgress: Double {
        guard goalCarbs > 0 else { return 0 }
        return min(totalCarbs / goalCarbs, 1.0)
    }
    
    var fatProgress: Double {
        guard goalFat > 0 else { return 0 }
        return min(totalFat / goalFat, 1.0)
    }
    
    var sugarProgress: Double {
        guard goalSugar > 0 else { return 0 }
        return min(totalSugar / goalSugar, 1.0)
    }
    
    var remainingCalories: Double {
        return max(goalCalories - totalCalories, 0)
    }
    
    var remainingProtein: Double {
        return max(goalProtein - totalProtein, 0)
    }
    
    var remainingCarbs: Double {
        return max(goalCarbs - totalCarbs, 0)
    }
    
    var remainingFat: Double {
        return max(goalFat - totalFat, 0)
    }
    
    var remainingSugar: Double {
        return max(goalSugar - totalSugar, 0)
    }
}

// MARK: - Ingredient Model
struct Ingredient: Codable, Identifiable {
    let id: String
    let name: String
    let macros: MacroNutrition
    let category: IngredientCategory
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case macros
        case category
        case createdAt = "created_at"
    }
    
    init(id: String, name: String, macros: MacroNutrition, category: IngredientCategory = .other, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.macros = macros
        self.category = category
        self.createdAt = createdAt
    }
}

// MARK: - Ingredient Category
enum IngredientCategory: String, CaseIterable, Codable {
    case protein = "protein"
    case carbs = "carbs"
    case fats = "fats"
    case vegetables = "vegetables"
    case fruits = "fruits"
    case dairy = "dairy"
    case grains = "grains"
    case spices = "spices"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .carbs: return "Carbohydrates"
        case .fats: return "Fats & Oils"
        case .vegetables: return "Vegetables"
        case .fruits: return "Fruits"
        case .dairy: return "Dairy"
        case .grains: return "Grains"
        case .spices: return "Spices & Seasonings"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .protein: return "🥩"
        case .carbs: return "🌾"
        case .fats: return "🥑"
        case .vegetables: return "🥕"
        case .fruits: return "🍎"
        case .dairy: return "🥛"
        case .grains: return "🍞"
        case .spices: return "🧂"
        case .other: return "📦"
        }
    }
}

// MARK: - User Ingredient Preset
struct UserIngredientPreset: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let macros: MacroNutrition
    let category: IngredientCategory
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case macros
        case category
        case createdAt = "created_at"
    }
    
    init(id: String, userId: String, name: String, macros: MacroNutrition, category: IngredientCategory = .other, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.macros = macros
        self.category = category
        self.createdAt = createdAt
    }
}

// MARK: - USDA FoodData Central API Models
struct USDAApiResponse: Codable {
    let foods: [USDAFood]
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case foods
        case totalHits
        case currentPage
        case totalPages
    }
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let brandedFoodCategory: String?
    let ingredients: String?
    let foodNutrients: [USDAFoodNutrient]
    let servingSize: Double?
    let servingSizeUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case brandOwner
        case brandedFoodCategory
        case ingredients
        case foodNutrients
        case servingSize
        case servingSizeUnit
    }
}

struct USDAFoodNutrient: Codable {
    let nutrient: USDANutrient
    let amount: Double
    
    enum CodingKeys: String, CodingKey {
        case nutrient
        case amount
    }
}

struct USDANutrient: Codable {
    let id: Int
    let number: String
    let name: String
    let rank: Int
    let unitName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case number
        case name
        case rank
        case unitName
    }
}

// MARK: - Local Storage for Ingredients
struct LocalIngredientsManager {
    private static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private static let ingredientsURL = documentsDirectory.appendingPathComponent("ingredients.json")
    private static let recentIngredientsURL = documentsDirectory.appendingPathComponent("recent_ingredients.json")
    private static let lastUpdateKey = "lastIngredientsUpdate"
    private static let recentIngredientsKey = "recentIngredients"
    
    static func saveIngredients(_ ingredients: [Ingredient]) {
        do {
            let data = try JSONEncoder().encode(ingredients)
            try data.write(to: ingredientsURL)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
            print("Saved \(ingredients.count) ingredients locally")
        } catch {
            print("Failed to save ingredients locally: \(error)")
        }
    }
    
    static func loadIngredients() -> [Ingredient] {
        do {
            let data = try Data(contentsOf: ingredientsURL)
            let ingredients = try JSONDecoder().decode([Ingredient].self, from: data)
            print("Loaded \(ingredients.count) ingredients from local storage")
            return ingredients
        } catch {
            print("Failed to load local ingredients: \(error)")
            return []
        }
    }
    
    static func shouldUpdateIngredients() -> Bool {
        guard let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date else {
            return true // Never updated, should update
        }
        
        // Update once per day
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdate, to: Date()).day ?? 0
        return daysSinceUpdate >= 1
    }
    
    static func hasLocalIngredients() -> Bool {
        return FileManager.default.fileExists(atPath: ingredientsURL.path)
    }
    
    // MARK: - Recent Ingredients Management
    static func addRecentIngredient(_ ingredient: Ingredient) {
        var recentIngredients = loadRecentIngredients()
        
        // Remove if already exists (to update order)
        recentIngredients.removeAll { $0.id == ingredient.id }
        
        // Add to beginning
        recentIngredients.insert(ingredient, at: 0)
        
        // Keep only last 20
        if recentIngredients.count > 20 {
            recentIngredients = Array(recentIngredients.prefix(20))
        }
        
        saveRecentIngredients(recentIngredients)
    }
    
    static func loadRecentIngredients() -> [Ingredient] {
        do {
            let data = try Data(contentsOf: recentIngredientsURL)
            let ingredients = try JSONDecoder().decode([Ingredient].self, from: data)
            return ingredients
        } catch {
            return []
        }
    }
    
    private static func saveRecentIngredients(_ ingredients: [Ingredient]) {
        do {
            let data = try JSONEncoder().encode(ingredients)
            try data.write(to: recentIngredientsURL)
        } catch {
            print("Failed to save recent ingredients: \(error)")
        }
    }
    
    static func clearRecentIngredients() {
        do {
            try FileManager.default.removeItem(at: recentIngredientsURL)
        } catch {
            print("Failed to clear recent ingredients: \(error)")
        }
    }
}
