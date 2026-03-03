import 'package:flutter/services.dart';
import '../cart/cart_controller.dart';
import 'americano/americano_screen.dart';
import 'open_matches/open_match_screen.dart';
import 'widgets/booking_exports.dart';

class BookingScreen extends GetView<BookingController> {
  const BookingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
            SliverAppBar(
              centerTitle: true,
              expandedHeight: Get.height * 0.2,
              pinned: true,
              floating: false,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              snap: false,
              forceElevated: false,
              stretch: false,  // Add this
              excludeHeaderSemantics: true,
              // title: Obx(() {
              //   final clubName = controller.courtsData.value.clubName ?? '';
              //   return LayoutBuilder(
              //     builder: (context, constraints) {
              //       final settings =
              //       context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
              //       final collapsed = (settings?.currentExtent ?? 0) <=
              //           (settings?.minExtent ?? kToolbarHeight) + 10;
              //
              //       return AnimatedOpacity(
              //         opacity: collapsed && clubName.isNotEmpty ? 1 : 0,
              //         duration: const Duration(milliseconds: 200),
              //         child: Text(
              //           clubName,
              //           maxLines: 1,
              //           overflow: TextOverflow.ellipsis,
              //           style: const TextStyle(
              //             color: AppColors.blackColor,
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         )
              //       );
              //     },
              //   );
              // }),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  final isCollapsed = top <= kToolbarHeight + 50;

                  final iconColor =
                  isCollapsed ? AppColors.blackColor : AppColors.blackColor;
                  final bgColor =
                  isCollapsed ? AppColors.whiteColor : Colors.transparent;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      /// Background image (only when expanded)
                      if (!isCollapsed)
                        Obx(() {
                          final courtDetails = controller.courtsData.value.courts?.isNotEmpty == true 
                              ? controller.courtsData.value.courts![0] 
                              : null;
                          final imageUrl = courtDetails?.courtImage?.isNotEmpty == true
                              ? courtDetails!.courtImage![0]
                              : '';
                          return imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: Get.width,
                            height: double.infinity,
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.redColor,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.whiteColor,
                                  size: 50,
                                ),
                              ),
                            ),
                          )
                              : Container(color: AppColors.redColor);
                        }),

                      /// Dynamic background when collapsed
                      if (isCollapsed)
                        Container(
                          color: bgColor,
                          width: double.infinity,
                          height: double.infinity,
                        ),

                      /// Gradient overlay (only when expanded)
                      if (!isCollapsed)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 1.0],
                            ),
                          ),
                        ),

                      /// Club name & address (only when expanded)
                      if (!isCollapsed)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 30,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(() {
                                final clubName =
                                    controller.courtsData.value.clubName ?? 'Unknown Club';
                                return Text(
                                  clubName,
                                  style: const TextStyle(
                                    color: AppColors.whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }),
                              const SizedBox(height: 8),
                              Obx(() {
                                final locationDetails = controller.courtsData.value.locations?.isNotEmpty == true
                                    ? controller.courtsData.value.locations![0]
                                    : null;
                                final address = locationDetails?.address ?? controller.courtsData.value.address ?? '';
                                final city = locationDetails?.city ?? controller.courtsData.value.city ?? '';
                                final fullAddress = address.isNotEmpty && city.isNotEmpty 
                                    ? "$address, $city" 
                                    : address.isNotEmpty 
                                        ? address 
                                        : city.isNotEmpty 
                                            ? city 
                                            : 'Address not available';
                                return Text(
                                  fullAddress,
                                  style: const TextStyle(
                                    color: AppColors.whiteColor,
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        offset: Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }),
                            ],
                          ).paddingSymmetric(horizontal: 32),
                        ),

                      /// Top Bar (Back, Share, Cart)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: Get.width * 0.04,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Back button
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isCollapsed
                                          ? Colors.transparent
                                          : Colors.black.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: isCollapsed?Colors.black:Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                // Share + Cart
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: controller.shareWithImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isCollapsed
                                              ? Colors.grey.withValues(alpha: 0.1)
                                              : AppColors.whiteColor,
                                          shape: BoxShape.circle,
                                          boxShadow: isCollapsed
                                              ? []
                                              : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: SvgPicture.asset(
                                          Assets.imagesIcShareBooking,
                                          width: 20,
                                          height: 20,
                                          colorFilter: ColorFilter.mode(
                                            iconColor,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // const SizedBox(width: 12),
                                    // GestureDetector(
                                    //   onTap: () => Get.to(() => CartScreen(buttonType: "true")),
                                    //   child: Container(
                                    //     padding: const EdgeInsets.all(8),
                                    //     decoration: BoxDecoration(
                                    //       color: isCollapsed
                                    //           ? Colors.grey.withValues(alpha: 0.1)
                                    //           : AppColors.whiteColor,
                                    //       shape: BoxShape.circle,
                                    //       boxShadow: isCollapsed
                                    //           ? []
                                    //           : [
                                    //         BoxShadow(
                                    //           color: Colors.black.withValues(alpha: 0.1),
                                    //           blurRadius: 4,
                                    //           offset: const Offset(0, 2),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //     child: Stack(
                                    //       clipBehavior: Clip.none,
                                    //       children: [
                                    //         Icon(
                                    //           Icons.shopping_cart_outlined,
                                    //           color: iconColor,
                                    //           size: 22,
                                    //         ),
                                    //         Positioned(
                                    //           right: -6,
                                    //           top: -6,
                                    //           child: Obx(() {
                                    //             final slotCount = Get.find<CartController>()
                                    //                 .totalSlot
                                    //                 .value;
                                    //             return slotCount > 0
                                    //                 ? Container(
                                    //               padding: const EdgeInsets.all(4),
                                    //               decoration: const BoxDecoration(
                                    //                 color: Colors.red,
                                    //                 shape: BoxShape.circle,
                                    //               ),
                                    //               constraints: const BoxConstraints(
                                    //                 minWidth: 18,
                                    //                 minHeight: 18,
                                    //               ),
                                    //               child: Text(
                                    //                 '$slotCount',
                                    //                 style: const TextStyle(
                                    //                   color: Colors.white,
                                    //                   fontSize: 10,
                                    //                   fontWeight: FontWeight.bold,
                                    //                 ),
                                    //                 textAlign: TextAlign.center,
                                    //               ),
                                    //             )
                                    //                 : const SizedBox.shrink();
                                    //           }),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
              // Pinned TabBar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  myTabBar(controller.tabController, context),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: controller.tabController,
            children: [
              HomeContent(),
              BookSession(),
              OpenMatchesScreen(),
              AmericanoScreen(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for pinned TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final PreferredSizeWidget _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.whiteColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

/// TabBar widget
PreferredSizeWidget myTabBar(
    TabController tabController, BuildContext context) {
  return TabBar(
    controller: tabController,
    isScrollable: true,
    unselectedLabelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
      fontSize: 13,
      color: AppColors.textColor,
      fontWeight: FontWeight.w600,
    ),
    labelStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 13,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.w600,
    ),
    dividerHeight: 0.5,
    dividerColor: AppColors.textColor.withValues(alpha: 0.1),
    labelPadding: const EdgeInsets.only(left: 20, right: 40),
    automaticIndicatorColorAdjustment: true,
    indicatorWeight: 1,
    tabs: const [
      Tab(child: Text("Home")),
      Tab(child: Text("Book")),
      Tab(child: Text("Open Matches")),
      // Tab(child: Text("Americano")),
    ],
  );}