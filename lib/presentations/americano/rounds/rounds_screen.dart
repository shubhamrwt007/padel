import 'package:flutter/material.dart';

import '../../../configs/app_colors.dart';
import '../../../configs/components/app_bar.dart';
import '../../auth/forgot_password/widgets/forgot_password_exports.dart';
class RoundsScreen extends StatelessWidget {
  const RoundsScreen({super.key});

  static const List<RoundData> roundsData = [
    RoundData(
      title: "Round 1",
      matches: [
        MatchData(
          courtName: "Court 1",
          player1SideA: "Vikarm",
          player2SideA: "Dhruv",
          player1SideB: "Vikarm",
          player2SideB: "Dhruv",
          avatarUrlsSideA: [
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80",
          ],
          avatarUrlsSideB: [
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80",
          ],
          scoreA: "20",
          scoreB: "12",
        ),
        MatchData(
          courtName: "Court 1",
          player1SideA: "Vikarm",
          player2SideA: "Dhruv",
          player1SideB: "Vikarm",
          player2SideB: "Dhruv",
          avatarUrlsSideA: [
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80",
          ],
          avatarUrlsSideB: [
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80",
          ],
          scoreA: "20",
          scoreB: "12",
        ),
      ],
    ),
    RoundData(
      title: "Round 2",
      matches: [
        MatchData(
          courtName: "Court 1",
          player1SideA: "Vikarm",
          player2SideA: "Dhruv",
          player1SideB: "Vikarm",
          player2SideB: "Dhruv",
          avatarUrlsSideA: [
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80",
          ],
          avatarUrlsSideB: [
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80",
          ],
          scoreA: "20",
          scoreB: "12",
        ),
        MatchData(
          courtName: "Court 1",
          player1SideA: "Vikarm",
          player2SideA: "Dhruv",
          player1SideB: "Vikarm",
          player2SideB: "Dhruv",
          avatarUrlsSideA: [
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80",
          ],
          avatarUrlsSideB: [
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80",
          ],
          scoreA: "20",
          scoreB: "12",
        ),
      ],
    ),
    RoundData(
      title: "Round 2",
      matches: [
        MatchData(
          courtName: "Court 1",
          player1SideA: "Vikarm",
          player2SideA: "Dhruv",
          player1SideB: "Vikarm",
          player2SideB: "Dhruv",
          avatarUrlsSideA: [
            "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80",
          ],
          avatarUrlsSideB: [
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80",
            "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80",
          ],
          scoreA: "20",
          scoreB: "12",
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: primaryAppBar(
        centerTitle: true,
        titleTextColor: AppColors.whiteColor,
        leadingButtonColor: AppColors.whiteColor,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backGroundColor: AppColors.primaryColor,
        title: const Text("Rounds"),
        context: context,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: roundsData.length,
        itemBuilder: (context, roundIndex) {
          final round = roundsData[roundIndex];
          return RoundSection(
            roundTitle: round.title,
            children: round.matches.map((match) {
              return CourtCard(
                courtName: match.courtName,
                player1SideA: match.player1SideA,
                player2SideA: match.player2SideA,
                player1SideB: match.player1SideB,
                player2SideB: match.player2SideB,
                avatarUrlsSideA: match.avatarUrlsSideA,
                avatarUrlsSideB: match.avatarUrlsSideB,
                scoreA: match.scoreA,
                scoreB: match.scoreB,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class RoundSection extends StatelessWidget {
  final String roundTitle;
  final List<Widget> children;

  const RoundSection({
    super.key,
    required this.roundTitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2C82), // Dark royal blue banner
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            roundTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class CourtCard extends StatelessWidget {
  final String courtName;
  final String player1SideA;
  final String player2SideA;
  final String player1SideB;
  final String player2SideB;
  final List<String> avatarUrlsSideA;
  final List<String> avatarUrlsSideB;
  final String scoreA;
  final String scoreB;

  const CourtCard({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    const cardBgColor = Color(0xFF244BC9); // Card background color matching mockup
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            courtName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Left side players
              Expanded(
                child: PlayerSide(
                  player1: player1SideA,
                  player2: player2SideA,
                  avatarUrls: avatarUrlsSideA,
                  isRightAligned: false,
                  cardBgColor: cardBgColor,
                ),
              ),
              // Center score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ScoreCenter(
                  scoreA: scoreA,
                  scoreB: scoreB,
                ),
              ),
              // Right side players
              Expanded(
                child: PlayerSide(
                  player1: player1SideB,
                  player2: player2SideB,
                  avatarUrls: avatarUrlsSideB,
                  isRightAligned: true,
                  cardBgColor: cardBgColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlayerSide extends StatelessWidget {
  final String player1;
  final String player2;
  final List<String> avatarUrls;
  final bool isRightAligned;
  final Color cardBgColor;

  const PlayerSide({
    super.key,
    required this.player1,
    required this.player2,
    required this.avatarUrls,
    required this.isRightAligned,
    required this.cardBgColor,
  });

  @override
  Widget build(BuildContext context) {
    const double avatarRadius = 18;
    return Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          height: 39,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppColors.greyColor,
                  backgroundImage: NetworkImage(avatarUrls[0]),
                ),
              ),
              Positioned(
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBgColor, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppColors.greyColor,
                    backgroundImage: NetworkImage(avatarUrls[1]),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$player1 + $player2",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ScoreCenter extends StatelessWidget {
  final String scoreA;
  final String scoreB;

  const ScoreCenter({
    super.key,
    required this.scoreA,
    required this.scoreB,
  });

  @override
  Widget build(BuildContext context) {
    final isAWinner = (int.tryParse(scoreA) ?? 0) > (int.tryParse(scoreB) ?? 0);
    final isBWinner = (int.tryParse(scoreB) ?? 0) > (int.tryParse(scoreA) ?? 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scoreA,
          style: TextStyle(
            color: isAWinner ? const Color(0xFF3DBE64) : Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ":",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          scoreB,
          style: TextStyle(
            color: isBWinner ? const Color(0xFF3DBE64) : Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
