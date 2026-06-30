import 'package:padel_mobile/configs/components/safe_bottom_container.dart';
import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/payment/payment_method_controller.dart';

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
    print('Match Description: ${match.matchDescription}');
    print('Match Description isEmpty: ${match.matchDescription?.isEmpty}');
    print('Match Description isNotEmpty: ${match.matchDescription?.isNotEmpty}');

    return Container(
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
              physics: const ClampingScrollPhysics(),
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
                          infoTile("Game Type", match.gender?.capitalizeFirstChar() ?? "N/A"),
                          infoTile("Match Format", match.americanoFormat?.capitalizeFirstChar() ?? "Individual"),
                          infoTile("Last Date", _formatIsoDate(match.registrationLastDate)),
                          Dash(
                            direction: Axis.horizontal,
                            length: 300,
                            dashLength: 12,
                            dashColor: AppColors.primaryColor,
                          ).paddingOnly(top: 10),
                          infoTile("Price", "₹${match.registrationFee ?? match.totalPrice ?? 0}", highlight: true),
                          if (match.prize != null && (match.prize!['first'] != null || match.prize!['second'] != null || match.prize!['third'] != null)) ...[
                            Dash(
                              direction: Axis.horizontal,
                              length: 300,
                              dashLength: 12,
                              dashColor: AppColors.primaryColor,
                            ).paddingOnly(top: 10, bottom: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                              child: Text(
                                "Winning Prizes",
                                style: Get.textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (match.prize!['first'] != null)
                              infoTile("1st Prize", "₹${match.prize!['first']}"),
                            if (match.prize!['second'] != null)
                              infoTile("2nd Prize", "₹${match.prize!['second']}"),
                            if (match.prize!['third'] != null)
                              infoTile("3rd Prize", "₹${match.prize!['third']}"),
                          ],
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
                        final joined = match.players?.isNotEmpty == true ? match.players!.length : (match.joinedMembers ?? 0);
                        final left = maxP - joined;
                        final leftText = left > 0 ? "$left left" : "Full";
                        return infoTile("Total Members", "$joined/ $leftText", redHighlight: left <= 2);
                      }(),
                    ),
                  ),

                  const SizedBox(height: 30),
                  if (match.matchDescription != null && match.matchDescription!.isNotEmpty) ...[
                    Text("Description", style: Get.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      match.matchDescription!,
                      style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),
                  ],
                  Text("Rules", style: Get.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (match.americanoFormat?.toLowerCase() == 'fixed_team') ...[
                    _ruleText("Rotate Partners Every Round", "Players are assigned a new partner for each match according to the tournament schedule."),
                    _ruleText("Individual Scoring System", "Points earned in every match are added to each player's personal total score."),
                    _ruleText("Play Fixed Points Per Match", "Each match is played to a predetermined number of points (e.g., 16, 21, or 24 points)."),
                    _ruleText("Highest Total Score Wins", "At the end of all rounds, the player with the highest accumulated points is declared the winner."),
                  ] else ...[
                    _ruleText("🎾 Doubles Team Rules", ""),
                    _ruleText("Fixed Team Partnership", "Players must play with the same partner throughout the tournament."),
                    _ruleText("Match Scoring", "Matches are played according to the tournament format (e.g., best of 3 sets or first to 6 games)."),
                    _ruleText("Respect and Sportsmanship", "All players must show respect to opponents, partners, officials, and organizers."),
                    _ruleText("Punctual Attendance", "Teams must be present on time. Late arrival may result in a walkover or point penalty."),
                  ],
                  const SizedBox(height: 16),
                  Text("FAQs", style: Get.textTheme.headlineMedium),
                  if (match.americanoFormat?.toLowerCase() == 'fixed_team') ...[
                    faqTile("What is Padel Americano?", "Padel Americano is a tournament format where players change partners every round and compete as individuals rather than fixed teams."),
                    faqTile("How is the winner determined?", "The winner is the player who accumulates the most points across all matches."),
                    faqTile("Do I play with the same partner throughout the tournament?", "No. Partners rotate every round so that everyone plays with different teammates."),
                    faqTile("Is Padel Americano suitable for beginners?", "Yes. It is a fun and social format designed for players of all skill levels."),
                  ] else ...[
                    faqTile("What is a Doubles Team Tournament?", "A competition where two players form a team and play together for the entire tournament."),
                    faqTile("Can I change my partner during the tournament?", "No. Once the tournament starts, partner changes are generally not allowed unless approved by the organizer."),
                    faqTile("How is the winning team decided?", "The team that wins the final match or accumulates the highest points (depending on the format) is declared the winner."),
                    faqTile("What happens if a player cannot continue playing?", "The team may be withdrawn from the tournament unless the organizer allows a substitute according to the event rules."),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 20,
              child: SafeBottomContainer(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CustomButton(
                  width: Get.width * 0.9,
                  onTap: () async {
                    // Show a loading dialog while initiating registration
                    Get.dialog(
                      PopScope(
                        canPop: false,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  "Initiating registration...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      barrierDismissible: false,
                    );

                    try {
                      final paymentController = Get.put(PaymentMethodController(), permanent: true);
                      await paymentController.createAmericanoRegistration(match.sId ?? '');
                    } catch (e) {
                      if (Get.isDialogOpen == true) {
                        Get.back();
                      }
                      Get.delete<PaymentMethodController>(force: true);
                    }
                  },
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

    );
  }

  Widget _ruleText(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500, color: Colors.black),
          children: [
            TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (description.isNotEmpty) TextSpan(text: "\n$description"),
          ],
        ),
      ),
    );
  }

  Widget faqTile(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question, style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(answer, style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)),
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
