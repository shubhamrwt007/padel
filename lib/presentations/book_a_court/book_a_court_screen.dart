import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/request_models/home_models/get_available_court.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/book_a_court/book_a_court_controller.dart';
import 'package:padel_mobile/services/socket_service.dart';
import 'package:padel_mobile/core/network/dio_client.dart' show storage;
import 'package:padel_mobile/presentations/cart/cart_controller.dart';
import 'package:padel_mobile/presentations/payment/payment_method_controller.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/court_slots_shimmer.dart';
import 'package:padel_mobile/presentations/booking/book_session/widgets/upword_arrow_animation.dart';
import 'package:padel_mobile/data/response_models/get_courts_by_duration_model.dart';
class BookACourtScreen extends StatelessWidget {
  final BookACourtController controller = Get.put(BookACourtController());
  final WalletController walletController = Get.put(WalletController());
  final RxBool isExpanded = false.obs;
  final RxBool isProcessing = false.obs;
  final ScrollController mainScrollController = ScrollController();
  final ScrollController paymentScrollController = ScrollController();
  final RxInt displayedCourtsCount = 10.obs;
  final GlobalKey availableCourtsKey = GlobalKey();

  BookACourtScreen({super.key}) {
    mainScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mainScrollController.position.pixels >= mainScrollController.position.maxScrollExtent - 200) {
      _loadMoreCourts();
    }
  }
  @override
  Widget build(BuildContext context) {
    // Fetch wallet balance after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletController.fetchWallet();
      // Ensure socket is connected with userId
      try {
        final socketService = SocketService.instance;
        final userId = storage.read('userId')?.toString() ?? '';
        if (userId.isNotEmpty) {
          socketService.setUserIdAndConnect(userId);
        } else if (!socketService.isConnected) {
          socketService.connect();
        }
      } catch (e) {
        log('Socket connection error in BookACourtScreen: $e');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      bottomNavigationBar: _buildPaymentPanel(),
      appBar: primaryAppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Find a Court").paddingOnly(right: 5),
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
                child: Icon(Icons.info_outline,size: 15,).paddingOnly(top: 3))
          ],
        ),
        centerTitle: true,
        context: context,
        action: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
        controller: mainScrollController,
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
                      controller.showMainGrid.value ? 'Prefered Slots' : 'Selected Slots',
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
              )).paddingOnly(bottom: 0),
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
                  onTap: () {
                    displayedCourtsCount.value = 10; // Reset to initial count
                    controller.fetchClubs();
                    // Scroll to available courts section after a short delay
                    Future.delayed(Duration(milliseconds: 300), () {
                      _scrollToAvailableCourts();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10,horizontal: 14),
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
                  ? availableCourts()
                  : SizedBox.shrink()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGradientToggleChild({
    required String text,
    required bool isSelected,
  }) {
    return Container(
      width: 60,
      alignment: Alignment.center,
      // padding: const EdgeInsets.symmetric(horizontal: 12),
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


  Widget _typeButton(String title, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget availableCourts() {
    return Column(
      key: availableCourtsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show header with match type buttons
        Row(
          children: [
            Text('Available Courts', style: Get.textTheme.labelLarge),
            const Spacer(),
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
                message: "You will not be given XP points\nupon selections of friendly match",
                waitDuration: Duration(milliseconds: 200),
                showDuration: Duration(seconds: 3),
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline,size: 15,)).paddingOnly(right: 5),

            Obx(() {
              final isFriendly = controller.matchType.value == "friendly";

              return Container(
                height: 30,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    _typeButton("Friendly", isFriendly, () {
                      controller.matchType.value = "friendly";
                    }),
                    _typeButton("Competitive", !isFriendly, () {
                      controller.matchType.value = "competitive";
                    }),
                  ],
                ),
              );
            }),

          ],
        ),
        const SizedBox(height: 16),
        // Conditional content based on selection state
        Builder(
          builder: (context) => _buildAvailableCourtsContent(context),
        ),
      ],
    );
  }

  Widget _buildAvailableCourtsContent(BuildContext context) {
    return Obx(() {
      // Check if no slots are selected from main grid
      if (controller.multiDateSelections.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Please select a time slot from above to see available courts.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // Show loading state
      if (controller.isLoadingCourtsByDuration.value) {
        return const SizedBox(
          height: 100,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: LoadingWidget(color: AppColors.primaryColor),
            ),
          ),
        );
      }

      final courtsByDuration = controller.courtsByDuration.value;

      // Show empty state if no data
      if (courtsByDuration == null ||
          courtsByDuration.data == null ||
          courtsByDuration.data!.isEmpty) {
        return  Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No court’s available for this time',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ).paddingOnly(top: Get.height*.2);
      }

      final clubsData = courtsByDuration.data!;
      final displayCount = displayedCourtsCount.value.clamp(0, clubsData.length);
      final displayedClubs = clubsData.take(displayCount).toList();
      final hasMore = displayCount < clubsData.length;

      // Auto-expand first club (since all clubs have the requested time)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (displayedClubs.isNotEmpty && controller.expandedIndex.value == -1) {
          controller.expandedIndex.value = 0; // Expand first club
          log('🔵 Auto-expanding first club at index 0');
        }
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(displayedClubs.length, (clubIndex) {
            final clubData = displayedClubs[clubIndex];
            final isLastItem = clubIndex == displayedClubs.length - 1;

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
                                      controller.getLocationNameFromClub(clubData),
                                      style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)
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
                            slotDuration: court.slotDuration,
                            selectedIndex: courtIndex,
                            availableSlots: court.slots,
                            courtId: court.id ?? '',
                            isRequestedTime: clubIndex == 0, // First club gets auto-scroll
                            clubIndex: clubIndex,
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
          if (hasMore)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: TextButton(
                  onPressed: _loadMoreCourts,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Load More Courts',
                    style: Get.textTheme.labelMedium!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _courtRow({
    required BuildContext context,
    required String courtName,
    List<int>? slotDuration,
    required int selectedIndex,
    List<CourtSlot>? availableSlots,
    String? courtId,
    bool isRequestedTime = false,
    required int clubIndex,
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

    final scrollController = ScrollController();

    // Auto-scroll to requested time slot when club is expanded
    if (displaySlots.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.expandedIndex.value == (clubIndex * 100)) {
          Future.delayed(Duration(milliseconds: 350), () {
            if (scrollController.hasClients && availableSlots != null) {
              // Find the slot marked as isRequestedTime in the API response
              int foundIndex = -1;
              for (int i = 0; i < availableSlots.length; i++) {
                if (availableSlots[i].isRequestedTime == true) {
                  foundIndex = i;
                  log('✅ Found requested slot at index $foundIndex: ${availableSlots[i].time}');
                  break;
                }
              }
              
              if (foundIndex != -1) {
                final offset = (foundIndex * 98.0).clamp(0.0, scrollController.position.maxScrollExtent);
                scrollController.animateTo(
                  offset,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                log('❌ No slot found with isRequestedTime: true');
              }
            }
          });
        }
      });
    }

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
                      "(${slotDuration.map((d) => '${d}min').join(', ')})",
                      style: Get.textTheme.labelSmall!.copyWith(
                        color: Colors.grey.shade600,
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
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: displaySlots.map((slot) {
                      final index = displaySlots.indexOf(slot);
                      return Padding(
                        padding: EdgeInsets.only(right: index < displaySlots.length - 1 ? 10 : 0),
                        child: SizedBox(
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
                        ),
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
                            // Hide today's date if time is 11:01 PM or later
                            if (now.hour == 23 && now.minute >= 1) {
                              if (currentDate.year == today.year &&
                                  currentDate.month == today.month &&
                                  currentDate.day == today.day) {
                                return const SizedBox.shrink();
                              }
                            }
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
                            // Refresh courts by duration if time slot is selected
                            controller.fetchCourtsIfReady();
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
                  // GestureDetector(
                  //   onTap: () {
                  //     controller.openDatePicker(context);
                  //   },
                  //   child: Container(
                  //     height: 25,
                  //     width: 25,
                  //     decoration: BoxDecoration(
                  //       color: AppColors.textFieldColor,
                  //       borderRadius: BorderRadius.circular(5),
                  //       boxShadow: const [
                  //         BoxShadow(
                  //           color: Colors.black12,
                  //           blurRadius: 8,
                  //           offset: Offset(2, 2),
                  //         ),
                  //       ],
                  //     ),
                  //     child: const Center(
                  //       child: Icon(
                  //         Icons.calendar_month_outlined,
                  //         color: AppColors.primaryColor,
                  //         size: 20,
                  //       ),
                  //     ),
                  //   ),
                  // ).paddingOnly(left: 10)
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

          // Keep slot available until 15 minutes past start time
          return currentMinutes <= slotMinutes + 15;
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
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
          ),

        ],
      );
    });
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

  // Helper method to find corresponding API slot for status check
  CourtSlot? _findCorrespondingApiSlot(dynamic slot, String courtId) {
    final courtsByDuration = controller.courtsByDuration.value;
    if (courtsByDuration?.data == null) return null;
    
    for (var clubData in courtsByDuration!.data!) {
      if (clubData.courts != null) {
        for (var court in clubData.courts!) {
          // Match both court ID and slot time
          if (court.id == courtId && court.slots != null) {
            for (var apiSlot in court.slots!) {
              if (apiSlot.time == slot.time) {
                return apiSlot;
              }
            }
          }
        }
      }
    }
    return null;
  }

  Widget _buildCourtSlotTile(
      BuildContext context,
      dynamic slot,
      String courtName,
      int courtIndex,
      int slotIndex, {
        String? courtId,
        List<Slots>? availableSlots,
      })
  {
    final resolvedCourtId = courtId ?? 'court${courtIndex + 1}';
    final supports30Min = controller.clubSupports30MinSlots(resolvedCourtId);
    final isSelected = controller.isRealCourtSlotSelected(slot, resolvedCourtId);
    // Check for booked slots from API response
    final correspondingApiSlot = _findCorrespondingApiSlot(slot, resolvedCourtId);
    final _status = correspondingApiSlot?.status?.toLowerCase();
    final isSlotBooked = _status == 'booked' || _status == 'unavailable';
    
    final isLeftHalfBooked = supports30Min && (controller.isLeftHalfBooked(slot, resolvedCourtId) || isSlotBooked);
    final isRightHalfBooked = supports30Min && (controller.isRightHalfBooked(slot, resolvedCourtId) || isSlotBooked);
    final isBothHalvesBooked = isLeftHalfBooked && isRightHalfBooked;
    final isAnyHalfBooked = isLeftHalfBooked || isRightHalfBooked;

    const blueColor = Color(0xff053CFF);
    const radius = 5.0;

    return Builder(
      builder: (BuildContext builderContext) {
        return GestureDetector(
          onTapDown: supports30Min ? (details) {
            // For 30-minute support, detect left/right half tap
            final RenderBox? box = builderContext.findRenderObject() as RenderBox?;
            if (box != null) {
              final localPosition = box.globalToLocal(details.globalPosition);
              final isLeftHalf = localPosition.dx < box.size.width / 2;

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
                availableSlots: availableSlots,
              );
            }
          } : null,
          onTap: !supports30Min ? () {
            // Prevent selection if slot is booked
            if (isSlotBooked || isAnyHalfBooked) {
              return;
            }

            controller.toggleCourtRowSlotSelection(
              slot,
              courtId: resolvedCourtId,
              courtName: courtName,
            );
          } : null,
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

                /// FULL GRADIENT FOR NON-30MIN SELECTIONS
                if (isSelected && !supports30Min)
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

                /// LEFT HALF BOOKED OVERLAY (RED)
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
                        color: AppColors.lightred,
                      ),
                    ),
                  ),

                /// RIGHT HALF BOOKED OVERLAY (RED)
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
                        color: AppColors.lightred,
                      ),
                    ),
                  ),

                /// FULL SLOT BOOKED OVERLAY (RED) - for non-30min slots or both halves booked
                if ((!supports30Min && isSlotBooked && !isSelected) || (supports30Min && isBothHalvesBooked && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId)))
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      color: AppColors.lightred,
                    ),
                  ),

                /// VERTICAL DIVIDER FOR 30MIN SLOTS
                if (supports30Min && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId))
                  Center(
                    child: Container(
                      width: 2,
                      height: 35,
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),

                /// LEFT STRIP (ONLY WHEN NOT SELECTED) - RED FOR BOOKED, BLUE FOR AVAILABLE
                if (!isSelected )
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 4,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (isSlotBooked || isAnyHalfBooked) ? AppColors.redColor
                            : blueColor,
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

                      // Left half white text overlay
                      if (supports30Min && controller.isLeftHalfSelectedInCourt(slot, resolvedCourtId))
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
                      if (supports30Min && controller.isRightHalfSelectedInCourt(slot, resolvedCourtId))
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

                      // Full slot grayed text for booked slots
                      if ((!supports30Min && isSlotBooked && !isSelected) || (supports30Min && isBothHalvesBooked && !controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId)))
                        Text(
                          controller.formatTimeForDisplay(slot.time),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),

                      // Full white text for non-30min selections or both halves selected
                      if ((!supports30Min && isSelected) || (supports30Min && controller.isBothHalvesSelectedInCourt(slot, resolvedCourtId)))
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
        (slot.availabilityStatus?.toLowerCase() == 'staff unavailability')||
        (slot.availabilityStatus?.toLowerCase() == 'tournament');

    // Check if first half is past for today (with 15 min buffer)
    final now = DateTime.now();
    final selectedDate = controller.selectedDate.value;
    final isToday = selectedDate?.year == now.year &&
        selectedDate?.month == now.month &&
        selectedDate?.day == now.day;

    bool isLeftHalfPast = false;
    if (isToday && supports30Min) {
      final slotMinutes = _parseTimeToMinutes(slot.time ?? '');
      final currentMinutes = now.hour * 60 + now.minute;
      // First half ends at slot start + 30 min, add 15 min buffer
      final firstHalfEndWithBuffer = slotMinutes + 30 + 15;
      isLeftHalfPast = currentMinutes > firstHalfEndWithBuffer;
    }

    const blueColor = Color(0xff053CFF);
    const radius = 5.0;

    return Builder(
      builder: (BuildContext builderContext) {
        return GestureDetector(
          onTapDown: supports30Min ? (details) {
            // For 30-minute support, detect left/right half tap
            final RenderBox? box = builderContext.findRenderObject() as RenderBox?;
            if (box != null) {
              final localPosition = box.globalToLocal(details.globalPosition);
              final isLeftHalf = localPosition.dx < box.size.width / 2;

              // Prevent selection of past left half
              if (isLeftHalf && isLeftHalfPast) {
                return;
              }

              controller.toggleSlotSelection(
                slot,
                courtId: courtId,
                courtName: '',
                isHalfSlot: true,
                isFirstHalf: isLeftHalf,
              );
            }
          } : null,
          onTap: !supports30Min && !isUnavailable ? () {
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

                  /// LEFT HALF - PAST OVERLAY (grayed) OR SELECTED GRADIENT
                  if (supports30Min && !controller.isBothHalvesSelectedInMainGrid(slot, courtId))
                    if (isLeftHalfPast && !controller.isLeftHalfSelectedInMainGrid(slot, courtId))
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
                      )
                    else if (controller.isLeftHalfSelectedInMainGrid(slot, courtId))
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
                        width: 44,
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

                  /// LEFT STRIP (ONLY WHEN NOT SELECTED) - RED FOR BOOKED, BLUE FOR AVAILABLE
                  if (!isSelected)
                    Positioned.fill(
                      left: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: isUnavailable ? AppColors.lightred : blueColor,
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

                        // Left half text overlay (white if selected, gray if past)
                        if (supports30Min && (controller.isLeftHalfSelectedInMainGrid(slot, courtId) || isLeftHalfPast))
                          ClipRect(
                            clipper: LeftHalfClipper(),
                            child: Text(
                              controller.formatTimeForDisplay(slot.time),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: controller.isLeftHalfSelectedInMainGrid(slot, courtId)
                                    ? Colors.white
                                    : Colors.grey.shade600,
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



  void showChangeLocationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>  ChangeLocationBottomSheet(),
    );
  }

  String formatTimeSlot(String time) {
    if (time.isEmpty) return time;

    try {
      // Parse and format the time consistently
      final timeString = time.trim();
      DateTime? parsedTime;

      // Try to parse with common formats
      for (final pattern in ['h:mm a', 'h a', 'HH:mm', 'H:mm']) {
        try {
          parsedTime = DateFormat(pattern).parse(timeString);
          break;
        } catch (_) {}
      }

      if (parsedTime != null) {
        return DateFormat('h:mm a').format(parsedTime);
      }

      return time; // Return original if parsing fails
    } catch (e) {
      return time;
    }
  }

  Widget _buildPaymentPanel() {
    return Obx(() {
      if (controller.realCourtSelections.isEmpty) {
        return const SizedBox.shrink();
      }

      final maxHeight = Get.height * 0.6;

      return GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -5) {
            isExpanded.value = true;
          } else if (details.primaryDelta! > 5 && isExpanded.value) {
            if (paymentScrollController.hasClients && paymentScrollController.offset <= 0) {
              isExpanded.value = false;
            }
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  isExpanded.value = !isExpanded.value;
                },
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.6,
                    child: Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: Color(0xFF003AFF),
                        shape: BoxShape.circle,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, -5),
                        child: Obx(
                              () => ArrowAnimation(
                            isUpward: !isExpanded.value,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: BoxConstraints(maxHeight: isExpanded.value ? maxHeight : 200),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003AFF), Color(0xFF07289A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isExpanded.value)
                    Flexible(
                      child: SingleChildScrollView(
                        controller: paymentScrollController,
                        padding: const EdgeInsets.all(16),
                        child: _buildSlotDetails(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            isExpanded.value = !isExpanded.value;
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total to Pay',
                                    style: Get.textTheme.bodyMedium!.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Total Slots: ${_getGroupedSlotsCount()}',
                                    style: Get.textTheme.bodySmall!.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹ ${_getSelectedSlotAmount()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          width: Get.width * 0.81,
                          height: 55,
                          gradientColors: [Colors.white, Colors.white, Colors.white],
                          onTap: () async {
                            isProcessing.value = true;

                            final success = await controller.processSlotHistoryForPayment();
                            if (!success) {
                              isProcessing.value = false;
                              return;
                            }

                            if (!Get.isRegistered<CartController>()) {
                              Get.put(CartController());
                            }
                            final cartController = Get.find<CartController>();
                            cartController.totalPrice.value = _getSelectedSlotAmount();

                            final paymentController = Get.put(PaymentMethodController(), permanent: false);

                            try {
                              await paymentController.createInitialBooking();

                              if (controller.hasCalledSlotHistoryAPI.value) {
                                await controller.cleanupOnBack();
                                controller.hasCalledSlotHistoryAPI.value = false;
                              }
                            } catch (e) {
                              CustomLogger.logMessage(msg: "Failed to prepare booking. Please try again.", level: LogLevel.debug);
                            } finally {
                              isProcessing.value = false;
                            }
                          },
                          child: isProcessing.value
                              ? LoadingAnimationWidget.waveDots(
                            color: AppColors.blackColor,
                            size: 45,
                          ).paddingOnly(right: 40)
                              : Text(
                            "Pay Now",
                            style: Get.textTheme.headlineLarge!.copyWith(
                              color: AppColors.secondaryColor,
                              fontSize: 16,
                            ),
                          ).paddingOnly(right: 40),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
          // Both halves selected - create one consolidated entry with full slot info
          final firstSelection = slotSelections.first;
          final totalAmount = slotSelections.fold<int>(0, (sum, sel) => sum + (sel['amount'] as int? ?? 0));
          consolidatedSelections.add({
            'slot': firstSelection['slot'],
            'amount': totalAmount,
            'dateTime': firstSelection['dateTime'],
            'courtId': firstSelection['courtId'],
            'date': firstSelection['date'],
            'isHalfSlot': false, // Mark as full slot since both halves are selected
            'isFirstHalf': true,
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

        // Find consecutive slots (considering half-slots)
        for (var j = i + 1; j < consolidatedSelections.length; j++) {
          final currentSelection = consolidatedSelections[j - 1];
          final nextSelection = consolidatedSelections[j];

          final currentSlot = currentSelection['slot'] as Slots;
          final nextSlot = nextSelection['slot'] as Slots;

          final currentIsHalf = currentSelection['isHalfSlot'] as bool? ?? false;
          final currentIsFirst = currentSelection['isFirstHalf'] as bool? ?? true;
          final nextIsHalf = nextSelection['isHalfSlot'] as bool? ?? false;
          final nextIsFirst = nextSelection['isFirstHalf'] as bool? ?? true;

          final currentTime = _parseTimeToMinutes(currentSlot.time ?? '');
          final nextTime = _parseTimeToMinutes(nextSlot.time ?? '');

          // Calculate actual end time of current slot
          final currentSlotDuration = currentSlot.duration ?? 60;
          int currentEndTime = currentTime;
          if (currentSlotDuration == 90) {
            currentEndTime += 90; // 90-minute slot
          } else if (currentIsHalf) {
            currentEndTime += currentIsFirst ? 30 : 60; // First half ends at +30, second half ends at +60
          } else {
            currentEndTime += 60; // Full slot
          }

          // Calculate actual start time of next slot
          int nextStartTime = nextTime;
          if (nextIsHalf && !nextIsFirst) {
            nextStartTime += 30; // Second half starts at +30
          }

          // Check if slots are consecutive
          if (currentEndTime == nextStartTime) {
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
          // For single slot, check if it's a half slot and display start-end time
          final selection = consecutiveGroup.first;
          final slot = selection['slot'] as Slots;
          final isHalfSlot = selection['isHalfSlot'] as bool? ?? false;
          final isFirstHalf = selection['isFirstHalf'] as bool? ?? true;
          final slotDuration = slot.duration ?? 60;

          // Handle 90-minute slots
          if (slotDuration == 90) {
            try {
              final cleanTime = (slot.time ?? '').trim().toLowerCase();
              final parts = cleanTime.split(' ');
              if (parts.length == 2) {
                final timePart = parts[0];
                final period = parts[1];
                final timeParts = timePart.split(':');
                int hour = int.tryParse(timeParts[0]) ?? 0;
                int minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

                if (period == 'pm' && hour != 12) hour += 12;
                if (period == 'am' && hour == 12) hour = 0;

                // Calculate end time (90 minutes later)
                int endHour = hour;
                int endMinute = minute + 90;
                while (endMinute >= 60) {
                  endHour += 1;
                  endMinute -= 60;
                }

                // Format start time
                String startPeriod = hour >= 12 ? 'PM' : 'AM';
                int displayStartHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                String formattedStart = '$displayStartHour:${minute.toString().padLeft(2, '0')} $startPeriod';

                // Format end time
                String endPeriod = endHour >= 12 ? 'PM' : 'AM';
                int displayEndHour = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
                String formattedEnd = '$displayEndHour:${endMinute.toString().padLeft(2, '0')} $endPeriod';

                timeRange = '$formattedStart - $formattedEnd';
              } else {
                timeRange = slot.time ?? '';
              }
            } catch (e) {
              timeRange = slot.time ?? '';
            }
          } else {
            // Use the existing method for 30/60 minute slots
            timeRange = controller.formatTimeRangeWithDuration(
              firstSlot.time ?? '',
              isHalfSlot: isHalfSlot,
              isFirstHalf: isFirstHalf,
            );
          }
        } else {
          // For consecutive slots, calculate total duration from all selections
          final startTime = firstSlot.time ?? '';
          final firstSelection = consecutiveGroup.first;
          final lastSelection = consecutiveGroup.last;

          final firstIsHalf = firstSelection['isHalfSlot'] as bool? ?? false;
          final firstIsFirst = firstSelection['isFirstHalf'] as bool? ?? true;
          final lastIsHalf = lastSelection['isHalfSlot'] as bool? ?? false;
          final lastIsFirst = lastSelection['isFirstHalf'] as bool? ?? true;

          // Calculate total duration
          int totalDuration = 0;
          for (var selection in consecutiveGroup) {
            final slot = selection['slot'] as Slots;
            final isHalf = selection['isHalfSlot'] as bool? ?? false;
            final slotDuration = slot.duration ?? 60;

            if (slotDuration == 90) {
              totalDuration += 90;
            } else {
              totalDuration += isHalf ? 30 : 60;
            }
          }

          // Parse start time
          try {
            final cleanTime = startTime.trim().toLowerCase();
            final parts = cleanTime.split(' ');
            if (parts.length == 2) {
              final timePart = parts[0];
              final period = parts[1];
              final timeParts = timePart.split(':');
              int hour = int.tryParse(timeParts[0]) ?? 0;
              int minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

              if (period == 'pm' && hour != 12) hour += 12;
              if (period == 'am' && hour == 12) hour = 0;

              // Adjust start time if first selection is second half
              if (firstIsHalf && !firstIsFirst) {
                minute += 30;
                if (minute >= 60) {
                  hour += 1;
                  minute -= 60;
                }
              }

              // Calculate end time
              int endHour = hour;
              int endMinute = minute + totalDuration;
              while (endMinute >= 60) {
                endHour += 1;
                endMinute -= 60;
              }

              // Format start time
              String startPeriod = hour >= 12 ? 'PM' : 'AM';
              int displayStartHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
              String formattedStart = '$displayStartHour:${minute.toString().padLeft(2, '0')} $startPeriod';

              // Format end time
              String endPeriod = endHour >= 12 ? 'PM' : 'AM';
              int displayEndHour = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
              String formattedEnd = '$displayEndHour:${endMinute.toString().padLeft(2, '0')} $endPeriod';

              timeRange = '$formattedStart - $formattedEnd';
            } else {
              timeRange = startTime;
            }
          } catch (e) {
            timeRange = startTime;
          }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${entry['date']} ${entry['timeRange']}',
                        style: Get.textTheme.labelSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   '',
                      //   style: Get.textTheme.labelSmall!.copyWith(
                      //     color: Colors.white.withValues(alpha: 0.9),
                      //     fontWeight: FontWeight.w500,
                      //     fontSize: 12,
                      //   ),
                      // ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry['clubName']} - ${entry['courtName']}',
                        style: Get.textTheme.labelSmall!.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                      final userId = storage.read("userId")??"";
                      slotsToDelete.add({
                        "slotId": slotId,
                        "courtId": courtId,
                        "bookingDate": dateString,
                        "time": slot.time ?? '',
                        "bookingTime": slot.time ?? '',
                        "duration": duration,
                        "userId":userId
                      });
                    }

                    await controller.deleteSlotHistory(slots: {"slots": slotsToDelete});

                    for (var selection in selections) {
                      final slot = selection['slot'] as Slots;
                      final courtId = selection['courtId'] as String;
                      controller.realCourtSelections.removeWhere((key, value) =>
                      (value['slot'] as Slots).sId == slot.sId && value['courtId'] == courtId);
                      // Only remove from selectedSlots if no other courts have this slot selected
                      final hasOtherCourtWithSameSlot = controller.realCourtSelections.values.any((value) =>
                      (value['slot'] as Slots).sId == slot.sId && value['courtId'] != courtId);
                      if (!hasOtherCourtWithSameSlot) {
                        controller.selectedSlots.removeWhere((s) => s.sId == slot.sId);
                      }
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

  int _getSelectedSlotAmount() {
    if (controller.realCourtSelections.isEmpty) return 0;

    // Sum all selected slot amounts from API
    int totalAmount = 0;
    for (var selection in controller.realCourtSelections.values) {
      final slot = selection['slot'] as Slots;
      totalAmount += slot.amount ?? 0;
    }
    return totalAmount;
  }

  int _getGroupedSlotsCount() {
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
    int totalEntries = 0;

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
          // Both halves selected - create one consolidated entry with full slot info
          final firstSelection = slotSelections.first;
          final totalAmount = slotSelections.fold<int>(0, (sum, sel) => sum + (sel['amount'] as int? ?? 0));
          consolidatedSelections.add({
            'slot': firstSelection['slot'],
            'amount': totalAmount,
            'dateTime': firstSelection['dateTime'],
            'courtId': firstSelection['courtId'],
            'date': firstSelection['date'],
            'isHalfSlot': false, // Mark as full slot since both halves are selected
            'isFirstHalf': true,
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

      // Group consecutive slots (same logic as _buildSlotDetails)
      var i = 0;
      while (i < consolidatedSelections.length) {
        final consecutiveGroup = [consolidatedSelections[i]];

        // Find consecutive slots (considering half-slots)
        for (var j = i + 1; j < consolidatedSelections.length; j++) {
          final currentSelection = consolidatedSelections[j - 1];
          final nextSelection = consolidatedSelections[j];

          final currentSlot = currentSelection['slot'] as Slots;
          final nextSlot = nextSelection['slot'] as Slots;

          final currentIsHalf = currentSelection['isHalfSlot'] as bool? ?? false;
          final currentIsFirst = currentSelection['isFirstHalf'] as bool? ?? true;
          final nextIsHalf = nextSelection['isHalfSlot'] as bool? ?? false;
          final nextIsFirst = nextSelection['isFirstHalf'] as bool? ?? true;

          final currentTime = _parseTimeToMinutes(currentSlot.time ?? '');
          final nextTime = _parseTimeToMinutes(nextSlot.time ?? '');

          // Calculate actual end time of current slot
          final currentSlotDuration = currentSlot.duration ?? 60;
          int currentEndTime = currentTime;
          if (currentSlotDuration == 90) {
            currentEndTime += 90; // 90-minute slot
          } else if (currentIsHalf) {
            currentEndTime += currentIsFirst ? 30 : 60; // First half ends at +30, second half ends at +60
          } else {
            currentEndTime += 60; // Full slot
          }

          // Calculate actual start time of next slot
          int nextStartTime = nextTime;
          if (nextIsHalf && !nextIsFirst) {
            nextStartTime += 30; // Second half starts at +30
          }

          // Check if slots are consecutive
          if (currentEndTime == nextStartTime) {
            consecutiveGroup.add(consolidatedSelections[j]);
          } else {
            break;
          }
        }

        // Each consecutive group counts as one entry in the order summary
        totalEntries++;
        i += consecutiveGroup.length;
      }
    }

    return totalEntries;
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

  String _formatTimeForDisplay(String time) {
    try {
      final cleanTime = time.trim().toLowerCase();
      final parts = cleanTime.split(' ');
      if (parts.length != 2) return time;

      final timePart = parts[0];
      final period = parts[1];

      final timeParts = timePart.split(':');
      final hour = timeParts[0];

      return '$hour$period';
    } catch (e) {
      return time;
    }
  }

  void _loadMoreCourts() {
    final courtsByDuration = controller.courtsByDuration.value;
    if (courtsByDuration?.data != null) {
      final totalCourts = courtsByDuration!.data!.length;
      if (displayedCourtsCount.value < totalCourts) {
        displayedCourtsCount.value = (displayedCourtsCount.value + 10).clamp(0, totalCourts);
      }
    }
  }

  void _scrollToAvailableCourts() {
    final context = availableCourtsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

}

class ChangeLocationBottomSheet extends StatelessWidget {
  final BookACourtController controller = Get.put(BookACourtController());
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