import 'dart:developer';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/auth/sign_up/widgets/sign_up_exports.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/presentations/score_board/widgets/shimmer_widgets.dart';
import 'package:padel_mobile/presentations/score_board/widgets/app_players_bottomsheet.dart';

class ScoreBoardScreen extends StatelessWidget {
  final ScoreBoardController controller = Get.put(ScoreBoardController());

  ScoreBoardScreen({super.key});

  @override
  final RxBool isDragging = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() {
        final teamAPlayers = controller.teams.isNotEmpty
            ? controller.teams[0]["players"] as List
            : [];
        final teamBPlayers = controller.teams.length > 1
            ? controller.teams[1]["players"] as List
            : [];
        bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;

        // Hide button if all players added or in shuffle mode
        if (allPlayersAdded || controller.isShuffleMode.value) {
          return const SizedBox.shrink();
        }

        return controller.bookingType.value == "normal"
            ? GestureDetector(
          onTap: () {
            _showFindAPlayerDialog();
          },
          child: Container(
            height: 52,
            width: Get.width * 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E5BFF),
                  Color(0xFF1E3EBE),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Find players",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        )
            : const SizedBox.shrink();
      }),
      appBar: primaryAppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backGroundColor: AppColors.primaryColor,
          titleTextColor: Colors.white,
          leadingButtonColor: Colors.white,
          title: Text("Scoreboard"),
          centerTitle: true,
          action: [
            Obx(() => IconButton(
              icon: Icon(
                controller.isShuffleMode.value ? Icons.check : Icons.swap_horiz,
                color: controller.canSwapPlayers ? Colors.white : Colors.grey,
                size: 25,
              ),
              onPressed: controller.canSwapPlayers ? () {
                if (controller.isShuffleMode.value) {
                  controller.savePlayerSwaps();
                } else {
                  _showShuffleDialog();
                }
              } : null,
            )),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20,),
              onPressed: () => controller.shareScoreboard(context),
            ),
          ],
          context: context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: controller.scoreboardStream,
              builder: (context, snapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 120,
                          color: AppColors.primaryColor,
                          width: Get.width,
                        ),
                        Obx(() => controller.isLoading.value
                            ? BuildMatchCardShimmer().paddingOnly(left: 15, right: 15, top: 10)
                            : _buildMatchCard(context).paddingOnly(left: 15, right: 15, top: 10)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAddSetButton(),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (!controller.isGameStarted.value) {
                        return const SizedBox.shrink();
                      }
                      return controller.isLoading.value
                          ? BuildSetSectionShimmer().paddingOnly(left: 15, right: 15)
                          : _buildSetSection().paddingOnly(left: 15, right: 15);
                    }),

                    // Add bottom padding when in shuffle mode to prevent content from being hidden behind remove zone
                    Obx(() => controller.isShuffleMode.value
                        ? const SizedBox(height: 100)
                        : const SizedBox.shrink()),
                  ],
                );
              },
            ),
          ),

          // Remove Zones - Top Layer
          Obx(() => isDragging.value
              ? Positioned(
                  top: 0,
                  left: Get.width * 0.15,
                  right: Get.width * 0.15,
                  child: _buildRemoveZone(isTop: true),
                )
              : const SizedBox.shrink()),

          Obx(() => isDragging.value
              ? Positioned(
                  bottom: 20,
                  left: Get.width * 0.15,
                  right: Get.width * 0.15,
                  child: _buildRemoveZone(isTop: false),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              border: Border.all(color: AppColors.blackColor.withAlpha(10)),
              boxShadow: [
                BoxShadow(
                    color: AppColors.greyColor,
                    blurRadius: 0.5,
                    spreadRadius: 0.1,
                    offset: Offset(0, 2)
                )
              ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMatchHeader(context,),
              _buildPlayerRow(),
              const SizedBox(height: 10),
              Obx(() {
                final teamAPlayers = controller.teams.isNotEmpty
                    ? controller.teams[0]["players"] as List
                    : [];
                final teamBPlayers = controller.teams.length > 1
                    ? controller.teams[1]["players"] as List
                    : [];
                bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;

                return Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 30,
                        width: 70,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(),
                        decoration: BoxDecoration(
                          color: controller.isCompleted.value
                              ? Colors.grey
                              : (allPlayersAdded && !controller.isShuffleMode.value
                              ? (controller.isGameStarted.value ? AppColors.secondaryColor : Colors.orange)
                              : Colors.orange),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() => Center(
                              child: Text(
                                controller.formattedTime,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )),
                            Text(
                              controller.isCompleted.value
                                  ? ""
                                  : (controller.isShuffleMode.value
                                  ? ""
                                  : (allPlayersAdded
                                  ? (controller.isGameStarted.value ? "" : "")
                                  : "")),
                              style: Get.textTheme.labelSmall!.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.isShuffleMode.value && !controller.isGameStarted.value)
                        Positioned.fill(
                          child: DragTarget<Map<String, dynamic>>(
                            onAccept: (data) {
                              final playerId = data['player']['playerId'];
                              final playerName = controller.capitalizeFirstWord(
                                data['player']['name'].toString().split(' ').first.trim()
                              );
                              final team = data['team'];
                              
                              Get.dialog(
                                AlertDialog(
                                  title: const Text('Remove Player'),
                                  content: Text('Remove $playerName from the match?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Get.back();
                                        await controller.removePlayer(playerId, team);
                                      },
                                      child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isActive = candidateData.isNotEmpty;
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isActive ? 1.0 : 0.0,
                                child: IgnorePointer(
                                  ignoring: !isActive,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddSetButton() {
    return Obx(() {
      final teamAPlayers = controller.teams.isNotEmpty
          ? controller.teams[0]["players"] as List
          : [];
      final teamBPlayers = controller.teams.length > 1
          ? controller.teams[1]["players"] as List
          : [];
      bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;

      bool inShuffleMode = controller.isShuffleMode.value;
      bool isGameStarted = controller.isGameStarted.value;
      bool isWithinMatchTime = controller.isWithinMatchTime.value;
      bool isCompleted = controller.isCompleted.value;

      bool isStartGameDisabled = !allPlayersAdded || !isWithinMatchTime || isCompleted;
      bool isAddSetDisabled = !isGameStarted || controller.sets.length >= 10 || isCompleted;

      bool isDisabled = inShuffleMode || isGameStarted
          ? isAddSetDisabled
          : isStartGameDisabled;

      String buttonText = "";
      if (inShuffleMode) {
        buttonText = "Start Game";
      } else {
        buttonText = isGameStarted ? "+ Add Set" : "Start Game";
      }

      String? disabledReason;
      if (isCompleted) {
        disabledReason = "Game completed";
      } else if (!allPlayersAdded) {
        disabledReason = "Add all 4 players";
      } else if (!isWithinMatchTime && !isGameStarted) {
        disabledReason = "Match has not started yet";
      }

      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey : AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: isDisabled
                  ? null
                  : () async {
                if (isCompleted) {
                  SnackBarUtils.showErrorSnackBar("Game is already completed");
                  return;
                }

                if (inShuffleMode) {
                  await controller.savePlayerSwaps();
                } else if (!isGameStarted) {
                  await controller.startGame();
                } else {
                  if (controller.sets.length >= 10) {
                    SnackBarUtils.showErrorSnackBar("Maximum 10 sets allowed");
                    return;
                  }
                  await controller.addSet();
                }
              },
              child: Obx(() => controller.isAddingSet.value
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: LoadingWidget(color: Colors.white),
              )
                  : Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              )),
            ),
          ),
          if (disabledReason != null && isDisabled)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Text(
                disabledReason,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    });
  }

  /// Get formatted time range with proper end time fallback
  String _getFormattedTimeRange(ScoreBoardController controller) {
    final startTimeStr = controller.startTime.value.isNotEmpty 
        ? _formatTimeWithMinutes(controller.startTime.value)
        : '';
    
    // Use endTime.value if available, otherwise fall back to matchEndTime
    String endTimeStr = '';
    if (controller.endTime.value.isNotEmpty) {
      endTimeStr = _formatTimeWithMinutes(controller.endTime.value);
    } else if (controller.matchEndTime.isNotEmpty) {
      endTimeStr = _formatTimeWithMinutes(controller.matchEndTime);
    }
    
    if (startTimeStr.isEmpty) return '';
    if (endTimeStr.isEmpty) return startTimeStr;
    return '$startTimeStr - $endTimeStr';
  }

  /// Format time while preserving minutes (e.g., "1:30 pm" stays "1:30 PM", "1 pm" becomes "1:00 PM")
  String _formatTimeWithMinutes(String timeStr) {
    if (timeStr.isEmpty) return '';
    
    try {
      final normalized = timeStr.trim();
      final lower = normalized.toLowerCase();
      
      // Check if it already has minutes
      if (normalized.contains(':')) {
        // Already has minutes, just normalize AM/PM
        return normalized.replaceAllMapped(
          RegExp(r'(am|pm)', caseSensitive: false),
          (match) => match.group(0)!.toUpperCase(),
        );
      }
      
      // No minutes, format to :00
      final parts = lower.split(' ');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final period = parts[1].toUpperCase();
        if (hour > 0) {
          return '$hour:00 $period';
        }
      }
      
      return normalized;
    } catch (e) {
      return timeStr;
    }
  }

  Widget _buildMatchHeader(BuildContext context,) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              color: Colors.transparent,
              width: Get.width * 0.58,
              child: Obx(() {
                String raw = controller.matchDate.value.toString().trim();

                DateTime? date;
                try {
                  date = DateTime.parse(raw);
                } catch (e) {
                  log("DATE PARSE ERROR: '$raw'");
                  date = null;
                }

                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: date != null ? "${DateFormat('EEEE').format(date)} " : "Invalid Date ",
                        style: Get.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 13
                        ),
                      ),
                      TextSpan(
                        text: date != null
                            ? "${DateFormat('dd MMM').format(date)} | ${_getFormattedTimeRange(controller)}"
                            : "| ${_getFormattedTimeRange(controller)}",
                        style: Get.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 13
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            Obx(
                  () => Container(
                width: Get.width * 0.3,
                alignment: AlignmentGeometry.centerRight,
                color: Colors.transparent,
                child: Text(
                  overflow: TextOverflow.ellipsis,
                  controller.clubName.value,
                  style: Get.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => controller.matchStatus.value
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFD6E0FF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(controller.matchType.value, style: Get.textTheme.labelMedium),
                  const SizedBox(width: 4),
                  const Icon(Icons.lock_outline, size: 16, color: AppColors.primaryColor),
                ],
              ),
            )
                : PopupMenuButton<String>(
              onSelected: (String newValue) {
                controller.updateMatchType(newValue);
              },
              itemBuilder: (BuildContext context) => ["Friendly", "Competitive"].map((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  height: 40,
                  child: Text(value, style: Get.textTheme.labelMedium),
                );
              }).toList(),
              offset: Offset(0, 30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.matchType.value, style: Get.textTheme.labelMedium),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primaryColor),
                  ],
                ),
              ),
            )),
            Transform.translate(
              offset: Offset(0, -10),
              child: Text(
                controller.courtName.value,
                style: Get.textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ).paddingOnly(top: 5)
      ],
    ).paddingOnly(bottom: 8);
  }

  Widget _buildPlayerRow() {
    return Obx(() {
      log("=== BUILDING PLAYER ROW ===");
      log("Teams count: ${controller.teams.length}");

      final teamAPlayers = controller.teams.isNotEmpty
          ? controller.teams[0]["players"] as List
          : [];

      log("Team A players: ${teamAPlayers.length}");
      for (int i = 0; i < teamAPlayers.length; i++) {
        log("  Team A Player $i: ${teamAPlayers[i]['name']}");
      }

      final teamBPlayers = controller.teams.length > 1
          ? controller.teams[1]["players"] as List
          : [];

      log("Team B players: ${teamBPlayers.length}");
      for (int i = 0; i < teamBPlayers.length; i++) {
        log("  Team B Player $i: ${teamBPlayers[i]['name']}");
      }

      bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;
      if (allPlayersAdded) {
        return _buildAllPlayersView(teamAPlayers, teamBPlayers);
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerSlot(teamAPlayers, 0, "teamA"),
            _buildPlayerSlot(teamAPlayers, 1, "teamA"),
            Container(
              width: 1,
              color: AppColors.blackColor.withAlpha(50),
            ).paddingOnly(bottom: 25),
            _buildPlayerSlot(teamBPlayers, 0, "teamB"),
            _buildPlayerSlot(teamBPlayers, 1, "teamB"),
          ],
        ),
      );
    });
  }

  Widget _buildAllPlayersView(List teamAPlayers, List teamBPlayers) {
    return Obx(() => controller.isShuffleMode.value
        ? _buildShuffleView(teamAPlayers, teamBPlayers)
        : _buildNormalView(teamAPlayers, teamBPlayers));
  }

  Widget _buildShuffleView(List teamAPlayers, List teamBPlayers) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Obx(() {
                  bool isWinner = controller.isCompleted.value &&
                      controller.winner.value == "Team A";
                  bool isLoser = controller.isCompleted.value &&
                      controller.winner.value == "Team B";

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isWinner)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      if (isWinner) const SizedBox(width: 8),
                      Text(
                        "Team A",
                        style: Get.textTheme.headlineLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isWinner
                              ? Colors.amber
                              : isLoser
                              ? Colors.grey
                              : AppColors.primaryColor,
                        ),
                      ),
                      if (isLoser) const SizedBox(width: 8),
                      if (isLoser)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sentiment_dissatisfied,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                ...teamAPlayers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return Column(
                    children: [
                      _buildShufflePlayerItem(player, index, 'Team A'),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                // Add empty slots
                ...List.generate(2 - teamAPlayers.length, (index) {
                  return Column(
                    children: [
                      _buildEmptyShuffleSlot('Team A', teamAPlayers.length + index),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],
            ),
          ),
          Container(
            width: 80,
            child: Text(
              "${controller.teamAWins.value}:${controller.teamBWins.value}",
              textAlign: TextAlign.center,
              style: Get.textTheme.displaySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                  fontSize: 26
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Obx(() {
                  bool isWinner = controller.isCompleted.value &&
                      controller.winner.value == "Team B";
                  bool isLoser = controller.isCompleted.value &&
                      controller.winner.value == "Team A";

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isWinner)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      if (isWinner) const SizedBox(width: 8),
                      Text(
                        "Team B",
                        style: Get.textTheme.headlineLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isWinner
                              ? Colors.amber
                              : isLoser
                              ? Colors.grey
                              : AppColors.primaryColor,
                        ),
                      ),
                      if (isLoser) const SizedBox(width: 8),
                      if (isLoser)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sentiment_dissatisfied,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                ...teamBPlayers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return Column(
                    children: [
                      _buildShufflePlayerItem(player, index, 'Team B'),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                // Add empty slots
                ...List.generate(2 - teamBPlayers.length, (index) {
                  return Column(
                    children: [
                      _buildEmptyShuffleSlot('Team B', teamBPlayers.length + index),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyShuffleSlot(String team, int index) {
    return DragTarget<Map<String, dynamic>>(
      onAccept: (data) {
        controller.movePlayerToEmptySlot(data['player']['playerId'], team, index);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: candidateData.isNotEmpty
              ? (Matrix4.identity()..scale(1.1))
              : Matrix4.identity(),
          width: 60,
          child: Column(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: candidateData.isNotEmpty
                      ? AppColors.primaryColor.withOpacity(0.3)
                      : AppColors.textFieldColor,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: candidateData.isNotEmpty
                      ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.5),
                      blurRadius: 7,
                      spreadRadius: 0.4,
                    ),
                  ]
                      : [],
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Available",
                style: Get.textTheme.bodySmall!.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingRemoveZone() {
    return Positioned(
      bottom: 0,
      left: 20,
      right: 20,
      child: DragTarget<Map<String, dynamic>>(
        onAccept: (data) {
          final playerId = data['player']['playerId'];
          final playerName = controller.capitalizeFirstWord(
            data['player']['name'].toString().split(' ').first.trim()
          );
          final team = data['team'];
          
          Get.dialog(
            AlertDialog(
              title: const Text('Remove Player'),
              content: Text('Remove $playerName from the match?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Get.back();
                    await controller.removePlayer(playerId, team);
                  },
                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isActive,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ] : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemoveZone({required bool isTop}) {
    return DragTarget<Map<String, dynamic>>(
      onAccept: (data) {
        final playerId = data['player']['playerId'];
        final playerName = controller.capitalizeFirstWord(
          data['player']['name'].toString().split(' ').first.trim()
        );
        final team = data['team'];
        
        Get.dialog(
          AlertDialog(
            title: const Text('Remove Player'),
            content: Text('Remove $playerName from the match?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await controller.removePlayer(playerId, team);
                },
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isActive ? 70 : 50,
          decoration: BoxDecoration(
            color: isActive ? Colors.red.withOpacity(0.9) : Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive ? [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ] : [],
          ),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.2 : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: Colors.white,
                    size: isActive ? 28 : 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'Drop to Remove' : 'Drag here to remove',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isActive ? 16 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShufflePlayerItem(Map<String, dynamic> player, int index, String team) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Draggable<Map<String, dynamic>>(
          data: {'player': player, 'team': team, 'index': index},
          onDragStarted: () => isDragging.value = true,
          onDragEnd: (_) => isDragging.value = false,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 60,
              child: Column(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textFieldColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shuffle, color: AppColors.primaryColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Container(
            width: 60,
            child: Column(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: const Icon(Icons.more_horiz, color: Colors.grey, size: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.capitalizeFirstWord(player["name"].toString().split(' ').first.trim()),
                  style: Get.textTheme.bodySmall!.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          child: DragTarget<Map<String, dynamic>>(
            onAccept: (data) {
              if (data['player']['playerId'] != player['playerId']) {
                controller.swapPlayers(data['player']['playerId'], team, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: candidateData.isNotEmpty
                    ? (Matrix4.identity()..scale(1.1))
                    : Matrix4.identity(),
                width: 60,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.5),
                            blurRadius: 7,
                            spreadRadius: 0.4,
                          ),
                        ],
                      ),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: candidateData.isNotEmpty
                              ? AppColors.primaryColor.withOpacity(0.3)
                              : AppColors.textFieldColor,
                        ),
                        child: (player["pic"] != null && player["pic"].toString().isNotEmpty)
                            ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player["pic"],
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                height: 15,
                                width: 15,
                                child: LoadingWidget(color: AppColors.primaryColor),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                getNameInitials(player["name"], player["lastName"]),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                            : Center(
                          child: Text(
                            getNameInitials(player["name"], player["lastName"]),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.capitalizeFirstWord(player["name"].toString().split(' ').first.trim()),
                      style: Get.textTheme.bodySmall!.copyWith(
                        color: AppColors.textColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNormalView(List teamAPlayers, List teamBPlayers) {
    return Column(
      children: [
        Container(
          width: Get.width,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildOverlappingAvatar(teamAPlayers[0], 0, 'Team A'),
                    Positioned(
                      left: 35,
                      child: _buildOverlappingAvatar(teamAPlayers[1], 1, 'Team A'),
                    ),
                  ],
                ),
              ).paddingOnly(left: 10),
              Text(
                "${controller.teamAWins.value} : ${controller.teamBWins.value}",
                style: Get.textTheme.displaySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                    fontSize: 28
                ),
              ).paddingOnly(left: 30),
              SizedBox(
                width: 100,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildOverlappingAvatar(teamBPlayers[0], 0, 'Team B'),
                    Positioned(
                      left: 35,
                      child: _buildOverlappingAvatar(teamBPlayers[1], 1, 'Team B'),
                    ),
                  ],
                ),
              ).paddingOnly(left: 40),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                children: [
                  Obx(() {
                    bool isWinner = controller.isCompleted.value &&
                        controller.winner.value == "Team A";
                    bool isLoser = controller.isCompleted.value &&
                        controller.winner.value == "Team B";

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isWinner)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 20,
                            ),
                          ),
                        if (isWinner) const SizedBox(width: 8),
                        Text(
                          "Team A",
                          style: Get.textTheme.headlineLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isWinner
                                ? Colors.amber
                                : isLoser
                                ? Colors.grey
                                : AppColors.primaryColor,
                          ),
                        ),
                        if (isLoser) const SizedBox(width: 8),
                        if (isLoser)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sentiment_dissatisfied,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                      ],
                    );
                  }),
                  // Winner/Loser text
                  Obx(() {
                    bool isWinner = controller.isCompleted.value &&
                        controller.winner.value == "Team A";
                    bool isLoser = controller.isCompleted.value &&
                        controller.winner.value == "Team B";
                    
                    if (isWinner) {
                      return Text(
                        "Winner",
                        style: Get.textTheme.bodySmall!.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else if (isLoser) {
                      return Text(
                        "-",
                        style: Get.textTheme.bodySmall!.copyWith(
                          color: Colors.grey,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  Text(
                    controller.capitalizeFirstWord(teamAPlayers[0]["name"].toString().split(' ').first.trim()),
                    textAlign: TextAlign.center,
                    style: Get.textTheme.bodySmall!.copyWith(
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    controller.capitalizeFirstWord(teamAPlayers[1]["name"].toString().split(' ').first.trim()),
                    textAlign: TextAlign.center,
                    style: Get.textTheme.bodySmall!.copyWith(
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 50),
            Expanded(
              child: Column(
                children: [
                  Obx(() {
                    bool isWinner = controller.isCompleted.value &&
                        controller.winner.value == "Team B";
                    bool isLoser = controller.isCompleted.value &&
                        controller.winner.value == "Team A";

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isWinner)
                          Image.asset(Assets.imagesIcCrown, scale: 3),
                        if (isWinner) const SizedBox(width: 8),
                        Text(
                          "Team B",
                          style: Get.textTheme.headlineLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isWinner
                                ? Colors.amber
                                : isLoser
                                ? Colors.grey
                                : AppColors.primaryColor,
                          ),
                        ),
                        if (isLoser) const SizedBox(width: 8),
                        if (isLoser)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sentiment_dissatisfied,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                      ],
                    );
                  }),
                  // Winner/Loser text for Team B
                  Obx(() {
                    bool isWinner = controller.isCompleted.value &&
                        controller.winner.value == "Team B";
                    bool isLoser = controller.isCompleted.value &&
                        controller.winner.value == "Team A";
                    
                    if (isWinner) {
                      return Text(
                        "Winner",
                        style: Get.textTheme.bodySmall!.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    } else if (isLoser) {
                      return Text(
                        "-",
                        style: Get.textTheme.bodySmall!.copyWith(
                          color: Colors.grey,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  // Show player names only if not loser
                  Obx(() {
                    bool isLoser = controller.isCompleted.value &&
                        controller.winner.value == "Team A";
                    
                    if (isLoser) {
                      return const SizedBox.shrink();
                    }
                    
                    return Column(
                      children: [
                        Text(
                          controller.capitalizeFirstWord(teamBPlayers[0]["name"].toString().split(' ').first.trim()),
                          textAlign: TextAlign.center,
                          style: Get.textTheme.bodySmall!.copyWith(
                            color: AppColors.textColor,
                          ),
                        ),
                        Text(
                          controller.capitalizeFirstWord(teamBPlayers[1]["name"].toString().split(' ').first.trim()),
                          textAlign: TextAlign.center,
                          style: Get.textTheme.bodySmall!.copyWith(
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverlappingAvatar(Map<String, dynamic> player, int index, String team) {
    return Obx(() => controller.isShuffleMode.value && controller.canSwapPlayers
        ? Draggable<Map<String, dynamic>>(
      data: {'player': player, 'team': team, 'index': index},
      onDragStarted: () => isDragging.value = true,
      onDragEnd: (_) => isDragging.value = false,
      feedback: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textFieldColor,
          border: Border.all(color: AppColors.whiteColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.shuffle, color: AppColors.primaryColor, size: 25),
      ),
      childWhenDragging: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 65,
        width: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.3),
          border: Border.all(color: AppColors.whiteColor, width: 2),
        ),
        child: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
      ),
      child: DragTarget<Map<String, dynamic>>(
        onAccept: (data) {
          if (data['player']['playerId'] != player['playerId']) {
            controller.swapPlayers(data['player']['playerId'], team, index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: candidateData.isNotEmpty
                ? (Matrix4.identity()..scale(1.1))
                : Matrix4.identity(),
            child: _buildAvatarContainer(player, candidateData.isNotEmpty),
          );
        },
      ),
    )
        : _buildAvatarContainer(player, false));
  }

  Widget _buildAvatarContainer(Map<String, dynamic> player, bool isHovered) {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHovered
            ? AppColors.primaryColor.withOpacity(0.3)
            : AppColors.textFieldColor,
        border: Border.all(color: AppColors.whiteColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => controller.isShuffleMode.value
          ? Stack(
        children: [
          if (player["pic"] != null && player["pic"].toString().isNotEmpty)
            ClipOval(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: player["pic"],
                  fit: BoxFit.cover,
                  width: 65,
                  height: 65,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: LoadingWidget(color: AppColors.primaryColor),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryColor,
                      size: 30,
                    ),
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text(
                          getNameInitials(player["name"], player["lastName"]),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shuffle,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
        ],
      )
          : (player["pic"] != null && player["pic"].toString().isNotEmpty)
          ? ClipOval(
        child: CachedNetworkImage(
          imageUrl: player["pic"],
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: LoadingWidget(color: AppColors.primaryColor),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.person,
            color: AppColors.primaryColor,
            size: 30,
          ),
        ),
      )
          : Center(
        child: Text(
          getNameInitials(player["name"], player["lastName"]),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      )),
    );
  }

  Widget _buildPlayerSlot(List players, int index, String teamName) {
    bool hasPlayer = index < players.length;

    return GestureDetector(
      onTap: () {
        if (!hasPlayer) {
          log("Opening bottomsheet - scoreboardId: ${controller.scoreboardId.value}, openMatchId: ${controller.openMatchId.value}, bookingId: ${controller.bookingId.value}, bookingType: ${controller.bookingType.value}");
          Get.bottomSheet(
            AppPlayersBottomSheetScore(
              matchId: controller.bookingId.value,
              teamName: teamName,
              openMatchId: controller.openMatchId.value,
              bookingId: controller.bookingId.value,
              bookingType: controller.bookingType.value,
              currentPlayerIds: controller.currentPlayerIds,
            ),
            isScrollControlled: true,
          );
        }
      },
      child: Column(
        children: [
          Obx(() => controller.isShuffleMode.value && hasPlayer && controller.canSwapPlayers
              ? Draggable<Map<String, dynamic>>(
            data: {'player': players[index], 'team': teamName, 'index': index},
            onDragStarted: () => isDragging.value = true,
            onDragEnd: (_) => isDragging.value = false,
            feedback: Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textFieldColor,
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: const Icon(Icons.shuffle, color: AppColors.primaryColor, size: 20),
            ),
            childWhenDragging: Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.3),
                border: Border.all(color: AppColors.primaryColor),
              ),
            ),
            child: DragTarget<Map<String, dynamic>>(
              onAccept: (data) {
                if (data['player']['playerId'] != players[index]['playerId']) {
                  controller.swapPlayers(data['player']['playerId'], teamName, index);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return _buildPlayerSlotContainer(players, index, hasPlayer, candidateData.isNotEmpty);
              },
            ),
          )
              : controller.isShuffleMode.value && !hasPlayer && controller.canSwapPlayers
              ? DragTarget<Map<String, dynamic>>(
            onAccept: (data) {
              controller.movePlayerToEmptySlot(data['player']['playerId'], teamName, index);
            },
            builder: (context, candidateData, rejectedData) {
              return _buildPlayerSlotContainer(players, index, hasPlayer, candidateData.isNotEmpty);
            },
          )
              : _buildPlayerSlotContainer(players, index, hasPlayer, false)),
          SizedBox(
            width: Get.width * 0.13,
            child: Text(
              hasPlayer
                  ? controller.capitalizeFirstWord(players[index]["name"].toString().split(' ').first.trim())
                  : "Available",
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Get.textTheme.bodySmall!.copyWith(
                color: AppColors.primaryColor,
                fontSize: 11,
              ),
            ).paddingOnly(top: Get.height * 0.003),
          ),
          hasPlayer
              ? Container(
            height: 17,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.secondaryColor.withAlpha(20),
            ),
            child: Text(
              players[index]["level"] ?? "-",
              style: Get.textTheme.labelMedium!.copyWith(color: AppColors.secondaryColor),
            ),
          ).paddingOnly(top: 4)
              : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _buildPlayerSlotContainer(List players, int index, bool hasPlayer, bool isHovered) {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHovered
            ? AppColors.primaryColor.withOpacity(0.3)
            : hasPlayer
            ? AppColors.primaryColor.withValues(alpha: 0.1)
            : controller.isShuffleMode.value
            ? AppColors.secondaryColor.withOpacity(0.1)
            : Colors.white,
        border: Border.all(
          color: hasPlayer
              ? Colors.transparent
              : controller.isShuffleMode.value
              ? AppColors.secondaryColor
              : AppColors.primaryColor,
          style: controller.isShuffleMode.value && !hasPlayer
              ? BorderStyle.solid
              : BorderStyle.solid,
        ),
      ),
      child: hasPlayer
          ? Obx(() => controller.isShuffleMode.value
          ? Stack(
        children: [
          if (players[index]["pic"] != null && players[index]["pic"].toString().isNotEmpty)
            ClipOval(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: players[index]["pic"],
                  fit: BoxFit.cover,
                  width: 65,
                  height: 65,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      height: 25,
                      width: 25,
                      child: LoadingWidget(color: AppColors.primaryColor),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryColor,
                      size: 30,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: Text(
                  getNameInitials(players[index]["name"], players[index]["lastName"]),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          const Center(
            child: Icon(
              Icons.shuffle,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      )
          : (players[index]["pic"] != null && players[index]["pic"].toString().isNotEmpty)
          ? ClipOval(
        child: CachedNetworkImage(
          imageUrl: players[index]["pic"],
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: LoadingWidget(color: AppColors.primaryColor),
            ),
          ),
          errorWidget: (context, url, error) => const Icon(
            Icons.person,
            color: AppColors.primaryColor,
            size: 30,
          ),
        ),
      )
          : Center(
        child: Text(
          getNameInitials(players[index]["name"], players[index]["lastName"]),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ))
          : Obx(() => controller.isShuffleMode.value
          ? Stack(
        children: [
          Center(
            child: const Icon(
              Icons.add,
              size: 24,
              color: AppColors.primaryColor,
            ),
          ),
          if (isHovered)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryColor.withOpacity(0.3),
              ),
              child: const Icon(
                Icons.move_down,
                color: AppColors.secondaryColor,
                size: 20,
              ),
            ),
        ],
      )
          : const Icon(
        Icons.add,
        size: 24,
        color: AppColors.primaryColor,
      )),
    );
  }

  Widget _buildAddScoreButton() {
    return Obx(() {
      final teamAPlayers = controller.teams.isNotEmpty
          ? controller.teams[0]["players"] as List
          : [];
      final teamBPlayers = controller.teams.length > 1
          ? controller.teams[1]["players"] as List
          : [];
      bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;

      bool isUserInMatch = controller.isUserInTeamA || controller.isUserInTeamB;

      bool canUserTeamScore = controller.sets.any((set) {
        if (controller.isUserInTeamA) {
          return (set["teamAScore"] ?? 0) == 0;
        } else if (controller.isUserInTeamB) {
          return (set["teamBScore"] ?? 0) == 0;
        }
        return false;
      });

      bool isDisabled = controller.isCompleted.value || !allPlayersAdded || !isUserInMatch || !canUserTeamScore;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? Colors.grey : AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: isDisabled ? null : () {
            Get.dialog(const SetScoreDialog());
          },
          child: const Text(
            "+ Add Score",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  Widget buildAddSetButton() {
    return Obx(() {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            if (controller.isCompleted.value) {
              SnackBarUtils.showErrorSnackBar("Game is already completed");
              return;
            }

            if (controller.sets.length >= 10) {
              SnackBarUtils.showErrorSnackBar("Maximum 10 sets allowed");
              return;
            }

            final teamAPlayers = controller.teams.isNotEmpty
                ? controller.teams[0]["players"] as List
                : [];
            final teamBPlayers = controller.teams.length > 1
                ? controller.teams[1]["players"] as List
                : [];
            bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;

            if (!allPlayersAdded) {
              if (Get.isSnackbarOpen) return;
              SnackBarUtils.showErrorSnackBar("Please add all players before adding a set");
              return;
            }

            controller.addSet();
          },
          child: controller.isAddingSet.value
              ? const SizedBox(
            height: 20,
            width: 20,
            child: LoadingWidget(color: Colors.white),
          )
              : const Text(
            "Start Game",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  void _showShuffleDialog() {
    Get.dialog(
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
                    color: Color(0xFF2F49C6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
                "Shuffle Players?",
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "If you shuffle the teams, the score will reset to zero and XP points will be calculated from the beginning.",
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyLarge?.copyWith(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                          "Cancel",
                          style: Get.textTheme.labelLarge!.copyWith(color: Colors.black87)
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.isShuffleMode.value = true;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F49C6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text("Ok", style: Get.textTheme.labelLarge!.copyWith(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showFindAPlayerDialog() {
    Get.dialog(
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
                      color: Color(0xFF2F49C6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ]
                  ),
                  child: Transform.scale(
                      scale: 0.5,
                      child: SvgPicture.asset(Assets.imagesIcPadelIcon, height: 20, width: 20, color: Colors.white,))
              ),
              const SizedBox(height: 20),
              Text(
                "Convert to Open Match",
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Do you want to convert your booking to an open match? By converting, your match will be open to online players and you'll be able to play with others.",
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyLarge?.copyWith(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                          "Cancel",
                          style: Get.textTheme.labelLarge!.copyWith(color: Colors.black87)
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.convertToOpenMatch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F49C6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Obx(() => controller.isConvertingToOpenMatch.value
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: LoadingWidget(color: Colors.white),
                      )
                          : Text("Convert", style: Get.textTheme.labelLarge!.copyWith(color: Colors.white))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildTeamAddScoreButton(String team, int setNumber) {
    final teamAPlayers = controller.teams.isNotEmpty
        ? controller.teams[0]["players"] as List
        : [];
    final teamBPlayers = controller.teams.length > 1
        ? controller.teams[1]["players"] as List
        : [];
    bool allPlayersAdded = teamAPlayers.length == 2 && teamBPlayers.length == 2;

    if (!allPlayersAdded) {
      return const Icon(Icons.remove, color: Colors.black54, size: 16);
    }

    bool canScore = controller.canScoreForTeam(team);

    if (!canScore) {
      return const Icon(Icons.remove, color: Colors.black54, size: 16);
    }

    return GestureDetector(
      onTap: () {
        _showQuickScoreDialog(team, setNumber);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          " Add Score",
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showQuickScoreDialog(String team, int setNumber) {
    Get.dialog(SetScoreDialog(preselectedSet: setNumber));
  }

  void _showAddScoreDialog() {
    final teamAController = TextEditingController();
    final teamBController = TextEditingController();
    int? selectedSetNumber;

    Get.dialog(
      AlertDialog(
        title: Text("Add Score", style: Get.textTheme.headlineLarge,),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedSetNumber,
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.textFieldColor,
                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: Get.width * 0.04),
                    labelText: "Select Set",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textFieldColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: controller.sets.map((set) {
                    final setNum = set["setNumber"] as int;
                    return DropdownMenuItem<int>(
                      value: setNum,
                      child: Text("Set $setNum", style: Get.textTheme.headlineSmall,),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSetNumber = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                PrimaryTextField(
                  controller: teamAController,
                  labelText: "Team A Score",
                  keyboardType: TextInputType.number,
                  hintText: '',
                ),
                const SizedBox(height: 16),
                PrimaryTextField(
                  controller: teamBController,
                  labelText: "Team B Score",
                  keyboardType: TextInputType.number,
                  hintText: '',
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          Obx(() => PrimaryButton(
            width: 70,
            height: 40,
            textStyle: Get.textTheme.headlineSmall!.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            onTap: controller.isAddingScore.value ? () {} : () {
              if (selectedSetNumber == null) {
                SnackBarUtils.showInfoSnackBar("Please select a set");
                return;
              }
              final teamAScore = int.tryParse(teamAController.text) ?? 0;
              final teamBScore = int.tryParse(teamBController.text) ?? 0;

              controller.addScore(selectedSetNumber!, teamAScore, teamBScore).then((_) {
                if (!controller.isAddingScore.value) {
                  Get.back();
                }
              });
            },
            text: controller.isAddingScore.value ? "" : "Add",
            child: controller.isAddingScore.value
                ? SizedBox(
                height: 20,
                width: 20,
                child: LoadingWidget(color: Colors.white,)
            )
                : null,
          )),
        ],
      ),
    );
  }

  Widget _buildSetSection() {
    return Obx(() {
      return Card(
        child: Container(
          constraints: BoxConstraints(
            minHeight: Get.height * 0.4,
          ),
          width: Get.width,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    ...controller.sets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final set = entry.value;
                      final int setNumber = set["setNumber"];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 60,
                              child: () {
                                final teamAScore = set["teamAScore"] ?? 0;

                                return teamAScore > 0
                                    ? Text(
                                  "$teamAScore",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                )
                                    : _buildTeamAddScoreButton('Team A', setNumber);
                              }(),
                            ),
                                () {
                              final teamAScore = set["teamAScore"] ?? 0;
                              final teamBScore = set["teamBScore"] ?? 0;
                              bool hasScores = teamAScore > 0 || teamBScore > 0;
                              bool canEdit = hasScores && (controller.isUserInTeamA || controller.isUserInTeamB);

                              if (canEdit) {
                                return GestureDetector(
                                  onTap: () {
                                    Get.dialog(SetScoreDialog(preselectedSet: setNumber));
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Row(
                                      children: [
                                        Text(
                                          "Set ${set["setNumber"] ?? index + 1}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ).paddingOnly(right: 5),
                                        Icon(Icons.edit, size: 15,)
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return Row(
                                  children: [
                                    Text(
                                      "Set ${set["setNumber"] ?? index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Icon(Icons.abc, size: 18, color: Colors.white,).paddingOnly(left: 5)
                                  ],
                                );
                              }
                            }(),
                            SizedBox(
                              width: 60,
                              child: () {
                                final teamBScore = set["teamBScore"] ?? 0;

                                return teamBScore > 0
                                    ? Row(
                                  children: [
                                    Text(
                                      "$teamBScore",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                                    : _buildTeamAddScoreButton('Team B', setNumber);
                              }(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Column(
                children: [
                  if (controller.sets.length > 2 && !controller.isCompleted.value && _shouldShowEndGameButton())
                    const SizedBox(height: 10),
                  if (controller.sets.length > 2 && !controller.isCompleted.value && _shouldShowEndGameButton())
                    Obx(() => GestureDetector(
                      onTap: controller.isEndGame.value ? null : () {
                        bool hasEmptySet = controller.sets.any((set) {
                          final teamAScore = set["teamAScore"] ?? 0;
                          final teamBScore = set["teamBScore"] ?? 0;
                          return teamAScore == 0 && teamBScore == 0;
                        });

                        if (hasEmptySet) {
                          SnackBarUtils.showErrorSnackBar("Cannot end game with empty sets. Please add scores first.");
                          return;
                        }

                        controller.endGame();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: controller.isEndGame.value ? Colors.red.withOpacity(0.6) : Colors.red,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: controller.isEndGame.value ? [] : [
                              BoxShadow(
                                  color: AppColors.greyColor,
                                  blurRadius: 0.5,
                                  spreadRadius: 0.6,
                                  offset: Offset(0, 2)
                              )
                            ]
                        ),
                        child: controller.isEndGame.value
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: LoadingWidget(color: Colors.white),
                        )
                            : const Text(
                          "End Game",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ).paddingOnly(left: 10, right: 10),
                    )),
                  const SizedBox(height: 20),
                  Divider(color: AppColors.greyColor, height: 0.1,),
                  buildMatchSummary(),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  bool _shouldShowEndGameButton() {
    if (controller.sets.length < 3) return false;

    final thirdSet = controller.sets.firstWhere(
          (set) => set["setNumber"] == 3,
      orElse: () => {},
    );

    if (thirdSet.isEmpty) return false;

    final teamAScore = thirdSet["teamAScore"] ?? 0;
    final teamBScore = thirdSet["teamBScore"] ?? 0;

    bool thirdSetHasScores = teamAScore > 0 && teamBScore > 0;
    bool hasAnyScores = controller.sets.any((set) {
      final aScore = set["teamAScore"] ?? 0;
      final bScore = set["teamBScore"] ?? 0;
      return aScore > 0 || bScore > 0;
    });

    return thirdSetHasScores && hasAnyScores;
  }

  Widget buildMatchSummary() {
    return Obx(() {
      return Stack(
        children: [
          Container(
            width: Get.width,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Match Summary",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Team A Wins:"),
                    Text("${controller.teamAWins.value}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Team B Wins:"),
                    Text("${controller.teamBWins.value}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Winner:"),
                    Obx(() {
                      final winnerText = controller.winner.value;
                      final hasWinner = winnerText.isNotEmpty && 
                                        winnerText.toLowerCase() != 'none' && 
                                        winnerText != '-';
                      return Text(hasWinner ? winnerText : "-");
                    }),
                  ],
                ),
              ],
            ),
          ),
          if (controller.isShuffleMode.value)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: DragTarget<Map<String, dynamic>>(
                onAccept: (data) {
                  final playerId = data['player']['playerId'];
                  final playerName = controller.capitalizeFirstWord(
                    data['player']['name'].toString().split(' ').first.trim()
                  );
                  final team = data['team'];
                  
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Remove Player'),
                      content: Text('Remove $playerName from the match?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Get.back();
                            await controller.removePlayer(playerId, team);
                          },
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  final isActive = candidateData.isNotEmpty;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !isActive,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 35,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ] : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_forever, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                const Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}
////
class SetScoreDialog extends StatefulWidget {
  final int? preselectedSet;
  const SetScoreDialog({super.key, this.preselectedSet});

  @override
  State<SetScoreDialog> createState() => _SetScoreDialogState();
}

class _SetScoreDialogState extends State<SetScoreDialog> {
  final ScoreBoardController controller = Get.find<ScoreBoardController>();
  final teamAController = TextEditingController();
  final teamBController = TextEditingController();
  final teamAFocusNode = FocusNode();
  final teamBFocusNode = FocusNode();
  int currentSetNumber = 1;

  @override
  void initState() {
    super.initState();
    _determineCurrentSet();
    _loadExistingScores();
    _autoFocusField();
  }

  void _autoFocusField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isUserInTeamA) {
        teamAFocusNode.requestFocus();
      } else if (controller.isUserInTeamB) {
        teamBFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    teamAFocusNode.dispose();
    teamBFocusNode.dispose();
    super.dispose();
  }

  void _loadExistingScores() {
    if (widget.preselectedSet != null) {
      final set = controller.sets.firstWhere(
            (s) => s["setNumber"] == widget.preselectedSet,
        orElse: () => {},
      );
      if (set.isNotEmpty) {
        final teamAScore = set["teamAScore"] ?? 0;
        final teamBScore = set["teamBScore"] ?? 0;
        teamAController.text = teamAScore > 0 ? teamAScore.toString() : '';
        teamBController.text = teamBScore > 0 ? teamBScore.toString() : '';
      }
    }
  }

  void _determineCurrentSet() {
    if (widget.preselectedSet != null) {
      currentSetNumber = widget.preselectedSet!;
      return;
    }

    for (var set in controller.sets) {
      final teamAScore = set["teamAScore"] ?? 0;
      final teamBScore = set["teamBScore"] ?? 0;
      if (teamAScore == 0 && teamBScore == 0) {
        currentSetNumber = set["setNumber"];
        return;
      }
    }
    currentSetNumber = controller.sets.isNotEmpty ? controller.sets.last["setNumber"] : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          _scoreSection(),
          Divider(height: 1, color: Colors.grey.shade300,),
          _goButton(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF263FA3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Text("🏆", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            "Set $currentSetNumber",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.close, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _scoreSection() {
    return SizedBox(
      height: 190,
      child: Row(
        children: [
          _teamCard(
            title: "Team A",
            bgColor: const Color(0xFFF2F5FF),
            avatars: const [],
          ),
          Container(width: 1, color: Colors.grey.shade300),
          _teamCard(
            title: "Team B",
            bgColor: const Color(0xFFFFFEF6),
            avatars: const [],
          ),
        ],
      ),
    );
  }

  Widget _teamCard({
    required String title,
    required Color bgColor,
    required List<String> avatars,
  }) {
    final teamPlayers = title == "Team A"
        ? (controller.teams.isNotEmpty ? controller.teams[0]["players"] as List : [])
        : (controller.teams.length > 1 ? controller.teams[1]["players"] as List : []);

    final canScore = controller.canScoreForTeam(title);

    return Expanded(
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _avatars(teamPlayers),
            Text(
              title,
              style: Get.textTheme.headlineSmall!.copyWith(
                color: canScore ? AppColors.labelBlackColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 80,
              child: TextField(
                controller: title == "Team A" ? teamAController : teamBController,
                focusNode: title == "Team A" ? teamAFocusNode : teamBFocusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                enabled: canScore,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w500,
                  color: canScore ? Colors.grey : Colors.grey.withOpacity(0.5),
                  height: 1,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "00",
                  filled: true,
                  fillColor: bgColor,
                  hintStyle: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: canScore ? Colors.grey : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatars(List players) {
    return Stack(
      children: List.generate(
        players.length,
            (i) => Container(
          margin: EdgeInsets.only(left: i * 22),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: (players[i]["pic"] != null && players[i]["pic"].toString().isNotEmpty)
                ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: players[i]["pic"],
                fit: BoxFit.cover,
                width: 32,
                height: 32,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    height: 12,
                    width: 12,
                    child: LoadingWidget(color: AppColors.primaryColor),
                  ),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.textFieldColor,
                  child: Text(
                    getNameInitials(players[i]["name"], players[i]["lastName"]),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            )
                : CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.textFieldColor,
              child: Text(
                getNameInitials(players[i]["name"], players[i]["lastName"]),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Obx(() => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.isAddingScore.value ? Colors.grey : const Color(0xFF6BC172),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        ),
        onPressed: controller.isAddingScore.value ? null : () {
          final teamAScore = int.tryParse(teamAController.text) ?? 0;
          final teamBScore = int.tryParse(teamBController.text) ?? 0;

          final existingSet = controller.sets.firstWhere(
                (s) => s["setNumber"] == currentSetNumber,
            orElse: () => {},
          );
          final existingTeamAScore = existingSet.isNotEmpty ? (existingSet["teamAScore"] ?? 0) : 0;
          final existingTeamBScore = existingSet.isNotEmpty ? (existingSet["teamBScore"] ?? 0) : 0;

          if (controller.isUserInTeamA && teamBScore > 0 && existingTeamBScore == 0) {
            SnackBarUtils.showErrorSnackBar("You can only add scores for Team A");
            return;
          }
          if (controller.isUserInTeamB && teamAScore > 0 && existingTeamAScore == 0) {
            SnackBarUtils.showErrorSnackBar("You can only add scores for Team B");
            return;
          }

          controller.addScore(currentSetNumber, teamAScore, teamBScore).then((_) {
            if (!controller.isAddingScore.value) {
              Get.back();
            }
          });
        },
        child: controller.isAddingScore.value
            ? const SizedBox(
          height: 20,
          width: 20,
          child: LoadingWidget(color: Colors.white),
        )
            : Text(
          "GO",
          style: Get.textTheme.labelLarge!.copyWith(color: Colors.white),
        ),
      )),
    );
  }
}