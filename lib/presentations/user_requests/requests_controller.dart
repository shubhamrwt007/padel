import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/wallet/widgets/payment_for_wallet.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';

class RequestsController extends GetxController {
  ProfileController profileController = Get.put(ProfileController());
  RxInt expandedIndex = (-1).obs;

  void toggleExpand(int index) {
    expandedIndex.value = expandedIndex.value == index ? -1 : index;
  }

  RxInt selectedTab = 0.obs; // 0 = Join, 1 = My
  void changeTab(int index) => selectedTab.value = index;

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
        if (expandedIndex.value == index) {
          expandedIndex.value = -1;
        } else if (expandedIndex.value > index) {
          expandedIndex.value = expandedIndex.value - 1;
        }
      }
    } else {

      if (index >= 0 && index < joinRequests.length) {
        joinRequests.removeAt(index);
        // Reset expanded index if needed
        if (expandedIndex.value == index) {
          expandedIndex.value = -1;
        } else if (expandedIndex.value > index) {
          expandedIndex.value = expandedIndex.value - 1;
        }
      }
    }
  }

  @override
  void onInit()async {
    super.onInit();
    await fetchJoinRequests();
    await fetchMyRequests();
  }
  Future<void> fetchJoinRequests() async {
    try {
      isLoadingRequests.value = true;
      joinRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(type: "both",filter: "invitation");

      if (response != null && response.requests != null) {
        joinRequests.addAll(response.requests!);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching join requests: $e", level: LogLevel.error);
      // Get.snackbar("Error", "Failed to fetch join requests");
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> fetchMyRequests() async {
    try {
      isLoadingRequests.value = true;
      myRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(type: "both",filter: "request");

      if (response != null && response.requests != null) {
        requestIds.clear();
        requestIds.addAll(response.requests!.map((request) => request.id ?? "").where((id) => id.isNotEmpty));
        myRequests.addAll(response.requests!);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching my requests: $e", level: LogLevel.error);
      // Get.snackbar("Error", "Failed to fetch my requests");
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> acceptPlayerRequest(String requestId, String matchId, String team, String requestType,Requests? request) async {
    try {
      acceptingRequests[requestId] = true;
      final body = {
        "requestId": requestId,
        "action": "accept",
      };

      if (requestType == 'booking_invitation') {
        await repository.respondToBookingRequest(body: body);
      } else if (requestType == 'request') {
        body["type"] = "MatchCreator";
        await repository.acceptOrRejectRequestPlayer(body: body);
      }else if(requestType == 'invitation'){
        await repository.acceptOrRejectRequestPlayer(body: body);
      }
      
      // Remove the accepted request from the list
      joinRequests.removeWhere((request) => request.id == requestId);
      // Refresh data
      await fetchJoinRequests();
      await profileController.fetCustomerLeaderBoardRank();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        Get.to(() => PaymentForWallet(
          totalAmount: request?.perShare?.toDouble() ?? 0.0,
          title: "Match Request",
        ));
      } else if (e.response?.statusCode == 400) {
        AppToast.error(e.response?.data?['message']??"");
      }else {
        CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
        Get.snackbar("Error", "Failed to accept request");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error accepting player request: $e", level: LogLevel.error);
    } finally {
      acceptingRequests[requestId] = false;
    }
  }

  RxList<String> requestIds = <String>[].obs;
  Future<void> withdrawRequest(String requestId) async {
    if (requestId.isNotEmpty) {
      try {
        isLoadingRequests.value = true;
        final response = await repository.withdrawRequest(id: requestId);

        if (response.status == 200) {
          CustomLogger.logMessage(msg: response.message ?? "", level: LogLevel.debug);
          // Remove the request from the list after successful withdrawal
          myRequests.removeWhere((request) => request.id == requestId);
          // Get.snackbar("Success", "Request withdrawn successfully");
          await profileController.fetCustomerLeaderBoardRank();
        }
      } catch (e) {
        CustomLogger.logMessage(msg: "Error request: $e", level: LogLevel.error);
        // Get.snackbar("Error", "Failed to withdraw request");
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