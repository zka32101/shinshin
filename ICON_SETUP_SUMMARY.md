# App Icon Setup - 小学コレ！道徳

## Setup Completed

### Source Icon
- **File**: `G:\マイドライブ\images\小学コレ！\アプリアイコン\512\アプリアイコン (道徳).jpg`
- **Size**: 512x512 pixels
- **Format**: JPEG

### Android Icons
Icons have been automatically resized and placed in the correct mipmap directories:

| Density | Size | Path |
|---------|------|------|
| mdpi | 48x48 | `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` |
| hdpi | 72x72 | `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` |
| xhdpi | 96x96 | `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` |
| xxhdpi | 144x144 | `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` |
| xxxhdpi | 192x192 | `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` |

**AndroidManifest.xml**: Already references `@mipmap/ic_launcher` in line 5
```xml
<application
    android:label="shougaku_kore_doutoku"
    android:icon="@mipmap/ic_launcher">
```
No changes needed.

### iOS Icons
Icons have been resized and placed in the correct directory:
- **Directory**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Total icons**: 15 files
- **Contents.json**: Already correctly configured with all icon references

#### Icon Sizes Generated
- 20x20 (Settings: 1x, 2x, 3x)
- 29x29 (Spotlight: 1x, 2x, 3x)
- 40x40 (iPad Spotlight: 1x, 2x, 3x)
- 60x60 (iPhone App: 2x, 3x)
- 76x76 (iPad App: 1x, 2x)
- 83.5x83.5 (iPad Pro: 2x)
- 1024x1024 (App Store)

### pubspec.yaml
No icon configuration needed in pubspec.yaml. Flutter uses the native platform configurations:
- **Android**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Verification Steps

### 1. Visual Verification (Optional)
To verify the icons look correct:
```bash
# Android
ls -la android/app/src/main/res/mipmap-*/ic_launcher.png

# iOS
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
```

### 2. Build & Test

#### Android
```bash
flutter clean
flutter pub get
flutter run -d android
```
After building, check the app launcher icon on Android device/emulator.

#### iOS
```bash
flutter clean
flutter pub get
flutter run -d ios
```
After building, check the app launcher icon on iOS device/simulator.

## Icon Appearance

The icon shows the 小学コレ！道徳 app logo and will appear:
- On the Android home screen with the app name "shougaku_kore_doutoku"
- On iOS home screen as the app launcher icon
- In app drawers and settings

## Notes

1. **Image Format**: All icons have been converted to PNG format (better for app icons than JPEG)
2. **Transparency**: The source JPEG has been converted to PNG; if transparency is needed, the source icon may need adjustment
3. **Build Cache**: Running `flutter clean` is recommended before rebuilding to ensure old icons are not cached
4. **App Label**: The app label is currently "shougaku_kore_doutoku" - consider updating this in AndroidManifest.xml for a more user-friendly name if desired

## File Manifest

Setup script: `setup_icon.py` (can be reused for other icon updates)

Generated files:
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (5 KB)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (10 KB)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (17 KB)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (36 KB)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (60 KB)
- 15 iOS icon files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Next Steps

1. Run `flutter clean && flutter pub get`
2. Test on both Android and iOS platforms
3. Verify icons appear correctly on both launchers
4. Build APK/AAB for Android Play Store release
5. Build IPA for iOS App Store release
