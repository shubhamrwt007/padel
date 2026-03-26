import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';

Future<void> showTeamsShuffleResultDialog({
  required ScoreBoardController controller,
  required String teamAResult,
  required String teamBResult,
}) async {
  // Determine user's team and result
  final isUserInTeamA = controller.isUserInTeamA;
  final isUserInTeamB = controller.isUserInTeamB;
  
  String userResult = "DRAW";
  if (isUserInTeamA) {
    userResult = teamAResult;
  } else if (isUserInTeamB) {
    userResult = teamBResult;
  }
  
  // Get XP text based on result
  String xpText = "";
  if (userResult == "WIN" && controller.xpEarned.value > 0) {
    xpText = "+${controller.xpEarned.value} XP";
  } else if (userResult == "LOSE" && controller.xpLost.value > 0) {
    xpText = "-${controller.xpLost.value} XP";
  } else if (userResult == "DRAW") {
    xpText = "0 XP";
  }
  
  return Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2F49C6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Teams Shuffled!",
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Previous match result:",
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyLarge?.copyWith(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      "Team A",
                      style: Get.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamAResult,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: teamAResult == "WIN" ? Colors.green : 
                               teamAResult == "LOSE" ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                Text(
                  "VS",
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "Team B",
                      style: Get.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamBResult,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: teamBResult == "WIN" ? Colors.green : 
                               teamBResult == "LOSE" ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (xpText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: userResult == "WIN" 
                    ? Colors.green.withOpacity(0.1)
                    : userResult == "LOSE"
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: userResult == "WIN" 
                      ? Colors.green
                      : userResult == "LOSE"
                        ? Colors.red
                        : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Text(
                  xpText,
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: userResult == "WIN" 
                      ? Colors.green
                      : userResult == "LOSE"
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F49C6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Continue",
                  style: Get.textTheme.labelLarge!.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );
}