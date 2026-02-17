#!/bin/bash

# Build AAB for IkwimPay App
# This script builds the Android App Bundle for uploading to Google Play Store

set -e  # Exit on error

echo "========================================="
echo "Building AAB for IkwimPay"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"
echo ""

# Check if keystore exists
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}Error: android/key.properties not found${NC}"
    echo ""
    echo "Please create the key.properties file with your keystore information."
    echo "See BUILD_AAB.md for instructions on creating a keystore."
    echo ""
    echo "Example key.properties content:"
    echo "  storePassword=YOUR_STORE_PASSWORD"
    echo "  keyPassword=YOUR_KEY_PASSWORD"
    echo "  keyAlias=YOUR_KEY_ALIAS"
    echo "  storeFile=YOUR_KEYSTORE_FILE.keystore"
    exit 1
fi

if [ ! -f "android/ikwimpay-release.keystore" ]; then
    echo -e "${YELLOW}Warning: android/ikwimpay-release.keystore not found${NC}"
    echo "Please ensure the keystore file exists before building for release."
    exit 1
fi

echo -e "${GREEN}✓ Keystore configuration found${NC}"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Build the AAB
echo "Building Android App Bundle (AAB)..."
echo "This may take a few minutes..."
echo ""

flutter build appbundle --release

echo ""
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "AAB file location:"
    echo "  build/app/outputs/bundle/release/app-release.aab"
    echo ""
    ls -lh build/app/outputs/bundle/release/app-release.aab
    echo ""
    echo -e "${GREEN}You can now upload this file to Google Play Store${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Go to https://play.google.com/console"
    echo "2. Select your app or create a new one"
    echo "3. Navigate to Release → Production (or Testing)"
    echo "4. Upload the app-release.aab file"
    echo "5. Fill in release details and submit"
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}✗ Build failed!${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    echo "Please check the error messages above."
    exit 1
fi
