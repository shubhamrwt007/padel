import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_screen.dart';
import 'package:padel_mobile/presentations/booking/open_matches/your_match_requests/your_match_requests_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
class YourMatchRequestsScreen extends StatelessWidget {
  final YourMatchRequestsController controller = Get.put(
      YourMatchRequestsController());

  YourMatchRequestsScreen({super.key});

  String formatMatchDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('EEEE dd MMM').format(date);
    } catch (e) {
      return dateString;
    }
  }

  List<RequesterId> getAllPlayers(MatchId? match) {
    List<RequesterId> players = [];
    if (match?.teamA != null) {
      players.addAll(match!.teamA!.map((player) => player.user).where((user) => user != null).cast<RequesterId>());
    }
    if (match?.teamB != null) {
      players.addAll(match!.teamB!.map((player) => player.user).where((user) => user != null).cast<RequesterId>());
    }
    return players;
  }

  List<Widget> _buildAvatarList(MatchId? match, Requests request, BuildContext context) {
    final teamAPlayers = match?.teamA?.map((player) => player.user).where((user) => user != null).cast<RequesterId>().toList() ?? [];
    final teamBPlayers = match?.teamB?.map((player) => player.user).where((user) => user != null).cast<RequesterId>().toList() ?? [];
    final matchId = match?.id ?? "";
    final isBookingInvitation = request.type == 'invitation';
    List<Widget> avatars = [];

    // Add Team A players (first 2 slots)
    for (int i = 0; i < 2; i++) {
      avatars.add(
        Positioned(
          left: i * 35.0,
          child: i < teamAPlayers.length
              ? _buildPlayerAvatar(teamAPlayers[i], isBookingInvitation, context, isAdd: false)
              : _buildPlayerAvatar(null, isBookingInvitation, context, isAdd: true, team: "teamA", matchId: matchId, request: request),
        ),
      );
    }

    // Add Team B players (next 2 slots)
    for (int i = 0; i < 2; i++) {
      avatars.add(
        Positioned(
          left: (2 + i) * 35.0,
          child: i < teamBPlayers.length
              ? _buildPlayerAvatar(teamBPlayers[i], isBookingInvitation, context, isAdd: false)
              : _buildPlayerAvatar(null, isBookingInvitation, context, isAdd: true, team: "teamB", matchId: matchId, request: request),
        ),
      );
    }

    return avatars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(
          titleTextColor: AppColors.primaryColor,
          title: Text("Your match Invitation"), context: context),
      body: Column(
        children: [
          Text(
            textAlign: TextAlign.center,
            "You have new match requests! Accept the requests from the players you want to play with. Once accepted, you’ll be paired for the match and can start competing right away.",
          style: Get.textTheme.bodyLarge!.copyWith(fontSize: 12),).paddingOnly(left: 16,right: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRequests.value) {
                return Center(child: LoadingWidget(color: AppColors.primaryColor,));
              }
              if (controller.joinRequests.isEmpty) {
                return Center(child: Text("No match requests found"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.joinRequests.length,
                itemBuilder: (context, index) {
                  final request = controller.joinRequests[index];

                  return Obx(() {
                    final isExpanded = controller.expandedIndex.value == index;
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildMatchCardFromData(
                        context,
                        index,
                        isExpanded,
                        request,
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
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
    final club = match?.club;
    final isBookingInvitation = request.type == 'invitation';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isBookingInvitation ? Color(0xffC8D6FB) : Color(0xff3DBE64).withOpacity(0.5)),
        gradient: LinearGradient(
          colors: isBookingInvitation
              ? [Color(0xffF3F7FF), Color(0xff9EBAFF).withOpacity(0.3)]
              : [Color(0xffBFEECD).withOpacity(0.3), Color(0xffBFEECD).withOpacity(0.2)],
        ),
      ),
      child: Column(
        children: [
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
                              text: ' | ${formatTimeRange(match?.matchTime)}',
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
                  if ((request.match?.skillLevel?.isNotEmpty ?? false) ||
                      (request.match?.gender?.isNotEmpty ?? false))
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(
                          " ${request.match?.skillLevel ?? ''} | ",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        genderIcon(request.match?.gender),
                        const SizedBox(width: 4),
                        Text(
                          request.match?.gender ?? '',
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
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => controller.toggleExpand(index),
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
              )
            ],
          ),
          isExpanded
              ? _expandedCard(context, request)
              : _collapsedCard(context, request),

        ],
      )
    );
  }
  Widget _collapsedCard(BuildContext context, Requests request) {
    final match = request.match;
    final club = match?.club;
    final totalPlayers = (match?.teamA?.length ?? 0) + (match?.teamB?.length ?? 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 4 * 30 + 42,
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
                  ]
              ),
              child: SizedBox(
                height: 50,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _buildAvatarList(match, request, context),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                controller.acceptRequest(request.id ?? "", request.type ?? "", request);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6,horizontal: 15),
                side: BorderSide(color: Colors.white),
                backgroundColor:AppColors.primaryColor ,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                  "Accept",
                  style: Get.textTheme.labelLarge!.copyWith(color: Colors.white)
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
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
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${club?.city ?? ''},${club?.zipCode??""}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, 2),
              child: Text(
                "₹ ${formatAmount(request.perShare?.toString() ?? '0')}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1c46a0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _expandedCard(BuildContext context, Requests request) {
    final match = request.match;
    final club = match?.club;
    final totalPlayers = (match?.teamA?.length ?? 0) + (match?.teamB?.length ?? 0);
    
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children:  [
                  Icon(Icons.access_time, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "${formatMatchDate(match?.matchDate)} | ${formatTimeRange(match?.matchTime)}",
                    style: Get.textTheme.bodySmall,
                  ),
                ],
              ),
              // const Icon(Icons.share, size: 20, color: Colors.grey),
            ],
          ),
      
          const SizedBox(height: 12),
      
          Row(
            children:  [
              Icon(Icons.group, size: 18),
              SizedBox(width: 8),
              Text("$totalPlayers attendee ($totalPlayers confirmed)",style: Get.textTheme.bodySmall,),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 4 * 30 + 42,
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
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: _buildAvatarList(match, request, context),
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
                  Text(club?.clubName ?? 'N/A',style:Get.textTheme.labelLarge),
                  SizedBox(
                      width: Get.width*0.5,
                      child: Text("${club?.address ?? ''}, ${club?.city ?? ''} ${club?.zipCode ?? ''}",style:Get.textTheme.bodySmall,overflow: TextOverflow.clip,)),
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
                  Text("Type of Court (${club?.courtCount ?? 0} court)",style:Get.textTheme.labelLarge),
                  Text(club?.courtType?.join(' • ') ?? 'N/A',style:Get.textTheme.bodySmall),
                ],
              ),
            ],
          ),
      
          Divider(color: Colors.grey,thickness: 0.1,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Share:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "₹${formatAmount(request.perShare?.toString() ?? '0')}",
                style: TextStyle(
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
              Text(
                "Total Price:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                "₹${formatAmount(((request.totalAmount ?? 0)).toString())}",
                style: TextStyle(
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
    if (times == null || times.isEmpty) return 'N/A';
    if (times.length == 1) return times.first;
    return '${times.first} - ${times.last}';
  }

  Widget _buildPlayerAvatar(RequesterId? player, bool isBookingInvitation, BuildContext context, {bool isAdd = false, String? team, String? matchId, Requests? request}) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white,
      child: !isAdd && player?.profilePic != null && player!.profilePic!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: player.profilePic!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircleAvatar(
                  radius: 24,
                  backgroundColor: isBookingInvitation ? const Color(0xffeaf0ff) : Color(0xffDFF7E6),
                  child: Text(
                    _getInitials(player.name),
                    style: TextStyle(
                      fontSize: 18,
                      color: isBookingInvitation ? AppColors.primaryColor : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 24,
                  backgroundColor: isBookingInvitation ? const Color(0xffeaf0ff) : Color(0xffDFF7E6),
                  child: Text(
                    _getInitials(player.name),
                    style: TextStyle(
                      fontSize: 18,
                      color: isBookingInvitation ? AppColors.primaryColor : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : CircleAvatar(
              radius: 24,
              backgroundColor: isBookingInvitation ? const Color(0xffeaf0ff) : Color(0xffDFF7E6),
              child: isAdd
                  ? Icon(Icons.add, color: isBookingInvitation ? AppColors.primaryColor : Colors.green)
                  : Text(
                      _getInitials(player?.name),
                      style: TextStyle(
                        fontSize: 18,
                        color: isBookingInvitation ? AppColors.primaryColor : Colors.green,
                        fontWeight: FontWeight.bold,
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