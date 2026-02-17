# Quick Start Guide - Build for Play Store

This is a quick reference guide. For detailed instructions, see [PLAYSTORE_BUILD_GUIDE.md](PLAYSTORE_BUILD_GUIDE.md).

## 🚀 Quick Setup (One-Time)

### 1. Create Keystore (Windows)
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ikwimpay
```

### 2. Create key.properties
Create `android/key.properties` file:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD  
keyAlias=ikwimpay
storeFile=upload-keystore.jks
```

**⚠️ IMPORTANT**: Back up `upload-keystore.jks` and remember your passwords!

## 📱 Build for Play Store

### Option 1: Use Build Script (Easiest)

**Windows:**
```bash
build_for_playstore.bat
```

**Mac/Linux:**
```bash
./build_for_playstore.sh
```

### Option 2: Manual Build

**For Play Store (recommended):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**For testing:**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

## 📝 Before Each Release

1. Update version in `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment the number after +
```

2. Clean and build:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

3. Test the release build thoroughly!

## 📤 Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to "Production" → "Create new release"
4. Upload `app-release.aab`
5. Add release notes
6. Review and submit

## 📚 More Information

- **Complete Guide**: [PLAYSTORE_BUILD_GUIDE.md](PLAYSTORE_BUILD_GUIDE.md)
- **Upload Checklist**: [PLAYSTORE_CHECKLIST.md](PLAYSTORE_CHECKLIST.md)
- **Flutter Docs**: https://flutter.dev/docs/deployment/android

## 🆘 Need Help?

Common issues and solutions in [PLAYSTORE_BUILD_GUIDE.md](PLAYSTORE_BUILD_GUIDE.md#troubleshooting)
