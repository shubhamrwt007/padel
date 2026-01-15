import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());

  @override
  void initState() {
    super.initState();
    controller.fetchTransaction();
    controller.fetchWallet();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(),
            Expanded(child: _transactionList()),
          ],
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _header() {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: BoxDecoration(
        gradient: walletGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// AppBar Row
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(onPressed: (){Get.back();},icon: const Icon(Icons.arrow_back, color: Colors.white)),
              const Text(
                'Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          Text(
            'Current Balance',
            style: Get.textTheme.bodyLarge!.copyWith(color: Colors.white,fontSize: 13),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children:  [
              Obx(() => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: controller.walletBalance.value.toString(),
                      style: Get.textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: " Credits",
                      style: Get.textTheme.titleLarge!.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 18
                      ),
                    ),
                  ],
                ),
              )),

              SizedBox(width: 10),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Today 15 Jun',
                  style: Get.textTheme.bodyLarge!.copyWith(color: Colors.white,fontSize: 13),
                ),
              )
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Text(
                'Total Spending:',
                style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white),
              ),
              Text(
                ' ₹ 0',
                style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white,fontSize: 13,fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 24),

          /// Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.add, 'Add'),
              // const SizedBox(width: 16),
              // _actionButton(Icons.arrow_downward, 'Withdraw'),
            ],
          ),
        ],
      ),
    );
  }
  LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3CDB),
      Color(0xFF1A2FB7),
      Color(0xFF12207A),
    ],
  );
  Widget _actionButton(IconData icon, String text) {
    return GestureDetector(
      onTap: () {
        if (text == 'Add') {
          controller.showAddBalanceDialog();
        }else if (text=="Withdraw"){
          SnackBarUtils.showInfoSnackBar("Withdraw option coming soon!");
        }
      },
      child: Container(
        height: 40,
        width: Get.width*0.3,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            Text(
              text,
              style: Get.textTheme.headlineMedium!.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TRANSACTIONS =================
  Widget _transactionList() {
    return Container(
      // margin: const EdgeInsets.only(top: -20),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          /// Title
          Row(
            children: [
              Text(
                'Transaction',
                style:Get.textTheme.headlineMedium
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                ),
              )
            ],
          ),
          const SizedBox(height: 15),

          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.4),
                        spreadRadius: 1.5,
                        blurRadius: 5.0
                    )
                  ]
              ),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }
                if (controller.transactionList.isEmpty) {
                  return Center(child: Text('No transactions found'));
                }
                return ListView.separated(
                  itemCount: controller.transactionList.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final transaction = controller.transactionList[index];
                    final isCredit = transaction.type == 'credit';
                    return _transactionTile(
                      title: transaction.description ?? 'Transaction',
                      amount: '₹${transaction.amount ?? 0}',
                      isCredit: isCredit,
                      date: transaction.createdAt ?? '',
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile({
    required String title,
    required String amount,
    required bool isCredit,
    required String date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade100,
            child: Icon(
              isCredit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isCredit ? Colors.green : Colors.black,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.headlineSmall,
                ), Text(
                  _formatDate(date),
                  style: Get.textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              color: isCredit ? Colors.green : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')} | ${date.day} ${_getMonth(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
