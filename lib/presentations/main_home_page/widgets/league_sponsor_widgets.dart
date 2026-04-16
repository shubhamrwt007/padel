import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart' as LeagueModel;
import 'package:url_launcher/url_launcher.dart';

class SponsorImagesPage extends StatelessWidget {
  const SponsorImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: primaryAppBar(title: Text("Sponsors"), centerTitle: true,context: context),
      body: Center(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(Assets.imagesJubilee1),
                  const SizedBox(height: 20),
                  Image.asset(Assets.imagesJubliee2),
                ],
              ),
            ),
            Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 30,width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child:  Icon(Icons.arrow_back,color: Colors.black,),
                  ),
                )),
          ],
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
          // Text(
          //   "Sponsors",
          //   style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w400),
          // ).paddingOnly(bottom: 6),
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
  static const double _tileWidth = 90;
  static const Duration _loopDuration = Duration(seconds: 18);

  late final Ticker _ticker;
  final ValueNotifier<double> _dx = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final sponsors = (widget.league.sponsors ?? [])
          .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 3')
          .toList();
      final trackWidth = sponsors.length * _tileWidth;
      if (trackWidth <= 0) return;

      final loopMicros = _loopDuration.inMicroseconds;
      final traveledMicros = elapsed.inMicroseconds % loopMicros;
      final traveled = (traveledMicros / loopMicros) * trackWidth;
      _dx.value = -traveled;
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
    final tier3Sponsors = (widget.league.sponsors ?? [])
        .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 3')
        .toList();

    if (tier3Sponsors.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      width: Get.width,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1)
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = tier3Sponsors.length * _tileWidth;
          final cycles = (constraints.maxWidth / trackWidth).ceil() + 2;
          final repeatedSponsors = List<dynamic>.generate(
            cycles * tier3Sponsors.length,
            (index) => tier3Sponsors[index % tier3Sponsors.length],
          );

          final row = Row(
            children: repeatedSponsors.map(_buildTier3Sponsor).toList(),
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
      ),
    ).paddingOnly(top: 10);
  }

  Widget _buildTier3Sponsor(dynamic sponsor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: 50,
        height: 50,
        child: sponsor.logo != null
            ? CachedNetworkImage(
                imageUrl: sponsor.logo!,
                width: 50,
                height: 50,
                fit: BoxFit.fill,
                placeholder: (context, url) => const ColoredBox(color: Colors.grey),
                errorWidget: (context, url, error) => const ColoredBox(color: Colors.grey),
              )
            : const ColoredBox(color: Colors.grey),
      ),
    );
  }
}
