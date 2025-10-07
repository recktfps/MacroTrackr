#!/bin/bash

# MacroTrackr - Complete Package Fix Script
echo "🔧 Complete package fix for MacroTrackr..."

# Clean everything
echo "🧹 Cleaning all caches and derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MacroTrackr-*
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/UserData/IDESwiftPackageManagerCache/
rm -rf build/

# Create a backup of the current project
echo "💾 Creating backup..."
cp MacroTrackr.xcodeproj/project.pbxproj MacroTrackr.xcodeproj/project.pbxproj.backup

echo "✅ Complete cleanup finished!"
echo ""
echo "🚨 IMPORTANT: The project file has been corrupted during our fixes."
echo "The best solution is to recreate the project with proper package dependencies."
echo ""
echo "🔧 RECOMMENDED SOLUTION:"
echo ""
echo "1. Create a NEW Xcode project:"
echo "   - File → New → Project"
echo "   - iOS → App"
echo "   - Product Name: MacroTrackr"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Use Core Data: NO"
echo ""
echo "2. Add Swift Package Dependencies:"
echo "   - File → Add Package Dependencies"
echo "   - Add these URLs one by one:"
echo "     • https://github.com/supabase/supabase-swift"
echo "     • https://github.com/onevcat/Kingfisher"
echo "     • https://github.com/realm/realm-swift"
echo ""
echo "3. Copy your source files:"
echo "   - Copy MacroTrackrApp.swift from this project"
echo "   - Copy all other .swift files from the MacroTrackr folder"
echo "   - Copy Info.plist settings"
echo ""
echo "4. Configure capabilities:"
echo "   - Add Camera, Photo Library, Push Notifications"
echo "   - Add Sign in with Apple if needed"
echo ""
echo "This will give you a clean, working project with all dependencies! 🚀"
echo ""
echo "Alternative: Try opening the current project and:"
echo "1. File → Packages → Reset Package Caches"
echo "2. File → Packages → Resolve Package Versions"
echo "3. If that fails, remove and re-add all packages manually"
