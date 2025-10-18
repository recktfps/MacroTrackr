#!/usr/bin/env python3
"""
Script to download a pre-trained food recognition Core ML model.
"""

import urllib.request
import os
import sys

def download_model():
    """Download a food recognition Core ML model."""
    
    # Create the Models directory if it doesn't exist
    models_dir = "MacroTrackr/Models"
    os.makedirs(models_dir, exist_ok=True)
    
    print("🍎 Downloading Core ML Food Recognition Model...")
    
    # Try different model sources
    models_to_try = [
        {
            "name": "MobileNetV2",
            "url": "https://docs-assets.developer.apple.com/coreml/models/Image/Classification/MobileNetV2/MobileNetV2Int8LUT.mlmodel",
            "filename": "MobileNetV2.mlmodel"
        }
    ]
    
    for model in models_to_try:
        try:
            print(f"📥 Attempting to download {model['name']}...")
            urllib.request.urlretrieve(model['url'], f"{models_dir}/{model['filename']}")
            print(f"✅ Successfully downloaded {model['name']}!")
            return True
        except Exception as e:
            print(f"❌ Failed to download {model['name']}: {e}")
            continue
    
    print("⚠️  Could not download any models automatically.")
    print("\n📋 Manual Instructions:")
    print("1. Visit: https://developer.apple.com/machine-learning/models/")
    print("2. Download a food recognition model (recommended: MobileNetV2 or Food-101)")
    print("3. Drag the .mlmodel file into your Xcode project under MacroTrackr/Models/")
    print("4. Build and run your project")
    
    return False

if __name__ == "__main__":
    download_model()
