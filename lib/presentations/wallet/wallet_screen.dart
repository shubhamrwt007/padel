import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController controller = Get.put(WalletController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.fetchTransaction();
    controller.fetchWallet();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: BoxDecoration(
        gradient: walletGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// AppBar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.translate(
                  offset: Offset(-10, 0),
                  child: IconButton(onPressed: (){Get.back();},icon: const Icon(Icons.arrow_back, color: Colors.white))),
              const Text(
                'Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 20,width: 50,
              )
            ],
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: Get.textTheme.bodyLarge!.copyWith(color: Colors.white,fontSize: 14),
              ),
              // Text(
              //   _getCurrentDate(),
              //   style: Get.textTheme.bodyLarge!.copyWith(color: Colors.white,fontSize: 13),
              // )
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:  [
              Obx(() => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: formatWalletAmount(controller.walletBalance.value.toString()),
                      style: Get.textTheme.titleLarge!.copyWith(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: " Credits",
                      style: Get.textTheme.titleLarge!.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 18
                      ),
                    ),
                  ],
                ),
              )),

            ],
          ),
          const SizedBox(height: 6),

          // Row(
          //   children: [
          //     Text(
          //       'Total Spending: ',
          //       style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white,fontSize: 14),
          //     ),
          //     Text(
          //       '${formatAmount(controller.totalDebitedBalance.value.toString())} Credits',
          //       style: Get.textTheme.headlineSmall!.copyWith(color: Colors.white,fontSize: 14,fontWeight: FontWeight.w800),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              Icon(Icons.info_outline,color: Colors.white,size: 13,),
              Text("1 Credit = 1 Rupee",style: Get.textTheme.bodySmall!.copyWith(color: Colors.white,fontWeight: FontWeight.w400),)
            ],
          ),
          const SizedBox(height: 24),

          /// Buttons
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     _actionButton(Icons.add, 'Add'),
          //     // const SizedBox(width: 16),
          //     // _actionButton(Icons.arrow_downward, 'Withdraw'),
          //   ],
          // ),
          const SizedBox(height: 24),
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
          // SnackBarUtils.showInfoSnackBar("Withdraw option coming soon!");
        }
      },
      child: Container(
        height: 40,
        width: Get.width*0.3,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
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
    return Transform.translate(
      offset: Offset(0, -25),
      child: Container(
        // margin: const EdgeInsets.only(top: -20),
        padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            /// Title
            SizedBox(
              height: 8,
            ),
            Row(
              children: [
                Text(
                  'Transaction',
                  style:Get.textTheme.headlineMedium
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (controller.selectedStartDate.value != null || controller.selectedEndDate.value != null) {
                      controller.setDateRange(null, null);
                    } else {
                      openDateRangePicker(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() => Text(
                          controller.selectedDateRangeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                        const SizedBox(width: 4),
                        Obx(() => Icon(
                          controller.selectedStartDate.value != null || controller.selectedEndDate.value != null
                              ? Icons.close
                              : Icons.calendar_month,
                          color: Colors.white,
                          size: 16,
                        )),
                      ],
                    ),
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
                    return Center(child: LoadingWidget(color: AppColors.primaryColor,));
                  }
                  if (controller.transactionList.isEmpty) {
                    return Center(child: Text('No transactions found'));
                  }
                  return ListView.separated(
                    physics: ClampingScrollPhysics(),
                    controller: _scrollController,
                    itemCount: controller.transactionList.length + (controller.hasMoreTransactions.value ? 1 : 0),
                    padding: EdgeInsets.zero,
                    separatorBuilder: (_, index) => index < controller.transactionList.length ? fadeDivider(): SizedBox.shrink(),
                    itemBuilder: (_, index) {
                      if (index >= controller.transactionList.length) {
                        return Obx(() => controller.isLoadingMore.value
                          ? Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: LoadingWidget(color: AppColors.primaryColor,)),
                            )
                          : SizedBox.shrink());
                      }
                      final transaction = controller.transactionList[index];
                      final isCredit = transaction.type == 'credit';
                      return _transactionTile(
                        title: transaction.description ?? 'Transaction',
                        amount: '${formatAmount(transaction.amount ?? 0)} Cr',
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
              isCredit ? Icons.arrow_downward:Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
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
            "${formatAmount(amount)} Cr",
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
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'November'];
    return months[month - 1];
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day} ${_getMonth(now.month)}';
  }

  ///Date Range Picker----------------------------------------------------------------
  Future<void> openDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedStartDate.value != null &&
          controller.selectedEndDate.value != null
          ? DateTimeRange(
        start: controller.selectedStartDate.value!,
        end: controller.selectedEndDate.value!,
      )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor, // Start & End date color
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppColors.secondaryColor.withValues(alpha: 0.2),
              rangeSelectionOverlayColor:
              MaterialStatePropertyAll(Colors.green.withOpacity(0.2)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

}
