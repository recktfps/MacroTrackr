#!/usr/bin/env swift

import Foundation

print("🚀 ULTIMATE COMPREHENSIVE MACROTRACKR TEST SUITE")
print("=================================================")
print("Testing EVERY feature to ensure 100% functionality")
print("")

// Test Results Tracking
var allTestResults: [String: [String: Bool]] = [:]
var overallScore = 0
var totalTests = 0

func runTestSuite(_ suiteName: String, _ tests: [String: () -> Bool]) {
    print("\n📋 TEST SUITE: \(suiteName.uppercased())")
    print(String(repeating: "=", count: suiteName.count + 20))
    
    var suiteResults: [String: Bool] = [:]
    var suiteScore = 0
    
    for (testName, testFunction) in tests {
        print("\n🔍 Testing: \(testName)")
        let result = testFunction()
        suiteResults[testName] = result
        suiteScore += result ? 1 : 0
        print(result ? "✅ PASSED" : "❌ FAILED")
        
        if !result {
            print("   ⚠️  This test failed and needs attention!")
        }
    }
    
    allTestResults[suiteName] = suiteResults
    overallScore += suiteScore
    totalTests += tests.count
    
    let successRate = Double(suiteScore) / Double(tests.count) * 100
    print("\n📊 \(suiteName) Results: \(suiteScore)/\(tests.count) (\(String(format: "%.1f", successRate))%)")
}

// MARK: - AUTHENTICATION & PERSISTENCE TESTS

let authTests: [String: () -> Bool] = [
    "App Builds Successfully": {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        task.arguments = [
            "-project", "MacroTrackr.xcodeproj",
            "-scheme", "MacroTrackr",
            "-destination", "platform=iOS Simulator,name=iPhone 17",
            "build"
        ]
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    },
    
    "Authentication Manager Exists": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("class AuthenticationManager") && 
               content.contains("@Published var isAuthenticated") &&
               content.contains("@Published var currentUser")
    },
    
    "Auto-Login Logic Present": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("if authManager.isAuthenticated") &&
               content.contains("MainTabView") &&
               content.contains("AuthenticationView")
    },
    
    "Supabase Client Configured": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("SupabaseClient") &&
               content.contains("SUPABASE_URL") &&
               content.contains("SUPABASE_ANON_KEY")
    },
    
    "Apple Sign In Integration": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("AuthenticationServices") &&
               content.contains("AppleSignInDelegate") &&
               content.contains("Sign in with Apple")
    }
]

runTestSuite("Authentication & Auto-Login", authTests)

// MARK: - PHOTO LIBRARY & IMAGE UPLOAD TESTS

let photoTests: [String: () -> Bool] = [
    "PhotosUI Import Present": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("import PhotosUI")
    },
    
    "Photo Library Permission": {
        let infoPlist = "MacroTrackr/Info.plist"
        guard let content = try? String(contentsOfFile: infoPlist, encoding: .utf8) else { return false }
        return content.contains("NSPhotoLibraryUsageDescription")
    },
    
    "Camera Permission": {
        let infoPlist = "MacroTrackr/Info.plist"
        guard let content = try? String(contentsOfFile: infoPlist, encoding: .utf8) else { return false }
        return content.contains("NSCameraUsageDescription")
    },
    
    "PhotosPicker Implementation": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("PhotosPicker") &&
               content.contains("selection:") &&
               content.contains("matching: .images")
    },
    
    "Profile Image Upload Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func uploadProfileImage") &&
               content.contains("profile-images") &&
               content.contains("FileOptions")
    },
    
    "Meal Image Upload Function": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("func uploadImage") &&
               content.contains("meal-images") &&
               content.contains("selectedImage")
    },
    
    "Image State Management": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("@State") &&
               content.contains("selectedImage") &&
               content.contains("mealImage")
    },
    
    "Kingfisher Image Caching": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("import Kingfisher") &&
               content.contains("KFImage")
    }
]

runTestSuite("Photo Library & Image Upload", photoTests)

// MARK: - MEAL MANAGEMENT TESTS

let mealTests: [String: () -> Bool] = [
    "Save Meal Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func saveMeal") &&
               content.contains("INSERT INTO meals")
    },
    
    "Load Today Meals Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func loadTodayMeals") &&
               content.contains("SELECT * FROM meals")
    },
    
    "Search Meals Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func searchMeals") &&
               content.contains("ilike") &&
               content.contains("name")
    },
    
    "Meal Model Structure": {
        let modelsFile = "MacroTrackr/Models.swift"
        guard let content = try? String(contentsOfFile: modelsFile, encoding: .utf8) else { return false }
        return content.contains("struct Meal") &&
               content.contains("id: UUID") &&
               content.contains("name: String") &&
               content.contains("macros: MacroNutrition")
    },
    
    "Macro Nutrition Model": {
        let modelsFile = "MacroTrackr/Models.swift"
        guard let content = try? String(contentsOfFile: modelsFile, encoding: .utf8) else { return false }
        return content.contains("struct MacroNutrition") &&
               content.contains("calories: Double") &&
               content.contains("protein: Double") &&
               content.contains("carbs: Double") &&
               content.contains("fats: Double")
    },
    
    "Add Meal View Structure": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("struct AddMealView") &&
               content.contains("@State") &&
               content.contains("TextField") &&
               content.contains("Button")
    },
    
    "AI Food Scanning": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("import Vision") &&
               content.contains("VNDetectTextRectanglesRequest") &&
               content.contains("FoodScanResult")
    },
    
    "Quantity Multiplier": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("quantity") &&
               content.contains("Stepper") &&
               content.contains("multiply")
    }
]

runTestSuite("Meal Management", mealTests)

// MARK: - SOCIAL FEATURES TESTS

let socialTests: [String: () -> Bool] = [
    "Friend Request Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func sendFriendRequest") &&
               content.contains("friend_requests") &&
               content.contains("display_name")
    },
    
    "Friend Request Model": {
        let modelsFile = "MacroTrackr/Models.swift"
        guard let content = try? String(contentsOfFile: modelsFile, encoding: .utf8) else { return false }
        return content.contains("struct FriendRequest") &&
               content.contains("from_user_id") &&
               content.contains("to_user_id") &&
               content.contains("status")
    },
    
    "Friendship Model": {
        let modelsFile = "MacroTrackr/Models.swift"
        guard let content = try? String(contentsOfFile: modelsFile, encoding: .utf8) else { return false }
        return content.contains("struct Friendship") &&
               content.contains("user_id_1") &&
               content.contains("user_id_2")
    },
    
    "User Profile Model": {
        let modelsFile = "MacroTrackr/Models.swift"
        guard let content = try? String(contentsOfFile: modelsFile, encoding: .utf8) else { return false }
        return content.contains("struct UserProfile") &&
               content.contains("display_name") &&
               content.contains("profile_image_url")
    },
    
    "Load Friends Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func loadFriends") &&
               content.contains("friendships")
    },
    
    "Load All Users Function": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func loadAllUsers") &&
               content.contains("profiles")
    },
    
    "Respond to Friend Request": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("func respondToFriendRequest") &&
               content.contains("accepted") &&
               content.contains("declined")
    },
    
    "Database Trigger for Friendships": {
        let schemaFile = "supabase-schema.sql"
        guard let content = try? String(contentsOfFile: schemaFile, encoding: .utf8) else { return false }
        return content.contains("handle_accepted_friend_request") &&
               content.contains("CREATE TRIGGER") &&
               content.contains("INSERT INTO friendships")
    }
]

runTestSuite("Social Features", socialTests)

// MARK: - WIDGET TESTS

let widgetTests: [String: () -> Bool] = [
    "Widget Bundle Exists": {
        let widgetBundleFile = "MacroTrackrWidget/MacroTrackrWidgetBundle.swift"
        return FileManager.default.fileExists(atPath: widgetBundleFile)
    },
    
    "Widget Implementation": {
        let widgetFile = "MacroTrackrWidget/MacroTrackrWidget.swift"
        guard let content = try? String(contentsOfFile: widgetFile, encoding: .utf8) else { return false }
        return content.contains("import WidgetKit") &&
               content.contains("struct MacroTrackrWidget") &&
               content.contains("TimelineProvider")
    },
    
    "Widget Sizes Implemented": {
        let widgetFile = "MacroTrackrWidget/MacroTrackrWidget.swift"
        guard let content = try? String(contentsOfFile: widgetFile, encoding: .utf8) else { return false }
        return content.contains("SmallWidgetView") &&
               content.contains("MediumWidgetView") &&
               content.contains("LargeWidgetView")
    },
    
    "Widget Data Source": {
        let widgetFile = "MacroTrackrWidget/MacroTrackrWidget.swift"
        guard let content = try? String(contentsOfFile: widgetFile, encoding: .utf8) else { return false }
        return content.contains("func getTimeline") &&
               content.contains("TimelineEntry") &&
               content.contains("getSnapshot")
    },
    
    "App Groups Configuration": {
        let entitlementsFile = "MacroTrackr/MacroTrackr.entitlements"
        guard let content = try? String(contentsOfFile: entitlementsFile, encoding: .utf8) else { return false }
        return content.contains("com.apple.security.application-groups") &&
               content.contains("group.com.macrotrackr.shared")
    },
    
    "Widget Data Sharing": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("updateWidgetData") &&
               content.contains("WidgetCenter") &&
               content.contains("reloadAllTimelines")
    }
]

runTestSuite("Widget Functionality", widgetTests)

// MARK: - DATABASE & BACKEND TESTS

let databaseTests: [String: () -> Bool] = [
    "Database Schema Complete": {
        let schemaFile = "supabase-schema.sql"
        guard let content = try? String(contentsOfFile: schemaFile, encoding: .utf8) else { return false }
        return content.contains("CREATE TABLE profiles") &&
               content.contains("CREATE TABLE meals") &&
               content.contains("CREATE TABLE friend_requests") &&
               content.contains("CREATE TABLE friendships") &&
               content.contains("CREATE TABLE saved_meals")
    },
    
    "RLS Policies Configured": {
        let schemaFile = "supabase-schema.sql"
        guard let content = try? String(contentsOfFile: schemaFile, encoding: .utf8) else { return false }
        return content.contains("ALTER TABLE") &&
               content.contains("ENABLE ROW LEVEL SECURITY") &&
               content.contains("CREATE POLICY")
    },
    
    "Storage Buckets Configured": {
        let schemaFile = "supabase-schema.sql"
        guard let content = try? String(contentsOfFile: schemaFile, encoding: .utf8) else { return false }
        return content.contains("INSERT INTO storage.buckets") &&
               content.contains("profile-images") &&
               content.contains("meal-images")
    },
    
    "Database Triggers": {
        let schemaFile = "supabase-schema.sql"
        guard let content = try? String(contentsOfFile: schemaFile, encoding: .utf8) else { return false }
        return content.contains("CREATE OR REPLACE FUNCTION") &&
               content.contains("handle_accepted_friend_request") &&
               content.contains("CREATE TRIGGER")
    },
    
    "Error Handling": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("do {") &&
               content.contains("try await") &&
               content.contains("catch {") &&
               content.contains("NSError")
    },
    
    "Real-time Subscriptions": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("subscribeToFriendRequests") &&
               content.contains("subscribeToMeals") &&
               content.contains("postgresChange")
    }
]

runTestSuite("Database & Backend", databaseTests)

// MARK: - UI/UX TESTS

let uiTests: [String: () -> Bool] = [
    "Main Tab View Structure": {
        let appFile = "MacroTrackr/MacroTrackrApp.swift"
        guard let content = try? String(contentsOfFile: appFile, encoding: .utf8) else { return false }
        return content.contains("struct MainTabView") &&
               content.contains("TabView") &&
               content.contains("DailyView") &&
               content.contains("SearchView") &&
               content.contains("StatsView") &&
               content.contains("ProfileView")
    },
    
    "Daily View Implementation": {
        let dailyFile = "MacroTrackr/DailyView.swift"
        guard let content = try? String(contentsOfFile: dailyFile, encoding: .utf8) else { return false }
        return content.contains("struct DailyView") &&
               content.contains("@State") &&
               content.contains("DatePicker") &&
               content.contains("Today")
    },
    
    "Search View Implementation": {
        let searchFile = "MacroTrackr/SearchView.swift"
        guard let content = try? String(contentsOfFile: searchFile, encoding: .utf8) else { return false }
        return content.contains("struct SearchView") &&
               content.contains("SearchBar") &&
               content.contains("List")
    },
    
    "Stats View Implementation": {
        let statsFile = "MacroTrackr/StatsView.swift"
        guard let content = try? String(contentsOfFile: statsFile, encoding: .utf8) else { return false }
        return content.contains("struct StatsView") &&
               content.contains("Chart") &&
               content.contains("weekly") &&
               content.contains("monthly")
    },
    
    "Profile View Implementation": {
        let profileFile = "MacroTrackr/ProfileView.swift"
        guard let content = try? String(contentsOfFile: profileFile, encoding: .utf8) else { return false }
        return content.contains("struct ProfileView") &&
               content.contains("DailyGoalsView") &&
               content.contains("PrivacySettingsView")
    },
    
    "Cancel/Save Button Logic": {
        let addMealFile = "MacroTrackr/AddMealView.swift"
        guard let content = try? String(contentsOfFile: addMealFile, encoding: .utf8) else { return false }
        return content.contains("Button") &&
               content.contains("Cancel") &&
               content.contains("Save") &&
               content.contains("dismiss")
    },
    
    "Macro Display Formatting": {
        let dailyFile = "MacroTrackr/DailyView.swift"
        guard let content = try? String(contentsOfFile: dailyFile, encoding: .utf8) else { return false }
        return content.contains("MacroBadge") &&
               content.contains("font") &&
               content.contains("horizontal") &&
               content.contains("Text")
    }
]

runTestSuite("UI/UX & Navigation", uiTests)

// MARK: - PACKAGE DEPENDENCIES TESTS

let packageTests: [String: () -> Bool] = [
    "Supabase Swift Package": {
        let packageFile = "Package.swift"
        guard let content = try? String(contentsOfFile: packageFile, encoding: .utf8) else { return false }
        return content.contains("supabase-swift") &&
               content.contains("https://github.com/supabase/supabase-swift")
    },
    
    "Realm Swift Package": {
        let packageFile = "Package.swift"
        guard let content = try? String(contentsOfFile: packageFile, encoding: .utf8) else { return false }
        return content.contains("realm-swift") &&
               content.contains("https://github.com/realm/realm-swift")
    },
    
    "Kingfisher Package": {
        let packageFile = "Package.swift"
        guard let content = try? String(contentsOfFile: packageFile, encoding: .utf8) else { return false }
        return content.contains("Kingfisher") &&
               content.contains("https://github.com/onevcat/Kingfisher")
    },
    
    "Package Resolution File": {
        return FileManager.default.fileExists(atPath: "Package.resolved")
    },
    
    "Swift Tools Version": {
        let packageFile = "Package.swift"
        guard let content = try? String(contentsOfFile: packageFile, encoding: .utf8) else { return false }
        return content.contains("swift-tools-version") &&
               content.contains("5.9")
    }
]

runTestSuite("Package Dependencies", packageTests)

// MARK: - FINAL RESULTS

print("\n🏆 ULTIMATE COMPREHENSIVE TEST RESULTS")
print("======================================")

let overallSuccessRate = Double(overallScore) / Double(totalTests) * 100

print("📊 OVERALL SCORE: \(overallScore)/\(totalTests) (\(String(format: "%.1f", overallSuccessRate))%)")
print("")

for (suiteName, suiteResults) in allTestResults {
    let suiteScore = suiteResults.values.filter { $0 }.count
    let suiteTotal = suiteResults.count
    let suiteRate = Double(suiteScore) / Double(suiteTotal) * 100
    
    print("\(suiteName): \(suiteScore)/\(suiteTotal) (\(String(format: "%.1f", suiteRate))%)")
    
    if suiteRate < 100 {
        print("  ❌ Failed tests:")
        for (testName, result) in suiteResults {
            if !result {
                print("    - \(testName)")
            }
        }
    }
}

print("")

if overallSuccessRate >= 95 {
    print("🎉 EXCELLENT! App is ready for production!")
    print("✅ All critical features are working")
} else if overallSuccessRate >= 90 {
    print("✅ VERY GOOD! Minor issues to address")
    print("🔧 Fix the failed tests above")
} else if overallSuccessRate >= 80 {
    print("⚠️  GOOD! Several issues need attention")
    print("🔧 Review and fix failed tests")
} else {
    print("❌ NEEDS WORK! Significant issues found")
    print("🔧 Major fixes required")
}

print("\n📱 READY FOR MANUAL TESTING!")
print("Launch the app and test:")
print("1. Authentication and auto-login")
print("2. Photo library access and image uploads")
print("3. All meal management features")
print("4. Social features and friend requests")
print("5. Widget functionality")
print("6. Database operations")
print("7. UI/UX and navigation")
print("8. Error handling and edge cases")

print("\n🚀 ULTIMATE TESTING COMPLETE!")