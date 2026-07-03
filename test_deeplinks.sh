#!/bin/bash

# Deep Link Testing Script for Swoot App
# Tests all deep link routes on both iOS and Android

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PACKAGE_NAME="com.matchacha.app"
DOMAIN="swootapp.com"

echo -e "${BLUE}"
echo "=========================================="
echo "   Deep Link Testing Suite"
echo "=========================================="
echo -e "${NC}"

# Check if device/simulator is available
check_device() {
    local platform=$1
    
    if [ "$platform" == "ios" ]; then
        if ! command -v xcrun &> /dev/null; then
            echo -e "${RED}Error: xcrun not found. Are you on macOS?${NC}"
            return 1
        fi
        
        # Check for running simulator
        if ! xcrun simctl list devices | grep -q "Booted"; then
            echo -e "${YELLOW}Warning: No iOS simulator running. Please start a simulator.${NC}"
            return 1
        fi
        echo -e "${GREEN}✓ iOS Simulator detected${NC}"
    elif [ "$platform" == "android" ]; then
        if ! command -v adb &> /dev/null; then
            echo -e "${RED}Error: adb not found. Is Android SDK installed?${NC}"
            return 1
        fi
        
        # Check for connected device
        if ! adb devices | grep -q "device$"; then
            echo -e "${YELLOW}Warning: No Android device/emulator connected.${NC}"
            return 1
        fi
        echo -e "${GREEN}✓ Android device detected${NC}"
    fi
    
    return 0
}

# Test a single deep link
test_link() {
    local platform=$1
    local url=$2
    local description=$3
    
    echo ""
    echo -e "${YELLOW}Testing: $description${NC}"
    echo "URL: $url"
    
    if [ "$platform" == "ios" ]; then
        xcrun simctl openurl booted "$url"
    elif [ "$platform" == "android" ]; then
        adb shell am start -W -a android.intent.action.VIEW -d "$url" "$PACKAGE_NAME"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Link opened successfully${NC}"
        sleep 2
    else
        echo -e "${RED}✗ Failed to open link${NC}"
    fi
}

# Main menu
echo ""
echo "Select testing platform:"
echo "1. iOS (Simulator)"
echo "2. Android (Emulator/Device)"
echo "3. Both"
echo "4. Test server configuration"
echo "5. Exit"
echo ""
read -p "Enter choice (1-5): " platform_choice

case $platform_choice in
    1)
        PLATFORM="ios"
        check_device "ios" || exit 1
        ;;
    2)
        PLATFORM="android"
        check_device "android" || exit 1
        ;;
    3)
        PLATFORM="both"
        check_device "ios" || IOS_AVAILABLE=false
        check_device "android" || ANDROID_AVAILABLE=false
        ;;
    4)
        echo ""
        echo -e "${BLUE}Testing Server Configuration${NC}"
        echo ""
        
        echo -e "${YELLOW}1. Testing iOS association file...${NC}"
        curl -I https://$DOMAIN/.well-known/apple-app-site-association
        echo ""
        
        echo -e "${YELLOW}2. Testing Android asset links...${NC}"
        curl https://$DOMAIN/.well-known/assetlinks.json
        echo ""
        
        echo -e "${YELLOW}3. Testing fallback page...${NC}"
        curl -I https://$DOMAIN/booking?courtId=123
        echo ""
        
        exit 0
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "Select test type:"
echo "1. Test Universal Links (https://)"
echo "2. Test Custom Schemes (padel://)"
echo "3. Test all routes"
echo "4. Custom URL"
echo ""
read -p "Enter choice (1-4): " test_choice

# Define test routes
declare -A ROUTES=(
    ["Home"]="/"
    ["Booking"]="/booking?courtId=123"
    ["Match"]="/match?matchId=456"
    ["Open Match"]="/open-match?matchId=789"
    ["Tournament"]="/tournament?tournamentId=101"
    ["League"]="/league?leagueId=202"
    ["Profile"]="/profile?userId=303"
    ["Court"]="/court?courtId=404"
    ["Wallet"]="/wallet"
    ["Notifications"]="/notifications"
    ["Leaderboard"]="/leaderboard"
)

run_tests() {
    local scheme=$1
    local platform=$2
    
    echo ""
    echo -e "${BLUE}=========================================="
    echo "Testing $scheme on $platform"
    echo "==========================================${NC}"
    
    for route_name in "${!ROUTES[@]}"; do
        local path="${ROUTES[$route_name]}"
        local url="$scheme$path"
        test_link "$platform" "$url" "$route_name"
        echo "---"
    done
}

case $test_choice in
    1)
        # Universal Links
        if [ "$PLATFORM" == "ios" ]; then
            run_tests "https://$DOMAIN" "ios"
        elif [ "$PLATFORM" == "android" ]; then
            run_tests "https://$DOMAIN" "android"
        elif [ "$PLATFORM" == "both" ]; then
            [ "$IOS_AVAILABLE" != false ] && run_tests "https://$DOMAIN" "ios"
            [ "$ANDROID_AVAILABLE" != false ] && run_tests "https://$DOMAIN" "android"
        fi
        ;;
    2)
        # Custom Schemes
        if [ "$PLATFORM" == "ios" ]; then
            run_tests "padel://$DOMAIN" "ios"
        elif [ "$PLATFORM" == "android" ]; then
            run_tests "padel://$DOMAIN" "android"
        elif [ "$PLATFORM" == "both" ]; then
            [ "$IOS_AVAILABLE" != false ] && run_tests "padel://$DOMAIN" "ios"
            [ "$ANDROID_AVAILABLE" != false ] && run_tests "padel://$DOMAIN" "android"
        fi
        ;;
    3)
        # All routes - both schemes
        if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "both" ]; then
            [ "$IOS_AVAILABLE" != false ] && {
                run_tests "https://$DOMAIN" "ios"
                run_tests "padel://$DOMAIN" "ios"
            }
        fi
        
        if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "both" ]; then
            [ "$ANDROID_AVAILABLE" != false ] && {
                run_tests "https://$DOMAIN" "android"
                run_tests "padel://$DOMAIN" "android"
            }
        fi
        ;;
    4)
        # Custom URL
        echo ""
        read -p "Enter full URL to test: " custom_url
        
        if [ "$PLATFORM" == "ios" ]; then
            test_link "ios" "$custom_url" "Custom URL"
        elif [ "$PLATFORM" == "android" ]; then
            test_link "android" "$custom_url" "Custom URL"
        elif [ "$PLATFORM" == "both" ]; then
            [ "$IOS_AVAILABLE" != false ] && test_link "ios" "$custom_url" "Custom URL (iOS)"
            [ "$ANDROID_AVAILABLE" != false ] && test_link "android" "$custom_url" "Custom URL (Android)"
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}"
echo "=========================================="
echo "   Testing Complete!"
echo "=========================================="
echo -e "${NC}"
echo ""
echo "Summary:"
echo "- Platform: $PLATFORM"
echo "- Test type: $test_choice"
echo ""
echo "If any tests failed, check:"
echo "1. App is installed on device/simulator"
echo "2. Association files are deployed correctly"
echo "3. Team ID and SHA256 fingerprints are correct"
echo "4. App has correct intent filters (Android)"
echo "5. App has associated domains (iOS)"
echo ""
echo "For detailed troubleshooting, see DEEP_LINKING_GUIDE.md"
echo ""

# Offer to check verification status
read -p "Check Android App Links verification status? (y/n): " check_status

if [ "$check_status" == "y" ] || [ "$check_status" == "Y" ]; then
    if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "both" ]; then
        echo ""
        echo -e "${BLUE}Android App Links Verification Status:${NC}"
        adb shell pm get-app-links "$PACKAGE_NAME"
        echo ""
        
        read -p "Reset verification? (y/n): " reset_verify
        if [ "$reset_verify" == "y" ] || [ "$reset_verify" == "Y" ]; then
            echo "Resetting verification..."
            adb shell pm set-app-links --package "$PACKAGE_NAME" 0 all
            adb shell pm verify-app-links --re-verify "$PACKAGE_NAME"
            echo -e "${GREEN}Verification reset. Please wait a few seconds and test again.${NC}"
        fi
    fi
fi

exit 0
