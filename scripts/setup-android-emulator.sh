#!/bin/bash

# Android Emulator 環境セットアップスクリプト
# 用途：各セッションの自動初期化（session-start hook で呼び出し）

set -e

echo "🚀 Android Emulator Environment Setup"

# 環境変数の設定
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"

# 1. Android SDK コマンドラインツール確認
echo "📱 Checking Android SDK..."
if ! command -v sdkmanager &> /dev/null; then
  echo "⚠️  Android SDK not found. Installing..."
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  cd /tmp
  curl -s "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o cmdline-tools.zip
  unzip -q cmdline-tools.zip
  mv cmdline-tools/* "$ANDROID_HOME/cmdline-tools/latest/" 2>/dev/null || mv cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
  rm -f cmdline-tools.zip
  cd -
fi

# 2. 必要な SDK コンポーネント インストール
echo "📦 Installing Android SDK components..."
yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager --update > /dev/null 2>&1 || true
sdkmanager \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "system-images;android-34;google_apis;x86_64" \
  "emulator" \
  "platform-tools" \
  > /dev/null 2>&1 || true

# 3. AVD（Android Virtual Device）作成
AVD_NAME="${1:-default}"
echo "🎮 Creating Android Virtual Device: $AVD_NAME"

# AVD ディレクトリ
AVD_DIR="$HOME/.android/avd/$AVD_NAME.avd"

if [ ! -d "$AVD_DIR" ]; then
  cat > "$HOME/.android/avd/$AVD_NAME.ini" << EOF
avd.ini.encoding=UTF-8
path=$AVD_DIR
path.rel=avd/$AVD_NAME.avd
target=android-34
EOF

  mkdir -p "$AVD_DIR"
  cat > "$AVD_DIR/config.ini" << EOF
avd.ini.encoding=UTF-8
abi.type=x86_64
hw.device.name=Pixel_6_Pro_API_34
hw.dpadKeys=yes
hw.gsmModem=yes
hw.gsmNoise=yes
hw.initialOrientation=portrait
hw.keyboard=yes
hw.mainKeys=no
hw.ramMB=4096
hw.screen.density=420
hw.screen.height=3120
hw.screen.width=1440
hw.sensors.orientation=yes
hw.sensors.proximity=yes
hw.trackBall=no
image.sysdir.1=system-images/android-34/google_apis/x86_64/
kernel.newDeviceNaming=yes
kernel.qemu.vm.hw.mainkeys=no
showDeviceFrame=yes
tag.display=Google APIs
tag.id=google_apis
vm.heapSize=512
EOF

  echo "✅ AVD created: $AVD_NAME"
else
  echo "ℹ️  AVD already exists: $AVD_NAME"
fi

# 4. Gradle キャッシュ設定
echo "⚙️  Configuring Gradle..."
mkdir -p "$HOME/.gradle"
cat > "$HOME/.gradle/gradle.properties" << EOF
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.workers.max=4
org.gradle.jvmargs=-Xmx2048m -XX:+UseParallelGC
android.useAndroidX=true
android.enableJetifier=true
EOF

# 5. Flutter キャッシュ削除（オプション）
if command -v flutter &> /dev/null; then
  echo "🔄 Cleaning Flutter cache..."
  flutter clean --verbose || true
  flutter pub get || true
fi

echo "✅ Android Emulator setup complete!"
echo ""
echo "📌 Start emulator manually with:"
echo "   emulator -avd $AVD_NAME -no-audio -no-boot-anim &"
echo ""
echo "📌 Or run with CI/CD workflow for automated testing"
