import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/presentations/bottomnav/bottom_nav_controller.dart';
import 'package:padel_mobile/presentations/drawer/zoom_drawer_controller.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_screen.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/presentations/notification/notification_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:padel_mobile/presentations/home/widget/custom_skelton_loader.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/presentations/booking/booking_controller.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/widgets/semi_circle_progress_bar.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_screen.dart';
import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import '../../data/request_models/home_models/get_club_name_model.dart';
import '../../data/request_models/booking/boking_history_model.dart';
import 'dart:developer';
class MainHomeScreen extends StatelessWidget {
  final MainHomeController controller = Get.put(MainHomeController());
  final WalletController walletController = Get.put(WalletController());
  final storage = GetStorage();

  MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    walletController.fetchWallet();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: primaryAppBar(
        toolbarHeight: 70,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backGroundColor: AppColors.primaryColor,
        showLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            // Drawer menu icon
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white, size: 26),
              onPressed: () {
                final drawerController = Get.find<CustomZoomDrawerController>();
                drawerController.toggleDrawer();
              },
            ),
            // Space between icon and title
            const SizedBox(width: 0),
            // Existing title widget
            Expanded(child: _buildAppBarTitle(context)),
          ],
        ),
        action: [
          GestureDetector(
            onTap: () {
              Get.toNamed(RoutesName.notification);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                  Icon(
                    Icons.notifications,
                    color: AppColors.whiteColor,
                    size: 25,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Obx(() {
                    final count = Get.find<NotificationController>()
                        .unreadNotificationCount
                        .value;
                    if (count == 0) return const SizedBox.shrink();

                    return Container(
                      height: 16,
                      width: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ).paddingOnly(right: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: ()=>Get.toNamed(RoutesName.wallet),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7,vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,

                  border: Border.all(
                    color: AppColors.whiteColor,
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(Assets.imagesIcWallet2,height: 20,width: 20,).paddingOnly(right: 4),
                    Obx(() => Text(
                      formatWalletAmount(walletController.walletBalance.value ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.whiteColor,
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ),
        ],
        context: context,
      ),
      body: Column(
        children: [
          // Sport Tab Selector
          _buildSportTabSelector(),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              color: Colors.white,
              onRefresh: () async {
                final locationId = controller.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
                await controller.homeController.fetchBookings(
                  categoryId: controller.selectedCategoryId.value,
                  locationId: locationId,
                );
                await controller.homeController.fetchClubs(
                  isRefresh: true,
                  categoryId: controller.selectedCategoryId.value,
                  locationId: locationId,
                );
                await controller.fetchOpenMatches();
                await controller.fetchNearCityPlayers();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    _banner(),
                    const SizedBox(height: 16),
                    _quickActions(),

                    _bookingSection(),

                    Obx(() {
                      if (controller.selectedSportTab.value == 0) {
                        return Column(
                          children: [
                            const SizedBox(height: 15),
                            statsDashboard(),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                      return const SizedBox(height: 20);
                    }),
                    _sectionTitle("Courts Near you", () {
                      Get.toNamed(RoutesName.home);
                    }),
                    _courtCard(),
                    const SizedBox(height: 15),


                    Obx(() {
                      if (controller.selectedSportTab.value == 0) {
                        return Column(
                          children: [
                            _sectionTitle("Top players near you", () {
                              Get.to(()=>LeaderboardScreen(buttonType: "drawer",));
                            }),
                            _players(),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Obx(() {
                      final matches = controller.openMatches.value?.data ?? [];
                      if (matches.isEmpty && !controller.isLoadingOpenMatches.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _sectionTitle("Open Match", () {
                            Get.toNamed(RoutesName.openMatchForAllCourts);
                          }).paddingOnly(bottom: 8),
                          _openMatchesSection(),
                          const SizedBox(height: 15),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// SPORT TAB SELECTOR
  Widget _buildSportTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Obx(() => Row(
        children: [
          // Padel Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.onSportTabChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: controller.selectedSportTab.value == 0
                      ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFEEF2FF),
                      const Color(0xFFE0E7FF),
                    ],
                  )
                      : null,
                  color: controller.selectedSportTab.value == 0
                      ? null
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: controller.selectedSportTab.value == 0
                      ? Border.all(
                    color: const Color(0xFF3B5BDB),
                    width: 1.5,
                  )
                      : null,
                  boxShadow: controller.selectedSportTab.value == 0
                      ? [
                    BoxShadow(
                      color: const Color(0xFF3B5BDB).withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: -1,
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      Assets.imagesIcPadel,
                      height: 18, // Add this line - adjust value as needed
                      color: controller.selectedSportTab.value == 0
                          ? const Color(0xFF3B5BDB)
                          : const Color(0xFF252525),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Padel',
                      style: TextStyle(
                        color: controller.selectedSportTab.value == 0
                            ? const Color(0xFF3B5BDB)
                            : const Color(0xFF252525),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pickleball Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.onSportTabChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: controller.selectedSportTab.value == 1
                      ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFEEF2FF),
                      const Color(0xFFE0E7FF),
                    ],
                  )
                      : null,
                  color: controller.selectedSportTab.value == 1
                      ? null
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: controller.selectedSportTab.value == 1
                      ? Border.all(
                    color: const Color(0xFF3B5BDB),
                    width: 1.5,
                  )
                      : null,
                  boxShadow: controller.selectedSportTab.value == 1
                      ? [
                    BoxShadow(
                      color: const Color(0xFF3B5BDB).withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: -1,
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      Assets.imagesIcPickleball,
                      height: 18, // Add this line - adjust value as needed
                      color: controller.selectedSportTab.value == 1
                          ? const Color(0xFF3B5BDB)
                          : const Color(0xFF252525),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pickleball',
                      style: TextStyle(
                        color: controller.selectedSportTab.value == 1
                            ? const Color(0xFF3B5BDB)
                            : const Color(0xFF252525),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
  Widget _buildAppBarTitle(BuildContext context) {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      if (controller.profileController.isLoading.value) {
        return Container(
          width: 120,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }

      final name =
          profile?.response?.name?.capitalizeFirst?.split(' ').first ?? "";
      final displayName = (name.trim().isEmpty) ? 'Guest' : name;
      final location = profile?.response?.city?.name ?? "";

      return SizedBox(
        width: Get.width * 0.34,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: AppStrings.hello,
                    style: Get.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 15),
                  ),
                  TextSpan(
                    text: "$displayName!",
                    style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(-3, 0),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 14),
                  Text(
                    location,
                    style: Get.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).paddingOnly(left: 5);
    });
  }

  /// BOOKING SECTION
  Widget _bookingSection() {
    return Obx(() {
      final homeController = controller.homeController;
      
      // Show shimmer while loading
      if (homeController.isLoadingBookings.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
          child: bookingShimmer(),
        );
      }

      final bookings = homeController.bookings.value?.data ?? [];

      if (bookings.isEmpty) {
        return SizedBox.shrink();
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    AppStrings.yourBooking,
                    style: Get.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final bottomNavController =
                      Get.find<BottomNavigationController>();
                      bottomNavController.updateIndex(1);
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Text(
                        "See all",
                        style: Get.textTheme.labelLarge!
                            .copyWith(color: AppColors.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _clubTicketList(),
          ],
        ).paddingOnly(top: 10);
      }
    });
  }

  Widget _clubTicketList() {
    return Obx(() {
      final allBookings = controller.homeController.bookings.value?.data ?? [];
      final booking = allBookings.where((b) => b.isOpenMatch != true).toList();
      
      if (booking.isEmpty) {
        return SizedBox.shrink();
      }
      
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          itemCount: booking.length,
          itemBuilder: (context, index) =>
              _buildBookingCard(context, booking[index]),
        ),
      );
    });
  }

  Widget _buildBookingCard(BuildContext context, BookingHistoryData b) {
    final club = b.registerClubId;
    final isOngoing = controller.homeController.isBookingOngoing(b);

    return GestureDetector(
      onTap: () {
        if (!controller.homeController.isCheckingScoreboard.value) {
          final id = b.bookingType == "openMatch" ? b.openMatchId?.sId : b.sId;
          if (id != null && id.isNotEmpty) {
            controller.homeController.createScoreBoard(bookingId: id);
          }
        }
      },
      child: Obx(() {
        final id = b.bookingType == "openMatch" ? b.openMatchId?.sId : b.sId;
        final isLoading =
            controller.homeController.loadingBookingId.value == id;
        return Stack(
          children: [
            Container(
              width: 235,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOngoing
                      ? Colors.transparent
                      : b.bookingType == "normal"
                      ? Color(0xffC6F6D5)
                      : Color(0xff9EBAFF),
                  width: isOngoing ? 2 : 1,
                ),
                gradient: LinearGradient(
                  colors: isOngoing
                      ? [
                    Color(0xffFFEBEE),
                    Color(0xffFFCDD2).withValues(alpha: 0.3)
                  ]
                      : b.bookingType == "normal"
                      ? [
                    Color(0xffF0FFF4),
                    Color(0xffC6F6D5).withValues(alpha: 0.3)
                  ]
                      : [
                    Color(0xffF3F7FF),
                    Color(0xff9EBAFF).withValues(alpha: 0.3)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _bookingImage(club),
                      _bookingInfo(context, club),
                      _bookingRatingArrow(context),
                    ],
                  ),
                  _bookingTimeInfo(context, b, isOngoing),
                ],
              ),
            ),

            // LIVE indicator badge
            if (isOngoing)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (isLoading)
              Container(
                width: 235,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: LoadingAnimationWidget.waveDots(
                    color: AppColors.whiteColor,
                    size: 30,
                  ),
                ),
              ),
          ],
        );
      }).paddingOnly(right: 10),
    );
  }

  Widget _bookingImage(RegisterClubId? club) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greyColor),
      ),
      child: ClipOval(
        child: (club?.courtImage != null &&
            club!.courtImage!.isNotEmpty)
            ? CachedNetworkImage(
          imageUrl: club.courtImage![0],
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              LoadingWidget(color: AppColors.primaryColor),
          errorWidget: (_, __, ___) =>
              Image.asset(Assets.imagesImgHomeLogo),
        )
            : Image.asset(
          Assets.imagesImgHomeLogo,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _bookingInfo(BuildContext context, RegisterClubId? club) {
    // Extract city from locations array based on locationId
    String cityName = "N/A";
    if (club?.locations != null && club!.locations!.isNotEmpty) {
      cityName = club.locations![0].city?.capitalizeFirst ?? "N/A";
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: Get.width * 0.27,
          child: Text(
            club?.clubName ?? "N/A",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.blackColor, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            Image.asset(Assets.imagesIcLocation,
                scale: 3, color: AppColors.blackColor),
            const SizedBox(width: 2),
            SizedBox(
              width: Get.width * 0.3,
              child: Text(
                cityName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.blackColor, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ).paddingOnly(left: 6);
  }

  Widget _bookingRatingArrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.secondaryColor, size: 13),
            Text("0", style: Theme.of(context).textTheme.bodySmall),
          ],
        ).paddingOnly(bottom: 20),
      ],
    );
  }

  Widget _bookingTimeInfo(BuildContext context, BookingHistoryData b, bool isOngoing) {
    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                controller.homeController.formatDate(b.bookingDate),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: isOngoing
                      ? Colors.red.shade700
                      : AppColors.blackColor,
                ),
              ),
              if (b.startTime != null && b.endTime != null)
                Container(
                  color: Colors.transparent,
                  width: Get.width*0.25,
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    "${b.startTime ?? ""} - ${b.endTime ?? ""}",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isOngoing
                          ? Colors.red.shade700
                          : AppColors.blackColor,
                      fontSize: 11,
                    ),
                  ).paddingOnly(left: 5),
                ),
            ],
          ),
          Text(
            "(${b.duration ?? 0}m)",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color:
              isOngoing ? Colors.red.shade700 : AppColors.blackColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).paddingOnly(bottom: 2);
  }

  Widget _banner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 140,
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: PageView.builder(
            controller: controller.pageController,
            onPageChanged: (index) {
              controller.currentBannerIndex.value = index % controller.bannerImages.length;
            },
            itemBuilder: (context, index) {
              final actualIndex = index % controller.bannerImages.length;
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(controller.bannerImages[actualIndex]),
                    fit: BoxFit.cover,
                    alignment: Alignment(0, -0.3),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                          offset: Offset(0, -5),
                          child: Text("Discover, Book",style: Get.textTheme.titleMedium!.copyWith(color: Colors.white,))),
                      Transform.translate(
                          offset: Offset(0, -10),
                          child: Text("and Play",style: Get.textTheme.titleMedium!.copyWith(color: Colors.white,))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => controller.onBannerTap(actualIndex),
                        child: Container(
                          width: Get.width * 0.35,
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "BOOK NOW!",
                                style: Get.textTheme.titleSmall!.copyWith(fontSize: 12,fontWeight: FontWeight.w600),
                              ).paddingOnly(left: 10),
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryColor,
                                child: const Icon(Icons.arrow_forward, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// QUICK ACTIONS
  Widget _quickActions() {
    final items = [
      {
        "icon": Assets.imagesIcBookACourtNew,
        "title": "Find a Court",
        "action": "book",
        "boxSize": 70.0,
        "iconSize": 34.0,
        "offset": Offset(0, 3)
      },
      {
        "icon": Assets.imagesIcOpenMatchNew,
        "title": "Find a Game",
        "action": "match",
        "boxSize": 70.0,
        "iconSize": 34.0,
        "offset": Offset(0, 4)
      },
      {
        "icon": Assets.imagesIcFindAPlayer,
        "title": "Find a Player",
        "action": "player",
        "boxSize": 70.0,
        "iconSize": 40.0,
        "offset": Offset(0, 4)
      },
      {
        "icon": Assets.imagesIcAmericanoNew,
        "title": "Americano",
        "action": "americano",
        "boxSize": 70.0,
        "iconSize": 34.0,
        "offset": Offset(0, 3)
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((e) {
        final double boxSize = e["boxSize"] as double;
        final double iconSize = e["iconSize"] as double;
        final Offset offset = e["offset"] as Offset;

        return GestureDetector(
          onTap: () => _handleQuickAction(e["action"] as String),
          child: Column(
            children: [
              Container(
                height: boxSize,
                width: boxSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3F56D6),
                      Color(0xFF2B44C4),
                    ],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background circle glow
                    Positioned(
                      top: -boxSize * 0.35,
                      left: -boxSize * 0.35,
                      child: Container(
                        height: boxSize * 1.3,
                        width: boxSize * 1.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),

                    // Icon
                    Center(
                      child: Transform.translate(
                        offset: offset,
                        child: SvgPicture.asset(
                          e["icon"] as String,
                          width: iconSize,
                          height: iconSize,
                        ),
                      ),
                    ),

                    // 🎀 Perfect corner ribbon
                    if (e["action"] == "americano" || e["action"] == "player")
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SizedBox(
                          width: boxSize,
                          height: boxSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Diagonal strip
                                Positioned(
                                  top: 6,
                                  left: -28,
                                  child: Transform.rotate(
                                    angle: -0.685398, // -45°
                                    child: Container(
                                      width: 90,
                                      height: 14,
                                      alignment: Alignment.center,
                                      color: Colors.orange,
                                      child: const Text(
                                        "COMING SOON",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e["title"] as String,
                style: Get.textTheme.labelSmall!.copyWith(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _handleQuickAction(String action) {
    if (Get.isSnackbarOpen) return;

    switch (action) {
      case 'book':
        Get.toNamed(RoutesName.bookACourt);
        break;
      case 'match':
        final categoryId = controller.selectedCategoryId.value;
        final locationId = controller.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
        Get.toNamed(RoutesName.openMatchForAllCourts, arguments: {
          'categoryId': categoryId,
          'location': locationId,
        });
        break;
      case 'americano':
      // SnackBarUtils.showInfoSnackBar("Americano tournaments coming soon!");
        break;
      case 'player':
      // SnackBarUtils.showInfoSnackBar("Find a Player feature coming soon!");
        break;
    }
  }

  /// SECTION TITLE
  Widget _sectionTitle(String title, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: Get.textTheme.headlineMedium),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              color: Colors.transparent,
              child: Text("View all",
                  style: Get.textTheme.labelLarge!
                      .copyWith(color: AppColors.primaryColor)),
            ),
          ),
        ],
      ),
    );
  }

  /// COURT CARD
  Widget _courtCard() {
    return Obx(() {
      final homeController = controller.homeController;

      if (homeController.isLoadingClub.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CarouselSlider.builder(
            itemCount: 3,
            itemBuilder: (context, index, realIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.grey[300],
                  ),
                  child: const Center(
                    child: LoadingWidget(color: AppColors.primaryColor),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 260,
              viewportFraction: 0.78,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              autoPlay: false,
            ),
          ),
        );
      }

      final courts = homeController.courtsList;

      if (courts.isEmpty) {
        return const SizedBox(height: 260);
      }

      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CarouselSlider.builder(
          itemCount: courts.length > 5 ? 5 : courts.length,
          itemBuilder: (context, index, realIndex) {
            final court = courts[index];
            return _buildCourtCarouselCard(context, court);
          },
          options: CarouselOptions(
            height: 300,
            viewportFraction: 0.78,
            enlargeCenterPage: true,
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
            enableInfiniteScroll: courts.length > 1,
            autoPlay: courts.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
          ),
        ),
      );
    });
  }

  Widget _buildCourtCarouselCard(BuildContext context, Courts court) {
    final courtDetails = court.courts?.isNotEmpty == true ? court.courts![0] : null;
    final courtImage = courtDetails?.courtImage?.isNotEmpty == true ? courtDetails!.courtImage![0] : null;
    final courtCount = courtDetails?.courtCount ?? 0;
    final features = courtDetails?.features ?? [];
    final locationDetails = court.locations?.isNotEmpty == true ? court.locations![0] : null;
    final city = locationDetails?.city ?? court.city ?? "N/A";
    final zipCode = locationDetails?.zipCode ?? court.zipCode ?? "";
    
    return GestureDetector(
      onTap: () {
        log("CLUB ID -> ${court.id}");
        log(" ID -> ${court.courts?[0].id??""}");
        if (court.id != null) {
          Get.delete<BookingController>();
          Get.toNamed(RoutesName.booking,
              arguments: {"data": court, "clubId": court.id, "sID":court.courts?[0].id??""});
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              /// IMAGE
              Positioned.fill(
                child: courtImage != null
                    ? CachedNetworkImage(
                  imageUrl: courtImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: LoadingWidget(color: AppColors.primaryColor),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 40),
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.photo, color: Colors.grey, size: 40),
                  ),
                ),
              ),

              /// BLACK GRADIENT
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              /// BLACK GRADIENT
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              /// CONTENT
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            color: Colors.transparent,
                            width: Get.width * 0.5,
                            child: Text(
                              court.clubName ?? "N/A",
                              style: Get.textTheme.titleMedium!
                                  .copyWith(color: Colors.white, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                "0",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              city,
                              style: Get.textTheme.bodySmall!
                                  .copyWith(color: Colors.white70, fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$courtCount Courts | ${features.isNotEmpty ? features.join(' | ') : 'Available'}",
                        style: Get.textTheme.bodySmall!
                            .copyWith(color: Colors.white70, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "Booking Price",
                            style: Get.textTheme.headlineLarge!.copyWith(
                                color: AppColors.secondaryColor, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            "₹ ${formatAmount(court.totalAmount ?? 0)}",
                            style: Get.textTheme.titleMedium!
                                .copyWith(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// PLAYERS
  Widget _players() {
    return Obx(() {
      if (controller.isLoadingPlayers.value) {
        return SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: LoadingWidget(color: AppColors.primaryColor),
              ),
            ),
          ),
        );
      }

      final players = controller.nearCityPlayers.value?.data?.leaderboard ?? [];

      if (players.isEmpty) {
        return SizedBox(
          height: 160,
          child: Center(
            child: Text(
              "No players found in your city",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return SizedBox(
        height: 160,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: players.length > 10 ? 10 : players.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final player = players[i];
            return Container(
              width: 120,
              padding: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.4),
                        spreadRadius: 1.5,
                        blurRadius: 5.0)
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.secondaryColor,
                    child: player.profilePic != null && player.profilePic!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: player.profilePic!,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 24,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) => CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondaryColor,
                        child: Text(
                          _getInitials(player.name ?? ""),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondaryColor,
                        child: Text(
                          _getInitials(player.name ?? ""),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                        : CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryColor,
                      child: Text(
                        _getInitials(player.name ?? ""),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -5),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.secondaryColor),
                      child: Text("${formatAmount(player.xpPoints ?? 0)} XP",
                          style: Get.textTheme.labelMedium!
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                  Text(
                    player.name?.capitalizeFirstChar() ?? "Unknown Player",
                    style: Get.textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ).paddingOnly(top: 10,bottom: 10);
          },
        ),
      );
    });
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "?";

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }

    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Widget statsDashboard() {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      final recentMatches = profile?.response?.recentMatches ?? [];

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _matchPlayedCard()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      _leaderboardCard(),
                      SizedBox(
                        height: 10,
                      ),
                      _xpCard(),
                    ],
                  ),
                ),
              ],
            ),
            if (recentMatches.isNotEmpty) ...[
              const SizedBox(height: 10),
              _recentMatches(),
            ],
          ],
        ),
      );
    });
  }

  Widget _matchPlayedCard() {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      final totalMatches = profile?.response?.totalMatchesPlayed ?? 0;
      final totalWins = profile?.response?.totalWins ?? 0;
      final winRatio = totalMatches > 0 ? (totalWins / totalMatches) : 0.0;
      final winPercentage = (winRatio * 100).round();

      return GestureDetector(
        onTap: () => Get.to(EditProfileUi(
          buttonType: "drawer",
        )),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              colors: [Color(0xffE9EFFF), Color(0xffE6EBFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              Transform.translate(
                  offset: Offset(-15, -16),
                  child: SvgPicture.asset(
                      Assets.imagesImgBackgroundPlayedMatch)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Match\nPlayed',
                        style: Get.textTheme.titleSmall!.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 17),
                      ),
                      Spacer(),
                      Text(
                        '$totalMatches',
                        style: Get.textTheme.titleLarge!
                            .copyWith(color: Color(0xff0E1E55), fontSize: 30),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 170,
                          height: 100,
                          child: CustomPaint(
                            painter: BlockSemiCirclePainter(
                              progress: winRatio,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                  offset: Offset(0, 4),
                                  child: Text('$winPercentage%',
                                      style: Get.textTheme.titleLarge)),
                              Text(
                                'Win Ratio',
                                style: Get.textTheme.headlineSmall!
                                    .copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _leaderboardCard() {
    return Obx(() {
      return GestureDetector(
        onTap: () => Get.to(LeaderboardScreen(
          buttonType: "drawer",
        )),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.secondaryColor.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xffE7F8EA), Color(0xffF1FFF4)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: Color(0xff2947C7),
                    size: 30,
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(controller.customerRank.value.toString(),
                        style: Get.textTheme.titleLarge!
                            .copyWith(color: Color(0xff0E1E55))),
                  ),
                ],
              ),
              Text('Leaderboard\nPosition',
                  style: Get.textTheme.titleSmall!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    });
  }

  Widget _xpCard() {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      final xpPoints = profile?.response?.xpPoints?.toInt() ?? 0;

      return GestureDetector(
        onTap: () => Get.toNamed(RoutesName.xpPoints),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xffEDF1FF), Color(0xffE6EBFF)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffDDE3FF),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Transform.translate(
                          offset: Offset(0, 2),
                          child:
                          Icon(Icons.star, color: Colors.green, size: 22)),
                      Text('$xpPoints',
                          style: Get.textTheme.titleLarge!
                              .copyWith(color: Color(0xff0E1E55))),
                    ],
                  ),
                  Text(
                    'XP Points',
                    style: Get.textTheme.headlineLarge!
                        .copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _recentMatches() {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      final recentMatches = profile?.response?.recentMatches ?? [];

      List<String> results = recentMatches.isNotEmpty ? recentMatches.cast<String>() : [];

      final displayResults = results.length > 5
          ? results.sublist(results.length - 5)
          : results;

      return Container(
        color: Colors.transparent,
        width: Get.width,
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.imagesIcPadelBall,
            ).paddingOnly(right: 10),
            Flexible(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF003AFF),
                      Color(0xFF07289A),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Text('Recent Matches',
                        style: Get.textTheme.headlineSmall!
                            .copyWith(color: Colors.white)),
                    const SizedBox(width: 8),
                    ...displayResults.map(
                          (e) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: e == 'W'
                                ? Colors.green
                                : e == 'L'
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SvgPicture.asset(
              Assets.imagesIcPadelBall,
            ).paddingOnly(left: 10),
          ],
        ),
      );
    });
  }

  /// OPEN MATCHES SECTION
  Widget _openMatchesSection() {
    return Obx(() {
      if (controller.isLoadingOpenMatches.value) {
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[300],
              ),
              child: const Center(
                child: LoadingWidget(color: AppColors.primaryColor),
              ),
            ),
          ),
        );
      }

      final matches = controller.openMatches.value?.data ?? [];
      if (matches.isEmpty) return const SizedBox.shrink();

      final displayMatches = matches.take(3).toList();

      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayMatches.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOpenMatchCard(displayMatches[index], index),
        ),
      );
    });
  }

  Widget _buildOpenMatchCard(OpenMatchBookingData data, int index) {
    final dayStr = DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(data.matchDate ?? ''));
    final dateOnlyStr = DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(data.matchDate ?? ''));
    final timeStr = data.openMatchStatus == "pending"
        ? "${data.startTime?.split(' ').first ?? ""}-${data.endTime ?? ""}"
        : "${data.bookingId?.startTime?.split(' ').first ?? ""}-${data.bookingId?.endTime ?? ""}";
    final clubName = data.clubId?.clubName ?? '-';
    
    // Extract location name from locations array matching locationId
    String locationName = "N/A";
    if (data.clubId?.locations != null && data.clubId!.locations!.isNotEmpty) {
      final matchingLocation = data.clubId!.locations!.firstWhere(
        (loc) => loc.sId == data.locationId,
        orElse: () => data.clubId!.locations!.first,
      );
      locationName = matchingLocation.city?.capitalizeFirst ?? "N/A";
    }

    final teamAPlayers = (data.teamA ?? []).take(2).toList();
    final teamBPlayers = (data.teamB ?? []).take(2).toList();

    return GestureDetector(
      onTap: () {
        final categoryId = controller.selectedCategoryId.value;
        final locationId = controller.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";
        Get.toNamed(RoutesName.openMatchForAllCourts, arguments: {
          'categoryId': categoryId,
          'locationId': locationId,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xffC8D6FB)),
          gradient: LinearGradient(
            colors: [Color(0xffF3F7FF), Color(0xff9EBAFF).withValues(alpha: 0.3)],
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SvgPicture.asset(
                index % 2 == 0 ? Assets.imagesImgOpenMatchBg : Assets.imagesImgOpenMatchGreenBg,
                height: 150,
                width: 150,
              ).paddingOnly(right: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$dayStr ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1c46a0),
                                ),
                              ),
                              TextSpan(
                                text: '$dateOnlyStr | $timeStr',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(
                              " ${data.skillLevel?.capitalizeFirst ?? 'Professional'} | ",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 2),
                            genderIcon(data.gender),
                            const SizedBox(width: 4),
                            Text(
                              data.gender?.capitalizeFirst ?? "Mixed Doubles",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // UPDATED PLAYER CIRCLES WITH OVERLAPPING EFFECT
                _buildOverlappingPlayerRow(teamAPlayers, teamBPlayers),

                const SizedBox(height: 10),
                Divider(color: Colors.grey, thickness: 0.1),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clubName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              Transform.translate(
                                offset: Offset(0, -1),
                                child: Image.asset(Assets.imagesIcLocation, scale: 2, color: AppColors.primaryColor),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locationName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, 2),
                      child: Text(
                        "₹ ${formatAmount(data.totalAmount ?? 0)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff1c46a0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// NEW METHOD: Creates overlapping player circles exactly like the image
// Replace the _buildOverlappingPlayerRow method with this:

  Widget _buildOverlappingPlayerRow(List<dynamic> teamAPlayers, List<dynamic> teamBPlayers) {
    return SizedBox(
      height: 44,
      child: SizedBox(
        width: Get.width, // Width for 4 overlapping circles (44 + 22 + 22 + 22)
        child: Stack(
          children: [
            // First player (Team A - Player 1)
            Positioned(
              left: 0,
              child: teamAPlayers.isNotEmpty
                  ? _buildFilledPlayerCircle(
                teamAPlayers[0].userId?.profilePic ?? "",
                teamAPlayers[0].userId?.name ?? "",
                teamAPlayers[0].userId?.lastName ?? "",
              )
                  : _buildEmptyPlayerCircle(),
            ),
            // Second player (Team A - Player 2)
            Positioned(
              left: 32, // Overlap by half
              child: teamAPlayers.length > 1
                  ? _buildFilledPlayerCircle(
                teamAPlayers[1].userId?.profilePic ?? "",
                teamAPlayers[1].userId?.name ?? "",
                teamAPlayers[1].userId?.lastName ?? "",
              )
                  : _buildEmptyPlayerCircle(),
            ),
            // Third player (Team B - Player 1)
            Positioned(
              left: 64, // Continue overlapping
              child: teamBPlayers.isNotEmpty
                  ? _buildFilledPlayerCircle(
                teamBPlayers[0].userId?.profilePic ?? "",
                teamBPlayers[0].userId?.name ?? "",
                teamBPlayers[0].userId?.lastName ?? "",
              )
                  : _buildEmptyPlayerCircle(),
            ),
            // Fourth player (Team B - Player 2)
            Positioned(
              left: 96, // Continue overlapping
              child: teamBPlayers.length > 1
                  ? _buildFilledPlayerCircle(
                teamBPlayers[1].userId?.profilePic ?? "",
                teamBPlayers[1].userId?.name ?? "",
                teamBPlayers[1].userId?.lastName ?? "",
              )
                  : _buildEmptyPlayerCircle(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFilledPlayerCircle(String? imageUrl, String name, String lastName) {
    final firstLetter = name.trim().isNotEmpty
        ? '${name.trim()[0].toUpperCase()}${lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : ''}'
        : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xffeaf0ff),
        child: ClipOval(
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Center(
              child: Text(
                firstLetter,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Text(
                firstLetter,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
              : Center(
            child: Text(
              firstLetter,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlayerCircle() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xffeaf0ff),
        child: Icon(Icons.add, color: AppColors.primaryColor, size: 20),
      ),
    );
  }

  String _getDay(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(ymd);
      return DateFormat('EEEE').format(parsed);
    } catch (_) {
      return ymd;
    }
  }

  String _getDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(ymd);
      return DateFormat('dd MMM').format(parsed);
    } catch (_) {
      return ymd;
    }
  }
}
