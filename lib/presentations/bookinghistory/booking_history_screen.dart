import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/score_board/widgets/app_players_bottomsheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_screen.dart';
import 'package:get_storage/get_storage.dart';

import '../../configs/routes/routes_name.dart';
import '../../data/request_models/booking/boking_history_model.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';
import 'booking_history_controller.dart';

class BookingHistoryUi extends StatefulWidget {
  final String? buttonType;
  const BookingHistoryUi({super.key,this.buttonType});

  @override
  State<BookingHistoryUi> createState() => _BookingHistoryUiState();
}

class _BookingHistoryUiState extends State<BookingHistoryUi> {
  final List<bool> _expandedStates = [];
  final storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    final BookingHistoryController controller = Get.put(
      BookingHistoryController(),
      tag: 'booking_history',
    );
    return Scaffold(
      appBar: primaryAppBar(
          centerTitle: true,
          showLeading:widget.buttonType=="drawer"? true:false,
          title: Text("My Bookings"), context: context),
      body: Column(
        children: [
          tabBar(controller),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _tabContent(context, controller: controller, type: "upcoming"),
                _tabContent(context, controller: controller, type: "ongoing"),
                _tabContent(context, controller: controller, type: "completed"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tabBar(BookingHistoryController controller) {
    return Container(
      color: Colors.white,
      child: TabBar(
        dividerColor: Colors.grey.shade200,
        controller: controller.tabController,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 3,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: "Upcoming"),
          Tab(text: "Ongoing"),
          Tab(text: "Completed"),
        ],
      ),
    );
  }

  Widget _tabContent(BuildContext context, {
    required BookingHistoryController controller,
    required String type,
  }) {
    return Obx(() {
      final bookings = (type == "completed")
          ? (controller.completedBookings.value?.data ?? [])
          : (type == "ongoing")
          ? (controller.inProgressBookings.value?.data ?? [])
          : (type == "cancelled")
          ? (controller.cancelledBookings.value?.data ?? [])
          : (controller.upcomingBookings.value?.data ?? []);

      if (controller.isLoading.value) {
        return ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return bookingCardShimmer(context, index);
          },
        );
      }

      if (bookings.isEmpty) {
        return const Center(
          child: Text(
            "No bookings found",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.whiteColor,
        onRefresh: () async => controller.refreshBookings(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100 &&
                controller.hasMoreData(type) &&
                !controller.isLoadingMore.value) {
              controller.loadMoreBookings(type);
            }
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04, vertical: 12),
            itemCount: bookings.length + (controller.hasMoreData(type) ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == bookings.length) {
                return Obx(() {
                  if (controller.isLoadingMore.value) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: LoadingWidget(color: AppColors.primaryColor),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                });
              }

              final booking = bookings[index];
              final club = booking.registerClubId;

              // Initialize expanded states if needed
              if (_expandedStates.length != bookings.length) {
                _expandedStates.clear();
                _expandedStates.addAll(List.filled(bookings.length, false));
              }

              return GestureDetector(
                onTap: (booking.bookingType ?? "").toLowerCase() == "normal" ? () {
                  final bookingId = booking.sId;
                  if (bookingId != null && bookingId.isNotEmpty) {
                    Get.toNamed(
                      RoutesName.bookingConfirmAndCancel,
                      arguments: {
                        "id": bookingId,
                        "fromCompleted": type == "completed",
                        "fromCancelled": type == "cancelled",
                      },
                    );
                  } else {
                    Get.snackbar("Error", "Booking ID not available");
                  }
                } : null,
                child: type == "completed"
                    ? _buildCompletedBookingCard(context, booking, club, index)
                    : _buildUpcomingBookingCard(context, booking, club, index, type),
              );
            },
          ),
        ),
      );
    });
  }

  // NEW: Completed booking card matching the screenshot design
  Widget _buildCompletedBookingCard(BuildContext context, dynamic booking, dynamic club, int index) {
    final clubName = club?.clubName ?? "The Good Club";
    final address = "${club?.city ?? 'Chandigarh'} ${club?.zipCode ?? '160001'}";
    final price = (booking.totalAmount ?? 2000).toString();
    final score = _getMatchScore(booking);
    final bookingType = booking.bookingType ?? "";
    final isBlueTheme = bookingType.toLowerCase() == "normal";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !isBlueTheme ? const Color(0xffC8D6FB) : const Color(0xff3DBE64).withOpacity(0.5),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: !isBlueTheme
              ? [const Color(0xffF3F7FF), const Color(0xff9EBAFF).withOpacity(0.3)]
              : [const Color(0xffBFEECD).withOpacity(0.3), const Color(0xffBFEECD).withOpacity(0.2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date, time and badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              formatDate(booking.bookingDate).split(',')[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1c46a0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDate(booking.bookingDate).split(',').length > 1
                                  ? formatDate(booking.bookingDate).split(',')[1].trim()
                                  : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              " | ${_getTimeString(booking)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (_shouldShowSkillGenderRow(booking))
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                booking.openMatchId?.skillLevel ?? "Professional",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "|",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              genderIcon(booking.openMatchId?.gender),
                              const SizedBox(width: 4),
                              Text(
                                booking.openMatchId?.gender ?? "Mixed",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1c46a0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.message,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),

                  ],
                ).paddingOnly(bottom: 5),
              ),
            ],
          ),

          // Teams and Score section
          Row(
            children: [
              // Team A
              Expanded(
                child: Column(
                  children: [
                    _buildTeamAvatars(booking, "teamA"),
                    const SizedBox(height: 8),
                    const Text(
                      "Team A",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      score,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1c46a0),
                        letterSpacing: 2,
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _navigateToScoreboard(booking);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            // border: Border.all(color: const Color(0xff1c46a0), width: 1.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "View Scoreboard",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff1c46a0),
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.share,
                                size: 16,
                                color: Color(0xff1c46a0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Team B
              Expanded(
                child: Column(
                  children: [
                    _buildTeamAvatars(booking, "teamB"),
                    const SizedBox(height: 8),
                    const Text(
                      "Team B",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Divider
          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 4),

          // Club info and price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clubName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xff1c46a0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                "₹ $price",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1c46a0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatars(dynamic booking, String team) {
    List<Widget> avatars = [];
    
    // Get players from booking.teamA or booking.teamB directly
    final teamPlayers = team == "teamA" ? booking.teamA : booking.teamB;
    if (teamPlayers != null && teamPlayers.isNotEmpty) {
      for (var teamPlayer in teamPlayers) {
        final userId = teamPlayer.userId;
        final profilePic = userId?.profilePic ?? '';
        final name = userId?.name ?? 'N/A';
        avatars.add(_buildCompletedAvatar(profilePic, name));
      }
    }
    
    // Fallback to openMatchId if no players found
    if (avatars.isEmpty) {
      final openMatchId = booking.openMatchId;
      if (openMatchId != null) {
        final openTeamPlayers = team == "teamA" ? openMatchId.teamA : openMatchId.teamB;
        if (openTeamPlayers != null && openTeamPlayers.isNotEmpty) {
          for (var teamPlayer in openTeamPlayers) {
            final playerId = booking.playerIds?.firstWhere(
              (p) => p.sId == teamPlayer.userId,
              orElse: () => PlayerId(),
            );
            final profilePic = playerId?.profilePic ?? '';
            final name = playerId?.name ?? 'N/A';
            avatars.add(_buildCompletedAvatar(profilePic, name));
          }
        }
      }
    }
    
    // Fallback to scoreboard if still no players found
    if (avatars.isEmpty) {
      final scoreboard = booking.scoreboard;
      if (scoreboard?.teams != null) {
        final teamIndex = team == "teamA" ? 0 : 1;
        if (teamIndex < scoreboard.teams.length) {
          final teamData = scoreboard.teams[teamIndex];
          if (teamData.players != null) {
            for (var player in teamData.players) {
              final profilePic = player.playerId?.profilePic ?? '';
              final name = player.playerId?.name ?? player.name ?? 'N/A';
              avatars.add(_buildCompletedAvatar(profilePic, name));
            }
          }
        }
      }
    }

    // Add missing player placeholders with correct labels
    while (avatars.length < 2) {
      final playerNum = team == "teamA" ? (avatars.length + 1) : (avatars.length + 3);
      final playerLabel = "P$playerNum";
      avatars.add(_buildCompletedAvatar(null, playerLabel, isPlaceholder: true));
    }

    return SizedBox(
      width: 80,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: avatars[0],
          ),
          if (avatars.length > 1)
            Positioned(
              right: 0,
              child: avatars[1],
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatarStack() {
    return SizedBox(
      width: 80,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _buildCompletedAvatar(null, "P", isPlaceholder: true),
          ),
          Positioned(
            right: 0,
            child: _buildCompletedAvatar(null, "P", isPlaceholder: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedAvatar(String? imageUrl, String name, {bool isPlaceholder = false}) {
    final firstLetter = isPlaceholder ? "P" : (name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?');
    final displayText = isPlaceholder ? name : firstLetter;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: isPlaceholder ? Color(0xffeaf0ff) : const Color(0xFFEAF0FF),
        child: (imageUrl != null && imageUrl.isNotEmpty && !isPlaceholder)
            ? ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (context, url, error) => Text(
              displayText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isPlaceholder ? Colors.grey.shade600 : const Color(0xFF1C46A0),
              ),
            ),
          ),
        )
            : Text(
          displayText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPlaceholder ? Colors.grey.shade600 : const Color(0xFF1C46A0),
          ),
        ),
      ),
    );
  }

  bool _shouldShowSkillGenderRow(dynamic booking) {
    final skillLevel = booking.openMatchId?.skillLevel;
    final gender = booking.openMatchId?.gender;
    return (skillLevel != null && skillLevel.isNotEmpty) || (gender != null && gender.isNotEmpty);
  }

  String _getMatchScore(dynamic booking) {
    final scoreboard = booking.scoreboard;
    if (scoreboard?.totalScore == null) {
      return "0 : 0";
    }

    final scoreA = scoreboard.totalScore.teamA ?? 0;
    final scoreB = scoreboard.totalScore.teamB ?? 0;

    return "$scoreA : $scoreB";
  }

  // EXISTING: Upcoming booking card (your original design)
  Widget _buildUpcomingBookingCard(BuildContext context, dynamic booking, dynamic club, int index, String type) {
    final isUpcoming = type == "upcoming";
    final clubName = club?.clubName ?? "N/A";
    final address = "${club?.city ?? ''}, ${club?.zipCode ?? ''}";
    final price = (booking.totalAmount ?? 2000).toString();
    final bookingType = booking.bookingType ?? "";
    final isBlueTheme = bookingType.toLowerCase() == "normal";

    // Get real players from scoreboard
    final playerAvatars = _buildPlayerAvatarsFromScoreboard(booking);
    final addButtons = _buildAddButtonsFromScoreboard(booking, bookingType);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: !isBlueTheme ? Color(0xffC8D6FB) : Color(0xff3DBE64).withOpacity(0.5)),
        gradient: LinearGradient(
          colors: !isBlueTheme
              ? [Color(0xffF3F7FF), Color(0xff9EBAFF).withOpacity(0.3)]
              : [Color(0xffBFEECD).withOpacity(0.3), Color(0xffBFEECD).withOpacity(0.2)],
        ),
      ),
      child: Stack(
        children: [
          Align(
              alignment: AlignmentGeometry.centerRight,
              child: SvgPicture.asset(!isBlueTheme?Assets.imagesImgOpenMatchBg:Assets.imagesImgOpenMatchGreenBg,height: 190,width: 150,).paddingOnly(right: 20)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP SECTION (Date + Time + Status Badge + Arrow)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildDateTimeInfo(context, booking),
                          // if (isUpcoming)
                          //   Container(
                          //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          //     decoration: BoxDecoration(
                          //       color: AppColors.secondaryColor,
                          //       borderRadius: BorderRadius.circular(30),
                          //     ),
                          //     child: const Text(
                          //       "A",
                          //       style: TextStyle(color: Colors.white, fontSize: 9),
                          //     ),
                          //   ).paddingOnly(left: 5),
                        ],
                      ),
                      // Skill Level Tags (if upcoming)
                      if (isUpcoming && _shouldShowSkillGenderRow(booking))
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(
                              " ${booking.openMatchId?.skillLevel ?? "Professional"} | ",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            genderIcon(booking.openMatchId?.gender),
                            const SizedBox(width: 4),
                            Text(
                              booking.openMatchId?.gender ?? "Mixed",
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
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedStates[index] = !_expandedStates[index];
                        });
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _expandedStates.length > index && _expandedStates[index]
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),

              // Show expanded or collapsed content
              _expandedStates.length > index && _expandedStates[index]
                  ? _expandedCard(context, index, booking, playerAvatars, addButtons, clubName, address, price, type)
                  : _collapsedCard(context, index, booking, playerAvatars, addButtons, clubName, address, price, type),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeInfo(BuildContext context, dynamic booking) {
    try {
      final dateStr = formatDate(booking.bookingDate);
      final timeStr = _getTimeString(booking);

      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${dateStr.split(',')[0]} ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff1c46a0),
              ),
            ),
            TextSpan(
              text: '${dateStr.contains(',') ? dateStr.split(',')[1].trim() : ''}${timeStr.isNotEmpty ? ' | $timeStr' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  String _getTimeString(dynamic booking) {
    try {
      // Check for matchTime array first
      if (booking.openMatchId?.matchTime != null && booking.openMatchId?.matchTime is List) {
        final matchTimes = booking.openMatchId?.matchTime as List;
        if (matchTimes.isEmpty) return '';

        if (matchTimes.length == 1) {
          return matchTimes[0].toString();
        }

        final firstTime = matchTimes.first.toString();
        final lastTime = matchTimes.last.toString();

        // Extract hour from first and last time (e.g., "8 pm" -> "8", "9 pm" -> "9")
        final firstHour = firstTime.replaceAll(RegExp(r'[^0-9]'), '');
        final lastHour = lastTime.replaceAll(RegExp(r'[^0-9]'), '');
        final period = lastTime.contains('pm') ? 'pm' : 'am';

        return '$firstHour-$lastHour$period';
      }

      // Fallback to original slot logic
      if (booking.slot == null) return '';
      final slotList = booking.slot;
      if (slotList is! List || slotList.isEmpty) return '';

      List<String> allTimes = [];

      // Collect all times from all slots
      for (var slot in slotList) {
        if (slot?.slotTimes != null) {
          for (var slotTime in slot.slotTimes) {
            final timeString = slotTime?.time ?? "";
            if (timeString.isNotEmpty) {
              allTimes.add(timeString);
            }
          }
        }
      }

      if (allTimes.isEmpty) return '';

      if (allTimes.length == 1) {
        return formatTimeSlot(allTimes[0]);
      }

      final firstTime = allTimes.first;
      final lastTime = allTimes.last;

      return '${formatTimeSlot(firstTime)} - ${formatTimeSlot(lastTime)}';
    } catch (e) {
      return '';
    }
  }

  List<Widget> _buildPlayerAvatarsFromScoreboard(dynamic booking) {
    List<Widget> avatars = [];
    
    // Get players from booking.teamA and booking.teamB directly
    final teamAPlayers = booking.teamA ?? [];
    final teamBPlayers = booking.teamB ?? [];
    final allTeamPlayers = [...teamAPlayers, ...teamBPlayers];
    
    for (var teamPlayer in allTeamPlayers) {
      final userId = teamPlayer.userId;
      final name = userId?.name ?? 'N/A';
      final profilePic = userId?.profilePic ?? '';
      avatars.add(_buildFilledPlayerFromScoreboard(profilePic, name, '', booking.bookingType ?? '', avatars.length, booking: booking));
    }
    
    // Fallback to openMatchId if no players found
    if (avatars.isEmpty) {
      final openMatchId = booking.openMatchId;
      if (openMatchId != null) {
        final allOpenTeamPlayers = [...?openMatchId.teamA, ...?openMatchId.teamB];
        for (var teamPlayer in allOpenTeamPlayers) {
          final playerId = booking.playerIds?.firstWhere(
            (p) => p.sId == teamPlayer.userId,
            orElse: () => PlayerId(),
          );
          final name = playerId?.name ?? 'N/A';
          final profilePic = playerId?.profilePic ?? '';
          avatars.add(_buildFilledPlayerFromScoreboard(profilePic, name, '', booking.bookingType ?? '', avatars.length, booking: booking));
        }
      }
    }
    
    // Fallback to scoreboard if still no players found
    if (avatars.isEmpty) {
      final scoreboard = booking.scoreboard;
      if (scoreboard?.teams != null) {
        int index = 0;
        for (var team in scoreboard.teams) {
          if (team.players != null) {
            for (var player in team.players) {
              final name = player.playerId?.name ?? player.name ?? 'N/A';
              final profilePic = player.playerId?.profilePic ?? '';
              avatars.add(_buildFilledPlayerFromScoreboard(profilePic, name, '', booking.bookingType ?? '', index, booking: booking));
              index++;
            }
          }
        }
      }
    }
    
    return avatars;
  }

  Widget _buildFilledPlayerFromScoreboard(String? imageUrl, String name, String lastName, String bookingType, int index, {dynamic booking}) {
    final isBlueTheme = bookingType.toLowerCase() == "openmatch" || bookingType.toLowerCase() == "normal";
    final firstLetter = name.trim().isNotEmpty
        ? '${name.trim()[0].toUpperCase()}${lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : ''}'
        : '??';

    return GestureDetector(
      onTap: () {
        if (booking != null) {
          _showPlayerDetailsDialog(booking);
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: !isBlueTheme ? const Color(0xffeaf0ff) : Color(0xffDFF7E6),
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
                    color: (!isBlueTheme ? AppColors.primaryColor : AppColors.secondaryColor).withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: 18,
                    color: !isBlueTheme ? AppColors.primaryColor : AppColors.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
                : Center(
              child: Text(
                firstLetter,
                style: TextStyle(
                  fontSize: 18,
                  color: !isBlueTheme ? AppColors.primaryColor : AppColors.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAddButtonsFromScoreboard(dynamic booking, String bookingType) {
    int totalPlayers = 0;
    
    // Count players from booking.teamA and booking.teamB directly
    totalPlayers = (booking.teamA?.length ?? 0) + (booking.teamB?.length ?? 0);
    
    // Fallback to openMatchId if no players found
    if (totalPlayers == 0) {
      final openMatchId = booking.openMatchId;
      if (openMatchId != null) {
        totalPlayers = (openMatchId.teamA?.length ?? 0) + (openMatchId.teamB?.length ?? 0);
      }
    }
    
    // Fallback to scoreboard if still no players found
    if (totalPlayers == 0) {
      final scoreboard = booking.scoreboard;
      if (scoreboard?.teams != null) {
        for (var team in scoreboard.teams) {
          totalPlayers += (team.players?.length ?? 0) as int;
        }
      }
    }

    // Ensure minimum 4 total avatars (players + add buttons)
    int remainingSlots = 4 - totalPlayers;
    if (remainingSlots < 0) remainingSlots = 0;
    if (totalPlayers + remainingSlots < 4) {
      remainingSlots = 4 - totalPlayers;
    }

    return List.generate(remainingSlots, (index) => _buildAvailableCircleFromScoreboard(bookingType, booking: booking));
  }

  Widget _buildAvailableCircleFromScoreboard(String bookingType, {dynamic booking}) {
    final isBlueTheme = bookingType.toLowerCase() == "openmatch" || bookingType.toLowerCase() == "normal";
    return GestureDetector(
      onTap: () {
        if (booking != null) {
          final matchId = booking.sId ?? "";
          final scoreboardId = booking.scoreboard?.sId ?? "";
          final bookingId = booking.sId ??"";
          final isMatchCreator = _isMatchCreator(booking);
          final isLoginUserInMatch = _isLoginUserInMatch(booking);

          if (isMatchCreator) {
            Get.bottomSheet(AppPlayersBottomSheetScore(matchId: matchId, teamName: "teamA",bookingId:bookingId ,), isScrollControlled: true);
          } else {
            AddPlayerBottomSheet.show(
              context,
              arguments: {
                "team": "teamA",
                "matchId": matchId,
                "scoreBoardId": scoreboardId,
                "needOpenMatchesForAllCourts": true,
                "needBookingHistory": true,
                "matchLevel": "Professional",
                "isLoginUser": !isLoginUserInMatch,
                "isMatchCreator": isMatchCreator,
              },
            );
          }
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: !isBlueTheme ? const Color(0xffeaf0ff) : Color(0xffDFF7E6),
          child: Icon(Icons.add, color: !isBlueTheme ? AppColors.primaryColor : AppColors.secondaryColor),
        ),
      ),
    );
  }

  Widget _collapsedCard(BuildContext context, int index, dynamic booking, List<Widget> playerAvatars, List<Widget> addButtons, String clubName, String address, String price, String type) {
    final isUpcoming = type == "upcoming";
    final bookingType = booking.bookingType ?? "";
    final isBlueTheme = bookingType.toLowerCase() == "upcoming" || bookingType.toLowerCase() == "confirmed";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: math.max((playerAvatars.length + addButtons.length) * 28 + 28, 4 * 28 + 28),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ]
              ),
              child: SizedBox(
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < playerAvatars.length; i++)
                      Positioned(
                        left: i * 30,
                        child: playerAvatars[i],
                      ),
                    for (int i = 0; i < addButtons.length; i++)
                      Positioned(
                        left: (playerAvatars.length * 30) + (i * 30),
                        child: addButtons[i],
                      ),
                  ],
                ),
              ),
            ),
            if (isUpcoming)
              GestureDetector(
                onTap: () {
                  _navigateToScoreboard(booking);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Transform.translate(
                    offset: const Offset(0, -3),
                    child: Container(
                      height: 23,
                      width: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.secondaryColor,
                      ),
                      child: Text(
                        "Play Now",
                        style: Get.textTheme.headlineSmall!
                            .copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ).paddingOnly(bottom: 12),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isUpcoming)
              GestureDetector(
                onTap: () {
                  _navigateToChat(booking);
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 5, right: 1,top: 2,bottom: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Start Chat with Players",
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ).paddingOnly(right: 10,left: 5),
                      Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: !isBlueTheme ? AppColors.primaryColor : AppColors.secondaryColor,
                          ),
                          child: Icon(Icons.chat_outlined, color: Colors.white, size: 18)
                      )
                    ],
                  ),
                ),
              ),
            if (!isUpcoming) const SizedBox.shrink(),
            Row(
              children: [
                if (isUpcoming) ...[
                  GestureDetector(
                    onTap: () {
                      _showPlayerRequestsBottomSheet(context, booking);
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const Icon(Icons.notifications, color: AppColors.primaryColor, size: 18),
                          RichText(
                            text: TextSpan(
                              text: 'Requests ',
                              style: Get.textTheme.labelSmall!.copyWith(decoration: TextDecoration.underline),
                              children: [
                                TextSpan(
                                  text: '(',
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: "0",
                                  style: Get.textTheme.labelSmall!.copyWith(color: AppColors.primaryColor),
                                ),
                                TextSpan(
                                  text: ')',
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (isUpcoming)
                  const Icon(Icons.share, size: 20, color: AppColors.darkGreyColor),
              ],
            ),
          ],
        ).paddingOnly(bottom: Get.height * 0.01),

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
                      const Icon(Icons.location_on, size: 14, color: AppColors.primaryColor),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          address,
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
                "₹ $price",
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
    );
  }

  Widget _expandedCard(BuildContext context, int index, dynamic booking, List<Widget> playerAvatars, List<Widget> addButtons, String clubName, String address, String price, String type) {
    final isUpcoming = type == "upcoming";
    final timeStr = _getTimeString(booking);

    // Count actual players from scoreboard
    int totalPlayers = 0;
    final scoreboard = booking.scoreboard;
    if (scoreboard?.teams != null) {
      for (var team in scoreboard.teams) {
        totalPlayers += (team.players?.length ?? 0) as int;
      }
    }

    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "${formatDate(booking.bookingDate)}${timeStr.isNotEmpty ? ' | $timeStr' : ''}",
                    style: Get.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.group, size: 18),
              SizedBox(width: 8),
              Text("4 atten@dee ($totalPlayers confirmed)", style: Get.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: math.max((playerAvatars.length + addButtons.length) * 28 + 28, 4 * 28 + 28),
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.greyColor),
            ),
            child: SizedBox(
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < playerAvatars.length; i++)
                    Positioned(
                      left: i * 30,
                      child: playerAvatars[i],
                    ),
                  for (int i = 0; i < addButtons.length; i++)
                    Positioned(
                      left: (playerAvatars.length * 30) + (i * 30),
                      child: addButtons[i],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                        const Icon(Icons.location_on, size: 14, color: AppColors.primaryColor),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            address,
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
              Text(
                "₹ $price",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1c46a0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToChat(dynamic booking) {
    final scoreboard = booking.scoreboard;
    if (scoreboard?.teams == null) {
      Get.snackbar("Error", "No team data available");
      return;
    }

    List<Map<String, dynamic>> teamAData = [];
    List<Map<String, dynamic>> teamBData = [];

    for (var team in scoreboard.teams) {
      if (team.players != null) {
        for (var player in team.players) {
          final playerData = {
            'userId': player.playerId?.sId ?? '',
            'name': player.playerId?.name ?? player.name ?? '',
            'lastName': '',
          };
          if (teamAData.length <= teamBData.length) {
            teamAData.add(playerData);
          } else {
            teamBData.add(playerData);
          }
        }
      }
    }

    Get.toNamed(RoutesName.chat, arguments: {
      "matchID": booking.sId ?? "",
      "teamA": teamAData,
      "teamB": teamBData,
    });
  }

  void _showPlayerRequestsBottomSheet(BuildContext context, dynamic booking) {
    final matchId = booking.sId ?? '';
    if (matchId.isEmpty) {
      Get.snackbar("Error", "Match ID not available");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: Get.height * 0.9,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Player Requests',
                        style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, color: AppColors.primaryColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.grey.shade300, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "You have new match requests! Accept the requests from the "
                        "players you want to play with. Once accepted, you'll be "
                        "paired for the match and can start competing right away.",
                    style: Get.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'No join requests yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlayerDetailsDialog(dynamic booking) {
    final scoreboard = booking.scoreboard;
    if (scoreboard?.teams == null) {
      Get.snackbar("Error", "No player data available");
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Player Information',
                    style: Get.textTheme.titleMedium
                        ?.copyWith(color: AppColors.primaryColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ],
              ),
              const Divider(thickness: 0.6),
              ..._buildPlayersFromScoreboard(scoreboard.teams),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlayersFromScoreboard(List<dynamic> teams) {
    List<Widget> playerWidgets = [];
    for (var team in teams) {
      if (team.players != null) {
        for (var player in team.players) {
          final name = player.playerId?.name ?? player.name ?? '';
          final phoneNumber = player.playerId?.phoneNumber?.toString() ?? '';
          final countryCode ='+91';
          final profilePic = player.playerId?.profilePic ?? '';

          playerWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondaryColor,
                    radius: 28,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: (profilePic.isNotEmpty)
                          ? CachedNetworkImageProvider(profilePic)
                          : null,
                      child: (profilePic.isEmpty)
                          ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Get.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '⭐ 0 XP Points ',
                              style: Get.textTheme.bodySmall
                                  ?.copyWith(color: Colors.orange),
                            ),
                            Text(
                              '| $countryCode-$phoneNumber',
                              style: Get.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryColor,
                      child: const Icon(Icons.call, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    return playerWidgets;
  }

  bool _isMatchCreator(dynamic booking) {
    final userId = storage.read('userId');
    if (userId == null || booking == null) return false;
    return booking.userId == userId.toString();
  }

  bool _isLoginUserInMatch(dynamic booking) {
    final userId = storage.read('userId');
    if (userId == null || booking == null) return false;

    final scoreboard = booking.scoreboard;
    if (scoreboard?.teams == null) return false;

    for (var team in scoreboard.teams) {
      if (team.players != null) {
        for (var player in team.players) {
          if (player.playerId?.sId == userId.toString()) return true;
        }
      }
    }
    return false;
  }

  void _navigateToScoreboard(dynamic booking) {
    final bookingId = booking.sId;
    if (bookingId != null && bookingId.isNotEmpty) {
      Get.toNamed(
        RoutesName.scoreBoard,
        arguments: {
          "bookingId": bookingId,
          "fromBookingHistory": true,
        },
      );
    } else {
      Get.snackbar("Error", "Booking ID not available");
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, dd MMM').format(date);
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing date: $e");
      }
      return dateStr;
    }
  }

  Widget bookingCardShimmer(BuildContext context, int index) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6,left: 15,right: 15,top: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: index % 2 == 0 ? Color(0xffC8D6FB) : Color(0xff3DBE64).withOpacity(0.5)),
          gradient: LinearGradient(
            colors: index % 2 == 0
                ? [Color(0xffF3F7FF), Color(0xff9EBAFF).withOpacity(0.3)]
                : [Color(0xffBFEECD).withOpacity(0.3), Color(0xffBFEECD).withOpacity(0.2)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: Get.width * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 36,
                  width: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  height: 50,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: Get.width * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: Get.width * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 28,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}