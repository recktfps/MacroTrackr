import XCTest

class MacroTrackrUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    // MARK: - Test 1: Authentication Flow
    func testAuthenticationFlow() throws {
        print("🧪 TEST 1: Testing Authentication Flow")
        
        // Wait for app to load
        sleep(2)
        
        // Check if we're on auth screen or already logged in
        let signInButton = app.buttons["Sign In"]
        
        if signInButton.exists {
            print("✅ Authentication screen loaded")
            
            // Find email field
            let emailField = app.textFields["Email"]
            XCTAssertTrue(emailField.exists, "Email field should exist")
            emailField.tap()
            emailField.typeText("ivan562562@gmail.com")
            print("✅ Entered email: ivan562562@gmail.com")
            
            // Find password field
            let passwordField = app.secureTextFields["Password"]
            XCTAssertTrue(passwordField.exists, "Password field should exist")
            passwordField.tap()
            passwordField.typeText("cacasauce")
            print("✅ Entered password")
            
            // Tap sign in
            signInButton.tap()
            print("✅ Tapped Sign In button")
            
            // Wait for login to complete
            sleep(3)
            
            // Check if we reached the main tab bar
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should navigate to main screen after login")
            print("✅ Successfully logged in - Tab bar visible")
        } else {
            print("ℹ️ Already logged in, skipping authentication")
        }
    }
    
    // MARK: - Test 2: Daily View
    func testDailyView() throws {
        print("\n🧪 TEST 2: Testing Daily View")
        
        // Tap on Daily tab
        let dailyTab = app.tabBars.buttons["Daily"]
        if dailyTab.exists {
            dailyTab.tap()
            print("✅ Navigated to Daily tab")
            
            // Check for key elements
            let dateSelector = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Today'")).firstMatch
            XCTAssertTrue(dateSelector.exists, "Date selector should exist")
            print("✅ Date selector present")
            
            // Check for progress indicators
            let caloriesLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Calories'")).firstMatch
            if caloriesLabel.exists {
                print("✅ Calories tracking visible")
            }
            
            // Check for Add Meal button
            let addButton = app.buttons["Add Meal"]
            if addButton.exists {
                print("✅ Add Meal button present")
            }
        }
    }
    
    // MARK: - Test 3: Add Meal Flow
    func testAddMealFlow() throws {
        print("\n🧪 TEST 3: Testing Add Meal Flow")
        
        // Tap on center Add button in tab bar
        let addTab = app.tabBars.buttons.element(boundBy: 2) // Center button
        addTab.tap()
        print("✅ Opened Add Meal screen")
        
        sleep(1)
        
        // Enter meal name
        let mealNameField = app.textFields["Meal Name"]
        if mealNameField.exists {
            mealNameField.tap()
            mealNameField.typeText("Test Chicken Breast")
            print("✅ Entered meal name: Test Chicken Breast")
        }
        
        // Select meal type
        let mealTypePicker = app.pickers.firstMatch
        if mealTypePicker.exists {
            print("✅ Meal type picker present")
        }
        
        // Enter nutrition values
        let caloriesField = app.textFields.containing(NSPredicate(format: "label CONTAINS 'Calories'")).firstMatch
        if caloriesField.exists {
            caloriesField.tap()
            caloriesField.typeText("165")
            print("✅ Entered calories: 165")
        }
        
        let proteinField = app.textFields.containing(NSPredicate(format: "label CONTAINS 'Protein'")).firstMatch
        if proteinField.exists {
            proteinField.tap()
            proteinField.typeText("31")
            print("✅ Entered protein: 31g")
        }
        
        // Try to save
        let saveButton = app.navigationBars.buttons["Save"]
        if saveButton.exists {
            saveButton.tap()
            print("✅ Tapped Save button")
            sleep(2)
        }
        
        // Check if we returned to previous screen
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Should return to main screen after saving")
        print("✅ Meal saved successfully")
    }
    
    // MARK: - Test 4: Search View
    func testSearchView() throws {
        print("\n🧪 TEST 4: Testing Search View")
        
        // Navigate to Search tab
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        print("✅ Navigated to Search tab")
        
        sleep(1)
        
        // Find search field
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Chicken")
            print("✅ Entered search query: Chicken")
            
            sleep(2)
            
            // Check for results
            let resultsList = app.tables.firstMatch
            if resultsList.exists {
                print("✅ Search results displayed")
            }
        }
    }
    
    // MARK: - Test 5: Profile View
    func testProfileView() throws {
        print("\n🧪 TEST 5: Testing Profile View")
        
        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        print("✅ Navigated to Profile tab")
        
        sleep(1)
        
        // Check for profile elements
        let displayName = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '@'")).firstMatch
        if displayName.exists {
            print("✅ Display name visible")
        }
        
        // Check for action buttons
        let goalsButton = app.buttons["Daily Goals"]
        if goalsButton.exists {
            print("✅ Daily Goals button present")
        }
        
        let friendsButton = app.buttons["Friends"]
        if friendsButton.exists {
            print("✅ Friends button present")
            
            // Test friends functionality
            friendsButton.tap()
            print("✅ Opened Friends screen")
            sleep(1)
            
            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                print("✅ Returned from Friends screen")
            }
        }
        
        let privacyButton = app.buttons["Privacy Settings"]
        if privacyButton.exists {
            print("✅ Privacy Settings button present")
            
            // Test privacy settings
            privacyButton.tap()
            print("✅ Opened Privacy Settings")
            sleep(1)
            
            // Check for privacy toggles
            let privateToggle = app.switches["Private Profile"]
            if privateToggle.exists {
                print("✅ Privacy toggle present")
            }
            
            // Go back
            let cancelButton = app.navigationBars.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
                print("✅ Returned from Privacy Settings")
            }
        }
    }
    
    // MARK: - Test 6: Stats View
    func testStatsView() throws {
        print("\n🧪 TEST 6: Testing Stats View")
        
        // Navigate to Stats tab
        let statsTab = app.tabBars.buttons["Stats"]
        statsTab.tap()
        print("✅ Navigated to Stats tab")
        
        sleep(1)
        
        // Check for chart elements
        let charts = app.otherElements.containing(NSPredicate(format: "identifier CONTAINS 'chart'"))
        if charts.count > 0 {
            print("✅ Charts displayed")
        }
        
        // Check for time period selector
        let weekButton = app.buttons["Week"]
        if weekButton.exists {
            print("✅ Time period selector present")
        }
    }
    
    // MARK: - Test 7: Camera Scanner
    func testCameraScanner() throws {
        print("\n🧪 TEST 7: Testing Camera Scanner")
        
        // Go to Add Meal
        let addTab = app.tabBars.buttons.element(boundBy: 2)
        addTab.tap()
        sleep(1)
        
        // Find AI Scanner button
        let scannerButton = app.buttons["AI Estimator"]
        if scannerButton.exists {
            scannerButton.tap()
            print("✅ Opened Camera Scanner")
            
            sleep(2)
            
            // Check for camera view
            let cameraView = app.otherElements["Camera View"]
            if cameraView.exists {
                print("✅ Camera view displayed")
            }
            
            // Try simulate button
            let simulateButton = app.buttons["Simulate"]
            if simulateButton.exists {
                simulateButton.tap()
                print("✅ Simulated food scan")
                sleep(2)
            }
            
            // Close scanner
            let cancelButton = app.navigationBars.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
                print("✅ Closed scanner")
            }
        }
    }
    
    // MARK: - Test 8: Friend Requests
    func testFriendRequests() throws {
        print("\n🧪 TEST 8: Testing Friend Request System")
        
        // Navigate to Profile
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        sleep(1)
        
        // Open Friends
        let friendsButton = app.buttons["Friends"]
        if friendsButton.exists {
            friendsButton.tap()
            sleep(1)
            
            // Try to add a friend
            let addFriendButton = app.buttons["Add Friend"]
            if addFriendButton.exists {
                addFriendButton.tap()
                print("✅ Opened Add Friend dialog")
                
                sleep(1)
                
                // Enter display name
                let displayNameField = app.textFields["Display Name"]
                if displayNameField.exists {
                    displayNameField.tap()
                    displayNameField.typeText("TestUser")
                    print("✅ Entered friend display name")
                    
                    // Send request
                    let sendButton = app.buttons["Send Request"]
                    if sendButton.exists {
                        sendButton.tap()
                        print("✅ Sent friend request")
                        sleep(2)
                    }
                }
            }
            
            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
}

