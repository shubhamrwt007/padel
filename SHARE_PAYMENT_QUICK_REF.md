# 📋 Share Payment Quick Reference Card

## 🎯 Copy & Paste Examples

### 1. Basic Share Button (Simplest)
```dart
import 'package:padel_mobile/utils/share_payment_helper.dart';

ElevatedButton.icon(
  icon: Icon(Icons.share),
  label: Text('Share Payment'),
  onPressed: () => SharePaymentHelper.sharePaymentLink(
    matchId: 'YOUR_MATCH_ID_HERE',
  ),
)
```

### 2. Share with Details
```dart
SharePaymentHelper.sharePaymentLink(
  matchId: '6a43c02aa809eb2272032e90',
  matchName: 'Evening Match',
  courtName: 'Court 1',
  amount: '₹500',
);
```

### 3. Show Share Options Dialog
```dart
SharePaymentHelper.showShareOptions(
  matchId: matchId,
  matchName: 'Padel Match',
  amount: '₹500',
);
```

### 4. Copy Link to Clipboard
```dart
SharePaymentHelper.copyLinkToClipboard(matchId);
```

### 5. Pre-built Card Widget
```dart
import 'package:padel_mobile/presentations/widgets/share_payment_widgets.dart';

SharePaymentCard(
  matchId: '6a43c02aa809eb2272032e90',
  matchName: 'Evening Match',
  courtName: 'Court 1',
  amount: '500',
  currency: 'INR',
)
```

### 6. App Bar Icon Button
```dart
import 'package:padel_mobile/presentations/widgets/share_payment_widgets.dart';

AppBar(
  title: Text('Match Details'),
  actions: [
    SharePaymentIconButton(
      matchId: matchId,
      matchName: 'Match Name',
    ),
  ],
)
```

## 🔗 Link Format

```
https://swootapp.com/share-payment?matchId=6a43c02aa809eb2272032e90
```

## 🛠️ API Endpoint

```
GET /api/customer/court/openmatch/pay-share-payment/{matchId}/resolve
```

## 📱 Test Commands

```bash
# iOS
xcrun simctl openurl booted "https://swootapp.com/share-payment?matchId=6a43c02aa809eb2272032e90"

# Android
adb shell am start -W -a android.intent.action.VIEW -d "https://swootapp.com/share-payment?matchId=6a43c02aa809eb2272032e90" com.matchacha.app
```

## 📂 Files to Import

```dart
import 'package:padel_mobile/utils/share_payment_helper.dart';
import 'package:padel_mobile/presentations/widgets/share_payment_widgets.dart';
import 'package:padel_mobile/presentations/share_payment/share_payment_screen.dart';
```

## 🎨 All Available Methods

```dart
// Share via system sheet
SharePaymentHelper.sharePaymentLink(matchId: id);

// Show options dialog
SharePaymentHelper.showShareOptions(matchId: id);

// Copy to clipboard
SharePaymentHelper.copyLinkToClipboard(matchId);

// Generate link only
String link = SharePaymentHelper.generateLink(matchId);

// Custom message
SharePaymentHelper.shareWithCustomMessage(
  matchId: id,
  message: 'Custom text here',
);

// WhatsApp direct
SharePaymentHelper.shareViaApp(
  matchId: id,
  app: 'whatsapp',
);

// SMS direct
SharePaymentHelper.shareViaApp(
  matchId: id,
  app: 'sms',
);

// Email
SharePaymentHelper.shareViaApp(
  matchId: id,
  app: 'email',
);

// QR code data
String qrData = SharePaymentHelper.generateQRData(matchId);
```

## 📋 Add Route

In your routes file:
```dart
GetPage(
  name: '/share-payment',
  page: () => const SharePaymentScreen(),
),
```

## ✅ Checklist

- [ ] Added route to routes file
- [ ] Added share button to match screen
- [ ] Tested deep link on iOS
- [ ] Tested deep link on Android
- [ ] Redeployed apple-app-site-association
- [ ] Tested on real device

## 📚 Full Documentation

- `SHARE_PAYMENT_SUMMARY.md` - Complete overview
- `SHARE_PAYMENT_GUIDE.md` - Detailed usage guide

---

**Keep this card handy for quick implementation!**
