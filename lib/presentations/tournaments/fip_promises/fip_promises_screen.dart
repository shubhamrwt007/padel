import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/tournaments/fip_promises/fip_promises_controller.dart';
class FipPromisesScreen extends StatelessWidget {
  final FipPromisesController controller =Get.put(FipPromisesController());
  FipPromisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(title: Text("FIP Promises"),centerTitle: true, context: context,
      action: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xffE3E8F8),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Icon(Icons.list, size: 20,color: Color(0xff2E4DB7)),
        )
      ]
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabSelector(),
          _liveMatchCard().paddingOnly(top: 20),
         Text(
             "Upcoming  Matches",
             style: Get.textTheme.headlineMedium
         ).paddingOnly(left: 16,top: 10,bottom: 10),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context,index){
                return UpcomingMatchCard();
              },
            ),
          ),

        ],
      ),
    );
  }
  /// TAB SELECTOR
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamColor,
        borderRadius: BorderRadius.circular(18),
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
          decoration:  BoxDecoration(
            // gradient: LinearGradient(
            //   colors: [
            //     Color(0xff1f41bb).withValues(alpha: 0.2),
            //     Colors.white,
            //     Colors.white.withValues(alpha: 0.5),
            //     Color(0xff3dbe64).withValues(alpha: 0.2),
            //   ],
            // ),
          ),
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
                      _teamColumn("A1",
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
                      _teamColumn("A2",
                          "https://i.pravatar.cc/150?img=3",
                          "https://i.pravatar.cc/150?img=4",
                          "Theresa Webb",
                          "Ronald Richards",
                          AppColors.secondaryColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// WATCH LIVE BUTTON
        GestureDetector(
          onTap: (){
            Get.toNamed(RoutesName.liveTournament);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 40, vertical: 10),
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

        // /// INDICATORS
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     _dot(true),
        //     _dot(false),
        //     _dot(false),
        //   ],
        // )
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
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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

          /// MAIN Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xffF2F4F9),
                  Color(0xffDCE4F7),
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
                      "05Jun, 2025",
                      style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: Text(
                        "Upcoming",
                          style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: AppColors.primaryColor)
                      ),
                    )
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Eleanor Pena &\nKristin Watson",
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)
                      ),
                    ),
                    Text(
                      "A1",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E4DB7),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "vs",
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "A2",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E4DB7),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Theresa Webb &\nRonald Richards",
                        textAlign: TextAlign.right,
                        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                )
              ],
            ).paddingOnly(top: 10,left: 20,bottom: 10,right: 20),
            ],
            ),
          ),
/// BLUE COURT TAB (fills notch)
          Container(
            height: 30,
            width: 100,
            decoration: const BoxDecoration(
              color: Color(0xff2E4DB7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "Court 1",
              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }
}
class _DotsPattern extends StatelessWidget {
  final Alignment alignment;

  const _DotsPattern({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          20,
              (index) => Container(
            width: index % 3 == 0 ? 8 : 6,
            height: index % 3 == 0 ? 8 : 6,
            decoration: BoxDecoration(
              color: const Color(0xff2E4DB7)
                  .withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
class CourtCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double cornerRadius = 28;
    const double notchWidth = 200;
    const double notchDepth = 40;

    final double center = size.width / 2;
    final double notchStart = center - notchWidth / 2;
    final double notchEnd = center + notchWidth / 2;

    Path path = Path();

    /// Top Left Corner
    path.moveTo(cornerRadius, 0);
    path.quadraticBezierTo(0, 0, 0, cornerRadius);

    /// Left Side
    path.lineTo(0, size.height - cornerRadius);
    path.quadraticBezierTo(
        0, size.height, cornerRadius, size.height);

    /// Bottom
    path.lineTo(size.width - cornerRadius, size.height);
    path.quadraticBezierTo(size.width, size.height,
        size.width, size.height - cornerRadius);

    /// Right Side
    path.lineTo(size.width, cornerRadius);
    path.quadraticBezierTo(
        size.width, 0, size.width - cornerRadius, 0);

    /// Move to start of notch
    path.lineTo(notchEnd, 0);

    /// Smooth inward concave curve
    path.cubicTo(
      notchEnd - 20, 0,
      center + 40, notchDepth,
      center, notchDepth,
    );

    path.cubicTo(
      center - 40, notchDepth,
      notchStart + 20, 0,
      notchStart, 0,
    );

    /// Continue top edge
    path.lineTo(cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}