import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/primary_text_feild.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_controller.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_screen.dart';

import '../../../repositories/openmatches/open_match_repository.dart';
import '../../widgets/coming_soon_fireworks.dart';

class AppPlayersController extends GetxController {
  RxList<Map<String, dynamic>> nearbyPlayers = <Map<String, dynamic>>[].obs;
  RxBool isLoadingNearbyPlayers = false.obs;
  RxString requestingPlayerId = ''.obs;
  RxList<String> requestedPlayerIds = <String>[].obs;
  final OpenMatchRepository repository = OpenMatchRepository();
  RxString bookingType = ''.obs;
  RxBool invitationSent = false.obs;
  RxBool isSendingInvitation = false.obs;
  
  // Pagination
  RxInt currentPage = 1.obs;
  RxInt totalPages = 1.obs;
  RxBool hasMore = true.obs;
  RxBool isLoadingMore = false.obs;
  final ScrollController scrollController = ScrollController();
  RxString currentBookingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final delta = maxScroll - currentScroll;
      
      print('📜 Scroll: current=$currentScroll, max=$maxScroll, delta=$delta');
      print('📊 Pagination: page=${currentPage.value}, totalPages=${totalPages.value}, hasMore=${hasMore.value}, isLoadingMore=${isLoadingMore.value}');
      
      if (delta <= 200) {
        print('🔄 Near bottom, checking if should load more...');
        if (!isLoadingMore.value && hasMore.value) {
          print('✅ Loading more players...');
          loadMorePlayers();
        } else {
          print('❌ Cannot load: isLoadingMore=${isLoadingMore.value}, hasMore=${hasMore.value}');
        }
      }
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> sendBookingInvitation(String bookingId) async {
    try {
      isSendingInvitation.value = true;
      print("OBJEDOIJF________________$bookingId,,,,,");
      final response = await repository.sendBookingInvitation(bookingId: bookingId, sendNotifications: true);
      if (response.status == 200) {
        invitationSent.value = true;
        await fetchNearByPlayers(bookingId: bookingId);
      }
    } catch (e) {
      // handle silently
    } finally {
      isSendingInvitation.value = false;
    }
  }

  Future<void> fetchNearByPlayers({String search = '',required String bookingId}) async {
    try {
      isLoadingNearbyPlayers.value = true;
      currentPage.value = 1;
      currentBookingId.value = bookingId;
      nearbyPlayers.clear();
      
      print('🔍 Fetching players: page=1, bookingId=$bookingId, search=$search');
      
      final response = await repository.findNearByPlayer(
        search: search,
        bookingId: bookingId,
        page: currentPage.value,
        limit: 10,  // Reduced for testing pagination
      );
      
      if(response.status == 200 && response.players != null){
        totalPages.value = response.totalPages ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        
        print('✅ Fetched ${response.players!.length} players');
        print('📊 Pagination: currentPage=${currentPage.value}, totalPages=${totalPages.value}, hasMore=${hasMore.value}');
        
        nearbyPlayers.value = response.players!.map((player) {
          print('Player: ${player.name}, Level: ${player.level}');
          return {
            'id': player.id ?? '',
            'name': player.name ?? '',
            'profilePic': player.profilePic ?? '',
            'city': player.city ?? '',
            'cityName': player.cityName ?? '',
            'level': player.level ?? '',
            'totalMatchesPlayed': player.totalMatchesPlayed ?? '',
            'xpPoints': player.xpPoints ?? '',
            "hasPendingRequest":player.hasPendingRequest??false
          };
        }).toList();
      }
    } catch (e) {
      print('❌ Error fetching players: $e');
      isLoadingNearbyPlayers.value = false;
    } finally {
      isLoadingNearbyPlayers.value = false;
    }
  }

  Future<void> loadMorePlayers() async {
    if (isLoadingMore.value || !hasMore.value) {
      print('⏸️ Load more skipped: isLoadingMore=${isLoadingMore.value}, hasMore=${hasMore.value}');
      return;
    }
    
    try {
      isLoadingMore.value = true;
      currentPage.value++;
      
      print('📄 Loading page ${currentPage.value}...');
      
      final response = await repository.findNearByPlayer(
        bookingId: currentBookingId.value,
        page: currentPage.value,
        limit: 3,  // Reduced for testing pagination
      );
      
      if(response.status == 200 && response.players != null){
        totalPages.value = response.totalPages ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        
        print('✅ Loaded ${response.players!.length} more players');
        print('📊 Updated pagination: currentPage=${currentPage.value}, totalPages=${totalPages.value}, hasMore=${hasMore.value}');
        
        final newPlayers = response.players!.map((player) {
          return {
            'id': player.id ?? '',
            'name': player.name ?? '',
            'profilePic': player.profilePic ?? '',
            'city': player.city ?? '',
            'cityName': player.cityName ?? '',
            'level': player.level ?? '',
            'totalMatchesPlayed': player.totalMatchesPlayed ?? '',
            'xpPoints': player.xpPoints ?? '',
            "hasPendingRequest":player.hasPendingRequest??false
          };
        }).toList();
        
        nearbyPlayers.addAll(newPlayers);
        print('📋 Total players now: ${nearbyPlayers.length}');
      }
    } catch (e) {
      print('❌ Error loading more: $e');
      currentPage.value--;
    } finally {
      isLoadingMore.value = false;
    }
  }
}

class AppPlayersBottomSheetScore extends StatefulWidget {
  final String matchId;
  final String teamName;
  final String? openMatchId;
  final String? bookingId;
  final String? bookingType;
  final List<String>? currentPlayerIds;
  final bool showAddGuestButton;

  const AppPlayersBottomSheetScore({
    super.key, 
    required this.matchId, 
    required this.teamName, 
    this.openMatchId, 
    this.bookingId, 
    this.bookingType, 
    this.currentPlayerIds, 
    this.showAddGuestButton = true,
  });

  @override
  State<AppPlayersBottomSheetScore> createState() => _AppPlayersBottomSheetScoreState();
}

class _AppPlayersBottomSheetScoreState extends State<AppPlayersBottomSheetScore> {
  late final AppPlayersController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AppPlayersController(), tag: widget.bookingId);
    print("AppPlayersBottomSheetScore - matchId: ${widget.matchId}, openMatchId: ${widget.openMatchId}, bookingId: ${widget.bookingId}, bookingType: ${widget.bookingType}");
    controller.bookingType.value = widget.bookingType ?? '';
    controller.fetchNearByPlayers(bookingId: widget.bookingId ?? "");
  }

  @override
  void dispose() {
    Get.delete<AppPlayersController>(tag: widget.bookingId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final maxHeight = screenHeight - topPadding - 60;
    
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 10,
          bottom: 10,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            SizedBox(
              height: 45,
              child: PrimaryTextField(
                contentPadding: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
                maxLength: 10,
                onChanged: (value) => controller.fetchNearByPlayers(search: value, bookingId: widget.bookingId ?? ""),
                hintStyle: Get.textTheme.headlineSmall!.copyWith(color: AppColors.textColor),
                suffixIcon: Icon(Icons.search, color: AppColors.textColor),
                hintText: 'Search by Name / Phone number',
              ),
            ),
            Obx(() => controller.invitationSent.value
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: controller.isSendingInvitation.value
                        ? null
                        : () => controller.sendBookingInvitation(widget.bookingId ?? ''),
                    child: Container(
                      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 14, right: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xffEEF1FF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Send Request Automatic", style: Get.textTheme.headlineSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: controller.isSendingInvitation.value
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    'Send Request',
                                    style: Get.textTheme.bodyLarge!.copyWith(
                                      color: AppColors.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ).paddingOnly(top: 5)),
            const SizedBox(height: 12),
            SizedBox(
              height: Get.height * 0.25,
              child: _playersList(widget.bookingId ?? ""),
            ),
            const SizedBox(height: 12),
            _actionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Find a player',
          style: Get.textTheme.headlineMedium,
        ),
        ComingSoonFireworks(
          textStyle: Get.textTheme.bodySmall!.copyWith(color: AppColors.primaryColor),
        ).paddingOnly(left: Get.width*.18),
        Transform.translate(
          offset: Offset(8, 0),
          child: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ),

      ],
    );
  }

  Widget _playersList(String bookingId) {
    return Obx(() {
      if (controller.isLoadingNearbyPlayers.value) {
        return Center(child: CircularProgressIndicator());
      }
      
      if (controller.nearbyPlayers.isEmpty) {
        return Center(
          child: Text(
            'No  player found',
            style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.darkGrey),
          ),
        );
      }
      
      final itemCount = controller.nearbyPlayers.length;
      
      return ListView.separated(
        controller: controller.scrollController,
        itemCount: itemCount + (controller.hasMore.value ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
        itemBuilder: (_, i) {
          if (i == itemCount) {
            return Obx(() => controller.isLoadingMore.value
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox.shrink());
          }
          
          final player = controller.nearbyPlayers[i];
          final isRequested = player['hasPendingRequest'] ?? false;
          final initials = getInitials(player['name']);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: (player['profilePic']?.isNotEmpty == true)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player['profilePic'],
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            placeholder: (context, url) => Text(
                              initials,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => Text(
                              initials,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Text(
                    initials,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(player['name'] ?? '').toString().capitalizeFirstChar()} ',
                        style: Get.textTheme.headlineMedium!
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 4,horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${formatAmount(player['xpPoints'] ?? 0)} XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            ' • ${player['level'] ?? 'Beginner'}',
                            style: Get.textTheme.bodySmall!
                                .copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryColor),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset(Assets.imagesIcLocation, scale: 3, color: AppColors.blackColor),
                          const SizedBox(width: 4),
                          Text(
                            player['cityName'] ?? '',
                            style: Get.textTheme.bodyLarge!
                                .copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _requestButton(player['hasPendingRequest'] ?? false, player['id'] ?? '', player['preferredTeam'] ?? 'teamA',bookingId),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _requestButton(bool hasPendingRequest, String playerId, String team, String bookingId) {
    return Obx(() {
      final isRequesting = controller.requestingPlayerId.value == playerId;
      final isRequested = hasPendingRequest || controller.requestedPlayerIds.contains(playerId);
      
      return GestureDetector(
        onTap: (isRequested || isRequesting) ? null : () async {
          controller.requestingPlayerId.value = playerId;
          
          // Normalize team name: "Team A" -> "teamA", "Team B" -> "teamB"
          String normalizedTeam = widget.teamName.trim().toLowerCase() == 'team a' ? 'teamA' : 'teamB';
          
          print("=== REQUEST BUTTON TAPPED ===");
          print("bookingType: ${controller.bookingType.value}");
          print("bookingId:-- $bookingId");
          print("playerId: $playerId");
          print("original teamName: ${widget.teamName}");
          print("normalized team: $normalizedTeam");
          
          bool success = false;
          
          if (controller.bookingType.value == 'openMatch') {
            print("Calling requestPlayerForOpenMatch API");
            final addPlayerController = Get.put(AddPlayerController());
            addPlayerController.matchId.value =  widget.openMatchId ?? "";
            addPlayerController.playerId.value = playerId;
            addPlayerController.selectedTeam.value = normalizedTeam;
            success = await addPlayerController.requestPlayerForOpenMatch(type: 'matchCreatorRequest', bookingId: bookingId);
          } else {
            print("Calling requestToJoinBookingModel API");
            final body = {
              "bookingId": bookingId,
              "playerId": playerId,
              "preferredTeam": normalizedTeam,
            };
            print("Request body: $body");
            try {
              final response = await controller.repository.requestToJoinBookingModel(body: body);
              if (response != null) {
                success = true;
              }
            } catch (e) {
              print("Error calling API: $e");
            }
          }
          
          if (success) {
            controller.requestedPlayerIds.add(playerId);
          }
          
          controller.requestingPlayerId.value = '';
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isRequested ? const Color(0xffE9ECF5) : const Color(0xffEEF1FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isRequesting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                )
              : Text(
                  isRequested ? 'Request Sent' : 'Send Request',
                  style: Get.textTheme.bodyLarge!.copyWith(
                    color: isRequested ? Colors.grey : AppColors.primaryColor,fontSize: 10,fontWeight: FontWeight.w800
                  ),
                ),
        ),
      );
    });
  }

  Widget _actionButtons(BuildContext context) {
    final style = Get.textTheme.labelLarge!.copyWith(color: Colors.white);
    return Column(
      children: [
        // OutlinedButton(
        //   onPressed: () {},
        //   style: OutlinedButton.styleFrom(
        //     minimumSize: const Size.fromHeight(45),
        //     side: const BorderSide(color: Colors.green),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(5),
        //     ),
        //   ),
        //   child: Text(
        //     'Invite Player',
        //     style: Get.textTheme.labelLarge!.copyWith(color: AppColors.secondaryColor),
        //   ),
        // ),
        const SizedBox(height: 4),
        // ElevatedButton(
        //   onPressed: () {},
        //   style: ElevatedButton.styleFrom(
        //     minimumSize: const Size.fromHeight(40),
        //     backgroundColor: Colors.green,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //   ),
        //   child: Text('Invite Player through whatsapp', style: style),
        // ),
        // const SizedBox(height: 4),
        if (widget.showAddGuestButton)
          ElevatedButton(
            onPressed: () {
              AddPlayerBottomSheet.show(
                context,
                arguments: {
                  "team": widget.teamName,
                  "matchId": widget.matchId,
                  "needAsGuest": true,
                  "needBookingHistory":true,
                  "scoreBoardId": widget.matchId,
                  "openMatchId": widget.openMatchId ?? "",
                  "bookingId": widget.bookingId
                },
              );
              // Get.toNamed(
              //   RoutesName.addPlayer,
              //   arguments: {
              //     "team": teamName,
              //     "matchId": matchId,
              //     "needAsGuest": true,
              //     "scoreBoardId": matchId,
              //   },
              // );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
              backgroundColor: const Color(0xff2D3EBE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text('Add Guest  →', style: style),
          ),
      ],
    );
  }
  String getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';

    final parts = fullName.trim().split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }
}
