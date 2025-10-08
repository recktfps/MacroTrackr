#!/bin/bash

echo "🔨 MacroTrackr Build & Fix Script"
echo "================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get available iOS simulators
get_available_simulators() {
    xcrun simctl list devices available | grep "iPhone" | head -5
}

# Function to run build with error capture
run_build() {
    local simulator_name="$1"
    echo "📱 Building for simulator: $simulator_name"
    
    # Run build and capture both stdout and stderr
    local build_output
    build_output=$(xcodebuild -project MacroTrackr.xcodeproj -scheme MacroTrackr -destination "platform=iOS Simulator,name=$simulator_name" build 2>&1)
    local exit_code=$?
    
    # Save build output to file for analysis
    echo "$build_output" > build_output.log
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Build successful!"
        return 0
    else
        echo "❌ Build failed with exit code: $exit_code"
        echo "📄 Full build output saved to build_output.log"
        
        # Extract and display key errors
        echo ""
        echo "🔍 Key compilation errors:"
        echo "-------------------------"
        grep -E "(error:|warning:)" build_output.log | head -10
        
        return $exit_code
    fi
}

# Function to fix common Swift compilation errors
fix_swift_errors() {
    echo ""
    echo "🔧 Attempting to fix common Swift errors..."
    
    # Check for missing imports
    if grep -q "Cannot find type\|Use of unresolved identifier" build_output.log; then
        echo "🔍 Found potential import issues..."
        
        # Check if WidgetKit import is missing in main app
        if ! grep -q "import WidgetKit" MacroTrackr/MacroTrackrApp.swift; then
            echo "➕ Adding WidgetKit import to MacroTrackrApp.swift"
            sed -i '' '1a\
import WidgetKit
' MacroTrackr/MacroTrackrApp.swift
        fi
        
        # Check if AVFoundation import is missing in AddMealView
        if ! grep -q "import AVFoundation" MacroTrackr/AddMealView.swift; then
            echo "➕ Adding AVFoundation import to AddMealView.swift"
            sed -i '' '1a\
import AVFoundation
' MacroTrackr/AddMealView.swift
        fi
    fi
    
    # Check for syntax errors
    if grep -q "Expected.*after\|Missing.*in" build_output.log; then
        echo "🔍 Found potential syntax errors..."
        
        # Check for missing closing braces or parentheses
        echo "🔧 Checking for syntax issues in Swift files..."
        
        # Check DailyView for syntax issues
        if [ -f "MacroTrackr/DailyView.swift" ]; then
            echo "🔧 Validating DailyView.swift syntax..."
            swiftc -parse MacroTrackr/DailyView.swift 2>&1 | head -5
        fi
        
        # Check AddMealView for syntax issues
        if [ -f "MacroTrackr/AddMealView.swift" ]; then
            echo "🔧 Validating AddMealView.swift syntax..."
            swiftc -parse MacroTrackr/AddMealView.swift 2>&1 | head -5
        fi
    fi
    
    # Check for missing conformances
    if grep -q "does not conform to protocol\|Type.*cannot conform to" build_output.log; then
        echo "🔍 Found protocol conformance issues..."
        echo "🔧 These may require manual fixes in the code"
    fi
}

# Function to check for missing files
check_missing_files() {
    echo ""
    echo "📁 Checking for missing required files..."
    
    local missing_files=()
    
    # Check for required Swift files
    local required_files=(
        "MacroTrackr/MacroTrackrApp.swift"
        "MacroTrackr/ContentView.swift"
        "MacroTrackr/DailyView.swift"
        "MacroTrackr/AddMealView.swift"
        "MacroTrackr/ProfileView.swift"
        "MacroTrackr/SearchView.swift"
        "MacroTrackr/StatsView.swift"
        "MacroTrackr/MealDetailView.swift"
        "MacroTrackr/AuthenticationView.swift"
        "MacroTrackr/Models.swift"
        "MacroTrackrWidget/MacroTrackrWidget.swift"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo "❌ Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "   - $file"
        done
        return 1
    else
        echo "✅ All required files present"
        return 0
    fi
}

# Function to validate Swift syntax
validate_swift_syntax() {
    echo ""
    echo "🔍 Validating Swift syntax..."
    
    local swift_files=(
        "MacroTrackr/MacroTrackrApp.swift"
        "MacroTrackr/DailyView.swift"
        "MacroTrackr/AddMealView.swift"
        "MacroTrackr/ProfileView.swift"
        "MacroTrackrWidget/MacroTrackrWidget.swift"
    )
    
    local syntax_errors=0
    
    for file in "${swift_files[@]}"; do
        if [ -f "$file" ]; then
            echo "🔧 Checking syntax: $file"
            local parse_output
            parse_output=$(swiftc -parse "$file" 2>&1)
            if [ $? -ne 0 ]; then
                echo "❌ Syntax error in $file:"
                echo "$parse_output" | head -3
                syntax_errors=$((syntax_errors + 1))
            else
                echo "✅ $file syntax OK"
            fi
        fi
    done
    
    return $syntax_errors
}

# Function to clean and rebuild
clean_and_rebuild() {
    echo ""
    echo "🧹 Cleaning build artifacts..."
    
    # Clean derived data
    rm -rf ~/Library/Developer/Xcode/DerivedData/MacroTrackr-*
    
    # Clean build folder
    xcodebuild clean -project MacroTrackr.xcodeproj -scheme MacroTrackr
    
    echo "✅ Clean completed"
}

# Main execution
main() {
    echo "🚀 Starting build and fix process..."
    
    # Check prerequisites
    if ! command_exists xcodebuild; then
        echo "❌ xcodebuild not found. Please install Xcode Command Line Tools."
        exit 1
    fi
    
    # Get available simulators
    echo ""
    echo "📱 Available iOS Simulators:"
    get_available_simulators
    echo ""
    
    # Check for missing files first
    if ! check_missing_files; then
        echo "❌ Missing required files. Please ensure all Swift files are present."
        exit 1
    fi
    
    # Validate Swift syntax
    if ! validate_swift_syntax; then
        echo "❌ Swift syntax errors found. Attempting fixes..."
        fix_swift_errors
        
        # Re-validate after fixes
        echo ""
        echo "🔍 Re-validating syntax after fixes..."
        if ! validate_swift_syntax; then
            echo "❌ Still have syntax errors. Manual intervention required."
            exit 1
        fi
    fi
    
    # Try building with first available simulator
    local simulator_name="iPhone 17"
    
    # First attempt
    if ! run_build "$simulator_name"; then
        echo ""
        echo "🔧 Build failed. Attempting fixes..."
        fix_swift_errors
        
        # Clean and try again
        clean_and_rebuild
        
        echo ""
        echo "🔄 Retrying build after fixes..."
        if ! run_build "$simulator_name"; then
            echo ""
            echo "❌ Build still failing after fixes."
            echo "📄 Check build_output.log for detailed error information."
            echo ""
            echo "🔍 Common issues to check manually:"
            echo "   - Missing imports in Swift files"
            echo "   - Syntax errors (missing braces, parentheses)"
            echo "   - Protocol conformance issues"
            echo "   - Missing required methods or properties"
            echo ""
            echo "💡 Try opening the project in Xcode for detailed error analysis."
            exit 1
        fi
    fi
    
    echo ""
    echo "🎉 SUCCESS! MacroTrackr builds successfully!"
    echo ""
    echo "✅ All compilation errors have been resolved."
    echo "📱 App is ready to run on iOS Simulator."
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Open MacroTrackr.xcodeproj in Xcode"
    echo "   2. Select a simulator and press Run (⌘+R)"
    echo "   3. Test the app functionality"
}

# Run main function
main "$@"
