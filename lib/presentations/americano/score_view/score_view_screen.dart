import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import '../../leaderBoard/leader_board_screen.dart';

class ScoreViewScreen extends GetView<ScoreViewController> {
  const ScoreViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: primaryAppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leadingButtonColor: AppColors.whiteColor,
          titleTextColor: AppColors.whiteColor,
          centerTitle: true,
          title: Obx(()=> Text(controller.selectedTab.value == 0?"Score View":"Americano")), context: context),
      body: Stack(
        children: [
          // Background curved container
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 10),
              Obx(() => controller.selectedTab.value == 0
                  ? _buildRankingInfo()
                  : SizedBox.shrink()),
              Obx(() => controller.selectedTab.value == 0
                  ? _buildPodiumSection()
                  : _roundsTabContent()),
            ],
          ),
          // Leaderboard bottom sheet
          _buildLeaderboardSheet(context),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      return Container(
        width: Get.width,
        padding: const EdgeInsets.all(4),
        margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        decoration: BoxDecoration(
          color: const Color(0xFF4F6DF6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(2, (i) {
            final title = i == 0 ? 'Score Board' : 'Rounds';
            final selected = controller.selectedTab.value == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedTab.value = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF0B3BA7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    title,
                    style: Get.textTheme.headlineLarge!.copyWith(color:AppColors.whiteColor,fontWeight: FontWeight.w600)
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
  Widget _buildRankingInfo() {
    return Obx(() {
      final rankInfo = controller.myRankInfo.value;
      if (rankInfo == null) {
        return const SizedBox.shrink();
      }

      final rank = rankInfo.rank ?? 0;
      final message = rankInfo.message ?? "";

      if (message.isEmpty && rank == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0XFFCBD6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.labelBlackColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "#$rank",
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
    });
  }
  String _getPlayerInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final firstLetter = parts.first[0];
      final lastLetter = parts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
    return fullName.trim()[0].toUpperCase();
  }

  String _getPlayerName(AmericanoPlayer player) {
    final name = player.fullName;
    if (name != null && name.isNotEmpty) {
      return name.capitalizeFirstChar();
    }
    final registerName = player.registerUserId?.name;
    if (registerName != null && registerName.isNotEmpty) {
      return registerName.capitalizeFirstChar();
    }
    return "Anonymous";
  }

  Widget _buildPodiumSection() {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: Get.height * 0.4,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      final playersList = controller.leaderboardPlayers;

      if (playersList.isEmpty) {
        return SizedBox(
          height: Get.height * 0.4,
          child: const Center(
            child: Text(
              'No players available',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      final top3 = playersList.take(3).toList();

      return SizedBox(
        height: Get.height * 0.47,
        width: Get.width,
        child: Stack(
          children: [
            Transform.scale(
              scale: 1.1,
              child: SvgPicture.asset(
                Assets.imagesImgBackgroundScoreView,
                fit: BoxFit.cover,
              ),
            ).paddingOnly(left: 10, top: 10),
            Center(
              child: SvgPicture.asset(
                Assets.imagesImgScoreView,
                height: 250,
                fit: BoxFit.contain,
              ),
            ).paddingOnly(left: 30, right: 30),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2nd place (left side)
                  if (top3.length > 1)
                    _podiumItem(top3[1], 2)
                  else
                    const SizedBox(width: 80),

                  // 1st place (center, highest)
                  Container(
                    margin: EdgeInsets.only(left: Get.width * 0.1, right: Get.width * 0.1),
                    child: _podiumItem(top3[0], 1),
                  ),

                  // 3rd place (right side)
                  if (top3.length > 2)
                    _podiumItem(top3[2], 3)
                  else
                    const SizedBox(width: 80),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _podiumItem(AmericanoPlayer player, int position) {
    final heightOffsets = {1: Get.height * 0.018, 2: Get.height * 0.068, 3: Get.height * 0.098};

    final pic = player.registerUserId?.profilePic;
    final hasImage = pic != null && pic.isNotEmpty;
    final name = _getPlayerName(player);
    final initials = _getPlayerInitials(player.fullName ?? player.registerUserId?.name);
    final points = player.totalPoints ?? 0;

    return Padding(
      padding: EdgeInsets.only(top: heightOffsets[position]!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: position == 1 ? 36 : 31,
            child: CircleAvatar(
              radius: position == 1 ? 35 : 30,
              backgroundColor: AppColors.primaryColor,
              backgroundImage: hasImage ? NetworkImage(pic) : null,
              child: !hasImage
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: position == 1 ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 16,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$points",
              style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white, fontSize: 11),
            ),
          ).paddingOnly(bottom: Get.height * 0.03),
          Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontSize: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSheet(BuildContext context) {
    return Obx(() {
      return DraggableScrollableSheet(
        key: ValueKey(controller.selectedTab.value),
        initialChildSize: controller.selectedTab.value == 0 ? 0.48 : 0.55,
        minChildSize: controller.selectedTab.value == 0 ? 0.48 : 0.55,
        maxChildSize: 0.9,
        builder: (context, scroll) => Obx(() {
          final playersList = controller.leaderboardPlayers;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                painter: UpwardCurvePainter(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xffF9FAFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '#',
                                style: Get.textTheme.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Player',
                                style: Get.textTheme.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              width: 55,
                              child: Text(
                                'W-L-T',
                                style: Get.textTheme.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'Diff',
                                style: Get.textTheme.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                'Points',
                                style: Get.textTheme.labelLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ).paddingOnly(bottom: 10),
                      Expanded(
                        child: controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : playersList.isEmpty
                                ? const Center(child: Text("No leaderboard data available"))
                                : ListView.builder(
                                    controller: scroll,
                                    itemCount: playersList.length,
                                    itemBuilder: (_, idx) {
                                      final p = playersList[idx];
                                      final pic = p.registerUserId?.profilePic;
                                      final hasImage = pic != null && pic.isNotEmpty;
                                      final name = _getPlayerName(p);
                                      final initials = _getPlayerInitials(p.fullName ?? p.registerUserId?.name);
                                      final wins = p.wins ?? 0;
                                      final losses = p.losses ?? 0;
                                      final draws = p.draws ?? 0;
                                      final diff = p.pointDifference ?? 0;
                                      final diffSign = diff >= 0 ? "+" : "";
                                      final points = p.totalPoints ?? 0;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 5),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.primaryColor.withAlpha(30)),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 30,
                                              child: Text(
                                                '${idx + 1}',
                                                style: Get.textTheme.bodySmall!.copyWith(color: Colors.black, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 15,
                                                    backgroundColor: AppColors.primaryColor,
                                                    backgroundImage: hasImage ? NetworkImage(pic) : null,
                                                    child: !hasImage
                                                        ? Text(
                                                            initials,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          )
                                                        : null,
                                                  ).paddingOnly(right: 10),
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: Get.textTheme.bodySmall!.copyWith(color: Colors.black),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 55,
                                              child: Text(
                                                "$wins - $losses - $draws",
                                                style: Get.textTheme.displaySmall!.copyWith(fontSize: 11),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 45,
                                              child: Text(
                                                "$diffSign$diff",
                                                style: Get.textTheme.displaySmall!.copyWith(fontSize: 11),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 50,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  height: 16,
                                                  width: 30,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.secondaryColor,
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    "$points",
                                                    style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white, fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ).paddingSymmetric(horizontal: 12, vertical: 10),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
                ),
              ),
              Positioned(
                top: -8,
                left: Get.width * 0.5 - 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.starUnselectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      );
    });
  }

Widget _roundsTabContent(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: Get.height*0.3,
          child: Stack(
            children: [
              Positioned(
                top: Get.height*0.04,
                child: GestureDetector(
                  onTap: ()=>Get.toNamed(RoutesName.roundsScore),
                  child: Container(
                      height: Get.height*0.25,
                      width: Get.width,
                      // color: Colors.grey,
                      padding: EdgeInsets.only(left: 10,right: 10),
                      child: SvgPicture.asset(Assets.imagesImgRoundBackground)),
                ),
              ),
              Container(
                height: Get.height*0.24,
                width: Get.width,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A79),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "Your Match",
                      style: Get.textTheme.titleSmall!.copyWith(color: Colors.white)
                    ).paddingOnly(bottom: Get.height*0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPlayerColumn(
                          imageUrls: [
                            'https://i.pravatar.cc/150?img=11',
                            'https://i.pravatar.cc/150?img=10'
                          ],
                          names: ['Claire', 'Wendy'],
                          score: controller.leftScore,
                        ),
                        SvgPicture.asset(Assets.imagesImgVsRounds,height: 100,),
                        _buildPlayerColumn(
                          imageUrls: [
                            'https://i.pravatar.cc/150?img=13',
                            'https://i.pravatar.cc/150?img=12'
                          ],
                          names: ['Bessie', 'Jane'],
                          score: controller.rightScore,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: Offset(0, -Get.height*0.05),
          child: GestureDetector(
            onTap: ()=>Get.toNamed(RoutesName.roundsScore),
            child: Text(
              "View All",
              style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.whiteColor)
            ),
          ),
        ),
      ],
    );
}
  Widget _buildPlayerColumn({
    required List<String> imageUrls,
    required List<String> names,
    required RxInt score,
  }) {
    final style = Get.textTheme.headlineSmall!.copyWith(color: AppColors.whiteColor);
    return Column(
      children: [
        Container(
          // color: Colors.grey,
          width: 100,
          height: 70,
          alignment: Alignment.centerRight,
          child: Stack(
            children: [
              Positioned(
                left: 10,
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(imageUrls[0]),
                ),
              ),
              Positioned(
                left: 35,
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(imageUrls[1]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              names[0],
              style: style,
            ),
            Text(
              '  +  ',
              style: style,
            ),
            Text(
              names[1],
              style: style,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            score.value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        )),
      ],
    );
  }
}
