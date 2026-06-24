import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../handler/text_formatter.dart';

class AmericanoScreen extends StatelessWidget {
  final String? buttonType;
  final AmericanoController controller = Get.put(AmericanoController());

  AmericanoScreen({super.key, this.buttonType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
        title: const Text("Americano"),
        centerTitle: true,
        context: context,
        action: [
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.blue.shade800,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textTheme: const TextTheme(
                        headlineMedium: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        titleSmall: TextStyle(fontSize: 14),
                        bodyLarge: TextStyle(fontSize: 16),
                        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    child: Transform.scale(scale: 0.9, child: child!),
                  );
                },
                initialDate: controller.selectedDate.value ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                controller.selectedDate.value = pickedDate;
                controller.fetchAmericanoMatches(isRefresh: true);
              }
            },
            child: Obx(() => Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.textFieldColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.selectedDate.value == null
                        ? 'Date'
                        : DateFormat('dd MMM yyyy').format(controller.selectedDate.value!),
                    style: Get.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  if (controller.selectedDate.value != null)
                    GestureDetector(
                      onTap: () {
                        controller.selectedDate.value = null;
                        controller.fetchAmericanoMatches(isRefresh: true);
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 18,
                      ),
                    )
                  else
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.black,
                      size: 18,
                    ),
                ],
              ),
            )),
          ).paddingOnly(right: 15),
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              // 1. Fullscreen Loading State (Initial load only)
              if (controller.isLoading.value && controller.isEmpty) {
                return const Center(child: LoadingWidget());
              }

              // 2. Empty State
              if (controller.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => controller.fetchAmericanoMatches(isRefresh: true),
                  color: AppColors.whiteColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: Get.height * 0.8,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.sportscourt, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                "No Americano matches found",
                                style: Get.textTheme.titleMedium?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pull down to refresh",
                                style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 3. Populated Matches List State (Seamless Refresh)
              return RefreshIndicator(
                onRefresh: () => controller.fetchAmericanoMatches(isRefresh: true),
                color: AppColors.whiteColor,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: controller.scrollController,
                  padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
                  children: [
                    if (controller.ongoingMatches.isNotEmpty) ...[
                      _sectionTitle("Ongoing"),
                      ...controller.ongoingMatches.map((match) => buildMatchesList(match: match, add: false)),
                    ],
                    if (controller.upcomingMatches.isNotEmpty) ...[
                      _sectionTitle("Upcoming"),
                      ...controller.upcomingMatches.map((match) => buildMatchesList(match: match, add: true)),
                    ],
                    if (controller.isLoadingMore.value) ...[
                      const SizedBox(height: 16),
                      const Center(child: LoadingWidget()),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(height: Get.height * 0.05),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Section title widget
  Widget _sectionTitle(String title) => Text(
        title,
        style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.blackColor),
      ).paddingOnly(bottom: Get.height * 0.01, top: Get.height * 0.02);

  Widget buildMatchesList({required AmericanoMatch match, required bool add}) {
    String genderText = match.gender ?? "Female Only";
    IconData genderIcon = Icons.female;
    if (genderText.toLowerCase().contains("male") && !genderText.toLowerCase().contains("female")) {
      genderIcon = Icons.male;
    } else if (genderText.toLowerCase().contains("mixed")) {
      genderIcon = Icons.wc;
    }

    final bool isJoined = match.isJoined ?? false;
    final int joinedCount = match.players?.isNotEmpty == true ? match.players!.length : (match.joinedMembers ?? 0);
    final bool isFull = match.maxPlayers != null && joinedCount >= match.maxPlayers!;
    final bool canJoin = add && !isJoined && !isFull;

    return GestureDetector(
      onTap: () {
        if (isFull) {
          Get.toNamed(RoutesName.scoreView, arguments: {'americanoMatchId': match.sId})?.then((_){controller.fetchAmericanoMatches(isRefresh: true);});
        } else if (canJoin) {
          showAmericanoBottomSheet(Get.context!, match);
        } else {
          Get.toNamed(RoutesName.scoreView, arguments: {'americanoMatchId': match.sId})?.then((_){controller.fetchAmericanoMatches(isRefresh: true);});
        }
      },
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(11),
          gradient: LinearGradient(
            colors: [
              Color(0xffFFFFFF),
              Color(0xffDEE5FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              color: Colors.grey.withAlpha(60),
              blurRadius: 9.0,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -40,
              top: -10,
              child: SvgPicture.asset(Assets.images.dotsFipPromises.path,height: 100,width: 100,),
            ),
            Positioned(
              right: -30,
              bottom: -20,
              child: SvgPicture.asset(Assets.images.dotsFipPromises.path,height: 100,width: 100,),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.clubId?.clubName ?? "Club Name",
                        style: Get.textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    avatarGroup(
                      players: match.players ?? [],
                      add: canJoin,
                      joinedMembers: joinedCount,
                      isJoined: isJoined,
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "${match.matchDay??""} | ${match.formattedMatchDate}",
                      style: Get.textTheme.bodySmall,
                    ).paddingOnly(right: 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6,vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.secondaryColor,
                      ),
                      child: Text(
                        match.skillLevel ?? "A",
                        style: Get.textTheme.bodySmall!.copyWith(
                          color: AppColors.whiteColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(genderIcon, size: 15),
                    Text(
                      genderText.capitalizeFirstChar(),
                      style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ).paddingOnly(bottom: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.person_crop_circle, size: 14),
                        Text(
                          "$joinedCount Players",
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            canJoin
                                ? "Join Now!  "
                                : (isFull
                                    ? "Full  "
                                    : (isJoined ? "Joined  " : "View Score  ")),
                            style: Get.textTheme.displaySmall!.copyWith(
                              color: isFull
                                  ? Colors.red.shade600
                                  : AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: isFull
                                ? Colors.grey.shade300
                                : AppColors.primaryColor,
                            child: Icon(
                              isFull ? Icons.lock : Icons.arrow_forward,
                              size: 14,
                              color: AppColors.whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ).paddingAll(10),
          ],
        ),
      ).paddingOnly(bottom: Get.height * 0.015),
    );
  }

  String? _getPlayerProfilePic(AmericanoPlayer player) {
    final pic = player.registerUserId?.profilePic;
    if (pic != null && pic.isNotEmpty) {
      return pic;
    }
    return null;
  }

  String _getPlayerInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final firstLetter = parts.first[0];
      final lastLetter = parts.last[0];
      return (firstLetter + lastLetter).toUpperCase();
    }
    return fullName.trim()[0].toUpperCase();
  }

  void showPlayersDialog(BuildContext context, List<AmericanoPlayer> players) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            width: Get.width * 0.88,
            height: Get.height * 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Joined Players",
                          style: Get.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.blackColor,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${players.length}",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                
                // List of Players
                Expanded(
                  child: players.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.person_3, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              const Text("No players joined yet", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: players.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final profilePic = _getPlayerProfilePic(player);
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.textFieldColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withAlpha(20)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.secondaryColor,
                                    radius: 21,
                                    child: CircleAvatar(
                                      radius: 19,
                                      backgroundColor: AppColors.primaryColor,
                                      backgroundImage: profilePic != null ? CachedNetworkImageProvider(profilePic) : null,
                                      child: profilePic == null
                                          ? Text(
                                              _getPlayerInitials(player.fullName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          player.fullName?.capitalizeFirstChar() ?? "Anonymous",
                                          style: Get.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blackColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (player.playerLevel != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            player.playerLevel!,
                                            style: Get.textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Player Badge or gender
                                  if (player.gender != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        player.gender!.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget avatarGroup({
    required List<AmericanoPlayer> players,
    required bool add,
    required int joinedMembers,
    required bool isJoined,
  }) {
    // Show up to 4 items
    final int displayedCount = players.isNotEmpty ? (players.length > 4 ? 4 : players.length) : 0;
    final int itemsToGenerate = displayedCount;

    final int remaining = joinedMembers - itemsToGenerate;
    final bool showExtraCircle = remaining > 0 || add;

    final int totalItems = itemsToGenerate + (showExtraCircle ? 1 : 0);

    return GestureDetector(
      onTap: () {
        if (isJoined && players.isNotEmpty) {
          showPlayersDialog(Get.context!, players);
        }
      },
      child: SizedBox(
        height: 40,
        width: totalItems * 22.0 + 20,
        child: Stack(
          children: [
            ...List.generate(itemsToGenerate, (index) {
              final String? profilePic = _getPlayerProfilePic(players[index]);
              return Positioned(
                left: index * 22.0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryColor,
                    backgroundImage: profilePic != null ? CachedNetworkImageProvider(profilePic) : null,
                    child: profilePic == null
                        ? Text(
                            _getPlayerInitials(players[index].fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
            if (showExtraCircle)
              Positioned(
                left: itemsToGenerate * 22.0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: add ? const Color(0xFF1E40AF) : Colors.grey.shade400,
                    child: Text(
                      add ? '+' : '+$remaining',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: add ? 20 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showAmericanoBottomSheet(BuildContext context, AmericanoMatch match) {
    final DraggableScrollableController draggableController = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              DraggableScrollableSheet(
                controller: draggableController,
                initialChildSize: 0.45,
                minChildSize: 0.45,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return GestureDetector(
                    onTap: () {},
                    child: AmericanoBottomSheetContent(
                      scrollController: scrollController,
                      draggableController: draggableController,
                      match: match,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}