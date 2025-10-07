# New Project Setup Guide 🚀

## 🔧 **Recommended Solution: Create New Project**

The current project file has become corrupted during our fixes. The best solution is to create a fresh Xcode project with proper package dependencies.

## 📋 **Step-by-Step Setup:**

### **1. Create New Xcode Project**
1. **Open Xcode**
2. **File → New → Project**
3. **iOS → App**
4. **Configure:**
   - Product Name: `MacroTrackr`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: `NO`
   - Include Tests: `NO` (optional)
5. **Save** to a new location (e.g., `MacroTrackr-New`)

### **2. Add Swift Package Dependencies**
1. **File → Add Package Dependencies**
2. **Add these URLs one by one:**
   - `https://github.com/supabase/supabase-swift`
   - `https://github.com/onevcat/Kingfisher`
   - `https://github.com/realm/realm-swift`
3. **Select all products** for each package
4. **Click Add Package**

### **3. Copy Source Files**
Copy these files from the current project to the new project:
- `MacroTrackr/MacroTrackrApp.swift`
- `MacroTrackr/Models.swift`
- `MacroTrackr/AuthenticationView.swift`
- `MacroTrackr/AddMealView.swift`
- `MacroTrackr/SearchView.swift`
- `MacroTrackr/StatsView.swift`
- `MacroTrackr/ProfileView.swift`
- `MacroTrackr/DailyView.swift`
- `MacroTrackr/MealDetailView.swift`

### **4. Configure App Capabilities**
1. **Select the project** in navigator
2. **Select the MacroTrackr target**
3. **Go to Signing & Capabilities tab**
4. **Click + Capability** and add:
   - **Camera** (for food scanning)
   - **Photo Library** (for profile pictures and meal images)
   - **Push Notifications** (for meal notifications)
   - **Sign in with Apple** (for authentication)

### **5. Configure Info.plist**
Add these keys to Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>MacroTrackr uses the camera to scan food and estimate nutritional information.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MacroTrackr uses the photo library to save profile pictures and meal images.</string>
<key>NSAppleSignInUsageDescription</key>
<string>MacroTrackr uses Sign in with Apple to securely authenticate your account and sync your nutrition data.</string>
```

### **6. Update Supabase Configuration**
In `MacroTrackrApp.swift`, update:
```swift
supabaseURL: URL(string: "https://adnjakimzfidaolaxmck.supabase.co")!,
supabaseKey: "sb_publishable_VY1OkpLC8zEUuOkiPgxPoQ_9d0eVE9_"
```

### **7. Build and Test**
1. **Product → Clean Build Folder** (⌘+Shift+K)
2. **Build the project** (⌘+B)
3. **Run on simulator** (⌘+R)

## 🎯 **Expected Result:**
- ✅ **All packages resolve correctly**
- ✅ **No missing dependency errors**
- ✅ **App builds and runs successfully**
- ✅ **All features working** (auth, camera, notifications)

## 🚀 **Why This Works:**
- **Fresh project** = No corruption or conflicts
- **Proper package setup** = Xcode manages dependencies correctly
- **Clean configuration** = All settings are properly applied
- **Proven approach** = This is the standard way to set up iOS projects

## 📝 **Alternative: Fix Current Project**
If you prefer to fix the current project:
1. **Open MacroTrackr.xcodeproj**
2. **File → Packages → Reset Package Caches**
3. **File → Packages → Resolve Package Versions**
4. **If that fails, remove and re-add all packages manually**

**The new project approach is recommended for the cleanest result!** 🎉
