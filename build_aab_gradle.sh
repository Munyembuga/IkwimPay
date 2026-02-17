#!/bin/bash

# Build AAB using Gradle (without Flutter CLI)
# This script builds the Android App Bundle using only Gradle

set -e  # Exit on error

echo "========================================="
echo "Building AAB using Gradle"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo -e "${RED}Error: Java is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Java found: $(java -version 2>&1 | head -1)${NC}"
echo ""

# Check if keystore exists
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}Error: android/key.properties not found${NC}"
    exit 1
fi

if [ ! -f "android/ikwimpay-release.keystore" ]; then
    echo -e "${RED}Error: android/ikwimpay-release.keystore not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Keystore configuration found${NC}"
echo ""

# Navigate to android directory
cd android

# Clean previous builds
echo "Cleaning previous builds..."
./gradlew clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Build the AAB
echo "Building Android App Bundle (AAB)..."
echo "This may take a few minutes..."
echo ""

./gradlew bundleRelease

echo ""
if [ -f "app/build/outputs/bundle/release/app-release.aab" ]; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "AAB file location:"
    echo "  android/app/build/outputs/bundle/release/app-release.aab"
    echo ""
    ls -lh app/build/outputs/bundle/release/app-release.aab
    echo ""
    echo -e "${GREEN}You can now upload this file to Google Play Store${NC}"
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}✗ Build failed!${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi
