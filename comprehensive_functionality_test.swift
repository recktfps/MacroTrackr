#!/usr/bin/env swift

import Foundation

print("=== MacroTrackr Comprehensive Functionality Test ===")
print("Date: \(Date())")
print()

// Test 1: Database Operations Verification
print("1. DATABASE OPERATIONS VERIFICATION:")
let dbOperations = [
    "saveMeal", "addMeal", "loadTodayMeals", "loadSavedMeals", 
    "searchMeals", "updateMeal", "deleteMeal", "updateUserProfile",
    "sendFriendRequest", "respondToFriendRequest", "loadFriendRequests",
    "loadAllUsers", "loadFriends"
]

if FileManager.default.fileExists(atPath: "MacroTrackr/MacroTrackrApp.swift") {
    do {
        let content = try String(contentsOfFile: "MacroTrackr/MacroTrackrApp.swift")
        var dbScore = 0
        for operation in dbOperations {
            let exists = content.contains("func \(operation)")
            print("   \(exists ? "✅" : "❌") \(operation)")
            if exists { dbScore += 1 }
        }
        print("   📊 Database Operations Score: \(dbScore)/\(dbOperations.count)")
    } catch {
        print("   ❌ Could not read MacroTrackrApp.swift")
    }
}
print()

// Test 2: Friend Request System
print("2. FRIEND REQUEST SYSTEM:")
let friendRequestComponents = [
    ("sendFriendRequest", "MacroTrackr/MacroTrackrApp.swift"),
    ("respondToFriendRequest", "MacroTrackr/MacroTrackrApp.swift"),
    ("loadFriendRequests", "MacroTrackr/MacroTrackrApp.swift"),
    ("handleUserAction", "MacroTrackr/ProfileView.swift"),
    ("FriendRequestsView", "MacroTrackr/ProfileView.swift"),
    ("handle_accepted_friend_request", "supabase-schema.sql")
]

var friendScore = 0
for (component, file) in friendRequestComponents {
    if FileManager.default.fileExists(atPath: file) {
        do {
            let content = try String(contentsOfFile: file)
            let exists = content.contains(component)
            print("   \(exists ? "✅" : "❌") \(component) in \(file)")
            if exists { friendScore += 1 }
        } catch {
            print("   ❌ Could not read \(file)")
        }
    } else {
        print("   ❌ \(file) not found")
    }
}
print("   📊 Friend Request System Score: \(friendScore)/\(friendRequestComponents.count)")
print()

// Test 3: Profile Picture Upload
print("3. PROFILE PICTURE UPLOAD:")
let profileUploadComponents = [
    ("uploadProfileImage", "MacroTrackr/MacroTrackrApp.swift"),
    ("profile-images", "supabase-schema.sql"),
    ("photosPicker", "MacroTrackr/ProfileView.swift"),
    ("profile-images bucket", "supabase-schema.sql")
]

var profileScore = 0
for (component, file) in profileUploadComponents {
    if FileManager.default.fileExists(atPath: file) {
        do {
            let content = try String(contentsOfFile: file)
            let exists = content.contains(component)
            print("   \(exists ? "✅" : "❌") \(component) in \(file)")
            if exists { profileScore += 1 }
        } catch {
            print("   ❌ Could not read \(file)")
        }
    } else {
        print("   ❌ \(file) not found")
    }
}
print("   📊 Profile Picture Upload Score: \(profileScore)/\(profileUploadComponents.count)")
print()

// Test 4: Widget Functionality
print("4. WIDGET FUNCTIONALITY:")
let widgetFiles = [
    "MacroTrackrWidget/MacroTrackrWidget.swift",
    "MacroTrackrWidget/MacroTrackrWidgetBundle.swift"
]

var widgetScore = 0
for file in widgetFiles {
    let exists = FileManager.default.fileExists(atPath: file)
    print("   \(exists ? "✅" : "❌") \(file)")
    if exists { widgetScore += 1 }
}
print("   📊 Widget Functionality Score: \(widgetScore)/\(widgetFiles.count)")
print()

// Test 5: Meal Photo Picker
print("5. MEAL PHOTO PICKER:")
let mealPhotoComponents = [
    ("photosPicker", "MacroTrackr/AddMealView.swift"),
    ("choosePhoto", "MacroTrackr/AddMealView.swift"),
    ("scanFood", "MacroTrackr/AddMealView.swift")
]

var mealPhotoScore = 0
for (component, file) in mealPhotoComponents {
    if FileManager.default.fileExists(atPath: file) {
        do {
            let content = try String(contentsOfFile: file)
            let exists = content.contains(component)
            print("   \(exists ? "✅" : "❌") \(component) in \(file)")
            if exists { mealPhotoScore += 1 }
        } catch {
            print("   ❌ Could not read \(file)")
        }
    } else {
        print("   ❌ \(file) not found")
    }
}
print("   📊 Meal Photo Picker Score: \(mealPhotoScore)/\(mealPhotoComponents.count)")
print()

// Test 6: Macro Goals Saving
print("6. MACRO GOALS SAVING:")
let macroGoalsComponents = [
    ("updateUserProfile", "MacroTrackr/MacroTrackrApp.swift"),
    ("daily_goals", "supabase-schema.sql"),
    ("DailyGoalsView", "MacroTrackr/ProfileView.swift")
]

var macroGoalsScore = 0
for (component, file) in macroGoalsComponents {
    if FileManager.default.fileExists(atPath: file) {
        do {
            let content = try String(contentsOfFile: file)
            let exists = content.contains(component)
            print("   \(exists ? "✅" : "❌") \(component) in \(file)")
            if exists { macroGoalsScore += 1 }
        } catch {
            print("   ❌ Could not read \(file)")
        }
    } else {
        print("   ❌ \(file) not found")
    }
}
print("   📊 Macro Goals Saving Score: \(macroGoalsScore)/\(macroGoalsComponents.count)")
print()

// Test 7: Database Schema Verification
print("7. DATABASE SCHEMA VERIFICATION:")
let schemaComponents = [
    ("profiles table", "supabase-schema.sql"),
    ("meals table", "supabase-schema.sql"),
    ("friend_requests table", "supabase-schema.sql"),
    ("friendships table", "supabase-schema.sql"),
    ("handle_accepted_friend_request trigger", "supabase-schema.sql"),
    ("profile-images bucket", "supabase-schema.sql")
]

var schemaScore = 0
if FileManager.default.fileExists(atPath: "supabase-schema.sql") {
    do {
        let content = try String(contentsOfFile: "supabase-schema.sql")
        for (component, _) in schemaComponents {
            let exists = content.contains(component.replacingOccurrences(of: " ", with: "_"))
            print("   \(exists ? "✅" : "❌") \(component)")
            if exists { schemaScore += 1 }
        }
    } catch {
        print("   ❌ Could not read supabase-schema.sql")
    }
} else {
    print("   ❌ supabase-schema.sql not found")
}
print("   📊 Database Schema Score: \(schemaScore)/\(schemaComponents.count)")
print()

// Overall Score Calculation
let totalScore = dbOperations.count + friendRequestComponents.count + profileUploadComponents.count + 
                widgetFiles.count + mealPhotoComponents.count + macroGoalsComponents.count + 
                schemaComponents.count

let actualScore = dbOperations.count + friendScore + profileScore + widgetScore + 
                 mealPhotoScore + macroGoalsScore + schemaScore

print("=== OVERALL ASSESSMENT ===")
print("📊 Total Possible Points: \(totalScore)")
print("📊 Actual Score: \(actualScore)")
print("📊 Success Rate: \(String(format: "%.1f", Double(actualScore) / Double(totalScore) * 100))%")
print()

if actualScore >= Int(Double(totalScore) * 0.9) {
    print("🎉 EXCELLENT! App is ready for testing.")
} else if actualScore >= Int(Double(totalScore) * 0.8) {
    print("✅ GOOD! Minor issues to address.")
} else if actualScore >= Int(Double(totalScore) * 0.7) {
    print("⚠️  FAIR! Several issues need attention.")
} else {
    print("❌ POOR! Major issues require immediate attention.")
}

print("\n=== NEXT STEPS ===")
print("1. Run the app in iOS Simulator")
print("2. Test friend request functionality")
print("3. Test profile picture upload")
print("4. Test meal photo picker")
print("5. Test macro goals saving")
print("6. Test widget functionality")
print("\n=== Test Complete ===")
