import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/court_slots_shimmer.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/upword_arrow_animation.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import '../../../../handler/text_formatter.dart';
import 'create_open_matches_controller.dart';

class CreateOpenMatchesScreen extends StatelessWidget {
  CreateOpenMatchesScreen({super.key});
  final CreateOpenMatchesController controller = Get.put(CreateOpenMatchesController());
  
  // Map to track expanded state for each court
  final RxMap<String, bool> courtExpandedStates = <String, bool>{}.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _bottomButton(context),
      backgroundColor: AppColors.whiteColor,
     appBar: primaryAppBar(title: Text("Create Open Match"),centerTitle: true, context: context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatePicker(),
                Transform.translate(
                    offset: Offset(0, -Get.height * 0.05),
                    child: fadeDivider()),
                Transform.translate(
                  offset: Offset(0, -Get.height * 0.03),
                  child: _buildTimeOfDayTabs(),
                ),
                /// Slots Section Header
                Transform.translate(
                  offset: Offset(0, -Get.height * .01),
                  child: Text("All Slots", style: Get.textTheme.labelLarge).paddingOnly(left: 5),
                ),
                Transform.translate(
                  offset: Offset(0, -Get.height * 0.01),
                  child: _buildAllCourtsWithSlots(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationSection() {
    return Obx(() {
      // Check if any slot has 30-minute pricing available
      final hasAny30MinSlots = controller.hasAny30MinSlots();
      final durations = hasAny30MinSlots 
          ? ['30 min', '60 min'] 
          : ['60 min'];

      return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Obx(
            () => Row(
          children: durations.map((e) {
            final isSelected = controller.selectedDuration.value == e;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.select(e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                      colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                        : null,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.05 : 1,
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
    });
  }

  /// 📅 Date Picker - Fixed spacing and toggle functionality
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Date",
          style: Get.textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).paddingOnly(top: 10),

        Obx(() => Transform.translate(
          offset: const Offset(0, -30),

          child: Row(
            children: [
              /// Month container (vertical text)
              Transform.translate(
                offset: const Offset(0, 0),
                child: Container(
                  width: 25,
                  height: 55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Color(0xffF3F3F5),
                    border: Border.all(
                      color: AppColors.blackColor.withAlpha(10),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: DateFormat('MMM')
                        .format(controller.focusedMonth.value)
                        .toUpperCase()
                        .split('')
                        .map(
                          (char) => Text(
                        char,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ).paddingOnly(right: 5),
              ),

              /// Date timeline with scroll listener
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollUpdateNotification) {
                      final scrollOffset = scrollNotification.metrics.pixels;
                      final itemExtent = 46.0;
                      final itemsScrolled = (scrollOffset / itemExtent).round();
                      final estimatedDate = DateTime.now().add(Duration(days: itemsScrolled));

                      // Update focusedMonth based on scroll position
                      final newMonth = DateTime(estimatedDate.year, estimatedDate.month, 1);
                      if (controller.focusedMonth.value.month != newMonth.month ||
                          controller.focusedMonth.value.year != newMonth.year) {
                        controller.focusedMonth.value = newMonth;
                      }
                    }
                    return false;
                  },
                  child: EasyDateTimeLinePicker.itemBuilder(
                    headerOptions: HeaderOptions(
                      headerBuilder: (_, context, date) =>
                      const SizedBox.shrink(),
                    ),
                    selectionMode: SelectionMode.alwaysFirst(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030, 3, 18),
                    focusedDate: controller.selectedDate.value,
                    itemExtent: 46,
                    itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final currentDate = DateTime(date.year, date.month, date.day);
                      if (currentDate.isBefore(today)) return const SizedBox.shrink();

                      final dayName = DateFormat('E').format(date);
                      final dateString =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                      return GestureDetector(
                        onTap: () {
                          onTap();
                          // Update both selectedDate and focusedMonth here
                          controller.selectedDate.value = date;
                          controller.focusedMonth.value =
                              DateTime(date.year, date.month, 1);
                        },
                        child: Obx(() {
                          final dateSelections =
                              controller.getSelectionsByDate()[dateString] ?? [];

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 55,
                                  width: Get.width * 0.11,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    gradient: isSelected ? LinearGradient(
                                      colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ) : null,
                                    color: isSelected ? null : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : dateSelections.isNotEmpty
                                          ? AppColors.primaryColor
                                          : AppColors.blackColor.withAlpha(20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${date.day}",
                                        style: Get.textTheme.titleMedium!.copyWith(
                                          fontSize: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : dateSelections.isNotEmpty
                                              ? AppColors.primaryColor
                                              : AppColors.textColor,
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -2),
                                        child: Text(
                                          dayName,
                                          style: Get.textTheme.bodySmall!.copyWith(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : dateSelections.isNotEmpty
                                                ? AppColors.primaryColor
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (dateSelections.isNotEmpty)
                                  Positioned(
                                    top: -3,
                                    right: -2,
                                    child: Container(
                                      height: 16,
                                      width: 16,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.secondaryColor,
                                      ),
                                      child: Text(
                                        "${dateSelections.length}",
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      );
                    },

                    onDateChange: (date) async {
                      controller.selectedDate.value = date;
                      controller.focusedMonth.value =
                          DateTime(date.year, date.month, 1);
                      controller.isLoadingCourts.value = true;
                      await controller.fetchAllSlotPrices();
                      await controller.getAvailableCourtsById(
                        controller.argument.id!,
                        showUnavailable: true, // Always show both available and unavailable
                      );
                      controller.slots.refresh();
                      controller.isLoadingCourts.value = false;
                    },
                  ),
                ),
              ),
            ],
          ).paddingOnly(top: 10),
        )),
      ],
    );
  }

  /// Time of Day Filter Tabs (Morning /Noon/ Night)
  Widget _buildTimeOfDayTabs() {
    return Obx(() {
      final selectedTab = controller.selectedTimeOfDay.value;
      final tabs = [
        {"label": "Morning", "icon": Icons.wb_twilight_sharp, "value": 0},
        {"label": "Noon", "icon": Icons.wb_sunny, "value": 1},
        {"label": "Evening", "icon": Icons.nightlight_round, "value": 2},
      ];

      return Theme(
        data: Theme.of(Get.context!).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
              ),
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final value = tab["value"] as int;
                  final isSelected = selectedTab == value;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        controller.isManualTabSelection.value = true;
                        controller.selectedTimeOfDay.value = value;
                        controller.filterSlotsByTimeOfDay();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            )
                          ]
                              : [],
                        ),
                        child: Center(
                          child: Icon(
                            tab["icon"] as IconData,
                            size: 20,
                            color: isSelected
                                ? AppColors.primaryColor
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final value = tab["value"] as int;
                final isSelected = selectedTab == value;

                return Expanded(
                  child: Center(
                    child: Text(
                      tab["label"] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  /// Build all courts with their slots
  Widget _buildAllCourtsWithSlots() {
    return Obx(() {
      if (controller.isLoadingCourts.value) {
        return CourtSlotsShimmer();
      }

      final slotsData = controller.slots.value;

      if (slotsData == null || slotsData.data == null || slotsData.data!.isEmpty) {
        return const Center(child: Text("No courts available"));
      }

      final courts = slotsData.data!;

      return GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe left (negative velocity) = next tab
          if (details.primaryVelocity! < -300) {
            // Move to next tab
            int nextTab = (controller.selectedTimeOfDay.value + 1) % 3;
            controller.selectedTimeOfDay.value = nextTab;
            controller.filterSlotsByTimeOfDay();
          }
          // Swipe right (positive velocity) = previous tab
          else if (details.primaryVelocity! > 300) {
            // Move to previous tab
            int prevTab = (controller.selectedTimeOfDay.value - 1) % 3;
            if (prevTab < 0) prevTab = 2; // Wrap around to Night
            controller.selectedTimeOfDay.value = prevTab;
            controller.filterSlotsByTimeOfDay();
          }
        },
        child: Column(
          children: [
            // Show all courts in a list
            ...courts.asMap().entries.map((entry) {
              final index = entry.key;
              final court = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCourtSection(court, index),
              );
            }),

            const SizedBox(height: 26),
          ],
        ),
      );
    });
  }

  Widget _buildCourtSection(dynamic courtData, int index) {
    final courtName = courtData.courtName ?? 'Unknown Court';
    final slotTimes = courtData.slots ?? [];
    final courtId = courtData.sId ?? '';

    final courtTypes = courtData.registerClubId?.courtType;

    final featureText = (courtTypes is List && index < courtTypes.length)
        ? courtTypes[index].toString()
        : 'Standard court';

    log("Building court section for: $courtName with ${slotTimes.length} slots");

    // Initialize expanded state based on court count and index
    if (!courtExpandedStates.containsKey(courtId)) {
      final totalCourts = controller.slots.value?.data?.length ?? 0;
      // If multiple courts, collapse all except first one (index 0)
      // If single court, keep it expanded
      courtExpandedStates[courtId] = totalCourts > 1 ? index == 0 : true;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Court Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            courtName,
                            style: Get.textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ).paddingOnly(right: 5),
                          Text(
                            "[$featureText]",
                            overflow: TextOverflow.ellipsis,
                            style: Get.textTheme.bodySmall!.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(() => GestureDetector(
                      onTap: () {
                        courtExpandedStates[courtId] = !courtExpandedStates[courtId]!;
                      },
                      child: AnimatedRotation(
                        turns: courtExpandedStates[courtId]! ? 0.0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: AppColors.whiteColor,
                            size: 24,
                          ),
                        ),
                      ),
                    )),
                  ],
                ).paddingOnly(bottom: courtExpandedStates[courtId]! ?0:10),
              ],
            ),
          ),

          // Animated Slots Grid
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: courtExpandedStates[courtId]! ? null : 0,
            child: courtExpandedStates[courtId]!
                ? Padding(
                    padding: slotTimes.isNotEmpty
                        ? const EdgeInsets.all(12)
                        : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: _buildSlotsGrid(slotTimes, courtId),
                  )
                : const SizedBox.shrink(),
          )),
        ],
      ),
    );
  }

  /// Build slots grid for a specific court
  Widget _buildSlotsGrid(List<dynamic> slotTimes, String courtId) {
    final filteredSlots = slotTimes;

    if (filteredSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 28,
                color: Colors.grey,
              ),
              const SizedBox(height: 6),
              Text(
                "No slots available",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Try selecting a different date",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: filteredSlots.length,
      itemBuilder: (context, index) {
        final slot = filteredSlots[index];
        return Obx(() => _buildSlotTile(slot, courtId, context));
      },
    );
  }

  /// Build individual slot tile
  Widget _buildSlotTile(dynamic slot, String courtId, BuildContext context) {
    final isSelected = controller.isSlotSelected(slot, courtId);
    final isPartOfGroup = controller.isPartOfSelectedGroup(slot, courtId);
    final selectedDuration = controller.selectedDuration.value;
    final supports30Min = controller.slotSupports30Min(slot);
    final isHalfSlot = supports30Min;

    final isUnavailable = controller.isPastAndUnavailable(slot) ||
        (slot.status?.toLowerCase() == 'booked') ||
        (slot.availabilityStatus?.toLowerCase() == 'maintenance') ||
        (slot.availabilityStatus?.toLowerCase() == 'weather conditions') ||
        (slot.availabilityStatus?.toLowerCase() == 'staff unavailability');

    // Check for booked slots (for all durations)
    final isLeftHalfBooked = controller.isLeftHalfBooked(slot);
    final isRightHalfBooked = controller.isRightHalfBooked(slot);
    final isBothHalvesBooked = isLeftHalfBooked && isRightHalfBooked;
    final isAnyHalfBooked = isLeftHalfBooked || isRightHalfBooked;

    // For slots that don't support 30min, if any half is booked, the whole slot is unavailable
    final isSlotBookedForFullSlot = !supports30Min && isAnyHalfBooked;

    const blueColor = Color(0xff053CFF);
    const radius = 5.0;
    final price = slot.amount ?? 0;



    return Builder(
      builder: (BuildContext slotContext) {
        return GestureDetector(
          onTapDown: (isUnavailable || isBothHalvesBooked || isSlotBookedForFullSlot)
              ? null
              : (details) {
            if (supports30Min) {
              // For slots that support 30-min pricing, detect left/right half tap
              final RenderBox box = slotContext.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final isLeftHalf = localPosition.dx < box.size.width / 2;

              // Check if the tapped half is already booked
              if ((isLeftHalf && isLeftHalfBooked) || (!isLeftHalf && isRightHalfBooked)) {
                // Get.snackbar(
                //   "Slot Unavailable",
                //   "This ${isLeftHalf ? 'left' : 'right'} half is already booked.",
                //   backgroundColor: Colors.redAccent,
                //   colorText: Colors.white,
                //   snackPosition: SnackPosition.TOP,
                //   duration: const Duration(seconds: 2),
                // );
                return;
              }

              controller.toggleSlotSelection(
                slot,
                courtId: courtId,
                courtName: '',
                isLeftHalf: isLeftHalf,
              );
            } else {
              // For slots that don't support 30-min pricing or when selecting full slots
              if (isAnyHalfBooked) {
                // Get.snackbar(
                //   "Slot Unavailable",
                //   "This slot is already booked.",
                //   backgroundColor: Colors.redAccent,
                //   colorText: Colors.white,
                //   snackPosition: SnackPosition.TOP,
                //   duration: const Duration(seconds: 2),
                // );
                return;
              }

              controller.toggleSlotSelection(
                slot,
                courtId: courtId,
                courtName: '',
              );
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: (isUnavailable || isBothHalvesBooked || isSlotBookedForFullSlot) ? Colors.grey.shade100 : Colors.white,
                border: Border.all(
                  color: (isUnavailable || isBothHalvesBooked || isSlotBookedForFullSlot)
                      ? Colors.grey.shade300
                      : (isSelected || isPartOfGroup)
                      ? Colors.transparent
                      : Colors.grey.shade300,
                  width: (isSelected || isPartOfGroup) ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  /// FULL GRADIENT FOR BOTH HALVES SELECTED (30MIN with 30min support)
                  if (supports30Min && controller.isBothHalvesSelected(slot, courtId))
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: const LinearGradient(
                            colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                  /// FULL GRADIENT FOR FULL SLOT SELECTIONS
                  if ((isSelected || isPartOfGroup) && !supports30Min)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: const LinearGradient(
                            colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),



                  /// LEFT HALF GRADIENT FOR 30MIN LEFT SELECTION (ONLY WHEN RIGHT NOT SELECTED)
                  if (supports30Min && _isLeftHalfSelected(slot, courtId) && !controller.isBothHalvesSelected(slot, courtId))
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 40, // Half width of the slot tile
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(radius),
                            bottomLeft: Radius.circular(radius),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                  /// RIGHT HALF GRADIENT FOR 30MIN RIGHT SELECTION (ONLY WHEN LEFT NOT SELECTED)
                  if (supports30Min && _isRightHalfSelected(slot, courtId) && !controller.isBothHalvesSelected(slot, courtId))
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 40, // Half width of the slot tile
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(radius),
                            bottomRight: Radius.circular(radius),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                  /// FULL BOOKED OVERLAY FOR 30MIN WHEN BOTH HALVES ARE BOOKED
                  if (supports30Min && isHalfSlot && isBothHalvesBooked && !isSelected && !isPartOfGroup)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: Colors.grey.shade300.withOpacity(0.8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.block,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),

                  /// FULL BOOKED OVERLAY FOR FULL SLOT SELECTIONS
                  if ((!supports30Min || !isHalfSlot) && isAnyHalfBooked && !isSelected && !isPartOfGroup)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: Colors.grey.shade300.withOpacity(0.8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.block,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),

                  /// LEFT HALF BOOKED OVERLAY (30MIN ONLY - WHEN ONLY LEFT IS BOOKED)
                  if (supports30Min && isHalfSlot && isLeftHalfBooked && !isRightHalfBooked && !_isLeftHalfSelected(slot, courtId))
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 40, // Half width of the slot tile
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(radius),
                            bottomLeft: Radius.circular(radius),
                          ),
                          color: Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.block,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),

                  /// RIGHT HALF BOOKED OVERLAY (30MIN ONLY - WHEN ONLY RIGHT IS BOOKED)
                  if (supports30Min && isHalfSlot && isRightHalfBooked && !isLeftHalfBooked && !_isRightHalfSelected(slot, courtId))
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 40, // Half width of the slot tile
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(radius),
                            bottomRight: Radius.circular(radius),
                          ),
                          color: Colors.grey.shade300,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.block,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),

                  /// VERTICAL DIVIDER FOR 30MIN SLOTS THAT SUPPORT IT
                  if (supports30Min && !isUnavailable && !isBothHalvesBooked && !isSlotBookedForFullSlot)
                    Positioned(
                      left: 40, // Center of the 80px wide slot tile
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: AppColors.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),

                  /// LEFT BLUE STRIP (ONLY WHEN AVAILABLE AND NOT SELECTED)
                  if (!isUnavailable && !isSelected && !isPartOfGroup)
                    Positioned.fill(
                      left: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: blueColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(radius),
                              bottomLeft: Radius.circular(radius),
                            ),
                          ),
                        ),
                      ),
                    ),

                  /// SLOT CONTENT
                  
                  /// TIME AND PRICE - WHITE TEXT FOR FULL SLOT SELECTIONS (NON-30MIN SLOTS)
                  if (!supports30Min && (isSelected || isPartOfGroup))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.time ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (price > 0)
                            Text(
                              "₹$price",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),

                  /// TIME AND PRICE - WHITE TEXT FOR BOTH HALVES SELECTED
                  if (supports30Min && controller.isBothHalvesSelected(slot, courtId))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.time ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          if (price > 0)
                            Text(
                              "₹$price",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),

                  /// TIME AND PRICE - GRADIENT TEXT FOR LEFT HALF SELECTION
                  if (supports30Min && _isLeftHalfSelected(slot, courtId) && !controller.isBothHalvesSelected(slot, courtId))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [Colors.white, Colors.white, Colors.black87, Colors.black87],
                                stops: [0.0, 0.5, 0.5, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              slot.time ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (price > 0)
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [Colors.white70, Colors.white70, Colors.black54, Colors.black54],
                                  stops: [0.0, 0.5, 0.5, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                "₹$price",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  /// TIME AND PRICE - GRADIENT TEXT FOR RIGHT HALF SELECTION
                  if (supports30Min && _isRightHalfSelected(slot, courtId) && !controller.isBothHalvesSelected(slot, courtId))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [Colors.black87, Colors.black87, Colors.white, Colors.white],
                                stops: [0.0, 0.5, 0.5, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              slot.time ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (price > 0)
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [Colors.black54, Colors.black54, Colors.white70, Colors.white70],
                                  stops: [0.0, 0.5, 0.5, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                "₹$price",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),



                  /// TIME AND PRICE - NORMAL FOR UNSELECTED SLOTS
                  if ((!supports30Min && !isSelected && !isPartOfGroup) ||
                      (supports30Min && !_isLeftHalfSelected(slot, courtId) && !_isRightHalfSelected(slot, courtId) && !controller.isBothHalvesSelected(slot, courtId)))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.time ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isUnavailable
                                  ? Colors.grey.shade500
                                  : (isSelected || isPartOfGroup)
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          if (price > 0)
                            Text(
                              "₹$price",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isUnavailable
                                    ? Colors.grey.shade400
                                    : (isSelected || isPartOfGroup)
                                    ? Colors.white70
                                    : AppColors.primaryColor,
                              ),
                            ),
                        ],
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

  Widget _bottomButton(BuildContext context) {
    return Obx(() {
      final totalSelections = controller.getTotalSelectionsCount();
      final hasSelections = totalSelections > 0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: CustomButton(
          width: Get.width * 0.9,
          child: Text(
            "Next",
            style: Get.textTheme.headlineMedium!.copyWith(
              color: AppColors.whiteColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ).paddingOnly(right: 40),
          onTap: () async {
            if (!hasSelections) {
              // SnackBarUtils.showInfoSnackBar("Please select at least one slot to continue.");
              return;
            }
            
            // Call API to process slot history
            final success = await controller.processSlotHistoryForPayment();
            if (!success) {
              return;
            }
            
            controller.onNext();
          },
        ),
      );
    });
  }
  
  bool _isPartOfSelectedGroup(dynamic slot, String courtId) {
    final currentDate = controller.selectedDate.value ?? DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
    final supports30Min = controller.slotSupports30Min(slot);
    
    if (supports30Min) {
      // For slots that support 30min pricing, only return true if BOTH halves are selected
      final leftKey = '${dateString}_${courtId}_${slot.sId}_L';
      final rightKey = '${dateString}_${courtId}_${slot.sId}_R';
      return controller.multiDateSelections.containsKey(leftKey) && controller.multiDateSelections.containsKey(rightKey);
    } else {
      final multiDateKey = '${dateString}_${courtId}_${slot.sId}';
      return controller.multiDateSelections.containsKey(multiDateKey);
    }
  }
  
  /// Check if left half of a slot is selected (only for slots that support 30-minute pricing)
  bool _isLeftHalfSelected(dynamic slot, String courtId) {
    if (!controller.slotSupports30Min(slot)) return false;
    
    final currentDate = controller.selectedDate.value ?? DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
    final leftKey = '${dateString}_${courtId}_${slot.sId}_L';
    return controller.multiDateSelections.containsKey(leftKey);
  }
  
  /// Check if right half of a slot is selected (only for slots that support 30-minute pricing)
  bool _isRightHalfSelected(dynamic slot, String courtId) {
    if (!controller.slotSupports30Min(slot)) return false;
    
    final currentDate = controller.selectedDate.value ?? DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
    final rightKey = '${dateString}_${courtId}_${slot.sId}_R';
    return controller.multiDateSelections.containsKey(rightKey);
  }
}