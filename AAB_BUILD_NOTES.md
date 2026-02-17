# AAB Build Setup - Important Notes

## Configuration Complete ✅

The AAB build configuration has been successfully set up for this Flutter project. Here's what was done:

### 1. Keystore Created
- A release keystore has been created: `android/ikwimpay-release.keystore`
- Keystore configuration stored in: `android/key.properties`
- **Default credentials** (CHANGE THESE FOR PRODUCTION):
  - Store Password: `android123`
  - Key Password: `android123`
  - Key Alias: `ikwimpay`

### 2. Build Configuration Updated
- Modified `android/app/build.gradle` to include:
  - Keystore properties loading
  - Release signing configuration
  - Proper AAB build settings

### 3. Security Updates
- Updated `.gitignore` to exclude:
  - `*.keystore` files
  - `*.jks` files
  - `android/key.properties`
- This ensures sensitive signing information is never committed to git

### 4. Build Scripts Created
- `build_aab.sh` - Full Flutter build script
- `build_aab_gradle.sh` - Gradle-only build script
- Both scripts include error checking and helpful output

### 5. Documentation Created
- `BUILD_AAB.md` - Comprehensive build guide
- Updated `README.md` with quick build instructions

## To Build the AAB

### Prerequisites
You need to install Flutter SDK on your development machine:
1. Download from: https://flutter.dev/docs/get-started/install
2. Add Flutter to your PATH
3. Run `flutter doctor` to verify installation

### Building
Once Flutter is installed:

```bash
# Option 1: Use the build script
./build_aab.sh

# Option 2: Use Flutter command directly
flutter build appbundle --release
```

The AAB file will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Important Security Notes

⚠️ **PRODUCTION REMINDER**:
1. **Change the keystore passwords** before releasing to production
2. **Back up your keystore** - store it securely (password manager, cloud storage)
3. **Never lose the keystore** - you can't update your app without it
4. **Never commit the keystore** to version control

### To Create a New Keystore for Production

```bash
cd android
keytool -genkey -v -keystore my-release-key.keystore \
  -alias my-key-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Then update android/key.properties with the new values
```

## What You Can Do Now

1. ✅ Clone this repository on your development machine with Flutter installed
2. ✅ Run `flutter pub get` to install dependencies
3. ✅ Run `./build_aab.sh` to build the AAB
4. ✅ Upload the AAB to Google Play Console

## Files Modified

- `android/app/build.gradle` - Added signing configuration
- `.gitignore` - Added keystore exclusions
- `README.md` - Added build instructions

## Files Created

- `android/ikwimpay-release.keystore` - Release keystore (not in git)
- `android/key.properties` - Keystore configuration (not in git)
- `BUILD_AAB.md` - Detailed build documentation
- `build_aab.sh` - Build script (Flutter-based)
- `build_aab_gradle.sh` - Build script (Gradle-based)
- `AAB_BUILD_NOTES.md` - This file

## Next Steps

1. Install Flutter on your development machine
2. Review the BUILD_AAB.md documentation
3. Consider changing the keystore passwords for production
4. Build the AAB using one of the provided methods
5. Upload to Google Play Store

For detailed instructions, see [BUILD_AAB.md](BUILD_AAB.md)
