#!/usr/bin/env python3
"""
Quick setup for Create ML training - works with manually downloaded dataset
"""

import os
import tarfile
from pathlib import Path

def extract_dataset():
    """Extract the manually downloaded dataset."""
    
    tar_file = "food-101.tar.gz"
    extract_dir = "food-101"
    
    if not os.path.exists(tar_file):
        print(f"❌ {tar_file} not found!")
        print("📥 Please download it manually from: https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz")
        return False
    
    if os.path.exists(extract_dir):
        print("✅ Dataset already extracted!")
        return True
    
    print("📦 Extracting dataset (this may take 5-10 minutes)...")
    try:
        with tarfile.open(tar_file, 'r:gz') as tar:
            tar.extractall()
        
        print("✅ Extraction completed!")
        
        # Verify structure
        images_dir = Path("food-101/images")
        if images_dir.exists():
            categories = [d.name for d in images_dir.iterdir() if d.is_dir()]
            print(f"🎯 Found {len(categories)} food categories ready for training!")
            
            # Show sample categories
            sample_cats = sorted(categories)[:5]
            print(f"📋 Sample categories: {', '.join(sample_cats)}")
            
            return True
        else:
            print("❌ Invalid dataset structure")
            return False
            
    except Exception as e:
        print(f"❌ Extraction failed: {e}")
        return False

def check_ready_for_createml():
    """Check if ready for Create ML training."""
    
    dataset_path = Path("food-101/images")
    
    if not dataset_path.exists():
        print("❌ Dataset not found. Please extract first.")
        return False
    
    categories = [d for d in dataset_path.iterdir() if d.is_dir()]
    
    print("🍎 Create ML Training Readiness Check:")
    print(f"   📁 Dataset path: {dataset_path.absolute()}")
    print(f"   🏷️  Categories: {len(categories)}")
    print(f"   💾 Space needed: ~2-4 GB for training")
    
    # Count total images
    total_images = 0
    for category in categories[:5]:  # Check first 5 categories
        images = list(category.glob("*"))
        total_images += len(images)
        print(f"   📸 {category.name}: {len(images)} images")
    
    print(f"\n✅ Ready for Create ML training!")
    print(f"🎯 Estimated training time on M1: 2-4 hours")
    
    return True

if __name__ == "__main__":
    print("🚀 Food-101 Quick Setup for Create ML")
    print("=" * 40)
    
    if extract_dataset():
        check_ready_for_createml()
        
        print(f"\n🎉 Next Steps:")
        print(f"1. Open Create ML")
        print(f"2. Choose Image Classification") 
        print(f"3. Select dataset: {Path('food-101/images').absolute()}")
        print(f"4. Start training (2-4 hours on M1)")
        print(f"5. Export .mlmodel to MacroTrackr project")
    else:
        print(f"\n❌ Setup incomplete. Check the manual download guide.")
