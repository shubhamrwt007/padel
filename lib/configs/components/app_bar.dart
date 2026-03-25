import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../app_colors.dart';
AppBar primaryAppBar({
  Color? backGroundColor,
  List<Widget>? action,
  bool? centerTitle,
  Widget? leading,
  double? leadingWidth,
  required Widget title,
  required BuildContext context,
  PreferredSizeWidget? bottom,
  SystemUiOverlayStyle? systemOverlayStyle,
  Color? titleTextColor,
  Color? leadingButtonColor,
  bool? showLeading,
  BorderRadius? borderRadius,
  double? toolbarHeight,
  Widget? flexibleSpace

}) {
  final bool shouldShowLeading = showLeading ?? Navigator.canPop(context);
  return AppBar(
    systemOverlayStyle: systemOverlayStyle,
    bottom: bottom,
    toolbarHeight:toolbarHeight?? 50,
    leadingWidth: leadingWidth ?? Get.width * 0.15,
    centerTitle: centerTitle ?? false,
    automaticallyImplyLeading: false,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadius ??
          BorderRadius.zero,
    ),
    leading: shouldShowLeading
        ? leading ??
        GestureDetector(
          onTap: () {
            Get.back();
          },
          child: Container(
            color: Colors.transparent,
            height: 30,
            width: 40,
            child: Icon(
              Icons.arrow_back,
              color:leadingButtonColor?? AppColors.blackColor,
              size: 22,
            ),
          ),
        )
        : null, // hide leading if shouldShowLeading is false

    title: title,
    titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
      color:titleTextColor?? AppColors.blackColor,
      fontSize: 20,
    ),
    surfaceTintColor: Colors.transparent,
    backgroundColor: backGroundColor ?? Colors.transparent,
    elevation: 3,
    actionsPadding: EdgeInsets.only(right: Get.width * 0.01),
    actions: action,
    flexibleSpace: flexibleSpace,

  );
}
