import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';

import '../../league/widgets/match_card_clipper.dart';
import 'rounds_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/forgot_password/widgets/forgot_password_exports.dart';

enum MatchStatus { live, finished, scheduled }

class RoundsScreen extends StatelessWidget {
  const RoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RoundsController>();

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: primaryAppBar(
        centerTitle: true,
        // titleTextColor: AppColors.whiteColor,
        // leadingButtonColor: AppColors.whiteColor,
        // systemOverlayStyle: SystemUiOverlayStyle.light,
        // backGroundColor: AppColors.primaryColor,
        title: const Text("Rounds"),
        context: context,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.roundsList.isEmpty) {
          return const Center(
            child: LoadingWidget(color: AppColors.primaryColor),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryColor,
          backgroundColor: Colors.white,
          onRefresh: () => controller.fetchRounds(),
          child: controller.roundsList.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const Center(
                        child: Text(
                          "No rounds available",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Scrollbar(
                  controller: controller.scrollController,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: controller.scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: controller.roundsList.length,
                    itemBuilder: (context, roundIndex) {
                      final round = controller.roundsList[roundIndex];
                      return RoundSection(
                        roundTitle: round.title,
                        children: round.matches.map((match) {
                          return GestureDetector(
                            onTap: () {
                              if (match.status.toLowerCase() == "scheduled") {
                                return;
                              }
                              Get.toNamed(
                                RoutesName.liveStreamAmericano,
                                arguments: {
                                  "matchType": match.status,
                                  "americanoMatchId": match.americanoMatchId,
                                  "roundId": match.roundId,
                                },
                              )?.then((_) {
                                controller.fetchRounds();
                              });
                            },
                            child: CourtCard(
                              status: match.status,
                              courtName: match.courtName,
                              player1SideA: match.player1SideA.split(' ').first,
                              player2SideA: match.player2SideA.split(' ').first,
                              player1SideB: match.player1SideB.split(' ').first,
                              player2SideB: match.player2SideB.split(' ').first,
                              avatarUrlsSideA: match.avatarUrlsSideA,
                              avatarUrlsSideB: match.avatarUrlsSideB,
                              scoreA: match.scoreA,
                              scoreB: match.scoreB,
                              matchDate: match.matchDate,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
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
          margin: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2C82), // Dark royal blue banner
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
  final String status;
  final String courtName;
  final String player1SideA;
  final String player2SideA;
  final String player1SideB;
  final String player2SideB;
  final List<String> avatarUrlsSideA;
  final List<String> avatarUrlsSideB;
  final String scoreA;
  final String scoreB;
  final String matchDate;

  const CourtCard({
    super.key,
    required this.status,
    required this.courtName,
    required this.player1SideA,
    required this.player2SideA,
    required this.player1SideB,
    required this.player2SideB,
    required this.avatarUrlsSideA,
    required this.avatarUrlsSideB,
    required this.scoreA,
    required this.scoreB,
    required this.matchDate,
  });

  @override
  Widget build(BuildContext context) {
    final String statusLower = status.toLowerCase();
    final MatchStatus resolvedStatus;
    if (statusLower == 'live') {
      resolvedStatus = MatchStatus.live;
    } else if (statusLower == 'completed' || statusLower == 'finished') {
      resolvedStatus = MatchStatus.finished;
    } else {
      resolvedStatus = MatchStatus.scheduled;
    }

    String formatDate(String date) {
      if (date.isEmpty) return "Date";
      try {
        final dateTime = DateTime.parse(date);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return "${days[dateTime.weekday - 1]} ${dateTime.day}/${dateTime.month}/${dateTime.year}";
      } catch (e) {
        return date;
      }
    }

    final List<Color> gradientColors;
    // ignore: unused_local_variable
    Color tabColor;
    Color scoreColor;
    Color imageColor;
    Widget statusWidget;

    switch (resolvedStatus) {
      case MatchStatus.live:
        gradientColors = const [Color(0xffffffff), Color(0xffffc6c2)];
        tabColor = const Color(0xffD32F2F);
        scoreColor = const Color(0xffD32F2F);
        imageColor = const Color(0xffCD3529);
        statusWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: imageColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "Watch Live",
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;
      case MatchStatus.finished:
        gradientColors = const [Color(0xffffffff), Color(0xfff5f5f5)];
        tabColor = const Color(0xff616161);
        scoreColor = Colors.black54;
        imageColor = AppColors.textColor;
        statusWidget = const SizedBox.shrink();
        break;
      default:
        gradientColors = const [Color(0xffffffff), Color(0xffcbd6ff)];
        tabColor = const Color(0xff2E4DB7);
        scoreColor = const Color(0xff2E4DB7);
        imageColor = AppColors.primaryColor;
        statusWidget = const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
        height: 25,
        width: 140,
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
            formatDate(matchDate),
            style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
        ),
      ).paddingOnly(top:5),
        ClipPath(clipper: MatchCardClipper(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            // padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
                width: 0.1,
              ),
            ),
            child: Stack(
              children: [
                /// LEFT DOT
                Positioned(
                  left: -50,
                  top: -10,
                  child: SvgPicture.asset(
                    Assets.images.dotsFipPromises.path,
                    height: 90,
                    width: 90,
                    colorFilter: ColorFilter.mode(imageColor, BlendMode.srcIn),
                  ),
                ),

                /// RIGHT DOT
                Positioned(
                  right: -8,
                  bottom: 0,
                  child: SvgPicture.asset(
                    Assets.images.dotsFipPromises.path,
                    height: 90,
                    width: 90,
                    colorFilter: ColorFilter.mode(imageColor, BlendMode.srcIn),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          courtName,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        statusWidget,
                      ],
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
                            cardBgColor: Colors.white,
                            showCrown: resolvedStatus == MatchStatus.finished && (int.tryParse(scoreA) ?? 0) > (int.tryParse(scoreB) ?? 0),
                          ),
                        ),
                        // Center score or VS image
                        resolvedStatus == MatchStatus.scheduled
                            ? SvgPicture.asset(Assets.images.imgVs.path).paddingOnly(bottom: 5, top: 5)
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: ScoreCenter(
                                  scoreA: scoreA,
                                  scoreB: scoreB,
                                  scoreColor: scoreColor,
                                  isFinished: resolvedStatus == MatchStatus.finished,
                                ),
                              ),

                        // Right side players
                        Expanded(
                          child: PlayerSide(
                            player1: player1SideB,
                            player2: player2SideB,
                            avatarUrls: avatarUrlsSideB,
                            isRightAligned: true,
                            cardBgColor: Colors.white,
                            showCrown: resolvedStatus == MatchStatus.finished && (int.tryParse(scoreB) ?? 0) > (int.tryParse(scoreA) ?? 0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).paddingAll(16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PlayerSide extends StatelessWidget {
  final String player1;
  final String player2;
  final List<String> avatarUrls;
  final bool isRightAligned;
  final Color cardBgColor;
  final bool showCrown;

  const PlayerSide({
    super.key,
    required this.player1,
    required this.player2,
    required this.avatarUrls,
    required this.isRightAligned,
    required this.cardBgColor,
    this.showCrown = false,
  });

  String _capitalizeName(String name) {
    if (name.trim().isEmpty) return "";
    return name
        .split(" ")
        .map((word) => word.isEmpty
            ? ""
            : "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}")
        .join(" ");
  }

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
      backgroundColor: AppColors.primaryColor,
      backgroundImage: hasImage ? CachedNetworkImageProvider(url) : null,
      child: !hasImage
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
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

    final capPlayer1 = _capitalizeName(player1);
    final capPlayer2 = _capitalizeName(player2);

    return Column(
      crossAxisAlignment: isRightAligned
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          height: 43,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (hasPlayer1)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBgColor, width: 1),
                      ),
                      child: _buildAvatar(player1, url1, avatarRadius)),
                ),
              if (hasPlayer2)
                Positioned(
                  top: 1,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBgColor, width: 1),
                    ),
                    child: _buildAvatar(player2, url2, avatarRadius),
                  ),
                ),
              if (showCrown)
                Positioned(
                  top: -12,
                  left: hasPlayer2 ? 16 : 8,
                  child: Image.asset(
                    Assets.images.icCrown.path,
                    width: 18,
                    height: 18,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasPlayer2 ? "$capPlayer1 + $capPlayer2" : capPlayer1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
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
  final Color scoreColor;
  final bool isFinished;

  const ScoreCenter({
    super.key,
    required this.scoreA,
    required this.scoreB,
    this.scoreColor = Colors.black,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAWinner = isFinished && (int.tryParse(scoreA) ?? 0) > (int.tryParse(scoreB) ?? 0);
    final isBWinner = isFinished && (int.tryParse(scoreB) ?? 0) > (int.tryParse(scoreA) ?? 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scoreA,
          style: TextStyle(
            color: isAWinner ? const Color(0xFF3DBE64) : scoreColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ":",
            style: TextStyle(
              color: scoreColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          scoreB,
          style: TextStyle(
            color: isBWinner ? const Color(0xFF3DBE64) : scoreColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
