# AAB Build Workflow

This document provides a visual workflow for building and deploying your AAB to the Play Store.

## 📊 Build Process Flow

```
┌─────────────────────────────────────────────────────────┐
│                    PREREQUISITES                         │
├─────────────────────────────────────────────────────────┤
│ 1. Flutter SDK installed                                │
│ 2. Project cloned on dev machine                        │
│ 3. Android SDK configured (via flutter doctor)          │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│              INSTALL DEPENDENCIES                        │
│                                                          │
│  $ flutter pub get                                       │
│                                                          │
│  ✓ Downloads all required packages                      │
│  ✓ Resolves dependencies                                │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│              BUILD AAB FILE                              │
│                                                          │
│  Option 1: $ ./build_aab.sh                             │
│  Option 2: $ flutter build appbundle --release          │
│                                                          │
│  Process:                                                │
│  1. Validates keystore exists                           │
│  2. Compiles Dart code                                  │
│  3. Builds Android resources                            │
│  4. Creates optimized bundle                            │
│  5. Signs with release keystore                         │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│              LOCATE AAB FILE                             │
│                                                          │
│  Path: build/app/outputs/bundle/release/                │
│  File: app-release.aab                                  │
│                                                          │
│  Typical size: 20-50 MB                                 │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│           UPLOAD TO PLAY STORE                           │
│                                                          │
│  1. Go to: play.google.com/console                      │
│  2. Select your app                                     │
│  3. Release → Production (or Testing)                   │
│  4. Create new release                                  │
│  5. Upload app-release.aab                              │
│  6. Fill release notes                                  │
│  7. Submit for review                                   │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────┐
│              APP PUBLISHED! 🎉                           │
└─────────────────────────────────────────────────────────┘
```

## 🗂️ File Structure

```
IkwimPay/
│
├── android/
│   ├── app/
│   │   └── build.gradle            ← Signing configuration
│   ├── ikwimpay-release.keystore   ← Your signing key (NOT in git)
│   └── key.properties              ← Keystore credentials (NOT in git)
│
├── build/                          ← Created during build
│   └── app/
│       └── outputs/
│           └── bundle/
│               └── release/
│                   └── app-release.aab  ← YOUR AAB FILE!
│
├── BUILD_AAB.md                    ← Detailed build guide
├── QUICK_START.md                  ← Quick reference
├── AAB_SETUP_COMPLETE.md           ← Setup summary
├── build_aab.sh                    ← Build script
└── pubspec.yaml                    ← App version info
```

## 🔑 Keystore Files (Secured)

```
android/
├── ikwimpay-release.keystore       🔒 Private key (2.7 KB)
└── key.properties                  🔒 Credentials file

Both files are:
✓ Excluded from git (.gitignore)
✓ Required for signing
✓ Must be backed up securely
⚠️  Never share or commit these!
```

## 📋 Command Reference

### One-Time Setup
```bash
# Clone repository
git clone https://github.com/Munyembuga/IkwimPay.git
cd IkwimPay

# Verify Flutter
flutter doctor

# Install dependencies
flutter pub get
```

### Build Commands
```bash
# Clean build (if needed)
flutter clean

# Build AAB (recommended)
./build_aab.sh

# Or manual build
flutter build appbundle --release
```

### Verification
```bash
# Check if AAB was created
ls -lh build/app/outputs/bundle/release/app-release.aab

# Should show file size (typically 20-50 MB)
```

## 🎯 Version Management

To update your app version before building:

1. Edit `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Format: major.minor.patch+buildNumber
   ```

2. Build new AAB:
   ```bash
   ./build_aab.sh
   ```

3. Upload to Play Store as new version

## ⚡ Quick Commands

```bash
# Full build from scratch
flutter clean && flutter pub get && ./build_aab.sh

# Check Flutter environment
flutter doctor -v

# Test on connected device
flutter run --release

# Analyze code
flutter analyze
```

## 🆘 Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| "Flutter not found" | Add Flutter to PATH or use full path |
| "Keystore not found" | Ensure `android/key.properties` exists |
| "Build failed" | Run `flutter clean` then retry |
| "Gradle error" | Delete `android/.gradle` and rebuild |
| "Out of memory" | Add `org.gradle.jvmargs=-Xmx2048m` to `android/gradle.properties` |

## 📱 Testing Before Upload

```bash
# Test on connected device
flutter run --release

# Or build APK for testing
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

## 🔄 Update Workflow

For subsequent updates:

```bash
1. Update code/features
2. Increment version in pubspec.yaml
3. flutter pub get
4. ./build_aab.sh
5. Upload new AAB to Play Store
6. Create release notes
7. Submit update
```

## 📚 Documentation Map

| When? | Read This |
|-------|-----------|
| First time setup | `AAB_SETUP_COMPLETE.md` |
| Need quick build | `QUICK_START.md` |
| Troubleshooting | `BUILD_AAB.md` |
| Process overview | `BUILD_WORKFLOW.md` (this file) |
| Important notes | `AAB_BUILD_NOTES.md` |

---

**Ready to build?** Start with `QUICK_START.md` for a step-by-step checklist!
