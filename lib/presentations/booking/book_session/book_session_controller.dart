import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/data/response_models/get_all_slot_prices_of_court_model.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import '../../../data/request_models/home_models/get_available_court.dart';
import '../../../data/request_models/home_models/get_club_name_model.dart';
import '../../../repositories/cart/cart_repository.dart';
import '../../../repositories/home_repository/home_repository.dart';
import '../../cart/cart_controller.dart';

class BookSessionController extends GetxController {
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
      await getAvailableCourtsById(argument.id!, showUnavailable: true);
    }
  }


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
  CartRepository cartRepository = CartRepository();

  RxMap<String, Map<String, dynamic>> selectedSlotsWithCourtInfo = <String, Map<String, dynamic>>{}.obs;
  RxBool isBottomSheetOpen = false.obs;
  
  // Track if slot history API was called
  RxBool hasCalledSlotHistoryAPI = false.obs;

  @override
  void onInit() {
    super.onInit();
    argument = Get.arguments['data'];
    selectedDate.value = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchAllSlotPrices();
      await getAvailableCourtsById(argument.id!, showUnavailable: true);
    });
  }

  @override
  void onClose() {
    cleanupOnBack();
    selectedSlots.clear();
    selectedSlotsWithCourtInfo.clear();
    multiDateSelections.clear();
    totalAmount.value = 0;
    pageController.dispose();
    super.onClose();
  }

  Future<void> cleanupOnBack() async {
    if (multiDateSelections.isEmpty) return;
    
    try {
      final slots = [];
      
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
      
      await repository.deleteSlotHistory(data: {"slots": slots});
      log('Bulk delete slot history on back: $slots');
    } catch (e) {
      log('Error in bulk delete on back: $e');
    }
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

      Get.snackbar(
        "Error",
        "Failed to load courts. Please try again.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
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

  /// Check if adding a new slot would violate limits
  bool _canAddSlot() {
    final currentCount = multiDateSelections.length;
    if (currentCount >= maxSlots) {
      SnackBarUtils.showErrorSnackBar("Booking Limit Reached\nYou can select a maximum of $maxSlots slots.");
      return false;
    }

    final uniqueDates = _getUniqueDates();
    if (uniqueDates.length >= maxDays) {
      Get.snackbar(
        "Day Limit Reached",
        "You can book for a maximum of $maxDays days only.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    return true;
  }

  Future<bool> createAndGetSlotHistory({required List<Map<String, dynamic>> slots}) async {
    try {
      log('createAndGetSlotHistory called with body: $slots');
      final response = await repository.createAndGetSlotHistory(data: slots);

      if (response.data.isEmpty) {
        SnackBarUtils.showInfoSnackBar("No slot data returned");
        return false;
      }

      final createdSlots = response.data.where((e) => e.created).toList();
      final lockedSlots = response.data.where((e) => !e.created).toList();

      if (createdSlots.isNotEmpty) {
        return true;
      }

      if (lockedSlots.isNotEmpty) {
        SnackBarUtils.showInfoSnackBar(
          lockedSlots.first.message ?? "This slot is currently locked. Please try again.",
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
      
      final success = await createAndGetSlotHistory(slots: slots);
      if (success) {
        hasCalledSlotHistoryAPI.value = true;
      }
      return success;
    } catch (e) {
      log('Error processing slot history: $e');
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
    
    // Check limits before adding
    if (multiDateSelections.length + slotsToSelect.length > maxSlots) {
      SnackBarUtils.showErrorSnackBar("Booking Limit Reached\nYou can select a maximum of $maxSlots slots.");
      return;
    }
    
    // Add all slots in the group
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
    if (status == 'booked') return true;
    if (status.isNotEmpty && status != 'available') return true;

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

  bool _isUnavailableSlot(Slots slot) {
    final availability = slot.availabilityStatus?.toLowerCase();
    final isBlocked = availability == "maintenance" ||
        availability == "weather conditions" ||
        availability == "staff unavailability";
    final isBooked = (slot.status?.toLowerCase() == 'booked');
    final isPast = isPastAndUnavailable(slot);
    
    // For 30-minute duration, check if any half is booked
    final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    bool isHalfBooked = false;
    if (selectedDurationMinutes == 30) {
      isHalfBooked = isLeftHalfBooked(slot) || isRightHalfBooked(slot);
    }
    
    return isPast || isBlocked || isBooked || isHalfBooked;
  }

  bool _isAvailableSlot(Slots slot) {
    final status = slot.status?.toLowerCase() ?? '';
    final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    
    // For 30-minute duration, slot is available if at least one half is free
    if (selectedDurationMinutes == 30) {
      final leftBooked = isLeftHalfBooked(slot);
      final rightBooked = isRightHalfBooked(slot);
      // Available if at least one half is free and not blocked/past
      final isNotBlocked = !isPastAndUnavailable(slot) && 
          slot.availabilityStatus?.toLowerCase() != "maintenance" &&
          slot.availabilityStatus?.toLowerCase() != "weather conditions" &&
          slot.availabilityStatus?.toLowerCase() != "staff unavailability" &&
          slot.status?.toLowerCase() != 'booked';
      return isNotBlocked && (!leftBooked || !rightBooked);
    }
    
    return !_isUnavailableSlot(slot) && (status == 'available' || status.isEmpty);
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
    try {
      // Parse the time string
      final time = DateFormat('h:mm a').parseStrict(timeString.trim());
      // Add minutes
      final newTime = time.add(Duration(minutes: minutesToAdd));
      // Format back to string
      return DateFormat('h:mm a').format(newTime);
    } catch (_) {
      try {
        // Try parsing without minutes (e.g., "3 PM")
        final time = DateFormat('h a').parseStrict(timeString.trim());
        final newTime = time.add(Duration(minutes: minutesToAdd));
        return DateFormat('h:mm a').format(newTime);
      } catch (_) {
        // If parsing fails, return original string
        return timeString;
      }
    }
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

  var cartLoader = false.obs;
  Future<bool> processSlotHistoryForBooking() async {
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

      // Call API to process slot history
      final success = await processSlotHistoryForBooking();
      if (!success) {
        cartLoader.value = false;
        return;
      }

      final clubId = argument.id!;
      final List<Map<String, dynamic>> allSlots = [];
      final Map<String, Map<String, dynamic>> consolidatedSlots = {};
      final selectedDurationMinutes = int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;

      // First pass: identify slots that need consolidation (only for slots that support 30-minute pricing)
      multiDateSelections.forEach((key, selection) {
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final supports30Min = slotSupports30Min(slot);
        
        if (supports30Min && selectedDurationMinutes == 30) {
          if (key.endsWith('_L') || key.endsWith('_R')) {
            // This is a half-slot selection for a slot that supports 30-minute pricing
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
        }
      });

      // Second pass: process all selections
      multiDateSelections.forEach((key, selection) {
        final slot = selection['slot'] as Slots;
        final courtId = selection['courtId'] as String;
        final courtName = selection['courtName'] as String;
        final dateString = selection['date'] as String;
        final bookingTime = selection['bookingTime'] as String? ?? slot.time ?? '';
        final adjustedAmount = selection['adjustedAmount'] as int? ?? slot.amount ?? 0;
        final slotId = slot.sId ?? '';
        final supports30Min = slotSupports30Min(slot);
        
        // Skip if this is a half-slot that will be consolidated
        if (supports30Min && selectedDurationMinutes == 30 && (key.endsWith('_L') || key.endsWith('_R'))) {
          final consolidatedSlot = consolidatedSlots[slotId];
          if (consolidatedSlot != null && 
              consolidatedSlot['leftHalf'] != null && 
              consolidatedSlot['rightHalf'] != null) {
            // Both halves exist - only process once (for left half)
            if (key.endsWith('_L')) {
              // Get the full slot price (60-minute price) from the original slot
              final fullSlotPrice = slot.amount ?? 0; // This should be the 60-minute price from API
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
                    "amount": fullSlotPrice, // Use full slot price instead of adjustedAmount
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
                ],
                "duration": 60, // Full slot duration when both halves selected
                "totalTime": 60,
                "bookingTime": slot.time ?? '' // Use original time for full slot
              };
              allSlots.add(slotEntry);
            }
            return; // Skip right half processing
          } else {
            // Only one half selected - process as 30min slot
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
                  "amount": adjustedAmount,
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
              ],
              "duration": 30,
              "totalTime": 30,
              "bookingTime": bookingTime
            };
            allSlots.add(slotEntry);
          }
          return;
        }
        
        // Process full slot selections (60 minutes)
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
              "amount": adjustedAmount,
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
          ],
          "duration": 60,
          "totalTime": 60,
          "bookingTime": bookingTime
        };

        allSlots.add(slotEntry);
      });

      final List<Map<String, dynamic>> cartPayload = [{
        "slot": allSlots,
        "register_club_id": clubId,
      }];

      log("Multi-Date Cart Payload: $cartPayload");

      await cartRepository.addCartItems(data: cartPayload).then((v) async {
        final CartController controller = Get.find<CartController>();
        await controller.getCartItems();

        Get.to(() => CartScreen(buttonType: "true"))?.then((_) async {
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
      Get.snackbar(
        "Error",
        detailed,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      log("Error adding to cart: $e");
      Get.snackbar(
        "Error",
        "Failed to add slots to cart. Please try again.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
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
        duration: '', // Get all durations
        day: '', // Get all days
        timePeriod: '', // Get all time periods
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
  
 
}