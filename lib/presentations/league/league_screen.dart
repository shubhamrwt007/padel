import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/league/league_controller.dart';
import 'package:padel_mobile/presentations/league/widgets/build_sponsor_banner.dart';
import 'package:padel_mobile/presentations/league/widgets/match_card_clipper.dart';
import 'package:padel_mobile/presentations/league/widgets/scoreboard_row.dart';

class LeagueScreen extends StatelessWidget {
  final LeagueController controller =Get.put(LeagueController());
  LeagueScreen({super.key});

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
          title: leagueTitle == 'Swoot Padel League'
              ? SvgPicture.asset(Assets.imagesImgSwootPadelLeague, height: 22, width: 25)
              : Text(leagueTitle),
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
                    ? _liveMatchContent(context).paddingOnly(top: 10)
                    : const LeaderBoardWidget().paddingOnly(top: 20),
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
            }).paddingOnly(bottom: 20),
            BuildTitleSponsor(controller: controller),
            Obx(() {
              final sponsors = controller.sponsors.value?.data?.sponsors ?? [];
              if (sponsors.isEmpty) return const SizedBox.shrink();
              return BuildMoreSponsor(sponsors: sponsors);
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
                      Get.toNamed(RoutesName.leagueMatchLists, arguments: {
                        'leagueId': controller.leagueId ?? '',
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
              height: Get.height * 0.45,
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
                    //   Assets.imagesIcPadel,
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
    final liveData = scheduleData.where((data) => data.matchStatus == 'live').toList();
    
    if (liveData.isEmpty) return const SizedBox.shrink();

    final allMatches = liveData.expand((data) => data.matches ?? []).toList();
    if (allMatches.isEmpty) return const SizedBox.shrink();

    final firstMatch = allMatches.first;
    final categoryType = liveData.firstOrNull?.categoryType ?? "Mixed Doubles";
    final setsWon = liveData.firstOrNull?.matchId?.setsWon;

      return Column(
        children: [
          GestureDetector(
            onTap: (){
              Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
                "matchType":"live",
                "matchId": liveData.firstOrNull?.matchId?.id ?? ""
              });
              print("MATCH ID-> ${ liveData.firstOrNull?.matchId?.id}");
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Stack(
                children: [
                  SvgPicture.asset(Assets.imagesFipPromesisBg,fit: BoxFit.cover,width: Get.width,),
                  Column(
                    children: [
                      /// LIVE TAG
                      _AnimatedLiveTag(),
                      /// SCORE ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _teamColumn(
                            firstMatch.teamA?.clubType ?? "",
                            "",
                            "",
                            (firstMatch.teamA?.players?.isNotEmpty ?? false) ? (firstMatch.teamA!.players![0].playerName ?? "") : "Player 1",
                            (firstMatch.teamA?.players != null && firstMatch.teamA!.players!.length > 1) ? (firstMatch.teamA!.players![1].playerName ?? "") : "Player 2",
                            AppColors.primaryColor,
                          ),

                            Transform.translate(
                            offset: Offset(0, -15),
                            child: Column(
                              children: [
                                Text(categoryType, style: Get.textTheme.labelMedium),
                                SizedBox(height: 8),
                                Obx(() {
                                  final currentSetsWon = controller.upcomingMatches.value?.data
                                    ?.where((data) => data.matchStatus == 'live')
                                    .firstOrNull?.matchId?.setsWon;
                                  return Text(
                                  "${currentSetsWon?.teamA ?? setsWon?.teamA ?? 0} : ${currentSetsWon?.teamB ?? setsWon?.teamB ?? 0}",
                                      style: Get.textTheme.titleLarge!.copyWith(color: AppColors.blackColor,fontSize: 42));
                                }),
                              ],
                            ),
                          ),
                          _teamColumn(
                            firstMatch.teamB?.clubType ?? "",
                            "",
                            "",
                            (firstMatch.teamB?.players?.isNotEmpty ?? false) ? (firstMatch.teamB!.players![0].playerName ?? "") : "Player 3",
                            (firstMatch.teamB?.players != null && firstMatch.teamB!.players!.length > 1) ? (firstMatch.teamB!.players![1].playerName ?? "") : "Player 4",
                            AppColors.secondaryColor,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          _AnimatedWatchLiveButton(onTap: (){
                            Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
                              "matchType":"live",
                              "matchId": liveData.firstOrNull?.matchId?.id ?? ""
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
          _buildScoreBoard(liveData.firstOrNull).paddingOnly(right: Get.width*0.05,left: Get.width*0.05,top: 10)
        ],
      );
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
  
  Widget _buildScoreBoard(ScheduleMatchData? matchData) {
    return Obx(() {
      final scoreboardData = controller.liveMatchScoreboard.value;
      final liveMatchData = controller.upcomingMatches.value?.data
        ?.where((data) => data.matchStatus == 'live')
        .firstOrNull;
      
      if (controller.isLoadingScoreboard.value) {
        return const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(),
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
              ScoreBoardRow(
                logo: "",
                player1: teamAPlayers.isNotEmpty ? (teamAPlayers[0].playerName ?? "Player 1") : "Player 1",
                player2: teamAPlayers.length > 1 ? (teamAPlayers[1].playerName ?? "Player 2") : "Player 2",
                scores: ["0"],
                points: "0",
                isTeamA: true,
              ),
            const Divider(),
            if (teamBPlayers.isNotEmpty)
              ScoreBoardRow(
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
            ScoreBoardRow(
              logo: teamAData['logo']?.toString() ?? "",
              player1: teamAPlayers.isNotEmpty ? (teamAPlayers[0]['playerName'] ?? "Player 1") : "Player 1",
              player2: teamAPlayers.length > 1 ? (teamAPlayers[1]['playerName'] ?? "Player 2") : "Player 2",
              scores: _formatRoundScores(teamARoundScores, totalRounds),
              points: teamAPoints,
              isTeamA: true,
            ),
          const Divider(height: 1, color: Colors.grey),
          if (teamBPlayers.isNotEmpty)
            ScoreBoardRow(
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
          
          if (matches.isEmpty) return const SizedBox.shrink();
          
          final match = matches.first;
          
          if (scheduleItem.matchStatus == 'live') {
            return GestureDetector(
              onTap: () {
                Get.toNamed(RoutesName.liveAndCompleteLeagueMatch, arguments: {
                  "matchType": "live",
                  "matchId": scheduleItem.matchId?.id ?? ""
                });
              },
              child: LiveMatchCard(
                match: match,
                categoryType: scheduleItem.categoryType,
                setsWon: scheduleItem.matchId?.setsWon,
              ),
            );
          }
          
          return UpcomingMatchCard(
            match: match,
            categoryType: scheduleItem.categoryType,
            date: scheduleItem.date,
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
          return GestureDetector(
            onTap: () {
              final matchData = scheduleData.firstWhere(
                (data) => data.matches?.contains(allMatches[index]) ?? false,
                orElse: () => scheduleData.first,
              );
              Get.toNamed(RoutesName.liveAndCompleteLeagueMatch, arguments: {
                "matchType": "result",
                "matchId": matchData.matchId?.id ?? ""
              });
            },
            child: ResultMatchCard(
              match: allMatches[index],
              categoryType: matchData.categoryType,
              date: matchData.date,
              setsWon: matchData.matchId?.setsWon,
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
  
  const UpcomingMatchCard({super.key, this.match, this.categoryType, this.date});

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
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,),
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Container(
                            color: Colors.transparent,
                            width: Get.width*0.2,
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                                match?.teamA?.clubType ?? "Team A",
                                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)
                            ),
                          ),
                          const Spacer(),
                          Container(
                            color: Colors.transparent,
                            width: Get.width*0.2,
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                                match?.teamB?.clubType ?? "Team B",
                                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)
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
                              SvgPicture.asset(Assets.imagesImgVs,).paddingOnly(bottom: 5,top: 5),
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,),
                              Text("${match?.startTime?.split(' ').first??""}-${match?.endTime??""}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w300),),
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
  final SetsWon? setsWon;
  const LiveMatchCard({super.key, this.match, this.categoryType, this.setsWon});

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
                      Assets.imagesDotsFipPromises,
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
                      Assets.imagesDotsFipPromises,
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
                              match?.teamA?.clubType ?? "Team A",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                          const Spacer(),
                          Text(
                              match?.teamB?.clubType ?? "Team B",
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
  final String? date;
  final SetsWon? setsWon;
  
  const ResultMatchCard({super.key, this.match, this.categoryType, this.date, this.setsWon});

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
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF494949),
                        BlendMode.srcIn,
                      ),),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100, colorFilter: const ColorFilter.mode(
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
                                  Assets.imagesIcCrown,
                                  height: 12,
                                  width: 12,
                                ).paddingOnly(right: 4),
                              Text(
                                  match?.teamA?.clubType ?? "",
                                  style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                  match?.teamB?.clubType ?? "",
                                  style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                              ),
                              if (teamBWon)
                                Image.asset(
                                  Assets.imagesIcCrown,
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

class LeaderBoardWidget extends StatelessWidget {
  const LeaderBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LeagueController>();
    
    return RefreshIndicator(
      color: AppColors.whiteColor,
      onRefresh: () async {
        await Future.wait([
          controller.fetchLeaderBoard(),
          controller.fetchUpcomingMatches(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
        Obx(() {
          final standings = controller.leaderBoard.value?.data?.standings ?? [];

          if (standings.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  spreadRadius: 1.5,
                  blurRadius: 5.0,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: Image.asset(
                      Assets.imagesImgIconSwoot,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Column(
                  children: [
                    _headerRow(),
                    Divider(color: Colors.grey.shade300),
                    ...standings.asMap().entries.map((entry) {
                      final index = entry.key;
                      final standing = entry.value;
                      return Column(
                        children: [
                          _teamRow(standing),
                          if (index < standings.length - 1)
                            Divider(color: Colors.grey.shade300),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ).paddingOnly(bottom: 20);
        }),
        BuildTitleSponsor(controller: controller),
        Obx(() {
          final sponsors = controller.sponsors.value?.data?.sponsors ?? [];
          if (sponsors.isEmpty) return const SizedBox.shrink();
          return BuildMoreSponsor(sponsors: sponsors);
        }),
        Obx(() {
          final hasUpcoming = (controller.upcomingMatches.value?.data ?? [])
              .expand((d) => d.matches ?? []).isNotEmpty;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Matches", style: Get.textTheme.headlineMedium),
              if (hasUpcoming)
                GestureDetector(
                  onTap: () {
                    Get.toNamed(RoutesName.leagueMatchLists, arguments: {
                      // 'matchTab': 0,
                      'leagueId': controller.leagueId ?? ''
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
        SizedBox(width: 25, child: Text("#", style: style)),
        Expanded(
          flex: 3,
          child: Text("Teams", style: style),
        ),
        SizedBox(width: 30, child: Center(child: Text("M", style: style))),
        SizedBox(width: 30, child: Center(child: Text("W", style: style))),
        SizedBox(width: 30, child: Center(child: Text("L", style: style))),
        SizedBox(width: 30, child: Center(child: Text("Pts", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700,color: AppColors.primaryColor)))),
        SizedBox(width: 30, child: Center(child: Text("Adv", style: style))),
        SizedBox(width: 30, child: Center(child: Text("Int", style: style))),
        SizedBox(width: 30, child: Center(child: Text("Mx", style: style))),
        SizedBox(width: 30, child: Center(child: Text("Wm", style: style))),
      ],
    );
  }

  Widget _teamRow(standing) {
    return Row(
      children: [
        SizedBox(width: 25, child: Text("${standing.position ?? 0}", style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600, fontSize: 10))),
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
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          (standing.clubName ?? "?")[0].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.primaryColor,
                      child: Text(
                        (standing.clubName ?? "?")[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  standing.clubName ?? "Unknown",
                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 30, child: Center(child: Text("${standing.played ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.wins ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.losses ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.points ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.abWins ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.cdWins ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.mixedWins ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
        SizedBox(width: 30, child: Center(child: Text("${standing.womensWins ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)))),
      ],
    );
  }

  Widget _upcomingListForLeaderboard() {
    return Obx(() {
      final controller = Get.find<LeagueController>();
      
      if (controller.isLoadingUpcomingMatches.value) {
        return SizedBox(
          height: 200,
          child: Center(child: LoadingWidget(color: AppColors.primaryColor,)),
        );
      }

      final scheduleData = controller.upcomingMatches.value?.data ?? [];
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