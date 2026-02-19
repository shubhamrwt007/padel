import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/get_all_slot_prices_of_court_model.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import '../../../../data/request_models/home_models/get_available_court.dart';
import '../../../../data/request_models/home_models/get_club_name_model.dart';
import '../../../../repositories/cart/cart_repository.dart';
import '../../../../repositories/home_repository/home_repository.dart';
import '../../../cart/cart_controller.dart';
import '../../../../configs/routes/routes_name.dart';
import '../../../booking/details_page/details_page_controller.dart';
import '../questions_bottomsheet/questions_bottomsheet_controller.dart';
import '../questions_bottomsheet/questions_bottomsheet_screen.dart';

class CreateOpenMatchesController extends GetxController {

  ///Date Picker----------------------------------------------------------------
  Future<void> openDatePicker(BuildContext context) async {

    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: TextTheme(
              // Header (month/year)
              headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              // Days of week (Mon, Tue, ...)
              titleSmall: TextStyle(fontSize: 14),
              // Date numbers
              bodyLarge: TextStyle(fontSize: 16),
              // Buttons (CANCEL/OK)
              labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

          ),
          child: Transform.scale(
            scale: 0.9, // 👈 Adjust this to control overall calendar height
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      selectedDate.value = picked;
      dateTimelineController.animateToDate(picked);

      // // Refresh slots for all selected courts for the new date
      // for (String courtId in selectedCourtIds) {
      //   await getAvailableCourtsById(
      //       registerClubId: registerClubId.value,
      //       courtId: courtId
      //   );
      // }
    }
  }
  final EasyDatePickerController dateTimelineController = EasyDatePickerController();
  // Booking limits
  static const int maxSlots = 3; // Limit for open matches
  static const int maxDays = 1; // Single day for open matches
  final focusedMonth = DateTime.now().obs;
  
  final selectedDate = Rxn<DateTime>();
  final selectedDuration = '60 min'.obs;

  /// Check if any slot has 30-minute pricing available
  bool hasAny30MinSlots() {
    final courts = slots.value?.data ?? [];
    for (final court in courts) {
      final slotsList = court.slots ?? [];
      for (final slot in slotsList) {
        if (slot.has30MinPrice == true) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Check if a specific slot supports 30-minute pricing
  bool slotSupports30Min(Slots slot) {
    return slot.has30MinPrice == true;
  }

  Courts argument = Courts();
  RxBool showUnavailableSlots = false.obs;
  RxInt currentPage = 0.obs;
  var selectedTimeOfDay = 0.obs;
  var isManualTabSelection = false.obs;

  var morningCount = 0.obs;
  var noonCount = 0.obs;
  var nightCount = 0.obs;

  // Date formatter for consistency
  static final _dateFormatter = DateFormat('yyyy-MM-dd');

  void select(String value) async {
    selectedDuration.value = value;
    // Clear all selections when duration changes
    multiDateSelections.clear();
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    totalAmount.value = 0;
    // Refetch courts with updated prices when duration changes
    if (slots.value != null) {
      await getAvailableCourtsById(argument.id!, showUnavailable: true);
    }
  }

  // Cache base slot lists (after unavailable/available toggle applied)
  final Map<String, List<Slots>> _originalSlotsCache = {};
  final Map<String, List<Slots>> _allSlotsCache = {}; // Combined slots cache

  PageController pageController = PageController();

  // OLD: Single date selections
  RxList<Slots> selectedSlots = <Slots>[].obs;

  // NEW: Multi-date selections - key format: "date_courtId_slotId"
  RxMap<String, Map<String, dynamic>> multiDateSelections = <String, Map<String, dynamic>>{}.obs;

  RxInt totalAmount = 0.obs;
  final HomeRepository repository = HomeRepository();
  Rx<GetAllActiveCourtsForSlotWiseModel?> slots = Rx<GetAllActiveCourtsForSlotWiseModel?>(null);
  RxBool isLoadingCourts = false.obs;
  CartRepository cartRepository = CartRepository();

  // Keep existing for backward compatibility
  RxMap<String, Map<String, dynamic>> selectedSlotsWithCourtInfo = <String, Map<String, dynamic>>{}.obs;
  RxBool isBottomSheetOpen = false.obs;
  
  // Track if slot history API was called
  RxBool hasCalledSlotHistoryAPI = false.obs;
  
  // Payment option selection
  final selectedIndex = 0.obs; // 0 = Pay All, 1 = Pay Share
  void selectPaymentOption(int index) {
    selectedIndex.value = index;
  }
  var categoryId = "".obs;
  var locationID = "".obs;
  var locationsId = "".obs;
   var sId = "".obs;

  @override
  void onInit() {
    super.onInit();
    argument = Get.arguments['id'];
    sId.value = Get.arguments['sID']??"";
    categoryId.value = Get.arguments['categoryId'];
    locationID.value = Get.arguments['location'];
    locationsId.value = Get.arguments['locationsId'];
    selectedDate.value = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchAllSlotPrices();
      await getAvailableCourtsById(argument.id!, showUnavailable: true);
    });
  }

  @override
  void onClose() {
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    multiDateSelections.clear();
    totalAmount.value = 0;
    pageController.dispose();
    super.onClose();
  }

  // API method for deleting slot history (batch)
  Future<void> deleteSlotHistory({required List<Map<String, dynamic>> slots}) async {
    try {
      log('deleteSlotHistory called with body: $slots');
      await repository.deleteSlotHistory(data: {"slots": slots});
    } catch (e) {
      log('Error in deleteSlotHistory: $e');
    }
  }

  Future<void> cleanupSlotHistory() async {
    if (multiDateSelections.isEmpty || !hasCalledSlotHistoryAPI.value) return;
    
    try {
      final slots = <Map<String, dynamic>>[];
      
      for (var entry in multiDateSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final dateString = selection['date'] as String;
        final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
        final isLeftHalf = selection['isLeftHalf'] as bool?;
        final supports30Min = slotSupports30Min(slot);
        final duration = (supports30Min && isLeftHalf != null) ? 30 : 60;
        
        slots.add({
          "slotId": slotId,
          "courtId": courtId,
          "bookingDate": dateString,
          "time": bookingTime,
          "bookingTime": bookingTime,
          "duration": duration,
        });
      }
      
      await deleteSlotHistory(slots: slots);
      log('Cleanup slot history: $slots');
      hasCalledSlotHistoryAPI.value = false;
    } catch (e) {
      log('Error in cleanup slot history: $e');
    }
  }



  // Process slot history for payment - call APIs for all selections
  Future<bool> processSlotHistoryForPayment() async {
    if (multiDateSelections.isEmpty) return false;

    try {
      final slots = <Map<String, dynamic>>[];
      
      for (var entry in multiDateSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final dateString = selection['date'] as String;
        final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
        final isLeftHalf = selection['isLeftHalf'] as bool?;
        final supports30Min = slotSupports30Min(slot);
        final duration = (supports30Min && isLeftHalf != null) ? 30 : 60;
        
        slots.add({
          "slotId": slotId,
          "courtId": courtId,
          "courtName": courtName,
          "bookingDate": dateString,
          "time": bookingTime,
          "bookingTime": bookingTime,
          "duration": duration,
          "totalTime": duration,
        });
      }
      
      final success = await createAndGetSlotHistory(slots);
      if (success) {
        hasCalledSlotHistoryAPI.value = true;
      }
      return success;
    } catch (e) {
      log('Error processing slot history: $e');
      return false;
    }
  }

  void onNextPressed() {
    if (selectedIndex.value == 0) {
      // Pay for All Players
      Get.back();
      onNext();
    } else if (selectedIndex.value == 1) {
      // Pay your share only
      Get.back();
      onNextPayShareOnly();
    }
  }
  
  void onNextPayShareOnly() async {
    log("Pay Share Only - Slots -> $selectedSlots");

    if (multiDateSelections.isEmpty) {
      return;
    }

    try {
      final success = await processSlotHistoryForPayment();
      if (!success) {
        return;
      }
    } catch (e) {
      return;
    }

    // Collect all unique court IDs and names from selections
    Map<String, String> courtsMap = {};
    multiDateSelections.forEach((key, selection) {
      final courtId = selection['courtId'] as String?;
      final courtName = selection['courtName'] as String?;
      if (courtId != null && courtId.isNotEmpty) {
        courtsMap[courtId] = courtName ?? '';
      }
    });

    List<String> courtIds = courtsMap.keys.toList();
    List<String> courtNames = courtsMap.values.toList();
    String primaryCourtId = courtIds.first;
    String primaryCourtName = courtNames.first;

    if (Get.isRegistered<DetailsController>()) {
      Get.delete<DetailsController>();
    }
    final detailsController = Get.put(DetailsController());
    detailsController.isFromOpenMatch = true;

    detailsController.localMatchData.update("clubName", (value) => slots.value!.data![0].clubName ?? "");
    detailsController.localMatchData.update("address", (value) => slots.value!.data![0].registerClubId?.address ?? "");
    detailsController.localMatchData.update("clubId", (v) => slots.value!.data![0].registerClubId!.sId ?? "");
    detailsController.localMatchData["ownerId"] = slots.value!.data![0].registerClubId?.ownerId?.sId ?? "";
    detailsController.localMatchData["categoryId"] = categoryId.value;
    detailsController.localMatchData["location"] = locationID.value;
    detailsController.localMatchData["stateId"] = locationsId.value;
    detailsController.localMatchData["paymentOption"] = "payShareOnly";
    
    detailsController.localMatchData.update("matchDate", (v) => selectedDate.value ?? "");
    detailsController.localMatchData.update("clubImage", (v)=> slots.value!.data![0].registerClubId?.courtImage ??[]);
    detailsController.localMatchData.update("matchTime", (v) => selectedSlots.map((s) => s.time).toList());
    detailsController.localMatchData.update("price", (v) => totalAmount.toString());

    
    final courtTypes = slots.value!.data![0].registerClubId!.courtType ?? [];
    final courts = slots.value?.data ?? [];
    List<String> selectedCourtTypes = [];
    
    for (String courtId in courtIds) {
      int courtIndex = -1;
      for (int i = 0; i < courts.length; i++) {
        if (courts[i].sId == courtId) {
          courtIndex = i;
          break;
        }
      }
      
      if (courtIndex >= 0 && courtIndex < courtTypes.length) {
        selectedCourtTypes.add(courtTypes[courtIndex]);
      } else if (courtTypes.isNotEmpty) {
        selectedCourtTypes.add(courtTypes.first);
      }
    }
    
    final courtTypeValue = selectedCourtTypes.length == 1 ? selectedCourtTypes.first : selectedCourtTypes;
    detailsController.localMatchData.update("courtType", (v) => courtTypeValue);
    
    List<Slots> updatedSlots = [];
    Map<String, Slots> consolidatedSlots = {};
    
    for (Slots slot in selectedSlots) {
      Map<String, dynamic>? leftHalfSelection;
      Map<String, dynamic>? rightHalfSelection;
      
      multiDateSelections.forEach((key, selection) {
        final selectionSlot = selection['slot'] as Slots;
        if (selectionSlot.sId == slot.sId) {
          if (key.endsWith('_L')) {
            leftHalfSelection = selection;
          } else if (key.endsWith('_R')) {
            rightHalfSelection = selection;
          } else {
            leftHalfSelection = selection;
          }
        }
      });
      
      final supports30Min = slotSupports30Min(slot);
      
      if (supports30Min && leftHalfSelection != null && rightHalfSelection != null) {
        if (!consolidatedSlots.containsKey(slot.sId)) {
          consolidatedSlots[slot.sId!] = Slots(
            sId: slot.sId,
            time: slot.time,
            amount: slot.amount,
            businessHours: slot.businessHours,
            status: slot.status,
            availabilityStatus: slot.availabilityStatus,
            duration: 60,
            bookingTime: slot.time ?? '',
          );
        }
      } else {
        final selectionData = leftHalfSelection ?? rightHalfSelection;
        final adjustedAmount = selectionData?['adjustedAmount'] as int? ?? slot.amount ?? 0;
        final duration = supports30Min && (leftHalfSelection != null || rightHalfSelection != null) ? 30 : 60;
        
        Slots updatedSlot = Slots(
          sId: slot.sId,
          time: slot.time,
          amount: adjustedAmount,
          businessHours: slot.businessHours,
          status: slot.status,
          availabilityStatus: slot.availabilityStatus,
          duration: duration,
          bookingTime: selectionData?['bookingTime'] ?? slot.time ?? '',
        );
        updatedSlots.add(updatedSlot);
      }
    }
    
    updatedSlots.addAll(consolidatedSlots.values);
    
    final slotsAsMap = updatedSlots.map((slot) {
      final businessHoursList = (slot.businessHours ?? []).map((bh) => {
        "time": bh.time ?? '',
        "day": bh.day ?? '',
      }).toList();
      
      return {
        "slotId": slot.sId ?? '',
        "businessHours": businessHoursList,
        "slotTimes": [{
          "time": slot.bookingTime ?? slot.time ?? '',
          "amount": slot.amount ?? 0,
        }],
        "duration": slot.duration ?? 60,
        "bookingTime": slot.bookingTime ?? slot.time ?? '',
      };
    }).toList();
    
    detailsController.localMatchData.update("slot", (v) => slotsAsMap);
    detailsController.localMatchData["courtId"] = primaryCourtId;
    detailsController.localMatchData["courtName"] = primaryCourtName;
    detailsController.localMatchData["courtIds"] = courtIds;
    detailsController.localMatchData["courtNames"] = courtNames;
    detailsController.localMatchData["courtsDetails"] = courtsMap;

    Get.put(QuestionsBottomsheetController(), tag: 'questions');
    Get.find<QuestionsBottomsheetController>(tag: 'questions').localMatchData = detailsController.localMatchData;
    
    Get.bottomSheet(
      QuestionsBottomsheetScreen(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    ).then((_) {
      cleanupSlotHistory();
      Get.delete<QuestionsBottomsheetController>(tag: 'questions');
    });
  }

  void onNext() async {
    log("Slots -> $selectedSlots");

    if (multiDateSelections.isEmpty) {
      // SnackBarUtils.showInfoSnackBar("Please select at least one slot to continue.");
      return;
    }

    try {
      final success = await processSlotHistoryForPayment();
      if (!success) {
        return;
      }
    } catch (e) {
      return;
    }

    // Collect all unique court IDs and names from selections
    Map<String, String> courtsMap = {}; // courtId -> courtName
    multiDateSelections.forEach((key, selection) {
      final courtId = selection['courtId'] as String?;
      final courtName = selection['courtName'] as String?;
      if (courtId != null && courtId.isNotEmpty) {
        courtsMap[courtId] = courtName ?? '';
      }
    });

    List<String> courtIds = courtsMap.keys.toList();
    List<String> courtNames = courtsMap.values.toList();

    // For backward compatibility, use the first court as primary
    String primaryCourtId = courtIds.first;
    String primaryCourtName = courtNames.first;

    // Clear existing controller and create fresh one
    if (Get.isRegistered<DetailsController>()) {
      Get.delete<DetailsController>();
    }
    final detailsController = Get.put(DetailsController());
    
    // Set flag to prevent profile initialization
    detailsController.isFromOpenMatch = true;

    detailsController.localMatchData.update("clubName", (value) => slots.value!.data![0].clubName ?? "");
    detailsController.localMatchData.update("address", (value) => slots.value!.data![0].registerClubId?.address ?? "");
    detailsController.localMatchData.update("clubId", (v) => slots.value!.data![0].registerClubId!.sId ?? "");
    detailsController.localMatchData["ownerId"] = slots.value!.data![0].registerClubId?.ownerId?.sId ?? "";
    detailsController.localMatchData["categoryId"] = categoryId.value;
    detailsController.localMatchData["location"] = locationsId.value;
    detailsController.localMatchData["stateId"] = locationID.value;
    detailsController.localMatchData["paymentOption"] = "payForAll";
    log("CategoryId: ${categoryId.value}, Location: ${locationID.value}, StateId: ${locationsId.value}");
    detailsController.localMatchData.update("matchDate", (v) => selectedDate.value ?? "");
    detailsController.localMatchData.update("clubImage", (v)=> slots.value!.data![0].registerClubId?.courtImage ??[]);
    detailsController.localMatchData.update(
      "matchTime",
          (v) => selectedSlots.map((s) => s.time).toList(),
    );    detailsController.localMatchData.update("price", (v) => totalAmount.toString());
    // Get court types for all selected courts
    final courtTypes = slots.value!.data![0].registerClubId!.courtType ?? [];
    final courts = slots.value?.data ?? [];
    List<String> selectedCourtTypes = [];
    
    // Get court type for each selected court
    for (String courtId in courtIds) {
      int courtIndex = -1;
      for (int i = 0; i < courts.length; i++) {
        if (courts[i].sId == courtId) {
          courtIndex = i;
          break;
        }
      }
      
      if (courtIndex >= 0 && courtIndex < courtTypes.length) {
        selectedCourtTypes.add(courtTypes[courtIndex]);
      } else if (courtTypes.isNotEmpty) {
        selectedCourtTypes.add(courtTypes.first); // fallback
      }
    }
    
    // If single court, send string; if multiple courts, send list
    final courtTypeValue = selectedCourtTypes.length == 1 
        ? selectedCourtTypes.first 
        : selectedCourtTypes;
    
    detailsController.localMatchData.update("courtType", (v) => courtTypeValue);
    // Update slot data with duration, totalTime, and bookingTime from selections
    List<Slots> updatedSlots = [];
    Map<String, Slots> consolidatedSlots = {}; // To merge both halves of 30min slots
    
    for (Slots slot in selectedSlots) {
      // Find the selection data for this slot
      Map<String, dynamic>? leftHalfSelection;
      Map<String, dynamic>? rightHalfSelection;
      
      multiDateSelections.forEach((key, selection) {
        final selectionSlot = selection['slot'] as Slots;
        if (selectionSlot.sId == slot.sId) {
          if (key.endsWith('_L')) {
            leftHalfSelection = selection;
          } else if (key.endsWith('_R')) {
            rightHalfSelection = selection;
          } else {
            // Non-30min selection
            leftHalfSelection = selection;
          }
        }
      });
      
      final supports30Min = slotSupports30Min(slot);
      
      if (supports30Min && leftHalfSelection != null && rightHalfSelection != null) {
        // Both halves selected - treat as one full slot with full price
        if (!consolidatedSlots.containsKey(slot.sId)) {
          consolidatedSlots[slot.sId!] = Slots(
            sId: slot.sId,
            time: slot.time,
            amount: slot.amount, // Use full price when both halves selected
            businessHours: slot.businessHours,
            status: slot.status,
            availabilityStatus: slot.availabilityStatus,
            duration: 60, // Full slot duration
            bookingTime: slot.time ?? '', // Use original time for full slot
          );
        }
      } else {
        // Single half or non-30min selection
        final selectionData = leftHalfSelection ?? rightHalfSelection;
        final adjustedAmount = selectionData?['adjustedAmount'] as int? ?? slot.amount ?? 0;
        final duration = supports30Min && (leftHalfSelection != null || rightHalfSelection != null) ? 30 : 60;
        
        Slots updatedSlot = Slots(
          sId: slot.sId,
          time: slot.time,
          amount: adjustedAmount, // Use adjusted amount (half price for single half, full price for full slot)
          businessHours: slot.businessHours,
          status: slot.status,
          availabilityStatus: slot.availabilityStatus,
          duration: duration,
          bookingTime: selectionData?['bookingTime'] ?? slot.time ?? '',
        );
        updatedSlots.add(updatedSlot);
      }
    }
    
    // Add consolidated full slots
    updatedSlots.addAll(consolidatedSlots.values);
    
    // Convert Slots objects to Map format for questions controller
    final slotsAsMap = updatedSlots.map((slot) {
      final businessHoursList = (slot.businessHours ?? []).map((bh) => {
        "time": bh.time ?? '',
        "day": bh.day ?? '',
      }).toList();
      
      return {
        "slotId": slot.sId ?? '',
        "businessHours": businessHoursList,
        "slotTimes": [{
          "time": slot.bookingTime ?? slot.time ?? '',
          "amount": slot.amount ?? 0,
        }],
        "duration": slot.duration ?? 60,
        "bookingTime": slot.bookingTime ?? slot.time ?? '',
      };
    }).toList();
    
    detailsController.localMatchData.update("slot", (v) => slotsAsMap);
    
    // Use direct assignment for new keys instead of update
    detailsController.localMatchData["courtId"] = primaryCourtId;
    detailsController.localMatchData["courtName"] = primaryCourtName;
    detailsController.localMatchData["courtIds"] = courtIds;
    detailsController.localMatchData["courtNames"] = courtNames;
    detailsController.localMatchData["courtsDetails"] = courtsMap;

    log("Selected Courts: ${courtIds.length}");
    log("Court IDs: $courtIds");
    log("Court Names: $courtNames");
      // Show QuestionsBottomsheetScreen as bottom sheet with match data
      Get.put(QuestionsBottomsheetController(), tag: 'questions');
      Get.find<QuestionsBottomsheetController>(tag: 'questions').localMatchData = detailsController.localMatchData;
      
      Get.bottomSheet(
        QuestionsBottomsheetScreen(),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
      ).then((_) {
        // Cleanup when bottomsheet is closed
        cleanupSlotHistory();
        Get.delete<QuestionsBottomsheetController>(tag: 'questions');
      });
  } 
  void _autoSelectTab() {
    // Don't auto-select if user has manually selected a tab
    if (isManualTabSelection.value) return;
    
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour <= 11 && morningCount.value > 0) {
      selectedTimeOfDay.value = 0; // Morning
    } else if (hour >= 12 && hour <= 17 && noonCount.value > 0) {
      selectedTimeOfDay.value = 1; // Noon
    } else if (hour >= 18 && hour <= 23 && nightCount.value > 0) {
      selectedTimeOfDay.value = 2; // Night
    } else {
      // Fallback: pick first tab that has slots
      if (morningCount.value > 0) {
        selectedTimeOfDay.value = 0;
      } else if (noonCount.value > 0) {
        selectedTimeOfDay.value = 1;
      } else if (nightCount.value > 0) {
        selectedTimeOfDay.value = 2;
      } else {
        selectedTimeOfDay.value = 0; // default
      }
    }

    filterSlotsByTimeOfDay();
  }
  void filterSlotsByTimeOfDay() {
    final tab = selectedTimeOfDay.value;
    final courts = slots.value?.data ?? [];
    for (final court in courts) {
      final courtId = court.sId ?? '';
      final baseList = _originalSlotsCache[courtId] ?? List<Slots>.from(court.slots ?? []);
      court.slots = baseList.where((s) {
        // Only filter out past slots, keep booked future slots
        if (_isPastSlot(s)) return false;
        
        final hour = _parseHour24(s.time);
        if (hour == null) return false;
        if (tab == 0) return hour >= 6 && hour <= 11; // Morning 6-11 am
        if (tab == 1) return hour >= 12 && hour <= 17; // Noon 12-5 pm
        return hour >= 18 && hour <= 23; // Night 6-11 pm
      }).toList();
    }
    _recalculateTimeOfDayCounts();
    slots.refresh();
  }
  void _recalculateTimeOfDayCounts() {
    morningCount.value = 0;
    noonCount.value = 0;
    nightCount.value = 0;
    _originalSlotsCache.forEach((_, list) {
      for (final s in list) {
        // Skip past slots in count, but include booked future slots
        if (_isPastSlot(s)) continue;
        
        final hour = _parseHour24(s.time);
        if (hour == null) continue;
        if (hour >= 6 && hour <= 11) {
          morningCount.value++;
        } else if (hour >= 12 && hour <= 17) {
          noonCount.value++;
        } else if (hour >= 18 && hour <= 23) {
          nightCount.value++;
        }
      }
    });
  }
  int? _parseHour24(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final t = timeStr.trim().toLowerCase();
    try {
      // Try h:mm a first
      final dt = DateFormat('h:mm a').parseStrict(t);
      return dt.hour;
    } catch (_) {
      try {
        final dt = DateFormat('h a').parseStrict(t);
        return dt.hour;
      } catch (_) {
        // Fallback manual parse: "10:30 am" or "10 am"
        final parts = t.split(' ');
        if (parts.length == 2) {
          final isPm = parts[1] == 'pm';
          final hm = parts[0].split(':');
          final h = int.tryParse(hm[0]);
          if (h == null) return null;
          var hour = h % 12;
          if (isPm) hour += 12;
          return hour;
        }
        return null;
      }
    }
  }
  Future<bool> createAndGetSlotHistory(List<Map<String, dynamic>> slots) async {
    try {
      log('createAndGetSlotHistory called with slots: $slots');
      final response = await repository.createAndGetSlotHistory(data: {"slots": slots});
      return true;
    } catch (e) {
      log('Error in createAndGetSlotHistory: $e');
      return false;
    }
  }



  void toggleSlotSelection(Slots slot, {String? courtId, String? courtName, bool? isLeftHalf}) {
    Map<String, String>? resolvedCourtInfo;
    if (courtId != null && courtId.isNotEmpty) {
      final resolvedName = (courtName != null && courtName.isNotEmpty)
          ? courtName
          : _getCourtNameById(courtId);
      resolvedCourtInfo = {
        'courtId': courtId,
        'courtName': resolvedName ?? '',
      };
    } else {
      resolvedCourtInfo = _findCourtInfoForSlot(slot);
    }

    if (resolvedCourtInfo == null) return;

    final slotId = slot.sId ?? '';
    final resolvedCourtId = resolvedCourtInfo['courtId'] ?? '';
    final resolvedCourtName = resolvedCourtInfo['courtName'] ?? '';
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    
    final supports30Min = slotSupports30Min(slot);
    
    final multiDateKey = supports30Min && isLeftHalf != null 
        ? '${dateString}_${resolvedCourtId}_${slotId}_${isLeftHalf ? 'L' : 'R'}'
        : '${dateString}_${resolvedCourtId}_${slotId}';

    if (multiDateSelections.containsKey(multiDateKey)) {
      multiDateSelections.remove(multiDateKey);
      selectedSlots.removeWhere((s) => s.sId == slotId);
      selectedSlotsWithCourtInfo.remove('${resolvedCourtId}_$slotId');
    } else {
      _addSlotGroup(slot, resolvedCourtId, resolvedCourtName, dateString, currentDate, isLeftHalf);
    }

    _recalculateTotalAmount();
    log("Selected ${multiDateSelections.length} slots across multiple dates, Total: ₹${totalAmount.value}");
  }
  /// Check if adding a new slot would violate limits
  bool _canAddSlot() {
    final currentCount = getTotalSelectionsCount(); // Use the consolidated count
    if (currentCount >= maxSlots) {
      // SnackBarUtils.showErrorSnackBar("Booking Limit Reached\nYou can select a maximum of $maxSlots slots.");
      return false;
    }

    // For open matches, we only allow single day selection, so skip the day limit check
    // since we already enforce single date selection in toggleSlotSelection
    return true;
  }

  /// Get unique dates from selections
  Set<String> _getUniqueDates() {
    final Set<String> dates = {};
    multiDateSelections.forEach((key, selection) {
      final dateString = selection['date'] as String;
      dates.add(dateString);
    });
    return dates;
  }

  void _addSlotGroup(Slots primarySlot, String courtId, String courtName, String dateString, DateTime currentDate, bool? isLeftHalf) {
    final slotsToSelect = <Slots>[];
    final supports30Min = slotSupports30Min(primarySlot);
    
    // Find all slots for this court
    final courtData = slots.value?.data?.firstWhere((court) => court.sId == courtId);
    if (courtData?.slots == null) return;
    
    final allSlots = courtData!.slots!;
    final primarySlotIndex = allSlots.indexWhere((s) => s.sId == primarySlot.sId);
    if (primarySlotIndex == -1) return;
    
    // For slots that support 30-minute pricing, allow half-slot selection
    if (supports30Min && isLeftHalf != null) {
      slotsToSelect.add(primarySlot);
    } else {
      // For slots that don't support 30-minute pricing, always select full slot (60 minutes)
      slotsToSelect.add(primarySlot);
    }
    
    // Check limits before adding - but only if this would be a new slot
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final slotId = primarySlot.sId ?? '';
    
    // Check if this slot is already partially selected
    final leftKey = '${dateString}_${courtId}_${slotId}_L';
    final rightKey = '${dateString}_${courtId}_${slotId}_R';
    final fullKey = '${dateString}_${courtId}_${slotId}';
    
    final isSlotAlreadySelected = multiDateSelections.containsKey(leftKey) || 
                                  multiDateSelections.containsKey(rightKey) || 
                                  multiDateSelections.containsKey(fullKey);
    
    if (!isSlotAlreadySelected && getTotalSelectionsCount() >= maxSlots) {
      // SnackBarUtils.showErrorSnackBar("Booking Limit Reached\nYou can select a maximum of $maxSlots slots.");
      return;
    }
    
    // Check if this selection maintains consecutive slots
    if (!isSlotAlreadySelected && !_isConsecutiveSelectionAllowed(courtId, slotId, dateString)) {
      // SnackBarUtils.showErrorSnackBar("Please select consecutive time slots only.");
      return;
    }
    
    for (int i = 0; i < slotsToSelect.length; i++) {
      final slotToAdd = slotsToSelect[i];
      final slotKey = supports30Min && isLeftHalf != null 
          ? '${dateString}_${courtId}_${slotToAdd.sId}_${isLeftHalf ? 'L' : 'R'}'
          : '${dateString}_${courtId}_${slotToAdd.sId}';
      final compositeKey = '${courtId}_${slotToAdd.sId}';
      
      // Calculate booking time for 30-minute slots that support it
      String bookingTime = slotToAdd.time ?? '';
      int adjustedAmount = slotToAdd.amount ?? 0;
      
      if (supports30Min && isLeftHalf != null) {
        if (isLeftHalf) {
          // Left half: use original time and half the price
          bookingTime = slotToAdd.time ?? '';
          adjustedAmount = (slotToAdd.amount ?? 0) ~/ 2;
          log('Left half selected - bookingTime: $bookingTime, price: $adjustedAmount');
        } else {
          // Right half: add 30 minutes and half the price
          final originalTime = slotToAdd.time ?? '';
          bookingTime = _addMinutesToTime(originalTime, 30);
          adjustedAmount = (slotToAdd.amount ?? 0) ~/ 2;
          log('Right half selected - original: $originalTime, calculated bookingTime: $bookingTime, price: $adjustedAmount');
        }
      }
      
      multiDateSelections[slotKey] = {
        'slot': slotToAdd,
        'courtId': courtId,
        'courtName': courtName,
        'date': dateString,
        'dateTime': currentDate,
        'bookingTime': bookingTime,
        'isLeftHalf': isLeftHalf,
        'adjustedAmount': adjustedAmount,
      };
      
      if (!selectedSlots.any((s) => s.sId == slotToAdd.sId)) {
        selectedSlots.add(slotToAdd);
      }
      selectedSlotsWithCourtInfo[compositeKey] = {
        'slot': slotToAdd,
        'courtId': courtId,
        'courtName': courtName,
        'bookingTime': bookingTime,
        'adjustedAmount': adjustedAmount,
      };
    }
  }
  
  void _removeSlotGroup(Slots primarySlot, String courtId, String dateString) {
    final supports30Min = slotSupports30Min(primarySlot);
    
    // Find all slots for this court
    final courtData = slots.value?.data?.firstWhere((court) => court.sId == courtId);
    if (courtData?.slots == null) return;
    
    final allSlots = courtData!.slots!;
    final primarySlotIndex = allSlots.indexWhere((s) => s.sId == primarySlot.sId);
    if (primarySlotIndex == -1) return;
    
    // For slots that support 30-minute pricing, remove both left and right half keys
    if (supports30Min) {
      final leftKey = '${dateString}_${courtId}_${primarySlot.sId}_L';
      final rightKey = '${dateString}_${courtId}_${primarySlot.sId}_R';
      
      multiDateSelections.remove(leftKey);
      multiDateSelections.remove(rightKey);
      
      selectedSlots.removeWhere((s) => s.sId == primarySlot.sId);
      final compositeKey = '${courtId}_${primarySlot.sId}';
      selectedSlotsWithCourtInfo.remove(compositeKey);
    } else {
      // For slots that don't support 30-minute pricing, remove the full slot
      final slotKey = '${dateString}_${courtId}_${primarySlot.sId}';
      final compositeKey = '${courtId}_${primarySlot.sId}';
      
      multiDateSelections.remove(slotKey);
      selectedSlots.removeWhere((s) => s.sId == primarySlot.sId);
      selectedSlotsWithCourtInfo.remove(compositeKey);
    }
  }
  // Check if the same time slot is already selected in a different court
  bool _hasTimeConflictAcrossCourts(String? slotTime, String currentCourtId, String dateString) {
    if (slotTime == null || slotTime.isEmpty) return false;
    
    for (final entry in multiDateSelections.entries) {
      final selection = entry.value;
      final existingDate = selection['date'] as String;
      final existingCourtId = selection['courtId'] as String;
      final existingSlot = selection['slot'] as Slots;
      
      // Check if same date, different court, and same time
      if (existingDate == dateString && 
          existingCourtId != currentCourtId && 
          existingSlot.time == slotTime) {
        return true;
      }
    }
    return false;
  }

  // Validate that all selected slots form one continuous time block
  bool _isConsecutiveSelectionAllowed(String courtId, String slotId, String dateString) {
    // Get all existing unique slot times for the same date
    final Set<String> existingSlotTimes = {};
    multiDateSelections.forEach((key, selection) {
      if (selection['date'] == dateString) {
        final slot = selection['slot'] as Slots;
        if (slot.time != null) existingSlotTimes.add(slot.time!);
      }
    });

    // If no existing selections, allow first selection
    if (existingSlotTimes.isEmpty) return true;

    // Get the candidate slot details
    final candidateSlot = _getSlotById(courtId, slotId);
    if (candidateSlot == null) return false;
    if (candidateSlot.time == null) return false;

    // Create a list of all slot times (existing + candidate)
    final allTimes = existingSlotTimes.toList()..add(candidateSlot.time!);

    // Convert times to comparable format and sort
    final List<int> timeMinutes = [];
    for (final timeStr in allTimes) {
      final minutes = _convertTimeToMinutes(timeStr);
      if (minutes != null) timeMinutes.add(minutes);
    }
    
    if (timeMinutes.length != allTimes.length) return false; // Some times couldn't be parsed
    
    timeMinutes.sort();

    // Check if all times are consecutive (60-minute intervals)
    for (int i = 1; i < timeMinutes.length; i++) {
      if (timeMinutes[i] - timeMinutes[i - 1] != 60) {
        return false; // Gap found
      }
    }
    
    return true;
  }

  // Helper method to get slot by ID from a specific court
  Slots? _getSlotById(String courtId, String slotId) {
    final courts = slots.value?.data ?? [];
    for (final court in courts) {
      if (court.sId == courtId) {
        final courtSlots = _originalSlotsCache[courtId] ?? court.slots ?? [];
        for (final slot in courtSlots) {
          if (slot.sId == slotId) return slot;
        }
      }
    }
    return null;
  }

  // Helper method to convert time string to minutes since midnight
  int? _convertTimeToMinutes(String timeStr) {
    try {
      final cleanTime = timeStr.trim().toLowerCase();
      
      // Try parsing with DateFormat first
      DateTime? parsed;
      for (final pattern in const ['h:mm a', 'h a', 'HH:mm', 'H:mm']) {
        try {
          parsed = DateFormat(pattern).parseStrict(cleanTime);
          break;
        } catch (_) {}
      }
      
      if (parsed != null) {
        return parsed.hour * 60 + parsed.minute;
      }
      
      // Fallback manual parsing
      final parts = cleanTime.split(' ');
      String timePart = parts[0];
      String? meridiem = parts.length > 1 ? parts[1] : null;
      
      final timePieces = timePart.split(':');
      int hour = int.tryParse(timePieces[0]) ?? 0;
      int minute = timePieces.length > 1 ? int.tryParse(timePieces[1]) ?? 0 : 0;
      
      if (meridiem == 'pm' && hour != 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      
      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  // Get the index of a slot within the base slot list for a court
  int _getSlotIndexInCourt(String courtId, String slotId) {
    final List<Slots> baseList = _originalSlotsCache[courtId] ?? [];
    for (int i = 0; i < baseList.length; i++) {
      if (baseList[i].sId == slotId) return i;
    }
    // As a fallback, try the currently shown (possibly time-filtered) slots list
    final data = slots.value?.data ?? [];
    final court = data.firstWhereOrNull((c) => c.sId == courtId);
    final currentList = court?.slots ?? [];
    for (int i = 0; i < currentList.length; i++) {
      if (currentList[i].sId == slotId) return i;
    }
    return -1;
  }

// Replace your existing _clearCurrentDateSelections method with this:
  void clearCurrentDateSelections() {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    // Remove selections for current date only
    multiDateSelections.removeWhere((key, value) => key.startsWith(dateString));

    // Rebuild legacy collections based on currently selected date
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();

    // Only add back slots that belong to the current date
    multiDateSelections.forEach((key, selection) {
      if (key.startsWith(dateString)) {
        final slot = selection['slot'] as Slots;
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final compositeKey = '${courtId}_${slot.sId}';

        if (!selectedSlots.any((s) => s.sId == slot.sId)) {
          selectedSlots.add(slot);
        }
        selectedSlotsWithCourtInfo[compositeKey] = {
          'slot': slot,
          'courtId': courtId,
          'courtName': courtName,
        };
      }
    });
  }

// NEW: Method to sync the legacy collections with current date selections
  void _syncLegacyCollectionsWithCurrentDate() {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    // Clear legacy collections
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();

    // Populate them with current date's selections only
    multiDateSelections.forEach((key, selection) {
      if (key.startsWith(dateString)) {
        final slot = selection['slot'] as Slots;
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final compositeKey = '${courtId}_${slot.sId}';

        if (!selectedSlots.any((s) => s.sId == slot.sId)) {
          selectedSlots.add(slot);
        }
        selectedSlotsWithCourtInfo[compositeKey] = {
          'slot': slot,
          'courtId': courtId,
          'courtName': courtName,
        };
      }
    });

    // Recalculate total for current view
    _recalculateTotalAmount();
  }

  Future<void> getAvailableCourtsById(String clubId, {bool showUnavailable = false}) async {
    log("=== DEBUG API CALL ===");
    log("Fetching courts for club: $clubId");
    log("Selected date: ${selectedDate.value}");
    log("Show unavailable: $showUnavailable");

    isLoadingCourts.value = true;

    try {
      final date = selectedDate.value ?? DateTime.now();
      final formattedDay = _getWeekday(date.weekday);
      final formattedDate = _dateFormatter.format(date);

      log("Formatted day: $formattedDay");
      log("Formatted date: $formattedDate");
      log("Club ID: $clubId");

      final result = await repository.fetchAvailableCourtsSlotWise(
        day: formattedDay,
        registerClubId: clubId,
        date: formattedDate,
        sID: sId.value,
        categoryId: categoryId.value,
        location: locationID.value,
        locId: locationsId.value
      );

      // Debug: Log booking times from API
      log("=== DEBUG BOOKING TIMES ===");
      for (var court in result.data ?? []) {
        for (var slot in court.slots ?? []) {
          if (slot.bookingTime != null && slot.bookingTime!.isNotEmpty) {
            log("Slot time: '${slot.time}', bookingTime: '${slot.bookingTime}'");
            log("Normalized slot time: '${_normalizeTime(slot.time ?? '')}'");
            log("Normalized booking time: '${_normalizeTime(slot.bookingTime!)}'");
            log("Left half booked: ${isLeftHalfBooked(slot)}");
            log("Right half booked: ${isRightHalfBooked(slot)}");
            log("Status: ${slot.status}");
            log("---");
          }
        }
      }

      // Update slot prices from fetchAllSlotPrices API
      _updateSlotPrices(result, formattedDay);

      // Store ALL slots (both available and unavailable)
      _allSlotsCache.clear();
      for (var court in result.data ?? []) {
        _allSlotsCache[court.sId ?? ''] = List<Slots>.from(court.slots ?? []);
      }

      // Apply filtering based on toggle
      for (var court in result.data ?? []) {
        final base = _allSlotsCache[court.sId ?? ''] ?? [];
        if (showUnavailable) {
          // Show BOTH available and unavailable
          court.slots = List<Slots>.from(base);
        } else {
          // Show only available
          court.slots = base.where((s) => _isAvailableSlot(s)).toList();
        }
      }

      slots.value = result;

      // Build original cache from filtered slots for time-of-day filtering
      _originalSlotsCache.clear();
      final courts = slots.value?.data ?? [];
      for (final court in courts) {
        _originalSlotsCache[court.sId ?? ''] = List<Slots>.from(court.slots ?? []);
      }
      _recalculateTimeOfDayCounts();

      filterSlotsByTimeOfDay();
      _autoSelectTab();

    } catch (e, stackTrace) {
      log("Error occurred: $e");
      log("Stack trace: $stackTrace");
      slots.value = null;

      // Get.snackbar(
      //   "Error",
      //   "Failed to load courts. Please try again.",
      //   backgroundColor: Colors.redAccent,
      //   colorText: Colors.white,
      //   snackPosition: SnackPosition.TOP,
      // );
    } finally {
      isLoadingCourts.value = false;
    }
  }

  void _recalculateTotalAmount() {
    int total = 0;
    multiDateSelections.forEach((key, selection) {
      // Use adjusted amount if available, otherwise use original slot amount
      final adjustedAmount = selection['adjustedAmount'] as int?;
      if (adjustedAmount != null) {
        total += adjustedAmount;
      } else {
        final slot = selection['slot'] as Slots;
        total += slot.amount ?? 0;
      }
    });
    totalAmount.value = total;
  }

  /// Find court information for a given slot
  Map<String, String>? _findCourtInfoForSlot(Slots targetSlot) {
    final data = slots.value?.data ?? [];

    for (var courtData in data) {
      final slotsList = courtData.slots ?? [];
      final hasSlot = slotsList.any((s) => s.sId == targetSlot.sId);

      if (hasSlot) {
        return {
          'courtId': courtData.sId ?? '',
          'courtName': courtData.courtName ?? '',
        };
      }
    }
    return null;
  }

  String? _getCourtNameById(String courtId) {
    final data = slots.value?.data ?? [];
    for (var courtData in data) {
      if (courtData.sId == courtId) {
        return courtData.courtName ?? '';
      }
    }
    return null;
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  // Check if slot is in the past (for filtering)
  bool _isPastSlot(Slots slot) {
    final rawTime = slot.time;
    if (rawTime == null || rawTime.trim().isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final selected = selectedDate.value ?? now;

    try {
      final timeString = rawTime.toLowerCase().trim();

      DateTime? parsed;
      for (final pattern in const ['h:mm a', 'h a', 'HH:mm', 'H:mm', 'HH']) {
        try {
          parsed = DateFormat(pattern).parseStrict(timeString);
          break;
        } catch (_) {}
      }

      int hour;
      int minute;
      if (parsed != null) {
        hour = parsed.hour;
        minute = parsed.minute;
      } else {
        String t = timeString;
        String meridiem = '';
        final parts = t.split(' ');
        if (parts.length == 2) {
          t = parts[0];
          meridiem = parts[1];
        }
        final timePieces = t.split(':');
        hour = int.tryParse(timePieces[0]) ?? 0;
        minute = timePieces.length > 1 ? int.tryParse(timePieces[1]) ?? 0 : 0;
        if (meridiem == 'pm' && hour != 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
      }

      final slotDateTime = DateTime(
        selected.year,
        selected.month,
        selected.day,
        hour,
        minute,
      );

      final isToday = selected.year == now.year &&
          selected.month == now.month &&
          selected.day == now.day;

      if (isToday && now.isAfter(slotDateTime)) {
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  bool isPastAndUnavailable(Slots slot) {
    // Check if slot is in the past
    if (_isPastSlot(slot)) return true;
    
    // Check for maintenance/weather/staff unavailability
    final availability = _normalizeStatus(slot.availabilityStatus);
    if (availability == "maintenance" ||
        availability == "weather conditions" ||
        availability == "staff unavailability") {
      return true;
    }
    
    return false;
  }

  // Helper: determine if a slot should be considered unavailable (past, booked, or blocked)
  bool _isUnavailableSlot(Slots slot) {
    final availability = _normalizeStatus(slot.availabilityStatus);
    final isBlocked = availability == "maintenance" ||
        availability == "weather conditions" ||
        availability == "staff unavailability";
    final isBooked = (_normalizeStatus(slot.status) == 'booked');
    final isPast = isPastAndUnavailable(slot);
    return isPast || isBlocked || isBooked;
  }

  // Helper: available when not unavailable and status is available/empty
  bool _isAvailableSlot(Slots slot) {
    final status = _normalizeStatus(slot.status);
    return !_isUnavailableSlot(slot) && (status == 'available' || status.isEmpty);
  }

  // Normalize status/availability strings to avoid case and whitespace issues
  String _normalizeStatus(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  var cartLoader = false.obs;

  void addToCart() async {
    try {
      if (cartLoader.value) return;
      cartLoader.value = true;

      if (multiDateSelections.isEmpty) {
        // Get.snackbar(
        //   "No Slots Selected",
        //   "Please select at least one slot before adding to cart.",
        //   backgroundColor: Colors.redAccent,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.TOP,
        // );
        return;
      }

      // Group by date and club
      final Map<String, Map<String, dynamic>> groupedByDate = {};

      multiDateSelections.forEach((key, selection) {
        final slot = selection['slot'] as Slots;
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final dateString = selection['date'] as String;
        final dateTime = selection['dateTime'] as DateTime;
        final clubId = argument.id!;

        // Create date-specific key
        final dateKey = '${dateString}_$clubId';

        if (!groupedByDate.containsKey(dateKey)) {
          groupedByDate[dateKey] = {
            "slot": [],
            "register_club_id": clubId,
            "date": dateString,
            "dateTime": dateTime,
          };
        }

        final slotEntry = {
          "businessHours": slot.businessHours
              ?.map((bh) => {
            "time": bh.time,
            "day": bh.day,
          })
              .toList(),
          "slotTimes": [
            {
              "time": slot.time,
              "amount": slot.amount,
              "slotId": slot.sId,
            },
            {
              "bookingDate": dateString,
            },
            {
              "courtId": courtId,
            },
            {
              "courtName": courtName,
            }
          ]
        };

        (groupedByDate[dateKey]!["slot"] as List).add(slotEntry);
      });

      // Convert to final payload format (grouped by date)
      final List<Map<String, dynamic>> cartPayload = groupedByDate.values
          .map((dateGroup) => {
        "slot": dateGroup["slot"],
        "register_club_id": dateGroup["register_club_id"],
      })
          .toList();

      log("Multi-Date Cart Payload: $cartPayload");

      await cartRepository.addCartItems(data: cartPayload).then((v) async {
        final CartController controller = Get.find<CartController>();
        await controller.getCartItems();

        Get.to(() => CartScreen(buttonType: "true"))?.then((_) async {
          // Clear all selections
          multiDateSelections.clear();
          selectedSlots.clear();
          selectedSlotsWithCourtInfo.clear();
          totalAmount.value = 0;
          await getAvailableCourtsById(argument.id!);
        });
      });
    } on DioException catch (e) {
      final dynamic data = e.response?.data;
      final serverMessage =
      (data is Map && data['message'] is String) ? data['message'] as String : null;
      final detailed = serverMessage ?? e.message ?? 'Something went wrong.';
      log("Add to cart failed (Dio): status=${e.response?.statusCode}, data=${e.response?.data}");
      // Get.snackbar(
      //   "Error",
      //   detailed,
      //   backgroundColor: Colors.redAccent,
      //   colorText: Colors.white,
      //   snackPosition: SnackPosition.TOP,
      // );
    } catch (e) {
      log("Error adding to cart: $e");
      // Get.snackbar(
      //   "Error",
      //   "Failed to add slots to cart. Please try again.",
      //   backgroundColor: Colors.redAccent,
      //   colorText: Colors.white,
      //   snackPosition: SnackPosition.TOP,
      // );
    } finally {
      cartLoader.value = false;
    }
  }

  List<dynamic> getAllCourts() {
    return slots.value?.data ?? [];
  }

  bool isSlotSelected(Slots slot, String courtId) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final supports30Min = slotSupports30Min(slot);
    
    if (supports30Min) {
      // For slots that support 30min pricing, only return true if BOTH halves are selected
      final leftKey = '${dateString}_${courtId}_${slot.sId}_L';
      final rightKey = '${dateString}_${courtId}_${slot.sId}_R';
      return multiDateSelections.containsKey(leftKey) && multiDateSelections.containsKey(rightKey);
    } else {
      final multiDateKey = '${dateString}_${courtId}_${slot.sId}';
      return multiDateSelections.containsKey(multiDateKey);
    }
  }

  bool isPartOfSelectedGroup(Slots slot, String courtId) {
    final supports30Min = slotSupports30Min(slot);
    if (!supports30Min) return false; // No group selection for slots that don't support 30min pricing
    
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final currentSlotKey = '${dateString}_${courtId}_${slot.sId}';
    
    // If this slot is already selected, check if it's part of a group
    if (multiDateSelections.containsKey(currentSlotKey)) {
      return true;
    }
    
    return false;
  }

  bool isSlotDisabled(Slots slot, String courtId) {
    // If slot is already selected, it's not disabled
    if (isSlotSelected(slot, courtId)) return false;
    
    // If 3 slots are already selected, disable all other slots
    return multiDateSelections.length >= 3;
  }

  int getSelectedSlotsCountForCourt(String courtId) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);

    return multiDateSelections.keys.where((key) =>
    key.startsWith(dateString) && key.contains('_${courtId}_')
    ).length;
  }

  int getTotalAmountForCourt(String courtId) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);

    int total = 0;
    multiDateSelections.forEach((key, selection) {
      if (key.startsWith(dateString) && key.contains('_${courtId}_')) {
        final slot = selection['slot'] as Slots;
        total += slot.amount ?? 0;
      }
    });
    return total;
  }

  // NEW: Get total selections across all dates - count consolidated slots properly
  int getTotalSelectionsCount() {
    final Map<String, Set<String>> consolidatedSlots = {}; // date -> set of slotIds
    
    multiDateSelections.forEach((key, selection) {
      final dateString = selection['date'] as String;
      final slot = selection['slot'] as Slots;
      final slotId = slot.sId ?? '';
      
      if (!consolidatedSlots.containsKey(dateString)) {
        consolidatedSlots[dateString] = <String>{};
      }
      
      // Add the slot ID to the set (automatically handles duplicates for half-slots)
      consolidatedSlots[dateString]!.add(slotId);
    });
    
    // Count total unique slots across all dates
    int totalCount = 0;
    consolidatedSlots.forEach((date, slotIds) {
      totalCount += slotIds.length;
    });
    
    return totalCount;
  }

  // NEW: Get selections grouped by date
  Map<String, List<Map<String, dynamic>>> getSelectionsByDate() {
    final Map<String, List<Map<String, dynamic>>> result = {};
    multiDateSelections.forEach((key, selection) {
      final dateString = selection['date'] as String;
      if (!result.containsKey(dateString)) {
        result[dateString] = [];
      }
      result[dateString]!.add(selection);
    });
    return result;
  }

  // NEW: Clear all selections (useful for reset functionality)
  void clearAllSelections() {
    multiDateSelections.clear();
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    totalAmount.value = 0;
  }

  /// Check if left half of a 30-minute slot is booked
  bool isLeftHalfBooked(Slots slot) {
    if (slot.bookingTime == null || slot.bookingTime!.isEmpty) return false;
    
    final originalTime = slot.time ?? '';
    final bookingTime = slot.bookingTime!;
    
    // Check duration from API - if 60, whole slot is booked
    if (slot.duration == 60) return true;
    
    // If duration is 30, check booking time to determine which half
    if (slot.duration == 30) {
      // If booking time equals original time (e.g., both are "5:00 PM"), left half is booked
      return _normalizeTime(bookingTime) == _normalizeTime(originalTime);
    }
    
    // Fallback to original logic
    return _normalizeTime(bookingTime) == _normalizeTime(originalTime);
  }

  /// Check if right half of a 30-minute slot is booked
  bool isRightHalfBooked(Slots slot) {
    if (slot.bookingTime == null || slot.bookingTime!.isEmpty) return false;
    
    final originalTime = slot.time ?? '';
    final bookingTime = slot.bookingTime!;
    
    // Check duration from API - if 60, whole slot is booked
    if (slot.duration == 60) return true;
    
    // If duration is 30, check booking time to determine which half
    if (slot.duration == 30) {
      // If booking time is 30 minutes after original time (e.g., "5:30 PM" vs "5:00 PM"), right half is booked
      final expectedRightTime = _addMinutesToTime(originalTime, 30);
      return _normalizeTime(bookingTime) == _normalizeTime(expectedRightTime);
    }
    
    // Fallback to original logic
    final expectedRightTime = _addMinutesToTime(originalTime, 30);
    return _normalizeTime(bookingTime) == _normalizeTime(expectedRightTime);
  }

  /// Check if both halves of a slot are selected (only for slots that support 30-minute pricing)
  bool isBothHalvesSelected(Slots slot, String courtId) {
    if (!slotSupports30Min(slot)) return false;
    
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final leftKey = '${dateString}_${courtId}_${slot.sId}_L';
    final rightKey = '${dateString}_${courtId}_${slot.sId}_R';
    return multiDateSelections.containsKey(leftKey) && multiDateSelections.containsKey(rightKey);
  }

  /// Normalize time format for comparison (convert to consistent format)
  String _normalizeTime(String timeString) {
    try {
      // Try parsing and reformatting to ensure consistent format
      final upperTime = timeString.trim().toUpperCase();
      final time = DateFormat('h a').parseStrict(upperTime);
      return DateFormat('h:mm a').format(time);
    } catch (_) {
      try {
        final time = DateFormat('h:mm a').parseStrict(timeString.trim());
        return DateFormat('h:mm a').format(time);
      } catch (_) {
        return timeString.trim().toUpperCase();
      }
    }
  }

  /// Add minutes to a time string (e.g., "3:00 PM" + 30 minutes = "3:30 PM")
  String _addMinutesToTime(String timeString, int minutesToAdd) {
    log('_addMinutesToTime: input="$timeString", adding $minutesToAdd minutes');
    try {
      final cleanTime = timeString.trim();
      DateTime? parsedTime;
      
      // Try different parsing formats
      final formats = ['h:mm a', 'h a', 'H:mm', 'HH:mm'];
      
      for (final format in formats) {
        try {
          parsedTime = DateFormat(format).parseStrict(cleanTime);
          log('_addMinutesToTime: successfully parsed with format "$format"');
          break;
        } catch (_) {
          // Try with case-insensitive parsing
          try {
            parsedTime = DateFormat(format).parseStrict(cleanTime.toUpperCase());
            log('_addMinutesToTime: successfully parsed with uppercase format "$format"');
            break;
          } catch (_) {
            continue;
          }
        }
      }
      
      if (parsedTime != null) {
        final newTime = parsedTime.add(Duration(minutes: minutesToAdd));
        final result = DateFormat('h:mm a').format(newTime);
        log('_addMinutesToTime: final result="$result"');
        return result;
      }
      
      log('_addMinutesToTime: all parsing failed, returning original');
      return timeString;
    } catch (e) {
      log('_addMinutesToTime: error occurred: $e, returning original');
      return timeString;
    }
  }

  // Variables to store fetched slot prices
  var allSlotPricesResponse = Rxn<GetAllSlotPricesOfCourtModel>();
  var isSlotPricesLoading = false.obs;
  final Map<String, Map<String, int>> slotPricesData = {}; // day -> {duration -> price}
  final Map<String, Map<String, int>> originalSlotPricesData = {}; // Track original prices
  
  ///Fetch All Slot Prices------------------------------------------------------
  Future<void> fetchAllSlotPrices() async {
    try {
      isSlotPricesLoading.value = true;

      final result = await repository.getAllSlotPricesOfCourt(
        registerClubId: argument.id!,
        duration: '', // Get all durations
        day: '', // Get all days
        timePeriod: '', // Get all time periods
        categoryId: categoryId.value,
        locationId: locationID.value,
        lockId: locationsId.value
      );

      allSlotPricesResponse.value = result;

      // Clear existing data
      slotPricesData.clear();
      originalSlotPricesData.clear();

      // Parse and store the data
      if (result.data?.isNotEmpty ?? false) {
        for (final item in result.data!) {
          final day = item.day;
          final duration = item.duration?.toString();
          final price = item.price ?? 0;

          if (day != null && duration != null) {
            slotPricesData[day] ??= {};
            slotPricesData[day]![duration] = price;

            // Store original prices
            originalSlotPricesData[day] ??= {};
            originalSlotPricesData[day]![duration] = price;
          }
        }
      }

      CustomLogger.logMessage(
        msg: "Fetched slot prices for all periods: $slotPricesData",
        level: LogLevel.info,
      );

    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching slot prices: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
    } finally {
      isSlotPricesLoading.value = false;
    }
  }

  /// Update slot prices from fetchAllSlotPrices API
  void _updateSlotPrices(GetAllActiveCourtsForSlotWiseModel result, String day) {
    if (result.data == null) return;
    
    for (var court in result.data!) {
      if (court.slots == null) continue;
      
      for (var slot in court.slots!) {
        final slotTime = slot.time;
        if (slotTime == null) continue;
        
        // For create_open_matches, we only use 60min pricing
        final slotPrice = _findPriceForSlot(slotTime, day, 60);
        
        if (slotPrice != null) {
          slot.amount = slotPrice;
        }
      }
    }
  }
  
  /// Find price for a specific slot time from fetchAllSlotPrices data
  int? _findPriceForSlot(String slotTime, String day, int duration) {
    final slotPrices = allSlotPricesResponse.value?.data;
    if (slotPrices == null) return null;
    
    // Parse slot time to 24-hour format
    final slotHour = _parseHour24(slotTime);
    if (slotHour == null) return null;
    
    // Find matching price entry
    for (final priceEntry in slotPrices) {
      if (priceEntry.day != day || priceEntry.duration != duration) continue;
      
      final slotTimeRange = priceEntry.slotTime;
      if (slotTimeRange == null) continue;
      
      // Check if slot time falls within the price range
      if (_isTimeInRange(slotHour, slotTimeRange)) {
        return priceEntry.price;
      }
    }
    
    return null;
  }
  
  /// Find price by date string (converts date string to day name)
  int? _findPriceForSlotByDate(String slotTime, String dateString, int duration) {
    try {
      final date = DateTime.parse(dateString);
      final dayName = _getWeekday(date.weekday);
      return _findPriceForSlot(slotTime, dayName, duration);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if a time falls within a time range (e.g., "6:00 AM - 11:00 AM")
  bool _isTimeInRange(int slotHour, String timeRange) {
    try {
      final parts = timeRange.split(' - ');
      if (parts.length != 2) return false;
      
      final startHour = _parseHour24(parts[0].trim());
      final endHour = _parseHour24(parts[1].trim());
      
      if (startHour == null || endHour == null) return false;
      
      // Handle cases where end time is inclusive (e.g., 6 AM - 11 AM includes 11 AM)
      return slotHour >= startHour && slotHour <= endHour;
    } catch (e) {
      return false;
    }
  }

  /// Helper methods for left/right half selection
  bool isLeftHalfSelected(Slots slot, String courtId) {
    if (!slotSupports30Min(slot)) return false;
    
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final leftKey = '${dateString}_${courtId}_${slot.sId}_L';
    return multiDateSelections.containsKey(leftKey);
  }

  bool isRightHalfSelected(Slots slot, String courtId) {
    if (!slotSupports30Min(slot)) return false;
    
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final rightKey = '${dateString}_${courtId}_${slot.sId}_R';
    return multiDateSelections.containsKey(rightKey);
  }


}