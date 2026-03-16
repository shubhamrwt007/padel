import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

bool _isOpeningMatchSummaryDialog = false;

Future<void> showMatchSummaryDialog(ScoreBoardController controller) async {
  // Prevent stacking the same dialog multiple times due to rapid triggers
  if (_isOpeningMatchSummaryDialog) return;
  _isOpeningMatchSummaryDialog = true;

  try {
    // Close any existing dialogs first
    if (Get.isDialogOpen == true) {
      while (Get.isDialogOpen == true) {
        Get.back();
      }
      // Let the navigator settle before opening a new dialog
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final result = _getMatchResult(controller);
    _showResultDialog(
      result: result,
      controller: controller,
    );
  } finally {
    _isOpeningMatchSummaryDialog = false;
  }
}

// Helper function to reset the dialog flag
void _resetDialogFlag(ScoreBoardController controller) {
  controller.isShowingMatchSummary.value = false;
}

enum _MatchResult { win, loss, draw }

_MatchResult _getMatchResult(ScoreBoardController controller) {
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
void _showResultDialog({
  required _MatchResult result,
  required ScoreBoardController controller,
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
    _MatchResult.win => "+100 XP",
    _MatchResult.loss => "-100 XP",
    _MatchResult.draw => "0 XP",
  };

  Get.dialog(
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

                    /// XP VALUE
                    profileController != null
                        ? Obx(() {
                      final xp = profileController!
                          .profileModel.value?.response?.xpPoints
                          ?.toInt() ??
                          0;
                      return _xpText(xp);
                    })
                        : _xpText(initialXp),

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
                onTap: () {
                  _resetDialogFlag(controller);
                  // If multiple dialogs got stacked for any reason, close all at once
                  if (Get.isDialogOpen == true) {
                    while (Get.isDialogOpen == true) {
                      Get.back();
                    }
                  } else {
                    Get.back();
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
  ).then((_) {
    // Reset flag when dialog is dismissed by any means
    _resetDialogFlag(controller);
  });
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
