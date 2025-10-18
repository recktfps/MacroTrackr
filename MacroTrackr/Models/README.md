# Core ML Models for MacroTrackr

This directory contains Core ML models used for food recognition in MacroTrackr.

## 🎯 **Model Priority Order**

Your app will automatically use models in this order:

1. **`GoogleFood101.mlmodel`** - Your custom-trained Google Food-101 model (highest priority)
2. **`Food101.mlmodel`** - Pre-trained Food-101 model  
3. **`ResNet50.mlmodel`** - High-accuracy general classification
4. **`MobileNetV2.mlmodel`** - Fast lightweight option
5. **Vision Framework** - Built-in Apple fallback

## 🚀 **Quick Setup**

### **For Pre-trained Models:**
1. **Download** any `.mlmodel` file from the guides below
2. **Add to Project**: Drag into this directory in Xcode
3. **Build** - your app will automatically use it!

### **For Custom Training (Google Food-101):**
See `GOOGLE_FOOD101_TRAINING_GUIDE.md` for complete training instructions.

## 📁 **Current Files**

- `GOOGLE_FOOD101_TRAINING_GUIDE.md` - Complete training setup
- `RESNET50_SETUP_GUIDE.md` - ResNet50 download & integration  
- `Food101_Model_Sources.md` - Pre-trained model sources
- `PRETRAINED_MODELS_GUIDE.md` - Quick download options

## Model Requirements

- Input: Image (preferably 224x224 or 299x299 pixels)
- Output: Classification labels with confidence scores
- Format: Core ML `.mlmodel` or `.mlmodelc` files
