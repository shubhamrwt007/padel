import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/user_requests/requests_controller.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  RequestsController get controller => Get.find<RequestsController>();

  String formatMatchDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEE dd MMM').format(date);
    } catch (e) {
      return dateString;
    }
  }

  List<RequesterId> getAllPlayers(MatchId? match) {
    List<RequesterId> players = [];
    if (match?.teamA != null) {
      players.addAll(
        match!.teamA!
            .map((player) => player.user)
            .where((user) => user != null)
            .cast<RequesterId>(),
      );
    }
    if (match?.teamB != null) {
      players.addAll(
        match!.teamB!
            .map((player) => player.user)
            .where((user) => user != null)
            .cast<RequesterId>(),
      );
    }
    return players;
  }

  List<Widget> _buildAvatarList(
    MatchId? match,
    Requests request,
    int index,
    BuildContext context,
  ) {
    final teamAPlayers =
        match?.teamA
            ?.map((player) => player.user)
            .where((user) => user != null)
            .cast<RequesterId>()
            .toList() ??
        [];
    final teamBPlayers =
        match?.teamB
            ?.map((player) => player.user)
            .where((user) => user != null)
            .cast<RequesterId>()
            .toList() ??
        [];
    final matchId = match?.id ?? "";
    List<Widget> avatars = [];

    // Add Team A players (first 2 slots)
    for (int i = 0; i < 2; i++) {
      avatars.add(
        Positioned(
          left: i * 30.0,
          child: i < teamAPlayers.length
              ? _buildPlayerAvatar(
                  teamAPlayers[i],
                  index,
                  context,
                  isAdd: false,
                )
              : _buildPlayerAvatar(
                  null,
                  index,
                  context,
                  isAdd: true,
                  team: "teamA",
                  matchId: matchId,
                  request: request,
                ),
        ),
      );
    }

    // Add Team B players (next 2 slots)
    for (int i = 0; i < 2; i++) {
      avatars.add(
        Positioned(
          left: (2 + i) * 30.0,
          child: i < teamBPlayers.length
              ? _buildPlayerAvatar(
                  teamBPlayers[i],
                  index,
                  context,
                  isAdd: false,
                )
              : _buildPlayerAvatar(
                  null,
                  index,
                  context,
                  isAdd: true,
                  team: "teamB",
                  matchId: matchId,
                  request: request,
                ),
        ),
      );
    }

    return avatars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
        title: Text("Requests"),
        centerTitle: true,
        context: context,
      ),
      body: Column(
        children: [
          requestTabs(controller),
          Obx(
            () => controller.selectedTab.value == 0
                ? Text(
                    "You have new match requests! Accept the requests from the players you want to play with. Once accepted, you’ll be paired for the match and can start competing right away.",
                    textAlign: TextAlign.center,
                    style: Get.textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ).paddingOnly(left: 16, right: 16)
                : Text(
                    "If your open match request isn’t accepted, you can swipe left the card to cancel the booking and get an instant refund in your wallet.",
                    textAlign: TextAlign.center,
                    style: Get.textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ).paddingOnly(left: 16, right: 16),
          ),
          Expanded(
            child: Obx(() {
              final list = controller.selectedTab.value == 0
                  ? controller.joinRequests
                  : controller.myRequests;

              if (controller.isLoadingRequests.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (list.isEmpty) {
                return Center(
                  child: Text(
                    controller.selectedTab.value == 0
                        ? "No join requests found"
                        : "No match requests found",
                    style: Get.textTheme.bodyMedium,
                  ),
                );
              }

              return RefreshIndicator(
                color: Colors.white,
                onRefresh: controller.refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final request = list[index];

                    return Obx(() {
                      final isExpanded =
                          controller.expandedIndex.value == index;
                      final isMyRequestsTab = controller.selectedTab.value == 1;

                      final cardWidget = AnimatedSize(
                        key: ValueKey('card_$index'),
                        duration: const Duration(milliseconds: 300),
                        child: _buildMatchCardFromData(
                          context,
                          index,
                          isExpanded,
                          request,
                        ),
                      );

                      // Only wrap with Slidable in "My Requests" tab
                      if (isMyRequestsTab) {
                        return Slidable(
                          key: ValueKey('slidable_${request.id}_$index'),
                          endActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  _showDeleteConfirmation(
                                    context,
                                    request,
                                    index,
                                  );
                                },
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red,
                                icon: Icons.delete,
                                label: 'Delete',
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ],
                          ),
                          child: cardWidget,
                        );
                      }

                      return cardWidget;
                    });
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget requestTabs(RequestsController controller) {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _tabButton(
              title: "Receive",
              count: controller.joinRequests.length,
              selected: controller.selectedTab.value == 0,
              onTap: () => controller.changeTab(0),
            ),
            _tabButton(
              title: "Sent",
              count: controller.myRequests.length,
              selected: controller.selectedTab.value == 1,
              onTap: () => controller.changeTab(1),
            ),
          ],
        ),
      );
    });
  }

  Widget _tabButton({
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? const Color(0xff1c46a0)
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xff1c46a0)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCardFromData(
    BuildContext context,
    int index,
    bool isExpanded,
    Requests request,
  ) {
    final match = request.match;
    final time =
        "${request.startTime?.split(' ').first ?? ""}-${request.endTime ?? ""}";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: request.type != "booking_invitation"
              ? Color(0xffC8D6FB)
              : Color(0xff3DBE64).withValues(alpha: 0.5),
        ),
        gradient: LinearGradient(
          colors: request.type != "booking_invitation"
              ? [Color(0xffF3F7FF), Color(0xff9EBAFF).withValues(alpha: 0.3)]
              : [
                  Color(0xffBFEECD).withValues(alpha: 0.3),
                  Color(0xffBFEECD).withValues(alpha: 0.2),
                ],
        ),
      ),
      child: Column(
        children: [
          if (controller.selectedTab.value == 0) ...[
            Row(
              children: [
                /// Avatar with badge
                CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  radius: 22,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        (request.type == "request"
                            ? request.requester?.profilePic?.isNotEmpty ?? false
                            : request.matchCreator?.profilePic?.isNotEmpty ??
                                  false)
                        ? CachedNetworkImageProvider(
                            request.type == "request"
                                ? request.requester!.profilePic!
                                : request.matchCreator!.profilePic!,
                          )
                        : null,
                    child:
                        (request.type == "request"
                            ? request.requester?.profilePic?.isEmpty ?? true
                            : request.matchCreator?.profilePic?.isEmpty ?? true)
                        ? Text(
                            _getInitials(
                              request.type == "request"
                                  ? "${request.requester?.name ?? ''} ${request.requester?.lastName ?? ''}"
                                  : "${request.matchCreator?.name ?? ''} ${request.matchCreator?.lastName ?? ''}",
                            ).trim(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                /// Name + XP + phone
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (request.type == "request"
                                    ? request.requester?.name
                                              ?.capitalizeFirstChar() ??
                                          'Unknown'
                                    : request.matchCreator?.name
                                              ?.capitalizeFirstChar() ??
                                          'Unknown')
                                .trim(),
                            style: Get.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '⭐ ${formatAmount('${request.type == "request" ? request.requester?.xpPoints ?? 0 : request.matchCreator?.xpPoints ?? 0}')} XP Points ',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '| ${request.type == "request" ? request.requester?.gender ?? '' : request.matchCreator?.gender ?? ''}',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '| ${request.type == "request" ? request.requester?.level ?? '' : request.matchCreator?.level ?? ''}',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () {
                          if (request.type == "request") {
                            _showAcceptConfirmation(
                              context,
                              request.match?.id ?? "",
                              request.preferredTeam ?? "",
                              request.match?.skillLevel ?? "",
                              request.id ?? "",
                              request.type ?? "",
                              request,
                            );
                          } else {
                            controller.acceptPlayerRequest(
                              request.id ?? "",
                              request.match?.id ?? "",
                              request.preferredTeam ?? "",
                              request.type ?? "",
                              request,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 15,
                          ),
                          side: BorderSide(color: Colors.white),
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Obx(() {
                          final isLoading =
                              controller.acceptingRequests[request.id] ?? false;
                          return isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Accept",
                                  style: Get.textTheme.labelLarge!.copyWith(
                                    color: Colors.white,
                                  ),
                                );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.primaryColor, thickness: 0.1),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: formatMatchDate(match?.matchDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1c46a0),
                              ),
                            ),
                            TextSpan(
                              text: ' | $time',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      //   decoration: BoxDecoration(
                      //     color: Colors.green,
                      //     borderRadius: BorderRadius.circular(30),
                      //   ),
                      //   child: const Text(
                      //     "A",
                      //     style: TextStyle(color: Colors.white, fontSize: 9),
                      //   ),
                      // ).paddingOnly(left: 5),
                    ],
                  ),
                  if (request.type != "booking_invitation")
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(
                          " ${request.match?.skillLevel ?? 'N/A'} | ",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        genderIcon(match?.gender),
                        const SizedBox(width: 4),
                        Text(
                          request.match?.gender ?? 'N/A',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => controller.toggleExpand(index, request: request),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          isExpanded
              ? _expandedCard(context, index, request)
              : _collapsedCard(context, index, request),
        ],
      ),
    );
  }

  void _showAcceptConfirmation(
    BuildContext context,
    String matchId,
    String team,
    String skillLevel,
    String requestId,
    String requestType,
    Requests request,
  ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirm Request',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ],
              ),
              const Divider(thickness: 0.6),
              const SizedBox(height: 16),
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Accept this player request?',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once accepted, the player will be added to your match and you won\'t be able to remove them.',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        controller.acceptPlayerRequest(
                          requestId,
                          matchId,
                          team,
                          requestType,
                          request,
                        );
                      },
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Requests request,
    int index,
  ) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, size: 22),
                ),
              ),

              const SizedBox(height: 8),

              // Red delete icon
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                'Withdraw Request',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Do you really want to withdraw your request? If you proceed, you will no longer be able to join this match.',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        controller.withdrawRequest(request.id ?? "");
                      },
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _collapsedCard(BuildContext context, int index, Requests request) {
    final match = request.match;
    final club = match?.club;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 4 * 28 + 28,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _buildAvatarList(match, request, index, context),
                ),
              ),
            ),
            if (controller.selectedTab.value == 1)
              Row(
                children: [
                  Icon(CupertinoIcons.eye_fill,color: Colors.grey,size: 15,),
                  Text(
                    " ${request.viewCount ?? 0} ",
                    style: Get.textTheme.headlineSmall!.copyWith(color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club?.clubName ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          club?.locations?.isNotEmpty == true
                              ? club!.locations!.first.city
                                        ?.capitalizeFirstChar() ??
                                    ""
                              : club?.billingAddress?.city
                                        ?.capitalizeFirstChar() ??
                                    "",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Your Share: ",
                        style: Get.textTheme.headlineMedium!.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text:
                            "₹${controller.formatAmount('${controller.getPerShare(request)}')}",
                        style: Get.textTheme.headlineMedium!.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Total Price: ",
                        style: Get.textTheme.headlineMedium!.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text:
                            "₹${controller.formatAmount('${controller.getTotalAmount(request)}')}",
                        style: Get.textTheme.titleLarge!.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _expandedCard(BuildContext context, int index, Requests request) {
    final match = request.match;
    final club = match?.club;
    final totalPlayers =
        (match?.teamA?.length ?? 0) + (match?.teamB?.length ?? 0);
    final courtCount = request.courtCount ?? 0;
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, size: 18),
              SizedBox(width: 8),
              Text("$totalPlayers attendee", style: Get.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 4 * 28 + 28,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.greyColor),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black12,
              //     blurRadius: 10,
              //     offset: Offset(0, -2),
              //   ),
              // ]
            ),
            child: SizedBox(
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: _buildAvatarList(match, request, index, context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.sports_tennis, size: 18),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club?.clubName ?? 'N/A',
                    style: Get.textTheme.labelLarge,
                  ),
                  club?.locations?.isNotEmpty == true
                      ? SizedBox(
                          width: Get.width * 0.7,
                          child: Text(
                            club?.locations?.isNotEmpty == true
                                ? "Address: ${club?.locations?.first.address}"
                                : "",
                            style: Get.textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.clip,
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.sports_tennis, size: 18),
              SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No. of ${((request.courtCount ?? 0) >= 2) ? 'Courts' : 'Court'} ($courtCount)",
                    style: Get.textTheme.labelLarge,
                  ),
                  // Text(club?.locations?[0].courtType?.join(' • ') ?? 'N/A',style:Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w400)),
                ],
              ),
            ],
          ),

          Divider(color: Colors.grey, thickness: 0.1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Share:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "₹${controller.formatAmount('${controller.getPerShare(request)}')}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1c46a0),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Price:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "₹${controller.formatAmount('${controller.getTotalAmount(request)}')}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1c46a0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatTimeRange(List<String>? times) {
    if (times == null || times.isEmpty) return '';
    if (times.length == 1) return times.first;

    final first = times.first;
    final last = times.last;

    // Extract number from first time (e.g., "8" from "8 pm")
    final firstNumber = first.replaceAll(RegExp(r'[^0-9]'), '');

    return '$firstNumber-$last';
  }

  Widget _buildPlayerAvatar(
    RequesterId? player,
    int index,
    BuildContext context, {
    bool isAdd = false,
    String? team,
    String? matchId,
    Requests? request,
  }) {
    return GestureDetector(
      onTap: isAdd
          ? () {
              // AddPlayerBottomSheet.show(
              //   context,
              //   arguments: {
              //     "team": request?.preferredTeam ?? team,
              //     "matchId": matchId ?? "",
              //     "needYourMatchRequests": true,
              //     "matchLevel": "",
              //     "isLoginUser": true,
              //     "isMatchCreator": false,
              //     "requestId":request?.id??""
              //   },
              // );
              // Get.toNamed(
              //   '/addPlayer',
              //   arguments: {
              //     "team": request?.preferredTeam ?? team,
              //     "matchId": matchId ?? "",
              //     "needYourMatchRequests": true,
              //     "matchLevel": "",
              //     "isLoginUser": true,
              //     "isMatchCreator": false,
              //     "requestId":request?.id??""
              //   },
              // );
            }
          : null,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child:
            !isAdd &&
                player?.profilePic != null &&
                player!.profilePic!.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: player.profilePic!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircleAvatar(
                    radius: 20,
                    backgroundColor: request?.type != "booking_invitation"
                        ? const Color(0xffeaf0ff)
                        : Color(0xffDFF7E6),
                    child: Text(
                      _getInitials(player.name),
                      style: TextStyle(
                        fontSize: 18,
                        color: request?.type != "booking_invitation"
                            ? AppColors.primaryColor
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: 20,
                    backgroundColor: request?.type != "booking_invitation"
                        ? const Color(0xffeaf0ff)
                        : Color(0xffDFF7E6),
                    child: Text(
                      _getInitials(player.name),
                      style: TextStyle(
                        fontSize: 18,
                        color: request?.type != "booking_invitation"
                            ? AppColors.primaryColor
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: request?.type != "booking_invitation"
                    ? const Color(0xffeaf0ff)
                    : Color(0xffDFF7E6),
                child: isAdd
                    ? Icon(
                        Icons.add,
                        color: request?.type != "booking_invitation"
                            ? AppColors.primaryColor
                            : Colors.green,
                      )
                    : Text(
                        _getInitials(player?.name),
                        style: TextStyle(
                          fontSize: 18,
                          color: request?.type != "booking_invitation"
                              ? Colors.green
                              : AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    // If it looks like a user ID (long string), just use first 2 characters
    if (name.length > 10 && !name.contains(' ')) {
      return name.substring(0, 2).toUpperCase();
    }
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
