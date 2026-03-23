import 'dart:developer';
import 'package:padel_mobile/data/request_models/home_models/get_club_name_model.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/booking/home_content/home_content_controller.dart';
import 'package:padel_mobile/presentations/booking/book_session/book_session_controller.dart';
import 'package:padel_mobile/presentations/booking/americano/americano_controller.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../../repositories/home_repository/home_repository.dart';

class BookingController extends GetxController with GetSingleTickerProviderStateMixin {
  DetailsController detailsController = Get.put(DetailsController());
  ProfileController profileController = Get.put(ProfileController());
  late TabController tabController;

  Rx<Courts> courtsData = Courts().obs;

  /// 🔹 Reactive variable to track cart count
  RxInt cartCount = 0.obs;

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1,
    );

    _loadBookingData();
  }

  // Call this method when returning from payment or any other page
  Future<void> onPageResumed() async {
    // Get selected slots from BookSessionController if available
    if (Get.isRegistered<BookSessionController>()) {
      final bookSessionController = Get.find<BookSessionController>();
      await bookSessionController.cleanupOnBack();
    } else {
      // Fallback: call with empty slots
      await _callDeleteSlotHistoryAPI();
    }
  }

  Future<void> _callDeleteSlotHistoryAPI() async {
    try {
      final repository = HomeRepository();
      await repository.deleteSlotHistory(data: {"slots": []});
      log('Called deleteSlotHistory API on page return');
    } catch (e) {
      log('Error calling deleteSlotHistory API: $e');
    }
  }

  void _loadBookingData() {
    final args = Get.arguments;
    if (args != null && args["data"] != null) {
      courtsData.value = args["data"];
      detailsController.localMatchData.update(
        "address",
            (v) => "${courtsData.value.city},${courtsData.value.address}",
      );

      log("Data Fetch Successfully -> ${courtsData.value}");
      profileController.fetchUserProfile();
      _refreshChildControllers();
    }
  }

  void _refreshChildControllers() {
    try {
      if (Get.isRegistered<HomeContentController>()) {
        Get.delete<HomeContentController>();
      }
      if (Get.isRegistered<BookSessionController>()) {
        Get.delete<BookSessionController>();
      }
      if (Get.isRegistered<OpenMatchesController>()) {
        Get.delete<OpenMatchesController>();
      }
      if (Get.isRegistered<AmericanoController>()) {
        Get.delete<AmericanoController>();
      }
    } catch (e) {
      log("Error refreshing child controllers: $e");
    }
  }

  // /// Optional helper methods to modify cart count
  // void addToCart() {
  //   cartCount.value++;
  // }

  // void removeFromCart() {
  //   if (cartCount.value > 0) cartCount.value--;
  // }

  // void setCartCount(int count) {
  //   cartCount.value = count;
  // }

  /// Try getting image file from cache or download if not available
  // Future<File?> _getCachedOrDownloadImage(String imageUrl) async {
  //   try {
  //     final cacheManager = DefaultCacheManager();
  //     final fileInfo = await cacheManager.getFileFromCache(imageUrl);
  //
  //     if (fileInfo != null && await fileInfo.file.exists()) {
  //       return fileInfo.file;
  //     }
  //
  //     final response = await http.get(Uri.parse(imageUrl));
  //     if (response.statusCode == 200) {
  //       final file = await cacheManager.putFile(
  //         imageUrl,
  //         response.bodyBytes,
  //         fileExtension: 'jpg',
  //       );
  //       return file;
  //     }
  //   } catch (e) {
  //     debugPrint('Error getting cached/downloaded image: $e');
  //   }
  //   return null;
  // }

  /// Share image with text
  Future<void> shareWithImage() async {
    try {
      final imageUrl = courtsData.value.courtImage?.isNotEmpty == true
          ? courtsData.value.courtImage!.first
          : null;

      Get.dialog(
        const Center(child: LoadingWidget(color: AppColors.primaryColor,)),
        barrierDismissible: false,
      );

      await Future.delayed(const Duration(milliseconds: 150));

      if (imageUrl != null && imageUrl.isNotEmpty) {
        String? imagePath;
        try {
          final cacheManager = DefaultCacheManager();
          final fileInfo = await cacheManager.getFileFromCache(imageUrl);

          if (fileInfo != null && await fileInfo.file.exists()) {
            imagePath = fileInfo.file.path;
          } else {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final file = await cacheManager.putFile(
                imageUrl,
                response.bodyBytes,
                fileExtension: 'jpg',
              );
              imagePath = file.path;
            }
          }
        } catch (_) {}

        Get.back();

        if (imagePath != null) {
          await Share.shareXFiles(
            [XFile(imagePath)],
            text: 'Check out this amazing club: ${courtsData.value.clubName ?? 'Unknown Club'}\n${courtsData.value.address ?? ''}, ${courtsData.value.city ?? ''}',
            subject: 'Padel Club Details',
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
          );
        } else {
          shareTextOnly();
        }
      } else {
        Get.back();
        shareTextOnly();
      }
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      shareTextOnly();
    }
  }

  void shareTextOnly() {
    Share.share(
      'Check out this amazing club: ${courtsData.value.clubName ?? 'Unknown Club'}\n${courtsData.value.address ?? ''}, ${courtsData.value.city ?? ''}',
      subject: 'Padel Club Details',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
