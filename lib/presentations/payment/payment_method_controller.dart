import 'dart:developer';
import 'dart:io';
import 'dart:math';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/response_models/cart/carte_booking_model.dart';
import '../../services/payment_services/razorpay.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';
import '../booking/successful_screens/booking_successful_screen.dart';
import '../../repositories/cart/cart_repository.dart';
import '../cart/cart_controller.dart';
import '../book_a_court/book_a_court_controller.dart';
import '../booking/book_session/book_session_controller.dart';
import '../main_home_page/main_home_controller.dart';
import '../profile/profile_controller.dart';

class PaymentMethodController extends GetxController {
  var option = ''.obs;
  RxBool isProcessing = false.obs;
  RazorpayPaymentService? _paymentService;
  String? _razorpayOrderId;
  bool? initiatePayment;

  RxDouble walletAmountUsed = 0.0.obs;
  RxDouble razorpayAmountUsed = 0.0.obs;

  /// When set, use this payload instead of cart/bookACourt (book session → payment direct flow).
  List<Map<String, dynamic>>? directBookingPayload;

  void setDirectBookingPayload(List<Map<String, dynamic>> payload) {
    directBookingPayload = payload;
  }

  static final _cartRepository = CartRepository();

  CartController? get _cartController =>
      Get.isRegistered<CartController>() ? Get.find<CartController>() : null;
  
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

  bool get isFromBookSession =>
      directBookingPayload != null && directBookingPayload!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // Initialize Razorpay for both iOS and Android
    _paymentService = RazorpayPaymentService();
    _paymentService!.onPaymentSuccess = _handlePaymentSuccess;
    _paymentService!.onPaymentFailure = _handlePaymentFailure;
    // _paymentService!.onExternalWallet = _handleExternalWallet;
    
    // Create initial booking
    // _createInitialBooking();
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

    await _processBookingAfterPayment(
      razorpayPaymentId: response.paymentId,
      razorpayOrderId: _razorpayOrderId,
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    isProcessing.value = false;
    // Get.back();
    // SnackBarUtils.showErrorSnackBar("Payment Failed: ${response.message}");
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

  Future<void> _processBookingAfterPayment({
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    try {
      List<Map<String, dynamic>>? bookingPayload;

      final mainHomeController = Get.isRegistered<MainHomeController>() ? Get.find<MainHomeController>() : null;
      final profileController = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
      final categoryId = mainHomeController?.selectedCategoryId.value;
      final locationId = profileController?.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

      if (isFromBookSession && directBookingPayload != null) {
        bookingPayload = List<Map<String, dynamic>>.from(directBookingPayload!);
      } else if (isFromBookACourt && bookACourtController != null) {
        bookingPayload = bookACourtController!.buildBookingPayload();
      } else {
        final cart = _cartController;
        bookingPayload = cart?.buildBookingPayload(categoryId: categoryId, locationId: locationId);
      }

      if (bookingPayload == null || bookingPayload.isEmpty) {
        Get.back();
        return;
      }

      if (razorpayPaymentId != null && razorpayOrderId != null) {
        for (var payload in bookingPayload) {
          payload['razorpay_payment_id'] = razorpayPaymentId;
          payload['razorpay_order_id'] = razorpayOrderId;
          payload['initiatePayment'] = true;
          payload['type'] = 'booked';

        }
      }

      print("Booking payload after payment: $bookingPayload");

      final response = await _cartRepository.dioClient.post(
        AppEndpoints.carteBooking,
        data: bookingPayload,
      );

      if (response.statusCode == 200) {
        print("Booking confirmed: ${response.data}");

        if (!isFromBookSession) {
          final cart = _cartController;
          if (cart != null) await cart.getCartItems();
        } else {
          directBookingPayload = null;
          if (Get.isRegistered<BookSessionController>()) {
            final c = Get.find<BookSessionController>();
            c.clearAllSelections();
          }
        }

        if (isFromBookACourt && bookACourtController != null) {
          bookACourtController!.clearAllSelections();
        }

        Get.to(() => BookingSuccessfulScreen());
      } else {
        Get.close(2);
        showBookingErrorDialog();
      }
    } catch (e) {
      print("Error processing booking after payment: $e");
      Get.close(2);
      showBookingErrorDialog();
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

  String _generateRandomPaymentId() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return 'pay_${List.generate(14, (index) => chars[random.nextInt(chars.length)]).join()}';
  }


  Future<void> createInitialBooking() async {
    try {
      List<Map<String, dynamic>>? bookingPayload;

      final mainHomeController = Get.isRegistered<MainHomeController>() ? Get.find<MainHomeController>() : null;
      final profileController = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
      final categoryId = mainHomeController?.selectedCategoryId.value;
      final locationId = profileController?.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

      if (isFromBookSession && directBookingPayload != null) {
        bookingPayload = List<Map<String, dynamic>>.from(directBookingPayload!);
      } else if (isFromBookACourt && bookACourtController != null) {
        bookingPayload = bookACourtController!.buildBookingPayload();
      } else {
        final cart = _cartController;
        bookingPayload = cart?.buildBookingPayload(categoryId: categoryId, locationId: locationId);
      }

      if (bookingPayload == null || bookingPayload.isEmpty) {
        print("No booking payload available");
        return;
      }

      for (var payload in bookingPayload) {
        payload['initiatePayment'] = false;
      }

      print("Initial booking payload: $bookingPayload");

      final response = await _cartRepository.dioClient.post(
        AppEndpoints.carteBooking,
        data: bookingPayload,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        print("Booking API response: $responseData");

        _razorpayOrderId = responseData['orderId'];
        initiatePayment = responseData.containsKey('requiresPayment')
            ? (responseData['requiresPayment'] as bool)
            : false;
        walletAmountUsed.value =
            (responseData['walletAmountUsed'] as num?)?.toDouble() ?? 0.0;
        razorpayAmountUsed.value =
            (responseData['razorpayAmountUsed'] as num?)?.toDouble() ?? 0.0;

        print(
          "Booking created with order ID: $_razorpayOrderId\n"
          "Wallet: ${walletAmountUsed.value}, Razorpay: ${razorpayAmountUsed.value}, Requires Payment: $initiatePayment",
        );

        if (initiatePayment == false) {
          showBookingSuccessDialog();
        } else {
          await Get.toNamed(RoutesName.paymentMethod);
        }
      }
    } catch (e, st) {
      print("Error creating initial booking: $e");
      print(st);
    }
  }

  void showBookingSuccessDialog() {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: Get.width * 0.85,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Booking Confirmed!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              const Text(
                "Your court has been booked successfully. No payment was required.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!isFromBookSession) {
                      final cart = _cartController;
                      if (cart != null) cart.getCartItems();
                    } else {
                      directBookingPayload = null;
                      if (Get.isRegistered<BookSessionController>()) {
                        Get.find<BookSessionController>().clearAllSelections();
                      }
                    }
                    if (isFromBookACourt && bookACourtController != null) {
                      bookACourtController!.clearAllSelections();
                    }
                    Get.back();
                    Get.offAllNamed(RoutesName.bottomNav);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Go to Home",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> startPayment() async {
    if (option.value.isEmpty) {
      Get.snackbar("Payment Method", "Please select a payment method");
      return;
    }

    if (_razorpayOrderId == null) {
      SnackBarUtils.showErrorSnackBar("Booking not initialized. Please try again.");
      return;
    }

    isProcessing.value = true;

    try {
      await _paymentService!.initiatePayment(
        keyId: 'rzp_live_RtOIWe2johK6H7',
        // keyId: 'rzp_test_1DP5mmOlF5G5ag',
        amount: razorpayAmountUsed.value.toDouble(),
        currency: 'INR',
        name: 'Swoot',
        description: 'Paying for court booking',
        image: 'https://rowthtech.s3.amazonaws.com/padel/Thu%20Jan%2022%202026%2013%3A38%3A20%20GMT%2B0530%20%28India%20Standard%20Time%29Padel_logo.svg',
        userEmail: 'test@example.com',
        userContact: '9999999999',
      );
    } catch (e) {
      isProcessing.value = false;
      CustomLogger.logMessage(msg: "Error: $e", level: LogLevel.error);
      // SnackBarUtils.showErrorSnackBar("Payment failed: $e");
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
