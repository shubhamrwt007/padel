import 'package:padel_owner/core/endpoitns.dart';
import 'package:padel_owner/presentations/home/widgets/home_exports.dart';
import 'package:padel_owner/presentations/tournament/match_details/model/score_history_model.dart'
    hide TeamA;
import 'package:padel_owner/presentations/tournament/match_details/model/score_static_model.dart';
import 'package:padel_owner/socket/socket_connection.dart';

class MatchDetailsController extends GetxController {
  final DioClient dioClient = DioClient();
  final Rx<ScoreHistoryModel?> historyData = Rx<ScoreHistoryModel?>(null);
  final RxBool isHistoryLoading = false.obs;
  final RxList<bool> isSet2Expanded = <bool>[].obs;
  final socketService = SocketService();
  String? matchId;

  @override
  void onInit() {
    if (Get.arguments != null) {
      matchId = Get.arguments['matchId'];
      selectedTab.value = Get.arguments['tabIndex'] ?? 0;
    }
    socketService.connect(matchId: matchId);
    fetchHistory();
    fetchStatistics();
    socketListener();
    super.onInit();
  }
  socketListener() {
    //history update socket
    socketService.listen("historyUpdate", (data) {
      try {
        if (data is Map<String, dynamic>) {
          final historyJson = data['history'] ?? data;

          historyData.value = ScoreHistoryModel.fromJson({
            'success': true,
            'data': historyJson,
          });

          _updateScores();

          // ── Sync expanded state if new set added ──────────
          final setCount = historyData.value?.data?.sets?.length ?? 0;
          if (setCount != isSet2Expanded.length) {
            isSet2Expanded.value = List.generate(
              setCount,
                  (i) => i < isSet2Expanded.length
                  ? isSet2Expanded[i]
                  : false,
            );
          }

          CustomLogger.logMessage(
            msg: "historyUpdate received — sets: $setCount",
            level: LogLevel.info,
          );
        }
      } catch (e, st) {
        CustomLogger.logMessage(
          msg: "historyUpdate parse failed: ${e.toString()}",
          level: LogLevel.error,
          st: st,
        );
        // ── Fallback to API ────────────────────────────────
        fetchHistory();
      }
    });
    //stats update socket
    socketService.listen("statsUpdate", (data) {
      try {
        if (data is Map<String, dynamic>) {
          statisticsData.value = ScoreStatisticModel.fromJson({
            'success': true,
            'data': {
              'matchId': matchId,
              'statistics': data['statistics'] ?? data,
              'totalEvents': data['totalEvents'],
            },
          });

          CustomLogger.logMessage(
            msg: "statsUpdate received",
            level: LogLevel.info,
          );
        }
      } catch (e, st) {
        CustomLogger.logMessage(
          msg: "statsUpdate parse failed: ${e.toString()}",
          level: LogLevel.error,
          st: st,
        );
        // ── Fallback to API ──────────────────────────────────
        fetchStatistics();
      }
    });
  }

  Future<void> fetchHistory() async {
    try {
      isHistoryLoading.value = true;
      final response = await dioClient.get(
        "${AppEndpoints.scoreBase}$matchId/history",
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        historyData.value = ScoreHistoryModel.fromJson(response.data);
        _updateScores();
        // ── Init expanded state per set ───────────────────────
        final setCount = historyData.value?.data?.sets?.length ?? 0;
        isSet2Expanded.value = List.generate(setCount, (_) => false);
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Fetch history failed: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
    } finally {
      isHistoryLoading.value = false;
    }
  }

  // ── Getters for history ───────────────────────────────────────
  String historyTeamAName() =>
      historyData.value?.data?.teamA?.teamName ?? 'Team A';

  String historyTeamBName() =>
      historyData.value?.data?.teamB?.teamName ?? 'Team B';

  String historyWinner() => historyData.value?.data?.winner ?? '';

  bool historyTeamAWon() => historyWinner() == 'teamA';

  bool historyTeamBWon() => historyWinner() == 'teamB';

  List<Sets> get historySets => historyData.value?.data?.sets ?? [];

  // ── Set winner name for a given set index ─────────────────────
  String setWinnerName(int index) {
    final sets = historySets;
    if (index >= sets.length) return '';
    final a = sets[index].finalScore?.teamA ?? 0;
    final b = sets[index].finalScore?.teamB ?? 0;
    if (a > b) return historyTeamAName();
    if (b > a) return historyTeamBName();
    return '';
  }

  // ── Final score string for a set e.g. "6-3" ──────────────────
  String setFinalScoreString(int index) {
    final sets = historySets;
    if (index >= sets.length) return '0-0';
    final a = sets[index].finalScore?.teamA ?? 0;
    final b = sets[index].finalScore?.teamB ?? 0;
    return '$a-$b';
  }

  // ── Set label: last set = "Final Set", others = "Set X" ───────
  // String setLabel(int index) {
  //   final sets = historySets;
  //   final total = sets.length;
  //   if (index == 0) return 'Final Set';
  //   return 'Set ${total - index}';
  // }
  String setLabel(int index) {
    final sets = historySets;
    if (index < 0 || index >= sets.length) return "Set";
    final setNo = sets[index].setNumber;
    if (setNo == null) return "Set";
    final maxSetNo = sets.map((s) => s.setNumber ?? 0).reduce((a, b) => a > b ? a : b);
    return setNo == maxSetNo ? "Final Set" : "Set $setNo";
  }

  // ── Rounds for a set ─────────────────────────────────────────
  List<Rounds> getRounds(int setIndex) {
    final sets = historySets;
    if (setIndex >= sets.length) return [];
    return sets[setIndex].rounds ?? [];
  }

  void _updateScores() {
    final points = historyData.value?.data?.setsWon;
    teamAScore.value = points?.teamA  ?? 0;
    teamBScore.value = points?.teamB  ?? 0;
  }

  RxInt teamAScore = 0.obs;
  RxInt teamBScore = 0.obs;
  final RxInt selectedTab = 0.obs;

  RxInt set3TeamAScore = 6.obs;
  RxInt set3TeamBScore = 4.obs;

  RxString setStatus = "Ongoing".obs;

  List<int> teamARounds = [30, 30, 30, 30];
  List<int> teamBRounds = [45, 45, 45, 45];

  final Rx<ScoreStatisticModel?> statisticsData = Rx<ScoreStatisticModel?>(
    null,
  );
  final RxBool isStatisticsLoading = false.obs;

  TeamA? get statsTeamA => statisticsData.value?.data?.statistics?.teamA;

  TeamA? get statsTeamB => statisticsData.value?.data?.statistics?.teamB;

  Future<void> fetchStatistics() async {
    try {
      isStatisticsLoading.value = true;
      final response = await dioClient.get(
        "${AppEndpoints.scoreBase}$matchId/statistics",
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        statisticsData.value = ScoreStatisticModel.fromJson(response.data);
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Fetch statistics failed: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
    } finally {
      isStatisticsLoading.value = false;
    }
  }
}
