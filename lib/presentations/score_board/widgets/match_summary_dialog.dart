import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

bool _isOpeningMatchSummaryDialog = false;
bool _isOpeningTeamsShuffleSummaryDialog = false;

Future<void> showMatchSummaryDialog(ScoreBoardController controller) async {
  print('🎭 ========== showMatchSummaryDialog CALLED ==========');
  print('🎭 _isOpeningMatchSummaryDialog: $_isOpeningMatchSummaryDialog');
  
  // Prevent stacking the same dialog multiple times due to rapid triggers
  if (_isOpeningMatchSummaryDialog) {
    print('⚠️ Dialog already opening, skipping');
    return;
  }
  _isOpeningMatchSummaryDialog = true;

  try {
    // Close any existing dialogs first
    if (Get.isDialogOpen == true) {
      print('🚪 Closing existing dialogs...');
      while (Get.isDialogOpen == true) {
        Get.back();
      }
      // Let the navigator settle before opening a new dialog
      await Future.delayed(const Duration(milliseconds: 50));
    }

    print('🔍 Getting match result...');
    final result = _getMatchResult(controller);
    print('🏆 Match result: $result');
    
    print('💬 Showing result dialog...');
    await _showResultDialog(
      result: result,
      controller: controller,
      resetDialogFlagOnClose: true,
    );
    print('✅ Dialog shown successfully');
  } catch (e, stackTrace) {
    print('❌ Error showing dialog: $e');
    print('❌ Stack trace: $stackTrace');
  } finally {
    _isOpeningMatchSummaryDialog = false;
    print('🎭 ========== showMatchSummaryDialog COMPLETED ==========');
  }
}

// Helper function to reset the dialog flag
void _resetDialogFlag(ScoreBoardController controller) {
  controller.isShowingMatchSummary.value = false;
}

enum _MatchResult { win, loss, draw }

_MatchResult _getMatchResult(ScoreBoardController controller) {
  print('🔍 ========== GET MATCH RESULT ==========');
  print('🔍 wasSwapDuringMatch: ${controller.wasSwapDuringMatch.value}');
  
  // If this is a swap during match, use xpChanges array to determine result
  if (controller.wasSwapDuringMatch.value) {
    print('🏆 SWAP DURING MATCH - Using XP changes to determine result');
    
    // Get current user ID
    final currentUserId = controller.currentUserId;
    print('👤 Current User ID: $currentUserId');
    
    // Check if we have XP values set (which means we found user in xpChanges)
    if (controller.xpEarned.value > 0) {
      print('✅ User WON - xpEarned: ${controller.xpEarned.value}');
      return _MatchResult.win;
    }
    
    if (controller.xpLost.value > 0) {
      print('❌ User LOST - xpLost: ${controller.xpLost.value}');
      return _MatchResult.loss;
    }
    
    // Fallback to old logic if XP not found
    print('⚠️ XP values not found, using fallback logic');
    print('🔍 preShuffleWinner: "${controller.preShuffleWinner.value}"');
    print('🔍 preShuffleTeamAWins: ${controller.preShuffleTeamAWins.value}');
    print('🔍 preShuffleTeamBWins: ${controller.preShuffleTeamBWins.value}');
    print('🔍 preShuffleUserInTeamA: ${controller.preShuffleUserInTeamA.value}');
    print('🔍 preShuffleUserInTeamB: ${controller.preShuffleUserInTeamB.value}');
    
    final preWinner = controller.preShuffleWinner.value.trim().toLowerCase().replaceAll(' ', '');
    
    // Check for draw first
    if (preWinner == 'draw' || preWinner == 'tie' || controller.preShuffleTeamAWins.value == controller.preShuffleTeamBWins.value) {
      print('🏆 Result: DRAW (equal scores or explicit draw)');
      return _MatchResult.draw;
    }
    
    // Use PRE-SHUFFLE team membership for determining win/loss
    final wasUserInTeamA = controller.preShuffleUserInTeamA.value;
    final wasUserInTeamB = controller.preShuffleUserInTeamB.value;
    
    // Determine winner based on pre-shuffle data
    if (preWinner == 'teama') {
      final result = wasUserInTeamA ? _MatchResult.win : _MatchResult.loss;
      print('🏆 Result: ${result == _MatchResult.win ? "WIN" : "LOSS"} (Team A won, user WAS in Team A: $wasUserInTeamA)');
      return result;
    }
    
    if (preWinner == 'teamb') {
      final result = wasUserInTeamB ? _MatchResult.win : _MatchResult.loss;
      print('🏆 Result: ${result == _MatchResult.win ? "WIN" : "LOSS"} (Team B won, user WAS in Team B: $wasUserInTeamB)');
      return result;
    }
    
    // Fallback: determine by scores
    if (controller.preShuffleTeamAWins.value > controller.preShuffleTeamBWins.value) {
      final result = wasUserInTeamA ? _MatchResult.win : _MatchResult.loss;
      print('🏆 Result: ${result == _MatchResult.win ? "WIN" : "LOSS"} (Team A won by score ${controller.preShuffleTeamAWins.value}-${controller.preShuffleTeamBWins.value}, user WAS in Team A: $wasUserInTeamA)');
      return result;
    } else if (controller.preShuffleTeamBWins.value > controller.preShuffleTeamAWins.value) {
      final result = wasUserInTeamB ? _MatchResult.win : _MatchResult.loss;
      print('🏆 Result: ${result == _MatchResult.win ? "WIN" : "LOSS"} (Team B won by score ${controller.preShuffleTeamBWins.value}-${controller.preShuffleTeamAWins.value}, user WAS in Team B: $wasUserInTeamB)');
      return result;
    } else {
      print('🏆 Result: DRAW (scores are equal)');
      return _MatchResult.draw;
    }
  }
  
  // Normal match completion flow
  final winnerRaw = controller.winner.value.trim();
  final winner = winnerRaw.toLowerCase();

  // API may explicitly send "draw"
  if (winner == 'draw' || winner == 'tie' || winner == 'tied' || winner == 'match draw') {
    return _MatchResult.draw;
  }

  final bool hasWinner =
      winnerRaw.isNotEmpty && winnerRaw != '-' && winner != 'none';

  // If backend doesn't declare a winner and total wins are equal, treat as draw.
  // This ensures both teams see "DRAW".
  if (!hasWinner && controller.teamAWins.value == controller.teamBWins.value) {
    return _MatchResult.draw;
  }

  if (winner == 'team a') {
    return controller.isUserInTeamA ? _MatchResult.win : _MatchResult.loss;
  }

  if (winner == 'team b') {
    return controller.isUserInTeamB ? _MatchResult.win : _MatchResult.loss;
  }

  // Another common backend format: "teamA"/"teamB"
  if (winner.replaceAll(' ', '') == 'teama') {
    return controller.isUserInTeamA ? _MatchResult.win : _MatchResult.loss;
  }
  if (winner.replaceAll(' ', '') == 'teamb') {
    return controller.isUserInTeamB ? _MatchResult.win : _MatchResult.loss;
  }

  // Fallback: if winner is unknown/unexpected, don't incorrectly mark WIN.
  return _MatchResult.loss;
}

/// ------------------------------------------------------------
/// RESULT DIALOG (WIN / LOST)
/// ------------------------------------------------------------
Future<void> _showResultDialog({
  required _MatchResult result,
  required ScoreBoardController controller,
  required bool resetDialogFlagOnClose,
}) {
  ProfileController? profileController;
  try {
    profileController = Get.find<ProfileController>();
  } catch (_) {}

  final initialXp =
      profileController?.profileModel.value?.response?.xpPoints?.toInt() ?? 0;

  final Color primaryColor = switch (result) {
    _MatchResult.win => const Color(0xFF4CAF50),
    _MatchResult.loss => const Color(0xFFD32F2F),
    _MatchResult.draw => const Color(0xFF607D8B),
  };

  final String statusText = switch (result) {
    _MatchResult.win => "WIN!",
    _MatchResult.loss => "LOST",
    _MatchResult.draw => "DRAW",
  };

  final String titleText = switch (result) {
    _MatchResult.win => "Congratulations!",
    _MatchResult.loss => "Better Luck Next Time!",
    _MatchResult.draw => "It’s a draw!",
  };

  final String badgeText = switch (result) {
    _MatchResult.win => controller.xpEarned.value > 0 ? "+${controller.xpEarned.value} XP" : "+100 XP",
    _MatchResult.loss => controller.xpLost.value > 0 ? "-${controller.xpLost.value} XP" : "-100 XP",
    _MatchResult.draw => "0 XP",
  };

  return Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          /// MAIN CARD
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TOP STATUS CONTAINER (INSIDE POPUP)
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
              ),

              /// BODY
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Your XP Points",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),

                    /// XP VALUE - Show currentXP from socket if available (swap scenario)
                    controller.wasSwapDuringMatch.value && controller.currentXP.value > 0
                        ? _xpText(controller.currentXP.value)
                        : (profileController != null
                            ? Obx(() {
                                final xp = profileController!
                                        .profileModel.value?.response?.xpPoints
                                        ?.toInt() ??
                                    0;
                                return _xpText(xp);
                              })
                            : _xpText(initialXp)),

                    const SizedBox(height: 18),

                    /// XP CHANGE BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// CLOSE BUTTON (INSIDE)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  if (resetDialogFlagOnClose) {
                    _resetDialogFlag(controller);
                  }
                  
                  // Check if this was a swap during match scenario
                  final wasSwapDuringMatch = controller.wasSwapDuringMatch.value;
                  
                  // Close dialog(s)
                  if (Get.isDialogOpen == true) {
                    while (Get.isDialogOpen == true) {
                      Get.back();
                    }
                  } else {
                    Get.back();
                  }
                  
                  // If it was a swap during match, reset the match
                  if (wasSwapDuringMatch) {
                    print('🔄 Swap during match detected, resetting match...');
                    await _restartMatchAfterSwap(controller);
                    controller.wasSwapDuringMatch.value = false;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    barrierDismissible: true,
  ).then((_) async {
    // Reset flag when dialog is dismissed by any means
    if (resetDialogFlagOnClose) {
      _resetDialogFlag(controller);
    }
    
    // Check if this was a swap during match scenario
    final wasSwapDuringMatch = controller.wasSwapDuringMatch.value;
    
    // If it was a swap during match, reset the match
    if (wasSwapDuringMatch) {
      print('🔄 Swap during match detected (on dismiss), resetting match...');
      await _restartMatchAfterSwap(controller);
      controller.wasSwapDuringMatch.value = false;
    }
  });
}

_MatchResult _parseTeamResult(String raw) {
  final v = raw.trim().toLowerCase();
  if (v == 'win' || v == 'won' || v.contains('win')) return _MatchResult.win;
  if (v == 'loss' || v == 'lose' || v.contains('loss') || v.contains('lose')) {
    return _MatchResult.loss;
  }
  return _MatchResult.draw;
}

/// Shows the same win/lose dialog UI twice: first for Team A, then Team B.
/// Used when teams are shuffled mid-match (check icon confirmation).
Future<void> showTeamsShuffleResultDialog({
  required ScoreBoardController controller,
  required String teamAResult,
  required String teamBResult,
}) async {
  if (_isOpeningTeamsShuffleSummaryDialog) return;
  _isOpeningTeamsShuffleSummaryDialog = true;

  try {
    await _showResultDialog(
      result: _parseTeamResult(teamAResult),
      controller: controller,
      resetDialogFlagOnClose: false,
    );
    await _showResultDialog(
      result: _parseTeamResult(teamBResult),
      controller: controller,
      resetDialogFlagOnClose: false,
    );
  } finally {
    _resetDialogFlag(controller);
    _isOpeningTeamsShuffleSummaryDialog = false;
  }
}

/// Reset match after swap during active match
Future<void> _restartMatchAfterSwap(ScoreBoardController controller) async {
  print('🔄 Starting match restart after swap...');
  
  // Stop the game timer if running
  if (controller.isGameStarted.value) {
    try {
      controller.isGameStarted.value = false;
      print('✅ Game stopped');
    } catch (e) {
      print('⚠️ Error stopping game: $e');
    }
  }

  // Clear all sets and scores locally
  controller.sets.clear();
  controller.sets.refresh();
  controller.teamAWins.value = 0;
  controller.teamBWins.value = 0;
  controller.winner.value = "";
  controller.isCompleted.value = false;
  controller.wasSwapDuringMatch.value = false;
  
  // CRITICAL: Reset XP values
  controller.xpEarned.value = 0;
  controller.xpLost.value = 0;
  controller.currentXP.value = 0;
  print('✅ XP values reset');
  
  print('✅ Local state cleared');

  // Reset the match state on the server
  try {
    final body = {
      "scoreboardId": controller.scoreboardId.value,
      "type": "reset"
    };
    final response = await controller.repository.updateScoreBoard(data: body);
    print('✅ Match reset API response: ${response.success}');
  } catch (e) {
    print('❌ Error resetting match on server: $e');
  }

  // Small delay to ensure server processes the reset
  await Future.delayed(const Duration(milliseconds: 300));

  // Fetch updated scoreboard to sync with server
  await controller.fetchScoreBoard(showLoader: false);
  print('✅ Scoreboard refreshed');
  
  // Restart countdown timer if within match time
  if (controller.isWithinMatchTime.value && !controller.isGameStarted.value) {
    controller.remainingSeconds.value = controller.calculateRemainingMatchTime();
    print('✅ Countdown timer restarted with ${controller.remainingSeconds.value} seconds');
  }
  
  print('🔄 Match restarted - ready for new game with new teams');
}

/// XP TEXT
Widget _xpText(int xp) {
  return Text(
    "$xp",
    style: const TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );
}

/// SWAP HISTORY DIALOG
Future<void> _showSwapHistoryDialog(ScoreBoardController controller) async {
  return Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2E5BFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: const Text(
                "Match History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            /// BODY
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: controller.swapHistory.map((swap) => _buildSwapHistoryItem(swap, const Color(0xFF2E5BFF))).toList(),
                ),
              ),
            ),
            
            /// CLOSE BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

/// SWAP HISTORY ITEM
Widget _buildSwapHistoryItem(Map<String, dynamic> swap, Color primaryColor) {
  final teams = swap['teams'] as List? ?? [];
  final sets = swap['sets'] as List? ?? [];
  final totalScore = swap['totalScore'] as Map? ?? {};
  final winner = swap['winner']?.toString() ?? '';
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teams and Score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Team A
            if (teams.isNotEmpty) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teams[0]['name'] ?? 'Team A',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...(teams[0]['players'] as List? ?? []).map((player) => Text(
                      player['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),
            ],
            
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${totalScore['teamA'] ?? 0} - ${totalScore['teamB'] ?? 0}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            
            // Team B
            if (teams.length > 1) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      teams[1]['name'] ?? 'Team B',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...(teams[1]['players'] as List? ?? []).map((player) => Text(
                      player['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    )),
                  ],
                ),
              )
            ],
          ],
        ),
        
        // Sets
        if (sets.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sets.map((set) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                'Set ${set['setNumber']}: ${set['teamAScore']}-${set['teamBScore']}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
            )).toList(),
          ),
        ],
        
        // Winner
        if (winner.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Winner: $winner',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ],
    ),
  );
}
