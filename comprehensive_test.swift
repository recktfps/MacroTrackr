#!/usr/bin/env swift

import Foundation

// MARK: - Test Configuration
let projectPath = FileManager.default.currentDirectoryPath
let testResults: [(name: String, status: Bool, message: String)] = []

print("🧪 MacroTrackr Comprehensive Feature Test")
print(String(repeating: "=", count: 60))
print("Project Path: \(projectPath)")
print("Test Date: \(Date())")
print(String(repeating: "=", count: 60))
print()

// MARK: - Helper Functions
func testPassed(_ name: String, _ message: String = "") {
    print("✅ PASS: \(name)")
    if !message.isEmpty {
        print("   → \(message)")
    }
}

func testFailed(_ name: String, _ message: String) {
    print("❌ FAIL: \(name)")
    print("   → \(message)")
}

func testWarning(_ name: String, _ message: String) {
    print("⚠️  WARN: \(name)")
    print("   → \(message)")
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: "\(projectPath)/\(path)")
}

func readFile(_ path: String) -> String? {
    guard let data = FileManager.default.contents(atPath: "\(projectPath)/\(path)") else {
        return nil
    }
    return String(data: data, encoding: .utf8)
}

func searchInFile(_ path: String, pattern: String) -> Bool {
    guard let content = readFile(path) else { return false }
    return content.contains(pattern)
}

// MARK: - Test Suite 1: File Structure
print("📁 Test Suite 1: File Structure & Organization")
print(String(repeating: "-", count: 60))

let requiredFiles = [
    "MacroTrackr/MacroTrackrApp.swift",
    "MacroTrackr/Models.swift",
    "MacroTrackr/AuthenticationView.swift",
    "MacroTrackr/DailyView.swift",
    "MacroTrackr/AddMealView.swift",
    "MacroTrackr/SearchView.swift",
    "MacroTrackr/StatsView.swift",
    "MacroTrackr/ProfileView.swift",
    "MacroTrackr/MealDetailView.swift",
    "MacroTrackr/ContentView.swift",
    "MacroTrackr/Info.plist",
    "supabase-schema.sql"
]

var filesPresent = 0
for file in requiredFiles {
    if fileExists(file) {
        filesPresent += 1
    } else {
        testFailed("File missing", file)
    }
}

if filesPresent == requiredFiles.count {
    testPassed("All core files present", "\(filesPresent)/\(requiredFiles.count) files")
} else {
    testFailed("Missing files", "\(requiredFiles.count - filesPresent) files missing")
}

print()

// MARK: - Test Suite 2: Authentication Features
print("🔐 Test Suite 2: Authentication Implementation")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/MacroTrackrApp.swift") {
    // Test for AuthenticationManager
    if content.contains("class AuthenticationManager") {
        testPassed("AuthenticationManager class exists")
    } else {
        testFailed("AuthenticationManager", "Class not found")
    }
    
    // Test for sign in functionality
    if content.contains("func signIn") && content.contains("email") && content.contains("password") {
        testPassed("Sign In method implemented")
    } else {
        testFailed("Sign In", "Method not properly implemented")
    }
    
    // Test for sign up functionality
    if content.contains("func signUp") {
        testPassed("Sign Up method implemented")
    } else {
        testWarning("Sign Up", "Method might be missing")
    }
    
    // Test for sign out functionality
    if content.contains("func signOut") {
        testPassed("Sign Out method implemented")
    } else {
        testFailed("Sign Out", "Method not found")
    }
    
    // Test for Apple Sign In
    if content.contains("Apple") && (content.contains("SignIn") || content.contains("signIn")) {
        testPassed("Apple Sign In integration detected")
    } else {
        testWarning("Apple Sign In", "Integration not detected")
    }
} else {
    testFailed("Authentication", "Cannot read MacroTrackrApp.swift")
}

print()

// MARK: - Test Suite 3: Data Models
print("📊 Test Suite 3: Data Models & Structures")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/Models.swift") {
    let models = [
        "UserProfile",
        "MacroGoals",
        "MacroNutrition",
        "Meal",
        "SavedMeal",
        "FriendRequest",
        "Friendship",
        "DailyStats"
    ]
    
    var modelsFound = 0
    for model in models {
        if content.contains("struct \(model)") {
            modelsFound += 1
        } else {
            testFailed("Model missing", model)
        }
    }
    
    if modelsFound == models.count {
        testPassed("All data models defined", "\(modelsFound)/\(models.count) models")
    } else {
        testFailed("Missing models", "\(models.count - modelsFound) models missing")
    }
    
    // Test for enums
    if content.contains("enum MealType") {
        testPassed("MealType enum defined")
    }
    if content.contains("enum FriendRequestStatus") {
        testPassed("FriendRequestStatus enum defined")
    }
    if content.contains("enum FriendshipStatus") {
        testPassed("FriendshipStatus enum defined")
    }
} else {
    testFailed("Data Models", "Cannot read Models.swift")
}

print()

// MARK: - Test Suite 4: UI Views Implementation
print("🎨 Test Suite 4: UI Views Implementation")
print(String(repeating: "-", count: 60))

let views = [
    ("DailyView", "MacroTrackr/DailyView.swift"),
    ("AddMealView", "MacroTrackr/AddMealView.swift"),
    ("SearchView", "MacroTrackr/SearchView.swift"),
    ("StatsView", "MacroTrackr/StatsView.swift"),
    ("ProfileView", "MacroTrackr/ProfileView.swift")
]

for (viewName, path) in views {
    if let content = readFile(path) {
        if content.contains("struct \(viewName)") && content.contains("View") {
            testPassed("\(viewName) implemented")
        } else {
            testFailed(viewName, "View structure not found")
        }
    } else {
        testFailed(viewName, "File not readable")
    }
}

print()

// MARK: - Test Suite 5: Database Features
print("💾 Test Suite 5: Database & Supabase Integration")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/MacroTrackrApp.swift") {
    // Check for DataManager
    if content.contains("class DataManager") {
        testPassed("DataManager class exists")
        
        // Check for CRUD operations
        let operations = ["saveMeal", "fetchMeals", "deleteMeal", "updateMeal"]
        for op in operations {
            if content.contains("func \(op)") {
                testPassed("Operation: \(op)")
            } else {
                testWarning("Operation: \(op)", "Method not found")
            }
        }
    } else {
        testFailed("DataManager", "Class not found")
    }
    
    // Check for Supabase client
    if content.contains("supabase") || content.contains("Supabase") {
        testPassed("Supabase client integration detected")
    } else {
        testFailed("Supabase", "Client not found")
    }
} else {
    testFailed("Database Integration", "Cannot verify")
}

print()

// MARK: - Test Suite 6: Friend System
print("👥 Test Suite 6: Friend System Implementation")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/ProfileView.swift") {
    // Check for friend request features
    if content.contains("sendFriendRequest") || content.contains("Send Request") {
        testPassed("Friend request UI exists")
    } else {
        testWarning("Friend Request UI", "Not found")
    }
    
    // Check for friends list
    if content.contains("FriendsView") || content.contains("Friends") {
        testPassed("Friends view component exists")
    } else {
        testWarning("Friends View", "Not found")
    }
}

if let content = readFile("MacroTrackr/MacroTrackrApp.swift") {
    // Check for friend request methods
    if content.contains("func sendFriendRequest") {
        testPassed("sendFriendRequest method exists")
    }
    if content.contains("func respondToFriendRequest") {
        testPassed("respondToFriendRequest method exists")
    }
    if content.contains("func fetchFriends") {
        testPassed("fetchFriends method exists")
    }
}

print()

// MARK: - Test Suite 7: Search Functionality
print("🔍 Test Suite 7: Search Feature Implementation")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/SearchView.swift") {
    if content.contains("TextField") && content.contains("search") {
        testPassed("Search input field exists")
    } else {
        testFailed("Search Input", "TextField not found")
    }
    
    if content.contains("performSearch") || content.contains("searchMeals") {
        testPassed("Search method implemented")
    } else {
        testFailed("Search Method", "Implementation not found")
    }
    
    // Check for filters
    if content.contains("filter") || content.contains("Filter") {
        testPassed("Search filters detected")
    } else {
        testWarning("Search Filters", "Not detected")
    }
}

print()

// MARK: - Test Suite 8: Stats & Analytics
print("📈 Test Suite 8: Statistics & Charts")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/StatsView.swift") {
    if content.contains("Chart") || content.contains("BarChart") || content.contains("LineChart") {
        testPassed("Chart components detected")
    } else {
        testWarning("Charts", "Chart library might not be used")
    }
    
    if content.contains("DailyStats") {
        testPassed("DailyStats model usage detected")
    }
    
    // Check for time period filters
    let periods = ["Week", "Month", "Year"]
    var periodsFound = 0
    for period in periods {
        if content.contains(period) {
            periodsFound += 1
        }
    }
    
    if periodsFound == periods.count {
        testPassed("Time period filters implemented", "\(periodsFound)/\(periods.count) periods")
    } else {
        testWarning("Time Periods", "Only \(periodsFound)/\(periods.count) found")
    }
}

print()

// MARK: - Test Suite 9: Profile & Settings
print("⚙️  Test Suite 9: Profile & Settings")
print(String(repeating: "-", count: 60))

if let content = readFile("MacroTrackr/ProfileView.swift") {
    // Check for profile picture upload
    if content.contains("PhotosPicker") || content.contains("photo") {
        testPassed("Photo picker integration detected")
    } else {
        testWarning("Photo Upload", "Feature not clearly visible")
    }
    
    // Check for goals settings
    if content.contains("GoalsView") || content.contains("goals") {
        testPassed("Goals settings view exists")
    }
    
    // Check for privacy settings
    if content.contains("Privacy") {
        testPassed("Privacy settings detected")
    }
}

print()

// MARK: - Test Suite 10: Database Schema
print("🗄️  Test Suite 10: Database Schema Validation")
print(String(repeating: "-", count: 60))

if let content = readFile("supabase-schema.sql") {
    let tables = [
        "profiles",
        "meals",
        "saved_meals",
        "friend_requests",
        "friendships"
    ]
    
    var tablesFound = 0
    for table in tables {
        if content.contains("CREATE TABLE \(table)") || content.contains("create table \(table)") {
            tablesFound += 1
        } else {
            testFailed("Table missing", table)
        }
    }
    
    if tablesFound == tables.count {
        testPassed("All database tables defined", "\(tablesFound)/\(tables.count) tables")
    } else {
        testFailed("Missing tables", "\(tables.count - tablesFound) tables missing")
    }
    
    // Check for RLS policies
    if content.contains("ROW LEVEL SECURITY") || content.contains("row level security") {
        testPassed("RLS enabled in schema")
    } else {
        testWarning("RLS", "Row Level Security might not be enabled")
    }
    
    // Check for storage buckets
    if content.contains("storage.buckets") || content.contains("profile-images") {
        testPassed("Storage bucket configuration found")
    } else {
        testWarning("Storage", "Bucket configuration not found")
    }
} else {
    testFailed("Database Schema", "Cannot read supabase-schema.sql")
}

print()

// MARK: - Test Suite 11: Build Configuration
print("🔨 Test Suite 11: Build Configuration")
print(String(repeating: "-", count: 60))

// Check for Info.plist
if fileExists("MacroTrackr/Info.plist") {
    if let content = readFile("MacroTrackr/Info.plist") {
        // Check for required permissions
        if content.contains("NSCameraUsageDescription") {
            testPassed("Camera permission description exists")
        } else {
            testWarning("Camera Permission", "Description not found in Info.plist")
        }
        
        if content.contains("NSPhotoLibraryUsageDescription") {
            testPassed("Photo library permission description exists")
        } else {
            testWarning("Photo Permission", "Description not found in Info.plist")
        }
    }
} else {
    testWarning("Info.plist", "File not found (might be auto-generated)")
}

print()

// MARK: - Test Suite 12: Code Quality Checks
print("✨ Test Suite 12: Code Quality & Best Practices")
print(String(repeating: "-", count: 60))

var totalErrorHandling = 0
var totalAsyncAwait = 0

for (_, path) in views {
    if let content = readFile(path) {
        // Count async/await usage
        let asyncCount = content.components(separatedBy: "async").count - 1
        let awaitCount = content.components(separatedBy: "await").count - 1
        totalAsyncAwait += asyncCount + awaitCount
        
        // Count error handling
        let tryCatch = content.components(separatedBy: "try").count - 1
        totalErrorHandling += tryCatch
    }
}

if totalAsyncAwait > 0 {
    testPassed("Async/await pattern used", "\(totalAsyncAwait) instances found")
} else {
    testWarning("Async Operations", "No async/await detected")
}

if totalErrorHandling > 0 {
    testPassed("Error handling implemented", "\(totalErrorHandling) try statements found")
} else {
    testWarning("Error Handling", "Limited error handling detected")
}

print()

// MARK: - Final Summary
print(String(repeating: "=", count: 60))
print("🎯 Test Summary")
print(String(repeating: "=", count: 60))
print()
print("All automated tests completed!")
print()
print("Next Steps:")
print("1. Run 'xcodebuild' to verify build")
print("2. Launch app in simulator for manual testing")
print("3. Follow the manual testing guide for UI interactions")
print()
print(String(repeating: "=", count: 60))

