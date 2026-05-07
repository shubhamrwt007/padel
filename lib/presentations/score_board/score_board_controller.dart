import 'dart:async';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/repositories/score_board_repo/score_board_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:padel_mobile/presentations/score_board/widgets/match_summary_dialog.dart';
import 'package:padel_mobile/presentations/score_board/widgets/teams_shuffle_result_dialog.dart' hide showTeamsShuffleResultDialog;
import 'package:flutter/services.dart';

class ScoreBoardController extends GetxController {
  RxList<Map<String, dynamic>> sets = <Map<String, dynamic>>[].obs;

  RxInt teamAWins = 0.obs;
  RxInt teamBWins = 0.obs;
  RxString winner = "".obs;
  RxString matchDate = "".obs;
  RxString matchTime = "".obs;
  RxString startTime = "".obs;
  RxString endTime = "".obs;
  RxString clubName = "".obs;
  RxString courtName = "".obs;
  RxBool isCompleted = false.obs;

  ///Get match end time----------------------------------------------
  String get matchEndTime {
    try {
      if (matchTime.value.isEmpty) return "";

      String timeStr = matchTime.value.trim();
      List<String> parts = timeStr.split('-');

      String endTimeStr;
      
      if (parts.length == 1) {
        // Single time format - use slot duration
        String startTimeStr = _normalizeTimeFormat(parts[0].trim());
        DateTime startTime = DateFormat('h:mm a').parse(startTimeStr);
        int slotDurationMinutes = _getSlotDurationMinutes();
        DateTime endTime = startTime.add(Duration(minutes: slotDurationMinutes));
        endTimeStr = DateFormat('h:mm a').format(endTime);
      } else if (parts.length >= 2) {
        endTimeStr = _normalizeTimeFormat(parts[1].trim());
      } else {
        return "";
      }

      return endTimeStr;
    } catch (e) {
      CustomLogger.logMessage(msg: "Error getting match end time: $e", level: LogLevel.error);
      return "";
    }
  }
  // Timer-related variables
  RxInt remainingSeconds = 0.obs;
  late Timer _gameTimer;
  late Timer _countdownTimer;
  RxBool isGameStarted = false.obs;
  RxBool isWithinMatchTime = false.obs;
  RxBool isCountdownActive = false.obs;

  ///Calculate total match duration in seconds----------------------------------------------
  int _calculateTotalMatchDuration() {
    try {
      if (startTime.value.isEmpty || endTime.value.isEmpty) return 0;

      String startTimeStr = _normalizeTimeFormat(startTime.value.trim());
      String endTimeStr = _normalizeTimeFormat(endTime.value.trim());
      
      DateTime startTimeObj = DateFormat('h:mm a').parse(startTimeStr);
      DateTime endTimeObj = DateFormat('h:mm a').parse(endTimeStr);
      
      int durationMinutes = endTimeObj.difference(startTimeObj).inMinutes;
      return durationMinutes * 60; // Convert to seconds
    } catch (e) {
      CustomLogger.logMessage(msg: "Error calculating total match duration: $e", level: LogLevel.error);
      return 0;
    }
  }

  ///Calculate remaining match time in seconds----------------------------------------------
  int calculateRemainingMatchTime() {
    try {
      if (endTime.value.isEmpty || matchDate.value.isEmpty) return 0;

      String endTimeStr = _normalizeTimeFormat(endTime.value.trim());
      DateTime endTimeObj = DateFormat('h:mm a').parse(endTimeStr);
      DateTime now = DateTime.now();
      
      // Parse match date
      DateTime matchDateObj = DateTime.parse(matchDate.value.trim());
      
      // Create end datetime using match date
      DateTime endDateTime = DateTime(matchDateObj.year, matchDateObj.month, matchDateObj.day, endTimeObj.hour, endTimeObj.minute);

      int remainingSeconds = endDateTime.difference(now).inSeconds;
      return remainingSeconds > 0 ? remainingSeconds : 0;
    } catch (e) {
      CustomLogger.logMessage(msg: "Error calculating remaining match time: $e", level: LogLevel.error);
      return 0;
    }
  }

  ///Get slot duration in minutes from booking----------------------------------------------
  int _getSlotDurationMinutes() {
    try {
      if (matchTime.value.isEmpty) return 60; // Default 60 minutes

      String timeStr = matchTime.value.trim();
      List<String> parts = timeStr.split('-');

      if (parts.length >= 2) {
        String startTimeStr = _normalizeTimeFormat(parts[0].trim());
        String endTimeStr = _normalizeTimeFormat(parts[1].trim());
        
        DateTime startTime = DateFormat('h:mm a').parse(startTimeStr);
        DateTime endTime = DateFormat('h:mm a').parse(endTimeStr);
        
        int durationMinutes = endTime.difference(startTime).inMinutes;
        return durationMinutes > 0 ? durationMinutes : 60;
      }
      
      return 60; // Default if single time format
    } catch (e) {
      CustomLogger.logMessage(msg: "Error getting slot duration: $e", level: LogLevel.error);
      return 60; // Default fallback
    }
  }

  ///Check if current time is at or after match start time----------------------------------------------
  bool _isWithinMatchTimeWindow() {
    try {
      if (startTime.value.isEmpty || endTime.value.isEmpty || matchDate.value.isEmpty) {
        CustomLogger.logMessage(msg: "startTime, endTime or matchDate is EMPTY", level: LogLevel.error);
        return false;
      }

      String startTimeStr = _normalizeTimeFormat(startTime.value.trim());
      String endTimeStr = _normalizeTimeFormat(endTime.value.trim());
      
      DateTime startTimeObj = DateFormat('h:mm a').parse(startTimeStr);
      DateTime endTimeObj = DateFormat('h:mm a').parse(endTimeStr);
      DateTime now = DateTime.now();
      
      // Parse match date
      DateTime matchDateObj = DateTime.parse(matchDate.value.trim());
      
      // Create start and end datetime using match date
      DateTime startDateTime = DateTime(matchDateObj.year, matchDateObj.month, matchDateObj.day, startTimeObj.hour, startTimeObj.minute);
      DateTime endDateTime = DateTime(matchDateObj.year, matchDateObj.month, matchDateObj.day, endTimeObj.hour, endTimeObj.minute);
      
      // If end time is before start time, it's next day
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
      
      // Check if current time is within match window
      bool isWithin = (now.isAfter(startDateTime) || now.isAtSameMomentAs(startDateTime)) && now.isBefore(endDateTime);
      
      return isWithin;
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR in _isWithinMatchTimeWindow: $e", level: LogLevel.error);
      return false;
    }
  }

  final _uuid = Uuid();

  // Stream controller for periodic updates
  late StreamController<Map<String, dynamic>> _scoreboardStreamController;
  late Timer _periodicTimer;

  Stream<Map<String, dynamic>> get scoreboardStream => _scoreboardStreamController.stream;

  ///Capitalize First Word------------------------------------------------------

  String capitalizeFirstWord(String text) {
    if (text.isEmpty) return text;
    List<String> words = text.split(" ");
    String first = words.first;
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  ///Format remaining time as HH:MM:SS or MM:SS----------------------------------------------
  String get formattedTime {
    if (!isWithinMatchTime.value && !isGameStarted.value) {
      return '00:00';
    }
    
    final totalMinutes = remainingSeconds.value ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final seconds = remainingSeconds.value % 60;
    
    if (hours > 0) {
      // Show hours:minutes:seconds format (e.g., 1:59:59)
      return '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      // Show minutes:seconds format (e.g., 59:59)
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  ///Get current player IDs in the match--------------------------------------
  List<String> get currentPlayerIds {
    List<String> playerIds = [];
    for (var team in teams) {
      final players = team['players'] as List;
      for (var player in players) {
        final playerId = player['playerId']?.toString();
        if (playerId != null && playerId.isNotEmpty) {
          playerIds.add(playerId);
        }
      }
    }
    return playerIds;
  }

  ///Check if all 4 players are added----------------------------------------------
  bool get allPlayersAdded {
    final teamAPlayers = teams.isNotEmpty
        ? teams[0]["players"] as List
        : [];
    final teamBPlayers = teams.length > 1
        ? teams[1]["players"] as List
        : [];
    return teamAPlayers.length == 2 && teamBPlayers.length == 2;
  }

  ///Get Score Board Api--------------------------------------------------------

  RxList<Map<String, dynamic>> teams = <Map<String, dynamic>>[].obs;
  var bookingId = ''.obs;
  var bookingType = ''.obs;
  var scoreboardId = ''.obs;
  var openMatchId = ''.obs;
  final registerClubId = ''.obs;
  ScoreBoardRepository repository = Get.put(ScoreBoardRepository());
  final isLoading = true.obs;
  final isAddingSet = false.obs;
  final isAddingScore = false.obs;
  final isShuffleMode = false.obs;
  final hasPlayerSwaps = false.obs;
  final didShuffleDuringActiveMatch = false.obs;
  final wasSwapDuringMatch = false.obs; // New flag to track if current completion was due to swap
  final preShuffleWinner = ''.obs;
  final preShuffleTeamAWins = 0.obs;
  final preShuffleTeamBWins = 0.obs;
  final preShuffleUserInTeamA = false.obs;
  final preShuffleUserInTeamB = false.obs;
  var matchBookingId = ''.obs;
  final shouldShakeAvatars = false.obs;
  final isShowingShuffleResultDialog = false.obs;
  final xpEarned = 0.obs;
  final xpLost = 0.obs;
  final currentXP = 0.obs;
  RxList<Map<String, dynamic>> swapHistory = <Map<String, dynamic>>[].obs;

  Future<void> fetchScoreBoard({bool showLoader = true}) async {
    if (showLoader) {
      isLoading.value = true;
    }

    try {
      final response = await repository.getScoreBoard(bookingId: bookingId.value);

      if (response.status == 200 && response.data!.isNotEmpty) {
        final item = response.data!.first;
        scoreboardId.value = item.sId ?? "";
        openMatchId.value = item.bookingId?.openMatchId ?? "";
        matchBookingId.value = item.bookingId?.sId ?? "";
        registerClubId.value = item.bookingId?.registerClubId ?? "";
        bookingType.value = item.bookingId?.bookingType ?? "regular";
        CustomLogger.logMessage(
            msg: "Booking Type from API: ${item.bookingId?.bookingType}", level: LogLevel.info);
        CustomLogger.logMessage(
            msg: "Booking Type set to: ${bookingType.value}", level: LogLevel.info);
        matchType.value = (item.matchType ?? "Friendly").capitalizeFirst ?? "Friendly";
        matchStatus.value = item.matchStatus ?? false;
        CustomLogger.logMessage(
            msg: "Using scoreboard ID: ${item.sId}", level: LogLevel.info);
        CustomLogger.logMessage(
            msg: "Open Match ID from API: ${item.bookingId?.openMatchId}", level: LogLevel.info);
        CustomLogger.logMessage(
            msg: "Teams count in response: ${item.teams?.length ?? 0}",
            level: LogLevel.info);
        matchDate.value = item.matchDate ?? "";
        matchTime.value = item.matchTime ?? "";
        startTime.value = item.startTime ?? "";
        endTime.value = item.endTime ?? "";
        clubName.value = item.clubName ?? "";
        courtName.value = item.courtName ?? "";

        teams.clear();
        final teamAPlayers = <Map<String, dynamic>>[];
        final teamBPlayers = <Map<String, dynamic>>[];

        if (item.teams != null && item.teams!.isNotEmpty) {
          for (var t in item.teams!) {
            final playersList = <Map<String, dynamic>>[];
            if (t.players != null) {
              for (var p in t.players!) {
                String fullLevel = p.playerId?.level ?? p.playerId?.playerLevel ?? "";
                String levelCode = fullLevel.contains(' – ') ? fullLevel.split(' – ')[0] : fullLevel;
                playersList.add({
                  "playerId": p.playerId?.sId ?? "",
                  "name": p.playerId?.name ?? "Unknown",
                  "lastName": p.playerId?.lastName ?? "",
                  "pic": p.playerId?.profilePic ?? "",
                  "level": levelCode,
                });
              }
            }
            // Check team name - case insensitive and handle both "Team A"/"teamA" formats
            final teamNameLower = (t.name ?? '').toLowerCase().replaceAll(' ', '');
            if (teamNameLower == 'teama') {
              teamAPlayers.addAll(playersList);
            } else if (teamNameLower == 'teamb') {
              teamBPlayers.addAll(playersList);
            }
          }
        }

        teams.add({"name": "Team A", "players": teamAPlayers});
        teams.add({"name": "Team B", "players": teamBPlayers});

        sets.clear();

        if (item.sets != null && item.sets!.isNotEmpty) {
          for (var s in item.sets!) {
            int setNum = s.setNumber ?? 0;

            sets.add({
              "uniqueId": _uuid.v4(),
              "setNumber": setNum,
              "teamAScore": s.teamAScore ?? 0,
              "teamBScore": s.teamBScore ?? 0,
              "winner": s.winner,
            });
          }
        }

        sets.refresh();

        teamAWins.value = item.totalScore?.teamA ?? 0;
        teamBWins.value = item.totalScore?.teamB ?? 0;
        winner.value = item.winner?.toString() ?? "";
        isCompleted.value = item.isCompleted ?? false;
        
        // Parse swap history
        swapHistory.clear();
        if (item.swapHistory != null && item.swapHistory!.isNotEmpty) {
          for (var swap in item.swapHistory!) {
            final swapData = <String, dynamic>{
              'swappedAt': swap.swappedAt ?? '',
              'winner': swap.winner ?? '',
              'totalScore': {
                'teamA': swap.totalScore?.teamA ?? 0,
                'teamB': swap.totalScore?.teamB ?? 0,
              },
              'teams': [],
              'sets': [],
            };
            
            // Parse teams
            if (swap.teams != null) {
              for (var team in swap.teams!) {
                final teamData = <String, dynamic>{
                  'name': team.name ?? '',
                  'players': [],
                };
                
                if (team.players != null) {
                  for (var player in team.players!) {
                    teamData['players'].add({
                      'playerId': player.playerId?.sId ?? '',
                      'name': player.playerId?.name ?? 'Unknown',
                      'pic': player.playerId?.profilePic ?? '',
                    });
                  }
                }
                
                swapData['teams'].add(teamData);
              }
            }
            
            // Parse sets
            if (swap.sets != null) {
              for (var set in swap.sets!) {
                swapData['sets'].add({
                  'setNumber': set.setNumber ?? 0,
                  'teamAScore': set.teamAScore ?? 0,
                  'teamBScore': set.teamBScore ?? 0,
                  'winner': set.winner ?? '',
                });
              }
            }
            
            swapHistory.add(swapData);
          }
        }
        
        // Set game started status based on existing sets
        isGameStarted.value = sets.isNotEmpty;
        
        // Start timer if game is started and within match time
        if (isGameStarted.value && _isWithinMatchTimeWindow()) {
          remainingSeconds.value = calculateRemainingMatchTime();
          _startGameTimer();
        }

        CustomLogger.logMessage(msg: "=== FINAL TEAMS ===", level: LogLevel.info);
        for (int i = 0; i < teams.length; i++) {
          final team = teams[i];
          final players = team['players'] as List;
          CustomLogger.logMessage(
              msg: "Team ${i + 1}: ${team['name']}, ${players.length} player(s)",
              level: LogLevel.info);
        }

        teams.refresh();
      }
    } catch (e, stackTrace) {
      CustomLogger.logMessage(msg: "ERROR-> $e", level: LogLevel.error);
      CustomLogger.logMessage(
          msg: "Stack: $stackTrace", level: LogLevel.error);
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }
  ///Start Game - Initializes first set and starts timer-----------------------------------
  Future<void> startGame() async {
    if (isCompleted.value) {
      AppToast.error("Cannot start game. Match is already completed.");
      return;
    }

    if (!allPlayersAdded) {
      AppToast.error("Please add all 4 players first");
      return;
    }

    if (!isWithinMatchTime.value) {
      AppToast.error("Game can only start during match time");
      return;
    }

    if (isGameStarted.value) {
      // Game already started, just add a new set
      await addSet();
      return;
    }

    // Start the game for the first time
    isGameStarted.value = true;
    
    // Stop the countdown timer but keep the current remaining time
    // Don't reset remainingSeconds - continue with the same countdown
    _stopCountdownTimer();
    
    // If remainingSeconds is 0 or not set, calculate it from current time to end time
    // Otherwise, keep the current remaining time that was already counting down
    if (remainingSeconds.value <= 0) {
      remainingSeconds.value = calculateRemainingMatchTime();
    }
    
    // Start the game timer which will continue counting down from current remaining time
    _startGameTimer();

    // Add the first set
    await createSets(_nextAvailableSetNumber());
  }

  void _startGameTimer() {
    try {
      _gameTimer.cancel();
    } catch (e) {}
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        remainingSeconds.value = 0;
        timer.cancel();
        isGameStarted.value = false;
        AppToast.error("Match time is up! Game ended automatically.");
      }
    });
  }

  Future<void> createSets(int setNumber, {String? type}) async {
    CustomLogger.logMessage(msg: 'createSets API call - setNumber: $setNumber', level: LogLevel.info);
    isAddingSet.value = true;
    try {
      final body = {
        "scoreboardId": scoreboardId.value,
        "sets": [
          {"setNumber": setNumber}
        ]
      };
      final response = await repository.updateScoreBoard(data: body);

      if (response.success == true) {
        sets.add({
          "uniqueId": _uuid.v4(),
          "setNumber": setNumber,
          "teamAScore": 0,
          "teamBScore": 0,
          "winner": null,
        });

        sets.refresh();

        CustomLogger.logMessage(msg: "Set $setNumber added successfully", level: LogLevel.debug);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR-> $e", level: LogLevel.error);
    } finally {
      isAddingSet.value = false;
    }
  }

  ///Add Set--------------------------------------------------------------------
  Future<void> addSet() async {
    if (isCompleted.value) {
      AppToast.error("Cannot add set. Match is already completed.");
      return;
    }
    
    if (sets.length < 10) {
      await createSets(_nextAvailableSetNumber());
    } else {
      AppToast.error("Limit Reached\nYou can add up to 10 sets only");
    }
  }

  int _nextAvailableSetNumber() {
    final existingNumbers = sets
        .map((s) => s["setNumber"])
        .whereType<int>()
        .toSet();

    int candidate = 1;
    while (existingNumbers.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  @override
  void onInit() async {
    super.onInit();
    bookingId.value = Get.arguments["bookingId"];
    openMatchId.value = Get.arguments["openMatchId"] ?? "";
    CustomLogger.logMessage(msg: "BOOKING ID-> ${bookingId.value}", level: LogLevel.info);
    CustomLogger.logMessage(msg: "OPEN MATCH ID-> ${openMatchId.value}", level: LogLevel.info);

    _scoreboardStreamController = StreamController<Map<String, dynamic>>.broadcast();
    await fetchScoreBoard();
    
    // Connect socket and join scoreboard
    print('🔵 SCOREBOARD ID: ${scoreboardId.value}');
    if (scoreboardId.value.isNotEmpty) {
      repository.joinScoreboard(scoreboardId.value);
      repository.onScoreboardUpdate((data) {
        print('🔔 Scoreboard update received in controller: $data');
        
        // Check if this update is due to a swap during match
        // We'll detect this by checking if teams changed while match was active
        final wasMatchActive = isGameStarted.value || sets.isNotEmpty;
        
        fetchScoreBoard(showLoader: false).then((_) {
          // After fetching, check if teams were swapped during active match
          if (wasMatchActive && !isGameStarted.value && sets.isEmpty && !isCompleted.value) {
            // This indicates a swap happened and match was reset by another player
            print('🔄 Detected swap during match from scoreboardUpdate');
            wasSwapDuringMatch.value = true;
            isCompleted.value = true;
            
            // Show match summary dialog
            Future.delayed(const Duration(milliseconds: 500), () {
              tryShowMatchSummaryDialog();
            });
          }
        });
      });
      repository.onScoreboardSwapped((data) {
        print('🔄 ========== SCOREBOARD SWAPPED EVENT RECEIVED ==========');
        print('🔄 Full data: $data');
        print('🔄 Data type: ${data.runtimeType}');
        
        // Log complete data structure
        CustomLogger.logMessage(
          msg: '🔄 COMPLETE SOCKET DATA: ${data.toString()}',
          level: LogLevel.info,
        );
        
        if (data != null) {
          print('🔄 Data is not null');
          
          if (data is Map) {
            print('🔄 Data is a Map');
            print('🔄 Available keys: ${data.keys.toList()}');
            
            // Log each key-value pair
            data.forEach((key, value) {
              CustomLogger.logMessage(
                msg: '🔍 KEY: "$key" => VALUE: $value (${value.runtimeType})',
                level: LogLevel.info,
              );
            });
            
            // Check for swapXpChanges array
            if (data.containsKey('swapXpChanges')) {
              final swapXpChanges = data['swapXpChanges'];
              CustomLogger.logMessage(
                msg: '💰 SWAP XP CHANGES FOUND: $swapXpChanges',
                level: LogLevel.info,
              );
              
              if (swapXpChanges is List) {
                CustomLogger.logMessage(
                  msg: '💰 swapXpChanges is a List with ${swapXpChanges.length} items',
                  level: LogLevel.info,
                );
                
                for (int i = 0; i < swapXpChanges.length; i++) {
                  final change = swapXpChanges[i];
                  CustomLogger.logMessage(
                    msg: '💰 Player $i: $change',
                    level: LogLevel.info,
                  );
                }
              }
            } else {
              CustomLogger.logMessage(
                msg: '⚠️ swapXpChanges NOT FOUND in socket data',
                level: LogLevel.warning,
              );
            }
            
            // Check for playerXpChanges array (alternative key name)
            if (data.containsKey('playerXpChanges')) {
              final playerXpChanges = data['playerXpChanges'];
              CustomLogger.logMessage(
                msg: '💰 PLAYER XP CHANGES FOUND: $playerXpChanges',
                level: LogLevel.info,
              );
            }
            
            final isSwappingDuringMatch = data['isSwappingDuringMatch'];
            print('🔄 isSwappingDuringMatch value: $isSwappingDuringMatch');
            print('🔄 isSwappingDuringMatch type: ${isSwappingDuringMatch.runtimeType}');
            
            // CRITICAL: Only show dialog if match was actually started (has sets)
            if (isSwappingDuringMatch == true && sets.isNotEmpty) {
              print('🎯 ========== SWAP DURING MATCH DETECTED ==========');
              
              // Extract pre-shuffle data
              final preShuffleWinner = data['preShuffleWinner']?.toString() ?? '';
              final preShuffleTeamAWins = data['preShuffleTeamAWins'] ?? 0;
              final preShuffleTeamBWins = data['preShuffleTeamBWins'] ?? 0;
              
              print('📊 Pre-shuffle data:');
              print('   Winner: $preShuffleWinner');
              print('   Team A Wins: $preShuffleTeamAWins');
              print('   Team B Wins: $preShuffleTeamBWins');
              
              // Set flag to indicate this completion is due to swap
              wasSwapDuringMatch.value = true;
              
              // Mark match as completed to trigger match summary
              isCompleted.value = true;
              
              // Get XP values from socket data if available
              int socketXpEarned = 0;
              int socketXpLost = 0;
              
              socketXpEarned = (data['xpEarned'] ?? data['currentXP'] ?? data['xpChange'] ?? 0) as int;
              socketXpLost = (data['xpLost'] ?? 0) as int;
              
              if (socketXpEarned > 0) {
                xpEarned.value = socketXpEarned;
              }
              if (socketXpLost > 0) {
                xpLost.value = socketXpLost;
              }
              
              print('📊 XP values - Earned: $socketXpEarned, Lost: $socketXpLost');
              print('🔔 Scheduling match summary dialog to show in 500ms...');
              
              // Fetch scoreboard and show match summary dialog
              fetchScoreBoard(showLoader: false).then((_) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  print('🔔 Showing match summary dialog with previous match result');
                  tryShowMatchSummaryDialog();
                });
              });
            } else {
              print('⚠️ isSwappingDuringMatch is FALSE or null - normal swap, no popup');
              fetchScoreBoard(showLoader: false);
            }
          } else {
            print('❌ Data is NOT a Map - type: ${data.runtimeType}');
            fetchScoreBoard(showLoader: false);
          }
        } else {
          print('❌ Data is NULL');
          fetchScoreBoard(showLoader: false);
        }
        
        print('🔄 ========== END SCOREBOARD SWAPPED EVENT ==========');
      });
      repository.onTeamShuffleResult((data) {
        print('🏆 Team shuffle result received: $data');
        // Show the shuffle result dialog to all players
        _handleTeamShuffleResultFromSocket(data);
      });

      repository.onMatchCompleted((data) {
        print('🏆 ========== MATCH COMPLETED EVENT RECEIVED ==========');
        print('🏆 Full data: $data');
        print('🏆 Data type: ${data.runtimeType}');
        
        // Check if this is a swap during match scenario
        bool isSwapDuringMatch = false;
        if (data != null && data is Map) {
          isSwapDuringMatch = data['isSwapDuringMatch'] == true;
          print('🔄 isSwapDuringMatch: $isSwapDuringMatch');
          
          // Log all keys in data
          print('🔍 Available keys: ${data.keys.toList()}');
          
          // Extract pre-shuffle data from socket if swap during match
          if (isSwapDuringMatch) {
            // CRITICAL: Store team membership FIRST before any fetchScoreBoard call
            // because fetchScoreBoard will update teams and change isUserInTeamA/B
            print('🔴 BEFORE STORING - isUserInTeamA: $isUserInTeamA, isUserInTeamB: $isUserInTeamB');
            preShuffleUserInTeamA.value = isUserInTeamA;
            preShuffleUserInTeamB.value = isUserInTeamB;
            print('🟢 AFTER STORING - preShuffleUserInTeamA: ${preShuffleUserInTeamA.value}, preShuffleUserInTeamB: ${preShuffleUserInTeamB.value}');
            
            final socketPreShuffleWinner = data['preShuffleWinner']?.toString() ?? data['winner']?.toString() ?? data['swapWinner']?.toString() ?? '';
            final socketPreShuffleTeamAWins = data['preShuffleTeamAWins'] ?? data['teamAWins'] ?? data['totalScore']?['teamA'] ?? 0;
            final socketPreShuffleTeamBWins = data['preShuffleTeamBWins'] ?? data['teamBWins'] ?? data['totalScore']?['teamB'] ?? 0;
            
            // Update pre-shuffle values from socket
            if (socketPreShuffleWinner.isNotEmpty) {
              preShuffleWinner.value = socketPreShuffleWinner;
            }
            preShuffleTeamAWins.value = socketPreShuffleTeamAWins;
            preShuffleTeamBWins.value = socketPreShuffleTeamBWins;
            
            print('📊 PRE-SHUFFLE DATA FROM SOCKET:');
            print('   Winner: ${preShuffleWinner.value}');
            print('   Team A Wins: ${preShuffleTeamAWins.value}');
            print('   Team B Wins: ${preShuffleTeamBWins.value}');
            print('   User in Team A (before swap): ${preShuffleUserInTeamA.value}');
            print('   User in Team B (before swap): ${preShuffleUserInTeamB.value}');
            
            // Check for xpChanges array
            if (data.containsKey('xpChanges') && data['xpChanges'] is List) {
              final xpChanges = data['xpChanges'] as List;
              print('💰 XP CHANGES ARRAY FOUND with ${xpChanges.length} items');
              
              // Find current user's XP change
              final currentUserId = profileController.profileModel.value?.response?.sId ?? '';
              print('👤 Current User ID: $currentUserId');
              
              bool foundUser = false;
              for (var change in xpChanges) {
                final playerId = change['playerId']?.toString() ?? '';
                final xpChange = (change['xpChange'] ?? 0).toDouble();
                final result = change['result']?.toString() ?? '';
                
                print('💰 Player: $playerId, XP: $xpChange, Result: $result');
                
                if (playerId == currentUserId) {
                  foundUser = true;
                  print('✅ FOUND CURRENT USER XP!');
                  if (result == 'W') {
                    xpEarned.value = xpChange.abs().toInt();
                    print('✅ Set xpEarned to: ${xpEarned.value}');
                  } else if (result == 'L') {
                    xpLost.value = xpChange.abs().toInt();
                    print('✅ Set xpLost to: ${xpLost.value}');
                  }
                  break;
                }
              }
              
              if (!foundUser) {
                print('⚠️ CURRENT USER NOT FOUND IN XP CHANGES!');
              }
            } else {
              print('⚠️ xpChanges array NOT FOUND in socket data');
              print('⚠️ Available keys: ${data.keys.toList()}');
            }
          }
        } else {
          print('⚠️ Data is null or not a Map');
        }
        
        print('🔄 Setting isCompleted to true');
        isCompleted.value = true;
        
        // If swap during match, set the flag
        if (isSwapDuringMatch) {
          wasSwapDuringMatch.value = true;
          print('🔄 Setting wasSwapDuringMatch flag to true');
        }
        
        print('📥 Fetching scoreboard...');
        
        // DON'T fetch scoreboard before showing dialog - it will reset teams
        // Show dialog immediately
        if (isSwapDuringMatch) {
          print('⚡ SWAP DURING MATCH - Showing dialog immediately WITHOUT fetchScoreBoard');
          Future.delayed(const Duration(milliseconds: 300), () {
            print('🔔 Calling tryShowMatchSummaryDialog...');
            tryShowMatchSummaryDialog();
          });
        } else {
          // Normal match completion - fetch then show
          fetchScoreBoard(showLoader: false).then((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              print('🔔 Calling tryShowMatchSummaryDialog...');
              tryShowMatchSummaryDialog();
            });
          });
        }
        
        print('🏆 ========== MATCH COMPLETED EVENT HANDLER COMPLETED ==========');
      });

      repository.onSwapPlayer((data) {
        print('🔄 ========== SWAP PLAYER EVENT RECEIVED ==========');
        print('🔄 Full data: $data');
        print('🔄 Data type: ${data.runtimeType}');
        
        if (data != null && data is Map) {
          // CRITICAL: Only process if match was actually started (has sets)
          if (sets.isEmpty) {
            print('⚠️ Match not started yet (no sets), ignoring swap player event');
            fetchScoreBoard(showLoader: false);
            return;
          }
          
          print('🎯 ========== SWAP DURING MATCH DETECTED ==========');
          
          preShuffleUserInTeamA.value = isUserInTeamA;
          preShuffleUserInTeamB.value = isUserInTeamB;
          print('🟢 Stored team membership - TeamA: ${preShuffleUserInTeamA.value}, TeamB: ${preShuffleUserInTeamB.value}');
          
          final winnerValue = data['swapWinner']?.toString() ?? '';
          final totalScore = data['totalScore'];
          final teamAWinsValue = totalScore?['teamA'] ?? 0;
          final teamBWinsValue = totalScore?['teamB'] ?? 0;
          
          if (winnerValue.isNotEmpty) {
            preShuffleWinner.value = winnerValue;
          }
          preShuffleTeamAWins.value = teamAWinsValue;
          preShuffleTeamBWins.value = teamBWinsValue;
          
          print('📊 Winner: ${preShuffleWinner.value}, TeamA: ${preShuffleTeamAWins.value}, TeamB: ${preShuffleTeamBWins.value}');
          
          final currentUserId = profileController.profileModel.value?.response?.sId ?? '';
          print('👤 Current User ID: $currentUserId');
          
          bool foundUser = false;
          data.forEach((key, value) {
            if (value is List) {
              print('💰 Found array with ${value.length} items');
              for (var change in value) {
                if (change is Map) {
                  var playerId = change['playerId'];
                  String playerIdStr = '';
                  
                  if (playerId != null) {
                    playerIdStr = playerId.toString().replaceAll('ObjectId("', '').replaceAll('")', '').replaceAll("'", '');
                  }
                  
                  final xpChange = (change['xpChange'] ?? 0).toDouble();
                  final result = change['result']?.toString() ?? '';
                  final name = change['name']?.toString() ?? '';
                  final currentXPValue = (change['currentXP'] ?? 0).toDouble();
                  
                  print('💰 $name ($playerIdStr): XP=$xpChange, Result=$result, CurrentXP=$currentXPValue');
                  
                  if (playerIdStr == currentUserId) {
                    foundUser = true;
                    print('✅ FOUND CURRENT USER!');
                    currentXP.value = currentXPValue.toInt();
                    print('✅ currentXP = ${currentXP.value}');
                    if (result == 'W') {
                      xpEarned.value = xpChange.abs().toInt();
                      print('✅ xpEarned = ${xpEarned.value}');
                    } else if (result == 'L') {
                      xpLost.value = xpChange.abs().toInt();
                      print('✅ xpLost = ${xpLost.value}');
                    }
                  }
                }
              }
            }
          });
          
          if (!foundUser) {
            print('⚠️ USER NOT FOUND IN XP CHANGES!');
          }
          
          wasSwapDuringMatch.value = true;
          isCompleted.value = true;
          
          print('⚡ Showing dialog in 300ms');
          Future.delayed(const Duration(milliseconds: 300), () {
            print('🔔 Calling tryShowMatchSummaryDialog');
            tryShowMatchSummaryDialog();
          });
        } else {
          print('❌ Data is null or not a Map');
        }
        
        print('🔄 ========== HANDLER COMPLETED ==========');
      });
    } else {
      print('⚠️ Scoreboard ID is empty, cannot join socket');
    }
    
    _startPeriodicUpdates();
    _startMatchTimeCheck();
    
    // Force immediate check
    isWithinMatchTime.value = _isWithinMatchTimeWindow();
    CustomLogger.logMessage(
      msg: "Initial match time check: ${isWithinMatchTime.value}, matchTime: ${matchTime.value}",
      level: LogLevel.info
    );
    if (isWithinMatchTime.value) {
      remainingSeconds.value = calculateRemainingMatchTime();
      _startCountdownTimer();
    } else {
      remainingSeconds.value = 0;
    }
  }

  void _startMatchTimeCheck() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      bool previousValue = isWithinMatchTime.value;
      isWithinMatchTime.value = _isWithinMatchTimeWindow();
      
      if (previousValue != isWithinMatchTime.value) {
        CustomLogger.logMessage(
          msg: "Match time status changed: $previousValue -> ${isWithinMatchTime.value}",
          level: LogLevel.info
        );
        
        if (isWithinMatchTime.value && !isCountdownActive.value && !isGameStarted.value) {
          _startCountdownTimer();
        } else if (!isWithinMatchTime.value && isCountdownActive.value) {
          _stopCountdownTimer();
          remainingSeconds.value = 0;
        }
      }

      // Only update timer if game hasn't started yet
      if (!isGameStarted.value && isWithinMatchTime.value) {
        remainingSeconds.value = calculateRemainingMatchTime();
      }
    });
  }

  ///Calculate time until match starts in seconds----------------------------------------------
  int _calculateTimeUntilMatchStart() {
    try {
      if (matchTime.value.isEmpty) return 0;

      // Parse match time (e.g., "7:00 PM - 8:00 PM" or "11 am - 12 pm")
      String timeStr = matchTime.value.trim();
      List<String> parts = timeStr.split('-');

      if (parts.length < 1) return 0;

      // Get start time (first part)
      String startTimeStr = parts[0].trim();

      // Normalize time format: "11 am" -> "11:00 AM"
      startTimeStr = _normalizeTimeFormat(startTimeStr);

      // Parse start time
      DateTime startTime = DateFormat('h:mm a').parse(startTimeStr);
      DateTime now = DateTime.now();
      DateTime startDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      // If start time is in the past, use tomorrow
      if (startDateTime.isBefore(now)) {
        startDateTime = startDateTime.add(const Duration(days: 1));
      }

      int timeUntilSeconds = startDateTime.difference(now).inSeconds;
      return timeUntilSeconds > 0 ? timeUntilSeconds : 0;
    } catch (e) {
      CustomLogger.logMessage(msg: "Error calculating time until match: $e", level: LogLevel.error);
      return 0;
    }
  }

  ///Normalize time format to "h:mm a" format----------------------------------------------
  String _normalizeTimeFormat(String time) {
    time = time.trim();
    // Convert "11 am" to "11:00 AM"
    if (!time.contains(':')) {
      final parts = time.split(' ');
      if (parts.length == 2) {
        time = '${parts[0]}:00 ${parts[1].toUpperCase()}';
      }
    } else {
      // Ensure AM/PM is uppercase
      time = time.replaceAllMapped(RegExp(r'(am|pm)', caseSensitive: false), (match) => match.group(0)!.toUpperCase());
    }
    return time;
  }

  void _startPeriodicUpdates() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _fetchScoreBoardForStream();
    });
  }

  Future<void> _fetchScoreBoardForStream() async {
    try {
      if (_scoreboardStreamController.isClosed) return;

      final response = await repository.getScoreBoard(bookingId: bookingId.value);
      if (response.status == 200 && response.data!.isNotEmpty) {
        final item = response.data!.first;

        // Update match type and status
        matchType.value = (item.matchType ?? "Friendly").capitalizeFirst ?? "Friendly";
        matchStatus.value = item.matchStatus ?? false;

        // Update teams
        final teamAPlayers = <Map<String, dynamic>>[];
        final teamBPlayers = <Map<String, dynamic>>[];

        if (item.teams != null && item.teams!.isNotEmpty) {
          for (var t in item.teams!) {
            final playersList = <Map<String, dynamic>>[];
            if (t.players != null) {
              for (var p in t.players!) {
                String fullLevel = p.playerId?.level ?? p.playerId?.playerLevel ?? "";
                String levelCode = fullLevel.contains(' – ') ? fullLevel.split(' – ')[0] : fullLevel;
                playersList.add({
                  "playerId": p.playerId?.sId ?? "",
                  "name": p.playerId?.name ?? "Unknown",
                  "lastName": p.playerId?.lastName ?? "",
                  "pic": p.playerId?.profilePic ?? "",
                  "level": levelCode,
                });
              }
            }
            final teamNameLower = (t.name ?? '').toLowerCase().replaceAll(' ', '');
            if (teamNameLower == 'teama') {
              teamAPlayers.addAll(playersList);
            } else if (teamNameLower == 'teamb') {
              teamBPlayers.addAll(playersList);
            }
          }
        }

        teams.clear();
        teams.add({"name": "Team A", "players": teamAPlayers});
        teams.add({"name": "Team B", "players": teamBPlayers});
        teams.refresh();

        // Only update sets if API has data, don't clear existing sets
        if (item.sets != null && item.sets!.isNotEmpty) {
          sets.clear();
          for (var s in item.sets!) {
            sets.add({
              "uniqueId": _uuid.v4(),
              "setNumber": s.setNumber ?? 0,
              "teamAScore": s.teamAScore ?? 0,
              "teamBScore": s.teamBScore ?? 0,
              "winner": s.winner,
            });
          }
          sets.refresh();
        }

        // Update scores
        teamAWins.value = item.totalScore?.teamA ?? 0;
        teamBWins.value = item.totalScore?.teamB ?? 0;
        winner.value = item.winner?.toString() ?? "";
        
        // Update isCompleted from API response
        final apiCompleted = item.isCompleted ?? false;
        if (apiCompleted && !isCompleted.value) {
          isCompleted.value = true;
        }

        if (!_scoreboardStreamController.isClosed) {
          _scoreboardStreamController.add({'updated': true});
        }
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Stream fetch error: $e", level: LogLevel.error);
    }
  }

  void _startCountdownTimer() {
    if (isCountdownActive.value) return;
    
    isCountdownActive.value = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameStarted.value) {
        int remaining = calculateRemainingMatchTime();
        remainingSeconds.value = remaining;
        
        if (remaining <= 0) {
          remainingSeconds.value = 0;
          _stopCountdownTimer();
        }
      } else {
        _stopCountdownTimer();
      }
    });
  }

  void _stopCountdownTimer() {
    if (isCountdownActive.value) {
      try {
        _countdownTimer.cancel();
      } catch (e) {}
      isCountdownActive.value = false;
    }
  }

  @override
  void onClose() {
    if (isGameStarted.value) {
      _gameTimer.cancel();
    }
    _stopCountdownTimer();
    _periodicTimer.cancel();
    if (!_scoreboardStreamController.isClosed) {
      _scoreboardStreamController.close();
    }
    // Disconnect socket when leaving screen
    // repository.leaveScoreboard(scoreboardId.value);
    super.onClose();
  }

  ///Add Score------------------------------------------------------------------
  Future<void> addScore(int setNumber, int teamAScore, int teamBScore) async {
    // Prevent score addition if game hasn't started
    if (!isGameStarted.value) {
      AppToast.error("Cannot add score. Please start the match first.");
      return;
    }
    
    // Validate scores don't exceed 20
    if (teamAScore > 20 || teamBScore > 20) {
      AppToast.error("Score cannot exceed 20");
      return;
    }
    
    CustomLogger.logMessage(msg: 'addScore API call - set: $setNumber, scores: $teamAScore-$teamBScore', level: LogLevel.info);
    if (teamAScore == 0 && teamBScore == 0) {
      AppToast.error("Both team scores cannot be zero.");
      return;
    }
    isAddingScore.value = true;
    try {
      final Map<String, dynamic> setData = {
        "setNumber": setNumber,
      };

      // Only send score for the team that is updating
      if (teamAScore > 0) {
        setData["teamAScore"] = teamAScore;
      }
      if (teamBScore > 0) {
        setData["teamBScore"] = teamBScore;
      }

      final body = {
        "scoreboardId": scoreboardId.value,
        "sets": [setData]
      };

      print('🎯 Updating score: $body');
      final response = await repository.updateScoreBoard(data: body);
      if (response.success == true) {
        CustomLogger.logMessage(msg: "Score Added Successfully", level: LogLevel.info);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error-> $e", level: LogLevel.error);
    } finally {
      isAddingScore.value = false;
    }
  }

  ///End Game------------------------------------------------------------------
  var isEndGame = false.obs;
  var matchType = "Friendly".obs;
  var matchStatus = false.obs;
  ProfileController profileController = Get.put(ProfileController());

  ///Update Match Type----------------------------------------------------------
  Future<void> updateMatchType(String newMatchType) async {
    try {
      final body = {
        "bookingId": matchBookingId.value,
        "matchType": newMatchType.toLowerCase()
      };

      final response = await repository.updateBooking(body: body);

      if (response?.success == true) {
        matchType.value = newMatchType;
        matchStatus.value = true;
        AppToast.success("Match type updated to $newMatchType");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR updating match type-> $e", level: LogLevel.error);
    }
  }

  // Add flag to prevent multiple dialog calls
  RxBool isShowingMatchSummary = false.obs;

  DateTime? _lastMatchSummaryDialogRequestAt;

  void tryShowMatchSummaryDialog() {
    print('🔔 ========== tryShowMatchSummaryDialog CALLED ==========');
    print('🔔 isShowingMatchSummary: ${isShowingMatchSummary.value}');
    print('🔔 isCompleted: ${isCompleted.value}');
    print('🔔 wasSwapDuringMatch: ${wasSwapDuringMatch.value}');
    
    final now = DateTime.now();
    final last = _lastMatchSummaryDialogRequestAt;
    if (last != null && now.difference(last).inMilliseconds < 1500) {
      print('⚠️ Dialog request too soon, skipping (${now.difference(last).inMilliseconds}ms)');
      return;
    }
    _lastMatchSummaryDialogRequestAt = now;

    if (isShowingMatchSummary.value) {
      print('⚠️ Dialog already showing, skipping');
      return;
    }
    
    print('✅ Showing match summary dialog...');
    isShowingMatchSummary.value = true;
    showMatchSummaryDialog(this);
    print('🔔 ========== tryShowMatchSummaryDialog COMPLETED ==========');
  }

  Future<void> endGame() async {
    CustomLogger.logMessage(msg: 'endGame API call', level: LogLevel.info);
    // Check if any set is empty (no scores)
    bool hasEmptySet = sets.any((set) {
      final teamAScore = set["teamAScore"] ?? 0;
      final teamBScore = set["teamBScore"] ?? 0;
      return teamAScore == 0 && teamBScore == 0;
    });

    if (hasEmptySet) {
      AppToast.error("Cannot end game with empty sets. Please add scores first.");
      return;
    }

    isEndGame.value = true;
    if (isGameStarted.value) {
      _gameTimer.cancel();
      isGameStarted.value = false;
    }
    try {
      final body = {
        "scoreboardId": scoreboardId.value,
        "type": "completed"
      };

      final response = await repository.updateScoreBoard(data: body);

      if (response.success == true) {
        isCompleted.value = true;
        
        // Capture XP values from API response
        if (response.data != null) {
          xpEarned.value = response.data!.xpEarned ?? 0;
          xpLost.value = response.data!.xpLost ?? 0;
          CustomLogger.logMessage(
            msg: 'XP values from API - Earned: ${xpEarned.value}, Lost: ${xpLost.value}',
            level: LogLevel.info,
          );
        }
        
        await profileController.fetchUserProfile();
        await fetchScoreBoard(showLoader: false);
        
        // Show dialog with delay to ensure proper state
        Future.delayed(const Duration(milliseconds: 300), () {
          tryShowMatchSummaryDialog();
        });
      } else {
        CustomLogger.logMessage(msg: response.message ?? "", level: LogLevel.debug);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR-> $e", level: LogLevel.error);
    } finally {
      isEndGame.value = false;
    }
  }

  ///Check if swapping is allowed----------------------------------------------
  bool get canSwapPlayers => !isCompleted.value && currentPlayerIds.isNotEmpty;

  ///Check user's team and scoring permissions----------------------------------
  String get currentUserId => profileController.profileModel.value?.response?.sId ?? '';

  bool get isUserInTeamA {
    if (teams.isEmpty) return false;
    final teamAPlayers = teams[0]['players'] as List;
    return teamAPlayers.any((player) => player['playerId'] == currentUserId);
  }

  bool get isUserInTeamB {
    if (teams.length < 2) return false;
    final teamBPlayers = teams[1]['players'] as List;
    return teamBPlayers.any((player) => player['playerId'] == currentUserId);
  }

  bool canScoreForTeam(String team) {
    if (team == 'Team A') return isUserInTeamA;
    if (team == 'Team B') return isUserInTeamB;
    return false;
  }

  ///Remove Player from Team-------------------------------------------------
  var isRemovingPlayer = false.obs;
  
  /// Convert team name from "Team A"/"Team B" to "teamA"/"teamB" format
  String normalizeTeamName(String teamName) {
    if (teamName.trim().toLowerCase() == 'team a') {
      return 'teamA';
    } else if (teamName.trim().toLowerCase() == 'team b') {
      return 'teamB';
    }
    // If already in correct format, return as is
    return teamName;
  }
  
  Future<void> removePlayer(String playerId, String teamName) async {
    CustomLogger.logMessage(msg: 'removePlayer called for $playerId from $teamName', level: LogLevel.info);
    
    isRemovingPlayer.value = true;
    
    // Stop periodic updates temporarily
    _periodicTimer.cancel();
    
    try {
      // Immediately update local UI first
      final normalizedTeamName = normalizeTeamName(teamName);
      final teamIndex = normalizedTeamName == 'teamA' ? 0 : 1;
      
      if (teamIndex < teams.length) {
        final teamPlayers = List<Map<String, dynamic>>.from(teams[teamIndex]['players'] as List);
        teamPlayers.removeWhere((player) => player['playerId'] == playerId);
        teams[teamIndex]['players'] = teamPlayers;
        teams.refresh();
        CustomLogger.logMessage(msg: 'Local UI updated immediately', level: LogLevel.info);
      }
      
      // Now make API call
      final body = {
        "matchId": matchBookingId.value,
        "playerId": playerId,
        "team": normalizedTeamName,
      };

      CustomLogger.logMessage(msg: 'Remove player request body: $body', level: LogLevel.info);
      final response = await repository.removePlayerFromMatch(body: body);

      if (response?.success == true) {
        CustomLogger.logMessage(msg: 'Player removed successfully from server', level: LogLevel.info);
      } else {
        CustomLogger.logMessage(msg: response?.message ?? "Failed to remove player", level: LogLevel.debug);

        // Revert local changes if API failed
        await fetchScoreBoard(showLoader: false);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Remove player error: $e', level: LogLevel.error);
      // Revert local changes on error
      await fetchScoreBoard(showLoader: false);
    } finally {
      isRemovingPlayer.value = false;
      // Restart periodic updates
      _startPeriodicUpdates();
    }
  }

  ///Swap Players---------------------------------------------------------------
  void swapPlayers(String draggedPlayerId, String targetTeam, int targetIndex) {
    HapticFeedback.mediumImpact();
    CustomLogger.logMessage(msg: '🔄 SWAP INITIATED - draggedPlayerId: $draggedPlayerId, targetTeam: $targetTeam, targetIndex: $targetIndex', level: LogLevel.info);
    
    try {
      // Safety checks
      if (teams.isEmpty || targetIndex < 0) {
        CustomLogger.logMessage(msg: '❌ SWAP FAILED - Invalid parameters: teams.isEmpty=${teams.isEmpty}, targetIndex=$targetIndex', level: LogLevel.error);
        return;
      }
      
      // Find dragged player and remove from current position
      Map<String, dynamic>? draggedPlayer;
      int draggedTeamIndex = -1;
      int draggedPlayerIndex = -1;
      String sourceTeam = '';

      for (int teamIndex = 0; teamIndex < teams.length; teamIndex++) {
        final teamPlayers = teams[teamIndex]['players'] as List;
        for (int playerIndex = 0; playerIndex < teamPlayers.length; playerIndex++) {
          if (teamPlayers[playerIndex]['playerId'] == draggedPlayerId) {
            draggedPlayer = Map<String, dynamic>.from(teamPlayers[playerIndex]);
            draggedTeamIndex = teamIndex;
            draggedPlayerIndex = playerIndex;
            sourceTeam = teams[teamIndex]['name'];
            CustomLogger.logMessage(msg: '👤 PLAYER FOUND - ${draggedPlayer['name']} from $sourceTeam at position $playerIndex', level: LogLevel.info);
            break;
          }
        }
        if (draggedPlayer != null) break;
      }

      if (draggedPlayer == null || draggedTeamIndex == -1 || draggedPlayerIndex == -1) {
        CustomLogger.logMessage(msg: '❌ SWAP FAILED - Dragged player not found or invalid indices!', level: LogLevel.error);
        return;
      }

      // Get target team index
      int targetTeamIndex = targetTeam == 'Team A' ? 0 : 1;
      if (targetTeamIndex >= teams.length) {
        CustomLogger.logMessage(msg: '❌ SWAP FAILED - Invalid target team index: $targetTeamIndex', level: LogLevel.error);
        return;
      }

      // Get target player if exists
      Map<String, dynamic>? targetPlayer;
      final targetTeamPlayers = teams[targetTeamIndex]['players'] as List;
      if (targetIndex >= 0 && targetIndex < targetTeamPlayers.length) {
        targetPlayer = Map<String, dynamic>.from(targetTeamPlayers[targetIndex]);
        CustomLogger.logMessage(msg: '🎯 TARGET FOUND - ${targetPlayer['name']} in $targetTeam at position $targetIndex', level: LogLevel.info);
      } else {
        CustomLogger.logMessage(msg: '🎯 TARGET EMPTY - Moving to empty slot in $targetTeam', level: LogLevel.info);
      }

      // Log before swap state
      CustomLogger.logMessage(msg: '📊 BEFORE SWAP:', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Team A: ${(teams[0]['players'] as List).map((p) => p['name']).join(', ')}', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Team B: ${(teams[1]['players'] as List).map((p) => p['name']).join(', ')}', level: LogLevel.info);

      // Perform the swap in local data
      final draggedTeamPlayers = teams[draggedTeamIndex]['players'] as List;

      // Additional safety check for array access
      if (draggedPlayerIndex >= draggedTeamPlayers.length) {
        CustomLogger.logMessage(msg: '❌ SWAP FAILED - Invalid dragged player index: $draggedPlayerIndex >= ${draggedTeamPlayers.length}', level: LogLevel.error);
        return;
      }

      if (targetPlayer != null) {
        // Swap players - only update local UI, don't send API call
        CustomLogger.logMessage(msg: '🔄 EXECUTING SWAP - ${draggedPlayer['name']} ↔ ${targetPlayer['name']}', level: LogLevel.info);
        draggedTeamPlayers[draggedPlayerIndex] = targetPlayer;
        targetTeamPlayers[targetIndex] = draggedPlayer;
      } else {
        // Move player to empty slot - only update local UI, don't send API call
        CustomLogger.logMessage(msg: '➡️ EXECUTING MOVE - ${draggedPlayer['name']} from $sourceTeam to $targetTeam', level: LogLevel.info);
        draggedTeamPlayers.removeAt(draggedPlayerIndex);
        if (targetIndex >= 0 && targetIndex < targetTeamPlayers.length) {
          targetTeamPlayers[targetIndex] = draggedPlayer;
        } else {
          targetTeamPlayers.add(draggedPlayer);
        }
      }

      // Log after swap state
      CustomLogger.logMessage(msg: '📊 AFTER SWAP:', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Team A: ${(teams[0]['players'] as List).map((p) => p['name']).join(', ')}', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Team B: ${(teams[1]['players'] as List).map((p) => p['name']).join(', ')}', level: LogLevel.info);

      hasPlayerSwaps.value = true;
      teams.refresh();
      CustomLogger.logMessage(msg: '✅ SWAP COMPLETED SUCCESSFULLY (Local only)', level: LogLevel.info);
      
    } catch (e) {
      CustomLogger.logMessage(msg: '💥 SWAP ERROR: $e', level: LogLevel.error);
    }
  }

  ///Send Swap Action API Call
  Future<void> _sendSwapAction(String player1Id, String player1Team, String player1NewTeam, String player2Id, String player2Team, String player2NewTeam) async {
    try {
      CustomLogger.logMessage(msg: '📡 PREPARING SWAP API CALL', level: LogLevel.info);
      
      // Build the teams array with current player positions after swap
      final updatedTeams = [];
      for (int i = 0; i < teams.length; i++) {
        final teamPlayers = teams[i]['players'] as List;
        final playerIds = teamPlayers.map((p) => {'playerId': p['playerId']}).toList();

        updatedTeams.add({
          'name': teams[i]['name'],
          'players': playerIds,
        });
        
        CustomLogger.logMessage(msg: '   ${teams[i]['name']}: ${teamPlayers.map((p) => p['name']).join(', ')}', level: LogLevel.info);
      }
      
      final body = {
        "scoreboardId": scoreboardId.value,
        "action": "swap",
        "teams": updatedTeams,
      };
      
      CustomLogger.logMessage(msg: '📤 SENDING SWAP API BODY:', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   ScoreboardId: ${scoreboardId.value}', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Action: swap', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Teams: $updatedTeams', level: LogLevel.info);
      
      // Call the updateScoreBoard API
      final response = await repository.updateScoreBoard(data: body);
      
      if (response.success == true) {
        CustomLogger.logMessage(msg: '✅ SWAP API CALL SUCCESSFUL', level: LogLevel.info);
        
        // Emit socket event for real-time update
        repository.emitScoreboardSwapped(body);
        CustomLogger.logMessage(msg: '📡 SOCKET EVENT EMITTED', level: LogLevel.info);
      } else {
        CustomLogger.logMessage(msg: '❌ SWAP API CALL FAILED: ${response.message}', level: LogLevel.error);
      }
      
    } catch (e) {
      CustomLogger.logMessage(msg: '💥 ERROR SENDING SWAP API CALL: $e', level: LogLevel.error);
    }
  }

  ///Send Move Action API Call
  Future<void> _sendMoveAction(String playerId, String fromTeam, String toTeam) async {
    try {
      CustomLogger.logMessage(msg: '📡 PREPARING MOVE API CALL', level: LogLevel.info);
      
      // Build the teams array with current player positions after move
      final updatedTeams = [];
      for (int i = 0; i < teams.length; i++) {
        final teamPlayers = teams[i]['players'] as List;
        final playerIds = teamPlayers.map((p) => {'playerId': p['playerId']}).toList();

        updatedTeams.add({
          'name': teams[i]['name'],
          'players': playerIds,
        });
        
        CustomLogger.logMessage(msg: '   ${teams[i]['name']}: ${teamPlayers.map((p) => p['name']).join(', ')}', level: LogLevel.info);
      }
      
      final body = {
        "scoreboardId": scoreboardId.value,
        "action": "move",
        "teams": updatedTeams,
      };
      
      CustomLogger.logMessage(msg: '📤 SENDING MOVE API BODY:', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   ScoreboardId: ${scoreboardId.value}', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Action: move', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Teams: $updatedTeams', level: LogLevel.info);
      
      // Call the updateScoreBoard API
      final response = await repository.updateScoreBoard(data: body);
      
      if (response.success == true) {
        CustomLogger.logMessage(msg: '✅ MOVE API CALL SUCCESSFUL', level: LogLevel.info);
        
        // Emit socket event for real-time update
        repository.emitScoreboardSwapped(body);
        CustomLogger.logMessage(msg: '📡 SOCKET EVENT EMITTED', level: LogLevel.info);
      } else {
        CustomLogger.logMessage(msg: '❌ MOVE API CALL FAILED: ${response.message}', level: LogLevel.error);
      }
      
    } catch (e) {
      CustomLogger.logMessage(msg: '💥 ERROR SENDING MOVE API CALL: $e', level: LogLevel.error);
    }
  }

  ///Move Player to Empty Slot-------------------------------------------------
  void movePlayerToEmptySlot(String playerId, String targetTeam, int targetIndex) {
    HapticFeedback.mediumImpact();
    CustomLogger.logMessage(msg: 'movePlayerToEmptySlot called - playerId: $playerId, targetTeam: $targetTeam, targetIndex: $targetIndex', level: LogLevel.info);
    try {
      // Safety checks
      if (teams.isEmpty || targetIndex < 0) {
        CustomLogger.logMessage(msg: 'Invalid parameters: teams.isEmpty=${teams.isEmpty}, targetIndex=$targetIndex', level: LogLevel.error);
        return;
      }
      
      // Find the player to move
      Map<String, dynamic>? playerToMove;
      int sourceTeamIndex = -1;
      int sourcePlayerIndex = -1;
      String sourceTeam = '';

      for (int teamIndex = 0; teamIndex < teams.length; teamIndex++) {
        final teamPlayers = teams[teamIndex]['players'] as List;
        for (int playerIndex = 0; playerIndex < teamPlayers.length; playerIndex++) {
          if (teamPlayers[playerIndex]['playerId'] == playerId) {
            playerToMove = Map<String, dynamic>.from(teamPlayers[playerIndex]);
            sourceTeamIndex = teamIndex;
            sourcePlayerIndex = playerIndex;
            sourceTeam = teams[teamIndex]['name'];
            break;
          }
        }
        if (playerToMove != null) break;
      }

      if (playerToMove == null || sourceTeamIndex == -1 || sourcePlayerIndex == -1) {
        CustomLogger.logMessage(msg: 'Player not found or invalid indices', level: LogLevel.error);
        return;
      }

      // Get target team index
      int targetTeamIndex = targetTeam == 'Team A' ? 0 : 1;
      if (targetTeamIndex >= teams.length) {
        CustomLogger.logMessage(msg: 'Invalid target team index: $targetTeamIndex', level: LogLevel.error);
        return;
      }
      
      CustomLogger.logMessage(msg: 'Moving from team $sourceTeamIndex index $sourcePlayerIndex to team $targetTeamIndex index $targetIndex', level: LogLevel.info);

      // Additional safety check for array access
      final sourceTeamPlayers = List<Map<String, dynamic>>.from(teams[sourceTeamIndex]['players'] as List);
      if (sourcePlayerIndex >= sourceTeamPlayers.length) {
        CustomLogger.logMessage(msg: 'Invalid source player index: $sourcePlayerIndex >= ${sourceTeamPlayers.length}', level: LogLevel.error);
        return;
      }
      
      sourceTeamPlayers.removeAt(sourcePlayerIndex);
      teams[sourceTeamIndex]['players'] = sourceTeamPlayers;

      // Add player to target team at specific index
      final targetTeamPlayers = List<Map<String, dynamic>>.from(teams[targetTeamIndex]['players'] as List);
      
      // Insert at the correct position
      if (targetIndex >= targetTeamPlayers.length || targetIndex < 0) {
        targetTeamPlayers.add(playerToMove);
      } else {
        targetTeamPlayers.insert(targetIndex, playerToMove);
      }
      
      teams[targetTeamIndex]['players'] = targetTeamPlayers;
      
      hasPlayerSwaps.value = true;
      teams.refresh();
      
      CustomLogger.logMessage(msg: 'Player moved to slot successfully (Local only)', level: LogLevel.info);
    } catch (e) {
      CustomLogger.logMessage(msg: 'Move player error: $e', level: LogLevel.error);
    }
  }

  ///Save Player Swaps---------------------------------------------------------
  void prepareShuffleSession() {
    // If a user shuffles mid-match, we want to finalize the pre-shuffle result UI
    // and restart the match with the new teams.
    didShuffleDuringActiveMatch.value = isGameStarted.value && sets.isNotEmpty;
    
    // Store current team membership BEFORE swap
    preShuffleUserInTeamA.value = isUserInTeamA;
    preShuffleUserInTeamB.value = isUserInTeamB;
    
    // Determine winner based on current scores
    String calculatedWinner = '';
    if (teamAWins.value > teamBWins.value) {
      calculatedWinner = 'Team A';
    } else if (teamBWins.value > teamAWins.value) {
      calculatedWinner = 'Team B';
    } else {
      calculatedWinner = 'draw';
    }
    
    // Use calculated winner if winner.value is empty
    preShuffleWinner.value = winner.value.isNotEmpty ? winner.value : calculatedWinner;
    preShuffleTeamAWins.value = teamAWins.value;
    preShuffleTeamBWins.value = teamBWins.value;
    
    CustomLogger.logMessage(
      msg: '📊 PREPARE SHUFFLE SESSION - Winner: ${preShuffleWinner.value}, Team A: ${preShuffleTeamAWins.value}, Team B: ${preShuffleTeamBWins.value}, User in Team A: ${preShuffleUserInTeamA.value}, User in Team B: ${preShuffleUserInTeamB.value}',
      level: LogLevel.info,
    );
  }

  Future<void> _showPreShuffleResultDialog() async {
    final normalizedWinner = preShuffleWinner.value.trim().toLowerCase().replaceAll(' ', '');
    String teamAStatus = "LOSE";
    String teamBStatus = "WIN";

    if (normalizedWinner == 'teama') {
      teamAStatus = "WIN";
      teamBStatus = "LOSE";
    } else if (normalizedWinner == 'teamb') {
      teamAStatus = "LOSE";
      teamBStatus = "WIN";
    } else if (normalizedWinner == 'draw' ||
        normalizedWinner == 'tie' ||
        normalizedWinner == 'tied' ||
        preShuffleTeamAWins.value == preShuffleTeamBWins.value) {
      teamAStatus = "DRAW";
      teamBStatus = "DRAW";
    } else if (preShuffleTeamAWins.value > preShuffleTeamBWins.value) {
      teamAStatus = "WIN";
      teamBStatus = "LOSE";
    } else if (preShuffleTeamBWins.value > preShuffleTeamAWins.value) {
      teamAStatus = "LOSE";
      teamBStatus = "WIN";
    }
    await showTeamsShuffleResultDialog(
      controller: this,
      teamAResult: teamAStatus,
      teamBResult: teamBStatus,
    );
  }

  ///Handle team shuffle result from scoreboardSwapped event
  Future<void> _handleTeamShuffleResultFromSwap({
    required String teamAResult,
    required String teamBResult,
    required int teamAScore,
    required int teamBScore,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: '🔔 SHUFFLE RESULT FROM SWAP - isShowingShuffleResultDialog: ${isShowingShuffleResultDialog.value}',
        level: LogLevel.info,
      );
      
      // Prevent duplicate dialog if already showing
      if (isShowingShuffleResultDialog.value) {
        CustomLogger.logMessage(
          msg: 'Shuffle result dialog already showing, skipping duplicate',
          level: LogLevel.info,
        );
        return;
      }
      
      CustomLogger.logMessage(
        msg: 'Showing shuffle result - Team A: $teamAResult ($teamAScore), Team B: $teamBResult ($teamBScore)',
        level: LogLevel.info,
      );
      
      // Set flag to prevent duplicate
      isShowingShuffleResultDialog.value = true;
      
      // Show the dialog to this player
      await showTeamsShuffleResultDialog(
        controller: this,
        teamAResult: teamAResult,
        teamBResult: teamBResult,
      );
      
      CustomLogger.logMessage(
        msg: '✅ Dialog closed, resetting match',
        level: LogLevel.info,
      );
      
      // Reset flag after dialog is closed
      isShowingShuffleResultDialog.value = false;
      
      // After dialog is closed, reset the match for this player
      await _restartMatchAfterShuffle();
      didShuffleDuringActiveMatch.value = false;
      
    } catch (e, stackTrace) {
      isShowingShuffleResultDialog.value = false;
      CustomLogger.logMessage(
        msg: 'Error handling team shuffle result from swap: $e',
        level: LogLevel.error,
      );
      CustomLogger.logMessage(
        msg: 'Stack trace: $stackTrace',
        level: LogLevel.error,
      );
    }
  }

  ///Handle team shuffle result from socket for all players
  Future<void> _handleTeamShuffleResultFromSocket(dynamic data) async {
    try {
      CustomLogger.logMessage(
        msg: '🔔 SOCKET HANDLER CALLED - isShowingShuffleResultDialog: ${isShowingShuffleResultDialog.value}',
        level: LogLevel.info,
      );
      
      // Prevent duplicate dialog if already showing
      if (isShowingShuffleResultDialog.value) {
        CustomLogger.logMessage(
          msg: 'Shuffle result dialog already showing, skipping duplicate',
          level: LogLevel.info,
        );
        return;
      }
      
      // Log the entire data object
      CustomLogger.logMessage(
        msg: '🔍 FULL SOCKET DATA: $data',
        level: LogLevel.info,
      );
      
      final teamAResult = data['teamAResult']?.toString() ?? 'DRAW';
      final teamBResult = data['teamBResult']?.toString() ?? 'DRAW';
      final teamAScore = data['teamAScore'] ?? 0;
      final teamBScore = data['teamBScore'] ?? 0;
      
      // Get XP values from socket data - try multiple possible key names
      int socketXpEarned = 0;
      int socketXpLost = 0;
      
      if (data is Map) {
        socketXpEarned = (data['xpEarned'] ?? data['currentXP'] ?? data['xpChange'] ?? 0) as int;
        socketXpLost = (data['xpLost'] ?? 0) as int;
        
        CustomLogger.logMessage(
          msg: '🔍 EXTRACTED XP - Earned: $socketXpEarned, Lost: $socketXpLost',
          level: LogLevel.info,
        );
        CustomLogger.logMessage(
          msg: '🔍 AVAILABLE KEYS: ${data.keys.toList()}',
          level: LogLevel.info,
        );
      }
      
      // Update controller XP values from socket
      if (socketXpEarned > 0) {
        xpEarned.value = socketXpEarned;
        CustomLogger.logMessage(
          msg: '✅ XP Earned updated to: ${xpEarned.value}',
          level: LogLevel.info,
        );
      }
      if (socketXpLost > 0) {
        xpLost.value = socketXpLost;
        CustomLogger.logMessage(
          msg: '✅ XP Lost updated to: ${xpLost.value}',
          level: LogLevel.info,
        );
      }
      
      CustomLogger.logMessage(
        msg: 'Showing shuffle result dialog from socket - Team A: $teamAResult ($teamAScore), Team B: $teamBResult ($teamBScore), XP Earned: $socketXpEarned, XP Lost: $socketXpLost',
        level: LogLevel.info,
      );
      
      // Set flag to prevent duplicate
      isShowingShuffleResultDialog.value = true;
      
      // Show the dialog to this player
      await showTeamsShuffleResultDialog(
        controller: this,
        teamAResult: teamAResult,
        teamBResult: teamBResult,
      );
      
      CustomLogger.logMessage(
        msg: '✅ Dialog closed, resetting match',
        level: LogLevel.info,
      );
      
      // Reset flag after dialog is closed
      isShowingShuffleResultDialog.value = false;
      
      // After dialog is closed, reset the match for this player
      await _restartMatchAfterShuffle();
      didShuffleDuringActiveMatch.value = false;
      
    } catch (e, stackTrace) {
      isShowingShuffleResultDialog.value = false;
      CustomLogger.logMessage(
        msg: 'Error handling team shuffle result: $e',
        level: LogLevel.error,
      );
      CustomLogger.logMessage(
        msg: 'Stack trace: $stackTrace',
        level: LogLevel.error,
      );
    }
  }

  Future<void> _restartMatchAfterShuffle() async {
    // Stop the game timer if running
    if (isGameStarted.value) {
      try {
        _gameTimer.cancel();
      } catch (_) {}
      isGameStarted.value = false;
    }

    // Clear all sets and scores
    sets.clear();
    sets.refresh();
    teamAWins.value = 0;
    teamBWins.value = 0;
    winner.value = "";

    // Reset the match state on the server
    try {
      final body = {
        "scoreboardId": scoreboardId.value,
        "type": "reset"
      };
      await repository.updateScoreBoard(data: body);
      CustomLogger.logMessage(msg: 'Match reset successfully', level: LogLevel.info);
    } catch (e) {
      CustomLogger.logMessage(msg: 'Error resetting match: $e', level: LogLevel.error);
    }

    // Fetch updated scoreboard to sync with server
    await fetchScoreBoard(showLoader: false);
    
    CustomLogger.logMessage(msg: 'Match restarted - ready for new game with new teams', level: LogLevel.info);
  }

  Future<void> savePlayerSwaps() async {
    if (!hasPlayerSwaps.value) {
      CustomLogger.logMessage(msg: 'No swaps made - exiting shuffle mode without API call', level: LogLevel.info);
      isShuffleMode.value = false;
      return;
    }

    // Check if swapping during an active match (game must be started AND have sets)
    final isSwappingDuringMatch = isGameStarted.value && sets.isNotEmpty;
    
    CustomLogger.logMessage(
      msg: '🔄 SWAP INITIATED - isSwappingDuringMatch: $isSwappingDuringMatch, isGameStarted: ${isGameStarted.value}, sets.length: ${sets.length}',
      level: LogLevel.info,
    );
    
    // Store pre-shuffle state if swapping during match
    if (isSwappingDuringMatch) {
      prepareShuffleSession();
      CustomLogger.logMessage(
        msg: '📊 PRE-SHUFFLE STATE - Winner: ${preShuffleWinner.value}, Team A: ${preShuffleTeamAWins.value}, Team B: ${preShuffleTeamBWins.value}',
        level: LogLevel.info,
      );
    }

    CustomLogger.logMessage(msg: 'savePlayerSwaps called - SENDING SWAP ACTION TO API', level: LogLevel.info);
    try {
      // Build API body with swap action
      final updatedTeams = [];
      for (int i = 0; i < teams.length; i++) {
        final teamPlayers = teams[i]['players'] as List;
        final playerIds = teamPlayers.map((p) => {'playerId': p['playerId']}).toList();

        updatedTeams.add({
          'name': teams[i]['name'],
          'players': playerIds,
        });
      }

      final body = {
        'scoreboardId': scoreboardId.value,
        'action': 'swap',
        'teams': updatedTeams,
        // Include match state for backend to determine if shuffle result is needed
        'isSwappingDuringMatch': isSwappingDuringMatch,
        'preShuffleWinner': isSwappingDuringMatch ? preShuffleWinner.value : null,
        'preShuffleTeamAWins': isSwappingDuringMatch ? preShuffleTeamAWins.value : null,
        'preShuffleTeamBWins': isSwappingDuringMatch ? preShuffleTeamBWins.value : null,
      };

      CustomLogger.logMessage(msg: '========== SENDING SWAP API ==========', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   ScoreboardId: ${scoreboardId.value}', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   Action: swap', level: LogLevel.info);
      CustomLogger.logMessage(msg: '   isSwappingDuringMatch: $isSwappingDuringMatch', level: LogLevel.info);
      if (isSwappingDuringMatch) {
        CustomLogger.logMessage(msg: '   preShuffleWinner: ${preShuffleWinner.value}', level: LogLevel.info);
        CustomLogger.logMessage(msg: '   preShuffleTeamAWins: ${preShuffleTeamAWins.value}', level: LogLevel.info);
        CustomLogger.logMessage(msg: '   preShuffleTeamBWins: ${preShuffleTeamBWins.value}', level: LogLevel.info);
      }
      CustomLogger.logMessage(msg: '   Teams: $updatedTeams', level: LogLevel.info);
      CustomLogger.logMessage(msg: '========================================', level: LogLevel.info);

      final response = await repository.updateScoreBoard(data: body);

      if (response?.success == true) {
        CustomLogger.logMessage(msg: '✅ SWAP API CALL SUCCESSFUL', level: LogLevel.info);
        
        hasPlayerSwaps.value = false;
        isShuffleMode.value = false;
        
        // EMIT SOCKET EVENT: swapPlayer
        CustomLogger.logMessage(
          msg: '📡 ========== EMITTING swapPlayer SOCKET EVENT ==========',
          level: LogLevel.info,
        );
        
        final socketData = {
          'scoreboardId': scoreboardId.value,
          'teams': updatedTeams,
          'isSwappingDuringMatch': isSwappingDuringMatch,
          'preShuffleWinner': isSwappingDuringMatch ? preShuffleWinner.value : null,
          'preShuffleTeamAWins': isSwappingDuringMatch ? preShuffleTeamAWins.value : null,
          'preShuffleTeamBWins': isSwappingDuringMatch ? preShuffleTeamBWins.value : null,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        CustomLogger.logMessage(
          msg: '📡 Socket Data: $socketData',
          level: LogLevel.info,
        );
        
        // Emit swapPlayer event
        repository.emitSwapPlayer(socketData);
        
        CustomLogger.logMessage(
          msg: '✅ swapPlayer socket event emitted',
          level: LogLevel.info,
        );
        
        // If swapping during match, wait for matchCompleted event from backend
        if (isSwappingDuringMatch) {
          CustomLogger.logMessage(
            msg: '⏳ Waiting for matchCompleted event from backend...',
            level: LogLevel.info,
          );
          
          // Set flag to indicate this completion is due to swap
          wasSwapDuringMatch.value = true;
          
          // Mark match as completed to show result
          isCompleted.value = true;
        } else {
          // Normal swap without active match
          AppToast.success('Teams updated successfully');
        }
        
        CustomLogger.logMessage(msg: 'Teams swapped and socket event emitted', level: LogLevel.info);
      } else {
        AppToast.error('Failed to update teams');
        CustomLogger.logMessage(msg: '❌ SWAP API CALL FAILED: ${response?.message}', level: LogLevel.error);
      }
    } catch (e, stackTrace) {
      isShowingShuffleResultDialog.value = false;
      CustomLogger.logMessage(msg: '💥 ERROR SENDING SWAP API CALL: $e', level: LogLevel.error);
      CustomLogger.logMessage(msg: 'Stack trace: $stackTrace', level: LogLevel.error);
      AppToast.error('Error updating teams');
    }
  }
  ///Convert Booking To Open Match---------------------------------------------
  var isConvertingToOpenMatch = false.obs;
  MainHomeController mainHomeController = Get.put(MainHomeController());
  Future<void> convertToOpenMatch() async {
    isConvertingToOpenMatch.value = true;
    try {
      final clubLocationId = _resolveClubLocationId();
      final profileLocationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId
          ?? "68c94a94d72a6f9769712ff0";
      final categoryId = mainHomeController.selectedCategoryId.value;
      final body = {
        "bookingId": matchBookingId.value,
        "matchType": matchType.value.toLowerCase(),
        "bookingType": "openMatch",
        "categoryId": categoryId,
        "location": clubLocationId,
        "stateId": profileLocationId,
      };

      final response = await repository.convertBookingToOpenMatch(body: body);

      if (response?.success == true) {
        bookingType.value = "openMatch";
        CustomLogger.logMessage(msg: response?.message ?? "Booking converted to open match successfully!", level: LogLevel.debug);

        await fetchScoreBoard(showLoader: false);
        await mainHomeController.homeController.fetchBookings();
      } else {
        CustomLogger.logMessage(msg: response?.message ?? "Failed to convert booking", level: LogLevel.debug);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR converting to open match-> $e", level: LogLevel.error);
    } finally {
      isConvertingToOpenMatch.value = false;
    }
  }

  String _resolveClubLocationId() {
    try {
      final clubId = registerClubId.value;
      if (clubId.isEmpty) return "";

      final clubs = mainHomeController.homeController.courtsData.value?.data?.courts;
      if (clubs == null || clubs.isEmpty) return "";

      final club = clubs.firstWhere(
        (c) => (c.id ?? "") == clubId,
        orElse: () => clubs.first,
      );

      return (club.locations?.isNotEmpty == true) ? (club.locations![0].id ?? "") : "";
    } catch (_) {
      return "";
    }
  }

  ///Show Remove Player Confirmation Dialog------------------------------------
  Future<void> showRemovePlayerDialog(String playerId, String playerName, String teamName) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Are you sure you want to remove $playerName from the team?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await removePlayer(playerId, teamName);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  ///Share Scoreboard-----------------------------------------------------------
  Future<void> shareScoreboard(BuildContext context) async {
    String formatPlayerNames(List<dynamic> players) {
      if (players.isEmpty) return "Available";
      return players
          .where((p) => p['name'] != null && p['name'].toString().isNotEmpty)
          .map((p) {
        final firstName = (p['name']?.toString())?.capitalizeFirst ?? '';
        final lastName = (p['lastName']?.toString())?.capitalizeFirst ?? '';
        final fullName = "$firstName $lastName".trim();
        return fullName.isEmpty ? "Unknown" : fullName;
      }).join(", ");
    }

    final teamAPlayers = teams.isNotEmpty ? formatPlayerNames(teams[0]["players"]) : "Available";
    final teamBPlayers = teams.length > 1 ? formatPlayerNames(teams[1]["players"]) : "Available";

    final formattedDate = formatMatchDateAt(matchDate.value);
    final clubNameValue = clubName.value.isNotEmpty ? clubName.value : "Unknown Club";
    final courtNameValue = courtName.value.isNotEmpty ? courtName.value : "Court 1";

    String setsResults = "";
    if (sets.isNotEmpty) {
      setsResults = sets.map((set) {
        final teamA = set["teamAScore"] ?? 0;
        final teamB = set["teamBScore"] ?? 0;
        return "Set ${set["setNumber"]}: $teamA - $teamB";
      }).join("\n");
    } else {
      setsResults = "No scores recorded yet";
    }

    final message = '''
🎾 *Padel Scoreboard*

📍 *Club:* $clubNameValue
🏟️ *Court:* $courtNameValue
📅 *Date:* $formattedDate

👥 *Team A:* $teamAPlayers
👥 *Team B:* $teamBPlayers

📊 *Scores:*
$setsResults

🏆 *Overall Score:* ${teamAWins.value} - ${teamBWins.value}
${winner.value.isNotEmpty && winner.value != "-" ? "🎉 *Winner:* ${winner.value}" : ""}

Great game! 🏓
''';

    final renderBox = context.findRenderObject() as RenderBox?;
    final Rect shareRect = (renderBox != null)
        ? (renderBox.localToGlobal(Offset.zero) & renderBox.size)
        : const Rect.fromLTWH(0, 0, 1, 1);

    await Share.share(
      message,
      subject: "Check out this Padel scoreboard!",
      sharePositionOrigin: (shareRect.width == 0 || shareRect.height == 0)
          ? const Rect.fromLTWH(0, 0, 1, 1)
          : shareRect,
    );
  }

  String formatMatchDateAt(String dateString) {
    try {
      if (dateString.isEmpty) return "Unknown Date";
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    } catch (e) {
      return "Unknown Date";
    }
  }
}