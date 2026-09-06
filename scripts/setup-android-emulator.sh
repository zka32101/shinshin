#!/bin/bash

# Android Emulator Setup Script
# This script sets up the Android Emulator environment for testing
# Usage: setup-android-emulator.sh --api-level 31 --target google_apis --arch x86_64

set -e

# Default values
API_LEVEL=31
TARGET="google_apis"
ARCH="x86_64"
ANDROID_HOME="${ANDROID_HOME:-.}/android"
EMULATOR_NAME="flutter_test"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --api-level)
      API_LEVEL="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --android-home)
      ANDROID_HOME="$2"
      shift 2
      ;;
    --name)
      EMULATOR_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=========================================="
echo "Android Emulator Setup"
echo "=========================================="
echo "API Level: $API_LEVEL"
echo "Target: $TARGET"
echo "Architecture: $ARCH"
echo "Android Home: $ANDROID_HOME"
echo "Emulator Name: $EMULATOR_NAME"
echo "=========================================="

# Set ANDROID_HOME if not set
export ANDROID_HOME="$ANDROID_HOME"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}"

# Update Android SDK
echo "Updating Android SDK components..."
yes | sdkmanager --update 2>/dev/null || true

# Install necessary SDK components
echo "Installing SDK components..."
yes | sdkmanager "platform-tools" 2>/dev/null || true
yes | sdkmanager "platforms;android-${API_LEVEL}" 2>/dev/null || true
yes | sdkmanager "system-images;android-${API_LEVEL};${TARGET};${ARCH}" 2>/dev/null || true

# Create emulator AVD (Android Virtual Device)
echo "Creating Android Virtual Device (AVD)..."

# Remove existing AVD if it exists
if [ -d "$HOME/.android/avd/${EMULATOR_NAME}.avd" ]; then
  echo "Removing existing AVD: $EMULATOR_NAME"
  rm -rf "$HOME/.android/avd/${EMULATOR_NAME}.avd"
  rm -f "$HOME/.android/avd/${EMULATOR_NAME}.ini"
fi

# Create new AVD
echo "Creating new AVD: $EMULATOR_NAME"
echo "" | avdmanager create avd \
  --name "$EMULATOR_NAME" \
  --package "system-images;android-${API_LEVEL};${TARGET};${ARCH}" \
  --device "pixel_4a" \
  --force

# Configure AVD with optimized settings
echo "Configuring AVD settings..."
AVD_CONFIG_PATH="$HOME/.android/avd/${EMULATOR_NAME}.avd/config.ini"

if [ -f "$AVD_CONFIG_PATH" ]; then
  # Enable GPU acceleration for speed
  sed -i.bak 's/^hw.gpu.enabled=.*/hw.gpu.enabled=yes/' "$AVD_CONFIG_PATH" || true
  sed -i.bak 's/^hw.gpu.mode=.*/hw.gpu.mode=swiftshader_indirect/' "$AVD_CONFIG_PATH" || true

  # Set memory allocation
  sed -i.bak 's/^hw.ramSize=.*/hw.ramSize=2048/' "$AVD_CONFIG_PATH" || true

  # Disable unnecessary features for faster boot
  sed -i.bak 's/^showDeviceFrame=.*/showDeviceFrame=no/' "$AVD_CONFIG_PATH" || true

  # Enable fast boot (snapshot)
  echo "vm.heapSize=512" >> "$AVD_CONFIG_PATH" || true
  echo "fastboot.chosenSnapshotFile=default_boot" >> "$AVD_CONFIG_PATH" || true

  # Clean up backup files
  rm -f "$AVD_CONFIG_PATH.bak"

  echo "AVD configuration completed:"
  cat "$AVD_CONFIG_PATH"
fi

echo ""
echo "=========================================="
echo "Android Emulator setup completed!"
echo "=========================================="
echo "To start the emulator, run:"
echo "  \${ANDROID_HOME}/emulator/emulator -avd $EMULATOR_NAME"
echo ""
