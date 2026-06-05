import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/auth/sign_up/widgets/sign_up_exports.dart';
import 'package:padel_mobile/presentations/ipt_tournament/ipt_tournament_controller.dart';
import 'package:padel_mobile/presentations/ipt_tournament/widgets/ipt_build_sponsor_banner.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/generated/assets.dart';
import '../../../data/response_models/ipt_tournament/get_ipt_tournament_match_details_model.dart';
import 'live_stream_americano_controller.dart';

class LiveStreamAmericanoScreen extends StatefulWidget {
  const LiveStreamAmericanoScreen({super.key});

  @override
  State<LiveStreamAmericanoScreen> createState() => _LiveStreamAmericanoScreenState();
}

class _LiveStreamAmericanoScreenState extends State<LiveStreamAmericanoScreen> {
  final LiveStreamAmericanoController controller = Get.put(LiveStreamAmericanoController());

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ytController = controller.youtubeController.value;
      if (controller.matchType.value == "live" && controller.showVideoPlayer.value && ytController != null) {
        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: ytController,
            showVideoProgressIndicator: false,
            progressIndicatorColor: Colors.transparent,
            progressColors: const ProgressBarColors(
              playedColor: Colors.transparent,
              handleColor: Colors.transparent,
              bufferedColor: Colors.transparent,
              backgroundColor: Colors.transparent,
            ),
            bottomActions: [
              const Spacer(),
              Obx(() => controller.showGoToLiveButton.value
                  ? GestureDetector(
                      onTap: controller.goToLive,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCD3529),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Go Live",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              const SizedBox(width: 8),
              FullScreenButton(),
            ],
            onReady: () {
              ytController.addListener(() {});
            },
          ),
          builder: (context, player) => _buildScaffold(context, videoPlayer: player),
        );
      }
      return _buildScaffold(context);
    });
  }

  Widget _buildScaffold(BuildContext context, {Widget? videoPlayer}) {
    return Scaffold(
      appBar: primaryAppBar(title: Text(controller.matchType.value == "live" ?"Live Match":"Match Details"),centerTitle: true, context: context,
          // action: [
          //   CircleAvatar(
          //     radius: 18,
          //     backgroundColor: AppColors.textFieldColor,
          //     child: const Icon(Icons.share, size: 18,color: AppColors.primaryColor,),
          //   ).paddingOnly(right: 10)
          // ]
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
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  ...List.generate(
                                    sets.length,
                                    (index) => _buildSetTwoCard(index).paddingOnly(bottom: 10),
                                  ),
                                  _pointHistorySection().paddingSymmetric(horizontal: 16),
                                ],
                              ),
                            ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoSection(Widget? player) {
    if (player != null) {
      return player;
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
      ],
    );
  }

  Widget _buildSponsorBannerSafe() {
    try {
      if (Get.isRegistered<IptTournamentController>()) {
        final iptTournamentController = Get.find<IptTournamentController>();
        return Column(
          children: [
            BuildIptTournamentTitleSponsor(controller: iptTournamentController),
            Obx(() {
              final sponsors = iptTournamentController.sponsors.value?.data?.sponsors ?? [];
              if (sponsors.isEmpty) return const SizedBox.shrink();
              return BuildIptTournamentMoreSponsor(sponsors: sponsors);
            }),
          ],
        );
      }
    } catch (e) {
      print('IptTournamentController not found: $e');
    }
    return const SizedBox.shrink();
  }
  Widget _buildScoreSection() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          // height: 140, // 👈 decrease height here safely
          child: SvgPicture.asset(
            alignment: AlignmentGeometry.center,
            Assets.imagesFipPromesisBg,
            fit: BoxFit.cover, // 👈 IMPORTANT
          ),
        ),
        Transform.translate(
          offset:controller.winnerTeam != null? Offset(0, -10):Offset(0, 0),
          child: Padding(
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
                        if (controller.winnerTeam != null)
                          Obx(() => controller.winnerTeam == 'teamA'
                              ? Image.asset(Assets.imagesImgCrown, width: 24, height: 24)
                              : const SizedBox(height: 24)),
                        Text(controller.historyData.value?.teamA?.teamName ?? "",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Get.textTheme.titleLarge!.copyWith(fontSize: 20)),
                        const SizedBox(height: 6),
                        Text(_teamPlayersText(controller.historyData.value?.teamA).capitalizeFirstChar(),
                            style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,fontSize: 11),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),

                  /// SCORE
                  Transform.translate(
                    offset: Offset(-3, 8),
                    child: Column(
                      children: [
                        Text(
                          "${controller.teamAScore.value} : ${controller.teamBScore.value}",
                          style: Get.textTheme.titleLarge!.copyWith(color: Colors.black,fontSize: 40),
                        ),
                        Text(
                          controller.historyData.value?.categoryType ?? "",
                          style: Get.textTheme.headlineSmall!.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// TEAM B
                  Container(
                    color: Colors.transparent,
                    width: Get.width*0.25,
                    child: Column(
                      children: [
                        if (controller.winnerTeam != null)
                          Obx(() => controller.winnerTeam == 'teamB'
                              ? Image.asset(Assets.imagesImgCrown, width: 24, height: 24)
                              : const SizedBox(height: 24)),
                        Text(controller.historyData.value?.teamB?.teamName ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: Get.textTheme.titleLarge!.copyWith(fontSize: 20,color: AppColors.secondaryColor)),
                        const SizedBox(height: 6),
                        Text(_teamPlayersText(controller.historyData.value?.teamB).capitalizeFirstChar(),
                            style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,fontSize: 11),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
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
                            _hasRoundsAndSetWinner(index)
                                ? Container(
                                    padding: EdgeInsets.symmetric(vertical: 4,horizontal: 9),
                                    decoration: BoxDecoration(
                                        color: AppColors.textFieldColor,
                                        borderRadius: BorderRadius.circular(7)
                                    ),
                                    child: Text("Tie Break",style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.primaryColor,fontSize: 12),),
                                  ).paddingOnly(left: 10)
                                : SizedBox.shrink()
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
                  ? (getRounds(index).isEmpty && getSetWinner(index) != null
                      ? _buildWinnerColumn(index)
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // ── ROUND HEADERS R1, R2... ───
                                              Row(
                                                children: [
                                                  const SizedBox(width: 80),
                                                  // ← team name space
                                                  ...List.generate(
                                                    getRounds(index).length,
                                                    (i) {
                                                      final rounds = getRounds(index);
                                                      final winType = rounds[i].winType;
                                                      String displayText = 'R${i + 1}';
                                                      if (winType == 'TIEBREAK') {
                                                        displayText = 'TB';
                                                      } else if (winType == 'SUPER_TIEBREAK') {
                                                        displayText = 'STB';
                                                      }
                                                      return SizedBox(
                                                        width: 40,
                                                        child: Text(
                                                          displayText,
                                                          textAlign: TextAlign.center,
                                                          style: Get.textTheme.bodyMedium!.copyWith(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              // ── TEAM A ROW ──────────────────
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  // ── Team A label + score ───
                                                  SizedBox(
                                                    width: 80,
                                                    child: Row(
                                                      children: [
                                                        RotatedBox(
                                                          quarterTurns: 3,
                                                          child: Text(
                                                            controller.historyData.value?.teamA?.teamName ?? 'Team A',
                                                            style: Get.textTheme.displaySmall!.copyWith(
                                                              fontSize: 9,
                                                              color: AppColors.labelBlackColor,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          width: 4,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xff2D5BFF),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          '${getFinalScore(index)?.teamA ?? 0}',
                                                          style: Get.textTheme.headlineMedium!.copyWith(
                                                            color: AppColors.primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // ── Points per round ────────
                                                  ...List.generate(getRounds(index).length, (i) {
                                                    final rounds = getRounds(index);
                                                    final pts = rounds[i].pointsAtEnd?.teamA ?? '-';
                                                    final bool isWinner = rounds[i].gameWinner == 'teamA';
                                                    final winType = rounds[i].winType;
                                                    return SizedBox(
                                                      width: 40,
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          if (isWinner)
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Transform.rotate(
                                                                  angle: -0.3,
                                                                  child: SizedBox(
                                                                    width: 14,
                                                                    height: 14,
                                                                    child: Image.asset(
                                                                      Assets.imagesIcCrown,
                                                                      width: 14,
                                                                      height: 14,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (winType == 'ADVANTAGE')
                                                                  Text(
                                                                    'AD',
                                                                    style: Get.textTheme.bodySmall!.copyWith(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.primaryColor,
                                                                    ),
                                                                  ),
                                                                if (winType == 'GOLDEN_POINT')
                                                                  Text(
                                                                    'GP',
                                                                    style: Get.textTheme.bodySmall!.copyWith(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.primaryColor,
                                                                    ),
                                                                  ),
                                                                      if (winType == 'TIEBREAK')
                                                                  Text(
                                                                    'TB',
                                                                    style: Get.textTheme.bodySmall!.copyWith(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.primaryColor,
                                                                    ),
                                                                  ),
                                                              ],
                                                            )
                                                          else
                                                            const SizedBox(height: 14),
                                                          Text(
                                                            pts.toString(),
                                                            textAlign: TextAlign.center,
                                                            style: Get.textTheme.titleSmall!.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 12,
                                                              color: Colors.grey,
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
                                                            controller.historyData.value?.teamB?.teamName ?? 'Team B',
                                                            style: Get.textTheme.displaySmall!.copyWith(
                                                              fontSize: 9,
                                                              color: AppColors.labelBlackColor,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Container(
                                                          width: 4,
                                                          height: 30,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.secondaryColor,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          '${getFinalScore(index)?.teamB ?? 0}',
                                                          style: Get.textTheme.headlineMedium!.copyWith(
                                                            color: AppColors.secondaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // ── Points per round ────────
                                                  ...List.generate(getRounds(index).length, (i) {
                                                    final rounds = getRounds(index);
                                                    final pts = rounds[i].pointsAtEnd?.teamB ?? '-';
                                                    final bool isWinner = rounds[i].gameWinner == 'teamB';
                                                    final winType = rounds[i].winType;
                                                    return SizedBox(
                                                      width: 40,
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          if (isWinner)
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Transform.rotate(
                                                                  angle: -0.3,
                                                                  child: SizedBox(
                                                                    width: 14,
                                                                    height: 14,
                                                                    child: Image.asset(
                                                                      Assets.imagesIcCrown,
                                                                      width: 14,
                                                                      height: 14,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (winType == 'ADVANTAGE')
                                                                  Text(
                                                                    'AD',
                                                                    style: Get.textTheme.bodySmall!.copyWith(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.secondaryColor,
                                                                    ),
                                                                  ),
                                                                if (winType == 'GOLDEN_POINT')
                                                                  Text(
                                                                    'GP',
                                                                    style: Get.textTheme.bodySmall!.copyWith(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.secondaryColor,
                                                                    ),
                                                                  ),
                                                                        if (winType == 'TIEBREAK')
                                                                  Text(
                                                                    'TB',
                                                                    style: Get.textTheme.bodySmall!.copyWith(
                                                                      fontSize: 8,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: AppColors.secondaryColor,
                                                                    ),
                                                                  ),
                                                              ],
                                                            )
                                                          else
                                                            const SizedBox(height: 14),
                                                          Text(
                                                            pts.toString(),
                                                            textAlign: TextAlign.center,
                                                            style: Get.textTheme.titleSmall!.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 12,
                                                              color: Colors.grey,
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
    ));
  }
}
class MatchStatsCard extends StatelessWidget {
  final LiveStreamAmericanoController controller;
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
            _statRow("Errors", teamA?.winners ?? 0, teamB?.errors ?? 0),
            // _statRow("Forced Errors", teamA?.forcedErrors ?? 0, teamB?.forcedErrors ?? 0),
            // _statRow("Unforced Errors", teamA?.unforcedErrors ?? 0, teamB?.unforcedErrors ?? 0),
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

extension _MatchDetailsUiHelpers on _LiveStreamAmericanoScreenState {
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



  bool _hasRoundsAndSetWinner(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return false;
    final rounds = sets[index].rounds ?? const [];
    final setWinner = sets[index].setWinner;
    return rounds.isEmpty && setWinner != null;
  }

  List<RoundData> getRounds(int setIndex) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (setIndex >= sets.length) return [];
    return sets[setIndex].rounds ?? [];
  }

  String? getSetWinner(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return null;
    return sets[index].setWinner;
  }

  FinalScore? getFinalScore(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return null;
    return sets[index].finalScore;
  }

  Widget _buildWinnerColumn(int index) {
    final sets = controller.historyData.value?.sets ?? const [];
    if (index < 0 || index >= sets.length) return const SizedBox.shrink();
    
    final setWinner = sets[index].setWinner;
    if (setWinner == null) return const SizedBox.shrink();
    
    final winnerTeamName = setWinner == 'teamA'
        ? controller.historyData.value?.teamA?.teamName ?? 'Team A'
        : controller.historyData.value?.teamB?.teamName ?? 'Team B';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Transform.rotate(
            angle: -0.3,
            child: Image.asset(
              Assets.imagesIcCrown,
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

  Widget _pointHistorySection() {
    return Obx(() {
      final history = controller.pointHistoryList;
      if (history.isEmpty) {
        return const SizedBox.shrink();
      }

      // Reverse history so latest points appear at the top
      final reversedHistory = history.reversed.toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Point History",
                    style: Get.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${history.length}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (history.length > 5) 
                const Text(
                  "Recent Points",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversedHistory.length,
            itemBuilder: (context, index) {
              final item = reversedHistory[index];
              final isLatest = index == 0;
              
              final isTeamAWinner = item.winner == 'teamA';
              final winnerName = isTeamAWinner ? controller.teamAName : controller.teamBName;
              final winnerColor = isTeamAWinner ? AppColors.primaryColor : AppColors.secondaryColor;
              
              final displayScore = controller.leftTeam == 'teamA' 
                  ? '${item.teamAScore} - ${item.teamBScore}' 
                  : '${item.teamBScore} - ${item.teamAScore}';

              String recordedTime = '';
              if (item.recordedAt != null && item.recordedAt!.isNotEmpty) {
                try {
                  final dateTime = DateTime.parse(item.recordedAt!).toLocal();
                  recordedTime = DateFormat('h:mm:ss a').format(dateTime);
                } catch (_) {
                  recordedTime = '';
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isLatest ? winnerColor.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLatest 
                        ? winnerColor.withValues(alpha: 0.4) 
                        : Colors.grey.shade200,
                    width: isLatest ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Point Number Badge
                    Container(
                      height: 36,
                      width: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isLatest ? winnerColor : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${item.pointNo ?? (history.length - index)}",
                        style: TextStyle(
                          color: isLatest ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Winner Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Point Winner",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isLatest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: winnerColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "LATEST",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            winnerName,
                            style: TextStyle(
                              color: winnerColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (recordedTime.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              recordedTime,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayScore,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      );
    });
  }
}