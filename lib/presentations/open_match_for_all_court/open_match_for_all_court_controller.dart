import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/data/request_models/home_models/get_club_name_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/all_open_matches.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/repositories/score_board_repo/score_board_repository.dart';

class OpenMatchForAllCourtController extends GetxController {
  final isMyBooking = true.obs;
  Rx<bool> viewUnavailableSlots = false.obs;
  RxList<String> selectedSlots = <String>[].obs;
  RxString selectedTimeFilter = 'morning'.obs; // New: for tab selection
  RxString selectedGameLevel = 'Game Level'.obs; // New: for game level selection
  RxBool isGameLevelSelected = false.obs; // Track if game level is selected
  RxInt expandedIndex = (-1).obs; // Add expanded index for card expansion

  String? selectedTime;
  Rx<DateTime> selectedDate = DateTime.now().obs;
  RxBool isLoading = false.obs;
  Rx<OpenMatchModel?> createdMatch = Rx<OpenMatchModel?>(null);
  Rx<OpenMatchBookingModel?> matchesBySelection = Rx<OpenMatchBookingModel?>(null);
  RxString errorMessage = ''.obs;

  // Join requests related observables
  RxList<Map<String, dynamic>> joinRequests = <Map<String, dynamic>>[].obs;
  RxBool isLoadingRequests = false.obs;
  RxString acceptingRequestId = ''.obs;
  RxString rejectingRequestId = ''.obs;

  // Nearby players
  RxList<Map<String, dynamic>> nearbyPlayers = <Map<String, dynamic>>[].obs;
  RxBool isLoadingNearbyPlayers = false.obs;
  RxString requestingPlayerId = ''.obs; // Track which player request is in progress
  RxList<String> requestedPlayerIds = <String>[].obs; // Track requested players

  // Scoreboard
  final ScoreBoardRepository scoreBoardRepository = Get.put(ScoreBoardRepository());
  final GetStorage storage = GetStorage();
  RxBool isCheckingScoreboard = false.obs;
  RxString loadingMatchId = ''.obs;

  final List<String> timeSlots = [
    "6:00 am",
    "7:00 am",
    "8:00 am",
    "9:00 am",
    "10:00 am",
    "11:00 am",
    "12:00 pm",
    "1:00 pm",
    "2:00 pm",
    "3:00 pm",
    "4:00 pm",
    "5:00 pm",
    "6:00 pm",
    "7:00 pm",
    "8:00 pm",
    "9:00 pm",
    "10:00 pm",
    "11:00 pm",
  ];

  String getDay(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(ymd);
      return DateFormat('EEE').format(parsed);
    } catch (_) {
      return ymd;
    }
  }

  String getDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(ymd);
      return DateFormat('dd MMM').format(parsed);
    } catch (_) {
      return ymd;
    }
  }

  Rx<DateTime> focusedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    focusedDate.value = selectedDate.value;
    if (timeSlots.isNotEmpty) {
      final firstAvail = firstAvailableSlot();
      if (firstAvail != null) {
        selectedSlots
          ..clear()
          ..add(firstAvail);
        selectedTime = firstAvail;
      } else {
        selectedSlots.clear();
        selectedTime = null;
      }
      fetchMatchesForSelection();
    }
  }

  /// Get time period (morning, noon, night) for a given time slot
  String getTimePeriod(String timeSlot) {
    try {
      final cleaned = timeSlot.replaceAll(' ', '').toUpperCase();
      DateTime? parsed;

      try {
        parsed = DateFormat('h:mma').parse(cleaned);
      } catch (_) {
        try {
          parsed = DateFormat('hha').parse(cleaned);
        } catch (_) {
          try {
            parsed = DateFormat('ha').parse(cleaned);
          } catch (_) {
            return 'morning'; // default fallback
          }
        }
      }

      final hour = parsed.hour;

      if (hour >= 6 && hour < 12) {
        return 'morning'; // 6 AM - 11:59 AM
      } else if (hour >= 12 && hour < 18) {
        return 'noon'; // 12 PM - 5:59 PM
      } else {
        return 'night'; // 6 PM - 5:59 AM
      }
    } catch (_) {
      return 'morning';
    }
  }

  /// Filter slots by selected time period
  List<String> filterSlotsByPeriod(List<String> slots) {
    final filter = selectedTimeFilter.value;
    return slots.where((slot) => getTimePeriod(slot) == filter).toList();
  }

  /// Filtered available slots based on tab selection
  List<String> get filteredAvailableSlots {
    return filterSlotsByPeriod(availableSlots);
  }

  /// Filtered unavailable slots based on tab selection
  List<String> get filteredUnavailableSlots {
    return filterSlotsByPeriod(unavailableSlots);
  }
  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  /// Function to create match
  Future<void> createOpenMatch() async {
    try {
      isLoading.value = true;

      if (selectedTime == null) {
        Get.snackbar("Error", "Please select a time slot");
        return;
      }

      String formattedDate = DateFormat("yyyy-MM-dd").format(selectedDate.value);

      final data = {
        "matchDate": formattedDate,
        "matchTime": selectedTime,
        "slots": selectedSlots,
      };

      final response = await repository.createMatch(data: data);

      createdMatch.value = response;

      Get.snackbar("Success", "Match created successfully!");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch matches for selected date and first chosen time slot
  Future<void> fetchMatchesForSelection() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      _ensureValidSelection();
      if (selectedTime == null) {
        matchesBySelection.value = null;
        return;
      }

      final formattedDate = DateFormat("yyyy-MM-dd").format(selectedDate.value);
      final matchDate = formattedDate.isEmpty ? DateFormat("yyyy-MM-dd").format(DateTime.now()) : formattedDate;
      final userId = storage.read("userId")??"";
      final filter = isMyBooking.value ? 'myMatch' : 'allMatches';
      final response = await repository.getOpenMatchBookings(
        userid: userId,
        filter: filter,
        type: '',
        matchDate: matchDate
      );
      matchesBySelection.value = response;
    } catch (e) {
      errorMessage.value = e.toString();
      CustomLogger.logMessage(msg: "Error -> ${errorMessage.value}", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  String _formatTimeForApi(String raw) {
    final cleaned = raw.replaceAll(' ', '').toUpperCase();
    DateTime? parsed;
    try {
      parsed = DateFormat('h:mma').parse(cleaned);
    } catch (_) {
      try {
        parsed = DateFormat('hha').parse(cleaned);
      } catch (_) {
        try {
          parsed = DateFormat('ha').parse(cleaned);
        } catch (_) {
          parsed = null;
        }
      }
    }
    if (parsed == null) {
      return raw;
    }
    return DateFormat('h a').format(parsed).toLowerCase();
  }

  /// Format time range from list of times
  String formatTimeRange(List<String>? times) {
    if (times == null || times.isEmpty) return '';
    if (times.length == 1) return times.first;
    
    final first = times.first;
    final last = times.last;
    
    // Extract number from first time (e.g., "8" from "8 pm")
    final firstNumber = first.replaceAll(RegExp(r'[^0-9]'), '');
    
    return '$firstNumber-$last';
  }

  bool isPastTime(String slotLabel) {
    try {
      final targetDate = selectedDate.value;
      final now = DateTime.now();

      if (DateTime(targetDate.year, targetDate.month, targetDate.day)
          .isAfter(DateTime(now.year, now.month, now.day))) {
        return false;
      }

      if (DateTime(targetDate.year, targetDate.month, targetDate.day)
          .isBefore(DateTime(now.year, now.month, now.day))) {
        return true;
      }

      final cleaned = slotLabel.replaceAll(' ', '').toUpperCase();
      final parsed = DateFormat('ha').parse(cleaned);
      final slotDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, parsed.hour, 0);
      return slotDateTime.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  String? firstAvailableSlot() {
    for (final t in timeSlots) {
      if (!isPastTime(t)) return t;
    }
    return null;
  }

  List<String> get availableSlots => timeSlots.where((t) => !isPastTime(t)).toList();
  List<String> get unavailableSlots => timeSlots.where((t) => isPastTime(t)).toList();

  void _ensureValidSelection() {
    if (selectedTime == null || isPastTime(selectedTime!)) {
      final nextSlot = firstAvailableSlot();
      if (nextSlot != null) {
        selectedTime = nextSlot;
        selectedSlots
          ..clear()
          ..add(nextSlot);
      } else {
        selectedSlots.clear();
        selectedTime = null;
      }
    }
  }

  /// Fetch join requests for a match
  Future<void> fetchJoinRequests(String matchId) async {
    try {
      isLoadingRequests.value = true;
      joinRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(matchId: matchId,type: "MatchCreator");

      if (response != null && response.requests != null) {
        joinRequests.value = response.requests!.map((request) => {
          'id': request.id ?? '',
          'name': request.requester?.name ?? '',
          'lastName': request.requester?.lastName ?? '',
          'profilePic': request.requester?.profilePic ?? '',
          'level': request.level ?? '',
        }).toList();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching join requests: $e", level: LogLevel.error);
      Get.snackbar("Error", "Failed to fetch join requests");
    } finally {
      isLoadingRequests.value = false;
    }
  }

  /// Accept a join request
  Future<void> acceptRequest(String requestId, String matchId) async {
    try {
      acceptingRequestId.value = requestId;
      final body = {
        "requestId": requestId,
        "action": "accept",
        "type": "MatchCreator"
      };
      await repository.acceptOrRejectRequestPlayer(body: body);

      // Remove from requests list
      joinRequests.removeWhere((request) => request['id'] == requestId);

      SnackBarUtils.showSuccessSnackBar("Request accepted successfully");

      // Refresh matches
      await fetchMatchesForSelection();
    } catch (e) {
      CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
    } finally {
      acceptingRequestId.value = '';
    }
  }

  /// Reject a join request
  Future<void> rejectRequest(String requestId, String matchId) async {
    try {
      rejectingRequestId.value = requestId;
      final body = {
        "requestId": requestId,
        "action": "reject"
      };

      await repository.acceptOrRejectRequestPlayer(body: body);

      // Remove from requests list
      joinRequests.removeWhere((request) => request['id'] == requestId);
      SnackBarUtils.showSuccessSnackBar("Request rejected");
    } catch (e) {
      CustomLogger.logMessage(msg: "Error rejecting request: $e", level: LogLevel.error);
    } finally {
      rejectingRequestId.value = '';
    }
  }
  /// Find Near By Players Api--------------------------------------------------
  Future<void> fetchNearByPlayers({String search = ''}) async {
    try {
      isLoadingNearbyPlayers.value = true;
      nearbyPlayers.clear();

      final response = await repository.findNearByPlayer(search: search);
      if(response.status == 200 && response.players != null){
        nearbyPlayers.value = response.players!.map((player) => {
          'id': player.id ?? '',
          'name': player.name ?? '',
          // 'lastName': player.lastName ?? '',
          'profilePic': player.profilePic ?? '',
          'city': player.city ?? '',
          'level': player.level ?? '',
          'totalMatchesPlayed': player.totalMatchesPlayed ?? '',
          'xpPoints': player.xpPoints ?? '',
        }).toList();
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching nearby players: $e", level: LogLevel.error);
    } finally {
      isLoadingNearbyPlayers.value = false;
    }
  }

  /// Create Scoreboard for Open Match--------------------------------------------------------
  Future<void> createScoreBoardForOpenMatch({required OpenMatchBookingData matchData}) async {
    try {
      final matchId = matchData.sId ?? '';
      if (matchId.isEmpty) {
        SnackBarUtils.showErrorSnackBar("Match ID not available");
        return;
      }

      // Check if logged-in user is part of the match (in teamA or teamB)
      final userId = storage.read('userId');
      if (userId == null) {
        SnackBarUtils.showErrorSnackBar("User not logged in");
        return;
      }

      bool isUserInMatch = false;
      
      // Check in teamA
      for (final player in matchData.teamA ?? []) {
        if (player.userId?.sId == userId) {
          isUserInMatch = true;
          break;
        }
      }

      // Check in teamB if not found in teamA
      if (!isUserInMatch) {
        for (final player in matchData.teamB ?? []) {
          if (player.userId?.sId == userId) {
            isUserInMatch = true;
            break;
          }
        }
      }

      // Only proceed if user is part of the match
      if (!isUserInMatch) {
        SnackBarUtils.showErrorSnackBar("You must be part of the match to create a scoreboard");
        return;
      }

      isCheckingScoreboard.value = true;
      loadingMatchId.value = matchId;

      // First, check if scoreboard already exists for this match
      final checkResponse = await scoreBoardRepository.getScoreBoard(bookingId: matchId);

      bool scoreboardExists = false;

      if (checkResponse.data != null) {
        if (checkResponse.data is List) {
          scoreboardExists = (checkResponse.data as List).isNotEmpty;
        } else {
          scoreboardExists = true;
        }
      }

      if (scoreboardExists) {
        isCheckingScoreboard.value = false;
        Get.toNamed(RoutesName.scoreBoard, arguments: {
          "bookingId": matchId,
          "openMatchId": matchId,
        });
        return;
      }

      // --- Create scoreboard ---
      final matchTimeStr = (matchData.matchTime?.isNotEmpty == true)
          ? matchData.matchTime!.first
          : (matchData.slot?.isNotEmpty == true &&
                  matchData.slot!.first.slotTimes?.isNotEmpty == true)
              ? matchData.slot!.first.slotTimes!.first.time ?? ""
              : "";

      final courtName = matchData.slot?.isNotEmpty == true
          ? matchData.slot!.first.courtName ?? ""
          : "";

      final clubName = matchData.clubId?.clubName ?? "";

      // Build teams from match data
      List<Map<String, dynamic>> teams = [];
      
      // Team A
      if (matchData.teamA?.isNotEmpty == true) {
        teams.add({
          "name": "Team A",
          "players": matchData.teamA!.map((player) => {
            "name": "${player.userId?.name ?? ''} ${player.userId?.lastName ?? ''}".trim(),
            "playerId": player.userId?.sId ?? "",
          }).toList(),
        });
      } else {
        teams.add({
          "name": "Team A",
          "players": [],
        });
      }

      // Team B
      if (matchData.teamB?.isNotEmpty == true) {
        teams.add({
          "name": "Team B",
          "players": matchData.teamB!.map((player) => {
            "name": "${player.userId?.name ?? ''} ${player.userId?.lastName ?? ''}".trim(),
            "playerId": player.userId?.sId ?? "",
          }).toList(),
        });
      } else {
        teams.add({
          "name": "Team B",
          "players": [],
        });
      }

      final body = {
        "bookingId": matchId,
        "matchDate": matchData.matchDate ?? "",
        "matchTime": matchTimeStr,
        "userId": storage.read("userId") ?? "",
        "courtName": courtName,
        "clubName": clubName,
        "openMatchId": matchId,
        "teams": teams,
      };

      final response = await scoreBoardRepository.createScoreBoard(data: body);

      isCheckingScoreboard.value = false;

      if (response.success == true) {
        Get.toNamed(RoutesName.scoreBoard, arguments: {
          "bookingId": matchId,
          "openMatchId": matchId,
        });
      }
    } catch (e) {
      isCheckingScoreboard.value = false;
      CustomLogger.logMessage(msg: "Error creating scoreboard: $e", level: LogLevel.error);
      SnackBarUtils.showErrorSnackBar("Failed to load or create scoreboard");
    } finally {
      loadingMatchId.value = '';
    }
  }
}