import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:padel_mobile/configs/components/custom_button.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../configs/app_colors.dart';
import '../../../configs/components/app_bar.dart';
import '../../../configs/components/snack_bars.dart';
import '../../../generated/assets.dart';
import '../../../handler/logger.dart';
import 'details_page_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailsScreen extends StatelessWidget {
  final DetailsController controller = Get.put(DetailsController(), permanent: true);
  DetailsScreen({super.key});

  bool _shouldShowChatButton() {
    final loggedInUserId = controller.profileController.profileModel.value?.response?.sId;
    
    if (loggedInUserId == null || loggedInUserId.isEmpty) {
      return false;
    }

    bool isUserInTeamA = controller.teamA.any((player) => 
        player['userId'] == loggedInUserId);
    
    bool isUserInTeamB = controller.teamB.any((player) => 
        player['userId'] == loggedInUserId);

    return isUserInTeamA || isUserInTeamB;
  }

  void _handleChatAccess(String matchID) {
    final loggedInUserId = controller.profileController.profileModel.value?.response?.sId;
    
    if (loggedInUserId == null || loggedInUserId.isEmpty) {
      CustomLogger.logMessage(msg: "Please login to access chat", level: LogLevel.error);

      return;
    }

    // Check if logged-in user is in teamA or teamB
    bool isUserInTeamA = controller.teamA.any((player) => 
        player['userId'] == loggedInUserId);
    
    bool isUserInTeamB = controller.teamB.any((player) => 
        player['userId'] == loggedInUserId);

    if (isUserInTeamA || isUserInTeamB) {
      Get.toNamed(RoutesName.chat, arguments: {"matchID": matchID});
    } else {
      CustomLogger.logMessage(msg: "Only match players can access the chat", level: LogLevel.error);

    }
  }
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final matchID = args is Map ? args['matchId'] : null;
    final bool fromOpenMatch =
        args is Map && args['fromOpenMatch'] == true;
    final bool isCompleted =
        args is Map && args['completed'] == true;

    final data = controller.localMatchData;
    List slots = data['slot'];
    log("Slots ${slots.length}");
    return BackgroundContainer(
    imageUrl: (data['clubImage'] is List && (data['clubImage'] as List).isNotEmpty) 
          ? (data['clubImage'] as List).first.toString() 
          : (data['clubImage']?.toString() ?? ""),
      child: PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              controller.handleBackNavigation();
            },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: primaryAppBar(
            systemOverlayStyle: SystemUiOverlayStyle.light,
            titleTextColor: AppColors.whiteColor,
            leadingButtonColor: AppColors.whiteColor,
            title: Text("Details"),
            context: context,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () {
                controller.handleBackNavigation();
                Get.back();
              },
              child: Container(
                color: Colors.transparent,
                height: 30,
                width: 40,
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.whiteColor,
                  size: 22,
                ),
              ),
            ),
            action: [
              appBarAction(
                Colors.white,
                const Icon(Icons.share_outlined, color: Colors.black, size: 18),
                  ()async{
                    await controller.shareLocalMatch(context);
                  }
              ).paddingOnly(right: 10),
            ],
          ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // club + date card
              Container(
                width: Get.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: AppColors.whiteColor,
                  border: Border.all(color: AppColors.blackColor.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: SvgPicture.asset(Assets.imagesIcPadelIcon,height: 30,),
                      title: Text(
                        data['clubName'] ?? "Unknown club",
                        style:
                            Get.textTheme.headlineLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ) ??
                            const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        "${formatMatchDateAt(data['matchDate'] ?? "")} | ${_formatMatchTime(data['matchTime'])}",
                        style: Get.textTheme.displaySmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.darkGreyColor,
                        ) ?? const TextStyle(fontSize: 11),
                      ),
                    ),
                    Center(
                      child: Container(
                        height: 1,
                        width: Get.width * .88,
                        color: AppColors.blackColor.withAlpha(30),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        gameTypeSelector(readOnly: fromOpenMatch),
                        gameDetails(
                          "Game Level",
                          data['skillLevel'] ?? "-",
                          AppColors.blackColor,
                          13,
                            FontWeight.w400
                        ),
                        gameDetails(
                          "Price",
                          "₹ ${formatAmount(data['price'])}",
                          AppColors.primaryColor,
                          16,
                            FontWeight.w600
                        ),
                      ],
                    ).paddingOnly(
                      top: Get.height * 0.01,
                      bottom: Get.height * 0.01,
                    ),
                  ],
                ),
              ).paddingOnly(top: Get.height * 0.03),

              // match type
              Container(
                height: Get.height * .045,
                width: Get.width,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: const Color(0xFFf4f6fc),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blackColor.withAlpha(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Open Match",
                      style: Get.textTheme.bodyLarge,
                    ),
                    fromOpenMatch?
                    Row(
                      children: [
                        SvgPicture.asset(Assets.imagesIcCheckCircle,height: 15,).paddingOnly(right: 5),
                        Text("Court Booked",style: Get.textTheme.bodySmall!.copyWith(fontSize: 10,color: AppColors.secondaryColor),),
                      ],
                    ):SizedBox.shrink()
                  ],
                ).paddingOnly(left: 14,right: 14),
              ).paddingOnly(top: Get.height * .015, bottom: Get.height * .015),

              // game card
              gameCard(
                context: context,
                teamA: controller.teamA,
                teamB: controller.teamB,
              ),
              SizedBox(height:_shouldShowChatButton() && fromOpenMatch && !isCompleted ? null : Get.height * .015,),
              _shouldShowChatButton() && fromOpenMatch && !isCompleted ?
              Align(
                alignment: AlignmentGeometry.center,
                  child: GestureDetector(
                    onTap: () => _handleChatAccess(matchID),
                    child: Container(
                      height: 30,
                      width: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_outlined,color: Colors.white,size: 16,).paddingOnly(right: 4),
                          Text("Chat",style: Get.textTheme.headlineLarge!.copyWith(color: Colors.white,fontSize: 12),)
                        ],
                      ),
                    ),
                  ),
              ).paddingOnly(top: Get.height*0.01,bottom: Get.height*0.01) : SizedBox.shrink(),

              // club info card
              Container(
                width: Get.width,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blackColor.withAlpha(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: Get.height * .1,
                      width: Get.width * .3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withAlpha(10),
                        border: Border.all(
                          color: AppColors.blackColor.withAlpha(10),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: (data['clubImage'] is List && (data['clubImage'] as List).isNotEmpty) 
                              ? (data['clubImage'] as List).first.toString() 
                              : (data['clubImage']?.toString() ?? ""),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            Assets.imagesImgDummy2,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final address = data['address'];
                        final encodedAddress = Uri.encodeComponent(address);
                        final googleMapsUrl =
                            "https://www.google.com/maps/search/?api=1&query=$encodedAddress";

                        if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                          await launchUrl(Uri.parse(googleMapsUrl),
                              mode: LaunchMode.externalApplication);
                        } else {
                          CustomLogger.logMessage(msg: "Could not open maps",level: LogLevel.debug);
                        }
                      },
                      child: Container(
                        color: const Color(0xFFf4f6fc),
                        width: Get.width * .51,
                        height: Get.height * .1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['clubName'] ?? "",
                                  style:
                                      Get.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ) ??
                                      const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                Icon(
                                  Icons.directions,
                                  color: AppColors.secondaryColor,
                                  size: 30,
                                ),
                              ],
                            ).paddingOnly(bottom: 5),
                            Text(
                              maxLines: 3,
                              data['address'] ?? "Unknown address, please update",
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Get.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11,
                                  ) ??
                                  const TextStyle(fontSize: 11),
                            ).paddingOnly(bottom: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).paddingAll(15),
              ),

              information(),

              // Add some bottom padding to prevent content from being hidden behind the bottom bar
              SizedBox(height: Get.height * 0.02),
            ],
          ).paddingAll(16),
        ),
        // Add the bottom bar here (hidden when opened from OpenMatch booking list)
        bottomNavigationBar:
            fromOpenMatch ? null : bottomBar(context, controller),
        ),
      ),
    );
  }

  Widget appBarAction(Color backgroundColor, Widget child,Function()? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: backgroundColor,
          child: child,
        ),
      ),
    );
  }

  Widget gameTypeSelector({required bool readOnly}) {
    final data = controller.localMatchData;
    final currentValue = data['gender'] ?? 'Mixed Doubles';
    
    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Game Type", style: Get.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: Get.height * .01),

          readOnly
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentValue,
                style: Get.textTheme.headlineMedium?.copyWith(
                  color: AppColors.blackColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          )
              : Obx(() => PopupMenuButton<String>(
            offset: const Offset(-20, 30),
            onSelected: (value) {
              controller.gameType.value = value;
            },
            itemBuilder: (context) =>  [
              PopupMenuItem(value: 'Male Only', child: Text('Male Only',style: Get.textTheme.bodyLarge,)),
              PopupMenuItem(value: 'Female Only', child: Text('Female Only',style: Get.textTheme.bodyLarge,)),
              PopupMenuItem(value: 'Mixed Doubles', child: Text('Mixed Doubles',style: Get.textTheme.bodyLarge,)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.gameType.value,
                  style: Get.textTheme.headlineMedium?.copyWith(
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Icon(Icons.arrow_drop_down,
                    color: AppColors.blackColor, size: 18),
              ],
            ),
          )),
        ],
      ),
    );
  }


  Widget gameDetails(
    String title,
    String subtitle,
    Color color,
    double fontSize,
      FontWeight? fontWeight
  ) {
    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Get.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: Get.height * .01),
          Text(
            subtitle,
            style:
                Get.textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight:fontWeight,
                  fontSize: fontSize,
                ) ??
                TextStyle(
                  color: color,
                  fontWeight:fontWeight,
                  fontSize: fontSize,
                ),
          ),
        ],
      ),
    );
  }

  Widget playerCard(String name, bool showSubtitle, String image, String? skillLevel,
      {String? lastName}) {
    // Extract initials (first letter of name + first letter of lastName if available)
    String getInitials(String fullName, String? lastN) {
      if (fullName.trim().isEmpty) {
        // If name is empty, just use the first letter of lastName if available
        return (lastN != null && lastN.trim().isNotEmpty) ? lastN.trim()[0].toUpperCase() : "";
      }

      // Get first letter of the name (handle multi-word names by taking the first part)
      String firstInitial = fullName.trim().split(" ").first[0].toUpperCase();

      // Get first letter of the lastName if provided and not empty
      String lastInitial = "";
      if (lastN != null && lastN.trim().isNotEmpty) {
        lastInitial = lastN.trim().split(" ").first[0].toUpperCase();
      }

      return firstInitial + lastInitial;
    }

    // Calculate initials using both name and lastName
    final initials = getInitials(name, lastName);

    // Get first word of name and lastName for display
    String getFirstWord(String text) {
      if (text.trim().isEmpty) return "";
      return text.trim().split(" ").first;
    }

    String displayName = getFirstWord(name);
    if (lastName != null && lastName.trim().isNotEmpty) {
      String lastNameFirst = getFirstWord(lastName);
      displayName = "$displayName $lastNameFirst";
    }

    // Capitalize display name
    displayName = displayName.split(' ')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '')
        .join(' ');

    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: image.isEmpty ? AppColors.primaryColor.withValues(alpha: .1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color:Colors.transparent),
            ),
            child: image.isNotEmpty
                ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CupertinoActivityIndicator(),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
                : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 90,
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 0),
          showSubtitle && skillLevel != null && skillLevel.isNotEmpty
              ? Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            height: 18,
            width: 35,
            child: Text(
              skillLevel,
              style: Get.textTheme.bodyLarge?.copyWith(
                color: Colors.green,
                fontSize: 10,
              ) ??
                  const TextStyle(color: Colors.green),
            ),
          )
              : const SizedBox(height: 20),
        ],
      ),
    );
  }
  Widget gameCard({
    required BuildContext context,
    required RxList<Map<String, dynamic>> teamA,
    required RxList<Map<String, dynamic>> teamB,
  }) {
    return GetBuilder<DetailsController>(
      builder: (controller) => Container(
        // height: Get.height * .20,
        width: Get.width,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.blackColor.withAlpha(10)),
          color: const Color(0xFFf4f6fc),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Players",
                style: Get.textTheme.headlineLarge?.copyWith(
                  color: AppColors.blackColor,
                ) ?? const TextStyle(color: AppColors.blackColor),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Team A Players
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(2, (index) {
                          bool hasPlayer = index < controller.teamA.length &&
                              controller.teamA[index].isNotEmpty &&
                              (controller.teamA[index]['name'] != null &&
                                  controller.teamA[index]['name'].toString().isNotEmpty);

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index == 0 ? 16 : 0),
                              child: hasPlayer
                                  ? playerCard(
                                      controller.teamA[index]['name'] ?? "Unknown",
                                      true,
                                      controller.teamA[index]['image'] ?? "",
                                      controller.teamA[index]['level'] ?? "",
                                      lastName: controller.teamA[index]['lastName'],
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        final args = Get.arguments;
                                        final bool fromOpenMatch = args is Map && args['fromOpenMatch'] == true;
                                        
                                        if (fromOpenMatch) {
                                          final matchId = args['matchId'];
                                          final isLoginUserInMatch = controller.isLoginUserInMatch();
                                          Get.toNamed(
                                            RoutesName.addPlayer,
                                            arguments: {
                                              "matchId": matchId,
                                              "team": "teamA",
                                              "needBottomAllOpenMatches": true,
                                              "isLoginUser": !isLoginUserInMatch,
                                              "matchLevel": controller.localMatchData['skillLevel'] ?? "-"
                                            },
                                          );
                                        } else {
                                          controller.showDailogue(
                                            context,
                                            index: index,
                                            team: "teamA",
                                          );
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            height: 50,
                                            width: 50,
                                            child: Icon(
                                              CupertinoIcons.add,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Available",
                                            style: Get.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  // Divider
                  Container(
                    height: Get.height * 0.1,
                    width: 1,
                    color: AppColors.blackColor.withAlpha(30),
                  ),
                  SizedBox(width: 10,),
                  // Team B Players
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(2, (index) {
                          bool hasPlayer = index < controller.teamB.length &&
                              controller.teamB[index].isNotEmpty &&
                              (controller.teamB[index]['name'] != null &&
                                  controller.teamB[index]['name'].toString().isNotEmpty);

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index == 0 ? 16 : 0),
                              child: hasPlayer
                                  ? playerCard(
                                      controller.teamB[index]['name'] ?? "Unknown",
                                      true,
                                      controller.teamB[index]['image'] ?? "",
                                      controller.teamB[index]['level'] ?? "",
                                      lastName: controller.teamB[index]['lastName'],
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        final args = Get.arguments;
                                        final bool fromOpenMatch = args is Map && args['fromOpenMatch'] == true;
                                        
                                        if (fromOpenMatch) {
                                          final matchId = args['matchId'];
                                          final isLoginUserInMatch = controller.isLoginUserInMatch();
                                          Get.toNamed(
                                            RoutesName.addPlayer,
                                            arguments: {
                                              "matchId": matchId,
                                              "team": "teamB",
                                              "needBottomAllOpenMatches": true,
                                              "isLoginUser": !isLoginUserInMatch,
                                              "matchLevel": controller.localMatchData['skillLevel'] ?? "-"
                                            },
                                          );
                                        } else {
                                          controller.showDailogue(
                                            context,
                                            index: index,
                                            team: "teamB",
                                          );
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            child: Icon(
                                              CupertinoIcons.add,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Available",
                                            style: Get.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              // SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Team A",
                    style: Get.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ) ?? const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Team B",
                    style: Get.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ) ?? const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ).paddingOnly(left: 15, right: 15, top: 10, bottom: 10),
        ),
      ),
    );
  }
  String _getEndRegistrationTime() {
    final args = Get.arguments;
    final bool fromOpenMatch = args is Map && args['fromOpenMatch'] == true;
    
    String timeString = "";
    
    if (fromOpenMatch) {
      // From open match - use matchTime
      final matchTime = controller.localMatchData['matchTime'];
      if (matchTime is List && matchTime.isNotEmpty) {
        timeString = matchTime.first?.toString() ?? "";
      } else if (matchTime != null) {
        timeString = matchTime.toString();
      }
    } else {
      // From create open match - use slot time
      final slots = controller.localMatchData['slot'] as List?;
      if (slots != null && slots.isNotEmpty) {
        final firstSlot = slots.first;
        timeString = firstSlot.time?.toString() ?? "";
      }
    }
    
    if (timeString.isEmpty) return "Today at 10:00 PM";
    
    try {
      // Normalize time format: "5 pm" -> "5:00 PM"
      timeString = timeString.trim();
      if (!timeString.contains(':')) {
        final parts = timeString.split(' ');
        if (parts.length == 2) {
          timeString = '${parts[0]}:00 ${parts[1].toUpperCase()}';
        }
      }
      
      final format = DateFormat('h:mm a');
      final time = format.parse(timeString);
      final endRegistration = time.subtract(Duration(minutes: 15));
      final formattedTime = format.format(endRegistration);
      return "Today at $formattedTime";
    } catch (e) {
      CustomLogger.logMessage(msg: "Error parsing time: $e",level: LogLevel.error);
    }
    
    return "Today at 10:00 PM";
  }

  Widget information() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Information",
          style:
              Get.textTheme.headlineLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        ListTile(
          leading: SvgPicture.asset(
            Assets.imagesIcMyClub,
            colorFilter: ColorFilter.mode(AppColors.textColor, BlendMode.srcIn),
          ),
          title: Text(
            "Type of Courts",
            style: Get.textTheme.bodyLarge,
          ),
          subtitle: Text(
            controller.localMatchData['courtType'] is List
                ? (controller.localMatchData['courtType'] as List).join(', ')
                : controller.localMatchData['courtType'].toString(),
            style: Get.textTheme.bodyLarge,
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.calendar_month_outlined,
            color: AppColors.textColor,
          ),
          title: Text("End registration", style: Get.textTheme.bodyLarge),
          subtitle: Text(
            _getEndRegistrationTime(),
            style: Get.textTheme.bodyLarge,
          ),
        ),
      ],
    ).paddingOnly(top: Get.height * 0.01);
  }

  Widget bottomBar(BuildContext context, DetailsController controller) {
    final data = controller.localMatchData;

    return Container(
      alignment: Alignment
          .center,
      height: Get.height * .12,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Obx(
            () => CustomButton(
              width: Get.width*0.9,
                child: controller.isProcessing.value?
                LoadingAnimationWidget.waveDots(
                  color: AppColors.whiteColor,
                  size: 45,
                ).paddingOnly(right: 40):
                Row(
                  mainAxisAlignment:MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "₹ ",
                            style: Get.textTheme.titleMedium!.copyWith(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: formatAmount(data['price'] ?? '₹0'),
                            style: Get.textTheme.titleMedium!.copyWith(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ).paddingOnly(
                      right: Get.width * 0.3,
                      left: Get.width * 0.05,
                    ),
                    Text(
                      "Book Now",
                      style: Get.textTheme.headlineMedium!.copyWith(
                        color: AppColors.whiteColor,
                      ),
                    ).paddingOnly(right:70),
                  ],
                ),
                  onTap: () {
                          // Call the new payment method instead of directly creating match
                          controller.initiatePaymentAndCreateMatch();
                    },),
      ).paddingOnly(bottom: Get.height * 0.03),
    );
  }}

class BackgroundContainer extends StatelessWidget {
  final Widget child;
  final String? imageUrl;

  const BackgroundContainer({super.key, required this.child,this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height,
      width: Get.width,
      color: AppColors.whiteColor,
      child: Stack(
        children: [
          Container(
            height: 200,
            width: Get.width,
            decoration: BoxDecoration(color: AppColors.primaryColor),
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  LoadingWidget(color: AppColors.primaryColor),
              errorWidget: (context, url, error) => Icon(Icons.image),
            )
                : Icon(Icons.image),
          ),
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(31, 65, 187, 0.4),
                  Color.fromRGBO(61, 190, 100, 0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

}
String formatMatchDateAt(dynamic dateInput) {
  if (dateInput == null) return "";

  try {
    DateTime date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String && dateInput.isNotEmpty) {
      date = DateTime.parse(dateInput);
    } else {
      return "";
    }

    final day = date.day;
    final suffix = getDaySuffix(day);
    final month = DateFormat("MMM").format(date);
    final year = date.year;
    return "$day$suffix $month $year";
  } catch (e) {
    return "";
  }
}
String getDaySuffix(int day) {
  if (day >= 11 && day <= 13) return "th";
  switch (day % 10) {
    case 1:
      return "st";
    case 2:
      return "nd";
    case 3:
      return "rd";
    default:
      return "th";
  }
}
String _formatMatchTime(dynamic matchTime) {
  if (matchTime is List && matchTime.isNotEmpty) {
    if (matchTime.length == 1) return matchTime.first.toString();
    if (matchTime.length == 2) return "${matchTime.first} - ${matchTime.last}";
    return "${matchTime.first} - ${matchTime.last}";
  }
  if (matchTime is String && matchTime.isNotEmpty) return matchTime;
  return "";
}

