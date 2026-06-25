import 'package:flutter/material.dart';
import 'package:padel_mobile/presentations/americano/widgets/payment_popup_dialog.dart';

class NotificationHandler {
  static void handleNotificationTap(BuildContext context, Map<String, dynamic> notificationData) {
    final paymentLink = notificationData['paymentLink'] as String?;
    
    if (paymentLink != null && paymentLink.contains('pay-share-payment')) {
      PaymentPopupDialog.show(context, paymentLink);
    }
  }
}
