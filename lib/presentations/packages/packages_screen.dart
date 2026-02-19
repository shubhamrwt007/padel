import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/primary_button.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/packages/packages_controller.dart';
class PackagesUi extends GetView<PackagesController> {
  const PackagesUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
          centerTitle: true,
          title: Text("Packages"), context: context),
      body: Obx(
            () => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: controller.packages.length,
          itemBuilder: (context, index) {
            final p = controller.packages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade400,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Slots: ${p.slots}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,

                              ),
                            ),
                            Text(
                              "Validity: ${p.validity}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹ ${formatAmount(p.price)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                    PrimaryButton(
                        width: Get.width*0.25,
                        height: 30,
                        textStyle: Get.textTheme.labelLarge!.copyWith(color: Colors.white),
                        onTap: (){
                        }, text: "Buy Now")
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}