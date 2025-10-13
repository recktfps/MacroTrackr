# Widget Setup Guide for MacroTrackr

## ⚠️ Important: Manual Xcode Setup Required

Unfortunately, widget extensions require manual Xcode configuration through the GUI. This guide will walk you through it step-by-step with screenshots references.

---

## 🎯 Quick Setup (5-10 minutes)

### Step 1: Add Widget Extension Target
1. **Open Xcode** with MacroTrackr.xcodeproj
2. Click **File** → **New** → **Target...**
3. In the template picker:
   - Search for: `Widget Extension`
   - Select **Widget Extension**
   - Click **Next**

4. Configure the target:
   ```
   Product Name: MacroTrackrWidget
   Team: (your team)
   Organization Identifier: com.macrotrackr
   Bundle Identifier: com.macrotrackr.MacroTrackr.MacroTrackrWidget
   Language: Swift
   ☐ Include Configuration Intent (leave UNCHECKED)
   ```
   - Click **Finish**
   - When asked "Activate 'MacroTrackrWidget' scheme?", click **Activate**

### Step 2: Replace Auto-Generated Files
Xcode created template files, but we already have better ones:

1. In **Project Navigator** (left sidebar), expand the `MacroTrackrWidget` folder
2. **Delete these auto-generated files** (select and press Delete, choose "Move to Trash"):
   - `MacroTrackrWidget.swift` (the template version)
   - `MacroTrackrWidgetBundle.swift` (if it was created)
   - Keep `Info.plist`

3. **Add our existing files**:
   - Right-click on the `MacroTrackrWidget` group in the navigator
   - Select **Add Files to "MacroTrackr"...**
   - Navigate to the `MacroTrackrWidget` folder in Finder
   - Select:
     - ☑️ `MacroTrackrWidget.swift`
     - ☑️ `MacroTrackrWidgetBundle.swift`
   - In the dialog:
     - ☑️ Check "Copy items if needed"
     - Under "Add to targets", check **MacroTrackrWidget** ONLY
   - Click **Add**

### Step 3: Configure App Groups (CRITICAL!)
This allows the widget to read data from the main app.

#### For the Main App:
1. Select **MacroTrackr** project (top of navigator)
2. Select **MacroTrackr** target (under TARGETS)
3. Click **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Search for and double-click **App Groups**
6. Click the **+** button under "App Groups"
7. Enter: `group.com.macrotrackr.shared`
8. Press **Enter** to add

#### For the Widget:
1. Still in project settings, select **MacroTrackrWidget** target
2. Click **Signing & Capabilities** tab
3. Click **+ Capability** button
4. Double-click **App Groups**
5. Click the **+** button
6. Enter: `group.com.macrotrackr.shared` (MUST BE EXACTLY THE SAME)
7. Press **Enter** to add

**✅ Verification**: Both targets should show:
```
App Groups
  ☑️ group.com.macrotrackr.shared
```

### Step 4: Link Models.swift to Widget Target
The widget needs access to your data models:

1. In **Project Navigator**, locate `MacroTrackr/Models.swift`
2. Click on `Models.swift` to select it
3. Open **File Inspector** (right sidebar, first tab - looks like a document icon)
4. Under **Target Membership** section, check BOTH:
   - ☑️ MacroTrackr
   - ☑️ MacroTrackrWidget

### Step 5: Build and Test

1. **Select the MacroTrackr scheme** (at the top, near the play button)
2. **Clean build**: Press **⇧⌘K** (Shift+Cmd+K)
3. **Build**: Press **⌘B** (Cmd+B)
4. Wait for build to complete - should see "Build Succeeded"
5. **Run**: Press **⌘R** (Cmd+R)

### Step 6: Add Widget to Home Screen

1. Once the app launches in the simulator
2. Go to **home screen** (press Home button or ⌘⇧H)
3. **Long press** on empty space on home screen
4. Tap the **+** button (top left)
5. Search for **"MacroTrackr"**
6. You should see three widget sizes:
   - Small (shows calories circle)
   - Medium (shows calories, protein, carbs, fat)
   - Large (shows all 6 macros)
7. Select a size → **Add Widget**

---

## 🐛 Troubleshooting

### Widget Doesn't Appear in Gallery

**Solution 1: Clean and Rebuild**
```
1. Product → Clean Build Folder (⇧⌘K)
2. Close Xcode completely
3. Reopen project
4. Build and run again
```

**Solution 2: Reset Simulator**
```
1. In Simulator: Device → Erase All Content and Settings
2. Rebuild and run app
3. Try adding widget again
```

**Solution 3: Verify Target Settings**
```
1. Select MacroTrackrWidget target
2. General tab:
   - Deployment Target: iOS 17.0 (or your min version)
   - Bundle Identifier: com.macrotrackr.MacroTrackr.MacroTrackrWidget
3. Signing & Capabilities:
   - App Groups should show: group.com.macrotrackr.shared
4. Build Phases → Compile Sources:
   - Should include:
     ✓ MacroTrackrWidget.swift
     ✓ MacroTrackrWidgetBundle.swift
     ✓ Models.swift
```

### Build Errors

**Error: "Cannot find 'MacroNutrition' in scope"**
```
Solution: Make sure Models.swift is added to MacroTrackrWidget target
(see Step 4 above)
```

**Error: "Failed to access shared container"**
```
Solution: Verify App Groups are configured correctly
- Both targets must have EXACTLY the same App Group ID
- Check for typos: group.com.macrotrackr.shared
```

**Error: "Multiple commands produce MacroTrackrWidget"**
```
Solution: 
1. Select MacroTrackrWidget target
2. Build Phases tab
3. Expand "Compile Sources"
4. Remove duplicate entries of MacroTrackrWidget.swift
```

---

## 📱 Testing Widget Functionality

Once the widget is added:

### Test 1: Widget Shows Current Data
1. Open MacroTrackr app
2. Add a meal with some macros
3. Go to home screen
4. Widget should update within ~15 minutes (or force-refresh by removing and re-adding)

### Test 2: Widget Updates When App Updates
1. Add multiple meals in the app
2. Close app
3. Widget will update on its timeline (every hour)

### Test 3: All Three Widget Sizes Work
1. Add all three sizes to home screen
2. Verify each shows appropriate data:
   - **Small**: Calories circle + percentage
   - **Medium**: 4 macro cards (Cal, Protein, Carbs, Fat)
   - **Large**: All 6 macros with progress bars

---

## ✅ Success Checklist

Before you're done, verify:

- [ ] MacroTrackrWidget target exists in project
- [ ] Both targets have App Groups capability with `group.com.macrotrackr.shared`
- [ ] Models.swift is a member of both targets
- [ ] Project builds successfully (⌘B)
- [ ] App runs in simulator (⌘R)
- [ ] Widget appears in widget gallery when searching "MacroTrackr"
- [ ] Widget can be added to home screen
- [ ] Widget displays placeholder data (if no meals logged yet)
- [ ] Widget updates when meals are added to the app

---

## 🆘 Still Having Issues?

If you're stuck, check:

1. **Xcode Version**: Make sure you're using Xcode 15 or later
2. **iOS Version**: Simulator should be iOS 17 or later
3. **Bundle Identifiers**: 
   - Main app: `com.macrotrackr.MacroTrackr`
   - Widget: `com.macrotrackr.MacroTrackr.MacroTrackrWidget`

Common mistakes:
- ❌ Forgot to add App Groups to BOTH targets
- ❌ App Group IDs don't match exactly (check for typos)
- ❌ Models.swift not linked to widget target
- ❌ Old template files still in the project
- ❌ Didn't clean build after making changes

---

## 📚 Additional Resources

- [Apple's Widget Documentation](https://developer.apple.com/widgets/)
- [WidgetKit Framework](https://developer.apple.com/documentation/widgetkit)

---

**Estimated Setup Time**: 5-10 minutes  
**Difficulty**: ⭐⭐ Intermediate

Good luck! The widget code is already written and working - it just needs Xcode to recognize it! 🎉

