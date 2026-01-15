import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/core/endpoitns.dart';
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
  
  RxInt walletAmountUsed = 0.obs;
  RxInt razorpayAmountUsed = 0.obs;
  
  CartController get cartController => Get.find<CartController>();
  final storage = GetStorage();
  
  OpenMatchBookingController openMatchBookingController = Get.put(OpenMatchBookingController());
  ProfileController profileController = Get.put(ProfileController());
  HomeController homeController = Get.put(HomeController());
  
  // Local match data from create open matches controller
  Map<String, dynamic> localMatchData = {};
  
  // Calculate total amount from selected slots
  int get totalAmount {
    final slots = (localMatchData["slot"] as List?)?.cast<Slots>() ?? [];
    return slots.fold(0, (sum, slot) => sum + (slot.amount ?? 0));
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
      SnackBarUtils.showErrorSnackBar("Payment successful but match creation failed: $e");
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
        Get.snackbar("Error", "Invalid match data");
        return;
      }

      if (razorpayPaymentId != null && razorpayOrderId != null) {
        matchBody['razorpay_payment_id'] = razorpayPaymentId;
        matchBody['razorpay_order_id'] = razorpayOrderId;
        matchBody['initiatePayment'] = true;
      }

      log("Match payload after payment: $matchBody");

      final response = await repository.dioClient.post(
        AppEndpoints.createMatches,
        data: matchBody,
      );

      if (response.statusCode == 200) {
        log("Match confirmed: ${response.data}");
        SnackBarUtils.showSuccessSnackBar("Match created successfully!");
        Get.offAllNamed(RoutesName.bottomNav);
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
    if (!validateTeams()) {
      SnackBarUtils.showWarningSnackBar("Please add required players to both teams");
      return;
    }
    if (_razorpayOrderId == null) {
      SnackBarUtils.showErrorSnackBar("Match not initialized. Please try again.");
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
        userEmail: profileController.profileModel.value?.response?.email ?? 'test@example.com',
        userContact: '9999999999',
      );
    } catch (e) {
      isProcessing.value = false;
      log("Payment initiation error: $e");
      SnackBarUtils.showErrorSnackBar("Failed to initiate payment: $e");
    }
  }

  Future<void> _createInitialMatch() async {
    try {
      final matchBody = _buildMatchBody();
      if (matchBody == null) return;

      matchBody['initiatePayment'] = false;

      log("Initial match payload: $matchBody");

      final response = await repository.dioClient.post(
        AppEndpoints.createMatches,
        data: matchBody,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        log("Match API response: $responseData");
        
        if (responseData['orderId'] != null) {
          _razorpayOrderId = responseData['orderId'];
          walletAmountUsed.value = responseData['walletAmountUsed'] ?? 0;
          razorpayAmountUsed.value = responseData['razorpayAmountUsed'] ?? 0;
          log("Match created with order ID: $_razorpayOrderId");
        }
      }
    } catch (e) {
      log("Error creating initial match: $e");
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
    
    final slotData = (localMatchData["slot"] as List?)?.cast<Slots>() ?? [];
    final courtId = localMatchData["courtId"]?.toString() ?? "";
    final courtIds = (localMatchData["courtIds"] as List?)?.map((e) => e.toString()).toList() ?? [];
    final courtName = localMatchData["courtName"]?.toString() ?? "";

    final slotsJson = slotData.asMap().entries.map((entry) {
      final index = entry.key;
      final slot = entry.value;

      String slotCourtId = courtId;
      if (courtIds.isNotEmpty && index < courtIds.length) {
        slotCourtId = courtIds[index];
      }

      final businessHours = (localMatchData["businessHours"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final selectedDayName = DateFormat('EEEE').format(parsedMatchDate!);
      
      final cleanBusinessHours = businessHours
          .where((bh) => bh["day"] == selectedDayName)
          .map((bh) => {
            "time": bh["time"] ?? "",
            "day": bh["day"] ?? "",
          }).toList();

      String cleanSlotId = slot.sId ?? "";
      if (cleanSlotId.contains('_')) {
        cleanSlotId = cleanSlotId.split('_')[0];
      }
      
      int duration = slot.duration ?? 60;
      int totalTime = slot.duration ?? 60;
      String bookingTime = slot.bookingTime ?? slot.time ?? "";

      return {
        "slotId": cleanSlotId,
        "businessHours": cleanBusinessHours,
        "slotTimes": [
          {
            "time": slot.time ?? "",
            "amount": slot.amount ?? 0,
          }
        ],
        "matchType": selectedMatchType.value,
        "courtName": courtName,
        "courtId": slotCourtId,
        "bookingDate": formattedBookingDate,
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
      "matchTime": localMatchData["matchTime"] ?? "",
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
    _createInitialMatch();
  }

  @override
  void onClose() {
    _paymentService?.dispose();
    super.onClose();
  }
  
  // Group consecutive slots
  List<Map<String, dynamic>> getGroupedSlots() {
    final slots = (localMatchData["slot"] as List?)?.cast<Slots>() ?? [];
    if (slots.isEmpty) return [];

    // Sort slots by time
    final sortedSlots = slots.toList()
      ..sort((a, b) => _getSlotHour(a.time).compareTo(_getSlotHour(b.time)));

    final List<Map<String, dynamic>> groups = [];
    var i = 0;

    while (i < sortedSlots.length) {
      final consecutiveSlots = [sortedSlots[i]];
      var totalAmount = sortedSlots[i].amount ?? 0;

      // Find consecutive slots
      for (var j = i + 1; j < sortedSlots.length; j++) {
        final currentHour = _getSlotHour(sortedSlots[j - 1].time);
        final nextHour = _getSlotHour(sortedSlots[j].time);

        if (nextHour - currentHour == 1) {
          consecutiveSlots.add(sortedSlots[j]);
          totalAmount += sortedSlots[j].amount ?? 0;
        } else {
          break;
        }
      }

      // Create time range
      String timeRange;
      if (consecutiveSlots.length == 1) {
        timeRange = _formatTimeSlot(consecutiveSlots.first.time ?? '');
      } else {
        final startTime = _formatTimeSlot(consecutiveSlots.first.time ?? '');
        final endTime = _formatTimeSlot(consecutiveSlots.last.time ?? '');
        final startPeriod = startTime.contains('AM') ? 'AM' : 'PM';
        final endPeriod = endTime.contains('AM') ? 'AM' : 'PM';
        final startHour = startTime.replaceAll(RegExp(r'\s*(AM|PM)', caseSensitive: false), '');
        final endHour = endTime.replaceAll(RegExp(r'\s*(AM|PM)', caseSensitive: false), '');
        
        if (startPeriod == endPeriod) {
          timeRange = '$startHour-$endHour$endPeriod';
        } else {
          timeRange = '$startTime-$endTime';
        }
      }

      groups.add({
        'timeRange': timeRange,
        'totalAmount': totalAmount,
        'slots': consecutiveSlots,
      });

      i += consecutiveSlots.length;
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