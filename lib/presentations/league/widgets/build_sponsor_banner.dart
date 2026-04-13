import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/presentations/main_home_page/widgets/league_sponsor_widgets.dart';

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
          if (sponsorData.titleSponsor?.titleSponsorBanner != null)
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
                    imageUrl: sponsorData.titleSponsor!.titleSponsorBanner!,
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

class BuildMoreSponsor extends StatefulWidget {
  final List<dynamic> sponsors;
  const BuildMoreSponsor({super.key, required this.sponsors});

  @override
  State<BuildMoreSponsor> createState() => _BuildMoreSponsorState();
}

class _BuildMoreSponsorState extends State<BuildMoreSponsor> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    while (mounted) {
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 20).toInt()),
        curve: Curves.linear,
      );
      if (!mounted) break;
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier3Sponsors = widget.sponsors
        .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 3')
        .toList();

    if (tier3Sponsors.isEmpty) return const SizedBox.shrink();

    final loopedSponsors = [...tier3Sponsors, ...tier3Sponsors, ...tier3Sponsors];

    return Container(
      height: 30,
      width: Get.width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3513EA), Color(0xFF002091)],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: loopedSponsors.length,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final sponsor = loopedSponsors[index];
          return Row(
            children: [
              if (sponsor.logo != null)
                CachedNetworkImage(
                  imageUrl: sponsor.logo!,
                  // width: 20,
                  // height: 20,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                ).paddingOnly(right: 5)
              else
                const CircleAvatar(radius: 10, backgroundColor: Colors.grey)
                    .paddingOnly(right: 5),
              // Text(
              //   sponsor.name ?? "Sponsor",
              //   style: Get.textTheme.bodySmall!
              //       .copyWith(fontWeight: FontWeight.w500, color: Colors.white),
              // ),
            ],
          ).paddingOnly(right: 16);
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
            // Text(
            //   "Sponsors",
            //   style:
            //       Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w400),
            // ).paddingOnly(bottom: 6),
            GestureDetector(
              onTap: (){
                print("DDDDDDDDDD_______sssss__");
                Get.to(() => const SponsorImagesPage());
              },
              child: SizedBox(
                height: 48,
                width: 120,
                child: sponsorData.titleSponsor?.logo != null
                    ? CachedNetworkImage(
                        imageUrl: sponsorData.titleSponsor!.logo!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(child: LoadingWidget(color: AppColors.primaryColor)),
                        errorWidget: (context, url, error) => Image.asset(
                          Assets.imagesImgDummyLogo2,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(Assets.imagesImgDummyLogo2, fit: BoxFit.contain),
              ),
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
                  final items = sponsorData.sponsors!
                      .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 2')
                      .take(3)
                      .toList();
                  final children = <Widget>[];

                  for (final sponsor in items) {
                    children.add(
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 70,
                            child: sponsor.logo != null
                                ? CachedNetworkImage(
                                    imageUrl: sponsor.logo!,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                  )
                                : const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                          ),
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
