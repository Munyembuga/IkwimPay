# Building Android App Bundle (AAB) for Play Store

This document explains how to build the Android App Bundle (AAB) file for uploading to Google Play Store.

## Prerequisites

1. **Flutter SDK** - Install Flutter from https://flutter.dev/docs/get-started/install
2. **Android SDK** - Installed via Android Studio or command-line tools
3. **Java Development Kit (JDK)** - Version 11 or higher

## Keystore Configuration

The project uses a release keystore for signing the app. The keystore configuration is stored in:
- **Keystore file**: `android/ikwimpay-release.keystore`
- **Configuration**: `android/key.properties`

### Key Properties

The `android/key.properties` file contains:
```properties
storePassword=android123
keyPassword=android123
keyAlias=ikwimpay
storeFile=ikwimpay-release.keystore
```

**IMPORTANT**: 
- These files are excluded from git (in `.gitignore`)
- For production, use strong passwords and keep them secure
- Never commit keystore files or passwords to version control
- Store keystore backup in a secure location

## Building the AAB

### Option 1: Using Flutter (Recommended)

```bash
# Navigate to project directory
cd /path/to/IkwimPay

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build the AAB
flutter build appbundle --release
```

The AAB file will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

### Option 2: Using Gradle (Without Flutter CLI)

```bash
# Navigate to project directory
cd /path/to/IkwimPay

# Navigate to android directory
cd android

# Build the AAB using Gradle
./gradlew bundleRelease
```

The AAB file will be created at:
```
android/app/build/outputs/bundle/release/app-release.aab
```

### Option 3: Using Build Script

```bash
# Make the script executable
chmod +x build_aab.sh

# Run the build script
./build_aab.sh
```

## Verification

After building, verify the AAB file:

```bash
# Check if the file exists
ls -lh build/app/outputs/bundle/release/app-release.aab

# Get file information (optional)
file build/app/outputs/bundle/release/app-release.aab
```

## Uploading to Play Store

1. Go to https://play.google.com/console
2. Select your app (or create a new app)
3. Navigate to "Release" → "Production" (or "Internal testing" for testing)
4. Click "Create new release"
5. Upload the `app-release.aab` file
6. Fill in the release details and click "Review release"
7. Submit the release for review

## App Information

- **Package Name**: com.itec.ikwimpays
- **Version**: 1.0.0+1
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: Latest (configured in Flutter)

## Troubleshooting

### Build Fails
- Ensure all dependencies are installed: `flutter pub get`
- Clean the build: `flutter clean`
- Check Flutter doctor: `flutter doctor -v`

### Keystore Issues
- Verify `key.properties` file exists in `android/` directory
- Verify `ikwimpay-release.keystore` file exists in `android/` directory
- Check that file paths in `key.properties` are correct

### Gradle Issues
- Update Gradle wrapper: `cd android && ./gradlew wrapper --gradle-version=8.0`
- Clean Gradle cache: `cd android && ./gradlew clean`

## Security Notes

⚠️ **IMPORTANT SECURITY REMINDERS**:

1. **Keystore Backup**: Always keep a secure backup of your keystore file. If you lose it, you cannot update your app on Play Store.

2. **Password Security**: Change the default passwords in `key.properties` to strong, unique passwords.

3. **Version Control**: Never commit the following files:
   - `*.keystore`
   - `*.jks`
   - `android/key.properties`

4. **Production Keys**: For production apps, create a new keystore with strong passwords and store them securely (e.g., in a password manager or secure vault).

## Creating Your Own Keystore (Optional)

If you want to create a new keystore with your own details:

```bash
keytool -genkey -v -keystore android/your-app-release.keystore \
  -alias your-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Then update android/key.properties with your values
```

## Additional Resources

- [Flutter Build Documentation](https://flutter.dev/docs/deployment/android)
- [Play Store Upload Guide](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Android App Bundle Documentation](https://developer.android.com/guide/app-bundle)
