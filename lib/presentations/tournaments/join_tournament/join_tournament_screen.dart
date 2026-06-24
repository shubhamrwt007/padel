import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/booking/americano/container_clipper.dart';
import 'package:padel_mobile/presentations/tournaments/join_tournament/join_tournament_controller.dart';
import 'package:padel_mobile/presentations/tournaments/number_verify_bottomsheet/number_verify_bottom_sheet.dart';
class JoinTournamentScreen extends StatelessWidget {
  final JoinTournamentController controller = Get.put(JoinTournamentController());
  JoinTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(title: Text("Championship 2026"), centerTitle: true,context: context,
          action: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.textFieldColor,
              child: const Icon(Icons.share, size: 18,color: AppColors.primaryColor,),
            )
          ]
      ),
      bottomNavigationBar:   _bottomButton(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Top Image Section
            _buildHeader(),
            _buildLogoRow(),

            /// 🔹 Details Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Get.width*0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsCard().paddingOnly(bottom: Get.height*0.01),
                  /// 🔹 Slots
                  _buildSlots().paddingOnly(bottom: Get.height*0.01),
                  /// 🔹 Prize Section
                  _buildPrizes(),

                  const SizedBox(height: 15),

                  /// 🔹 Players
                  Text("All Players",
                      style: Get.textTheme.headlineMedium).paddingOnly(bottom: Get.height*0.01),

                  Obx(() => Column(
                    children: controller.teams
                        .map((team) => buildTeamCard(
                      teamName: "Team A",
                      leftPlayers: ["Eleanor Pena", "Kristin Watson"],
                      rightPlayers: ["Eleanor Pena", "Kristin Watson"],
                      leftImages: [
                        "https://i.pravatar.cc/150?img=12",
                        "https://i.pravatar.cc/150?img=13",
                      ],
                      rightImages: [
                        "https://i.pravatar.cc/150?img=14",
                        "https://i.pravatar.cc/150?img=15",
                      ],
                    ),)
                        .toList(),
                  )),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _bottomButton(BuildContext context){
    return Container(
      height: Get.height * .09,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomButton(
        width: Get.width * 0.9,
        child: Text(
          "Join Tournament",
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.whiteColor),
        ).paddingOnly(right: Get.width * 0.14),
        onTap: () {
          Get.bottomSheet(
            NumberVerifyBottomSheet(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
      ).paddingOnly(bottom: 0),
    );
  }
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width*0.05),
      child: Stack(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
                borderRadius:  BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: .4),
              image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(
                  "https://images.unsplash.com/photo-1599058917765-a780eda07a3e"))
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:  BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: .4),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children:  [
                Container(
                  decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                    borderRadius: BorderRadius.circular(20)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12,vertical: 4),
                  child: Text("Upcoming",
                      style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500,color: Colors.white)),
                ),
                SizedBox(height: 10),
                Text("Championship 2026",
                    style: Get.textTheme.titleMedium!.copyWith(color: Colors.white)),
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _buildLogoRow() {
    final logos = [
      "https://i.pravatar.cc/150?img=1",
      "https://i.pravatar.cc/150?img=2",
      "https://i.pravatar.cc/150?img=3",
      "https://i.pravatar.cc/150?img=4",
      "https://i.pravatar.cc/150?img=5",
    ];
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: logos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(logos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "Your Logo",
                style: Get.textTheme.labelMedium
              )
            ],
          );
        },
      ),
    ).paddingOnly(left: Get.width*0.05);
  }
  Widget _buildDetailsCard() {
    return ClipPath(
      clipper: ContainerClipper(notchOffsetFromCenter: 52),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14,vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.greyColor),
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            _row("Tournament Name", "Championship 2026"),
            _row("Date", "21 June, 2026"),
            _row("Duration", "3 Hours"),
            _row("Match Level", "Professional"),
            _row("Gender", "Mixed"),
            _row("Last Joining Date", "12 June, 2026"),
            Dash(
              direction: Axis.horizontal,
              length: 320,
              dashLength: 12,
              dashColor: AppColors.primaryColor,
            ).paddingOnly(top: 10,bottom: 5),
            _row("Your Share", "₹5,000",
                valueColor: AppColors.primaryColor,
                valueFontSize: 20,
                titleFontSize: 13,
                titleFontWeight: FontWeight.w600,
                titleTextColor: Colors.black,
                fontWeight: FontWeight.bold),
          ],
        ),
      ),
    );
  }
  Widget _row(String title, String value,
      {Color? valueColor, FontWeight? fontWeight,double? valueFontSize,FontWeight? titleFontWeight ,double? titleFontSize,Color? titleTextColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Get.textTheme.labelSmall!.copyWith(color:titleTextColor?? AppColors.textColor,fontWeight:titleFontWeight ?? FontWeight.w500,fontSize:titleFontSize??11 )),
          Text(value,
              style: Get.textTheme.bodySmall!.copyWith( color: valueColor ?? Colors.black,
                  fontWeight: fontWeight ?? FontWeight.w500,fontSize: valueFontSize??12))
        ],
      ),
    );
  }
  Widget _buildSlots() {
    return ClipPath(
      clipper: ContainerClipper(notchOffsetFromCenter: 0),
      child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              color: AppColors.primaryColor.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blackColor.withAlpha(10))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Members",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: AppColors.labelBlackColor),),
              RichText(text: TextSpan(
                children: [
                  TextSpan(
                    text: "10/ ",style: Get.textTheme.labelLarge!.copyWith(color: Colors.black),
                  ),
                  TextSpan(
                    text: "2 left",style: Get.textTheme.labelLarge!.copyWith(color: Colors.red),
                  ),
                ]
              ))
            ],
          )),
    );
  }
  Widget _buildPrizes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _prizeCard("1st Place", "₹25,000",svgPath: Assets.images.icFirstPlace.path),
        _prizeCard("2nd Place", "₹15,000",svgPath: Assets.images.icSecondPlace.path),
        _prizeCard("3rd Place", "₹10,000",svgPath: Assets.images.icThirdPlace.path),
      ],
    );
  }
  Widget _prizeCard(String title, String amount,{required String svgPath}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4,vertical: 0),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.greyColor),
            borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            Positioned(
                bottom: 0,
                right: -5,
                child: SvgPicture.asset(Assets.images.icBall.path)),
            Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      svgPath,
                      height: 28,
                      width: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(title,
                        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(amount,
                        style: Get.textTheme.labelLarge!.copyWith(color: AppColors.primaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildTeamCard({
    required String teamName,
    required List<String> leftPlayers,
    required List<String> leftImages,
    required List<String> rightPlayers,
    required List<String> rightImages,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          /// 🔹 Left Side
          _playerSide(leftPlayers, leftImages, isLeft: true),

          /// 🔹 Center Team Button
          _teamButton(teamName),

          /// 🔹 Right Side
          _playerSide(rightPlayers, rightImages, isLeft: true),
        ],
      ),
    );
  }
  Widget _playerSide(
      List<String> names,
      List<String> images, {
        required bool isLeft,
      }) {
    return Row(
      children: [
        if (isLeft) _stackedAvatars(images),

        Column(
          crossAxisAlignment:
          isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: names
              .map(
                (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                e,
                style: Get.textTheme.labelMedium!.copyWith(fontSize: 10)
              ),
            ),
          )
              .toList(),
        ),


        if (!isLeft) _stackedAvatars(images),
      ],
    );
  }
  Widget _stackedAvatars(List<String> images) {
    return SizedBox(
      width: 60,
      height: 55,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: _avatar(images[0]),
          ),
          Positioned(
            left: 4,
            top: 20,
            child: _avatar(images[1]),
          ),
        ],
      ),
    );
  }
  Widget _teamButton(String teamName) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xff2F49B5),
        borderRadius: BorderRadius.circular(16), // 👈 THIS is the key
      ),
      child: Text(
        teamName,
        style:Get.textTheme.labelMedium!.copyWith(fontSize: 9,color: Colors.white)
      ),
    );
  }
  Widget _avatar(String image) {
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 2),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}