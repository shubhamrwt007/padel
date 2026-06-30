import 'dart:developer';

import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/data/response_models/americano_models/americano_rounds_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import '../../leaderBoard/leader_board_screen.dart';

class ScoreViewScreen extends GetView<ScoreViewController> {
  const ScoreViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: primaryAppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leadingButtonColor: AppColors.whiteColor,
        titleTextColor: AppColors.whiteColor,
        centerTitle: true,
        title: Obx(
          () => Text(
            controller.selectedTab.value == 0 ? "Score View" : "Americano",
          ),
        ),
        action: [
          Obx(() {
            if (controller.selectedTab.value == 0) {
              return const SizedBox.shrink();
            }
            return Center(
              child: Container(
                height: 25,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ToggleButtons(
                  isSelected: [
                    controller.isMyBooking.value,
                    !controller.isMyBooking.value,
                  ],
                  borderRadius: BorderRadius.circular(5),
                  constraints: const BoxConstraints(
                    minHeight: 25,
                    maxHeight: 25,
                    minWidth: 60,
                  ),
                  fillColor: AppColors.secondaryColor,
                  selectedColor: Colors.white,
                  color: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  renderBorder: false,
                  onPressed: (index) {
                    controller.isMyBooking.value = index == 0;
                    controller.fetchUserRounds();
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("My"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("All"),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        context: context,
      ),
      body: Stack(
        children: [
          // Background curved container
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 10),
              Obx(
                () => controller.selectedTab.value == 0
                    ? _buildRankingInfo()
                    : SizedBox.shrink(),
              ),
              Obx(
                () => controller.selectedTab.value == 0
                    ? _buildPodiumSection()
                    : _roundsTabContent(),
              ),
            ],
          ),
          // Leaderboard bottom sheet
          _buildLeaderboardSheet(context),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      return Container(
        width: Get.width,
        padding: const EdgeInsets.all(4),
        margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        decoration: BoxDecoration(
          color: const Color(0xFF4F6DF6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(2, (i) {
            final title = i == 0 ? 'Score Board' : 'Rounds';
            final selected = controller.selectedTab.value == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedTab.value = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF0B3BA7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    title,
                    style: Get.textTheme.headlineLarge!.copyWith(
                      color: AppColors.whiteColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _buildRankingInfo() {
    return Obx(() {
      final rankInfo = controller.myRankInfo.value;
      if (rankInfo == null || rankInfo.isInMatch == false) {
        return const SizedBox.shrink();
      }

      final rank = rankInfo.rank ?? 0;
      final message = rankInfo.message ?? "";

      if (message.isEmpty && rank == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0XFFCBD6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.labelBlackColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "#$rank",
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getPlayerInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final firstLetter = parts.first[0];
      final lastLetter = parts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
    return fullName.trim()[0].toUpperCase();
  }

  String _getPlayerName(AmericanoPlayer player) {
    final name = player.fullName;
    if (name != null && name.isNotEmpty) {
      return name.capitalizeFirstChar();
    }
    final registerName = player.registerUserId?.name;
    if (registerName != null && registerName.isNotEmpty) {
      return registerName.capitalizeFirstChar();
    }
    return "Anonymous";
  }

  Widget _buildPodiumSection() {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: Get.height * 0.4,
          child: const Center(child: LoadingWidget(color: Colors.white)),
        );
      }

      final isFixedTeam = controller.americanoFormat.value == "fixed_team";
      final hasData = isFixedTeam
          ? controller.leaderboardTeams.isNotEmpty
          : controller.leaderboardPlayers.isNotEmpty;

      if (!hasData) {
        return SizedBox(
          height: Get.height * 0.4,
          child: Center(
            child: Text(
              isFixedTeam ? 'No teams available' : 'No players available',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      final top3Teams = isFixedTeam
          ? controller.leaderboardTeams.take(3).toList()
          : [];
      final top3Players = isFixedTeam
          ? []
          : controller.leaderboardPlayers.take(3).toList();
      final len = isFixedTeam ? top3Teams.length : top3Players.length;

      return SizedBox(
        height: Get.height * 0.47,
        width: Get.width,
        child: Stack(
          children: [
            Transform.scale(
              scale: 1.1,
              child: SvgPicture.asset(
                Assets.images.imgBackgroundScoreView.path,
                fit: BoxFit.cover,
              ),
            ).paddingOnly(left: 10, top: 10),
            Center(
              child: SvgPicture.asset(
                Assets.images.imgScoreView.path,
                height: 250,
                fit: BoxFit.contain,
              ),
            ).paddingOnly(left: 30, right: 30),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2nd place (left side)
                  if (len > 1)
                    isFixedTeam
                        ? _teamPodiumItem(top3Teams[1], 2)
                        : _podiumItem(top3Players[1], 2)
                  else
                    const SizedBox(width: 80),

                  // 1st place (center, highest)
                  Container(
                    margin: EdgeInsets.only(
                      left: isFixedTeam ? Get.width * 0.05 : Get.width * 0.1,
                      right: isFixedTeam ? Get.width * 0.05 : Get.width * 0.1,
                    ),
                    child: isFixedTeam
                        ? _teamPodiumItem(top3Teams[0], 1)
                        : _podiumItem(top3Players[0], 1),
                  ),

                  // 3rd place (right side)
                  if (len > 2)
                    isFixedTeam
                        ? _teamPodiumItem(top3Teams[2], 3)
                        : _podiumItem(top3Players[2], 3)
                  else
                    const SizedBox(width: 80),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _teamPodiumItem(AmericanoTeam team, int position) {
    final heightOffsets = {
      1: Get.height * 0.018,
      2: Get.height * 0.068,
      3: Get.height * 0.098,
    };
    final points = team.totalPoints ?? 0;
    final players = team.players ?? [];

    return Padding(
      padding: EdgeInsets.only(top: heightOffsets[position]!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: position == 1 ? 80 : 70,
            height: position == 1 ? 74 : 62,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (players.isNotEmpty)
                  Positioned(
                    left: 0,
                    top: position == 1 ? 13 : 11,
                    child: _buildTeamPlayerAvatar(
                      players[0],
                      radius: position == 1 ? 24 : 20,
                    ),
                  ),
                if (players.length > 1)
                  Positioned(
                    right: 0,
                    top: position == 1 ? 13 : 11,
                    child: _buildTeamPlayerAvatar(
                      players[1],
                      radius: position == 1 ? 24 : 20,
                    ),
                  ),
                if (position == 1)
                  Positioned(
                    top: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        Assets.images.imgCrown.path,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 90,
            child: Text(
              team.teamName?.capitalizeFirstChar() ?? "Team",
              style: Get.textTheme.headlineSmall!.copyWith(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 90,
            child: Text(
              players
                  .map(
                    (p) => (p.fullName?.capitalizeFirst ?? "").split(' ').first,
                  )
                  .join(" & "),
              style: Get.textTheme.bodyMedium!.copyWith(
                color: Colors.white70,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 16,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$points",
              style: Get.textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ).paddingOnly(bottom: Get.height * 0.01),
          Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontSize: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPlayerAvatar(
    AmericanoTeamPlayer player, {
    required double radius,
  }) {
    final dynamic regUser = player.registerUserId;
    String? pic;
    if (regUser is RegisterUser) {
      pic = regUser.profilePic;
    } else if (regUser is Map) {
      pic = regUser['profilePic']?.toString();
    }
    final hasImage = pic != null && pic.isNotEmpty;
    final initials = _getPlayerInitials(player.fullName);
    final String? imageUrl = pic;

    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: radius + 1,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryColor,
        backgroundImage: (hasImage && imageUrl != null)
            ? CachedNetworkImageProvider(imageUrl)
            : null,
        child: !hasImage
            ? Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.5,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTeamPlayerAvatarForList(AmericanoTeamPlayer player) {
    final dynamic regUser = player.registerUserId;
    String? pic;
    if (regUser is RegisterUser) {
      pic = regUser.profilePic;
    } else if (regUser is Map) {
      pic = regUser['profilePic']?.toString();
    }
    final hasImage = pic != null && pic.isNotEmpty;
    final initials = _getPlayerInitials(player.fullName);
    final String? imageUrl = pic;

    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 11,
        backgroundColor: AppColors.primaryColor,
        backgroundImage: (hasImage && imageUrl != null)
            ? CachedNetworkImageProvider(imageUrl)
            : null,
        child: !hasImage
            ? Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _podiumItem(AmericanoPlayer player, int position) {
    final heightOffsets = {
      1: Get.height * 0.018,
      2: Get.height * 0.068,
      3: Get.height * 0.098,
    };

    final pic = player.registerUserId?.profilePic;
    final hasImage = pic != null && pic.isNotEmpty;
    final name = _getPlayerName(player);
    final initials = _getPlayerInitials(
      player.fullName ?? player.registerUserId?.name,
    );
    final points = player.totalPoints ?? 0;

    return Padding(
      padding: EdgeInsets.only(top: heightOffsets[position]!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: position == 1 ? 36 : 31,
                child: CircleAvatar(
                  radius: position == 1 ? 35 : 30,
                  backgroundColor: AppColors.primaryColor,
                  backgroundImage: hasImage
                      ? CachedNetworkImageProvider(pic)
                      : null,
                  child: !hasImage
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: position == 1 ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              if (position == 1)
                Positioned(
                  top: -16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      Assets.images.imgCrown.path,
                      width: 26,
                      height: 26,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: Get.textTheme.headlineSmall!.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 16,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "$points",
              style: Get.textTheme.bodyMedium!.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ).paddingOnly(bottom: Get.height * 0.03),
          Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontSize: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSheet(BuildContext context) {
    return Obx(() {
      final hasRanking =
          controller.myRankInfo.value != null &&
          controller.myRankInfo.value!.isInMatch != false;
      final size = (controller.selectedTab.value == 0 && hasRanking)
          ? 0.48
          : 0.55;

      return DraggableScrollableSheet(
        key: ValueKey('${controller.selectedTab.value}_$hasRanking'),
        initialChildSize: size,
        minChildSize: size,
        maxChildSize: 0.9,
        builder: (context, scroll) => Obx(() {
          final isFixedTeam = controller.americanoFormat.value == "fixed_team";
          final playersList = controller.leaderboardPlayers;
          final teamsList = controller.leaderboardTeams;
          final hasData = isFixedTeam
              ? teamsList.isNotEmpty
              : playersList.isNotEmpty;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                painter: UpwardCurvePainter(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffF9FAFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '#',
                                style: Get.textTheme.labelLarge!.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isFixedTeam ? 'Team / Players' : 'Player',
                                style: Get.textTheme.labelLarge!.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 55,
                              child: Text(
                                'W-L-T',
                                style: Get.textTheme.labelLarge!.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Diff',
                                style: Get.textTheme.labelLarge!.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'Points',
                                style: Get.textTheme.labelLarge!.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).paddingOnly(bottom: 10),
                      Expanded(
                        child: controller.isLoading.value
                            ? const Center(child: LoadingWidget())
                            : !hasData
                            ? const Center(
                                child: Text("No leaderboard data available"),
                              )
                            : ListView.builder(
                                controller: scroll,
                                itemCount: isFixedTeam
                                    ? teamsList.length
                                    : playersList.length,
                                itemBuilder: (_, idx) {
                                  if (isFixedTeam) {
                                    final team = teamsList[idx];
                                    final teamName = team.teamName ?? "Team";
                                    final players = team.players ?? [];
                                    final wins = team.wins ?? 0;
                                    final losses = team.losses ?? 0;
                                    final draws = team.draws ?? 0;
                                    final diff = team.pointDifference ?? 0;
                                    final diffSign = diff >= 0 ? "+" : "";
                                    final points = team.totalPoints ?? 0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primaryColor
                                              .withAlpha(30),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '${idx + 1}',
                                              style: Get.textTheme.bodySmall!
                                                  .copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 46,
                                                  height: 28,
                                                  child: Stack(
                                                    children: [
                                                      if (players.isNotEmpty)
                                                        Positioned(
                                                          left: 0,
                                                          top: -1,
                                                          child:
                                                              _buildTeamPlayerAvatarForList(
                                                                players[0],
                                                              ),
                                                        ),
                                                      if (players.length > 1)
                                                        Positioned(
                                                          left: 14,
                                                          top: 2,
                                                          child:
                                                              _buildTeamPlayerAvatarForList(
                                                                players[1],
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ).paddingOnly(right: 8),
                                                Expanded(
                                                  child: Tooltip(
                                                    message: players
                                                        .map(
                                                          (p) =>
                                                              p
                                                                  .fullName
                                                                  ?.capitalizeFirst ??
                                                              "",
                                                        )
                                                        .join(", "),
                                                    child: Container(
                                                      color: Colors.transparent,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            teamName,
                                                            style: Get
                                                                .textTheme
                                                                .bodySmall!
                                                                .copyWith(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          Text(
                                                            players
                                                                .map(
                                                                  (p) =>
                                                                      p
                                                                          .fullName
                                                                          ?.capitalizeFirst ??
                                                                      "",
                                                                )
                                                                .join(", "),
                                                            style: Get
                                                                .textTheme
                                                                .bodySmall!
                                                                .copyWith(
                                                                  color: Colors
                                                                      .black54,
                                                                  fontSize: 9,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 55,
                                            child: Text(
                                              "$wins - $losses - $draws",
                                              style: Get.textTheme.displaySmall!
                                                  .copyWith(fontSize: 11),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 45,
                                            child: Text(
                                              "$diffSign$diff",
                                              style: Get.textTheme.displaySmall!
                                                  .copyWith(fontSize: 11),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                height: 16,
                                                width: 30,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.secondaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  "$points",
                                                  style: Get
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ).paddingSymmetric(horizontal: 12, vertical: 8),
                                    );
                                  } else {
                                    final p = playersList[idx];
                                    final pic = p.registerUserId?.profilePic;
                                    final hasImage =
                                        pic != null && pic.isNotEmpty;
                                    final name = _getPlayerName(p);
                                    final initials = _getPlayerInitials(
                                      p.fullName ?? p.registerUserId?.name,
                                    );
                                    final wins = p.wins ?? 0;
                                    final losses = p.losses ?? 0;
                                    final draws = p.draws ?? 0;
                                    final diff = p.pointDifference ?? 0;
                                    final diffSign = diff >= 0 ? "+" : "";
                                    final points = p.totalPoints ?? 0;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primaryColor
                                              .withAlpha(30),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '${idx + 1}',
                                              style: Get.textTheme.bodySmall!
                                                  .copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 15,
                                                  backgroundColor:
                                                      AppColors.primaryColor,
                                                  backgroundImage: hasImage
                                                      ? CachedNetworkImageProvider(
                                                          pic,
                                                        )
                                                      : null,
                                                  child: !hasImage
                                                      ? Text(
                                                          initials,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        )
                                                      : null,
                                                ).paddingOnly(right: 10),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: Get
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                          color: Colors.black,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 55,
                                            child: Text(
                                              "$wins - $losses - $draws",
                                              style: Get.textTheme.displaySmall!
                                                  .copyWith(fontSize: 11),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 45,
                                            child: Text(
                                              "$diffSign$diff",
                                              style: Get.textTheme.displaySmall!
                                                  .copyWith(fontSize: 11),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                height: 16,
                                                width: 30,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.secondaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  "$points",
                                                  style: Get
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ).paddingSymmetric(horizontal: 12, vertical: 10),
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
                ),
              ),
              Positioned(
                top: -8,
                left: Get.width * 0.5 - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.starUnselectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      );
    });
  }

  Widget _roundsTabContent() {
    return Obx(() {
      if (controller.isLoadingRounds.value) {
        return SizedBox(
          height: Get.height * 0.35,
          child: const Center(child: LoadingWidget(color: Colors.white)),
        );
      }

      final match = controller.userLastMatch.value;
      if (match == null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: Get.height * 0.25,
              width: Get.width,
              alignment: Alignment.center,
              child: const Text(
                "No match found for this round",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -Get.height * 0.02),
              child: GestureDetector(
                onTap: () => Get.toNamed(
                  RoutesName.roundsScore,
                  arguments: {
                    'americanoMatchId': controller.americanoMatchId.value,
                    'filter': controller.isMyBooking.value
                        ? "my_match"
                        : "all_matches",
                  },
                ),
                child: Text(
                  "View All",
                  style: Get.textTheme.headlineSmall!.copyWith(
                    color: AppColors.whiteColor,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      final teamAPlayers = match.teamA?.players ?? [];
      final teamBPlayers = match.teamB?.players ?? [];

      final namesA = teamAPlayers
          .map((p) => p.fullName ?? p.registerUserId?.name ?? "")
          .toList();
      final namesB = teamBPlayers
          .map((p) => p.fullName ?? p.registerUserId?.name ?? "")
          .toList();

      final urlsA = teamAPlayers
          .map((p) => p.registerUserId?.profilePic ?? "")
          .toList();
      final urlsB = teamBPlayers
          .map((p) => p.registerUserId?.profilePic ?? "")
          .toList();

      final scoreA = match.teamA?.points?.toString() ?? "0";
      final scoreB = match.teamB?.points?.toString() ?? "0";

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: Get.height * 0.3,
            child: Stack(
              children: [
                Positioned(
                  top: Get.height * 0.04,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(
                      RoutesName.roundsScore,
                      arguments: {
                        'americanoMatchId': controller.americanoMatchId.value,
                        'filter': controller.isMyBooking.value
                            ? "my_match"
                            : "all_matches",
                      },
                    ),
                    child: Container(
                      height: Get.height * 0.25,
                      width: Get.width,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: SvgPicture.asset(Assets.images.imgRoundBackground.path),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    log("Match Status:-> ${match.status}");
                    if (match.status?.toLowerCase() == "scheduled") {
                      return;
                    }
                    Get.toNamed(
                      RoutesName.liveStreamAmericano,
                      arguments: {
                        "matchType": match.status,
                        "americanoMatchId": match.americanoMatchId,
                        "roundId": match.sId,
                      },
                    )?.then((_) {
                      controller.fetchUserRounds();
                    });
                  },
                  child: Container(
                    height: Get.height * 0.24,
                    width: Get.width,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111A79),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          controller.isMyBooking.value
                              ? "Your Match"
                              : "Latest Round",
                          style: Get.textTheme.titleSmall!.copyWith(
                            color: Colors.white,
                          ),
                        ).paddingOnly(bottom: Get.height * 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPlayerColumn(
                              imageUrls: urlsA,
                              names: namesA,
                              score: scoreA,
                            ),
                            SvgPicture.asset(
                              Assets.images.imgVsRounds.path,
                              height: 100,
                            ),
                            _buildPlayerColumn(
                              imageUrls: urlsB,
                              names: namesB,
                              score: scoreB,
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
          Transform.translate(
            offset: Offset(0, -Get.height * 0.05),
            child: GestureDetector(
              onTap: () => Get.toNamed(
                RoutesName.roundsScore,
                arguments: {
                  'americanoMatchId': controller.americanoMatchId.value,
                  'filter': controller.isMyBooking.value
                      ? "my_match"
                      : "all_matches",
                },
              ),
              child: Text(
                "View All",
                style: Get.textTheme.headlineSmall!.copyWith(
                  color: AppColors.whiteColor,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPlayerColumn({
    required List<String> imageUrls,
    required List<String> names,
    required String score,
  }) {
    final style = Get.textTheme.headlineSmall!.copyWith(
      color: AppColors.whiteColor,
    );

    String getPlayerInitials(String fullName) {
      if (fullName.isEmpty) return "?";
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final firstLetter = parts.first[0];
        final lastLetter = parts.last[0];
        return (firstLetter + lastLetter).toUpperCase();
      }
      return fullName.trim()[0].toUpperCase();
    }

    Widget buildAvatarItem(String name, String? url) {
      final hasImage = url != null && url.isNotEmpty;
      final initials = getPlayerInitials(name);
      return CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.greyColor,
        backgroundImage: hasImage ? CachedNetworkImageProvider(url) : null,
        child: !hasImage
            ? Text(
                initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    }

    final hasPlayer1 = names.isNotEmpty && names[0].isNotEmpty;
    final hasPlayer2 = names.length > 1 && names[1].isNotEmpty;

    final url1 = imageUrls.isNotEmpty ? imageUrls[0] : "";
    final url2 = imageUrls.length > 1 ? imageUrls[1] : "";

    // Helper to get formatted name
    String formatName(String full) {
      final first = full.split(' ').first;
      if (first.length > 8) {
        return "${first.substring(0, 6)}..";
      }
      return first;
    }

    return Column(
      children: [
        Container(
          width: 100,
          height: 70,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (hasPlayer1)
                Positioned(
                  left: hasPlayer2 ? 10 : 20,
                  child: buildAvatarItem(names[0], url1),
                ),
              if (hasPlayer2)
                Positioned(
                  left: 35,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF111A79),
                        width: 2,
                      ),
                    ),
                    child: buildAvatarItem(names[1], url2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPlayer1)
              Text(formatName(names[0]).capitalizeFirstChar(), style: style),
            if (hasPlayer2) ...[
              Text(' + ', style: style),
              Text(formatName(names[1]).capitalizeFirstChar(), style: style),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
