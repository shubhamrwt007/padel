import 'package:get/get.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/data/response_models/get_all_slot_prices_of_court_model.dart';
import 'package:padel_mobile/data/response_models/get_courts_by_duration_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/booking/open_matches/questions_bottomsheet/questions_bottomsheet_controller.dart';
import 'package:padel_mobile/presentations/booking/open_matches/questions_bottomsheet/questions_bottomsheet_screen.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import '../../../../data/request_models/home_models/get_available_court.dart';

class CreateOpenMatchForAllCourtsController extends GetxController {
  final HomeRepository _homeRepository = HomeRepository();

  ///Available Slots------------------------------------------------------------
  // Remove duration selection - always use 60 min
  final selectedDuration = '60 min'.obs;

  ///Available Clubs------------------------------------------------------------
  final expandedIndex = (-1).obs;
  void toggle(int index) {
    expandedIndex.value = expandedIndex.value == index ? -1 : index;
  }

  ///Available Slots Collapse/Expand------------------------------------------------------------
  RxBool isSlotsCollapsed = false.obs;
  RxnString selectedSearchSlotId = RxnString();
  RxBool showMainGrid = true.obs; // New variable to control main grid visibility

  void toggleSlotsCollapse() async {
    isSlotsCollapsed.value = !isSlotsCollapsed.value;
    showMainGrid.value = !showMainGrid.value; // Toggle main grid visibility
    
    // If reopening the main grid, delete slot history
    if (showMainGrid.value && realCourtSelections.isNotEmpty) {
      await _cleanupOnBack();
    }
  }

  // Method to fetch clubs and hide main grid
  void fetchClubs() {
    if (multiDateSelections.isEmpty) {
      Get.snackbar(
        "No Selection",
        "Please select at least one slot to continue.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    showMainGrid.value = false; // Hide main grid
    fetchCourtsIfReady(); // Hit the API
  }

  final selectedDate = Rxn<DateTime>();
  Rx<DateTime> focusedMonth = DateTime.now().obs;

  RxBool showUnavailableSlots = false.obs;

  // Cache base slot lists
  final Map<String, List<Slots>> _originalSlotsCache = {};

  RxList<Slots> selectedSlots = <Slots>[].obs;

  // Multi-date selections - key format: "date_courtId_slotId"
  RxMap<String, Map<String, dynamic>> multiDateSelections = <String, Map<String, dynamic>>{}.obs;

  // Real court selections from availableCourts (for payment panel)
  RxMap<String, Map<String, dynamic>> realCourtSelections = <String, Map<String, dynamic>>{}.obs;

  RxInt totalAmount = 0.obs;
  Rx<GetAllActiveCourtsForSlotWiseModel?> slots = Rx<GetAllActiveCourtsForSlotWiseModel?>(null);
  RxBool isLoadingCourts = false.obs;

  // Courts by duration data
  Rx<GetCourtsByDurationModel?> courtsByDuration = Rx<GetCourtsByDurationModel?>(null);
  RxBool isLoadingCourtsByDuration = false.obs;
  RxString selectedTimeSlot = ''.obs;

  // Variables to store fetched slot prices
  var allSlotPricesResponse = Rxn<GetAllSlotPricesOfCourtModel>();
  var isSlotPricesLoading = false.obs;
  final Map<String, Map<String, int>> slotPricesData = {}; // day -> {duration -> price}
  final Map<String, Map<String, int>> originalSlotPricesData = {}; // Track original prices
  @override
  void onInit() {
    super.onInit();
    selectedDate.value = DateTime.now();
    _initializeMockData();
  }

  void _initializeMockData() {
    slots.value = GetAllActiveCourtsForSlotWiseModel(
      data: [
        Data(
          sId: 'court1',
          courtName: '',
          clubName: 'Sample Club',
          slots: [
            Slots(sId: 'slot1', time: '6:00 AM', amount: 400, status: 'available'),
            Slots(sId: 'slot2', time: '7:00 AM', amount: 400, status: 'available'),
            Slots(sId: 'slot3', time: '8:00 AM', amount: 500, status: 'available'),
            Slots(sId: 'slot4', time: '9:00 AM', amount: 500, status: 'available'),
            Slots(sId: 'slot5', time: '10:00 AM', amount: 500, status: 'available'),
            Slots(sId: 'slot6', time: '11:00 AM', amount: 500, status: 'available'),
            Slots(sId: 'slot7', time: '12:00 PM', amount: 600, status: 'available'),
            Slots(sId: 'slot8', time: '1:00 PM', amount: 600, status: 'available'),
            Slots(sId: 'slot9', time: '2:00 PM', amount: 600, status: 'available'),
            Slots(sId: 'slot10', time: '3:00 PM', amount: 600, status: 'available'),
            Slots(sId: 'slot11', time: '4:00 PM', amount: 600, status: 'available'),
            Slots(sId: 'slot12', time: '5:00 PM', amount: 600, status: 'available'),
            Slots(sId: 'slot13', time: '6:00 PM', amount: 700, status: 'available'),
            Slots(sId: 'slot14', time: '7:00 PM', amount: 700, status: 'available'),
            Slots(sId: 'slot15', time: '8:00 PM', amount: 700, status: 'available'),
            Slots(sId: 'slot16', time: '9:00 PM', amount: 700, status: 'available'),
            Slots(sId: 'slot17', time: '10:00 PM', amount: 700, status: 'available'),
            Slots(sId: 'slot18', time: '11:00 PM', amount: 700, status: 'available'),
          ],
        ),
      ],
    );

    _originalSlotsCache.clear();
    final courts = slots.value?.data ?? [];
    for (final court in courts) {
      _originalSlotsCache[court.sId ?? ''] = List<Slots>.from(court.slots ?? []);
    }
  }

  @override
  void onClose() {
    _cleanupOnBack();
    selectedSlots.clear();
    multiDateSelections.clear();
    realCourtSelections.clear();
    totalAmount.value = 0;
    super.onClose();
  }

  Future<void> _cleanupOnBack() async {
    if (realCourtSelections.isEmpty) return;
    
    try {
      final slots = [];
      
      for (var entry in realCourtSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final dateString = selection['date'] as String;
        final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
        final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
        
        final bookingTime = isHalfSlot 
            ? _getHalfSlotTime(slot.time ?? '', isFirstHalf)
            : slot.time ?? '';
        final duration = isHalfSlot ? 30 : 60;
        
        slots.add({
          "slotId": slotId,
          "courtId": courtId,
          "bookingDate": dateString,
          "time": bookingTime,
          "bookingTime": bookingTime,
          "duration": duration,
        });
      }
      
      await _homeRepository.deleteSlotHistory(data: {"slots": slots});
      log('Bulk delete slot history on back: $slots');
    } catch (e) {
      log('Error in bulk delete on back: $e');
    }
  }





  void refreshSlots({bool showUnavailable = false}) {
    isLoadingCourts.value = true;

    Future.delayed(Duration(milliseconds: 500), () {
      final courts = slots.value?.data ?? [];
      for (var court in courts) {
        final base = _originalSlotsCache[court.sId ?? ''] ?? [];
        if (showUnavailable) {
          court.slots = base.where((s) => _isUnavailableSlot(s)).toList();
        } else {
          court.slots = base.where((s) => _isAvailableSlot(s)).toList();
        }
      }

      slots.refresh();
      isLoadingCourts.value = false;
    });
  }

  Future<bool> createAndGetSlotHistory({
    required List<Map<String, dynamic>> slots,
  }) async {
    try {
      log('createAndGetSlotHistory called with body: $slots');

      final response =
      await _homeRepository.createAndGetSlotHistory(data: slots);

      // response is CreateAndGetSlotHistoryResponse
      final createdSlots =
      response.data.where((e) => e.created).toList();

      final lockedSlots =
      response.data.where((e) => !e.created).toList();

      // ✅ If at least one slot created → success
      if (createdSlots.isNotEmpty) {
        return true;
      }

      // ❌ All slots failed (locked)
      if (lockedSlots.isNotEmpty) {
        SnackBarUtils.showInfoSnackBar(
          lockedSlots.first.message ??
              "Selected slots are currently locked. Please try again.",
        );
      }

      return false;
    } catch (e) {
      log('Error in createAndGetSlotHistory: $e');
      Get.snackbar(
        "Error",
        "Failed to select slot. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }


  // API method for deleting slot history (batch)
  Future<void> deleteSlotHistory({required List<Map<String, dynamic>> slots}) async {
    try {
      log('deleteSlotHistory called with body: $slots');
      await _homeRepository.deleteSlotHistory(data: slots);
    } catch (e) {
      log('Error in deleteSlotHistory: $e');
    }
  }
  void toggleCourtRowSlotSelection(Slots slot, {String? courtId, String? courtName, bool? isHalfSlot, bool? isFirstHalf}) {
    final slotId = slot.sId ?? '';
    final resolvedCourtId = courtId ?? '';
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    
    if (isHalfSlot == true && clubSupports30MinSlots(resolvedCourtId)) {
      final halfSlotSuffix = isFirstHalf == true ? '_first_half' : '_second_half';
      final realCourtKey = '${dateString}_${resolvedCourtId}_$slotId$halfSlotSuffix';

      if (realCourtSelections.containsKey(realCourtKey)) {
        realCourtSelections.remove(realCourtKey);
      } else {
        if (!_canAddRealCourtSlot(slot, resolvedCourtId, dateString, isHalfSlot: true)) {
          Get.snackbar(
            "Selection Limit",
            "You can only select 3 consecutive slots.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        final halfSlot = Slots(
          sId: slotId,
          time: slot.time,
          amount: slot.amount ?? 0,
        );

        realCourtSelections[realCourtKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
          'isHalfSlot': true,
          'isFirstHalf': isFirstHalf,
        };
      }
    } else {
      final realCourtKey = '${dateString}_${resolvedCourtId}_$slotId';

      if (realCourtSelections.containsKey(realCourtKey)) {
        realCourtSelections.remove(realCourtKey);
        selectedSlots.removeWhere((s) => s.sId == slotId);
      } else {
        if (!_canAddRealCourtSlot(slot, resolvedCourtId, dateString)) {
          Get.snackbar(
            "Selection Limit",
            "You can only select 3 consecutive slots.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        realCourtSelections[realCourtKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };

        if (!selectedSlots.any((s) => s.sId == slotId)) {
          selectedSlots.add(slot);
        }
      }
    }

    recalculateRealCourtTotalAmount();
  }
  // Get half slot time - for left half return original time, for right half add 30 minutes
  String _getHalfSlotTime(String originalTime, bool isFirstHalf) {
    if (isFirstHalf) {
      return originalTime; // Left half uses original time (e.g., "8:00 PM")
    } else {
      // Right half adds 30 minutes (e.g., "8:30 PM")
      try {
        final timeString = originalTime.trim();
        DateTime? parsedTime;
        
        // Try to parse with common formats
        for (final pattern in ['h:mm a', 'h a', 'HH:mm', 'H:mm']) {
          try {
            parsedTime = DateFormat(pattern).parse(timeString);
            break;
          } catch (_) {}
        }
        
        if (parsedTime != null) {
          // Add 30 minutes
          final newTime = parsedTime.add(Duration(minutes: 30));
          return DateFormat('h:mm a').format(newTime);
        }
        
        // Fallback: manual parsing for formats like "8 PM"
        final parts = timeString.split(' ');
        if (parts.length == 2) {
          final timePart = parts[0];
          final period = parts[1].toLowerCase();
          
          int? hour = int.tryParse(timePart);
          if (hour != null) {
            // Add 30 minutes (0.5 hour)
            final newHour = hour;
            final newMinute = 30;
            
            return '$newHour:${newMinute.toString().padLeft(2, '0')} ${period.toUpperCase()}';
          }
        }
      } catch (e) {
        log('Error calculating half slot time: $e');
      }
      
      // Fallback: return original time with :30 added
      return originalTime.replaceFirst(':', ':30').replaceFirst(' ', ':30 ');
    }
  }

  void toggleSlotSelection(Slots slot, {String? courtId, String? courtName, bool? isLeftHalf}) {
    if(Get.isSnackbarOpen) return;

    final slotId = slot.sId ?? '';
    final resolvedCourtId = courtId ?? '';
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    final multiDateKey = '${dateString}_${resolvedCourtId}_$slotId';

    if (multiDateSelections.containsKey(multiDateKey)) {
      multiDateSelections.remove(multiDateKey);
    } else {
      // Check if adding this slot would exceed 3 slots or break consecutiveness
      if (!_canAddSlot(slot, resolvedCourtId, dateString)) {
        Get.snackbar(
          "Selection Limit",
          "You can only select 3 consecutive slots.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      multiDateSelections[multiDateKey] = {
        'slot': slot,
        'courtId': resolvedCourtId,
        'courtName': courtName ?? '',
        'date': dateString,
        'dateTime': currentDate,
        'amount': slot.amount ?? 0,
      };
    }

    selectedTimeSlot.value = slot.time ?? '';
    _recalculateTotalAmount();
    log("Selected ${multiDateSelections.length} slots for date: $dateString, Total: ₹${totalAmount.value}");
  }






  void _recalculateTotalAmount() {
    int total = 0;
    multiDateSelections.forEach((key, selection) {
      if (selection.containsKey('amount')) {
        total += selection['amount'] as int;
      } else {
        final slot = selection['slot'] as Slots;
        total += slot.amount ?? 0;
      }
    });
    totalAmount.value = total;
  }

  void recalculateRealCourtTotalAmount() {
    int total = 0;
    realCourtSelections.forEach((key, selection) {
      if (selection.containsKey('amount')) {
        total += selection['amount'] as int;
      } else {
        final slot = selection['slot'] as Slots;
        total += slot.amount ?? 0;
      }
    });
    totalAmount.value = total;
  }

  bool isPastAndUnavailable(Slots slot) {
    // Treat booked or explicitly unavailable statuses as unavailable
    final status = _normalizeStatus(slot.status);
    if (status == 'booked') return true;
    if (status.isNotEmpty && status != 'available') return true;

    // If time is missing or malformed, don't mark as past (avoid crashes)
    final rawTime = slot.time;
    if (rawTime == null || rawTime.trim().isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final selected = selectedDate.value ?? now;

    try {
      final timeString = rawTime.toLowerCase().trim();

      // Try common formats first
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
        // Fallback manual parse: supports "10", "10:30", with optional am/pm
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

      // On any parsing error, consider it not past to be safe

      return false;
    }
    return false;
  }

  bool _isUnavailableSlot(Slots slot) {
    final availability = _normalizeStatus(slot.availabilityStatus);
    final isBlocked = availability == "maintenance" ||
        availability == "weather conditions" ||
        availability == "staff unavailability";
    final isBooked = (_normalizeStatus(slot.status) == 'booked');
    final isPast = isPastAndUnavailable(slot);
    return isPast || isBlocked || isBooked;
  }

  bool _isAvailableSlot(Slots slot) {
    final status = _normalizeStatus(slot.status);
    return !_isUnavailableSlot(slot) && (status == 'available' || status.isEmpty);
  }

  String _normalizeStatus(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  bool isSlotSelected(Slots slot, String courtId) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final multiDateKey = '${dateString}_${courtId}_${slot.sId}';

    return multiDateSelections.containsKey(multiDateKey);
  }

  bool isRealCourtSlotSelected(Slots slot, String courtId) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    // Check for full slot selection
    final realCourtKey = '${dateString}_${courtId}_${slot.sId}';
    if (realCourtSelections.containsKey(realCourtKey)) {
      return true;
    }

    // Check for half-slot selections if club supports 30-minute slots
    if (clubSupports30MinSlots(courtId)) {
      final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
      final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
      return realCourtSelections.containsKey(firstHalfKey) || realCourtSelections.containsKey(secondHalfKey);
    }

    return false;
  }

  // Check if both halves are selected for a court slot
  bool isBothHalvesSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';

    return realCourtSelections.containsKey(firstHalfKey) && realCourtSelections.containsKey(secondHalfKey);
  }

  // Check if left half is selected for a court slot
  bool isLeftHalfSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';

    return realCourtSelections.containsKey(firstHalfKey);
  }

  // Check if right half is selected for a court slot
  bool isRightHalfSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';

    return realCourtSelections.containsKey(secondHalfKey);
  }



  int getTotalSelectionsCount() {
    return multiDateSelections.length;
  }

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

  bool _canAddSlot(Slots newSlot, String courtId, String dateString) {
    final currentSelections = multiDateSelections.entries
        .where((e) => e.key.startsWith('${dateString}_${courtId}_'))
        .map((e) => e.value['slot'] as Slots)
        .toList();

    if (currentSelections.length >= 3) return false;
    if (currentSelections.isEmpty) return true;

    final allSlots = [...currentSelections, newSlot];
    return _areConsecutive(allSlots);
  }

  bool _canAddRealCourtSlot(Slots newSlot, String courtId, String dateString, {bool isHalfSlot = false}) {
    // Check if this time slot is already selected in any other court
    final newSlotTime = newSlot.time;
    final isTimeAlreadySelected = realCourtSelections.entries.any((entry) {
      final selection = entry.value;
      final existingCourtId = selection['courtId'] as String;
      final existingSlot = selection['slot'] as Slots;
      return existingCourtId != courtId && existingSlot.time == newSlotTime;
    });

    if (isTimeAlreadySelected) {
      Get.snackbar(
        "Time Conflict",
        "This time slot is already selected in another court.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // For half slots, if we're selecting the other half of the same slot, always allow it
    if (isHalfSlot && clubSupports30MinSlots(courtId)) {
      final newSlotId = newSlot.sId ?? '';
      final hasOtherHalf = realCourtSelections.entries.any((entry) {
        final key = entry.key;
        final selection = entry.value;
        final existingCourtId = selection['courtId'] as String;
        final existingSlot = selection['slot'] as Slots;
        final existingSlotId = existingSlot.sId ?? '';
        
        return existingCourtId == courtId && 
               existingSlotId == newSlotId && 
               key.startsWith('${dateString}_${courtId}_${newSlotId}_');
      });
      
      // If we're selecting the other half of an existing slot, allow it
      if (hasOtherHalf) {
        return true;
      }
    }

    // Get unique slots (consolidate half-slots of the same slot ID)
    final Map<String, Slots> uniqueSlots = {};
    for (var entry in realCourtSelections.entries) {
      if (!entry.key.startsWith('${dateString}_${courtId}_')) continue;
      
      final selection = entry.value;
      final slot = selection['slot'] as Slots;
      final slotId = slot.sId ?? '';
      
      if (!uniqueSlots.containsKey(slotId)) {
        uniqueSlots[slotId] = slot;
      }
    }

    final currentSelections = uniqueSlots.values.toList();
    
    // Add new slot if it's not already in the unique slots
    final newSlotId = newSlot.sId ?? '';
    if (!uniqueSlots.containsKey(newSlotId)) {
      if (currentSelections.length >= 3) return false;
      currentSelections.add(newSlot);
    }

    if (currentSelections.isEmpty) return true;
    if (currentSelections.length == 1) return true;

    return _areConsecutive(currentSelections);
  }

  bool _areConsecutive(List<Slots> slots) {
    if (slots.length <= 1) return true;

    final sortedSlots = slots.toList()..sort((a, b) => _getSlotHour(a.time).compareTo(_getSlotHour(b.time)));
    
    for (int i = 1; i < sortedSlots.length; i++) {
      final prevHour = _getSlotHour(sortedSlots[i - 1].time);
      final currentHour = _getSlotHour(sortedSlots[i].time);
      if (currentHour - prevHour != 1) return false;
    }
    return true;
  }

  int _getSlotHour(String? timeStr) {
    if (timeStr == null) return 0;
    final hour = parseHour24(timeStr);
    return hour ?? 0;
  }

  void clearAllSelections() {
    multiDateSelections.clear();
    realCourtSelections.clear();
    selectedSlots.clear();
    totalAmount.value = 0;
    selectedTimeSlot.value = '';
    selectedSearchSlotId.value = null;
    isSlotsCollapsed.value = false;
    // Don't clear courtsByDuration to preserve clubs when switching dates
  }

  void clearAllSelectionsAndClubs() {
    multiDateSelections.clear();
    realCourtSelections.clear();
    selectedSlots.clear();
    totalAmount.value = 0;
    courtsByDuration.value = null;
    selectedTimeSlot.value = '';
    selectedSearchSlotId.value = null;
    isSlotsCollapsed.value = false;
  }

  // Fetch courts by duration when all required data is available
  void fetchCourtsIfReady() {
    if (selectedDate.value != null && selectedDuration.value.isNotEmpty && selectedTimeSlot.value.isNotEmpty) {
      fetchCourtsByDuration();
    }
  }

  ///Fetch All Slot Prices------------------------------------------------------
  Future<void> fetchAllSlotPrices(String clubId, {String? selectedTimes}) async {
    try {
      isSlotPricesLoading.value = true;

      final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;

      final result = await _homeRepository.getAllSlotPricesOfCourt(
        registerClubId: clubId,
        duration: '',
        // duration: selectedDurationMinutes.toString(), // Send selected duration
        day: '', // Get all days
        timePeriod: '', // Send selected times or empty for all
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
        msg: "Fetched slot prices for selected times: $selectedTimes, data: $slotPricesData",
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

  /// Update slot prices from fetchAllSlotPrices API for a specific club
  void updateSlotPricesForSpecificClub(GetCourtsByDurationData clubData) {
    if (clubData.courts == null) return;

    final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    final currentDate = selectedDate.value ?? DateTime.now();
    final dayName = getWeekday(currentDate.weekday);

    for (var court in clubData.courts!) {
      if (court.slots == null) continue;

      for (var slot in court.slots!) {
        final slotTime = slot.time;
        if (slotTime == null) continue;

        int? slotPrice;

        if (selectedDurationMinutes == 90) {
          // For 90min display: show only 60min price
          slotPrice = findPriceForSlot(slotTime, dayName, 60);
        } else {
          // For other durations, use the duration price directly
          final duration = selectedDurationMinutes == 120 ? 60 : selectedDurationMinutes;
          slotPrice = findPriceForSlot(slotTime, dayName, duration);
        }

        if (slotPrice != null) {
          slot.amount = slotPrice;
        }
      }
    }
  }

  /// Find price for a specific slot time from fetchAllSlotPrices data
  int? findPriceForSlot(String slotTime, String day, int duration) {
    final slotPrices = allSlotPricesResponse.value?.data;
    if (slotPrices == null) return null;

    // Parse slot time to 24-hour format
    final slotHour = parseHour24(slotTime);
    if (slotHour == null) return null;

    // Find matching price entry
    for (final priceEntry in slotPrices) {
      if (priceEntry.day != day || priceEntry.duration != duration) continue;

      final slotTimeRange = priceEntry.slotTime;
      if (slotTimeRange == null) continue;

      // Check if slot time falls within the price range
      if (isTimeInRange(slotHour, slotTimeRange)) {
        return priceEntry.price;
      }
    }

    return null;
  }

  /// Check if a time falls within a time range (e.g., "6:00 AM - 11:00 AM")
  bool isTimeInRange(int slotHour, String timeRange) {
    try {
      final parts = timeRange.split(' - ');
      if (parts.length != 2) return false;

      final startHour = parseHour24(parts[0].trim());
      final endHour = parseHour24(parts[1].trim());

      if (startHour == null || endHour == null) return false;

      // Handle cases where end time is inclusive (e.g., 6 AM - 11 AM includes 11 AM)
      return slotHour >= startHour && slotHour <= endHour;
    } catch (e) {
      return false;
    }
  }

  /// Parse time string to 24-hour format
  int? parseHour24(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final t = timeStr.trim().toLowerCase();
    try {
      final dt = DateFormat('h:mm a').parseStrict(t);
      return dt.hour;
    } catch (_) {
      try {
        final dt = DateFormat('h a').parseStrict(t);
        return dt.hour;
      } catch (_) {
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

  String getWeekday(int weekday) {
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

  /// Format time from "7pm" to "7:00 pm" for UI display
  String formatTimeForDisplay(String? time) {
    if (time == null || time.isEmpty) return '';

    final timeStr = time.trim().toLowerCase();

    // If already in correct format, return as is
    if (timeStr.contains(':')) {
      return time;
    }

    // Parse time like "7pm" or "7am"
    final match = RegExp(r'(\d+)\s*(am|pm)').firstMatch(timeStr);
    if (match != null) {
      final hour = match.group(1);
      final period = match.group(2);
      return '$hour:00 $period';
    }

    return time; // Return original if parsing fails
  }

  /// Get next hour time for 90min half slot display
  String _getNextHourTime(String currentTime) {
    try {
      final hour = parseHour24(currentTime);
      if (hour != null) {
        final nextHour = (hour + 1) % 24;
        final period = nextHour >= 12 ? 'pm' : 'am';
        final displayHour = nextHour == 0 ? 12 : (nextHour > 12 ? nextHour - 12 : nextHour);
        return '$displayHour $period';
      }
    } catch (e) {
      // Fallback
    }
    return currentTime;
  }

  // Convert time format from "7:00 PM" to "7 pm"
  String _formatTimeForAPI(String time) {
    if (time.isEmpty) return time;

    try {
      // Parse the time string
      final timeString = time.trim();

      // Try to parse with common formats
      DateTime? parsedTime;
      for (final pattern in ['h:mm a', 'h a', 'HH:mm', 'H:mm']) {
        try {
          parsedTime = DateFormat(pattern).parse(timeString);
          break;
        } catch (_) {}
      }

      if (parsedTime != null) {
        int hour = parsedTime.hour;
        String period = hour >= 12 ? 'pm' : 'am';

        // Convert to 12-hour format
        if (hour == 0) {
          hour = 12;
        } else if (hour > 12) {
          hour = hour - 12;
        }

        return '$hour $period';
      }

      // Fallback: manual parsing
      final parts = timeString.split(' ');
      String timePart = parts[0];
      String? period = parts.length > 1 ? parts[1].toLowerCase() : null;

      // Remove minutes (everything after colon)
      if (timePart.contains(':')) {
        timePart = timePart.split(':')[0];
      }

      int? hour = int.tryParse(timePart);
      if (hour != null) {
        // Determine period if not provided
        if (period == null) {
          period = hour >= 12 ? 'pm' : 'am';
        } else {
          period = period.toLowerCase();
        }

        // Convert to 12-hour format if needed
        if (hour == 0) {
          hour = 12;
        } else if (hour > 12) {
          hour = hour - 12;
          period = 'pm';
        } else if (hour == 12 && period == 'am') {
          hour = 12;
        }

        return '$hour $period';
      }
    } catch (e) {
      log('Error formatting time: $e');
    }

    // Return original if parsing fails
    return time;
  }

  // Fetch courts by duration from API
  Future<void> fetchCourtsByDuration() async {
    try {
      isLoadingCourtsByDuration.value = true;

      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value!);

      // Collect all selected slot times from multiDateSelections
      String formattedTime = '';
      if (multiDateSelections.isNotEmpty) {
        final selectedSlotTimes = <String>{};
        multiDateSelections.forEach((key, selection) {
          final slot = selection['slot'] as Slots;
          if (slot.time != null && slot.time!.isNotEmpty) {
            selectedSlotTimes.add(_formatTimeForAPI(slot.time!));
          }
        });
        formattedTime = selectedSlotTimes.join(',');
      }

      final response = await _homeRepository.getCourtsByDuration(
        duration: "",
        date: dateString,
        time: formattedTime,
      );

      courtsByDuration.value = response;

      log('Courts by duration fetched: ${response.data?.length} clubs');
    } catch (e) {
      log('Error fetching courts by duration: $e');
    } finally {
      isLoadingCourtsByDuration.value = false;
    }
  }

  // Check if a club supports 30-minute slots
  bool clubSupports30MinSlots(String courtId) {
    if (courtsByDuration.value?.data == null) return false;

    for (var clubData in courtsByDuration.value!.data!) {
      if (clubData.courts != null) {
        for (var court in clubData.courts!) {
          if (court.id == courtId && court.slots != null) {
            return court.slots!.any((slot) => slot.has30MinPrice == true);
          }
        }
      }
    }
    return false;
  }


  Future<bool> processSlotHistoryForNext() async {
    if (realCourtSelections.isEmpty) return false;

    try {
      final slots = <Map<String, dynamic>>[];
      
      for (var entry in realCourtSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final dateString = selection['date'] as String;
        final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
        final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
        
        final bookingTime = isHalfSlot 
            ? _getHalfSlotTime(slot.time ?? '', isFirstHalf)
            : slot.time ?? '';
        final duration = isHalfSlot ? 30 : 60;
        
        slots.add({
          "slotId": slotId,
          "courtId": courtId,
          "courtName": courtName,
          "bookingDate": dateString,
          "userId": "",
          "time": bookingTime,
          "bookingTime": bookingTime,
          "duration": duration,
          "totalTime": duration,
        });
      }
      
      return await createAndGetSlotHistory(slots: slots);
    } catch (e) {
      log('Error processing slot history: $e');
      return false;
    }
  }

  void onNext() async {
    log("Slots -> $selectedSlots");

    if (realCourtSelections.isEmpty) {
      Get.snackbar(
        "No Selection",
        "Please select at least one slot to continue.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final success = await processSlotHistoryForNext();
    if (!success) return;

    String selectedCourtId = '';
    String selectedCourtName = '';
    String selectedClubId = '';

    if (realCourtSelections.isNotEmpty) {
      final firstSelection = realCourtSelections.values.first;
      selectedCourtId = firstSelection['courtId'] ?? '';
      selectedCourtName = firstSelection['courtName'] ?? '';
      if (courtsByDuration.value?.data != null) {
        for (var club in courtsByDuration.value!.data!) {
          if (club.courts != null) {
            for (var court in club.courts!) {
              if (court.id == selectedCourtId) {
                selectedClubId = club.registerClub?.id ?? '';
                selectedCourtName = court.courtName ?? selectedCourtName;
                break;
              }
            }
          }
          if (selectedClubId.isNotEmpty) break;
        }
      }
    }

    final Map<String, Slots> consolidatedSlots = {};
    final Map<String, int> slotAmounts = {};
    
    realCourtSelections.forEach((key, value) {
      final slot = value['slot'] as Slots;
      final slotId = slot.sId ?? '';
      final amount = value['amount'] as int? ?? 0;
      
      if (consolidatedSlots.containsKey(slotId)) {
        slotAmounts[slotId] = (slotAmounts[slotId] ?? 0) + amount;
      } else {
        consolidatedSlots[slotId] = slot;
        slotAmounts[slotId] = amount;
      }
    });
    
    final sortedSlots = consolidatedSlots.values.toList()
      ..sort((a, b) => _getSlotHour(a.time).compareTo(_getSlotHour(b.time)));
    
    final List<Map<String, dynamic>> consecutiveGroups = [];
    var i = 0;
    
    while (i < sortedSlots.length) {
      final consecutiveSlots = [sortedSlots[i]];
      var totalAmount = slotAmounts[sortedSlots[i].sId] ?? 0;
      
      for (var j = i + 1; j < sortedSlots.length; j++) {
        final currentHour = _getSlotHour(sortedSlots[j - 1].time);
        final nextHour = _getSlotHour(sortedSlots[j].time);
        
        if (nextHour - currentHour == 1) {
          consecutiveSlots.add(sortedSlots[j]);
          totalAmount += slotAmounts[sortedSlots[j].sId] ?? 0;
        } else {
          break;
        }
      }
      
      // Create time range
      String timeRange;
      if (consecutiveSlots.length == 1) {
        timeRange = formatTimeForDisplay(consecutiveSlots.first.time ?? '');
      } else {
        final startTime = formatTimeForDisplay(consecutiveSlots.first.time ?? '');
        final endHour = _getSlotHour(consecutiveSlots.last.time) + 1;
        final endPeriod = endHour >= 12 ? 'PM' : 'AM';
        final displayEndHour = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);
        timeRange = '${startTime.replaceAll(RegExp(r'\s*(AM|PM)', caseSensitive: false), '')}-${displayEndHour}:00 $endPeriod';
      }
      
      consecutiveGroups.add({
        'slots': consecutiveSlots,
        'timeRange': timeRange,
        'totalAmount': totalAmount,
      });
      
      i += consecutiveSlots.length;
    }
    
    // Create consolidated slots for bottomsheet
    final selectedSlotsFromCourts = <Slots>[];
    for (var group in consecutiveGroups) {
      final slots = group['slots'] as List<Slots>;
      final consolidatedSlot = Slots(
        sId: slots.map((s) => s.sId).join('_'),
        time: group['timeRange'] as String,
        amount: group['totalAmount'] as int,
        status: slots.first.status,
      );
      selectedSlotsFromCourts.add(consolidatedSlot);
    }
    
    String matchTimeFromCourts = '';
    if (selectedSlotsFromCourts.isNotEmpty && selectedSlotsFromCourts.first.time != null) {
      matchTimeFromCourts = selectedSlotsFromCourts.first.time!;
    }

    // Get business hours from courtsByDuration API response
    List<dynamic> businessHours = [];
    print("Debug - Extracting businessHours from API response");
    if (courtsByDuration.value?.data != null) {
      for (var club in courtsByDuration.value!.data!) {
        if (club.registerClub?.id == selectedClubId) {
          // Get business hours from the club's registerClub
          if (club.registerClub?.businessHours != null) {
            for (var bh in club.registerClub!.businessHours!) {
              final bhJson = {
                'day': bh.day ?? '',
                'time': bh.time ?? '',
              };
              businessHours.add(bhJson);
            }
          }
          break;
        }
      }
    }
    print("Debug - Extracted businessHours from API: $businessHours");

    final matchData = {
      "slot": selectedSlotsFromCourts,
      "matchDate": selectedDate.value,
      "courtName": selectedCourtName,
      "clubId": selectedClubId,
      "courtId": selectedCourtId,
      "matchTime": matchTimeFromCourts,
      "businessHours": businessHours.isNotEmpty ? businessHours : null, // Only include if not empty
      "selectedDuration": selectedDuration.value, // Pass selected duration
    };

    // Debug: Print what we're sending
    print("Debug - Final matchData businessHours: ${matchData['businessHours']}");
    print("Debug - Sending ${selectedSlotsFromCourts.length} slots from available courts to bottomsheet");
    for (var slot in selectedSlotsFromCourts) {
      print("Sending slot: ${slot.sId} - ${slot.time} - ${slot.amount}");
    }

    // Show QuestionsBottomsheetScreen as bottom sheet with match data
    final controller = Get.put(QuestionsBottomsheetController(), tag: 'questions');
    controller.localMatchData = matchData;

    Get.bottomSheet(
      QuestionsBottomsheetScreen(),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    ).then((_) {
      // Cleanup when bottomsheet is closed
      _cleanupOnBack();
      Get.delete<QuestionsBottomsheetController>(tag: 'questions');
    });
  }
}