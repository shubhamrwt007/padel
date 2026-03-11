import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/generated/assets.dart';
class BuildSponsorBanner extends StatelessWidget {
  const BuildSponsorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: (){},
          child: Container(
            width: Get.width,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(Assets.imagesImgLeagueSponsor,fit: BoxFit.cover,)),
          ),
        ).paddingOnly(bottom: 10),
        BuildMoreSponsor()
      ],
    ).paddingOnly(bottom: 10);
  }
}
class BuildMoreSponsor extends StatelessWidget {
  const BuildMoreSponsor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: Get.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              Color(0xFF3513EA),
              Color(0xFF002091),
            ]),
      ),
      child: ListView.builder(
        itemCount: 4,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context,index){
          return Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: Colors.grey,
              ).paddingOnly(right: 5),
              Text("Sponsor Name",style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white),)

            ],
          ).paddingOnly(right: 8);
        },
      ).paddingOnly(left: 10),
    ).paddingOnly(top: 10);
  }
}
