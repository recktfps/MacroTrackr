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
        case id, displayName, email, dailyGoals, isPrivate, createdAt, favoriteMeals, profileImageURL
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
        case id, userId, name, imageURL, ingredients, cookingInstructions, macros, createdAt, mealType, isFavorite
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
        case id, userId, originalMealId, name, imageURL, ingredients, cookingInstructions, macros, isFavorite, createdAt
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

// MARK: - Friend System Models

struct FriendRequest: Codable, Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let status: FriendRequestStatus
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, fromUserId, toUserId, status, createdAt
    }
}

enum FriendRequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
}

struct Friendship: Codable, Identifiable {
    let id: String
    let userId1: String
    let userId2: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId1, userId2, createdAt
    }
}

// MARK: - Statistics Models

struct DailyStats: Codable {
    let date: Date
    var totalMacros: MacroNutrition
    var meals: [Meal]
    var goalProgress: MacroProgress
    
    enum CodingKeys: String, CodingKey {
        case date, totalMacros, meals, goalProgress
    }
}

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

// MARK: - Food Scanning Models

struct FoodScanResult: Codable {
    let foodItems: [DetectedFood]
    let estimatedMacros: MacroNutrition
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case foodItems, estimatedMacros, confidence
    }
}

struct DetectedFood: Codable, Identifiable {
    let id: String
    let name: String
    let confidence: Double
    let estimatedPortion: String
    var macros: MacroNutrition
    
    enum CodingKeys: String, CodingKey {
        case id, name, confidence, estimatedPortion, macros
    }
}

// MARK: - Widget Models

struct WidgetData: Codable {
    let date: Date
    let totalMacros: MacroNutrition
    let goals: MacroGoals
    let progress: MacroProgress
    
    enum CodingKeys: String, CodingKey {
        case date, totalMacros, goals, progress
    }
}
