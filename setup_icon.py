#!/usr/bin/env python3
"""
Setup app icon for Android and iOS
Resizes source icon to required dimensions
"""

import os
import shutil
from pathlib import Path

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    print("WARNING: Pillow not found. Icons will be copied without resizing.")

# Configuration
# Get icon source from environment variable, or use a default relative path
SOURCE_ICON = os.getenv(
    'APP_ICON_SOURCE',
    'assets/app_icon/icon.png'  # Default relative path within project
)
PROJECT_ROOT = Path(__file__).parent

# Android density to size mapping
ANDROID_DENSITIES = {
    'mdpi': 48,      # baseline
    'hdpi': 72,      # 1.5x
    'xhdpi': 96,     # 2x
    'xxhdpi': 144,   # 3x
    'xxxhdpi': 192,  # 4x
}

# iOS icon sizes (scale-independent)
IOS_SIZES = [
    (20, '1x'),      # Settings
    (20, '2x'),
    (20, '3x'),
    (29, '1x'),      # Spotlight
    (29, '2x'),
    (29, '3x'),
    (40, '1x'),      # iPad Spotlight
    (40, '2x'),
    (40, '3x'),
    (60, '2x'),      # iPhone App
    (60, '3x'),
    (76, '1x'),      # iPad App
    (76, '2x'),
    (83.5, '2x'),    # iPad Pro
    (1024, '1x'),    # App Store
]

def setup_android_icons():
    """Setup Android app icons"""
    print("\n=== Setting up Android icons ===")

    if not os.path.exists(SOURCE_ICON):
        print(f"ERROR: Source icon not found: {SOURCE_ICON}")
        return False

    try:
        if HAS_PIL:
            source_img = Image.open(SOURCE_ICON)
            print(f"Opened source image: {source_img.size}")

        for density, size in ANDROID_DENSITIES.items():
            mipmap_dir = PROJECT_ROOT / 'android' / 'app' / 'src' / 'main' / 'res' / f'mipmap-{density}'
            mipmap_dir.mkdir(parents=True, exist_ok=True)

            icon_path = mipmap_dir / 'ic_launcher.png'

            if HAS_PIL:
                # Resize to specified dimension
                resized = source_img.resize((size, size), Image.Resampling.LANCZOS)
                resized.save(icon_path, 'PNG')
                print(f"  Created: {icon_path} ({size}x{size})")
            else:
                # Fallback: just copy the source
                shutil.copy2(SOURCE_ICON, icon_path)
                print(f"  Copied (no resize): {icon_path}")

    except Exception as e:
        print(f"ERROR setting up Android icons: {e}")
        return False

    print("Android icons setup complete!")
    return True

def setup_ios_icons():
    """Setup iOS app icons"""
    print("\n=== Setting up iOS icons ===")

    if not os.path.exists(SOURCE_ICON):
        print(f"ERROR: Source icon not found: {SOURCE_ICON}")
        return False

    appicon_dir = PROJECT_ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
    appicon_dir.mkdir(parents=True, exist_ok=True)

    try:
        if HAS_PIL:
            source_img = Image.open(SOURCE_ICON)

        for size, scale in IOS_SIZES:
            # Calculate pixel size from scale
            pixel_size = int(size * (2 if scale == '2x' else 3 if scale == '3x' else 1))

            # Create filename
            if size == int(size):
                size_str = f"{int(size)}x{int(size)}"
            else:
                size_str = f"{size}x{size}"

            filename = f"Icon-App-{size_str}@{scale}.png"
            icon_path = appicon_dir / filename

            if HAS_PIL:
                resized = source_img.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)
                resized.save(icon_path, 'PNG')
                print(f"  Created: {filename} ({pixel_size}x{pixel_size})")
            else:
                shutil.copy2(SOURCE_ICON, icon_path)
                print(f"  Copied (no resize): {filename}")

    except Exception as e:
        print(f"ERROR setting up iOS icons: {e}")
        return False

    print("iOS icons setup complete!")
    return True

def main():
    """Main setup function"""
    print("Setting up app icons for shougaku-kore-doutoku...")

    if not HAS_PIL:
        print("\nInstalling Pillow for image resizing...")
        os.system("pip install pillow")
        # Re-import
        from PIL import Image
        globals()['HAS_PIL'] = True

    android_ok = setup_android_icons()
    ios_ok = setup_ios_icons()

    if android_ok and ios_ok:
        print("\n✓ Icon setup completed successfully!")
        print("\nNext steps:")
        print("  1. Verify icons in Flutter project:")
        print("     - Android: android/app/src/main/res/mipmap-*/ic_launcher.png")
        print("     - iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/")
        print("  2. Run 'flutter pub get' and 'flutter run' to rebuild")
        return True
    else:
        print("\n✗ Icon setup had errors")
        return False

if __name__ == '__main__':
    import sys
    sys.exit(0 if main() else 1)
