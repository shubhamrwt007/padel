// import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';
//
// class ProfileUi extends GetView<ProfileController> {
//   const ProfileUi({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: primaryAppBar(
//         centerTitle: true,
//         showLeading: false,
//         title: Text(
//           AppStrings.profile,
//           style: Get.textTheme.titleMedium!.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ).paddingOnly(left: Get.width * 0.02),
//         context: context,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           /// Profile Header
//           Row(
//             children: [
//               Obx(
//                     () => Container(
//                   height: Get.height * 0.1,
//                   width: Get.height * 0.1,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: AppColors.tabSelectedColor,
//                   ),
//                   child: ClipOval(
//                     child: (controller.profileModel.value?.response?.profilePic?.isNotEmpty ?? false)
//                         ? CachedNetworkImage(
//                       imageUrl: controller.profileModel.value?.response?.profilePic ?? "",
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => Center(
//                         child: LoadingWidget(color: AppColors.primaryColor,)
//                       ),
//                       errorWidget: (context, url, error) => Icon(
//                         Icons.person,
//                         size: 40,
//                         color: AppColors.labelBlackColor,
//                       ),
//                     )
//                         : Icon(
//                       Icons.person,
//                       size: 40,
//                       color: AppColors.labelBlackColor,
//                     ),
//                   ),
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Obx(() {
//                     final profile = controller.profileModel.value?.response;
//                     return Text(
//                       "${profile?.name ?? 'Unknown'} ${profile?.lastName ?? ""}",
//                       style: Get.textTheme.titleSmall!.copyWith(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 16,
//                         color: AppColors.labelBlackColor,
//                       ),
//                     ).paddingOnly(left: 5);
//                   }),
//                   Obx(() {
//                     final profile = controller.profileModel.value?.response;
//                     return Text(
//                       profile?.email ?? 'unknown@gmail.com',
//                       style: Get.textTheme.headlineSmall!.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.labelBlackColor,
//                       ),
//                     ).paddingOnly(left: 5);
//                   }),
//                   GestureDetector(
//                     onTap: () {
//                       Get.toNamed(RoutesName.editProfile);
//                     },
//                     child: Container(
//                       alignment: Alignment.center,
//                       height: Get.height * .03,
//                       width: Get.width * .22,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         gradient: const LinearGradient(
//                           begin: Alignment.centerLeft,
//                           end: Alignment.centerRight,
//                           colors: [
//                             Color(0xFF3DBE64),
//                             Color(0xFF1F41BB),
//                           ],
//                           stops: [0.1, 0.4],
//                         ),
//                       ),
//                       child: Text(
//                         AppStrings.editProfile,
//                         style: Get.textTheme.bodyLarge!.copyWith(
//                           color: AppColors.whiteColor,
//                           fontSize: 8,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ).paddingOnly(top: 10, left: 5),
//                   ),
//                 ],
//               ).paddingOnly(left: 10),
//             ],
//           ),
//
//           /// Profile Options
//           Obx(
//             ()=> ProfileRow(
//               icon: Icon(Icons.calendar_month_outlined, size: 20,color: controller.selectedIndex.value == 0 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//               title: AppStrings.booking,
//               isSelected:  controller.selectedIndex.value == 0,
//               onTap: (){
//                 controller.selectedIndex.value = 0;
//                 Get.toNamed(RoutesName.bookingHistory);
//               },
//             ).paddingOnly(top: Get.height * .05),
//           ),
//
//
//           // Obx(
//           //   ()=> ProfileRow(
//           //     icon: SvgPicture.asset(Assets.imagesPadelIcon, height: 17, width: 17,color: controller.selectedIndex.value == 1 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//           //     title: "Open Match",
//           //     isSelected:  controller.selectedIndex.value == 1,
//           //     onTap: () {
//           //       controller.selectedIndex.value = 1;
//           //     },
//           //   ),
//           // ),
//           //
//           // Obx(
//           //   ()=> ProfileRow(
//           //     icon: SvgPicture.asset(Assets.imagesIcAmericano, height: 19, width: 19,color: controller.selectedIndex.value == 2 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//           //     title: "Americano",
//           //     isSelected:  controller.selectedIndex.value == 2,
//           //     onTap: () {
//           //       controller.selectedIndex.value = 2;
//           //     },
//           //   ),
//           // ),
//
//           Obx(
//             ()=> ProfileRow(
//               icon: Image.asset(Assets.images.icBalanceWallet.path, scale: 5,color: controller.selectedIndex.value == 3 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//               title: AppStrings.payments,
//               isSelected:  controller.selectedIndex.value == 3,
//               onTap: (){
//                 controller.selectedIndex.value = 3;
//                 Get.toNamed(RoutesName.paymentWallet);
//               },
//             ),
//           ),Obx(
//             ()=> ProfileRow(
//               icon: Image.asset(Assets.images.icPadelIcon.path, scale: 5,color: controller.selectedIndex.value == 4 ? AppColors.primaryColor:AppColors.blackColor,),
//               title: AppStrings.openMatch,
//               isSelected:  controller.selectedIndex.value == 4,
//               onTap: (){
//                 controller.selectedIndex.value = 4;
//                 Get.toNamed(RoutesName.matchBooking,arguments: {
//                   "type": "profile"
//                 });
//               },
//             ),
//           ),
//
//           Obx(
//             ()=> ProfileRow(
//               icon: Icon(Icons.shopping_cart_outlined, size: 20, color: controller.selectedIndex.value == 5 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//               title: AppStrings.cart,
//               isSelected:  controller.selectedIndex.value == 5,
//               onTap: () {
//                 controller.selectedIndex.value = 5;
//                 Get.to(() => CartScreen(buttonType: "true"), transition: Transition.rightToLeft);
//               },
//             ),
//           ),
//
//           Obx(
//             ()=> ProfileRow(
//               icon: SvgPicture.asset(Assets.imagesIcPackages, height: 17, width: 17,color: controller.selectedIndex.value == 6 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//               title: "Packages",
//               isSelected:  controller.selectedIndex.value == 6,
//               onTap: () {
//                 controller.selectedIndex.value = 6;
//                 Get.toNamed(RoutesName.packages);
//               },
//             ),
//           ),
//
//           Obx(
//             ()=> ProfileRow(
//               icon: Icon(Icons.headset_mic_outlined, size: 20,color: controller.selectedIndex.value == 7 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//               title: AppStrings.helpSupport,
//               isSelected:  controller.selectedIndex.value == 7,
//               onTap: (){
//                 controller.selectedIndex.value = 7;
//                 Get.toNamed(RoutesName.support);
//               },
//             ),
//           ),
//
//           Obx(
//             ()=> ProfileRow(
//               icon: Image.asset(Assets.images.icPrivacy.path, scale: 5,color: controller.selectedIndex.value == 8 ? AppColors.primaryColor:AppColors.labelBlackColor,),
//               title: AppStrings.privacy,
//               isSelected:  controller.selectedIndex.value == 8,
//               onTap: () {
//                 controller.selectedIndex.value = 8;
//               },
//             ),
//           ),
//
//           ProfileRow(
//             icon: SvgPicture.asset(Assets.images.icLogOut.path, height: 15, width: 17).paddingOnly(left: 3),
//             title: AppStrings.logout,
//             textColor: Colors.red,
//             onTap: () => controller.showLogoutDialog(context),
//           ),
//         ],
//       ).paddingOnly(left: Get.width * .05, right: Get.width * .05),
//     );
//   }
// }
//
// /// Reusable row widget
// class ProfileRow extends StatelessWidget {
//   final Widget icon;
//   final String title;
//   final VoidCallback? onTap;
//   final Color? textColor;
//   final bool isSelected;
//
//   const ProfileRow({
//     super.key,
//     required this.icon,
//     required this.title,
//     this.onTap,
//     this.textColor,
//     this.isSelected = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final defaultColor = AppColors.labelBlackColor;
//     final highlightColor = AppColors.primaryColor;
//
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 50,
//         color: Colors.transparent,
//         child: Row(
//           children: [
//             icon,
//             const SizedBox(width: 40),
//             Text(
//               title,
//               style: Get.textTheme.headlineSmall!.copyWith(
//                 color: isSelected ? highlightColor : (textColor ?? defaultColor),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
import 'package:flutter/material.dart';
class ProfileUi extends StatelessWidget {
  const ProfileUi({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

