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
  var isAddingBalance = false.obs;
  var transactionList = <Transaction>[].obs;
  var walletBalance = 0.obs;
  var pendingAmount = 0.obs;
  
  Future<void> fetchTransaction() async {
    try {
      isLoading.value = true;
      final response = await repository.getTransaction();
      if (response.status == 200) {
        transactionList.value = response.transactions ?? [];
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR->$e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWallet() async {
    try {
      final response = await repository.getWallet();
      walletBalance.value = response.balance ?? 0;
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR->$e", level: LogLevel.error);
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
        SnackBarUtils.showErrorSnackBar("Failed to create wallet order");
        isAddingBalance.value = false;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR -> $e", level: LogLevel.error);
      SnackBarUtils.showErrorSnackBar("Something went wrong");
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
      SnackBarUtils.showErrorSnackBar("Failed to initiate payment");
      isAddingBalance.value = false;
    }
  }

  Future<void> _onPaymentSuccess(String paymentId, String orderId, String signature) async {
    try {
      SnackBarUtils.showSuccessSnackBar("Balance added successfully");
      await fetchWallet();
      await fetchTransaction();
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR -> $e", level: LogLevel.error);
    } finally {
      isAddingBalance.value = false;
    }
  }

  void _onPaymentError(String error) {
    SnackBarUtils.showErrorSnackBar("Payment failed: $error");
    isAddingBalance.value = false;
  }


  void showAddBalanceDialog() {
    final TextEditingController amountController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('Add Balance'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isAddingBalance.value ? null : () {
              final amount = int.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                createBalance(amount);
              }
            },
            child: isAddingBalance.value 
                ? SizedBox(width: 20, height: 20, child: LoadingWidget(color: AppColors.primaryColor,))
                : Text('Add'),
          )),
        ],
      ),
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