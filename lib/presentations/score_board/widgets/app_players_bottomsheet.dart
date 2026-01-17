import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/primary_text_feild.dart';
import 'package:padel_mobile/configs/components/snack_bars.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_controller.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_screen.dart';

import '../../../repositories/openmatches/open_match_repository.dart';

class AppPlayersController extends GetxController {
  RxList<Map<String, dynamic>> nearbyPlayers = <Map<String, dynamic>>[].obs;
  RxBool isLoadingNearbyPlayers = false.obs;
  RxString requestingPlayerId = ''.obs;
  RxList<String> requestedPlayerIds = <String>[].obs;
  final OpenMatchRepository repository = OpenMatchRepository();
  RxString bookingType = ''.obs;

  Future<void> fetchNearByPlayers({String search = ''}) async {
    try {
      isLoadingNearbyPlayers.value = true;
      nearbyPlayers.clear();
      
      final response = await repository.findNearByPlayer(search: search);
      if(response.status == 200 && response.players != null){
        nearbyPlayers.value = response.players!.map((player) => {
          'id': player.id ?? '',
          'name': player.name ?? '',
          // 'lastName': player.lastName ?? '',
          'profilePic': player.profilePic ?? '',
          'city': player.city ?? '',
          'level': player.level ?? '',
          // 'preferredTeam': player.preferredTeam ?? 'teamA',
        }).toList();
      }
    } catch (e) {
      isLoadingNearbyPlayers.value = false;
    } finally {
      isLoadingNearbyPlayers.value = false;
    }
  }
}

class AppPlayersBottomSheetScore extends StatelessWidget {
  final String matchId;
  final String teamName;
  final String? openMatchId;
  final String? bookingId;
  final String? bookingType;
  final List<String>? currentPlayerIds;
  
  AppPlayersBottomSheetScore({super.key, required this.matchId, required this.teamName, this.openMatchId, this.bookingId, this.bookingType, this.currentPlayerIds});
  
  final AppPlayersController controller = Get.put(AppPlayersController());

  @override
  Widget build(BuildContext context) {
    print("AppPlayersBottomSheetScore - matchId: $matchId, openMatchId: $openMatchId, bookingId: $bookingId, bookingType: $bookingType");
    controller.bookingType.value = bookingType ?? '';
    controller.fetchNearByPlayers();
    
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = screenHeight - topPadding - keyboardHeight - 60;
    
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              PrimaryTextField(
                onChanged: (value) => controller.fetchNearByPlayers(search: value),
                hintStyle: Get.textTheme.headlineSmall!.copyWith(color: AppColors.textColor),
                suffixIcon: Icon(Icons.search, color: AppColors.textColor),
                hintText: 'Search by Name / Phone number',
              ),
              const SizedBox(height: 8),
              Text(
                'Nearby & match your level',
                style: Get.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              _playersList(bookingId??""),
              const SizedBox(height: 12),
              _actionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'App Players',
          style: Get.textTheme.headlineMedium,
        ),
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
        return const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      
      if (controller.nearbyPlayers.isEmpty) {
        return SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'No nearby players found',
              style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.darkGrey),
            ),
          ),
        );
      }
      
      final itemCount = controller.nearbyPlayers.length;
      final displayCount = itemCount > 5 ? 5 : itemCount;
      final itemHeight = 60.0;
      final listHeight = displayCount * itemHeight + (displayCount - 1) * 1;
      
      return SizedBox(
        height: listHeight,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: itemCount,
          separatorBuilder: (_, __) => Divider(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
          itemBuilder: (_, i) {
            final player = controller.nearbyPlayers[i];
            final isRequested = false;
            final isAlreadyInMatch = currentPlayerIds?.contains(player['id']) ?? false;

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
                                '${player['name']?[0] ?? ''}${player['lastName']?[0] ?? ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              errorWidget: (context, url, error) => Text(
                                '${player['name']?[0] ?? ''}${player['lastName']?[0] ?? ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            '${player['name']?[0] ?? ''}${player['lastName']?[0] ?? ''}',
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
                          '${(player['name'] ?? '').toString().capitalizeFirst} '
                              '${(player['lastName'] ?? '').toString().capitalizeFirst}',
                          style: Get.textTheme.labelLarge!
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player['city'] ?? '',
                          style: Get.textTheme.bodyLarge!
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _requestButton(isRequested, player['id'] ?? '', player['preferredTeam'] ?? 'teamA',bookingId, isAlreadyInMatch),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _requestButton(bool sent, String playerId, String team, String bookingId, bool isAlreadyInMatch) {
    return Obx(() {
      final isRequesting = controller.requestingPlayerId.value == playerId;
      final isRequested = sent || controller.requestedPlayerIds.contains(playerId);
      
      return GestureDetector(
        onTap: (isRequested || isRequesting || isAlreadyInMatch) ? null : () async {
          controller.requestingPlayerId.value = playerId;
          
          print("=== REQUEST BUTTON TAPPED ===");
          print("bookingType: ${controller.bookingType.value}");
          print("bookingId: $bookingId");
          print("playerId: $playerId");
          print("team: $team");
          
          bool success = false;
          
          if (controller.bookingType.value == 'openMatch') {
            print("Calling requestPlayerForOpenMatch API");
            final addPlayerController = Get.put(AddPlayerController());
            addPlayerController.matchId.value = (openMatchId?.isEmpty ?? true) ? matchId : openMatchId!;
            addPlayerController.playerId.value = playerId;
            addPlayerController.selectedTeam.value = team;
            success = await addPlayerController.requestPlayerForOpenMatch(type: 'matchCreatorRequest', bookingId: bookingId);
          } else {
            print("Calling requestToJoinBookingModel API");
            final body = {
              "bookingId": bookingId,
              "playerId": playerId,
              "preferredTeam": team,
            };
            print("Request body: $body");
            try {
              final response = await controller.repository.requestToJoinBookingModel(body: body);
              if (response != null) {
                // SnackBarUtils.showSuccessSnackBar("Player request sent successfully");
                success = true;
              }
            } catch (e) {
              print("Error calling API: $e");
              // SnackBarUtils.showErrorSnackBar("Failed to send request");
            }
          }
          
          if (success) {
            controller.requestedPlayerIds.add(playerId);
          }
          
          controller.requestingPlayerId.value = '';
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAlreadyInMatch ? const Color(0xffE9ECF5) : (isRequested ? const Color(0xffE9ECF5) : const Color(0xffEEF1FF)),
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
                  isAlreadyInMatch ? 'Already Added' : (isRequested ? 'Request Sent' : 'Send Request'),
                  style: Get.textTheme.bodyLarge!.copyWith(
                    color: (isAlreadyInMatch || isRequested) ? Colors.grey : AppColors.primaryColor,
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
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            side: const BorderSide(color: Colors.green),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Invite Player',
            style: Get.textTheme.labelLarge!.copyWith(color: AppColors.secondaryColor),
          ),
        ),
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
        ElevatedButton(
          onPressed: () {
            AddPlayerBottomSheet.show(
              context,
              arguments: {
                "team": teamName,
                "matchId": matchId,
                "needAsGuest": true,
                "scoreBoardId": matchId,
                "openMatchId": openMatchId ?? "",
                "bookingId": bookingId
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
            minimumSize: const Size.fromHeight(40),
            backgroundColor: const Color(0xff2D3EBE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Add Guest  →', style: style),
        ),
      ],
    );
  }
}