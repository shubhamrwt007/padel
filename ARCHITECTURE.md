# 🏗️ Deep Linking Architecture

## 📊 Flow Diagram

```
User clicks link
      ↓
https://swootapp.com/booking?courtId=123
      ↓
      ├─── App Installed? ───┐
      │                      │
     YES                    NO
      │                      │
      ↓                      ↓
  Open App            Open Browser
      ↓                      ↓
  Deep Link         web_fallback.html
   Service                   ↓
      ↓              ┌───────┴────────┐
  Parse URL         │  Try to open    │
      ↓             │  app via        │
  Route to          │  custom scheme  │
  Screen            └───────┬─────────┘
      ↓                     │
  Show Booking    ┌─────────┴──────────┐
   Page          │                      │
               Success               Fail
                  │                    │
                  ↓                    ↓
              Open App          Show Download
              Navigate          Buttons
              to Screen         (App/Play Store)
```

---

## 🔄 Deep Link Processing Flow

### 1. Link is Opened
```
Input: https://swootapp.com/booking?courtId=123
```

### 2. Operating System Checks
```
iOS: Checks apple-app-site-association
     - Domain: swootapp.com
     - App ID: TEAM_ID.com.matchacha.app
     - Path matches: /booking ✓

Android: Checks assetlinks.json
         - Package: com.matchacha.app
         - SHA256 matches ✓
         - Path: /booking ✓
```

### 3. App Opens (if installed)
```
DeepLinkService receives:
  - Full URL: https://swootapp.com/booking?courtId=123
  - Path: /booking
  - Parameters: {courtId: "123"}
```

### 4. Service Routes to Screen
```dart
if (path.startsWith('/booking')) {
  final courtId = queryParams['courtId'];
  _navigateToBooking(courtId);
}
```

### 5. User Sees Screen
```
BookingScreen(courtId: "123")
```

---

## 🏛️ System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   User's Device                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────┐    │
│  │              Mobile Browser                 │    │
│  │  (Safari / Chrome / Messages / WhatsApp)   │    │
│  └──────────────────┬──────────────────────────┘   │
│                     │                               │
│                     │ User clicks link              │
│                     ↓                               │
│  ┌────────────────────────────────────────────┐    │
│  │           Operating System                  │    │
│  │  (iOS Universal Links / Android App Links) │    │
│  └──────────────────┬──────────────────────────┘   │
│                     │                               │
│         ┌───────────┴───────────┐                  │
│         │                       │                  │
│    App Found?              App Not Found?          │
│         │                       │                  │
│         ↓                       ↓                  │
│  ┌─────────────┐        ┌─────────────┐          │
│  │  Swoot App  │        │   Browser   │          │
│  │             │        │  (Fallback) │          │
│  └──────┬──────┘        └──────┬──────┘          │
│         │                      │                  │
│         │                      │                  │
└─────────┼──────────────────────┼──────────────────┘
          │                      │
          │                      │
          ↓                      ↓
   ┌──────────────┐      ┌─────────────┐
   │ Deep Link    │      │  Web Page   │
   │ Service      │      │  (Fallback) │
   │              │      │             │
   │ - Parse URL  │      │ - Download  │
   │ - Route      │      │   buttons   │
   │ - Navigate   │      │ - Auto-open │
   └──────────────┘      │   attempt   │
                         └─────────────┘
```

---

## 📱 Component Breakdown

### 1. Server Side (swootapp.com)

```
swootapp.com/
│
├── .well-known/
│   ├── apple-app-site-association (iOS)
│   │   - Tells iOS which app handles links
│   │   - No file extension
│   │   - Content-Type: application/json
│   │
│   └── assetlinks.json (Android)
│       - Tells Android which app handles links
│       - Must match SHA256 fingerprint
│
├── web_fallback.html (All routes)
│   - Shown when app not installed
│   - Attempts to open app
│   - Shows download buttons
│   - Responsive design
│
└── Other pages (optional)
```

### 2. App Side (Flutter)

```
Swoot App
│
├── main.dart
│   └── Initialize DeepLinkService
│
├── services/
│   └── deep_link_service.dart
│       ├── Listen for links (AppLinks)
│       ├── Parse URL
│       ├── Extract parameters
│       ├── Route to screen
│       └── Handle errors
│
├── iOS Configuration
│   ├── Runner.entitlements
│   │   └── Associated Domains
│   │       - applinks:swootapp.com
│   │
│   └── Info.plist
│       └── Custom URL Schemes
│           - padel://
│           - swoot://
│
└── Android Configuration
    └── AndroidManifest.xml
        └── Intent Filters
            - https://swootapp.com
            - padel://
```

---

## 🔐 Security Flow

### iOS Universal Links Verification

```
1. User clicks: https://swootapp.com/booking?courtId=123
                        ↓
2. iOS checks cache for swootapp.com association
                        ↓
3. If not cached, downloads from:
   https://swootapp.com/.well-known/apple-app-site-association
                        ↓
4. Verifies:
   - Valid JSON?
   - HTTPS?
   - No redirects?
   - Team ID matches installed app?
                        ↓
5. If all checks pass → Open app
   If any check fails → Open Safari
```

### Android App Links Verification

```
1. User clicks: https://swootapp.com/booking?courtId=123
                        ↓
2. Android checks if app handles swootapp.com
                        ↓
3. Verifies assetlinks.json:
   https://swootapp.com/.well-known/assetlinks.json
                        ↓
4. Checks:
   - Package name matches?
   - SHA256 fingerprint matches signing key?
   - Domain matches?
                        ↓
5. If verified → Open app
   If not verified → Show app chooser or browser
```

---

## 🎭 Scenarios

### Scenario 1: Happy Path (App Installed)
```
1. User receives: https://swootapp.com/match?matchId=456
2. Taps link
3. iOS/Android verifies association
4. Opens Swoot app
5. DeepLinkService parses link
6. Navigates to MatchDetailsScreen(matchId: 456)
7. User sees match details immediately
```

### Scenario 2: App Not Installed
```
1. User receives: https://swootapp.com/match?matchId=456
2. Taps link
3. iOS/Android checks for app → Not found
4. Opens browser at swootapp.com/match?matchId=456
5. Server returns web_fallback.html
6. Page attempts to open app via custom scheme
7. Fails (app not installed)
8. Shows App Store / Play Store buttons
9. User installs app
10. Re-clicks link → Opens app (Scenario 1)
```

### Scenario 3: App in Background
```
1. App is running in background
2. User clicks: https://swootapp.com/tournament?tournamentId=101
3. App comes to foreground
4. DeepLinkService receives link
5. Navigates to TournamentScreen
6. User sees tournament immediately
```

### Scenario 4: App Terminated
```
1. App is not running (killed)
2. User clicks: https://swootapp.com/wallet
3. OS launches app
4. App initializes
5. getInitialLink() retrieves the link
6. DeepLinkService processes link
7. After splash screen, navigates to WalletScreen
```

---

## 🔗 Link Types Comparison

| Type | Format | When Works | Fallback |
|------|--------|------------|----------|
| Universal Link (iOS) | https://swootapp.com/... | App installed | Safari |
| App Link (Android) | https://swootapp.com/... | App installed & verified | Browser/Chooser |
| Custom Scheme | padel://swootapp.com/... | App installed | Error/Nothing |
| Web Link | https://swootapp.com/... | Always | Browser |

---

## 🎯 Decision Tree

```
                     User Clicks Link
                           ↓
                   ┌───────────────┐
                   │ Link Format?  │
                   └───────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    https://          padel://          swoot://
         │                 │                 │
         ↓                 ↓                 ↓
   ┌──────────┐      ┌──────────┐     ┌──────────┐
   │Universal/│      │ Custom   │     │ Custom   │
   │App Links │      │ Scheme   │     │ Scheme   │
   └────┬─────┘      └────┬─────┘     └────┬─────┘
        │                 │                 │
        ↓                 ↓                 ↓
   ┌──────────┐      ┌──────────┐     ┌──────────┐
   │App       │      │App       │     │App       │
   │installed?│      │installed?│     │installed?│
   └────┬─────┘      └────┬─────┘     └────┬─────┘
        │                 │                 │
   ┌────┴────┐       ┌────┴────┐      ┌────┴────┐
   │         │       │         │      │         │
  YES       NO      YES       NO     YES       NO
   │         │       │         │      │         │
   ↓         ↓       ↓         ↓      ↓         ↓
 Open    Fallback  Open    Error   Open    Error
 App      Page     App             App
```

---

## 📊 Data Flow

### Incoming Link → App Screen

```
Link: https://swootapp.com/booking?courtId=123&date=2024-03-15

        ↓ [AppLinks receives]

URI Object:
{
  scheme: "https",
  host: "swootapp.com",
  path: "/booking",
  queryParameters: {
    "courtId": "123",
    "date": "2024-03-15"
  }
}

        ↓ [DeepLinkService._handleDeepLink]

Parsed:
- Route: "/booking"
- Params: {courtId: "123", date: "2024-03-15"}

        ↓ [Routing logic]

Navigation:
Get.toNamed('/book-court', arguments: {
  'courtId': '123',
  'date': '2024-03-15'
})

        ↓ [GetX navigation]

Screen Rendered:
BookingScreen(
  courtId: "123",
  date: "2024-03-15"
)
```

---

## 🛠️ Extension Points

### Add New Route

1. **Update deep_link_service.dart:**
```dart
else if (path.startsWith('/new-route')) {
  final id = queryParams['id'] ?? '';
  _navigateToNewRoute(id);
}
```

2. **Add navigation method:**
```dart
void _navigateToNewRoute(String id) {
  Get.toNamed('/new-route', arguments: {'id': id});
}
```

3. **Update server files:**
- Add `/new-route` to apple-app-site-association
- Redeploy to server

4. **Test:**
```bash
xcrun simctl openurl booted "https://swootapp.com/new-route?id=123"
```

---

## 🔍 Debugging Flow

```
Link Not Working?
      ↓
Check Server
- curl -I https://swootapp.com/.well-known/apple-app-site-association
- Is it returning 200 and application/json?
      ↓
     YES
      ↓
Check Configuration
- Team ID correct in apple-app-site-association?
- SHA256 correct in assetlinks.json?
      ↓
     YES
      ↓
Check App
- Associated Domains in Xcode?
- Intent filter in AndroidManifest?
      ↓
     YES
      ↓
Check Device
- Reinstall app
- Clear cache (iOS: delete app, Android: clear data)
- Test on real device, not just simulator
      ↓
    Still Not Working?
      ↓
Check Logs
- iOS: Console.app → Device → Filter: "swootapp"
- Android: adb logcat | grep -i "swootapp"
```

---

## 📈 Analytics Integration Points

Track these events:

1. **Deep Link Opened**
```dart
void _handleDeepLink(String link) {
  // Log event
  FirebaseAnalytics.instance.logEvent(
    name: 'deep_link_opened',
    parameters: {'link': link, 'route': path}
  );
  // Continue routing...
}
```

2. **Route Navigation**
```dart
void _navigateToBooking(String courtId) {
  FirebaseAnalytics.instance.logEvent(
    name: 'deep_link_navigate',
    parameters: {'route': 'booking', 'courtId': courtId}
  );
  Get.toNamed('/book-court', arguments: {'courtId': courtId});
}
```

3. **Link Generation**
```dart
String generateDeepLink(...) {
  final link = ...;
  FirebaseAnalytics.instance.logEvent(
    name: 'deep_link_generated',
    parameters: {'link': link}
  );
  return link;
}
```

---

## 🎓 Best Practices

1. **Always Use HTTPS** for universal/app links
2. **Keep Paths Simple** - `/booking` better than `/v1/api/booking`
3. **Use Query Parameters** for IDs and filters
4. **Handle Missing Parameters** gracefully
5. **Log All Deep Links** for analytics
6. **Test Both Platforms** thoroughly
7. **Update Documentation** when adding routes
8. **Version Association Files** for rollback capability
9. **Monitor Error Rates** for failed links
10. **Provide Fallback** for app not installed

---

**Last Updated:** [Current Date]  
**Version:** 1.0.0
