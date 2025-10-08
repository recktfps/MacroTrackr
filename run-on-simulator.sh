#!/bin/bash

echo "🚀 Running MacroTrackr on iOS Simulator"
echo "======================================="
echo ""

# Boot the simulator first
echo "📱 Booting iPhone 17 Simulator..."
xcrun simctl boot "iPhone 17" 2>/dev/null || echo "Simulator already booted"

# Open Simulator app
echo "🖥️  Opening Simulator app..."
open -a Simulator

# Wait a moment for simulator to be ready
sleep 3

# Build and run
echo "🔨 Building and installing app..."
xcodebuild -project MacroTrackr.xcodeproj \
  -scheme MacroTrackr \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | grep -E "(BUILD|Compiling)" | tail -5

echo ""
echo "📲 Installing app on simulator..."

# Get the app bundle path
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/MacroTrackr-*/Build/Products/Debug-iphonesimulator/MacroTrackr.app 2>/dev/null | head -1)

if [ -n "$APP_PATH" ]; then
    echo "✅ App built successfully at: $APP_PATH"
    
    # Install the app
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 17" | grep "Booted" | grep -oE '\([A-F0-9-]+\)' | tr -d '()')
    
    if [ -n "$DEVICE_ID" ]; then
        xcrun simctl install "$DEVICE_ID" "$APP_PATH"
        
        # Launch the app
        echo "🚀 Launching MacroTrackr..."
        xcrun simctl launch "$DEVICE_ID" com.macrotrackr.MacroTrackr
        
        echo ""
        echo "✅ App launched successfully!"
        echo ""
        echo "👀 Check the Simulator window to see your app running"
    else
        echo "❌ Simulator not booted. Run: open -a Simulator"
    fi
else
    echo "❌ Could not find built app. Try building in Xcode first."
fi

