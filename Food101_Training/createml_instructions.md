# Create ML Training Instructions for Food-101

## 🚀 After running the download script, follow these steps:

### 1. Open Create ML
```bash
# In Terminal or Xcode
open /Applications/Xcode.app/Contents/Developer/usr/bin/createML
```
Or launch from Xcode: **Develop → Open Developer Tool → Create ML**

### 2. Create New Image Classifier Project
1. Choose **Image Classification**
2. Click **Next**
3. Name it **"Food101_Classifier"**
4. Choose location: `Food101_Training/`

### 3. Configure Training Data
1. **Training Data**: Select `food-101/images/` folder
2. **Testing Data**: Leave as "Automatically split from training data" (20%)
3. **Validation Data**: Leave as default (recommended)

### 4. Training Settings
- **Algorithm**: Choose your preference:
  - **VisionFeaturePrint.Scene** (faster, good accuracy)
  - **ImageClassifier** (best accuracy, longer training)

### 5. Start Training
- Click **"Train"** button
- **Estimated time on M1**: 2-4 hours
- You can monitor progress in real-time

### 6. Export Model
- After training completes, click **"Output"** tab
- Drag the `.mlmodel` file to your MacroTrackr project

## 📊 Expected Results
- **Accuracy**: 75-85% on Food-101 dataset
- **Model Size**: ~20-50MB
- **Categories**: 101 food types

## ⚡ Tips for Better Training
1. **Close other apps** to give Create ML maximum resources
2. **Keep your Mac plugged in** during training
3. **Don't put Mac to sleep** - this stops training

## 🔧 Troubleshooting
- If training fails: try reducing batch size or using VisionFeaturePrint.Scene
- If out of memory: close other apps or use smaller algorithm
- If too slow: consider using smaller subset of categories first
