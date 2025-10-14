#!/usr/bin/env swift

import Foundation

print("🔍 MacroTrackr App Status Check\n")

let workspaceURL = URL(fileURLWithPath: "/Users/ivanmartinez/Desktop/MacroTrackr")

// Define test categories
var totalTests = 0
var passedTests = 0

func checkFile(_ path: String, contains: String, description: String) {
    totalTests += 1
    let fullPath = workspaceURL.appendingPathComponent(path).path
    
    guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
        print("❌ \(description): File not found")
        return
    }
    
    if content.contains(contains) {
        print("✅ \(description)")
        passedTests += 1
    } else {
        print("❌ \(description): Missing '\(contains)'")
    }
}

print("📱 Core Functionality Tests\n")

// Test 1: Friend Request System
checkFile("MacroTrackr/MacroTrackrApp.swift", 
         contains: "func sendFriendRequest(fromUserId: String, toDisplayName: String)",
         description: "Friend request function exists")

checkFile("MacroTrackr/MacroTrackrApp.swift",
         contains: "func respondToFriendRequest(requestId: String, status: FriendRequestStatus, currentUserId: String)",
         description: "Respond to friend request function exists")

checkFile("MacroTrackr/ProfileView.swift",
         contains: "dataManager.loadAllUsers(for:",
         description: "Load users function exists")

// Test 2: Profile Picture Upload
checkFile("MacroTrackr/MacroTrackrApp.swift",
         contains: "func uploadProfileImage(_ imageData: Data, userId: String)",
         description: "Upload profile image function exists")

checkFile("MacroTrackr/ProfileView.swift",
         contains: "PhotosPicker",
         description: "PhotosPicker integrated in ProfileView")

// Test 3: Meal Photo Picker
checkFile("MacroTrackr/AddMealView.swift",
         contains: "PhotosPicker",
         description: "PhotosPicker integrated in AddMealView")

checkFile("MacroTrackr/AddMealView.swift",
         contains: "@State private var selectedImage: PhotosPickerItem?",
         description: "PhotosPicker state variable exists")

// Test 4: Widget Support
checkFile("MacroTrackrWidget/MacroTrackrWidget.swift",
         contains: "struct MacroTrackrWidget",
         description: "Widget structure exists")

checkFile("MacroTrackrWidget/MacroTrackrWidgetBundle.swift",
         contains: "@main",
         description: "Widget bundle properly configured")

// Test 5: Database Schema
checkFile("supabase-schema.sql",
         contains: "CREATE TABLE profiles",
         description: "Profiles table schema exists")

checkFile("supabase-schema.sql",
         contains: "CREATE TABLE friend_requests",
         description: "Friend requests table schema exists")

checkFile("supabase-schema.sql",
         contains: "handle_accepted_friend_request",
         description: "Friend request trigger exists")

checkFile("supabase-schema.sql",
         contains: "profile-images",
         description: "Profile images bucket configured")

// Test 6: UI Components
checkFile("MacroTrackr/DailyView.swift",
         contains: "MacroBadge",
         description: "Macro display component exists")

checkFile("MacroTrackr/SearchView.swift",
         contains: "TextField",
         description: "Search functionality exists")

// Summary
print("\n" + String(repeating: "=", count: 50))
print("Test Results: \(passedTests)/\(totalTests) passed")
let percentage = totalTests > 0 ? (Double(passedTests) / Double(totalTests)) * 100 : 0
print(String(format: "Success Rate: %.1f%%", percentage))

if passedTests == totalTests {
    print("🎉 All tests passed!")
} else if passedTests >= Int(Double(totalTests) * 0.8) {
    print("✅ Most features implemented")
} else {
    print("⚠️  Some features need attention")
}

print(String(repeating: "=", count: 50))

exit(passedTests == totalTests ? 0 : 1)

