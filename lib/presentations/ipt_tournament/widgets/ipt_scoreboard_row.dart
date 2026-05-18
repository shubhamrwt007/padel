import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';

class IptScoreboardRow extends StatelessWidget {
  final String logo;
  final String player1;
  final String player2;
  final List<String> scores;
  final String points;
  final bool isTeamA;

  const IptScoreboardRow({
    super.key,
    required this.logo,
    required this.player1,
    required this.player2,
    required this.scores,
    required this.points,
    this.isTeamA = true,
  });

  Widget scoreBox(String text, Color color, BorderRadiusGeometry? borderRadius) {
    return Container(
      width: 35,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.zero,
        border: const Border(
          right: BorderSide(color: Colors.black12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget pointBox(String text) {
    return Container(
      width: 35,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xffd9d9d9),
        borderRadius: isTeamA 
            ? const BorderRadius.only(
                topRight: Radius.circular(8),
              )
            : const BorderRadius.only(
                bottomRight: Radius.circular(8),
              ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xff1d3fa3),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // LEFT SIDE (LOGO + PLAYERS)
          Expanded(
            child: Row(
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: logo,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.3),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.primaryColor,
                      child: const Icon(
                        Icons.sports_tennis,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player1,
                      style: Get.textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      player2,
                      style: Get.textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // DYNAMIC SCORE BOXES
          Row(
            children: [
              // Dynamic score boxes based on rounds played
              ...scores.asMap().entries.map((entry) {
                final index = entry.key;
                final score = entry.value;
                
                BorderRadiusGeometry? borderRadius;
                Color boxColor = const Color(0xff2e46b8); // Default blue
                
                // First box - left rounded
                if (index == 0) {
                  borderRadius= isTeamA
                      ? const BorderRadius.only(
                    topLeft: Radius.circular(8),
                  )
                      : const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  );
                }
                // Last box but not first - no special radius
                else if (index == scores.length - 1 && scores.length > 1) {
                  borderRadius = BorderRadius.zero;
                  boxColor = const Color(0xff41b66b); // Green for last score
                }
                // Middle boxes
                else {
                  borderRadius = BorderRadius.zero;
                }
                
                return scoreBox(score, boxColor, borderRadius);
              }).toList(),
              // Points box
              pointBox(points),
            ],
          ),
        ],
      ),
    );
  }
}