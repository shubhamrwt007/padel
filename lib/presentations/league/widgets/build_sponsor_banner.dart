import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BuildSponsorBanner extends StatelessWidget {
  final dynamic controller;
  const BuildSponsorBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // if (controller.isLoadingSponsors.value) {
      //   return Container(
      //     height: 150,
      //     margin: const EdgeInsets.symmetric(horizontal: 14),
      //     child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
      //   ).paddingOnly(bottom: 10);
      // }

      final sponsorData = controller.sponsors.value?.data;
      if (sponsorData == null) return const SizedBox.shrink();

      return Column(
        children: [
          if (sponsorData.mobileBanner != null)
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 150,
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
                  child: CachedNetworkImage(
                    imageUrl: sponsorData.mobileBanner!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      Assets.imagesImgLeagueSponsor,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ).paddingOnly(bottom: 10),
            ),
          if (sponsorData.sponsors != null && sponsorData.sponsors!.isNotEmpty)
            BuildMoreSponsor(sponsors: sponsorData.sponsors!)
        ],
      ).paddingOnly(bottom: 10);
    });
  }
}

class BuildMoreSponsor extends StatelessWidget {
  final List<dynamic> sponsors;
  const BuildMoreSponsor({super.key, required this.sponsors});

  @override
  Widget build(BuildContext context) {
    if (sponsors.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 30,
      width: Get.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3513EA),
            Color(0xFF002091),
          ],
        ),
      ),
      child: ListView.builder(
        itemCount: sponsors.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final sponsor = sponsors[index];
          return Row(
            children: [
              if (sponsor.logo != null)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: sponsor.logo!,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey,
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ).paddingOnly(right: 5)
              else
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey,
                ).paddingOnly(right: 5),
              Text(
                sponsor.name ?? "Sponsor",
                style: Get.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )
            ],
          ).paddingOnly(right: 8);
        },
      ).paddingOnly(left: 10),
    ).paddingOnly(top: 10);
  }
}

class BuildTitleSponsor extends StatelessWidget {
  final dynamic controller;
  const BuildTitleSponsor({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingSponsors.value) {
        return SizedBox(
          height: 70,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        );
      }

      final sponsorData = controller.sponsors.value?.data;
      if (sponsorData == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text(
              "Sponsors",
              style:
                  Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w400),
            ).paddingOnly(bottom: 6),
            if (sponsorData.titleSponsor?.logo != null)
              CachedNetworkImage(
                imageUrl: sponsorData.titleSponsor!.logo!,
                height: 40,
                placeholder: (context, url) => Container(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  Assets.imagesImgDummyLogo2,
                  height: 40,
                ),
              )
            else
              Image.asset(
                Assets.imagesImgDummyLogo2,
                height: 40,
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: Colors.black26,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (sponsorData.sponsors != null &&
                sponsorData.sponsors!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: () {
                  final items = sponsorData.sponsors!.take(3).toList();
                  final children = <Widget>[];

                  for (final sponsor in items) {
                    children.add(
                      Expanded(
                        child: sponsor.logo != null
                            ? CachedNetworkImage(
                                imageUrl: sponsor.logo!,
                                height: 25,
                                placeholder: (context, url) => Container(
                                  height: 25,
                                  width: 25,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.image_not_supported,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                              )
                            : Icon(
                                Icons.image_not_supported,
                                size: 25,
                                color: Colors.grey,
                              ),
                      ),
                    );
                    children.add(_divider());
                  }

                  if (children.isNotEmpty) children.removeLast();
                  return children;
                }(),
              ),
          ],
        ),
      );
    });
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.black26,
    );
  }
}
