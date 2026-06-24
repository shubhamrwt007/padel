import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'all_open_match_controller.dart';

class AllOpenMatchScreen extends StatelessWidget {
  AllOpenMatchScreen({super.key});

  final AllOpenMatchController controller = Get.put(AllOpenMatchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
        centerTitle: true,
        title: const Text("Open Matches"),
        context: context,
      ),
      body: RefreshIndicator(
        edgeOffset: 1,
        displacement: Get.width * .2,
        color: AppColors.whiteColor,
        onRefresh: () async {
          await controller.fetchOpenMatches(); // <- reload API
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "For your level",
                  style: Get.textTheme.headlineLarge,
                ),
                GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      filter(context),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  },
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: AppColors.playerCardBackgroundColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Image.asset(
                      Assets.images.icFilter.path,
                      scale: 3.5,
                    ),
                  ),
                ),
              ],
            ).paddingSymmetric(horizontal: 16),
            Obx(() {
              if (controller.isLoading.value) {
                return Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return buildMatchCardShimmer();
                    },
                  ),
                );
              }

              final matches = controller.matchesBySelection.value;

              if (matches == null || (matches.data?.isEmpty ?? true)) {
                return Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 50, color: AppColors.darkGrey),
                            Text(
                              'No matches available for this time',
                              style: Get.textTheme.labelLarge
                                  ?.copyWith(color: AppColors.darkGrey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ).paddingSymmetric(vertical: Get.height * 0.35),
                      ),
                    ],
                  ),
                );
              }

              return Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: matches.data!.length,
                    itemBuilder: (context, index) {
                      final m = matches.data![index];
                      return _buildMatchCardFromData(context, m);
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget filter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, size: 22),
                ),
                Text(
                  "Filters",
                  style: Get.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: controller.clearAll,
                  child: Text(
                    "Clear all",
                    style: Get.textTheme.headlineSmall!.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            // Date Picker
            Text(
              "Date",
              style: Get.textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingOnly(top: Get.height * 0.01),
            const SizedBox(height: 8),
            Obx(() {
              return GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    controller.selectedDate.value = pickedDate;
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryColor.withAlpha(10),
                    border: Border.all(
                      color: AppColors.blackColor.withAlpha(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy')
                            .format(controller.selectedDate.value),
                        style: Get.textTheme.bodyMedium,
                      ),
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 22,
                        color: AppColors.textColor,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Timing
            Text(
              "Timing",
              style: Get.textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingOnly(top: Get.height * 0.01),
            Obx(
                  () => Wrap(
                spacing: 12,
                children: ["Morning", "After noon", "Evening"].map((label) {
                  final isSelected = controller.selectedTiming.value == label;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        activeColor: AppColors.secondaryColor,
                        value: isSelected,
                        onChanged: (_) {
                          controller.selectedTiming.value = label;
                        },
                      ),
                      Text(
                        label,
                        style: Get.textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // 🌟 Beautiful Player Level Dropdown
            Text(
              "Player Level",
              style: Get.textTheme.headlineLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).paddingOnly(top: Get.height * 0.01),
            const SizedBox(height: 8),
            Obx(() {
              final levels = [
                'A – Top Player',
                'B1 – Experienced Player',
                'B2 – Advanced Player',
                'C1 – Confident Player',
                'C2 – Intermediate Player',
                'D1 – Amateur Player',
                'D2 – Novice Player',
                'E – Entry Level',
              ];

              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primaryColor.withAlpha(10),
                  border:
                  Border.all(color: AppColors.blackColor.withAlpha(10)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedLevel.value.isEmpty
                        ? null
                        : controller.selectedLevel.value,
                    dropdownColor: Colors.white,
                    hint: Row(
                      children: [
                        const Icon(Icons.sports_tennis_outlined,
                            color: AppColors.textColor, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "Select Level",
                          style: Get.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textColor),
                    items: levels.map((level) {
                      final code = level.split('–').first.trim();
                      final title = level.split('–').last.trim();

                      return DropdownMenuItem(
                        value: level,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                height: 30,
                                width: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.secondaryColor.withAlpha(30),
                                ),
                                child: Text(
                                  code,
                                  style:
                                  Get.textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: Get.textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                    controller.selectedLevel.value = value ?? '',
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),
            PrimaryButton(
              onTap: () {
                Get.back();
              },
              text: "Apply Filter",
            ).paddingOnly(bottom: Get.height * 0.05),
          ],
        ),
      ),
    );
  }

  // ---- Card builder methods remain unchanged ----
  Widget _buildMatchCardFromData(BuildContext context, MatchData data) {
    final dayStr = controller.getDay(data.matchDate);
    final dateOnlyStr = controller.getDate(data.matchDate);
    final timeStr = (data.matchTime ?? '').toLowerCase();
    final clubName = data.clubId?.clubName ?? '-';
    final address = data.clubId?.address ?? "N/A";
    final price = (data.slot?.isNotEmpty == true &&
        data.slot!.first.slotTimes?.isNotEmpty == true)
        ? '₹${data.slot!.first.slotTimes!.first.amount ?? ''}'
        : '₹-';

    final isTimePassed = controller.isMatchTimePassed(data.matchDate, data.matchTime);
    CustomLogger.logMessage(msg: "Match: ${data.matchDate} ${data.matchTime} - Time passed: $isTimePassed", level: LogLevel.debug);
    
    final teamAPlayers = (data.teamA ?? []).take(2).map((p) {
      final pic = p.userId?.profilePic;
      final name = (p.userId?.name ?? "").trim();
      final level = p.userId?.playerLevel?.split(' ').first ?? "-";
      return _buildFilledPlayer(pic ?? "", name, level);
    }).toList();

    while (teamAPlayers.length < 2) {
      if (isTimePassed) {
        teamAPlayers.add(_buildPlayerIndex("P${teamAPlayers.length + 1}","${teamAPlayers.length + 1}"));
      } else {
        teamAPlayers.add(_buildAvailableCircle("teamA", data.sId ?? "", data.skillLevel));
      }
    }

    final teamBPlayers = (data.teamB ?? []).take(2).map((p) {
      final pic = p.userId?.profilePic;
      final name = (p.userId?.name ?? "").trim();
      final level = p.userId?.playerLevel?.split(' ').first ?? "-";
      return _buildFilledPlayer(pic ?? "", name, level);
    }).toList();

    while (teamBPlayers.length < 2) {
      if (isTimePassed) {
        teamBPlayers.add(_buildPlayerIndex("P${teamBPlayers.length + 3}","${teamBPlayers.length + 1}"));
      } else {
        teamBPlayers.add(_buildAvailableCircle("teamB", data.sId ?? "", data.skillLevel));
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.playerCardBackgroundColor,
        border: Border.all(color: AppColors.greyColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$dayStr ',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        TextSpan(
                          text: '$dateOnlyStr | $timeStr',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ).paddingOnly(right: Get.width * 0.05),
                  // Container(
                  //   padding:
                  //   const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.secondaryColor,
                  //     borderRadius: BorderRadius.circular(20),
                  //   ),
                  //   child: Text(
                  //     data.skillLevel?.substring(0, 1).toUpperCase() ?? 'A/B',
                  //     style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  //         color: AppColors.whiteColor, fontSize: 10),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    "${data.skillLevel?.capitalizeFirst ?? 'Professional'} |",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  genderIcon(data.gender).paddingOnly(right: 5, left: 5),
                  Text(
                    data.gender?.capitalizeFirst ?? 'Mixed Doubles',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              )
            ],
          ).paddingOnly(top: 15, bottom: 10, left: 15),

          // Players Row
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...teamAPlayers,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: VerticalDivider(
                      color: AppColors.greyColor,
                      thickness: 1.5,
                      width: 0,
                    ),
                  ),
                  ...teamBPlayers,
                ],
              ),
            ),
          ),

          Divider(thickness: 1.5, height: 0, color: AppColors.greyColor),

          // Footer
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clubName,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: AppColors.darkGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: Get.width * .22,
                color: AppColors.playerCardBackgroundColor,
                child: Text(
                  "₹ ${formatAmount(price)}",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: AppColors.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ).paddingOnly(top: 10, bottom: 12, left: 15),
        ],
      ),
    ).paddingOnly(bottom: 12);
  }

  Widget _buildFilledPlayer(String? imageUrl, String name, String level) {
    // final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
final firstLetter = name.trim().isNotEmpty
    ? name.trim().split(" ").map((e) => e[0]).take(2).join().toUpperCase()
    : '?';
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              placeholder: (context, url) =>
              LoadingWidget(color: AppColors.primaryColor,),
              errorWidget: (context, url, error) => Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
              : Text(
            firstLetter,
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          color: Colors.transparent,
          // height: 40,
          width: Get.width*0.15,
          child: Text(
            name.split(' ').first.capitalizeFirst!,
            style: Get.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          height: 17,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.secondaryColor.withAlpha(20),
          ),
          child: Text(
            level,
            style: Get.textTheme.labelMedium!.copyWith(
              color: AppColors.secondaryColor,
            ),
          ),
        ).paddingOnly(top: 4)
      ],
    );
  }

  Widget _buildAvailableCircle(String team, String matchId, String? skillLevel) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Get.toNamed(
              RoutesName.addPlayer,
              arguments: {
                "team": team,
                "matchId": matchId,
                "needAllOpenMatches": true,
                "matchLevel": skillLevel,
              },
            );
            CustomLogger.logMessage(
                msg: "Team -> $team \nMatch Id -> $matchId",
                level: LogLevel.debug);
          },
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 1),
            ),
            child: const Center(
              child: Icon(Icons.add, color: AppColors.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Available",
          style: Get.textTheme.labelSmall!
              .copyWith(color: AppColors.primaryColor),
        )
      ],
    );
  }

  Widget _buildPlayerIndex(String playerIndex,String index) {
    return Column(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Text(
              playerIndex,
              style: const TextStyle(
                fontSize: 20,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Player $index",
          style: Get.textTheme.labelSmall!
              .copyWith(color: AppColors.blackColor),
        )
      ],
    );
  }
}
