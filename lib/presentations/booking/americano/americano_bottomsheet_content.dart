import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';

import 'package:get/get.dart';

import '../../../configs/app_colors.dart';
import '../../../configs/components/primary_button.dart';
import 'container_clipper.dart';

class AmericanoBottomSheetContents extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController draggableController;

  const AmericanoBottomSheetContents({super.key, required this.scrollController, required this.draggableController});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final isExpanded = draggableController.size >= 0.9;
        draggableController.animateTo(
          isExpanded ? 0.4 : 0.9,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: CustomPaint(
        painter: CurvedTopPainter(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Get.width*0.02),
          decoration: const BoxDecoration(
            color: Colors.transparent, // Make transparent since painter handles the background
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 70, top: 0), // Increased top padding for the curve
                child: ListView(
                  physics: NeverScrollableScrollPhysics(),
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                   Icon(Icons.circle,size: 10,color: AppColors.greyColor,),
                    ClipPath(
                      clipper: ContainerClipper(notchOffsetFromCenter: 50),
                      child: Container(
                        decoration: BoxDecoration(
                            color: AppColors.cartColor,

                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.blackColor.withAlpha(10))
                        ),
                        child: Column(
                          children: [
                            infoTile("Americano Name", "Americano 1"),
                            infoTile("Date", "Fri 29/06/2025"),
                            infoTile("Time / Min", "8:00am"),
                            infoTile("Match Format", "Team"),
                            infoTile("Last Date", "Wed 27/06/2025"),
                            Dash(
                              direction: Axis.horizontal,
                              length: 300,
                              dashLength: 12,
                              dashColor: AppColors.primaryColor,
                            ).paddingOnly(top: 10),

                            infoTile("Price", "₹1200", highlight: true),
                          ],
                        ),
                      ).paddingOnly(bottom: Get.height*0.01),
                    ),
                    ClipPath(
                      clipper: ContainerClipper(notchOffsetFromCenter: 0),
                      child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                              color: AppColors.cartColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.blackColor.withAlpha(10))
                          ),
                          child: infoTile("Total Members", "10/ 2 left", redHighlight: true)),
                    ),
                    const SizedBox(height: 30),
                    Text("Rules", style: Get.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text("1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor",style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500)),
                    Text("2. incididunt ut labore et dolore magna aliqua. Ut enim ad minim",style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500)),
                    Text("3. veniam, quis",style: Get.textTheme.bodyLarge,),
                    Text("4. nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),),
                    SizedBox(height: 16),
                    Text("FAQs", style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500)),
                    faqTile("Lorem ipsum dolor sit amet, consectetur adipiscing?"),
                    faqTile("Lorem ipsum dolor sit amet, consectetur adipiscing?"),
                    faqTile("Lorem ipsum dolor sit amet, consectetur adipiscing?"),
                  ],
                ),
              ),
              // Fixed bottom button
              Positioned(
                left: 16,
                right: 16,
                bottom: 30,
                child: PrimaryButton(
                  onTap: () {
                    // Get.toNamed(RoutesName.registrationAmericano);
                    Get.back();
                  },
                  text: "Register Now",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget faqTile(String question) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question, style: Get.textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text("Answer to the question goes here."),
        ),
      ],
    );
  }

  Widget infoTile(String title, String value, {bool highlight = false, bool redHighlight = false}) {
    final isHighlight = highlight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Get.textTheme.bodyLarge!.copyWith(
              color: AppColors.textColor,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 16 : null,
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodyMedium!.copyWith(
              color: redHighlight
                  ? Colors.red
                  : highlight
                  ? AppColors.primaryColor
                  : Colors.black,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              fontSize: highlight ? 18 : redHighlight? 13:14,
            ),
          )
        ],
      ),
    );
  }
}

class CurvedTopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(0, size.height);

    // Line to bottom right
    path.lineTo(size.width, size.height);

    // Line up to top right, but before the curve
    path.lineTo(size.width, 30);

    // Curve at the top right
    path.quadraticBezierTo(size.width, 0, size.width - 20, 0);

    // Line to center right (before the center curve) - decreased width
    path.lineTo(size.width * 0.55, 0);

    // Center curve (upward notch) - more curve with deeper control point
    path.quadraticBezierTo(
      size.width * 0.5, -22, // Control point (center, deeper up)
      size.width * 0.45, 0,  // End point - decreased width
    );

    // Line to top left corner curve
    path.lineTo(30, 0);

    // Curve at the top left
    path.quadraticBezierTo(0, 0, 0, 30);

    // Close the path
    path.close();

    canvas.drawPath(path, paint);

    // Optional: Add shadow effect
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 3, false);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}