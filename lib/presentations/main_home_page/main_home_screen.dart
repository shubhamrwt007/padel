import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart'
    as LeagueModel;
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/presentations/bottomnav/bottom_nav_controller.dart';
import 'package:padel_mobile/presentations/drawer/zoom_drawer_controller.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_screen.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/widgets/find_a_player_screen.dart';
import 'package:padel_mobile/presentations/main_home_page/widgets/league_sponsor_widgets.dart';
import 'package:padel_mobile/presentations/main_home_page/widgets/seamless_banner_swiper.dart';
import 'package:padel_mobile/presentations/notification/notification_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:padel_mobile/presentations/home/widget/custom_skelton_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/presentations/booking/booking_controller.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/widgets/semi_circle_progress_bar.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_screen.dart';
import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';
import 'package:padel_mobile/presentations/tutorial/tutorial_screen.dart';
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
          IconButton(
            onPressed: () {
              Get.to(TutorialScreen(buttonType: "home"));
            },
            icon: Icon(
              CupertinoIcons.question_circle,
              size: 24,
              color: Colors.white,
            ),
          ),
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
                  child: Icon(
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
              onTap: () => Get.toNamed(RoutesName.wallet),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                    SvgPicture.asset(
                      Assets.imagesIcWallet2,
                      height: 20,
                      width: 20,
                    ).paddingOnly(right: 4),
                    Obx(
                      () => Text(
                        formatWalletAmount(
                          walletController.walletBalance.value,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
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
                final locationId =
                    controller
                        .profileController
                        .profileModel
                        .value
                        ?.response
                        ?.city
                        ?.sId ??
                    "68c94a94d72a6f9769712ff0";
                await controller.homeController.fetchBookings(
                  categoryId: controller.selectedCategoryId.value,
                  locationId: locationId,
                );
                await controller.homeController.fetchClubs(
                  isRefresh: true,
                  categoryId: controller.selectedCategoryId.value,
                  locationId: locationId,
                );
                await controller.fetchActiveLeagues();
                await controller.fetchScheduleMatches();
                await controller.fetchOpenMatches();
                await controller.fetchNearCityPlayers();
                await controller.profileController.fetchUserProfile();
                await controller.fetchPollResults();
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
                    _buildLeagueComingSoon(),
                    // _buildLeagueLiveMatch(),
                    _bookingSection(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Obx(() {
                        final profile =
                            controller.profileController.profileModel.value;
                        final recentMatches =
                            profile?.response?.recentMatches ?? [];

                        if (recentMatches.length >= 5) {
                          return Column(
                            children: [
                              const SizedBox(height: 15),
                              _recentMatches(),
                            ],
                          );
                        }

                        return const SizedBox.shrink();
                      }),
                    ),
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
                    Obx(() {
                      final courts = controller.homeController.courtsList;
                      if (courts.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _sectionTitle("Courts Near you", () {
                            Get.toNamed(RoutesName.home);
                          }),
                          const SizedBox(height: 8),
                          _courtCard(),
                          const SizedBox(height: 18),
                        ],
                      );
                    }),
                    Obx(() {
                      if (controller.selectedSportTab.value == 0) {
                        return Column(
                          children: [
                            _sectionTitle("Top players near you", () {
                              Get.to(
                                () => LeaderboardScreen(buttonType: "drawer"),
                              );
                            }),
                            const SizedBox(height: 5),
                            _players(),
                            const SizedBox(height: 5),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Obx(() {
                      final matches = controller.openMatches.value?.data ?? [];
                      if (matches.isEmpty &&
                          !controller.isLoadingOpenMatches.value) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _sectionTitle("Open Matches", () {
                            Get.toNamed(RoutesName.openMatchForAllCourts);
                          }).paddingOnly(bottom: 8),
                          const SizedBox(height: 5),
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.creamColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: Obx(() {
        final selected = controller.selectedSportTab.value;
        return Stack(
          children: [
            // Animated sliding pill background
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: selected == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF3B5BDB),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B5BDB).withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  height: 38,
                ),
              ),
            ),

            // Tab buttons row (on top of pill)
            Row(
              children: [
                // Padel Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.onSportTabChanged(0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      height: 38,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: selected == 0 ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: SvgPicture.asset(
                              Assets.imagesIcPadel,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                selected == 0
                                    ? const Color(0xFF3B5BDB)
                                    : const Color(0xFF252525),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              color: selected == 0
                                  ? const Color(0xFF3B5BDB)
                                  : const Color(0xFF252525),
                              fontSize: 14,
                              fontWeight: selected == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFamily: Get.textTheme.bodyMedium?.fontFamily,
                            ),
                            child: const Text('Padel'),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      height: 38,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: selected == 1 ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: SvgPicture.asset(
                              Assets.imagesIcPickleball,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                selected == 1
                                    ? const Color(0xFF3B5BDB)
                                    : const Color(0xFF252525),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              color: selected == 1
                                  ? const Color(0xFF3B5BDB)
                                  : const Color(0xFF252525),
                              fontSize: 14,
                              fontWeight: selected == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFamily: Get.textTheme.bodyMedium?.fontFamily,
                            ),
                            child: const Text('Pickleball'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
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
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: "$displayName!",
                    style: Get.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 15,
                    ),
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
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).paddingOnly(left: 5);
    });
  }

  Widget _buildSwootTitle(String? leagueName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [Text(leagueName ?? "", style: Get.textTheme.headlineMedium)],
      ),
    );
  }

  /// LEAGUE SECTION
  Widget _buildLeagueComingSoon() => _LeagueComingSoonWidget(
    controller: controller,
    buildLiveSlider: () => _buildLeagueLiveMatchSlider([]),
    buildUpcoming: () => _upcomingMatchCard(),
  );

  // Widget _buildSingleLeagueCard(LeagueModel.Data leagueData) {
  //   return GestureDetector(
  //     onTap: () {
  //       Get.toNamed(RoutesName.league, arguments: {
  //         'leagueId': leagueData.id,
  //         'leagueTitle': leagueData.leagueName,
  //       });
  //     },
  //     child: Container(
  //       width: Get.width,
  //       height: 163,
  //       margin: const EdgeInsets.symmetric(horizontal: 14),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.shade300,
  //             blurRadius: 8,
  //             spreadRadius: 2.3,
  //             offset: const Offset(0, 3),
  //           ),
  //         ],
  //       ),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(20),
  //         child: leagueData.mobileBanner != null && leagueData.mobileBanner!.isNotEmpty
  //             ? CachedNetworkImage(imageUrl: leagueData.mobileBanner!, fit: BoxFit.cover)
  //             : Image.asset(Assets.imagesImgLeagueComingSoon),
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildLeagueCarousel(List<LeagueModel.Data> leagues) {
  //   return _LeagueCarouselWidget(
  //     leagues: leagues,
  //     onPageChanged: (index) {
  //       controller.leagueCarouselIndex.value = index;
  //     },
  //   );
  // }

  Widget _buildLeagueLiveMatch() {
    return Obx(() {
      final scheduleData = controller.scheduleMatches.value?.data ?? [];
      final upcomingData = controller.upcomingMatches.value?.data ?? [];

      final allLiveMatches = scheduleData
          .expand((data) => data.matches ?? [])
          .toList();
      final allUpcomingMatches = upcomingData
          .expand((data) => data.matches ?? [])
          .toList();

      // If both live and upcoming are empty, show coming soon
      if (allLiveMatches.isEmpty &&
          allUpcomingMatches.isEmpty &&
          !controller.isLoadingScheduleMatches.value &&
          !controller.isLoadingUpcomingMatches.value) {
        return _buildLeagueComingSoon();
      }

      // Get league data from active leagues
      final leagues = controller.activeLeagues.value?.data ?? [];
      final currentLeague = leagues.isNotEmpty ? leagues.first : null;

      // Otherwise show the league section
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwootTitle(currentLeague?.leagueName),
          const SizedBox(height: 12),
          Obx(() {
            final scheduleData = controller.scheduleMatches.value?.data ?? [];
            final allMatches = scheduleData
                .expand((data) => data.matches ?? [])
                .toList();

            if (controller.isLoadingScheduleMatches.value) {
              return Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: LoadingWidget(color: AppColors.primaryColor),
                ),
              );
            }

            if (scheduleData.isEmpty || allMatches.isEmpty) {
              return _upcomingMatchCard();
            }

            return _buildLeagueLiveMatchSlider([]);
          }),
          if (currentLeague != null) ...[
            BuildLeagueTitleSponsor(league: currentLeague),
            BuildLeagueMoreSponsor(league: currentLeague),
          ],
          // _buildLeaguePointsTable(),
        ],
      ).paddingOnly(top: 10);
    });
  }

  Widget _buildLeagueLiveMatchSlider(List<Widget> cards) {
    return Obx(() {
      final scheduleData = controller.scheduleMatches.value?.data ?? [];

      if (controller.isLoadingScheduleMatches.value) {
        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
        );
      }

      if (scheduleData.isEmpty) return const SizedBox.shrink();

      final allMatches = scheduleData
          .expand((data) => data.matches ?? [])
          .toList();
      if (allMatches.isEmpty) return const SizedBox.shrink();

      final liveMatchCards = scheduleData.expand((data) {
        return (data.matches ?? []).map(
          (match) => _liveMatchCard(
            match,
            data.categoryType,
            data.matchId?.id,
            data.matchId?.setsWon,
          ),
        );
      }).toList();

      if (liveMatchCards.length == 1) return liveMatchCards.first;

      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: liveMatchCards.length,
            itemBuilder: (context, index, realIndex) => liveMatchCards[index],
            options: CarouselOptions(
              viewportFraction: 1,
              enableInfiniteScroll: false,
              enlargeCenterPage: false,
              autoPlay: false,
              height: 200,
              onPageChanged: (index, reason) {
                controller.leagueLiveCarouselIndex.value = index;
              },
            ),
          ),
          Obx(() {
            final idx = controller.leagueLiveCarouselIndex.value;
            if (idx >= liveMatchCards.length) {
              controller.leagueLiveCarouselIndex.value = 0;
            }
            final activeIndex = controller.leagueLiveCarouselIndex.value.clamp(
              0,
              liveMatchCards.length - 1,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(liveMatchCards.length, (i) {
                final isActive = i == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isActive ? 18 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryColor : Colors.black12,
                    borderRadius: BorderRadius.circular(50),
                  ),
                );
              }),
            );
          }),
          SizedBox(height: 10),
        ],
      );
    });
  }

  Widget _liveMatchCard(
    Matches? match,
    String? categoryType,
    String? matchId,
    SetsWon? setsWon,
  ) {
    if (match == null) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final leagueId =
                controller.activeLeagues.value?.data?.firstOrNull?.id ?? '';
            final leagueTitle =
                controller.activeLeagues.value?.data?.firstOrNull?.leagueName ??
                'League';
            Get.toNamed(
              RoutesName.league,
              arguments: {
                'leagueId': leagueId,
                'leagueTitle': leagueTitle,
                'initialTab': 0,
              },
            )?.then((_) {
              controller.fetchPollResults();
              controller.fetchScheduleMatches();
              controller.fetchActiveLeagues();
              controller.fetchLeaderBoard();
            });
          },
          child: Container(
            height: 170,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Stack(
              children: [
                Builder(
                  builder: (context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SvgPicture.asset(
                        Assets.imagesFipPromesisBg,
                        fit: BoxFit.cover,
                        width: Get.width,
                        alignment: AlignmentGeometry.topCenter,
                      ),
                    );
                  },
                ),
                Column(
                  children: [
                    /// LIVE TAG
                    _AnimatedLiveTag(),

                    /// SCORE ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _teamColumn(
                          match.teamA?.clubType ?? "Team A",
                          "https://i.pravatar.cc/150?img=1",
                          "https://i.pravatar.cc/150?img=2",
                          (match.teamA?.players?.isNotEmpty ?? false)
                              ? (match.teamA!.players![0].playerName ?? "")
                              : "Player 1",
                          (match.teamA?.players != null &&
                                  match.teamA!.players!.length > 1)
                              ? (match.teamA!.players![1].playerName ?? "")
                              : "Player 2",
                          AppColors.primaryColor,
                        ),

                        Transform.translate(
                          offset: Offset(0, -15),
                          child: Column(
                            children: [
                              Text(
                                categoryType ?? "",
                                style: Get.textTheme.labelMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${setsWon?.teamA ?? 0} : ${setsWon?.teamB ?? 0}",
                                style: Get.textTheme.titleLarge!.copyWith(
                                  color: AppColors.blackColor,
                                  fontSize: 42,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _teamColumn(
                          match.teamB?.clubType ?? "Team B",
                          "https://i.pravatar.cc/150?img=3",
                          "https://i.pravatar.cc/150?img=4",
                          (match.teamB?.players?.isNotEmpty ?? false)
                              ? (match.teamB!.players![0].playerName ?? "")
                              : "Player 1",
                          (match.teamB?.players != null &&
                                  match.teamB!.players!.length > 1)
                              ? (match.teamB!.players![1].playerName ?? "")
                              : "Player 2",
                          AppColors.secondaryColor,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _AnimatedWatchLiveButton(
                          onTap: () {
                            final leagueId =
                                controller
                                    .activeLeagues
                                    .value
                                    ?.data
                                    ?.firstOrNull
                                    ?.id ??
                                '';
                            final leagueTitle =
                                controller
                                    .activeLeagues
                                    .value
                                    ?.data
                                    ?.firstOrNull
                                    ?.leagueName ??
                                'League';
                            Get.toNamed(
                              RoutesName.league,
                              arguments: {
                                'leagueId': leagueId,
                                'leagueTitle': leagueTitle,
                                'initialTab': 0,
                              },
                            )?.then((_) {
                              controller.fetchPollResults();
                              controller.fetchScheduleMatches();
                              controller.fetchActiveLeagues();
                              controller.fetchLeaderBoard();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _upcomingMatchCard() {
    return Obx(() {
      if (controller.isLoadingUpcomingMatches.value) {
        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
        );
      }

      final scheduleData = controller.upcomingMatches.value?.data ?? [];
      if (scheduleData.isEmpty) return const SizedBox.shrink();

      final allMatches = scheduleData
          .expand((data) => data.matches ?? [])
          .toList();
      if (allMatches.isEmpty) return const SizedBox.shrink();

      final firstMatch = allMatches.first;
      final matchData = scheduleData.firstWhere(
        (data) => data.matches?.contains(firstMatch) ?? false,
        orElse: () => scheduleData.first,
      );

      final teamAPlayers = firstMatch.teamA?.players ?? [];
      final teamBPlayers = firstMatch.teamB?.players ?? [];

      String formatDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) return "TBD";
        try {
          final date = DateTime.parse(dateStr);
          final months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year}";
        } catch (e) {
          return dateStr;
        }
      }

      return GestureDetector(
        onTap: () {
          final leagueId =
              controller.activeLeagues.value?.data?.firstOrNull?.id ?? '';
          final leagueTitle =
              controller.activeLeagues.value?.data?.firstOrNull?.leagueName ??
              'League';
          Get.toNamed(
            RoutesName.league,
            arguments: {
              'leagueId': leagueId,
              'leagueTitle': leagueTitle,
              'initialTab': 1,
            },
          );
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            children: [
              Image.asset(
                Assets.imagesImgLeagueUpcomingMatch,
                fit: BoxFit.cover,
                width: Get.width,
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Upcoming",
                          style: Get.textTheme.labelMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ).paddingOnly(top: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _teamColumn(
                        firstMatch.teamA?.clubType ?? "Team A",
                        "https://i.pravatar.cc/150?img=1",
                        "https://i.pravatar.cc/150?img=2",
                        teamAPlayers.isNotEmpty
                            ? (teamAPlayers[0].playerName ?? "Player 1")
                            : "Player 1",
                        teamAPlayers.length > 1
                            ? (teamAPlayers[1].playerName ?? "Player 2")
                            : "Player 2",
                        AppColors.primaryColor,
                      ),
                      Transform.translate(
                        offset: Offset(0, -8),
                        child: Column(
                          children: [
                            Text(
                              matchData.categoryType ?? "",
                              style: Get.textTheme.labelMedium,
                            ),
                            SizedBox(height: 8),
                            SvgPicture.asset(Assets.imagesImgVsUpcoming),
                          ],
                        ),
                      ),
                      _teamColumn(
                        firstMatch.teamB?.clubType ?? "Team B",
                        "https://i.pravatar.cc/150?img=3",
                        "https://i.pravatar.cc/150?img=4",
                        teamBPlayers.isNotEmpty
                            ? (teamBPlayers[0].playerName ?? "Player 1")
                            : "Player 1",
                        teamBPlayers.length > 1
                            ? (teamBPlayers[1].playerName ?? "Player 2")
                            : "Player 2",
                        AppColors.primaryColor,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // Get.toNamed(RoutesName.liveAndCompleteLeagueMatch, arguments: {
                      //   "matchType": "upcoming"
                      // });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        formatDate(matchData.date),
                        style: Get.textTheme.labelMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).paddingOnly(bottom: 10),
      );
    });
  }

  Widget _teamColumn(
    String team,
    String img1,
    String img2,
    String name1,
    String name2,
    Color color,
  ) {
    return SizedBox(
      width: 130,
      child: Column(
        children: [
          /// TEAM LABEL
          Container(
            width: Get.width * 0.2,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Text(
              overflow: TextOverflow.ellipsis,
              team,
              style: Get.textTheme.headlineMedium!.copyWith(color: color),
            ),
          ),

          const SizedBox(height: 15),

          /// STACKED AVATARS
          SizedBox(
            height: 40,
            width: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _avatarWithInitials(name1, 0, color),
                _avatarWithInitials(name2, 24, color),
              ],
            ),
          ),

          /// NAMES
          Text(
            "$name1 &\n$name2",
            textAlign: TextAlign.center,
            style: Get.textTheme.labelMedium!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarWithInitials(String name, double left, Color? color) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

    return Positioned(
      left: left,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          color: color,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// BOOKING SECTION
  Widget _bookingSection() {
    return Obx(() {
      final homeController = controller.homeController;

      // Show shimmer while loading
      if (homeController.isLoadingBookings.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: bookingShimmer(),
        );
      }

      final bookings = homeController.bookings.value?.data ?? [];
      final filteredBookings = bookings
          .where((b) => b.openMatchId?.openMatchStatus != "pending")
          .toList();

      if (filteredBookings.isEmpty) {
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
                        style: Get.textTheme.labelLarge!.copyWith(
                          color: AppColors.primaryColor,
                        ),
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
      final filteredBookings = allBookings
          .where((b) => b.openMatchId?.openMatchStatus != "pending")
          .toList();

      if (filteredBookings.isEmpty) {
        return SizedBox.shrink();
      }

      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) =>
              _buildBookingCard(context, filteredBookings[index]),
        ),
      );
    });
  }

  Widget _buildBookingCard(BuildContext context, BookingHistoryData b) {
    final club = b.registerClubId;
    final isOngoing = controller.homeController.isBookingOngoing(b);

    return GestureDetector(
      onTap: controller.selectedSportTab.value == 1
          ? null
          : () {
              if (!controller.homeController.isCheckingScoreboard.value) {
                final id = b.bookingType == "openMatch"
                    ? b.openMatchId?.sId
                    : b.sId;
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
                      : b.bookingType == "regular"
                      ? Color(0xffC6F6D5)
                      : Color(0xff9EBAFF),
                  width: isOngoing ? 2 : 1,
                ),
                gradient: LinearGradient(
                  colors: isOngoing
                      ? [
                          Color(0xffFFEBEE),
                          Color(0xffFFCDD2).withValues(alpha: 0.3),
                        ]
                      : b.bookingType == "regular"
                      ? [
                          Color(0xffF0FFF4),
                          Color(0xffC6F6D5).withValues(alpha: 0.3),
                        ]
                      : [
                          Color(0xffF3F7FF),
                          Color(0xff9EBAFF).withValues(alpha: 0.3),
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
        child: (club?.logo != null && club!.logo!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: club.logo!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    LoadingWidget(color: AppColors.primaryColor),
                errorWidget: (_, __, ___) =>
                    Image.asset(Assets.imagesImgHomeLogo),
              )
            : Image.asset(Assets.imagesImgHomeLogo, fit: BoxFit.cover),
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
              color: AppColors.blackColor,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            Image.asset(
              Assets.imagesIcLocation,
              scale: 3,
              color: AppColors.blackColor,
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: Get.width * 0.3,
              child: Text(
                cityName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.blackColor,
                  fontSize: 10,
                ),
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

  Widget _bookingTimeInfo(
    BuildContext context,
    BookingHistoryData b,
    bool isOngoing,
  ) {
    String formattedDateTime = '';
    if (b.bookingDate != null) {
      try {
        final date = DateTime.parse(b.bookingDate!);
        final dateStr = DateFormat('dd MMM').format(date);
        final timeRange = (b.startTime != null && b.endTime != null)
            ? '${b.startTime?.split(' ').first}–${b.endTime}'
            : '';
        formattedDateTime = timeRange.isNotEmpty
            ? '$dateStr, $timeRange'
            : dateStr;
      } catch (e) {
        formattedDateTime = '';
      }
    }

    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              formattedDateTime,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: isOngoing ? Colors.red.shade700 : AppColors.blackColor,
              ),
            ),
          ),
          Text(
            "(${b.totalTime ?? 0}m)",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isOngoing ? Colors.red.shade700 : AppColors.blackColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).paddingOnly(bottom: 2);
  }

  Widget _banner() {
    return Obx(() {
      final images = controller.bannerImages;
      if (images.isEmpty) return const SizedBox.shrink();

      return SeamlessBannerSwiper(
        key: ValueKey(images.join('|')),
        images: images,
        height: 170,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 700),
        onTap: controller.onBannerTap,
        onIndexChanged: (index) => controller.currentBannerIndex.value = index,
      );
    });
  }

  /*
  /// Simple swiper (PageView) with seamless wrap (last -> first).
  /// Duplicate first/last pages are used; wrap jump is done instantly after animation ends.
class _SeamlessBannerSwiper extends StatefulWidget {
  final List<String> images;
  final double height;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final void Function(int index) onTap;
  final ValueChanged<int> onIndexChanged;

  const _SeamlessBannerSwiper({
    required this.images,
    required this.height,
    required this.autoPlayInterval,
    required this.autoPlayAnimationDuration,
    required this.onTap,
    required this.onIndexChanged,
  });

  @override
  State<_SeamlessBannerSwiper> createState() => _SeamlessBannerSwiperState();
}

class _SeamlessBannerSwiperState extends State<_SeamlessBannerSwiper> {
  late final PageController _pageController;
  Timer? _timer;
  bool _isAnimating = false;
  int _currentPage = 1; // extended page index

  int get _len => widget.images.length;

  int _effectiveIndexFromPage(int pageIndex) {
    if (_len <= 0) return 0;
    if (pageIndex == 0) return _len - 1;
    if (pageIndex == _len + 1) return 0;
    return pageIndex - 1;
  }

  @override
  void initState() {
    super.initState();
    final initialPage = 1;
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);

    if (_len > 1) {
      _timer = Timer.periodic(widget.autoPlayInterval, (_) => _goNext());
    }

    // Assets cache warm up: next image decode lag ko reduce karega.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final path in widget.images) {
        precacheImage(AssetImage(path), context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted || _isAnimating || _len <= 1) return;

    final nextPage = _currentPage + 1;
    _isAnimating = true;
    _pageController
        .animateToPage(
          nextPage,
          duration: widget.autoPlayAnimationDuration,
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
          if (!mounted) return;
          _isAnimating = false;
        });
  }

  void _handlePageChanged(int pageIndex) {
    final effectiveIndex = _effectiveIndexFromPage(pageIndex);
    widget.onIndexChanged(effectiveIndex);

    if (pageIndex == 0) {
      // Jump to the real "last" page (which is extended page == len).
      _currentPage = _len;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.jumpToPage(_len);
      });
    } else if (pageIndex == _len + 1) {
      // Jump to the real "first" page (extended page == 1).
      _currentPage = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.jumpToPage(1);
      });
    } else {
      _currentPage = pageIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_len == 0) return const SizedBox.shrink();
    final itemCount = _len + 2; // [last] + [real items] + [first]

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: itemCount,
        onPageChanged: _handlePageChanged,
        itemBuilder: (context, pageIndex) {
          final effectiveIndex = _effectiveIndexFromPage(pageIndex);
          final imagePath = widget.images[effectiveIndex];

          return Container(
            width: Get.width,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                    ),
                  ),
                  Positioned.fill(
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
                            offset: const Offset(0, -5),
                            child: Text(
                              "Discover, Book",
                              style: Get.textTheme.titleMedium!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: Text(
                              "and Play",
                              style: Get.textTheme.titleMedium!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => widget.onTap(effectiveIndex),
                            child: Container(
                              width: Get.width * 0.35,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 3, horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "BOOK NOW!",
                                    style: Get.textTheme.titleSmall!.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ).paddingOnly(left: 10),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primaryColor,
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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
        },
      ),
    );
  }
}

*/

  /// QUICK ACTIONS
  Widget _quickActions() {
    final items = [
      {
        "icon": Assets.imagesIcBookACourtNew,
        "title": "Find a Court",
        "action": "book",
        "boxSize": 70.0,
        "iconSize": 34.0,
        "offset": Offset(0, 3),
      },
      {
        "icon": Assets.imagesIcOpenMatchNew,
        "title": "Find a Game",
        "action": "match",
        "boxSize": 70.0,
        "iconSize": 34.0,
        "offset": Offset(0, 4),
      },
      {
        "icon": Assets.imagesIcFindAPlayer,
        "title": "Find a Player",
        "action": "player",
        "boxSize": 70.0,
        "iconSize": 40.0,
        "offset": Offset(0, 4),
      },
      {
        "icon": Assets.imagesIcSpl,
        "title": "League",
        "action": "league",
        "boxSize": 70.0,
        "iconSize": 37.0,
        "offset": Offset(0, 6),
      },
    ];

    return Obx(() {
      final leagueEmpty = (controller.activeLeagues.value?.data ?? []).isEmpty;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((e) {
          final double boxSize = e["boxSize"] as double;
          final double iconSize = e["iconSize"] as double;
          final Offset offset = e["offset"] as Offset;
          final isLeague = e["action"] == "league";
          final showComingSoon = isLeague && leagueEmpty;

          return GestureDetector(
            onTap: showComingSoon
                ? null
                : () => _handleQuickAction(e["action"] as String),
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
                      colors: [Color(0xFF3F56D6), Color(0xFF2B44C4)],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                      if (showComingSoon)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF3DBE64).withValues(alpha: 0.5),
                                      Color(0xFF1F41BB).withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "Coming\nSoon",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
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
    });
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'book':
        Get.toNamed(RoutesName.bookACourt, arguments: {});
        break;
      case 'match':
        final categoryId = controller.selectedCategoryId.value;
        final locationId =
            controller
                .profileController
                .profileModel
                .value
                ?.response
                ?.city
                ?.sId ??
            "68c94a94d72a6f9769712ff0";
        Get.toNamed(
          RoutesName.openMatchForAllCourts,
          arguments: {'categoryId': categoryId, 'location': locationId},
        );
        break;
      case 'league':
        final leagues = controller.activeLeagues.value?.data ?? [];
        if (leagues.isNotEmpty) {
          final leagueId = leagues.first.id;
          final leagueTitle = leagues.first.leagueName;
          Get.toNamed(
            RoutesName.league,
            arguments: {
              'leagueId': leagueId,
              'leagueTitle': leagueTitle,
              'initialTab': 1,
            },
          )?.then((_) {
            controller.fetchPollResults();
            controller.fetchScheduleMatches();
            controller.fetchActiveLeagues();
            controller.fetchLeaderBoard();
          });
        }
        break;
      case 'player':
        Get.bottomSheet(
          backgroundColor: Colors.transparent,
          SizedBox(height: Get.height, child: FindPlayerScreen()),
          isScrollControlled: true,
        );
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
              child: Text(
                "View all",
                style: Get.textTheme.labelLarge!.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
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
    final courtDetails = court.courts?.isNotEmpty == true
        ? court.courts![0]
        : null;
    final courtCount = courtDetails?.courtCount ?? 0;
    final features = courtDetails?.features ?? [];
    final locationDetails = court.locations?.isNotEmpty == true
        ? court.locations![0]
        : null;
    final city = locationDetails?.city ?? court.city ?? "";
    // final zipCode = locationDetails?.zipCode ?? court.zipCode ?? "";

    return GestureDetector(
      onTap: () {
        log("CLUB ID -> ${court.id}");
        log(" ID -> ${court.courts?[0].id ?? ""}");
        log("locationsId => ${court.locations?[0].id}");
        if (court.id != null) {
          Get.delete<BookingController>();
          Get.toNamed(
            RoutesName.booking,
            arguments: {
              "data": court,
              "clubId": court.id,
              "sID": court.courts?[0].id ?? "",
              "categoryId": controller.selectedCategoryId.value,
              "locationsId": court.locations?[0].id,
              "location":
                  controller
                      .profileController
                      .profileModel
                      .value
                      ?.response
                      ?.city
                      ?.sId ??
                  "68c94a94d72a6f9769712ff0",
            },
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              /// LOGO
              Positioned.fill(
                child: court.logo != null && court.logo!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: court.logo!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: LoadingWidget(color: AppColors.primaryColor),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Image.asset(
                          Assets.imagesImgHomeLogo,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(Assets.imagesImgHomeLogo, fit: BoxFit.cover),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                              style: Get.textTheme.titleMedium!.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "0",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              city,
                              style: Get.textTheme.bodySmall!.copyWith(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$courtCount Courts | ${features.isNotEmpty ? features.join(' | ') : 'Available'}",
                        style: Get.textTheme.bodySmall!.copyWith(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            "Booking Price",
                            style: Get.textTheme.headlineLarge!.copyWith(
                              color: AppColors.secondaryColor,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "₹ ${formatAmount(court.totalAmount ?? 0)}",
                            style: Get.textTheme.titleMedium!.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
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
                    blurRadius: 5.0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.secondaryColor,
                    child:
                        player.profilePic != null &&
                            player.profilePic!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: player.profilePic!,
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
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
                        color: AppColors.secondaryColor,
                      ),
                      child: Text(
                        "${formatAmount(player.xpPoints ?? 0)} XP",
                        style: Get.textTheme.labelMedium!.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    player.name?.capitalizeFirstChar() ?? "Unknown Player",
                    style: Get.textTheme.labelLarge!.copyWith(fontSize: 12),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ).paddingOnly(top: 10, bottom: 10);
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _matchPlayedCard()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [_leaderboardCard(), SizedBox(height: 10), _xpCard()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchPlayedCard() {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      final totalMatches = profile?.response?.totalMatchesPlayed ?? 0;
      final totalWins = profile?.response?.totalWins ?? 0;
      final winRatio = totalMatches > 0 ? (totalWins / totalMatches) : 0.0;
      final winPercentage = (winRatio * 100).round();

      return GestureDetector(
        onTap: () => Get.to(EditProfileUi(buttonType: "drawer")),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
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
                child: SvgPicture.asset(Assets.imagesImgBackgroundPlayedMatch),
              ),
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
                          fontSize: 17,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '$totalMatches',
                        style: Get.textTheme.titleLarge!.copyWith(
                          color: Color(0xff0E1E55),
                          fontSize: 30,
                        ),
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
                            painter: BlockSemiCirclePainter(progress: winRatio),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: Offset(0, 4),
                                child: Text(
                                  '$winPercentage%',
                                  style: Get.textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                'Win Ratio',
                                style: Get.textTheme.headlineSmall!.copyWith(
                                  color: Colors.grey,
                                ),
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
        onTap: () => Get.to(LeaderboardScreen(buttonType: "drawer")),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.secondaryColor.withValues(alpha: 0.1),
            ),
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
                  Icon(Icons.bar_chart, color: Color(0xff2947C7), size: 30),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      controller.customerRank.value.toString(),
                      style: Get.textTheme.titleLarge!.copyWith(
                        color: Color(0xff0E1E55),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Leaderboard\nPosition',
                style: Get.textTheme.titleSmall!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                        child: Icon(Icons.star, color: Colors.green, size: 22),
                      ),
                      Text(
                        '$xpPoints',
                        style: Get.textTheme.titleLarge!.copyWith(
                          color: Color(0xff0E1E55),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'XP Points',
                    style: Get.textTheme.headlineLarge!.copyWith(
                      color: Colors.grey,
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

  Widget _recentMatches() {
    return Obx(() {
      final profile = controller.profileController.profileModel.value;
      final recentMatches = profile?.response?.recentMatches ?? [];

      List<String> results = recentMatches.isNotEmpty
          ? recentMatches.cast<String>()
          : [];

      final displayResults = results.length > 5
          ? results.sublist(results.length - 5)
          : results;

      return Container(
        color: Colors.transparent,
        width: Get.width,
        child: Row(
          children: [
            SvgPicture.asset(Assets.imagesIcPadelBall).paddingOnly(right: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003AFF), Color(0xFF07289A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Recent Matches',
                      style: Get.textTheme.headlineSmall!.copyWith(
                        color: Colors.white,
                      ),
                    ),
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
            SvgPicture.asset(Assets.imagesIcPadelBall).paddingOnly(left: 10),
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
    final dayStr = DateFormat(
      'EEEE',
    ).format(DateFormat('yyyy-MM-dd').parse(data.matchDate ?? ''));
    final dateOnlyStr = DateFormat(
      'dd MMM',
    ).format(DateFormat('yyyy-MM-dd').parse(data.matchDate ?? ''));
    final timeStr =
        data.openMatchStatus == "pending" || data.openMatchStatus == "cancelled"
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
        final locationId =
            controller
                .profileController
                .profileModel
                .value
                ?.response
                ?.city
                ?.sId ??
            "68c94a94d72a6f9769712ff0";
        Get.toNamed(
          RoutesName.openMatchForAllCourts,
          arguments: {'categoryId': categoryId, 'locationId': locationId},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xffC8D6FB)),
          gradient: LinearGradient(
            colors: [
              Color(0xffF3F7FF),
              Color(0xff9EBAFF).withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SvgPicture.asset(
                index % 2 == 0
                    ? Assets.imagesImgOpenMatchBg
                    : Assets.imagesImgOpenMatchGreenBg,
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
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            Text(
                              " ${data.skillLevel?.capitalizeFirst ?? 'Professional'} | ",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                        ),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Transform.translate(
                                offset: Offset(0, -1),
                                child: Image.asset(
                                  Assets.imagesIcLocation,
                                  scale: 2,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locationName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
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

  Widget _buildOverlappingPlayerRow(
    List<dynamic> teamAPlayers,
    List<dynamic> teamBPlayers,
  ) {
    return Container(
      width: Get.width * .37,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.greyColor),
      ),
      child: SizedBox(
        height: 44,
        child: SizedBox(
          width: Get.width,
          // Width for 4 overlapping circles (44 + 22 + 22 + 22)
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
      ),
    );
  }

  Widget _buildFilledPlayerCircle(
    String? imageUrl,
    String name,
    String lastName,
  ) {
    final firstLetter = name.trim().isNotEmpty
        ? '${name.trim()[0].toUpperCase()}${lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : ''}'
        : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
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
                        color: AppColors.primaryColor.withValues(alpha: 0.5),
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
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xffeaf0ff),
        child: Icon(Icons.add, color: AppColors.primaryColor, size: 20),
      ),
    );
  }

  String _getScoreText(dynamic score) {
    if (score == null) return "0";
    if (score is int) return score.toString();
    if (score is ScoreDetail) {
      return (score.sets ?? 0).toString();
    }
    return score.toString();
  }
}

class _LeagueComingSoonWidget extends StatefulWidget {
  final MainHomeController controller;
  final Widget Function() buildLiveSlider;
  final Widget Function() buildUpcoming;

  const _LeagueComingSoonWidget({
    required this.controller,
    required this.buildLiveSlider,
    required this.buildUpcoming,
  });

  @override
  State<_LeagueComingSoonWidget> createState() =>
      _LeagueComingSoonWidgetState();
}

class _LeagueComingSoonWidgetState extends State<_LeagueComingSoonWidget> {
  List<LeagueModel.Data> _leagues = [];
  bool _loading = true;
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    ever(widget.controller.isLoadingLeagueSection, (_) => _sync());
    ever(widget.controller.activeLeagues, (_) => _sync());
    ever(widget.controller.scheduleMatches, (_) => _sync());
    ever(widget.controller.upcomingMatches, (_) => _sync());
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    setState(() {
      _loading = widget.controller.isLoadingLeagueSection.value;
      _leagues = widget.controller.activeLeagues.value?.data ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
      ).paddingOnly(top: 10);
    }

    if (_leagues.isEmpty) return const SizedBox.shrink();

    final currentLeague = _leagues.length > _carouselIndex
        ? _leagues[_carouselIndex]
        : _leagues.first;

    final ctrl = widget.controller;
    final liveMatches = (ctrl.scheduleMatches.value?.data ?? [])
        .expand((d) => d.matches ?? [])
        .toList();
    final upcomingMatches = (ctrl.upcomingMatches.value?.data ?? [])
        .expand((d) => d.matches ?? [])
        .toList();

    Widget matchSection;
    if (liveMatches.isNotEmpty) {
      matchSection = widget.buildLiveSlider();
    } else if (upcomingMatches.isNotEmpty) {
      matchSection = widget.buildUpcoming();
    } else {
      matchSection = _leagues.length == 1
          ? _buildSingleLeagueCard(_leagues.first)
          : _LeagueCarouselWidget(
              leagues: _leagues,
              onPageChanged: (index) {
                setState(() => _carouselIndex = index);
              },
            );
    }

    return Column(
      children: [
        _buildSwootTitle(currentLeague.leagueName),
        const SizedBox(height: 12),
        matchSection,
        const SizedBox(height: 12),
        BuildLeagueTitleSponsor(league: currentLeague),
        BuildLeagueMoreSponsor(league: currentLeague),
        _buildLeaguePointsTable(),
        GestureDetector(
          onTap: () {
            widget.controller.fetchPollResults();
            showVoteDialog(context);
          },
          child: Image.asset(Assets.imagesImgPoll),
        ).paddingOnly(top: 5),
      ],
    ).paddingOnly(top: 10);
  }

  Widget _buildSwootTitle(String? leagueName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SvgPicture.asset(
            Assets.imagesImgSwootPadelLeague,
            height: 22,
            width: 25,
          ),
          // SvgPicture.asset(
          //   Assets.imagesIcPadelBall,
          //   height: 18,width: 18,
          // ).paddingOnly(right: 10),
          // Text(leagueName ?? "", style: Get.textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _buildLeaguePointsTable() {
    return Obx(() {
      if (widget.controller.isLoadingLeaderBoard.value) {
        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
        );
      }

      final standings =
          widget.controller.leaderBoard.value?.data?.standings ?? [];
      if (standings.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              spreadRadius: 1.5,
              blurRadius: 5.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            /// Header Row
            _headerRow(),

            Divider(color: Colors.grey.shade300),

            /// List
            ...standings.take(6).map((standing) {
              return Column(
                children: [
                  _teamRow(standing),
                  Divider(color: Colors.grey.shade300),
                ],
              );
            }),
          ],
        ),
      ).paddingOnly(top: 10);
    });
  }

  Widget _headerRow() {
    final style = Get.textTheme.labelMedium!.copyWith(
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 20, child: Text("#", style: style)),
        Expanded(
          flex: 3,
          child: SizedBox(width: 35, child: Text(" Teams", style: style)),
        ),
        // SizedBox(width: 30, child: Text("M",style: style)),
        SizedBox(
          width: 30,
          child: Center(child: Text(" W", style: style)),
        ),
        SizedBox(
          width: 30,
          child: Center(child: Text(" L", style: style)),
        ),
        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              " Pts",
              style: Get.textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(child: Text("Last 5 ", style: style)),
        ),
      ],
    );
  }

  Widget _teamRow(dynamic standing) {
    return Row(
      children: [
        SizedBox(
          width: 25,
          child: Text(
            "${standing.position ?? 0}",
            style: Get.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              standing.clubLogo != null && standing.clubLogo!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: standing.clubLogo!,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 11,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) => CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          (standing.clubName ?? "?")[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          (standing.clubName ?? "?")[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.primaryColor,
                      child: Text(
                        (standing.clubName ?? "?")[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  standing.clubName ?? "Unknown",
                  style: Get.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              "${standing.wins ?? 0}",
              style: Get.textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              "${standing.losses ?? 0}",
              style: Get.textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              "${standing.points ?? 0}",
              style: Get.textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildRecentFormIcons(standing.recentForm ?? []),
              ),
              Icon(Icons.arrow_back, size: 9, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecentFormIcons(List<dynamic> recentForm) {
    final formList = recentForm.take(5).toList();
    final widgets = <Widget>[];

    // Add placeholders first (left side) if less than 5 matches
    final emptyCount = 5 - formList.length;
    for (int i = 0; i < emptyCount; i++) {
      widgets.add(_buildResultIcon(null));
    }

    // Then add actual match results
    for (var result in formList) {
      final isWin = result.toString().toUpperCase() == 'W';
      widgets.add(_buildResultIcon(isWin));
    }

    return widgets;
  }

  Widget _buildResultIcon(bool? win) {
    if (win == null) {
      // Placeholder for no match data
      return Container(
        margin: const EdgeInsets.only(right: 4),
        height: 16,
        width: 16,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        color: win ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
      child: Icon(
        win ? Icons.check : Icons.close,
        size: 10,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSingleLeagueCard(LeagueModel.Data leagueData) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          RoutesName.league,
          arguments: {
            'leagueId': leagueData.id,
            'leagueTitle': leagueData.leagueName,
          },
        )?.then((_) {
          widget.controller.fetchPollResults();
          widget.controller.fetchScheduleMatches();
          widget.controller.fetchActiveLeagues();
          widget.controller.fetchLeaderBoard();
        });
      },
      child: Container(
        width: Get.width,
        height: 163,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              spreadRadius: 2.3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child:
              leagueData.mobileBanner != null &&
                  leagueData.mobileBanner!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: leagueData.mobileBanner!,
                  fit: BoxFit.cover,
                )
              : Image.asset(Assets.imagesImgLeagueComingSoon),
        ),
      ),
    );
  }

  void showVoteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Obx(() {
          final pollData = widget.controller.pollResults.value?.data;
          final clubs = pollData?.clubs ?? [];
          final maxVotes = clubs.isEmpty
              ? 1
              : clubs.map((c) => c.votes ?? 0).reduce((a, b) => a > b ? a : b);
          final safeMax = maxVotes == 0 ? 1 : maxVotes;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Container(
              padding: EdgeInsets.only(top: 20, bottom: 20, right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0XFFCBD6FF)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pollData?.poll?.question ??
                            "Vote Your Club. Make It Count.",
                        style: Get.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          color: Colors.transparent,
                          child: Icon(Icons.close),
                        ),
                      ),
                    ],
                  ).paddingOnly(left: 20),
                  Divider(color: Colors.grey.shade300).paddingOnly(left: 20),
                  const SizedBox(height: 10),
                  if (clubs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No poll data available",
                        style: Get.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...clubs.map(
                      (club) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: clubItem(
                          clubName: club.clubName ?? "",
                          votes: club.votes ?? 0,
                          logoUrl: club.logo ?? "",
                          clubId: club.clubId ?? "",
                          widthFactor: (club.votes ?? 0) / safeMax,
                          rgbColor: club.rgbColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget clubItem({
    required String clubName,
    required int votes,
    required String logoUrl,
    required String clubId,
    double widthFactor = 1.0,
    String? rgbColor,
  }) {
    Color color1;
    Color color2;
    Color textColor;

    if (rgbColor != null && rgbColor.isNotEmpty) {
      try {
        // Handle hex color format (e.g., #2cba8f or 2cba8f)
        String hexColor = rgbColor.replaceAll('#', '');
        if (hexColor.length == 6) {
          final r = int.parse(hexColor.substring(0, 2), radix: 16);
          final g = int.parse(hexColor.substring(2, 4), radix: 16);
          final b = int.parse(hexColor.substring(4, 6), radix: 16);

          color1 = Color.fromRGBO(r, g, b, 1.0);
          // Create a lighter shade for gradient
          color2 = Color.fromRGBO(
            (r + (255 - r) * 0.3).clamp(0, 255).toInt(),
            (g + (255 - g) * 0.3).clamp(0, 255).toInt(),
            (b + (255 - b) * 0.3).clamp(0, 255).toInt(),
            1.0,
          );
          // Calculate brightness to determine text color
          final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
          textColor = brightness > 150 ? Colors.black : Colors.white;
        } else {
          throw Exception('Invalid hex color format');
        }
      } catch (e) {
        // Fallback to default colors if parsing fails
        final colors = [
          [Color(0xff4A27FF), Color(0xff001E8C)],
          [Color(0xffC6C000), Color(0xffF4E66A)],
          [Color(0xff4C8E00), Color(0xff9FD94F)],
          [Color(0xff8F2D00), Color(0xffE65E2C)],
          [Color(0xff002E13), Color(0xff006633)],
        ];
        final idx = clubName.hashCode.abs() % colors.length;
        color1 = colors[idx][0];
        color2 = colors[idx][1];
        textColor = idx == 1 || idx == 2 ? Colors.black : Colors.white;
      }
    } else {
      // Use default colors if rgbColor is null
      final colors = [
        [Color(0xff4A27FF), Color(0xff001E8C)],
        [Color(0xffC6C000), Color(0xffF4E66A)],
        [Color(0xff4C8E00), Color(0xff9FD94F)],
        [Color(0xff8F2D00), Color(0xffE65E2C)],
        [Color(0xff002E13), Color(0xff006633)],
      ];
      final idx = clubName.hashCode.abs() % colors.length;
      color1 = colors[idx][0];
      color2 = colors[idx][1];
      textColor = idx == 1 || idx == 2 ? Colors.black : Colors.white;
    }

    return _ClubVoteItem(
      clubName: clubName,
      votes: votes,
      logoUrl: logoUrl,
      clubId: clubId,
      color1: color1,
      color2: color2,
      textColor: textColor,
      widthFactor: widthFactor,
      onVote: () =>
          widget.controller.castVote(clubId: clubId, clubName: clubName),
    );
  }
}

class _ClubVoteItem extends StatefulWidget {
  final String clubName;
  final int votes;
  final String logoUrl;
  final String clubId;
  final Color color1;
  final Color color2;
  final Color textColor;
  final double widthFactor;
  final Future<bool> Function() onVote;

  const _ClubVoteItem({
    required this.clubName,
    required this.votes,
    required this.logoUrl,
    required this.clubId,
    required this.color1,
    required this.color2,
    required this.textColor,
    required this.widthFactor,
    required this.onVote,
  });

  @override
  State<_ClubVoteItem> createState() => _ClubVoteItemState();
}

class _ClubVoteItemState extends State<_ClubVoteItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleVote() async {
    if (_voting) return;
    setState(() => _voting = true);
    _animController.forward(from: 0);
    await widget.onVote();
    if (mounted) setState(() => _voting = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = (constraints.maxWidth * widget.widthFactor).clamp(
          110.0,
          constraints.maxWidth - 40,
        );
        return SizedBox(
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width: barWidth,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    colors: [widget.color1, widget.color2],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.clubName,
                            overflow: TextOverflow.ellipsis,
                            style: Get.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w500,
                              color: widget.textColor,
                            ),
                          ),
                          Text(
                            "${widget.votes} votes",
                            style: Get.textTheme.displayLarge!.copyWith(
                              color: widget.textColor,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: widget.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.logoUrl,
                                fit: BoxFit.cover,
                                width: 28,
                                height: 28,
                                errorWidget: (_, __, ___) =>
                                    Icon(Icons.sports_tennis, size: 16),
                              )
                            : Icon(Icons.sports_tennis, size: 16),
                      ),
                    ).paddingOnly(left: 5),
                  ],
                ),
              ),
              Positioned(
                left: barWidth + 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _handleVote,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Image.asset(Assets.imagesImgPollVote, scale: 3.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeagueCarouselWidget extends StatefulWidget {
  final List<LeagueModel.Data> leagues;
  final void Function(int) onPageChanged;

  const _LeagueCarouselWidget({
    required this.leagues,
    required this.onPageChanged,
  });

  @override
  State<_LeagueCarouselWidget> createState() => _LeagueCarouselWidgetState();
}

class _LeagueCarouselWidgetState extends State<_LeagueCarouselWidget> {
  late final PageController _pageController;
  int _currentIndex = 0; // logical index (0..length-1) for dots
  int _currentPage = 1; // extended index (0..length+1)
  Timer? _autoPlayTimer;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Use 2 extra pages to make last->first seamless without visible jump.
    // Page 0: last league, Page 1..length: leagues[0..length-1], Page length+1: first league
    _pageController = PageController(initialPage: 1);
    _currentPage = 1;
    if (widget.leagues.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_pageController.hasClients) return;
        if (_isAnimating) return;

        final nextPage = _currentPage + 1;
        _isAnimating = true;
        _pageController
            .animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            )
            .whenComplete(() {
              if (!mounted) return;
              _isAnimating = false;
            });
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.leagues.length + 2,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                if (widget.leagues.length == 0) {
                  _currentIndex = 0;
                } else if (index == 0) {
                  _currentIndex = widget.leagues.length - 1;
                } else if (index == widget.leagues.length + 1) {
                  _currentIndex = 0;
                } else {
                  _currentIndex = index - 1;
                }
              });

              // Seamless reset: if we land on duplicate page, jump to the real one.
              if (index == widget.leagues.length + 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _pageController.jumpToPage(1);
                });
              } else if (index == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _pageController.jumpToPage(widget.leagues.length);
                });
              }
            },
            itemBuilder: (context, index) {
              final int effectiveIndex;
              if (index == 0) {
                effectiveIndex = widget.leagues.length - 1;
              } else if (index == widget.leagues.length + 1) {
                effectiveIndex = 0;
              } else {
                effectiveIndex = index - 1;
              }
              final leagueData = widget.leagues[effectiveIndex];
              return GestureDetector(
                onTap: () {
                  Get.toNamed(
                    RoutesName.league,
                    arguments: {
                      'leagueId': leagueData.id,
                      'leagueTitle': leagueData.leagueName,
                    },
                  )?.then((_) {
                    // Refresh APIs when coming back from league screen
                    final controller = Get.find<MainHomeController>();
                    controller.fetchPollResults();
                    controller.fetchScheduleMatches();
                    controller.fetchActiveLeagues();
                    controller.fetchLeaderBoard();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 8,
                        spreadRadius: 1.3,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child:
                        leagueData.mobileBanner != null &&
                            leagueData.mobileBanner!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: leagueData.mobileBanner!,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(Assets.imagesImgLeagueComingSoon),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (widget.leagues.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.leagues.length, (i) {
              final isActive = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isActive ? 18 : 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryColor : Colors.black12,
                  borderRadius: BorderRadius.circular(50),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _AnimatedLiveTag extends StatefulWidget {
  @override
  _AnimatedLiveTagState createState() => _AnimatedLiveTagState();
}

class _AnimatedLiveTagState extends State<_AnimatedLiveTag>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseController.repeat(reverse: true);
    _scaleController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentGeometry.centerRight,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _scaleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (_scaleAnimation.value * 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Color(0xFFCD3529),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(
                      0xFFCD3529,
                    ).withValues(alpha: _pulseAnimation.value * 0.5),
                    blurRadius: 6 + (_pulseAnimation.value * 3),
                    spreadRadius: _pulseAnimation.value * 1.5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.7 + (_pulseAnimation.value * 0.3),
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: _pulseAnimation.value * 0.4,
                            ),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "LIVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).paddingOnly(top: 10, right: 10),
    );
  }
}

class _AnimatedWatchLiveButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedWatchLiveButton({required this.onTap});

  @override
  _AnimatedWatchLiveButtonState createState() =>
      _AnimatedWatchLiveButtonState();
}

class _AnimatedWatchLiveButtonState extends State<_AnimatedWatchLiveButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _iconController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _iconAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticInOut),
    );

    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    _iconController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _shimmerController,
          _iconController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseAnimation.value * 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.secondaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(
                      alpha: 0.4 + (_pulseAnimation.value * 0.3),
                    ),
                    blurRadius: 6 + (_pulseAnimation.value * 3),
                    spreadRadius: 0.5 + (_pulseAnimation.value * 1),
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment(_shimmerAnimation.value - 1, 0),
                            end: Alignment(_shimmerAnimation.value, 0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Button content
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _iconAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Watch Live",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
