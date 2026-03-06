import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/request_models/home_models/get_available_court.dart';
import 'package:padel_mobile/data/response_models/get_courts_by_duration_model.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/court_slots_shimmer.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/upword_arrow_animation.dart';
import 'package:padel_mobile/data/response_models/get_courts_by_duration_model.dart' as GetCourtsByDurationModel;
import 'package:padel_mobile/presentations/cart/cart_controller.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'create_open_match_for_all_courts_controller.dart';
class CreateOpenMatchForAllCourtsScreen extends StatelessWidget {
  final CreateOpenMatchForAllCourtsController controller = Get.put(CreateOpenMatchForAllCourtsController());
  final WalletController walletController = Get.put(WalletController());
  final RxBool isExpanded = false.obs;
  final RxBool isProcessing = false.obs;

  CreateOpenMatchForAllCourtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch wallet balance when screen builds
    walletController.fetchWallet();
    
    // Start periodic timer to check and remove expired slots
    _startSlotExpiryCheck();

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      bottomNavigationBar: _buildPaymentPanel(),
      appBar: primaryAppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Create a Game").paddingOnly(right: 5),
            
            Tooltip(
                textStyle: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                ),
                message: "You can choose your\nprefer date & slot",
                waitDuration: Duration(milliseconds: 200),
                showDuration: Duration(seconds: 3),
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline,size: 22,))
          ],
        ),
        centerTitle: true,
        context: context,
        action: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: ()=>Get.toNamed(RoutesName.wallet),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7,vertical: 3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.textFieldColor
                  // border: Border.all(
                  //   color: AppColors.primaryColor,
                  //   style: BorderStyle.solid, // dotted simulated below
                  //   width: 1.2,
                  // ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(Assets.imagesIcWallet,height: 20,width: 20,).paddingOnly(right: 4),
                    Obx(() => Text(
                      formatWalletAmount(walletController.walletBalance.value ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primaryColor,
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildDatePicker(context),
              fadeDivider().paddingOnly(bottom: 10),
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      controller.showMainGrid.value ? 'Prefer Slots' : 'Selected Slots',
                      style: Get.textTheme.labelLarge
                  ),
                  if (!controller.showMainGrid.value && controller.courtsByDuration.value != null)
                    GestureDetector(
                      onTap: () {
                        controller.showMainGrid.value = true;
                      },
                      child: Text(
                        '+ Add more slots',
                        style: Get.textTheme.labelMedium!.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (controller.showMainGrid.value)
                    Row(
                      children: [
                        Obx(() {
                          final is30 = controller.is30Slots.value;

                          return Transform.scale(
                            scale: 0.7,
                            child: ToggleButtons(
                              isSelected: [is30, !is30],
                              borderRadius: BorderRadius.circular(25),
                              constraints: const BoxConstraints(minHeight: 15, minWidth: 60),
                              fillColor: Colors.transparent, // important
                              selectedColor: Colors.white,
                              color: Colors.black,
                              textStyle: const TextStyle(fontSize: 12),
                              onPressed: (index) {
                                controller.is30Slots.value = index == 0;
                                controller.updateDurationFromToggle();
                                // Clear selections when duration changes
                                // controller.clearAllSelections();
                              },
                              children: [
                                _buildGradientToggleChild(
                                  text: "Half",
                                  isSelected: is30,
                                ),
                                _buildGradientToggleChild(
                                  text: "Full",
                                  isSelected: !is30,
                                ),
                              ],
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () {
                            controller.toggleSlotsCollapse();
                          },
                          child: AnimatedRotation(
                            turns: controller.isSlotsCollapsed.value ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                size: 22,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              )),
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: controller.showMainGrid.value
                    ? _buildAllCourtsWithSlots()
                    : _buildSelectedSlotsList().paddingOnly(top: 10),
              )),
              Align(
                alignment: AlignmentGeometry.centerRight,
                child: Obx(() => controller.showMainGrid.value
                    ? GestureDetector(
                  onTap: () => controller.fetchClubs(),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12,horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Text("Fetch Clubs",style: Get.textTheme.labelMedium!.copyWith(color: Colors.white,fontSize: 11),),
                  ),
                )
                    : SizedBox.shrink()),
              ).paddingOnly(bottom: 10,top: 10),
              Obx(() => !controller.showMainGrid.value
                  ? availableCourts(context)
                  : SizedBox.shrink()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

  }



  Widget availableCourts(BuildContext context) {
    return Obx(() {
      // Check if no slots are selected from main grid
      if (controller.multiDateSelections.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Courts', style: Get.textTheme.labelLarge),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Please select a time slot from above to see available courts.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      }

      // Show loading state
      if (controller.isLoadingCourtsByDuration.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Courts', style: Get.textTheme.labelLarge),
            const SizedBox(height: 100),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: LoadingWidget(color: AppColors.primaryColor,),
              ),
            ),
          ],
        );
      }

      final courtsByDuration = controller.courtsByDuration.value;

      // Show empty state if no data
      if (courtsByDuration == null ||
          courtsByDuration.data == null ||
          courtsByDuration.data!.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Courts', style: Get.textTheme.labelLarge),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No courts available for the selected time slot.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        );
      }

      final clubsData = courtsByDuration.data!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Courts', style: Get.textTheme.labelLarge),
          ...List.generate(clubsData.length, (clubIndex) {
            final clubData = clubsData[clubIndex];
            final isLastItem = clubIndex == clubsData.length - 1;

            return Column(
              children: [
                /// CLUB HEADER
                GestureDetector(
                  onTap: ()=>controller.toggle(clubIndex * 100),
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey.shade200,
                            child: clubData.registerClub?.logo != null && clubData.registerClub!.logo!.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: clubData.registerClub!.logo!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Icon(Icons.sports_tennis),
                              errorWidget: (context, url, error) => const Icon(Icons.sports_tennis),
                            )
                                : const Icon(Icons.sports_tennis),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clubData.clubName ?? 'Club',
                                style: Get.textTheme.headlineMedium!
                                    .copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Image.asset(Assets.imagesIcLocation,color: AppColors.textColor,scale: 2.2,),
                                  Text(
                                    clubData.registerClub?.locations?.isNotEmpty == true
                                        ? clubData.registerClub!.locations!.first.city ?? ''
                                        : '',
                                    style: Get.textTheme.labelMedium!
                                        .copyWith(fontWeight: FontWeight.w400),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text("UP  ",style: Get.textTheme.headlineLarge!.copyWith(color: Colors.grey,fontSize: 10),),
                            Transform.translate(
                                offset: Offset(0, -2),
                                child: Text("TO  ",style: Get.textTheme.headlineLarge!.copyWith(color: Colors.grey,fontSize: 10),)),
                          ],
                        ),
                        Text(
                          '₹ ${clubData.registerClub?.totalAmount ?? 0}',
                          style: Get.textTheme.titleLarge!.copyWith(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Obx(() {
                          final isExpanded = controller.expandedIndex.value == (clubIndex * 100);
                          return AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(Icons.keyboard_arrow_down),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (clubData.courts != null && clubData.courts!.isNotEmpty)
                  ...List.generate(clubData.courts!.length, (courtIndex) {
                    final court = clubData.courts![courtIndex];

                    return Obx(() {
                      final isExpanded = controller.expandedIndex.value == (clubIndex * 100);

                      return AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: isExpanded && court.slots != null && court.slots!.isNotEmpty
                            ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: _courtRow(
                            context: context,
                            courtName: court.courtName ?? 'Court ${courtIndex + 1}',
                            type: clubData.registerClub?.courtType?.join(', ') ?? '',
                            selectedIndex: courtIndex,
                            availableSlots: court.slots,
                            courtId: court.id ?? '',
                            slotDuration: court.slotDuration,
                          ),
                        )
                            : const SizedBox.shrink(),
                      );
                    });
                  }),
                if (!isLastItem) ...[
                  const SizedBox(height: 8),
                  fadeDivider(),
                ],
              ],
            );
          }),
        ],
      );
    });
  }

  Widget _courtRow({
    required BuildContext context,
    required String courtName,
    required String type,
    required int selectedIndex,
    List<CourtSlot>? availableSlots,
    String? courtId,
    List<int>? slotDuration,
  })
  {
    // Show all slots from API
    final displaySlots = availableSlots?.isNotEmpty == true
        ? availableSlots!.map((slot) => Slots(
      sId: slot.id ?? 'slot_${selectedIndex}_${slot.time}',
      time: slot.time ?? '',
      amount: slot.amount ?? 0,
      duration: slot.duration,
    )).toList()
        : <Slots>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT TEXT
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courtName,
                    style: Get.textTheme.headlineLarge!.copyWith(fontSize: 13,fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (slotDuration != null && slotDuration.isNotEmpty)
                    Text(
                      '(${slotDuration.first} min)',
                      style: Get.textTheme.labelSmall!.copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 15),

            /// TIME SLOTS - Show all slots in horizontal scroll
            if (displaySlots.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: displaySlots.map((slot) {
                      final index = displaySlots.indexOf(slot);
                      return SizedBox(
                        width: 88,
                        child: Obx(() => _buildCourtSlotTile(
                          context,
                          slot,
                          courtName,
                          selectedIndex,
                          index,
                          courtId: courtId ?? 'court$selectedIndex',
                          availableSlots: displaySlots,
                        )),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'No slots available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Date Picker - Fixed spacing and toggle functionality
  Widget _buildDatePicker(BuildContext context) {
    return Container(
      height: 110,
      width: Get.width,
      color: Colors.transparent,
      child: Stack(
        children: [
          /// Date picker wrapped separately with Obx
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: Obx(
                  () => Transform.translate(
                offset: Offset(0, -13),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: Offset(0, 0),
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
                        // Display month vertically (O C T) - now uses focusedMonth
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
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollUpdateNotification) {
                            final scrollOffset = scrollNotification.metrics.pixels;
                            final itemExtent = 46.0;
                            final itemsScrolled = (scrollOffset / itemExtent)
                                .round();
                            final estimatedDate = DateTime.now().add(
                              Duration(days: itemsScrolled),
                            );

                            // Update focusedMonth based on scroll position
                            final newMonth = DateTime(
                              estimatedDate.year,
                              estimatedDate.month,
                              1,
                            );
                            if (controller.focusedMonth.value.month !=
                                newMonth.month ||
                                controller.focusedMonth.value.year !=
                                    newMonth.year) {
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
                          itemExtent: 43,
                          itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final currentDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            if (currentDate.isBefore(today)) {
                              return const SizedBox.shrink();
                            }
                            final dayName = DateFormat('E').format(date);
                            final dateString =
                                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

                            return GestureDetector(
                              onTap: onTap,
                              child: Obx(() {
                                final realCourtSelections =
                                controller.realCourtSelections.entries
                                    .where((entry) => entry.value['date'] == dateString)
                                    .map((entry) => entry.value)
                                    .toList();
                                final totalSelections = realCourtSelections.length;

                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: SizedBox(
                                    height: 55,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          height: 55,
                                          width: Get.width * 0.11,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            gradient: isSelected
                                                ? LinearGradient(
                                              colors: [
                                                Color(0xff1F41BB),
                                                Color(0xff0E1E55),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            )
                                                : null,
                                            color: isSelected ? null : Colors.white,
                                            // color: isSelected
                                            //     ? Colors.black
                                            //     : dateSelections.isNotEmpty
                                            //     ? AppColors.primaryColor.withValues(alpha: 0.1)
                                            //     : AppColors.playerCardBackgroundColor,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.transparent
                                                  : totalSelections > 0
                                                  ? AppColors.primaryColor
                                                  : AppColors.blackColor.withAlpha(
                                                20,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${date.day}",
                                                style: Get.textTheme.titleMedium!
                                                    .copyWith(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : totalSelections > 0
                                                      ? AppColors.primaryColor
                                                      : AppColors.textColor,
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: Offset(0, -2),
                                                child: Text(
                                                  dayName,
                                                  style: Get.textTheme.bodySmall!
                                                      .copyWith(
                                                    fontSize: 11,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : totalSelections > 0
                                                        ? AppColors.primaryColor
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (totalSelections > 0)
                                          Positioned(
                                            top: -2,
                                            right: -6,
                                            child: Container(
                                              height: 16,
                                              width: 16,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppColors.secondaryColor
                                                    : AppColors.primaryColor,
                                              ),
                                              child: Text(
                                                "$totalSelections",
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
                                  ),
                                );
                              }),
                            );
                          },
                          onDateChange: (date) {
                            final wasShowingClubs = controller.courtsByDuration.value != null && !controller.showMainGrid.value;

                            controller.selectedDate.value = date;
                            controller.focusedMonth.value = DateTime(
                              date.year,
                              date.month,
                              1,
                            );
                            controller.clearAllSelections();
                            controller.isLoadingCourts.value = true;
                            controller.refreshSlots(
                              showUnavailable:
                              controller.showUnavailableSlots.value,
                            );
                            controller.slots.refresh();
                            // Show main grid when date changes
                            controller.showMainGrid.value = true;

                            // If clubs were showing before date change, refetch them after slots are refreshed
                            if (wasShowingClubs) {
                              Future.delayed(Duration(milliseconds: 600), () {
                                if (controller.multiDateSelections.isNotEmpty) {
                                  controller.fetchCourtsByDuration();
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          /// Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              ),
              GestureDetector(
                onTap: () => showChangeLocationBottomSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textFieldColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primaryColor,
                        size: 17,
                      ),
                      Obx(() => Text(
                        controller.getSelectedLocationName(),
                        style: Get.textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryColor,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildAllCourtsWithSlots() {
    return Obx(() {
      if (controller.isLoadingCourts.value) {
        return CourtSlotsShimmer();
      }

      final slotsData = controller.slots.value;

      if (slotsData == null ||
          slotsData.data == null ||
          slotsData.data!.isEmpty) {
        return const Center(child: Text("No slots available"));
      }

      final court = slotsData.data!.first;
      var slotTimes = court.slots ?? [];

      // Filter out past time slots if selected date is today
      final now = DateTime.now();
      final selectedDate = controller.selectedDate.value;
      final isToday = selectedDate?.year == now.year &&
          selectedDate?.month == now.month &&
          selectedDate?.day == now.day;

      if (isToday) {
        slotTimes = slotTimes.where((slot) {
          final slotTime = slot.time ?? '';
          final slotMinutes = _parseTimeToMinutes(slotTime);
          final currentMinutes = now.hour * 60 + now.minute;
          
          // Keep slot available until AFTER 15 minutes past start time
          // User can select at 5:15 for a 5:00 slot, removed at 5:16
          return currentMinutes < slotMinutes + 16;
        }).toList();
      }

      // Filter to show only the row containing selected slot when collapsed
      if (controller.isSlotsCollapsed.value && controller.selectedSearchSlotId.value != null) {
        final selectedSlotId = controller.selectedSearchSlotId.value!;
        final selectedIndex = slotTimes.indexWhere((slot) => slot.sId == selectedSlotId);

        if (selectedIndex != -1) {
          // Grid has 4 columns per row
          const columnsPerRow = 4;
          final rowIndex = selectedIndex ~/ columnsPerRow;
          final startIndex = rowIndex * columnsPerRow;
          final endIndex = (startIndex + columnsPerRow).clamp(0, slotTimes.length);

          // Get all slots in the same row
          slotTimes = slotTimes.sublist(startIndex, endIndex);
        }
      }

      return _buildSlotsGrid(slotTimes, court.sId ?? '');
    });
  }

  Widget _buildSelectedSlotsList() {
    return Obx(() {
      if (controller.multiDateSelections.isEmpty) {
        return const Center(
          child: Text(
            "No slots selected",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        );
      }

      // Group selections by slot ID to consolidate half slots
      final Map<String, List<Map<String, dynamic>>> slotGroups = {};

      controller.multiDateSelections.forEach((key, selection) {
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        final selectionCourtId = selection['courtId'] as String? ?? '';
        final selectionDate = selection['date'] as String? ?? '';

        // Create a unique key for grouping: date_courtId_slotId (without half suffix)
        // This groups all selections for the same slot together
        final groupKey = '${selectionDate}_${selectionCourtId}_$slotId';

        if (!slotGroups.containsKey(groupKey)) {
          slotGroups[groupKey] = [];
        }
        slotGroups[groupKey]!.add(selection);
      });

      // Consolidate slots: if both halves selected, show as one slot
      final consolidatedSlots = <Slots>[];
      slotGroups.forEach((key, selections) {
        final is30Min = controller.is30Slots.value;

        // Check if both halves are selected
        final hasFirstHalf = selections.any((s) =>
          s['isHalfSlot'] == true && s['isFirstHalf'] == true);
        final hasSecondHalf = selections.any((s) =>
          s['isHalfSlot'] == true && s['isFirstHalf'] == false);
        final hasBothHalves = is30Min && hasFirstHalf && hasSecondHalf;

        if (hasBothHalves) {
          // Both halves selected - show as one slot (use the slot from first half)
          final firstHalfSelection = selections.firstWhere((s) =>
            s['isHalfSlot'] == true && s['isFirstHalf'] == true);
          consolidatedSlots.add(firstHalfSelection['slot'] as Slots);
        } else {
          // Single selection (full slot or single half) - add unique slots
          for (var selection in selections) {
            final slot = selection['slot'] as Slots;
            // Only add if not already added (avoid duplicates)
            if (!consolidatedSlots.any((s) => s.sId == slot.sId &&
                s.time == slot.time)) {
              consolidatedSlots.add(slot);
            }
          }
        }
      });

      return GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.0,
        ),
        itemCount: consolidatedSlots.length,
        itemBuilder: (context, index) {
          final slot = consolidatedSlots[index];
          return _buildSelectedSlotTile(slot);
        },
      );
    });
  }

  Widget _buildGradientToggleChild({
    required String text,
    required bool isSelected,
  }) {
    return Container(
      width: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
          colors: [
            Color(0xff1F41BB), Color(0xff0E1E55)
          ],
        )
            : null,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,style: TextStyle(fontSize: 18),),
    );
  }

  Widget _buildSelectedSlotTile(dynamic slot) {
    const radius = 5.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.secondaryColor
          // gradient: const LinearGradient(
          //   colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
          //   begin: Alignment.topCenter,
          //   end: Alignment.bottomCenter,
          // ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                controller.formatTimeForDisplay(slot.time),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSlotsGrid(List<dynamic> slotTimes, String courtId) {
    if (slotTimes.isEmpty) {
      return const Center(
        child: Text(
          "No time slots available",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            fontSize: 12,
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemCount: slotTimes.length,
      itemBuilder: (context, index) {
        final slot = slotTimes[index];
        return Obx(() => _buildSlotTile(slot, courtId));
      },
    );
  }

  /// Build slot tile for court rows with half-slot selection support
  Widget _buildCourtSlotTile(
      BuildContext context,
      dynamic slot,
      String courtName,
      int courtIndex,
      int slotIndex, {
        String? courtId,
        List<dynamic>? availableSlots,
      })
  {
    final resolvedCourtId = courtId ?? 'court${courtIndex + 1}';
    final supports30Min = controller.clubSupports30MinSlots(resolvedCourtId);
    final isSelected = controller.isRealCourtSlotSelected(slot, resolvedCourtId);
    final isLeftHalfBooked = supports30Min && controller.isLeftHalfBooked(slot, resolvedCourtId);
    final isRightHalfBooked = supports30Min && controller.isRightHalfBooked(slot, resolvedCourtId);

    // Check if this is the first selection for this court
    final isFirstSelectionForCourt = controller.realCourtSelections.entries
        .where((e) => (e.value['courtId'] as String) == resolvedCourtId)
        .isEmpty;

    const blueColor = Color(0xff053CFF);
    const radius = 5.0;

    return Builder(
      builder: (BuildContext builderContext) {
        return GestureDetector(
          onTapDown: (details) {
            final RenderBox? box = builderContext.findRenderObject() as RenderBox?;
            if (box != null) {
              final localPosition = box.globalToLocal(details.globalPosition);
              final isLeftHalf = localPosition.dx < box.size.width / 2;

              // Check if this is the first selection for this court
              final isFirstSelectionForCourt = controller.realCourtSelections.entries
                  .where((e) => (e.value['courtId'] as String) == resolvedCourtId)
                  .isEmpty;

              // Check if full slot is already selected
              final currentDate = controller.selectedDate.value ?? DateTime.now();
              final dateString = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
              final realCourtKey = '${dateString}_${resolvedCourtId}_${slot.sId}';
              final isFullSlotSelected = controller.realCourtSelections.containsKey(realCourtKey);

              if (isFullSlotSelected) {
                // Full slot is selected - unselect it completely
                controller.toggleCourtRowSlotSelection(
                  slot,
                  courtId: resolvedCourtId,
                  courtName: courtName,
                );
              } else if (supports30Min && !isFirstSelectionForCourt) {
                // Half slot selection for subsequent selections
                // Prevent selection of left half if it's booked
                if (isLeftHalf && isLeftHalfBooked) {
                  return;
                }
                // Prevent selection of right half if it's booked
                if (!isLeftHalf && isRightHalfBooked) {
                  return;
                }

                controller.toggleCourtRowSlotSelection(
                  slot,
                  courtId: resolvedCourtId,
                  courtName: courtName,
                  isHalfSlot: true,
                  isFirstHalf: isLeftHalf,
                );
              } else {
                // Full slot selection for first selection or non-30min
                controller.toggleCourtRowSlotSelection(
                  slot,
                  courtId: resolvedCourtId,
                  courtName: courtName,
                );
              }
            }
          },
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                /// FULL GRADIENT FOR BOTH HALVES SELECTED (30MIN)
                if (supports30Min && controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: const LinearGradient(
                        colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                /// FULL GRADIENT FOR FULL SLOT SELECTION (NON-30MIN OR FIRST SELECTION)
                if (isSelected && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId) && 
                    !controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId) && 
                    !controller.isRightHalfSelectedInCourt(slot, resolvedCourtId))
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: const LinearGradient(
                        colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                /// LEFT HALF GRADIENT FOR 30MIN LEFT SELECTION
                if (supports30Min && controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId) && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 44, // Fixed width for simplicity
                      height: 34,
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

                /// RIGHT HALF GRADIENT FOR 30MIN RIGHT SELECTION
                if (supports30Min && controller.isRightHalfSelectedInCourt(slot, resolvedCourtId) && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 44, // Fixed width for simplicity
                      height: 34,
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

                /// LEFT HALF BOOKED OVERLAY (FADED)
                if (supports30Min && isLeftHalfBooked && !controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 44,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(radius),
                          bottomLeft: Radius.circular(radius),
                        ),
                        color: Colors.grey.shade300.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  
                /// RIGHT HALF BOOKED OVERLAY (FADED)
                if (supports30Min && isRightHalfBooked && !controller.isRightHalfSelectedInCourt(slot, resolvedCourtId))
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 44,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(radius),
                          bottomRight: Radius.circular(radius),
                        ),
                        color: Colors.grey.shade300.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                /// VERTICAL DIVIDER FOR 30MIN SLOTS
                if (supports30Min && !isSelected)
                  Center(
                    child: Container(
                      width: 2,
                      height: 35,
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),

                /// LEFT BLUE STRIP (ONLY WHEN NOT SELECTED)
                if (!isSelected)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: blueColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(radius),
                          bottomLeft: Radius.circular(radius),
                        ),
                      ),
                    ),
                  ),

                /// TEXT - Single text with half-color support using Stack
                Center(
                  child: Stack(
                    children: [
                      // Base text (black for unselected parts)
                      Text(
                        controller.formatTimeForDisplay(slot.time),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      // Full white text for full slot selection (no half selections)
                      if (isSelected && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId) && 
                          !controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId) && 
                          !controller.isRightHalfSelectedInCourt(slot, resolvedCourtId))
                        Text(
                          controller.formatTimeForDisplay(slot.time),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),

                      // Full white text for both halves selected
                      if (supports30Min && controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                        Text(
                          controller.formatTimeForDisplay(slot.time),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),

                      // Left half white text overlay
                      if (supports30Min && controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId) && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                        ClipRect(
                          clipper: LeftHalfClipper(),
                          child: Text(
                            controller.formatTimeForDisplay(slot.time),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Right half white text overlay
                      if (supports30Min && controller.isRightHalfSelectedInCourt(slot, resolvedCourtId) && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                        ClipRect(
                          clipper: RightHalfClipper(),
                          child: Text(
                            controller.formatTimeForDisplay(slot.time),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Left half grayed text for booked slots
                      if (supports30Min && isLeftHalfBooked && !controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId))
                        ClipRect(
                          clipper: LeftHalfClipper(),
                          child: Text(
                            controller.formatTimeForDisplay(slot.time),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        
                      // Right half grayed text for booked slots
                      if (supports30Min && isRightHalfBooked && !controller.isRightHalfSelectedInCourt(slot, resolvedCourtId))
                        ClipRect(
                          clipper: RightHalfClipper(),
                          child: Text(
                            controller.formatTimeForDisplay(slot.time),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotTile(dynamic slot, String courtId) {
    final isSelected = controller.isSlotSelected(slot, courtId);
    final supports30Min = controller.is30Slots.value;
    final isBothHalvesSelected = supports30Min && controller.isBothHalvesSelectedInMainGrid(slot, courtId);
    final isFullySelected = isBothHalvesSelected || (isSelected && !supports30Min);

    final isUnavailable = controller.isPastAndUnavailable(slot) ||
        (slot.status?.toLowerCase() == 'booked') ||
        (slot.availabilityStatus?.toLowerCase() == 'maintenance') ||
        (slot.availabilityStatus?.toLowerCase() == 'weather conditions') ||
        (slot.availabilityStatus?.toLowerCase() == 'staff unavailability'||
        (slot.availabilityStatus?.toLowerCase() == 'tournament'));

    // Check if this is the first selection
    final isFirstSelection = controller.multiDateSelections.isEmpty;

    const blueColor = Color(0xff053CFF);
    const radius = 5.0;

    return Builder(
      builder: (BuildContext builderContext) {
        return GestureDetector(
          onTapDown: supports30Min && !isFirstSelection ? (details) {
            // For 30-minute support (only if NOT first selection), detect left/right half tap
            final RenderBox? box = builderContext.findRenderObject() as RenderBox?;
            if (box != null) {
              final localPosition = box.globalToLocal(details.globalPosition);
              final isLeftHalf = localPosition.dx < box.size.width / 2;

              controller.toggleSlotSelection(
                slot,
                courtId: courtId,
                courtName: '',
                isHalfSlot: true,
                isFirstHalf: isLeftHalf,
              );
            }
          } : null,
          onTap: (!supports30Min || isFirstSelection) && !isUnavailable ? () {
            // Full slot selection for non-30min OR first selection
            controller.toggleSlotSelection(
              slot,
              courtId: courtId,
              courtName: '',
            );
          } : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: isUnavailable ? Colors.grey.shade100 : Colors.white,
                border: Border.all(
                  color: isUnavailable
                      ? Colors.grey.shade300
                      : isFullySelected
                      ? Colors.transparent
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  /// FULL GRADIENT FOR BOTH HALVES SELECTED (30MIN)
                  if (supports30Min && controller.isBothHalvesSelectedInMainGrid(slot, courtId))
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

                  /// FULL GRADIENT FOR NON-30MIN SELECTIONS
                  if (isSelected && !supports30Min)
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

                  /// LEFT HALF GRADIENT FOR 30MIN LEFT SELECTION
                  if (supports30Min && controller.isLeftHalfSelectedInMainGrid(slot, courtId) && !controller.isBothHalvesSelectedInMainGrid(slot, courtId))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 44, // Fixed width for simplicity
                        height: 34,
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

                  /// RIGHT HALF GRADIENT FOR 30MIN RIGHT SELECTION
                  if (supports30Min && controller.isRightHalfSelectedInMainGrid(slot, courtId) && !controller.isBothHalvesSelectedInMainGrid(slot, courtId))
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 44, // Fixed width for simplicity
                        height: 34,
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

                  /// VERTICAL DIVIDER FOR 30MIN SLOTS
                  if (supports30Min && !controller.isBothHalvesSelectedInMainGrid(slot, courtId))
                    Center(
                      child: Container(
                        width: 2,
                        height: 35,
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),

                  /// LEFT BLUE STRIP (ONLY WHEN AVAILABLE AND NOT SELECTED)
                  if (!isSelected)
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

                  /// TEXT - Single text with half-color support using Stack
                  Center(
                    child: Stack(
                      children: [
                        // Base text (black for unselected parts)
                        Text(
                          controller.formatTimeForDisplay(slot.time),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isUnavailable
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),

                        // Left half white text overlay
                        if (supports30Min && controller.isLeftHalfSelectedInMainGrid(slot, courtId))
                          ClipRect(
                            clipper: LeftHalfClipper(),
                            child: Text(
                              controller.formatTimeForDisplay(slot.time),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Right half white text overlay
                        if (supports30Min && controller.isRightHalfSelectedInMainGrid(slot, courtId))
                          ClipRect(
                            clipper: RightHalfClipper(),
                            child: Text(
                              controller.formatTimeForDisplay(slot.time),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // Full white text for non-30min selections or both halves selected
                        if ((!supports30Min && isSelected) || (supports30Min && controller.isBothHalvesSelectedInMainGrid(slot, courtId)))
                          Text(
                            controller.formatTimeForDisplay(slot.time),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isUnavailable
                                  ? Colors.grey.shade500
                                  : Colors.white,
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
  String formatTimeSlot(String time) {
    return controller.formatTimeForDisplay(time);
  }

  String _formatTimeForDisplay(String time) {
    return controller.formatTimeForDisplay(time);
  }

  void showChangeLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeLocationBottomSheet(),
    );
  }

  Widget _buildPaymentPanel() {
    return Obx(() {
      final hasCourtSlotSelections = controller.realCourtSelections.isNotEmpty;
      final isEnabled = hasCourtSlotSelections;

      final double collapsedHeight = Get.height * .11;
      final double expandedHeight = Get.height * .11;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        height: isEnabled ? expandedHeight : collapsedHeight,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: CustomButton(
                width: Get.width*0.9,
                child: Text("Next",style:  Get.textTheme.headlineMedium!.copyWith(
                  color: AppColors.whiteColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),).paddingOnly(right: 40),
                onTap: isEnabled ? () {
                  Get.bottomSheet(
                    backgroundColor: Colors.transparent,
                    SizedBox(
                      height: Get.height,
                      child: PaymentOptionSheet(),
                    ),
                    isScrollControlled: true,
                  );
                } : null,
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buildSlotDetails() {
    // Group selections by date and court, then group consecutive slots
    final groupedSelections = <String, List<Map<String, dynamic>>>{};

    // First group by date and court
    for (var entry in controller.realCourtSelections.entries) {
      final selection = entry.value;
      final dateTime = selection['dateTime'] as DateTime;
      final courtId = selection['courtId'] as String;
      final formattedDate = DateFormat('dd, MMM').format(dateTime);
      final key = '${formattedDate}_$courtId';

      if (!groupedSelections.containsKey(key)) {
        groupedSelections[key] = [];
      }
      groupedSelections[key]!.add(selection);
    }

    // Process each group to find consecutive slots and consolidate half-slots
    final processedEntries = <Map<String, dynamic>>[];

    for (var entry in groupedSelections.entries) {
      final selections = entry.value;
      final parts = entry.key.split('_');
      final date = parts[0];
      final courtId = parts.length > 1 ? parts[1] : '';

      // Get club name and court name from courtsByDuration data
      String clubName = 'Club';
      String courtName = 'Court';
      if (controller.courtsByDuration.value?.data != null) {
        for (var clubData in controller.courtsByDuration.value!.data!) {
          if (clubData.courts != null) {
            for (var court in clubData.courts!) {
              if (court.id == courtId) {
                clubName = clubData.clubName ?? 'Club';
                courtName = court.courtName ?? 'Court';
                break;
              }
            }
          }
          if (clubName != 'Club') break;
        }
      }

      // Group by slot ID to consolidate half-slots
      final Map<String, List<Map<String, dynamic>>> slotGroups = {};
      for (var selection in selections) {
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        if (!slotGroups.containsKey(slotId)) {
          slotGroups[slotId] = [];
        }
        slotGroups[slotId]!.add(selection);
      }

      // Convert slot groups to consolidated selections
      final consolidatedSelections = <Map<String, dynamic>>[];
      for (var slotGroup in slotGroups.entries) {
        final slotSelections = slotGroup.value;
        if (slotSelections.length == 2) {
          // Both halves selected - create one consolidated entry
          final firstSelection = slotSelections.first;
          final totalAmount = slotSelections.fold<int>(0, (sum, sel) => sum + (sel['amount'] as int? ?? 0));
          consolidatedSelections.add({
            'slot': firstSelection['slot'],
            'amount': totalAmount,
            'dateTime': firstSelection['dateTime'],
          });
        } else {
          // Single half or full slot - add as is
          consolidatedSelections.addAll(slotSelections);
        }
      }

      // Sort consolidated selections by time
      consolidatedSelections.sort((a, b) {
        final timeA = _parseTimeToMinutes((a['slot'] as Slots).time ?? '');
        final timeB = _parseTimeToMinutes((b['slot'] as Slots).time ?? '');
        return timeA.compareTo(timeB);
      });

      // Group consecutive slots
      var i = 0;
      while (i < consolidatedSelections.length) {
        final consecutiveGroup = [consolidatedSelections[i]];
        var totalAmount = consolidatedSelections[i]['amount'] as int? ?? 0;

        // Find consecutive slots
        for (var j = i + 1; j < consolidatedSelections.length; j++) {
          final currentTime = _parseTimeToMinutes((consolidatedSelections[j - 1]['slot'] as Slots).time ?? '');
          final nextTime = _parseTimeToMinutes((consolidatedSelections[j]['slot'] as Slots).time ?? '');

          if (nextTime - currentTime == 60) { // 1 hour difference
            consecutiveGroup.add(consolidatedSelections[j]);
            totalAmount += consolidatedSelections[j]['amount'] as int? ?? 0;
          } else {
            break;
          }
        }

        // Create entry for this group
        final firstSlot = consecutiveGroup.first['slot'] as Slots;
        final lastSlot = consecutiveGroup.last['slot'] as Slots;

        String timeRange;
        if (consecutiveGroup.length == 1) {
          timeRange = formatTimeSlot(firstSlot.time ?? '');
        } else {
          final startTime = _formatTimeForDisplay(firstSlot.time ?? '');
          final endTime = _formatTimeForDisplay(lastSlot.time ?? '');
          // Extract period from end time and use it for the range
          final endPeriod = endTime.contains('pm') ? 'pm' : 'am';
          final startHour = startTime.replaceAll(RegExp(r'[ap]m'), '');
          final endHour = endTime.replaceAll(RegExp(r'[ap]m'), '');
          timeRange = '$startHour-$endHour$endPeriod';
        }

        processedEntries.add({
          'date': date,
          'timeRange': timeRange,
          'courtName': courtName,
          'clubName': clubName,
          'totalAmount': totalAmount,
          'selections': consecutiveGroup,
        });

        i += consecutiveGroup.length;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary:',
          style: Get.textTheme.headlineSmall!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...processedEntries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Get.textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry['date']} ${entry['timeRange']}\n',
                          style: Get.textTheme.labelSmall!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        TextSpan(
                          text: '${entry['clubName']} - ${entry['courtName']}',
                          style: Get.textTheme.labelSmall!.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '₹ ${entry['totalAmount']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final selections = entry['selections'] as List<Map<String, dynamic>>;
                    final slotsToDelete = <Map<String, dynamic>>[];

                    for (var selection in selections) {
                      final slot = selection['slot'] as Slots;
                      final slotId = slot.sId ?? '';
                      final courtId = selection['courtId'] as String;
                      final dateString = selection['date'] as String;
                      final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
                      final duration = isHalfSlot ? 30 : 60;

                      slotsToDelete.add({
                        "slotId": slotId,
                        "courtId": courtId,
                        "bookingDate": dateString,
                        "time": slot.time ?? '',
                        "bookingTime": slot.time ?? '',
                        "duration": duration,
                      });
                    }

                    // Only call deleteSlotHistory if "Pay for All Players" option is used
                    await controller.deleteSlotHistory(
                      slots: slotsToDelete, 
                      isPayForAll: controller.isPayForAllPlayersSelected
                    );

                    for (var selection in selections) {
                      final slot = selection['slot'] as Slots;
                      controller.realCourtSelections.removeWhere((key, value) =>
                      (value['slot'] as Slots).sId == slot.sId);
                      controller.selectedSlots.removeWhere((s) => s.sId == slot.sId);
                    }
                    controller.recalculateRealCourtTotalAmount();
                  },
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Divider(color: Colors.white.withOpacity(0.25)),
        const SizedBox(height: 8),
      ],
    );
  }

  int _getGroupedSlotsCount() {
    // Group selections by date and court, then count consolidated slots
    final groupedSelections = <String, List<Map<String, dynamic>>>{};

    // First group by date, court, and club
    for (var entry in controller.realCourtSelections.entries) {
      final selection = entry.value;
      final dateTime = selection['dateTime'] as DateTime;
      final courtId = selection['courtId'] as String;
      final formattedDate = DateFormat('dd, MMM').format(dateTime);
      final key = '${formattedDate}_$courtId';

      if (!groupedSelections.containsKey(key)) {
        groupedSelections[key] = [];
      }
      groupedSelections[key]!.add(selection);
    }

    int totalGroups = 0;

    for (var entry in groupedSelections.entries) {
      final selections = entry.value;

      // Group by slot ID to consolidate half-slots
      final Map<String, List<Map<String, dynamic>>> slotGroups = {};
      for (var selection in selections) {
        final slot = selection['slot'] as Slots;
        final slotId = slot.sId ?? '';
        if (!slotGroups.containsKey(slotId)) {
          slotGroups[slotId] = [];
        }
        slotGroups[slotId]!.add(selection);
      }

      // Convert slot groups to consolidated selections
      final consolidatedSelections = <Map<String, dynamic>>[];
      for (var slotGroup in slotGroups.entries) {
        final slotSelections = slotGroup.value;
        if (slotSelections.length == 2) {
          // Both halves selected - count as one slot
          consolidatedSelections.add(slotSelections.first);
        } else {
          // Single half or full slot - add as is
          consolidatedSelections.addAll(slotSelections);
        }
      }

      // Sort consolidated selections by time
      consolidatedSelections.sort((a, b) {
        final timeA = _parseTimeToMinutes((a['slot'] as Slots).time ?? '');
        final timeB = _parseTimeToMinutes((b['slot'] as Slots).time ?? '');
        return timeA.compareTo(timeB);
      });

      // Count consecutive groups
      var i = 0;
      while (i < consolidatedSelections.length) {
        var consecutiveCount = 1;

        // Find consecutive slots
        for (var j = i + 1; j < consolidatedSelections.length; j++) {
          final currentTime = _parseTimeToMinutes((consolidatedSelections[j - 1]['slot'] as Slots).time ?? '');
          final nextTime = _parseTimeToMinutes((consolidatedSelections[j]['slot'] as Slots).time ?? '');

          if (nextTime - currentTime == 60) { // 1 hour difference
            consecutiveCount++;
          } else {
            break;
          }
        }

        totalGroups++;
        i += consecutiveCount;
      }
    }

    return totalGroups;
  }

  int _parseTimeToMinutes(String time) {
    try {
      final cleanTime = time.trim().toLowerCase();
      final parts = cleanTime.split(' ');
      if (parts.length != 2) return 0;

      final timePart = parts[0];
      final period = parts[1];

      final timeParts = timePart.split(':');
      int hour = int.tryParse(timeParts[0]) ?? 0;
      int minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  bool _isSlotPastExpiry(dynamic slot) {
    final now = DateTime.now();
    final selectedDate = controller.selectedDate.value;
    
    // If no date selected or not today, slot is not expired
    if (selectedDate == null) return false;
    
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (!isToday) return false;

    final slotTime = slot.time ?? '';
    if (slotTime.isEmpty) return false;
    
    final slotMinutes = _parseTimeToMinutes(slotTime);
    final currentMinutes = now.hour * 60 + now.minute;

    // Slot is expired if current time is MORE than 15 minutes past slot time
    return currentMinutes > slotMinutes + 15;
  }

  void _startSlotExpiryCheck() {
    // Check every minute for expired slots
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      _removeExpiredSlots();
    });
  }

  void _removeExpiredSlots() {
    final now = DateTime.now();
    final selectedDate = controller.selectedDate.value;
    final isToday = selectedDate?.year == now.year &&
        selectedDate?.month == now.month &&
        selectedDate?.day == now.day;

    if (!isToday) return;

    final currentMinutes = now.hour * 60 + now.minute;
    final keysToRemove = <String>[];

    controller.multiDateSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final slotTime = slot.time ?? '';
      final slotMinutes = _parseTimeToMinutes(slotTime);

      if (currentMinutes > slotMinutes + 15) {
        keysToRemove.add(key);
      }
    });

    for (var key in keysToRemove) {
      controller.multiDateSelections.remove(key);
    }

    // Also remove from realCourtSelections
    final realKeysToRemove = <String>[];
    controller.realCourtSelections.forEach((key, selection) {
      final slot = selection['slot'] as Slots;
      final slotTime = slot.time ?? '';
      final slotMinutes = _parseTimeToMinutes(slotTime);

      if (currentMinutes > slotMinutes + 15) {
        realKeysToRemove.add(key);
      }
    });

    for (var key in realKeysToRemove) {
      controller.realCourtSelections.remove(key);
    }

    if (keysToRemove.isNotEmpty || realKeysToRemove.isNotEmpty) {
      controller.recalculateRealCourtTotalAmount();
    }
  }


  void _initiatePayment() {
    isProcessing.value = true;

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      isProcessing.value = false;
      CustomLogger.logMessage(msg: "Payment successful! Booking confirmed.", level: LogLevel.debug);
      controller.clearAllSelections();
    });
  }
}

class ChangeLocationBottomSheet extends StatelessWidget {
  final CreateOpenMatchForAllCourtsController controller = Get.put(CreateOpenMatchForAllCourtsController());
  ChangeLocationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 5),

            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Change Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance back icon
                ],
              ),
            ),
            fadeDivider(),
            //
            // /// SEARCH
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: TextField(
            //     style: Get.textTheme.headlineSmall!.copyWith(
            //       color: AppColors.labelBlackColor,
            //     ),
            //     decoration: InputDecoration(
            //       hintText: 'Search by city name',
            //       suffixIcon: const Icon(Icons.search),
            //       filled: true,
            //       fillColor: AppColors.textFieldColor,
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //   ),
            // ),

            /// CITY LIST
            Expanded(
              child: Obx(() {
                if (controller.isLoadingLocations.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryColor),
                  );
                }

                final locations = controller.locationsData.value?.data;
                if (locations == null || locations.isEmpty) {
                  return const Center(child: Text('No locations available'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: locations.length,
                  separatorBuilder: (_, __) =>  Divider(height: 1,color: Colors.grey.withValues(alpha: 0.3),),
                  itemBuilder: (context, index) {
                    final location = locations[index];

                    return Obx(() {
                      final isSelected =
                          controller.selectedCityId.value == location.id;

                      return InkWell(
                        onTap: () {
                          controller.selectedCityId.value = location.id ?? '';
                        },
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xffE8ECFF) // blue selected tile
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  location.name ?? '',
                                  style: Get.textTheme.bodyLarge!.copyWith(
                                    fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  },

                );
              }),
            ),

            /// UPDATE BUTTON
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final isEnabled = controller.selectedCityId.value.isNotEmpty;
                final isLoading = controller.isUpdatingLocation.value;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled
                          ? const Color(0xff2C3EBB)
                          : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (isEnabled && !isLoading)
                        ? () async {
                      final selectedId = controller.selectedCityId.value;
                      final success = await controller.updateUserLocation(selectedId);
                      if (success) {
                        Navigator.pop(context);
                      }
                    }
                        : null,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 16,
                              color: isEnabled ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Custom clippers for half-text coloring
class LeftHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

class RightHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

class PaymentOptionSheet extends StatelessWidget {
  final CreateOpenMatchForAllCourtsController controller = Get.put(CreateOpenMatchForAllCourtsController());
  PaymentOptionSheet({super.key});


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),
      
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                ),
                Obx(() => Column(
                  children: [
                    _optionCard(
                      index: 0,
                      controller: controller,
                      title: 'Pay for All Players',
                      subtitle: 'INSTANT CONFIRMATION',
                      image: Assets.imagesIcCash,
                      optionIcon: Icons.check_circle,
                      activeColor: Colors.green,
                      points: const [
                        'Confirm court booking immediately',
                        'Instant refunds as your teammates pay their share',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _optionCard(
                      index: 1,
                      controller: controller,
                      title: 'Pay your share only',
                      subtitle: 'FLEXIBLE BOOKING',
                      image: Assets.imagesIcPerson,
                      optionIcon: Icons.timelapse,
                      activeColor: Colors.orange,
                      points: const [
                        'Matches remain unbooked until the 4-player minimum is reached.',
                        'Fail to hit 4 players? You’ll get an automatic refund.',
                        'If your court is busy, we’ll relocate your game or issue a full refund.',
                      ],
                    ),
                  ],
                )),
                _secureInfo().paddingSymmetric(vertical: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white10,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: Get.textTheme.labelLarge!
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: ()=>controller.onNextPressed(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Next",
                          style: Get.textTheme.labelLarge!
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ).paddingAll(16),
          ),
        ],
      ),
    );
  }

  Widget _secureInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(Assets.imagesIcPrivacy,scale: 4.5,color: Colors.white70,),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Secured payment with automated instant refunds',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  Widget _optionCard({
    required int index,
    required CreateOpenMatchForAllCourtsController controller,
    required String title,
    required String subtitle,
    required String image,
    required IconData optionIcon,
    required Color activeColor,
    required List<String> points,
  }) {
    final isSelected = controller.selectedIndex.value == index;

    return GestureDetector(
      onTap: () => controller.select(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: activeColor,
                  child: SvgPicture.asset(image,height: 20,width: 20,),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: TextStyle(
                              color: activeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: activeColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...points.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(optionIcon,
                        color: activeColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

