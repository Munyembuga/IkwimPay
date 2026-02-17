# Building IkwimPay for Google Play Store

This guide will help you build and prepare the IkwimPay app for upload to the Google Play Store.

## Prerequisites

1. **Flutter SDK**: Install Flutter from https://flutter.dev/docs/get-started/install
2. **Android Studio**: Install from https://developer.android.com/studio
3. **Java Development Kit (JDK)**: Version 8 or higher

## Step 1: Create a Keystore

A keystore is required to sign your app for release. You only need to do this once.

### On Windows:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ikwimpay
```

### On macOS/Linux:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ikwimpay
```

**Important Notes:**
- Choose a strong password and remember it!
- Keep the keystore file safe - you'll need it for all future updates
- Back up the keystore file in a secure location
- If you lose the keystore, you won't be able to update your app

You will be asked for:
- Keystore password (remember this!)
- Key password (can be the same as keystore password)
- Your name, organization, city, state, and country
- Confirmation

## Step 2: Configure the Key Properties

1. Move the generated `upload-keystore.jks` file to the `android/` directory of your project
2. Create a file named `key.properties` in the `android/` directory
3. Use the template file `android/key.properties.template` as reference
4. Add the following content to `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ikwimpay
storeFile=../upload-keystore.jks
```

Replace:
- `YOUR_KEYSTORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password (usually the same as keystore password)

**Note**: The `key.properties` file is automatically ignored by git for security.

## Step 3: Update App Version

Before building, update the version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

The format is `version+buildNumber`:
- `1.0.0` is the version name (shown to users)
- `1` is the version code (must increment with each release)

For subsequent releases:
- Increment version code: `1.0.0+2`, `1.0.0+3`, etc.
- Update version name as needed: `1.0.1+2`, `1.1.0+3`, etc.

## Step 4: Build the App

### Build an APK (for testing)
```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

### Build an App Bundle (AAB) - RECOMMENDED for Play Store
```bash
flutter build appbundle --release
```

The AAB will be located at: `build/app/outputs/bundle/release/app-release.aab`

**Why AAB?**
- Smaller download sizes for users
- Google Play's preferred format
- Automatic optimization for different device configurations

## Step 5: Test the Release Build

### Install APK on a device:
```bash
flutter install --release
```

Or manually install the APK:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Important Testing Checklist:
- [ ] Test all major features
- [ ] Check camera functionality
- [ ] Test NFC features (if applicable)
- [ ] Verify Bluetooth printer connectivity
- [ ] Test permissions (camera, storage, Bluetooth, NFC)
- [ ] Check app performance
- [ ] Verify no crashes or errors

## Step 6: Prepare for Play Store Upload

### Required Assets

1. **App Icon**: Already configured in `pubspec.yaml`
   - Location: `assets/images/loga.png`

2. **Screenshots**: Prepare screenshots of your app (required by Play Store)
   - At least 2 screenshots
   - Recommended: 4-8 screenshots showing key features
   - Supported formats: PNG or JPEG
   - Minimum dimension: 320px
   - Maximum dimension: 3840px

3. **Feature Graphic** (required):
   - Size: 1024px x 500px
   - Format: PNG or JPEG

4. **Privacy Policy**: Create and host a privacy policy URL
   - Required because the app requests sensitive permissions
   - Must cover data collection and usage

### App Information Needed

- **Title**: IkwimPay (max 50 characters)
- **Short Description**: Brief description (max 80 characters)
- **Full Description**: Detailed description (max 4000 characters)
- **App Category**: Finance or Business
- **Content Rating**: Complete the questionnaire
- **Pricing**: Free or Paid
- **Countries**: Select target countries

## Step 7: Upload to Google Play Console

1. **Create a Google Play Developer Account**
   - Visit https://play.google.com/console
   - Pay one-time $25 registration fee
   - Complete account setup

2. **Create a New App**
   - Click "Create app"
   - Fill in app details
   - Select default language and app type

3. **Complete Store Listing**
   - Upload app icon, screenshots, and feature graphic
   - Write app description
   - Add privacy policy URL
   - Set categorization

4. **Upload the App Bundle**
   - Go to "Production" or "Internal testing"
   - Click "Create new release"
   - Upload `app-release.aab`
   - Add release notes
   - Review and save

5. **Content Rating**
   - Complete the content rating questionnaire
   - Get your rating certificate

6. **Pricing and Distribution**
   - Set app pricing
   - Select countries
   - Agree to policies

7. **Submit for Review**
   - Review all sections
   - Click "Submit for review"
   - Wait for Google's approval (typically 1-3 days)

## Troubleshooting

### Build Errors

**"Gradle build failed"**
- Run `flutter clean` then try building again
- Check that Java and Android SDK are properly installed

**"Keystore not found"**
- Verify the path in `key.properties` is correct
- Ensure `upload-keystore.jks` exists in the `android/` directory

**"Execution failed for task ':app:minifyReleaseWithR8'"**
- Check ProGuard rules in `android/app/proguard-rules.pro`
- May need to add keep rules for specific classes

### Testing Issues

**App crashes on startup**
- Check ProGuard rules aren't removing necessary classes
- Test with minification disabled first: modify `build.gradle` temporarily

**Permissions not working**
- Verify all permissions in `AndroidManifest.xml`
- Request permissions at runtime for Android 6.0+

## App Permissions

This app requires the following permissions (already configured):
- **CAMERA**: For scanning QR codes and capturing images
- **BLUETOOTH**: For connecting to thermal printers
- **NFC**: For NFC card reading
- **INTERNET**: For online features
- **STORAGE**: For saving receipts and images

Make sure to explain these permissions in your app description and privacy policy.

## Security Best Practices

1. **Never commit the keystore file** - It's gitignored automatically
2. **Never commit `key.properties`** - It's gitignored automatically
3. **Keep backups** of your keystore in a secure location
4. **Use strong passwords** for keystore and key
5. **Document passwords** in a secure password manager

## Support

For issues or questions:
- Flutter documentation: https://flutter.dev/docs
- Google Play Console help: https://support.google.com/googleplay/android-developer

## Version History

- v1.0.0+1: Initial release

---

**Remember**: Always increment the version code before each new release!
