# Share Payment Link Implementation Guide

## 🎯 Overview

This implementation allows users to share payment links for open matches. When someone clicks the link, they are directed to the app (if installed) or a fallback web page, where they can complete the payment.

## 🔗 API Endpoint

```
GET https://padelstagingmobileapi.swootapp.com/api/customer/court/openmatch/pay-share-payment/{matchId}/resolve
```

**Example:**
```
https://padelstagingmobileapi.swootapp.com/api/customer/court/openmatch/pay-share-payment/6a43c02aa809eb2272032e90/resolve
```

## 📱 Deep Link Format

Generated deep links follow this pattern:
```
https://swootapp.com/share-payment?matchId={matchId}
```

**Example:**
```
https://swootapp.com/share-payment?matchId=6a43c02aa809eb2272032e90
```

## 🚀 Usage Examples

### 1. Basic Share in Your Existing Screen

Add a share button anywhere in your app:

```dart
import 'package:padel_mobile/utils/share_payment_helper.dart';

// In your widget
ElevatedButton.icon(
  icon: Icon(Icons.share),
  label: Text('Share Payment'),
  onPressed: () {
    SharePaymentHelper.sharePaymentLink(
      matchId: '6a43c02aa809eb2272032e90',
      matchName: 'Padel Match - Court 1',
      courtName: 'Jubilee Hills Court',
      amount: '₹500',
    );
  },
)
```

### 2. Show Share Options Dialog

Display multiple sharing options:

```dart
IconButton(
  icon: Icon(Icons.more_vert),
  onPressed: () {
    SharePaymentHelper.showShareOptions(
      matchId: matchId,
      matchName: 'Evening Match',
      amount: '₹500',
    );
  },
)
```

### 3. Copy Link to Clipboard

```dart
TextButton(
  onPressed: () {
    SharePaymentHelper.copyLinkToClipboard(matchId);
  },
  child: Text('Copy Link'),
)
```

### 4. Share via Specific App

```dart
// WhatsApp
SharePaymentHelper.shareViaApp(
  matchId: matchId,
  app: 'whatsapp',
  message: 'Hey! Please complete the payment for our match.',
);

// SMS
SharePaymentHelper.shareViaApp(
  matchId: matchId,
  app: 'sms',
  recipient: '+919876543210',
);

// Email
SharePaymentHelper.shareViaApp(
  matchId: matchId,
  app: 'email',
  recipient: 'player@example.com',
);
```

### 5. Generate Link Only

```dart
String link = SharePaymentHelper.generateLink(matchId);
print(link); // https://swootapp.com/share-payment?matchId=123
```

### 6. Generate QR Code

```dart
import 'package:qr_flutter/qr_flutter.dart';

QrImageView(
  data: SharePaymentHelper.generateQRData(matchId),
  version: QrVersions.auto,
  size: 200.0,
)
```

## 📋 Adding to Routes

Add the share payment route to your routes configuration:

```dart
// In lib/configs/routes/routes.dart

static final route = [
  // ... your existing routes ...
  
  GetPage(
    name: '/share-payment',
    page: () => const SharePaymentScreen(),
  ),
  
  // If you need a separate resolve screen
  GetPage(
    name: '/share-payment-resolve',
    page: () => const SharePaymentScreen(),
  ),
];
```

## 🎨 Example: Open Match Screen Integration

```dart
import 'package:flutter/material.dart';
import 'package:padel_mobile/utils/share_payment_helper.dart';

class OpenMatchDetailsScreen extends StatelessWidget {
  final String matchId;
  final Map<String, dynamic> matchData;

  const OpenMatchDetailsScreen({
    required this.matchId,
    required this.matchData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
        actions: [
          // Share button in app bar
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _handleShare(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... your match details widgets ...
            
            // Share payment section
            Card(
              child: ListTile(
                leading: Icon(Icons.payment),
                title: Text('Share Payment Request'),
                subtitle: Text('Let others pay their share'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => _handleShare(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare() {
    SharePaymentHelper.showShareOptions(
      matchId: matchId,
      matchName: matchData['matchName'] ?? 'Open Match',
      amount: matchData['paymentAmount']?.toString(),
    );
  }
}
```

## 🔔 Example: Share from Notification

```dart
// When creating a notification with share button
await NotificationService().showNotification(
  id: 123,
  title: 'Payment Reminder',
  body: 'Share payment link with other players',
  payload: 'share_payment|$matchId',
);

// Handle notification tap
void handleNotificationTap(String? payload) {
  if (payload != null && payload.startsWith('share_payment|')) {
    final matchId = payload.split('|')[1];
    SharePaymentHelper.sharePaymentLink(matchId: matchId);
  }
}
```

## 🎯 Complete Flow Example

### Scenario: User wants to share match payment

1. **User clicks "Share" button** in match details
2. **App shows share options** (WhatsApp, SMS, Copy, etc.)
3. **User selects WhatsApp**
4. **Message is pre-filled** with payment link
5. **User sends to friend**
6. **Friend clicks link**:
   - **If app installed**: Opens app → Shows payment screen
   - **If app NOT installed**: Opens browser → Shows fallback page with download buttons

### Code Implementation

```dart
// In your match details screen
class MatchDetailsController extends GetxController {
  String matchId = '';
  
  // Share payment button action
  void sharePayment() {
    SharePaymentHelper.sharePaymentLink(
      matchId: matchId,
      matchName: 'Saturday Evening Match',
      courtName: 'Court 1',
      amount: '₹500',
    );
  }
}

// In your UI
ElevatedButton.icon(
  icon: Icon(Icons.share),
  label: Text('Share Payment Link'),
  onPressed: () => controller.sharePayment(),
)
```

## 📊 API Response Handling

The API response is automatically handled in `SharePaymentRepository`:

```dart
// Typical API response structure (adjust based on your actual API)
{
  "success": true,
  "data": {
    "matchId": "6a43c02aa809eb2272032e90",
    "matchName": "Evening Match",
    "courtName": "Court 1",
    "matchDate": "2024-03-15",
    "matchTime": "18:00",
    "paymentAmount": 500,
    "currency": "INR",
    "paymentStatus": "pending"
  }
}
```

## ⚙️ Configuration

### 1. Update Server Association Files

Add the `/share-payment` route to both:

**apple-app-site-association:**
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.matchacha.app",
      "paths": [
        "*",
        "/share-payment",
        "/share-payment/resolve"
      ]
    }]
  }
}
```

**Redeploy to**: `https://swootapp.com/.well-known/apple-app-site-association`

### 2. Test Deep Links

```bash
# iOS
xcrun simctl openurl booted "https://swootapp.com/share-payment?matchId=6a43c02aa809eb2272032e90"

# Android
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://swootapp.com/share-payment?matchId=6a43c02aa809eb2272032e90" \
  com.matchacha.app
```

## 🎨 Customizing the Share Message

### Option 1: Simple Message
```dart
SharePaymentHelper.sharePaymentLink(
  matchId: matchId,
  matchName: 'Match Name',
  amount: '₹500',
);
```

### Option 2: Custom Message
```dart
SharePaymentHelper.shareWithCustomMessage(
  matchId: matchId,
  message: '''
🎾 Padel Match Payment

Hey! I've booked a court for our padel match.
Your share: ₹500

Click below to complete payment:
  ''',
);
```

## 🔒 Security Considerations

1. **Validate Match ID** on the server before showing payment details
2. **Check user permissions** - ensure they are authorized to pay
3. **Implement expiry** for payment links if needed
4. **Log all access** to shared payment links for audit

## 📱 Testing Checklist

- [ ] Share link generates correctly
- [ ] Link opens app when installed
- [ ] Link shows fallback page when app not installed
- [ ] Payment screen loads with correct match details
- [ ] Error handling works (invalid match ID, network errors)
- [ ] Share via WhatsApp works
- [ ] Share via SMS works
- [ ] Copy to clipboard works
- [ ] QR code generation works (if implemented)
- [ ] Works on both iOS and Android

## 🐛 Troubleshooting

### Link doesn't open app
- Verify association files are deployed
- Check Team ID and SHA256 fingerprints
- Reinstall the app

### Payment data not loading
- Check API endpoint is correct
- Verify matchId is being passed correctly
- Check network connectivity
- Review API response in logs

### Share button not working
- Ensure share_plus package is added to pubspec.yaml
- Check permissions for sharing on iOS/Android

## 📚 Related Files

- `lib/repositories/share_payment_repository.dart` - API calls
- `lib/services/deep_link_service.dart` - Deep link handling
- `lib/presentations/share_payment/share_payment_screen.dart` - UI screen
- `lib/utils/share_payment_helper.dart` - Helper methods

---

**Version:** 1.0.0  
**Last Updated:** Current Date
