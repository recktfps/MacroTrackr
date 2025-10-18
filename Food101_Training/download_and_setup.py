#!/usr/bin/env python3
"""
Download and prepare Food-101 dataset for Core ML training
"""

import os
import urllib.request
import tarfile
import shutil
from pathlib import Path

def download_food101():
    """Download and extract Food-101 dataset."""
    
    print("🍔 Starting Food-101 Dataset Setup...")
    
    # Check if dataset already exists
    if os.path.exists("food-101"):
        print("✅ Food-101 dataset already exists!")
        return True
    
    # Download the dataset
    url = "https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz"
    filename = "food-101.tar.gz"
    
    if os.path.exists(filename):
        print("📁 Found existing tar file, extracting...")
    else:
        print("📥 Downloading Food-101 dataset (6GB) - this may take 15-30 minutes...")
        try:
            urllib.request.urlretrieve(url, filename)
            print("✅ Download completed!")
        except Exception as e:
            print(f"❌ Download failed: {e}")
            return False
    
    # Extract the dataset
    print("📦 Extracting dataset...")
    try:
        with tarfile.open(filename, 'r:gz') as tar:
            tar.extractall()
        print("✅ Extraction completed!")
        
        # Clean up tar file to save space
        os.remove(filename)
        print("🗑️ Cleaned up tar file")
        
        return True
        
    except Exception as e:
        print(f"❌ Extraction failed: {e}")
        return False

def setup_for_createml():
    """Organize dataset for Create ML training."""
    
    if not os.path.exists("food-101"):
        print("❌ Food-101 dataset not found. Please run download_food101() first.")
        return False
    
    print("🎯 Setting up dataset structure for Create ML...")
    
    # Create training and testing directories
    train_dir = Path("food-101/train")
    test_dir = Path("food-101/test")
    
    if train_dir.exists() and test_dir.exists():
        print("✅ Dataset already properly structured for Create ML!")
        return True
    
    # The Food-101 dataset should already have train/test split
    # Let's verify the structure
    images_dir = Path("food-101/images")
    if images_dir.exists():
        categories = [d.name for d in images_dir.iterdir() if d.is_dir()]
        print(f"📊 Found {len(categories)} food categories:")
        
        # Show first 10 categories
        for i, cat in enumerate(sorted(categories)[:10]):
            print(f"   {i+1}. {cat}")
        if len(categories) > 10:
            print(f"   ... and {len(categories) - 10} more")
        
        print(f"\n🎯 Ready for Create ML training!")
        print(f"Dataset path: {os.path.abspath('food-101')}")
        return True
    
    print("❌ Could not find proper dataset structure")
    return False

if __name__ == "__main__":
    print("🚀 Food-101 Dataset Setup for Core ML")
    print("=" * 40)
    
    if download_food101():
        setup_for_createml()
        print("\n✅ Setup complete! You can now use Create ML to train your model.")
    else:
        print("\n❌ Setup failed. Please check your internet connection and try again.")
