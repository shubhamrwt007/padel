import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/app_strings.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/search_field.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/bottomnav/bottom_nav.dart';
import 'package:padel_mobile/presentations/bottomnav/bottom_nav_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/presentations/home/widget/custom_skelton_loader.dart';
import 'package:padel_mobile/presentations/booking/booking_controller.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';
import 'package:padel_mobile/services/socket_service.dart';
import '../../data/request_models/home_models/get_club_name_model.dart';
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});
  @override

  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bottomNavController = Get.find<BottomNavigationController>();
        bottomNavController.updateIndex(0);
        Get.offAll(() => BottomNavUi());
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: PopScope(
          canPop: false,
          child: Scaffold(
            appBar: primaryAppBar(
                centerTitle: true,
                title: Text("Courts"), context: context),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  searchField(),
                  Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1.0,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: controller.showLocationAndDate.value
                        ? locationAndDateTime(context)
                        : const SizedBox.shrink(
                      key: ValueKey('empty'),
                    ),
                  )),
                  Expanded(
                    child: Obx(() {
                      return RefreshIndicator(
                        color: Colors.white,
                        onRefresh: controller.retryFetch,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: controller.scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Courts Section ---
                              if (controller.isLoadingClub.value)
                                Column(
                                  children: List.generate(5, (_) => loadingCard()),
                                )
                              else
                                _buildCourtList(),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget searchField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SearchField(
          width: Get.width * 0.9,
          suffixIcon: Image.asset(
            Assets.imagesIcSearch,
            scale: 4,
            color: AppColors.textColor,
          ),
          hintText: AppStrings.search,
          hintStyle: Get.textTheme.bodyLarge!.copyWith(
            color: AppColors.textColor,
          ),
          onChanged: controller.searchClubs,
        ).paddingOnly(left: 5),
        // Obx(() {
        //   final isOpen = controller.showLocationAndDate.value;
        //
        //   return GestureDetector(
        //     onTap: () => controller.showLocationAndDate.toggle(),
        //     child: Container(
        //       height: 40,
        //       width: 40,
        //       decoration: BoxDecoration(
        //         color: AppColors.searchBarColor,
        //         borderRadius: BorderRadius.circular(10),
        //       ),
        //       child: AnimatedRotation(
        //         turns: isOpen ? 0.5 : 0,     // 0.5 turn = 180° rotation
        //         duration: const Duration(milliseconds: 300),
        //         child: Image.asset(
        //           Assets.imagesIcFilter,
        //           color: Colors.black,
        //           scale: 4.5,
        //         ),
        //       ),
        //     ),
        //   );
        // })
      ],
    ).paddingOnly(
      bottom: Get.height * 0.01,
    );
  }

  Widget locationAndDateTime(BuildContext context) {
    return Container(
      key: const ValueKey('locationDateTime'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _locationPicker(context),
          _datePicker(context),
        ],
      ).paddingOnly(
        bottom: Get.height * 0.02,
      ),
    );
  }

  Widget _locationPicker(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.showLocationPicker(),
      child: Container(
        height: 35,
        width: Get.width * 0.63,
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() => SizedBox(
              width: Get.width * 0.45,
              child: Text(
                controller.selectedLocation.value.isEmpty
                    ? AppStrings.location
                    : controller.selectedLocation.value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textColor),
                overflow: TextOverflow.ellipsis,
              ),
            )),
            Obx(() {
              final hasSelection = controller.selectedLocation.value.isNotEmpty;
              return GestureDetector(
                onTap: () {
                  if (hasSelection) controller.selectedLocation.value = '';
                },
                child: Icon(
                  hasSelection ? Icons.close : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.selectDate(context),
      child: Container(
        height: 35,
        width: Get.width * 0.27,
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.018),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(
                  () => Text(
                DateFormat('dd/MM/yyyy').format(controller.selectedDate.value),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 12,
                  color: AppColors.textColor,
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_outlined,
              size: 13,
              color: AppColors.textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtList() {
    // Handle loading state for initial load
    if (controller.isLoadingClub.value && !controller.isInitialized.value) {
      return Column(
        children: List.generate(4, (_) => loadingCard()),
      );
    }

    // Handle error state
    if (controller.clubError.value.isNotEmpty && !controller.hasCourtsData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 150,),
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.clubError.value,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ).paddingOnly(left: 20,right: 20),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.retryFetch,
              child: const Text('Retry'),
            ),
          ],
        ).paddingSymmetric(vertical: 50),
      );
    }

    // Get courts list
    final courts = controller.courtsList;

    // Handle empty state
    if (courts.isEmpty && controller.isInitialized.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No courts found for "${controller.searchQuery.value}"'
                  : 'No courts available',
              textAlign: TextAlign.center,
              style: Get.textTheme.headlineMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (controller.searchQuery.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.clearSearch,
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ).paddingSymmetric(vertical: 200),
      );
    }

    // Build court list with load more functionality
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courts.length + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end when loading more
        if (index == courts.length && controller.isLoadingMore.value) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: LoadingWidget(color: AppColors.primaryColor,),
            ),
          );
        }

        // Build court card
        if (index < courts.length) {
          return _buildCourtCard(context, courts[index], index);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCourtCard(BuildContext context, Courts club, int index) {
    final courtDetails = club.courts?.isNotEmpty == true ? club.courts![0] : null;
    final courtImage = courtDetails?.courtImage?.isNotEmpty == true ? courtDetails!.courtImage![0] : null;
    final courtCount = courtDetails?.courtCount ?? 0;
    final locationDetails = club.locations?.isNotEmpty == true ? club.locations![0] : null;
    final city = locationDetails?.city ?? club.city ?? "N/A";
    final zipCode = locationDetails?.zipCode ?? club.zipCode ?? "";
    
    return GestureDetector(
      onTap: () {
        log("CLUB ID -> ${club.id}");
        if (club.id != null) {
          Get.delete<BookingController>();
          
          String categoryId = "";
          String locationId = "";
          String userId = "";
          
          try {
            final mainHomeController = Get.find<MainHomeController>();
            categoryId = mainHomeController.selectedCategoryId.value;
            locationId = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "";
            userId = mainHomeController.profileController.profileModel.value?.response?.sId ?? "";
            
            log("Navigation data - categoryId: $categoryId, locationId: $locationId, userId: $userId");
          } catch (e) {
            log("MainHomeController not found: $e");
          }
          
          // Connect socket and register user
          try {
            final socketService = SocketService.instance;
            log("Socket service instance obtained");
            
            if (userId.isNotEmpty) {
              log("Setting user ID and connecting socket: $userId");
              socketService.setUserIdAndConnect(userId);
            } else {
              log("User ID is empty, connecting socket without user registration");
              socketService.connect();
            }
          } catch (e) {
            log("Socket service error: $e");
          }
          
          Get.toNamed(RoutesName.booking, arguments: {
            "data": club,
            "clubId": club.id,
            "sID": courtDetails?.id ?? "",
            "categoryId": categoryId,
            "location": locationId,
            "locationsId":club.locations?[0].id
          });
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.tabColor),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              height: 95,
              width: 118,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: club.logo != null && club.logo!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: club.logo!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(child: LoadingWidget(color: AppColors.primaryColor,)),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.business, color: Colors.grey)),
                )
                    : const Center(child: Icon(Icons.business, color: Colors.grey, size: 40)),
              ),
            ).paddingOnly(right: Get.width * 0.02),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.clubName ?? "N/A",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Image.asset(Assets.imagesIcLocation, scale: 3, color: AppColors.blackColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${city.capitalizeFirst}${zipCode.isNotEmpty ? ', $zipCode' : ''}",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$courtCount Courts",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(text: '₹', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.blueColor, fontSize: 17)),
                            TextSpan(
                              text: ' ${formatAmount(club.totalAmount ?? 00)}',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.blueColor, fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 15),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).paddingOnly(bottom: 5),
    );
  }

}
