import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import '../../../configs/components/snack_bars.dart';
import '../../../data/request_models/booking/booking_confermation_model.dart';
import '../../../data/request_models/booking/cancel_booking_model.dart';
import '../../../handler/logger.dart';
import '../../../repositories/bookinghisory/booking_history_repository.dart';
import '../../../repositories/review_repo/review_repository.dart'; // ✅ Add this import

class BookingConfirmAndCancelController extends GetxController {
  RxBool cancelBooking = false.obs;
  RxString selectedReason = ''.obs;
  var updateBookingStatusResponse = Rxn<CancelUserBooking>();
  TextEditingController otherReasonController = TextEditingController();

  // Track which slot is being cancelled
  RxnString slotToCancel = RxnString();

  // Booking details state
  Rx<BookingConfirmationModel?> bookingDetails = Rx<BookingConfirmationModel?>(null);
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  // ✅ Rating fields
  RxInt selectedRating = 0.obs;
  TextEditingController ratingMessageController = TextEditingController();

  List<String> cancellationReasons = [
    "Change of plans",
    "Found better timing",
    "Other"
  ];

  final BookingHistoryRepository _bookingRepo = BookingHistoryRepository();
  final ReviewRepository _reviewRepo = ReviewRepository(); // ✅ Add review repository
final fromBooking  = ''.obs;
final fromCancelled = ''.obs;
  @override
  void onInit() async {
    super.onInit();

    final String? bookingId = Get.arguments?['id'];
  fromBooking.value = Get.arguments?['fromCompleted']?.toString() ?? '';
  fromCancelled.value = Get.arguments?['fromCancelled']?.toString() ?? '';
    if (bookingId != null && bookingId.isNotEmpty) {
      await fetchBookingDetails(bookingId);
    } else {
      error.value = "No booking ID provided";
    }
  }

  /// Fetch booking details
  Future<void> fetchBookingDetails(String bookingId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final booking = await _bookingRepo.getBookingConfirmation(id: bookingId);
      bookingDetails.value = booking;

      if (booking.booking != null) {
        log("Booking details fetched! Status: ${booking.booking!.bookingStatus}");
      } else {
        log("No booking found for this ID");
      }
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) print("Error fetching booking details: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus() async {
    if (isLoading.value) return;

    if (bookingDetails.value == null || bookingDetails.value!.booking == null) {
      AppToast.error("Booking details not available");
      return;
    }

    if (otherReasonController.text.trim().isEmpty) {
      AppToast.error("Please enter the reason");
      return;
    }

    isLoading.value = true;

    try {
      final bookingId = bookingDetails.value!.booking!.sId;
      final slotId = slotToCancel.value;

      final body = {
        "id": bookingId,
        "status": "in-progress",
        "requestType":"user",
        "cancellationReason": otherReasonController.text.trim(),
        if (slotId != null) "slotId": slotId,
      };

      final result = await _bookingRepo.updateBookingStatus(body: body);
      updateBookingStatusResponse.value = result;

      if (result?.status == "200") {
        Get.offAllNamed(RoutesName.bottomNav);
        isLoading.value = false;

        // Refresh booking details
        await fetchBookingDetails(bookingId!);

        // Reset state
        cancelBooking.value = false;
        slotToCancel.value = null;

        CustomLogger.logMessage(
          msg: result?.message ?? "Updated",
          level: LogLevel.debug,
        );
        otherReasonController.clear();
      } else {
        CustomLogger.logMessage(msg: "Booking update failed", level: LogLevel.error);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: e, level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Submit rating with API integration
  Future<void> submitRating() async {
    if (isLoading.value) return;

    // ✅ Ensure booking details are available
    if (bookingDetails.value == null || bookingDetails.value!.booking == null) {
      AppToast.error("Booking details not available");
      return;
    }

    // ✅ Validate rating
    if (selectedRating.value == 0) {
      AppToast.error("Please select a rating");
      return;
    }

    // ✅ Validate message
    if (ratingMessageController.text.trim().isEmpty) {
      AppToast.error("Please write a message");
      return;
    }

    isLoading.value = true;

    try {
      final booking = bookingDetails.value!.booking!;
      final String? clubId = booking.registerClubId?.sId;

      if (clubId == null || clubId.isEmpty) {
        AppToast.error("Club ID not found");
        isLoading.value = false;
        return;
      }

      // ✅ Prepare request body
      final body = {
        "reviewComment": ratingMessageController.text.trim(),
        "reviewRating": selectedRating.value,
        "register_club_id": clubId,
      };

      CustomLogger.logMessage(
        msg: "Submitting review: $body",
        level: LogLevel.debug,
      );

      // ✅ API call
      final result = await _reviewRepo.createReview(data: body);

      // ✅ Success check
      if (result.review != null) {
        CustomLogger.logMessage(msg: result.message ?? "Thank you for your feedback!", level: LogLevel.error);

        // Reset fields
        selectedRating.value = 0;
        ratingMessageController.clear();

        CustomLogger.logMessage(
          msg:
          "Rating submitted successfully: ${result.review?.reviewRating} stars",
          level: LogLevel.debug,
        );
      } else {
        CustomLogger.logMessage(msg: result.message ?? "Failed to submit rating", level: LogLevel.error);
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Submit rating error: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    otherReasonController.dispose();
    ratingMessageController.dispose();
    super.onClose();
  }
}