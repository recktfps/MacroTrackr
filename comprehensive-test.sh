#!/bin/bash

# MacroTrackr Comprehensive Testing Suite
# This script will build, run, and test all features of the app

echo "🧪 MacroTrackr Comprehensive Testing Suite"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

test_passed() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

test_failed() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    echo "   Reason: $2"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

echo "📋 Phase 1: Pre-Build Validation"
echo "================================"
echo ""

# Test 1: Check if all required files exist
echo "🔍 Test 1: Checking required files..."
REQUIRED_FILES=(
    "MacroTrackr/MacroTrackrApp.swift"
    "MacroTrackr/Models.swift"
    "MacroTrackr/ContentView.swift"
    "MacroTrackr/DailyView.swift"
    "MacroTrackr/AddMealView.swift"
    "MacroTrackr/SearchView.swift"
    "MacroTrackr/StatsView.swift"
    "MacroTrackr/ProfileView.swift"
    "MacroTrackr/MealDetailView.swift"
    "MacroTrackr/AuthenticationView.swift"
    "MacroTrackrWidget/MacroTrackrWidget.swift"
    "supabase-schema.sql"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    test_passed "All required files present (${#REQUIRED_FILES[@]} files)"
else
    test_failed "Missing ${#MISSING_FILES[@]} required files" "${MISSING_FILES[*]}"
fi

# Test 2: Check for syntax errors
echo ""
echo "🔍 Test 2: Validating Swift syntax..."
SYNTAX_ERRORS=0
for file in MacroTrackr/*.swift MacroTrackrWidget/*.swift; do
    if [ -f "$file" ]; then
        if ! swiftc -parse "$file" 2>/dev/null; then
            ((SYNTAX_ERRORS++))
            echo "   - Syntax error in: $file"
        fi
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    test_passed "No syntax errors found"
else
    test_failed "Found $SYNTAX_ERRORS files with syntax errors" "Run swiftc -parse on individual files for details"
fi

# Test 3: Check for required imports
echo ""
echo "🔍 Test 3: Checking required imports..."
check_import() {
    local file=$1
    local import=$2
    if grep -q "import $import" "$file"; then
        return 0
    else
        return 1
    fi
}

IMPORT_ISSUES=0
# DailyView should have Supabase
if ! check_import "MacroTrackr/DailyView.swift" "Supabase"; then
    echo "   - Missing 'import Supabase' in DailyView.swift"
    ((IMPORT_ISSUES++))
fi
# AddMealView should have Combine
if ! check_import "MacroTrackr/AddMealView.swift" "Combine"; then
    echo "   - Missing 'import Combine' in AddMealView.swift"
    ((IMPORT_ISSUES++))
fi
# MacroTrackrApp should have WidgetKit
if ! check_import "MacroTrackr/MacroTrackrApp.swift" "WidgetKit"; then
    echo "   - Missing 'import WidgetKit' in MacroTrackrApp.swift"
    ((IMPORT_ISSUES++))
fi

if [ $IMPORT_ISSUES -eq 0 ]; then
    test_passed "All required imports present"
else
    test_failed "Missing $IMPORT_ISSUES required imports" "Check import statements in files"
fi

echo ""
echo "📋 Phase 2: Build Validation"
echo "============================"
echo ""

# Test 4: Clean build
echo "🔍 Test 4: Performing clean build..."
echo "   (This will take 2-3 minutes...)"

BUILD_OUTPUT=$(xcodebuild -project MacroTrackr.xcodeproj \
    -scheme MacroTrackr \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    clean build 2>&1)

BUILD_EXIT_CODE=$?

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    test_passed "Clean build succeeded"
else
    test_failed "Build failed" "Check build_output.log for details"
    echo "$BUILD_OUTPUT" > build_output.log
fi

# Test 5: Check for build warnings
echo ""
echo "🔍 Test 5: Checking for build warnings..."
WARNING_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "warning:" || echo "0")

if [ "$WARNING_COUNT" -eq 0 ]; then
    test_passed "No build warnings"
elif [ "$WARNING_COUNT" -lt 5 ]; then
    test_warning "Found $WARNING_COUNT build warnings (acceptable)"
else
    test_warning "Found $WARNING_COUNT build warnings (should investigate)"
fi

echo ""
echo "📋 Phase 3: Code Quality Checks"
echo "==============================="
echo ""

# Test 6: Check for TODO/FIXME comments
echo "🔍 Test 6: Checking for TODO/FIXME comments..."
TODO_COUNT=$(grep -r "TODO\|FIXME" MacroTrackr/*.swift 2>/dev/null | wc -l | tr -d ' ')

if [ "$TODO_COUNT" -eq 0 ]; then
    test_passed "No TODO/FIXME comments found"
else
    test_warning "Found $TODO_COUNT TODO/FIXME comments (informational)"
fi

# Test 7: Check for proper error handling
echo ""
echo "🔍 Test 7: Checking error handling patterns..."
UNHANDLED_TRIES=$(grep -r "try await" MacroTrackr/*.swift | grep -v "try?" | grep -v "do {" | wc -l | tr -d ' ')

if [ "$UNHANDLED_TRIES" -eq 0 ]; then
    test_passed "All async operations have error handling"
else
    test_warning "$UNHANDLED_TRIES async operations may need error handling review"
fi

# Test 8: Check for hardcoded strings (i18n check)
echo ""
echo "🔍 Test 8: Checking for localization readiness..."
HARDCODED_STRINGS=$(grep -rE 'Text\("' MacroTrackr/*.swift | wc -l | tr -d ' ')

if [ "$HARDCODED_STRINGS" -gt 0 ]; then
    test_warning "Found $HARDCODED_STRINGS hardcoded strings (consider localization for production)"
else
    test_passed "No hardcoded strings found"
fi

echo ""
echo "📋 Phase 4: Feature Implementation Checks"
echo "========================================="
echo ""

# Test 9: Authentication features
echo "🔍 Test 9: Checking authentication implementation..."
AUTH_FEATURES=(
    "signUp"
    "signIn"
    "signOut"
    "currentUser"
)
AUTH_FOUND=0
for feature in "${AUTH_FEATURES[@]}"; do
    if grep -q "$feature" MacroTrackr/MacroTrackrApp.swift; then
        ((AUTH_FOUND++))
    fi
done

if [ $AUTH_FOUND -eq ${#AUTH_FEATURES[@]} ]; then
    test_passed "Authentication features implemented ($AUTH_FOUND/${#AUTH_FEATURES[@]})"
else
    test_failed "Missing authentication features" "Found $AUTH_FOUND/${#AUTH_FEATURES[@]} features"
fi

# Test 10: Friend system features
echo ""
echo "🔍 Test 10: Checking friend system implementation..."
FRIEND_FEATURES=(
    "sendFriendRequest"
    "respondToFriendRequest"
    "loadFriends"
    "loadFriendRequests"
)
FRIEND_FOUND=0
for feature in "${FRIEND_FEATURES[@]}"; do
    if grep -q "$feature" MacroTrackr/MacroTrackrApp.swift; then
        ((FRIEND_FOUND++))
    fi
done

if [ $FRIEND_FOUND -eq ${#FRIEND_FEATURES[@]} ]; then
    test_passed "Friend system features implemented ($FRIEND_FOUND/${#FRIEND_FEATURES[@]})"
else
    test_failed "Missing friend system features" "Found $FRIEND_FOUND/${#FRIEND_FEATURES[@]} features"
fi

# Test 11: Meal tracking features
echo ""
echo "🔍 Test 11: Checking meal tracking implementation..."
MEAL_FEATURES=(
    "addMeal"
    "loadTodayMeals"
    "uploadImage"
    "MacroNutrition"
)
MEAL_FOUND=0
for feature in "${MEAL_FEATURES[@]}"; do
    if grep -rq "$feature" MacroTrackr/*.swift; then
        ((MEAL_FOUND++))
    fi
done

if [ $MEAL_FOUND -eq ${#MEAL_FEATURES[@]} ]; then
    test_passed "Meal tracking features implemented ($MEAL_FOUND/${#MEAL_FEATURES[@]})"
else
    test_failed "Missing meal tracking features" "Found $MEAL_FOUND/${#MEAL_FEATURES[@]} features"
fi

# Test 12: Widget implementation
echo ""
echo "🔍 Test 12: Checking widget implementation..."
if [ -f "MacroTrackrWidget/MacroTrackrWidget.swift" ]; then
    if grep -q "TimelineProvider" MacroTrackrWidget/MacroTrackrWidget.swift; then
        test_passed "Widget implemented with TimelineProvider"
    else
        test_failed "Widget missing TimelineProvider" "Check MacroTrackrWidget.swift"
    fi
else
    test_failed "Widget file not found" "MacroTrackrWidget/MacroTrackrWidget.swift"
fi

# Test 13: Camera/Scanner implementation
echo ""
echo "🔍 Test 13: Checking camera/scanner implementation..."
if grep -q "AVCaptureSession" MacroTrackr/AddMealView.swift; then
    if grep -q "CameraManager" MacroTrackr/AddMealView.swift; then
        test_passed "Camera scanning implemented with AVFoundation"
    else
        test_warning "Camera code present but CameraManager may be incomplete"
    fi
else
    test_failed "Camera scanning not implemented" "Check AddMealView.swift"
fi

# Test 14: Search functionality
echo ""
echo "🔍 Test 14: Checking search implementation..."
if grep -q "searchMeals\|performSearch" MacroTrackr/SearchView.swift; then
    test_passed "Search functionality implemented"
else
    test_failed "Search functionality missing" "Check SearchView.swift"
fi

# Test 15: Privacy settings
echo ""
echo "🔍 Test 15: Checking privacy settings..."
if grep -q "PrivacySettingsView" MacroTrackr/ProfileView.swift; then
    if grep -q "savePrivacySettings" MacroTrackr/ProfileView.swift; then
        test_passed "Privacy settings implemented with save functionality"
    else
        test_warning "Privacy settings view exists but save functionality may be incomplete"
    fi
else
    test_failed "Privacy settings not found" "Check ProfileView.swift"
fi

echo ""
echo "📋 Phase 5: Database Schema Validation"
echo "======================================"
echo ""

# Test 16: Check database schema
echo "🔍 Test 16: Validating database schema..."
if [ -f "supabase-schema.sql" ]; then
    REQUIRED_TABLES=(
        "profiles"
        "meals"
        "saved_meals"
        "friend_requests"
        "friendships"
    )
    TABLES_FOUND=0
    for table in "${REQUIRED_TABLES[@]}"; do
        if grep -q "CREATE TABLE.*$table" supabase-schema.sql; then
            ((TABLES_FOUND++))
        fi
    done
    
    if [ $TABLES_FOUND -eq ${#REQUIRED_TABLES[@]} ]; then
        test_passed "All required database tables defined ($TABLES_FOUND/${#REQUIRED_TABLES[@]})"
    else
        test_failed "Missing database tables" "Found $TABLES_FOUND/${#REQUIRED_TABLES[@]} tables"
    fi
else
    test_failed "Database schema file not found" "supabase-schema.sql"
fi

# Test 17: Check RLS policies
echo ""
echo "🔍 Test 17: Checking RLS policies..."
RLS_POLICIES=$(grep -c "CREATE POLICY" supabase-schema.sql 2>/dev/null || echo "0")

if [ "$RLS_POLICIES" -gt 10 ]; then
    test_passed "RLS policies defined ($RLS_POLICIES policies)"
elif [ "$RLS_POLICIES" -gt 5 ]; then
    test_warning "Some RLS policies defined ($RLS_POLICIES policies, may need more)"
else
    test_failed "Insufficient RLS policies" "Found only $RLS_POLICIES policies"
fi

# Test 18: Check storage buckets
echo ""
echo "🔍 Test 18: Checking storage bucket configuration..."
if grep -q "meal-images" supabase-schema.sql && grep -q "profile-images" supabase-schema.sql; then
    test_passed "Storage buckets configured (meal-images, profile-images)"
else
    test_failed "Storage buckets not properly configured" "Check supabase-schema.sql"
fi

echo ""
echo "📋 Phase 6: Runtime Checks (Simulator Required)"
echo "==============================================="
echo ""

# Test 19: Check if simulator is available
echo "🔍 Test 19: Checking iOS Simulator availability..."
SIMULATOR_COUNT=$(xcrun simctl list devices available | grep "iPhone" | wc -l | tr -d ' ')

if [ "$SIMULATOR_COUNT" -gt 0 ]; then
    test_passed "iOS Simulators available ($SIMULATOR_COUNT devices)"
else
    test_failed "No iOS Simulators available" "Check Xcode installation"
fi

# Test 20: Try to boot simulator
echo ""
echo "🔍 Test 20: Checking simulator boot capability..."
SIMULATOR_UUID=$(xcrun simctl list devices available | grep "iPhone 17" | head -1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -n "$SIMULATOR_UUID" ]; then
    BOOT_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_UUID" | grep -o "Booted\|Shutdown")
    if [ "$BOOT_STATE" = "Booted" ]; then
        test_passed "Simulator already booted (UUID: ${SIMULATOR_UUID:0:8}...)"
    elif [ "$BOOT_STATE" = "Shutdown" ]; then
        test_warning "Simulator available but not booted (can boot for testing)"
    fi
else
    test_warning "Could not detect simulator UUID"
fi

echo ""
echo "=========================================="
echo "📊 TEST RESULTS SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests Run:    $TOTAL_TESTS"
echo -e "Passed:            ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:            ${RED}$FAILED_TESTS${NC}"
echo -e "Warnings:          ${YELLOW}$WARNINGS${NC}"
echo ""

# Calculate pass rate
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Pass Rate:          $PASS_RATE%"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
        echo "The app is ready for manual testing on the simulator."
        echo ""
        echo "Next steps:"
        echo "  1. Boot simulator: xcrun simctl boot 'iPhone 17'"
        echo "  2. Run app: xcodebuild ... run"
        echo "  3. Or open in Xcode: open MacroTrackr.xcodeproj"
        exit 0
    elif [ $PASS_RATE -ge 80 ]; then
        echo -e "${YELLOW}⚠️  MOSTLY PASSING${NC}"
        echo "Most tests passed, but there are some issues to address."
        exit 1
    else
        echo -e "${RED}❌ MULTIPLE FAILURES${NC}"
        echo "Several tests failed. Review the output above for details."
        exit 1
    fi
fi

