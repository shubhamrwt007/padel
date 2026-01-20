import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'package:padel_mobile/handler/text_formatter.dart';

class RequestsController extends GetxController {
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
  void onInit() {
    super.onInit();
    fetchJoinRequests();
    fetchMyRequests();
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

  Future<void> acceptPlayerRequest(String requestId, String matchId, String team, String requestType) async {
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
      fetchJoinRequests();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _showInsufficientBalanceDialog(
          e.response?.data?['message'] ?? "Resource not found",
        );
      } else if (e.response?.statusCode == 400) {
        Fluttertoast.showToast(
          msg: e.response?.data?['message']??"",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
          timeInSecForIosWeb: 3,
        );
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

  void _showInsufficientBalanceDialog(String message) {
    final TextEditingController amountController = TextEditingController();
    final WalletController walletController = Get.put(WalletController());
    walletController.fetchWallet();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Insufficient Balance",
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Current Balance: ₹${formatAmount(walletController.walletBalance.value.toString())} Credits",
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: Get.textTheme.labelLarge!
                            .copyWith(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: walletController.isAddingBalance.value
                            ? null
                            : () {
                                final amount = int.tryParse(amountController.text) ?? 0;
                                if (amount > 0) {
                                  walletController.createBalance(amount);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F49C6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: walletController.isAddingBalance.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Pay Now",
                                style: Get.textTheme.labelLarge!
                                    .copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}