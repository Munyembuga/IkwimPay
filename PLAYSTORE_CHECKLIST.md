# Play Store Upload Checklist

Use this checklist to ensure you have everything ready before uploading to Google Play Store.

## ✅ Pre-Build Checklist

### 1. Code Preparation
- [ ] All features are complete and tested
- [ ] App is stable with no critical bugs
- [ ] All debugging code and logs removed
- [ ] App tested on multiple devices/screen sizes
- [ ] All permissions are necessary and justified

### 2. Keystore Setup
- [ ] Keystore file created (upload-keystore.jks)
- [ ] Keystore backed up in secure location
- [ ] key.properties file created in android/ folder
- [ ] Passwords documented in secure password manager
- [ ] Keystore file is in android/ directory
- [ ] key.properties configured correctly

### 3. Version Management
- [ ] Version code incremented in pubspec.yaml
- [ ] Version name updated appropriately
- [ ] Release notes prepared

## 📦 Build Checklist

### 1. Clean Build
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Build completed without errors

### 2. Build Outputs
- [ ] APK built for testing: `flutter build apk --release`
- [ ] App Bundle built for Play Store: `flutter build appbundle --release`
- [ ] Both builds signed with release keystore

### 3. Release Testing
- [ ] APK installed on physical device
- [ ] All core features tested
- [ ] Camera functionality works
- [ ] NFC features work (if applicable)
- [ ] Bluetooth printer connection works
- [ ] No crashes or unexpected behavior
- [ ] Performance is acceptable
- [ ] App works on different Android versions (test on min SDK 26)

## 🎨 Store Assets Checklist

### Required Assets
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG/JPEG)
- [ ] At least 2 screenshots (up to 8 recommended)
  - [ ] Screenshot 1
  - [ ] Screenshot 2
  - [ ] Screenshot 3
  - [ ] Screenshot 4
  - [ ] Additional screenshots as needed

### Asset Guidelines
- [ ] Screenshots show key features
- [ ] Screenshots have consistent style
- [ ] No device frames in screenshots (Play Store adds them)
- [ ] Images are high quality
- [ ] Feature graphic is eye-catching and brand-consistent

## 📝 Store Listing Checklist

### Required Information
- [ ] App title: ________________________
- [ ] Short description (80 chars): ________________________
- [ ] Full description (up to 4000 chars): ________________________
- [ ] App category selected
- [ ] Contact email: ________________________
- [ ] Privacy policy URL: ________________________
- [ ] Content rating questionnaire completed

### Optional Information
- [ ] Promotional text
- [ ] Video URL (YouTube/Vimeo)
- [ ] Website URL
- [ ] Support URL

## 🔐 Privacy & Security Checklist

### Privacy Policy
- [ ] Privacy policy created
- [ ] Privacy policy hosted online
- [ ] Privacy policy URL accessible
- [ ] Privacy policy covers all data collection
- [ ] Privacy policy mentions permissions:
  - [ ] Camera
  - [ ] Bluetooth
  - [ ] NFC
  - [ ] Internet
  - [ ] Storage

### Permissions Justification
- [ ] Camera: For QR code scanning and document capture
- [ ] Bluetooth: For thermal printer connectivity
- [ ] NFC: For NFC card reading
- [ ] Internet: For online features and updates
- [ ] Storage: For saving receipts and images

## 🏪 Google Play Console Checklist

### Account Setup
- [ ] Google Play Developer account created ($25 one-time fee)
- [ ] Payment profile set up
- [ ] Developer account verified

### App Configuration
- [ ] New app created in Play Console
- [ ] App details filled out
- [ ] Default language set
- [ ] App access (all functionality available)

### Release Configuration
- [ ] Production track selected (or Internal/Alpha/Beta for testing)
- [ ] App bundle uploaded
- [ ] Release notes added
- [ ] Rollout percentage set (or 100% for full release)

### Content Rating
- [ ] Content rating questionnaire completed
- [ ] Rating certificate obtained
- [ ] Rating displayed correctly

### Pricing & Distribution
- [ ] Pricing set (Free or Paid)
- [ ] Countries/regions selected
- [ ] Contains ads? (Yes/No)
- [ ] Age restriction reviewed

### App Content
- [ ] Target audience and content selected
- [ ] News app declaration (if applicable)
- [ ] COVID-19 contact tracing declaration (if applicable)
- [ ] Store presence reviewed

## 🚀 Final Submission Checklist

### Pre-Submission Review
- [ ] All sections show green checkmarks
- [ ] Store listing preview looks good
- [ ] App bundle is the latest version
- [ ] Release notes are accurate
- [ ] All warnings addressed

### Submission
- [ ] "Review and rollout release" completed
- [ ] Submitted for review
- [ ] Confirmation email received

### Post-Submission
- [ ] Review status monitored (typically 1-3 days)
- [ ] Respond to any issues from Google
- [ ] Plan for launch announcement
- [ ] Monitor crash reports and user feedback

## 📊 Post-Launch Checklist

### Monitoring
- [ ] Check crash reports daily
- [ ] Monitor user reviews
- [ ] Track download numbers
- [ ] Review performance metrics
- [ ] Check for ANR (App Not Responding) reports

### Updates
- [ ] Plan regular updates
- [ ] Keep dependencies up to date
- [ ] Address user feedback
- [ ] Fix critical bugs promptly

## 🆘 Troubleshooting

### Common Issues
- [ ] Build errors: Run `flutter clean` and rebuild
- [ ] Signing errors: Verify key.properties is correct
- [ ] Review delays: Be patient, typically 1-3 days
- [ ] Rejection: Read feedback carefully and address issues

## 📞 Support Resources

- Google Play Console: https://play.google.com/console
- Play Console Help: https://support.google.com/googleplay/android-developer
- Flutter Docs: https://flutter.dev/docs
- IkwimPay Build Guide: PLAYSTORE_BUILD_GUIDE.md

---

## Notes

Use this space for any additional notes, passwords (in a secure manner), or important information:

______________________________________________________________________

______________________________________________________________________

______________________________________________________________________

---

**Remember**: 
- Never share your keystore file publicly
- Back up your keystore in multiple secure locations
- Increment version code with each release
- Test thoroughly before each release
- Keep this checklist updated with your process
