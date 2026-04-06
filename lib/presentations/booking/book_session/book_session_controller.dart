import 'dart:async';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/get_all_slot_prices_of_court_model.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import '../../../data/request_models/home_models/get_available_court.dart';
import '../../../data/request_models/home_models/get_club_name_model.dart';
import '../../../repositories/home_repository/home_repository.dart';
import '../../../services/socket_service.dart';
import '../../../services/slot_wise_service.dart';
import '../../payment/payment_method_controller.dart';

class BookSessionController extends GetxController {
  final SlotWiseService _slotWiseService = SlotWiseService();
  RxBool isSocketDataReceived = false.obs;
  // Booking limits
  static const int maxSlots = 24;
  static const int maxDays = 5;
  final focusedMonth = DateTime.now().obs;
  ///Available Slots------------------------------------------------------------
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
  
  void select(String value) async {
    selectedDuration.value = value;
    // Clear all selections when duration changes
    multiDateSelections.clear();
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    totalAmount.value = 0;
    // Refetch courts with updated prices when duration changes
    if (slots.value != null) {
      await getAvailableCourtsById(locationID.value,categoryId.value,sId.value,argument.id!, showUnavailable: true);
    }
  }


  ///Date Picker----------------------------------------------------------------
  Future<void> openDatePicker(BuildContext context) async {

    final DateTime today = DateTime.now();
    final DateTime firstSelectableDate = today.hour >= 23 
        ? DateTime(today.year, today.month, today.day).add(const Duration(days: 1))
        : today;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? firstSelectableDate,
      firstDate: firstSelectableDate,
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
  // Date formatter for consistency
  static final _dateFormatter = DateFormat('yyyy-MM-dd');

  final selectedDate = Rxn<DateTime>();
  Courts argument = Courts();
  RxBool showUnavailableSlots = false.obs;
  RxInt currentPage = 0.obs;
  var selectedTimeOfDay = 0.obs;
  var isManualTabSelection = false.obs;

  var morningCount = 0.obs;
  var noonCount = 0.obs;
  var nightCount = 0.obs;

  // Cache base slot lists (after unavailable/available toggle applied)
  final Map<String, List<Slots>> _originalSlotsCache = {};
  final Map<String, List<Slots>> _allSlotsCache = {}; // Combined slots cache

  void _autoSelectTab() {
    // Don't auto-select if user has manually selected a tab
    if (isManualTabSelection.value) return;
    
    final now = DateTime.now();
    final hour = now.hour;
    final timeRanges = _getTimeRanges();

    if (hour >= timeRanges['morningStart']! && hour <= timeRanges['morningEnd']! && morningCount.value > 0) {
      selectedTimeOfDay.value = 0; // Morning
    } else if (hour >= timeRanges['noonStart']! && hour <= timeRanges['noonEnd']! && noonCount.value > 0) {
      selectedTimeOfDay.value = 1; // Noon
    } else if (hour >= timeRanges['nightStart']! && hour <= timeRanges['nightEnd']! && nightCount.value > 0) {
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
    final timeRanges = _getTimeRanges();
    
    for (final court in courts) {
      final courtId = court.sId ?? '';
      final baseList = _originalSlotsCache[courtId] ?? List<Slots>.from(court.slots ?? []);
      court.slots = baseList.where((s) {
        final hour = _parseHour24(s.time);
        if (hour == null) return false;
        
        // Filter out past slots
        if (isPastAndUnavailable(s)) return false;
        
        if (tab == 0) return hour >= timeRanges['morningStart']! && hour <= timeRanges['morningEnd']!;
        if (tab == 1) return hour >= timeRanges['noonStart']! && hour <= timeRanges['noonEnd']!;
        return hour >= timeRanges['nightStart']! && hour <= timeRanges['nightEnd']!;
      }).toList();
    }
    _recalculateTimeOfDayCounts();
    slots.refresh();
  }

  Map<String, int> _getTimeRanges() {
    return {
      'morningStart': 5, 'morningEnd': 11,
      'noonStart': 12, 'noonEnd': 16,
      'nightStart': 17, 'nightEnd': 23,
    };
  }

  void _recalculateTimeOfDayCounts() {
    morningCount.value = 0;
    noonCount.value = 0;
    nightCount.value = 0;
    final timeRanges = _getTimeRanges();
    
    _originalSlotsCache.forEach((_, list) {
      for (final s in list) {
        final hour = _parseHour24(s.time);
        if (hour == null) continue;
        
        // Skip past slots when counting
        if (isPastAndUnavailable(s)) continue;
        
        if (hour >= timeRanges['morningStart']! && hour <= timeRanges['morningEnd']!) {
          morningCount.value++;
        } else if (hour >= timeRanges['noonStart']! && hour <= timeRanges['noonEnd']!) {
          noonCount.value++;
        } else if (hour >= timeRanges['nightStart']! && hour <= timeRanges['nightEnd']!) {
          nightCount.value++;
        }
      }
    });
  }

  int? _parseHour24(String? timeStr) {
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

  PageController pageController = PageController();
  RxList<Slots> selectedSlots = <Slots>[].obs;
  RxMap<String, Map<String, dynamic>> multiDateSelections = <String, Map<String, dynamic>>{}.obs;

  RxInt totalAmount = 0.obs;
  final HomeRepository repository = HomeRepository();
  Rx<GetAllActiveCourtsForSlotWiseModel?> slots = Rx<GetAllActiveCourtsForSlotWiseModel?>(null);
  RxBool isLoadingCourts = false.obs;

  RxMap<String, Map<String, dynamic>> selectedSlotsWithCourtInfo = <String, Map<String, dynamic>>{}.obs;
  RxBool isBottomSheetOpen = false.obs;
  
  // Track if slot history API was called
  RxBool hasCalledSlotHistoryAPI = false.obs;
  
  // Store the locked slots data for cleanup
  List<Map<String, dynamic>> _lockedSlotsData = [];
  
  // Track if we're currently locking slots (to ignore socket updates temporarily)
  RxBool isLockingSlots = false.obs;
  
  // Store timestamp when slots were locked by current user
  DateTime? _lastLockTimestamp;
var sId = "".obs;
var categoryId = "".obs;
var locationID = "".obs;
var locationsId = "".obs;
  @override
  void onInit() {
    super.onInit();
    argument = Get.arguments['data']??"";
    sId.value = Get.arguments['sID']??"";
    categoryId.value = Get.arguments['categoryId']??"";
    locationID.value = Get.arguments['location']??"";
    locationsId.value = Get.arguments['locationsId']??"";
    selectedDate.value = _getInitialDate();
    
    // Add listener to check when screen becomes visible again
    ever(hasCalledSlotHistoryAPI, (value) {
      log('🔔 hasCalledSlotHistoryAPI changed to: $value');
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Subscribe to slot-wise updates first (with API fallback)
      _subscribeToSlotUpdates();
      _startDateAutoSwitchTimer();
    });
  }

  DateTime _getInitialDate() {
    final now = DateTime.now();
    if (now.hour >= 23) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }
    return now;
  }

  void _startDateAutoSwitchTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (now.hour == 23 && now.minute == 0) {
        final nextDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        selectedDate.value = nextDay;
        dateTimelineController.animateToDate(nextDay);
        getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
      }
    });
  }

  @override
  void onClose() {
    // Don't cleanup here - let the widget handle it when user actually navigates back
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    multiDateSelections.clear();
    totalAmount.value = 0;
    pageController.dispose();
    
    // Unsubscribe from slot updates
    _unsubscribeFromSlotUpdates();
    
    super.onClose();
  }

  Future<void> cleanupOnBack() async {
    log('🧹 cleanupOnBack() called');
    log('   - _lockedSlotsData count: ${_lockedSlotsData.length}');
    log('   - multiDateSelections count: ${multiDateSelections.length}');
    
    // Use stored locked slots data if available
    if (_lockedSlotsData.isEmpty) {
      log('   - No locked slots data to cleanup, returning');
      return;
    }
    
    try {
      log('🔓 Unlocking ${_lockedSlotsData.length} slot(s) via deleteSlotHistory API');
      log('   - Payload: $_lockedSlotsData');
      await repository.deleteSlotHistory(data: {"slots": _lockedSlotsData});
      log('✅ Successfully unlocked slots');
      
      // Clear the stored data after successful cleanup
      _lockedSlotsData.clear();
    } catch (e) {
      log('❌ Error in cleanupOnBack: $e');
    }
  }

  Future<void> getAvailableCourtsById(String locationId,String categoryId,String sID, String clubId, {bool showUnavailable = false}) async {
    log("=== DEBUG API CALL ===");
    log("Fetching courts for club: $clubId");
    log("Selected date: ${selectedDate.value}");
    log("Show unavailable: $showUnavailable");
    log("Lock ID (locationsId): ${locationsId.value}");

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
        sID: sID,
        categoryId: categoryId,
        // location: locationId,
        locId: locationsId.value
        // duration: selectedDuration.value.split(' ').first
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
      // _updateSlotPrices(result, formattedDay); // Commented out - use prices from getAllActiveCourtsForSlotWise API

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

      // Build original cache from ALL slots (including booked) for time-of-day filtering
      _originalSlotsCache.clear();
      for (var court in result.data ?? []) {
        _originalSlotsCache[court.sId ?? ''] = List<Slots>.from(_allSlotsCache[court.sId ?? ''] ?? []);
      }
      _recalculateTimeOfDayCounts();

      filterSlotsByTimeOfDay();
      _autoSelectTab();

    } catch (e, stackTrace) {
      log("Error occurred: $e");
      log("Stack trace: $stackTrace");
      slots.value = null;
    } finally {
      isLoadingCourts.value = false;
    }
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

  Future<bool> createAndGetSlotHistory({required List<Map<String, dynamic>> slots}) async {
    try {
      log('createAndGetSlotHistory called with body: $slots');
      
      // Set flag to ignore socket updates temporarily
      isLockingSlots.value = true;
      _lastLockTimestamp = DateTime.now();
      
      final response = await repository.createAndGetSlotHistory(data: slots);

      if (response.data.isEmpty) {
        CustomLogger.logMessage(msg: "No slot data returned", level: LogLevel.error);
        isLockingSlots.value = false;
        return false;
      }

      final createdSlots = response.data.where((e) => e.created).toList();
      final lockedSlots = response.data.where((e) => !e.created).toList();
      final currentUserId = storage.read("userId") ?? "";

      if (createdSlots.isNotEmpty) {
        // Delay resetting the flag to ignore socket updates for 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          isLockingSlots.value = false;
        });
        return true;
      }

      if (lockedSlots.isNotEmpty) {
        // Check if locked slots match with our request (same user trying to lock again)
        bool allMatchOurRequest = lockedSlots.every((lockedSlot) {
          final lockedData = lockedSlot.data;
          if (lockedData == null) return false;
          
          // Check if this locked slot matches any slot in our request
          return slots.any((requestSlot) => 
            requestSlot['slotId'] == lockedData.slotId &&
            requestSlot['courtId'] == lockedData.courtId &&
            requestSlot['bookingDate'] == lockedData.bookingDate &&
            requestSlot['bookingTime'] == lockedData.bookingTime &&
            requestSlot['userId'] == currentUserId
          );
        });
        
        if (allMatchOurRequest) {
          log('✅ All slots already locked by same user, allowing navigation');
          // Delay resetting the flag to ignore socket updates for 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            isLockingSlots.value = false;
          });
          return true;
        }
        
        isLockingSlots.value = false;
        AppToast.error(lockedSlots.first.message ?? "This slot is currently locked. Please try again.");
        CustomLogger.logMessage(msg: lockedSlots.first.message ?? "This slot is currently locked. Please try again.", level: LogLevel.error);
      }

      isLockingSlots.value = false;
      return false;
    } catch (e) {
      log('Error in createAndGetSlotHistory: $e');
      isLockingSlots.value = false;
      return false;
    }
  }

  Future<void> deleteSlotHistory({required List<Map<String, dynamic>> slots}) async {
    try {
      log('deleteSlotHistory called with body: $slots');
      await repository.deleteSlotHistory(data: {"slots": slots});
    } catch (e) {
      log('Error in deleteSlotHistory: $e');
    }
  }

  // Process slot history for payment - call APIs for all selections
  Future<bool> processSlotHistoryForPayment() async {
    if (multiDateSelections.isEmpty) return false;
    try {
      final slots = <Map<String, dynamic>>[];
      
      // Group selections by slot ID to detect both halves
      final Map<String, List<MapEntry<String, Map<String, dynamic>>>> slotGroups = {};
      for (var entry in multiDateSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final dateString = selection['date'] as String;
        final groupKey = '${dateString}_${courtId}_${slotId}';
        
        if (!slotGroups.containsKey(groupKey)) {
          slotGroups[groupKey] = [];
        }
        slotGroups[groupKey]!.add(entry);
      }
      
      log('📊 Total slot groups to process: ${slotGroups.length}');
      
      // Process each group
      for (var groupKey in slotGroups.keys) {
        final group = slotGroups[groupKey]!;
        if (group.isEmpty) continue;
        
        final firstEntry = group.first;
        final selection = firstEntry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final dateString = selection['date'] as String;
        final supports30Min = slotSupports30Min(slot);
        final userId = storage.read("userId") ?? "";
        
        // Check if both halves are selected
        final hasLeftHalf = group.any((e) => e.value['isLeftHalf'] == true);
        final hasRightHalf = group.any((e) => e.value['isLeftHalf'] == false);
        final bothHalvesSelected = hasLeftHalf && hasRightHalf;
        
        log('🔍 Processing group: $groupKey, supports30Min: $supports30Min, hasLeft: $hasLeftHalf, hasRight: $hasRightHalf');
        
        if (supports30Min && bothHalvesSelected) {
          // Both halves selected - create ONE entry with 60 minutes
          final finalDuration = (slot.duration == 90) ? 90 : 60;
          slots.add({
            "slotId": slotId,
            "courtId": courtId,
            "courtName": courtName,
            "bookingDate": dateString,
            "time": slot.time ?? '',
            "bookingTime": slot.time ?? '',
            "duration": finalDuration,
            "totalTime": finalDuration,
            "userId": userId
          });
          log('✅ Added full slot (both halves): ${slot.time}, duration: $finalDuration');
        } else if (supports30Min && (hasLeftHalf || hasRightHalf)) {
          // Only one half selected - create ONE entry with 30 minutes
          final isLeftHalf = hasLeftHalf;
          final bookingTime = isLeftHalf ? (slot.time ?? '') : _addMinutesToTime(slot.time ?? '', 30);
          slots.add({
            "slotId": slotId,
            "courtId": courtId,
            "courtName": courtName,
            "bookingDate": dateString,
            "time": bookingTime,
            "bookingTime": bookingTime,
            "duration": 30,
            "totalTime": 30,
            "userId": userId
          });
          log('✅ Added half slot: ${slot.time} (${isLeftHalf ? "left" : "right"}), bookingTime: $bookingTime');
        } else {
          // Full slot (non-30min support) - create ONE entry
          final finalDuration = (slot.duration == 90) ? 90 : 60;
          slots.add({
            "slotId": slotId,
            "courtId": courtId,
            "courtName": courtName,
            "bookingDate": dateString,
            "time": slot.time ?? '',
            "bookingTime": slot.time ?? '',
            "duration": finalDuration,
            "totalTime": finalDuration,
            "userId": userId
          });
          log('✅ Added full slot: ${slot.time}, duration: $finalDuration');
        }
      }
      
      log('📦 Total slots to lock: ${slots.length}');
      
      // Store the locked slots data for cleanup
      _lockedSlotsData = slots.map((s) => {
        "slotId": s["slotId"],
        "courtId": s["courtId"],
        "bookingDate": s["bookingDate"],
        "time": s["time"],
        "bookingTime": s["bookingTime"],
        "duration": s["duration"],
        "userId": s["userId"],
      }).toList();
      
      log('💾 Stored ${_lockedSlotsData.length} locked slots for cleanup');
      log('🔒 Calling createAndGetSlotHistory API with ${slots.length} slots');
      
      final success = await createAndGetSlotHistory(slots: slots);
      
      log('📊 API Response - Success: $success');
      
      if (success) {
        hasCalledSlotHistoryAPI.value = true;
        log('✅ Slot history API called successfully, flag set to true');
      } else {
        log('❌ Slot history API failed, clearing stored data');
        _lockedSlotsData.clear();
      }
      return success;
    } catch (e) {
      log('Error processing slot history: $e');
      _lockedSlotsData.clear();
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
    final is90MinSlot = slot.duration == 90;
    
    // Check for duration mismatch if not the first slot
    if (multiDateSelections.isNotEmpty) {
      bool has90MinSlot = false;
      bool hasNon90MinSlot = false;
      
      multiDateSelections.forEach((key, selection) {
        final existingSlot = selection['slot'] as Slots;
        if (existingSlot.duration == 90) {
          has90MinSlot = true;
        } else {
          hasNon90MinSlot = true;
        }
      });
      
      if (is90MinSlot && hasNon90MinSlot) {
        AppToast.error("Cannot mix 90-minute slots with 30/60-minute slots");
        return;
      }
      
      if (!is90MinSlot && has90MinSlot) {
        AppToast.error("Cannot mix 30/60-minute slots with 90-minute slots");
        return;
      }
    }

    // Store selection state before making changes
    final wasSelected = isSlotSelected(slot, resolvedCourtId);

    // ─────────────────────────────────────────────────────────────────────────
    // 30-min pricing supported: use the same half-slot continuity rules as
    // Book A Court (edge-only half selection; full slot otherwise; cleanup).
    // We store halves using the existing keys: _L / _R
    // ─────────────────────────────────────────────────────────────────────────
    if (supports30Min && isLeftHalf != null) {
      final leftKey = '${dateString}_${resolvedCourtId}_${slotId}_L';
      final rightKey = '${dateString}_${resolvedCourtId}_${slotId}_R';

      final hasLeft = multiDateSelections.containsKey(leftKey);
      final hasRight = multiDateSelections.containsKey(rightKey);
      final isSelected = hasLeft || hasRight;
      final tappingLeft = isLeftHalf == true;
      final slotBase = _convertTimeToMinutes(slot.time ?? '');
      if (slotBase == null) return;
      final tappedBlockStart = tappingLeft ? slotBase : slotBase + 30;

      // Upgrade case: other half already selected -> select full (both halves)
      if (hasLeft && !hasRight && !tappingLeft) {
        if (isRightHalfBooked(slot)) return;
        _upsertHalfSelection(
          slot: slot,
          courtId: resolvedCourtId,
          courtName: resolvedCourtName,
          dateString: dateString,
          currentDate: currentDate,
          isLeftHalf: false,
        );
        _recalculateTotalAmount();
        return;
      }
      if (hasRight && !hasLeft && tappingLeft) {
        if (isLeftHalfBooked(slot)) return;
        _upsertHalfSelection(
          slot: slot,
          courtId: resolvedCourtId,
          courtName: resolvedCourtName,
          dateString: dateString,
          currentDate: currentDate,
          isLeftHalf: true,
        );
        _recalculateTotalAmount();
        return;
      }

      final blocks = _getSelectedHalfBlocksForCourtDate(
        courtId: resolvedCourtId,
        dateString: dateString,
      );

      // SELECTING (slot not selected)
      if (!isSelected) {
        if (blocks.isEmpty) {
          // Nothing selected yet -> always select FULL slot (both halves)
          if (isLeftHalfBooked(slot) || isRightHalfBooked(slot)) return;
          if (!_ensureMaxSlotsCapacity(addCount: 2)) return;
          _upsertHalfSelection(
            slot: slot,
            courtId: resolvedCourtId,
            courtName: resolvedCourtName,
            dateString: dateString,
            currentDate: currentDate,
            isLeftHalf: true,
          );
          _upsertHalfSelection(
            slot: slot,
            courtId: resolvedCourtId,
            courtName: resolvedCourtName,
            dateString: dateString,
            currentDate: currentDate,
            isLeftHalf: false,
          );
          _recalculateTotalAmount();
          return;
        }

        final rangeStart = blocks.first;
        final rangeEnd = blocks.last; // last block start
        final slotEnd = slotBase + 60;

        if (slotEnd == rangeStart) {
          // Slot directly BEFORE range -> add RIGHT half only
          if (isRightHalfBooked(slot)) return;
          if (!_ensureMaxSlotsCapacity(addCount: 1)) return;
          _upsertHalfSelection(
            slot: slot,
            courtId: resolvedCourtId,
            courtName: resolvedCourtName,
            dateString: dateString,
            currentDate: currentDate,
            isLeftHalf: false,
          );
        } else if (slotBase == rangeEnd + 30) {
          // Slot directly AFTER range -> add LEFT half only
          if (isLeftHalfBooked(slot)) return;
          if (!_ensureMaxSlotsCapacity(addCount: 1)) return;
          _upsertHalfSelection(
            slot: slot,
            courtId: resolvedCourtId,
            courtName: resolvedCourtName,
            dateString: dateString,
            currentDate: currentDate,
            isLeftHalf: true,
          );
        } else {
          // Not consecutive -> select FULL slot (both halves)
          if (isLeftHalfBooked(slot) || isRightHalfBooked(slot)) return;
          if (!_ensureMaxSlotsCapacity(addCount: 2)) return;
          _upsertHalfSelection(
            slot: slot,
            courtId: resolvedCourtId,
            courtName: resolvedCourtName,
            dateString: dateString,
            currentDate: currentDate,
            isLeftHalf: true,
          );
          _upsertHalfSelection(
            slot: slot,
            courtId: resolvedCourtId,
            courtName: resolvedCourtName,
            dateString: dateString,
            currentDate: currentDate,
            isLeftHalf: false,
          );
        }

        _cleanupIsolatedHalfSelections(
          courtId: resolvedCourtId,
          dateString: dateString,
        );
        _recalculateTotalAmount();
        return;
      }

      // DESELECTING (slot already selected)
      if (blocks.isEmpty) return;
      final rangeStart = blocks.first;
      final rangeEnd = blocks.last;
      final isAtStart = tappedBlockStart == rangeStart;
      final isAtEnd = tappedBlockStart == rangeEnd;

      // If selection is only one full slot (2 blocks) or one half (1 block) -> clear all for court+date
      if (blocks.length <= 2) {
        _removeAllHalfSelectionsForCourtDate(
          courtId: resolvedCourtId,
          dateString: dateString,
        );
        _recalculateTotalAmount();
        return;
      }

      if (isAtStart) {
        _removeHalfEdgeBlock(
          slot: slot,
          courtId: resolvedCourtId,
          courtName: resolvedCourtName,
          dateString: dateString,
          currentDate: currentDate,
          removingLeftSide: true,
        );
        _cleanupIsolatedHalfSelections(
          courtId: resolvedCourtId,
          dateString: dateString,
        );
        _recalculateTotalAmount();
        return;
      }

      if (isAtEnd) {
        _removeHalfEdgeBlock(
          slot: slot,
          courtId: resolvedCourtId,
          courtName: resolvedCourtName,
          dateString: dateString,
          currentDate: currentDate,
          removingLeftSide: false,
        );
        _cleanupIsolatedHalfSelections(
          courtId: resolvedCourtId,
          dateString: dateString,
        );
        _recalculateTotalAmount();
        return;
      }

      // Middle: if both halves selected, keep the opposite half; otherwise remove only tapped half
      if (hasLeft && hasRight) {
        if (tappingLeft) {
          multiDateSelections.remove(leftKey);
        } else {
          multiDateSelections.remove(rightKey);
        }
      } else {
        if (hasLeft) multiDateSelections.remove(leftKey);
        if (hasRight) multiDateSelections.remove(rightKey);
      }

      _cleanupIsolatedHalfSelections(
        courtId: resolvedCourtId,
        dateString: dateString,
      );
      _recalculateTotalAmount();
      return;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Non-30-min pricing: simple full-slot toggle
    // ─────────────────────────────────────────────────────────────────────────
    final fullKey = '${dateString}_${resolvedCourtId}_${slotId}';
    if (multiDateSelections.containsKey(fullKey)) {
      multiDateSelections.remove(fullKey);
      selectedSlots.removeWhere((s) => s.sId == slotId);
      selectedSlotsWithCourtInfo.remove('${resolvedCourtId}_$slotId');
    } else {
      if (!_ensureMaxSlotsCapacity(addCount: 1)) return;
      multiDateSelections[fullKey] = {
        'slot': slot,
        'courtId': resolvedCourtId,
        'courtName': resolvedCourtName,
        'date': dateString,
        'dateTime': currentDate,
        'bookingTime': slot.time ?? '',
        'isLeftHalf': null,
        'adjustedAmount': slot.amount ?? 0,
      };
      if (!selectedSlots.any((s) => s.sId == slotId)) selectedSlots.add(slot);
      selectedSlotsWithCourtInfo['${resolvedCourtId}_$slotId'] = {
        'slot': slot,
        'courtId': resolvedCourtId,
        'courtName': resolvedCourtName,
        'bookingTime': slot.time ?? '',
        'adjustedAmount': slot.amount ?? 0,
      };
    }

    _recalculateTotalAmount();
    _ensureSubscribedForAllSelectedDates();
  }

  bool _ensureMaxSlotsCapacity({required int addCount}) {
    if (addCount <= 0) return true;
    if (multiDateSelections.length + addCount > maxSlots) {
      CustomLogger.logMessage(
        msg: "Booking Limit Reached\nYou can select a maximum of $maxSlots slots.",
        level: LogLevel.error,
      );
      return false;
    }
    return true;
  }

  List<int> _getSelectedHalfBlocksForCourtDate({
    required String courtId,
    required String dateString,
  }) {
    final mins = <int>{};
    multiDateSelections.forEach((k, v) {
      if (!k.startsWith(dateString)) return;
      if ((v['courtId'] as String?) != courtId) return;
      final slot = v['slot'] as Slots;
      if (!slotSupports30Min(slot)) return;
      final base = _convertTimeToMinutes(slot.time ?? '');
      if (base == null) return;
      final isLeft = v['isLeftHalf'] as bool?;
      if (isLeft == null) return;
      mins.add(isLeft ? base : base + 30);
    });
    final list = mins.toList()..sort();
    return list;
  }

  void _removeAllHalfSelectionsForCourtDate({
    required String courtId,
    required String dateString,
  }) {
    final keys = multiDateSelections.keys.where((k) {
      final v = multiDateSelections[k];
      if (v == null) return false;
      if ((v['date'] as String?) != dateString) return false;
      if ((v['courtId'] as String?) != courtId) return false;
      final slot = v['slot'] as Slots;
      return slotSupports30Min(slot) && (v['isLeftHalf'] is bool);
    }).toList();

    final slotIds = <String>{};
    for (final k in keys) {
      final v = multiDateSelections[k]!;
      final slot = v['slot'] as Slots;
      slotIds.add(slot.sId ?? '');
      multiDateSelections.remove(k);
    }
    for (final slotId in slotIds) {
      selectedSlots.removeWhere((s) => s.sId == slotId);
      selectedSlotsWithCourtInfo.remove('${courtId}_$slotId');
    }
  }

  void _removeHalfEdgeBlock({
    required Slots slot,
    required String courtId,
    required String courtName,
    required String dateString,
    required DateTime currentDate,
    required bool removingLeftSide,
  }) {
    final slotId = slot.sId ?? '';
    final leftKey = '${dateString}_${courtId}_${slotId}_L';
    final rightKey = '${dateString}_${courtId}_${slotId}_R';
    final hasLeft = multiDateSelections.containsKey(leftKey);
    final hasRight = multiDateSelections.containsKey(rightKey);

    // If both halves exist, remove the edge half only
    if (hasLeft && hasRight) {
      if (removingLeftSide) {
        multiDateSelections.remove(leftKey);
      } else {
        multiDateSelections.remove(rightKey);
      }
      return;
    }

    // Otherwise remove whichever exists
    if (hasLeft) multiDateSelections.remove(leftKey);
    if (hasRight) multiDateSelections.remove(rightKey);
  }

  void _cleanupIsolatedHalfSelections({
    required String courtId,
    required String dateString,
  }) {
    bool changed = true;
    while (changed) {
      changed = false;
      final keysToRemove = <String>[];

      multiDateSelections.forEach((key, value) {
        if ((value['courtId'] as String?) != courtId) return;
        if ((value['date'] as String?) != dateString) return;
        final slot = value['slot'] as Slots;
        if (!slotSupports30Min(slot)) return;
        final isLeft = value['isLeftHalf'] as bool?;
        if (isLeft == null) return;

        final base = _convertTimeToMinutes(slot.time ?? '');
        if (base == null) return;
        final myBlock = isLeft ? base : base + 30;
        final neighbourBlocks = isLeft
            ? <int>{base - 30, base + 30} // prev slot OR same-slot right half
            : <int>{base, base + 60};     // same-slot left half OR next slot

        bool neighbourExists = false;
        multiDateSelections.forEach((k2, v2) {
          if (k2 == key) return;
          if ((v2['courtId'] as String?) != courtId) return;
          if ((v2['date'] as String?) != dateString) return;
          final s2 = v2['slot'] as Slots;
          if (!slotSupports30Min(s2)) return;
          final isLeft2 = v2['isLeftHalf'] as bool?;
          if (isLeft2 == null) return;
          final base2 = _convertTimeToMinutes(s2.time ?? '');
          if (base2 == null) return;
          final block2 = isLeft2 ? base2 : base2 + 30;
          if (neighbourBlocks.contains(block2)) neighbourExists = true;
        });

        if (!neighbourExists) keysToRemove.add(key);
      });

      if (keysToRemove.isEmpty) return;
      final removedSlotIds = <String>{};
      for (final k in keysToRemove) {
        final v = multiDateSelections[k];
        if (v != null) {
          final s = v['slot'] as Slots;
          removedSlotIds.add(s.sId ?? '');
        }
        multiDateSelections.remove(k);
        changed = true;
      }
      for (final slotId in removedSlotIds) {
        final stillExists = multiDateSelections.values.any((sel) {
          if ((sel['courtId'] as String?) != courtId) return false;
          if ((sel['date'] as String?) != dateString) return false;
          final s = sel['slot'] as Slots;
          return (s.sId ?? '') == slotId;
        });
        if (!stillExists) {
          selectedSlots.removeWhere((s) => s.sId == slotId);
          selectedSlotsWithCourtInfo.remove('${courtId}_$slotId');
        }
      }
    }
  }

  void _upsertHalfSelection({
    required Slots slot,
    required String courtId,
    required String courtName,
    required String dateString,
    required DateTime currentDate,
    required bool isLeftHalf,
  }) {
    final slotId = slot.sId ?? '';
    final slotKey = '${dateString}_${courtId}_${slotId}_${isLeftHalf ? 'L' : 'R'}';
    final compositeKey = '${courtId}_$slotId';

    final bookingTime =
        isLeftHalf ? (slot.time ?? '') : _addMinutesToTime(slot.time ?? '', 30);
    final adjustedAmount = (slot.amount ?? 0) ~/ 2;

    multiDateSelections[slotKey] = {
      'slot': slot,
      'courtId': courtId,
      'courtName': courtName,
      'date': dateString,
      'dateTime': currentDate,
      'bookingTime': bookingTime,
      'isLeftHalf': isLeftHalf,
      'adjustedAmount': adjustedAmount,
    };

    if (!selectedSlots.any((s) => s.sId == slotId)) selectedSlots.add(slot);
    selectedSlotsWithCourtInfo[compositeKey] = {
      'slot': slot,
      'courtId': courtId,
      'courtName': courtName,
      'bookingTime': bookingTime,
      'adjustedAmount': adjustedAmount,
    };
  }

  void _removeSlotAndAllAfter(Slots slot, String courtId, String dateString) {
    final slotTimeMinutes = _convertTimeToMinutes(slot.time ?? '');
    if (slotTimeMinutes == null) return;

    final keysToRemove = <String>[];
    final slotIdsToRemove = <String>{};

    multiDateSelections.forEach((key, selection) {
      if (key.startsWith(dateString)) {
        final selectionSlot = selection['slot'] as Slots;
        final selectionCourtId = selection['courtId'] as String;
        final selectionTimeMinutes = _convertTimeToMinutes(selectionSlot.time ?? '');

        if (selectionCourtId == courtId && 
            selectionTimeMinutes != null && 
            selectionTimeMinutes >= slotTimeMinutes) {
          keysToRemove.add(key);
          slotIdsToRemove.add(selectionSlot.sId ?? '');
        }
      }
    });

    for (final key in keysToRemove) {
      multiDateSelections.remove(key);
    }

    for (final slotId in slotIdsToRemove) {
      selectedSlots.removeWhere((s) => s.sId == slotId);
      selectedSlotsWithCourtInfo.remove('${courtId}_$slotId');
    }

    log('Removed ${keysToRemove.length} slots to maintain continuity');
  }

  int? _convertTimeToMinutes(String timeString) {
    if (timeString.isEmpty) return null;
    
    try {
      final trimmed = timeString.trim().toLowerCase();
      final parts = trimmed.split(' ');
      
      if (parts.length != 2) return null;
      
      final timePart = parts[0];
      final meridiem = parts[1];
      
      int hour;
      int minute = 0;
      
      if (timePart.contains(':')) {
        final timePieces = timePart.split(':');
        hour = int.parse(timePieces[0]);
        minute = int.parse(timePieces[1]);
      } else {
        hour = int.parse(timePart);
      }
      
      if (meridiem == 'pm' && hour != 12) {
        hour += 12;
      } else if (meridiem == 'am' && hour == 12) {
        hour = 0;
      }
      
      return hour * 60 + minute;
    } catch (e) {
      log('ERROR: Failed to convert "$timeString" to minutes: $e');
      return null;
    }
  }

  void _addSlotGroup(Slots primarySlot, String courtId, String courtName, String dateString, DateTime currentDate, bool? isLeftHalf) {
    final slotsToSelect = <Slots>[];
    final supports30Min = slotSupports30Min(primarySlot);
    
    final courtData = slots.value?.data?.firstWhere((court) => court.sId == courtId);
    if (courtData?.slots == null) return;
    
    final allSlots = courtData!.slots!;
    final primarySlotIndex = allSlots.indexWhere((s) => s.sId == primarySlot.sId);
    if (primarySlotIndex == -1) return;
    
    if (supports30Min && isLeftHalf != null) {
      slotsToSelect.add(primarySlot);
    } else {
      slotsToSelect.add(primarySlot);
    }
    
    final slotId = primarySlot.sId ?? '';
    final leftKey = '${dateString}_${courtId}_${slotId}_L';
    final rightKey = '${dateString}_${courtId}_${slotId}_R';
    final fullKey = '${dateString}_${courtId}_${slotId}';
    
    final isSlotAlreadySelected = multiDateSelections.containsKey(leftKey) || 
                                  multiDateSelections.containsKey(rightKey) || 
                                  multiDateSelections.containsKey(fullKey);
    
    if (!isSlotAlreadySelected && multiDateSelections.length + slotsToSelect.length > maxSlots) {
      CustomLogger.logMessage(msg: "Booking Limit Reached\nYou can select a maximum of $maxSlots slots.", level: LogLevel.error);
      return;
    }
    
    _fillGapsBeforeSlot(primarySlot, courtId, courtName, dateString, currentDate, isLeftHalf, allSlots);
    
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
      
      log('DEBUG: Stored in multiDateSelections - key: $slotKey, bookingTime: $bookingTime, adjustedAmount: $adjustedAmount');
      
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
  
  void _fillGapsBeforeSlot(Slots targetSlot, String courtId, String courtName, String dateString, DateTime currentDate, bool? isLeftHalf, List<Slots> allSlots) {
    if (multiDateSelections.isEmpty) return;
    
    final targetTimeMinutes = _convertTimeToMinutes(targetSlot.time ?? '');
    if (targetTimeMinutes == null) return;
    
    final supports30Min = slotSupports30Min(targetSlot);
    final targetSlotId = targetSlot.sId ?? '';
    
    if (supports30Min && isLeftHalf == false) {
      final leftKey = '${dateString}_${courtId}_${targetSlotId}_L';
      if (!multiDateSelections.containsKey(leftKey)) {
        // Check if left half is booked before auto-selecting
        if (isLeftHalfBooked(targetSlot)) {
          log('Cannot auto-select left half of ${targetSlot.time} - it is booked');
          return;
        }
        
        final bookingTime = targetSlot.time ?? '';
        final adjustedAmount = (targetSlot.amount ?? 0) ~/ 2;
        
        multiDateSelections[leftKey] = {
          'slot': targetSlot,
          'courtId': courtId,
          'courtName': courtName,
          'date': dateString,
          'dateTime': currentDate,
          'bookingTime': bookingTime,
          'isLeftHalf': true,
          'adjustedAmount': adjustedAmount,
        };
        
        if (!selectedSlots.any((s) => s.sId == targetSlotId)) {
          selectedSlots.add(targetSlot);
        }
        
        log('Auto-selected left half of ${targetSlot.time} to maintain continuity');
      }
    }
    
    int? latestSelectedTimeMinutes;
    Slots? latestSelectedSlot;
    
    multiDateSelections.forEach((key, selection) {
      if (key.startsWith(dateString)) {
        final selectionSlot = selection['slot'] as Slots;
        final selectionCourtId = selection['courtId'] as String;
        
        if (selectionCourtId == courtId) {
          final timeMinutes = _convertTimeToMinutes(selectionSlot.time ?? '');
          if (timeMinutes != null && (latestSelectedTimeMinutes == null || timeMinutes > latestSelectedTimeMinutes!)) {
            latestSelectedTimeMinutes = timeMinutes;
            latestSelectedSlot = selectionSlot;
          }
        }
      }
    });
    
    if (latestSelectedTimeMinutes == null || latestSelectedSlot == null) return;
    if (targetTimeMinutes <= latestSelectedTimeMinutes!) return;
    
    final slotsToFill = <Slots>[];
    for (final slot in allSlots) {
      final slotTimeMinutes = _convertTimeToMinutes(slot.time ?? '');
      if (slotTimeMinutes != null && 
          slotTimeMinutes > latestSelectedTimeMinutes! && 
          slotTimeMinutes < targetTimeMinutes) {
        // CRITICAL FIX: Check if slot is booked before adding to fill list
        final isSlotBooked = isLeftHalfBooked(slot) || isRightHalfBooked(slot);
        if (!isSlotBooked) {
          slotsToFill.add(slot);
        } else {
          log('Skipping booked slot ${slot.time} in gap filling');
        }
      }
    }
    
    for (final gapSlot in slotsToFill) {
      final supports30Min = slotSupports30Min(gapSlot);
      final gapSlotId = gapSlot.sId ?? '';
      
      if (supports30Min) {
        final leftKey = '${dateString}_${courtId}_${gapSlotId}_L';
        final rightKey = '${dateString}_${courtId}_${gapSlotId}_R';
        
        if (!multiDateSelections.containsKey(leftKey) && !isLeftHalfBooked(gapSlot)) {
          final bookingTime = gapSlot.time ?? '';
          final adjustedAmount = (gapSlot.amount ?? 0) ~/ 2;
          
          multiDateSelections[leftKey] = {
            'slot': gapSlot,
            'courtId': courtId,
            'courtName': courtName,
            'date': dateString,
            'dateTime': currentDate,
            'bookingTime': bookingTime,
            'isLeftHalf': true,
            'adjustedAmount': adjustedAmount,
          };
          
          if (!selectedSlots.any((s) => s.sId == gapSlotId)) {
            selectedSlots.add(gapSlot);
          }
        }
        
        if (!multiDateSelections.containsKey(rightKey) && !isRightHalfBooked(gapSlot)) {
          final originalTime = gapSlot.time ?? '';
          final bookingTime = _addMinutesToTime(originalTime, 30);
          final adjustedAmount = (gapSlot.amount ?? 0) ~/ 2;
          
          multiDateSelections[rightKey] = {
            'slot': gapSlot,
            'courtId': courtId,
            'courtName': courtName,
            'date': dateString,
            'dateTime': currentDate,
            'bookingTime': bookingTime,
            'isLeftHalf': false,
            'adjustedAmount': adjustedAmount,
          };
          
          if (!selectedSlots.any((s) => s.sId == gapSlotId)) {
            selectedSlots.add(gapSlot);
          }
        }
      } else {
        final fullKey = '${dateString}_${courtId}_${gapSlotId}';
        if (!multiDateSelections.containsKey(fullKey)) {
          multiDateSelections[fullKey] = {
            'slot': gapSlot,
            'courtId': courtId,
            'courtName': courtName,
            'date': dateString,
            'dateTime': currentDate,
            'bookingTime': gapSlot.time ?? '',
            'isLeftHalf': null,
            'adjustedAmount': gapSlot.amount ?? 0,
          };
          
          if (!selectedSlots.any((s) => s.sId == gapSlotId)) {
            selectedSlots.add(gapSlot);
          }
        }
      }
    }
    
    log('Filled ${slotsToFill.length} gap slots to maintain continuity (skipped booked slots)');
  }
  
  void _removeSlotGroup(Slots primarySlot, String courtId, String dateString) {
    final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    
    // Find all slots for this court
    final courtData = slots.value?.data?.firstWhere((court) => court.sId == courtId);
    if (courtData?.slots == null) return;
    
    final allSlots = courtData!.slots!;
    final primarySlotIndex = allSlots.indexWhere((s) => s.sId == primarySlot.sId);
    if (primarySlotIndex == -1) return;
    
    // Calculate how many slots to remove based on duration
    int slotsToRemove;
    switch (selectedDurationMinutes) {
      case 30:
        slotsToRemove = 1;
        break;
      case 60:
        slotsToRemove = 2;
        break;
      case 90:
        slotsToRemove = 3;
        break;
      case 120:
        slotsToRemove = 4;
        break;
      default:
        slotsToRemove = 2;
    }
    
    // Remove all slots in the group
    for (int i = 0; i < slotsToRemove; i++) {
      final slotIndex = primarySlotIndex + i;
      if (slotIndex >= allSlots.length) break;
      
      final slotToRemove = allSlots[slotIndex];
      final slotKey = '${dateString}_${courtId}_${slotToRemove.sId}';
      final compositeKey = '${courtId}_${slotToRemove.sId}';
      
      multiDateSelections.remove(slotKey);
      selectedSlots.removeWhere((s) => s.sId == slotToRemove.sId);
      selectedSlotsWithCourtInfo.remove(compositeKey);
    }
  }

  void _recalculateTotalAmount() {
    int total = 0;
    multiDateSelections.forEach((key, selection) {
      final adjustedAmount = selection['adjustedAmount'] as int?;
      if (adjustedAmount != null) {
        total += adjustedAmount;
        log('Adding adjustedAmount: $adjustedAmount for key: $key');
      } else {
        final slot = selection['slot'] as Slots;
        final slotAmount = slot.amount ?? 0;
        total += slotAmount;
        log('Adding slot.amount: $slotAmount for key: $key');
      }
    });
    totalAmount.value = total;
    log('Total amount recalculated: $total');
  }

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

  bool isPastAndUnavailable(Slots slot) {
    final status = slot.status?.toLowerCase() ?? '';
    // Don't filter out booked/maintenance/etc slots - we want to show them in red
    if (status.isNotEmpty && status != 'available' && status != 'booked') return false;

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

      if (isToday) {
        final slotEndTime = slotDateTime.add(const Duration(minutes: 15));
        if (now.isAfter(slotEndTime)) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  bool _isUnavailableSlot(Slots slot) {
    final availability = slot.availabilityStatus?.toLowerCase();
    final isBlocked = availability == "maintenance" ||
        availability == "weather conditions" ||
        availability == "staff unavailability"||
        availability == "tournament";
    // Don't consider booked slots as unavailable - they should be shown in red
    final isPast = isPastAndUnavailable(slot);
    
    // For 30-minute duration, check if any half is booked
    final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    bool isHalfBooked = false;
    if (selectedDurationMinutes == 30) {
      isHalfBooked = isLeftHalfBooked(slot) || isRightHalfBooked(slot);
    }
    
    // Only consider past or blocked slots as unavailable (not booked slots)
    return isPast || isBlocked;
  }

  bool _isAvailableSlot(Slots slot) {
    // Only filter out truly past slots
    // Booked, maintenance, weather, tournament etc. will be shown in red in UI
    return !isPastAndUnavailable(slot);
  }

  /// Check if left half of a 30-minute slot is booked
  bool isLeftHalfBooked(Slots slot) {
    // If status is booked or locked, entire slot is booked
    if (slot.status?.toLowerCase() == 'booked') return true;
    if (slot.status?.toLowerCase() == 'lock') return true;
    
    // Check if bookingTime exists and is not empty
    final bookingTime = slot.bookingTime?.trim();
    if (bookingTime == null || bookingTime.isEmpty) return false;
    
    final originalTime = slot.time ?? '';
    
    // Check duration from API - if 60, whole slot is booked
    if (slot.duration == 60) return true;
    
    // If duration is 30, check booking time to determine which half
    if (slot.duration == 30) {
      // If booking time equals original time (e.g., both are "5:00 PM"), left half is booked
      final normalizedBooking = _normalizeTime(bookingTime);
      final normalizedOriginal = _normalizeTime(originalTime);
      log('Left half check - booking: $normalizedBooking, original: $normalizedOriginal, match: ${normalizedBooking == normalizedOriginal}');
      return normalizedBooking == normalizedOriginal;
    }
    
    // Fallback: compare normalized times
    return _normalizeTime(bookingTime) == _normalizeTime(originalTime);
  }

  /// Check if right half of a 30-minute slot is booked
  bool isRightHalfBooked(Slots slot) {
    // If status is booked or locked, entire slot is booked
    if (slot.status?.toLowerCase() == 'booked') return true;
    if (slot.status?.toLowerCase() == 'lock') return true;
    
    // Check if bookingTime exists and is not empty
    final bookingTime = slot.bookingTime?.trim();
    if (bookingTime == null || bookingTime.isEmpty) return false;
    
    final originalTime = slot.time ?? '';
    
    // Check duration from API - if 60, whole slot is booked
    if (slot.duration == 60) return true;
    
    // If duration is 30, check booking time to determine which half
    if (slot.duration == 30) {
      // If booking time is 30 minutes after original time (e.g., "12:30 PM" vs "12 PM"), right half is booked
      final expectedRightTime = _addMinutesToTime(originalTime, 30);
      final normalizedBooking = _normalizeTime(bookingTime);
      final normalizedExpected = _normalizeTime(expectedRightTime);
      log('Right half check - originalTime: $originalTime, expectedRightTime: $expectedRightTime');
      log('Right half check - booking: $normalizedBooking, expected: $normalizedExpected, match: ${normalizedBooking == normalizedExpected}');
      return normalizedBooking == normalizedExpected;
    }
    
    // Fallback: compare with 30 minutes added
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
  
  /// Check if left half of a slot is selected (only for slots that support 30-minute pricing)
  bool _isLeftHalfSelected(Slots slot, String courtId) {
    if (!slotSupports30Min(slot)) return false;
    
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final leftKey = '${dateString}_${courtId}_${slot.sId}_L';
    return multiDateSelections.containsKey(leftKey);
  }
  
  /// Check if right half of a slot is selected (only for slots that support 30-minute pricing)
  bool _isRightHalfSelected(Slots slot, String courtId) {
    if (!slotSupports30Min(slot)) return false;
    
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final rightKey = '${dateString}_${courtId}_${slot.sId}_R';
    return multiDateSelections.containsKey(rightKey);
  }

  /// Add minutes to a time string
  String _addMinutesToTime(String timeString, int minutesToAdd) {
    if (timeString.isEmpty) return timeString;
    
    try {
      // Manual parsing for formats like "1 pm", "12 pm", "1:30 pm"
      final trimmed = timeString.trim().toLowerCase();
      final parts = trimmed.split(' ');
      
      if (parts.length != 2) return timeString;
      
      final timePart = parts[0];
      final meridiem = parts[1]; // "am" or "pm"
      
      int hour;
      int minute = 0;
      
      if (timePart.contains(':')) {
        final timePieces = timePart.split(':');
        hour = int.parse(timePieces[0]);
        minute = int.parse(timePieces[1]);
      } else {
        hour = int.parse(timePart);
      }
      
      // Convert to 24-hour format
      if (meridiem == 'pm' && hour != 12) {
        hour += 12;
      } else if (meridiem == 'am' && hour == 12) {
        hour = 0;
      }
      
      // Create DateTime and add minutes
      final now = DateTime.now();
      final time = DateTime(now.year, now.month, now.day, hour, minute);
      final newTime = time.add(Duration(minutes: minutesToAdd));
      
      // Format back to "h:mm a"
      final result = DateFormat('h:mm a').format(newTime);
      log('_addMinutesToTime SUCCESS: "$timeString" + $minutesToAdd min = "$result"');
      return result;
    } catch (e) {
      log('ERROR: Failed to parse "$timeString": $e');
      return timeString;
    }
  }

  /// Normalize time format for comparison (convert to consistent format)
  String _normalizeTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    final trimmed = timeString.trim().toLowerCase(); // Convert to lowercase
    
    try {
      // Try parsing with minutes first (e.g., "5:00 pm")
      final time = DateFormat('h:mm a').parse(trimmed);
      return DateFormat('h:mm a').format(time).toUpperCase();
    } catch (_) {
      try {
        // Try parsing without minutes (e.g., "5 pm")
        final time = DateFormat('h a').parse(trimmed);
        return DateFormat('h:mm a').format(time).toUpperCase();
      } catch (_) {
        // Return uppercase trimmed string as fallback
        return trimmed.toUpperCase();
      }
    }
  }

  var cartLoader = false.obs;

  /// Build booking payload from multiDateSelections (same structure as CartController.buildBookingPayload).
  /// Used when skipping cart and going directly to payment.
  List<Map<String, dynamic>>? buildBookingPayloadFromSelections() {
    if (multiDateSelections.isEmpty) return null;

    final clubId = argument.id ?? '';
    if (clubId.isEmpty) return null;

    final registerClub = slots.value?.data?.firstOrNull?.registerClubId;
    final ownerIdStr = registerClub?.ownerId?.sId?.toString() ??
        argument.ownerId ??
        '';

    final List<Map<String, dynamic>> slotData = [];
    final Map<String, Map<String, dynamic>> consolidatedSlots = {};

    // First pass: identify slots that need consolidation (both halves selected)
    multiDateSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final slotId = slot.sId ?? '';
      final supports30Min = slotSupports30Min(slot);

      if (supports30Min && (key.endsWith('_L') || key.endsWith('_R'))) {
        if (!consolidatedSlots.containsKey(slotId)) {
          consolidatedSlots[slotId] = {
            'leftHalf': null,
            'rightHalf': null,
            'slot': slot,
            'courtId': selection['courtId'],
            'courtName': selection['courtName'],
            'dateString': selection['date'],
          };
        }
        if (key.endsWith('_L')) {
          consolidatedSlots[slotId]!['leftHalf'] = selection;
        } else {
          consolidatedSlots[slotId]!['rightHalf'] = selection;
        }
      }
    });

    String bookingDayFor(String dateString) {
      try {
        final d = DateTime.parse(dateString);
        return _getWeekday(d.weekday);
      } catch (_) {
        return '';
      }
    }

    void addSlotEntry({
      required Slots slot,
      required String courtId,
      required String courtName,
      required String dateString,
      required String bookingTime,
      required int amount,
      required int duration,
    }) {
      final bookingDay = bookingDayFor(dateString);
      final selectedBusinessHour = slot.businessHours
          ?.where((bh) => bh.day == bookingDay)
          .map((bh) => {'time': bh.time ?? '', 'day': bh.day ?? ''})
          .toList() ?? [];
      
      // Use slot's duration from API if it's 90, otherwise use calculated duration
      final finalDuration = (slot.duration == 90) ? 90 : duration;
      
      slotData.add({
        'slotId': slot.sId ?? '',
        'businessHours': selectedBusinessHour,
        'slotTimes': [
          {'time': slot.time ?? '', 'amount': amount}
        ],
        'courtId': courtId,
        'courtName': courtName,
        'bookingDate': dateString,
        'duration': finalDuration,
        'totalTime': finalDuration,
        'bookingTime': bookingTime,
        'type':"booked"
      });
    }

    // Track processed consolidated slots to avoid duplicates
    final processedConsolidatedSlots = <String>{};

    // Second pass: build slotData
    multiDateSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final courtId = selection['courtId'] as String;
      final courtName = selection['courtName'] as String;
      final dateString = selection['date'] as String;
      final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
      final adjustedAmount = selection['adjustedAmount'] as int? ?? slot.amount ?? 0;
      final slotId = slot.sId ?? '';
      final supports30Min = slotSupports30Min(slot);

      if (supports30Min && (key.endsWith('_L') || key.endsWith('_R'))) {
        final consolidated = consolidatedSlots[slotId];
        if (consolidated != null &&
            consolidated['leftHalf'] != null &&
            consolidated['rightHalf'] != null) {
          // Both halves selected - create one consolidated entry
          if (!processedConsolidatedSlots.contains(slotId)) {
            final fullPrice = slot.amount ?? 0;
            addSlotEntry(
              slot: slot,
              courtId: courtId,
              courtName: courtName,
              dateString: dateString,
              bookingTime: slot.time ?? '', // Use original slot time for full booking
              amount: fullPrice,
              duration: 60,
            );
            processedConsolidatedSlots.add(slotId);
          }
          return;
        }
        // Only one half selected
        addSlotEntry(
          slot: slot,
          courtId: courtId,
          courtName: courtName,
          dateString: dateString,
          bookingTime: bookingTime,
          amount: adjustedAmount,
          duration: 30,
        );
        return;
      }

      // Regular full slot selection
      addSlotEntry(
        slot: slot,
        courtId: courtId,
        courtName: courtName,
        dateString: dateString,
        bookingTime: bookingTime,
        amount: adjustedAmount,
        duration: 60,
      );
    });

    if (slotData.isEmpty) return null;

    return [
      {
        'slot': slotData,
        'register_club_id': clubId,
        'ownerId': ownerIdStr,
        'categoryId': categoryId.value,
        'location': locationsId.value,
        'stateId': locationID.value,
      },
    ];
  }

  /// Skip cart: process slot history, build payload, create initial booking, then navigate to payment.
  Future<void> proceedToPayment() async {
    try {
      if (cartLoader.value) return;
      if (multiDateSelections.isEmpty) return;

      cartLoader.value = true;

      log('💳 proceedToPayment called with ${multiDateSelections.length} selections');
      
      // Use processSlotHistoryForPayment instead of processSlotHistoryForBooking
      final success = await processSlotHistoryForPayment();
      if (!success) {
        log('❌ processSlotHistoryForPayment failed');
        cartLoader.value = false;
        return;
      }

      log('✅ processSlotHistoryForPayment succeeded');
      
      final payload = buildBookingPayloadFromSelections();
      if (payload == null || payload.isEmpty) {
        log('❌ buildBookingPayloadFromSelections returned empty');
        cartLoader.value = false;
        return;
      }

      final paymentController = Get.put(PaymentMethodController());
      paymentController.setDirectBookingPayload(payload);
      
      // Set flag to indicate we're going to payment page
      // This will be used to check if user returns without completing payment
      final currentRoute = Get.currentRoute;
      log('💳 Navigating to payment page from: $currentRoute');
      
      await paymentController.createInitialBooking();
    } catch (e) {
      log('proceedToPayment error: $e');
    } finally {
      cartLoader.value = false;
    }
  }

  Future<bool> processSlotHistoryForBooking() async {
    if (multiDateSelections.isEmpty) return false;

    try {
      final slots = <Map<String, dynamic>>[];
      
      // Group selections by slot ID to detect both halves
      final Map<String, List<MapEntry<String, Map<String, dynamic>>>> slotGroups = {};
      for (var entry in multiDateSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final dateString = selection['date'] as String;
        final groupKey = '${dateString}_${courtId}_${slotId}';
        
        if (!slotGroups.containsKey(groupKey)) {
          slotGroups[groupKey] = [];
        }
        slotGroups[groupKey]!.add(entry);
      }
      
      // Process each group
      for (var group in slotGroups.values) {
        if (group.isEmpty) continue;
        
        final firstEntry = group.first;
        final selection = firstEntry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final dateString = selection['date'] as String;
        final supports30Min = slotSupports30Min(slot);
        
        // Check if both halves are selected
        final hasLeftHalf = group.any((e) => e.value['isLeftHalf'] == true);
        final hasRightHalf = group.any((e) => e.value['isLeftHalf'] == false);
        final bothHalvesSelected = hasLeftHalf && hasRightHalf;
        
        if (supports30Min && bothHalvesSelected) {
          // Both halves selected - create ONE entry with 60 minutes
          final finalDuration = (slot.duration == 90) ? 90 : 60;
          final userId = storage.read("userId")??"";
          slots.add({
            "slotId": slotId,
            "courtId": courtId,
            "courtName": courtName,
            "bookingDate": dateString,
            "time": slot.time ?? '',
            "bookingTime": slot.time ?? '',
            "duration": finalDuration,
            "totalTime": finalDuration,
            "userId":userId
          });
        } else {
          // Single half or full slot - create entries as is
          for (var entry in group) {
            final sel = entry.value;
            final bookingTime = sel['bookingTime'] as String? ?? slot.time ?? '';
            final isLeftHalf = sel['isLeftHalf'] as bool?;
            final duration = (supports30Min && isLeftHalf != null) ? 30 : 60;
            final finalDuration = (slot.duration == 90) ? 90 : duration;
            final userId = storage.read("userId")??"";
            slots.add({
              "slotId": slotId,
              "courtId": courtId,
              "courtName": courtName,
              "bookingDate": dateString,
              "time": bookingTime,
              "bookingTime": bookingTime,
              "duration": finalDuration,
              "totalTime": finalDuration,
              "userId":userId
            });
          }
        }
      }
      
      // NOW lock the slots by calling createAndGetSlotHistory
      log('🔒 Locking slots on Book Now button tap: $slots');
      final success = await createAndGetSlotHistory(slots: slots);
      if (success) {
        hasCalledSlotHistoryAPI.value = true;
        log('✅ Slots successfully locked');
      } else {
        log('❌ Failed to lock slots');
      }
      return success;
    } catch (e) {
      log('Error processing slot history: $e');
      return false;
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

  int getSelectedSlotsCountForCourt(String courtId) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = _dateFormatter.format(currentDate);
    final consolidatedCount = <String>{};

    multiDateSelections.forEach((key, selection) {
      if (key.startsWith(dateString) && key.contains('_${courtId}_')) {
        final slot = selection['slot'] as Slots;
        final supports30Min = slotSupports30Min(slot);
        
        if (supports30Min && (key.endsWith('_L') || key.endsWith('_R'))) {
          // For half-slots, use the base key without the _L/_R suffix
          final baseKey = '${dateString}_${courtId}_${slot.sId}';
          consolidatedCount.add(baseKey);
        } else {
          // For full slots, use the key as-is
          consolidatedCount.add(key);
        }
      }
    });
    
    return consolidatedCount.length;
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

  int getTotalSelectionsCount() {
    final consolidatedCount = <String>{};
    
    multiDateSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final courtId = selection['courtId'] as String;
      final dateString = selection['date'] as String;
      final supports30Min = slotSupports30Min(slot);
      
      if (supports30Min && (key.endsWith('_L') || key.endsWith('_R'))) {
        // For half-slots, use the base key without the _L/_R suffix
        final baseKey = '${dateString}_${courtId}_${slot.sId}';
        consolidatedCount.add(baseKey);
      } else {
        // For full slots, use the key as-is
        consolidatedCount.add(key);
      }
    });
    
    return consolidatedCount.length;
  }

  Map<String, List<Map<String, dynamic>>> getSelectionsByDate() {
    final Map<String, List<Map<String, dynamic>>> result = {};
    final Map<String, Map<String, dynamic>> consolidatedSlots = {};

    // First pass: identify and consolidate half-slots
    multiDateSelections.forEach((key, selection) {
      final dateString = selection['date'] as String;
      final slot = selection['slot'] as Slots;
      final supports30Min = slotSupports30Min(slot);
      final slotId = slot.sId ?? '';
      
      if (supports30Min && (key.endsWith('_L') || key.endsWith('_R'))) {
        // This is a half-slot selection
        final baseKey = '${dateString}_${slotId}';
        
        if (!consolidatedSlots.containsKey(baseKey)) {
          consolidatedSlots[baseKey] = {
            'leftHalf': null,
            'rightHalf': null,
            'slot': slot,
            'courtId': selection['courtId'],
            'courtName': selection['courtName'],
            'date': dateString,
          };
        }
        
        if (key.endsWith('_L')) {
          consolidatedSlots[baseKey]!['leftHalf'] = selection;
        } else {
          consolidatedSlots[baseKey]!['rightHalf'] = selection;
        }
      } else {
        // Regular full slot selection
        if (!result.containsKey(dateString)) {
          result[dateString] = [];
        }
        result[dateString]!.add(selection);
      }
    });
    
    // Second pass: add consolidated slots to result
    consolidatedSlots.forEach((baseKey, consolidatedSlot) {
      final dateString = consolidatedSlot['date'] as String;
      final leftHalf = consolidatedSlot['leftHalf'];
      final rightHalf = consolidatedSlot['rightHalf'];
      
      if (!result.containsKey(dateString)) {
        result[dateString] = [];
      }
      
      if (leftHalf != null && rightHalf != null) {
        // Both halves selected - create a single consolidated entry
        final slot = consolidatedSlot['slot'] as Slots;
        result[dateString]!.add({
          'slot': slot,
          'courtId': consolidatedSlot['courtId'],
          'courtName': consolidatedSlot['courtName'],
          'date': dateString,
          'bookingTime': slot.time ?? '', // Use original time for full slot
          'adjustedAmount': slot.amount ?? 0, // Use full slot price
          'isConsolidated': true,
        });
      } else {
        // Only one half selected - add the individual half
        final halfSelection = leftHalf ?? rightHalf;
        if (halfSelection != null) {
          result[dateString]!.add(halfSelection);
        }
      }
    });

    return result;
  }

  void clearAllSelections() {
    multiDateSelections.clear();
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    totalAmount.value = 0;
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
        duration: '',
        day: '', // Get all days
        timePeriod: '', // Get all time periods
        locationId: locationID.value,
        categoryId: categoryId.value,
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
    
    final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    
    for (var court in result.data!) {
      if (court.slots == null) continue;
      
      for (var slot in court.slots!) {
        final slotTime = slot.time;
        if (slotTime == null) continue;
        
        int? slotPrice;
        
        if (selectedDurationMinutes == 90) {
          // For 90min: get 60min price + 30min price
          final price60 = _findPriceForSlot(slotTime, day, 60);
          final price30 = _findPriceForSlot(slotTime, day, 30);
          if (price60 != null && price30 != null) {
            slotPrice = price60 + price30;
          }
        } else {
          // For other durations, use the duration price directly
          final duration = selectedDurationMinutes == 120 ? 60 : selectedDurationMinutes;
          slotPrice = _findPriceForSlot(slotTime, day, duration);
        }
        
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

  /// Subscribe to slot-wise updates using SlotWiseService
  // Track all currently subscribed dates
  final Set<String> _subscribedDates = {};

  void _subscribeToSlotUpdates() {
    try {
      final date = selectedDate.value ?? DateTime.now();
      final formattedDate = _dateFormatter.format(date);
      _subscribeForDate(formattedDate, fallbackToApi: true);
    } catch (e) {
      log('Error subscribing to slot updates: $e');
      getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
    }
  }

  void _subscribeForDate(String formattedDate, {bool fallbackToApi = false}) {
    if (_subscribedDates.contains(formattedDate)) {
      log('Already subscribed to date: $formattedDate');
      return;
    }
    
    try {
      final socketService = SocketService.instance;
      
      // Check if socket is connected before subscribing
      if (!socketService.isConnected) {
        log('⚠️ Socket not connected, connecting first...');
        socketService.connect();
        
        // Wait for connection and retry
        Future.delayed(const Duration(seconds: 2), () {
          if (socketService.isConnected) {
            log('✅ Socket connected, retrying subscription');
            _subscribeForDate(formattedDate, fallbackToApi: fallbackToApi);
          } else {
            log('❌ Socket connection failed, falling back to API');
            if (fallbackToApi) {
              getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
            }
          }
        });
        return;
      }
      
      final date = DateTime.parse(formattedDate);
      final formattedDay = _getWeekday(date.weekday);

      log('📡 Subscribing to slot-wise updates for date: $formattedDate');
      
      _slotWiseService.subscribeToSlotWise(
        clubId: argument.id ?? '',
        date: formattedDate,
        locationId: locationID.value,
        categoryId: categoryId.value,
        sId: sId.value,
        locId: locationsId.value,
        day: formattedDay,
        onInitialData: (data) {
          log('📡 SlotWise acknowledgment received for date: $formattedDate');
          isSocketDataReceived.value = true;
          _handleInitialSlotData(data);
        },
        onSlotUpdate: (data) {
          log('🔄 SlotWise real-time update received for date: $formattedDate');
          _handleRealTimeSlotUpdate(data);
          _checkAndUnselectLockedSlots(data);
        },
      );
      
      _subscribedDates.add(formattedDate);
      log('✅ Subscribed to slot-wise updates for club: ${argument.id}, date: $formattedDate');

      // Fallback to API if no socket data received within 5 seconds
      if (fallbackToApi) {
        Timer(const Duration(seconds: 5), () {
          if (!isSocketDataReceived.value) {
            log('⚠️ No socket data received within 5 seconds, falling back to API');
            getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
          } else {
            log('✅ Socket data received successfully, no API fallback needed');
          }
        });
      }
    } catch (e) {
      log('❌ Error subscribing for date $formattedDate: $e');
      if (fallbackToApi) {
        log('Falling back to API due to subscription error');
        getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
      }
    }
  }

  /// Subscribe to all dates that have selections (for conflict detection)
  void _ensureSubscribedForAllSelectedDates() {
    final selectedDates = <String>{};
    multiDateSelections.forEach((key, selection) {
      final dateString = selection['date'] as String;
      selectedDates.add(dateString);
    });
    for (final dateString in selectedDates) {
      _subscribeForDate(dateString);
    }
  }

  /// Unsubscribe from slot-wise updates
  void _unsubscribeFromSlotUpdates() {
    try {
      for (final date in _subscribedDates) {
        _slotWiseService.unsubscribe(argument.id ?? '', date);
        log('Unsubscribed from slot-wise updates for date: $date');
      }
      _subscribedDates.clear();
    } catch (e) {
      log('Error unsubscribing from slot updates: $e');
    }
  }

  /// Re-subscribe to slot updates when date changes
  void resubscribeToSlotUpdates() {
    isSocketDataReceived.value = false;
    isLoadingCourts.value = true;
    // Unsubscribe only dates that have no selections
    final datesWithSelections = <String>{};
    multiDateSelections.forEach((key, selection) {
      datesWithSelections.add(selection['date'] as String);
    });
    final datesToUnsub = _subscribedDates.difference(datesWithSelections);
    for (final date in datesToUnsub) {
      _slotWiseService.unsubscribe(argument.id ?? '', date);
    }
    _subscribedDates.removeAll(datesToUnsub);

    Future.delayed(const Duration(milliseconds: 500), () {
      _subscribeToSlotUpdates();
    });
  }

  /// Handle initial slot data from subscription acknowledgment
  void _handleInitialSlotData(dynamic initialData) {
    try {
      log('📡 Handling initial slot data from acknowledgment');
      
      if (initialData != null) {
        log('Initial slot data received, parsing and updating UI');
        
        // Handle both List and Map formats from socket
        Map<String, dynamic> dataMap;
        if (initialData is List) {
          // If data is a list, wrap it in the expected structure
          dataMap = {'data': initialData};
        } else if (initialData is Map<String, dynamic>) {
          dataMap = initialData;
        } else {
          log('❌ Unexpected initial data format: ${initialData.runtimeType}');
          // Fallback to API on unexpected format
          getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
          return;
        }
        
        // Parse the socket data into GetAllActiveCourtsForSlotWiseModel
        final parsedData = GetAllActiveCourtsForSlotWiseModel.fromJson(dataMap);
        
        // Update slot prices and apply filtering
        _updateSocketSlotData(parsedData);
        
        log('✅ Socket data successfully displayed in UI');
      }
    } catch (e) {
      log('❌ Error handling initial slot data: $e');
      // Fallback to API on parsing error
      getAvailableCourtsById(locationID.value, categoryId.value, sId.value, argument.id!, showUnavailable: true);
    }
  }

  /// Handle real-time slot data updates
  void _handleRealTimeSlotUpdate(dynamic socketResponse) {
    try {
      log('🔄 Handling real-time slot data update');

      if (socketResponse == null) return;

      // socketResponse is the full res object: {clubId, date, data, ...}
      final responseClubId = socketResponse['clubId']?.toString() ?? '';
      final responseDate = socketResponse['date']?.toString() ?? '';
      final slotData = socketResponse['data'] ?? socketResponse;

      final currentClubId = argument.id ?? '';
      final currentDate = selectedDate.value ?? DateTime.now();
      final currentDateString = _dateFormatter.format(currentDate);

      if (responseClubId.isNotEmpty && responseClubId != currentClubId) {
        log('⚠️ Ignoring socket update: clubId mismatch (got $responseClubId, current $currentClubId)');
        return;
      }

      // Only reject if date is not subscribed at all (not current date AND not a selected date)
      if (responseDate.isNotEmpty && responseDate != currentDateString) {
        final isSelectedDate = multiDateSelections.values.any(
          (sel) => (sel['date'] as String?) == responseDate,
        );
        if (!isSelectedDate) {
          log('⚠️ Ignoring socket update: date $responseDate not current or selected');
          return;
        }
      }

      log('Real-time slot data received for date: $responseDate, updating UI');

      Map<String, dynamic> dataMap;
      if (slotData is List) {
        dataMap = {'data': slotData};
      } else if (slotData is Map<String, dynamic>) {
        dataMap = slotData;
      } else {
        log('❌ Unexpected data format: ${slotData.runtimeType}');
        return;
      }

      final parsedData = GetAllActiveCourtsForSlotWiseModel.fromJson(dataMap);

      // If update is for a non-current date, only run conflict detection (don't update UI slots)
      if (responseDate.isNotEmpty && responseDate != currentDateString) {
        _deSelectAndCleanupConflictingSlots(parsedData);
        log('✅ Conflict check done for non-current date: $responseDate');
        return;
      }

      _updateSocketSlotData(parsedData);
      log('✅ Real-time slot data successfully updated in UI');
    } catch (e) {
      log('❌ Error handling real-time slot update: $e');
    }
  }

  void _checkAndUnselectLockedSlots(dynamic socketResponse) {
    try {
      // Ignore socket updates if we're currently locking slots
      if (isLockingSlots.value) {
        log('⏸️ Ignoring socket update - currently locking slots');
        return;
      }
      
      // Ignore socket updates for 3 seconds after locking
      if (_lastLockTimestamp != null) {
        final timeSinceLock = DateTime.now().difference(_lastLockTimestamp!);
        if (timeSinceLock.inSeconds < 3) {
          log('⏸️ Ignoring socket update - ${3 - timeSinceLock.inSeconds}s remaining after lock');
          return;
        }
      }
      
      if (socketResponse == null) return;

      final slotData = socketResponse['data'] ?? socketResponse;
      List<dynamic> courts;

      if (slotData is List) {
        courts = slotData;
      } else if (slotData is Map<String, dynamic> && slotData['data'] is List) {
        courts = slotData['data'];
      } else {
        return;
      }

      final currentDate = selectedDate.value ?? DateTime.now();
      final dateString = _dateFormatter.format(currentDate);
      final currentUserId = storage.read("userId") ?? "";
      final keysToRemove = <String>[];

      for (final court in courts) {
        final courtId = court['_id'] as String?;
        if (courtId == null) continue;

        final slotsList = court['slots'] as List<dynamic>?;
        if (slotsList == null) continue;

        for (final slotData in slotsList) {
          final slotId = slotData['_id'] as String?;
          final status = slotData['status'] as String?;
          final userId = slotData['userId'] as String?;

          if (slotId == null || status == null) continue;

          if (status.toLowerCase() == 'lock') {
            // Only deselect if locked by a DIFFERENT user
            if (userId != null && userId == currentUserId) {
              log('✅ Slot $slotId locked by current user - keeping selection');
              continue;
            }
            final fullKey = '${dateString}_${courtId}_${slotId}';
            final leftKey = '${dateString}_${courtId}_${slotId}_L';
            final rightKey = '${dateString}_${courtId}_${slotId}_R';

            if (multiDateSelections.containsKey(fullKey)) {
              keysToRemove.add(fullKey);
              log('Auto-unselecting locked slot: $slotId (locked by different user)');
            }

            if (multiDateSelections.containsKey(leftKey)) {
              keysToRemove.add(leftKey);
              log('Auto-unselecting locked left half: $slotId (locked by different user)');
            }
            if (multiDateSelections.containsKey(rightKey)) {
              keysToRemove.add(rightKey);
              log('Auto-unselecting locked right half: $slotId (locked by different user)');
            }
          }
        }
      }

      if (keysToRemove.isNotEmpty) {
        for (final key in keysToRemove) {
          final selection = multiDateSelections[key];
          if (selection != null) {
            final slot = selection['slot'] as Slots;
            final courtId = selection['courtId'] as String;
            selectedSlots.removeWhere((s) => s.sId == slot.sId);
            selectedSlotsWithCourtInfo.remove('${courtId}_${slot.sId}');
          }
          multiDateSelections.remove(key);
        }
        _recalculateTotalAmount();
        // AppToast.error('Some selected slots were locked by another user');
      }
    } catch (e) {
      log('Error checking locked slots: $e');
    }
  }

  /// Update slots with socket data and apply filtering
  void _updateSocketSlotData(GetAllActiveCourtsForSlotWiseModel socketData) {
    try {
      // Check if any selected slot became booked/locked and deselect + delete history
      _deSelectAndCleanupConflictingSlots(socketData);

      // Store ALL slots (both available and unavailable)
      _allSlotsCache.clear();
      for (var court in socketData.data ?? []) {
        _allSlotsCache[court.sId ?? ''] = List<Slots>.from(court.slots ?? []);
      }

      // Apply filtering based on toggle
      for (var court in socketData.data ?? []) {
        final base = _allSlotsCache[court.sId ?? ''] ?? [];
        if (showUnavailableSlots.value) {
          court.slots = List<Slots>.from(base);
        } else {
          court.slots = base.where((s) => _isAvailableSlot(s)).toList();
        }
      }

      slots.value = socketData;

      // Build original cache from ALL slots (including booked) for time-of-day filtering
      _originalSlotsCache.clear();
      for (var court in socketData.data ?? []) {
        _originalSlotsCache[court.sId ?? ''] = List<Slots>.from(_allSlotsCache[court.sId ?? ''] ?? []);
      }
      _recalculateTimeOfDayCounts();

      filterSlotsByTimeOfDay();
      _autoSelectTab();
      isLoadingCourts.value = false;

      log('✅ Socket slot data successfully processed and displayed');
    } catch (e) {
      log('❌ Error updating socket slot data: $e');
    }
  }

  /// Deselect any selected slots that became booked/locked in the new socket data
  void _deSelectAndCleanupConflictingSlots(GetAllActiveCourtsForSlotWiseModel socketData) {
    if (multiDateSelections.isEmpty) return;

    // Build a quick lookup: slotId -> updated Slots object
    final Map<String, Slots> updatedSlotMap = {};
    for (final court in socketData.data ?? []) {
      for (final slot in court.slots ?? []) {
        if (slot.sId != null) updatedSlotMap[slot.sId!] = slot;
      }
    }

    final keysToRemove = <String>[];
    final slotsToDelete = <Map<String, dynamic>>[];

    multiDateSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final slotId = slot.sId ?? '';
      final updatedSlot = updatedSlotMap[slotId];
      if (updatedSlot == null) return;

      final status = updatedSlot.status?.toLowerCase() ?? '';
      final isLeftHalf = selection['isLeftHalf'] as bool?;
      final supports30Min = slotSupports30Min(slot);
      
      // Check if slot status is booked or lock
      if (status == 'booked' || status == 'lock') {
        keysToRemove.add(key);
        final courtId = selection['courtId'] as String;
        final dateString = selection['date'] as String;
        final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
        final duration = (supports30Min && isLeftHalf != null) ? 30 : 60;
        final finalDuration = (slot.duration == 90) ? 90 : duration;
        final userId = storage.read('userId') ?? '';
        slotsToDelete.add({
          'slotId': slotId,
          'courtId': courtId,
          'bookingDate': dateString,
          'time': bookingTime,
          'bookingTime': bookingTime,
          'duration': finalDuration,
          'userId': userId,
        });
        log('🔴 Slot ${slot.time} (${slotId}) became $status - will be deselected');
      }
      // For 30-min slots, check if specific half became booked
      else if (supports30Min && isLeftHalf != null) {
        final leftBooked = isLeftHalfBooked(updatedSlot);
        final rightBooked = isRightHalfBooked(updatedSlot);
        
        if ((isLeftHalf && leftBooked) || (!isLeftHalf && rightBooked)) {
          keysToRemove.add(key);
          final courtId = selection['courtId'] as String;
          final dateString = selection['date'] as String;
          final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
          final userId = storage.read('userId') ?? '';
          slotsToDelete.add({
            'slotId': slotId,
            'courtId': courtId,
            'bookingDate': dateString,
            'time': bookingTime,
            'bookingTime': bookingTime,
            'duration': 30,
            'userId': userId,
          });
          log('🔴 Slot ${slot.time} ${isLeftHalf ? "left" : "right"} half became booked - will be deselected');
        }
      }
    });

    if (keysToRemove.isEmpty) return;

    // Collect slot info before removing
    final slotIdsToClean = <String>{};
    final courtIdsToClean = <String, String>{};
    for (final key in keysToRemove) {
      final selection = multiDateSelections[key];
      if (selection != null) {
        final slot = selection['slot'] as Slots;
        final courtId = selection['courtId'] as String;
        slotIdsToClean.add(slot.sId ?? '');
        courtIdsToClean[slot.sId ?? ''] = courtId;
      }
    }

    // Remove from multiDateSelections
    for (final key in keysToRemove) {
      multiDateSelections.remove(key);
    }

    // Clean up selectedSlots and selectedSlotsWithCourtInfo
    for (final slotId in slotIdsToClean) {
      selectedSlots.removeWhere((s) => s.sId == slotId);
      final courtId = courtIdsToClean[slotId] ?? '';
      selectedSlotsWithCourtInfo.remove('${courtId}_$slotId');
    }

    _recalculateTotalAmount();
    
    if (keysToRemove.isNotEmpty) {
      log('⚠️ Auto-deselected ${keysToRemove.length} slots that became booked/locked');
      AppToast.error('${keysToRemove.length} selected slot(s) became unavailable and were removed');
    }

    if (slotsToDelete.isNotEmpty) {
      deleteSlotHistory(slots: slotsToDelete);
    }
  }

  List<Map<String, dynamic>>? buildBookingPayload() {
    if (multiDateSelections.isEmpty) return null;

    final clubId = argument.id ?? '';
    if (clubId.isEmpty) return null;

    final registerClub = slots.value?.data?.firstOrNull?.registerClubId;
    final ownerIdStr = registerClub?.ownerId?.sId?.toString() ?? argument.ownerId ?? '';
    final clubLocationId = registerClub?.locations?.isNotEmpty == true
        ? registerClub!.locations![0].sId ?? ''
        : '';

    final List<Map<String, dynamic>> slotData = [];

    multiDateSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final courtId = selection['courtId'] as String;
      final courtName = selection['courtName'] as String;
      final dateString = selection['date'] as String;
      final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
      final adjustedAmount = selection['adjustedAmount'] as int? ?? slot.amount ?? 0;
      final isLeftHalf = selection['isLeftHalf'] as bool?;
      final supports30Min = slotSupports30Min(slot);
      final duration = (supports30Min && isLeftHalf != null) ? 30 : 60;
      
      // Use slot's duration from API if it's 90, otherwise use calculated duration
      final finalDuration = (slot.duration == 90) ? 90 : duration;

      final bookingDay = _getWeekday(DateTime.parse(dateString).weekday);
      final selectedBusinessHour = slot.businessHours
          ?.where((bh) => bh.day == bookingDay)
          .map((bh) => {'time': bh.time ?? '', 'day': bh.day ?? ''})
          .toList() ?? [];

      slotData.add({
        'slotId': slot.sId ?? '',
        'businessHours': selectedBusinessHour,
        'slotTimes': [
          {'time': slot.time ?? '', 'amount': adjustedAmount}
        ],
        'courtId': courtId,
        'courtName': courtName,
        'bookingDate': dateString,
        'duration': finalDuration,
        'totalTime': finalDuration,
        'bookingTime': bookingTime,
      });
    });

    if (slotData.isEmpty) return null;

    return [
      {
        'slot': slotData,
        'register_club_id': clubId,
        'ownerId': ownerIdStr,
        'categoryId': categoryId.value,
        'location': clubLocationId,
        'stateId': locationID.value,
      },
    ];
  }

}