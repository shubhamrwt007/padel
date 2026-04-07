import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/auth/sign_up/widgets/sign_up_exports.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/league/live_and_complete_league_match_details/live_and_complete_league_match_controller.dart';
import 'package:padel_mobile/presentations/league/league_controller.dart';
import 'package:padel_mobile/presentations/league/widgets/build_sponsor_banner.dart';

class LiveAndCompleteLeagueMatchScreen extends StatefulWidget {
  const LiveAndCompleteLeagueMatchScreen({super.key});

  @override
  State<LiveAndCompleteLeagueMatchScreen> createState() => _LiveAndCompleteLeagueMatchScreenState();
}

class _LiveAndCompleteLeagueMatchScreenState extends State<LiveAndCompleteLeagueMatchScreen> {
  final LiveAndCompleteLeagueMatchController controller = Get.put(LiveAndCompleteLeagueMatchController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ytController = controller.youtubeController.value;
      if (controller.matchType.value == "live" && controller.showVideoPlayer.value && ytController != null) {
        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: ytController,
            showVideoProgressIndicator: true,

          ),
          builder: (context, player) => _buildScaffold(context, videoPlayer: player),
        );
      }
      return _buildScaffold(context);
    });
  }

  Widget _buildScaffold(BuildContext context, {Widget? videoPlayer}) {
    return Scaffold(
      appBar: primaryAppBar(title: Text("SPL"),centerTitle: true, context: context,
          action: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.textFieldColor,
              child: const Icon(Icons.share, size: 18,color: AppColors.primaryColor,),
            ).paddingOnly(right: 10)
          ]
      ),
      body: Obx(() {
        final isLoading = controller.isLoadingMatchDetails.value;
        final err = controller.matchDetailsError.value.trim();
        final history = controller.historyData.value;
        final sets = history?.sets ?? const [];

        if (controller.isLoadingHistory.value) {
          return const Center(child: LoadingWidget(color: AppColors.primaryColor,));
        }

        return Column(
          children: [
            controller.matchType.value == "live" && controller.showVideoPlayer.value
                ? _buildVideoSection(videoPlayer)
                : controller.matchType.value == "live" && controller.isStreamLoading.value
                    ? const SizedBox(height: 200, child: Center(child: LoadingWidget(color: AppColors.primaryColor,)))
                    : controller.matchType.value == "live"
                        ? const SizedBox.shrink()
                        : _buildSponsorBannerSafe(),
            _buildScoreSection(),
            _buildTabSelector(),
            if (isLoading) LinearProgressIndicator(color: AppColors.primaryColor,minHeight: 1,),
            if (!isLoading && err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  err,
                  style: Get.textTheme.bodySmall!.copyWith(color: Colors.red),
                ),
              ),
            Expanded(
              child: controller.selectedTab.value == 1
                  ? MatchStatsCard(controller: controller)
                  : controller.isLoadingHistory.value
                      ? const Center(child: LoadingWidget( color: AppColors.primaryColor,))
                      : sets.isEmpty
                          ? Center(child: Text("No history available", style: Get.textTheme.bodyMedium))
                          : ListView.builder(
                              itemCount: sets.length,
                              itemBuilder: (context, index) {
                                return _buildSetTwoCard(index).paddingOnly(bottom: 10);
                              },
                            ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoSection(Widget? player) {
    if (player != null) {
      return Stack(
        children: [
          player,
          // Positioned(left: 16, top: 16, child: _liveBadge()),
        ],
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          color: Colors.black,
          child: const Center(child: LoadingWidget(color: Colors.white54)),
        ),
        // Positioned(left: 16, top: 16, child: _liveBadge()),
      ],
    );
  }

  Widget _liveBadge() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFCD3529),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 4,
                backgroundColor: controller.isSocketConnected.value ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 6),
              const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ).paddingOnly(right: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 13),
              SizedBox(width: 6),
              Text("2K", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSponsorBannerSafe() {
    try {
      if (Get.isRegistered<LeagueController>()) {
        final leagueController = Get.find<LeagueController>();
        return BuildSponsorBanner(controller: leagueController);
      }
    } catch (e) {
      print('LeagueController not found: $e');
    }
    return const SizedBox(height: 200);
  }
  Widget _buildScoreSection() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 140, // 👈 decrease height here safely
          child: SvgPicture.asset(
            alignment: AlignmentGeometry.bottomCenter,
            Assets.imagesFipPromesisBg,
            fit: BoxFit.cover, // 👈 IMPORTANT
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40,vertical: 35),
          child: Obx(
                () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                /// TEAM A
                Container(
                  color: Colors.transparent,
                  width: Get.width*0.25,
                  child: Column(
                    children: [
                      Text(controller.historyData.value?.teamA?.clubName ?? "",
                          style: Get.textTheme.titleLarge!.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(_teamPlayersText(controller.historyData.value?.teamA),
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),

                /// SCORE
                Transform.translate(
                  offset: Offset(0, 0),
                  child: Text(
                    "${controller.teamAScore.value} : ${controller.teamBScore.value}",
                    style: Get.textTheme.titleLarge!.copyWith(color: Colors.black,fontSize: 40),
                  ),
                ),

                /// TEAM B
                Container(
                  color: Colors.transparent,
                  width: Get.width*0.25,
                  child: Column(
                    children: [
                      Text(controller.historyData.value?.teamB?.clubName ?? "",
                          style: Get.textTheme.titleLarge!.copyWith(fontSize: 20,color: AppColors.secondaryColor)),
                      const SizedBox(height: 6),
                      Text(_teamPlayersText(controller.historyData.value?.teamB),
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow:  [
          BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0.3,
              offset: Offset(0, 6))
        ],
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.onTabChanged(0),
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
                    Icon(Icons.history,color: controller.selectedTab.value == 0
                        ? AppColors.primaryColor
                        :AppColors.textColor,size: 18,),
                    const SizedBox(width: 6),
                    Text('History',style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,
                      color: controller.selectedTab.value == 0
                          ? AppColors.primaryColor
                          : AppColors.textColor,),),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.onTabChanged(1),
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
                    Icon(Icons.table_chart_outlined,size: 18,
                      color: controller.selectedTab.value == 1
                          ? AppColors.primaryColor
                          : AppColors.textColor,
                    ),
                    const SizedBox(width: 6),
                    Text('Statistics',style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,
                      color: controller.selectedTab.value == 1
                          ? AppColors.primaryColor
                          : AppColors.textColor,),)
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
  Widget _buildSetTwoCard(int index) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 6),
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                for (int i = 0; i < controller.isSet2Expanded.length; i++) {
                  controller.isSet2Expanded[i] = i == index ? !controller.isSet2Expanded[index] : false;
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
                          _setTitle(index),
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(_setScoreText(index),style: Get.textTheme.headlineMedium).paddingOnly(right: 5),
                            Text(_setWinnerText(index),style: Get.textTheme.labelMedium!.copyWith(color: _getWinnerColor(index),fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    CircleAvatar(
                        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                        child: Icon(
                          controller.isSet2Expanded[index]
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.black,
                        )),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: controller.isSet2Expanded.length > index && controller.isSet2Expanded[index]
                  ? _buildExpandedSetGrid(index)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ));
  }
}
class MatchStatsCard extends StatelessWidget {
  final LiveAndCompleteLeagueMatchController controller;
  const MatchStatsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = controller.statisticsData.value?.statistics;
    final teamA = stats?.teamA;
    final teamB = stats?.teamB;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          )
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
                  controller.historyData.value?.teamA?.teamName ?? "Team A",
                  style: Get.textTheme.labelLarge!.copyWith(color: AppColors.primaryColor,fontWeight: FontWeight.w600),
                ),
                Text(
                  controller.historyData.value?.teamB?.teamName ?? "Team B",
                  style: Get.textTheme.labelLarge!.copyWith(color: AppColors.secondaryColor,fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade300,thickness: 0.5,),
            const SizedBox(height: 10),

            /// Stats
            _statRow("Total Points", teamA?.totalPoints ?? 0, teamB?.totalPoints ?? 0),
            _statRow("Break Point Opportunities", teamA?.breakPointOpportunities ?? 0, teamB?.breakPointOpportunities ?? 0),
            _statRow("Break Points won", teamA?.breakPointsWon ?? 0, teamB?.breakPointsWon ?? 0),
            _statRow("Golden Point", teamA?.goldenPoints ?? 0, teamB?.goldenPoints ?? 0),
            _statRow("Winners", teamA?.winners ?? 0, teamB?.winners ?? 0),
            _statRow("Forced Errors", teamA?.forcedErrors ?? 0, teamB?.forcedErrors ?? 0),
            _statRow("Unforced Errors", teamA?.unforcedErrors ?? 0, teamB?.unforcedErrors ?? 0),
            _statRow("First Serve%", teamA?.firstServePercentage ?? 0, teamB?.firstServePercentage ?? 0, isPercentage: true),
          ],
        ),
      ),
    );
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
                  style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600)
              ),
              Text(
                title,
                style: Get.textTheme.labelMedium!.copyWith(color: AppColors.textColor,fontWeight: FontWeight.w500),
              ),
              Text(
                  isPercentage ? "$right%" : right.toString().padLeft(2, '0'),
                  style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600)
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Progress Bars (Exact Image Style)
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const gap = 8.0;

              final halfWidth = (totalWidth - gap) / 2;

              final leftProgressWidth = halfWidth * leftRatio;
              final rightProgressWidth = halfWidth * rightRatio;

              return Row(
                children: [
                  /// LEFT SIDE
                  Stack(
                    children: [
                      // Light base
                      Container(
                        width: halfWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xffD9E1F2), // light blue
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      // Dark progress
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
                      // Light base
                      Container(
                        width: halfWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xffDDEEE5), // light green
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      // Dark progress
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

extension _MatchDetailsUiHelpers on _LiveAndCompleteLeagueMatchScreenState {
  String _teamPlayersText(dynamic team) {
    try {
      final players = team?.players as List<dynamic>?;
      if (players == null || players.isEmpty) return "-";
      final names = players
          .map((p) => (p.playerName ?? "").toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isEmpty) return "-";
      return names.join(" &\n");
    } catch (_) {
      return "-";
    }
  }

  String _setTitle(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return "Set";
    final setNo = sets[index].setNumber;
    if (setNo == null) return "Set";
    final maxSetNo = sets.map((s) => s.setNumber ?? 0).reduce((a, b) => a > b ? a : b);
    return setNo == maxSetNo ? "Final Set" : "Set $setNo";
  }

  String _setScoreText(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return "-";
    final s = sets[index].finalScore;
    final a = s?.teamA;
    final b = s?.teamB;
    if (a == null || b == null) return "-";
    return "$a-$b";
  }

  String _setWinnerText(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return "";
    final s = sets[index].finalScore;
    final a = s?.teamA ?? 0;
    final b = s?.teamB ?? 0;
    final winnerTeamName = a == b
        ? null
        : (a > b
            ? controller.historyData.value?.teamA?.teamName
            : controller.historyData.value?.teamB?.teamName);
    return winnerTeamName == null ? "" : "($winnerTeamName)";
  }

  Color _getWinnerColor(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return AppColors.primaryColor;
    final s = sets[index].finalScore;
    final a = s?.teamA ?? 0;
    final b = s?.teamB ?? 0;
    if (a == b) return AppColors.primaryColor;
    return a > b ? AppColors.primaryColor : AppColors.secondaryColor;
  }

  Widget _buildRoundsForSet(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return const SizedBox.shrink();
    final rounds = sets[index].rounds ?? const [];
    if (rounds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "No rounds available",
            style: Get.textTheme.bodySmall,
          ),
        ),
      );
    }

    final visibleRounds = rounds.toList();
    final cols = visibleRounds.length;
    const int maxVisible = 8;
    final needsScroll = cols > maxVisible;

    String leftTimeLabel() {
      final completedAt = visibleRounds.first.completedAt ?? "";
      print("Debug completedAt: '$completedAt'"); // Debug line
      if (completedAt.isEmpty) return "-";
      
      // Try to parse different time formats
      try {
        // If it's a full datetime string, extract time part
        if (completedAt.contains('T')) {
          final timePart = completedAt.split('T').last;
          if (timePart.contains(':')) {
            return timePart.substring(0, 5); // HH:MM format
          }
        }
        
        // If it already looks like time (contains colon)
        if (completedAt.contains(':')) {
          return completedAt.length >= 5 ? completedAt.substring(0, 5) : completedAt;
        }
        
        // Fallback to original logic
        return completedAt.length >= 5 ? completedAt.substring(completedAt.length - 5) : completedAt;
      } catch (e) {
        print("Error parsing time: $e");
        return "-";
      }
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        needsScroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 50 + (cols * 40.0),
                  child: _roundsContent(sets, index, visibleRounds, cols),
                ),
              )
            : _roundsContent(sets, index, visibleRounds, cols),
      ],
    );
  }

  Widget _roundsContent(List sets, int index, List visibleRounds, int cols) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 50),
                  for (int i = 0; i < cols; i++) Expanded(child: Center(child: Text("R${i + 1}", style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500)))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          visibleRounds.first.completedAt != null ? _parseTime(visibleRounds.first.completedAt!) : "-",
                          style: Get.textTheme.labelSmall!.copyWith(color: AppColors.labelBlackColor, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 30, decoration: BoxDecoration(color: const Color(0xff2D5BFF), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Text((sets[index].finalScore?.teamA ?? 0).toString(), style: Get.textTheme.headlineMedium!.copyWith(color: AppColors.primaryColor)),
                    ],
                  ),
                  for (int i = 0; i < cols; i++)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (visibleRounds[i].pointsAtEnd?.teamA != null)
                              Text(visibleRounds[i].pointsAtEnd!.teamA!, style: Get.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(thickness: 0.5, color: Colors.grey.shade300).paddingOnly(left: 30),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 25),
                      Container(width: 4, height: 30, decoration: BoxDecoration(color: AppColors.secondaryColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Text((sets[index].finalScore?.teamB ?? 0).toString(), style: Get.textTheme.headlineMedium!.copyWith(color: AppColors.secondaryColor)),
                    ],
                  ),
                  for (int i = 0; i < cols; i++)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (visibleRounds[i].pointsAtEnd?.teamB != null)
                              Text(visibleRounds[i].pointsAtEnd!.teamB!, style: Get.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _parseTime(String completedAt) {
    try {
      if (completedAt.contains('T')) return completedAt.split('T').last.substring(0, 5);
      if (completedAt.contains(':')) return completedAt.length >= 5 ? completedAt.substring(0, 5) : completedAt;
      return completedAt.length >= 5 ? completedAt.substring(completedAt.length - 5) : completedAt;
    } catch (_) {
      return "-";
    }
  }

  Widget _buildExpandedSetGrid(int index) => _buildRoundsForSet(index);

  Widget _wlWidget(bool? isWin) {
    if (isWin == null) return const Text("-");
    return Text(
      isWin ? "W" : "L",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: isWin ? AppColors.secondaryColor : Colors.red,
      ),
    );
  }

  Widget _roundTitle(String text) {
    const double colWidth = 32;
    return SizedBox(
      width: colWidth,
      child: Center(
        child: Text(
          text,
          style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _roundCell(Widget child) {
    const double colWidth = 32;
    return SizedBox(
      width: colWidth,
      child: Center(child: child),
    );
  }
}