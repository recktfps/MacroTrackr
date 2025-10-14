#!/usr/bin/env swift

import Foundation

// Test script to verify current app functionality
print("=== MacroTrackr Current Status Test ===")
print("Date: \(Date())")
print()

// Test 1: Check if key files exist
let keyFiles = [
    "MacroTrackr/MacroTrackrApp.swift",
    "MacroTrackr/ProfileView.swift", 
    "MacroTrackr/DailyView.swift",
    "MacroTrackr/AddMealView.swift",
    "MacroTrackr/Models.swift",
    "supabase-schema.sql"
]

print("1. File Structure Check:")
for file in keyFiles {
    let exists = FileManager.default.fileExists(atPath: file)
    print("   \(exists ? "✅" : "❌") \(file)")
}
print()

// Test 2: Check for friend request functionality
print("2. Friend Request System Check:")
let friendRequestFiles = [
    "MacroTrackr/MacroTrackrApp.swift": ["sendFriendRequest", "respondToFriendRequest", "loadFriendRequests"],
    "MacroTrackr/ProfileView.swift": ["handleUserAction", "FriendRequestsView"]
]

for (file, methods) in friendRequestFiles {
    if FileManager.default.fileExists(atPath: file) {
        do {
            let content = try String(contentsOfFile: file)
            for method in methods {
                let exists = content.contains(method)
                print("   \(exists ? "✅" : "❌") \(method) in \(file)")
            }
        } catch {
            print("   ❌ Could not read \(file)")
        }
    }
}
print()

// Test 3: Check for profile picture upload functionality
print("3. Profile Picture Upload Check:")
let profileUploadFiles = [
    "MacroTrackr/MacroTrackrApp.swift": ["uploadProfileImage"],
    "MacroTrackr/ProfileView.swift": ["uploadProfileImage", "photosPicker"]
]

for (file, methods) in profileUploadFiles {
    if FileManager.default.fileExists(atPath: file) {
        do {
            let content = try String(contentsOfFile: file)
            for method in methods {
                let exists = content.contains(method)
                print("   \(exists ? "✅" : "❌") \(method) in \(file)")
            }
        } catch {
            print("   ❌ Could not read \(file)")
        }
    }
}
print()

// Test 4: Check for database operations
print("4. Database Operations Check:")
let dbOperations = [
    "saveMeal", "addMeal", "loadTodayMeals", "loadSavedMeals", 
    "searchMeals", "updateMeal", "deleteMeal", "updateUserProfile"
]

if FileManager.default.fileExists(atPath: "MacroTrackr/MacroTrackrApp.swift") {
    do {
        let content = try String(contentsOfFile: "MacroTrackr/MacroTrackrApp.swift")
        for operation in dbOperations {
            let exists = content.contains("func \(operation)")
            print("   \(exists ? "✅" : "❌") \(operation)")
        }
    } catch {
        print("   ❌ Could not read MacroTrackrApp.swift")
    }
}
print()

// Test 5: Check for widget functionality
print("5. Widget Functionality Check:")
let widgetFiles = [
    "MacroTrackr/MacroTrackrWidget.swift",
    "MacroTrackr/MacroTrackrWidgetBundle.swift"
]

for file in widgetFiles {
    let exists = FileManager.default.fileExists(atPath: file)
    print("   \(exists ? "✅" : "❌") \(file)")
}
print()

print("=== Test Complete ===")
print("Next: Run the app to test actual functionality")
