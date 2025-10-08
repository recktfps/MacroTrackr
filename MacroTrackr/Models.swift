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

struct MacroNutrition: Codable {
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
    var mealType: MealType
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
