import 'package:intl/intl.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeContent extends StatelessWidget {
  HomeContent({super.key});

  final HomeContentController controller = Get.put(HomeContentController());

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Get.height,
      width: Get.width,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Court Information",
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: AppColors.labelBlackColor,
                  ),
                ),
                Obx(() {
                  if (controller.isLoading.value) {
                    return Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ).paddingOnly(right: Get.width * 0.02),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 30,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final reviewData = controller.registerClubResponse.value?.reviewData;
                  final averageRating = reviewData?.averageRating?.toDouble() ==0 ?4.5 : 4.0;
                  // final totalReviews = reviewData?.totalReviews ?? 0;

                  return Row(
                    children: [
                      RatingBar.builder(
                        itemSize: 16,
                        initialRating: averageRating,
                        minRating: 0,
                        unratedColor: AppColors.starUnselectedColor,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: EdgeInsets.zero,
                        itemBuilder: (context, _) => Container(
                          width: 5.0,
                          height: 30.0,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.star,
                            size: 27.0,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        onRatingUpdate: (rating) {},
                      ).paddingOnly(right: Get.width * 0.02),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.labelBlackColor,
                            ),
                      ),
                      // Text(
                      //   " ($totalReviews)",
                      //   style: Theme.of(context).textTheme.bodyMedium!
                      //       .copyWith(
                      //         color: AppColors.textColor,
                      //       ),
                      // ),
                    ],
                  );
                }),
              ],
            ).paddingOnly(top: Get.height * 0.02, bottom: Get.height * 0.005),
            Obx(() {
              if (controller.isLoading.value) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ).paddingOnly(bottom: Get.height * 0.02);
              }

              // Get description from courts array
              final courtDetails = controller.argument.courts?.isNotEmpty == true 
                  ? controller.argument.courts!.first 
                  : null;
              final description = courtDetails?.description;
              
              if (description == null || description.isEmpty) {
                return const SizedBox.shrink();
              }

              return Text(
                description,
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  color: AppColors.textColor,
                  fontSize: 13,
                ),
              ).paddingOnly(bottom: Get.height * 0.02);
            }),
            Text(
              "Facilities",
              style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.labelBlackColor,fontWeight: FontWeight.w700
              ),
            ).paddingOnly(bottom: Get.height * 0.01),
            Obx(() {
              if (controller.isLoading.value) {
                return SizedBox(
                  height: 25,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (BuildContext context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ).paddingOnly(right: 10);
                    },
                  ),
                ).paddingOnly(bottom: Get.height * 0.02);
              }

              // Get features from courts array
              final courtDetails = controller.argument.courts?.isNotEmpty == true 
                  ? controller.argument.courts!.first 
                  : null;
              final features = courtDetails?.features ?? [];

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.asMap().entries.map((entry) {
                  return SizedBox(
                    width: (Get.width - 100) / 2, // 3 items per line with padding
                    child: facilities(context, entry.key, entry.value),
                  );
                }).toList(),
              ).paddingOnly(bottom: Get.height * 0.02);
            }),
            Container(
              height: Get.height * 0.1,
              width: double.infinity,
              color: Colors.transparent,
              child: Transform.translate(
                offset: Offset(10, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.homeOptionsList.length,
                        (index) => Obx(() {
                      final item = controller.homeOptionsList[index];
                      final isSelected = controller.selectedIndex.value == index;

                      final Widget iconWidget = item['isSvg']
                          ? SvgPicture.asset(
                        item['image'],
                        height: 24,
                        width: 24,
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.white : AppColors.labelBlackColor,
                          BlendMode.srcIn,
                        ),
                      )
                          : Icon(
                        item['icon'],
                        color: isSelected ? Colors.white : AppColors.labelBlackColor,
                      );

                      return GestureDetector(
                        onTap: () {
                          if (index == 0) {
                            // Direction - Show direction view
                            controller.selectedIndex.value = index;
                          } else if (index == 1) {
                            // Call - Make phone call
                            controller.makePhoneCall();
                          } else {
                            controller.selectedIndex.value = index;
                            if (index != 2) controller.isShowAllReviews.value = false;
                            if (index != 3) controller.isShowAllPhotos.value = false;
                          }
                        },
                        child: homeOptionItem(
                          context,
                          iconWidget: iconWidget,
                          label: item['label'],
                          isSelected: isSelected,
                        ).paddingOnly(right: 32), // small spacing only
                      );
                    }),
                  ),
                ),
              ),
            ),

            Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: getSelectedView(controller.selectedIndex.value),
              ),
            ),
            Obx(() {
              if (controller.selectedIndex.value == 0) {
                return const SizedBox.shrink();
              }

              // For photos, only show if there are 2 or more court images
              if (controller.selectedIndex.value == 3) {
                final clubData = controller.registerClubResponse.value?.data;
                final courtImages = clubData?.courtImage ?? [];
                if (courtImages.length < 2) {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: GestureDetector(
                    onTap: () {
                      controller.isShowAllPhotos.toggle();
                    },
                    child: Container(
                      width: Get.width * 0.2,
                      height: 20,
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.isShowAllPhotos.value
                                ? "Show Less"
                                : "Show All",
                            style: Theme.of(context).textTheme.labelMedium!
                                .copyWith(color: AppColors.primaryColor),
                          ),
                          Icon(
                            controller.isShowAllPhotos.value
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 15,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            }).paddingOnly(top: Get.height * 0.01),
            Obx(() {
              final clubData = controller.registerClubResponse.value?.data;
              final businessHours = clubData?.businessHours ?? [];
              
              if (businessHours.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Opening Hours",
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: AppColors.labelBlackColor,
                      fontWeight: FontWeight.w700
                    ),
                  ).paddingOnly(bottom: 5),
                  if (controller.isLoading.value)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: businessHours.map((hour) {
                        final day = hour.day ?? "";
                        final time = hour.time ?? "";

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day,
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                color: AppColors.textColor,fontWeight: FontWeight.w500
                              ),
                            ),
                            Text(
                              time,
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                color: AppColors.textColor,fontWeight: FontWeight.w500
                              ),
                            ),
                          ],
                        ).paddingOnly(bottom: 4);
                      }).toList(),
                    ),
                ],
              );
            }),
          ],
        ).paddingOnly(left: Get.width * 0.05, right: Get.width * 0.05),
      ),
    );
  }

  Widget facilities(BuildContext context, index, String feature) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon(
        //   Icons.ac_unit,
        //   size: 10,
        //   color: AppColors.primaryColor,
        // ).paddingOnly(right: 5, top: 2),
        Flexible(
          child: Text(
            "${index + 1}. $feature",
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget homeOptionItem(
    BuildContext context, {
    required Widget iconWidget,
    required String label,
    required bool isSelected,
  }) {
    return Column(
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? AppColors.labelBlackColor
                : AppColors.whiteColor,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Center(child: iconWidget),
        ).paddingOnly(bottom: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.labelBlackColor : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget getSelectedView(int index) {
    final height = Get.height * 0.33;
    switch (index) {
      case 0:
        return SizedBox(
          key: ValueKey(0),
          height: Get.height * 0.18,
          child: directionGoogleMaps(),
        );
      case 1:
        return SizedBox(
          key: ValueKey(1),
          height: height,
          child: const Center(child: Text("Call View")),
        );
      case 2:
        return SizedBox(
          key: ValueKey(2),
          child: reviewContent(Get.context!),
        );
      case 3:
        return SizedBox(
          key: ValueKey(3),
          height: controller.isShowAllPhotos.value
              ? Get.height * 0.6
              : Get.height * 0.33,
          child: photoGallery(Get.context!),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget reviewContent(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(child: LoadingWidget(color: AppColors.primaryColor,));
    }

    return Obx(() {
      final reviews = controller.displayedReviews;

      if (reviews.isEmpty) {
        return Center(child: Text("No reviews available").paddingSymmetric(vertical: 30));
      }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Customer reviews",
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: AppColors.labelBlackColor,
              ),
            ),
            GestureDetector(
              onTap: () => addReview(context),
              child: Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    Icon(Icons.add, color: AppColors.primaryColor, size: 14),
                    Text(
                      "Review",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).paddingOnly(bottom: Get.height * 0.01),

        ListView.builder(
          itemCount: reviews.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final rating = review.reviewRating ?? 0;
              final comment = review.reviewComment ?? "";
              // final userName = review.userId?.email ?? "Anonymous";
              final userName = review.userId?.name ?? "Anonymous";
              final postDate = review.createdAt != null
                  ? DateFormat("dd/MM/yyyy").format(DateTime.parse(review.createdAt!))
                  : "N/A";

              return Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.lightBlueColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.labelBlackColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 15,
                              backgroundImage: AssetImage(
                                Assets.imagesImgCustomerPicBooking,
                              ),
                            ).paddingOnly(right: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  color: Colors.transparent,
                                  width: Get.width*0.3,
                                  child: Text(
                                    userName,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: AppColors.labelBlackColor,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: rating.toDouble(),
                                      itemBuilder: (context, _) => Icon(
                                        Icons.star,
                                        color: AppColors.secondaryColor,
                                      ),
                                      itemSize: 12,
                                      unratedColor: AppColors.starUnselectedColor,
                                    ).paddingOnly(right: 5),
                                    Text(
                                      rating.toString(),
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.labelBlackColor,
                                        fontSize: 7,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          "Post Date: $postDate",
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ).paddingOnly(bottom: 5),

                    // Comment
                    Text(
                      comment,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium!
                          .copyWith(fontSize: 12, height: 1.1),
                    ),
                  ],
                ),
              ).paddingOnly(bottom: 10);
            },
          ),
      ],
    );
    });
  }


  void addReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReviewBottomSheet(),
    );
  }

  Widget photoGallery(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: Get.height * 0.33,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      
      // Get court images from nested courts array
      final List<String> imageUrls = [];
      if (controller.argument.courts != null && controller.argument.courts!.isNotEmpty) {
        for (var courtDetail in controller.argument.courts!) {
          if (courtDetail.courtImage != null) {
            imageUrls.addAll(courtDetail.courtImage!);
          }
        }
      }
      
      // Debug: Print court images
      print('Court Images Count: ${imageUrls.length}');
      print('Court Images: $imageUrls');

      final bool isExpanded = controller.isShowAllPhotos.value;
      
      if (imageUrls.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("No images available"),
            ],
          ),
        );
      }

      return SizedBox(
        height: isExpanded ? Get.height * 0.6 : Get.height * 0.33,
        child: Column(
          children: [
            // First block (always shown)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _buildImage(imageUrls[0], true)),
                  SizedBox(width: 10),
                  if (imageUrls.length > 1)
                    Expanded(flex: 1, child: _buildImage(imageUrls[1], true)),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Second block (always shown)
            if (imageUrls.length > 2)
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    if (imageUrls.length > 2)
                      Expanded(child: _buildImage(imageUrls[2], true)),
                    if (imageUrls.length > 3) ...[
                      SizedBox(width: 10),
                      Expanded(child: _buildImage(imageUrls[3], true)),
                    ],
                    if (imageUrls.length > 4) ...[
                      SizedBox(width: 10),
                      Expanded(child: _buildImage(imageUrls[4], true)),
                    ],
                  ],
                ),
              ),

            // Extra rows when expanded
            if (isExpanded && imageUrls.length > 5) ...[
              SizedBox(height: 10),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildImage(imageUrls[5], true)),
                    if (imageUrls.length > 6) ...[
                      SizedBox(width: 10),
                      Expanded(flex: 1, child: _buildImage(imageUrls[6], true)),
                    ],
                  ],
                ),
              ),
              if (imageUrls.length > 7) ...[
                SizedBox(height: 10),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(imageUrls[7], true)),
                      if (imageUrls.length > 8) ...[
                        SizedBox(width: 10),
                        Expanded(child: _buildImage(imageUrls[8], true)),
                      ],
                      if (imageUrls.length > 9) ...[
                        SizedBox(width: 10),
                        Expanded(child: _buildImage(imageUrls[9], true)),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    });
  }

  Widget _buildImage(String url, bool isNetworkImage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: isNetworkImage
          ? CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: LoadingWidget(color: AppColors.primaryColor,),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, color: Colors.grey[600]),
        ),
      )
          : Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget directionGoogleMaps() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: LoadingWidget(color: AppColors.primaryColor),
        );
      }
      
      if (controller.isIframeUrl.value && controller.iframeUrl.value.isNotEmpty) {
        return GoogleMapsWebView(
          key: ValueKey(controller.iframeUrl.value),
          iframeUrl: controller.iframeUrl.value,
        );
      }
      
      // Fallback: Show address text if no map available
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 40,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                controller.address.value,
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.bodyMedium,
              ).paddingSymmetric(horizontal: 16),
            ],
          ),
        ),
      );
    });
  }
}

class GoogleMapsWebView extends StatefulWidget {
  final String iframeUrl;

  const GoogleMapsWebView({super.key, required this.iframeUrl});

  @override
  State<GoogleMapsWebView> createState() => _GoogleMapsWebViewState();
}

class _GoogleMapsWebViewState extends State<GoogleMapsWebView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Create HTML with iframe and JavaScript to handle clicks
    final htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body, html {
              margin: 0;
              padding: 0;
              height: 100%;
              overflow: hidden;
            }
            iframe {
              width: 100%;
              height: 100%;
              border: 0;
              pointer-events: auto;
            }
          </style>
        </head>
        <body>
          <iframe 
            src="${widget.iframeUrl}" 
            allowfullscreen
            referrerpolicy="no-referrer-when-downgrade">
          </iframe>
        </body>
      </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print('🗺️ Navigation: $url');
            
            // Allow data URLs and about:blank
            if (url.startsWith('data:') || url.startsWith('about:')) {
              return NavigationDecision.navigate;
            }
            
            // Allow embed URLs
            if (url.contains('/maps/embed/') || url.contains('maps/api/js')) {
              return NavigationDecision.navigate;
            }
            
            // Intercept any other Google Maps URLs
            if (url.contains('google.com/maps') || url.contains('maps.google.com')) {
              print('🚀 Opening external: $url');
              launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
              return NavigationDecision.prevent;
            }
            
            // Block all other navigation
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: WebViewWidget(controller: _webViewController),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: const Center(
                child: LoadingWidget(
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
