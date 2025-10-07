#!/bin/bash

# MacroTrackr - Build Cleanup Script
echo "🧹 Cleaning MacroTrackr build artifacts..."

# Remove derived data
echo "📁 Removing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MacroTrackr-*

# Remove build folder if it exists
echo "🗂️ Removing build folder..."
rm -rf build/

# Clean any temporary files
echo "🧽 Cleaning temporary files..."
find . -name "*.tmp" -delete
find . -name ".DS_Store" -delete

echo "✅ Build cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Open your MacroTrackr.xcodeproj"
echo "3. Product → Clean Build Folder (⌘+Shift+K)"
echo "4. File → Packages → Reset Package Caches"
echo "5. File → Packages → Resolve Package Versions"
echo "6. Build the project (⌘+B)"
echo ""
echo "This should resolve the Info.plist conflict! 🚀"
