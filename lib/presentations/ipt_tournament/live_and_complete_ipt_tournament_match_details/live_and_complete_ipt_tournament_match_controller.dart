import 'dart:developer';

import 'package:get/get.dart';
import 'package:padel_mobile/presentations/ipt_tournament/ipt_tournament_controller.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_league_match_details_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:padel_mobile/configs/components/app_toast.dart';

import '../../../core/network/dio_client.dart';
import 'widgets/ipt_tournament_match_finished_dialog.dart';

class LiveAndCompleteIptTournamentMatchController extends GetxController{
  RxInt teamAScore = 0.obs;
  RxInt teamBScore = 0.obs;
  final RxInt selectedTab = 0.obs;
  
  String? get winnerTeam {
    final winner = historyData.value?.winner;
    if (winner == null || winner.isEmpty) return null;
    return winner;
  }
  var matchType = "".obs;
  var matchId = "".obs;
  RxList<bool> isSet2Expanded = <bool>[false, false, false, false].obs;
  
  final LeagueRepository _leagueRepository = LeagueRepository();
  final Rx<HistoryData?> historyData = Rx<HistoryData?>(null);
  final Rx<StatisticsData?> statisticsData = Rx<StatisticsData?>(null);
  final RxBool isLoadingMatchDetails = false.obs;
  final RxBool isLoadingHistory = true.obs;
  final RxString matchDetailsError = "".obs;
  int _previousRoundCount = 0;
  int _previousSetCount = 0;
  
  IO.Socket? _socket;
  final RxBool isSocketConnected = false.obs;
  final RxString youtubeVideoId = "".obs;
  final RxBool showVideoPlayer = false.obs;
  final RxBool isStreamLoading = false.obs;
  final Rx<YoutubePlayerController?> youtubeController = Rx<YoutubePlayerController?>(null);
  final RxBool showGoToLiveButton = false.obs;

  @override
  void onInit() {
    matchType.value = Get.arguments["matchType"] ?? "";
    matchId.value = Get.arguments["matchId"] ?? "";
    log('🎬 Controller Init - matchType: ${matchType.value}, matchId: ${matchId.value}');
    log('🔍 Checking matchType for youtube: "${matchType.value}" == "live" → ${matchType.value == "live"}');
    
    // Debug: Print current historyData
    log('👀 Current historyData winner: ${historyData.value?.winner}');
    log('👀 Current historyData teamA: ${historyData.value?.teamA?.teamName}');
    log('👀 Current historyData teamB: ${historyData.value?.teamB?.teamName}');
    
    if (matchType.value == "live") {
      log('▶️ Fetching stream url...');
      fetchStreamUrl();
      _startLiveCheckTimer();
    }
    if (matchId.value.isNotEmpty) {
      if (matchType.value == "live") {
        print('🔴 LIVE match detected - connecting WebSocket');
        _connectWebSocket();
      } else {
        print('📡 Finished match - fetching via API');
        fetchMatchDetails();
      }
    } else {
      print('⚠️ matchId is empty!');
    }
    super.onInit();
  }
  
  @override
  void onClose() {
    _disconnectWebSocket();
    youtubeController.value?.dispose();
    super.onClose();
  }

  void _startLiveCheckTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (youtubeController.value != null && matchType.value == "live") {
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

  Future<void> fetchStreamUrl() async {
    try {
      isStreamLoading.value = true;

    // final response = await _leagueRepository.getStreamUrl(matchId: matchId.value);
    // final streamKey = response.data?.streamKey;
    // if (response.success == true && streamKey != null && streamKey.isNotEmpty) {
    //   showVideoPlayer.value = true;
    //   setYoutubeUrl(streamKey);
    // } else {
    //   log('⚠️ Stream not available (success=false or no streamKey)');
    //   showVideoPlayer.value = false;
    // }

      // 🔴 Dummy Live Stream (temporary)
      const dummyLiveUrl = "jfKfPfyJRdk";

      showVideoPlayer.value = true;
      setYoutubeUrl(dummyLiveUrl);

    } catch (e) {
      log('❌ fetchStreamUrl error: $e');
      showVideoPlayer.value = false;
    } finally {
      isStreamLoading.value = false;
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
  }
  
  Future<void> fetchMatchDetails() async {
    try {
      isLoadingMatchDetails.value = true;
      matchDetailsError.value = "";
      final type = selectedTab.value == 0 ? "history" : "statistics";
      final response = await _leagueRepository.getLeagueMatchDetails(
        matchId: matchId.value,
        type: type,
      );
      if (type == "history") {
        historyData.value = response.history;
        isLoadingHistory.value = false;
        _syncHeaderFromHistory();
        _syncSetExpandStateFromHistory();
      } else {
        statisticsData.value = response.statistics;
      }
    } catch (e) {
      matchDetailsError.value = e.toString();
    } finally {
      isLoadingMatchDetails.value = false;
    }
  }
  
  void onTabChanged(int index) {
    selectedTab.value = index;
    if (matchId.value.isNotEmpty) {
      if (matchType.value == "live") {
        // For live matches, request data via socket
        _socket?.emit('requestData', {
          'matchId': matchId.value,
          'type': index == 0 ? 'history' : 'statistics'
        });
      } else {
        // For finished matches, use API
        fetchMatchDetails();
      }
    }
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
    // Create list with last set expanded (last index is the latest set)
    final expandedList = List<bool>.filled(setsLen, false);
    if (setsLen > 0) {
      expandedList[setsLen - 1] = true; // Expand the last set
    }
    isSet2Expanded.value = expandedList.obs;
  }
  
  void _connectWebSocket() {
    try {
      print('🔌 Attempting to connect WebSocket...');

      final userId = storage.read('userId')?.toString() ?? '';
      // _socket = IO.io(AppEndpoints.socketUrl, <String, dynamic>{
      //   'transports': ['websocket', 'polling'],
      //   'autoConnect': true,
      // });
      _socket = IO.io(
        "${AppEndpoints.socketUrl}/score",
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'userId': userId})
            .build(),
      );
      _socket?.on('connect', (_) {
        print('✅ Connected. Socket ID: ${_socket?.id}');
        isSocketConnected.value = true;
        print('📤 Emitting joinMatch with matchId: ${matchId.value}');
        _socket?.emit('joinScoreMatch', matchId.value);

        // Request initial data immediately
        print('📤 Requesting initial match data');
        // _socket?.emit('matchJoined', {'matchId': matchId.value});
        _socket?.on("scoreMatchJoined",(data){
          log('''
┌──────────────────────────────────────────────────────────────
│ 🟢 Get Match Data
├──────────────────────────────────────────────────────────────
$data
└──────────────────────────────────────────────────────────────
''');
        });
      });
      
      
      _socket?.on('disconnect', (reason) {
        log('❌ Disconnected: $reason');
        isSocketConnected.value = false;
      });
      
      _socket?.on('connect_error', (err) {
        log('⚠️ Connection failed: $err');
        matchDetailsError.value = '';
      });

      _socket?.on('matchUpdate', (data) {
        log('📥 matchUpdate event received');
        _handleMatchUpdate(data);
      });
      
      _socket?.on('scoreUpdate', (data) {
        print('📊 scoreUpdate event received');
        log('📊 Score Update Data: $data');
        if (data is Map<String, dynamic>) {
          final scoreboard = data['scoreboard'];
          log('📋 Scoreboard Data: $scoreboard');
          _updateScoreboard(scoreboard);
        }
      });
      
      _socket?.on('scoreMatchJoined', (data) {
        print('🎯 matchJoined event received');
        log('🎯 Match Joined Data: $data');
        if (data is Map<String, dynamic>) {
          // Handle scoreboard
          if (data.containsKey('scoreboard')) {
            _updateScoreboard(data['scoreboard']);
          }
          // Handle history
          if (data.containsKey('history')) {
            final newHistoryData = HistoryData.fromJson(data['history']);
            log('📚 scoreMatchJoined - TeamA: ${newHistoryData.teamA?.teamName}, TeamB: ${newHistoryData.teamB?.teamName}, Winner: ${newHistoryData.winner}');
            _initializeRoundCount(newHistoryData);
            historyData.value = newHistoryData;
            isLoadingHistory.value = false;
            _syncHeaderFromHistory();
            _syncSetExpandStateFromHistory();
          }
          // Handle statistics
          if (data.containsKey('statistics')) {
            statisticsData.value = StatisticsData.fromJson({'statistics': data['statistics']});
          }
        }
      });

      _socket?.on('historyUpdate', (data) {
        print('📜 historyUpdate event received');
        if (data is Map<String, dynamic>) {
          final history = data['history'];
          if (history != null) {
            print('📜 History Data received, updating...');
            final newHistoryData = HistoryData.fromJson(history);
            _checkRoundCompletion(newHistoryData);
            historyData.value = newHistoryData;
            isLoadingHistory.value = false;
            _syncSetExpandStateFromHistory();
          }
        }
      });
      
      _socket?.on('statsUpdate', (data) {
        print('📈 statsUpdate event received');
        if (data is Map<String, dynamic>) {
          final statistics = data['statistics'];
          if (statistics != null && selectedTab.value == 1) {
            print('📈 Statistics Data received, updating...');
            statisticsData.value = StatisticsData.fromJson({'statistics': statistics});
          }
        }
      });
      
      _socket?.on('matchFinished', (data) {
        log('🏁 matchFinished event received');
        log('🏁 Match Finished Data: $data');
        
        String winnerTeamName = 'Winner';
        
        if (data is Map<String, dynamic>) {
          final winner = data['winner'];
          log('🏆 Winner from socket: $winner');
          log('🏆 TeamA name: ${historyData.value?.teamA?.teamName}');
          log('🏆 TeamB name: ${historyData.value?.teamB?.teamName}');
          
          if (winner == 'teamA') {
            winnerTeamName = historyData.value?.teamA?.teamName ?? historyData.value?.teamA?.clubName ?? 'Team A';
          } else if (winner == 'teamB') {
            winnerTeamName = historyData.value?.teamB?.teamName ?? historyData.value?.teamB?.clubName ?? 'Team B';
          }
          
          log('🏆 Final winner team name: $winnerTeamName');
        }
        
        Get.dialog(
          IptTournamentMatchFinishedDialog(winnerTeamName: winnerTeamName),
          barrierDismissible: false,
        );
        
        if (Get.isRegistered<IptTournamentController>()) {
          final iptTournamentController = Get.find<IptTournamentController>();
          iptTournamentController.fetchResultMatches();
          iptTournamentController.fetchUpcomingMatches();
        }
      });
      
      // Listen to all events for debugging
      _socket?.onAny((event, data) {
        log('🔔 Socket Event: $event');
        log('🔔 Event Data: $data');
      });
      
    } catch (e) {
      log('❌ WebSocket error: $e');
      matchDetailsError.value = e.toString();
    }
  }
  
  void _disconnectWebSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isSocketConnected.value = false;
  }
  
  void _handleMatchUpdate(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        if (selectedTab.value == 0) {
          historyData.value = HistoryData.fromJson(data['history'] ?? {});
          _syncHeaderFromHistory();
          _syncSetExpandStateFromHistory();
        } else {
          statisticsData.value = StatisticsData.fromJson(data['statistics'] ?? {});
        }
      }
    } catch (e) {
      print('Error handling match update: $e');
    }
  }
  
  void _updateScoreboard(dynamic scoreboard) {
    try {
      print('🔄 Updating Scoreboard...');
      if (scoreboard is Map<String, dynamic>) {
        final setsWon = scoreboard['setsWon'];
        if (setsWon is Map<String, dynamic>) {
          final teamA = setsWon['teamA'];
          final teamB = setsWon['teamB'];
          
          if (teamA != null) {
            final newScore = teamA is int ? teamA : int.tryParse(teamA.toString()) ?? 0;
            print('🔵 Setting teamAScore from ${teamAScore.value} to $newScore (setsWon)');
            teamAScore.value = newScore;
          }
          if (teamB != null) {
            final newScore = teamB is int ? teamB : int.tryParse(teamB.toString()) ?? 0;
            print('🟢 Setting teamBScore from ${teamBScore.value} to $newScore (setsWon)');
            teamBScore.value = newScore;
          }
          
          print('✅ Scoreboard Updated - Team A: ${teamAScore.value}, Team B: ${teamBScore.value}');
        }
      }
    } catch (e) {
      print('❌ Error updating scoreboard: $e');
    }
  }

  void _initializeRoundCount(HistoryData? data) {
    if (data?.sets == null) return;
    int totalRounds = 0;
    for (var set in data!.sets!) {
      totalRounds += set.rounds?.length ?? 0;
    }
    _previousRoundCount = totalRounds;
    _previousSetCount = data.sets?.length ?? 0;
  }

  void _checkRoundCompletion(HistoryData? newData) {
    if (newData?.sets == null) return;
    
    int currentRoundCount = 0;
    for (var set in newData!.sets!) {
      currentRoundCount += set.rounds?.length ?? 0;
    }
    
    int currentSetCount = newData.sets?.length ?? 0;
    
    // Check if new set completed
    if (currentSetCount > _previousSetCount && _previousSetCount > 0) {
      AppToast.success('Set $currentSetCount completed! 🎾');
    }
    // Check if new round completed
    else if (currentRoundCount > _previousRoundCount && _previousRoundCount > 0) {
      AppToast.info('Round completed! 🎾');
    }
    
    _previousRoundCount = currentRoundCount;
    _previousSetCount = currentSetCount;
  }
}