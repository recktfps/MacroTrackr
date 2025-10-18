
# 🍎 Pre-trained Core ML Models for Food Recognition

## ✅ **BEST OPTIONS - Ready to Download**

### 1. **Apple's Official Models** (Recommended)
**Download directly from Apple:**
- 🔗 **MobileNetV2**: https://docs-assets.developer.apple.com/coreml/models/Image/Classification/MobileNetV2/MobileNetV2Int8LUT.mlmodel
- 🔗 **ResNet50**: https://docs-assets.developer.apple.com/coreml/models/Image/Classification/ResNet50/ResNet50.mlmodel
- 🔗 **MobileNetV2 (FP16)**: https://docs-assets.developer.apple.com/coreml/models/Image/Classification/MobileNetV2/MobileNetV2FP16.mlmodel

**How to use:**
1. Right-click → "Save Link As"
2. Save to `MacroTrackr/Models/` folder
3. Your app will automatically use them!

### 2. **Hugging Face Models** (Food-Specific)
**Direct downloads:**
- 🔗 **Food-101 Model**: https://huggingface.co/models?search=food+coreml
- 🔗 **MobileNet Food**: https://huggingface.co/google/MobileNetV2 (convert to Core ML)

### 3. **Core ML Model Hub**
- 🔗 **Visit**: https://coreml.store/ or https://modelplace.ai/
- Search for "food classification" or "Food-101"

## 🚀 **Quick Setup Instructions**

### For Apple's Models:
```bash
# Download MobileNetV2 (recommended for food)
curl -o MacroTrackr/Models/MobileNetV2.mlmodel "https://docs-assets.developer.apple.com/coreml/models/Image/Classification/MobileNetV2/MobileNetV2Int8LUT.mlmodel"
```

### For GitHub Models:
1. Visit: https://github.com/hollance/food-101-coreml
2. Download the `Food101.mlmodel` file
3. Add to your Xcode project

## 📊 **Model Comparison**

| Model | Size | Speed | Accuracy | Best For |
|-------|------|-------|----------|----------|
| **MobileNetV2** | ~14MB | Fast | Good | Real-time apps |
| **Food-101** | ~50MB | Medium | Excellent | Food-specific |
| **ResNet50** | ~100MB | Slow | Best | High accuracy |

## 🔧 **Integration**

Your MacroTrackr app is already set up to use any of these models! Just:
1. Download any `.mlmodel` file
2. Add to `MacroTrackr/Models/` folder
3. Build and run - it will work automatically!

## 🎯 **Recommended for You**

Given your **M1 Mac with 8GB RAM**, I recommend:
1. **Start with MobileNetV2** - fast and efficient
2. **Try Food-101 if available** - best food accuracy
3. **Keep ResNet50** as backup for high accuracy needs
