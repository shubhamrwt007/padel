import 'package:padel_mobile/configs/components/safe_bottom_container.dart';
import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/text_formatter.dart';

import '../../../configs/components/custom_button.dart';

class AmericanoBottomSheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController draggableController;
  final AmericanoMatch match;

  const AmericanoBottomSheetContent({
    super.key,
    required this.scrollController,
    required this.draggableController,
    required this.match,
  });

  String _formatIsoDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final datePart = isoString.contains('T') ? isoString.split('T').first : isoString;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return "$day/$month/$year";
      }
      return datePart;
    } catch (_) {
      return isoString;
    }
  }

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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.02),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      height: 3,
                      width: 50,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ClipPath(
                    clipper: ContainerClipper(notchOffsetFromCenter: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.blackColor.withAlpha(10)),
                      ),
                      child: Column(
                        children: [
                          infoTile("Americano Name", match.matchTitle ?? match.clubId?.clubName ?? "Americano"),
                          infoTile(
                            "Date",
                            "${match.matchDay != null && match.matchDay!.isNotEmpty ? "${match.matchDay} " : ""}${_formatIsoDate(match.matchDate)}"
                                .trim(),
                          ),
                          infoTile("Time / Min", match.matchTime ?? "N/A"),
                          infoTile("Match Format", match.americanoFormat?.capitalizeFirstChar() ?? "Individual"),
                          infoTile("Last Date", _formatIsoDate(match.registrationLastDate)),
                          Dash(
                            direction: Axis.horizontal,
                            length: 300,
                            dashLength: 12,
                            dashColor: AppColors.primaryColor,
                          ).paddingOnly(top: 10),
                          infoTile("Price", "₹${match.registrationFee ?? match.totalPrice ?? 0}", highlight: true),
                        ],
                      ),
                    ).paddingOnly(bottom: Get.height * 0.01),
                  ),
                  ClipPath(
                    clipper: ContainerClipper(notchOffsetFromCenter: 0),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.blackColor.withAlpha(10)),
                      ),
                      child: () {
                        final maxP = match.maxPlayers ?? 12;
                        final joined = match.joinedMembers ?? 0;
                        final left = maxP - joined;
                        final leftText = left > 0 ? "$left left" : "Full";
                        return infoTile("Total Members", "$joined/ $leftText", redHighlight: left <= 2);
                      }(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text("Rules", style: Get.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    "1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor",
                    style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "2. incididunt ut labore et dolore magna aliqua. Ut enim ad minim",
                    style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "3. veniam, quis",
                    style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "4. nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                    style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Text("FAQs", style: Get.textTheme.headlineMedium),
                  faqTile("Lorem ipsum dolor sit amet, consectetur adipiscing?"),
                  faqTile("Lorem ipsum dolor sit amet, consectetur adipiscing?"),
                  faqTile("Lorem ipsum dolor sit amet, consectetur adipiscing?"),
                ],
              ),
            ),
            // Fixed bottom button
            Positioned(
              left: 10,
              right: 10,
              bottom: 20,
              child: SafeBottomContainer(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CustomButton(
                  width: Get.width * 0.9,
                  onTap: () {},
                  child: Text(
                    "Register Now",
                    style: Get.textTheme.headlineMedium!.copyWith(
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget faqTile(String question) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question,style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text("Answer to the question goes here.",style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),),
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
            style: Get.textTheme.labelMedium!.copyWith(
              color: AppColors.textColor,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 16 : null,
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodySmall!.copyWith(
              color: redHighlight
                  ? Colors.red
                  : highlight
                  ? AppColors.primaryColor
                  : Colors.black,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              fontSize: highlight ? 18 : redHighlight? 13:null,
            ),
          )
        ],
      ),
    );
  }
}
