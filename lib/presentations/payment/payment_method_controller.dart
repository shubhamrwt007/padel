import 'dart:developer';
import 'dart:io';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/payment_services/razorpay.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';
import '../booking/successful_screens/booking_successful_screen.dart';
import '../cart/cart_controller.dart';
import '../book_a_court/book_a_court_controller.dart';

class PaymentMethodController extends GetxController {
  var option = ''.obs;
  RxBool isProcessing = false.obs;
  RazorpayPaymentService? _paymentService;
  
  final CartController cartController = Get.find<CartController>();
  
  BookACourtController? get bookACourtController {
    try {
      return Get.isRegistered<BookACourtController>() ? Get.find<BookACourtController>() : null;
    } catch (e) {
      return null;
    }
  }
  
  bool get isFromBookACourt {
    final controller = bookACourtController;
    return controller != null && controller.realCourtSelections.isNotEmpty;
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize Razorpay for both iOS and Android
    _paymentService = RazorpayPaymentService();
    _paymentService!.onPaymentSuccess = _handlePaymentSuccess;
    _paymentService!.onPaymentFailure = _handlePaymentFailure;
    // _paymentService!.onExternalWallet = _handleExternalWallet;
  }
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    isProcessing.value = false;

    Get.generalDialog(
      barrierDismissible: false,
      barrierColor: Colors.white,
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(color: AppColors.primaryColor, size: 30),
                const SizedBox(height: 20),
                const Text(
                  "Booking in progress...",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please wait while we confirm your booking.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    await _processBookingAfterPayment();
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    isProcessing.value = false;
    Get.back();
    SnackBarUtils.showErrorSnackBar("Payment Failed: ${response.message}");
  }

  // Direct booking without payment (for Android)
  Future<void> processDirectBooking() async {
    isProcessing.value = true;

    Get.generalDialog(
      barrierDismissible: false,
      barrierColor: Colors.white,
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingWidget(color: AppColors.primaryColor, size: 30),
                const SizedBox(height: 20),
                const Text(
                  "Booking in progress...",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please wait while we confirm your booking.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    await _processBookingAfterPayment();
  }

  Future<void> _processBookingAfterPayment() async {
    try {
      List<Map<String, dynamic>>? bookingPayload;
      
      // Check if booking is from BookACourtController
      if (isFromBookACourt && bookACourtController != null) {
        bookingPayload = bookACourtController!.buildBookingPayload();
      } else {
        // Use CartController's payload
        bookingPayload = cartController.buildBookingPayload();
      }

      if (bookingPayload == null) {
        Get.back();
        Get.snackbar("Error", "No selected items available for booking");
        return;
      }

      log("Booking payload after payment: $bookingPayload");

      // ⬅️ Get true/false from bookCart() - same API for both cases
      bool success = await cartController.bookCart(data: bookingPayload);

      if (success) {
        // 👍 Booking success
        SnackBarUtils.showSuccessSnackBar("Booking completed successfully");
        
        // Clear selections if from BookACourtController
        if (isFromBookACourt && bookACourtController != null) {
          bookACourtController!.clearAllSelections();
        }
        
        Get.to(() => BookingSuccessfulScreen());
      } else {
        // ❌ API returned error
        Get.close(2);  // close "booking in progress"
        showBookingErrorDialog();

      }
    } catch (e) {
      log("Error processing booking after payment: $e");

      Get.close(2); // ⬅️ close dialog
      showBookingErrorDialog();

      // Get.snackbar(
      //   "Booking Error",
      //   "Payment successful but booking failed: ${e.toString()}",
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    }
  }

  void showBookingErrorDialog() {
    Get.generalDialog(
      barrierDismissible: false,
      barrierColor: Colors.white,
      pageBuilder: (_, __, ___) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Booking Failed",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Your booking could not be completed right now.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Your payment has been received successfully, "
                        "but we couldn't confirm your booking at this moment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Please contact support for assistance or a refund.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Go Home button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.offAllNamed(RoutesName.bottomNav);
                      },
                      child: const Text(
                        "Go to Home",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Help & Support button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.toNamed(RoutesName.support);
                      },
                      child: Text(
                        "Help & Support",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> verifyPayment(
      String paymentId,
      String orderId,
      String signature,
      ) async {
    // Send paymentId, orderId, and signature to your backend for verification
    debugPrint('Verifying payment: $paymentId, $orderId, $signature');
  }

  Future<void> startPayment() async {
    if (option.value.isEmpty) {
      Get.snackbar("Payment Method", "Please select a payment method");
      return;
    }

    // Use Razorpay for both iOS and Android
    isProcessing.value = true;

    try {
      double amountToPay;
      if (isFromBookACourt && bookACourtController != null) {
        amountToPay = bookACourtController!.totalAmount.value.toDouble();
      } else {
        amountToPay = cartController.totalPrice.value.toDouble();
      }
      
      await _paymentService!.initiatePayment(
        keyId: 'rzp_test_1DP5mmOlF5G5ag',
        amount: amountToPay,
        currency: 'INR',
        name: 'Swoot',
        description: 'Paying for court booking',
        userEmail: 'test@example.com',
        userContact: '9999999999',
      );
      
    } catch (e) {
      isProcessing.value = false;
      CustomLogger.logMessage(msg: "Error: $e", level: LogLevel.error);
      SnackBarUtils.showErrorSnackBar("Payment failed: $e");
    }
  }

  @override
  void dispose() {
    _paymentService?.dispose();
    super.dispose();
  }

  final List<Map<String, String>> paymentList = [
    {
      "name": "Google Pay",
      "icon": Assets.imagesIcGooglePayment,
      "value": "google_pay",
    },
    {"name": "PayPal", "icon": Assets.imagesIcPaypal, "value": "paypal"},
    {"name": "ApplePay", "icon": Assets.imagesIcApple, "value": "apple_pay"},
    {
      "name": ".... .... .... 4698",
      "icon": Assets.imagesIcMasterCardPayment,
      "value": "mastercard",
    },
  ];
}
