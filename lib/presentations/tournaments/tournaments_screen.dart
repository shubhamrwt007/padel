import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/tournaments/tournaments_controller.dart';
class TournamentsScreen extends StatelessWidget {
  TournamentsScreen({super.key});

  final controller = Get.put(TournamentsController());
  final prizes = ["₹5L", "₹20K", "₹10L", "₹3L", "₹15K"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(title: Text("Tournaments"), centerTitle: true,context: context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabs().paddingOnly(left: Get.width*0.05),
          _sectionTitle("Live Matches", showSeeAll: true).paddingSymmetric(horizontal:Get.width*0.05 ,vertical: 15),
          _liveCarousel().paddingSymmetric(horizontal:Get.width*0.05 ),
          _sectionTitle("Upcoming Tournaments", showSeeAll: false).paddingSymmetric(horizontal:Get.width*0.05 ,vertical: 15),
          Expanded(
            child: ListView.builder(
              itemCount: prizes.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: index < prizes.length - 1 ? 18 : 0),
                child: TournamentCard(prize: prizes[index]),
              ),
            ).paddingSymmetric(horizontal:Get.width*0.05 ),
          )
        ],
      ),
    );
  }


  Widget _tabs() {
    final tabs = [
      "FIP Promises",
      "FIP Silver Hyderabad",
      "FIP Silver Hyderabad",
    ];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(right: index < tabs.length - 1 ? 12 : 0),
          child: _tabItem(tabs[index], index),
        ),
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Obx(() => Container(
        padding: EdgeInsets.symmetric(horizontal: 8,vertical: 5),
        decoration: BoxDecoration(
          color: controller.selectedTab.value == index
              ? AppColors.primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color:controller.selectedTab.value == index?Colors.transparent: Colors.grey.shade300),
          boxShadow:  [
            controller.selectedTab.value == index? BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4)):BoxShadow()
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage("https://images.unsplash.com/photo-1599058917765-a780eda07a3e"),
            ).paddingOnly(right: 5),
            Text(
              title,
              style:
              Get.textTheme.bodySmall!.copyWith(
                color: controller.selectedTab.value == index
                  ? Colors.white
                  : Colors.black87,
                fontWeight: FontWeight.w500,)
            ),
          ],
        ),
      )),
    );
  }

  Widget _sectionTitle(String title, {required bool showSeeAll}) {
    return Row(
      children: [
        Text(title, style: Get.textTheme.headlineMedium),
        const Spacer(),
        if (showSeeAll)
          Text("See all",
              style: Get.textTheme.labelLarge!
                  .copyWith(color: AppColors.primaryColor))
      ],
    );
  }

  Widget _liveCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller.pageController,
            onPageChanged: (index) => controller.changeLiveIndex(index),
            clipBehavior: Clip.none,
            itemBuilder: (context, index) => GestureDetector(
                onTap: (){
                  Get.toNamed(RoutesName.fipPromises);
                },
                child: const LiveMatchCard()),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin:
              const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width:
              controller.currentLiveIndex.value == index
                  ? 24
                  : 8,
              decoration: BoxDecoration(
                color:
                controller.currentLiveIndex.value ==
                    index
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ))
      ],
    );
  }
}
class LiveMatchCard extends StatelessWidget {
  const LiveMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow:  [
            BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: Offset(0, 6))
          ],
          image: const DecorationImage(
            image: NetworkImage(
                "https://images.unsplash.com/photo-1599058917765-a780eda07a3e"),
            fit: BoxFit.cover,
          ),
        ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(.75),
              Colors.transparent
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "LIVE TOURNAMENT",
                style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.white)),
              ).paddingOnly(top: 5),
            const Spacer(),
            Text("FIP Promises",
                style: Get.textTheme.titleMedium!.copyWith(fontSize: 22,color: Colors.white)),
            const SizedBox(height: 4),
             Text("Court 1 . Semifinals",
                style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(Assets.imagesIcLocation, scale: 3, color: AppColors.whiteColor),
                    const SizedBox(width: 4),
                    Text(
                      "Chandigarh",
                      style: Get.textTheme.bodyLarge!
                          .copyWith(fontSize: 11,color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
                      SizedBox(width: 4),
                      Text("Watch Live",
                          style: Get.textTheme.labelMedium!.copyWith(color: Colors.white,fontWeight: FontWeight.w500))
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
class TournamentCard extends StatelessWidget {
  final String prize;
  const TournamentCard({super.key, required this.prize});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6))
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFCBD6FF).withValues(alpha: 0.1)
                      ],
                    begin: AlignmentGeometry.centerLeft,
                    end: AlignmentGeometry.centerRight
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Championship 2026",
                          style: Get.textTheme.headlineMedium,
                        ).paddingOnly(top: 5),
                        Row(
                          children: [
                            Text("21 June, 2026",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: AppColors.primaryColor),),
                            Row(
                              children: [
                                const Text(
                                  " |",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Text("Professional",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,)),
                                Text(" | Mixed",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,)),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow:  [
                          BoxShadow(
                              color: AppColors.greyColor,
                              blurRadius: 7,
                              offset: Offset(0, 6))
                        ],
                      ),
                      child: Icon(Icons.share,
                          size: 18,
                          color: AppColors.primaryColor),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 12),
                child: Row(
                  children: [
                    _avatars(),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("2 Days Left",
                            style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.red,fontSize: 10) ),
                        Text(
                          "For Registration",
                          style: Get.textTheme.bodySmall!.copyWith(fontSize: 8),
                        )
                      ],
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFCBD6FF).withValues(alpha: 0.1)
                      ],
                      begin: AlignmentGeometry.centerLeft,
                      end: AlignmentGeometry.centerRight
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "SPONSORED BY",
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: AppColors.labelBlackColor)),
                        const SizedBox(width: 16),
                        _sponsorChip(),
                        const SizedBox(width: 10),
                        _sponsorChip(),
                        const SizedBox(width: 10),
                        _sponsorChip(),
                      ],
                    ).paddingOnly(bottom: 5,top: 5),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Divider(color: AppColors.primaryColor.withValues(alpha: 0.4),thickness: 0.5,),
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                              Text("The Good Club",
                                                 style: Get.textTheme.bodySmall!.copyWith(fontWeight:
                                                 FontWeight.w600)),
                                             const SizedBox(height: 4),
                                             Row(
                                               children: [
                                                 Image.asset(Assets.imagesIcLocation, scale: 3,color: AppColors.primaryColor,),
                                                 const SizedBox(width: 4),
                                                 Text(
                                                   "Chandigarh",
                                                   style: Get.textTheme.bodyLarge!
                                                       .copyWith(fontSize: 11),
                                                 ),
                                               ],
                                             ),
                                           ],
                                         ),
                                         Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                              Text("Prize Pool",
                                                 style: Get.textTheme.displayLarge!.copyWith(fontSize: 8,color: AppColors.textColor)),
                                             Text(prize,
                                                 style: const TextStyle(
                                                     fontSize: 24,
                                                     fontWeight:
                                                     FontWeight.bold,
                                                     color:AppColors.primaryColor))
                                           ],
                                         )
                                       ],
                                     ),
                                   ],
                                 ),
                  ],
                ),
              )
            ],
          ),
          Container(
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            alignment: Alignment.center,
            child:  Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "JOIN TOURNAMENT",
                  style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white)).paddingOnly(right: 4),
                Icon(Icons.arrow_forward,color: Colors.white,size: 18,)
              ],
            ),
            ),
        ],
      ),
    ));
  }
  Widget _sponsorChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xffE3E8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Nike Sports",
        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: AppColors.primaryColor)
      ),
    );
  }
  static Widget _avatars() {
    return Container(
      padding: EdgeInsets.only(right: 8,top: 1,bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(30),
        boxShadow:  [
          BoxShadow(
              color: AppColors.greyColor,
              blurRadius: 10,
              offset: Offset(0, 6))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8 * 19.0 + 32, // overlap: 8 avatars * step + plus button
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _circle("https://randomuser.me/api/portraits/women/11.jpg", 0,),
                _circle("https://randomuser.me/api/portraits/women/12.jpg", 24,),
                _circle("https://randomuser.me/api/portraits/men/13.jpg",   48,),
                _circle("https://randomuser.me/api/portraits/men/14.jpg",   72,),
                _circle("https://randomuser.me/api/portraits/women/15.jpg", 96,),
                _circle("https://randomuser.me/api/portraits/men/16.jpg",  120,),
                _plusCircle(148),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "20 Slots\nLeft",
            style: Get.textTheme.displayLarge!.copyWith(color: AppColors.primaryColor,fontSize: 11)
          ),
        ],
      ),
    );
  }

  static Widget _circle(String url, double left) {
    return Positioned(
      left: left,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondaryColor, width: 1),
          color: Colors.white,
        ),
        child: ClipOval(
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  static Widget _plusCircle(double left) {
    return Positioned(
      left: left,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryColor, width: 1),
          color: AppColors.textFieldColor,
        ),
        child: Icon(Icons.add, color: AppColors.primaryColor, size: 20),
      ),
    );
  }
}