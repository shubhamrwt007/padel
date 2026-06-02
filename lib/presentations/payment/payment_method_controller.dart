import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/payment_services/razorpay.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';
import '../booking/successful_screens/booking_successful_screen.dart';
import '../../repositories/cart/cart_repository.dart';
import '../book_a_court/book_a_court_controller.dart';
import '../booking/book_session/book_session_controller.dart';
import '../booking/booking_controller.dart';
import '../profile/profile_controller.dart';
import '../../repositories/americano_repository/americano_repository.dart';
import 'package:padel_mobile/presentations/americano/americano_controller.dart';

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

  String? americanoMatchId;
  bool get isFromAmericano =>
      americanoMatchId != null && americanoMatchId!.isNotEmpty;

  static final _cartRepository = CartRepository();
  static final _americanoRepository = AmericanoRepository();

  // CartController? get _cartController =>
  //     Get.isRegistered<CartController>() ? Get.find<CartController>() : null;

  BookACourtController? get bookACourtController {
    try {
      return Get.isRegistered<BookACourtController>()
          ? Get.find<BookACourtController>()
          : null;
    } catch (e) {
      return null;
    }
  }

  BookSessionController? get bookSessionController {
    try {
      return Get.isRegistered<BookSessionController>()
          ? Get.find<BookSessionController>()
          : null;
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
    _paymentService = RazorpayPaymentService();

    _paymentService!.onPaymentSuccess = (response) {
      _handlePaymentSuccess(response);
    };

    _paymentService!.onPaymentFailure = (response) {
      _handlePaymentFailure(response);
    };
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    isProcessing.value = false;

    // Extract signature from response
    final signature = response.signature;

    CustomLogger.logMessage(
      msg:
          'Payment Success - PaymentId: ${response.paymentId}, OrderId: ${response.orderId}, Signature: $signature',
      level: LogLevel.debug,
    );

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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      razorpaySignature: signature,
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    isProcessing.value = false;

    // Unlock slots when payment fails
    if (Get.isRegistered<BookSessionController>()) {
      final c = Get.find<BookSessionController>();
      if (c.hasCalledSlotHistoryAPI.value) {
        log('❌ Payment failed, unlocking slots');
        c.cleanupOnBack();
        c.hasCalledSlotHistoryAPI.value = false;
      }
    }

    if (Get.isRegistered<BookACourtController>()) {
      final c = Get.find<BookACourtController>();
      if (c.hasCalledSlotHistoryAPI.value) {
        log('❌ Payment failed, unlocking slots');
        c.cleanupOnBack();
        c.hasCalledSlotHistoryAPI.value = false;
      }
    }
    // Get.back();
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    String? razorpaySignature,
  }) async {
    try {
      if (isFromAmericano) {
        CustomLogger.logMessage(
          msg: "From Americano Registration----------------------",
          level: LogLevel.debug,
        );
        final response = await _americanoRepository.registerPlayer(
          americanoMatchId: americanoMatchId!,
          razorpayPaymentId: razorpayPaymentId,
          razorpayOrderId: razorpayOrderId,
          razorpaySignature: razorpaySignature,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          CustomLogger.logMessage(
            msg: "Americano registration confirmed: ${response.data}",
            level: LogLevel.debug,
          );
          americanoMatchId = null;
          Get.to(() => const BookingSuccessfulScreen(buttonType: "tournament"));
        } else {
          Get.close(2);
          showBookingErrorDialog();
        }
        return;
      }

      List<Map<String, dynamic>>? bookingPayload;

      if (isFromBookSession && directBookingPayload != null) {
        CustomLogger.logMessage(
          msg: "object------------------------",
          level: LogLevel.debug,
        );
        bookingPayload = List<Map<String, dynamic>>.from(directBookingPayload!);
      } else if (isFromBookACourt && bookACourtController != null) {
        CustomLogger.logMessage(
          msg: "From Book A Court PAge----------------------",
          level: LogLevel.debug,
        );
        bookingPayload = bookACourtController!.buildBookingPayload();
      } else if (bookSessionController != null) {
        CustomLogger.logMessage(
          msg: "From Book Session PAge----------------------",
          level: LogLevel.debug,
        );
        bookingPayload = bookSessionController!.buildBookingPayload();
      }

      if (bookingPayload == null || bookingPayload.isEmpty) {
        Get.back();
        return;
      }

      if (razorpayPaymentId != null && razorpayOrderId != null) {
        for (var payload in bookingPayload) {
          payload['razorpay_payment_id'] = razorpayPaymentId;
          payload['razorpay_order_id'] = razorpayOrderId;
          if (razorpaySignature != null) {
            payload['razorpay_signature'] = razorpaySignature;
          }
          payload['initiatePayment'] = true;
          payload['type'] = 'booked';
        }
      }

      CustomLogger.logMessage(
        msg: "Booking payload after payment: $bookingPayload",
        level: LogLevel.debug,
      );

      final response = await _cartRepository.dioClient.post(
        AppEndpoints.carteBooking,
        data: bookingPayload,
      );

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Booking confirmed: ${response.data}",
          level: LogLevel.debug,
        );

        if (!isFromBookSession) {
          // final cart = _cartController;
          // if (cart != null) await cart.getCartItems();
        } else {
          directBookingPayload = null;
          if (Get.isRegistered<BookSessionController>()) {
            final c = Get.find<BookSessionController>();
            // Reset the flag since payment was successful
            c.hasCalledSlotHistoryAPI.value = false;
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
      CustomLogger.logMessage(
        msg: "Error processing booking after payment: $e",
        level: LogLevel.debug,
      );
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
                  Icon(Icons.error_outline, color: Colors.red, size: 80),
                  const SizedBox(height: 20),

                  Text(
                    isFromAmericano ? "Registration Failed" : "Booking Failed",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    isFromAmericano
                        ? "Your registration could not be completed right now."
                        : "Your booking could not be completed right now.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),

                  // const SizedBox(height: 8),
                  //
                  // const Text(
                  //   "Your payment has been received successfully, "
                  //       "but we couldn't confirm your booking at this moment.",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //     fontSize: 15,
                  //     color: Colors.black54,
                  //     height: 1.4,
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 8),
                  //
                  // const Text(
                  //   "Please contact support for assistance or a refund.",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //     fontSize: 15,
                  //     color: Colors.black54,
                  //   ),
                  // ),
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
                        // Unlock slots before going home
                        if (Get.isRegistered<BookSessionController>()) {
                          final c = Get.find<BookSessionController>();
                          if (c.hasCalledSlotHistoryAPI.value) {
                            c.cleanupOnBack();
                            c.hasCalledSlotHistoryAPI.value = false;
                          }
                        }
                        if (Get.isRegistered<BookACourtController>()) {
                          final c = Get.find<BookACourtController>();
                          if (c.hasCalledSlotHistoryAPI.value) {
                            c.cleanupOnBack();
                            c.hasCalledSlotHistoryAPI.value = false;
                          }
                        }
                        if (isFromAmericano) {
                          Get.delete<PaymentMethodController>(force: true);
                        }
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
                        side: BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
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

  Future<void> createInitialBooking() async {
    try {
      List<Map<String, dynamic>>? bookingPayload;

      // final mainHomeController = Get.isRegistered<MainHomeController>() ? Get.find<MainHomeController>() : null;
      // final profileController = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;
      // final categoryId = mainHomeController?.selectedCategoryId.value;
      // final locationId = profileController?.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

      if (isFromBookSession && directBookingPayload != null) {
        CustomLogger.logMessage(
          msg: "Direct----------------------",
          level: LogLevel.debug,
        );
        bookingPayload = List<Map<String, dynamic>>.from(directBookingPayload!);
      } else if (isFromBookACourt && bookACourtController != null) {
        CustomLogger.logMessage(
          msg: "From Book A Court PAge----------------------",
          level: LogLevel.debug,
        );
        bookingPayload = bookACourtController!.buildBookingPayload();
      } else if (bookSessionController != null) {
        CustomLogger.logMessage(
          msg: "From Book Session PAge----------------------",
          level: LogLevel.debug,
        );
        bookingPayload = bookSessionController!.buildBookingPayload();
      }

      if (bookingPayload == null || bookingPayload.isEmpty) {
        CustomLogger.logMessage(
          msg: "No booking payload available",
          level: LogLevel.debug,
        );
        return;
      }

      for (var payload in bookingPayload) {
        payload['initiatePayment'] = false;
      }

      CustomLogger.logMessage(
        msg: "Initial booking payload: $bookingPayload",
        level: LogLevel.debug,
      );

      final response = await _cartRepository.dioClient.post(
        AppEndpoints.carteBooking,
        data: bookingPayload,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        CustomLogger.logMessage(
          msg: "Booking API response: $responseData",
          level: LogLevel.debug,
        );

        _razorpayOrderId =
            responseData['orderId']; // Use razorpayOrderId from backend
        initiatePayment = responseData.containsKey('requiresPayment')
            ? (responseData['requiresPayment'] as bool)
            : false;
        walletAmountUsed.value =
            (responseData['walletAmountUsed'] as num?)?.toDouble() ?? 0.0;
        razorpayAmountUsed.value =
            (responseData['razorpayAmountUsed'] as num?)?.toDouble() ?? 0.0;

        CustomLogger.logMessage(
          msg:
              "Booking created with Razorpay order ID: $_razorpayOrderId\n"
              "Wallet: ${walletAmountUsed.value}, Razorpay: ${razorpayAmountUsed.value}, Requires Payment: $initiatePayment",
          level: LogLevel.debug,
        );

        if (initiatePayment == false) {
          showBookingSuccessDialog();
        } else {
          await Get.toNamed(RoutesName.paymentMethod);
        }
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error creating initial booking: $e,$st",
        level: LogLevel.debug,
      );
    }
  }

  void showBookingSuccessDialog() {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  color: Colors.green.withValues(alpha: 0.15),
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
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!isFromBookSession) {
                      // final cart = _cartController;
                      // if (cart != null) cart.getCartItems();
                    } else {
                      directBookingPayload = null;
                      if (Get.isRegistered<BookSessionController>()) {
                        final c = Get.find<BookSessionController>();
                        // Reset the flag since booking was successful without payment
                        c.hasCalledSlotHistoryAPI.value = false;
                        c.clearAllSelections();
                      }
                    }
                    if (isFromBookACourt && bookACourtController != null) {
                      bookACourtController!.clearAllSelections();
                    }
                    Get.back();
                    // Call deleteSlotHistory when returning from payment
                    if (Get.isRegistered<BookingController>()) {
                      Get.find<BookingController>().onPageResumed();
                    }
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

  final ProfileController profileController = Get.put(ProfileController());
  Future<void> startPayment() async {
    if (option.value.isEmpty) {
      AppToast.error("Please select a payment method");
      return;
    }

    if (_razorpayOrderId == null || _razorpayOrderId!.isEmpty) {
      AppToast.error("Booking not initialized. Please try again.");
      return;
    }

    CustomLogger.logMessage(
      msg:
          "Starting payment with Razorpay Order ID: $_razorpayOrderId, Amount: ${razorpayAmountUsed.value}",
      level: LogLevel.debug,
    );

    isProcessing.value = true;

    try {
      await _paymentService!.initiatePayment(
        // keyId: PaymentConfig.keyId,
        keyId: isFromAmericano
            ? "rzp_test_RtRFaVPUzoUtkG"
            : PaymentConfig.keyId,
        orderId: _razorpayOrderId,
        amount: razorpayAmountUsed.value.toDouble(),
        currency: 'INR',
        name: 'Swoot',
        description: isFromAmericano
            ? 'Paying for Americano'
            : 'Paying for court booking',
        image:
            'https://rowthtech.s3.amazonaws.com/padel/Thu%20Jan%2022%202026%2013%3A38%3A20%20GMT%2B0530%20%28India%20Standard%20Time%29Padel_logo.svg',
        userEmail: profileController.profileModel.value?.response?.email ?? "",
        userContact:
            profileController.profileModel.value?.response?.phoneNumber
                .toString() ??
            "",
      );
    } catch (e) {
      isProcessing.value = false;
      CustomLogger.logMessage(msg: "Error: $e", level: LogLevel.error);
    }
  }

  Future<void> createAmericanoRegistration(String matchId) async {
    try {
      isProcessing.value = true;
      directBookingPayload = null;
      americanoMatchId = matchId;

      CustomLogger.logMessage(
        msg: "Creating Americano registration for match: $matchId",
        level: LogLevel.debug,
      );

      final response = await _americanoRepository.registerPlayer(
        americanoMatchId: matchId,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final responseData = response.data;
        CustomLogger.logMessage(
          msg: "Americano registration API response: $responseData",
          level: LogLevel.debug,
        );

        _razorpayOrderId =
            responseData['orderId'] ??
            responseData['razorpayOrderId'] ??
            responseData['order_id'];

        initiatePayment = responseData.containsKey('requiresPayment')
            ? (responseData['requiresPayment'] as bool)
            : (responseData.containsKey('requires_payment')
                  ? (responseData['requires_payment'] as bool)
                  : true);

        walletAmountUsed.value =
            (responseData['walletAmountUsed'] as num?)?.toDouble() ??
            (responseData['walletAmount'] as num?)?.toDouble() ??
            (responseData['wallet_amount'] as num?)?.toDouble() ??
            0.0;

        razorpayAmountUsed.value =
            (responseData['razorpayAmountUsed'] as num?)?.toDouble() ??
            (responseData['razorpayAmount'] as num?)?.toDouble() ??
            (responseData['amount'] as num?)?.toDouble() ??
            (responseData['price'] as num?)?.toDouble() ??
            (responseData['registrationFee'] as num?)?.toDouble() ??
            0.0;

        CustomLogger.logMessage(
          msg:
              "Americano Registration created with Razorpay order ID: $_razorpayOrderId\n"
              "Wallet: ${walletAmountUsed.value}, Razorpay: ${razorpayAmountUsed.value}, Requires Payment: $initiatePayment",
          level: LogLevel.debug,
        );

        if (Get.isDialogOpen == true) {
          Get.back();
        }

        if (initiatePayment == false) {
          showAmericanoSuccessDialog();
        } else {
          await Get.toNamed(RoutesName.paymentMethod);
        }
      } else {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        AppToast.error(
          "Failed to initialize registration. Please try again. --!!",
        );
      }
    } on DioException catch (e, st) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      CustomLogger.logMessage(
        msg: "Error creating Americano registration: $e, $st",
        level: LogLevel.error,
      );
      final message =
          e.response?.data?['message'] ??
          'Failed to initialize registration. Please try again.';
      AppToast.error(message.toString());
      rethrow;
    } catch (e, st) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      CustomLogger.logMessage(
        msg: "Error creating Americano registration: $e, $st",
        level: LogLevel.error,
      );
      // AppToast.error("Failed to initialize registration. Please try again.");
      rethrow;
    } finally {
      isProcessing.value = false;
    }
  }

  void showAmericanoSuccessDialog() {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: Get.width * 0.85,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Registration Confirmed!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              const Text(
                "You have registered for the Americano match successfully. No payment was required.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    americanoMatchId = null;
                    Get.back();
                    Get.back();
                    Get.delete<PaymentMethodController>(force: true);
                    if (Get.isRegistered<AmericanoController>()) {
                      Get.find<AmericanoController>().fetchAmericanoMatches(
                        isRefresh: true,
                      );
                    }
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

  @override
  void onClose() {
    _paymentService?.dispose();
    super.onClose();
  }
}
