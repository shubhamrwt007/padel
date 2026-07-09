# Deep Linking Deployment Checklist

## Pre-Deployment

### Get Required Information
- [ ] Get Apple Team ID from https://developer.apple.com/account
- [ ] Run `./get_sha256.sh` to get Android SHA256 fingerprints
- [ ] Get iOS App Store URL (or prepare to update later)
- [ ] Verify Play Store URL: `https://play.google.com/store/apps/details?id=com.matchacha.app`

### Update Configuration Files
- [ ] Update `apple-app-site-association` - Replace `TEAM_ID` with your Apple Team ID
- [ ] Update `assetlinks.json` - Replace both SHA256 fingerprint placeholders
- [ ] Update `web_fallback.html` - Replace `YOUR_APP_ID` in App Store URL
- [ ] Review supported routes in `deep_link_service.dart`

## Server Setup

### Deploy Association Files
- [ ] Create `.well-known` directory on server
- [ ] Upload `apple-app-site-association` to `https://swootapp.com/.well-known/`
- [ ] Upload `assetlinks.json` to `https://swootapp.com/.well-known/`
- [ ] Upload `web_fallback.html` to `https://swootapp.com/`
- [ ] Configure web server (nginx/apache) - see `nginx_config.conf`
- [ ] Verify HTTPS is enabled
- [ ] Ensure no redirects for `.well-known` files

### Verify Server Configuration
- [ ] Test: `curl -I https://swootapp.com/.well-known/apple-app-site-association`
- [ ] Verify Content-Type is `application/json`
- [ ] Verify HTTP status is 200
- [ ] Test: `curl https://swootapp.com/.well-known/assetlinks.json`
- [ ] Verify JSON is valid and SHA256s are correct
- [ ] Test: `curl https://swootapp.com/booking?courtId=123`
- [ ] Verify fallback page loads

## iOS Configuration

### Xcode Setup
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select Runner target
- [ ] Go to "Signing & Capabilities" tab
- [ ] Verify "Associated Domains" capability exists
- [ ] Verify domain includes: `applinks:swootapp.com`
- [ ] Verify domain includes: `applinks:www.swootapp.com`
- [ ] Check Team and Signing Certificate are correct

### iOS Testing
- [ ] Install dependencies: `cd ios && pod install && cd ..`
- [ ] Build for simulator: `flutter build ios --debug`
- [ ] Test custom scheme: `xcrun simctl openurl booted "padel://swootapp.com/booking?courtId=123"`
- [ ] Test universal link: `xcrun simctl openurl booted "https://swootapp.com/booking?courtId=123"`
- [ ] Verify app opens and routes to correct screen
- [ ] Test on real iOS device
- [ ] Test by sending link via Messages
- [ ] Test by clicking link in Safari
- [ ] Long-press link in Safari - should show "Open in Swoot"

## Android Configuration

### Android Studio Setup
- [ ] Verify `AndroidManifest.xml` has intent filters
- [ ] Verify `android:autoVerify="true"` is present
- [ ] Verify package name is `com.matchacha.app`
- [ ] Build project: `flutter build apk --debug`

### Android Testing
- [ ] Install app on emulator/device
- [ ] Test custom scheme: `adb shell am start -W -a android.intent.action.VIEW -d "padel://swootapp.com/booking?courtId=123" com.matchacha.app`
- [ ] Test app link: `adb shell am start -W -a android.intent.action.VIEW -d "https://swootapp.com/booking?courtId=123" com.matchacha.app`
- [ ] Verify app opens and routes to correct screen
- [ ] Check link verification: `adb shell pm get-app-links com.matchacha.app`
- [ ] Test on real Android device
- [ ] Test by sending link via WhatsApp
- [ ] Test by clicking link in Chrome browser

## App Testing

### Test All Routes
- [ ] Home: `https://swootapp.com/`
- [ ] Booking: `https://swootapp.com/booking?courtId=123`
- [ ] Match: `https://swootapp.com/match?matchId=456`
- [ ] Open Match: `https://swootapp.com/open-match?matchId=789`
- [ ] Tournament: `https://swootapp.com/tournament?tournamentId=101`
- [ ] League: `https://swootapp.com/league?leagueId=202`
- [ ] Profile: `https://swootapp.com/profile?userId=303`
- [ ] Court: `https://swootapp.com/court?courtId=404`
- [ ] Wallet: `https://swootapp.com/wallet`
- [ ] Notifications: `https://swootapp.com/notifications`
- [ ] Leaderboard: `https://swootapp.com/leaderboard`

### Test Scenarios
- [ ] App installed - link opens app
- [ ] App not installed - shows fallback page
- [ ] Invalid parameters - gracefully handled
- [ ] App in background - brings to foreground
- [ ] App terminated - launches app
- [ ] Share button functionality
- [ ] Generate deep link functionality
- [ ] QR code with deep link

## Production Release

### Build Release Versions
- [ ] Update version numbers in `pubspec.yaml`
- [ ] Build iOS release: `flutter build ios --release`
- [ ] Archive in Xcode for App Store
- [ ] Build Android release: `flutter build appbundle --release`
- [ ] Sign Android app bundle

### App Store Submission
- [ ] Submit iOS app to App Store
- [ ] Update iOS App Store URL in `web_fallback.html`
- [ ] Submit Android app to Play Store
- [ ] Verify Play Store URL matches `com.matchacha.app`

### Post-Launch
- [ ] Test deep links with published apps
- [ ] Monitor analytics for deep link usage
- [ ] Check error logs for any issues
- [ ] Update documentation if needed
- [ ] Share deep links on social media
- [ ] Send deep links in email campaigns

## Validation Tools

### iOS Validation
- [ ] Apple App Search Validation Tool: https://search.developer.apple.com/appsearch-validation-tool
- [ ] Enter domain: `swootapp.com`
- [ ] Enter bundle ID: `com.matchacha.app`

### Android Validation
- [ ] Google Digital Asset Links Tester: https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://swootapp.com
- [ ] Verify output includes your package name
- [ ] Check SHA256 matches

## Documentation

### Create
- [ ] Internal documentation for team
- [ ] Marketing materials with deep links
- [ ] User guide on sharing content
- [ ] Support documentation

### Review
- [ ] Read `DEEP_LINKING_GUIDE.md`
- [ ] Read `DEEP_LINKING_QUICK_REF.md`
- [ ] Read `IMPLEMENTATION_SUMMARY.md`
- [ ] Keep this checklist for future reference

## Optional Enhancements

- [ ] Add Firebase Analytics tracking for deep links
- [ ] Implement Firebase Dynamic Links
- [ ] Add Branch.io or Adjust.io for attribution
- [ ] Create QR codes for popular routes
- [ ] Add deep links to email templates
- [ ] Add deep links to push notifications
- [ ] Create promotional campaigns with deep links
- [ ] A/B test different link formats

---

## Notes

Add any notes or issues encountered during deployment:

```
[Add your notes here]
```

---

## Sign-Off

- [ ] All tests passed
- [ ] Documentation reviewed
- [ ] Team trained on deep linking
- [ ] Ready for production

**Completed By:** _______________  
**Date:** _______________  
**Sign:** _______________

---

**Version:** 1.0.0  
**Last Updated:** [Current Date]
