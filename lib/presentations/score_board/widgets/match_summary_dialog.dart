import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

void showMatchSummaryDialog(ScoreBoardController controller) {
  // Determine if user is winner or loser
  final isUserWinner = _isUserWinner(controller);
  
  if (isUserWinner) {
    showWinnerDialog(controller);
  } else {
    showLoserDialog(controller);
  }
}

bool _isUserWinner(ScoreBoardController controller) {
  final winner = controller.winner.value;
  if (winner.isEmpty || winner.toLowerCase() == 'none' || winner == '-') {
    return false;
  }
  
  final isUserInTeamA = controller.isUserInTeamA;
  final isUserInTeamB = controller.isUserInTeamB;
  
  if (winner.toLowerCase() == 'team a' && isUserInTeamA) {
    return true;
  }
  if (winner.toLowerCase() == 'team b' && isUserInTeamB) {
    return true;
  }
  
  return false;
}

void showWinnerDialog(ScoreBoardController controller) {
  ProfileController? profileController;
  try {
    profileController = Get.find<ProfileController>();
  } catch (e) {
    // ProfileController not found, use default value
  }
  
  final initialXpPoints = profileController?.profileModel.value?.response?.xpPoints?.toInt() ?? 0;
  
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green WIN Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "WIN!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Congratulations text
                      const Text(
                        "Congratulations!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Your XP Points label
                      const Text(
                        "Your XP Points",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // XP Score (reactive if profileController exists)
                      profileController != null
                          ? Obx(() {
                              final xpPoints = profileController!.profileModel.value?.response?.xpPoints?.toInt() ?? 0;
                              return Text(
                                "$xpPoints",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            })
                          : Text(
                              "$initialXpPoints",
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                      const SizedBox(height: 16),
                      
                      // XP Bonus badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "+100 XP",
                          style: TextStyle(
                            fontSize: 16,
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
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    ),
    barrierDismissible: false,
  );
}

void showLoserDialog(ScoreBoardController controller) {
  ProfileController? profileController;
  try {
    profileController = Get.find<ProfileController>();
  } catch (e) {
    // ProfileController not found, use default value
  }
  
  final initialXpPoints = profileController?.profileModel.value?.response?.xpPoints?.toInt() ?? 0;
  
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red LOST Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "LOST",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bad Luck text
                      const Text(
                        "Bad Luck!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Your XP Points label
                      const Text(
                        "Your XP Points",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // XP Score (reactive if profileController exists)
                      profileController != null
                          ? Obx(() {
                              final xpPoints = profileController!.profileModel.value?.response?.xpPoints?.toInt() ?? 0;
                              return Text(
                                "$xpPoints",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            })
                          : Text(
                              "$initialXpPoints",
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                      const SizedBox(height: 16),
                      
                      // XP Deduction badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "-100 XP",
                          style: TextStyle(
                            fontSize: 16,
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
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    ),
    barrierDismissible: false,
  );
}
