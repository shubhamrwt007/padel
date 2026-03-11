import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/league/league_match_lists/league_match_list_controller.dart';
import 'package:padel_mobile/presentations/league/widgets/match_card_clipper.dart';
class LeagueMatchListScreen extends StatelessWidget {
  final LeagueMatchListController controller = Get.put(LeagueMatchListController());
  LeagueMatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(title: Text(
          controller.matchTab.value == 0?
          "Upcoming Matches":
          controller.matchTab.value == 1?
              "Live Matches":"Match Results"
      ),centerTitle: true, context: context),
      body: Obx(() {
        if (controller.matchTab.value == 0) {
          return _upcomingList();
        }
        // else if (controller.matchTab.value == 1) {
          // return _liveList();
        // }
        else {
          return _resultsList();
        }
      }),
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

  // Widget _liveList() {
  //   return ListView.builder(
  //     itemCount: 3,
  //     itemBuilder: (context, index) => const LiveMatchCard(),
  //   );
  // }

  Widget _resultsList() {
    return ListView.builder(
      itemCount: 8,
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

                          Text(
                              "vs",
                              style: Get.textTheme.titleLarge!.copyWith(color: Colors.grey)
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
// class LiveMatchCard extends StatelessWidget {
//   const LiveMatchCard({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//       child: Stack(
//         alignment: Alignment.topCenter,
//         children: [
//
//           /// MAIN Container
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xffFFFFFF),
//                   Color(0xffFFC6C2),
//                 ],
//               ),
//             ),
//             child: Stack(
//               children: [
//                 Positioned(
//                   left: -40,
//                   top: -10,
//                   child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,color: Colors.red,),
//                 ),
//                 Positioned(
//                   right: -30,
//                   bottom: -20,
//                   child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100,color: Colors.red,),
//                 ),
//                 Column(
//                   children: [
//                     /// DATE + UPCOMING
//                     Row(
//                       children: [
//                         Text(
//                             "Team A",
//                             style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
//                         ),
//                         const Spacer(),
//                         Text(
//                             "Team B",
//                             style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
//                         ),
//                       ],
//                     ),
//
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             SizedBox(
//                               height: 30,
//                               width: 40,
//                               child: Stack(
//                                 clipBehavior: Clip.none,
//                                 children: [
//                                   _avatar("https://i.pravatar.cc/150?img=1", 0,0),
//                                   _avatar("https://i.pravatar.cc/150?img=1", 12,8),
//                                 ],
//                               ),
//                             ).paddingOnly(right: 5),
//                             Text(
//                                 "Eleanor Pena \nKristin Watson",
//                                 style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
//                             ),
//                           ],
//                         ),
//                         Row(
//                           children: [
//                             Text("2", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
//                             const SizedBox(width: 6),
//                             Text(":", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
//                             const SizedBox(width: 6),
//                             Text("0", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
//                           ],
//                         ),
//                         Row(
//                           children: [
//                             Text(
//                                 "Theresa Webb \nRonald Richards",
//                                 textAlign: TextAlign.right,
//                                 style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.black)
//                             ),
//                             SizedBox(
//                               height: 30,
//                               width: 40,
//                               child: Stack(
//                                 clipBehavior: Clip.none,
//                                 children: [
//                                   _avatar("https://i.pravatar.cc/150?img=1", 12,0),
//                                   _avatar("https://i.pravatar.cc/150?img=1", 0,8),
//                                 ],
//                               ),
//                             ).paddingOnly(left: 5),
//                           ],
//                         ),
//                       ],
//                     )
//                   ],
//                 ).paddingOnly(top: 10,left: 15,bottom: 10,right: 15),
//               ],
//             ),
//           ),
//           Container(
//             height: 25,
//             width: 100,
//             decoration: const BoxDecoration(
//               color: AppColors.liveMatchRed,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(14),
//                 bottomRight: Radius.circular(14),
//               ),
//             ),
//             alignment: Alignment.center,
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                     "Live",
//                     style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 10)
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _avatar(String url, double left,double top) {
//     return Positioned(
//       left: left,
//       top: top,
//       child: Container(
//         height: 25,
//         width: 25,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: Colors.white,
//             width: 2,
//           ),
//           image: DecorationImage(
//             image: NetworkImage(url),
//             fit: BoxFit.cover,
//           ),
//         ),
//       ),
//     );
//   }
// }
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
                    child: SvgPicture.asset(Assets.imagesDotsFipPromises,height: 100,width: 100, colorFilter: const ColorFilter.mode(
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
