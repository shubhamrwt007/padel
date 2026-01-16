import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';

void showMatchSummaryDialog(ScoreBoardController controller) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              "Match Completed!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Winner
            Obx(() => Text(
              "${controller.winner.value} Wins!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            )),
            const SizedBox(height: 24),
            
            // Final Score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Final Score",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    "${controller.teamAWins.value} - ${controller.teamBWins.value}",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Sets Summary
            Obx(() => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: controller.sets.map((set) {
                  final isTeamAWinner = set['winner'] == 'Team A';
                  final isTeamBWinner = set['winner'] == 'Team B';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Team A Score with Winner Indicator
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isTeamAWinner) ...[
                                const Icon(Icons.emoji_events, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                const Text('W', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                "${set['teamAScore']}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isTeamAWinner ? Colors.green : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Set Number
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            "Set ${set['setNumber']}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        // Team B Score with Winner Indicator
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "${set['teamBScore']}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isTeamBWinner ? Colors.green : Colors.black87,
                                ),
                              ),
                              if (isTeamBWinner) ...[
                                const SizedBox(width: 8),
                                const Text('W', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.emoji_events, color: Colors.green, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )),
            const SizedBox(height: 24),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
