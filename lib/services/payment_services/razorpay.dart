// pubspec.yaml dependencies needed:
// razorpay_flutter: ^1.3.6

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentService {
  late Razorpay _razorpay;

  // Callbacks for payment events
  Function(PaymentSuccessResponse)? onPaymentSuccess;
  Function(PaymentFailureResponse)? onPaymentFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayPaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Initialize payment
  Future<void> initiatePayment({
    required String keyId,
    required double amount,
    required String currency,
    required String name,
    required String description,
    required String image,
    String? orderId,
    String? userEmail,
    String? userContact,
    Map<String, dynamic>? notes,
    String? theme,
    bool enableGooglePay = true,
    List<String>? paymentMethods,
  }) async {
    var options = {
      'key': keyId,
      'amount': (amount * 100).toInt(),
      'currency': currency,
      'name': name,
      'description': description,
      'image':image,
      'prefill': {'contact': userContact ?? '', 'email': userEmail ?? ''},
      'external': {
        'wallets': ['paytm'],
      },
      'notes': notes ?? {},
      'theme': {'color': theme ?? '#3399cc'},
      'method': {
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': true,
        'emi': true,
        'paylater': true
      }
    };

    // Add specific payment method restrictions if provided
    if (paymentMethods != null && paymentMethods.isNotEmpty) {
      options['method'] = <String, bool>{};
      for (String method in paymentMethods) {
        (options['method'] as Map<String, bool>)[method] = true;
      }
    }

    // Only add order_id if it's provided and not empty
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      rethrow;
    }
  }

  // Initialize Google Pay specific payment
  Future<void> initiateGooglePayPayment({
    required String keyId,
    required double amount,
    required String currency,
    required String name,
    required String description,
    String? orderId,
    String? userEmail,
    String? userContact,
    Map<String, dynamic>? notes,
  }) async {
    var options = {
      'key': keyId,
      'amount': (amount * 100).toInt(),
      'currency': currency,
      'name': name,
      'description': description,
      'prefill': {'contact': userContact ?? '', 'email': userEmail ?? ''},
      'notes': notes ?? {},
      'theme': {'color': '#4285f4'}, // Google blue color
      'method': {
        'upi': true, // Only UPI for Google Pay
      }
    };

    // Only add order_id if it's provided and not empty
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      rethrow;
    }
  }

  // Payment success handler
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    onPaymentSuccess?.call(response);
  }

  // Payment failure handler
  void _handlePaymentFailure(PaymentFailureResponse response) {
    debugPrint('Payment Failed: ${response.code} - ${response.message}');
    onPaymentFailure?.call(response);
  }

  // External wallet handler
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  // Dispose resources
  void dispose() {
    _razorpay.clear();
  }
}