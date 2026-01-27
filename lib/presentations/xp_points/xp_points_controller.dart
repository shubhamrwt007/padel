import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rolling_number_text/rolling_number_text.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/xp_points_model/get_xp_points_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/repositories/xp_points_repository/xp_points_repository.dart';

class XpPointsController extends GetxController {
  final ProfileController profileController = Get.put(ProfileController());

  // Rolling number animation controller
  final AnimatedNumberTextController xpAnimationController = AnimatedNumberTextController();

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    fetchXpTransaction(isRefresh: true);
  }

  String get selectedDateRangeText {
    if (selectedStartDate.value != null && selectedEndDate.value != null) {
      final formatter = DateFormat('dd MMM');
      return '${formatter.format(selectedStartDate.value!)} - ${formatter.format(selectedEndDate.value!)}';
    }
    return 'Select Dates';
  }

  ///Date Range Picker----------------------------------------------------------------
  Future<void> openDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedStartDate.value != null &&
          selectedEndDate.value != null
          ? DateTimeRange(
        start: selectedStartDate.value!,
        end: selectedEndDate.value!,
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
      setDateRange(picked.start, picked.end);
    }
  }

  ///Get XP Points API----------------------------------------------------------
  var selectedStartDate = Rxn<DateTime>();
  var selectedEndDate = Rxn<DateTime>();
  var currentPage = 1;
  var hasMoreTransactions = true.obs;
  var isLoading = false.obs;
  var transactionList = <XpData>[].obs;
  final XpPointsRepository repository = Get.put(XpPointsRepository());

  Future<void> fetchXpTransaction({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        currentPage = 1;
        hasMoreTransactions.value = true;
      }
      isLoading.value = true;
      final userId = storage.read('userId');
      final response = await repository.getXpPoints(
        userId: userId,
        page: currentPage,
        limit: 10,
        fromDate: selectedStartDate.value != null ? DateFormat('yyyy-MM-dd').format(selectedStartDate.value!) : '',
        toDate: selectedEndDate.value != null ? DateFormat('yyyy-MM-dd').format(selectedEndDate.value!) : '',
      );
      if (response.success == true) {
        if (isRefresh) {
          transactionList.value = response.data ?? [];
        } else {
          transactionList.addAll(response.data ?? []);
        }
        hasMoreTransactions.value = (response.data?.length ?? 0) >= 10;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR->$e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() async {
    await fetchXpTransaction();

    // Initialize animation controller with XP points value (convert to int)
    final xpValue = (profileController.profileModel.value?.response?.xpPoints ?? 0).toInt();
    xpAnimationController.initialize(xpValue, shouldAnimate: true);

    super.onInit();
  }

  @override
  void onClose() {
    xpAnimationController.dispose();
    super.onClose();
  }
}