import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/presentations/main_home_page/widgets/league_sponsor_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

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

class BuildMoreSponsor extends StatelessWidget {
  final List<dynamic> sponsors;
  const BuildMoreSponsor({super.key, required this.sponsors});

  @override
  Widget build(BuildContext context) {
    final tier3Sponsors = sponsors
        .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 3')
        .toList();

    if (tier3Sponsors.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 30,
      width: Get.width,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
      ),
      child: _SeamlessSponsorTicker(sponsors: tier3Sponsors),
    ).paddingOnly(top: 10);
  }
}

class _SeamlessSponsorTicker extends StatefulWidget {
  final List<dynamic> sponsors;
  const _SeamlessSponsorTicker({required this.sponsors});

  @override
  State<_SeamlessSponsorTicker> createState() => _SeamlessSponsorTickerState();
}

class _SeamlessSponsorTickerState extends State<_SeamlessSponsorTicker>
    with SingleTickerProviderStateMixin {
  static const double _tileWidth = 100; // 60(width) + 20*2(padding)
  static const Duration _fullLoopDuration = Duration(seconds: 20);

  late final Ticker _ticker;
  final ValueNotifier<double> _dx = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final len = widget.sponsors.length;
      if (len == 0) return;

      final trackWidth = len * _tileWidth;
      if (trackWidth <= 0) return;

      final loopMicros = _fullLoopDuration.inMicroseconds;
      if (loopMicros <= 0) return;

      final traveledMicros = elapsed.inMicroseconds % loopMicros;
      final traveled = (traveledMicros / loopMicros) * trackWidth;

      // Pixel snapping to avoid sub-pixel shimmer on some devices.
      _dx.value = (-traveled).roundToDouble();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _dx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sponsors.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final len = widget.sponsors.length;
        if (len == 0) return const SizedBox.shrink();

        final viewportWidth = constraints.maxWidth;
        final trackWidth = len * _tileWidth;
        final cycles = (viewportWidth / trackWidth).ceil() + 2;

        final repeatedSponsors = List<dynamic>.generate(
          cycles * len,
          (index) => widget.sponsors[index % len],
        );

        final row = Row(
          children: repeatedSponsors.map(_buildSponsorLogo).toList(),
        );

        return ClipRect(
          child: ValueListenableBuilder<double>(
            valueListenable: _dx,
            builder: (context, dx, child) {
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: row,
          ),
        );
      },
    );
  }

  Widget _buildSponsorLogo(dynamic sponsor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: 60,
        height: 20,
        child: sponsor.logo != null
            ? CachedNetworkImage(
                imageUrl: sponsor.logo!,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                errorWidget: (context, url, error) =>
                    const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
              )
            : const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
      ),
    );
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
                        child: GestureDetector(
                          onTap: () async {
                            final url = sponsor.url;
                            if (url != null && url.isNotEmpty) {
                              final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          child: Center(
                            child: SizedBox(
                              height: 30,
                              width: 80,
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
