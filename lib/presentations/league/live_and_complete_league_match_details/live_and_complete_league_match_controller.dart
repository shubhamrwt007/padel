import 'dart:developer';

import 'package:get/get.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/repositories/league_repository/league_repository.dart';
import 'package:padel_mobile/data/response_models/league/get_league_match_details_model.dart';
import 'package:padel_mobile/presentations/league/league_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/network/dio_client.dart';

class LiveAndCompleteLeagueMatchController extends GetxController{
  RxInt teamAScore = 0.obs;
  RxInt teamBScore = 0.obs;
  final RxInt selectedTab = 0.obs;
  var matchType = "".obs;
  var matchId = "".obs;
  RxList<bool> isSet2Expanded = <bool>[false, false, false, false].obs;
  
  final LeagueRepository _leagueRepository = LeagueRepository();
  final Rx<HistoryData?> historyData = Rx<HistoryData?>(null);
  final Rx<StatisticsData?> statisticsData = Rx<StatisticsData?>(null);
  final RxBool isLoadingMatchDetails = false.obs;
  final RxString matchDetailsError = "".obs;
  
  IO.Socket? _socket;
  final RxBool isSocketConnected = false.obs;

  @override
  void onInit() {
    matchType.value = Get.arguments["matchType"] ?? "";
    matchId.value = Get.arguments["matchId"] ?? "";
    print('🎬 Controller Init - matchType: ${matchType.value}, matchId: ${matchId.value}');
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
    super.onClose();
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
    isSet2Expanded.value = List<bool>.filled(setsLen, false).obs;
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
        AppEndpoints.socketUrl,
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
        matchDetailsError.value = 'Connection failed';
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
            historyData.value = HistoryData.fromJson(data['history']);
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
            historyData.value = HistoryData.fromJson(history);
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
        if (Get.isRegistered<LeagueController>()) {
          final leagueController = Get.find<LeagueController>();
          leagueController.fetchLiveMatches();
          leagueController.fetchResultMatches();
          leagueController.fetchUpcomingMatches();
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
        // Get first set's games score
        final sets = scoreboard['sets'];
        if (sets != null && sets is List && sets.isNotEmpty) {
          final firstSet = sets[0];
          if (firstSet is Map<String, dynamic>) {
            final teamAGames = firstSet['teamA'];
            final teamBGames = firstSet['teamB'];
            
            if (teamAGames != null) {
              final newScore = teamAGames is int ? teamAGames : int.tryParse(teamAGames.toString()) ?? 0;
              print('🔵 Setting teamAScore from ${teamAScore.value} to $newScore (games)');
              teamAScore.value = newScore;
            }
            if (teamBGames != null) {
              final newScore = teamBGames is int ? teamBGames : int.tryParse(teamBGames.toString()) ?? 0;
              print('🟢 Setting teamBScore from ${teamBScore.value} to $newScore (games)');
              teamBScore.value = newScore;
            }
            
            print('✅ Scoreboard Updated - Team A: ${teamAScore.value}, Team B: ${teamBScore.value}');
          }
        }
      }
    } catch (e) {
      print('❌ Error updating scoreboard: $e');
    }
  }
}