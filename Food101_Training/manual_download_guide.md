# Manual Food-101 Dataset Download Guide

Since the automated download had SSL issues, here's how to manually download and set up:

## 🌐 Manual Download (Recommended)

### Step 1: Download the Dataset
1. **Visit**: https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz
2. **Right-click** → "Save Link As..." 
3. **Save as**: `food-101.tar.gz` in your `/Users/ivanmartinez/Desktop/MacroTrackr/Food101_Training/` folder

### Step 2: Extract the Dataset
```bash
cd /Users/ivanmartinez/Desktop/MacroTrackr/Food101_Training
tar -xzf food-101.tar.gz
```

### Step 3: Verify Structure
```bash
ls -la food-101/
# Should show: images/, meta/, README.txt
```

## 🍎 Alternative: Use Create ML's Built-in Datasets

If downloading is problematic, you can:
1. **Open Create ML**
2. **Choose**: Image Classification
3. **Use**: "Load Sample Dataset" → Try "Food Dataset" (Apple's built-in)

## 🚀 Quick Start with Existing Data

If you want to test immediately with a smaller dataset:

1. **Download**: A few hundred food images manually
2. **Organize**: Put in folders by food type
3. **Train**: Use Create ML with this smaller dataset

## ⏱️ Time Estimates Reminder

- **Download**: 15-30 minutes (manual download)
- **Extraction**: 2-5 minutes  
- **Training**: 2-4 hours on your M1 Mac
- **Total**: ~3-5 hours

Your **Apple M1 with 8GB RAM** is perfect for this training!
