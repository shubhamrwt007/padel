import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';

class SeamlessBannerSwiper extends StatefulWidget {
  final List<String> images;
  final double height;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final void Function(int index) onTap;
  final ValueChanged<int> onIndexChanged;

  const SeamlessBannerSwiper({
    super.key,
    required this.images,
    required this.height,
    required this.autoPlayInterval,
    required this.autoPlayAnimationDuration,
    required this.onTap,
    required this.onIndexChanged,
  });

  @override
  State<SeamlessBannerSwiper> createState() => _SeamlessBannerSwiperState();
}

class _SeamlessBannerSwiperState extends State<SeamlessBannerSwiper> {
  late final PageController _pageController;
  Timer? _timer;

  bool _isAnimating = false;
  bool _suppressNextOnPageChanged = false;

  int _pageIndex = 1; // extended index: 0(last), 1..len(real), len+1(first)

  int get _len => widget.images.length;

  int _effectiveIndexFromPage(int pageIndex) {
    if (_len <= 0) return 0;
    if (pageIndex == 0) return _len - 1;
    if (pageIndex == _len + 1) return 0;
    return pageIndex - 1;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final path in widget.images) {
        precacheImage(AssetImage(path), context);
      }
    });

    if (_len > 1) {
      _timer = Timer.periodic(widget.autoPlayInterval, (_) => _goNext());
    }
  }

  @override
  void didUpdateWidget(covariant SeamlessBannerSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      // reset autoplay to avoid wrap mismatch when list changes
      _timer?.cancel();
      _timer = null;
      if (_len > 1) {
        _timer = Timer.periodic(widget.autoPlayInterval, (_) => _goNext());
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final path in widget.images) {
          precacheImage(AssetImage(path), context);
        }
      });

      _pageIndex = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.jumpToPage(1);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted || _isAnimating || _len <= 1) return;

    final next = _pageIndex + 1;
    _isAnimating = true;

    _pageController
        .animateToPage(
          next,
          duration: widget.autoPlayAnimationDuration,
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
      if (!mounted) return;
      // If we've reached the duplicated "first" page (len + 1),
      // jump back to real first page (1) instantly to remove wrap jerk.
      if (next == _len + 1) {
        _suppressNextOnPageChanged = true;
        _pageController.jumpToPage(1);
        _pageIndex = 1;
      } else {
        _pageIndex = next;
      }
      _isAnimating = false;
    });
  }

  void _onPageChanged(int pageIndex) {
    if (_suppressNextOnPageChanged) {
      _suppressNextOnPageChanged = false;
      return;
    }

    _pageIndex = pageIndex;
    widget.onIndexChanged(_effectiveIndexFromPage(pageIndex));

    // User swipe safety: keep the page index inside the real range.
    if (pageIndex == 0) {
      // Jump to real last page (len)
      _suppressNextOnPageChanged = true;
      _pageController.jumpToPage(_len);
      _pageIndex = _len;
    } else if (pageIndex == _len + 1) {
      // Jump to real first page (1)
      _suppressNextOnPageChanged = true;
      _pageController.jumpToPage(1);
      _pageIndex = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_len == 0) return const SizedBox.shrink();

    final itemCount = _len + 2;

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: itemCount,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, pageIndex) {
          final effectiveIndex = _effectiveIndexFromPage(pageIndex);
          final imagePath = widget.images[effectiveIndex];

          return Container(
            width: Get.width,
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 18),
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
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      imagePath,
                      // Stretch to fully occupy the banner area (no top/bottom gap).
                      fit: BoxFit.fill,
                      alignment: Alignment.center,
                      gaplessPlayback: true,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Discover, Book",
                                style: Get.textTheme.titleMedium!
                                    .copyWith(color: Colors.white),
                              ),
                              Text(
                                "and Play",
                                style: Get.textTheme.titleMedium!
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => widget.onTap(effectiveIndex),
                            child: Container(
                              width: Get.width * 0.35,
                              padding: const EdgeInsets.symmetric(
                                vertical: 3,
                                horizontal: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "BOOK NOW!",
                                    style: Get.textTheme.titleSmall!.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ).paddingOnly(left: 10),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.primaryColor,
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

