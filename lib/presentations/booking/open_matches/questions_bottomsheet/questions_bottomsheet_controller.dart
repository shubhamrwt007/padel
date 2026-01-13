import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
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

  // Payment success handler for iOS
  Future<void> onPaymentSuccess({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    log("🎉 Payment successful - ID: $paymentId, Order: $orderId, Signature: $signature");
    log("🚀 About to call createMatchAfterPayment");

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
      
      await createMatchAfterPayment();
    } catch (e) {
      log("Error after payment success: $e");
      SnackBarUtils.showErrorSnackBar("Payment successful but match creation failed: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  // Handle payment failure for iOS
  // Direct match creation without payment (for Android)
  Future<void> createDirectMatch() async {
    log("🚀 Starting direct match creation process");
    if (!validateSelections()) {
      return;
    }
    
    if (!validateTeams()) {
      SnackBarUtils.showWarningSnackBar("Please add required players to both teams");
      return;
    }

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
    
    await createMatchAfterPayment();
  }

  // Create match after payment success
  var openMatchId = ''.obs;
  Future<void> createMatchAfterPayment() async {
    log("🚀 Starting createMatchAfterPayment method");
    try {
      final matchDateValue = localMatchData["matchDate"];
      DateTime? parsedMatchDate;

      if (matchDateValue is DateTime) {
        parsedMatchDate = matchDateValue;
      } else if (matchDateValue != null) {
        parsedMatchDate = DateTime.tryParse(matchDateValue.toString());
      }

      if (parsedMatchDate == null) {
        log("⚠️ No valid matchDate found in localMatchData, using today");
        parsedMatchDate = DateTime.now();
      }

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

        // Get businessHours from localMatchData
        final businessHours = (localMatchData["businessHours"] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        // Clean businessHours to only include time and day
        final cleanBusinessHours = businessHours.map((bh) => {
          "time": bh["time"] ?? "",
          "day": bh["day"] ?? "",
        }).toList();

        // Handle half slots and other suffixes - don't send suffixes in slotId
        String cleanSlotId = slot.sId ?? "";
        if (cleanSlotId.contains('_')) {
          cleanSlotId = cleanSlotId.split('_')[0]; // Remove everything after first underscore
        }
        
        // Calculate proper duration, totalTime, and bookingTime
        int duration = slot.duration ?? 60;
        int totalTime = slot.duration ?? 60;
        String bookingTime = slot.bookingTime ?? slot.time ?? "";
        
        // Get the selected duration from localMatchData
        final selectedDurationStr = localMatchData["selectedDuration"] as String?;
        int selectedDurationMinutes = 60;
        if (selectedDurationStr != null) {
          selectedDurationMinutes = int.tryParse(selectedDurationStr.replaceAll(' min', '')) ?? 60;
          log("Debug - Found selectedDuration in localMatchData: $selectedDurationStr -> $selectedDurationMinutes");
        } else {
          // Fallback: determine from slot count
          if (slotData.length >= 2) {
            selectedDurationMinutes = 120; // Assume 120min for 2+ slots
          }
          log("Debug - No selectedDuration found, using fallback based on slot count ${slotData.length}: $selectedDurationMinutes");
        }
        
        // Check if this is a half slot selection (30min duration with left/right indicators)
        bool isHalfSlot = selectedDurationMinutes == 30 && 
            (slot.sId?.contains('_left') == true || slot.sId?.contains('_right') == true);
        
        // Check if this is a 90min half slot (second slot in 90min selection)
        bool is90MinHalfSlot = selectedDurationMinutes == 90 && 
            (slot.sId?.contains('_half') == true || slot.sId?.contains('_second') == true);
        
        // Set duration and totalTime based on selected duration and slot type
        if (isHalfSlot || selectedDurationMinutes == 30) {
          duration = 30;
          totalTime = 30;
        } else if (is90MinHalfSlot) {
          duration = 30; // Half slot duration
          totalTime = 90; // Total time for 90min selection
        } else if (selectedDurationMinutes == 90) {
          duration = 60; // Full slot duration
          totalTime = 90; // Total time for 90min selection
        } else if (selectedDurationMinutes == 120) {
          totalTime = 60; // 60min per slot for 120min (2 slots of 60min each)
        } else {
          totalTime = selectedDurationMinutes; // 60min
        }
        
        log("Debug - Slot ${index}: selectedDuration=$selectedDurationMinutes, isHalfSlot=$isHalfSlot, is90MinHalfSlot=$is90MinHalfSlot, duration=$duration, totalTime=$totalTime");
        
        // For 30min slots, adjust bookingTime based on half selection
        if (slot.sId?.contains('_half') == true || slot.sId?.contains('_R') == true) {
          // For right half, add 30 minutes to the original time
          if (slot.sId?.endsWith('_R') == true) {
            bookingTime = _addMinutesToTime(slot.time ?? "", 30);
          }
        }

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
        // "skillLevel": localMatchData["skillLevel"] ?? "",
        "skillLevel": selectedGameLevel.value,
        // "skillDetails": localMatchData["skillDetails"] ?? [],
        // "customerScale": localMatchData["customerScale"] ?? "",
        // "customerRacketSport": localMatchData["customerRacketSport"] ?? "",
        // "receivingTP": localMatchData["receivingTP"] ?? "",
        // "customerAge": localMatchData["customerAge"] ?? "",
        // "volleyNetPositioning": localMatchData["volleyNetPositioning"] ?? "",
        // "playerLevel": localMatchData["playerLevel"] ?? "",
        // "reboundSkills": localMatchData["reboundSkills"] ?? "",
        "matchStatus": "open",
        "matchTime": localMatchData["matchTime"] ?? "",
        "gender":selectedGameType.value,
        // "matchType":selectedMatchType.value,
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

      log("✅ Final Match Request Body:");
      log(body.toString());
      final cleanedBody = removeEmpty(body);
      log("📦 Final Cleaned Body:");
      log(cleanedBody.toString());

      final response = await repository.createMatch(data: cleanedBody);
      log("🎯 Match Created -> ${response.toJson()}");
      openMatchId.value = response.matches?[0].id??"";
      SnackBarUtils.showSuccessSnackBar("Match created successfully!");
      CustomLogger.logMessage(msg: "MEWW-> ${response.message??""}", level: LogLevel.debug);
      // await createBooking();

      Get.offAllNamed(RoutesName.bottomNav);
      openMatchBookingController.fetchOpenMatchesBooking(type: 'upcoming');
    } catch (e, st) {
      log("❌ Match creation error: $e\n$st");
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

  // Platform-specific match creation
  Future<void> initiateMatchCreation() async {
    log("🚀 Starting platform-specific match creation process");
    
    if (Platform.isIOS) {
      // Use Razorpay for iOS
      await initiatePaymentAndCreateMatch();
    } else {
      // Direct match creation for Android
      await createDirectMatch();
    }
  }

  // Payment method for iOS
  Future<void> initiatePaymentAndCreateMatch() async {
    log("💳 Starting payment initiation process");
    if (!validateSelections()) {
      return;
    }
    
    if (!validateTeams()) {
      SnackBarUtils.showWarningSnackBar("Please add required players to both teams");
      return;
    }

    isProcessing.value = true;

    try {
      final priceString = totalAmount.toString();
      final price = double.tryParse(priceString.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

      if (price <= 0) {
        SnackBarUtils.showErrorSnackBar("Invalid price amount");
        isProcessing.value = false;
        return;
      }

      await _paymentService!.initiatePayment(
        keyId: 'rzp_test_1DP5mmOlF5G5ag',
        amount: price,
        currency: 'INR',
        name: 'Swoot',
        description: 'Payment for court booking and match creation',
        orderId: '',
        userEmail: profileController.profileModel.value?.response?.email ?? 'test@example.com',
        userContact: '9999999999',
        notes: {
          'user_id': profileController.profileModel.value?.response?.sId ?? '123',
          'club_id': localMatchData['clubId'],
          'match_date': localMatchData['matchDate'].toString(),
          'match_time': localMatchData['matchTime'].toString(),
        },
        theme: '#F37254',
        paymentMethods: ['card', 'netbanking', 'upi', 'wallet'],
      );
    } catch (e) {
      isProcessing.value = false;
      log("Payment initiation error: $e");
      SnackBarUtils.showErrorSnackBar("Failed to initiate payment: $e");
    }
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
    // Only initialize Razorpay for iOS
    if (Platform.isIOS) {
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
        // onPaymentError(errorMessage);
      };

      _paymentService!.onExternalWallet = (response) {
        log('External wallet used: ${response.walletName}');
      };
    }

    profileController.fetchUserProfile();
    
    // localMatchData will be set directly by the calling controller
    // No need to get from arguments since this is a bottomsheet
    
    // Add profile data to teamA
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