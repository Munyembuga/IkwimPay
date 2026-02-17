#!/bin/bash

# IkwimPay - Quick Build Script for Play Store
# This script helps build the app for Google Play Store release

echo "======================================"
echo "IkwimPay - Play Store Build Script"
echo "======================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  WARNING: android/key.properties not found!"
    echo "You need to create this file for signing the release build."
    echo "See PLAYSTORE_BUILD_GUIDE.md for instructions."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Ask what to build
echo "What would you like to build?"
echo "1) APK (for testing)"
echo "2) App Bundle/AAB (for Play Store - RECOMMENDED)"
echo "3) Both"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "📱 Building APK..."
        flutter build apk --release
        echo ""
        echo "✅ APK built successfully!"
        echo "Location: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    2)
        echo ""
        echo "📦 Building App Bundle..."
        flutter build appbundle --release
        echo ""
        echo "✅ App Bundle built successfully!"
        echo "Location: build/app/outputs/bundle/release/app-release.aab"
        ;;
    3)
        echo ""
        echo "📱 Building APK..."
        flutter build apk --release
        echo ""
        echo "📦 Building App Bundle..."
        flutter build appbundle --release
        echo ""
        echo "✅ Both builds completed successfully!"
        echo "APK Location: build/app/outputs/flutter-apk/app-release.apk"
        echo "AAB Location: build/app/outputs/bundle/release/app-release.aab"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Build Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Test the release build on a physical device"
echo "2. Upload to Google Play Console"
echo "3. See PLAYSTORE_BUILD_GUIDE.md for detailed upload instructions"
