import 'package:flutter/foundation.dart';

import '../../data/request_models/booking/boking_history_model.dart';
import '../../repositories/bookinghisory/booking_history_repository.dart';
import '../auth/forgot_password/widgets/forgot_password_exports.dart';

class BookingHistoryController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  final BookingHistoryRepository bookingRepo = BookingHistoryRepository();

  Rx<BookingHistoryModel?> upcomingBookings = Rx<BookingHistoryModel?>(null);
  Rx<BookingHistoryModel?> ongoingBookings = Rx<BookingHistoryModel?>(null);
  Rx<BookingHistoryModel?> completedBookings = Rx<BookingHistoryModel?>(null);
  Rx<BookingHistoryModel?> cancelledBookings = Rx<BookingHistoryModel?>(null);

  // Pagination variables
  RxInt upcomingPage = 1.obs;
  RxInt ongoingPage = 1.obs;
  RxInt completedPage = 1.obs;
  RxInt cancelledPage = 1.obs;

  RxBool upcomingHasMore = true.obs;
  RxBool ongoingHasMore = true.obs;
  RxBool completedHasMore = true.obs;
  RxBool cancelledHasMore = true.obs;

  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    tabController = TabController(length: 3, vsync: this); // Changed from 2 to 3

    // Add tab listener to fetch data when switching tabs
    tabController.addListener(() {
      if (!tabController.indexIsChanging) return;

      final currentIndex = tabController.index;
      String type = "upcoming";
      if (currentIndex == 1) type = "ongoing";
      if (currentIndex == 2) type = "completed";

      // Fetch data for the tab if not already loaded
      switch (type) {
        case "ongoing":
          if (ongoingBookings.value == null) fetchBookings("ongoing");
          break;
        case "completed":
          if (completedBookings.value == null) fetchBookings("completed");
          break;
      }
    });

    fetchBookings();
    super.onInit();
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
        ongoingPage.value = 1;
        completedPage.value = 1;
        cancelledPage.value = 1;
        upcomingHasMore.value = true;
        ongoingHasMore.value = true;
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
    final data = await bookingRepo.getBookingHistory(type: type, page: 1, limit: 10);
    data.data ??= [];

    switch (type) {
      case "upcoming":
        upcomingPage.value = 1;
        upcomingBookings.value = data;
        upcomingHasMore.value = (data.totalPages != null && data.page != null)
            ? data.page! < data.totalPages! : false;
        break;
      case "ongoing":
        ongoingPage.value = 1;
        ongoingBookings.value = data;
        ongoingHasMore.value = (data.totalPages != null && data.page != null)
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

          newData = await bookingRepo.getBookingHistory(type: type, page: nextPage, limit: 10);
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

        case "ongoing":
          nextPage = ongoingPage.value + 1;
          if (kDebugMode) {
            print("Loading ongoing page: $nextPage");
          }

          newData = await bookingRepo.getBookingHistory(type: type, page: nextPage, limit: 10);
          if (kDebugMode) {
            print("Ongoing page $nextPage - page: ${newData.page}, totalPages: ${newData.totalPages}, data: ${newData.data?.length}");
          }

          if (newData.data != null && newData.data!.isNotEmpty) {
            ongoingBookings.value ??= BookingHistoryModel();
            ongoingBookings.value!.data ??= [];
            ongoingBookings.value!.data!.addAll(newData.data!);
            ongoingPage.value = nextPage;

            if (newData.totalPages != null && newData.page != null) {
              ongoingHasMore.value = newData.page! < newData.totalPages!;
            } else {
              ongoingHasMore.value = false;
            }

            if (kDebugMode) {
              print("Updated ongoing: page $nextPage, hasMore: ${ongoingHasMore.value}");
            }
            ongoingBookings.refresh();
          } else {
            ongoingHasMore.value = false;
            if (kDebugMode) {
              print("No more ongoing data available");
            }
          }
          break;

        case "completed":
          nextPage = completedPage.value + 1;
          if (kDebugMode) {
            print("Loading completed page: $nextPage");
          }

          newData = await bookingRepo.getBookingHistory(type: type, page: nextPage, limit: 10);
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

          newData = await bookingRepo.getBookingHistory(type: type, page: nextPage, limit: 10);
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
      case "ongoing":
        result = ongoingHasMore.value;
        if (kDebugMode) {
          print("hasMoreData ongoing: $result, page: ${ongoingPage.value}, totalPages: ${ongoingBookings.value?.totalPages}");
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
    fetchBookings();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}