import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/league/league_controller.dart';
import 'package:padel_mobile/presentations/league/widgets/build_sponsor_banner.dart';
import 'package:padel_mobile/presentations/league/widgets/match_card_clipper.dart';
import 'package:padel_mobile/presentations/league/widgets/scoreboard_row.dart';

class LeagueScreen extends StatelessWidget {
  final LeagueController controller =Get.put(LeagueController());
  LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(()=> Scaffold(
        appBar: primaryAppBar(title: Text("League"),centerTitle: true, context: context,),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            Expanded(
              child: controller.selectedTab.value == 0
                  ? _liveMatchContent(context).paddingOnly(top: 10)
                  : const LeaderBoardWidget().paddingOnly(top: 20),
            ),
          ],
        ),
      ),
    );
  }
  Widget _liveMatchContent(BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _liveMatchCard().paddingOnly(bottom: 10),
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
                  : controller.matchTab.value == 1
                      ? "Live Matches"
                      : "Match Results",
              style: Get.textTheme.headlineMedium,
            ),
            if (controller.matchTab.value != 1)
              Obx(() {
                final hasMatches = controller.matchTab.value == 0
                    ? (controller.upcomingMatches.value?.data ?? []).expand((d) => d.matches ?? []).isNotEmpty
                    : (controller.resultMatches.value?.data ?? []).expand((d) => d.matches ?? []).isNotEmpty;
                if (!hasMatches) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    Get.toNamed(RoutesName.leagueMatchLists, arguments: {
                      'matchTab': controller.matchTab.value,
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
                );
              }),
          ],
        ).paddingSymmetric(horizontal: 18,vertical: 8)),
        Expanded(
          child: PageView(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            children: [
              _upcomingList(),
              _liveList(),
              _resultsList(),
            ],
          ),
        ),
      ],
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
          Tab(text: "Live"),
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
                      child: const Text('Live Match'),
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
                      child: const Text('Leader Board'),
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
    return Obx(() {
      if (controller.isLoadingLiveMatches.value) {
        return SizedBox(
          height: 200,
          child: Center(child: LoadingWidget(color: AppColors.primaryColor,)),
        );
      }

      final scheduleData = controller.liveMatches.value?.data ?? [];
      if (scheduleData.isEmpty) return const SizedBox.shrink();

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) return const SizedBox.shrink();

      final firstMatch = allMatches.first;
      final categoryType = scheduleData.firstOrNull?.categoryType ?? "Mixed Doubles";
      final setsWon = scheduleData.firstOrNull?.matchId?.setsWon;

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Stack(
              children: [
                SvgPicture.asset(Assets.imagesFipPromesisBg,fit: BoxFit.cover,width: Get.width,),
                Column(
                  children: [
                    /// LIVE TAG
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFCD3529),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() => CircleAvatar(
                            radius: 4, 
                            backgroundColor: controller.isSocketConnected.value ? Colors.white : Colors.white54
                          )),
                          const SizedBox(width: 6),
                          const Text(
                            "LIVE",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ).paddingOnly(top: 10),
                    /// SCORE ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _teamColumn(
                          firstMatch.teamA?.clubType ?? "",
                          "https://i.pravatar.cc/150?img=1",
                          "https://i.pravatar.cc/150?img=2",
                          (firstMatch.teamA?.players?.isNotEmpty ?? false) ? (firstMatch.teamA!.players![0].playerName ?? "") : "Player 1",
                          (firstMatch.teamA?.players != null && firstMatch.teamA!.players!.length > 1) ? (firstMatch.teamA!.players![1].playerName ?? "") : "Player 2",
                          AppColors.primaryColor,
                        ),

                          Transform.translate(
                          offset: Offset(0, 0),
                          child: Column(
                            children: [
                              Text(categoryType, style: Get.textTheme.labelMedium),
                              SizedBox(height: 8),
                              Obx(() {
                                final currentSetsWon = controller.liveMatches.value?.data?.firstOrNull?.matchId?.setsWon;
                                return Text(
                                "${currentSetsWon?.teamA ?? setsWon?.teamA ?? 0} : ${currentSetsWon?.teamB ?? setsWon?.teamB ?? 0}",
                                    style: Get.textTheme.titleLarge!.copyWith(color: AppColors.blackColor,fontSize: 42));
                              }),
                            ],
                          ),
                        ),
                        _teamColumn(
                          firstMatch.teamB?.clubType ?? "",
                          "https://i.pravatar.cc/150?img=3",
                          "https://i.pravatar.cc/150?img=4",
                          (firstMatch.teamB?.players?.isNotEmpty ?? false) ? (firstMatch.teamB!.players![0].playerName ?? "") : "Player 3",
                          (firstMatch.teamB?.players != null && firstMatch.teamB!.players!.length > 1) ? (firstMatch.teamB!.players![1].playerName ?? "") : "Player 4",
                          AppColors.secondaryColor,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: (){
                            Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
                              "matchType":"live",
                              "matchId": scheduleData.firstOrNull?.matchId?.id ?? ""
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: const Color(0xff27AE60),
                                borderRadius:
                                BorderRadius.circular(30)),
                            child:  Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: AppColors.primaryColor,
                                  child: Icon(Icons.play_arrow,
                                      color: Colors.white, size: 18),
                                ),
                                SizedBox(width: 8),
                                Text("Watch Live",
                                    style: Get.textTheme.labelMedium!.copyWith(color: Colors.white,fontWeight: FontWeight.w500))
                              ],
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
          _buildScoreBoard(scheduleData.firstOrNull).paddingOnly(right: Get.width*0.05,left: Get.width*0.05)
        ],
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
          Text(
            team,
              style:Get.textTheme.headlineMedium!.copyWith(color: color)

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
              style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,fontSize: 11)
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBoard(ScheduleMatchData? matchData) {
    return Obx(() {
      final scoreboardData = controller.liveMatchScoreboard.value;
      final liveMatchData = controller.liveMatches.value?.data?.first; // This will trigger updates
      
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
              logo: teamAData['logo']?.toString() ?? "https://via.placeholder.com/50",
              player1: teamAPlayers.isNotEmpty ? (teamAPlayers[0]['playerName'] ?? "Player 1") : "Player 1",
              player2: teamAPlayers.length > 1 ? (teamAPlayers[1]['playerName'] ?? "Player 2") : "Player 2",
              scores: _formatRoundScores(teamARoundScores, totalRounds),
              points: teamAPoints,
              isTeamA: true,
            ),
          const Divider(height: 1, color: Colors.grey),
          if (teamBPlayers.isNotEmpty)
            ScoreBoardRow(
              logo: teamBData['logo']?.toString() ?? "https://via.placeholder.com/50",
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
      if (controller.isLoadingUpcomingMatches.value) {
        return Center(child: LoadingWidget(color: AppColors.primaryColor,));
      }

      final scheduleData = controller.upcomingMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchUpcomingMatches,
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
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchUpcomingMatches,
          child: Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.white,
        onRefresh: controller.fetchUpcomingMatches,
        child: ListView.builder(
          itemCount: allMatches.length > 5 ? 5 : allMatches.length,
          itemBuilder: (context, index) {
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


  Widget _liveList() {
    return Obx(() {
      if (controller.isLoadingLiveMatches.value) {
        return Center(child: LoadingWidget(color: AppColors.primaryColor,));
      }

      final scheduleData = controller.liveMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchLiveMatches,
          child: Center(
            child: Text(
              "No live matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchLiveMatches,
          child: Center(
            child: Text(
              "No live matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.white,
        onRefresh: controller.fetchLiveMatches,
        child: ListView.builder(
          itemCount: allMatches.length,
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
                  "matchType": "live",
                  "matchId": matchData.matchId?.id ?? ""
                });
              },
              child: LiveMatchCard(
                match: allMatches[index],
                categoryType: matchData.categoryType,
                setsWon: matchData.matchId?.setsWon,
              ),
            );
          },
        ),
      );
    });
  }
  Widget _resultsList() {
    return Obx(() {
      if (controller.isLoadingResultMatches.value) {
        return Center(child: LoadingWidget(color: AppColors.primaryColor,));
      }

      final scheduleData = controller.resultMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchResultMatches,
          child: Center(
            child: Text(
              "No result matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchResultMatches,
          child: Center(
            child: Text(
              "No result matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.white,
        onRefresh: controller.fetchResultMatches,
        child: ListView.builder(
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
        ),
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
                    Color(0xffCBD6FF),
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
                                    formatName(e.playerName ?? ''),
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
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,)
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
                                    formatName(e.playerName ?? ''),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                    "Live",
                    style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
                ),
              ],
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
                    Color(0xffFFC6C2),
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
                                    formatName(e.playerName ?? ''),
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
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,)
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
                                    formatName(e.playerName ?? ''),
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
                          Text(
                              match?.teamA?.clubType ?? "",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                          const Spacer(),
                          Text(
                              match?.teamB?.clubType ?? "",
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
                                    formatName(e.playerName ?? ''),
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
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,)
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
                                    formatName(e.playerName ?? ''),
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
    
    return Column(
      children: [
        Obx(() {
          if (controller.isLoadingLeaderBoard.value) {
            return SizedBox(
              height: 200,
              child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
            );
          }

          final standings = controller.leaderBoard.value?.data?.standings ?? [];

          if (standings.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Column(
              children: [
                _headerRow(),
                Divider(color: Colors.grey.shade300),
                ...standings.map((standing) {
                  return Column(
                    children: [
                      _teamRow(standing),
                      Divider(color: Colors.grey.shade300),
                    ],
                  );
                }),
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
                      'matchTab': 0,
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
        _upcomingList()
      ],
    );
  }

  Widget _headerRow() {
    final style = Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500);
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 20, child: Text("#",style: style,)),
        Expanded(
            flex: 3,
            child: SizedBox(width: 35,child: Text("Teams",style: style))),
        SizedBox(width: 30, child: Text("M",style: style)),
        SizedBox(width: 30, child: Text("W",style: style)),
        SizedBox(width: 30, child: Text("L",style: style)),
        SizedBox(width: 30, child: Text("PTS",style: style)),
        SizedBox(width: 30, child: Text("A/B",style: style)),
        SizedBox(width: 30, child: Text("C/D",style: style)),
        SizedBox(width: 30, child: Text("MX",style: style)),
        SizedBox(width: 30, child: Text("WM",style: style)),
      ],
    );
  }

  Widget _teamRow(standing) {
    return Row(
      children: [
        SizedBox(width: 25, child: Text("${standing.position ?? 0}",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600),)),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
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

         SizedBox(width: 30, child: Text("${standing.played ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("${standing.wins ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("${standing.losses ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("${standing.points ?? 0}", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600))),
         SizedBox(width: 30, child: Text("${standing.abWins ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("${standing.cdWins ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("${standing.mixedWins ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("${standing.womensWins ?? 0}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
      ],
    );
  }
  Widget _upcomingList() {
    return Expanded(
      child: Obx(() {
        final controller = Get.find<LeagueController>();
        
        if (controller.isLoadingUpcomingMatches.value) {
          return Center(child: LoadingWidget(color: AppColors.primaryColor,));
        }

        final scheduleData = controller.upcomingMatches.value?.data ?? [];
        if (scheduleData.isEmpty) {
          return Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          );
        }

        final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
        if (allMatches.isEmpty) {
          return Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: allMatches.length > 5 ? 5 : allMatches.length,
          itemBuilder: (context, index) {
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
        );
      }),
    );
  }
}