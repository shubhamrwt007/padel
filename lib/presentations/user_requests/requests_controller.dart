import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:dio/dio.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/wallet/widgets/payment_for_wallet.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';

class RequestsController extends GetxController {
  ProfileController profileController = Get.put(ProfileController());
  final GetStorage storage = GetStorage();
  RxInt expandedIndex = (-1).obs;
  RxInt receiveExpandedIndex = (-1).obs;
  RxInt sentExpandedIndex = (-1).obs;
  final Set<String> viewedBookingRequestIds = {};

  Future<void> toggleExpand(int index, {Requests? request}) async {
    final activeExpandedIndex = selectedTab.value == 0
        ? receiveExpandedIndex
        : sentExpandedIndex;
    final shouldExpand = activeExpandedIndex.value != index;
    activeExpandedIndex.value = shouldExpand ? index : -1;
    expandedIndex.value = activeExpandedIndex.value;

    if (shouldExpand && selectedTab.value == 0 && request != null) {
      await markBookingRequestViewed(request);
    }
  }

  RxInt selectedTab = 0.obs; // 0 = Join, 1 = My
  void changeTab(int index) {
    selectedTab.value = index;
    expandedIndex.value = index == 0
        ? receiveExpandedIndex.value
        : sentExpandedIndex.value;
  }

  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  RxList<Requests> joinRequests = <Requests>[].obs;
  RxList<Requests> myRequests = <Requests>[].obs;
  RxBool isLoadingRequests = false.obs;
  RxMap<String, bool> acceptingRequests = <String, bool>{}.obs;

  void deleteRequest(int index) {
    if (selectedTab.value == 0) {
      if (index >= 0 && index < myRequests.length) {
        myRequests.removeAt(index);
        // Reset expanded index if needed
        if (sentExpandedIndex.value == index) {
          sentExpandedIndex.value = -1;
        } else if (sentExpandedIndex.value > index) {
          sentExpandedIndex.value = sentExpandedIndex.value - 1;
        }
        expandedIndex.value = sentExpandedIndex.value;
      }
    } else {
      if (index >= 0 && index < joinRequests.length) {
        joinRequests.removeAt(index);
        // Reset expanded index if needed
        if (receiveExpandedIndex.value == index) {
          receiveExpandedIndex.value = -1;
        } else if (receiveExpandedIndex.value > index) {
          receiveExpandedIndex.value = receiveExpandedIndex.value - 1;
        }
        expandedIndex.value = receiveExpandedIndex.value;
      }
    }
  }

  @override
  void onInit() async {
    super.onInit();
    await fetchJoinRequests();
    await fetchMyRequests();
  }

  Future<void> fetchJoinRequests() async {
    try {
      isLoadingRequests.value = true;
      joinRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(
        type: "both",
        filter: "invitation",
      );

      if (response != null && response.requests != null) {
        joinRequests.addAll(response.requests!);
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching join requests: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> fetchMyRequests() async {
    try {
      isLoadingRequests.value = true;
      myRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(
        type: "both",
        filter: "request",
      );

      if (response != null && response.requests != null) {
        requestIds.clear();
        requestIds.addAll(
          response.requests!
              .map((request) => request.id ?? "")
              .where((id) => id.isNotEmpty),
        );
        myRequests.addAll(response.requests!);
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching my requests: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> acceptPlayerRequest(
    String requestId,
    String matchId,
    String team,
    String requestType,
    Requests? request,
  ) async {
    try {
      acceptingRequests[requestId] = true;
      final body = {"requestId": requestId, "action": "accept"};

      if (requestType == 'booking_invitation') {
        await repository.respondToBookingRequest(body: body);
      } else if (requestType == 'request') {
        body["type"] = "MatchCreator";
        await repository.acceptOrRejectRequestPlayer(body: body);
      } else if (requestType == 'invitation') {
        await repository.acceptOrRejectRequestPlayer(body: body);
      }

      // Remove the accepted request from the list
      joinRequests.removeWhere((request) => request.id == requestId);
      // Refresh data
      await fetchJoinRequests();
      await profileController.fetCustomerLeaderBoardRank();
      // Close current page and navigate to booking history
      Get.back();
      Get.to(BookingHistoryUi(buttonType: "drawer",));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        Get.to(
          () => PaymentForWallet(
            totalAmount: request?.perShare?.toDouble() ?? 0.0,
            title: "Match Request",
          ),
          arguments: {
            'acceptRequestId': requestId,
            'acceptRequestType': requestType,
          },
        );
      } else if (e.response?.statusCode == 400) {
        AppToast.error(e.response?.data?['message'] ?? "");
      } else {
        CustomLogger.logMessage(
          msg: "Error accepting request: $e",
          level: LogLevel.error,
        );
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error accepting player request: $e",
        level: LogLevel.error,
      );
    } finally {
      acceptingRequests[requestId] = false;
    }
  }

  RxList<String> requestIds = <String>[].obs;
  Future<void> markBookingRequestViewed(Requests request) async {
    final bookingId = request.bookingId ?? "";
    final userId =
        storage.read("userId")?.toString() ??
        profileController.profileModel.value?.response?.sId ??
        "";

    if (bookingId.isEmpty || userId.isEmpty) {
      CustomLogger.logMessage(
        msg: "Skip mark booking request viewed: bookingId/userId missing",
        level: LogLevel.debug,
      );
      return;
    }

    final requestKey = request.id ?? bookingId;
    if (viewedBookingRequestIds.contains(requestKey)) return;

    viewedBookingRequestIds.add(requestKey);
    try {
      await repository.markBookingRequestViewed(
        body: {"bookingId": bookingId, "userId": userId, "isView": true},
      );
    } catch (e) {
      viewedBookingRequestIds.remove(requestKey);
      CustomLogger.logMessage(
        msg: "Error marking booking request viewed: $e",
        level: LogLevel.error,
      );
    }
  }

  Future<void> withdrawRequest(String requestId) async {
    if (requestId.isNotEmpty) {
      try {
        isLoadingRequests.value = true;
        final response = await repository.withdrawRequest(id: requestId);

        if (response.status == 200) {
          CustomLogger.logMessage(
            msg: response.message ?? "",
            level: LogLevel.debug,
          );
          // Remove the request from the list after successful withdrawal
          myRequests.removeWhere((request) => request.id == requestId);
          await profileController.fetCustomerLeaderBoardRank();
        }
      } catch (e) {
        CustomLogger.logMessage(
          msg: "Error request: $e",
          level: LogLevel.error,
        );
      } finally {
        isLoadingRequests.value = false;
      }
    }
  }

  Future<void> refreshData() async {
    if (selectedTab.value == 0) {
      await fetchJoinRequests();
    } else {
      await fetchMyRequests();
    }
  }

  // Helper methods for price formatting
  String formatAmount(String amount) {
    if (amount.isEmpty || amount == '0') return '0';
    try {
      final num value = num.parse(amount);
      return value.toStringAsFixed(0);
    } catch (e) {
      return amount;
    }
  }

  int getTotalAmount(Requests request) {
    return request.totalAmount ?? 0;
  }

  dynamic getPerShare(Requests request) {
    return request.perShare ?? 0;
  }
}
