#!/bin/bash

# Deep Linking Deployment Script for Swoot App
# This script helps deploy the necessary files for deep linking

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "=========================================="
echo "   Swoot Deep Linking Deployment"
echo "=========================================="
echo -e "${NC}"

# Variables - Update these for your setup
TEAM_ID=""
RELEASE_SHA256=""
DEBUG_SHA256=""
SERVER_USER=""
SERVER_HOST=""
SERVER_PATH="/var/www/swootapp.com"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to read user input
read_input() {
    local prompt="$1"
    local var_name="$2"
    local current_value="${!var_name}"
    
    if [ -n "$current_value" ]; then
        read -p "$prompt [$current_value]: " input
        if [ -z "$input" ]; then
            input="$current_value"
        fi
    else
        read -p "$prompt: " input
    fi
    
    eval "$var_name='$input'"
}

# Step 1: Gather required information
echo -e "${YELLOW}Step 1: Gather Information${NC}"
echo ""

if [ -z "$TEAM_ID" ]; then
    echo "Get your Apple Team ID from: https://developer.apple.com/account"
    read_input "Enter your Apple Team ID" TEAM_ID
fi

if [ -z "$RELEASE_SHA256" ]; then
    echo ""
    echo "Run './get_sha256.sh' to get your SHA256 fingerprints"
    read_input "Enter your RELEASE SHA256 fingerprint (no colons)" RELEASE_SHA256
fi

if [ -z "$DEBUG_SHA256" ]; then
    read_input "Enter your DEBUG SHA256 fingerprint (no colons)" DEBUG_SHA256
fi

echo ""
echo -e "${YELLOW}Step 2: Update Configuration Files${NC}"
echo ""

# Update apple-app-site-association
if [ -f "apple-app-site-association" ]; then
    echo "Updating apple-app-site-association with Team ID..."
    sed -i.bak "s/TEAM_ID/$TEAM_ID/g" apple-app-site-association
    echo -e "${GREEN}✓ Updated apple-app-site-association${NC}"
else
    echo -e "${RED}✗ apple-app-site-association not found${NC}"
fi

# Update assetlinks.json
if [ -f "assetlinks.json" ]; then
    echo "Updating assetlinks.json with SHA256 fingerprints..."
    sed -i.bak "s/YOUR_RELEASE_SHA256_FINGERPRINT/$RELEASE_SHA256/g" assetlinks.json
    sed -i.bak "s/YOUR_DEBUG_SHA256_FINGERPRINT/$DEBUG_SHA256/g" assetlinks.json
    echo -e "${GREEN}✓ Updated assetlinks.json${NC}"
else
    echo -e "${RED}✗ assetlinks.json not found${NC}"
fi

echo ""
echo -e "${YELLOW}Step 3: Deployment Options${NC}"
echo ""
echo "1. Manual deployment (copy files yourself)"
echo "2. Deploy via SCP (requires SSH access)"
echo "3. Generate deployment package"
echo "4. Skip deployment"
echo ""

read -p "Choose an option (1-4): " deploy_option

case $deploy_option in
    1)
        echo ""
        echo -e "${BLUE}Manual Deployment Instructions:${NC}"
        echo ""
        echo "1. Copy these files to your server at https://swootapp.com/.well-known/"
        echo "   - apple-app-site-association (no file extension)"
        echo "   - assetlinks.json"
        echo ""
        echo "2. Copy web_fallback.html to your server root"
        echo ""
        echo "3. Ensure files are accessible via HTTPS"
        echo "   Test: curl https://swootapp.com/.well-known/apple-app-site-association"
        echo ""
        echo "4. Set correct content-type for association file:"
        echo "   Content-Type: application/json"
        ;;
    
    2)
        echo ""
        read_input "Enter server username" SERVER_USER
        read_input "Enter server hostname/IP" SERVER_HOST
        read_input "Enter server path" SERVER_PATH
        
        echo ""
        echo "Deploying files via SCP..."
        
        # Create .well-known directory on server
        ssh "$SERVER_USER@$SERVER_HOST" "mkdir -p $SERVER_PATH/.well-known"
        
        # Copy files
        scp apple-app-site-association "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/.well-known/"
        scp assetlinks.json "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/.well-known/"
        scp web_fallback.html "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"
        
        # Set permissions
        ssh "$SERVER_USER@$SERVER_HOST" "chmod 644 $SERVER_PATH/.well-known/*"
        ssh "$SERVER_USER@$SERVER_HOST" "chmod 644 $SERVER_PATH/web_fallback.html"
        
        echo ""
        echo -e "${GREEN}✓ Files deployed successfully${NC}"
        echo ""
        echo "Verify deployment:"
        echo "curl -I https://swootapp.com/.well-known/apple-app-site-association"
        echo "curl https://swootapp.com/.well-known/assetlinks.json"
        ;;
    
    3)
        echo ""
        echo "Creating deployment package..."
        
        # Create deployment directory
        mkdir -p deploy/.well-known
        
        # Copy files
        cp apple-app-site-association deploy/.well-known/
        cp assetlinks.json deploy/.well-known/
        cp web_fallback.html deploy/
        cp nginx_config.conf deploy/
        
        # Create README
        cat > deploy/DEPLOY_README.txt << EOF
Deep Linking Deployment Package
================================

Files included:
1. .well-known/apple-app-site-association - iOS Universal Links
2. .well-known/assetlinks.json - Android App Links
3. web_fallback.html - Fallback page when app not installed
4. nginx_config.conf - Nginx configuration template

Deployment Instructions:
1. Upload .well-known directory to your web root
2. Upload web_fallback.html to your web root
3. Configure your web server (see nginx_config.conf for example)
4. Test the URLs:
   - https://swootapp.com/.well-known/apple-app-site-association
   - https://swootapp.com/.well-known/assetlinks.json

Requirements:
- HTTPS enabled
- No redirects for .well-known files
- Correct Content-Type: application/json

Support: Check DEEP_LINKING_GUIDE.md for detailed instructions
EOF
        
        # Create archive
        tar -czf swoot_deeplink_deploy_$(date +%Y%m%d_%H%M%S).tar.gz deploy/
        
        echo -e "${GREEN}✓ Deployment package created${NC}"
        echo ""
        echo "Package: swoot_deeplink_deploy_$(date +%Y%m%d_%H%M%S).tar.gz"
        echo "Extract and upload to your server"
        
        # Clean up
        rm -rf deploy/
        ;;
    
    4)
        echo "Skipping deployment"
        ;;
    
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac

echo ""
echo -e "${YELLOW}Step 4: Verification${NC}"
echo ""
echo "After deployment, verify with these commands:"
echo ""
echo -e "${BLUE}iOS Universal Links:${NC}"
echo "curl -I https://swootapp.com/.well-known/apple-app-site-association"
echo ""
echo -e "${BLUE}Android App Links:${NC}"
echo "curl https://swootapp.com/.well-known/assetlinks.json"
echo ""
echo -e "${BLUE}iOS Testing:${NC}"
echo "xcrun simctl openurl booted 'https://swootapp.com/booking?courtId=123'"
echo ""
echo -e "${BLUE}Android Testing:${NC}"
echo "adb shell am start -W -a android.intent.action.VIEW -d 'https://swootapp.com/booking?courtId=123' com.matchacha.app"
echo ""

echo -e "${YELLOW}Step 5: Update Xcode Project${NC}"
echo ""
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Select Runner target"
echo "3. Go to 'Signing & Capabilities'"
echo "4. Verify 'Associated Domains' includes:"
echo "   - applinks:swootapp.com"
echo "   - applinks:www.swootapp.com"
echo ""

echo -e "${GREEN}"
echo "=========================================="
echo "   Deployment Complete!"
echo "=========================================="
echo -e "${NC}"
echo ""
echo "Next steps:"
echo "1. Test deep links on real devices"
echo "2. Submit apps to stores"
echo "3. Monitor analytics"
echo ""
echo "Documentation: DEEP_LINKING_GUIDE.md"
echo "Quick Reference: DEEP_LINKING_QUICK_REF.md"
echo ""

# Clean up backup files
rm -f *.bak

exit 0
