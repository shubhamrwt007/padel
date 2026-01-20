import 'package:get/get.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'package:padel_mobile/handler/text_formatter.dart';

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

      final response = await repository.getRequestPlayersOpenMatch();

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

  Future<void> acceptRequest(String requestId, String requestType) async {
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
        _showInsufficientBalanceDialog(
          e.response?.data?['message'] ?? "Resource not found",
        );
      } else {
        CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
        Get.snackbar("Error", "Failed to accept request");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error accepting request: $e", level: LogLevel.error);
      Get.snackbar("Error", "Failed to accept request");
    }
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