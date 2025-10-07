#!/bin/bash

# MacroTrackr - Apple Sign In Setup Script
# This script helps verify your Apple Sign In configuration

echo "🍎 MacroTrackr - Apple Sign In Setup Helper"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "MacroTrackr.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the MacroTrackr project root directory"
    exit 1
fi

echo "✅ Found MacroTrackr project"

# Check Info.plist for Apple Sign In capability
if grep -q "NSAppleSignInUsageDescription" "MacroTrackr/Info.plist"; then
    echo "✅ Apple Sign In usage description found in Info.plist"
else
    echo "❌ Missing Apple Sign In usage description in Info.plist"
fi

# Check if AuthenticationServices is imported
if grep -q "import AuthenticationServices" "MacroTrackr/MacroTrackrApp.swift"; then
    echo "✅ AuthenticationServices framework imported"
else
    echo "❌ AuthenticationServices framework not imported"
fi

# Check for Sign in with Apple button
if grep -q "SignInWithAppleButton" "MacroTrackr/MacroTrackrApp.swift"; then
    echo "✅ Sign in with Apple button implemented"
else
    echo "❌ Sign in with Apple button not found"
fi

# Check for Apple authentication method
if grep -q "signInWithApple" "MacroTrackr/MacroTrackrApp.swift"; then
    echo "✅ Apple authentication method implemented"
else
    echo "❌ Apple authentication method not found"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Open Xcode and add 'Sign In with Apple' capability to your project"
echo "2. Follow the setup guide in supabase-apple-config.md"
echo "3. Configure your Apple Developer account"
echo "4. Test on a physical device (Sign in with Apple doesn't work in simulator)"
echo ""
echo "📚 Documentation:"
echo "- Supabase Apple Auth: https://supabase.com/docs/guides/auth/social-login/auth-apple"
echo "- Apple Sign in with Apple: https://developer.apple.com/sign-in-with-apple/"
echo ""
echo "🔧 Troubleshooting:"
echo "- Make sure you're testing on a physical device"
echo "- Verify your bundle identifier matches your Apple Developer App ID"
echo "- Check that all URLs and IDs match exactly between Apple and Supabase"
