import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:get/get.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import '../../../../data/request_models/home_models/get_available_court.dart';
import '../../repositories/home_repository/home_repository.dart';
import '../../repositories/authentication_repository/sign_up_repository.dart';
import '../../repositories/home_repository/profile_repository.dart';
import '../../data/response_models/get_courts_by_duration_model.dart' hide CourtDurationSlots;
import '../../data/response_models/get_all_slot_prices_of_court_model.dart';
import '../../data/response_models/get_locations_model.dart';
import '../../services/socket_service.dart';
import '../../core/network/dio_client.dart' show storage;

class BookACourtController extends GetxController {
  final HomeRepository _homeRepository = HomeRepository();
  final SignUpRepository _signUpRepository = SignUpRepository();

  // Locations data
  Rx<GetLocationsModel?> locationsData = Rx<GetLocationsModel?>(null);
  RxBool isLoadingLocations = false.obs;

  // Category and Location IDs from MainHomeController
  RxString categoryId = ''.obs;
  RxString locationId = ''.obs;
  RxString locationsId = ''.obs;

  ///Available Slots------------------------------------------------------------
  final selectedDuration = '60 min'.obs;
  final matchType = "competitive".obs;

  ///Available Clubs------------------------------------------------------------
  final expandedIndex = (-1).obs;
  void toggle(int index) {
    expandedIndex.value = expandedIndex.value == index ? -1 : index;
  }

  ///Available Slots Collapse/Expand--------------------------------------------
  RxBool isSlotsCollapsed = false.obs;
  RxnString selectedSearchSlotId = RxnString();
  RxBool showMainGrid = true.obs;

  void toggleSlotsCollapse() {
    isSlotsCollapsed.value = !isSlotsCollapsed.value;
    showMainGrid.value = !showMainGrid.value;
  }

  final is30Slots = false.obs;

  void updateDurationFromToggle() {
    selectedDuration.value = is30Slots.value ? '30 min' : '60 min';
  }

  void fetchClubs() {
    if (multiDateSelections.isEmpty) {
      showNoSelectionDialog();
      return;
    }
    showMainGrid.value = false;
    isSlotsCollapsed.value = false;
    fetchCourtsIfReady();
  }

  void showNoSelectionDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "No Selection",
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please select at least one slot to continue.",
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: Get.width * 0.5,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "OK",
                    style: Get.textTheme.labelLarge!
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
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
            textTheme: const TextTheme(
              headlineMedium:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              titleSmall: TextStyle(fontSize: 14),
              bodyLarge: TextStyle(fontSize: 16),
              labelLarge:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          child: Transform.scale(scale: 0.9, child: child!),
        );
      },
    );
    if (picked != null) {
      selectedDate.value = picked;
      dateTimelineController.animateToDate(picked);
    }
  }

  final EasyDatePickerController dateTimelineController =
  EasyDatePickerController();

  DateTime _getInitialDate() {
    final now = DateTime.now();
    if (now.hour == 23 && now.minute >= 1) {
      return DateTime(now.year, now.month, now.day + 1);
    }
    return now;
  }

  final selectedDate = Rxn<DateTime>();
  Rx<DateTime> focusedMonth = DateTime.now().obs;

  RxBool showUnavailableSlots = false.obs;

  final Map<String, List<Slots>> _originalSlotsCache = {};

  RxList<Slots> selectedSlots = <Slots>[].obs;

  // Multi-date selections - key: "date_courtId_slotId" or with _first_half/_second_half suffix
  RxMap<String, Map<String, dynamic>> multiDateSelections =
      <String, Map<String, dynamic>>{}.obs;

  // Real court selections from availableCourts (for payment panel)
  RxMap<String, Map<String, dynamic>> realCourtSelections =
      <String, Map<String, dynamic>>{}.obs;

  RxInt totalAmount = 0.obs;
  Rx<GetAllActiveCourtsForSlotWiseModel?> slots =
  Rx<GetAllActiveCourtsForSlotWiseModel?>(null);
  RxBool isLoadingCourts = false.obs;

  Rx<GetCourtsByDurationModel?> courtsByDuration =
  Rx<GetCourtsByDurationModel?>(null);
  RxBool isLoadingCourtsByDuration = false.obs;
  RxString selectedTimeSlot = ''.obs;

  var allSlotPricesResponse = Rxn<GetAllSlotPricesOfCourtModel>();
  var isSlotPricesLoading = false.obs;
  final Map<String, Map<String, int>> slotPricesData = {};
  final Map<String, Map<String, int>> originalSlotPricesData = {};

  RxBool hasCalledSlotHistoryAPI = false.obs;

  // Socket
  RxBool isSocketDataReceived = false.obs;
  String? _lastSubscribedDate;
  String? _lastSubscribedDuration;

  Future<void> fetchLocations() async {
    try {
      isLoadingLocations.value = true;
      final response = await _signUpRepository.getLocations();
      locationsData.value = response;
    } catch (e) {
      log('Error fetching locations: $e');
    } finally {
      isLoadingLocations.value = false;
    }
  }

  RxBool isUpdatingLocation = false.obs;

  Future<bool> updateUserLocation(String cityId) async {
    try {
      isUpdatingLocation.value = true;
      final mainHomeController = Get.find<MainHomeController>();
      final profile =
          mainHomeController.profileController.profileModel.value?.response;
      if (profile == null) return false;

      final profileRepo = ProfileRepository();
      await profileRepo.updateUserProfile(
        city: cityId,
        location: profile.location?.toJson() ?? {},
      );

      await mainHomeController.profileController.fetchUserProfile();
      final newLocationId = mainHomeController.profileController.profileModel
          .value?.response?.city?.sId ??
          "68c94a94d72a6f9769712ff0";
      locationId.value = newLocationId;
      final catId = mainHomeController.selectedCategoryId.value;
      await Future.wait([
        mainHomeController.homeController
            .fetchBookings(categoryId: catId, locationId: newLocationId),
        mainHomeController.homeController.fetchClubs(
            isRefresh: true, categoryId: catId, locationId: newLocationId),
        mainHomeController.fetchOpenMatches(),
        mainHomeController.fetchNearCityPlayers(),
        fetchCourtsByDuration()
      ]);

      CustomLogger.logMessage(
          msg: 'Location updated successfully', level: LogLevel.info);
      return true;
    } catch (e) {
      log('Error updating location: $e');
      CustomLogger.logMessage(
          msg: 'Failed to update location', level: LogLevel.error);
      return false;
    } finally {
      isUpdatingLocation.value = false;
    }
  }

  RxString selectedCityId = ''.obs;

  String getSelectedLocationName() {
    if (selectedCityId.value.isEmpty || locationsData.value?.data == null) {
      return 'Change Location';
    }
    final location = locationsData.value!.data!.firstWhere(
          (loc) => loc.id == selectedCityId.value,
      orElse: () => GetLocationData(),
    );
    return location.name ?? 'Change Location';
  }

  String getCityNameById(String? cityId) {
    if (cityId == null || cityId.isEmpty) return '';
    try {
      final mainHomeController = Get.find<MainHomeController>();
      final profileCity = mainHomeController
          .profileController.profileModel.value?.response?.city;
      if (profileCity?.sId == cityId && profileCity?.name != null) {
        return profileCity!.name!;
      }
    } catch (e) {
      log('getCityNameById: MainHomeController not found: $e');
    }
    if (locationsData.value?.data != null) {
      final location = locationsData.value!.data!
          .firstWhereOrNull((loc) => loc.id == cityId);
      if (location?.name != null) return location!.name!;
    }
    return '';
  }

  String getLocationNameFromClub(GetCourtsByDurationData? clubData) {
    if (clubData?.registerClub?.locations == null ||
        clubData!.registerClub!.locations!.isEmpty) {
      return '';
    }
    final location = clubData.registerClub!.locations!.first;
    return location.city ?? location.address ?? '';
  }

  @override
  void onInit() async {
    super.onInit();
    selectedDate.value = _getInitialDate();
    updateDurationFromToggle();
    _initializeMockData();
    await fetchLocations();

    try {
      final mainHomeController = Get.find<MainHomeController>();
      categoryId.value = mainHomeController.selectedCategoryId.value;
      locationId.value = mainHomeController.profileController.profileModel
          .value?.response?.city?.sId ??
          "68c94a94d72a6f9769712ff0";
      selectedCityId.value = locationId.value;
    } catch (e) {
      log('MainHomeController not found: $e');
    }

    try {
      final walletController = Get.find<WalletController>();
      walletController.fetchWallet();
    } catch (e) {
      // ignore
    }
  }

  void _initializeMockData() {
    slots.value = GetAllActiveCourtsForSlotWiseModel(
      data: [
        Data(
          sId: 'court1',
          courtName: '',
          clubName: 'Sample Club',
          slots: [
            Slots(sId: 'slot1', time: '5:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot2', time: '6:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot3', time: '7:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot4', time: '8:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot5', time: '9:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot6', time: '10:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot7', time: '11:00 AM', amount: 0, status: 'available'),
            Slots(sId: 'slot8', time: '12:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot9', time: '1:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot10', time: '2:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot11', time: '3:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot12', time: '4:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot13', time: '5:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot14', time: '6:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot15', time: '7:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot16', time: '8:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot17', time: '9:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot18', time: '10:00 PM', amount: 0, status: 'available'),
            Slots(sId: 'slot19', time: '11:00 PM', amount: 0, status: 'available'),
          ],
        ),
      ],
    );

    _originalSlotsCache.clear();
    final courts = slots.value?.data ?? [];
    for (final court in courts) {
      _originalSlotsCache[court.sId ?? ''] =
      List<Slots>.from(court.slots ?? []);
    }
  }

  @override
  void onClose() {
    _unsubscribeFromCourtsByDuration();
    cleanupOnBack();
    selectedSlots.clear();
    multiDateSelections.clear();
    realCourtSelections.clear();
    totalAmount.value = 0;
    super.onClose();
  }

  Future<void> cleanupOnBack() async {
    if (realCourtSelections.isEmpty) return;
    try {
      final slotsList = [];
      for (var entry in realCourtSelections.entries) {
        final selection = entry.value;
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final courtId = selection['courtId'] as String;
        final dateString = selection['date'] as String;
        final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
        final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
        final bookingTime = isHalfSlot
            ? getHalfSlotTime(slot.time ?? '', isFirstHalf)
            : slot.time ?? '';
        final duration = isHalfSlot ? 30 : 60;
        final finalDuration = (slot.duration == 90) ? 90 : duration;
        final userId = storage.read("userId")??"";
        slotsList.add({
          "slotId": slotId,
          "courtId": courtId,
          "bookingDate": dateString,
          "time": bookingTime,
          "bookingTime": bookingTime,
          "duration": finalDuration,
          "userId":userId
        });
      }
      log('Bulk delete slot history on back: $slotsList');
      await _homeRepository.deleteSlotHistory(data: {"slots": slotsList});
    } catch (e) {
      log('Error in bulk delete on back: $e');
    }
  }

  void onNext() {
    log("Slots -> $selectedSlots");
    if (multiDateSelections.isEmpty) {
      CustomLogger.logMessage(
          msg: "Please select at least one slot to continue.",
          level: LogLevel.debug);
      return;
    }
    CustomLogger.logMessage(
        msg: "Selected ${multiDateSelections.length} slots for ₹${totalAmount.value}",
        level: LogLevel.debug);
  }

  void refreshSlots({bool showUnavailable = false}) {
    isLoadingCourts.value = true;
    Future.delayed(const Duration(milliseconds: 500), () {
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
      final createdSlots = response.data.where((e) => e.created).toList();
      final lockedSlots = response.data.where((e) => !e.created).toList();
      if (createdSlots.isNotEmpty) return true;
      if (lockedSlots.isNotEmpty) {
        CustomLogger.logMessage(
            msg: lockedSlots.first.message ??
                "Selected slots are currently locked. Please try again.",
            level: LogLevel.debug);
      }
      return false;
    } catch (e) {
      log('Error in createAndGetSlotHistory: $e');
      return false;
    }
  }

  Future<void> deleteSlotHistory(
      {required Map<String, dynamic> slots}) async {
    try {
      log('deleteSlotHistory called with body: $slots');
      await _homeRepository.deleteSlotHistory(data: slots);
    } catch (e) {
      log('Error in deleteSlotHistory: $e');
    }
  }

  // ===========================================================================
  // AVAILABLE COURTS SLOT SELECTION (after Fetch Clubs)
  // ===========================================================================
  //
  // RULES (based on reference image):
  //
  // SELECTING (slot not yet selected):
  //   • Tap LEFT  half of unselected slot → allowed ONLY if the NEXT slot
  //     (slot+60min) already has its LEFT  half (or full) selected.
  //     Adds LEFT half only (extends range leftward by 30 min).
  //   • Tap RIGHT half of unselected slot → allowed ONLY if the PREV slot
  //     (slot-60min) already has its RIGHT half (or full) selected.
  //     Adds RIGHT half only (extends range rightward by 30 min).
  //   • Tap either half with NO neighbour → select FULL slot (60 min).
  //   • Half slot can NEVER exist alone without a consecutive neighbour.
  //
  // DESELECTING (slot already selected):
  //   • Tap a selected half/full block:
  //       – If it's the only block → remove all.
  //       – If it's at the START edge → trim: remove that block,
  //         if remaining left-behind half is now isolated → remove it too.
  //       – If it's at the END edge → same trim logic.
  //       – If it's in the MIDDLE → cascade-remove from that block onward.
  //   • After any removal, run cleanup to remove orphaned halves.
  // ===========================================================================

  void toggleCourtRowSlotSelection(
      Slots slot, {
        String? courtId,
        String? courtName,
        bool? isHalfSlot,
        bool? isFirstHalf,
        List<Slots>? availableSlots,
      }) {
    final slotId          = slot.sId ?? '';
    final resolvedCourtId = courtId ?? '';
    final currentDate     = selectedDate.value ?? DateTime.now();
    final dateString      =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    // ── Duration mismatch guard ──────────────────────────────────────────────
    final is90MinSlot = slot.duration == 90;
    if (realCourtSelections.isNotEmpty) {
      bool has90 = false, hasNon90 = false;
      realCourtSelections.forEach((key, sel) {
        final s = sel['slot'] as Slots;
        if (s.duration == 90) has90 = true; else hasNon90 = true;
      });
      if (is90MinSlot && hasNon90) {
        AppToast.error("Cannot mix 90-minute slots with 30/60-minute slots");
        return;
      }
      if (!is90MinSlot && has90) {
        AppToast.error("Cannot mix 30/60-minute slots with 90-minute slots");
        return;
      }
    }

    final supports30Min = clubSupports30MinSlots(resolvedCourtId);

    final fullKey   = '${dateString}_${resolvedCourtId}_$slotId';
    final firstKey  = '${dateString}_${resolvedCourtId}_${slotId}_first_half';
    final secondKey = '${dateString}_${resolvedCourtId}_${slotId}_second_half';

    final hasFullSlot   = realCourtSelections.containsKey(fullKey);
    final hasFirstHalf  = realCourtSelections.containsKey(firstKey);
    final hasSecondHalf = realCourtSelections.containsKey(secondKey);
    final isSelected    = hasFullSlot || hasFirstHalf || hasSecondHalf;

    // ── NON-30-MIN COURT: simple full-slot toggle ────────────────────────────
    if (!supports30Min) {
      if (isSelected) {
        realCourtSelections.remove(fullKey);
        selectedSlots.removeWhere((s) => s.sId == slotId);
      } else {
        realCourtSelections[fullKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
        if (!selectedSlots.any((s) => s.sId == slotId)) selectedSlots.add(slot);
      }
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    // ── 30-MIN COURT ─────────────────────────────────────────────────────────
    final slotBase         = _parseTimeToMinutesLocal(slot.time ?? '');
    final tappingFirstHalf = isFirstHalf ?? true;
    final tappedBlockStart = tappingFirstHalf ? slotBase : slotBase + 30;

    // ════════════════════════════════════════════════════════════════════════
    // SELECTING — slot is NOT yet selected at all
    // ════════════════════════════════════════════════════════════════════════
    if (!isSelected) {
      final blocks = _getRealCourtSelectedBlocks(resolvedCourtId, dateString);

      if (blocks.isEmpty) {
        // Nothing selected yet → always select FULL slot
        realCourtSelections[fullKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
        recalculateRealCourtTotalAmount();
        realCourtSelections.refresh();
        return;
      }

      final rangeStart = blocks.first; // earliest 30-min block start (minutes)
      final rangeEnd   = blocks.last;  // latest  30-min block start (minutes)
      // The range covers [rangeStart, rangeEnd + 30)

      // ── Determine if this slot is DIRECTLY consecutive to the range ─────
      //
      // Case 1: Slot is directly BEFORE the range start
      //   slotBase + 60 == rangeStart  (slot ends exactly where range begins)
      //   → The slot's RIGHT half (slotBase+30 to slotBase+60) connects.
      //   → Add RIGHT half only (first half would be dangling).
      //
      // Case 2: Slot is directly AFTER the range end
      //   slotBase == rangeEnd + 30  (slot starts exactly where range ends)
      //   → The slot's LEFT half (slotBase to slotBase+30) connects.
      //   → Add LEFT half only (second half would be dangling).
      //
      // Any other position → NOT consecutive → select FULL slot.

      final slotEnd = slotBase + 60; // where this full slot would end

      if (slotEnd == rangeStart) {
        // Slot is directly before the range → add RIGHT half only
        // e.g. range starts at 8pm(480), this slot is 7pm(420), 420+60=480 ✓
        // Right half = 7:30pm–8:00pm → connects to 8:00pm range start
        final halfSlot = Slots(
            sId: slotId, time: slot.time, amount: (slot.amount ?? 0) ~/ 2);
        realCourtSelections[secondKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': false,
        };
      } else if (slotBase == rangeEnd + 30) {
        // Slot is directly after the range → add LEFT half only
        // e.g. range ends at block 450(7:30pm), this slot is 8pm(480), 480==450+30 ✓
        // Left half = 8:00pm–8:30pm → connects to 7:30pm range end
        final halfSlot = Slots(
            sId: slotId, time: slot.time, amount: (slot.amount ?? 0) ~/ 2);
        realCourtSelections[firstKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': true,
        };
      } else {
        // Not consecutive → select FULL slot (no partial connection)
        realCourtSelections[fullKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      }

      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    // ════════════════════════════════════════════════════════════════════════
    // SPECIAL CASE: only ONE half of this slot is selected and user taps
    // the OTHER half → upgrade to FULL slot (both halves).
    // e.g. 8pm left half selected, user taps 8pm right half → 8pm full
    // ════════════════════════════════════════════════════════════════════════
    final onlyFirstHalf  = hasFirstHalf && !hasSecondHalf && !hasFullSlot;
    final onlySecondHalf = hasSecondHalf && !hasFirstHalf && !hasFullSlot;

    if (onlyFirstHalf && !tappingFirstHalf) {
      // Left half stored, user taps right half → upgrade to full
      realCourtSelections.remove(firstKey);
      realCourtSelections[fullKey] = {
        'slot': slot,
        'courtId': resolvedCourtId,
        'courtName': courtName ?? '',
        'date': dateString,
        'dateTime': currentDate,
        'amount': slot.amount ?? 0,
      };
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    if (onlySecondHalf && tappingFirstHalf) {
      // Right half stored, user taps left half → upgrade to full
      realCourtSelections.remove(secondKey);
      realCourtSelections[fullKey] = {
        'slot': slot,
        'courtId': resolvedCourtId,
        'courtName': courtName ?? '',
        'date': dateString,
        'dateTime': currentDate,
        'amount': slot.amount ?? 0,
      };
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    // ════════════════════════════════════════════════════════════════════════
    // DESELECTING — tap on an already-selected half or full slot
    // ════════════════════════════════════════════════════════════════════════
    final blocks     = _getRealCourtSelectedBlocks(resolvedCourtId, dateString);
    final rangeStart = blocks.isEmpty ? 0 : blocks.first;
    final rangeEnd   = blocks.isEmpty ? 0 : blocks.last;

    final isAtStart      = tappedBlockStart == rangeStart;
    final isAtEnd        = tappedBlockStart == rangeEnd;
    final isOnlyOneBlock = blocks.length == 1;
    final isOnlyTwoBlocks = blocks.length == 2; // = exactly one full slot

    // Single block → remove all
    if (isOnlyOneBlock) {
      _removeAllRealCourtForCourtDate(resolvedCourtId, dateString);
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    // Exactly one full slot (2 blocks) → tapping either half removes all
    if (isOnlyTwoBlocks) {
      _removeAllRealCourtForCourtDate(resolvedCourtId, dateString);
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    // 3+ blocks → safe to trim
    if (isAtStart) {
      _removeRealCourtEdgeBlock(
        removedBlockStart: tappedBlockStart,
        slotId: slotId,
        slot: slot,
        courtId: resolvedCourtId,
        courtName: courtName ?? '',
        dateString: dateString,
        currentDate: currentDate,
        removingFirstHalf: true,
        fullKey: fullKey,
        firstKey: firstKey,
        secondKey: secondKey,
        hasFullSlot: hasFullSlot,
      );
      _cleanupIsolatedRealCourtHalves(courtId: resolvedCourtId, dateString: dateString);
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    if (isAtEnd) {
      _removeRealCourtEdgeBlock(
        removedBlockStart: tappedBlockStart,
        slotId: slotId,
        slot: slot,
        courtId: resolvedCourtId,
        courtName: courtName ?? '',
        dateString: dateString,
        currentDate: currentDate,
        removingFirstHalf: false,
        fullKey: fullKey,
        firstKey: firstKey,
        secondKey: secondKey,
        hasFullSlot: hasFullSlot,
      );
      _cleanupIsolatedRealCourtHalves(courtId: resolvedCourtId, dateString: dateString);
      recalculateRealCourtTotalAmount();
      realCourtSelections.refresh();
      return;
    }

    // ── MIDDLE block tapped ──────────────────────────────────────────────────
    //
    // If the tapped half belongs to a FULL slot (both halves selected together),
    // remove that entire full slot — not just from this half onward.
    // This keeps the blocks on either side connected.
    //
    // Example: range [1140, 1170, 1200] = 7pm(full) + 8pm(left half)
    //   User taps 7pm right half (block 1170, which is a middle block).
    //   7pm is stored as a full slot → remove entire 7pm full slot.
    //   Remaining: [1200] = 8pm left half → cleanup removes isolated half?
    //   NO — 1200 is now the only block. That is a valid half if its
    //   neighbour 1170 was just removed. Cleanup will remove it only if
    //   it has no consecutive neighbour. Here 1200 has no neighbour left
    //   so cleanup removes it — leaves nothing.
    //   BUT that is WRONG: 7:30–8:30 should remain = [1170, 1200].
    //
    // Correct logic: remove ONLY the tapped 30-min block from its full slot,
    // keeping the OTHER half. Then cleanup will keep it if it still connects.
    //
    // So: tap 7pm RIGHT half (1170) while 7pm is full →
    //   Remove full 7pm, re-add 7pm LEFT half (1140) only.
    //   Blocks become [1140, 1200] — gap of 60! Not consecutive.
    //   Hmm that's wrong too.
    //
    // ACTUALLY the right answer is:
    //   Remove the full 7pm slot entirely (both halves 1140 + 1170).
    //   Result: [1200] = 8pm left half alone.
    //   8pm left half needs neighbour at 1170 or 1230. 1170 gone, 1230 not selected.
    //   → isolated → cleanup removes it. Everything gone.
    //
    // But user wants: 7:30–8:30 = [1170, 1200].
    // That means tap 7pm right half → remove 7pm LEFT half only (1140),
    // keep 7pm RIGHT half (1170). Result [1170, 1200] = consecutive ✓.
    //
    // So the rule for a middle block that is part of a FULL slot:
    //   • Tapping RIGHT half of full slot → remove LEFT half, keep RIGHT half.
    //   • Tapping LEFT  half of full slot → cascade from this block (remove this + everything after).

    if (hasFullSlot) {
      // Tapped half is part of a full slot in the middle of the range.
      // Remove the entire full slot — keep both the left side and right side
      // of the range intact as separate segments.
      // Cleanup will then remove any halves that become isolated.
      //
      // Example: 7pm(full) + 8pm(full) + 9pm(firstHalf)
      //   Tap 8pm left half → remove 8pm full entirely
      //   Result: 7pm(full) stays + 9pm(firstHalf) stays
      //   Cleanup: 9pm firstHalf neighbour = 1230 (gone) → isolated → removed
      //   Final: 7pm full only... BUT that's wrong per user expectation.
      //
      // Actually user wants: 7pm intact AND 8:30→9:30 intact.
      // 8pm right half (1230) + 9pm firstHalf (1260) are still consecutive.
      // So we should keep 8pm second half when removing 8pm first half.
      //
      // Rule:
      //   Tap LEFT  half of middle full slot → remove full, keep RIGHT half
      //   Tap RIGHT half of middle full slot → remove full, keep LEFT half
      // Both kept halves stay connected to whatever is on their respective side.

      realCourtSelections.remove(fullKey);

      if (tappingFirstHalf) {
        // Keep second half (right side stays connected forward)
        final halfSlot = Slots(
            sId: slotId, time: slot.time, amount: (slot.amount ?? 0) ~/ 2);
        realCourtSelections[secondKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': false,
        };
      } else {
        // Keep first half (left side stays connected backward)
        final halfSlot = Slots(
            sId: slotId, time: slot.time, amount: (slot.amount ?? 0) ~/ 2);
        realCourtSelections[firstKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': true,
        };
      }
    } else {
      // Standalone half in the middle — remove only this half entry.
      if (hasFirstHalf) {
        realCourtSelections.remove(firstKey);
      } else if (hasSecondHalf) {
        realCourtSelections.remove(secondKey);
      }
    }

    _cleanupIsolatedRealCourtHalves(courtId: resolvedCourtId, dateString: dateString);
    recalculateRealCourtTotalAmount();
    realCourtSelections.refresh();
  }

  // ---------------------------------------------------------------------------
  // REAL COURT HELPERS
  // ---------------------------------------------------------------------------

  /// Returns sorted list of 30-min block start times (minutes from midnight)
  /// for a specific court+date in realCourtSelections.
  List<int> _getRealCourtSelectedBlocks(String courtId, String dateString) {
    final mins = <int>{};
    realCourtSelections.forEach((k, v) {
      if ((v['courtId'] as String) != courtId) return;
      if ((v['date'] as String) != dateString) return;
      final s         = v['slot'] as Slots;
      final base      = _parseTimeToMinutesLocal(s.time ?? '');
      final halfFlag  = v['isHalfSlot'] as bool? ?? false;
      final firstFlag = v['isFirstHalf'] as bool? ?? true;
      if (!halfFlag) {
        mins.add(base);
        mins.add(base + 30);
      } else {
        mins.add(firstFlag ? base : base + 30);
      }
    });
    return mins.toList()..sort();
  }

  /// Remove an edge (start or end) 30-min block from realCourtSelections.
  void _removeRealCourtEdgeBlock({
    required int removedBlockStart,
    required String slotId,
    required Slots slot,
    required String courtId,
    required String courtName,
    required String dateString,
    required DateTime currentDate,
    required bool removingFirstHalf,
    required String fullKey,
    required String firstKey,
    required String secondKey,
    required bool hasFullSlot,
  }) {
    if (hasFullSlot) {
      realCourtSelections.remove(fullKey);
      if (removingFirstHalf) {
        // Keep second half only
        final halfSlot = Slots(
          sId: slotId,
          time: slot.time,
          amount: (slot.amount ?? 0) ~/ 2,
        );
        realCourtSelections[secondKey] = {
          'slot': halfSlot,
          'courtId': courtId,
          'courtName': courtName,
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': false,
        };
      } else {
        // Keep first half only
        final halfSlot = Slots(
          sId: slotId,
          time: slot.time,
          amount: (slot.amount ?? 0) ~/ 2,
        );
        realCourtSelections[firstKey] = {
          'slot': halfSlot,
          'courtId': courtId,
          'courtName': courtName,
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': true,
        };
      }
    } else {
      // Was already a single half — remove whichever half is actually stored
      if (realCourtSelections.containsKey(firstKey)) {
        realCourtSelections.remove(firstKey);
      } else {
        realCourtSelections.remove(secondKey);
      }
    }
  }

  /// Cascade-remove all 30-min blocks from [fromBlock] onward in realCourtSelections.
  /// Partial full slots (where first half is before fromBlock) are split — only
  /// the first half is kept.
  void _cascadeRemoveRealCourtFromBlock({
    required int fromBlock,
    required String courtId,
    required String dateString,
    required DateTime currentDate,
  }) {
    final keysToRemove = <String>[];
    final Map<String, Map<String, dynamic>> toAdd = {};

    realCourtSelections.forEach((key, value) {
      if ((value['courtId'] as String) != courtId) return;
      if ((value['date'] as String) != dateString) return;

      final s         = value['slot'] as Slots;
      final base      = _parseTimeToMinutesLocal(s.time ?? '');
      final halfFlag  = value['isHalfSlot'] as bool? ?? false;
      final firstFlag = value['isFirstHalf'] as bool? ?? true;

      if (!halfFlag) {
        if (base >= fromBlock) {
          // Entire full slot is at/after fromBlock → remove
          keysToRemove.add(key);
        } else if (base + 30 >= fromBlock) {
          // Partial overlap: base < fromBlock but base+30 >= fromBlock
          // Remove full slot, keep first half only
          keysToRemove.add(key);
          final slotId   = s.sId ?? '';
          final firstKey = '${dateString}_${courtId}_${slotId}_first_half';
          final halfSlot = Slots(
            sId: slotId,
            time: s.time,
            amount: (s.amount ?? 0) ~/ 2,
          );
          toAdd[firstKey] = {
            'slot': halfSlot,
            'courtId': courtId,
            'courtName': value['courtName'] ?? '',
            'date': dateString,
            'dateTime': currentDate,
            'amount': (s.amount ?? 0) ~/ 2,
            'isHalfSlot': true,
            'isFirstHalf': true,
          };
        }
      } else {
        final blockStart = firstFlag ? base : base + 30;
        if (blockStart >= fromBlock) keysToRemove.add(key);
      }
    });

    for (final k in keysToRemove) realCourtSelections.remove(k);
    toAdd.forEach((k, v) => realCourtSelections[k] = v);
  }

  /// Remove ALL realCourtSelections for a specific court+date.
  void _removeAllRealCourtForCourtDate(String courtId, String dateString) {
    final keys = realCourtSelections.keys.where((k) {
      final v = realCourtSelections[k]!;
      return (v['courtId'] as String) == courtId &&
          (v['date'] as String) == dateString;
    }).toList();
    for (final k in keys) realCourtSelections.remove(k);
  }

  /// Remove any isolated half slots in realCourtSelections that have no
  /// consecutive neighbour block. Loops until stable.
  void _cleanupIsolatedRealCourtHalves({
    required String courtId,
    required String dateString,
  }) {
    bool changed = true;
    while (changed) {
      changed = false;
      final keysToRemove = <String>[];

      realCourtSelections.forEach((key, value) {
        if ((value['courtId'] as String) != courtId) return;
        if ((value['date'] as String) != dateString) return;
        final isHalf = value['isHalfSlot'] as bool? ?? false;
        if (!isHalf) return;

        final s              = value['slot'] as Slots;
        final base           = _parseTimeToMinutesLocal(s.time ?? '');
        final isFirst        = value['isFirstHalf'] as bool? ?? true;
        // For first half  (covers base → base+30): neighbour must be at base-30 (block before) OR base+30 is covered by own full slot (impossible here)
        // The block this half occupies: isFirst → base, !isFirst → base+30
        // Its consecutive neighbour is the adjacent 30-min block:
        //   first half  (at base)      → neighbour at base-30  (block before it)
        //   second half (at base+30)   → neighbour at base+60  (block after it)
        final myBlock        = isFirst ? base : base + 30;
        final neighbourBlock = isFirst ? base - 30 : base + 60;

        bool neighbourExists = false;
        realCourtSelections.forEach((k2, v2) {
          if (k2 == key) return;
          if ((v2['courtId'] as String) != courtId) return;
          if ((v2['date'] as String) != dateString) return;
          final s2     = v2['slot'] as Slots;
          final base2  = _parseTimeToMinutesLocal(s2.time ?? '');
          final half2  = v2['isHalfSlot'] as bool? ?? false;
          final first2 = v2['isFirstHalf'] as bool? ?? true;
          if (!half2) {
            // Full slot covers blocks at base2 and base2+30
            if (base2 == neighbourBlock || base2 + 30 == neighbourBlock) {
              neighbourExists = true;
            }
          } else {
            // Half slot covers one block: first→base2, second→base2+30
            final block2 = first2 ? base2 : base2 + 30;
            if (block2 == neighbourBlock) neighbourExists = true;
          }
        });

        if (!neighbourExists) keysToRemove.add(key);
      });

      for (final k in keysToRemove) {
        realCourtSelections.remove(k);
        changed = true;
      }
    }
  }

  // ===========================================================================
  // MAIN GRID SLOT SELECTION (toggleSlotSelection) — unchanged from original
  // ===========================================================================

  void toggleSlotSelection(
      Slots slot, {
        String? courtId,
        String? courtName,
        bool? isHalfSlot,
        bool? isFirstHalf,
      }) {
    final slotId          = slot.sId ?? '';
    final resolvedCourtId = courtId ?? '';
    final currentDate     = selectedDate.value ?? DateTime.now();
    final dateString      =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    final is90MinSlot = slot.duration == 90;
    if (multiDateSelections.isNotEmpty) {
      bool has90 = false, hasNon90 = false;
      multiDateSelections.forEach((key, sel) {
        final s = sel['slot'] as Slots;
        if (s.duration == 90) has90 = true; else hasNon90 = true;
      });
      if (is90MinSlot && hasNon90) {
        CustomLogger.logMessage(
            msg: "Cannot mix 90-minute slots with 30/60-minute slots",
            level: LogLevel.error);
        return;
      }
      if (!is90MinSlot && has90) {
        CustomLogger.logMessage(
            msg: "Cannot mix 30/60-minute slots with 90-minute slots",
            level: LogLevel.error);
        return;
      }
    }

    selectedTimeSlot.value = slot.time ?? '';

    if (is30Slots.value && isHalfSlot == true) {
      if (isPastHalfSlot(slot, isFirstHalf ?? true)) return;

      final firstHalfKey  = '${dateString}_${resolvedCourtId}_${slotId}_first_half';
      final secondHalfKey = '${dateString}_${resolvedCourtId}_${slotId}_second_half';
      final fullSlotKey   = '${dateString}_${resolvedCourtId}_$slotId';
      final clickedHalfKey = isFirstHalf == true ? firstHalfKey : secondHalfKey;

      if (multiDateSelections.containsKey(clickedHalfKey)) {
        multiDateSelections.remove(clickedHalfKey);
      } else if (isFirstHalf == false &&
          multiDateSelections.containsKey(firstHalfKey)) {
        multiDateSelections.remove(firstHalfKey);
        multiDateSelections[fullSlotKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      } else if (isFirstHalf == true &&
          multiDateSelections.containsKey(secondHalfKey)) {
        multiDateSelections.remove(secondHalfKey);
        multiDateSelections[fullSlotKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      } else if (multiDateSelections.containsKey(fullSlotKey)) {
        multiDateSelections.remove(fullSlotKey);
        final halfSlot = Slots(
          sId: slotId,
          time: slot.time,
          amount: (slot.amount ?? 0) ~/ 2,
        );
        multiDateSelections[clickedHalfKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': isFirstHalf,
        };
      } else {
        final halfSlot = Slots(
          sId: slotId,
          time: slot.time,
          amount: (slot.amount ?? 0) ~/ 2,
        );
        multiDateSelections[clickedHalfKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': isFirstHalf,
        };
      }
    } else {
      final multiDateKey = '${dateString}_${resolvedCourtId}_$slotId';
      if (multiDateSelections.containsKey(multiDateKey)) {
        multiDateSelections.remove(multiDateKey);
      } else {
        multiDateSelections[multiDateKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      }
    }

    _recalculateTotalAmount();
    log("Selected ${multiDateSelections.length} slots for date: $dateString, Total: ₹${totalAmount.value}");
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================

  /// Parse time string to minutes from midnight.
  int _parseTimeToMinutesLocal(String time) {
    try {
      final cleanTime = time.trim().toLowerCase();
      final parts     = cleanTime.split(' ');
      if (parts.length != 2) return 0;
      final timePart  = parts[0];
      final period    = parts[1];
      final timeParts = timePart.split(':');
      int hour   = int.tryParse(timeParts[0]) ?? 0;
      int minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
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

  bool isPastHalfSlot(Slots slot, bool isFirstHalf) {
    final rawTime = slot.time;
    if (rawTime == null || rawTime.trim().isEmpty) return false;
    final now      = DateTime.now();
    final selected = selectedDate.value ?? now;
    final isToday  = selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day;
    if (!isToday) return false;

    try {
      final timeString = rawTime.toLowerCase().trim();
      DateTime? parsed;
      for (final pattern in const ['h:mm a', 'h a', 'HH:mm', 'H:mm', 'HH']) {
        try {
          parsed = DateFormat(pattern).parseStrict(timeString);
          break;
        } catch (_) {}
      }
      int hour, minute;
      if (parsed != null) {
        hour   = parsed.hour;
        minute = parsed.minute;
      } else {
        String t        = timeString;
        String meridiem = '';
        final parts     = t.split(' ');
        if (parts.length == 2) {
          t        = parts[0];
          meridiem = parts[1];
        }
        final timePieces = t.split(':');
        hour   = int.tryParse(timePieces[0]) ?? 0;
        minute = timePieces.length > 1 ? int.tryParse(timePieces[1]) ?? 0 : 0;
        if (meridiem == 'pm' && hour != 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
      }
      if (!isFirstHalf) {
        minute += 30;
        if (minute >= 60) { hour += 1; minute -= 60; }
      }
      final slotDateTime = DateTime(
          selected.year, selected.month, selected.day, hour, minute);
      return now.isAfter(slotDateTime);
    } catch (_) {
      return false;
    }
  }

  bool isPastAndUnavailable(Slots slot) {
    final status = _normalizeStatus(slot.status);
    if (status == 'booked') return true;
    if (status.isNotEmpty && status != 'available') return true;

    final rawTime = slot.time;
    if (rawTime == null || rawTime.trim().isEmpty) return false;

    final now      = DateTime.now();
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
      int hour, minute;
      if (parsed != null) {
        hour   = parsed.hour;
        minute = parsed.minute;
      } else {
        String t        = timeString;
        String meridiem = '';
        final parts     = t.split(' ');
        if (parts.length == 2) {
          t        = parts[0];
          meridiem = parts[1];
        }
        final timePieces = t.split(':');
        hour   = int.tryParse(timePieces[0]) ?? 0;
        minute = timePieces.length > 1 ? int.tryParse(timePieces[1]) ?? 0 : 0;
        if (meridiem == 'pm' && hour != 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
      }

      final slotDateTime = DateTime(
          selected.year, selected.month, selected.day, hour, minute);
      final isToday = selected.year == now.year &&
          selected.month == now.month &&
          selected.day == now.day;

      if (isToday) {
        // Show slot until 15 minutes after its start time
        // e.g., 3:00 PM slot remains visible until 3:15 PM
        if (now.isAfter(slotDateTime.add(const Duration(minutes: 15)))) return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  bool _isUnavailableSlot(Slots slot) {
    final availability = _normalizeStatus(slot.availabilityStatus);
    final isBlocked    = availability == "maintenance" ||
        availability == "weather conditions" ||
        availability == "staff unavailability" ||
        availability == "tournament";
    final isBooked = (_normalizeStatus(slot.status) == 'booked');
    final isPast   = isPastAndUnavailable(slot);
    return isPast || isBlocked || isBooked;
  }

  bool _isAvailableSlot(Slots slot) {
    final status = _normalizeStatus(slot.status);
    return !_isUnavailableSlot(slot) &&
        (status == 'available' || status.isEmpty);
  }

  String _normalizeStatus(String? value) =>
      (value ?? '').trim().toLowerCase();

  bool isSlotSelected(Slots slot, String courtId) {
    final currentDate  = selectedDate.value ?? DateTime.now();
    final dateString   =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final multiDateKey = '${dateString}_${courtId}_${slot.sId}';
    if (multiDateSelections.containsKey(multiDateKey)) return true;
    if (is30Slots.value) {
      final firstHalfKey  = '${dateString}_${courtId}_${slot.sId}_first_half';
      final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
      return multiDateSelections.containsKey(firstHalfKey) ||
          multiDateSelections.containsKey(secondHalfKey);
    }
    return false;
  }

  bool isBothHalvesSelectedInMainGrid(Slots slot, String courtId) {
    if (!is30Slots.value) return false;
    final currentDate   = selectedDate.value ?? DateTime.now();
    final dateString    =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey   = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey  = '${dateString}_${courtId}_${slot.sId}_first_half';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
    return multiDateSelections.containsKey(fullSlotKey) ||
        (multiDateSelections.containsKey(firstHalfKey) &&
            multiDateSelections.containsKey(secondHalfKey));
  }

  bool isLeftHalfSelectedInMainGrid(Slots slot, String courtId) {
    if (!is30Slots.value) return false;
    final currentDate  = selectedDate.value ?? DateTime.now();
    final dateString   =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey  = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
    return multiDateSelections.containsKey(fullSlotKey) ||
        multiDateSelections.containsKey(firstHalfKey);
  }

  bool isRightHalfSelectedInMainGrid(Slots slot, String courtId) {
    if (!is30Slots.value) return false;
    final currentDate   = selectedDate.value ?? DateTime.now();
    final dateString    =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey   = '${dateString}_${courtId}_${slot.sId}';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
    return multiDateSelections.containsKey(fullSlotKey) ||
        multiDateSelections.containsKey(secondHalfKey);
  }

  bool isRealCourtSlotSelected(Slots slot, String courtId) {
    final currentDate  = selectedDate.value ?? DateTime.now();
    final dateString   =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final realCourtKey = '${dateString}_${courtId}_${slot.sId}';
    if (realCourtSelections.containsKey(realCourtKey)) return true;
    if (clubSupports30MinSlots(courtId)) {
      final firstHalfKey  = '${dateString}_${courtId}_${slot.sId}_first_half';
      final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
      return realCourtSelections.containsKey(firstHalfKey) ||
          realCourtSelections.containsKey(secondHalfKey);
    }
    return false;
  }

  bool isBothHalvesSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;
    final currentDate   = selectedDate.value ?? DateTime.now();
    final dateString    =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey   = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey  = '${dateString}_${courtId}_${slot.sId}_first_half';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
    return realCourtSelections.containsKey(fullSlotKey) ||
        (realCourtSelections.containsKey(firstHalfKey) &&
            realCourtSelections.containsKey(secondHalfKey));
  }

  bool isLeftHalfSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;
    final currentDate  = selectedDate.value ?? DateTime.now();
    final dateString   =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey  = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
    return realCourtSelections.containsKey(fullSlotKey) ||
        realCourtSelections.containsKey(firstHalfKey);
  }

  bool isRightHalfSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;
    final currentDate   = selectedDate.value ?? DateTime.now();
    final dateString    =
        "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey   = '${dateString}_${courtId}_${slot.sId}';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
    return realCourtSelections.containsKey(fullSlotKey) ||
        realCourtSelections.containsKey(secondHalfKey);
  }

  int getTotalSelectionsCount() => multiDateSelections.length;

  String formatTimeRangeWithDuration(String startTime,
      {bool isHalfSlot = false, bool isFirstHalf = true}) {
    try {
      final cleanTime = startTime.trim().toLowerCase();
      final parts     = cleanTime.split(' ');
      if (parts.length != 2) return startTime;
      final timePart  = parts[0];
      final period    = parts[1];
      final timeParts = timePart.split(':');
      int hour   = int.tryParse(timeParts[0]) ?? 0;
      int minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      int durationMinutes = 60;
      if (isHalfSlot) {
        durationMinutes = 30;
        if (!isFirstHalf) {
          minute += 30;
          if (minute >= 60) { hour += 1; minute -= 60; }
        }
      }

      int endHour   = hour;
      int endMinute = minute + durationMinutes;
      if (endMinute >= 60) { endHour += 1; endMinute -= 60; }

      String startPeriod   = hour >= 12 ? 'PM' : 'AM';
      int displayStartHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      String formattedStart =
          '$displayStartHour:${minute.toString().padLeft(2, '0')} $startPeriod';

      String endPeriod   = endHour >= 12 ? 'PM' : 'AM';
      int displayEndHour = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
      String formattedEnd =
          '$displayEndHour:${endMinute.toString().padLeft(2, '0')} $endPeriod';

      return '$formattedStart - $formattedEnd';
    } catch (e) {
      return startTime;
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final timeString = timeStr.toLowerCase().trim();
      DateTime? parsed;
      for (final pattern in const ['h:mm a', 'h a', 'HH:mm', 'H:mm', 'HH']) {
        try {
          parsed = DateFormat(pattern).parseStrict(timeString);
          break;
        } catch (_) {}
      }
      int hour, minute;
      if (parsed != null) {
        hour   = parsed.hour;
        minute = parsed.minute;
      } else {
        String t        = timeString;
        String meridiem = '';
        final parts     = t.split(' ');
        if (parts.length == 2) {
          t        = parts[0];
          meridiem = parts[1];
        }
        final timePieces = t.split(':');
        hour   = int.tryParse(timePieces[0]) ?? 0;
        minute = timePieces.length > 1 ? int.tryParse(timePieces[1]) ?? 0 : 0;
        if (meridiem == 'pm' && hour != 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
      }
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  Map<String, List<Map<String, dynamic>>> getSelectionsByDate() {
    final Map<String, List<Map<String, dynamic>>> result = {};
    multiDateSelections.forEach((key, selection) {
      final dateString = selection['date'] as String;
      if (!result.containsKey(dateString)) result[dateString] = [];
      result[dateString]!.add(selection);
    });
    return result;
  }

  void clearAllSelections() {
    multiDateSelections.clear();
    realCourtSelections.clear();
    selectedSlots.clear();
    totalAmount.value          = 0;
    courtsByDuration.value     = null;
    selectedTimeSlot.value     = '';
    selectedSearchSlotId.value = null;
    isSlotsCollapsed.value     = false;
  }

  void clearAvailableCourtsOnly() {
    realCourtSelections.clear();
    courtsByDuration.value = null;
    recalculateRealCourtTotalAmount();
  }

  void fetchCourtsIfReady() {
    if (selectedDate.value != null &&
        selectedDuration.value.isNotEmpty &&
        selectedTimeSlot.value.isNotEmpty) {
      fetchCourtsByDuration();
    }
  }

  void updateSlotPricesForSpecificClub(GetCourtsByDurationData clubData) {
    if (clubData.courts == null) return;
    final selectedDurationMinutes =
        int.tryParse(selectedDuration.value.replaceAll(' min', '')) ?? 60;
    final currentDate = selectedDate.value ?? DateTime.now();
    final dayName     = getWeekday(currentDate.weekday);

    for (var court in clubData.courts!) {
      if (court.slots == null) continue;
      for (var slot in court.slots!) {
        final slotTime = slot.time;
        if (slotTime == null) continue;
        int? slotPrice;
        if (selectedDurationMinutes == 90) {
          slotPrice = findPriceForSlot(slotTime, dayName, 60);
        } else {
          final duration =
          selectedDurationMinutes == 120 ? 60 : selectedDurationMinutes;
          slotPrice = findPriceForSlot(slotTime, dayName, duration);
        }
        if (slotPrice != null) slot.amount = slotPrice;
      }
    }
  }

  int? findPriceForSlot(String slotTime, String day, int duration) {
    final slotPrices = allSlotPricesResponse.value?.data;
    if (slotPrices == null) return null;
    final slotHour = parseHour24(slotTime);
    if (slotHour == null) return null;
    for (final priceEntry in slotPrices) {
      if (priceEntry.day != day || priceEntry.duration != duration) continue;
      final slotTimeRange = priceEntry.slotTime;
      if (slotTimeRange == null) continue;
      if (isTimeInRange(slotHour, slotTimeRange)) return priceEntry.price;
    }
    return null;
  }

  bool isTimeInRange(int slotHour, String timeRange) {
    try {
      final parts = timeRange.split(' - ');
      if (parts.length != 2) return false;
      final startHour = parseHour24(parts[0].trim());
      final endHour   = parseHour24(parts[1].trim());
      if (startHour == null || endHour == null) return false;
      return slotHour >= startHour && slotHour <= endHour;
    } catch (e) {
      return false;
    }
  }

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
          final hm   = parts[0].split(':');
          final h    = int.tryParse(hm[0]);
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

  String formatTimeForDisplay(String? time) {
    if (time == null || time.isEmpty) return '';
    final timeStr = time.trim().toLowerCase();
    if (timeStr.contains(':')) return time;
    final match = RegExp(r'(\d+)\s*(am|pm)').firstMatch(timeStr);
    if (match != null) {
      final hour   = match.group(1);
      final period = match.group(2);
      return '$hour:00 $period';
    }
    return time;
  }

  String getHalfSlotTime(String originalTime, bool isFirstHalf) {
    if (isFirstHalf) return originalTime;
    try {
      final timeString = originalTime.trim();
      DateTime? parsedTime;
      for (final pattern in ['h:mm a', 'h a', 'HH:mm', 'H:mm']) {
        try {
          parsedTime = DateFormat(pattern).parse(timeString);
          break;
        } catch (_) {}
      }
      if (parsedTime != null) {
        final newTime = parsedTime.add(const Duration(minutes: 30));
        return DateFormat('h:mm a').format(newTime);
      }
      final parts = timeString.split(' ');
      if (parts.length == 2) {
        final timePart = parts[0];
        final period   = parts[1].toLowerCase();
        final hour     = int.tryParse(timePart);
        if (hour != null) return '$hour:30 ${period.toLowerCase()}';
      }
    } catch (e) {
      log('Error calculating half slot time: $e');
    }
    return originalTime.replaceFirst(':', ':30').replaceFirst(' ', ':30 ');
  }

  String _formatTimeForAPI(String time) {
    if (time.isEmpty) return time;
    try {
      final timeString = time.trim();
      DateTime? parsedTime;
      for (final pattern in ['h:mm a', 'h a', 'HH:mm', 'H:mm']) {
        try {
          parsedTime = DateFormat(pattern).parse(timeString);
          break;
        } catch (_) {}
      }
      if (parsedTime != null) {
        int hour      = parsedTime.hour;
        String period = hour >= 12 ? 'pm' : 'am';
        if (hour == 0) hour = 12;
        else if (hour > 12) hour = hour - 12;
        return '$hour $period';
      }
      final parts     = timeString.split(' ');
      String timePart = parts[0];
      String? period  = parts.length > 1 ? parts[1].toLowerCase() : null;
      if (timePart.contains(':')) timePart = timePart.split(':')[0];
      int? hour = int.tryParse(timePart);
      if (hour != null) {
        if (period == null) period = hour >= 12 ? 'pm' : 'am';
        else period = period.toLowerCase();
        if (hour == 0) hour = 12;
        else if (hour > 12) { hour = hour - 12; period = 'pm'; }
        else if (hour == 12 && period == 'am') hour = 12;
        return '$hour $period';
      }
    } catch (e) {
      log('Error formatting time: $e');
    }
    return time;
  }

  Future<void> fetchCourtsByDuration() async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
    final durationValue = is30Slots.value ? '30' : '60';

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

    String? catId;
    try {
      final mainHomeController = Get.find<MainHomeController>();
      catId = mainHomeController.selectedCategoryId.value.isNotEmpty
          ? mainHomeController.selectedCategoryId.value
          : null;
    } catch (_) {}

    // Unsubscribe previous if params changed
    if (_lastSubscribedDate != null) {
      _unsubscribeFromCourtsByDuration();
    }

    isSocketDataReceived.value = false;
    _lastSubscribedDate = dateString;
    _lastSubscribedDuration = durationValue;

    final socketService = SocketService.instance;
    if (socketService.isConnected) {
      final userId = storage.read('userId')?.toString() ?? '';
      socketService.setCourtsByDurationCallback((response) {
        log('🔄 courtsByDuration:data real-time update received: $response');
        final data = response['data'] ?? response;
        _handleCourtsByDurationData(data);
      });

      socketService.subscribeToCourtsByDuration(
        date: dateString,
        duration: durationValue,
        time: formattedTime.isNotEmpty ? formattedTime : null,
        categoryId: catId,
        // location: locationId.value.isNotEmpty ? locationId.value : null,
        queryKey: 'book-a-court',
        userId: userId,
        onInitialData: (data) {
          log('📡 courtsByDuration initial data from socket ack');
          isSocketDataReceived.value = true;
          _handleCourtsByDurationData(data);
        },
      );

      // Fallback: if no socket data in 3s, use API
      Future.delayed(const Duration(seconds: 3), () {
        if (!isSocketDataReceived.value) {
          log('⚠️ No socket data, falling back to API');
          _fetchCourtsByDurationFromApi(
            dateString: dateString,
            durationValue: durationValue,
            formattedTime: formattedTime,
            catId: catId,
          );
        }
      });
    } else {
      // No socket — use API directly
      await _fetchCourtsByDurationFromApi(
        dateString: dateString,
        durationValue: durationValue,
        formattedTime: formattedTime,
        catId: catId,
      );
    }
  }

  void _handleCourtsByDurationData(dynamic data) {
    try {
      if (data == null) return;
      // Socket sends the data array directly; wrap it for fromJson
      final Map<String, dynamic> json = data is List
          ? {'data': data}
          : (data is Map<String, dynamic> ? data : {'data': data});
      final response = GetCourtsByDurationModel.fromJson(json);
      courtsByDuration.value = response;
      isLoadingCourtsByDuration.value = false;
      log('✅ courtsByDuration updated: ${response.data?.length} clubs');
    } catch (e) {
      log('❌ Error parsing courtsByDuration socket data: $e');
    }
  }

  Future<void> _fetchCourtsByDurationFromApi({
    required String dateString,
    required String durationValue,
    required String formattedTime,
    String? catId,
  }) async {
    try {
      isLoadingCourtsByDuration.value = true;
      final response = await _homeRepository.getCourtsByDuration(
        duration: durationValue,
        date: dateString,
        time: formattedTime,
        categoryId: catId,
        page: 1,
        limit: 15,
      );
      courtsByDuration.value = response;
      log('Courts by duration fetched from API: ${response.data?.length} clubs');
    } catch (e) {
      log('Error fetching courts by duration from API: $e');
    } finally {
      isLoadingCourtsByDuration.value = false;
    }
  }

  void _unsubscribeFromCourtsByDuration() {
    if (_lastSubscribedDate == null || _lastSubscribedDuration == null) return;
    try {
      SocketService.instance.unsubscribeFromCourtsByDuration(
        date: _lastSubscribedDate!,
        duration: _lastSubscribedDuration!,
      );
      SocketService.instance.clearCourtsByDurationCallback();
      _lastSubscribedDate = null;
      _lastSubscribedDuration = null;
    } catch (e) {
      log('Error unsubscribing courtsByDuration: $e');
    }
  }

  bool isLeftHalfBooked(Slots slot, String courtId) {
    if (courtsByDuration.value?.data == null) return false;
    for (var clubData in courtsByDuration.value!.data!) {
      if (clubData.courts != null) {
        for (var court in clubData.courts!) {
          if (court.id == courtId && court.slots != null) {
            for (var apiSlot in court.slots!) {
              if (apiSlot.duration == 30 && apiSlot.bookingTime != null) {
                final leftHalfTime = getHalfSlotTime(slot.time ?? '', true);
                if (apiSlot.bookingTime!.toLowerCase().trim() ==
                    leftHalfTime.toLowerCase().trim()) return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  bool isRightHalfBooked(Slots slot, String courtId) {
    if (courtsByDuration.value?.data == null) return false;
    for (var clubData in courtsByDuration.value!.data!) {
      if (clubData.courts != null) {
        for (var court in clubData.courts!) {
          if (court.id == courtId && court.slots != null) {
            for (var apiSlot in court.slots!) {
              if (apiSlot.duration == 30 && apiSlot.bookingTime != null) {
                final rightHalfTime = getHalfSlotTime(slot.time ?? '', false);
                if (apiSlot.bookingTime!.toLowerCase().trim() ==
                    rightHalfTime.toLowerCase().trim()) return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

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

  Future<bool> processSlotHistoryForPayment() async {
    if (realCourtSelections.isEmpty) return false;
    try {
      final slotsList = <Map<String, dynamic>>[];
      for (var entry in realCourtSelections.entries) {
        final selection   = entry.value;
        final slot        = selection['slot'] as Slots;
        final slotId      = slot.sId ?? '';
        final courtId     = selection['courtId'] as String;
        final courtName   = selection['courtName'] as String;
        final dateString  = selection['date'] as String;
        final isHalfSlot  = selection['isHalfSlot'] as bool? ?? false;
        final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
        final bookingTime = isHalfSlot
            ? getHalfSlotTime(slot.time ?? '', isFirstHalf)
            : slot.time ?? '';
        final duration      = isHalfSlot ? 30 : 60;
        final finalDuration = (slot.duration == 90) ? 90 : duration;
        final userId = storage.read("userId")??"";
        slotsList.add({
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
      final success = await createAndGetSlotHistory(slots: slotsList);
      if (success) hasCalledSlotHistoryAPI.value = true;
      return success;
    } catch (e) {
      log('Error processing slot history: $e');
      return false;
    }
  }

  List<Map<String, dynamic>>? buildBookingPayload() {
    print("From Book A Court Payload------------");
    if (realCourtSelections.isEmpty || courtsByDuration.value == null) {
      return null;
    }

    final List<Map<String, dynamic>> payloadList = [];
    final Map<String, List<Map<String, dynamic>>> selectionsByClub = {};

    for (var entry in realCourtSelections.entries) {
      final selection = entry.value;
      final courtId   = selection['courtId'] as String;

      String? clubId;
      GetCourtsByDurationData? courtData;

      for (var clubData in courtsByDuration.value!.data ?? []) {
        if (clubData.courts != null) {
          for (var court in clubData.courts!) {
            if (court.id == courtId) {
              clubId    = clubData.registerClub?.id;
              courtData = clubData;
              break;
            }
          }
        }
        if (clubId != null) break;
      }
      if (clubId == null || courtData == null) continue;

      if (!selectionsByClub.containsKey(clubId)) {
        selectionsByClub[clubId] = [];
      }
      selectionsByClub[clubId]!.add(selection);
    }

    for (var clubEntry in selectionsByClub.entries) {
      final clubId         = clubEntry.key;
      final clubSelections = clubEntry.value;

      final specificCourtData = courtsByDuration.value!.data?.firstWhere(
            (c) => c.registerClub?.id == clubId,
        orElse: () => GetCourtsByDurationData(),
      );
      if (specificCourtData == null ||
          specificCourtData.registerClub?.id == null) continue;

      final firstSelection = clubSelections.first;
      final dateTime       = firstSelection['dateTime'] as DateTime;
      String bookingDay    = "";
      switch (dateTime.weekday) {
        case 1: bookingDay = "Monday";    break;
        case 2: bookingDay = "Tuesday";   break;
        case 3: bookingDay = "Wednesday"; break;
        case 4: bookingDay = "Thursday";  break;
        case 5: bookingDay = "Friday";    break;
        case 6: bookingDay = "Saturday";  break;
        case 7: bookingDay = "Sunday";    break;
      }

      final selectedBusinessHour = specificCourtData
          .registerClub?.businessHours
          ?.where((bh) => bh.day == bookingDay)
          .map((bh) => {"time": bh.time ?? "", "day": bh.day ?? ""})
          .toList() ??
          [];

      final Map<String, List<Map<String, dynamic>>> slotGroups = {};
      for (var selection in clubSelections) {
        final slot       = selection['slot'] as Slots;
        final cId        = selection['courtId'] as String;
        final slotId     = slot.sId ?? '';
        final dateString = selection['date'] as String;
        final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
        final groupKey   = isHalfSlot
            ? '${dateString}_${cId}_${slotId}_half'
            : '${dateString}_${cId}_${slotId}_full';
        if (!slotGroups.containsKey(groupKey)) slotGroups[groupKey] = [];
        slotGroups[groupKey]!.add(selection);
      }

      final List<Map<String, dynamic>> slotData = [];

      for (var slotGroup in slotGroups.entries) {
        final selections      = slotGroup.value;
        final isHalfSlotGroup = slotGroup.key.endsWith('_half');

        if (isHalfSlotGroup && selections.length == 2) {
          final firstSel    = selections.first;
          final slot        = firstSel['slot'] as Slots;
          final cId         = firstSel['courtId'] as String;
          final cName       = firstSel['courtName'] as String;
          final dt          = firstSel['dateTime'] as DateTime;
          final dateString  = DateFormat('yyyy-MM-dd').format(dt);
          final slotId      = slot.sId ?? '';
          final fullAmount  = selections.fold<int>(
              0, (sum, sel) => sum + (sel['amount'] as int? ?? 0));
          final finalDuration = (slot.duration == 90) ? 90 : 60;

          slotData.add({
            "slotId": slotId,
            "businessHours": selectedBusinessHour,
            "slotTimes": [{"time": slot.time ?? "", "amount": fullAmount}],
            "courtId": cId,
            "courtName": cName,
            "bookingDate": dateString,
            "duration": finalDuration,
            "totalTime": finalDuration,
            "bookingTime": slot.time ?? "",
          });
        } else {
          for (var selection in selections) {
            final slot          = selection['slot'] as Slots;
            final cId           = selection['courtId'] as String;
            final cName         = selection['courtName'] as String;
            final dt            = selection['dateTime'] as DateTime;
            final dateString    = DateFormat('yyyy-MM-dd').format(dt);
            final slotId        = slot.sId ?? '';
            final isHalfSlot    = selection['isHalfSlot'] as bool? ?? false;
            final isFirstHalf   = selection['isFirstHalf'] as bool? ?? true;
            final durationMins  = isHalfSlot ? 30 : 60;
            final finalDuration = (slot.duration == 90) ? 90 : durationMins;
            final bookingTime   = isHalfSlot
                ? getHalfSlotTime(slot.time ?? '', isFirstHalf)
                : slot.time ?? '';

            slotData.add({
              "slotId": slotId,
              "businessHours": selectedBusinessHour,
              "slotTimes": [
                {
                  "time": bookingTime,
                  "amount": selection['amount'] as int? ?? slot.amount ?? 0,
                }
              ],
              "courtId": cId,
              "courtName": cName,
              "bookingDate": dateString,
              "duration": finalDuration,
              "totalTime": finalDuration,
              "bookingTime": bookingTime,
            });
          }
        }
      }

      if (slotData.isNotEmpty) {
        final clubLocationId =
        specificCourtData.registerClub?.locations?.isNotEmpty == true
            ? specificCourtData.registerClub!.locations![0].id
            : "";

        final mainHomeController = Get.find<MainHomeController>();
        final profileLocationId  = mainHomeController.profileController
            .profileModel.value?.response?.city?.sId ??
            "68c94a94d72a6f9769712ff0";

        payloadList.add({
          "slot": slotData,
          "register_club_id": clubId,
          "ownerId": specificCourtData.registerClub?.ownerId ?? "",
          "matchType": matchType.value,
          "bookingMode": "mobile",
          "categoryId": categoryId.value,
          "location": clubLocationId,
          "stateId": profileLocationId,
        });
      }
    }

    return payloadList.isEmpty ? null : payloadList;
  }
}