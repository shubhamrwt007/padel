import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:padel_mobile/presentations/auth/sign_up/widgets/sign_up_exports.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../data/request_models/booking/boking_history_model.dart';
import '../../repositories/bookinghisory/booking_history_repository.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';
import '../main_home_page/main_home_controller.dart';

class BookingHistoryController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  final BookingHistoryRepository bookingRepo = BookingHistoryRepository();

  Rx<BookingHistoryModel?> upcomingBookings = Rx<BookingHistoryModel?>(null);
  Rx<BookingHistoryModel?> inProgressBookings = Rx<BookingHistoryModel?>(null);
  Rx<BookingHistoryModel?> completedBookings = Rx<BookingHistoryModel?>(null);
  Rx<BookingHistoryModel?> cancelledBookings = Rx<BookingHistoryModel?>(null);

  // Pagination variables
  RxInt upcomingPage = 1.obs;
  RxInt inProgressPage = 1.obs;
  RxInt completedPage = 1.obs;
  RxInt cancelledPage = 1.obs;

  RxBool upcomingHasMore = true.obs;
  RxBool inProgressHasMore = true.obs;
  RxBool completedHasMore = true.obs;
  RxBool cancelledHasMore = true.obs;

  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxString errorMessage = ''.obs;

  RxString categoryId = ''.obs;
  RxString location = ''.obs;

  @override
  void onInit() {
    tabController = TabController(length: 3, vsync: this); // Changed from 2 to 3

    // Get categoryId and location from MainHomeController
    try {
      final mainHomeController = Get.find<MainHomeController>();
      categoryId.value = mainHomeController.selectedCategoryId.value;
      location.value = mainHomeController.profileController.profileModel.value?.response?.city?.sId ?? "68c94a94d72a6f9769712ff0";

      // Listen to category changes
      ever(mainHomeController.selectedCategoryId, (String newCategoryId) {
        if (categoryId.value != newCategoryId) {
          categoryId.value = newCategoryId;
          onCategoryOrLocationChanged();
        }
      });
    } catch (e) {
      print("Error getting MainHomeController: $e");
    }

    // Add tab listener to fetch data when switching tabs
    tabController.addListener(() {
      if (!tabController.indexIsChanging) return;

      final currentIndex = tabController.index;
      String type = "upcoming";
      if (currentIndex == 1) type = "in-progress";
      if (currentIndex == 2) type = "completed";

      // Fetch data for the tab if not already loaded
      switch (type) {
        case "upcoming":
          if (upcomingBookings.value == null) fetchBookings("upcoming");
          break;
        case "in-progress":
          if (inProgressBookings.value == null) fetchBookings("in-progress");
          break;
        case "completed":
          if (completedBookings.value == null) fetchBookings("completed");
          break;
      }
    });

    fetchBookings();
    super.onInit();
  }

  void onCategoryOrLocationChanged() {
    upcomingBookings.value = null;
    inProgressBookings.value = null;
    completedBookings.value = null;
    cancelledBookings.value = null;

    upcomingPage.value = 1;
    inProgressPage.value = 1;
    completedPage.value = 1;
    cancelledPage.value = 1;

    upcomingHasMore.value = true;
    inProgressHasMore.value = true;
    completedHasMore.value = true;
    cancelledHasMore.value = true;

    final currentIndex = tabController.index;
    String type = "upcoming";
    if (currentIndex == 1) type = "in-progress";
    if (currentIndex == 2) type = "completed";

    fetchBookings(type);
  }

  void fetchBookings([String? specificType]) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (specificType != null) {
        await _fetchBookingType(specificType);
      } else {
        // Reset pagination for all types
        upcomingPage.value = 1;
        inProgressPage.value = 1;
        completedPage.value = 1;
        cancelledPage.value = 1;
        upcomingHasMore.value = true;
        inProgressHasMore.value = true;
        completedHasMore.value = true;
        cancelledHasMore.value = true;

        // Only fetch upcoming initially (active tab)
        await _fetchBookingType("upcoming");
      }

      update();
    } catch (e) {
      errorMessage.value = "Failed to fetch bookings: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchBookingType(String type) async {
    final data = await bookingRepo.getBookingHistory(
      type: type,
      page: 1,
      limit: 30,
      categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
      locationId: location.value.isNotEmpty ? location.value : null,
    );
    data.data ??= [];

    switch (type) {
      case "upcoming":
        upcomingPage.value = 1;
        upcomingBookings.value = data;
        upcomingHasMore.value = (data.totalPages != null && data.page != null)
            ? data.page! < data.totalPages! : false;
        break;
      case "in-progress":
        inProgressPage.value = 1;
        inProgressBookings.value = data;
        inProgressHasMore.value = (data.totalPages != null && data.page != null)
            ? data.page! < data.totalPages! : false;
        break;
      case "completed":
        completedPage.value = 1;
        completedBookings.value = data;
        completedHasMore.value = (data.totalPages != null && data.page != null)
            ? data.page! < data.totalPages! : false;
        break;
      case "cancelled":
        cancelledPage.value = 1;
        cancelledBookings.value = data;
        cancelledHasMore.value = (data.totalPages != null && data.page != null)
            ? data.page! < data.totalPages! : false;
        break;
    }
  }

  void loadMoreBookings(String type) async {
    if (isLoadingMore.value) {
      if (kDebugMode) {
        print("Already loading more data, skipping...");
      }
      return;
    }

    if (!hasMoreData(type)) {
      if (kDebugMode) {
        print("No more $type data available");
      }
      return;
    }

    try {
      isLoadingMore.value = true;

      BookingHistoryModel? newData;
      int nextPage;

      switch (type) {
        case "upcoming":
          nextPage = upcomingPage.value + 1;
          if (kDebugMode) {
            print("Loading upcoming page: $nextPage");
          }

          newData = await bookingRepo.getBookingHistory(
            type: type,
            page: nextPage,
            limit: 10,
            categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
            locationId: location.value.isNotEmpty ? location.value : null,
          );
          if (kDebugMode) {
            print("Upcoming page $nextPage - page: ${newData.page}, totalPages: ${newData.totalPages}, data: ${newData.data?.length}");
          }

          if (newData.data != null && newData.data!.isNotEmpty) {
            upcomingBookings.value ??= BookingHistoryModel();
            upcomingBookings.value!.data ??= [];
            upcomingBookings.value!.data!.addAll(newData.data!);
            upcomingPage.value = nextPage;

            if (newData.totalPages != null && newData.page != null) {
              upcomingHasMore.value = newData.page! < newData.totalPages!;
            } else {
              upcomingHasMore.value = false;
            }

            if (kDebugMode) {
              print("Updated upcoming: page $nextPage, hasMore: ${upcomingHasMore.value}");
            }
            upcomingBookings.refresh();
          } else {
            upcomingHasMore.value = false;
            if (kDebugMode) {
              print("No more upcoming data available");
            }
          }
          break;

        case "in-progress":
          nextPage = inProgressPage.value + 1;
          if (kDebugMode) {
            print("Loading in-progress page: $nextPage");
          }

          newData = await bookingRepo.getBookingHistory(
            type: type,
            page: nextPage,
            limit: 10,
            categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
            locationId: location.value.isNotEmpty ? location.value : null,
          );
          if (kDebugMode) {
            print("In-progress page $nextPage - page: ${newData.page}, totalPages: ${newData.totalPages}, data: ${newData.data?.length}");
          }

          if (newData.data != null && newData.data!.isNotEmpty) {
            inProgressBookings.value ??= BookingHistoryModel();
            inProgressBookings.value!.data ??= [];
            inProgressBookings.value!.data!.addAll(newData.data!);
            inProgressPage.value = nextPage;

            if (newData.totalPages != null && newData.page != null) {
              inProgressHasMore.value = newData.page! < newData.totalPages!;
            } else {
              inProgressHasMore.value = false;
            }

            if (kDebugMode) {
              print("Updated in-progress: page $nextPage, hasMore: ${inProgressHasMore.value}");
            }
            inProgressBookings.refresh();
          } else {
            inProgressHasMore.value = false;
            if (kDebugMode) {
              print("No more in-progress data available");
            }
          }
          break;

        case "completed":
          nextPage = completedPage.value + 1;
          if (kDebugMode) {
            print("Loading completed page: $nextPage");
          }

          newData = await bookingRepo.getBookingHistory(
            type: type,
            page: nextPage,
            limit: 10,
            categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
            locationId: location.value.isNotEmpty ? location.value : null,
          );
          if (kDebugMode) {
            print("Completed page $nextPage - page: ${newData.page}, totalPages: ${newData.totalPages}, data: ${newData.data?.length}");
          }

          if (newData.data != null && newData.data!.isNotEmpty) {
            completedBookings.value ??= BookingHistoryModel();
            completedBookings.value!.data ??= [];
            completedBookings.value!.data!.addAll(newData.data!);
            completedPage.value = nextPage;

            if (newData.totalPages != null && newData.page != null) {
              completedHasMore.value = newData.page! < newData.totalPages!;
            } else {
              completedHasMore.value = false;
            }

            if (kDebugMode) {
              print("Updated completed: page $nextPage, hasMore: ${completedHasMore.value}");
            }
            completedBookings.refresh();
          } else {
            completedHasMore.value = false;
            if (kDebugMode) {
              print("No more completed data available");
            }
          }
          break;

        case "cancelled":
          nextPage = cancelledPage.value + 1;
          if (kDebugMode) {
            print("Loading cancelled page: $nextPage");
          }

          newData = await bookingRepo.getBookingHistory(
            type: type,
            page: nextPage,
            limit: 10,
            categoryId: categoryId.value.isNotEmpty ? categoryId.value : null,
            locationId: location.value.isNotEmpty ? location.value : null,
          );
          if (kDebugMode) {
            print("Cancelled page $nextPage - page: ${newData.page}, totalPages: ${newData.totalPages}, data: ${newData.data?.length}");
          }

          if (newData.data != null && newData.data!.isNotEmpty) {
            cancelledBookings.value ??= BookingHistoryModel();
            cancelledBookings.value!.data ??= [];
            cancelledBookings.value!.data!.addAll(newData.data!);
            cancelledPage.value = nextPage;

            if (newData.totalPages != null && newData.page != null) {
              cancelledHasMore.value = newData.page! < newData.totalPages!;
            } else {
              cancelledHasMore.value = false;
            }

            if (kDebugMode) {
              print("Updated cancelled: page $nextPage, hasMore: ${cancelledHasMore.value}");
            }
            cancelledBookings.refresh();
          } else {
            cancelledHasMore.value = false;
            if (kDebugMode) {
              print("No more cancelled data available");
            }
          }
          break;
      }

      update();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error loading more bookings: $e");
      }
      if (kDebugMode) {
        print("Stack trace: $stackTrace");
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  bool hasMoreData(String type) {
    bool result;
    switch (type) {
      case "upcoming":
        result = upcomingHasMore.value;
        if (kDebugMode) {
          print("hasMoreData upcoming: $result, page: ${upcomingPage.value}, totalPages: ${upcomingBookings.value?.totalPages}");
        }
        break;
      case "in-progress":
        result = inProgressHasMore.value;
        if (kDebugMode) {
          print("hasMoreData in-progress: $result, page: ${inProgressPage.value}, totalPages: ${inProgressBookings.value?.totalPages}");
        }
        break;
      case "completed":
        result = completedHasMore.value;
        if (kDebugMode) {
          print("hasMoreData completed: $result, page: ${completedPage.value}, totalPages: ${completedBookings.value?.totalPages}");
        }
        break;
      case "cancelled":
        result = cancelledHasMore.value;
        if (kDebugMode) {
          print("hasMoreData cancelled: $result, page: ${cancelledPage.value}, totalPages: ${cancelledBookings.value?.totalPages}");
        }
        break;
      default:
        result = false;
    }
    return result;
  }

  void refreshBookings() {
    // Get current tab index and fetch data for that specific tab
    final currentIndex = tabController.index;
    String type = "upcoming";
    if (currentIndex == 1) type = "in-progress";
    if (currentIndex == 2) type = "completed";
    
    fetchBookings(type);
  }

  Future<void> updateNewCourtBooking({
    required String openMatchId,
    required List<Map<String, String>> slots,
  }) async {
    try {
      isLoading.value = true;
      
      final body = {
        "openMatchId": openMatchId,
        "slots": slots,
      };
      
      final result = await bookingRepo.updateNewCourtBookingModel(body: body);
      
      if (result?.status == 200) {
        Get.back(); // Close the sheet
        refreshBookings(); // Refresh the bookings list
        CustomLogger.logMessage(msg: "MESSAGE-> ${result?.message??""}", level: LogLevel.debug);
      } else {
        CustomLogger.logMessage(msg: "Failed to update court booking", level: LogLevel.debug);

      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Failed to update court booking: $e", level: LogLevel.debug);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refund({
    required String openMatchId,
    required int refund,
  }) async {
    try {
      isLoading.value = true;
      
      final body = {
        "openMatchId": openMatchId,
        "refund": refund,
      };
      
      final result = await bookingRepo.updateRefundAmount(body: body);
      
      if (result?.status == 200) {
        CustomLogger.logMessage(msg: "Refund processed successfully", level: LogLevel.debug);

        refreshBookings();
      } else {
        CustomLogger.logMessage(msg: "Failed to process refund", level: LogLevel.debug);

      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Failed to process refund: $e", level: LogLevel.debug);

    } finally {
      isLoading.value = false;
    }
  }

  // Helper function to get initials from full name
  String getInitials(String name) {
    if (name.trim().isEmpty) return '';
    
    List<String> nameParts = name.trim().split(' ');
    String initials = '';
    
    // Take first letter of first name and last name (max 2 initials)
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0].toUpperCase();
      if (nameParts.length > 1) {
        initials += nameParts[nameParts.length - 1][0].toUpperCase();
      }
    }
    
    return initials;
  }

  Future<void> downloadInvoice(String invoiceUrl) async {
    try {
      Get.dialog(
        const Center(child: LoadingWidget(color: Colors.white,)),
        barrierDismissible: false,
      );

      // Request storage permission based on Android version
      PermissionStatus status;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ doesn't need storage permission for downloads
          status = PermissionStatus.granted;
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.storage.request();
      }
      
      if (status.isDenied) {
        Get.back();
        AppToast.error("Storage permission denied");
        return;
      }

      final response = await http.get(Uri.parse(invoiceUrl));

      if (response.statusCode == 200) {
        Directory? directory;
        
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'invoice_$timestamp.pdf';
        final filePath = '${directory!.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        Get.back();
        AppToast.error("Invoice downloaded to Downloads folder");
      } else {
        Get.back();
        AppToast.error("Failed to download invoice");
      }
    } catch (e) {
      Get.back();
      AppToast.error("Error downloading invoice: $e");
    }
  }


  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}