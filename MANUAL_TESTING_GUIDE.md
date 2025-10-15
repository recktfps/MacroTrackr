# MacroTrackr Manual Testing Guide

## 🧪 Comprehensive App Testing Checklist

### ✅ Pre-Testing Status
- **Build Status**: ✅ SUCCESS (No errors)
- **App Installation**: ✅ INSTALLED on iPhone 17 Simulator
- **App Launch**: ✅ LAUNCHED (Process ID: 4511)
- **Code Quality**: ✅ 8/10 tests passed (80% success rate)

### 📱 Authentication Testing

#### Test 1.1: Sign Up Flow
- [ ] Tap "Sign Up" button
- [ ] Enter email: `test@example.com`
- [ ] Enter password: `testpassword123`
- [ ] Tap "Sign Up"
- [ ] Verify user is created and logged in
- [ ] Check if profile is created automatically

#### Test 1.2: Sign In Flow
- [ ] Tap "Sign In" button
- [ ] Enter email: `ivan562562@gmail.com`
- [ ] Enter password: `cacasauce`
- [ ] Tap "Sign In"
- [ ] Verify successful login
- [ ] Check if user profile loads correctly

#### Test 1.3: Apple Sign In
- [ ] Tap "Sign in with Apple" button
- [ ] Complete Apple ID authentication
- [ ] Verify successful login
- [ ] Check profile creation

### 🍽️ Meal Management Testing

#### Test 2.1: Add Meal (Basic)
- [ ] Navigate to "Add Meal" tab
- [ ] Enter meal name: "Grilled Chicken"
- [ ] Enter calories: 250
- [ ] Enter protein: 30g
- [ ] Enter carbs: 5g
- [ ] Enter fats: 12g
- [ ] Enter sugar: 2g
- [ ] Enter fiber: 1g
- [ ] Tap "Save Meal"
- [ ] Verify meal appears in Today's view

#### Test 2.2: Add Meal with Photo
- [ ] Navigate to "Add Meal" tab
- [ ] Tap "Choose Photo from Library"
- [ ] Select a food photo from library
- [ ] Verify photo appears in meal form
- [ ] Fill in meal details
- [ ] Save meal
- [ ] Verify meal with photo appears in Today's view

#### Test 2.3: Add Meal with AI Scan
- [ ] Navigate to "Add Meal" tab
- [ ] Tap "Scan Food with AI"
- [ ] Point camera at food item
- [ ] Wait for AI analysis
- [ ] Verify macro estimates appear
- [ ] Adjust quantities if needed
- [ ] Save meal
- [ ] Verify scanned meal appears in Today's view

#### Test 2.4: Add Meal for Different Date
- [ ] Navigate to "Today" tab
- [ ] Tap date picker (top left)
- [ ] Select yesterday's date
- [ ] Tap "Add Meal"
- [ ] Fill in meal details
- [ ] Save meal
- [ ] Verify meal appears on correct date
- [ ] Return to today's date

### 🔍 Search Functionality Testing

#### Test 3.1: Search Existing Meals
- [ ] Navigate to "Search" tab
- [ ] Type "Chicken" in search bar
- [ ] Verify results show meals with "Chicken"
- [ ] Tap on a meal result
- [ ] Verify meal details display correctly
- [ ] Tap "Add to Today" button
- [ ] Verify meal is added to today's intake

#### Test 3.2: Search with No Results
- [ ] Navigate to "Search" tab
- [ ] Type "Pizza" in search bar
- [ ] Verify "No meals found" message appears
- [ ] Verify helpful tips are shown

### 📊 Daily View Testing

#### Test 4.1: Today's Progress Display
- [ ] Navigate to "Today" tab
- [ ] Verify macro progress bars display correctly
- [ ] Check that numbers are horizontal (not vertical)
- [ ] Verify remaining targets show correctly
- [ ] Check that progress updates when meals are added

#### Test 4.2: Date Navigation
- [ ] Tap "Today" button (bottom left)
- [ ] Verify returns to current date
- [ ] Use arrow buttons to navigate dates
- [ ] Verify meals display for each date
- [ ] Check that adding meals works for past dates

#### Test 4.3: Macro Goals
- [ ] Navigate to "Profile" tab
- [ ] Scroll to "Daily Goals" section
- [ ] Modify calorie goal to 2000
- [ ] Modify protein goal to 150g
- [ ] Tap "Save Goals"
- [ ] Return to "Today" tab
- [ ] Verify new goals are reflected in progress bars

### 👥 Social Features Testing

#### Test 5.1: Profile Image Upload
- [ ] Navigate to "Profile" tab
- [ ] Tap profile image placeholder
- [ ] Select "Choose Photo from Library"
- [ ] Select a profile photo
- [ ] Wait for upload to complete
- [ ] Verify new profile image appears
- [ ] Check that no "Bucket not found" error occurs

#### Test 5.2: Friend Requests (Send)
- [ ] Navigate to "Profile" tab
- [ ] Scroll to "Add Friends" section
- [ ] Type a display name of another user
- [ ] Tap "Add Friend"
- [ ] Verify "Friend request sent" message
- [ ] Check that button changes to "Pending"

#### Test 5.3: Friend Requests (Receive)
- [ ] Log in with second account
- [ ] Navigate to "Profile" tab
- [ ] Check "Friend Requests" section
- [ ] Verify incoming request appears
- [ ] Tap "Accept" or "Decline"
- [ ] Verify request status updates

#### Test 5.4: Friend List
- [ ] Navigate to "Profile" tab
- [ ] Check "Friends" section
- [ ] Verify accepted friends appear
- [ ] Tap on a friend's name
- [ ] Verify friend's profile loads
- [ ] Check friend's meal sharing (if enabled)

### 📈 Stats View Testing

#### Test 6.1: Stats Display
- [ ] Navigate to "Stats" tab
- [ ] Verify weekly view shows current week data
- [ ] Tap "Month" button
- [ ] Verify monthly stats display
- [ ] Tap "Year" button
- [ ] Verify yearly stats display
- [ ] Check that future dates show no data

#### Test 6.2: Charts and Graphs
- [ ] Verify macro charts display correctly
- [ ] Check that data points match actual meals
- [ ] Verify chart interactions work (zoom, pan)
- [ ] Check that averages are calculated correctly

### 🔧 Widget Testing

#### Test 7.1: Widget Gallery
- [ ] Long press on home screen
- [ ] Tap "+" button
- [ ] Search for "MacroTrackr"
- [ ] Verify widget appears in gallery
- [ ] Select widget size (Small, Medium, Large)
- [ ] Add widget to home screen

#### Test 7.2: Widget Display
- [ ] Verify widget shows today's macro progress
- [ ] Check that numbers are readable
- [ ] Verify widget updates when meals are added
- [ ] Test different widget sizes

### 🎯 Navigation and UI Testing

#### Test 8.1: Tab Navigation
- [ ] Tap each tab in bottom navigation
- [ ] Verify smooth transitions
- [ ] Check that selected tab is highlighted
- [ ] Verify tab icons display correctly

#### Test 8.2: Cancel/Save Buttons
- [ ] Navigate to "Add Meal" tab
- [ ] Fill in some meal details
- [ ] Tap "Cancel" button
- [ ] Verify form dismisses without saving
- [ ] Fill in meal details again
- [ ] Tap "Save Meal" button
- [ ] Verify form dismisses after saving

#### Test 8.3: Error Handling
- [ ] Try to add meal with empty name
- [ ] Verify appropriate error message
- [ ] Try to search for non-existent user
- [ ] Verify "User not found" message
- [ ] Test network error scenarios

### 🚨 Known Issues to Monitor

1. **Profile Image Upload**: Watch for "Bucket not found" errors
2. **Friend Requests**: Check for RLS policy violations
3. **Meal Photo Picker**: Verify PhotosPicker works correctly
4. **Today Button**: Ensure it returns to current date
5. **Macro Display**: Check numbers are horizontal, not vertical
6. **Widget Gallery**: Verify MacroTrackr widget appears

### 📝 Test Results Template

```
Test Date: ___________
Tester: ___________
App Version: ___________

Authentication: ___/3 tests passed
Meal Management: ___/4 tests passed
Search: ___/2 tests passed
Daily View: ___/3 tests passed
Social Features: ___/4 tests passed
Stats: ___/2 tests passed
Widget: ___/2 tests passed
Navigation/UI: ___/3 tests passed

Overall Score: ___/23 tests passed (___%)

Critical Issues Found:
1. ________________
2. ________________
3. ________________

Recommendations:
________________
________________
```

### 🎉 Success Criteria

- **Minimum 90% test pass rate** (21/23 tests)
- **No critical functionality broken**
- **All major features working as intended**
- **Smooth user experience**
- **No data loss or corruption**

---

**Ready to begin comprehensive testing!** 🚀