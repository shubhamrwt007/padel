import 'dart:developer';

import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../data/response_models/ipt_tournament/get_ipt_tournament_match_details_model.dart';

class LiveStreamAmericanoController extends GetxController {
  RxInt teamAScore = 0.obs;
  RxInt teamBScore = 0.obs;
  final RxInt selectedTab = 0.obs;
  final RxList<PointHistoryItem> pointHistoryList = <PointHistoryItem>[].obs;
  
  String get teamAName => historyData.value?.teamA?.teamName ?? "Team A";
  String get teamBName => historyData.value?.teamB?.teamName ?? "Team B";
  String get leftTeam => 'teamA';

  String? get winnerTeam {
    final winner = historyData.value?.winner;
    if (winner == null || winner.isEmpty) return null;
    return winner;
  }

  var matchType = "".obs;
  var matchId = "".obs;
  RxList<bool> isSet2Expanded = <bool>[false, false, false, false].obs;

  final Rx<HistoryData?> historyData = Rx<HistoryData?>(null);
  final Rx<StatisticsData?> statisticsData = Rx<StatisticsData?>(null);
  final RxBool isLoadingMatchDetails = false.obs;
  final RxBool isLoadingHistory = true.obs;
  final RxString matchDetailsError = "".obs;

  final RxBool isSocketConnected = false.obs;
  final RxString youtubeVideoId = "".obs;
  final RxBool showVideoPlayer = false.obs;
  final RxBool isStreamLoading = false.obs;
  final Rx<YoutubePlayerController?> youtubeController = Rx<YoutubePlayerController?>(null);
  final RxBool showGoToLiveButton = false.obs;

  @override
  void onInit() {
    matchType.value = Get.arguments?["matchType"] ?? "live";
    matchId.value = Get.arguments?["matchId"] ?? "mock_match_id";
    log('🎬 Controller Init - matchType: ${matchType.value}, matchId: ${matchId.value}');

    _loadMockData();

    if (matchType.value == "live") {
      showVideoPlayer.value = true;
      setYoutubeUrl("dQw4w9WgXcQ");
    }

    super.onInit();
  }

  @override
  void onClose() {
    youtubeController.value?.dispose();
    super.onClose();
  }

  void _loadMockData() {
    isLoadingHistory.value = true;
    isLoadingMatchDetails.value = true;

    teamAScore.value = 1;
    teamBScore.value = 1;

    historyData.value = HistoryData(
      matchId: matchId.value,
      status: "live",
      winner: null,
      categoryType: "Americano Men's Open",
      teamA: Team(
        teamId: "team_a",
        teamName: "Super Smashers",
        clubName: "Padel Club A",
        players: [
          Player(playerId: "p1", playerName: "John Doe"),
          Player(playerId: "p2", playerName: "Jane Smith"),
        ],
      ),
      teamB: Team(
        teamId: "team_b",
        teamName: "Padel Pros",
        clubName: "Padel Club B",
        players: [
          Player(playerId: "p3", playerName: "Bob Johnson"),
          Player(playerId: "p4", playerName: "Alice Williams"),
        ],
      ),
      setsWon: SetsWon(teamA: 1, teamB: 1),
      sets: [
        SetData(
          setNumber: 1,
          finalScore: FinalScore(teamA: 21, teamB: 18),
          setWinner: "teamA",
          rounds: [
            RoundData(round: 1, score: FinalScore(teamA: 4, teamB: 2), pointsAtEnd: CurrentPoints(teamA: "4", teamB: "2"), completedAt: "16:00", gameWinner: "teamA", winType: "NORMAL"),
            RoundData(round: 2, score: FinalScore(teamA: 8, teamB: 4), pointsAtEnd: CurrentPoints(teamA: "8", teamB: "4"), completedAt: "16:05", gameWinner: "teamA", winType: "NORMAL"),
            RoundData(round: 3, score: FinalScore(teamA: 12, teamB: 8), pointsAtEnd: CurrentPoints(teamA: "12", teamB: "8"), completedAt: "16:10", gameWinner: "teamB", winType: "NORMAL"),
            RoundData(round: 4, score: FinalScore(teamA: 16, teamB: 12), pointsAtEnd: CurrentPoints(teamA: "16", teamB: "12"), completedAt: "16:15", gameWinner: "teamB", winType: "NORMAL"),
            RoundData(round: 5, score: FinalScore(teamA: 21, teamB: 18), pointsAtEnd: CurrentPoints(teamA: "21", teamB: "18"), completedAt: "16:20", gameWinner: "teamA", winType: "NORMAL"),
          ],
        ),
        SetData(
          setNumber: 2,
          finalScore: FinalScore(teamA: 15, teamB: 15),
          setWinner: null,
          rounds: [
            RoundData(round: 1, score: FinalScore(teamA: 2, teamB: 2), pointsAtEnd: CurrentPoints(teamA: "2", teamB: "2"), completedAt: "16:25", gameWinner: "teamA", winType: "NORMAL"),
            RoundData(round: 2, score: FinalScore(teamA: 4, teamB: 6), pointsAtEnd: CurrentPoints(teamA: "4", teamB: "6"), completedAt: "16:30", gameWinner: "teamB", winType: "NORMAL"),
            RoundData(round: 3, score: FinalScore(teamA: 8, teamB: 8), pointsAtEnd: CurrentPoints(teamA: "8", teamB: "8"), completedAt: "16:35", gameWinner: "teamA", winType: "NORMAL"),
            RoundData(round: 4, score: FinalScore(teamA: 12, teamB: 12), pointsAtEnd: CurrentPoints(teamA: "12", teamB: "12"), completedAt: "16:40", gameWinner: "teamB", winType: "NORMAL"),
            RoundData(round: 5, score: FinalScore(teamA: 15, teamB: 15), pointsAtEnd: CurrentPoints(teamA: "15", teamB: "15"), completedAt: "16:45", gameWinner: "teamA", winType: "NORMAL"),
          ],
        ),
      ],
    );

    statisticsData.value = StatisticsData(
      matchId: matchId.value,
      statistics: MatchStatistics(
        teamA: StatisticsTeam(
          winners: 12,
          errors: 8,
          forcedErrors: 4,
          unforcedErrors: 4,
          totalPoints: 36,
          breakPointOpportunities: 5,
          breakPointsWon: 3,
          goldenPoints: 2,
          firstServePercentage: 72,
        ),
        teamB: StatisticsTeam(
          winners: 10,
          errors: 11,
          forcedErrors: 5,
          unforcedErrors: 6,
          totalPoints: 33,
          breakPointOpportunities: 4,
          breakPointsWon: 2,
          goldenPoints: 1,
          firstServePercentage: 65,
        ),
      ),
    );

    pointHistoryList.value = [
      PointHistoryItem(winner: 'teamA', teamAScore: 1, teamBScore: 0, recordedAt: DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(), pointNo: 1),
      PointHistoryItem(winner: 'teamA', teamAScore: 2, teamBScore: 0, recordedAt: DateTime.now().subtract(const Duration(minutes: 13)).toIso8601String(), pointNo: 2),
      PointHistoryItem(winner: 'teamB', teamAScore: 2, teamBScore: 1, recordedAt: DateTime.now().subtract(const Duration(minutes: 11)).toIso8601String(), pointNo: 3),
      PointHistoryItem(winner: 'teamA', teamAScore: 3, teamBScore: 1, recordedAt: DateTime.now().subtract(const Duration(minutes: 9)).toIso8601String(), pointNo: 4),
      PointHistoryItem(winner: 'teamB', teamAScore: 3, teamBScore: 2, recordedAt: DateTime.now().subtract(const Duration(minutes: 7)).toIso8601String(), pointNo: 5),
      PointHistoryItem(winner: 'teamB', teamAScore: 3, teamBScore: 3, recordedAt: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(), pointNo: 6),
      PointHistoryItem(winner: 'teamA', teamAScore: 4, teamBScore: 3, recordedAt: DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(), pointNo: 7),
    ];

    isLoadingHistory.value = false;
    isLoadingMatchDetails.value = false;
    isSocketConnected.value = true;
    _syncHeaderFromHistory();
    _syncSetExpandStateFromHistory();
  }

  void _startLiveCheckTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (youtubeController.value != null && matchType.value == "live" && showVideoPlayer.value) {
        _checkIfBehindLive();
        _startLiveCheckTimer();
      }
    });
  }

  void _checkIfBehindLive() {
    final controller = youtubeController.value;
    if (controller == null) return;

    final currentPosition = controller.value.position.inSeconds;
    final duration = controller.metadata.duration.inSeconds;

    if (duration > 0 && (duration - currentPosition) > 10) {
      showGoToLiveButton.value = true;
    } else {
      showGoToLiveButton.value = false;
    }
  }

  void goToLive() {
    final controller = youtubeController.value;
    if (controller != null) {
      showGoToLiveButton.value = false;
      final duration = controller.metadata.duration.inSeconds;
      controller.seekTo(Duration(seconds: duration));
    }
  }

  void setYoutubeUrl(String videoId) {
    log('🎥 setYoutubeUrl called - videoId: $videoId');
    youtubeVideoId.value = videoId;
    youtubeController.value = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        disableDragSeek: true,
      ),
    );
    log('✅ YoutubePlayerController created with id: $videoId');
    _startLiveCheckTimer();
  }

  void onTabChanged(int index) {
    selectedTab.value = index;
  }

  void _syncHeaderFromHistory() {
    final h = historyData.value;
    if (h?.setsWon == null) return;

    final a = h!.setsWon!.teamA;
    final b = h.setsWon!.teamB;

    if (a != null) teamAScore.value = a;
    if (b != null) teamBScore.value = b;
  }

  void _syncSetExpandStateFromHistory() {
    final setsLen = historyData.value?.sets?.length ?? 0;
    if (setsLen <= 0) {
      isSet2Expanded.value = <bool>[].obs;
      return;
    }
    final expandedList = List<bool>.filled(setsLen, false);
    if (setsLen > 0) {
      expandedList[setsLen - 1] = true;
    }
    isSet2Expanded.value = expandedList.obs;
  }
}

class PointHistoryItem {
  final String winner;
  final int teamAScore;
  final int teamBScore;
  final String? recordedAt;
  final int? pointNo;

  PointHistoryItem({
    required this.winner,
    required this.teamAScore,
    required this.teamBScore,
    this.recordedAt,
    this.pointNo,
  });
}