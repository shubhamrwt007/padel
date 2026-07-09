# 🔗 Deep Linking Files - Overview

This directory contains all files related to deep linking implementation for the Swoot app.

## 📁 Files Overview

### 📱 App Configuration Files

| File | Purpose | Action Required |
|------|---------|-----------------|
| `lib/services/deep_link_service.dart` | Core deep linking service | ✅ Ready to use |
| `lib/main.dart` | Already updated with deep link initialization | ✅ Ready to use |
| `pubspec.yaml` | Updated with required packages | Run `flutter pub get` |

### 🍎 iOS Configuration

| File | Purpose | Action Required |
|------|---------|-----------------|
| `ios/Runner/Runner.entitlements` | Associated Domains | ✅ Ready - Verify in Xcode |
| `ios/Runner/Info.plist` | Custom URL schemes | ✅ Ready to use |
| `apple-app-site-association` | Universal Links config | ⚠️ Replace `TEAM_ID` |

### 🤖 Android Configuration

| File | Purpose | Action Required |
|------|---------|-----------------|
| `android/app/src/main/AndroidManifest.xml` | Intent filters | ✅ Ready to use |
| `assetlinks.json` | App Links config | ⚠️ Replace SHA256 fingerprints |

### 🌐 Server Files (Must Deploy)

| File | Deploy To | Purpose |
|------|-----------|---------|
| `apple-app-site-association` | `https://swootapp.com/.well-known/` | iOS Universal Links |
| `assetlinks.json` | `https://swootapp.com/.well-known/` | Android App Links |
| `web_fallback.html` | `https://swootapp.com/` | Fallback when app not installed |
| `nginx_config.conf` | Server config | Nginx configuration template |

### 🛠️ Utility Scripts

| File | Purpose | How to Use |
|------|---------|------------|
| `get_sha256.sh` | Extract Android SHA256 | `./get_sha256.sh` |
| `deploy_deeplinks.sh` | Automated deployment | `./deploy_deeplinks.sh` |

### 📖 Documentation

| File | Content |
|------|---------|
| `IMPLEMENTATION_SUMMARY.md` | ⭐ **START HERE** - What's done, what to do |
| `DEEP_LINKING_GUIDE.md` | Complete implementation guide |
| `DEEP_LINKING_QUICK_REF.md` | Quick commands and references |
| `DEPLOYMENT_CHECKLIST.md` | Step-by-step checklist |
| `README_DEEPLINKS.md` | This file |

---

## 🚀 Quick Start (5 Steps)

### 1️⃣ Get Your IDs

```bash
# Get Android SHA256 fingerprints
./get_sha256.sh

# Get Apple Team ID from:
# https://developer.apple.com/account → Membership
```

### 2️⃣ Update Configuration

```bash
# Edit these files:
# - apple-app-site-association → Replace TEAM_ID
# - assetlinks.json → Replace SHA256 fingerprints
# - web_fallback.html → Update App Store URL
```

### 3️⃣ Deploy to Server

```bash
# Option A: Use automated script
./deploy_deeplinks.sh

# Option B: Manual upload to swootapp.com
# - /.well-known/apple-app-site-association
# - /.well-known/assetlinks.json
# - /web_fallback.html
```

### 4️⃣ Install Dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

### 5️⃣ Test

```bash
# iOS
xcrun simctl openurl booted "https://swootapp.com/booking?courtId=123"

# Android
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://swootapp.com/booking?courtId=123" com.matchacha.app
```

---

## 📋 What Deep Links Are Supported?

All these work with `https://swootapp.com/[route]`:

- `/` - Home
- `/booking?courtId=XXX` - Book a court
- `/match?matchId=XXX` - Match details
- `/open-match?matchId=XXX` - Open match
- `/tournament?tournamentId=XXX` - Tournament
- `/league?leagueId=XXX` - League
- `/profile?userId=XXX` - User profile
- `/court?courtId=XXX` - Court details
- `/wallet` - Wallet
- `/notifications` - Notifications
- `/leaderboard` - Leaderboard

---

## 📚 Which Document Should I Read?

### 👉 Just Getting Started?
**Read:** `IMPLEMENTATION_SUMMARY.md`
- Shows what's already done
- Lists what you need to do
- Quick overview

### 🔧 Ready to Deploy?
**Read:** `DEPLOYMENT_CHECKLIST.md`
- Step-by-step checklist
- Nothing gets missed
- Track your progress

### 🆘 Need Detailed Help?
**Read:** `DEEP_LINKING_GUIDE.md`
- Complete implementation guide
- Troubleshooting section
- Configuration examples

### ⚡ Need Quick Commands?
**Read:** `DEEP_LINKING_QUICK_REF.md`
- All testing commands
- Common URLs
- Quick fixes

---

## ⚠️ Action Items

### Must Do Before Deployment

1. **Get Apple Team ID**
   - https://developer.apple.com/account
   - Update `apple-app-site-association`

2. **Get Android SHA256**
   - Run `./get_sha256.sh`
   - Update `assetlinks.json`

3. **Update App Store URL**
   - Update `web_fallback.html`

4. **Deploy Server Files**
   - Upload to swootapp.com
   - Verify HTTPS works

5. **Test Everything**
   - Both iOS and Android
   - All routes
   - Real devices

---

## 🔍 Verify Deployment

After deploying, run these tests:

```bash
# iOS Association File
curl -I https://swootapp.com/.well-known/apple-app-site-association
# Should return: Content-Type: application/json, Status: 200

# Android Asset Links
curl https://swootapp.com/.well-known/assetlinks.json
# Should return valid JSON with your SHA256s

# Fallback Page
curl https://swootapp.com/booking?courtId=123
# Should return HTML page
```

---

## 🎯 Common Use Cases

### Share a Booking
```dart
final deepLinkService = DeepLinkService.instance;
final link = deepLinkService.generateDeepLink(
  path: '/booking',
  queryParams: {'courtId': '123'},
);
// Returns: https://swootapp.com/booking?courtId=123
```

### Share a Match
```dart
final link = deepLinkService.generateDeepLink(
  path: '/match',
  queryParams: {'matchId': '456'},
);
// Share this link via WhatsApp, SMS, etc.
```

### Generate QR Code
```dart
// Generate link
final link = deepLinkService.generateDeepLink(
  path: '/court',
  queryParams: {'courtId': '789'},
);

// Use any QR code generator with this link
// Users scan QR → Opens app → Shows court details
```

---

## 🧪 Testing Checklist

- [ ] Test custom schemes: `padel://`, `swoot://`
- [ ] Test universal links: `https://swootapp.com/`
- [ ] Test on iOS simulator
- [ ] Test on Android emulator
- [ ] Test on real iOS device
- [ ] Test on real Android device
- [ ] Test when app is installed
- [ ] Test when app is NOT installed
- [ ] Test all routes
- [ ] Test with parameters
- [ ] Test sharing links
- [ ] Test QR codes

---

## 🐛 Troubleshooting

### Links Open in Browser
- ✅ Verify server files deployed
- ✅ Check HTTPS enabled
- ✅ Verify Team ID correct
- ✅ Check SHA256 fingerprints
- ✅ Reinstall app

### Can't Find Team ID
- Go to https://developer.apple.com/account
- Click "Membership"
- Look for "Team ID"

### SHA256 Script Doesn't Work
```bash
# Manual method for debug
cd android
./gradlew signingReport

# Manual method for release
keytool -list -v -keystore app/upload-keystore.jks -alias upload
```

### Associated Domains Not Showing in Xcode
1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Associated Domains"

---

## 💡 Tips

1. **Always use HTTPS** for universal/app links
2. **Test on real devices** before production
3. **Monitor analytics** to track deep link usage
4. **Keep documentation updated** when adding routes
5. **Version your association files** for rollback

---

## 📞 Need More Help?

1. Check `DEEP_LINKING_GUIDE.md` for detailed troubleshooting
2. Use `DEEP_LINKING_QUICK_REF.md` for quick commands
3. Follow `DEPLOYMENT_CHECKLIST.md` step by step
4. Review this file for overview

---

## 🎉 Ready to Deploy?

Follow this order:

1. ✅ Read `IMPLEMENTATION_SUMMARY.md`
2. ✅ Update configuration files (Team ID, SHA256, URLs)
3. ✅ Run `./deploy_deeplinks.sh`
4. ✅ Verify deployment with curl commands
5. ✅ Run `flutter pub get`
6. ✅ Test on simulators/emulators
7. ✅ Test on real devices
8. ✅ Follow `DEPLOYMENT_CHECKLIST.md`
9. ✅ Build release versions
10. ✅ Submit to stores 🚀

---

## 📊 File Structure

```
padel/
├── lib/
│   ├── services/
│   │   └── deep_link_service.dart          ✅ Core service
│   └── main.dart                            ✅ Updated
├── ios/
│   └── Runner/
│       ├── Runner.entitlements              ✅ Associated Domains
│       └── Info.plist                       ✅ URL schemes
├── android/
│   └── app/
│       └── src/main/
│           └── AndroidManifest.xml          ✅ Intent filters
├── apple-app-site-association               ⚠️ Update Team ID
├── assetlinks.json                          ⚠️ Update SHA256s
├── web_fallback.html                        ⚠️ Update URLs
├── nginx_config.conf                        📘 Template
├── get_sha256.sh                            🛠️ Utility
├── deploy_deeplinks.sh                      🛠️ Utility
├── IMPLEMENTATION_SUMMARY.md                📖 Start here
├── DEEP_LINKING_GUIDE.md                    📖 Complete guide
├── DEEP_LINKING_QUICK_REF.md                📖 Quick reference
├── DEPLOYMENT_CHECKLIST.md                  📖 Checklist
└── README_DEEPLINKS.md                      📖 This file
```

---

**Version:** 1.0.0  
**Last Updated:** [Current Date]  
**Status:** Ready for Configuration and Deployment 🚀
