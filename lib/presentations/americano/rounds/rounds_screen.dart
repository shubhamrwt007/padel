import 'package:padel_mobile/configs/routes/routes_name.dart';

import 'rounds_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/forgot_password/widgets/forgot_password_exports.dart';
class RoundsScreen extends StatelessWidget {
  const RoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoundsController>();

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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (controller.roundsList.isEmpty) {
          return const Center(
            child: Text(
              "No rounds available",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return Scrollbar(
          controller: controller.scrollController,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: controller.roundsList.length,
            itemBuilder: (context, roundIndex) {
              final round = controller.roundsList[roundIndex];
              return RoundSection(
                roundTitle: round.title,
                children: round.matches.map((match) {
                  return GestureDetector(
                    onTap: (){
                      Get.toNamed(RoutesName.liveStreamAmericano,arguments: {
                        "matchType": "live",
                        "matchId": "123"
                      });
                    },
                    child: CourtCard(
                      courtName: match.courtName,
                      player1SideA: match.player1SideA,
                      player2SideA: match.player2SideA,
                      player1SideB: match.player1SideB,
                      player2SideB: match.player2SideB,
                      avatarUrlsSideA: match.avatarUrlsSideA,
                      avatarUrlsSideB: match.avatarUrlsSideB,
                      scoreA: match.scoreA,
                      scoreB: match.scoreB,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }),
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

  String _getPlayerInitials(String fullName) {
    if (fullName.isEmpty) return "?";
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final firstLetter = parts.first[0];
      final lastLetter = parts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
    return fullName.trim()[0].toUpperCase();
  }

  Widget _buildAvatar(String name, String? url, double radius) {
    final hasImage = url != null && url.isNotEmpty;
    final initials = _getPlayerInitials(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.greyColor,
      backgroundImage: hasImage ? CachedNetworkImageProvider(url) : null,
      child: !hasImage
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.black,
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double avatarRadius = 18;
    
    final hasPlayer1 = player1.isNotEmpty;
    final hasPlayer2 = player2.isNotEmpty;

    if (!hasPlayer1 && !hasPlayer2) {
      return const SizedBox.shrink();
    }

    final url1 = avatarUrls.isNotEmpty ? avatarUrls[0] : "";
    final url2 = avatarUrls.length > 1 ? avatarUrls[1] : "";

    return Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          height: 39,
          child: Stack(
            children: [
              if (hasPlayer1)
                Positioned(
                  left: 0,
                  child: _buildAvatar(player1, url1, avatarRadius),
                ),
              if (hasPlayer2)
                Positioned(
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBgColor, width: 2),
                    ),
                    child: _buildAvatar(player2, url2, avatarRadius),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasPlayer2 ? "$player1 + $player2" : player1,
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


