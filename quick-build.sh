#!/bin/bash

echo "🚀 MacroTrackr Quick Build Test"
echo "==============================="

# Clean derived data first
echo "🧹 Cleaning build cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MacroTrackr-* 2>/dev/null

echo "📱 Building for iPhone 17 Simulator..."
echo "⏳ This will take 2-3 minutes..."
echo ""

# Run build with progress indicator
xcodebuild -project MacroTrackr.xcodeproj \
  -scheme MacroTrackr \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build 2>&1 | \
  tee build_output.log | \
  grep --line-buffered -E "(Building|Linking|Compiling|error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | \
  while IFS= read -r line; do
    if [[ "$line" == *"error:"* ]]; then
      echo "❌ $line"
    elif [[ "$line" == *"warning:"* ]]; then
      echo "⚠️  $line"
    elif [[ "$line" == *"BUILD SUCCEEDED"* ]]; then
      echo ""
      echo "✅ $line"
      echo ""
      echo "🎉 SUCCESS! The app compiled successfully!"
      echo ""
      echo "Next steps:"
      echo "  1. Open Xcode: open MacroTrackr.xcodeproj"
      echo "  2. Press ⌘+R to run on simulator"
      echo "  3. Test all features"
    elif [[ "$line" == *"BUILD FAILED"* ]]; then
      echo ""
      echo "❌ $line"
      echo ""
      echo "Check build_output.log for details"
    else
      # Show progress dots for other lines
      echo -n "."
    fi
  done

# Check final exit code
if [ ${PIPESTATUS[0]} -eq 0 ]; then
  exit 0
else
  echo ""
  echo "Build failed. Check build_output.log for full details."
  exit 1
fi

