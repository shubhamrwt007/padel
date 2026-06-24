import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_all_schedule_live_matches_ipt_tournament_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_leader_board_model.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/ipt_tournament/ipt_tournament_controller.dart';
import 'package:padel_mobile/presentations/ipt_tournament/widgets/ipt_build_sponsor_banner.dart';
import 'package:padel_mobile/presentations/ipt_tournament/widgets/ipt_scoreboard_row.dart';
import 'package:padel_mobile/presentations/league/widgets/match_card_clipper.dart';

class IptTournamentScreen extends StatelessWidget {
  final IptTournamentController controller =Get.put(IptTournamentController());
  IptTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String leagueTitle = Get.arguments?['leagueTitle'] ?? 'League';
    final int initialTab = Get.arguments?['initialTab'] ?? 0;
    print(leagueTitle);
    
    if (initialTab == 1 && controller.selectedTab.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setSelectedTab(1);
      });
    }
    
    return Scaffold(
      appBar: primaryAppBar(
        title: SvgPicture.asset(
          Assets.images.imgIptLogo.path,
          height: 14,
          width: 15,
        ),
        // title: leagueTitle.toLowerCase() == 'swoot padel league'
        //     ? SvgPicture.asset(
        //   Assets.images.imgSwootPadelLeague.path,
        //   height: 27,
        //   width: 30,
        // )
        //     : Text(leagueTitle),
        centerTitle: true,
        context: context,
      ),
        body: Obx(() {
          if (controller.isInitialLoading.value || controller.isRefreshingTab.value) {
            return Center(
              child: LoadingWidget(color: AppColors.primaryColor),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabSelector(),
              Expanded(
                child: controller.selectedTab.value == 0
                    ? _liveMatchContent(context).paddingOnly(top: 0)
                    : const LeaderBoardWidget().paddingOnly(top: 0),
              ),
            ],
          );
        }),
      );
  }
  Widget _liveMatchContent(BuildContext context){
    return RefreshIndicator(
      color: Colors.white,
      onRefresh: () async {
        await Future.wait([
          controller.fetchUpcomingMatches(),
          controller.fetchResultMatches(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (controller.isLoadingUpcomingMatches.value) {
                return SizedBox(
                  height: 200,
                  child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
                );
              }
              return _liveMatchCard();
            }),
            BuildIptTournamentTitleSponsor(controller: controller),
            Obx(() {
              final sponsors = controller.sponsors.value?.data?.sponsors ?? [];
              if (sponsors.isEmpty) return const SizedBox.shrink();
              return BuildIptTournamentMoreSponsor(sponsors: sponsors);
            }),
            _buildTabs(context),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.matchTab.value == 0
                      ? "Upcoming Matches"
                      : "Match Results",
                  style: Get.textTheme.headlineMedium,
                ),
                Obx(() {
                  final hasMatches = controller.matchTab.value == 0
                      ? (controller.upcomingMatches.value?.data ?? []).expand((d) => d.matches ?? []).isNotEmpty
                      : (controller.resultMatches.value?.data ?? []).expand((d) => d.matches ?? []).isNotEmpty;
                  if (!hasMatches) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      Get.toNamed(RoutesName.iptTournamentMatchLists, arguments: {
                        'tournamentId': controller.tournamentId ?? '',
                        'initialTab': controller.matchTab.value
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Text(
                        "See all",
                        style: Get.textTheme.labelLarge!
                            .copyWith(color: AppColors.primaryColor),
                      ),
                    ),
                  );
                }),
              ],
            ).paddingSymmetric(horizontal: 18,vertical: 8)),
            SizedBox(
              height:controller.isLoadingUpcomingMatches.value? Get.height * 0.45:Get.height*0.7,
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: [
                  _upcomingList(),
                  _resultsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTabs(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller.tabController,
        onTap: controller.onTabChanged,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.black54,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 1,
        dividerColor: Colors.grey.shade300,
        labelStyle:Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500) ,
        tabs: const [
          Tab(text: "Upcoming"),
          Tab(text: "Results"),
        ],
      ),
    );
  }

  /// TAB SELECTOR
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.creamColor,
        borderRadius: BorderRadius.circular(10),
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
          // Padel Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.setSelectedTab(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 0
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: controller.selectedTab.value == 0
                      ? Border.all(
                    color: const Color(0xFF3B5BDB),
                    width: 1.5,
                  )
                      : null,
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
                    // SvgPicture.asset(
                    //   Assets.images.icPadel.path,
                    //   height: 18, // Add this line - adjust value as needed
                    //   color: controller.selectedSportTab.value == 0
                    //       ? const Color(0xFF3B5BDB)
                    //       : const Color(0xFF252525),
                    // ),
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: controller.selectedTab.value == 0
                            ?Colors.white
                            : const Color(0xFF252525),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      child: const Text('Matches'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pickleball Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.setSelectedTab(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 1
                      ? AppColors.primaryColor
                      : Colors.transparent,
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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: controller.selectedTab.value == 1
                            ? Colors.white
                            : const Color(0xFF252525),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      child: const Text('Fixture’s'),
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
  Widget _liveMatchCard() {
    final scheduleData = controller.upcomingMatches.value?.data ?? [];
    final liveData = scheduleData.where((data) => data.matchStatus?.toLowerCase() == 'live').toList();
    
    if (liveData.isEmpty) return const SizedBox.shrink();

    final allMatches = liveData.expand((data) => data.matches ?? []).toList();
    if (allMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: Get.height * 0.34,
          child: PageView.builder(
            controller: controller.liveMatchCarouselController,
            onPageChanged: controller.onLiveMatchCarouselChanged,
            itemCount: liveData.length,
            itemBuilder: (context, index) {
              final matchData = liveData[index];
              final match = matchData.matches?.first;
              if (match == null) return const SizedBox.shrink();
              
              final categoryType = matchData.categoryType ?? "Mixed Doubles";
              final setsWon = matchData.matchId?.setsWon;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(RoutesName.liveAndCompleteIptTournamentMatch, arguments: {
                        "matchType": "live",
                        "matchId": matchData.matchId?.id ?? ""
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Stack(
                        children: [
                          SvgPicture.asset(Assets.images.fipPromesisBg.path, fit: BoxFit.cover, width: Get.width),
                          Column(
                            children: [
                              _AnimatedLiveTag(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _teamColumn(
                                    match.teamA?.teamName ?? "",
                                    "",
                                    "",
                                    (match.teamA?.players?.isNotEmpty ?? false) ? (match.teamA!.players![0].playerName ?? "") : "Player 1",
                                    (match.teamA?.players != null && match.teamA!.players!.length > 1) ? (match.teamA!.players![1].playerName ?? "") : "Player 2",
                                    AppColors.primaryColor,
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, 0),
                                    child: Column(
                                      children: [
                                        Text(categoryType, style: Get.textTheme.labelMedium),
                                        SizedBox(height: 8),
                                        Obx(() {
                                          final liveMatches = controller.upcomingMatches.value?.data
                                              ?.where((data) => data.matchStatus?.toLowerCase() == 'live')
                                              .toList() ?? [];
                                          final currentIndex = controller.currentLiveMatchIndex.value < liveMatches.length ? controller.currentLiveMatchIndex.value : 0;
                                          final currentSetsWon = liveMatches.isNotEmpty ? liveMatches[currentIndex].matchId?.setsWon : null;
                                          return Text(
                                              "${currentSetsWon?.teamA ?? setsWon?.teamA ?? 0} : ${currentSetsWon?.teamB ?? setsWon?.teamB ?? 0}",
                                              style: Get.textTheme.titleLarge!.copyWith(color: AppColors.blackColor, fontSize: 42));
                                        }),
                                      ],
                                    ),
                                  ),
                                  _teamColumn(
                                    match.teamB?.teamName ?? "",
                                    "",
                                    "",
                                    (match.teamB?.players?.isNotEmpty ?? false) ? (match.teamB!.players![0].playerName ?? "") : "Player 3",
                                    (match.teamB?.players != null && match.teamB!.players!.length > 1) ? (match.teamB!.players![1].playerName ?? "") : "Player 4",
                                    AppColors.secondaryColor,
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  _AnimatedWatchLiveButton(onTap: () {
                                    Get.toNamed(RoutesName.liveAndCompleteIptTournamentMatch, arguments: {
                                      "matchType": "live",
                                      "matchId": matchData.matchId?.id ?? ""
                                    });
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildScoreBoard(matchData).paddingOnly(right: Get.width * 0.05, left: Get.width * 0.05, top: 10),
                ],
              );
            },
          ),
        ),
        if (liveData.length > 1)
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              liveData.length,
              (index) {
                final isActive = controller.currentLiveMatchIndex.value == index;
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
              },
            ),
          ).paddingOnly(top: 8)),
      ],
    ).paddingOnly(bottom: 0);
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
            width: Get.width*0.2,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Text(
              team,
                overflow: TextOverflow.ellipsis,
                style:Get.textTheme.headlineMedium!.copyWith(color: color)

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
                _avatarWithInitials(name1, 0,color),
                _avatarWithInitials(name2, 24,color),
              ],
            ),
          ),


          /// NAMES
          Text(
              "$name1 &\n$name2",
              textAlign: TextAlign.center,
              style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,fontSize: 11)
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBoard(IptTournamentScheduleMatchData? matchData) {
    return Obx(() {
      final scoreboardData = controller.liveMatchScoreboard.value;
      final liveMatchData = controller.upcomingMatches.value?.data
        ?.where((data) => data.matchStatus?.toLowerCase() == 'live')
        .firstOrNull;
      
      if (controller.isLoadingScoreboard.value) {
        return const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: LoadingWidget(color: AppColors.primaryColor,),
          ),
        );
      }
      
      // Use live match data for real-time scores - this is the key change
      final currentMatchData = liveMatchData ?? matchData;
      
      if (scoreboardData == null) {
        // Fallback to basic match data if scoreboard data is not available
        if (currentMatchData?.matches == null || currentMatchData!.matches!.isEmpty) {
          return const SizedBox.shrink();
        }

        final match = currentMatchData.matches!.first;
        final teamAPlayers = match.teamA?.players ?? [];
        final teamBPlayers = match.teamB?.players ?? [];
        
        return Column(
          children: [
            if (teamAPlayers.isNotEmpty)
              IptScoreboardRow(
                logo: "",
                player1: teamAPlayers.isNotEmpty ? (teamAPlayers[0].playerName ?? "Player 1") : "Player 1",
                player2: teamAPlayers.length > 1 ? (teamAPlayers[1].playerName ?? "Player 2") : "Player 2",
                scores: ["0"],
                points: "0",
                isTeamA: true,
              ),
            const Divider(),
            if (teamBPlayers.isNotEmpty)
              IptScoreboardRow(
                logo: "",
                player1: teamBPlayers.isNotEmpty ? (teamBPlayers[0].playerName ?? "Player 3") : "Player 3",
                player2: teamBPlayers.length > 1 ? (teamBPlayers[1].playerName ?? "Player 4") : "Player 4",
                scores: ["0"],
                points: "0",
                isTeamA: false,
              ),
          ],
        );
      }

      final teamAData = scoreboardData['teamA'] as Map<String, dynamic>? ?? {};
      final teamBData = scoreboardData['teamB'] as Map<String, dynamic>? ?? {};

      final teamAPlayers = teamAData['players'] as List? ?? [];
      final teamBPlayers = teamBData['players'] as List? ?? [];

      // Use updated round scores from socket or fallback to stored data
      final teamARoundScores = teamAData['roundScores'] as List? ?? [];
      final teamBRoundScores = teamBData['roundScores'] as List? ?? [];
      final totalRounds = teamAData['totalRounds'] as int? ?? 0;

      // Use updated points from socket or fallback to stored data
      final teamAPoints = teamAData['currentPoints']?.toString() ?? '0';
      final teamBPoints = teamBData['currentPoints']?.toString() ?? '0';

      return Column(
        children: [
          if (teamAPlayers.isNotEmpty)
            IptScoreboardRow(
              logo: teamAData['logo']?.toString() ?? "",
              player1: teamAPlayers.isNotEmpty ? (teamAPlayers[0]['playerName'] ?? "Player 1") : "Player 1",
              player2: teamAPlayers.length > 1 ? (teamAPlayers[1]['playerName'] ?? "Player 2") : "Player 2",
              scores: _formatRoundScores(teamARoundScores, totalRounds),
              points: teamAPoints,
              isTeamA: true,
            ),
          const Divider(height: 1, color: Colors.grey),
          if (teamBPlayers.isNotEmpty)
            IptScoreboardRow(
              logo: teamBData['logo']?.toString() ?? "",
              player1: teamBPlayers.isNotEmpty ? (teamBPlayers[0]['playerName'] ?? "Player 3") : "Player 3",
              player2: teamBPlayers.length > 1 ? (teamBPlayers[1]['playerName'] ?? "Player 4") : "Player 4",
              scores: _formatRoundScores(teamBRoundScores, totalRounds),
              points: teamBPoints,
              isTeamA: false,
            ),
        ],
      );
    });
  }
  
  List<String> _formatRoundScores(List roundScores, int totalRounds) {
    final scores = <String>[];
    
    // Add scores based on actual rounds played
    for (int i = 0; i < totalRounds && i < roundScores.length; i++) {
      scores.add(roundScores[i].toString());
    }
    
    // If no rounds played yet, show at least one "0"
    if (scores.isEmpty) {
      scores.add("0");
    }
    
    return scores;
  }
  
  Widget _avatarWithInitials(String name, double left,Color? color) {
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
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          color:color,
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

    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

  Widget _upcomingList() {
    return Obx(() {
      final scheduleData = controller.upcomingMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return Center(
          child: Text(
            "No matches available",
            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        );
      }

      final allSchedules = scheduleData.take(5).toList();
      if (allSchedules.isEmpty) {
        return Center(
          child: Text(
            "No matches available",
            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: allSchedules.length,
        itemBuilder: (context, index) {
          final scheduleItem = allSchedules[index];
          final matches = scheduleItem.matches ?? [];
          final roundType = scheduleItem.roundType??"";
          if (matches.isEmpty) return const SizedBox.shrink();
          
          final match = matches.first;
          
          if (scheduleItem.matchStatus?.toLowerCase() == 'live') {
            return GestureDetector(
              onTap: () {
                Get.toNamed(RoutesName.liveAndCompleteIptTournamentMatch, arguments: {
                  "matchType": "live",
                  "matchId": scheduleItem.matchId?.id ?? ""
                });
              },
              child: LiveMatchCard(
                match: match,
                categoryType: scheduleItem.categoryType,
                setsWon: scheduleItem.matchId?.setsWon,
                roundType: roundType,
              ),
            );
          }
          
          return UpcomingMatchCard(
            match: match,
            categoryType: scheduleItem.categoryType,
            date: scheduleItem.date,
            roundType: roundType,
          );
        },
      );
    });
  }



  Widget _resultsList() {
    return Obx(() {
      final scheduleData = controller.resultMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return Center(
          child: Text(
            "No result matches available",
            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        );
      }

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) {
        return Center(
          child: Text(
            "No result matches available",
            style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: allMatches.length > 4 ? 4 : allMatches.length,
        itemBuilder: (context, index) {
          final matchData = scheduleData.firstWhere(
            (data) => data.matches?.contains(allMatches[index]) ?? false,
            orElse: () => scheduleData.first,
          );
          final roundType = matchData.roundType??"";
          return GestureDetector(
            onTap: () {
              final matchData = scheduleData.firstWhere(
                (data) => data.matches?.contains(allMatches[index]) ?? false,
                orElse: () => scheduleData.first,
              );
              Get.toNamed(RoutesName.liveAndCompleteIptTournamentMatch, arguments: {
                "matchType": "result",
                "matchId": matchData.matchId?.id ?? ""
              });
            },
            child: ResultMatchCard(
              match: allMatches[index],
              categoryType: matchData.categoryType,
              date: matchData.date,
              setsWon: matchData.matchId?.setsWon,
              roundType: roundType,
            ),
          );
        },
      );
    });
  }
}

class UpcomingMatchCard extends StatelessWidget {
  final dynamic match;
  final String? categoryType;
  final String? date;
  final String? roundType;

  const UpcomingMatchCard({super.key, this.match, this.categoryType, this.date,this.roundType});

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    
    final teamAPlayers = match?.teamA?.players ?? [];
    final teamBPlayers = match?.teamB?.players ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 25,
            width: 140,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
                _formatDate(date ?? ""),
                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
            ),
          ),
          /// MAIN Container
          ClipPath(
            clipper: MatchCardClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffFFFFFF),
                    Color(0xffDEE5FF),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -10,
                    child: SvgPicture.asset(Assets.images.dotsFipPromises.path,height: 100,width: 100,),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(Assets.images.dotsFipPromises.path,height: 100,width: 100,),
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Container(
                            color: Colors.transparent,
                            width: Get.width*0.2,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                                match?.teamA?.teamName ?? "Team A",
                                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.blackColor)
                            ),
                          ),
                          const Spacer(),
                          Container(
                            color: Colors.transparent,
                            width: Get.width*0.2,
                            alignment: AlignmentGeometry.centerRight,
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                                match?.teamB?.teamName ?? "Team B",
                                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.blackColor)
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar(teamAPlayers.isNotEmpty ? teamAPlayers[0].playerName ?? "" : "Player 1", 0, 0),
                                    _avatar(teamAPlayers.length > 1 ? teamAPlayers[1].playerName ?? "" : "Player 2", 12, 8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (match?.teamA?.players?.isNotEmpty ?? false)
                                      ? match!.teamA!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    overflow: TextOverflow.ellipsis,
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 1",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 2",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              SvgPicture.asset(Assets.images.imgVs.path,).paddingOnly(bottom: 5,top: 5),
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,),
                              Text("${match?.startTime?.split(' ').first??""}-${match?.endTime??""}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w300),),
                              roundType == "regular"?SizedBox.shrink():
                              Text(roundType?.capitalizeFirstChar()??"",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: (match?.teamB?.players?.isNotEmpty ?? false)
                                      ? match!.teamB!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    overflow: TextOverflow.ellipsis,
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 3",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 4",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar(teamBPlayers.isNotEmpty ? teamBPlayers[0].playerName ?? "" : "Player 3", 12, 0),
                                    _avatar(teamBPlayers.length > 1 ? teamBPlayers[1].playerName ?? "" : "Player 4", 0, 8),
                                  ],
                                ),
                              ).paddingOnly(left: 5),
                            ],
                          ),
                        ],
                      )
                    ],
                  ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day.toString().padLeft(2, '0')}${months[date.month - 1]}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _avatar(String name, double left, double top) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          color: AppColors.primaryColor,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  String formatName(String name) {
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts.first} ${parts.last[0]}";
    }
    return name;
  }
}

class LiveMatchCard extends StatelessWidget {
  final Matches? match;
  final String? categoryType;
  final String? roundType;
  final SetsWon? setsWon;
  const LiveMatchCard({super.key, this.match, this.categoryType, this.setsWon,this.roundType});

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    
    final teamAPlayers = match?.teamA?.players ?? [];
    final teamBPlayers = match?.teamB?.players ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 25,
            width: 140,
            decoration: const BoxDecoration(
              color: AppColors.liveMatchRed,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            alignment: Alignment.center,
            child: _AnimatedLiveIndicator(),
          ),
          /// MAIN Container
          ClipPath(
            clipper: MatchCardClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffFFFFFF),
                    Color(0xffFFD3CF),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -10,
                    child: SvgPicture.asset(
                      Assets.images.dotsFipPromises.path,
                      height: 100,
                      width: 100,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(
                      Assets.images.dotsFipPromises.path,
                      height: 100,
                      width: 100,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    )
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Text(
                              match?.teamA?.teamName ?? "Team A",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                          const Spacer(),
                          Text(
                              match?.teamB?.teamName ?? "Team B",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar(teamAPlayers.isNotEmpty ? teamAPlayers[0].playerName ?? "" : "Player 1", 0, 0),
                                    _avatar(teamAPlayers.length > 1 ? teamAPlayers[1].playerName ?? "" : "Player 2", 12, 8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (match?.teamA?.players?.isNotEmpty ?? false)
                                      ? match!.teamA!.players!
                                      .take(2)
                                      .map((e) => Text(
                                    overflow: TextOverflow.ellipsis,
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 1",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 2",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text("${setsWon?.teamA ?? 0}", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                  const SizedBox(width: 6),
                                  Text(":", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                  const SizedBox(width: 6),
                                  Text("${setsWon?.teamB ?? 0}", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                ],
                              ),
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,),
                              Text("${match?.startTime?.split(' ').first??""}-${match?.endTime??""}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w300),),
                              roundType == "regular"?SizedBox.shrink():
                              Text(roundType?.capitalizeFirstChar()??"",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),),
                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: (match?.teamB?.players?.isNotEmpty ?? false)
                                      ? match!.teamB!.players!
                                      .take(2)
                                      .map((e) => Text(
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    overflow: TextOverflow.ellipsis,
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 3",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 4",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar(teamBPlayers.isNotEmpty ? teamBPlayers[0].playerName ?? "" : "Player 3", 12, 0),
                                    _avatar(teamBPlayers.length > 1 ? teamBPlayers[1].playerName ?? "" : "Player 4", 0, 8),
                                  ],
                                ),
                              ).paddingOnly(left: 5),
                            ],
                          ),
                        ],
                      )
                    ],
                  ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _avatar(String name, double left, double top) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          color: AppColors.primaryColor,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  String formatName(String name) {
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts.first} ${parts.last[0]}";
    }
    return name;
  }
}
class ResultMatchCard extends StatelessWidget {
  final Matches? match;
  final String? categoryType;
  final String? roundType;
  final String? date;
  final SetsWon? setsWon;
  
  const ResultMatchCard({super.key, this.match, this.categoryType, this.date, this.setsWon,this.roundType});

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    
    final teamAPlayers = match?.teamA?.players ?? [];
    final teamBPlayers = match?.teamB?.players ?? [];
    final teamAWon = (setsWon?.teamA ?? 0) > (setsWon?.teamB ?? 0);
    final teamBWon = (setsWon?.teamB ?? 0) > (setsWon?.teamA ?? 0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 25,
            width: 140,
            decoration: const BoxDecoration(
              color: Color(0xff494949),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
                _formatDate(date ?? ""),
                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
            ),
          ),
          /// MAIN Container
          ClipPath(
            clipper: MatchCardClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffFFFFFF),
                    Color(0xffF5F5F5),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -10,
                    child: SvgPicture.asset(Assets.images.dotsFipPromises.path,height: 100,width: 100,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF494949),
                        BlendMode.srcIn,
                      ),),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(Assets.images.dotsFipPromises.path,height: 100,width: 100, colorFilter: const ColorFilter.mode(
                      Color(0xFF494949),
                      BlendMode.srcIn,
                    ),),
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Row(
                            children: [
                              if (teamAWon)
                                Image.asset(
                                  Assets.images.icCrown.path,
                                  height: 12,
                                  width: 12,
                                ).paddingOnly(right: 4),
                              Text(
                                  match?.teamA?.teamName ?? "",
                                  style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                  match?.teamB?.teamName ?? "",
                                  style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                              ),
                              if (teamBWon)
                                Image.asset(
                                  Assets.images.icCrown.path,
                                  height: 12,
                                  width: 12,
                                ).paddingOnly(left: 4),
                            ],
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatarWithInitials(teamAPlayers.isNotEmpty ? teamAPlayers[0].playerName ?? "" : "Player 1", 0, 0),
                                    _avatarWithInitials(teamAPlayers.length > 1 ? teamAPlayers[1].playerName ?? "" : "Player 2", 12, 8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (match?.teamA?.players?.isNotEmpty ?? false)
                                      ? match!.teamA!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    overflow: TextOverflow.ellipsis,
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 1",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 2",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              Row(
                                children: [
                                  Text("${setsWon?.teamA ?? 0}", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                  const SizedBox(width: 6),
                                  Text(":", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                  const SizedBox(width: 6),
                                  Text("${setsWon?.teamB ?? 0}", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                ],
                              ),
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,),
                              Text("${match?.startTime?.split(' ').first??""}-${match?.endTime??""}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w300),),
                              roundType == "regular"?SizedBox.shrink():
                              Text(roundType?.capitalizeFirstChar()??"",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),),

                            ],
                          ),

                          Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: (match?.teamB?.players?.isNotEmpty ?? false)
                                      ? match!.teamB!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    overflow: TextOverflow.ellipsis,
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 3",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 4",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatarWithInitials(teamBPlayers.isNotEmpty ? teamBPlayers[0].playerName ?? "" : "Player 3", 12, 0),
                                    _avatarWithInitials(teamBPlayers.length > 1 ? teamBPlayers[1].playerName ?? "" : "Player 4", 0, 8),
                                  ],
                                ),
                              ).paddingOnly(left: 5),
                            ],
                          ),
                        ],
                      )
                    ],
                  ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day.toString().padLeft(2, '0')}${months[date.month - 1]}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _avatarWithInitials(String name, double left, double top) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          color: AppColors.primaryColor,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  String formatName(String name) {
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts.first} ${parts.last[0]}";
    }
    return name;
  }

}

class LeaderBoardWidget extends StatefulWidget {
  const LeaderBoardWidget({super.key});

  @override
  State<LeaderBoardWidget> createState() => _LeaderBoardWidgetState();
}

class _LeaderBoardWidgetState extends State<LeaderBoardWidget> {
  final List<ScrollController> _scrollControllers = [];
  bool _isScrolling = false;

  @override
  void dispose() {
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _createSyncedController() {
    final controller = ScrollController();
    controller.addListener(() {
      if (_isScrolling) return;
      _isScrolling = true;
      for (var other in _scrollControllers) {
        if (other != controller && other.hasClients) {
          other.jumpTo(controller.offset);
        }
      }
      _isScrolling = false;
    });
    _scrollControllers.add(controller);
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IptTournamentController>();
    _scrollControllers.clear();
    
    return RefreshIndicator(
      color: AppColors.whiteColor,
      onRefresh: () async {
        await Future.wait([
          controller.fetchLeaderBoard(),
          controller.fetchLeaderboardUpcomingMatches(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Obx(() {
              final categories = controller.allCategories;
              if (categories.isEmpty) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  onSelected: controller.onCategoryChanged,
                  offset: Offset(0, 27),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.selectedCategory.value,
                          style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 20, color: AppColors.primaryColor),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => categories.map((category) {
                    return PopupMenuItem<String>(
                      value: category,
                      child: Text(category, style: Get.textTheme.bodySmall),
                    );
                  }).toList(),
                ),
              ).paddingOnly(bottom: 12);
            }),
        Obx(() {
          final leaderboard = controller.leaderBoard.value?.data?.leaderboard ?? [];

          if (leaderboard.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage(Assets.images.imgIconSwoot.path),
                fit: BoxFit.contain,
                opacity: 0.9, // 👈 direct opacity
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  spreadRadius: 1.5,
                  blurRadius: 5.0,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Column(
              children: [
                _headerRow(),
                Divider(color: Colors.grey.shade300),
                ...leaderboard.asMap().entries.map((entry) {
                  final index = entry.key;
                  final standing = entry.value;
                  return Column(
                    children: [
                      _teamRow(standing, index + 1),
                      if (index < leaderboard.length - 1)
                        Divider(color: Colors.grey.shade300),
                    ],
                  );
                }),
              ],
            ),
          ).paddingOnly(bottom: 20);
        }),
            BuildIptTournamentTitleSponsor(controller: controller),
        Obx(() {
          final sponsors = controller.sponsors.value?.data?.sponsors ?? [];
          if (sponsors.isEmpty) return const SizedBox.shrink();
          return BuildIptTournamentMoreSponsor(sponsors: sponsors);
        }),
        Obx(() {
          final hasUpcoming = (controller.leaderboardUpcomingMatches.value?.data ?? [])
              .expand((d) => d.matches ?? []).isNotEmpty;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Matches", style: Get.textTheme.headlineMedium),
              if (hasUpcoming)
                GestureDetector(
                  onTap: () {
                    Get.toNamed(RoutesName.iptTournamentMatchLists, arguments: {
                      // 'matchTab': 0,
                      'tournamentId': controller.tournamentId ?? ''
                    });
                    print("objectobjectobjectobjectobject-> ${controller.tournamentId ?? ''}");
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
          ).paddingSymmetric(horizontal: 18, vertical: 8);
        }),
          _upcomingListForLeaderboard(),
            SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    final style = Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500);
    
    return Row(
      children: [
        SizedBox(width: 30, child: Text("#", style: style)),
        Expanded(child: Text("Teams", style: style)),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("M", style: style))),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("W", style: style))),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("L", style: style))),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("Pts", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryColor)))),
      ],
    );
  }


  Widget _teamRow(Leaderboard standing, int position) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Row(
            children: [
              Text(
                "$position",
                style: Get.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 4),
              _buildPositionChangeIndicator(standing.positionChange),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                height: 30,
                width: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (standing.players != null && standing.players!.isNotEmpty) ...[
                      _buildPlayerAvatar(standing.players![0].playerName ?? "?", 0, 0),
                      if (standing.players!.length > 1)
                        _buildPlayerAvatar(standing.players![1].playerName ?? "?", 12, 8),
                    ] else
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          (standing.teamName ?? "?")[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (standing.players != null && standing.players!.isNotEmpty)
                      ...standing.players!.map((player) => Text(
                        player.playerName ?? "Unknown",
                        style: Get.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w500,fontSize: 9),
                        overflow: TextOverflow.ellipsis,
                      ))
                    else
                      Text(
                        standing.teamName ?? "Unknown",
                        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("${standing.played ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("${standing.wins ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("${standing.losses ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 50, child: Align(alignment: Alignment.center, child: Text("${standing.points ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryColor)))),
      ],
    );
  }


  
  Widget _buildPlayerAvatar(String name, double left, double top) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 22,
        width: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          color: AppColors.primaryColor,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionChangeIndicator(int? positionChange) {
    if (positionChange == null || positionChange == 0) {
      return SizedBox(

        width: 12,
        child: Center(
          child: Text(
            "-",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    final isUp = positionChange > 0;
    final color = isUp ? Colors.green : Colors.red;
    
    return SizedBox(
      width: 12,
      child: Icon(
        isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _upcomingListForLeaderboard() {
    return Obx(() {
      final controller = Get.find<IptTournamentController>();
      
      if (controller.isLoadingLeaderboardUpcoming.value) {
        return SizedBox(
          height: 200,
          child: Center(child: LoadingWidget(color: AppColors.primaryColor,)),
        );
      }

      final scheduleData = controller.leaderboardUpcomingMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return Column(
        children: List.generate(
          allMatches.length > 5 ? 5 : allMatches.length,
          (index) {
            final matchData = scheduleData.firstWhere(
              (data) => data.matches?.contains(allMatches[index]) ?? false,
              orElse: () => scheduleData.first,
            );
            return UpcomingMatchCard(
              match: allMatches[index],
              categoryType: matchData.categoryType,
              date: matchData.date,
            );
          },
        ),
      );
    });
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
    
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
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
                    color: Color(0xFFCD3529).withOpacity(_pulseAnimation.value * 0.5),
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
                        color: Colors.white.withOpacity(0.7 + (_pulseAnimation.value * 0.3)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(_pulseAnimation.value * 0.4),
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
      ).paddingOnly(top: 10,right: 10),
    );
  }
}
class _AnimatedLiveIndicator extends StatefulWidget {
  @override
  _AnimatedLiveIndicatorState createState() => _AnimatedLiveIndicatorState();
}

class _AnimatedLiveIndicatorState extends State<_AnimatedLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.8 + (_animation.value * 0.4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6 + (_animation.value * 0.4)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(_animation.value * 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "Live",
              style: Get.textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }
}
class _AnimatedWatchLiveButton extends StatefulWidget {
  final VoidCallback onTap;
  
  const _AnimatedWatchLiveButton({required this.onTap});

  @override
  _AnimatedWatchLiveButtonState createState() => _AnimatedWatchLiveButtonState();
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
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _iconAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticInOut,
    ));
    
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
        animation: Listenable.merge([_pulseController, _shimmerController, _iconController]),
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseAnimation.value * 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.secondaryColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.4 + (_pulseAnimation.value * 0.3)),
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
                              Colors.white.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
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