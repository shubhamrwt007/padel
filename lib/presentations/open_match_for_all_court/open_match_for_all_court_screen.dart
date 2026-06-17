import 'dart:developer';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:padel_mobile/configs/components/multiple_gender.dart';
import 'package:padel_mobile/configs/components/safe_scaffold.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/open_match_booking_model.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/presentations/booking/open_matches/addPlayer/add_player_screen.dart';
import 'package:padel_mobile/presentations/wallet/wallet_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../configs/components/safe_bottom_container.dart';
import '../booking/widgets/booking_exports.dart';
import '../notification/notification_controller.dart';
import 'open_match_for_all_court_controller.dart';
class OpenMatchForAllCourtScreen extends StatefulWidget {
  const OpenMatchForAllCourtScreen({super.key});
/////
  @override
  State<OpenMatchForAllCourtScreen> createState() => _OpenMatchForAllCourtScreenState();
}

class _OpenMatchForAllCourtScreenState extends State<OpenMatchForAllCourtScreen> {
  final OpenMatchForAllCourtController controller = Get.put(OpenMatchForAllCourtController());
  final WalletController walletController = Get.put(WalletController());

  final storage = GetStorage();
  final List<bool> _expandedStates = [];

  @override
  Widget build(BuildContext context) {
    walletController.fetchWallet();
    return SafeScaffold(
      bottomNavigationBar: _bottomButton(context),
      appBar: primaryAppBar(
        title: Text("Find a Game"), context: context,centerTitle: true,
        action: [
          GestureDetector(
            onTap: () {
              Get.toNamed(RoutesName.notification);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: AppColors.blackColor,
                    size: 25,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Obx(() {
                    final count = Get.find<NotificationController>().unreadNotificationCount.value;
                    if (count == 0) return const SizedBox.shrink();

                    return Container(
                      height: 16,
                      width: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ).paddingOnly(right: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: ()=>Get.toNamed(RoutesName.wallet),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7,vertical: 3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.textFieldColor
                  // border: Border.all(
                  //   color: AppColors.primaryColor,
                  //   style: BorderStyle.solid, // dotted simulated below
                  //   width: 1.2,
                  // ),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(Assets.imagesIcWallet,height: 20,width: 20,).paddingOnly(right: 4),
                    Obx(() => Text(
                      "${formatWalletAmount(walletController.walletBalance.value ?? 0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primaryColor,
                      ),
                    ))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        onRefresh: () async {
          await controller.fetchMatchesForSelection();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - Get.height * 0.09,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10,),
                  _buildDatePicker(),
                  _buildTimeTabs().paddingOnly(bottom: 10),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return Center(child: ListView.builder(shrinkWrap: true,itemCount: 3,itemBuilder: (context,index){
                        return buildMatchCardShimmer();
                      }));
                    }
                    final matches = controller.matchesBySelection.value;
                    if (matches == null || (matches.data?.isEmpty ?? true)) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_outlined, size: 50, color: AppColors.darkGrey),
                            Text(
                              'No matches available for this time',
                              style: Get.textTheme.labelLarge?.copyWith(color: AppColors.darkGrey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ).paddingOnly(top: Get.height * 0.1),
                      );
                    }
                    // Initialize expanded states if needed
                    if (_expandedStates.length != matches.data!.length) {
                      _expandedStates.clear();
                      _expandedStates.addAll(List.filled(matches.data!.length, false));
                    }

                    return Column(

                      children: matches.data!.asMap().entries.map((entry) =>
                          _buildMatchCardFromData(context, entry.value, entry.key)).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  ///---------------- BOTTOM BUTTON --------------
  Widget _bottomButton(BuildContext context){
    return Container(
      height: Get.height * .09,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomButton(
        width: Get.width * 0.9,
        child: Text(
          "Create a Game",
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: AppColors.whiteColor),
        ).paddingOnly(right: Get.width * 0.14),
        onTap: () {
          Get.toNamed(RoutesName.createOpenMatchForAllCourts, arguments: {
            'selectedDate': controller.selectedDate.value,
          });
        },
      ).paddingOnly(bottom: 0),
    );
  }
  /// --------------- DATE PICKER ---------------
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: Get.width,
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Obx(
                      () => Transform.translate(
                    offset: Offset(0, -19),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Color(0xffF3F3F5),
                            border: Border.all(color: AppColors.blackColor.withAlpha(10)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: DateFormat('MMM')
                                .format(controller.focusedDate.value)
                                .toUpperCase()
                                .split('')
                                .map((char) => Text(
                              char,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ))
                                .toList(),
                          ),
                        ).paddingOnly(right: 5),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (scrollNotification) {
                              if (scrollNotification is ScrollUpdateNotification) {
                                final scrollOffset = scrollNotification.metrics.pixels;
                                final itemExtent = 46.0;
                                final itemsScrolled = (scrollOffset / itemExtent).round();
                                final estimatedDate = DateTime.now().add(Duration(days: itemsScrolled));

                                // Only update focusedDate for month display, not selectedDate
                                controller.focusedDate.value = estimatedDate;
                              }
                              return false;
                            },
                            child: EasyDateTimeLinePicker.itemBuilder(
                              controller: controller.dateTimelineController,
                              headerOptions: HeaderOptions(
                                headerBuilder: (_, context, date) => const SizedBox.shrink(),
                              ),
                              selectionMode: SelectionMode.alwaysFirst(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030, 3, 18),
                              focusedDate: controller.selectedDate.value,
                              itemExtent: 46,
                              itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
                                final dayName = DateFormat('E').format(date);
                                return GestureDetector(
                                  onTap: onTap,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      height: 55,
                                      width: Get.width * 0.11,
                                      key: ValueKey(isSelected),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        gradient: isSelected ? LinearGradient(
                                          colors: [Color(0xff1F41BB), Color(0xff0E1E55)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ) : null,
                                        color: isSelected ? null : Colors.white,
                                        border: Border.all(
                                          color: isSelected ? Colors.transparent : AppColors.blackColor.withAlpha(20),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            date.day.toString(),
                                            style: Get.textTheme.titleMedium!.copyWith(
                                              fontSize: 18,
                                              color: isSelected ? Colors.white : AppColors.textColor,
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(0, -2),
                                            child: Text(
                                              dayName,
                                              style: Get.textTheme.bodySmall!.copyWith(
                                                fontSize: 11,
                                                color: isSelected ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).paddingSymmetric(vertical: 6);
                              },
                              onDateChange: (date) {
                                controller.selectedDate.value = date;
                                controller.focusedDate.value = date; // Sync on selection
                                controller.selectedTime = null;
                                controller.selectedSlots.clear();
                                controller.fetchMatchesForSelection();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Select Date",
                        style: Get.textTheme.labelLarge!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.openDatePicker(context);
                        },
                        child: Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            color: AppColors.textFieldColor,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ).paddingOnly(left: 10)
                    ],
                  ),

                  Obx(() {

                    return ToggleButtons(
                      isSelected: [
                        controller.isMyBooking.value,
                        !controller.isMyBooking.value,
                      ],
                      borderRadius: BorderRadius.circular(5),
                      constraints: const BoxConstraints(minHeight: 25, minWidth: 60),
                      fillColor: AppColors.primaryColor,
                      selectedColor: Colors.white,
                      color: Colors.black,
                      textStyle: TextStyle(fontSize: 12),
                      onPressed: (index) {
                        controller.isMyBooking.value = index == 0;
                        controller.fetchMatchesForSelection();
                      },
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text("My"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text("All"),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  /// ---------------- TIME TABS ----------------
  Widget _buildTimeTabs() {
    return Obx(() {
      final selectedFilter = controller.selectedTimeFilter.value;

      final tabs = [
        {"label": "Morning", "icon": Icons.wb_twilight_sharp, "value": "morning"},
        {"label": "Noon", "icon": Icons.wb_sunny, "value": "afternoon"},
        {"label": "Evening", "icon": Icons.nightlight_round, "value": "evening"},
      ];

      return Theme(
        data: Theme.of(Get.context!).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black26),
              ),
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final value = tab["value"] as String;
                  final isSelected = selectedFilter == value;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.selectedTimeFilter.value = value;
                        controller.fetchMatchesForSelection();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: isSelected ?Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)): Border.all(color: Colors.transparent),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            )
                          ]
                              : [],
                        ),
                        child: Center(
                          child: Icon(
                            tab["icon"] as IconData,
                            size: 20,
                            color: isSelected
                                ? AppColors.primaryColor
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final value = tab["value"] as String;
                final isSelected = selectedFilter == value;

                return Expanded(
                  child: Center(
                    child: Text(
                      tab["label"] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  // Rich card from API data
  Widget _buildMatchCardFromData(BuildContext context, OpenMatchBookingData data, int index) {
    final dayStr = controller.getDay(data.matchDate);
    final dateOnlyStr = controller.getDate(data.matchDate);

    // Get all slot times and format as range
    final slotTimes = data.slot?.expand((slot) =>
    slot.slotTimes?.map((st) => st.time ?? '') ?? <String>[]
    ).where((time) => time.isNotEmpty).toList() ?? [];
    // final timeStr = controller.formatTimeRange(data.matchTime ?? []);
    final timeStr ="${data.bookingId?.startTime?.split(' ').first ?? data.startTime?.split(' ').first??""}-${data.bookingId?.endTime ?? data.endTime??""}";
    final clubName = data.clubId?.clubName ?? '-';

    final locationName = (data.clubId?.locations?.isNotEmpty ?? false)
        ? data.clubId!.locations![0].city?.capitalizeFirstChar() ?? ""
        : "";


    final address = locationName.isNotEmpty ? locationName : "${data.clubId?.city ?? ""} ${data.clubId?.zipCode ?? ""}";

    // Show yourShare if openMatchStatus is pending, otherwise show totalAmount
    final price = data.openMatchStatus == "pending"
        ? "${data.yourShare ?? 0}"
        : "${data.totalAmount ?? 0}";
    // final price = (data.slot?.isNotEmpty == true &&
    //     data.slot!.first.slotTimes?.isNotEmpty == true)
    //     ? '${data.slot!.first.slotTimes!.first.amount ?? ''}'
    //     : '-';
    final pendingRequestsCount = 0; // Update based on your API response

    // TEAM A
    final teamAPlayers = (data.teamA ?? []).take(2).map((p) {
      if (p.isTemp == true) {
        return _buildFilledPlayer(
          "",
          p.name ?? "Temp Player",
          "-",
          index,
          "",
          matchData: data,
        );
      }
      return _buildFilledPlayer(
        p.userId?.profilePic ?? "",
        p.userId?.name ?? "",
        p.userId?.playerLevel?.split(' ').first ?? "-",
        index,
        p.userId?.lastName??"",
        matchData: data,
      );
    }).toList();

    while (teamAPlayers.length < 2) {
      teamAPlayers.add(
        _buildAvailableCircle("teamA", data.bookingId?.sId ?? "", data.skillLevel, index, data),
      );
    }

    // TEAM B
    final teamBPlayers = (data.teamB ?? []).take(2).map((p) {
      if (p.isTemp == true) {
        return _buildFilledPlayer(
          "",
          p.name ?? "Temp Player",
          "-",
          index,
          "",
          matchData: data,
        );
      }
      return _buildFilledPlayer(
        p.userId?.profilePic ?? "",
        p.userId?.name ?? "",
        p.userId?.playerLevel?.split(' ').first ?? "-",
        index,
        p.userId?.lastName??"",
        matchData: data,
      );
    }).toList();

    while (teamBPlayers.length < 2) {
      teamBPlayers.add(
        _buildAvailableCircle("teamB", data.bookingId?.sId ?? "", data.skillLevel, index, data),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: const Color(0xffeaf0ff),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color:Color(0xffC8D6FB)),
          gradient: LinearGradient(
            colors:[Color(0xffF3F7FF), Color(0xff9EBAFF).withValues(alpha: 0.3)],
          )
      ),
      child: Stack(
        children: [
          Align(
              alignment: AlignmentGeometry.centerRight,
              child: SvgPicture.asset(index % 2 == 0?Assets.imagesImgOpenMatchBg:Assets.imagesImgOpenMatchGreenBg,height:_isLoginUserInMatch(data)?160: 150,width: 150,).paddingOnly(right: 20)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔵 TOP SECTION (Day + Date + Time + Level Badge + Arrow)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$dayStr ',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1c46a0),
                                  ),
                                ),
                                TextSpan(
                                  text: '$dateOnlyStr | $timeStr',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          //   decoration: BoxDecoration(
                          //     color: AppColors.secondaryColor,
                          //     borderRadius: BorderRadius.circular(30),
                          //   ),
                          //   child: const Text(
                          //     "A",
                          //     style: TextStyle(color: Colors.white,fontSize: 9),
                          //   ),
                          // ).paddingOnly(left: 5),
                        ],
                      ),
                      // ⭐ Professional | Mixed
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(
                            " ${data.skillLevel?.capitalizeFirst ?? 'Professional'} | ",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          genderIcon(data.gender),
                          const SizedBox(width: 4),
                          Text(
                            data.gender?.capitalizeFirst ?? "Mixed Doubles",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_isLoginUserInMatch(data) && controller.getTotalPlayersCount(data) > 1)
                        GestureDetector(
                            onTap: (){
                              final teamAData = (data.teamA ?? []).map((p) {
                                if (p.isTemp == true) {
                                  return {
                                    'userId': p.tempPlayerId ?? p.sId ?? '',
                                    'name': p.name ?? 'Temp Player',
                                    'lastName': '',
                                  };
                                }
                                return {
                                  'userId': p.userId?.sId ?? '',
                                  'name': p.userId?.name ?? '',
                                  'lastName': p.userId?.lastName ?? '',
                                };
                              }).toList();
                              final teamBData = (data.teamB ?? []).map((p) {
                                if (p.isTemp == true) {
                                  return {
                                    'userId': p.tempPlayerId ?? p.sId ?? '',
                                    'name': p.name ?? 'Temp Player',
                                    'lastName': '',
                                  };
                                }
                                return {
                                  'userId': p.userId?.sId ?? '',
                                  'name': p.userId?.name ?? '',
                                  'lastName': p.userId?.lastName ?? '',
                                };
                              }).toList();

                              Get.toNamed(RoutesName.chat, arguments: {
                                "matchID": data.sId ?? "",
                                "teamA": teamAData,
                                "teamB": teamBData,
                              });
                            },
                            child:Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  // borderRadius: BorderRadius.circular(10),
                                  color:AppColors.primaryColor,
                                ),
                                child:Icon(Icons.chat_outlined, color: Colors.white, size: 18)
                            )
                        ).paddingOnly(right: 10),
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
                          onTap: () {
                            setState(() {
                              _expandedStates[index] = !_expandedStates[index];
                            });
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              _expandedStates.length > index && _expandedStates[index]
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),

              // 🧑‍🧑‍ Players Row
              // Show expanded or collapsed content
              _expandedStates.length > index && _expandedStates[index]
                  ? _expandedCard(context, index, data, teamAPlayers, teamBPlayers, clubName, address, price)
                  : _collapsedCard(context, index, data, teamAPlayers, teamBPlayers, clubName, address, price,pendingRequestsCount),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilledPlayer(String? imageUrl, String name, String level,int index,String lastName, {OpenMatchBookingData? matchData}) {
    final firstLetter = name.trim().isNotEmpty
        ? '${name.trim()[0].toUpperCase()}${lastName.trim().isNotEmpty ? lastName.trim()[0].toUpperCase() : ''}'
        : '?';

    return GestureDetector(
      onTap: (){
        if (matchData != null && (_isLoginUserInMatch(matchData) || _isMatchCreator(matchData))) {
          _showPlayerDetailsDialog(matchData);
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 20,
          backgroundColor:const Color(0xffeaf0ff),
          child: ClipOval(
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Center(
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryColor.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Text(
                  firstLetter,
                  style:  TextStyle(
                    fontSize: 18,
                    color:  AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
                : Center(
              child: Text(
                firstLetter,
                style:  TextStyle(
                  fontSize: 18,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAvailableCircle(String team, String matchId, String? skillLevel, int index, OpenMatchBookingData? match) {
    final isLoginUserInMatch = _isLoginUserInMatch(match);
    final isMatchCreator = _isMatchCreator(match);
    final hasActiveRequest = match?.isRequest == true;
    final isAdminMatch = match?.adminStatus == true;

    return GestureDetector(
      onTap: hasActiveRequest ? null : () async {
        if (isAdminMatch && !isLoginUserInMatch) {
          // Admin match - direct join flow
          print("Match from Admin----------------------");
          await controller.directJoinAdminMatch(match: match, prefferedTeam: team);
        } else if(match?.openMatchStatus == "pending" && !isLoginUserInMatch){
          print("Match from User Per Share----------------------");
          await controller.directJoinAdminMatch(match: match, prefferedTeam: team);
        } else if (isMatchCreator) {
          Get.bottomSheet(AppPlayersBottomSheet(matchId: match?.sId??"", selectedTeam: team,bookingId: match?.bookingId?.sId??"",price: match?.bookingId?.totalAmount/4,), isScrollControlled: true);
        } else if (!isLoginUserInMatch) {
          // Direct API call for login user
          await _requestToJoinMatch(team, match?.sId ?? '', match?.bookingId?.sId ?? '',match?.totalAmount/4);
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: hasActiveRequest ? Colors.grey.withOpacity(0.3) : const Color(0xffeaf0ff),
          child: Icon(
              Icons.add,
              color: hasActiveRequest ? Colors.grey : AppColors.primaryColor
          ),
        ),
      ),
    );
  }

  // Helper method to check if login user is in the match
  bool _isLoginUserInMatch(OpenMatchBookingData? match) {
    final userId = storage.read('userId');
    if (userId == null || match == null) return false;

    // Check in teamA
    for (final player in match.teamA ?? []) {
      if (player.userId?.sId == userId) return true;
    }

    // Check in teamB
    for (final player in match.teamB ?? []) {
      if (player.userId?.sId == userId) return true;
    }

    return false;
  }

  // Helper method to check if login user is the match creator
  bool _isMatchCreator(OpenMatchBookingData? match) {
    final userId = storage.read('userId');
    if (userId == null || match == null) return false;

    // createdBy is a UserId object, so we need to check the sId field
    return match.createdBy?.sId == userId.toString();
  }

  // Direct request to join match for login user
  Future<void> _requestToJoinMatch(String team, String matchId, String bookingId,dynamic price) async {
    final userId = storage.read('userId');
    if (userId == null) return;

    // Find the match data to check isRequest
    final matchData = controller.matchesBySelection.value?.data?.firstWhere(
          (match) => match.sId == matchId,
      orElse: () => OpenMatchBookingData(),
    );

    // Check if there's already an active request
    if (matchData?.isRequest == true) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info,
                  color: Colors.orange,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Request Already Sent',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have already sent a request to join this match. Please wait for the match creator to respond.',
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    try {
      final addPlayerController = Get.put(AddPlayerController());

      // Set required values
      addPlayerController.matchId.value = matchId;
      addPlayerController.selectedTeam.value = team;
      addPlayerController.playerId.value = userId;
      addPlayerController.openMatchForAllCourtController = controller;

      // Call the request API directly
      final success = await addPlayerController.requestPlayerForOpenMatch(bookingId: bookingId,price: price);
      if (success) {


        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Request Sent!',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your request to join the match has been sent successfully.',
                    textAlign: TextAlign.center,
                    style: Get.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

        );
        // Refresh matches without showing loader
        final currentLoading = controller.isLoading.value;
        controller.isLoading.value = false;
        await controller.fetchMatchesForSelection();
        controller.isLoading.value = currentLoading;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error requesting to join match: $e", level: LogLevel.error);
    }
  }

  void _makeCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      try {
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
        final Uri launchUri = Uri.parse('tel:$cleanNumber');
        await launchUrl(launchUri);
      } catch (e) {
        print('Error making call: $e');
      }
    }
  }

  void _showPlayerDetailsDialog(OpenMatchBookingData matchData) {
    final userId = storage.read('userId');
    final hasPlayers = (matchData.teamA ?? []).any((p) => p.isTemp == true || (p.userId?.sId != null && p.userId?.sId != userId && (p.userId?.name?.isNotEmpty ?? false))) ||
        (matchData.teamB ?? []).any((p) => p.isTemp == true || (p.userId?.sId != null && p.userId?.sId != userId && (p.userId?.name?.isNotEmpty ?? false)));

    if (!hasPlayers) return;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Player Information',
                    style: Get.textTheme.titleMedium
                        ?.copyWith(color: AppColors.primaryColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: Get.back,
                  ),
                ],
              ),
              const Divider(thickness: 0.6),
              ..._buildPlayers(matchData.teamA ?? []),
              ..._buildPlayers(matchData.teamB ?? []),
            ],
          ),
        ),
      ),
    );
  }


  List<Widget> _buildPlayers(List<dynamic> players) {
    final userId = storage.read('userId');
    return players.where((p) => p.isTemp == true || p.userId?.sId != userId).map((p) {
      if (p.isTemp == true) {
        final name = p.name ?? 'Temporary Player';
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.secondaryColor,
                radius: 28,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xffeaf0ff),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Get.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Temporary Player',
                          style: Get.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
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

      final name = [
        p.userId?.name,
        p.userId?.lastName,
      ]
          .where((e) => e != null && e!.isNotEmpty)
          .map((e) => e![0].toUpperCase() + e.substring(1).toLowerCase())
          .join(' ');
      final xpPoints = p.userId?.xpPoints;
      final gender = p.userId?.gender ??"";
      final level = p.userId?.level ?? "";

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            /// Avatar with badge
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  radius: 28,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage:
                    (p.userId?.profilePic?.isNotEmpty ?? false)
                        ? CachedNetworkImageProvider(p.userId!.profilePic!)
                        : null,
                    child: (p.userId?.profilePic?.isEmpty ?? true)
                        ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            /// Name + XP + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: Get.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("⭐ ", style: Get.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500),),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4,horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${formatAmount(xpPoints??"")} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        ' | $gender | $level',
                        style: Get.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  void _showRequestsBottomSheet(BuildContext context, String matchId) {
    controller.fetchJoinRequests(matchId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: Get.height * 0.9,
            child: Column(
              children: [
                /// HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Requests',
                        style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,color: AppColors.primaryColor
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),

                Divider(color: Colors.grey.shade300, height: 1),

                /// DESCRIPTION
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "You have new match requests! Accept the requests from the "
                        "players you want to play with. Once accepted, you'll be "
                        "paired for the match and can start competing right away.",
                    style: Get.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 13
                    ),
                  ),
                ),

                /// LIST
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingRequests.value) {
                      return Center(
                        child: LoadingWidget(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }

                    if (controller.joinRequests.isEmpty) {
                      return Center(
                        child: Text(
                          'No join requests yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: controller.joinRequests.length,
                      itemBuilder: (context, index) {
                        final request = controller.joinRequests[index];
                        return _buildRequestItem(request, matchId);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildRequestItem(Map<String, dynamic> request, String matchId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// AVATAR
          (request['profilePic'] != null && request['profilePic'].isNotEmpty)
              ? CachedNetworkImage(
            imageUrl: request['profilePic'],
            imageBuilder: (_, imageProvider) => CircleAvatar(
              radius: 26,
              backgroundImage: imageProvider,
            ),
            placeholder: (_, __) => _initialAvatar(request),
            errorWidget: (_, __, ___) => _initialAvatar(request),
          )
              : _initialAvatar(request),

          const SizedBox(width: 12),

          /// USER INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatName(request['name'], request['lastName']),
                        style: Get.textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (request['isVerified'] == true)
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '⭐ ${request['xp']??"0"} XP Points | ${request['gender'] ?? 'Male'}',
                  style: Get.textTheme.labelSmall!.copyWith(
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),

          /// ACTION BUTTONS
          Row(
            children: [
              // /// REJECT BUTTON
              // Obx(() {
              //   final isRejecting =
              //       controller.rejectingRequestId.value == request['id'];
              //
              //   return GestureDetector(
              //     onTap: isRejecting
              //         ? null
              //         : () => _showRejectConfirmation(request, matchId),
              //     child: Container(
              //       padding:
              //       const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              //       decoration: BoxDecoration(
              //         color: Colors.grey.shade200,
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       child: isRejecting
              //           ? const SizedBox(
              //         width: 18,
              //         height: 18,
              //         child: LoadingWidget(color: Colors.grey),
              //       )
              //           : Text(
              //         'Reject',
              //         style: Get.textTheme.bodyMedium!.copyWith(
              //           color: Colors.grey.shade700,
              //           fontWeight: FontWeight.w500,
              //           fontSize: 14
              //         ),
              //       ),
              //     ),
              //   );
              // }),
              // const SizedBox(width: 8),
              /// ACCEPT BUTTON
              Obx(() {
                final isAccepting =
                    controller.acceptingRequestId.value == request['id'];

                return GestureDetector(
                  onTap: isAccepting
                      ? null
                      : () => _showAcceptConfirmation(request, matchId),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isAccepting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: LoadingWidget(color: Colors.white),
                    )
                        : Text(
                      'Accept',
                      style: Get.textTheme.bodyMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
  Widget _initialAvatar(Map<String, dynamic> request) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Text(
        _getInitialsFromFullName(request['name'], request['lastName']),
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  String _formatName(String name, [String? lastName]) {
    if (name.isEmpty) return '';
    String fullName = name;
    if (lastName != null && lastName.isNotEmpty) {
      fullName = '$name $lastName';
    }
    final parts = fullName.trim().split(' ');
    return parts.map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase()).join(' ');
  }

  String _getInitialsFromFullName(String name, [String? lastName]) {
    if (name.isEmpty) return '';
    String fullName = name;
    if (lastName != null && lastName.isNotEmpty) {
      fullName = '$name $lastName';
    }
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }

  void _showAcceptConfirmation(Map<String, dynamic> request, String matchId) {
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

              // Green check icon
              Container(
                height: 70,
                width: 70,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                'Add ${_formatName(request['name'], request['lastName'])} to your open match? '
                    'You won’t be able to remove him later.',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Accept button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    controller.acceptRequest(request['id'], matchId);
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
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _collapsedCard(BuildContext context, int index, OpenMatchBookingData data, List<Widget> teamAPlayers, List<Widget> teamBPlayers, String clubName, String address, String price, int pendingRequestsCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: (teamAPlayers.length + teamBPlayers.length) * 28 + 28,
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
                    height: 44,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int i = 0; i < teamAPlayers.length; i++)
                          Positioned(
                            left: i * 30,
                            child: teamAPlayers[i],
                          ),
                        for (int i = 0; i < teamBPlayers.length; i++)
                          Positioned(
                            left: (teamAPlayers.length * 30) + (i * 30),
                            child: teamBPlayers[i],
                          ),
                      ],
                    ),
                  ),
                ),
                // if(data.teamA!.isNotEmpty && data.teamB!.isNotEmpty)
                // IconButton(onPressed: (){
                //   if (data != null && (_isLoginUserInMatch(data) || _isMatchCreator(data))) {
                //     _showPlayerDetailsDialog(data);
                //   }
                // }, icon: Icon(Icons.remove_red_eye),color: AppColors.primaryColor,)
              ],
            ),
            if (!_isLoginUserInMatch(data)) const SizedBox.shrink(),
            Row(
              children: [
                if (_isMatchCreator(data)) ...[
                  GestureDetector(
                    onTap: () => _showRequestsBottomSheet(context, data.sId ?? ''),
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const Icon(Icons.notifications, color: AppColors.primaryColor,size: 18,),
                          RichText(
                            text: TextSpan(
                              text: 'Requests ',
                              style: Get.textTheme.labelSmall!.copyWith(decoration: TextDecoration.underline),
                              children: [
                                TextSpan(
                                  text: '(',
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: "$pendingRequestsCount",
                                  style: Get.textTheme.labelSmall!.copyWith(color: AppColors.primaryColor),
                                ),
                                TextSpan(
                                  text: ')',
                                  style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  // const SizedBox(width: 10),
                ],
                // if (_isLoginUserInMatch(data))
                //   const Icon(Icons.share, size: 20,color: AppColors.darkGreyColor,),
              ],
            ),
            // if (_isLoginUserInMatch(data))
            //   Container(
            //     color: Colors.transparent,
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //
            //         Transform.translate(
            //           offset: const Offset(0, -3),
            //           child: GestureDetector(
            //             onTap: () {
            //               // Only allow if user is in the match
            //               if (!_isLoginUserInMatch(data)) {
            //                 return;
            //               }
            //
            //               if (!controller.isCheckingScoreboard.value) {
            //                 if (data.sId != null && data.sId!.isNotEmpty) {
            //                   controller.createScoreBoardForOpenMatch(matchData: data);
            //                 }
            //               }
            //             },
            //             child: Obx(() {
            //               final isLoading = controller.loadingMatchId.value == data.sId;
            //               return Container(
            //                 height: 23,
            //                 width: 55,
            //                 alignment: Alignment.center,
            //                 decoration: BoxDecoration(
            //                   borderRadius: BorderRadius.circular(8),
            //                   color: AppColors.secondaryColor,
            //                 ),
            //                 child: isLoading
            //                     ? LoadingAnimationWidget.waveDots(
            //                   color: AppColors.whiteColor,
            //                   size: 20,
            //                 )
            //                     : Text(
            //                   "Play Now",
            //                   style: Get.textTheme.headlineSmall!
            //                       .copyWith(color: Colors.white, fontSize: 10),
            //                 ),
            //               );
            //             }),
            //           ),
            //         )
            //       ],
            //     ),
            //   ).paddingOnly(bottom: 12),
          ],
        ).paddingOnly(bottom: 10),
        Divider(color: Colors.grey,thickness: 0.1,),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clubName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Transform.translate(
                          offset: Offset(0, -1),
                          child: Image.asset(Assets.imagesIcLocation, scale: 2, color: AppColors.primaryColor)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          address,
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
            Transform.translate(
              offset: Offset(0, 2),
              child: Text(
                "₹ ${formatAmount(price)}",
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

  Widget _expandedCard(BuildContext context, int index, OpenMatchBookingData data, List<Widget> teamAPlayers, List<Widget> teamBPlayers, String clubName, String address, String price) {
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
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Row(
          //       children: [
          //         Icon(Icons.access_time, size: 18),
          //         SizedBox(width: 8),
          //         Text(
          //           "${controller.getDate(data.matchDate)} | ${controller.formatTimeRange(data.matchTime ?? [])}",
          //           style: Get.textTheme.bodySmall,
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.group, size: 18),
              SizedBox(width: 8),
              Text("${(data.teamA?.length ?? 0) + (data.teamB?.length ?? 0)} attendee", style: Get.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: (teamAPlayers.length + teamBPlayers.length) * 28 + 28,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.greyColor),
            ),
            child: SizedBox(
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < teamAPlayers.length; i++)
                    Positioned(
                      left: i * 30,
                      child: teamAPlayers[i],
                    ),
                  for (int i = 0; i < teamBPlayers.length; i++)
                    Positioned(
                      left: (teamAPlayers.length * 30) + (i * 30),
                      child: teamBPlayers[i],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clubName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Transform.translate(
                            offset: Offset(0, -1),
                            child: Image.asset(Assets.imagesIcLocation, scale: 2, color: AppColors.primaryColor)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            address,
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
              Transform.translate(
                offset: Offset(0, 2),
                child: Text(
                  "₹ ${formatAmount(price)}",
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
      ),
    );
  }

}
class AppPlayersBottomSheet extends StatefulWidget {
  final String matchId;
  final String bookingId;
  final String? selectedTeam;
  final dynamic price;
  
  const AppPlayersBottomSheet({
    super.key, 
    required this.matchId, 
    this.selectedTeam,
    required this.bookingId,
    required this.price
  });

  @override
  State<AppPlayersBottomSheet> createState() => _AppPlayersBottomSheetState();
}

class _AppPlayersBottomSheetState extends State<AppPlayersBottomSheet> {
  late final OpenMatchForAllCourtController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OpenMatchForAllCourtController>();
    log("BookingID___> ${widget.bookingId}");
    controller.fetchNearByPlayers(bookingId: widget.bookingId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final maxHeight = screenHeight - topPadding - 60;

    return SafeBottomContainer(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      child: GestureDetector(
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
                  onChanged: (value) => controller.fetchNearByPlayers(search: value, bookingId: widget.bookingId ?? ""),
                  hintStyle: Get.textTheme.headlineSmall!.copyWith(color: AppColors.textColor),
                  suffixIcon: Icon(Icons.search,color: AppColors.textColor),
                  hintText: 'Search by Name / Phone number'
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
                child: _playersList(),
              ),
              const SizedBox(height: 12),
              _actionButtons(context),
              const SizedBox(height: 20),
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
          'Find a player',
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

  Widget _playersList() {
    return Obx(() {
      if (controller.isLoadingNearbyPlayers.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.nearbyPlayers.isEmpty) {
        return Center(
          child: Text(
            'No nearby players found',
            style: Get.textTheme.bodyMedium?.copyWith(color: AppColors.darkGrey),
          ),
        );
      }

      final itemCount = controller.nearbyPlayers.length;

      return ListView.separated(
        controller: controller.nearbyPlayersScrollController,
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
          final isRequested = false;
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
                        style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.primaryColor),
                      ),
                      errorWidget: (context, url, error) => Text(
                        initials,
                        style: const TextStyle(fontWeight: FontWeight.bold,color: AppColors.primaryColor),
                      ),
                    ),
                  )
                      : Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.bold,color: AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),

                /// Name + Level + XP + Matches + City
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (player['name'] ?? '').toString().capitalizeFirstChar(),
                        style: Get.textTheme.labelLarge!
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${player['level'] ?? 'Beginner'} • ',
                            style: Get.textTheme.bodySmall!
                                .copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
                          ),
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
                            ' • ${player['totalMatchesPlayed'] ?? 0} Played',
                            style: Get.textTheme.bodySmall!
                                .copyWith(fontSize: 10, color: Colors.grey),
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

                /// Button
                _requestButton(isRequested, player['id'] ?? '', player['preferredTeam'] ?? 'teamA',player['hasPendingRequest']),
              ],
            ),
          );
        },
      );
    });
  }


  Widget _requestButton(bool sent, String playerId, String team,bool hasPendingRequest) {
    return Obx(() {
      final isRequesting = controller.requestingPlayerId.value == playerId;
      final isRequested =hasPendingRequest || sent || controller.requestedPlayerIds.contains(playerId);

      return GestureDetector(
        onTap: (isRequested || isRequesting) ? null : () async {
          controller.requestingPlayerId.value = playerId;

          final addPlayerController = Get.put(AddPlayerController());
          addPlayerController.matchId.value = widget.matchId;
          addPlayerController.playerId.value = playerId;
          addPlayerController.selectedTeam.value = team;
          addPlayerController.openMatchForAllCourtController = controller;

          final success = await addPlayerController.requestPlayerForOpenMatch(type: 'matchCreatorRequest',bookingId: widget.bookingId);

          if (success) {
            controller.requestedPlayerIds.add(playerId);
          }

          controller.requestingPlayerId.value = '';
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              color: isRequested ? Colors.grey : AppColors.primaryColor,
            ),
          ),
        ),
      );
    });
  }

  void _makeCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      try {
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
        final Uri launchUri = Uri.parse('tel:$cleanNumber');
        await launchUrl(launchUri);
      } catch (e) {
        print('Error making call: $e');
      }
    }
  }

  Widget _actionButtons(BuildContext context) {
    final style =  Get.textTheme.labelLarge!.copyWith(color: Colors.white);
    return Column(
      children: [
        // OutlinedButton(
        //   onPressed: () {},
        //   style: OutlinedButton.styleFrom(
        //     minimumSize: const Size.fromHeight(45), // ↓ height
        //     side: const BorderSide(color: Colors.green),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(5),
        //     ),
        //   ),
        //   child: Text(
        //     'Invite Player',
        //     style: Get.textTheme.labelLarge!.copyWith(color: AppColors.secondaryColor),
        //   ),
        // ).paddingOnly(bottom: 4),
        ElevatedButton(
          onPressed: () {
            AddPlayerBottomSheet.show(
              context,
              arguments: {
                "bookingId": widget.bookingId,
                "team": widget.selectedTeam ?? "teamA",
                "matchId": widget.bookingId,
                "needOpenMatchesForAllCourts": true,
                "matchLevel": "",
                "isLoginUser": false,
                "isMatchCreator": true,
                "matchPrice": widget.price
              },
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(45),
            backgroundColor: const Color(0xff2D3EBE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Text('Add Guest  →',style: style,),
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