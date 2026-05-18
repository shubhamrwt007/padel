import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/tournaments/live_tournament/live_tournament_controller.dart';
class LiveTournamentScreen extends StatelessWidget {
  final LiveTournamentController controller = Get.put(LiveTournamentController());
  LiveTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(title: Text("FIP Promises"),centerTitle: true, context: context,
      action: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.textFieldColor,
          child: const Icon(Icons.share, size: 18,color: AppColors.primaryColor,),
        )
      ]
      ),
      body: Column(
        children: [
          _buildVideoSection(),
          _buildScoreSection(),
          _buildTabSelector(),
          Expanded(
            child: Obx(() => controller.selectedTab.value == 1
                ? const MatchStatsCard()
                : Column(
                    children: [
                      _buildFinalSetCard(),
                      _buildSetTwoCard(),
                    ],
                  )),
          ),
        ],
      ),
    );
  }
  Widget _buildVideoSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          color: Colors.black12,
          child: Image.network(
            "https://images.unsplash.com/photo-1599058917765-a780eda07a3e",
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 200,
          width: Get.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: AlignmentGeometry.topCenter,
                end: AlignmentGeometry.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.2),Colors.black.withValues(alpha: 0.4)])
          ),
        ),
        /// Play Button
        CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
        ),

        /// LIVE Badge
        Positioned(
          left: 16,
          top: 16,
          child: Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFCD3529),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "LIVE",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).paddingOnly(right: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_red_eye_outlined,color: Colors.white,size: 13,),
                    SizedBox(width: 6),
                    Text(
                      "2K",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            ],
          )
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            children: [
              Icon(Icons.settings,color: Colors.white,).paddingOnly(right: 10),
              Icon(Icons.zoom_out_map,color: Colors.white,),
            ],
          ),
        )
      ],
    );
  }
  Widget _buildScoreSection() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 140, // 👈 decrease height here safely
          child: SvgPicture.asset(
            alignment: AlignmentGeometry.bottomCenter,
            Assets.imagesFipPromesisBg,
            fit: BoxFit.cover, // 👈 IMPORTANT
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40,vertical: 35),
          child: Obx(
                () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                /// TEAM A
                Column(
                  children: [
                    Text("A1",
                        style: Get.textTheme.titleLarge!.copyWith(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text("Eleanor Pena &\nKristin Watson",
                        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                  ],
                ),

                /// SCORE
                Transform.translate(
                  offset: Offset(3, -5),
                  child: Text(
                    "${controller.teamAScore.value} : ${controller.teamBScore.value}",
                    style: Get.textTheme.titleLarge!.copyWith(color: Colors.black,fontSize: 40),
                  ),
                ),

                /// TEAM B
                Column(
                  children: [
                    Text("A2",
                        style: Get.textTheme.titleLarge!.copyWith(fontSize: 30,color: AppColors.secondaryColor)),
                    const SizedBox(height: 6),
                    Text("Theresa Webb &\nRonald Richards",
                        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        boxShadow:  [
          BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0.3,
              offset: Offset(0, 6))
        ],
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 0
                  ? AppColors.whiteColor
                  : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: controller.selectedTab.value == 0
                      ? [
                    BoxShadow(
                      color: const Color(0xFF3B5BDB).withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: -1,
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history,color: controller.selectedTab.value == 0
                      ? AppColors.primaryColor
                      :AppColors.textColor,size: 18,),
                    const SizedBox(width: 6),
                    Text('History',style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,
                      color: controller.selectedTab.value == 0
                          ? AppColors.primaryColor
                          : AppColors.textColor,),),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 1
                      ? AppColors.whiteColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: controller.selectedTab.value == 1
                      ? [
                    BoxShadow(
                      color: const Color(0xFF3B5BDB).withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: -1,
                    ),
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_chart_outlined,size: 18,
                      color: controller.selectedTab.value == 1
                          ? AppColors.primaryColor
                          : AppColors.textColor,
                    ),
                    const SizedBox(width: 6),
                    Text('Statistics',style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,
                      color: controller.selectedTab.value == 1
                          ? AppColors.primaryColor
                          : AppColors.textColor,),)
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text("History")),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Center(child: Text("Statistics")),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildFinalSetCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 TOP SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Final Set",
                    style: Get.textTheme.labelMedium!.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Set 3",
                    style: Get.textTheme.titleLarge!.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              /// Ongoing badge
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xffE8EEFF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Ongoing",
                  style: TextStyle(
                    color: Color(0xff2D5BFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          /// 🔹 SCORE TABLE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// LEFT SIDE (Time + Bars + Scores)
              Column(
                children: [

                  /// Row 1
                  Row(
                    children: [

                      /// Rotated Time
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          "05:00",
                          style: Get.textTheme.labelMedium!
                              .copyWith(color: Colors.grey),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// Blue bar
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xff2D5BFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// Score
                      const Text(
                        "6",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2D5BFF),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Row 2
                  Row(
                    children: [
                      const SizedBox(width: 28),

                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xff2EBE60),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        "4",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2EBE60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 40),

              /// RIGHT SIDE (Rounds)
              Expanded(
                child: Column(
                  children: [

                    /// Header
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("R1"),
                        Text("R2"),
                        Text("R3"),
                        Text("R4"),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// First Row Scores
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("30",
                            style: TextStyle(fontSize: 22)),
                        Text("30",
                            style: TextStyle(fontSize: 22)),
                        Text("30",
                            style: TextStyle(fontSize: 22)),
                        Text(
                          "30",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2D5BFF),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Divider(),

                    const SizedBox(height: 14),

                    /// Second Row Scores
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("45",
                            style: TextStyle(fontSize: 22)),
                        Text("45",
                            style: TextStyle(fontSize: 22)),
                        Text("45",
                            style: TextStyle(fontSize: 22)),
                        Text(
                          "45",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2EBE60),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFinalSetCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Final Set",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),),
                    Text("Set 3",style: Get.textTheme.headlineMedium),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Ongoing",style: Get.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w500,color: AppColors.primaryColor),),
                )
              ],
            ),
            const SizedBox(height: 20),
            /// Scores
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// LEFT SIDE (Time + Bars + Scores)
                Column(
                  children: [
                    SizedBox(height: 33,),
                    /// Row 1
                    Row(
                      children: [

                        /// Rotated Time
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            "05:00",
                            style: Get.textTheme.labelMedium!
                                .copyWith(color: AppColors.labelBlackColor),
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// Blue bar
                        Container(
                          width: 4,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xff2D5BFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// Score
                         Text(
                          "6",
                          style: Get.textTheme.headlineMedium!.copyWith(color: AppColors.primaryColor)
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Row 2
                    Row(
                      children: [
                        const SizedBox(width: 28),

                        Container(
                          width: 4,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          "4",
                          style: Get.textTheme.headlineMedium!.copyWith(color: AppColors.secondaryColor)
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 40),

                /// RIGHT SIDE (Rounds)
                Expanded(
                  child: Column(
                    children: [

                      /// Header
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text("R1",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),),
                          Text("R2",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),),
                          Text("R3",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),),
                          Text("R4",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// First Row Scores
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text("30",
                              style: Get.textTheme.titleSmall),
                          Text("30",
                              style: Get.textTheme.titleSmall),
                          Text("30",
                              style: Get.textTheme.titleSmall),
                          Text(
                            "30",
                              style: Get.textTheme.titleSmall!.copyWith(color: AppColors.primaryColor)
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Divider(thickness: 0.5,color: Colors.grey,),

                      const SizedBox(height: 6),

                      /// Second Row Scores
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text("45",
                              style: Get.textTheme.titleSmall),
                          Text("45",
                              style: Get.textTheme.titleSmall),
                          Text("45",
                              style: Get.textTheme.titleSmall),
                          Text(
                            "45",
                            style: Get.textTheme.titleSmall!.copyWith(color: AppColors.secondaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSetTwoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            )
          ],
        ),
        child:  Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set 2",
                  style: Get.textTheme.labelMedium!.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text("6-3 (Team A1)",style: Get.textTheme.headlineMedium),
              ],
            ),
            Icon(Icons.keyboard_arrow_down)
          ],
        ),
      ),
    );
  }
}
class MatchStatsCard extends StatelessWidget {
  const MatchStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],

      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
        
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Team A1",
                  style: Get.textTheme.labelLarge!.copyWith(color: AppColors.primaryColor),
                  ),
                Text(
                  "Team A2",
                  style: Get.textTheme.labelLarge!.copyWith(color: AppColors.secondaryColor),
                  ),
              ],
            ),
        
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade300,thickness: 0.5,),
            const SizedBox(height: 10),
        
            /// Stats
            _statRow("Total Points", 10, 9),
            _statRow("Break Point Opportunities", 2, 6),
            _statRow("Break Points won", 2, 6),
            _statRow("Golden Point", 2, 6),
            _statRow("Winners", 2, 6),
            _statRow("Forced Errors", 2, 6),
            _statRow("Unforced Errors", 2, 1),
            _statRow("First Serve%", 23, 84, isPercentage: true),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
      String title,
      num left,
      num right, {
        bool isPercentage = false,
      }) {
    double total = (left + right) == 0 ? 1 : (left + right).toDouble();
    double leftRatio = left / total;
    double rightRatio = right / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [

          /// Numbers + Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPercentage ? "$left%" : left.toString().padLeft(2, '0'),
                style: Get.textTheme.labelLarge
              ),
              Text(
                title,
                style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: AppColors.textColor),
              ),
              Text(
                isPercentage ? "$right%" : right.toString().padLeft(2, '0'),
                style: Get.textTheme.labelLarge,
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Progress Bars
          Row(
            children: [
              Expanded(
                flex: (leftRatio * 100).toInt(),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xff2E4CB8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(width: 5,),
              Expanded(
                flex: (rightRatio * 100).toInt(),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xff35B368),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}