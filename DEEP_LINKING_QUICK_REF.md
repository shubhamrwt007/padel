# Deep Linking Quick Reference

## 🚀 Quick Start Commands

### Get Android SHA256 Fingerprints
```bash
./get_sha256.sh
```

### Install Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

### Run App
```bash
flutter run
```

---

## 🔗 Deep Link Format

### Universal Links (Production)
```
https://swootapp.com/[route]?[params]
```

### Custom Scheme (Development/Testing)
```
padel://swootapp.com/[route]?[params]
swoot://[route]?[params]
```

---

## 📍 Available Routes

| Route | Parameters | Example |
|-------|------------|---------|
| `/` | None | `https://swootapp.com/` |
| `/booking` | `courtId` | `https://swootapp.com/booking?courtId=123` |
| `/match` | `matchId` | `https://swootapp.com/match?matchId=456` |
| `/open-match` | `matchId` | `https://swootapp.com/open-match?matchId=789` |
| `/tournament` | `tournamentId` | `https://swootapp.com/tournament?tournamentId=101` |
| `/league` | `leagueId` | `https://swootapp.com/league?leagueId=202` |
| `/profile` | `userId` | `https://swootapp.com/profile?userId=303` |
| `/court` | `courtId` | `https://swootapp.com/court?courtId=404` |
| `/wallet` | None | `https://swootapp.com/wallet` |
| `/notifications` | None | `https://swootapp.com/notifications` |
| `/leaderboard` | None | `https://swootapp.com/leaderboard` |

---

## 🧪 Testing Commands

### iOS Simulator
```bash
# Universal Link
xcrun simctl openurl booted "https://swootapp.com/booking?courtId=123"

# Custom Scheme
xcrun simctl openurl booted "padel://swootapp.com/booking?courtId=123"
```

### Android Emulator
```bash
# App Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://swootapp.com/match?matchId=456" com.matchacha.app

# Custom Scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "padel://swootapp.com/match?matchId=456" com.matchacha.app
```

---

## ✅ Verification URLs

### iOS Association File
```
https://swootapp.com/.well-known/apple-app-site-association
```

### Android Asset Links
```
https://swootapp.com/.well-known/assetlinks.json
```

### Test with curl
```bash
# iOS
curl -I https://swootapp.com/.well-known/apple-app-site-association

# Android
curl https://swootapp.com/.well-known/assetlinks.json
```

---

## 🔧 Common Issues & Fixes

### "Link opens in browser instead of app"
```bash
# iOS: Delete app and reinstall
# Android: Clear app data or reinstall
adb shell pm clear com.matchacha.app
```

### "Universal Links not working on iOS"
```bash
# Verify association file
curl -v https://swootapp.com/.well-known/apple-app-site-association

# Check Team ID in Xcode
open ios/Runner.xcworkspace
# Go to Signing & Capabilities → Associated Domains
```

### "App Links not verified on Android"
```bash
# Check verification status
adb shell pm get-app-links com.matchacha.app

# Reset verification
adb shell pm set-app-links --package com.matchacha.app 0 all
adb shell pm verify-app-links --re-verify com.matchacha.app
```

---

## 📝 Pre-Deployment Checklist

- [ ] Update Team ID in `apple-app-site-association`
- [ ] Run `./get_sha256.sh` and update `assetlinks.json`
- [ ] Update App Store URL in `web_fallback.html`
- [ ] Deploy association files to server
- [ ] Deploy fallback HTML to server
- [ ] Test deep links on real devices
- [ ] Verify HTTPS and no redirects
- [ ] Test both iOS and Android

---

## 🌐 Server Files to Deploy

1. **`/.well-known/apple-app-site-association`** (no extension)
   - Content-Type: `application/json`
   - Must be HTTPS
   - No redirects

2. **`/.well-known/assetlinks.json`**
   - Content-Type: `application/json`
   - Must be HTTPS

3. **`/web_fallback.html`** (or index.html)
   - Shown when app not installed
   - Contains store links and app open logic

---

## 🔐 Get Your IDs

### Apple Team ID
1. Go to https://developer.apple.com/account
2. Click on "Membership" in sidebar
3. Copy your Team ID (e.g., `ABC123XYZ`)

### Android Package Name
```
com.matchacha.app
```

### Bundle ID (iOS)
```
com.matchacha.app
```

---

## 📊 Generate Deep Links in Code

```dart
import 'package:padel_mobile/services/deep_link_service.dart';

final deepLinkService = DeepLinkService.instance;

// Generate a deep link
final link = deepLinkService.generateDeepLink(
  path: '/booking',
  queryParams: {'courtId': '123'},
);
print(link); // https://swootapp.com/booking?courtId=123

// Share a deep link
await deepLinkService.shareDeepLink(
  path: '/match',
  queryParams: {'matchId': '456'},
);
```

---

## 🎯 QR Code Generation

Generate QR codes for your deep links using any QR code generator:
- https://www.qr-code-generator.com/
- Or use a package like `qr_flutter`

Example QR code content:
```
https://swootapp.com/booking?courtId=123
```

---

## 📱 Social Media Sharing

Deep links work great on:
- WhatsApp
- Facebook Messenger
- Instagram DMs
- Twitter/X
- LinkedIn
- Email
- SMS

Example share text:
```
Check out this awesome court! 🎾
https://swootapp.com/court?courtId=123
```

---

## 🆘 Need Help?

1. Check `DEEP_LINKING_GUIDE.md` for detailed documentation
2. Verify all files are deployed correctly
3. Test with provided commands above
4. Check device logs for errors

---

## 🔄 Update Routes

To add a new deep link route:

1. Add route to `deep_link_service.dart`:
```dart
else if (path.startsWith('/new-route')) {
  final id = queryParams['id'] ?? '';
  _navigateToNewRoute(id);
}
```

2. Add navigation method:
```dart
void _navigateToNewRoute(String id) {
  Get.toNamed('/new-route', arguments: {'id': id});
}
```

3. Update association files:
   - `apple-app-site-association`: Add `/new-route` to paths
   - Redeploy to server

4. Update this reference and documentation

---

Last Updated: $(date)
Version: 1.0.0
