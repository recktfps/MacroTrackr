#!/usr/bin/env python3
"""
Download pre-trained Core ML models for food recognition
"""

import urllib.request
import os
import ssl
from pathlib import Path

# Create models directory
models_dir = Path("MacroTrackr/Models")
models_dir.mkdir(exist_ok=True)

# Create SSL context that ignores certificate issues
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

def download_with_retry(url, filename, max_retries=3):
    """Download with retry logic and SSL bypass."""
    for attempt in range(max_retries):
        try:
            print(f"📥 Downloading {filename}... (attempt {attempt + 1})")
            opener = urllib.request.build_opener(urllib.request.HTTPSHandler(context=ssl_context))
            urllib.request.install_opener(opener)
            
            urllib.request.urlretrieve(url, filename)
            print(f"✅ Successfully downloaded {filename}")
            return True
        except Exception as e:
            print(f"⚠️ Attempt {attempt + 1} failed: {e}")
            if attempt == max_retries - 1:
                print(f"❌ Failed to download {filename} after {max_retries} attempts")
                return False

def download_models():
    """Download pre-trained Core ML models."""
    
    print("🍎 Downloading Pre-trained Core ML Models for Food Recognition")
    print("=" * 60)
    
    # List of available models to try
    models_to_download = [
        {
            "name": "MobileNetV2",
            "url": "https://storage.googleapis.com/download.tensorflow.org/models/tflite/coreml/MobileNetV2.mlmodel",
            "filename": models_dir / "MobileNetV2.mlmodel",
            "description": "General image classification, lightweight (~14MB)"
        },
        {
            "name": "ResNet50", 
            "url": "https://docs-assets.developer.apple.com/coreml/models/Image/Classification/ResNet50/ResNet50.mlmodel",
            "filename": models_dir / "ResNet50.mlmodel",
            "description": "High accuracy image classification (~100MB)"
        }
    ]
    
    successful_downloads = []
    
    for model in models_to_download:
        print(f"\n🎯 Trying to download {model['name']}...")
        print(f"   Description: {model['description']}")
        
        if download_with_retry(model['url'], str(model['filename'])):
            successful_downloads.append(model['name'])
        else:
            print(f"   Skipping {model['name']}")
    
    return successful_downloads

def create_food101_instructions():
    """Create instructions for Food-101 model."""
    
    food101_guide = """
# Food-101 Pre-trained Model Sources

Since direct downloads may have issues, here are alternative sources:

## Option 1: Apple's Model Gallery
1. Visit: https://developer.apple.com/machine-learning/models/
2. Download "MobileNetV2" or "ResNet50" models
3. These work well for general image classification including food

## Option 2: GitHub Repositories
Search for these popular repositories with Food-101 models:
- `hollance/food-101-coreml`
- `apple/coreml-recipes`
- `tucan9389/Food-101-CoreML`

## Option 3: Create ML Template
1. Open Create ML in Xcode
2. Use Image Classification template
3. Load a smaller sample food dataset
4. Export as .mlmodel

## Option 4: Convert from TensorFlow/Keras
If you find TensorFlow models, use coremltools to convert:
```python
import coremltools as ct
model = ct.convert(tf_model, source='tensorflow')
model.save('Food101.mlmodel')
```
"""
    
    with open("MacroTrackr/Models/Food101_Model_Sources.md", "w") as f:
        f.write(food101_guide)
    
    print("📋 Created Food101_Model_Sources.md with alternative download options")

if __name__ == "__main__":
    successful = download_models()
    
    if successful:
        print(f"\n🎉 Successfully downloaded {len(successful)} models:")
        for model in successful:
            print(f"   ✅ {model}")
        
        print(f"\n🚀 Next Steps:")
        print(f"1. Build your MacroTrackr project in Xcode")
        print(f"2. The app will automatically detect and use these models")
        print(f"3. Test food recognition in your app!")
    else:
        print(f"\n⚠️ No models downloaded directly, but I've created alternative instructions.")
    
    create_food101_instructions()
    
    print(f"\n📁 Check MacroTrackr/Models/ directory for downloaded files and instructions.")
