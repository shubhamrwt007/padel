import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_owner/configs/app_colors.dart';
import 'package:padel_owner/configs/components/app_bar.dart';
import 'package:padel_owner/generated/assets.dart';
import 'package:padel_owner/presentations/tournament/match_details/match_details_controller.dart';

class MatchDetailsScreen extends StatelessWidget {
  final MatchDetailsController controller = Get.put(MatchDetailsController());

  MatchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
        title: Text("Match Details"),
        centerTitle: true,
        context: context,
        action: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.share,
              size: 18,
              color: AppColors.blackColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _liveMatchCard(),
          _buildTabSelector(),
          Expanded(
            child: Obx(
              () => controller.selectedTab.value == 1
                  ? MatchStatsCard(controller: controller)
                  : Obx(() {
                      if (controller.isHistoryLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return _buildSetTwoCard(
                            index,
                          ).paddingOnly(bottom: 10);
                        },
                      );
                    }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveMatchCard() {
    return Obx(() {
      if (controller.isHistoryLoading.value == true) {
        return SizedBox(
          width: Get.width,
          height: 200,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      var res = controller.historyData.value?.data?.status?.toLowerCase();
      Color statusColor = res == 'finished'
          ? Color(0xff616161)
          : res == 'live'
          ? Color(0xffD32F2F)
          : Color(0xff2E4DB7);

      // ── Get data from historyData ────────────────────────────
      final data = controller.historyData.value?.data;
      final teamA = data?.teamA;
      final teamB = data?.teamB;

      // ── Sets won count ────────────────────────────────────────
      int teamASetsWon = controller.teamAScore.toInt();
      int teamBSetsWon = controller.teamBScore.toInt();

      // ── Player names ──────────────────────────────────────────
      final teamAPlayers = teamA?.players ?? [];
      final teamBPlayers = teamB?.players ?? [];

      final teamAPlayer1 = teamAPlayers.isNotEmpty
          ? teamAPlayers[0].playerName ?? ''
          : '';
      final teamAPlayer2 = teamAPlayers.length > 1
          ? teamAPlayers[1].playerName ?? ''
          : '';
      final teamBPlayer1 = teamBPlayers.isNotEmpty
          ? teamBPlayers[0].playerName ?? ''
          : '';
      final teamBPlayer2 = teamBPlayers.length > 1
          ? teamBPlayers[1].playerName ?? ''
          : '';

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 0),
            decoration: const BoxDecoration(),
            child: Stack(
              children: [
                SvgPicture.asset(
                  Assets.imagesFipPromesisBg,
                  fit: BoxFit.cover,
                  width: Get.width,
                ),
                Column(
                  children: [
                    const SizedBox(height: 10),

                    /// LIVE BADGE
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              controller.historyData.value?.data?.status ??
                                  'Live',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// SCORE ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ── TEAM A ──────────────────────────────
                        _teamColumn(
                          teamA?.clubName.toString() ?? 'Team A',
                          "https://i.pravatar.cc/150?img=1",
                          "https://i.pravatar.cc/150?img=2",
                          teamAPlayer1,
                          teamAPlayer2,
                          AppColors.primaryColor,
                        ),

                        // ── SETS SCORE ───────────────────────────
                        Transform.translate(
                          offset: const Offset(2, 18),
                          child: Text(
                            '$teamASetsWon : $teamBSetsWon',
                            style: Get.textTheme.titleLarge!.copyWith(
                              color: AppColors.blackColor,
                              fontSize: 30,
                            ),
                          ),
                        ),

                        // ── TEAM B ──────────────────────────────
                        _teamColumn(
                          teamB?.clubName ?? 'Team B',
                          "https://i.pravatar.cc/150?img=3",
                          "https://i.pravatar.cc/150?img=4",
                          teamBPlayer1,
                          teamBPlayer2,
                          AppColors.secondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ── Updated _teamColumn ───────────────────────────────────────
  Widget _teamColumn(
    String teamName,
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
          /// TEAM NAME
          Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Get.textTheme.titleLarge!.copyWith(
              color: color,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 15),

          /// STACKED AVATARS
          SizedBox(
            height: 40,
            width: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [_avatar(img1, 0), _avatar(img2, 24)],
            ),
          ),

          const SizedBox(height: 8),

          /// PLAYER NAMES
          Text(
            name1.isNotEmpty && name2.isNotEmpty
                ? "$name1 &\n$name2"
                : name1.isNotEmpty
                ? name1
                : '',
            textAlign: TextAlign.center,
            style: Get.textTheme.displaySmall,
          ),
        ],
      ),
    );
  }

  Widget _avatar(String url, double left) {
    return Positioned(
      left: left,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0.3,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.selectedTab.value = 0;
                  controller.fetchHistory();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.selectedTab.value == 0
                        ? AppColors.whiteColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: controller.selectedTab.value == 0
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF3B5BDB,
                              ).withValues(alpha: 0.08),
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
                      Icon(
                        Icons.history,
                        color: controller.selectedTab.value == 0
                            ? AppColors.primaryColor
                            : AppColors.textColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'History',
                        style: Get.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: controller.selectedTab.value == 0
                              ? AppColors.primaryColor
                              : AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.selectedTab.value = 1;
                  controller.fetchStatistics();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.selectedTab.value == 1
                        ? AppColors.whiteColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: controller.selectedTab.value == 1
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF3B5BDB,
                              ).withValues(alpha: 0.08),
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
                      Icon(
                        Icons.table_chart_outlined,
                        size: 18,
                        color: controller.selectedTab.value == 1
                            ? AppColors.primaryColor
                            : AppColors.textColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Statistics',
                        style: Get.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: controller.selectedTab.value == 1
                              ? AppColors.primaryColor
                              : AppColors.textColor,
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
    );
  }

  Widget _buildSetTwoCard(int index) {
    return Obx(() {
      final sets = controller.historySets;
      if (index >= sets.length) return const SizedBox.shrink();

      final set = sets[index];
      final rounds = set.rounds ?? [];
      final int roundCount = rounds.length;
      final String? setWinner = set.setWinner;

      final int finalA = set.finalScore?.teamA ?? 0;
      final int finalB = set.finalScore?.teamB ?? 0;
      final bool teamAWonSet = finalA > finalB;
      final String winnerName = teamAWonSet
          ? controller.historyTeamAName()
          : controller.historyTeamBName();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 6),
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────
              GestureDetector(
                onTap: () {
                  for (int i = 0; i < controller.isSet2Expanded.length; i++) {
                    controller.isSet2Expanded[i] = i == index
                        ? !controller.isSet2Expanded[index]
                        : false;
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.setLabel(index),
                            style: Get.textTheme.displaySmall,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                controller.setFinalScoreString(index),
                                style: Get.textTheme.headlineMedium,
                              ).paddingOnly(right: 5),
                              Text(
                                '($winnerName)',
                                style: Get.textTheme.displaySmall!.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              roundCount == 0 && setWinner != null
                                  ?
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4,horizontal: 9),
                                decoration: BoxDecoration(
                                    color: AppColors.textFieldColor,
                                    borderRadius: BorderRadius.circular(7)
                                ),
                                child: Text("Tie Brake",style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.primaryColor),),
                              ).paddingOnly(left: 10):SizedBox.shrink()
                            ],
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          controller.isSet2Expanded[index]
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── EXPANDED ROUNDS OR WINNER ────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: controller.isSet2Expanded[index]
                    ? (roundCount == 0 && setWinner != null
                        ? _buildWinnerColumn(setWinner)
                        : Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Scrollable rounds section ──────────
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: IntrinsicWidth(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // ── ROUND HEADERS R1, R2... ───
                                            Row(
                                              children: [
                                                const SizedBox(width: 80),
                                                // ← team name space
                                                ...List.generate(
                                                  roundCount,
                                                  (i) => SizedBox(
                                                    width: 40,
                                                    // ← fixed width per round
                                                    child: Text(
                                                      'R${i + 1}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: Get
                                                          .textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 5),

                                            // ── TEAM A ROW ──────────────────
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                // ── Team A label + score ───
                                                SizedBox(
                                                  width: 80,
                                                  child: Row(
                                                    children: [
                                                      RotatedBox(
                                                        quarterTurns: 3,
                                                        child: Text(
                                                          controller
                                                              .historyTeamAName(),
                                                          style: Get
                                                              .textTheme
                                                              .displaySmall!
                                                              .copyWith(
                                                            fontSize: 9,
                                                                color: AppColors
                                                                    .labelBlackColor,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        width: 4,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xff2D5BFF,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '$finalA',
                                                        style: Get
                                                            .textTheme
                                                            .headlineMedium!
                                                            .copyWith(
                                                              color: AppColors
                                                                  .primaryColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // ── Points per round ────────
                                                ...List.generate(roundCount, (
                                                  i,
                                                ) {
                                                  final pts =
                                                      rounds[i]
                                                          .pointsAtEnd
                                                          ?.teamA ??
                                                      '-';
                                                  final bool isLast =
                                                      i == roundCount - 1;
                                                  final bool isWinner =
                                                      rounds[i].gameWinner == 'teamA';
                                                  return SizedBox(
                                                    width: 40,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isWinner)
                                                          Transform.rotate(
                                                            angle: -0.3,
                                                            child: SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child: Image.asset(
                                                                Assets.winnerImage,
                                                                width: 14,
                                                                height: 14,
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          const SizedBox(height: 14),
                                                        Text(
                                                          pts,
                                                          textAlign: TextAlign.center,
                                                          style: Get
                                                              .textTheme
                                                              .titleSmall!
                                                              .copyWith(
                                                            fontSize: 12,
                                                                color:
                                                                // isLast
                                                                //     ? AppColors.primaryColor
                                                                //     :
                                                                Colors.grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),

                                            const SizedBox(height: 0),
                                            Divider(
                                              thickness: 0.5,
                                              color: Colors.grey.shade300,
                                            ).paddingOnly(left: 15),
                                            const SizedBox(height: 0),

                                            // ── TEAM B ROW ──────────────────
                                            Row(
                                              children: [
                                                // ── Team B label + score ───
                                                SizedBox(
                                                  width: 80,
                                                  child: Row(
                                                    children: [
                                                      RotatedBox(
                                                        quarterTurns: 3,
                                                        child: Text(
                                                          controller
                                                              .historyTeamBName(),
                                                          style: Get
                                                              .textTheme
                                                              .displaySmall!
                                                              .copyWith(
                                                            fontSize: 9,
                                                                color: AppColors
                                                                    .labelBlackColor,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Container(
                                                        width: 4,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .secondaryColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '$finalB',
                                                        style: Get
                                                            .textTheme
                                                            .headlineMedium!
                                                            .copyWith(
                                                              color: AppColors
                                                                  .secondaryColor,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // ── Points per round ────────
                                                ...List.generate(roundCount, (
                                                  i,
                                                ) {
                                                  final pts =
                                                      rounds[i]
                                                          .pointsAtEnd
                                                          ?.teamB ??
                                                      '-';
                                                  final bool isLast =
                                                      i == roundCount - 1;
                                                  final bool isWinner =
                                                      rounds[i].gameWinner == 'teamB';
                                                  return SizedBox(
                                                    width: 40,
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isWinner)
                                                          Transform.rotate(
                                                            angle: -0.3,
                                                            child: SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child: Image.asset(
                                                                Assets.winnerImage,
                                                                width: 14,
                                                                height: 14,
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          const SizedBox(height: 14),
                                                        Text(
                                                          pts,
                                                          textAlign: TextAlign.center,
                                                          style: Get
                                                              .textTheme
                                                              .titleSmall!
                                                              .copyWith(
                                                            fontSize: 12,
                                                                color:
                                                                // isLast
                                                                //     ? AppColors.secondaryColor
                                                                //     :
                                                                Colors.grey,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ))
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
  Widget _buildWinnerColumn(String setWinner) {
    final winnerTeamName = setWinner == 'teamA'
        ? controller.historyTeamAName()
        : controller.historyTeamBName();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Transform.rotate(
            angle: -0.3,
            child: Image.asset(
              Assets.winnerImage,
              width: 30,
              height: 30,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            winnerTeamName,
            style: Get.textTheme.headlineMedium!.copyWith(
              fontSize: 14,
              color: setWinner == 'teamA'
                  ? AppColors.primaryColor
                  : AppColors.secondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchStatsCard extends StatelessWidget {
  final MatchDetailsController controller;

  const MatchStatsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isStatisticsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final teamA = controller.statsTeamA;
      final teamB = controller.statsTeamB;

      // ── Team names from historyData ───────────────────────
      final teamAName = controller.historyTeamAName();
      final teamBName = controller.historyTeamBName();

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 6),
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    teamAName,
                    style: Get.textTheme.labelLarge!.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    teamBName,
                    style: Get.textTheme.labelLarge!.copyWith(
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade300, thickness: 0.5),
              const SizedBox(height: 10),

              /// Stats
              _statRow(
                "Total Points",
                teamA?.totalPoints ?? 0,
                teamB?.totalPoints ?? 0,
              ),
              _statRow(
                "Break Point Opportunities",
                teamA?.breakPointOpportunities ?? 0,
                teamB?.breakPointOpportunities ?? 0,
              ),
              _statRow(
                "Break Points Won",
                teamA?.breakPointsWon ?? 0,
                teamB?.breakPointsWon ?? 0,
              ),
              _statRow(
                "Break Points Saved",
                teamA?.breakPointsSaved ?? 0,
                teamB?.breakPointsSaved ?? 0,
              ),
              _statRow(
                "Golden Point",
                teamA?.goldenPoints ?? 0,
                teamB?.goldenPoints ?? 0,
              ),
              _statRow("Winners", teamA?.winners ?? 0, teamB?.winners ?? 0),
              _statRow("Errors", teamA?.errors ?? 0, teamB?.errors ?? 0),
              // _statRow(
              //   "Forced Errors",
              //   teamA?.forcedErrors ?? 0,
              //   teamB?.forcedErrors ?? 0,
              // ),
              // _statRow(
              //   "Unforced Errors",
              //   teamA?.unforcedErrors ?? 0,
              //   teamB?.unforcedErrors ?? 0,
              // ),
              _statRow(
                "First Serve %",
                teamA?.firstServePercentage ?? 0,
                teamB?.firstServePercentage ?? 0,
                isPercentage: true,
              ),
              // _statRow("Aces", teamA?.aces ?? 0, teamB?.aces ?? 0),
              _statRow(
                "Double Faults",
                teamA?.doubleFaults ?? 0,
                teamB?.doubleFaults ?? 0,
              ),
              _statRow("Faults", teamA?.faults ?? 0, teamB?.faults ?? 0),
            ],
          ),
        ),
      );
    });
  }

  Widget _statRow(
    String title,
    num left,
    num right, {
    bool isPercentage = false,
  }) {
    double total = (left + right) == 0 ? 1 : (left + right).toDouble();
    double leftRatio = left / total;
    double rightRatio = right / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          /// Numbers + Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPercentage ? "$left%" : left.toString().padLeft(2, '0'),
                style: Get.textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                title,
                style: Get.textTheme.displaySmall!.copyWith(
                  color: AppColors.textColor,
                ),
              ),
              Text(
                isPercentage ? "$right%" : right.toString().padLeft(2, '0'),
                style: Get.textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Progress Bars (Exact Image Style)
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const gap = 14.0;
              final halfWidth = (totalWidth - gap) / 2;
              final leftProgressWidth = halfWidth * leftRatio;
              final rightProgressWidth = halfWidth * rightRatio;

              return Row(
                children: [
                  /// LEFT SIDE
                  Stack(
                    children: [
                      Container(
                        width: halfWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xffD9E1F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          width: leftProgressWidth,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xff2E4CB8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: gap),

                  /// RIGHT SIDE
                  Stack(
                    children: [
                      Container(
                        width: halfWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xffDDEEE5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Container(
                        width: rightProgressWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xff35B368),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

}
