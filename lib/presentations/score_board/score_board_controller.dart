import 'dart:async';
import 'package:intl/intl.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/repositories/score_board_repo/score_board_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:padel_mobile/presentations/score_board/widgets/match_summary_dialog.dart';

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
  int _calculateRemainingMatchTime() {
    try {
      if (endTime.value.isEmpty) return 0;

      String endTimeStr = _normalizeTimeFormat(endTime.value.trim());
      DateTime endTimeObj = DateFormat('h:mm a').parse(endTimeStr);
      DateTime now = DateTime.now();
      
      DateTime endDateTime = DateTime(now.year, now.month, now.day, endTimeObj.hour, endTimeObj.minute);

      // If end time is in the past, it means it's for next day
      if (endDateTime.isBefore(now)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

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
      if (startTime.value.isEmpty || endTime.value.isEmpty) {
        CustomLogger.logMessage(msg: "startTime or endTime is EMPTY", level: LogLevel.error);
        return false;
      }

      String startTimeStr = _normalizeTimeFormat(startTime.value.trim());
      String endTimeStr = _normalizeTimeFormat(endTime.value.trim());
      
      DateTime startTimeObj = DateFormat('h:mm a').parse(startTimeStr);
      DateTime endTimeObj = DateFormat('h:mm a').parse(endTimeStr);
      DateTime now = DateTime.now();
      
      DateTime startDateTime = DateTime(now.year, now.month, now.day, startTimeObj.hour, startTimeObj.minute);
      DateTime endDateTime = DateTime(now.year, now.month, now.day, endTimeObj.hour, endTimeObj.minute);
      
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
  ScoreBoardRepository repository = Get.put(ScoreBoardRepository());
  final isLoading = true.obs;
  final isAddingSet = false.obs;
  final isAddingScore = false.obs;
  final isShuffleMode = false.obs;
  final hasPlayerSwaps = false.obs;
  var matchBookingId = ''.obs;

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
        bookingType.value = item.bookingId?.bookingType ?? "normal";
        CustomLogger.logMessage(
            msg: "Booking Type from API: ${item.bookingId?.bookingType}", level: LogLevel.info);
        CustomLogger.logMessage(
            msg: "Booking Type set to: ${bookingType.value}", level: LogLevel.info);
        matchType.value = (item?.matchType ?? "Friendly").capitalizeFirst ?? "Friendly";
        matchStatus.value = item?.matchStatus ?? false;
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

        if (item.teams != null && item.teams!.isNotEmpty) {
          CustomLogger.logMessage(
              msg: "Processing ${item.teams!.length} teams",
              level: LogLevel.info);

          for (int teamIndex = 0; teamIndex < item.teams!.length; teamIndex++) {
            var t = item.teams![teamIndex];

            CustomLogger.logMessage(
                msg:
                "Team ${teamIndex + 1}: ${t.name}, players: ${t.players?.length ?? 0}",
                level: LogLevel.info);

            final playersList = <Map<String, dynamic>>[];

            if (t.players != null) {
              for (var p in t.players!) {
                String fullLevel =
                    p.playerId?.level ?? p.playerId?.playerLevel ?? "";
                String levelCode = fullLevel.contains(' – ')
                    ? fullLevel.split(' – ')[0]
                    : fullLevel;

                final playerData = {
                  "playerId": p.playerId?.sId ?? p.playerId?.sId ?? "",
                  "name": p.playerId?.name ?? "Unknown",
                  "lastName": p.playerId?.lastName ?? "",
                  "pic": p.playerId?.profilePic ?? "",
                  "level": levelCode,
                };

                playersList.add(playerData);

                CustomLogger.logMessage(
                    msg:
                    "  Player: ${playerData['name']}, Level: ${playerData['level']}",
                    level: LogLevel.info);
              }
            }

            teams.add({
              "name": t.name ?? "Team ${teamIndex + 1}",
              "players": playersList,
            });
          }
        }

        if (teams.length < 2) {
          CustomLogger.logMessage(
              msg:
              "Only ${teams.length} team(s) in response, adding empty Team B",
              level: LogLevel.warning);
          teams.add({
            "name": "Team B",
            "players": [],
          });
        }

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
        
        // Set game started status based on existing sets
        isGameStarted.value = sets.isNotEmpty;
        
        // Start timer if game is started and within match time
        if (isGameStarted.value && _isWithinMatchTimeWindow()) {
          remainingSeconds.value = _calculateRemainingMatchTime();
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
      SnackBarUtils.showErrorSnackBar("Cannot start game. Match is already completed.");
      return;
    }

    if (!allPlayersAdded) {
      SnackBarUtils.showErrorSnackBar("Please add all 4 players first");
      return;
    }

    if (!isWithinMatchTime.value) {
      SnackBarUtils.showErrorSnackBar("Game can only start during match time");
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
      remainingSeconds.value = _calculateRemainingMatchTime();
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
        SnackBarUtils.showInfoSnackBar("Match time is up! Game ended automatically.");
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
      SnackBarUtils.showErrorSnackBar("Cannot add set. Match is already completed.");
      return;
    }
    
    if (sets.length < 10) {
      await createSets(_nextAvailableSetNumber());
    } else {
      SnackBarUtils.showInfoSnackBar("Limit Reached\nYou can add up to 10 sets only");
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
    _startPeriodicUpdates();
    _startMatchTimeCheck();
    
    // Force immediate check
    isWithinMatchTime.value = _isWithinMatchTimeWindow();
    CustomLogger.logMessage(
      msg: "Initial match time check: ${isWithinMatchTime.value}, matchTime: ${matchTime.value}",
      level: LogLevel.info
    );
    if (isWithinMatchTime.value) {
      remainingSeconds.value = _calculateRemainingMatchTime();
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
        remainingSeconds.value = _calculateRemainingMatchTime();
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
    _periodicTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _fetchScoreBoardForStream();
    });
  }

  Future<void> _fetchScoreBoardForStream() async {
    try {
      if (_scoreboardStreamController.isClosed) return;

      final response = await repository.getScoreBoard(bookingId: bookingId.value);
      if (response.status == 200 && response.data!.isNotEmpty) {
        final item = response.data!.first;

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
        isCompleted.value = item.isCompleted ?? false;

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
        int remaining = _calculateRemainingMatchTime();
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
    super.onClose();
  }

  ///Add Score------------------------------------------------------------------
  Future<void> addScore(int setNumber, int teamAScore, int teamBScore) async {
    // Prevent score addition if game hasn't started
    if (!isGameStarted.value) {
      SnackBarUtils.showErrorSnackBar("Cannot add score. Please start the match first.");
      return;
    }
    
    // Validate scores don't exceed 20
    if (teamAScore > 20 || teamBScore > 20) {
      SnackBarUtils.showErrorSnackBar("Score cannot exceed 20");
      return;
    }
    
    CustomLogger.logMessage(msg: 'addScore API call - set: $setNumber, scores: $teamAScore-$teamBScore', level: LogLevel.info);
    if (teamAScore == 0 && teamBScore == 0) {
      SnackBarUtils.showErrorSnackBar("Both team scores cannot be zero.");
      return;
    }
    isAddingScore.value = true;
    try {
      // Only send the score for the team that actually scored
      final Map<String, dynamic> setData = {
        "setNumber": setNumber,
      };

      if (teamAScore > 0) {
        setData["teamAScore"] = teamAScore;
      }
      if (teamBScore > 0) {
        setData["teamBScore"] = teamBScore;
      }

      // Only determine winner if both teams have scores
      final currentSet = sets.firstWhere((s) => s["setNumber"] == setNumber, orElse: () => {});
      final currentTeamAScore = currentSet["teamAScore"] ?? 0;
      final currentTeamBScore = currentSet["teamBScore"] ?? 0;

      final finalTeamAScore = teamAScore > 0 ? teamAScore : currentTeamAScore;
      final finalTeamBScore = teamBScore > 0 ? teamBScore : currentTeamBScore;

      if (finalTeamAScore > 0 && finalTeamBScore > 0) {
        if (finalTeamAScore > finalTeamBScore) {
          setData["winner"] = "Team A";
        } else if (finalTeamBScore > finalTeamAScore) {
          setData["winner"] = "Team B";
        }
      }

      final body = {
        "scoreboardId": scoreboardId.value,
        "sets": [setData]
      };

      final response = await repository.updateScoreBoard(data: body);
      if (response.success == true) {
        CustomLogger.logMessage(msg: "Score Added Successfully", level: LogLevel.info);
        await fetchScoreBoard(showLoader: false);
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
        SnackBarUtils.showInfoSnackBar("Match type updated to $newMatchType");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR updating match type-> $e", level: LogLevel.error);
    }
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
      SnackBarUtils.showErrorSnackBar("Cannot end game with empty sets. Please add scores first.");
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
        await fetchScoreBoard(showLoader: false);
        await profileController.fetchUserProfile();
        showMatchSummaryDialog(this);
      } else {
        SnackBarUtils.showErrorSnackBar(response.message ?? "");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR-> $e", level: LogLevel.error);
    } finally {
      isEndGame.value = false;
    }
  }

  ///Check if swapping is allowed----------------------------------------------
  bool get canSwapPlayers => !isCompleted.value;

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
  String _normalizeTeamName(String teamName) {
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
      final normalizedTeamName = _normalizeTeamName(teamName);
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
        SnackBarUtils.showInfoSnackBar("Player removed successfully");
        CustomLogger.logMessage(msg: 'Player removed successfully from server', level: LogLevel.info);
      } else {
        SnackBarUtils.showErrorSnackBar(response?.message ?? "Failed to remove player");
        // Revert local changes if API failed
        await fetchScoreBoard(showLoader: false);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Remove player error: $e', level: LogLevel.error);
      SnackBarUtils.showErrorSnackBar("Failed to remove player");
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
    CustomLogger.logMessage(msg: 'swapPlayers called - draggedPlayerId: $draggedPlayerId, targetTeam: $targetTeam, targetIndex: $targetIndex', level: LogLevel.info);
    try {
      // Find dragged player and remove from current position
      Map<String, dynamic>? draggedPlayer;
      int draggedTeamIndex = -1;
      int draggedPlayerIndex = -1;

      for (int teamIndex = 0; teamIndex < teams.length; teamIndex++) {
        final teamPlayers = teams[teamIndex]['players'] as List;
        for (int playerIndex = 0; playerIndex < teamPlayers.length; playerIndex++) {
          if (teamPlayers[playerIndex]['playerId'] == draggedPlayerId) {
            draggedPlayer = Map<String, dynamic>.from(teamPlayers[playerIndex]);
            draggedTeamIndex = teamIndex;
            draggedPlayerIndex = playerIndex;
            CustomLogger.logMessage(msg: 'Found dragged player in team $teamIndex at index $playerIndex', level: LogLevel.info);
            break;
          }
        }
        if (draggedPlayer != null) break;
      }

      if (draggedPlayer == null) {
        CustomLogger.logMessage(msg: 'Dragged player not found!', level: LogLevel.error);
        return;
      }

      // Get target team index
      int targetTeamIndex = targetTeam == 'Team A' ? 0 : 1;
      CustomLogger.logMessage(msg: 'Target team index: $targetTeamIndex', level: LogLevel.info);

      // Get target player if exists
      Map<String, dynamic>? targetPlayer;
      final targetTeamPlayers = teams[targetTeamIndex]['players'] as List;
      if (targetIndex < targetTeamPlayers.length) {
        targetPlayer = Map<String, dynamic>.from(targetTeamPlayers[targetIndex]);
        CustomLogger.logMessage(msg: 'Found target player at index $targetIndex', level: LogLevel.info);
      }

      // Perform the swap in local data only - NO API CALL
      final draggedTeamPlayers = teams[draggedTeamIndex]['players'] as List;

      if (targetPlayer != null) {
        // Swap players
        CustomLogger.logMessage(msg: 'Swapping players between teams', level: LogLevel.info);
        draggedTeamPlayers[draggedPlayerIndex] = targetPlayer;
        targetTeamPlayers[targetIndex] = draggedPlayer;
      } else {
        // Move player to empty slot
        CustomLogger.logMessage(msg: 'Moving player to empty slot', level: LogLevel.info);
        draggedTeamPlayers.removeAt(draggedPlayerIndex);
        if (targetIndex < targetTeamPlayers.length) {
          targetTeamPlayers[targetIndex] = draggedPlayer;
        } else {
          targetTeamPlayers.add(draggedPlayer);
        }
      }

      hasPlayerSwaps.value = true;
      teams.refresh();
      CustomLogger.logMessage(msg: 'Local swap completed successfully', level: LogLevel.info);
    } catch (e) {
      CustomLogger.logMessage(msg: 'Swap error: $e', level: LogLevel.error);
    }
  }

  ///Move Player to Empty Slot-------------------------------------------------
  void movePlayerToEmptySlot(String playerId, String targetTeam, int targetIndex) {
    CustomLogger.logMessage(msg: 'movePlayerToEmptySlot called', level: LogLevel.info);
    try {
      // Find the player to move
      Map<String, dynamic>? playerToMove;
      int sourceTeamIndex = -1;
      int sourcePlayerIndex = -1;

      for (int teamIndex = 0; teamIndex < teams.length; teamIndex++) {
        final teamPlayers = teams[teamIndex]['players'] as List;
        for (int playerIndex = 0; playerIndex < teamPlayers.length; playerIndex++) {
          if (teamPlayers[playerIndex]['playerId'] == playerId) {
            playerToMove = Map<String, dynamic>.from(teamPlayers[playerIndex]);
            sourceTeamIndex = teamIndex;
            sourcePlayerIndex = playerIndex;
            break;
          }
        }
        if (playerToMove != null) break;
      }

      if (playerToMove == null) return;

      // Get target team index
      int targetTeamIndex = targetTeam == 'Team A' ? 0 : 1;

      // Remove player from source team
      final sourceTeamPlayers = teams[sourceTeamIndex]['players'] as List;
      sourceTeamPlayers.removeAt(sourcePlayerIndex);

      // Add player to target team at specific index
      final targetTeamPlayers = teams[targetTeamIndex]['players'] as List;
      if (targetIndex < targetTeamPlayers.length) {
        targetTeamPlayers[targetIndex] = playerToMove;
      } else {
        targetTeamPlayers.add(playerToMove);
      }
      hasPlayerSwaps.value = true;
      teams.refresh();
      CustomLogger.logMessage(msg: 'Player moved to empty slot successfully', level: LogLevel.info);
    } catch (e) {
      CustomLogger.logMessage(msg: 'Move player error: $e', level: LogLevel.error);
    }
  }

  ///Save Player Swaps---------------------------------------------------------
  Future<void> savePlayerSwaps() async {
    if (!hasPlayerSwaps.value) {
      CustomLogger.logMessage(msg: 'No swaps made - exiting shuffle mode without API call', level: LogLevel.info);
      isShuffleMode.value = false;
      return;
    }

    CustomLogger.logMessage(msg: 'savePlayerSwaps called - API CALL STARTING', level: LogLevel.info);
    try {
      // Build API body
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
        'teams': updatedTeams,
        'action': 'swap',
      };

      CustomLogger.logMessage(msg: 'Making API call to save player swaps', level: LogLevel.info);
      final response = await repository.updateScoreBoard(data: body);
      if (response.success == true) {
        hasPlayerSwaps.value = false;
        isShuffleMode.value = false;
        await fetchScoreBoard();
        CustomLogger.logMessage(msg: 'API call successful - shuffle mode disabled', level: LogLevel.info);
      } else {
        await fetchScoreBoard(showLoader: false);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: 'Save error: $e', level: LogLevel.error);
      await fetchScoreBoard(showLoader: false);
    }
  }
  ///Convert Booking To Open Match---------------------------------------------
  var isConvertingToOpenMatch = false.obs;
  MainHomeController mainHomeController = Get.put(MainHomeController());
  Future<void> convertToOpenMatch() async {
    isConvertingToOpenMatch.value = true;
    try {
      final body = {
        "bookingId": matchBookingId.value,
        "matchType": matchType.value.toLowerCase(),
        "bookingType": "openMatch"
      };

      final response = await repository.convertBookingToOpenMatch(body: body);

      if (response?.success == true) {
        bookingType.value = "openMatch";
        SnackBarUtils.showInfoSnackBar(response?.message ?? "Booking converted to open match successfully!");
        await fetchScoreBoard(showLoader: false);
        await mainHomeController.homeController.fetchBookings();
      } else {
        SnackBarUtils.showErrorSnackBar(response?.message ?? "Failed to convert booking");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR converting to open match-> $e", level: LogLevel.error);
      SnackBarUtils.showErrorSnackBar("Failed to convert booking");
    } finally {
      isConvertingToOpenMatch.value = false;
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
}