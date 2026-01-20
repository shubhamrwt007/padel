import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/scoreview/score_view_controoler.dart';

import '../../configs/app_colors.dart';
import '../../configs/components/app_bar.dart';
import '../../configs/routes/routes_name.dart';
import '../../generated/assets.dart';

class ScoreViewScreen extends GetView<ScoreViewController> {
  const ScoreViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: primaryAppBar(
          leadingButtonColor: AppColors.whiteColor,
          titleTextColor: AppColors.whiteColor,
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
              _buildCountdownTimer(),
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
          _buildLeaderboardSheet(context)
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
            final title = i == 0 ? 'Leader Board' : 'Rounds';
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

  Widget _buildCountdownTimer() {
    return Obx(() {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: controller.isTimerActive.value 
              ? AppColors.secondaryColor 
              : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.isTimerActive.value 
                ? AppColors.secondaryColor 
                : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.isTimerActive.value 
                  ? Icons.timer 
                  : Icons.timer_off,
              color: AppColors.whiteColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              controller.formattedTime,
              style: Get.textTheme.headlineMedium!.copyWith(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRankingInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0XFFCBD6FF),
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
              "#4",
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
              "You are doing better than 60% of other players!",
              style: Get.textTheme.bodyMedium!.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSection() {
    final top3 = controller.players.take(3).toList();

    // Ensure we have at least 3 players, otherwise handle gracefully
    if (top3.length < 3) {
      return const SizedBox(height: 300, child: Center(child: Text('Not enough players for podium')));
    }

    return SizedBox(
        height: Get.height*0.47,
        width: Get.width,
        // color: Colors.grey,
        child: Stack(
          children: [
            Transform.scale(
              scale: 1.1,
              child: SvgPicture.asset(
                Assets.imagesImgBackgroundScoreView,
                fit: BoxFit.cover,
              ),
            ).paddingOnly(left: 10,top: 10),
            Center(
              child: SvgPicture.asset(
                Assets.imagesImgScoreView,
                height: 250,
                fit: BoxFit.contain,
              ),
            ).paddingOnly(left: 30, right: 30),
            // Position players on top of the podium with precise alignment
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2nd place (left side) - positioned lower
                  Container(
                    // margin: EdgeInsets.only(bottom: 60, right: 15),
                    child: _podiumItem(top3[1], 2),
                  ),

                  // 1st place (center, highest) - positioned at the top
                  Container(
                    margin: EdgeInsets.only(left: Get.width*0.12),
                    child: _podiumItem(top3[0], 1),
                  ),

                  // 3rd place (right side) - positioned lowest
                  Container(
                    margin: EdgeInsets.only(bottom: 30, left: Get.width*0.12),
                    child: _podiumItem(top3[2], 3),
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }

  Widget _podiumItem(Player player, int position) {
    final heightOffsets = {1: Get.height*0.018, 2:Get.height*0.068, 3: Get.height*0.098}; // 1st highest, 2nd middle, 3rd lowest

    return Padding(
      padding: EdgeInsets.only(top: heightOffsets[position]!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: position == 1 ? 35 : 30,
            backgroundImage: NetworkImage(player.imageUrl),
          ),
          Text("Dianne",style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white),),
          Container(
            height: 16,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(10)
            ),
            child: Text("80",style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white,fontSize: 11),),
          ).paddingOnly(bottom: Get.height*0.03),
          Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontSize:48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSheet(BuildContext context) {
    return Obx(
          () => DraggableScrollableSheet(
        key: ValueKey(controller.selectedTab.value),
        initialChildSize: controller.selectedTab.value == 0 ? 0.5 : 0.55,
        minChildSize: controller.selectedTab.value == 0 ? 0.5 : 0.55,
        maxChildSize: 0.9,
        builder: (context, scroll) => Container(
          
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topLeft:Radius.circular(10),topRight: Radius.circular(10)),
            color: Colors.white,
          ),
          child: CustomPaint(
            painter: CurvedTopPainter(),
            child: Column(
              children: [
                // Space for the curved area
                const SizedBox(height: 0),
                Icon(Icons.circle,size: 10,color: AppColors.starUnselectedColor,).paddingOnly(bottom: 10),

                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: controller.players.length,
                    itemBuilder: (_, idx) {
                      final p = controller.players[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryColor.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('${idx + 1}').paddingOnly(right: 10),
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(p.imageUrl),
                                    ),
                                  ),
                                ).paddingOnly(right: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: Get.textTheme.headlineSmall,
                                    ).paddingOnly(bottom: 5),
                                    Row(
                                      children: [
                                        Container(
                                          height: 16,
                                          width: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "${p.points}",
                                            style: Get.textTheme.bodyMedium!.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const Text(' pts'),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "W - L - T",
                                  style: Get.textTheme.displaySmall!.copyWith(fontSize: 11),
                                ),
                                Text(p.record),
                              ],
                            ),
                          ],
                        ).paddingAll(10),
                      );
                    },
                  ),
                ),
              ],
            ).paddingOnly(
              left: Get.width * 0.05,
              right: Get.width * 0.05,
            ),
          ),
        ),
      ),
    );
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
                  onTap: (){},
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
                    ).paddingOnly(bottom: Get.height*0.02),
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
            onTap: (){Get.toNamed(RoutesName.rounds);},
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

// Custom painter for the curved top
class CurvedTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(0, size.height);

    // Line to bottom right
    path.lineTo(size.width, size.height);

    // Line up to top right, but before the curve
    path.lineTo(size.width, 30);

    // Curve at the top right
    path.quadraticBezierTo(size.width, 0, size.width - 20, 0);

    // Line to center right (before the center curve) - decreased width
    path.lineTo(size.width * 0.55, 0);

    // Center curve (upward notch) - more curve with deeper control point
    path.quadraticBezierTo(
      size.width * 0.5, -22, // Control point (center, deeper up)
      size.width * 0.45, 0,  // End point - decreased width
    );

    // Line to top left corner curve
    path.lineTo(30, 0);

    // Curve at the top left
    path.quadraticBezierTo(0, 0, 0, 30);

    // Close the path
    path.close();

    canvas.drawPath(path, paint);

    // Optional: Add shadow effect
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 3, false);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}