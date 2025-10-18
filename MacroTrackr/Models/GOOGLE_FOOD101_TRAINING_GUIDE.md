# 🍎 Google Food-101 Training Guide for MacroTrackr

## 🎯 **Your App is Ready for Google Food-101!**

Your MacroTrackr app has been configured to automatically prioritize your custom-trained Google Food-101 model when it's ready.

## 📋 **Training Setup (Do This Later When Ready)**

### **Priority Order** (Your app will now check in this order):
1. **`GoogleFood101.mlmodel`** - Your custom-trained model (highest priority)
2. **`Food101.mlmodel`** - Pre-trained Food-101 model
3. **`ResNet50.mlmodel`** - General classification
4. **`MobileNetV2.mlmodel`** - Fast lightweight option
5. **Vision Framework** - Built-in fallback

## 🚀 **When You're Ready to Train (Complete Guide)**

### **Step 1: Download Google Food-101 Dataset**
```bash
# Navigate to your training directory
cd ~/Desktop/MacroTrackr/Food101_Training

# Download the dataset (6GB)
curl -L -o food-101.tar.gz "http://data.vision.ee.ethz.ch/cvl/food-101.tar.gz"

# Extract the dataset
tar -xzf food-101.tar.gz
```

### **Step 2: Prepare Dataset for Create ML**
The Food-101 dataset contains:
- **101 food categories** (apple_pie, beef_carpaccio, etc.)
- **1000 images per category** (750 training + 250 test)
- **Total**: 101,000 images

### **Step 3: Train with Create ML**
1. **Open Create ML** in Xcode
2. **Choose**: Image Classifier template
3. **Training Data**: Point to `food-101/images/` folder
4. **Validation**: Choose "Automatic" (Create ML will handle train/test split)
5. **Settings**:
   - **Algorithm**: Automatic (recommended for Food-101)
   - **Maximum iterations**: 20-30 (good balance of accuracy/time)
6. **Train**: Click "Train" button
7. **Export**: Save as `GoogleFood101.mlmodel`

### **Step 4: Integration (30 seconds)**
1. **Save** your trained model as `GoogleFood101.mlmodel`
2. **Add** to `MacroTrackr/Models/` folder
3. **Drag** into Xcode project (Copy items if needed)
4. **Build** and test!

## ⏱️ **Training Time Estimate (Your M1 Mac)**

| Stage | Time | Notes |
|-------|------|-------|
| **Dataset Download** | 15-30 min | 6GB download |
| **Dataset Preparation** | 5 min | Extract and organize |
| **Create ML Training** | 2-4 hours | 101 classes, M1 optimized |
| **Model Export** | 1-2 min | Final .mlmodel file |
| **Integration** | 30 sec | Add to project |

**Total**: ~3-5 hours (same as original estimate)

## 🎯 **Expected Results**

With Google Food-101 trained model, you'll get:
- **90%+ accuracy** for food recognition
- **101 specific food categories** (vs general ImageNet classes)
- **Proper class names** like "Apple Pie", "Beef Carpaccio", "Caesar Salad"
- **Automatic nutrition estimation** based on recognized foods

## 🔧 **Technical Details**

### **Model Output Handling**
Your app automatically handles Food-101 specific outputs:
- **Class names** like `apple_pie` → `Apple Pie`
- **Confidence scores** from 101-class softmax outputs
- **Nutrition mapping** for each recognized food type

### **Input Requirements**
- **Image size**: 224×224 pixels (automatically resized)
- **Format**: RGB color space
- **Preprocessing**: Handled automatically in the app

## 📁 **File Structure After Training**
```
MacroTrackr/Models/
├── GoogleFood101.mlmodel     <- Your custom model (priority #1)
├── Food101.mlmodel          <- Backup pre-trained
├── ResNet50.mlmodel         <- General classification
└── MobileNetV2.mlmodel      <- Fast option
```

## 🚦 **Current Status**

✅ **App is configured** to use GoogleFood101 as highest priority  
✅ **Class name processing** ready for Food-101 format  
✅ **Nutrition estimation** will work with 101 food categories  
⏳ **Training** - Ready when you are!  

## 🎉 **What Happens When You're Ready**

1. **Train your model** using the steps above
2. **Add `GoogleFood101.mlmodel`** to the Models folder
3. **Build and run** - your app will automatically use it!
4. **Test with photos** - should see much better food recognition

The app will automatically detect and use your custom-trained model over any pre-trained alternatives!
