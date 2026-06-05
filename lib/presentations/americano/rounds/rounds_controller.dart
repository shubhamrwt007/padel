import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/repositories/americano_repository/americano_repository.dart';
import 'package:padel_mobile/data/response_models/americano_models/americano_rounds_response.dart';
import 'package:padel_mobile/handler/logger.dart';

class RoundsController extends GetxController {
  final AmericanoRepository _repository = AmericanoRepository();

  final RxString americanoMatchId = "".obs;
  final RxBool isLoading = false.obs;
  final RxList<RoundData> roundsList = <RoundData>[].obs;
  final RxBool isMyBooking = false.obs;
  final ScrollController scrollController = ScrollController();

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      americanoMatchId.value = args['americanoMatchId'] ?? '';
      isMyBooking.value = args['filter'] == 'my_match';
    } else if (args != null && args is String) {
      americanoMatchId.value = args;
    }
    
    fetchRounds();
  }

  Future<void> fetchRounds() async {
    if (americanoMatchId.value.isEmpty) {
      CustomLogger.logMessage(
        msg: "RoundsController: americanoMatchId is empty",
        level: LogLevel.warning,
      );
      return;
    }

    isLoading.value = true;
    try {
      final filterVal = isMyBooking.value ? "my_match" : "all_matches";
      final response = await _repository.getAmericanoRounds(
        americanoMatchId.value,
        filter: filterVal,
      );
      if (response.success == true && response.data != null) {
        // Group matches by roundNo
        final Map<int, List<AmericanoRoundMatch>> groupedMatches = {};
        for (var match in response.data!) {
          final rNo = match.roundNo ?? 1;
          if (!groupedMatches.containsKey(rNo)) {
            groupedMatches[rNo] = [];
          }
          groupedMatches[rNo]!.add(match);
        }

        // Sort round numbers ascending
        final sortedRoundNos = groupedMatches.keys.toList()..sort();

        // Map to RoundData and MatchData
        final List<RoundData> loadedRounds = [];
        for (var rNo in sortedRoundNos) {
          final matchesInRound = groupedMatches[rNo]!;
          
          // Sort matches inside each round by matchNo/courtNo
          matchesInRound.sort((a, b) => (a.matchNo ?? 0).compareTo(b.matchNo ?? 0));

          final List<MatchData> mappedMatches = matchesInRound.map((m) {
            final teamAPlayers = m.teamA?.players ?? [];
            final teamBPlayers = m.teamB?.players ?? [];

            final player1A = teamAPlayers.isNotEmpty ? (teamAPlayers[0].fullName ?? "") : "";
            final player2A = teamAPlayers.length > 1 ? (teamAPlayers[1].fullName ?? "") : "";

            final player1B = teamBPlayers.isNotEmpty ? (teamBPlayers[0].fullName ?? "") : "";
            final player2B = teamBPlayers.length > 1 ? (teamBPlayers[1].fullName ?? "") : "";

            final List<String> avatarsA = teamAPlayers.map((p) {
              final pic = p.registerUserId?.profilePic;
              return pic ?? "";
            }).toList();

            final List<String> avatarsB = teamBPlayers.map((p) {
              final pic = p.registerUserId?.profilePic;
              return pic ?? "";
            }).toList();

            return MatchData(
              roundId: m.sId ?? "",
              americanoMatchId: m.americanoMatchId ?? "",
              status: m.status ?? "",
              courtName: m.courtNo != null ? "Court ${m.courtNo}" : "Court",
              player1SideA: player1A,
              player2SideA: player2A,
              player1SideB: player1B,
              player2SideB: player2B,
              avatarUrlsSideA: avatarsA,
              avatarUrlsSideB: avatarsB,
              scoreA: m.teamA?.points?.toString() ?? "0",
              scoreB: m.teamB?.points?.toString() ?? "0",
            );
          }).toList();

          loadedRounds.add(RoundData(
            title: "Round $rNo",
            matches: mappedMatches,
          ));
        }

        roundsList.assignAll(loadedRounds);
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching Americano rounds in controller: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

class RoundData {
  final String title;
  final List<MatchData> matches;

  const RoundData({
    required this.title,
    required this.matches,
  });
}

class MatchData {
  final String roundId;
  final String americanoMatchId;
  final String status;
  final String courtName;
  final String player1SideA;
  final String player2SideA;
  final String player1SideB;
  final String player2SideB;
  final List<String> avatarUrlsSideA;
  final List<String> avatarUrlsSideB;
  final String scoreA;
  final String scoreB;

  const MatchData({
    required this.roundId,
    required this.americanoMatchId,
    required this.status,
    required this.courtName,
    required this.player1SideA,
    required this.player2SideA,
    required this.player1SideB,
    required this.player2SideB,
    required this.avatarUrlsSideA,
    required this.avatarUrlsSideB,
    required this.scoreA,
    required this.scoreB,
  });
}