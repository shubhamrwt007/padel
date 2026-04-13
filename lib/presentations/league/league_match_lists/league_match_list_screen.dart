import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/league/league_match_lists/league_match_list_controller.dart';
import 'package:padel_mobile/presentations/league/widgets/match_card_clipper.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
class LeagueMatchListScreen extends StatelessWidget {
  final LeagueMatchListController controller = Get.put(LeagueMatchListController());
  LeagueMatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
        title: Text(
          controller.matchTab.value == 0?
          "Upcoming Matches":
          controller.matchTab.value == 1?
              "Live Matches":"Match Results"
        ),
        // centerTitle: true,
        context: context,
        action: [
          PopupMenuButton<String>(
            offset: const Offset(0, 30),
            onSelected: (date) => controller.updateDate(date),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4,horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.textFieldColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Colors.black,
                size: 20,
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: '',
                height: 40,
                child: Obx(() => Text(
                  'All Dates',
                  style: Get.textTheme.labelSmall?.copyWith(
                    color: controller.selectedDate.value.isEmpty
                        ? AppColors.primaryColor
                        : Colors.black,
                    fontWeight: controller.selectedDate.value.isEmpty
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                )),
              ),
              ...controller.availableDates.map((date) {
                return PopupMenuItem(
                  value: date,
                  height: 40,
                  child: Obx(() => Text(
                    _formatDate(date),
                    style: Get.textTheme.labelSmall?.copyWith(
                      color: controller.selectedDate.value == date
                          ? AppColors.primaryColor
                          : Colors.black,
                      fontWeight: controller.selectedDate.value == date
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  )),
                );
              }).toList(),
            ],
          ).paddingOnly(right: 5),
          Obx(() => Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(vertical: 2,horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.textFieldColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => controller.updateFilter('all'),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: controller.selectedFilter.value == 'all' ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: controller.selectedFilter.value == 'all' ? AppColors.whiteColor : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => controller.updateFilter('my'),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: controller.selectedFilter.value == 'my' ? AppColors.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'My',
                      style: TextStyle(
                        color: controller.selectedFilter.value == 'my' ? AppColors.whiteColor : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.matchTab.value == 0) {
          return _upcomingList();
        }
        else {
          return _resultsList();
        }
      }),
    );
  }
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  Widget _upcomingList() {
    return Obx(() {
      if (controller.isLoadingUpcomingMatches.value) {
        return Center(child: LoadingWidget(color: AppColors.primaryColor,));
      }

      final scheduleData = controller.upcomingMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchUpcomingMatches,
          child: Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchUpcomingMatches,
          child: Center(
            child: Text(
              "No upcoming matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.white,
        onRefresh: controller.fetchUpcomingMatches,
        child: ListView.builder(
          itemCount: allMatches.length,
          itemBuilder: (context, index) {
            final matchData = scheduleData.firstWhere(
              (data) => data.matches?.contains(allMatches[index]) ?? false,
              orElse: () => scheduleData.first,
            );
            return GestureDetector(
              onTap: () {
                // final matchData = scheduleData.firstWhere(
                //   (data) => data.matches?.contains(allMatches[index]) ?? false,
                //   orElse: () => scheduleData.first,
                // );
                // Get.toNamed(RoutesName.liveAndCompleteLeagueMatch, arguments: {
                //   "matchType": "upcoming",
                //   "matchId": matchData.matchId ?? ""
                // });
              },
              child: UpcomingMatchCard(
                match: allMatches[index],
                categoryType: matchData.categoryType,
                date: matchData.date,
              ),
            );
          },
        ),
      );
    });
  }

  // Widget _liveList() {
  //   return ListView.builder(
  //     itemCount: 3,
  //     itemBuilder: (context, index) => const LiveMatchCard(),
  //   );
  // }

  Widget _resultsList() {
    return Obx(() {
      if (controller.isLoadingResultMatches.value) {
        return Center(child: LoadingWidget(color: AppColors.primaryColor,));
      }

      final scheduleData = controller.resultMatches.value?.data ?? [];
      if (scheduleData.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchResultMatches,
          child: Center(
            child: Text(
              "No result matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      final allMatches = scheduleData.expand((data) => data.matches ?? []).toList();
      if (allMatches.isEmpty) {
        return RefreshIndicator(
          color: Colors.white,
          onRefresh: controller.fetchResultMatches,
          child: Center(
            child: Text(
              "No result matches available",
              style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: Colors.white,
        onRefresh: controller.fetchResultMatches,
        child: ListView.builder(
          itemCount: allMatches.length,
          itemBuilder: (context, index) {
            final matchData = scheduleData.firstWhere(
              (data) => data.matches?.contains(allMatches[index]) ?? false,
              orElse: () => scheduleData.first,
            );
            return GestureDetector(
              onTap: () {
                final matchData = scheduleData.firstWhere(
                  (data) => data.matches?.contains(allMatches[index]) ?? false,
                  orElse: () => scheduleData.first,
                );
                Get.toNamed(RoutesName.liveAndCompleteLeagueMatch, arguments: {
                  "matchType": "result",
                  "matchId": matchData.matchId?.id ?? ""
                });
              },
              child: ResultMatchCard(
                match: allMatches[index],
                categoryType: matchData.categoryType,
                date: matchData.date,
                setsWon: matchData.matchId?.setsWon,
              ),
            );
          },
        ),
      );
    });
  }
}

class UpcomingMatchCard extends StatelessWidget {
  final dynamic match;
  final String? categoryType;
  final String? date;
  
  const UpcomingMatchCard({super.key, this.match, this.categoryType, this.date});

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    
    final teamAPlayers = match?.teamA?.players ?? [];
    final teamBPlayers = match?.teamB?.players ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
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
                _formatDate(date ?? ""),
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
                          Container(
                            color: Colors.transparent,
                            width: Get.width*0.2,
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                                match?.teamA?.clubType ?? "",
                                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)
                            ),
                          ),
                          const Spacer(),
                          Container(
                            color: Colors.transparent,
                            width: Get.width*0.2,
                            child: Text(
                              overflow: TextOverflow.ellipsis,
                                match?.teamB?.clubType ?? "",
                                style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: AppColors.primaryColor)
                            ),
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
                                    _avatar(teamAPlayers.isNotEmpty ? teamAPlayers[0].playerName ?? "" : "Player 1", 0, 0),
                                    _avatar(teamAPlayers.length > 1 ? teamAPlayers[1].playerName ?? "" : "Player 2", 12, 8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (match?.teamA?.players?.isNotEmpty ?? false)
                                      ? match!.teamA!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    overflow: TextOverflow.ellipsis,
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 1",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 2",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              SvgPicture.asset(Assets.imagesImgVs,).paddingOnly(bottom: 5,top: 5),
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,),
                              Text("${match?.startTime?.split(' ').first??""}-${match?.endTime??""}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w300),),

                            ],
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: (match?.teamB?.players?.isNotEmpty ?? false)
                                      ? match!.teamB!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    overflow: TextOverflow.ellipsis,
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 3",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 4",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatar(teamBPlayers.isNotEmpty ? teamBPlayers[0].playerName ?? "" : "Player 3", 12, 0),
                                    _avatar(teamBPlayers.length > 1 ? teamBPlayers[1].playerName ?? "" : "Player 4", 0, 8),
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
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day.toString().padLeft(2, '0')}${months[date.month - 1]}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _avatar(String name, double left, double top) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

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
          color: AppColors.primaryColor,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  String formatName(String name) {
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts.first} ${parts.last[0]}";
    }
    return name;
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
  final dynamic match;
  final String? categoryType;
  final String? date;
  final SetsWon? setsWon;
  
  const ResultMatchCard({super.key, this.match, this.categoryType, this.date, this.setsWon});

  @override
  Widget build(BuildContext context) {
    if (match == null) return const SizedBox.shrink();
    
    final teamAPlayers = match?.teamA?.players ?? [];
    final teamBPlayers = match?.teamB?.players ?? [];
    
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
                _formatDate(date ?? ""),
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
                              match?.teamA?.clubType ?? "",
                              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                          ),
                          const Spacer(),
                          Text(
                              match?.teamB?.clubType ?? "",
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
                                    _avatarWithInitials(teamAPlayers.isNotEmpty ? teamAPlayers[0].playerName ?? "" : "Player 1", 0, 0),
                                    _avatarWithInitials(teamAPlayers.length > 1 ? teamAPlayers[1].playerName ?? "" : "Player 2", 12, 8),
                                  ],
                                ),
                              ).paddingOnly(right: 5),
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (match?.teamA?.players?.isNotEmpty ?? false)
                                      ? match!.teamA!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    overflow: TextOverflow.ellipsis,
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 1",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 2",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              Row(
                                children: [
                                  Text("${setsWon?.teamA ?? 0}", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                  const SizedBox(width: 6),
                                  Text(":", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                  const SizedBox(width: 6),
                                  Text("${setsWon?.teamB ?? 0}", style: Get.textTheme.titleLarge!.copyWith(color: Colors.black)),
                                ],
                              ),
                              Text(categoryType ?? "Mixed Doubles",style: Get.textTheme.labelMedium,),
                              Text("${match?.startTime?.split(' ').first??""}-${match?.endTime??""}",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w300),),
                            ],
                          ),

                          Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: (match?.teamB?.players?.isNotEmpty ?? false)
                                      ? match!.teamB!.players!
                                      .take(2)
                                      .map<Widget>((e) => Text(
                                    formatName(e.playerName ?? '').capitalizeFirstChar(),
                                    overflow: TextOverflow.ellipsis,
                                    style: Get.textTheme.labelMedium!.copyWith(
                                        fontWeight: FontWeight.w500, color: Colors.black),
                                  ))
                                      .toList()
                                      : [
                                    Text("Player 3",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                    Text("Player 4",
                                        style: Get.textTheme.labelMedium!
                                            .copyWith(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                width: 40,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _avatarWithInitials(teamBPlayers.isNotEmpty ? teamBPlayers[0].playerName ?? "" : "Player 3", 12, 0),
                                    _avatarWithInitials(teamBPlayers.length > 1 ? teamBPlayers[1].playerName ?? "" : "Player 4", 0, 8),
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
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "TBD";
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${date.day.toString().padLeft(2, '0')}${months[date.month - 1]}, ${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _avatarWithInitials(String name, double left, double top) {
    String getInitials(String fullName) {
      if (fullName.trim().isEmpty) return "?";
      final words = fullName.trim().split(' ');
      if (words.length == 1) return words[0][0].toUpperCase();
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    }

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
          color: AppColors.primaryColor,
        ),
        child: Center(
          child: Text(
            getInitials(name),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  String formatName(String name) {
    final parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts.first} ${parts.last[0]}";
    }
    return name;
  }
}

String _getScoreText(dynamic score) {
  if (score == null) return "0";
  if (score is int) return score.toString();
  if (score is ScoreDetail) return (score.sets ?? 0).toString();
  return "0";
}
