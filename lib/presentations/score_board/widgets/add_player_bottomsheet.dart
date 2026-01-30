// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:padel_mobile/configs/app_colors.dart';
// import 'package:padel_mobile/configs/components/primary_text_feild.dart';
// import 'package:padel_mobile/configs/routes/routes_name.dart';
//
// class AddGuestPlayersController extends GetxController {
//   RxInt pageIndex = 0.obs;
//
//   void goTo(int index) => pageIndex.value = index;
//   void back() => pageIndex.value = pageIndex.value > 0 ? pageIndex.value - 1 : 0;
// }
//
// class AddPlayerBottomSheet extends StatelessWidget {
//   final String teamName;
//   final String scoreBoardId;
//   final AddGuestPlayersController controller = Get.put(AddGuestPlayersController());
//
//   AddPlayerBottomSheet({super.key,required this.teamName,required this.scoreBoardId});
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//         canPop: true,
//       onPopInvokedWithResult: (didPop, result) {
//         if (!didPop) {
//           controller.pageIndex.value = 0;
//         }
//       },
//       child: Obx(() {
//         switch (controller.pageIndex.value) {
//           case 1:
//             return _searchPlayer(controller);
//           default:
//             return _addPlayerMain(controller,teamName,scoreBoardId);
//         }
//       }),
//     );
//   }
// }
//
// Widget _buildHeader(String title, AddGuestPlayersController controller, {bool showBack = false}) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       if (showBack)
//         IconButton(
//           icon: const Icon(Icons.arrow_back, size: 20),
//           onPressed: controller.back,
//         )
//       else
//         const SizedBox(width: 40),
//       Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
//       IconButton(icon: const Icon(Icons.close), onPressed: Get.back),
//     ],
//   );
// }
//
// /// --- 1️⃣ Main Add Player Screen ---
// Widget _addPlayerMain(AddGuestPlayersController controller,String teamName,String scoreBoardId) {
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: const BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildHeader("Add Player", controller),
//         const SizedBox(height: 10),
//         _addOption(Icons.search, "Search Registered Player", "Find someone already on the app", () => controller.goTo(1)),
//         _addOption(Icons.person_add_alt_1, "Invite Player", "Send Whatsapp or SMS Invite", () {}),
//         _addOption(Icons.person_outline, "Add Guest", "Add name only, no account required", () {
//           Get.toNamed(
//           RoutesName.addPlayer,
//           arguments: {
//             "matchId": "123",
//             "team": teamName,
//             "needAsGuest": true,
//             "scoreBoardId":scoreBoardId
//           },
//         );
//         }),
//       ],
//     ),
//   );
// }
//
// Widget _addOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
//   return InkWell(
//     onTap: onTap,
//     child: Container(
//       margin: const EdgeInsets.only(top: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 26, color: Colors.black87),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//                 Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
//               ],
//             ),
//           ),
//           const Icon(Icons.arrow_forward, size: 24, color: AppColors.primaryColor),
//         ],
//       ),
//     ),
//   );
// }
//
// /// --- 2️⃣ Search Player Screen ---
// Widget _searchPlayer(AddGuestPlayersController controller) {
//   final players = [
//     {"name": "Dianne Smith", "location": "London", "image": "https://i.pravatar.cc/150?img=1"},
//     {"name": "Jane Cooper", "location": "New York", "image": "https://i.pravatar.cc/150?img=2"},
//     {"name": "Lily Johnson", "location": "London", "image": "https://i.pravatar.cc/150?img=3"},
//     {"name": "Sophia Brown", "location": "New York", "image": "https://i.pravatar.cc/150?img=4"},
//     {"name": "Dianne Smith", "location": "London", "image": "https://i.pravatar.cc/150?img=1"},
//     {"name": "Jane Cooper", "location": "New York", "image": "https://i.pravatar.cc/150?img=2"},
//     {"name": "Lily Johnson", "location": "London", "image": "https://i.pravatar.cc/150?img=3"},
//     {"name": "Sophia Brown", "location": "New York", "image": "https://i.pravatar.cc/150?img=4"},
//   ];
//
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: const BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _buildHeader("Search Player", controller, showBack: true),
//         const SizedBox(height: 8),
//         _searchBar(),
//         const SizedBox(height: 12),
//         ...players.map((p) => _playerTile(p['image']!, p['name']!, p['location']!, "Send Request", () {})),
//       ],
//     ),
//   );
// }
//
// /// --- Common Widgets ---
// Widget _searchBar() {
//   return PrimaryTextField(
//     hintText: "Search by player name",
//     keyboardType: TextInputType.text,
//     action: TextInputAction.done,
//     contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
//     suffixIcon: const Icon(Icons.search, color: AppColors.textColor),
//   );
// }
//
// Widget _playerTile(String image, String name, String subtitle, String buttonText, void Function()? onTap) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 10),
//     child: Row(
//       children: [
//         CircleAvatar(backgroundImage: NetworkImage(image), radius: 22),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(name, style: Get.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w700)),
//               Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
//             ],
//           ),
//         ),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: AppColors.primaryColor.withValues(alpha: 0.2),
//             ),
//             child: Text(
//               buttonText,
//               style: Get.textTheme.labelSmall!.copyWith(color: AppColors.primaryColor),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }