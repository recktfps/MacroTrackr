# Camera & Video AI Setup Guide

## Overview
Your MacroTrackr app now includes comprehensive camera and video-based AI food scanning capabilities.

## ✅ Capabilities Already Configured

### Required Capabilities (Already Added)
1. **Camera** - For taking photos and video recording
2. **Photo Library** - For selecting existing images

### Info.plist Permissions (Already Added)
```xml
<key>NSCameraUsageDescription</key>
<string>MacroTrackr needs access to your camera to scan food and take photos of your meals for accurate nutrition tracking.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>MacroTrackr needs access to your photo library to select meal images and save food photos.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>MacroTrackr needs permission to save meal photos to your photo library.</string>
```

## 🎥 Video-Based AI Food Scanning

### What You DON'T Need
- ❌ **Multitasking Camera Access** - Not required for this implementation
- ❌ **Microphone capability** - Only visual analysis is needed for food scanning
- ❌ **Additional capabilities** - Everything needed is already configured

### What You DO Have
- ✅ **Real-time video analysis** using Vision framework
- ✅ **AI food recognition** with confidence scores
- ✅ **Nutrition estimation** for detected foods
- ✅ **Live camera preview** with scanning overlay
- ✅ **Multiple food detection** (up to 3 foods at once)

## 🚀 Features Implemented

### 1. Camera Integration
- **Profile Pictures**: Take photos or select from library
- **Meal Images**: Add photos to meal entries
- **Real-time preview** with editing capabilities
- **Automatic image compression** and upload to Supabase

### 2. Video AI Food Scanner
- **Live video analysis** using Vision framework (visual-only, no audio)
- **Food classification** with confidence scores
- **Nutrition estimation** (calories, protein, carbs, fat)
- **Real-time detection** with visual feedback
- **Multiple food support** - detect up to 3 foods simultaneously

### 3. Push Notifications
- **Meal logging notifications** - Get notified when you log meals
- **Permission management** - Users can enable/disable in profile
- **Customizable settings** - Toggle notifications on/off

## 📱 How It Works

### Profile Pictures
1. Tap profile picture in Profile tab
2. Choose "Take Photo" or "Choose from Library"
3. Image automatically uploads to Supabase
4. Profile picture updates immediately

### Meal Images
1. Add meal with image option
2. Take photo or select from library
3. Image uploads and links to meal
4. Shows in meal history and search

### Video Food Scanning
1. Open camera scanner from Add Meal
2. Point camera at food
3. Tap "Start Scanning"
4. AI analyzes video feed in real-time
5. Select detected food to add to meal
6. Nutrition automatically populated

## 🔧 Technical Implementation

### Frameworks Used
- **AVFoundation** - Camera and video capture
- **Vision** - AI food recognition
- **UIKit** - Camera interface integration
- **PhotosUI** - Photo library access
- **UserNotifications** - Push notifications

### AI Food Recognition
- Uses **VNClassifyImageRequest** for food detection (visual analysis only)
- Filters for food-related classifications
- Estimates nutrition based on food type
- Provides confidence scores for accuracy
- **No audio processing** - purely visual AI analysis

### Image Upload System
- **Automatic compression** to JPEG format
- **Supabase Storage** integration
- **Public URL generation** for images
- **Error handling** for upload failures

## 🎯 User Experience

### Camera Features
- **Seamless switching** between camera and library
- **Image editing** with crop functionality
- **Loading states** during upload
- **Error handling** with user feedback

### AI Scanning
- **Real-time feedback** with confidence scores
- **Multiple food detection** for complex meals
- **Nutrition estimation** with macro breakdown
- **One-tap selection** to add to meal

### Notifications
- **Permission requests** with clear explanations
- **Settings management** in profile
- **Customizable preferences** per user
- **Non-intrusive** meal logging confirmations

## 🚀 Next Steps

### For Testing
1. **Build and run** on physical device (camera doesn't work in simulator)
2. **Test camera permissions** - app will request access
3. **Try food scanning** - point camera at various foods
4. **Test notifications** - log meals to see notifications

### For Production
1. **Test on multiple devices** - ensure camera works across devices
2. **Optimize AI accuracy** - train with more food types if needed
3. **Monitor upload performance** - check Supabase storage usage
4. **User feedback** - gather feedback on AI accuracy

## 🔍 Troubleshooting

### Common Issues
1. **Camera not working**: Ensure testing on physical device
2. **Permissions denied**: Check device settings (camera only, no microphone needed)
3. **AI not detecting**: Try different lighting or food positioning
4. **Upload failures**: Check internet connection and Supabase config

### Debug Tips
- Check console logs for Vision framework errors
- Verify camera permissions in device settings
- Test image upload with small files first
- Monitor Supabase storage usage
- **Note**: No microphone permissions required for AI scanning

## 📊 Performance Notes

### AI Scanning
- **Real-time processing** on device (no internet required)
- **Efficient Vision framework** usage (visual-only analysis)
- **Background processing** to avoid UI blocking
- **Confidence filtering** to reduce false positives
- **No audio processing** - faster and more privacy-friendly

### Image Handling
- **Automatic compression** to reduce upload time
- **Lazy loading** for better performance
- **Caching** with Kingfisher for quick display
- **Error recovery** for failed uploads

---

**Your app now has professional-grade camera and AI food scanning capabilities!** 🎉📱🤖
