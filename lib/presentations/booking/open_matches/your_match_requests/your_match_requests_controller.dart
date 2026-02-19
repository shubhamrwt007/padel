import 'package:get/get.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/wallet/widgets/payment_for_wallet.dart';

class YourMatchRequestsController extends GetxController {
  RxInt expandedIndex = (-1).obs;

  void toggleExpand(int index) {
    expandedIndex.value =
        expandedIndex.value == index ? -1 : index;
  }

  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  RxList<Requests> joinRequests = <Requests>[].obs;
  RxBool isLoadingRequests = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchJoinRequests();
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
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> acceptRequest(String requestId, String requestType, Requests request) async {
    try {
      final body = {
        "requestId": requestId,
        "action": "accept",
      };

      if (requestType == 'booking_invitation') {
        await repository.respondToBookingRequest(body: body);
      } else if (requestType == 'invitation') {
        await repository.acceptOrRejectRequestPlayer(body: body);
      }
      
      // Refresh the list after accepting
      fetchJoinRequests();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        Get.to(() => PaymentForWallet(
          totalAmount: request.perShare?.toDouble() ?? 0.0,
          title: "Match Request",
        ));
        // _showInsufficientBalanceDialog(
        //   e.response?.data?['message'] ?? "Resource not found",
        // );
      } else {
        CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
    }
  }
}
