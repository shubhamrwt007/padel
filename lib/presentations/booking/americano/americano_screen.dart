import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import '../../../data/response_models/americano_models/get_americano_model.dart';
import '../../americano/widgets/americano_bottomsheet_content.dart';
import 'americano_controller.dart';
class AmericanoScreens extends StatelessWidget {
  const AmericanoScreens({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AmericanoController());
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ongoing Section
          const Text(
            'Ongoing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // TODO: Replace hardcoded cards with real API data
          // Obx(() {
          //   if (controller.ongoingAmericanos.isEmpty) {
          //     return Text('No ongoing matches');
          //   }
          //   return Column(
          //     children: controller.ongoingAmericanos.map((match) {
          //       return _buildMatchCardFromApi(match);
          //     }).toList(),
          //   );
          // }),

          // First Ongoing Match
          _buildMatchCard(
            date: '23 June',
            time: '9:00am',
            type: 'T/C',
            typeColor: Colors.green,
            genderIcon: Icons.female,
            genderText: 'Female Only',
            playerCount: '12 Players',
            actionText: 'View Score',
            actionColor: Colors.blue,
            playerAvatars: [
              'https://i.pravatar.cc/40?img=1',
              'https://i.pravatar.cc/40?img=2',
              'https://i.pravatar.cc/40?img=3',
              'https://i.pravatar.cc/40?img=4',
            ],
            moreCount: '+5',
            prize: {'first': 100000, 'second': 70000, 'third': 50000},
          ),

          const SizedBox(height: 12),

          // Second Ongoing Match
          _buildMatchCard(
            date: '23 June',
            time: '9:00am',
            type: 'C/D',
            typeColor: Colors.green,
            genderIcon: Icons.female,
            genderText: 'Female Only',
            playerCount: '12 Players',
            actionText: 'View Score',
            actionColor: Colors.blue,
            playerAvatars: [
              'https://i.pravatar.cc/40?img=5',
              'https://i.pravatar.cc/40?img=6',
              'https://i.pravatar.cc/40?img=7',
              'https://i.pravatar.cc/40?img=8',
            ],
            moreCount: '+5',
            prize: {'first': 10000, 'second': 7000, 'third': 5000},
          ),

          const SizedBox(height: 24),

          // Upcoming Section
          const Text(
            'Upcoming',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // First Upcoming Match
          _buildMatchCard(
            date: '24 June',
            time: '9:00am',
            type: 'A/B',
            typeColor: Colors.orange,
            genderIcon: Icons.male,
            genderText: 'Male only',
            playerCount: 'Full',
            playerCountColor: Colors.red,
            actionText: null,
            playerAvatars: [
              'https://i.pravatar.cc/40?img=9',
              'https://i.pravatar.cc/40?img=10',
              'https://i.pravatar.cc/40?img=11',
              'https://i.pravatar.cc/40?img=12',
            ],
            moreCount: '+5',
            prize: null,
          ),

          const SizedBox(height: 12),

          // Second Upcoming Match
          _buildMatchCard(
            date: '25 June',
            time: '9:00am',
            type: 'B/C',
            typeColor: Colors.green,
            genderIcon: Icons.people,
            genderText: 'Mixed',
            playerCount: '12 Players',
            actionText: 'Join Now',
            actionColor: Colors.blue,
            playerAvatars: [
              'https://i.pravatar.cc/40?img=13',
              'https://i.pravatar.cc/40?img=14',
              'https://i.pravatar.cc/40?img=15',
              'https://i.pravatar.cc/40?img=16',
            ],
            moreCount: '+',
            prize: {'first': 50000, 'second': 30000, 'third': 20000},
          ),

          const SizedBox(height: 12),

          // ✅ Third Upcoming Match (Added)
          _buildMatchCard(
            date: '26 June',
            time: '9:00am',
            type: 'C/D',
            typeColor: Colors.green,
            genderIcon: Icons.female,
            genderText: 'Female only',
            playerCount: '12 Players',
            actionText: 'Join Now',
            actionColor: Colors.blue,
            playerAvatars: [
              'https://i.pravatar.cc/40?img=17',
              'https://i.pravatar.cc/40?img=18',
              'https://i.pravatar.cc/40?img=19',
              'https://i.pravatar.cc/40?img=20',
            ],
            moreCount: '+',
            prize: null,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard({
    required String date,
    required String time,
    required String type,
    required Color typeColor,
    required IconData genderIcon,
    required String genderText,
    required String playerCount,
    Color? playerCountColor,
    String? actionText,
    Color? actionColor,
    required List<String> playerAvatars,
    required String moreCount,
    Map<String, dynamic>? prize,
  }) {
    return GestureDetector(
      onTap: () {
        print('Passing prize to bottom sheet: $prize'); // Debug
        showAmericanoBottomSheet(Get.context!, prize: prize);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side - Date, Time, Type
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$date | $time',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        alignment: Alignment.center,
                        height: 15,
                        width: 25,
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        genderIcon,
                        size: 16,
                        color: AppColors.labelBlackColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        genderText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.labelBlackColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.group, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        playerCount,
                        style: TextStyle(
                          fontSize: 12,
                          color: playerCountColor ?? AppColors.labelBlackColor,
                          fontWeight: playerCountColor != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right side - Player avatars and action
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Player avatars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 32,
                        child: Stack(
                          children: [
                            for (int i = 0;
                            i < playerAvatars.length && i < 4;
                            i++)
                              Positioned(
                                right: i * 20.0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(playerAvatars[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            // More count circle
                            Positioned(
                              right: 80,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    moreCount,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action button
                  if (actionText != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          actionText,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void showAmericanoBottomSheet(BuildContext context, {Map<String, dynamic>? prize}) {
    final DraggableScrollableController draggableController = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Stack(
            children: [
              DraggableScrollableSheet(
                controller: draggableController,
                initialChildSize: 0.45,
                minChildSize: 0.45,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return GestureDetector(
                    onTap: () {}, // Prevents tap propagation inside the sheet
                    child: AmericanoBottomSheetContent(
                      scrollController: scrollController,
                      draggableController: draggableController,
                      match: AmericanoMatch(prize: prize),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build card from API data
  Widget _buildMatchCardFromApi(AmericanoMatch match) {
    return _buildMatchCard(
      date: match.formattedMatchDate,
      time: match.matchTime ?? '9:00am',
      type: match.skillLevel?.substring(0, 1).toUpperCase() ?? 'A',
      typeColor: Colors.green,
      genderIcon: match.gender == 'male only' ? Icons.male : 
                  match.gender == 'female only' ? Icons.female : Icons.people,
      genderText: match.gender ?? 'Mixed',
      playerCount: '${match.joinedMembers ?? 0} Players',
      actionText: match.matchStatus == 'ongoing' ? 'View Score' : 'Join Now',
      actionColor: Colors.blue,
      playerAvatars: match.joinedPlayersAvatars.isNotEmpty 
          ? match.joinedPlayersAvatars 
          : [
              'https://i.pravatar.cc/40?img=1',
              'https://i.pravatar.cc/40?img=2',
              'https://i.pravatar.cc/40?img=3',
              'https://i.pravatar.cc/40?img=4',
            ],
      moreCount: '+${(match.maxPlayers ?? 0) - (match.joinedMembers ?? 0)}',
      prize: match.prize, // This is the real prize data from API!
    );
  }
}