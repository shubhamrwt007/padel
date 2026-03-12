import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

void showMatchSummaryDialog(ScoreBoardController controller) {
  // Close any existing dialogs first
  if (Get.isDialogOpen == true) {
    Get.back();
  }
  
  // Add a small delay to ensure previous dialog is closed
  Future.delayed(const Duration(milliseconds: 100), () {
    final isUserWinner = _isUserWinner(controller);
    _showResultDialog(
      isWinner: isUserWinner,
      controller: controller,
    );
  });
}

// Helper function to reset the dialog flag
void _resetDialogFlag(ScoreBoardController controller) {
  controller.isShowingMatchSummary.value = false;
}

bool _isUserWinner(ScoreBoardController controller) {
  final winner = controller.winner.value;
  if (winner.isEmpty || winner == '-' || winner.toLowerCase() == 'none') {
    return false;
  }

  if (winner.toLowerCase() == 'team a' && controller.isUserInTeamA) {
    return true;
  }

  if (winner.toLowerCase() == 'team b' && controller.isUserInTeamB) {
    return true;
  }
  return false;
}

/// ------------------------------------------------------------
/// RESULT DIALOG (WIN / LOST)
/// ------------------------------------------------------------
void _showResultDialog({
  required bool isWinner,
  required ScoreBoardController controller,
}) {
  ProfileController? profileController;
  try {
    profileController = Get.find<ProfileController>();
  } catch (_) {}

  final initialXp =
      profileController?.profileModel.value?.response?.xpPoints?.toInt() ?? 0;

  final Color primaryColor =
  isWinner ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F);

  final String statusText = isWinner ? "WIN!" : "LOST";
  final String titleText =
  isWinner ? "Congratulations!" : "Better Luck Next Time!";
  final String badgeText = isWinner ? "+100 XP" : "-100 XP";

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
                  Get.back();
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
