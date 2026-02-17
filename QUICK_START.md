# Quick Start: Building AAB for Play Store

Follow these steps to build your AAB file:

## ☑️ Pre-Build Checklist

- [ ] Install Flutter SDK (https://flutter.dev/docs/get-started/install)
- [ ] Verify installation: `flutter doctor`
- [ ] Clone this repository to your development machine
- [ ] Navigate to project directory: `cd IkwimPay`

## 🔨 Build Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Build the AAB
Choose one of these methods:

**Method A: Use the build script (Recommended)**
```bash
chmod +x build_aab.sh
./build_aab.sh
```

**Method B: Use Flutter command**
```bash
flutter build appbundle --release
```

### Step 3: Locate the AAB file
The file will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

## 📤 Upload to Play Store

1. Go to https://play.google.com/console
2. Select your app (or create new app)
3. Navigate to: **Release** → **Production**
4. Click **Create new release**
5. Upload the `app-release.aab` file
6. Fill in release notes
7. Submit for review

## ⚠️ Important Notes

### Security
- The current keystore uses default passwords (`android123`)
- **For production**: Create a new keystore with strong passwords
- **Never commit** the keystore file to version control
- **Always backup** your keystore file securely

### First Time Setup
If this is your first build:
1. Make sure you have accepted Android SDK licenses: `flutter doctor --android-licenses`
2. Ensure Android SDK is properly installed
3. Have at least 8GB of disk space available

### Troubleshooting

**Problem**: `flutter: command not found`
- **Solution**: Add Flutter to your PATH or use full path to flutter binary

**Problem**: Build fails with Gradle error
- **Solution**: 
  ```bash
  flutter clean
  flutter pub get
  cd android
  ./gradlew clean
  cd ..
  flutter build appbundle --release
  ```

**Problem**: Signing configuration error
- **Solution**: Verify `android/key.properties` and `android/ikwimpay-release.keystore` exist

## 📚 More Information

- Detailed documentation: [BUILD_AAB.md](BUILD_AAB.md)
- Setup notes: [AAB_BUILD_NOTES.md](AAB_BUILD_NOTES.md)
- Flutter deployment guide: https://flutter.dev/docs/deployment/android

## ✅ After Build

- [ ] Verify AAB file exists and has reasonable size (> 10MB typically)
- [ ] Test the app on a device before uploading
- [ ] Review Play Store requirements
- [ ] Prepare store listing (screenshots, description, etc.)
- [ ] Upload AAB to Play Store
- [ ] Submit for review

---

**Questions?** Review the full documentation in BUILD_AAB.md
