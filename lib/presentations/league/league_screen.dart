import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/league/league_controller.dart';
import 'package:padel_mobile/presentations/league/widgets/build_sponsor_banner.dart';
import 'package:padel_mobile/presentations/league/widgets/match_card_clipper.dart';

class LeagueScreen extends StatelessWidget {
  final LeagueController controller =Get.put(LeagueController());
  LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(()=> Scaffold(
        appBar: primaryAppBar(title: Text("League"),centerTitle: true, context: context,),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            Expanded(
              child: controller.selectedTab.value == 0
                  ? _liveMatchContent(context).paddingOnly(top: 10)
                  : const LeaderBoardWidget().paddingOnly(top: 20),
            ),
          ],
        ),
      ),
    );
  }
  Widget _liveMatchContent(BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _liveMatchCard().paddingOnly(bottom: 10),
        BuildSponsorBanner(),
        _buildTabs(context),
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.matchTab.value == 0
                  ? "Upcoming Matches"
                  : controller.matchTab.value == 1
                      ? "Live Matches"
                      : "Match Results",
              style: Get.textTheme.headlineMedium,
            ),
            if(controller.matchTab.value !=1)
            GestureDetector(
              onTap: () {
                Get.toNamed(RoutesName.leagueMatchLists,arguments: {
                  'matchTab': controller.matchTab.value
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Text(
                  "See all",
                  style: Get.textTheme.labelLarge!
                      .copyWith(color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ).paddingSymmetric(horizontal: 18,vertical: 8)),
        Expanded(
          child: PageView(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            children: [
              _upcomingList(),
              _liveList(),
              _resultsList(),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTabs(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller.tabController,
        onTap: controller.onTabChanged,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.black54,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 1,
        dividerColor: Colors.grey.shade300,
        labelStyle:Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500) ,
        tabs: const [
          Tab(text: "Upcoming"),
          Tab(text: "Live"),
          Tab(text: "Results"),
        ],
      ),
    );
  }

  /// TAB SELECTOR
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.creamColor,
        borderRadius: BorderRadius.circular(10),
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
          // Padel Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 0
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: controller.selectedTab.value == 0
                      ? Border.all(
                    color: const Color(0xFF3B5BDB),
                    width: 1.5,
                  )
                      : null,
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
                    // SvgPicture.asset(
                    //   Assets.imagesIcPadel,
                    //   height: 18, // Add this line - adjust value as needed
                    //   color: controller.selectedSportTab.value == 0
                    //       ? const Color(0xFF3B5BDB)
                    //       : const Color(0xFF252525),
                    // ),
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: controller.selectedTab.value == 0
                            ?Colors.white
                            : const Color(0xFF252525),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      child: const Text('Live Match'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pickleball Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: controller.selectedTab.value == 1
                      ? AppColors.primaryColor
                      : Colors.transparent,
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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: controller.selectedTab.value == 1
                            ? Colors.white
                            : const Color(0xFF252525),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      child: const Text('Leader Board'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
  Widget _liveMatchCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Stack(
            children: [
              SvgPicture.asset(Assets.imagesFipPromesisBg,fit: BoxFit.cover,width: Get.width,),
              Column(
                children: [
                  /// LIVE TAG
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
                  ).paddingOnly(top: 10),
                  /// SCORE ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _teamColumn("Team A",
                        "https://i.pravatar.cc/150?img=1",
                        "https://i.pravatar.cc/150?img=2",
                        "Eleanor Pena",
                        "Kristin Watson",
                        AppColors.primaryColor,),

                      Transform.translate(
                        offset: Offset(0, 8),
                        child: Text(
                            "2 : 0",
                            style: Get.textTheme.titleLarge!.copyWith(color: AppColors.blackColor,fontSize: 42)),
                      ),
                      _teamColumn("Team B",
                          "https://i.pravatar.cc/150?img=3",
                          "https://i.pravatar.cc/150?img=4",
                          "Theresa Webb",
                          "Ronald Richards",
                          AppColors.secondaryColor),
                    ],
                  ),
                  GestureDetector(
                    onTap: (){
                      Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
                        "matchType":"live"
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: const Color(0xff27AE60),
                          borderRadius:
                          BorderRadius.circular(30)),
                      child:  Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.primaryColor,
                            child: Icon(Icons.play_arrow,
                                color: Colors.white, size: 18),
                          ),
                          SizedBox(width: 8),
                          Text("Watch Live",
                              style: Get.textTheme.labelMedium!.copyWith(color: Colors.white,fontWeight: FontWeight.w500))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamColumn(
      String team,
      String img1,
      String img2,
      String name1,
      String name2,
      Color color,
      ) {
    return SizedBox(
      width: 130,
      child: Column(
        children: [
          /// TEAM LABEL
          Text(
            team,
              style:Get.textTheme.headlineMedium!.copyWith(color: color)

          ),

          const SizedBox(height: 15),

          /// STACKED AVATARS
          SizedBox(
            height: 40,
            width: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _avatar(img1, 0),
                _avatar(img2, 24),
              ],
            ),
          ),


          /// NAMES
          Text(
              "$name1 &\n$name2",
              textAlign: TextAlign.center,
              style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
  Widget _avatar(String url, double left) {
    return Positioned(
      left: left,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _upcomingList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) =>
      GestureDetector(
          onTap: (){
            Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
              "matchType":"upcoming"
            });
          },
          child: const UpcomingMatchCard()),
    );
  }
  Widget _liveList() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) =>
          GestureDetector(
              onTap: (){
                Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
                  "matchType":"live"
                });
              },
              child: const LiveMatchCard()),
    );
  }
  Widget _resultsList() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, index) =>
      GestureDetector(
          onTap: (){
            Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
              "matchType":"result"
            });
          },
          child: const ResultMatchCard()),
    );
  }
}

class UpcomingMatchCard extends StatelessWidget {
  const UpcomingMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 25,
            width: 140,
            decoration: const BoxDecoration(
              color: Color(0xff2E4DB7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
                "05Jun, 2025",
                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
            ),
          ),
          /// MAIN Container
          ClipPath(
            clipper: MatchCardClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffFFFFFF),
                    Color(0xffCBD6FF),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -10,
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,),
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Text(
                              "Team A",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)
                          ),
                          const Spacer(),
                          Text(
                              "Team B",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar("https://i.pravatar.cc/150?img=1", 0,0),
                                    _avatar("https://i.pravatar.cc/150?img=1", 12,8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              Text(
                                  "Eleanor Pena \nKristin Watson",
                                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
                              ),
                            ],
                          ),
                          SvgPicture.asset(Assets.imagesImgVs,),
                          Row(
                            children: [
                              Text(
                                  "Theresa Webb \nRonald Richards",
                                  textAlign: TextAlign.right,
                                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar("https://i.pravatar.cc/150?img=1", 12,0),
                                    _avatar("https://i.pravatar.cc/150?img=1", 0,8),
                                  ],
                                ),
                              ).paddingOnly(left: 5),
                            ],
                          ),
                        ],
                      )
                    ],
                  ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _avatar(String url, double left,double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
class LiveMatchCard extends StatelessWidget {
  const LiveMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 25,
            width: 140,
            decoration: const BoxDecoration(
              color: AppColors.liveMatchRed,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                    "Live",
                    style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
                ),
              ],
            ),
          ),
          /// MAIN Container
          ClipPath(
            clipper: MatchCardClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffFFFFFF),
                    Color(0xffFFC6C2),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -10,
                    child: SvgPicture.asset(
                      Assets.imagesDotsFipPromises,
                      height: 100,
                      width: 100,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(
                      Assets.imagesDotsFipPromises,
                      height: 100,
                      width: 100,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    )
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Text(
                              "Team A",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                          const Spacer(),
                          Text(
                              "Team B",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar("https://i.pravatar.cc/150?img=1", 0,0),
                                    _avatar("https://i.pravatar.cc/150?img=1", 12,8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              Text(
                                  "Eleanor Pena \nKristin Watson",
                                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text("2", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                              const SizedBox(width: 6),
                              Text(":", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                              const SizedBox(width: 6),
                              Text("0", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                  "Theresa Webb \nRonald Richards",
                                  textAlign: TextAlign.right,
                                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar("https://i.pravatar.cc/150?img=1", 12,0),
                                    _avatar("https://i.pravatar.cc/150?img=1", 0,8),
                                  ],
                                ),
                              ).paddingOnly(left: 5),
                            ],
                          ),
                        ],
                      )
                    ],
                  ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _avatar(String url, double left,double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
class ResultMatchCard extends StatelessWidget {
  const ResultMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 25,
            width: 140,
            decoration: const BoxDecoration(
              color: Color(0xff494949),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
                "05Jun, 2025",
                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
            ),
          ),
          /// MAIN Container
          ClipPath(
            clipper: MatchCardClipper(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffFFFFFF),
                    Color(0xffF5F5F5),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -10,
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF494949),
                        BlendMode.srcIn,
                      ),),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100, colorFilter: const ColorFilter.mode(
                      Color(0xFF494949),
                      BlendMode.srcIn,
                    ),),
                  ),
                  Column(
                    children: [
                      /// DATE + UPCOMING
                      Row(
                        children: [
                          Text(
                              "Team A",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                          const Spacer(),
                          Text(
                              "Team B",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar("https://i.pravatar.cc/150?img=1", 0,0),
                                    _avatar("https://i.pravatar.cc/150?img=1", 12,8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              Text(
                                  "Eleanor Pena \nKristin Watson",
                                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Text("2", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                              const SizedBox(width: 6),
                              Text(":", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                              const SizedBox(width: 6),
                              Text("0", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                            ],
                          ),

                          Row(
                            children: [
                              Text(
                                  "Theresa Webb \nRonald Richards",
                                  textAlign: TextAlign.right,
                                  style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar("https://i.pravatar.cc/150?img=1", 12,0),
                                    _avatar("https://i.pravatar.cc/150?img=1", 0,8),
                                  ],
                                ),
                              ).paddingOnly(left: 5),
                            ],
                          ),
                        ],
                      )
                    ],
                  ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _avatar(String url, double left,double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class LeaderBoardWidget extends StatelessWidget {
  const LeaderBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 1.5,
                    blurRadius: 5.0,
                  offset: Offset(0, 3)
                )
              ]
          ),
          child: Column(
            children: [
              /// Header Row
              _headerRow(),

              Divider(color: Colors.grey.shade300,),

              /// List
              ...List.generate(6, (index) {
                return Column(
                  children: [
                    _teamRow(index + 1),
                    Divider(color: Colors.grey.shade300,),
                  ],
                );
              }),
            ],
          ),
        ).paddingOnly(bottom: 20),
        BuildSponsorBanner(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Upcoming Matches",
              style: Get.textTheme.headlineMedium,
            ),
            GestureDetector(
              onTap: () {
                Get.toNamed(RoutesName.leagueMatchLists,arguments: {
                  'matchTab': 0
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Text(
                  "See all",
                  style: Get.textTheme.labelLarge!
                      .copyWith(color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ).paddingSymmetric(horizontal: 18,vertical: 8),
        _upcomingList()
      ],
    );
  }

  Widget _headerRow() {
    final style = Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500);
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 20, child: Text("#",style: style,)),
        Expanded(
            flex: 3,
            child: SizedBox(width: 35,child: Text("Teams",style: style))),
        SizedBox(width: 30, child: Text("M",style: style)),
        SizedBox(width: 30, child: Text("W",style: style)),
        SizedBox(width: 30, child: Text("L",style: style)),
        SizedBox(width: 30, child: Text("PTS",style: style)),
        SizedBox(width: 30, child: Text("A/B",style: style)),
        SizedBox(width: 30, child: Text("C/D",style: style)),
        SizedBox(width: 30, child: Text("MX",style: style)),
        SizedBox(width: 30, child: Text("WM",style: style)),
      ],
    );
  }

  Widget _teamRow(int index) {
    List<String> teams = [
      "Terrakort",
      "Padel Haus",
      "Courtline",
      "Terrakort",
      "Padel Haus",
      "Courtline"
    ];

    return Row(
      children: [
        SizedBox(width: 25, child: Text("$index",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600),)),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black12,
                backgroundImage: NetworkImage(
                  "https://images.unsplash.com/photo-1599058917765-a780eda07a3e",
                ),
              ),
              const SizedBox(width: 8),
              Text(
                teams[index - 1],
                style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

         SizedBox(width: 30, child: Text("30",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("15",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("15",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("30", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600))),
         SizedBox(width: 30, child: Text("10",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("10",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("05",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
         SizedBox(width: 30, child: Text("05",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),)),
      ],
    );
  }
  Widget _upcomingList() {
    return Expanded(
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) =>
            GestureDetector(
                onTap: (){
                  Get.toNamed(RoutesName.liveAndCompleteLeagueMatch,arguments: {
                    "matchType":"upcoming"
                  });
                },
                child: const UpcomingMatchCard()),
      ),
    );
  }
}

