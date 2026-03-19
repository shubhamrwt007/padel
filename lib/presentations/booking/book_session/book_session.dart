import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/court_slots_shimmer.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/upword_arrow_animation.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/services/socket_service.dart';
import '../../../handler/text_formatter.dart';
import 'book_session_controller.dart';

class BookSession extends StatefulWidget {
  const BookSession({super.key});

  @override
  State<BookSession> createState() => _BookSessionState();
}

class _BookSessionState extends State<BookSession> with AutomaticKeepAliveClientMixin {
  final BookSessionController controller = Get.put(BookSessionController());
  final RxMap<String, bool> courtExpandedStates = <String, bool>{}.obs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Ensure socket is connected when book session screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final socketService = SocketService.instance;
        log('BookSession: Checking socket connection status');
        socketService.testConnection();
        
        if (!socketService.isConnected) {
          log('BookSession: Socket not connected, attempting to connect');
          socketService.connect();
        } else {
          log('BookSession: Socket already connected');
        }
      } catch (e) {
        log('Socket connection error in book session: $e');
      }
    });
  }

  @override
  void dispose() {
    try {
      final socketService = SocketService.instance;
      final clubId = controller.argument.id;
      final selectedDate = controller.selectedDate.value;
      final dateString = "${selectedDate?.year}-${selectedDate?.month.toString().padLeft(2, '0')}-${selectedDate?.day.toString().padLeft(2, '0')}";
      
      if (clubId != null) {
        socketService.unsubscribeFromSlotWiseUpdates(
          clubId: clubId,
          date: dateString,
        );
        log('BookSession: Unsubscribed from slot updates for club: $clubId, date: $dateString');
      }
    } catch (e) {
      log('Error unsubscribing from slot updates: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Stack(  // Change from Scaffold to Stack
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // bottom padding for button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatePicker(context),
              fadeDivider().paddingOnly(bottom: 15),
              _buildTimeOfDayTabs(),
              /// Slots Section Header
              Text("All Slots", style: Get.textTheme.labelLarge).paddingOnly(left: 5,top: 10),
              _buildAllCourtsWithSlots(),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _bottomButton(context),
        ),
      ],
    );
  }
  /// 📅 Date Picker - Fixed spacing and toggle functionality
  Widget _buildDatePicker(BuildContext context) {
    return Container(
      height: 120,
      width: Get.width,
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Obx(() => Transform.translate(
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
                        controller: controller.dateTimelineController,
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
                          
                          // Hide current date if time is 11 PM or later
                          if (now.hour >= 23 && currentDate.isAtSameMomentAs(today)) {
                            return const SizedBox.shrink();
                          }
                          
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
                                        // color: isSelected
                                        //     ? Colors.black
                                        //     : dateSelections.isNotEmpty
                                        //     ? AppColors.primaryColor
                                        //     .withValues(alpha: 0.1)
                                        //     : AppColors.playerCardBackgroundColor,
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
                          
                          // Re-subscribe to slot updates for new date
                          controller.resubscribeToSlotUpdates();
                          
                          await controller.fetchAllSlotPrices();
                          await controller.getAvailableCourtsById(
                            controller.locationID.value,
                            controller.categoryId.value,
                            controller.sId.value,
                            controller.argument.id!,
                            showUnavailable: true,
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
          ),
          Row(
            children: [
              Text(
                "Select Date",
                style: Get.textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.openDatePicker(context);
                },
                child: Container(
                  height: 25,
                  width: 25,
                  decoration: BoxDecoration(
                    color: AppColors.textFieldColor,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ).paddingOnly(left: 10)
            ],
          ).paddingOnly(top: 10),

        ],
      ),
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
                            border: isSelected ?Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)): Border.all(color: Colors.transparent),

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

      // Filter courts that have at least one non-past slot
      final courts = slotsData.data!.where((court) {
        final slotTimes = court.slots ?? [];
        return slotTimes.any((slot) => !controller.isPastAndUnavailable(slot));
      }).toList();

      // If no courts have available slots, show "No slots available" message
      if (courts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  "No slots available",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "All slots have passed for this time period",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }

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
                      child: Text(
                        courtName,
                        style: Get.textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ).paddingOnly(right: 5),
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
    // Filter out past time slots
    final filteredSlots = slotTimes.where((slot) => !controller.isPastAndUnavailable(slot)).toList();

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
        return Obx(() => _buildSlotTile(slot, courtId,context));
      },
    );
  }
  /// Build individual slot tile
  Widget _buildSlotTile(dynamic slot, String courtId, BuildContext context) {
    final isSelected = controller.isSlotSelected(slot, courtId);
    final isPartOfGroup = _isPartOfSelectedGroup(slot, courtId);
    final selectedDuration = controller.selectedDuration.value;
    final supports30Min = controller.slotSupports30Min(slot);
    final isHalfSlot = supports30Min;

    final isUnavailable = controller.isPastAndUnavailable(slot) ||
        (slot.availabilityStatus?.toLowerCase() == 'maintenance') ||
        (slot.availabilityStatus?.toLowerCase() == 'weather conditions') ||
        (slot.availabilityStatus?.toLowerCase() == 'staff unavailability')||
        (slot.availabilityStatus?.toLowerCase() == 'tournament');

    // Check for booked slots
    final isLeftHalfBooked = controller.isLeftHalfBooked(slot);
    final isRightHalfBooked = controller.isRightHalfBooked(slot);
    final isBothHalvesBooked = isLeftHalfBooked && isRightHalfBooked;
    final isAnyHalfBooked = isLeftHalfBooked || isRightHalfBooked;
    
    // Debug logs - ALWAYS print for debugging
    log('UI DEBUG - Slot: ${slot.time}, bookingTime: ${slot.bookingTime}, duration: ${slot.duration}, status: ${slot.status}');
    log('UI DEBUG - supports30Min: $supports30Min, has30MinPrice: ${slot.has30MinPrice}');
    log('UI DEBUG - isLeftHalfBooked: $isLeftHalfBooked, isRightHalfBooked: $isRightHalfBooked');

    // For slots that don't support 30min, if any half is booked, the whole slot is unavailable
    final isSlotBookedForFullSlot = !supports30Min && isAnyHalfBooked;

    const blueColor = Color(0xff053CFF);
    const radius = 5.0;
    final price = slot.amount ?? 0;

    return Builder(
      builder: (BuildContext slotContext) {
        return GestureDetector(
          onTapDown: (details) {
            // Prevent selection if slot is unavailable or booked
            if (isUnavailable || isBothHalvesBooked || isSlotBookedForFullSlot) {
              return;
            }

            if (supports30Min) {
              // For slots that support 30-min pricing, detect left/right half tap
              final RenderBox box = slotContext.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final isLeftHalf = localPosition.dx < box.size.width / 2;

              // Prevent selection if the tapped half is already booked
              if ((isLeftHalf && isLeftHalfBooked) || (!isLeftHalf && isRightHalfBooked)) {
                return;
              }

              controller.toggleSlotSelection(
                slot,
                courtId: courtId,
                courtName: '',
                isLeftHalf: isLeftHalf,
              );
            } else {
              // For full slots, prevent selection if any part is booked
              if (isAnyHalfBooked) {
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
                color: (isUnavailable || (isBothHalvesBooked && supports30Min) || isSlotBookedForFullSlot) 
                    ? Colors.grey.shade100
                    : Colors.white,
                border: Border.all(
                  color: (isUnavailable || isAnyHalfBooked)
                      ? Colors.transparent
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
                          color: AppColors.lightred
                        ),
                      ),
                    ),

                  /// FULL BOOKED OVERLAY FOR FULL SLOT SELECTIONS (NON-30MIN SLOTS ONLY)
                  if (!supports30Min && isAnyHalfBooked && !isSelected && !isPartOfGroup)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: AppColors.lightred,
                        ),
                      ),
                    ),

                  /// UNAVAILABLE OVERLAY (MAINTENANCE, WEATHER, STAFF UNAVAILABILITY)
                  if (isUnavailable && !isAnyHalfBooked && !isSelected && !isPartOfGroup)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: AppColors.lightred,
                        ),
                      ),
                    ),

                  /// LEFT HALF BOOKED OVERLAY (30MIN ONLY - WHEN ONLY LEFT IS BOOKED)
                  if (isHalfSlot && isLeftHalfBooked && !isRightHalfBooked && !_isLeftHalfSelected(slot, courtId))
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(radius),
                            bottomLeft: Radius.circular(radius),
                          ),
                          color: AppColors.lightred,
                        ),
                        // child: Center(
                        //   child: Icon(
                        //     Icons.block,
                        //     size: 16,
                        //     color: Colors.red.shade600,
                        //   ),
                        // ),
                      ),
                    ),

                  /// RIGHT HALF BOOKED OVERLAY (30MIN ONLY - WHEN ONLY RIGHT IS BOOKED)
                  if (isHalfSlot && isRightHalfBooked && !isLeftHalfBooked && !_isRightHalfSelected(slot, courtId))
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(radius),
                            bottomRight: Radius.circular(radius),
                          ),
                          color: AppColors.lightred,
                        ),
                        // child: Center(
                        //   child: Icon(
                        //     Icons.block,
                        //     size: 16,
                        //     color: Colors.red.shade600,
                        //   ),
                        // ),
                      ),
                    ),

                  /// VERTICAL DIVIDER FOR 30MIN SLOTS THAT SUPPORT IT
                  if (supports30Min && !isUnavailable && !isBothHalvesBooked)
                    Positioned(
                      left: 40, // Center of the 80px wide slot tile
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),

                  /// LEFT STRIP (BLUE FOR AVAILABLE, RED FOR BOOKED/UNAVAILABLE)
                  if (!isSelected && !isPartOfGroup)
                    Positioned.fill(
                      left: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: (isAnyHalfBooked || isUnavailable) ? Colors.red : blueColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(radius),
                              bottomLeft: Radius.circular(radius),
                            ),
                          ),
                        ),
                      ),
                    ),

                  /// TIME AND PRICE - WHITE TEXT FOR FULL SLOT SELECTIONS (NON-30MIN SLOTS)
                  if (!supports30Min && (isSelected || isPartOfGroup))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatTimeSlot(slot.time ?? ""),
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
                            formatTimeSlot(slot.time ?? ""),
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
                              formatTimeSlot(slot.time ?? ""),
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
                              formatTimeSlot(slot.time ?? ""),
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
                            formatTimeSlot(slot.time ?? ""),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: (isUnavailable || isAnyHalfBooked)
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
                                color: (isUnavailable || isAnyHalfBooked)
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


  /// Bottom bar with total & book button
  Widget _bottomButton(BuildContext context) {
    return Obx(() {
      final hasSelections = controller.multiDateSelections.isNotEmpty;
      final totalSelections = controller.getTotalSelectionsCount();

      final double collapsedHeight = Get.height * .11;
      final double expandedHeight = Get.height * .13;
      void openSelectedSlotsBottomSheet(BuildContext context) {
        if (controller.multiDateSelections.isEmpty) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Obx(() {
                        final selectionsByDate = controller.getSelectionsByDate();
                        final totalSelections = controller.getTotalSelectionsCount();

                        if (totalSelections == 0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            }
                          });
                          return const SizedBox.shrink();
                        }

                        final totalAmount = controller.totalAmount.value;
                        final entries = selectionsByDate.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));
                        
                        // Consolidate 30-minute slots for display
                        final consolidatedEntries = <String, List<Map<String, dynamic>>>{};
                        final selectedDurationMinutes = int.tryParse(controller.selectedDuration.value.replaceAll(' min', '')) ?? 60;
                        
                        for (final entry in entries) {
                          final dateKey = entry.key;
                          final selections = entry.value;
                          final consolidatedSelections = <Map<String, dynamic>>[];
                          final processedSlots = <String>{};
                          
                          if (selectedDurationMinutes == 30) {
                            // Group 30-minute half-slots
                            for (final selection in selections) {
                              final slotId = selection['slot'].sId ?? '';
                              if (processedSlots.contains(slotId)) continue;
                              
                              // Find both halves of this slot by checking if bookingTime equals original time or is 30 minutes later
                              final originalTime = selection['slot'].time ?? '';
                              final leftHalf = selections.where((s) => 
                                s['slot'].sId == slotId && s['bookingTime'] == originalTime).firstOrNull;
                              final rightHalf = selections.where((s) => 
                                s['slot'].sId == slotId && s['bookingTime'] != originalTime).firstOrNull;
                              
                              if (leftHalf != null && rightHalf != null) {
                                // Both halves selected - show as one full slot with 60-minute price
                                // Get the 60-minute price for this slot from the original slot data
                                final originalSlot = leftHalf['slot'];
                                final fullSlotPrice = originalSlot.amount ?? 0; // This should be the 60-minute price
                                consolidatedSelections.add({
                                  ...leftHalf,
                                  'bookingTime': originalTime, // Use original time for full slot
                                  'adjustedAmount': fullSlotPrice, // Use original slot amount (60-minute price)
                                  'isConsolidated': true,
                                });
                              } else if (leftHalf != null) {
                                // Only left half selected
                                consolidatedSelections.add(leftHalf);
                              } else if (rightHalf != null) {
                                // Only right half selected
                                consolidatedSelections.add(rightHalf);
                              }
                              
                              processedSlots.add(slotId);
                            }
                          } else {
                            // For non-30min durations, use selections as-is
                            consolidatedSelections.addAll(selections);
                          }
                          
                          consolidatedEntries[dateKey] = consolidatedSelections;
                        }

                        return SafeArea(
                          top: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 30),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Selected Slots Summary',
                                      style: Get.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,fontSize: 16
                                      ),
                                    ),
                                    // IconButton(
                                    //   splashRadius: 20,
                                    //   padding: EdgeInsets.zero,
                                    //   constraints: const BoxConstraints(),
                                    //   onPressed: () => Navigator.of(sheetContext).pop(),
                                    //   icon: const Icon(Icons.close_rounded, size: 22),
                                    // ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Summary',
                                            style: Get.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$totalSelections slot${totalSelections > 1 ? 's' : ''} selected',
                                            style: Get.textTheme.bodySmall?.copyWith(
                                              color: AppColors.darkGrey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        '₹ ${formatAmount(totalAmount)}',
                                        style: Get.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Text(
                                  'Date-wise Breakdown',
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.labelBlackColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: consolidatedEntries.length,
                                  itemBuilder: (context, index) {
                                    final entry = consolidatedEntries.entries.toList()[index];
                                    final date = DateTime.parse(entry.key);
                                    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
                                    final dayName = DateFormat('EEEE').format(date);
                                    final selections = entry.value;
                                    final selectionsByCourt = <String, List<Map<String, dynamic>>>{};

                                    for (final selection in selections) {
                                      final courtId = selection['courtId'] as String? ?? '';
                                      selectionsByCourt.putIfAbsent(courtId, () => []).add(selection);
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        /// ---- OUTSIDE ROW ---- ///
                                        Row(
                                          children: [
                                            Container(
                                              height: 32,
                                              width: 32,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.calendar_month,
                                                color: AppColors.primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                '$formattedDate ($dayName)',
                                                style: Get.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${selections.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),

                                        /// ---- CONTAINER BELOW ---- ///
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 14),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.shade200),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.04),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ...selectionsByCourt.entries.map((courtEntry) {
                                                final courtSelections = courtEntry.value;
                                                final courtName =
                                                (courtSelections.first['courtName'] ?? 'Court');

                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 0),
                                                  padding: const EdgeInsets.all(3),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.sports_tennis,
                                                              size: 14, color: AppColors.primaryColor),
                                                          const SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              courtName,
                                                              style: Get.textTheme.bodyMedium?.copyWith(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            courtSelections.length == 1
                                                                ? '1 slot'
                                                                : '${courtSelections.length} slots',
                                                            style: Get.textTheme.bodySmall?.copyWith(
                                                              color: AppColors.darkGrey,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: courtSelections.map((selection) {
                                                          // Use bookingTime for 30-minute slots, otherwise use original time
                                                          final bookingTime = selection['bookingTime'] as String? ?? selection['slot'].time;
                                                          final formattedTime = formatTimeSlot(bookingTime);

                                                          return Container(
                                                            width: 60,
                                                            alignment: Alignment.center,
                                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.blackColor,
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              formattedTime,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Positioned(
                        top: -10,
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () => Get.back(),
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,        // show only top part
                                    heightFactor: 0.6,
                                    child: Transform.translate(
                                      offset: Offset(0,4),
                                      child: Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withValues(alpha: 0.1),
                                              blurRadius: 1,
                                              spreadRadius: -2,
                                              offset: Offset(0, -5),
                                            ),
                                          ],
                                        ),
                                        child: Transform.translate(offset: Offset(0, -10),child: ArrowAnimation(isUpward: false,)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      }
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        height: hasSelections ? expandedHeight : collapsedHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: hasSelections
              ? (details) {
                  if ((details.primaryVelocity ?? 0) < -300) {
                    openSelectedSlotsBottomSheet(context);
                  }
                }
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSelections)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    GestureDetector(
                      onTap: ()=>openSelectedSlotsBottomSheet(context),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Text(
                              "$totalSelections slot${totalSelections > 1 ? 's' : ''} selected",
                              style: Get.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.blackColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "₹ ${formatAmount(controller.totalAmount.value)}",
                              style: Get.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ).paddingOnly(left: 18,right: 18,),
                      ),
                    ),
                    Positioned(
                      top: -20,
                      child: InkWell(
                        onTap: () => openSelectedSlotsBottomSheet(context),
                        customBorder: const CircleBorder(),
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,        // show only top part
                            heightFactor: 0.7,
                            child: Container(
                              height: 55,
                              width: 55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 1,
                                    spreadRadius: -2,
                                    offset: Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Transform.translate(offset: Offset(0, -5),child: ArrowAnimation(isUpward: true,)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              CustomButton(
                width: Get.width * 0.9,
                onTap: () {
                  if (controller.multiDateSelections.isEmpty) {
                    CustomLogger.logMessage(msg: "Please select at least one slot before booking.", level: LogLevel.error);
                    return;
                  }
                  controller.proceedToPayment();
                },
                child: controller.cartLoader.value
                    ? LoadingAnimationWidget.waveDots(
                        color: AppColors.whiteColor,
                        size: 45,
                      ).paddingOnly(right: 40)
                    : Text(
                        "Book Now",
                        style: Get.textTheme.headlineMedium!.copyWith(
                          color: AppColors.whiteColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
