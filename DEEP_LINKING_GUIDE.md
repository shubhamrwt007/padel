# Deep Linking Implementation Guide for Swoot App

This guide explains how to set up and deploy deep linking for the Swoot mobile app with support for both iOS Universal Links and Android App Links.

## 🎯 What's Been Implemented

### 1. **Custom URL Schemes**
- `padel://` - Custom scheme for deep links
- `swoot://` - Alternative custom scheme
- Example: `padel://swootapp.com/booking?courtId=123`

### 2. **Universal Links (iOS) & App Links (Android)**
- Domain: `https://swootapp.com`
- Subdomain: `https://www.swootapp.com`
- Example: `https://swootapp.com/match?matchId=456`

### 3. **Supported Deep Link Routes**
- `/` - Home page
- `/booking?courtId=XXX` - Booking page
- `/match?matchId=XXX` or `/open-match?matchId=XXX` - Match details
- `/tournament?tournamentId=XXX` - Tournament details
- `/league?leagueId=XXX` - League details
- `/profile?userId=XXX` - User profile
- `/court?courtId=XXX` - Court details
- `/wallet` - Wallet page
- `/notifications` - Notifications page
- `/leaderboard` - Leaderboard page

---

## 📱 Server Setup for Universal/App Links

### Step 1: Host the Association Files

You need to host two files on your domain `swootapp.com`:

#### A. For iOS (Universal Links)
Host this file at:
```
https://swootapp.com/.well-known/apple-app-site-association
```

**Important:** 
- NO file extension
- Content-Type: `application/json`
- Must be served over HTTPS
- Must be accessible without redirects

File location in this project: `apple-app-site-association`

**Before deploying, update `TEAM_ID`** with your Apple Team ID:
1. Go to https://developer.apple.com/account
2. Find your Team ID in the Membership section
3. Replace `TEAM_ID` in the file with your actual Team ID

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.matchacha.app",
        "paths": ["*", "/booking", "/match", ...]
      }
    ]
  }
}
```

#### B. For Android (App Links)
Host this file at:
```
https://swootapp.com/.well-known/assetlinks.json
```

File location in this project: `assetlinks.json`

**Before deploying, update SHA256 fingerprints:**

1. **Get your Debug SHA256 fingerprint:**
```bash
cd android
./gradlew signingReport
```

2. **Get your Release SHA256 fingerprint:**
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

3. Replace placeholders in `assetlinks.json`:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.matchacha.app",
      "sha256_cert_fingerprints": [
        "YOUR_RELEASE_SHA256_FINGERPRINT",
        "YOUR_DEBUG_SHA256_FINGERPRINT"
      ]
    }
  }
]
```

### Step 2: Deploy Files to Server

Using nginx, add to your server configuration:

```nginx
server {
    listen 443 ssl;
    server_name swootapp.com www.swootapp.com;

    # SSL configuration
    ssl_certificate /path/to/ssl/certificate.crt;
    ssl_certificate_key /path/to/ssl/private.key;

    # Apple app site association
    location /.well-known/apple-app-site-association {
        default_type application/json;
        add_header Content-Type application/json;
        return 200 '{
            "applinks": {
                "apps": [],
                "details": [{
                    "appID": "TEAM_ID.com.matchacha.app",
                    "paths": ["*", "/booking", "/match", "/tournament", "/league", "/profile", "/court", "/wallet", "/notifications", "/leaderboard"]
                }]
            }
        }';
    }

    # Android asset links
    location /.well-known/assetlinks.json {
        default_type application/json;
        add_header Content-Type application/json;
        return 200 '[{
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": "com.matchacha.app",
                "sha256_cert_fingerprints": ["YOUR_SHA256_HERE"]
            }
        }]';
    }

    # Fallback for when app is not installed
    location / {
        root /var/www/swootapp;
        try_files $uri /web_fallback.html;
    }
}
```

### Step 3: Deploy Fallback Web Page

Upload `web_fallback.html` to your web server at the root directory.

**Before deploying, update these URLs in the HTML:**
1. iOS App Store URL: `https://apps.apple.com/app/YOUR_APP_ID`
2. Android Play Store URL: Already set to `https://play.google.com/store/apps/details?id=com.matchacha.app`

---

## ✅ Verification Steps

### iOS Universal Links Verification

1. **Verify the association file:**
```bash
curl -I https://swootapp.com/.well-known/apple-app-site-association
```

Should return:
```
HTTP/2 200
content-type: application/json
```

2. **Test with Apple's validator:**
Visit: https://search.developer.apple.com/appsearch-validation-tool

Enter your domain and bundle ID.

3. **On Device Testing:**
- Uninstall the app
- Open Safari on iOS
- Type: `https://swootapp.com/booking?courtId=123`
- Long-press the link → should show "Open in Swoot"

### Android App Links Verification

1. **Verify the assetlinks file:**
```bash
curl https://swootapp.com/.well-known/assetlinks.json
```

2. **Test with Google's tool:**
```bash
adb shell pm get-app-links com.matchacha.app
```

3. **On Device Testing:**
```bash
# Test link handling
adb shell am start -W -a android.intent.action.VIEW -d "https://swootapp.com/booking?courtId=123" com.matchacha.app
```

---

## 🔧 iOS Xcode Configuration

### Step 1: Add Associated Domains Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Associated Domains"
6. Add these domains:
   - `applinks:swootapp.com`
   - `applinks:www.swootapp.com`

**Note:** This is already configured in `Runner.entitlements`, but verify in Xcode.

### Step 2: Verify Info.plist

The `Info.plist` should already contain:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>padel</string>
            <string>swoot</string>
        </array>
    </dict>
</array>
```

---

## 🤖 Android Studio Configuration

### Verify AndroidManifest.xml

The manifest should contain (already configured):

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" />
    <data android:host="swootapp.com" />
</intent-filter>
```

---

## 🧪 Testing Deep Links

### Test Custom Schemes (Development)

**iOS Simulator:**
```bash
xcrun simctl openurl booted "padel://swootapp.com/booking?courtId=123"
```

**Android Emulator:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "padel://swootapp.com/booking?courtId=123" com.matchacha.app
```

### Test Universal/App Links (Production)

**iOS:**
```bash
xcrun simctl openurl booted "https://swootapp.com/match?matchId=456"
```

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://swootapp.com/match?matchId=456" com.matchacha.app
```

### Test in Real Devices

1. **Send link via messaging app** (WhatsApp, SMS, etc.)
2. **Send link via email**
3. **Post link on social media**
4. **Scan QR code** with link
5. **Click link in mobile browser**

---

## 📦 Building & Deploying

### Before Building

1. ✅ Update Team ID in `apple-app-site-association`
2. ✅ Update SHA256 fingerprints in `assetlinks.json`
3. ✅ Update App Store URLs in `web_fallback.html`
4. ✅ Deploy association files to `swootapp.com/.well-known/`
5. ✅ Deploy fallback HTML to server

### Install Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

### Build iOS
```bash
flutter build ios --release
```

### Build Android
```bash
flutter build appbundle --release
```

---

## 🔍 Troubleshooting

### iOS Universal Links Not Working

1. **Check HTTPS:** Association file must be served over HTTPS
2. **Check redirects:** No redirects allowed when accessing association file
3. **Check format:** File must be valid JSON, no file extension
4. **Clear cache:** Delete app, restart device
5. **Check Team ID:** Verify Team ID matches your Apple Developer account
6. **Check paths:** Ensure paths in association file match your routes

```bash
# Test association file
curl -v https://swootapp.com/.well-known/apple-app-site-association
```

### Android App Links Not Working

1. **Check SHA256:** Fingerprint must match your signing key
2. **Check autoVerify:** Intent filter must have `android:autoVerify="true"`
3. **Check package name:** Must match exactly
4. **Verify domain:** Run `adb shell pm get-app-links com.matchacha.app`
5. **Reset verification:**
```bash
adb shell pm set-app-links-user-selection --user 0 --package com.matchacha.app true com.matchacha.app
```

### Custom Schemes Not Working

1. **Check scheme registration** in Info.plist (iOS) or AndroidManifest.xml (Android)
2. **Check case sensitivity** - schemes are case-sensitive
3. **Reinstall app** after making changes

---

## 📊 Analytics & Tracking

Add tracking to the `DeepLinkService` to monitor:
- Which deep links are used most
- Conversion rates from deep links
- User journey after deep link

Example:
```dart
void _handleDeepLink(String link) {
  // Log to analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'deep_link_opened',
    parameters: {'link': link},
  );
  
  // Continue with routing...
}
```

---

## 🎁 Additional Features

### Generate Dynamic Links

Use the `generateDeepLink` method:

```dart
final deepLinkService = DeepLinkService.instance;
final link = deepLinkService.generateDeepLink(
  path: '/booking',
  queryParams: {'courtId': '123'},
);
// Returns: https://swootapp.com/booking?courtId=123
```

### Share Deep Links

```dart
await deepLinkService.shareDeepLink(
  path: '/match',
  queryParams: {'matchId': '456'},
);
```

---

## 📝 Maintenance Checklist

- [ ] Monitor deep link analytics
- [ ] Test deep links after each release
- [ ] Update association files when adding new routes
- [ ] Keep SHA256 fingerprints updated
- [ ] Test on both iOS and Android
- [ ] Verify fallback page works correctly
- [ ] Check SSL certificate validity

---

## 🆘 Support

For issues or questions:
1. Check troubleshooting section above
2. Verify all configuration files
3. Test with provided verification commands
4. Check device/system logs

---

## 📚 References

- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [Android App Links](https://developer.android.com/training/app-links)
- [Flutter App Links Package](https://pub.dev/packages/app_links)
- [Uni Links Package](https://pub.dev/packages/uni_links)
