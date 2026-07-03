#!/bin/bash

# Script to get SHA256 fingerprints for Android App Links
# Run this script from the root of your Flutter project

echo "=========================================="
echo "Android SHA256 Fingerprint Extractor"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running from project root
if [ ! -d "android" ]; then
    echo -e "${RED}Error: Please run this script from the root of your Flutter project${NC}"
    exit 1
fi

cd android

echo -e "${YELLOW}1. Getting DEBUG SHA256 fingerprint...${NC}"
echo ""
./gradlew signingReport | grep -A2 "Variant: debug" | grep "SHA-256"
echo ""

echo -e "${YELLOW}2. Getting RELEASE SHA256 fingerprint...${NC}"
echo ""

# Check if keystore exists
if [ -f "app/upload-keystore.jks" ]; then
    echo "Found upload-keystore.jks"
    echo "Please enter keystore password when prompted:"
    keytool -list -v -keystore app/upload-keystore.jks -alias upload | grep "SHA256:"
else
    echo -e "${RED}Error: upload-keystore.jks not found in android/app/${NC}"
    echo "Please make sure your release keystore is in the correct location"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Copy the SHA256 fingerprints above"
echo "Remove colons (:) and use UPPERCASE"
echo "Add to assetlinks.json file"
echo "==========================================${NC}"

cd ..
