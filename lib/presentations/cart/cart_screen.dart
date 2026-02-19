import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/cart/cart_controller.dart';
import 'package:padel_mobile/presentations/payment/payment_method_controller.dart';
import '../../configs/routes/routes_name.dart';

class CartScreen extends StatelessWidget {
  final String buttonType;
  final CartController controller = Get.put(CartController());

  CartScreen({super.key, required this.buttonType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: primaryAppBar(
        showLeading: buttonType == "true" ? true : false,
        centerTitle: true,
        title: const Text("Cart"),
        context: context,
      ),
      body: Column(
        children: [
          Expanded(child: cartList(controller)),
        ],
      ).paddingSymmetric(horizontal: Get.width * 0.05),

      /// Bottom section
      bottomNavigationBar: Obx(() {
        if (controller.cartItems.isEmpty) return const SizedBox.shrink();
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                totalSlot(context),
                const SizedBox(height: 8),
                button(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget cartList(CartController controller) {
    return SizedBox(
      height: buttonType == "true" ? Get.height * 0.65 : Get.height * 0.56,
      child: Obx(() {
        if (controller.cartItems.isEmpty) {
          return emptyState();
        }

        final validItems = controller.cartItems.where((item) {
          return item.slot != null &&
              item.slot!.isNotEmpty &&
              item.slot!.any((s) =>
              s.slotTimes != null && s.slotTimes!.isNotEmpty);
        }).toList();

        if (validItems.isEmpty) {
          return emptyState();
        }

        return ListView.builder(
          controller: controller.scrollController,
          itemCount: validItems.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, index) {
            final item = validItems[index];

            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club Name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.registerClubId?.clubName ?? "Unknown Club",
                          style: Get
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ).paddingOnly(top: 10),

                  // 🔹 Loop through ALL slots + slotTimes with Slidable
                  Column(
                    children: item.slot!.map((slotGroup) {
                      return SlidableAutoCloseBehavior(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: slotGroup.slotTimes!.length,
                          itemBuilder: (context, int childIndex) {
                            final slot = slotGroup.slotTimes![childIndex];
                        
                            return Slidable(
                              key: ValueKey(slot.slotId ?? childIndex),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                // adjust extentRatio to fit your action width (0.22 - 0.32 typical)
                                extentRatio: 0.28,
                                children: [
                                  CustomSlidableAction(
                                    onPressed: (context) async {
                                      final slotTimeId = slot.slotId;
                                      if (slotTimeId == null || slotTimeId.isEmpty) {
                                        AppToast.error("Invalid slot ID");
                                        return;
                                      }
                                      await controller.removeCartItemsFromCart(slotIds: [slotTimeId]);
                                    },
                                    backgroundColor: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                        
                                    // Make sure the action has a fixed internal height that matches the row
                                    child: Center(
                                      child: SizedBox(
                                        height: 56, // <- match this to your row minHeight (tweak if needed)
                                        width: double.infinity,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min, // don't expand beyond content
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.delete, color: Colors.red, size: 20),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Delete',
                                              style: Get.textTheme.bodySmall!.copyWith(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        
                              // --- Slidable child: ensure min height & proper padding so no overflow or left overflow ---
                              child: Builder(
                                builder: (context) {
                                  final animation = Slidable.of(context)?.animation;
                                  return AnimatedBuilder(
                                    animation: animation ?? const AlwaysStoppedAnimation(0),
                                    builder: (context, _) {
                                      final isSliding = (animation?.value ?? 0) > 0.01;
                        
                                      return Container(
                                        // IMPORTANT: give a minHeight so text/icon won't overflow by a couple pixels
                                        constraints: const BoxConstraints(minHeight: 56),
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center, // vertical centering
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Left content
                                            Expanded(
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    formatCreatedAt(slot.bookingDate ?? ""),
                                                    style: Get.textTheme.bodyLarge!.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${formatTimeSlot(slot.time ?? 'N/A')} ",
                                                    style: Get.textTheme.bodyLarge!.copyWith(
                                                      color: AppColors.labelBlackColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "(${slot.courtName ?? ""})",
                                                    style: Get.textTheme.bodyLarge!.copyWith(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                        
                                            // Right content (price + remove)
                                            GestureDetector(
                                              onTap: () async {
                                                final slotTimeId = slot.slotId;
                                                if (slotTimeId == null || slotTimeId.isEmpty) {
                                                  CustomLogger.logMessage(msg: "Invalid slot ID", level: LogLevel.error);

                                                  return;
                                                }
                                                await controller.removeCartItemsFromCart(slotIds: [slotTimeId]);
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "₹ ${formatAmount(slot.amount ?? '0')}",
                                                    style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
                                                  ).paddingOnly(right: 10),
                        
                                                  if (!isSliding)
                                                    Container(
                                                      alignment: Alignment.center,
                                                      height: 18,
                                                      width: 18,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.red),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 12,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ).paddingOnly(
                bottom: Get.height * 0.01,
                left: Get.width * 0.03,
                right: Get.width * 0.03,
              ),
            );
          },
        );
      }),
    ).paddingOnly(bottom: Get.height * 0.02);
  }

  Widget totalSlot(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Obx(() {
      return Container(
        width: Get.width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.payColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.blackColor.withAlpha(10)),
        ),
        child: Column(
          children: [
            // Total Slots Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Slots (${cartController.totalSlot.value})",
                  style: Get.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "${cartController.totalSlot.value} (${cartController.totalSlot.value}h)",
                  style: Get.textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ).paddingOnly(bottom: Get.height * 0.01),

            // Total Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Price",
                  style: Get.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "₹ ",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.blackColor,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      formatAmount(cartController.totalPrice.value),
                      style: Get
                          .textTheme
                          .headlineMedium!
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ).paddingOnly(bottom: Get.height * 0.02);
    });
  }

  Widget button(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    return Obx(() {
      return CustomButton(
        width: Get.width * 0.9,
        onTap: () async {
          final cartItems = cartController.cartItems;
          if (cartItems.isEmpty) {
            CustomLogger.logMessage(msg: "Please add items to cart.", level: LogLevel.error);

            return;
          }
          
          // Create PaymentMethodController and call createInitialBooking
          final paymentController = Get.put(PaymentMethodController());
          await paymentController.createInitialBooking();
        },
        child: Row(
          children: [
            Text(
              "₹ ",
              style: Get.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: "Roboto",
                color: AppColors.whiteColor,
              ),
            ).paddingOnly(left: 30),
            Text(
              formatAmount(cartController.totalPrice.value.toString()),
              style: Get.textTheme.titleMedium!.copyWith(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ).paddingOnly(right: Get.width * 0.1),
            Text(
              "Proceed to Payment",
              style: Get.textTheme.headlineMedium!.copyWith(
                color: AppColors.whiteColor,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 16),
          Text(
            "No items in cart",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ).copyWith(color: AppColors.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            "Add some items to get started",
            style: const TextStyle(fontSize: 14).copyWith(
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String formatCreatedAt(String dateStr) {
    if (dateStr.isEmpty) return "Invalid Date";

    try {
      final date = DateTime.parse(dateStr);
      final day = date.day;
      final suffix = getDaySuffix(day);
      final month = DateFormat("MMM").format(date);
      final year = date.year;
      return "$day$suffix $month $year";
    } catch (e) {
      return "Invalid Date";
    }
  }

  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }
}