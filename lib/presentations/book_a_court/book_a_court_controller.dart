import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:get/get.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/app_colors.dart';
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

  ///Available Slots Collapse/Expand------------------------------------------------------------
  RxBool isSlotsCollapsed = false.obs;
  RxnString selectedSearchSlotId = RxnString();
  RxBool showMainGrid = true.obs; // New variable to control main grid visibility

  void toggleSlotsCollapse() {
    isSlotsCollapsed.value = !isSlotsCollapsed.value;
    showMainGrid.value = !showMainGrid.value; // Toggle main grid visibility

    // Don't reset available courts - keep them visible
    // User can modify selections and re-fetch if needed
  }
  final is30Slots = false.obs;

  // Sync selectedDuration with is30Slots toggle
  void updateDurationFromToggle() {
    selectedDuration.value = is30Slots.value ? '30 min' : '60 min';
  }

  void fetchClubs() {
    if (multiDateSelections.isEmpty) {
      showNoSelectionDialog();
      return;
    }

    showMainGrid.value = false; // Hide main grid
    isSlotsCollapsed.value = false; // Reset collapse state
    fetchCourtsIfReady(); // Hit the API
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
              // Icon
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

              // Title
              Text(
                "No Selection",
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                "Please select at least one slot to continue.",
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 24),

              // Action
              SizedBox(
                width: Get.width*0.5,
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

  // Track if slot history API was called
  RxBool hasCalledSlotHistoryAPI = false.obs;

  // Fetch locations from SignUpRepository
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

  // Update user profile location
  RxBool isUpdatingLocation = false.obs;
  Future<bool> updateUserLocation(String cityId) async {
    try {
      isUpdatingLocation.value = true;
      final mainHomeController = Get.find<MainHomeController>();
      final profile = mainHomeController.profileController.profileModel.value?.response;
      
      if (profile == null) return false;

      final profileRepo = ProfileRepository();
      await profileRepo.updateUserProfile(
        // name: profile.name ?? '',
        // email: profile.email,
        // gender: profile.gender ?? '',
        // dob: profile.dob ?? '',
        city: cityId,
        location: profile.location?.toJson() ?? {},
      );



      await mainHomeController.profileController.fetchUserProfile();
      final newLocationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
      locationId.value = newLocationId;
      final categoryId = mainHomeController.selectedCategoryId.value;
      await Future.wait([
        mainHomeController.homeController.fetchBookings(categoryId: categoryId, locationId: newLocationId),
        mainHomeController.homeController.fetchClubs(isRefresh: true, categoryId: categoryId, locationId: newLocationId),
        mainHomeController.fetchOpenMatches(),
        mainHomeController.fetchNearCityPlayers(),
        fetchCourtsByDuration()
      ]);

      CustomLogger.logMessage(msg: 'Location updated successfully', level: LogLevel.info);
      return true;
    } catch (e) {
      log('Error updating location: $e');
      CustomLogger.logMessage(msg: 'Failed to update location', level: LogLevel.error);
      return false;
    } finally {
      isUpdatingLocation.value = false;
    }
  }
  RxString selectedCityId = ''.obs;

  // Get selected location name for display
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

  // Get city name by city ID - first try profile model, then locations data
  String getCityNameById(String? cityId) {
    if (cityId == null || cityId.isEmpty) {
      return '';
    }

    // First try to get from profile model
    try {
      final mainHomeController = Get.find<MainHomeController>();
      final profileCity = mainHomeController.profileController.profileModel.value?.response?.city;
      if (profileCity?.sId == cityId && profileCity?.name != null) {
        return profileCity!.name!;
      }
    } catch (e) {
      log('getCityNameById: MainHomeController not found: $e');
    }

    // Fallback to locations data
    if (locationsData.value?.data != null) {
      final location = locationsData.value!.data!.firstWhereOrNull(
            (loc) => loc.id == cityId,
      );
      if (location?.name != null) {
        return location!.name!;
      }
    }

    return '';
  }

  // Get location name from club data
  String getLocationNameFromClub(GetCourtsByDurationData? clubData) {
    if (clubData?.registerClub?.locations == null || clubData!.registerClub!.locations!.isEmpty) {
      return '';
    }

    final location = clubData.registerClub!.locations!.first;
    return location.city ?? location.address ?? '';
  }


  @override
  void onInit()async {
    super.onInit();
    selectedDate.value = _getInitialDate();
    updateDurationFromToggle(); // Initialize duration based on is30Slots
    _initializeMockData();
    await fetchLocations();

    // Get categoryId and locationId from MainHomeController
    try {
      final mainHomeController = Get.find<MainHomeController>();
      categoryId.value = mainHomeController.selectedCategoryId.value;
      locationId.value = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
      // Set selectedCityId to show location name in UI
      selectedCityId.value = locationId.value;
    } catch (e) {
      log('MainHomeController not found: $e');
    }

    // Fetch wallet balance when controller initializes
    try {
      final walletController = Get.find<WalletController>();
      walletController.fetchWallet();
    } catch (e) {
      // WalletController not found, ignore
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
      _originalSlotsCache[court.sId ?? ''] = List<Slots>.from(court.slots ?? []);
    }
  }

  @override
  void onClose() {
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
            ? getHalfSlotTime(slot.time ?? '', isFirstHalf)
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
      log('Bulk delete slot history on back: $slots');
      await _homeRepository.deleteSlotHistory(data: {"slots": slots});
    } catch (e) {
      log('Error in bulk delete on back: $e');
    }
  }



  void onNext() {
    log("Slots -> $selectedSlots");

    if (multiDateSelections.isEmpty) {
      CustomLogger.logMessage(msg: "Please select at least one slot to continue.", level: LogLevel.debug);
      return;
    }
    CustomLogger.logMessage(msg: "Selected ${multiDateSelections.length} slots for ₹${totalAmount.value}", level: LogLevel.debug);
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
        CustomLogger.logMessage(msg: lockedSlots.first.message ??"Selected slots are currently locked. Please try again.", level: LogLevel.debug);
      }

      return false;
    } catch (e) {
      log('Error in createAndGetSlotHistory: $e');
      return false;
    }
  }


  // API method for deleting slot history (batch)
  Future<void> deleteSlotHistory({required Map<String, dynamic> slots}) async {
    try {
      log('deleteSlotHistory called with body: $slots');
      await _homeRepository.deleteSlotHistory(data: slots);
    } catch (e) {
      log('Error in deleteSlotHistory: $e');
    }
  }

  void toggleCourtRowSlotSelection(Slots slot, {String? courtId, String? courtName, bool? isHalfSlot, bool? isFirstHalf, List<Slots>? availableSlots}) {
    final slotId = slot.sId ?? '';
    final resolvedCourtId = courtId ?? '';
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    // Filter selections for this specific court and date only
    final allDateSelections = realCourtSelections.entries
        .where((entry) => entry.value['date'] == dateString && entry.value['courtId'] == resolvedCourtId)
        .toList();

    if (isHalfSlot == true && clubSupports30MinSlots(resolvedCourtId)) {
      final halfSlotSuffix = isFirstHalf == true ? '_first_half' : '_second_half';
      final realCourtKey = '${dateString}_${resolvedCourtId}_$slotId$halfSlotSuffix';
      final fullSlotKey = '${dateString}_${resolvedCourtId}_$slotId';
      final otherHalfKey = isFirstHalf == true 
          ? '${dateString}_${resolvedCourtId}_${slotId}_second_half'
          : '${dateString}_${resolvedCourtId}_${slotId}_first_half';

      // Check if clicking on already selected half - unselect and cascade
      if (realCourtSelections.containsKey(realCourtKey)) {
        _removeSlotAndCascade(slot, resolvedCourtId, dateString, isFirstHalf ?? true, availableSlots);
        recalculateRealCourtTotalAmount();
        realCourtSelections.refresh();
        return;
      }
      
      // Check if full slot is selected - convert to other half only
      if (realCourtSelections.containsKey(fullSlotKey)) {
        realCourtSelections.remove(fullSlotKey);
        final halfSlot = Slots(
          sId: slotId,
          time: slot.time,
          amount: (slot.amount ?? 0) ~/ 2,
        );
        realCourtSelections[otherHalfKey] = {
          'slot': halfSlot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': (slot.amount ?? 0) ~/ 2,
          'isHalfSlot': true,
          'isFirstHalf': !isFirstHalf!,
        };
        recalculateRealCourtTotalAmount();
        realCourtSelections.refresh();
        return;
      }
      
      // Check if other half is already selected - combine to full slot
      if (realCourtSelections.containsKey(otherHalfKey)) {
        realCourtSelections.remove(otherHalfKey);
        realCourtSelections[fullSlotKey] = {
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

      // First selection must be full slot
      if (allDateSelections.isEmpty) {
        realCourtSelections[fullSlotKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      } else {
        // For half slots, check if consecutive to existing range
        final timeRange = _getGlobalTimeRange(dateString, resolvedCourtId);
        final clickedTime = _getSlotStartTime(slot, isFirstHalf ?? true);
        
        if (!_isConsecutiveToRange(clickedTime, timeRange, isFirstHalf ?? true)) {
          // Not consecutive - select full slot instead
          realCourtSelections[fullSlotKey] = {
            'slot': slot,
            'courtId': resolvedCourtId,
            'courtName': courtName ?? '',
            'date': dateString,
            'dateTime': currentDate,
            'amount': slot.amount ?? 0,
          };
        } else {
          // Consecutive - select half slot
          final halfSlot = Slots(
            sId: slotId,
            time: slot.time,
            amount: (slot.amount ?? 0) ~/ 2,
          );

          realCourtSelections[realCourtKey] = {
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
      }
    } else {
      final realCourtKey = '${dateString}_${resolvedCourtId}_$slotId';

      // Check if clicking on already selected slot - unselect and cascade
      if (realCourtSelections.containsKey(realCourtKey)) {
        _removeSlotAndCascade(slot, resolvedCourtId, dateString, true, availableSlots);
        recalculateRealCourtTotalAmount();
        realCourtSelections.refresh();
        return;
      }

      // Full slots can be selected freely (no sequence check)
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

    recalculateRealCourtTotalAmount();
    realCourtSelections.refresh();
  }
  void toggleSlotSelection(Slots slot, {String? courtId, String? courtName, bool? isHalfSlot, bool? isFirstHalf}) {

    final slotId = slot.sId ?? '';
    final resolvedCourtId = courtId ?? '';
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

    // Only set selected time slot, don't fetch courts yet
    selectedTimeSlot.value = slot.time ?? '';

    // Handle half slot selection for 30 minutes
    if (is30Slots.value && isHalfSlot == true) {
      // Check if the half slot is in the past
      if (isPastHalfSlot(slot, isFirstHalf ?? true)) {
        return;
      }
      final firstHalfKey = '${dateString}_${resolvedCourtId}_${slotId}_first_half';
      final secondHalfKey = '${dateString}_${resolvedCourtId}_${slotId}_second_half';
      final fullSlotKey = '${dateString}_${resolvedCourtId}_$slotId';
      final clickedHalfKey = isFirstHalf == true ? firstHalfKey : secondHalfKey;

      // Check if the clicked half is already selected - if so, unselect it
      if (multiDateSelections.containsKey(clickedHalfKey)) {
        multiDateSelections.remove(clickedHalfKey);
      }
      // Check if we're selecting the second half and first half is already selected
      else if (isFirstHalf == false && multiDateSelections.containsKey(firstHalfKey)) {
        // Both halves will be selected - convert to full slot
        multiDateSelections.remove(firstHalfKey);
        multiDateSelections[fullSlotKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      }
      // Check if we're selecting the first half and second half is already selected
      else if (isFirstHalf == true && multiDateSelections.containsKey(secondHalfKey)) {
        // Both halves will be selected - convert to full slot
        multiDateSelections.remove(secondHalfKey);
        multiDateSelections[fullSlotKey] = {
          'slot': slot,
          'courtId': resolvedCourtId,
          'courtName': courtName ?? '',
          'date': dateString,
          'dateTime': currentDate,
          'amount': slot.amount ?? 0,
        };
      }
      // Check if full slot is already selected (both halves were previously selected)
      else if (multiDateSelections.containsKey(fullSlotKey)) {
        // Remove full slot and add the half that was clicked
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
      }
      // Normal half slot selection (only one half)
      else {
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
      // Handle full slot selection for 60 minutes
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
    if (rawTime == null || rawTime.trim().isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final selected = selectedDate.value ?? now;

    // Only check if it's today
    final isToday = selected.year == now.year &&
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

      // For half slots, add 30 minutes if it's the second half
      if (!isFirstHalf) {
        minute += 30;
        if (minute >= 60) {
          hour += 1;
          minute -= 60;
        }
      }

      final slotDateTime = DateTime(
        selected.year,
        selected.month,
        selected.day,
        hour,
        minute,
      );

      return now.isAfter(slotDateTime);
    } catch (_) {
      return false;
    }
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

    // Check for full slot selection
    final multiDateKey = '${dateString}_${courtId}_${slot.sId}';
    if (multiDateSelections.containsKey(multiDateKey)) {
      return true;
    }

    // Check for half-slot selections if 30 minutes is selected
    if (is30Slots.value) {
      final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
      final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';
      return multiDateSelections.containsKey(firstHalfKey) || multiDateSelections.containsKey(secondHalfKey);
    }

    return false;
  }

  // Check if both halves are selected for a main grid slot
  bool isBothHalvesSelectedInMainGrid(Slots slot, String courtId) {
    if (!is30Slots.value) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';

    // Check if full slot exists (both halves consolidated) OR both halves exist separately
    return multiDateSelections.containsKey(fullSlotKey) ||
        (multiDateSelections.containsKey(firstHalfKey) && multiDateSelections.containsKey(secondHalfKey));
  }

  // Check if left half is selected for a main grid slot
  bool isLeftHalfSelectedInMainGrid(Slots slot, String courtId) {
    if (!is30Slots.value) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';

    // Full slot means both halves are selected, so left half is selected
    return multiDateSelections.containsKey(fullSlotKey) || multiDateSelections.containsKey(firstHalfKey);
  }

  // Check if right half is selected for a main grid slot
  bool isRightHalfSelectedInMainGrid(Slots slot, String courtId) {
    if (!is30Slots.value) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey = '${dateString}_${courtId}_${slot.sId}';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';

    // Full slot means both halves are selected, so right half is selected
    return multiDateSelections.containsKey(fullSlotKey) || multiDateSelections.containsKey(secondHalfKey);
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
    final fullSlotKey = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';

    // Check if full slot is selected OR both halves are selected
    return realCourtSelections.containsKey(fullSlotKey) ||
        (realCourtSelections.containsKey(firstHalfKey) && realCourtSelections.containsKey(secondHalfKey));
  }

  // Check if left half is selected for a court slot
  bool isLeftHalfSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey = '${dateString}_${courtId}_${slot.sId}';
    final firstHalfKey = '${dateString}_${courtId}_${slot.sId}_first_half';

    // Full slot means both halves are selected, so left half is selected
    return realCourtSelections.containsKey(fullSlotKey) || realCourtSelections.containsKey(firstHalfKey);
  }

  // Check if right half is selected for a court slot
  bool isRightHalfSelectedInCourt(Slots slot, String courtId) {
    if (!clubSupports30MinSlots(courtId)) return false;

    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final fullSlotKey = '${dateString}_${courtId}_${slot.sId}';
    final secondHalfKey = '${dateString}_${courtId}_${slot.sId}_second_half';

    // Full slot means both halves are selected, so right half is selected
    return realCourtSelections.containsKey(fullSlotKey) || realCourtSelections.containsKey(secondHalfKey);
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

  void clearAllSelections() {
    multiDateSelections.clear();
    realCourtSelections.clear();
    selectedSlots.clear();
    totalAmount.value = 0;
    courtsByDuration.value = null;
    selectedTimeSlot.value = '';
    selectedSearchSlotId.value = null;
    isSlotsCollapsed.value = false;
  }

  void clearAvailableCourtsOnly() {
    realCourtSelections.clear();
    courtsByDuration.value = null;
    recalculateRealCourtTotalAmount();
  }

  // Fetch courts by duration when all required data is available
  void fetchCourtsIfReady() {
    if (selectedDate.value != null && selectedDuration.value.isNotEmpty && selectedTimeSlot.value.isNotEmpty) {
      fetchCourtsByDuration();
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

  // Cascade remove non-consecutive half slots after removing a slot
  void _cascadeRemoveNonConsecutive(String removedSlotId, String courtId, String dateString, List<Slots>? availableSlots) {
    if (availableSlots == null) return;
    
    final removedSlotIndex = availableSlots.indexWhere((s) => s.sId == removedSlotId);
    if (removedSlotIndex == -1) return;

    // Get all selections for this court and date
    final courtSelections = realCourtSelections.entries
        .where((entry) => 
            entry.value['courtId'] == courtId && 
            entry.value['date'] == dateString)
        .toList();

    // Check slots after the removed slot
    for (int i = removedSlotIndex + 1; i < availableSlots.length; i++) {
      final slotId = availableSlots[i].sId ?? '';
      final fullKey = '${dateString}_${courtId}_$slotId';
      final firstHalfKey = '${dateString}_${courtId}_${slotId}_first_half';
      final secondHalfKey = '${dateString}_${courtId}_${slotId}_second_half';

      // If full slot exists, stop cascade (it's consecutive)
      if (realCourtSelections.containsKey(fullKey)) {
        break;
      }

      // If any half slot exists, remove it (it's now non-consecutive)
      if (realCourtSelections.containsKey(firstHalfKey)) {
        realCourtSelections.remove(firstHalfKey);
      }
      if (realCourtSelections.containsKey(secondHalfKey)) {
        realCourtSelections.remove(secondHalfKey);
      }

      // If no selection for this slot, stop cascade
      if (!realCourtSelections.containsKey(firstHalfKey) && 
          !realCourtSelections.containsKey(secondHalfKey) &&
          !realCourtSelections.containsKey(fullKey)) {
        break;
      }
    }
  }

  // Validate if the new half slot selection is consecutive
  bool _isConsecutiveCourtSlotSelection(String slotId, String courtId, String dateString, bool isFirstHalf, List<Slots>? availableSlots) {
    // Get all current selections for this court and date
    final courtSelections = realCourtSelections.entries
        .where((entry) => 
            entry.value['courtId'] == courtId && 
            entry.value['date'] == dateString)
        .toList();

    // If no selections yet, allow first selection
    if (courtSelections.isEmpty) {
      return true;
    }

    // Find the slot index in available slots
    if (availableSlots == null) return false;
    final currentSlotIndex = availableSlots.indexWhere((s) => s.sId == slotId);
    if (currentSlotIndex == -1) return false;

    // Check if any existing selection is consecutive
    for (var entry in courtSelections) {
      final selection = entry.value;
      final existingSlot = selection['slot'] as Slots;
      final existingSlotId = existingSlot.sId ?? '';
      final existingIsHalfSlot = selection['isHalfSlot'] as bool? ?? false;
      final existingIsFirstHalf = selection['isFirstHalf'] as bool? ?? true;
      
      final existingSlotIndex = availableSlots.indexWhere((s) => s.sId == existingSlotId);
      if (existingSlotIndex == -1) continue;

      // Case 1: Existing is a full slot
      if (!existingIsHalfSlot) {
        // Check if current slot is immediately after (next slot, first half)
        if (currentSlotIndex == existingSlotIndex + 1 && isFirstHalf) {
          return true; // e.g., 7pm full + 8pm first half = 7pm-8:30pm
        }
        // Check if current slot is immediately before (prev slot, second half)
        if (currentSlotIndex == existingSlotIndex - 1 && !isFirstHalf) {
          return true; // e.g., 6pm second half + 7pm full = 6:30pm-8pm
        }
      }
      // Case 2: Existing is a half slot
      else {
        // Same slot, different half
        if (currentSlotIndex == existingSlotIndex) {
          return true; // Completing the full slot
        }
        // Next slot after existing second half
        if (currentSlotIndex == existingSlotIndex + 1 && !existingIsFirstHalf && isFirstHalf) {
          return true; // e.g., 7pm second half + 8pm first half
        }
        // Previous slot before existing first half
        if (currentSlotIndex == existingSlotIndex - 1 && existingIsFirstHalf && !isFirstHalf) {
          return true; // e.g., 6pm second half + 7pm first half
        }
      }
    }

    return false;
  }

  // Check if a slot time is already selected in another court for the same date
  bool isSlotTimeSelectedInOtherCourt(Slots slot, String currentCourtId, {bool? checkingFirstHalf}) {
    final currentDate = selectedDate.value ?? DateTime.now();
    final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
    final slotId = slot.sId ?? '';

    // Check all selections for the same date but different court
    return realCourtSelections.entries.any((entry) {
      final selection = entry.value;
      final selectionCourtId = selection['courtId'] as String;
      final selectionDate = selection['date'] as String;
      final selectionSlot = selection['slot'] as Slots;
      final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
      final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
      
      if (selectionDate != dateString || selectionCourtId == currentCourtId || selectionSlot.sId != slotId) {
        return false;
      }

      // If checking a specific half
      if (checkingFirstHalf != null) {
        // If other court has full slot, this half is blocked
        if (!isHalfSlot) return true;
        // If other court has the same half, it's blocked
        if (isHalfSlot && isFirstHalf == checkingFirstHalf) return true;
        // Different half is OK
        return false;
      }

      // If checking full slot, block if other court has any selection (full or half)
      return true;
    });
  }

  // Get global time range (earliest start to latest end) across all selections
  // Get global time range (earliest start to latest end) for a specific court
  Map<String, DateTime?> _getGlobalTimeRange(String dateString, String courtId) {
    DateTime? earliest;
    DateTime? latest;

    for (var entry in realCourtSelections.entries) {
      final selection = entry.value;
      if (selection['date'] != dateString) continue;
      if (selection['courtId'] != courtId) continue; // Only check same court

      final slot = selection['slot'] as Slots;
      final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
      final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;

      final startTime = _getSlotStartTime(slot, isFirstHalf);
      final endTime = _getSlotEndTime(slot, isHalfSlot, isFirstHalf);

      if (startTime != null) {
        if (earliest == null || startTime.isBefore(earliest)) earliest = startTime;
      }
      if (endTime != null) {
        if (latest == null || endTime.isAfter(latest)) latest = endTime;
      }
    }

    return {'start': earliest, 'end': latest};
  }

  // Check if clicked time is consecutive to existing range
  bool _isConsecutiveToRange(DateTime? clickedTime, Map<String, DateTime?> range, bool isFirstHalf) {
    if (clickedTime == null) return false;
    
    final start = range['start'];
    final end = range['end'];
    
    if (start == null || end == null) return true;

    // Check if clicked time extends the range (before start or after end)
    final clickedEnd = clickedTime.add(Duration(minutes: isFirstHalf ? 60 : 30));
    
    return clickedTime == end || clickedEnd == start;
  }

  // Get slot start time as DateTime
  DateTime? _getSlotStartTime(Slots slot, bool isFirstHalf) {
    final time = slot.time;
    if (time == null) return null;

    try {
      final hour = parseHour24(time);
      if (hour == null) return null;

      final currentDate = selectedDate.value ?? DateTime.now();
      final minute = isFirstHalf ? 0 : 30;
      
      return DateTime(currentDate.year, currentDate.month, currentDate.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // Get slot end time as DateTime
  DateTime? _getSlotEndTime(Slots slot, bool isHalfSlot, bool isFirstHalf) {
    final startTime = _getSlotStartTime(slot, isFirstHalf);
    if (startTime == null) return null;

    final duration = isHalfSlot ? 30 : 60;
    return startTime.add(Duration(minutes: duration));
  }

  // Remove slot and cascade remove everything after it
  void _removeSlotAndCascade(Slots slot, String courtId, String dateString, bool isFirstHalf, List<Slots>? availableSlots) {
    final slotId = slot.sId ?? '';
    final clickedTime = _getSlotStartTime(slot, isFirstHalf);
    if (clickedTime == null) return;

    // Remove all selections that start at or after the clicked time FOR THIS SPECIFIC COURT
    final keysToRemove = <String>[];
    
    for (var entry in realCourtSelections.entries) {
      final selection = entry.value;
      if (selection['date'] != dateString) continue;
      if (selection['courtId'] != courtId) continue; // Only remove from same court

      final selectionSlot = selection['slot'] as Slots;
      final selectionIsHalfSlot = selection['isHalfSlot'] as bool? ?? false;
      final selectionIsFirstHalf = selection['isFirstHalf'] as bool? ?? true;
      
      final selectionStartTime = _getSlotStartTime(selectionSlot, selectionIsFirstHalf);
      
      if (selectionStartTime != null && !selectionStartTime.isBefore(clickedTime)) {
        keysToRemove.add(entry.key);
      }
    }

    for (var key in keysToRemove) {
      realCourtSelections.remove(key);
    }
  }

  // Get half slot time - for left half return original time, for right half add 30 minutes
  String getHalfSlotTime(String originalTime, bool isFirstHalf) {
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

            return '$newHour:${newMinute.toString().padLeft(2, '0')} ${period.toLowerCase()}';
          }
        }
      } catch (e) {
        log('Error calculating half slot time: $e');
      }

      // Fallback: return original time with :30 added
      return originalTime.replaceFirst(':', ':30').replaceFirst(' ', ':30 ');
    }
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

      // Get duration from is30Slots: 30 for 30m, 60 for 60m
      final durationValue = is30Slots.value ? '30' : '60';

      // Get categoryId from MainHomeController
      final mainHomeController = Get.find<MainHomeController>();
      final categoryId = mainHomeController.selectedCategoryId.value.isNotEmpty
          ? mainHomeController.selectedCategoryId.value
          : null;

      // Get locationId from selectedCityId
      // final locationId = selectedCityId.value.isNotEmpty ? selectedCityId.value : null;

      final response = await _homeRepository.getCourtsByDuration(
        duration: durationValue,
        date: dateString,
        time: formattedTime,
        categoryId: categoryId,
        locationId: locationId.value,
      );

      courtsByDuration.value = response;

      log('Courts by duration fetched: ${response.data?.length} clubs');
    } catch (e) {
      log('Error fetching courts by duration: $e');
    } finally {
      isLoadingCourtsByDuration.value = false;
    }
  }

  // Check if left half of a slot is booked based on API response
  bool isLeftHalfBooked(Slots slot, String courtId) {
    if (courtsByDuration.value?.data == null) return false;

    for (var clubData in courtsByDuration.value!.data!) {
      if (clubData.courts != null) {
        for (var court in clubData.courts!) {
          if (court.id == courtId && court.slots != null) {
            for (var apiSlot in court.slots!) {
              // Check if this is a 30-minute booking for the left half
              if (apiSlot.duration == 30 && apiSlot.bookingTime != null) {
                final leftHalfTime = getHalfSlotTime(slot.time ?? '', true);
                final apiBookingTime = apiSlot.bookingTime!.toLowerCase().trim();
                final leftHalfTimeLower = leftHalfTime.toLowerCase().trim();

                if (apiBookingTime == leftHalfTimeLower) {
                  return true;
                }
              }
            }
          }
        }
      }
    }
    return false;
  }

  // Check if right half of a slot is booked based on API response
  bool isRightHalfBooked(Slots slot, String courtId) {
    if (courtsByDuration.value?.data == null) return false;

    for (var clubData in courtsByDuration.value!.data!) {
      if (clubData.courts != null) {
        for (var court in clubData.courts!) {
          if (court.id == courtId && court.slots != null) {
            for (var apiSlot in court.slots!) {
              // Check if this is a 30-minute booking for the right half
              if (apiSlot.duration == 30 && apiSlot.bookingTime != null) {
                final rightHalfTime = getHalfSlotTime(slot.time ?? '', false);
                final apiBookingTime = apiSlot.bookingTime!.toLowerCase().trim();
                final rightHalfTimeLower = rightHalfTime.toLowerCase().trim();

                if (apiBookingTime == rightHalfTimeLower) {
                  return true;
                }
              }
            }
          }
        }
      }
    }
    return false;
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

  // Process slot history for payment - call APIs for all selections
  Future<bool> processSlotHistoryForPayment() async {
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
            ? getHalfSlotTime(slot.time ?? '', isFirstHalf)
            : slot.time ?? '';
        final duration = isHalfSlot ? 30 : 60;

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

  // Build booking payload from realCourtSelections
  List<Map<String, dynamic>>? buildBookingPayload() {
    if (realCourtSelections.isEmpty || courtsByDuration.value == null) {
      return null;
    }

    final List<Map<String, dynamic>> payloadList = [];

    // Group selections by clubId
    final Map<String, List<Map<String, dynamic>>> selectionsByClub = {};

    for (var entry in realCourtSelections.entries) {
      final selection = entry.value;
      final courtId = selection['courtId'] as String;

      // Find the club for this court from courtsByDuration
      String? clubId;
      GetCourtsByDurationData? courtData;

      for (var clubData in courtsByDuration.value!.data ?? []) {
        if (clubData.courts != null) {
          for (var court in clubData.courts!) {
            if (court.id == courtId) {
              clubId = clubData.registerClub?.id;
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

    // Build payload for each club
    for (var clubEntry in selectionsByClub.entries) {
      final clubId = clubEntry.key;
      final clubSelections = clubEntry.value;

      // Find the specific court data for this club
      final specificCourtData = courtsByDuration.value!.data?.firstWhere(
            (c) => c.registerClub?.id == clubId,
        orElse: () => GetCourtsByDurationData(),
      );

      if (specificCourtData == null || specificCourtData.registerClub?.id == null) continue;

      // Get booking day
      final firstSelection = clubSelections.first;
      final dateTime = firstSelection['dateTime'] as DateTime;
      String bookingDay = "";
      switch (dateTime.weekday) {
        case 1:
          bookingDay = "Monday";
          break;
        case 2:
          bookingDay = "Tuesday";
          break;
        case 3:
          bookingDay = "Wednesday";
          break;
        case 4:
          bookingDay = "Thursday";
          break;
        case 5:
          bookingDay = "Friday";
          break;
        case 6:
          bookingDay = "Saturday";
          break;
        case 7:
          bookingDay = "Sunday";
          break;
      }

      // Get business hours for the day
      final selectedBusinessHour = specificCourtData.registerClub?.businessHours
          ?.where((bh) => bh.day == bookingDay)
          .map((bh) => {
        "time": bh.time ?? "",
        "day": bh.day ?? "",
      })
          .toList() ?? [];

      // Group selections by courtId + slotId + date to handle half slots correctly
      final Map<String, List<Map<String, dynamic>>> slotGroups = {};
      for (var selection in clubSelections) {
        final slot = selection['slot'] as Slots;
        final courtId = selection['courtId'] as String;
        final slotId = slot.sId ?? '';
        final dateString = selection['date'] as String;
        final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;

        // Create unique key: for half slots include half info, for full slots just basic info
        final groupKey = isHalfSlot
            ? '${dateString}_${courtId}_${slotId}_half'
            : '${dateString}_${courtId}_${slotId}_full';

        if (!slotGroups.containsKey(groupKey)) {
          slotGroups[groupKey] = [];
        }
        slotGroups[groupKey]!.add(selection);
      }

      // Build slot data
      final List<Map<String, dynamic>> slotData = [];

      for (var slotGroup in slotGroups.entries) {
        final selections = slotGroup.value;
        final isHalfSlotGroup = slotGroup.key.endsWith('_half');

        if (isHalfSlotGroup && selections.length == 2) {
          // Both halves selected - treat as one full slot
          final firstSelection = selections.first;
          final slot = firstSelection['slot'] as Slots;
          final courtId = firstSelection['courtId'] as String;
          final courtName = firstSelection['courtName'] as String;
          final dateTime = firstSelection['dateTime'] as DateTime;
          final dateString = DateFormat('yyyy-MM-dd').format(dateTime);
          final slotId = slot.sId ?? '';

          // Calculate full slot amount
          final fullAmount = selections.fold<int>(0, (sum, sel) => sum + (sel['amount'] as int? ?? 0));

          slotData.add({
            "slotId": slotId,
            "businessHours": selectedBusinessHour,
            "slotTimes": [
              {
                "time": slot.time ?? "",
                "amount": fullAmount,
              }
            ],
            "courtId": courtId,
            "courtName": courtName,
            "bookingDate": dateString,
            "duration": 60,
            "totalTime": 60,
            "bookingTime": slot.time ?? "",
          });
        } else {
          // Single selection (either full slot or single half)
          for (var selection in selections) {
            final slot = selection['slot'] as Slots;
            final courtId = selection['courtId'] as String;
            final courtName = selection['courtName'] as String;
            final dateTime = selection['dateTime'] as DateTime;
            final dateString = DateFormat('yyyy-MM-dd').format(dateTime);
            final slotId = slot.sId ?? '';

            final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
            final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
            final durationMinutes = isHalfSlot ? 30 : 60;
            final totalTimeMinutes = isHalfSlot ? 30 : 60;

            final bookingTime = isHalfSlot
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
              "courtId": courtId,
              "courtName": courtName,
              "bookingDate": dateString,
              "duration": durationMinutes,
              "totalTime": totalTimeMinutes,
              "bookingTime": bookingTime,
            });
          }
        }
      }

      if (slotData.isNotEmpty) {
        final clubLocationId = specificCourtData.registerClub?.locations?.isNotEmpty == true
            ? specificCourtData.registerClub!.locations![0].id
            : "";

        final mainHomeController = Get.find<MainHomeController>();
        final profileLocationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

        final bookingPayload = {
          "slot": slotData,
          "register_club_id": clubId,
          "ownerId": specificCourtData.registerClub?.ownerId ?? "",
          "matchType":matchType.value,
          "bookingMode": "mobile",
          "categoryId": categoryId.value,
          "location": clubLocationId,
          "stateId":profileLocationId

        };

        log('Booking payload ownerId: ${specificCourtData.registerClub?.ownerId}');

        payloadList.add(bookingPayload);
      }
    }

    return payloadList.isEmpty ? null : payloadList;
  }

}