# Installation & Setup Guide

**小学コレ！道徳 (Shougaku Kore Doutoku)**  
**Document Version**: 1.0  
**Last Updated**: 2026-09-02  
**Status**: Complete

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Development Setup](#development-setup)
3. [Backend Setup](#backend-setup)
4. [Firebase Configuration](#firebase-configuration)
5. [Running the Application](#running-the-application)
6. [Building for Release](#building-for-release)
7. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements

| Component | Minimum Version | Recommended | Notes |
|-----------|-----------------|-------------|-------|
| Flutter | 3.19.0 | 3.19.5+ | Dart 3.3.0+ required |
| Dart | 3.3.0 | 3.3.4+ | Included with Flutter |
| iOS | 12.0 | 14.0+ | iPhone SE or newer |
| Android | 7.0 (API 24) | 11.0+ | 2GB RAM minimum |
| macOS | 12.0 | 13.0+ | For iOS development |
| Xcode | 13.0 | 14.0+ | macOS only |
| Android Studio | 2021.1 | 2022.3+ | For Android development |
| Node.js | 14.0 | 16.0+ | For backend tools (optional) |
| Python | 3.9+ | 3.11 | For backend API |
| PostgreSQL | 13+ | 14+ | For backend database |
| Git | 2.30+ | Latest | For version control |

### Hardware Requirements

**For Development**:
- RAM: 8GB minimum (16GB recommended)
- Disk: 50GB free space (for SDKs, emulators, build artifacts)
- CPU: Multi-core processor (4+ cores recommended)

**For Testing**:
- Physical device: Mid-range Android/iOS phone recommended
- Emulator: Pixel 4a (Android) or iPhone 12 (iOS)

---

## Development Setup

### 1. Install Flutter

**macOS/Linux**:
```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git --branch stable
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify installation
flutter doctor
```

**Windows** (use [Flutter installer](https://flutter.dev/docs/get-started/install/windows)):
```bash
# Download and run installer from flutter.dev
# Add Flutter to PATH
flutter doctor
```

### 2. Install Dependencies

```bash
# Navigate to project root
cd shinshin

# Get Dart/Flutter packages
flutter pub get

# Run code generation (for models, routing, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor
```

**Expected Output**:
```
[✓] Flutter (Channel stable, 3.19.5, on macOS 13.6)
[✓] Android toolchain
[✓] Xcode (for iOS development)
[✓] VS Code (or IDE of choice)
[?] Android emulator (optional)
```

### 3. Configure IDE

#### VS Code
```bash
# Install extensions
# - Flutter (ID: Dart-Code.flutter)
# - Dart (ID: Dart-Code.dart-code)

# Create launch configuration (.vscode/launch.json)
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--verbose"]
    }
  ]
}
```

#### Android Studio/IntelliJ
```bash
# Install plugins
# - Flutter
# - Dart

# Create run configuration
# - Select "lib/main.dart" as entry point
# - Choose target device (emulator or physical)
```

### 4. Set Up Environment Variables

Create `.env` file in project root:
```env
# Firebase Configuration
FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID
FIREBASE_PROJECT_ID=shougaku-kore-doutoku
FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID

# API Configuration (if using custom backend)
API_BASE_URL=http://localhost:8000
API_VERSION=v1

# Environment
APP_ENV=development
DEBUG=true
```

**Loading Environment Variables**:
```dart
// In lib/main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}
```

### 5. Initialize Git Hooks (Optional)

```bash
# Create pre-commit hook for code quality checks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
flutter analyze
flutter test
EOF

chmod +x .git/hooks/pre-commit
```

---

## Backend Setup

### 1. Install Python & PostgreSQL

**macOS**:
```bash
# Using Homebrew
brew install python@3.11
brew install postgresql@14

# Start PostgreSQL
brew services start postgresql@14
```

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install python3.11 python3.11-venv postgresql-14

# Start PostgreSQL
sudo systemctl start postgresql
```

**Windows**:
```bash
# Download and install from:
# - Python: https://www.python.org/downloads/
# - PostgreSQL: https://www.postgresql.org/download/windows/

# Verify installation
python --version
psql --version
```

### 2. Set Up Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database and user
CREATE DATABASE shougaku_db;
CREATE USER shougaku_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE shougaku_db TO shougaku_user;
\q
```

### 3. Set Up Python Backend

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python3.11 -m venv venv

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Create .env file for backend
cat > .env << 'EOF'
DATABASE_URL=postgresql+asyncpg://shougaku_user:secure_password@localhost:5432/shougaku_db
SECRET_KEY=your-secret-key-change-in-production-min-64-chars
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=INFO
EOF
```

### 4. Run Database Migrations

```bash
# From backend directory with virtual environment active

# Create tables (using Alembic or SQLAlchemy)
alembic upgrade head

# Or using FastAPI's built-in migration (if configured)
python -m app.db.create_tables
```

### 5. Seed Database (Optional)

```bash
# Load initial data
python scripts/seed_database.py

# Expected output:
# ✓ Loaded 50+ story scenarios
# ✓ Loaded virtue categories
# ✓ Loaded badge definitions
```

### 6. Start Backend Server

```bash
# From backend directory with virtual environment active
uvicorn app.main:app --reload --port 8000

# Output:
# INFO:     Uvicorn running on http://127.0.0.1:8000
# INFO:     Application startup complete
```

**API Documentation**: http://localhost:8000/docs

---

## Firebase Configuration

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create Project"
3. Name: `shougaku-kore-doutoku`
4. Enable Google Analytics (recommended for analytics)
5. Select default Google Cloud project location

### 2. Register Android App

```bash
# In Firebase Console:
1. Click "Add app" → Android
2. Package name: jp.petitworks.shougakuKoreDoutoku
3. SHA-1: Run `./gradlew signingReport` from android/ directory
4. Download google-services.json
5. Place in: android/app/google-services.json
```

### 3. Register iOS App

```bash
# In Firebase Console:
1. Click "Add app" → iOS
2. Bundle ID: jp.petitworks.shougakuKoreDoutoku
3. Download GoogleService-Info.plist
4. Place in: ios/Runner/GoogleService-Info.plist
5. Follow Xcode integration steps
```

### 4. Configure Firebase Options

Update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: '1:000000000000:android:aaaaaaaaaaaaaaaa',
  messagingSenderId: '000000000000',
  projectId: 'shougaku-kore-doutoku',
  databaseURL: 'https://shougaku-kore-doutoku.firebaseio.com',
  storageBucket: 'shougaku-kore-doutoku.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: '1:000000000000:ios:bbbbbbbbbbbbbbbb',
  messagingSenderId: '000000000000',
  projectId: 'shougaku-kore-doutoku',
  databaseURL: 'https://shougaku-kore-doutoku.firebaseio.com',
  storageBucket: 'shougaku-kore-doutoku.appspot.com',
  iosClientId: 'YOUR_IOS_CLIENT_ID',
  iosBundleId: 'jp.petitworks.shougakuKoreDoutoku',
);
```

### 5. Enable Firebase Services

In Firebase Console:
- ✅ Authentication (Email/Password)
- ✅ Firestore Database (for real-time data)
- ✅ Cloud Storage (for avatars/media)
- ✅ Cloud Messaging (for push notifications)
- ✅ Analytics (for user tracking)

### 6. Set Up Firebase Emulator (For Testing)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize emulator
firebase init emulator

# Start emulator
firebase emulators:start

# In app, connect to emulator during development:
# FirebaseAuth.instance.useEmulator('localhost', 9099);
```

---

## Running the Application

### 1. Run on Emulator

```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run

# Run on iOS simulator
flutter run -d iphone

# Run with specific configuration
flutter run --debug --verbose
```

### 2. Run on Physical Device

**Android**:
```bash
# Connect device via USB and enable USB debugging
adb devices  # Should list your device

# Run app
flutter run -d <device-id>
```

**iOS**:
```bash
# Connect device and enable Developer Mode
# In Xcode: Window → Devices and Simulators → Trust this computer

# Run app
flutter run -d <device-id>
```

### 3. Hot Reload & Hot Restart

```bash
# During flutter run session:

# Hot reload (rebuild only changed code)
Press 'r'

# Hot restart (full app restart)
Press 'R'

# Quit
Press 'q'
```

### 4. Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
```

---

## Building for Release

### Android Release Build

```bash
# Generate keystore (one-time setup)
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -alias upload

# Create key.properties file
cat > android/key.properties << 'EOF'
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
EOF

# Build APK (for sideloading/testing)
flutter build apk --release

# Build App Bundle (for Google Play)
flutter build appbundle --release

# Outputs
# APK: build/app/outputs/apk/release/app-release.apk
# AAB: build/app/outputs/bundle/release/app.aab
```

### iOS Release Build

```bash
# Requires Apple Developer account and provisioning profiles

# Build IPA (for App Store)
flutter build ios --release

# Follow Xcode steps to sign and upload
# Or use Xcode directly:
# 1. flutter build ios --release
# 2. Open ios/Runner.xcworkspace in Xcode
# 3. Select Generic iOS Device
# 4. Product → Archive
# 5. Distribute App

# Output
# Archive: build/ios/archive/*.xcarchive
```

### Build Configuration

Create `lib/config/build_config.dart`:
```dart
class BuildConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const String firebaseProjectId = 'shougaku-kore-doutoku';
  
  static const bool isProduction = String.fromEnvironment('ENVIRONMENT') == 'production';
  
  static const bool enableAnalytics = isProduction;
}
```

### Build Arguments

```bash
# Build with custom configuration
flutter build apk --release \
  -t lib/main.dart \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.example.com
```

---

## Troubleshooting

### Issue: `flutter pub get` Fails

**Cause**: Network issues or dependency conflicts

**Solution**:
```bash
# Clear pub cache
flutter pub cache clean

# Delete lock files
rm pubspec.lock
rm -rf .dart_tool

# Get dependencies again
flutter pub get --verbose
```

### Issue: "No connected devices"

**Solution - Android**:
```bash
# Check ADB
adb devices

# If device not listed, enable USB debugging:
# Settings > Developer options > USB debugging > On

# Reconnect device
adb kill-server
adb start-server
```

**Solution - iOS**:
```bash
# Check Xcode devices
open -a Simulator

# Or connect physical device and trust it in Xcode
```

### Issue: "SDK not found"

**Solution**:
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Verify Flutter SDK
flutter doctor -v
```

### Issue: Build Fails with "Error building for device"

**Solution**:
```bash
# Clean build directory
flutter clean

# Reinstall dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build

# Rebuild
flutter run
```

### Issue: Firebase Configuration Error

**Solution**:
```bash
# Verify Firebase files are in correct location
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist

# For iOS, also check Xcode build phases:
# Build Phases → Link Binary With Libraries → Add Firebase pods
```

### Issue: Backend Connection Fails

**Solution**:
```bash
# Check backend is running
curl http://localhost:8000/docs

# Verify API_BASE_URL in .env
cat .env | grep API_BASE_URL

# Check network connectivity
ping localhost

# For iOS simulator accessing localhost backend:
# Use 10.0.2.2 instead of localhost
# API_BASE_URL=http://10.0.2.2:8000
```

### Issue: Database Connection Error

**Solution**:
```bash
# Verify PostgreSQL is running
psql -U postgres -c "SELECT version();"

# Check DATABASE_URL in backend/.env
grep DATABASE_URL backend/.env

# Test connection manually
PGPASSWORD=secure_password psql -U shougaku_user -d shougaku_db -h localhost -c "SELECT 1"
```

---

## Development Workflow

### Daily Development

```bash
# Terminal 1: Backend API
cd backend
source venv/bin/activate
uvicorn app.main:app --reload

# Terminal 2: Flutter App
cd shinshin
flutter run

# Terminal 3: Database (if needed)
psql -U shougaku_user -d shougaku_db
```

### Code Generation

```bash
# Generate models, routes, freezed classes
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes (rebuild on file save)
flutter pub run build_runner watch
```

### Running All Tests

```bash
# Backend tests
cd backend
pytest tests/ -v --cov=app

# Flutter tests
cd ../
flutter test --coverage

# Integration tests
flutter test integration_test/ -v
```

---

## Performance Optimization

### Flutter App

1. **Profile app performance**:
   ```bash
   flutter run --profile
   ```

2. **Use DevTools for analysis**:
   ```bash
   flutter pub global activate devtools
   devtools
   # Open http://localhost:9100 in browser
   ```

3. **Check memory usage**:
   ```bash
   # In DevTools → Memory tab
   # Profile heap snapshots
   # Track memory leaks
   ```

### Backend API

1. **Database optimization**:
   ```python
   # Use connection pooling
   # Index frequently queried columns
   # Optimize N+1 query issues
   ```

2. **API performance**:
   ```bash
   # Load test with Apache Bench
   ab -n 100 -c 10 http://localhost:8000/api/v1/stories
   ```

---

## Next Steps

1. ✅ Follow the setup guide above
2. ✅ Run `flutter run` and verify app launches
3. ✅ Test backend API at http://localhost:8000/docs
4. ✅ Configure Firebase credentials
5. ✅ Build release APK/AAB for testing
6. ✅ Prepare for submission to app stores

---

## Additional Resources

- [Flutter Installation](https://flutter.dev/docs/get-started/install)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)

---

**Document Status**: Complete  
**Last Updated**: 2026-09-02  
**Maintained by**: Phase 5 Documentation Team
