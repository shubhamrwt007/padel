import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart' as LeagueModel;

class SponsorImagesPage extends StatelessWidget {
  const SponsorImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Assets.imagesJubilee1),
              const SizedBox(height: 20),
              Image.asset(Assets.imagesJubliee2),
            ],
          ),
        ),
      ),
    );
  }
}

class BuildLeagueTitleSponsor extends StatelessWidget {
  final LeagueModel.Data league;
  const BuildLeagueTitleSponsor({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            "Sponsors",
            style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w400),
          ).paddingOnly(bottom: 6),
          GestureDetector(
            onTap: (){
              Get.to(() => const SponsorImagesPage());
            },
            child: SizedBox(
              height: 48,
              width: 120,
              child: league.titleSponsor?.logo != null
                  ? CachedNetworkImage(
                      imageUrl: league.titleSponsor!.logo!,
                      height: 48,
                      width: 120,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: LoadingWidget(color: AppColors.primaryColor),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        Assets.imagesImgDummyLogo2,
                        height: 48,
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      Assets.imagesImgDummyLogo2,
                      height: 48,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
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
          Builder(builder: (context) {
            final tier2Sponsors = (league.sponsors ?? [])
                .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 2')
                .take(3)
                .toList();
            if (tier2Sponsors.isEmpty) return const SizedBox.shrink();
            final children = <Widget>[];
            for (final sponsor in tier2Sponsors) {
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
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
              );
              children.add(Container(height: 30, width: 1, color: Colors.black26));
            }
            if (children.isNotEmpty) children.removeLast();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            );
          }),
        ],
      ),
    );
  }
}

class BuildLeagueMoreSponsor extends StatefulWidget {
  final LeagueModel.Data league;
  const BuildLeagueMoreSponsor({super.key, required this.league});

  @override
  State<BuildLeagueMoreSponsor> createState() => _BuildLeagueMoreSponsorState();
}

class _BuildLeagueMoreSponsorState extends State<BuildLeagueMoreSponsor>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier3Sponsors = (widget.league.sponsors ?? [])
        .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 3')
        .toList();

    if (tier3Sponsors.isEmpty) return const SizedBox.shrink();

    // Duplicate list to create seamless loop effect
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
