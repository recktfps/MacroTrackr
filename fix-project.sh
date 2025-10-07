#!/bin/bash

# MacroTrackr - Project Fix Script
echo "🔧 Fixing MacroTrackr project configuration..."

# Remove the existing Info.plist file to prevent conflicts
echo "🗑️ Removing existing Info.plist..."
rm -f MacroTrackr/Info.plist

# Clean all build artifacts
echo "🧹 Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MacroTrackr-*
rm -rf build/

echo "✅ Project cleanup complete!"
echo ""
echo "🔧 Manual Steps Required:"
echo ""
echo "1. Open Xcode"
echo "2. Open MacroTrackr.xcodeproj"
echo "3. Select the MacroTrackr target"
echo "4. Go to Build Settings"
echo "5. Search for 'Info.plist File'"
echo "6. Set 'Info.plist File' to: \$(SRCROOT)/MacroTrackr/Info.plist"
echo "7. Search for 'Generate Info.plist File'"
echo "8. Set 'Generate Info.plist File' to: YES"
echo "9. Product → Clean Build Folder (⌘+Shift+K)"
echo "10. Build the project (⌘+B)"
echo ""
echo "This will configure Xcode to generate the Info.plist automatically! 🚀"
