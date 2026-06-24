import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart' as LeagueModel;
import 'package:url_launcher/url_launcher.dart';

class SponsorImagesPage extends StatelessWidget {
  const SponsorImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: Image.asset(Assets.images.jubilee1.path, fit: BoxFit.fitWidth),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: Image.asset(Assets.images.jubliee2.path, fit: BoxFit.fitWidth),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
              ),
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
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: Get.width),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
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
                    Assets.images.imgDummyLogo2.path,
                    height: 48,
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                )
                    : Image.asset(
                  Assets.images.imgDummyLogo2.path,
                  height: 48,
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Expanded(
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
                  Flexible(
                    child: GestureDetector(
                      onTap: () async {
                        final url = sponsor.url;
                        if (url != null && url.isNotEmpty) {
                          final uri = Uri.parse(
                              url.startsWith('http') ? url : 'https://$url');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 80,
                            maxHeight: 30,
                          ),
                          child: sponsor.logo != null
                              ? CachedNetworkImage(
                            imageUrl: sponsor.logo!,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) =>
                            const Icon(
                              Icons.image_not_supported,
                              size: 20,
                              color: Colors.grey,
                            ),
                          )
                              : const Icon(
                            Icons.image_not_supported,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                children.add(
                  Container(height: 30, width: 1, color: Colors.black26),
                );
              }
              if (children.isNotEmpty) children.removeLast();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: children,
              );
            }),
          ],
        ),
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
  static const double _tileWidth = 100;
  static const double _scrollSpeed = 40; // pixels per second

  late final Ticker _ticker;
  final ValueNotifier<double> _dx = ValueNotifier<double>(0);
  DateTime? _lastTime;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final now = DateTime.now();
      if (_lastTime == null) {
        _lastTime = now;
        return;
      }

      final delta = now.difference(_lastTime!).inMicroseconds / 1_000_000;
      _lastTime = now;

      final sponsors = (widget.league.sponsors ?? [])
          .where((s) => s.categoryId?.name?.toLowerCase() == 'tier 3')
          .toList();

      final trackWidth = sponsors.length * _tileWidth;
      if (trackWidth <= 0) return;

      // Move left continuously
      _dx.value -= _scrollSpeed * delta;

      // Seamless reset: once we've scrolled one full track, jump back
      if (_dx.value.abs() >= trackWidth) {
        _dx.value = _dx.value + trackWidth;
      }
    })
      ..start();
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
      height: 30,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = tier3Sponsors.length * _tileWidth;

          // Enough copies to always fill screen + one extra for seamless wrap
          final cycles = (constraints.maxWidth / trackWidth).ceil() + 2;
          final repeatedSponsors = List<dynamic>.generate(
            cycles * tier3Sponsors.length,
                (index) => tier3Sponsors[index % tier3Sponsors.length],
          );

          // Build row once as child so it's not rebuilt on every frame
          final row = Row(
            children: repeatedSponsors.map(_buildTier3Sponsor).toList(),
          );

          return ValueListenableBuilder<double>(
            valueListenable: _dx,
            builder: (context, dx, child) {
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: OverflowBox(
                maxWidth: double.infinity, // 👈 allow infinite width
                alignment: Alignment.centerLeft,
                child: row),
          );
        },
      ),
    ).paddingOnly(top: 10);
  }

  Widget _buildTier3Sponsor(dynamic sponsor) {
    return SizedBox(
      // width: _tileWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: sponsor.logo != null
            ? CachedNetworkImage(
          imageUrl: sponsor.logo!,
          fit: BoxFit.contain,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const Icon(
            Icons.image_not_supported,
            size: 16,
            color: Colors.grey,
          ),
        )
            : const Icon(
          Icons.image_not_supported,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}