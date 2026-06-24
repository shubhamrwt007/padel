import 'dart:developer';

import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/endpoitns.dart';
import '../../../data/response_models/ipt_tournament/get_ipt_tournament_match_details_model.dart';
import '../../../data/response_models/americano_models/americano_live_round_response.dart';
import '../../../repositories/americano_repository/americano_repository.dart';

class LiveStreamAmericanoController extends GetxController {
  final AmericanoRepository _repository = AmericanoRepository();

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
  final RxString americanoMatchId = "".obs;
  final RxString roundId = "".obs;
  RxList<bool> isSet2Expanded = <bool>[false, false, false, false].obs;

  final Rx<HistoryData?> historyData = Rx<HistoryData?>(null);
  final Rx<StatisticsData?> statisticsData = Rx<StatisticsData?>(null);
  final RxBool isLoadingMatchDetails = false.obs;
  final RxBool isLoadingHistory = true.obs;
  final RxString matchDetailsError = "".obs;

  IO.Socket? _americanoSocket;
  final RxBool isSocketConnected = false.obs;
  final RxString youtubeVideoId = "".obs;
  final RxBool showVideoPlayer = false.obs;
  final RxBool isStreamLoading = false.obs;
  final Rx<YoutubePlayerController?> youtubeController =
      Rx<YoutubePlayerController?>(null);
  final RxBool showGoToLiveButton = false.obs;

  @override
  void onInit() {
    matchType.value = Get.arguments?["matchType"] ?? "live";
    matchId.value = Get.arguments?["matchId"] ?? "";
    americanoMatchId.value = Get.arguments?["americanoMatchId"] ?? "";
    roundId.value = Get.arguments?["roundId"] ?? "";
    log(
      '🎬 Controller Init - matchType: ${matchType.value}, matchId: ${matchId.value}, americanoMatchId: ${americanoMatchId.value}, roundId: ${roundId.value}',
    );

    if (matchType.value == "live") {
      isLoadingHistory.value = true;
      isLoadingMatchDetails.value = true;
      _initAmericanoSocket();
    } else {
      fetchLiveRoundDetails();
    }

    super.onInit();
  }

  @override
  void onClose() {
    youtubeController.value?.dispose();
    _americanoSocket?.disconnect();
    _americanoSocket?.dispose();
    super.onClose();
  }

  Future<void> fetchLiveRoundDetails() async {
    if (americanoMatchId.value.isEmpty || roundId.value.isEmpty) {
      log("LiveStreamAmericanoController: IDs are empty, cannot fetch details");
      matchDetailsError.value = "Match details ID or Round ID is missing";
      isLoadingHistory.value = false;
      isLoadingMatchDetails.value = false;
      return;
    }

    isLoadingHistory.value = true;
    isLoadingMatchDetails.value = true;
    matchDetailsError.value = "";

    try {
      final AmericanoLiveRoundResponse response = await _repository
          .getAmericanoLiveRound(americanoMatchId.value, roundId.value);

      if (response.success == true && response.data != null) {
        final data = response.data!;

        // 1. Update Scores
        teamAScore.value = data.score?.teamA ?? 0;
        teamBScore.value = data.score?.teamB ?? 0;

        // 2. Map Americano detail & Round detail to HistoryData
        final americanoDetail = data.americano;
        final roundDetail = data.round;

        final teamAData = data.teamA;
        final teamBData = data.teamB;

        historyData.value = HistoryData(
          matchId: roundDetail?.americanoMatchId ?? americanoMatchId.value,
          status: roundDetail?.status ?? "live",
          winner: roundDetail?.winner,
          categoryType: americanoDetail?.matchTitle ?? "Americano Match",
          teamA: Team(
            teamId: "teamA",
            teamName: teamAData?.teamName ?? "Team A",
            clubName: americanoDetail?.clubId?.clubName ?? "",
            players:
                teamAData?.players?.map((p) {
                  return Player(
                    playerId: p.americanoPlayerId,
                    playerName: p.fullName,
                  );
                }).toList() ??
                [],
          ),
          teamB: Team(
            teamId: "teamB",
            teamName: teamBData?.teamName ?? "Team B",
            clubName: americanoDetail?.clubId?.clubName ?? "",
            players:
                teamBData?.players?.map((p) {
                  return Player(
                    playerId: p.americanoPlayerId,
                    playerName: p.fullName,
                  );
                }).toList() ??
                [],
          ),
          // Set a dummy set with points score
          setsWon: SetsWon(teamA: teamAScore.value, teamB: teamBScore.value),
          sets: [
            SetData(
              setNumber: 1,
              finalScore: FinalScore(
                teamA: teamAScore.value,
                teamB: teamBScore.value,
              ),
              setWinner: roundDetail?.winner,
              rounds: [],
            ),
          ],
        );

        // 3. Map StatisticsData
        final statsA = data.stats?.teamA;
        final statsB = data.stats?.teamB;

        statisticsData.value = StatisticsData(
          matchId: roundDetail?.americanoMatchId ?? americanoMatchId.value,
          statistics: MatchStatistics(
            teamA: StatisticsTeam(
              totalPoints: teamAScore.value,
              winners: statsA?.forcedErrors ?? 0,
              faults: statsA?.faults ?? 0,
              errors: statsA?.errors ?? 0,
            ),
            teamB: StatisticsTeam(
              totalPoints: teamBScore.value,
              winners: statsB?.forcedErrors ?? 0,
              faults: statsB?.faults ?? 0,
              errors: statsB?.errors ?? 0,
            ),
          ),
        );

        // 4. Map Point History List
        if (data.pointHistory != null) {
          pointHistoryList.value = data.pointHistory!.map((item) {
            return PointHistoryItem(
              winner: item.winner ?? 'teamA',
              teamAScore: item.teamAScore ?? 0,
              teamBScore: item.teamBScore ?? 0,
              recordedAt: item.recordedAt,
              pointNo: item.pointNo,
            );
          }).toList();
        } else {
          pointHistoryList.value = [];
        }

        // 5. Setup Video Stream
        final videoId = data.youtubeVideoId ?? data.round?.youtubeVideoId;
        if (matchType.value == "live" && videoId != null && videoId.isNotEmpty) {
          showVideoPlayer.value = true;
          setYoutubeUrl(videoId);
        } else {
          showVideoPlayer.value = false;
        }

        isSocketConnected.value = true;
        _syncHeaderFromHistory();
        _syncSetExpandStateFromHistory();
      } else {
        matchDetailsError.value = "Failed to load live round details";
      }
    } catch (e) {
      matchDetailsError.value = "Error: $e";
      log("Error fetching live round details in controller: $e");
    } finally {
      isLoadingHistory.value = false;
      isLoadingMatchDetails.value = false;
    }
  }

  void _initAmericanoSocket() {
    if (matchType.value != "live") return;
    if (_americanoSocket != null) return;

    try {
      log('🔌 Initializing Americano Socket at ${AppEndpoints.socketUrl}/americano');
      _americanoSocket = IO.io('${AppEndpoints.socketUrl}/americano', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _americanoSocket?.onConnect((_) {
        log('✅ Connected to Americano socket namespace /americano');
        _americanoSocket?.emit("joinAmericanoRound", {
          "americanoMatchId": americanoMatchId.value,
          "roundId": roundId.value,
        });
      });

      _americanoSocket?.on("connect_error", (data) {
        log("❌ Socket connect_error: $data");
        isLoadingHistory.value = false;
        isLoadingMatchDetails.value = false;
      });

      _americanoSocket?.on("connect_timeout", (data) {
        log("❌ Socket connect_timeout: $data");
        isLoadingHistory.value = false;
        isLoadingMatchDetails.value = false;
      });

      _americanoSocket?.on("americanoRoundJoined", (payload) {
        log('📡 Socket event: americanoRoundJoined, payload: $payload');
        if (payload != null && payload is Map && payload['round'] != null) {
          _handleSocketRoundUpdate(Map<String, dynamic>.from(payload['round']));
        }
      });

      _americanoSocket?.on("scoreUpdate", (payload) {
        log('📡 Socket event: scoreUpdate, payload: $payload');
        if (payload != null && payload is Map && payload['round'] != null) {
          _handleSocketRoundUpdate(Map<String, dynamic>.from(payload['round']));
        }
      });

      _americanoSocket?.on("error", (payload) {
        log("❌ Socket error: $payload");
        isLoadingHistory.value = false;
        isLoadingMatchDetails.value = false;
      });

      _americanoSocket?.onDisconnect((_) {
        log('❌ Disconnected from Americano socket namespace /americano');
      });

    } catch (e) {
      log("❌ Error initializing Americano socket: $e");
      isLoadingHistory.value = false;
      isLoadingMatchDetails.value = false;
    }
  }

  void _handleSocketRoundUpdate(Map<String, dynamic> roundMap) {
    try {
      log("📡 Processing socket round update: $roundMap");

      // Set loading states to false as we have received data from socket
      isLoadingHistory.value = false;
      isLoadingMatchDetails.value = false;

      final String? newStatus = roundMap['status']?.toString();

      // If status is not live, we should stop showing the video player
      if (newStatus != null && newStatus != "live") {
        showVideoPlayer.value = false;
        youtubeController.value?.dispose();
        youtubeController.value = null;
      }

      final teamAMap = roundMap['teamA'] as Map<String, dynamic>?;
      final teamBMap = roundMap['teamB'] as Map<String, dynamic>?;

      final int pointsA = teamAMap?['points'] is int 
          ? teamAMap!['points'] 
          : int.tryParse(teamAMap?['points']?.toString() ?? '') ?? 0;
      final int pointsB = teamBMap?['points'] is int 
          ? teamBMap!['points'] 
          : int.tryParse(teamBMap?['points']?.toString() ?? '') ?? 0;

      // Update scores
      teamAScore.value = pointsA;
      teamBScore.value = pointsB;

      // Reconstruct HistoryData if it is null
      if (historyData.value == null) {
        final String matchTitle = roundMap['matchTitle']?.toString() ?? "Americano Match";

        // Parse players
        final List<Player> playersA = [];
        if (teamAMap?['players'] != null && teamAMap?['players'] is List) {
          for (var p in teamAMap!['players']) {
            if (p is Map) {
              playersA.add(Player(
                playerId: p['americanoPlayerId']?.toString(),
                playerName: p['fullName']?.toString() ?? p['name']?.toString() ?? '',
              ));
            }
          }
        }

        final List<Player> playersB = [];
        if (teamBMap?['players'] != null && teamBMap?['players'] is List) {
          for (var p in teamBMap!['players']) {
            if (p is Map) {
              playersB.add(Player(
                playerId: p['americanoPlayerId']?.toString(),
                playerName: p['fullName']?.toString() ?? p['name']?.toString() ?? '',
              ));
            }
          }
        }

        historyData.value = HistoryData(
          matchId: roundMap['americanoMatchId']?.toString() ?? americanoMatchId.value,
          status: newStatus ?? "live",
          winner: roundMap['winner']?.toString(),
          categoryType: matchTitle,
          teamA: Team(
            teamId: "teamA",
            teamName: teamAMap?['teamName']?.toString() ?? "Team A",
            clubName: "",
            players: playersA,
          ),
          teamB: Team(
            teamId: "teamB",
            teamName: teamBMap?['teamName']?.toString() ?? "Team B",
            clubName: "",
            players: playersB,
          ),
          setsWon: SetsWon(teamA: pointsA, teamB: pointsB),
          sets: [
            SetData(
              setNumber: 1,
              finalScore: FinalScore(teamA: pointsA, teamB: pointsB),
              setWinner: roundMap['winner']?.toString(),
              rounds: [],
            ),
          ],
        );
        _syncSetExpandStateFromHistory();
      } else {
        if (newStatus != null) {
          historyData.value!.status = newStatus;
        }
        historyData.value!.setsWon = SetsWon(teamA: pointsA, teamB: pointsB);
        if (historyData.value!.sets != null && historyData.value!.sets!.isNotEmpty) {
          historyData.value!.sets![0].finalScore = FinalScore(teamA: pointsA, teamB: pointsB);
        }
        final String? winner = roundMap['winner']?.toString();
        if (winner != null) {
          historyData.value!.winner = winner;
        }
      }

      // 3. Update Stats
      final int faultsA = teamAMap?['faults'] is int ? teamAMap!['faults'] : int.tryParse(teamAMap?['faults']?.toString() ?? '') ?? 0;
      final int errorsA = teamAMap?['errors'] is int ? teamAMap!['errors'] : int.tryParse(teamAMap?['errors']?.toString() ?? '') ?? 0;
      final int forcedErrorsA = teamAMap?['forcedErrors'] is int ? teamAMap!['forcedErrors'] : int.tryParse(teamAMap?['forcedErrors']?.toString() ?? '') ?? 0;

      final int faultsB = teamBMap?['faults'] is int ? teamBMap!['faults'] : int.tryParse(teamBMap?['faults']?.toString() ?? '') ?? 0;
      final int errorsB = teamBMap?['errors'] is int ? teamBMap!['errors'] : int.tryParse(teamBMap?['errors']?.toString() ?? '') ?? 0;
      final int forcedErrorsB = teamBMap?['forcedErrors'] is int ? teamBMap!['forcedErrors'] : int.tryParse(teamBMap?['forcedErrors']?.toString() ?? '') ?? 0;

      statisticsData.value = StatisticsData(
        matchId: americanoMatchId.value,
        statistics: MatchStatistics(
          teamA: StatisticsTeam(
            totalPoints: pointsA,
            winners: forcedErrorsA,
            faults: faultsA,
            errors: errorsA,
          ),
          teamB: StatisticsTeam(
            totalPoints: pointsB,
            winners: forcedErrorsB,
            faults: faultsB,
            errors: errorsB,
          ),
        ),
      );

      // 4. Update Point History
      final dynamic rawHistory = roundMap['pointHistory'];
      if (rawHistory != null && rawHistory is List) {
        pointHistoryList.value = rawHistory.map((item) {
          if (item is Map) {
            return PointHistoryItem(
              winner: item['winner']?.toString() ?? 'teamA',
              teamAScore: item['teamAScore'] is int ? item['teamAScore'] : int.tryParse(item['teamAScore']?.toString() ?? '') ?? 0,
              teamBScore: item['teamBScore'] is int ? item['teamBScore'] : int.tryParse(item['teamBScore']?.toString() ?? '') ?? 0,
              recordedAt: item['recordedAt']?.toString(),
              pointNo: item['pointNo'] is int ? item['pointNo'] : int.tryParse(item['pointNo']?.toString() ?? '') ?? 0,
            );
          }
          return PointHistoryItem(winner: 'teamA', teamAScore: 0, teamBScore: 0);
        }).toList();
      }

      // 5. Update Youtube Video if live status changes video ID
      final String? videoId = roundMap['youtubeVideoId']?.toString();
      if (newStatus == "live" && videoId != null && videoId.isNotEmpty && youtubeVideoId.value != videoId) {
        showVideoPlayer.value = true;
        setYoutubeUrl(videoId);
      }

      historyData.refresh();
      _syncHeaderFromHistory();
    } catch (e) {
      log("❌ Error parsing socket round payload: $e");
    }
  }


  void _startLiveCheckTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (youtubeController.value != null &&
          matchType.value == "live" &&
          showVideoPlayer.value) {
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
