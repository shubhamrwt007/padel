import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/data/request_models/test_create_wallet_balance_model.dart';
import 'package:padel_mobile/data/response_models/wallet/get_wallet_model.dart';
import 'package:padel_mobile/data/response_models/wallet/transaction_history_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/repositories/wallet_repository/wallet_repository.dart';
import 'package:padel_mobile/services/payment_services/razorpay.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';

class WalletController extends GetxController{
  final WalletRepository repository = Get.put(WalletRepository());
  RazorpayPaymentService? _paymentService;
  ProfileController profileController = Get.put(ProfileController());
  
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var isWalletLoading = false.obs;
  var isAddingBalance = false.obs;
  var transactionList = <Transaction>[].obs;
  var walletBalance = 0.obs;
  var totalSpendingBalance = 0.obs;
  var totalDebitedBalance = 0.obs;
  var pendingAmount = 0.obs;
  var currentPage = 1;
  var hasMoreTransactions = true.obs;
  
  Future<void> fetchTransaction({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        currentPage = 1;
        hasMoreTransactions.value = true;
      }
      isLoading.value = true;
      final response = await repository.getTransaction(
        page: currentPage.toString(),
        limit: 10
      );
      if (response.status == 200) {
        if (isRefresh) {
          transactionList.value = response.transactions ?? [];
        } else {
          transactionList.addAll(response.transactions ?? []);
        }
        hasMoreTransactions.value = (response.transactions?.length ?? 0) >= 10;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR->$e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreTransactions() async {
    if (isLoadingMore.value || !hasMoreTransactions.value) return;
    try {
      isLoadingMore.value = true;
      currentPage++;
      final response = await repository.getTransaction(
        page: currentPage.toString(),
        limit: 10
      );
      if (response.status == 200) {
        transactionList.addAll(response.transactions ?? []);
        hasMoreTransactions.value = (response.transactions?.length ?? 0) >= 10;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR->$e", level: LogLevel.error);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchWallet() async {
    try {
      isWalletLoading.value = true;
      final response = await repository.getWallet();
      walletBalance.value = response.balance ?? 0;
      totalDebitedBalance.value = response.totalDebitedBalance ?? 0;
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR->$e", level: LogLevel.error);
    } finally {
      isWalletLoading.value = false;
    }
  }

  Future<void> createBalance(int amount) async {
    try {
      isAddingBalance.value = true;
      pendingAmount.value = amount;

      final data = {"amount": amount};
      final LiveWalletAddBalanceModel response =
      await repository.testCreateWalletBalance(data: data);

      Get.back();

      if (response.orderId != null && response.amount != null) {
        await _initiateRazorpayPayment(response.orderId!, response.amount!);
      } else {
        // SnackBarUtils.showErrorSnackBar("Failed to create wallet order");
        isAddingBalance.value = false;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR -> $e", level: LogLevel.error);
      // SnackBarUtils.showErrorSnackBar("Something went wrong");
      isAddingBalance.value = false;
    }
  }

  Future<void> _initiateRazorpayPayment(String orderId, int amount) async {
    try {
      await _paymentService!.initiatePayment(
        // keyId: 'rzp_test_1DP5mmOlF5G5ag',
        ///Live Key-----------------------------
        keyId: 'rzp_live_RtOIWe2johK6H7',
        amount: amount.toDouble(),
        currency: 'INR',
        name: 'Swoot',
        description: 'Add balance to wallet',
        orderId: orderId,
        userEmail: profileController.profileModel.value?.response?.email ?? 'test@example.com',
        userContact: '9999999999',
        notes: {
          'user_id': profileController.profileModel.value?.response?.sId ?? '',
          'type': 'wallet_recharge',
        },
        theme: '#F37254',
        paymentMethods: ['card', 'netbanking', 'upi', 'wallet'],
      );
    } catch (e) {
      CustomLogger.logMessage(msg: "Payment initiation error: $e", level: LogLevel.error);
      // SnackBarUtils.showErrorSnackBar("Failed to initiate payment");
      isAddingBalance.value = false;
    }
  }

  Future<void> _onPaymentSuccess(String paymentId, String orderId, String signature) async {
    try {
      // SnackBarUtils.showSuccessSnackBar("Balance added successfully");
      await fetchWallet();
      await fetchTransaction(isRefresh: true);
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR -> $e", level: LogLevel.error);
    } finally {
      isAddingBalance.value = false;
    }
  }

  void _onPaymentError(String error) {
    // SnackBarUtils.showErrorSnackBar("Payment failed: $error");
    CustomLogger.logMessage(msg: "Payment failed: $error", level: LogLevel.error);
    isAddingBalance.value = false;
  }


  void showAddBalanceDialog() {
    final TextEditingController amountController = TextEditingController();

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
              // Icon
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
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

              // Title
              Text(
                "Add Balance",
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // Amount Input
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
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
                        onPressed: isAddingBalance.value
                            ? null
                            : () {
                          final amount =
                              int.tryParse(amountController.text) ?? 0;
                          if (amount > 0) {
                            createBalance(amount);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isAddingBalance.value
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingWidget(
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          "Add",
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


  @override
  void onInit() {
    super.onInit();
    _paymentService = RazorpayPaymentService();

    _paymentService!.onPaymentSuccess = (response) {
      _onPaymentSuccess(
        response.paymentId ?? '',
        response.orderId ?? '',
        response.signature ?? '',
      );
    };

    _paymentService!.onPaymentFailure = (response) {
      _onPaymentError(response.message ?? 'Payment failed');
    };

    _paymentService!.onExternalWallet = (response) {
      CustomLogger.logMessage(msg: 'External wallet: ${response.walletName}', level: LogLevel.debug);
    };

    profileController.fetchUserProfile();
  }

  @override
  void onClose() {
    _paymentService?.dispose();
    super.onClose();
  }
}