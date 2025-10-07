#!/bin/bash

# MacroTrackr - Package Resolution Script
echo "📦 Resolving Swift Package Manager dependencies..."

# Clean derived data
echo "🧹 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MacroTrackr-*

# Clean package caches
echo "📦 Cleaning package caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/UserData/IDESwiftPackageManagerCache/

echo "✅ Package cleanup complete!"
echo ""
echo "🔧 Manual Steps Required in Xcode:"
echo ""
echo "1. Open MacroTrackr.xcodeproj in Xcode"
echo "2. File → Packages → Reset Package Caches"
echo "3. File → Packages → Resolve Package Versions"
echo "4. Wait for packages to download and resolve"
echo "5. Product → Clean Build Folder (⌘+Shift+K)"
echo "6. Build the project (⌘+B)"
echo ""
echo "If packages still don't resolve:"
echo "1. Select the project in the navigator"
echo "2. Select the MacroTrackr target"
echo "3. Go to 'Package Dependencies' tab"
echo "4. Click the '+' button and re-add packages:"
echo "   - https://github.com/supabase/supabase-swift"
echo "   - https://github.com/onevcat/Kingfisher"
echo "   - https://github.com/realm/realm-swift"
echo ""
echo "This will resolve the missing package products! 🚀"
