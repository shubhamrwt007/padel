import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rolling_number_text/rolling_number_text.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/fade_divider.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/presentations/xp_points/xp_points_controller.dart';

class XpPointsScreen extends StatelessWidget {
  final XpPointsController controller = Get.put(XpPointsController());
  XpPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _header(),
            Expanded(child: _xpPointsList(context))
          ],
        ),
      ),
    );
  }

  Widget _xpPointsList(BuildContext context){
    return Transform.translate(
      offset: Offset(0, -20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.4),
                  spreadRadius: 1.5,
                  blurRadius: 5.0
              )
            ]
        ),
        child: Column(
          children: [
            // Sheet Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 10),
              child: Row(
                children: [
                  Text(
                      "XP Points Sheet",
                      style:Get.textTheme.headlineMedium
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (controller.selectedStartDate.value != null || controller.selectedEndDate.value != null) {
                        controller.setDateRange(null, null);
                      } else {
                        controller.openDateRangePicker(context);
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
            ),
            // List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Obx(() => controller.isLoading.value
                      ? Center(child: LoadingWidget(color:AppColors.primaryColor,))
                      : RefreshIndicator(
                    color: AppColors.whiteColor,
                    onRefresh: () async {
                      await Future.wait([
                        controller.fetchXpTransaction(isRefresh: true),
                        controller.profileController.fetchUserProfile(),
                      ]);
                    },
                    child: controller.transactionList.isEmpty
                        ? ListView(children: [Center(child: Text("No data available"))])
                        : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: controller.transactionList.length,
                      separatorBuilder: (_, __) => fadeDivider(),
                      itemBuilder: (context, index) {
                        final transaction = controller.transactionList[index];
                        return _XpRow(transaction: transaction);
                      },
                    ),
                  )
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3CDB),
            Color(0xFF1A2FB7),
            Color(0xFF12207A),
          ],
        ),
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
                'XP Points',
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
          Center(
            child: AnimatedNumberText(
              controller: controller.xpAnimationController,
              digitTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              animationDuration: Duration(milliseconds: 5000),
              animationCurve: Curves.easeOut,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  final dynamic transaction;

  const _XpRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isWin = transaction.result == "W";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Circle W / L
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xffF5F5F5),
            child: Text(
              isWin ? "W" : "L",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isWin ? Colors.green : Colors.red,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Date & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                Text(
                    transaction.createdAt != null
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(transaction.createdAt!))
                        : "N/A",
                    style: Get.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w400)
                ),
                SizedBox(height: 4),
                Text(
                    "${transaction.scoreboardId?.startTime ?? ''} - ${transaction.scoreboardId?.endTime ?? ''}",
                    style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)
                ),
              ],
            ),
          ),

          // XP Value
          Text(
              "${(transaction.xpChange ?? 0) > 0 ? '+' : ''}${(transaction.xpChange ?? 0).toStringAsFixed(2)} XP",
              style:Get.textTheme.titleSmall!.copyWith(color: (transaction.xpChange ?? 0) > 0 ? Colors.green : Colors.red,)
          ),
        ],
      ),
    );
  }
}