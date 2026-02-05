import 'dart:developer';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/booking/successful_screens/booking_successful_screen.dart';
import 'package:padel_mobile/presentations/openmatchbooking/openmatch_booking_controller.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../configs/app_colors.dart';
import '../../../../configs/components/loader_widgets.dart';
import '../../../../configs/components/snack_bars.dart';
import '../../../../data/request_models/home_models/get_available_court.dart';
import '../../../../handler/logger.dart';
import '../../../../services/payment_services/razorpay.dart';
import '../../../cart/cart_controller.dart';

class QuestionsBottomsheetController extends GetxController {
  OpenMatchRepository repository = OpenMatchRepository();
  RxBool isProcessing = false.obs;
  RxString gameType = ''.obs;
  RxString selectedGameLevel = ''.obs;
  RxString selectedGameType = ''.obs;
  RxString selectedMatchType = ''.obs;
  RazorpayPaymentService? _paymentService;
  String? _razorpayOrderId;

  RxDouble walletAmountUsed = 0.0.obs;
  RxDouble razorpayAmountUsed = 0.0.obs;

  
  CartController get cartController => Get.find<CartController>();
  final storage = GetStorage();
  
  OpenMatchBookingController openMatchBookingController = Get.put(OpenMatchBookingController());
  ProfileController profileController = Get.put(ProfileController());
  HomeController homeController = Get.put(HomeController());
  
  // Local match data from create open matches controller
  Map<String, dynamic> localMatchData = {};
  
  // Calculate total amount from selected slots
  int get totalAmount {
    final slots = (localMatchData["slot"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    int total = 0;
    for (var slotEntry in slots) {
      final slotTimes = (slotEntry["slotTimes"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var slotTime in slotTimes) {
        total += (slotTime["amount"] as int?) ?? 0;
      }
    }
    return total;
  }
  
  // Get slot count
  int get totalSlots {
    return (localMatchData["slot"] as List?)?.length ?? 0;
  }
  
  // Validation method
  bool validateSelections() {
    if (selectedGameLevel.value.isEmpty) {
      SnackBarUtils.showInfoSnackBar("Please select a game level");
      return false;
    }
    if (selectedGameType.value.isEmpty) {
      SnackBarUtils.showInfoSnackBar("Please select a game type");
      return false;
    }
    if (selectedMatchType.value.isEmpty) {
      SnackBarUtils.showInfoSnackBar("Please select a match type");
      return false;
    }
    return true;
  }
  
  RxList<Map<String, dynamic>> teamA = <Map<String, dynamic>>[{
    "name": "",
    "image": "",
    "userId": "",
  }].obs;

  RxList<Map<String, dynamic>> teamB = <Map<String, dynamic>>[].obs;

  // Payment success handler
  Future<void> onPaymentSuccess({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    log("🎉 Payment successful - ID: $paymentId");

    try {
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
                    "Creating your open match...",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please wait while we set up your match.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      await _createMatchAfterPayment(
        razorpayPaymentId: paymentId,
        razorpayOrderId: _razorpayOrderId,
      );
    } catch (e) {
      log("Error after payment success: $e");
      // SnackBarUtils.showErrorSnackBar("Payment successful but match creation failed: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _createMatchAfterPayment({
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) async {
    try {
      final matchBody = _buildMatchBody();
      if (matchBody == null) {
        Get.back();
        // Get.snackbar("Error", "Invalid match data");
        return;
      }

      // Choose endpoint based on payment option
      final paymentOption = localMatchData["paymentOption"] as String? ?? "payForAll";
      final endpoint = paymentOption == "payShareOnly" 
          ? AppEndpoints.createOpenMatchSlotBookOnly 
          : AppEndpoints.createMatches;

      if (razorpayPaymentId != null && razorpayOrderId != null) {
        matchBody['razorpay_payment_id'] = razorpayPaymentId;
        matchBody['razorpay_order_id'] = razorpayOrderId;
        matchBody['initiatePayment'] = true;
        
        // Only set type 'booked' when using createMatches endpoint
        if (endpoint == AppEndpoints.createMatches) {
          matchBody['type'] = 'booked';
        }
      }

      log("Match payload after payment: $matchBody");

      final response = await repository.dioClient.post(
        endpoint,
        data: matchBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Match confirmed: ${response.data}");
        // SnackBarUtils.showSuccessSnackBar("Match created successfully!");
        // Get.offAllNamed(RoutesName.bottomNav);
        Get.to(() => BookingSuccessfulScreen());
        openMatchBookingController.fetchOpenMatchesBooking(type: 'upcoming');
      } else {
        Get.close(2);
        showBookingErrorDialog();
      }
    } catch (e) {
      log("Error creating match after payment: $e");
      Get.close(2);
      showBookingErrorDialog();
    }
  }


  Map<String, dynamic> removeEmpty(Map<String, dynamic> json) {
    json.removeWhere((key, value) =>
    value == null ||
        value == "" ||
        (value is List && value.isEmpty));
    return json;
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
                        Get.toNamed(RoutesName.bottomNav);
                      },
                      child: const Text(
                        "Go to Home",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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

  // Match creation with payment
  Future<void> initiateMatchCreation() async {
    log("🚀 Starting match creation process with payment");
    if (!validateSelections()) return;
    // if (!validateTeams()) {
    //   Fluttertoast.showToast(
    //     msg: "Please add required players to both teams",
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.BOTTOM,
    //     backgroundColor: Colors.red,
    //     textColor: Colors.white,
    //     fontSize: 16.0,
    //     timeInSecForIosWeb: 3,
    //   );
    //   return;
    // }
    if (_razorpayOrderId == null) {
      Fluttertoast.showToast(
        msg: "Match not initialized. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 3,
      );
      return;
    }

    isProcessing.value = true;

    try {
      await _paymentService!.initiatePayment(
        // keyId: 'rzp_live_RtOIWe2johK6H7',
        keyId: 'rzp_test_1DP5mmOlF5G5ag',
        amount: razorpayAmountUsed.value.toDouble(),
        currency: 'INR',
        name: 'Swoot',
        description: 'Payment for court booking and match creation',
        image: 'https://rowthtech.s3.amazonaws.com/padel/Thu%20Jan%2022%202026%2013%3A38%3A20%20GMT%2B0530%20%28India%20Standard%20Time%29Padel_logo.svg',
        userEmail: profileController.profileModel.value?.response?.email ?? 'test@example.com',
        userContact: '9999999999',
      );
    } catch (e) {
      isProcessing.value = false;
      log("Payment initiation error: $e");
      // SnackBarUtils.showErrorSnackBar("Failed to initiate payment: $e");
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
                    Get.back(); // Close dialog
                    Get.offAllNamed(RoutesName.bottomNav); // Go to home
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
  Future<void> onDirectPaymentTap() async {
    if (!validateSelections()) {
      return;
    }

    if (requiresPayment.value == false) {
      // If payment is required, first create match with isCalculation: false
      await _createInitialMatch(isCalculation: false);
      showBookingSuccessDialog();
    } else {
      // If no payment required, directly initiate match creation
      await initiateMatchCreation();
    }
  }

  Future<void> _createInitialMatch({required isCalculation}) async {
    try {
      final matchBody = _buildMatchBody();
      if (matchBody == null) return;

      matchBody['initiatePayment'] = false;
      matchBody['isCalculation'] = isCalculation;

      log("Initial match payload: $matchBody");

      // Choose endpoint based on payment option
      final paymentOption = localMatchData["paymentOption"] as String? ?? "payForAll";
      final endpoint = paymentOption == "payShareOnly" 
          ? AppEndpoints.createOpenMatchSlotBookOnly 
          : AppEndpoints.createMatches;

      final response = await repository.dioClient.post(
        endpoint,
        data: matchBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201 && response.data != null) {
        final responseData = response.data;
        log("Match API response: $responseData");
        _razorpayOrderId = responseData['orderId'];

        walletAmountUsed.value =
            (responseData['walletAmountUsed'] as num?)?.toDouble() ?? 0.0;

        razorpayAmountUsed.value =
            (responseData['razorpayAmountUsed'] as num?)?.toDouble() ?? 0.0;
        requiresPayment.value = responseData['requiresPayment'] ?? true;

        log(
          "Match created with order ID: $_razorpayOrderId | "
              "Wallet: ${walletAmountUsed.value}, "
              "Razorpay: ${razorpayAmountUsed.value}",
        );
        // if (responseData['orderId'] != null) {
        //
        // }
      }
    } catch (e, st) {
      log("Error creating initial match: $e");
      log(st.toString());
    }
  }


  Map<String, dynamic>? _buildMatchBody() {
    final matchDateValue = localMatchData["matchDate"];
    DateTime? parsedMatchDate;

    if (matchDateValue is DateTime) {
      parsedMatchDate = matchDateValue;
    } else if (matchDateValue != null) {
      parsedMatchDate = DateTime.tryParse(matchDateValue.toString());
    }

    if (parsedMatchDate == null) return null;

    final formattedMatchDate = DateFormat('yyyy-MM-dd').format(parsedMatchDate);
    final formattedBookingDate = DateTime.utc(parsedMatchDate.year, parsedMatchDate.month, parsedMatchDate.day).toIso8601String();
    
    final slotData = (localMatchData["slot"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final courtId = localMatchData["courtId"]?.toString() ?? "";
    final courtIds = (localMatchData["courtIds"] as List?)?.map((e) => e.toString()).toList() ?? [];
    final courtName = localMatchData["courtName"]?.toString() ?? "";

    // Group consecutive slots and calculate total time range
    final groupedSlots = getGroupedSlots();
    String overallTimeRange = "";
    
    if (groupedSlots.isNotEmpty) {
      if (groupedSlots.length == 1) {
        overallTimeRange = groupedSlots.first['timeRange'];
      } else {
        final firstTime = groupedSlots.first['timeRange'];
        final lastTime = groupedSlots.last['timeRange'];
        overallTimeRange = "$firstTime-${lastTime.split('-').last}";
      }
    }

    final slotsJson = slotData.asMap().entries.map((entry) {
      final index = entry.key;
      final slotEntry = entry.value;

      String slotCourtId = slotEntry["courtId"]?.toString() ?? courtId;
      if (courtIds.isNotEmpty && index < courtIds.length) {
        slotCourtId = courtIds[index];
      }

      final businessHours = (slotEntry["businessHours"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final selectedDayName = DateFormat('EEEE').format(parsedMatchDate!);
      
      final cleanBusinessHours = businessHours
          .where((bh) => bh["day"] == selectedDayName)
          .map((bh) => {
            "time": bh["time"] ?? "",
            "day": bh["day"] ?? "",
          }).toList();

      String cleanSlotId = slotEntry["slotId"]?.toString() ?? "";
      if (cleanSlotId.contains('_')) {
        cleanSlotId = cleanSlotId.split('_')[0];
      }
      
      final slotTimes = (slotEntry["slotTimes"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final firstSlotTime = slotTimes.isNotEmpty ? slotTimes.first : {};
      final slotTime = firstSlotTime["time"]?.toString() ?? "";
      final slotAmount = (firstSlotTime["amount"] as int?) ?? 0;
      
      int duration = 60; // Default duration
      
      // Check if this specific slot is a half slot
      final isHalfSlot = slotEntry["isHalfSlot"] as bool? ?? false;
      final isFirstHalf = slotEntry["isFirstHalf"] as bool? ?? true;
      if (isHalfSlot) {
        duration = 30;
      }
      
      int totalTime = slotData.length * duration; // Total time for all slots
      String bookingTime = slotTime;
      
      // For half slots, adjust the booking time based on which half is selected
      if (isHalfSlot && !isFirstHalf) {
        bookingTime = _addMinutesToTime(slotTime, 30);
      }

      return {
        "slotId": cleanSlotId,
        "businessHours": cleanBusinessHours,
        "slotTimes": [
          {
            "time": bookingTime,
            "amount": slotAmount,
          }
        ],
        "matchType": selectedMatchType.value,
        "courtName": slotEntry["courtName"]?.toString() ?? courtName,
        "courtId": slotCourtId,
        "bookingDate": slotEntry["bookingDate"]?.toString() ?? formattedBookingDate,
        "duration": duration,
        "totalTime": totalTime,
        "bookingTime": bookingTime
      };
    }).toList();

    final body = {
      "slot": slotsJson,
      "clubId": localMatchData["clubId"] ?? "",
      "matchDate": formattedMatchDate,
      "skillLevel": selectedGameLevel.value,
      "matchTime": overallTimeRange.isNotEmpty ? overallTimeRange : (localMatchData["matchTime"] ?? ""),
      "gender":selectedGameType.value,
      "teamA": teamA
          .where((p) =>
      (p["userId"] ?? p["_id"]) != null &&
          (p["userId"] ?? p["_id"]).toString().isNotEmpty)
          .map((p) => p["userId"] ?? p["_id"])
          .toList(),
      "teamB": teamB
          .where((p) =>
      (p["userId"] ?? p["_id"]) != null &&
          (p["userId"] ?? p["_id"]).toString().isNotEmpty)
          .map((p) => p["userId"] ?? p["_id"])
          .toList(),
    };

    return removeEmpty(body);
  }

  bool validateTeams() {
    bool teamAValid = teamA.isNotEmpty &&
        teamA.any((player) =>
        player['name'] != null &&
            player['name'].toString().isNotEmpty &&
            player['userId'] != null &&
            player['userId'].toString().isNotEmpty);
    return teamAValid;
  }

  @override
  void onInit() {
    // Initialize Razorpay for both iOS and Android
    _paymentService = RazorpayPaymentService();

    _paymentService!.onPaymentSuccess = (response) {
      onPaymentSuccess(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      );
    };

    _paymentService!.onPaymentFailure = (response) {
      String errorMessage = 'Payment failed';
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        errorMessage = 'Payment was cancelled';
      } else if (response.message != null) {
        errorMessage = response.message!;
      }
    };

    _paymentService!.onExternalWallet = (response) {
      log('External wallet used: ${response.walletName}');
    };

    profileController.fetchUserProfile();
    
    String skillLevel = "";
    if ((localMatchData['playerLevel'] ?? '').toString().isNotEmpty) {
      skillLevel = localMatchData['playerLevel'].toString();
    } else {
      final skillDetails = localMatchData['skillDetails'];
      if (skillDetails != null && skillDetails is List && skillDetails.isNotEmpty) {
        skillLevel = skillDetails.last.toString();
      } else if (localMatchData['skillLevel'] != null) {
        skillLevel = localMatchData['skillLevel'].toString();
      }
    }

    Map<String, dynamic> profileData = <String, dynamic>{
      "name": profileController.profileModel.value?.response!.name ?? "",
      "lastName": profileController.profileModel.value?.response?.lastName??"",
      "image": profileController.profileModel.value?.response!.profilePic ?? "",
      "userId": profileController.profileModel.value?.response!.sId ?? "",
      "level": profileController.profileModel.value?.response!.playerLevel?.split(' ').first??"",
      "levelLabel": skillLevel,
   };

    teamA.first.addAll(profileData);
    
    super.onInit();
  }
  
  void initializeMatch() {
    _createInitialMatch(isCalculation: true);
  }
  RxBool requiresPayment = true.obs; // Add this flag

  @override
  void onClose() {
    // Cleanup slot history if user exits without completing payment
    _paymentService?.dispose();
    super.onClose();
  }

  
  // Group consecutive slots
  List<Map<String, dynamic>> getGroupedSlots() {
    final slots = (localMatchData["slot"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (slots.isEmpty) return [];

    final List<Map<String, dynamic>> groups = [];
    
    for (var slotEntry in slots) {
      final slotTimes = (slotEntry["slotTimes"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (slotTimes.isNotEmpty) {
        final slotTime = slotTimes.first;
        var time = slotTime["time"]?.toString() ?? '';
        final amount = (slotTime["amount"] as int?) ?? 0;
        
        // Check if this is a half slot and adjust time display
        final isHalfSlot = slotEntry["isHalfSlot"] as bool? ?? false;
        final isFirstHalf = slotEntry["isFirstHalf"] as bool? ?? true;
        
        if (isHalfSlot && !isFirstHalf) {
          // For right half, add 30 minutes to the display time
          time = _addMinutesToTime(time, 30);
        }
        
        groups.add({
          'timeRange': _formatTimeSlot(time),
          'totalAmount': amount,
          'slots': [slotEntry], // Keep original structure for compatibility
        });
      }
    }

    return groups;
  }

  // Get hour from time string
  int _getSlotHour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 0;
    
    try {
      final time = timeStr.trim().toLowerCase();
      final dt = DateFormat('h:mm a').parseStrict(time);
      return dt.hour;
    } catch (_) {
      try {
        final time = timeStr.trim().toLowerCase();
        final dt = DateFormat('h a').parseStrict(time);
        return dt.hour;
      } catch (_) {
        final parts = timeStr.split(' ');
        if (parts.length == 2) {
          final isPm = parts[1].toLowerCase() == 'pm';
          final hm = parts[0].split(':');
          final h = int.tryParse(hm[0]) ?? 0;
          var hour = h % 12;
          if (isPm) hour += 12;
          return hour;
        }
        return 0;
      }
    }
  }

  // Format time slot
  String _formatTimeSlot(String time) {
    if (time.isEmpty) return time;
    return time.contains(':') ? time : time;
  }
  String _addMinutesToTime(String timeStr, int minutes) {
    try {
      final time = timeStr.trim().toLowerCase();
      final dt = DateFormat('h:mm a').parseStrict(time);
      final newTime = dt.add(Duration(minutes: minutes));
      return DateFormat('h:mm a').format(newTime);
    } catch (_) {
      try {
        final time = timeStr.trim().toLowerCase();
        final dt = DateFormat('h a').parseStrict(time);
        final newTime = dt.add(Duration(minutes: minutes));
        return DateFormat('h:mm a').format(newTime);
      } catch (_) {
        return timeStr; // Return original if parsing fails
      }
    }
  }
}