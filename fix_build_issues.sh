#!/bin/bash

echo "🔧 MacroTrackr Build Fix Script"
echo "================================"

echo "📱 Opening Xcode..."
open MacroTrackr.xcodeproj

echo ""
echo "📋 MANUAL STEPS TO FOLLOW IN XCODE:"
echo "===================================="
echo ""
echo "1. Wait for Xcode to fully load the project"
echo ""
echo "2. In Xcode, go to:"
echo "   File → Packages → Reset Package Caches"
echo ""
echo "3. Then go to:"
echo "   File → Packages → Resolve Package Versions"
echo ""
echo "4. Wait for all packages to resolve (this may take a few minutes)"
echo ""
echo "5. Once packages are resolved, try building:"
echo "   Product → Clean Build Folder (Cmd+Shift+K)"
echo "   Product → Build (Cmd+B)"
echo ""
echo "6. If build succeeds, run the app:"
echo "   Product → Run (Cmd+R)"
echo ""
echo "⚠️  If you still get errors:"
echo "   - Check the app icon files are properly added to Assets.xcassets"
echo "   - Make sure all required app icon sizes are present"
echo "   - Verify the bundle identifier is correct"
echo ""
echo "💡 TROUBLESHOOTING TIPS:"
echo "   - Make sure your disk has at least 5GB free space"
echo "   - Close other apps to free up memory"
echo "   - Restart Xcode if packages won't resolve"
echo ""
echo "✅ The app should build and run successfully after following these steps!"

# Wait a moment then check if Xcode opened successfully
sleep 3
if pgrep -f "Xcode" > /dev/null; then
    echo "✅ Xcode opened successfully!"
else
    echo "⚠️  Xcode may not have opened. Please open it manually:"
    echo "   open MacroTrackr.xcodeproj"
fi

echo ""
echo "🚀 Ready to fix the build issues!"
