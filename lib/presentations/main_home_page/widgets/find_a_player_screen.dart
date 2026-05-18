import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';

class FindPlayerScreen extends StatefulWidget {
  const FindPlayerScreen({super.key});

  @override
  State<FindPlayerScreen> createState() => _FindPlayerScreenState();
}

class _FindPlayerScreenState extends State<FindPlayerScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10,horizontal:16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Find a Player",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),

                _optionCard(
                  index: 0,
                  title: "Already booked a court?",
                  subtitle: "Find players to join your match.",
                  borderColor: const Color(0xFF2F5BFF),
                  iconBg: const Color(0xFF2F5BFF),
                  icon: Icons.check_rounded,
                ),

                const SizedBox(height: 18),

                _optionCard(
                  index: 1,
                  title: "Need a court first?",
                  subtitle: "Book a court and set up your match.",
                  borderColor: const Color(0xFF3BB54A),
                  iconBg: const Color(0xFF3BB54A),
                  svgPath: Assets.imagesIcBookACourtNew
                ),

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        child:  Text("Cancel",style: Get.textTheme.labelLarge!
                            .copyWith(color: Colors.white),),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F5BFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (selectedIndex == 0) {
                            Get.back();
                            Get.to(()=>BookingHistoryUi(buttonType: "drawer",));
                          } else if (selectedIndex == 1) {
                            Get.back();
                            Get.toNamed(RoutesName.bookACourt);

                          }
                        },
                        child: Text("Next",style: Get.textTheme.labelLarge!
                            .copyWith(color: Colors.white),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required int index,
    required String title,
    required String subtitle,
    required Color borderColor,
    required Color iconBg,
    IconData? icon,
    String? svgPath,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? borderColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon != null
                  ? Icon(icon, color: Colors.white)
                  : SizedBox(
                width: 18,
                height: 18,
                child: Transform.scale(
                  scale: 0.7,
                  child: SvgPicture.asset(
                    svgPath!,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),


            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? borderColor : Colors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
