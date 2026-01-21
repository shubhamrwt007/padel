import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/leaderBoard/widgets/top_tab_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'leader_board_controller.dart';
class LeaderboardScreen extends StatelessWidget {
  final String? buttonType;
  final LeaderboardController controller = Get.put(LeaderboardController());

  LeaderboardScreen({super.key,this.buttonType});

  String _getInitials(String name) {
    return name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase();
  }

  String _formatName(String name) {
    final words = name.split(' ');
    if (words.length <= 1) return name;
    return '${words[0]} ${words[1][0]}.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        appBar: primaryAppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leadingButtonColor: AppColors.whiteColor,
          titleTextColor: AppColors.whiteColor,
          centerTitle: true,
          showLeading: buttonType=="drawer"?true:false,
          title: const Text("Leaderboard"),
          context: context,
          action: [
            Obx(() => Container(
              height: 30,
              width: Get.width*.25,

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedGenderFilter.value,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: AppColors.primaryColor,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All', style: const TextStyle(color: Colors.white,fontSize: 16))),
                    DropdownMenuItem(value: 'Male', child: Text('Male', style: const TextStyle(color: Colors.white,fontSize: 16))),
                    DropdownMenuItem(value: 'Female', child: Text('Female', style: const TextStyle(color: Colors.white,fontSize: 16))),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedGenderFilter.value = value;
                    }
                  },
                ).paddingOnly(left: 5,right: 5),
              ),
            )),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                TopTabBar(),
                const SizedBox(height: 16),
                // Obx(() {
                //   if (controller.selectedCategory.value == 'Tournaments') {
                //     return _buildTournamentFilters();
                //   } else {
                //     return _buildTabBar();
                //   }
                // }),
                const SizedBox(height: 20),

                // ✅ Directly reactive podium
                Obx(() {
                  if (controller.isLoading.value) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: LoadingWidget(color: Colors.white,)),
                    );
                  }
                  
                  final top3 = controller.topThreePlayers;
                  return _buildPodiumSectionFor(top3);
                }),
              ],
            ),

            // ✅ Directly reactive leaderboard sheet
            Obx(() {
              if (controller.isLoading.value) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.48,
                  minChildSize: 0.48,
                  maxChildSize: 1.0,
                  builder: (context, scroll) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                );
              }
              
              final data = controller.leaderboardData;
              return _buildLeaderboardSheet(context, data,buttonType??"");
            }),
          ],
        ),
      ),
    );
  }




  Widget _buildTabBar() {
    return Obx(() {
      final titles = ['All Time', 'Weekly', 'Monthly'];
      return Container(
        width: Get.width,
        padding: const EdgeInsets.all(4),
        margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        decoration: BoxDecoration(
          // color: const Color(0xFF4F6DF6),
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(titles.length, (i) {
            final selected = controller.selectedTab.value == i;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedTab.value = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF0B3BA7) : Colors
                        .transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    titles[i],
                    style: Get.textTheme.headlineSmall!.copyWith(
                      color: selected ? AppColors.whiteColor : AppColors
                          .primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
  Widget _buildTournamentFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
      child: Row(
        children: [
          // 🔍 Location Search Field
          Expanded(
            flex: 3,
            child: Container(
              height: 39, // decrease height here
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        cursorHeight: 15,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Location',
                          hintStyle: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.search,
                      color: Color(0xFF4F6DF6),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🔹 Gender Dropdown
        Expanded(
          flex: 2,
          child: Container(
            height: 39,
            padding: const EdgeInsets.only(left: 10, right: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() {
              return PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: Offset(10, 39),
                onSelected: (value) {
                  controller.selectedGender.value = value;
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'Male', child: Text('Male',style: Get.textTheme.bodyLarge,)),
                  PopupMenuItem(value: 'Female', child: Text('Female',style: Get.textTheme.bodyLarge,)),
                  PopupMenuItem(value: 'Others', child: Text('Others',style: Get.textTheme.bodyLarge,)),
                ],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedGender.value.isEmpty
                          ? "Gender"
                          : controller.selectedGender.value,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                  ],
                ),
              );
            }),
          ),
        ),
          const SizedBox(width: 8),

          // 🔹 Year Dropdown
      Expanded(
        flex: 2,
        child: Container(
          height: 39,
          padding: const EdgeInsets.only(left: 10, right: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Obx(() {
            return PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              offset: Offset(10, 39),
              onSelected: (value) {
                controller.selectedYear.value = value;
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: '2023', child: Text('2023',style: Get.textTheme.bodyLarge,)),
                PopupMenuItem(value: '2024', child: Text('2024',style: Get.textTheme.bodyLarge,)),
                PopupMenuItem(value: '2025', child: Text('2025',style: Get.textTheme.bodyLarge,)),
              ],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedYear.value.isEmpty
                        ? "Year"
                        : controller.selectedYear.value,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                ],
              ),
            );
          }),
        ),
      )
        ],
      ),
    );
  }

  Widget _buildPodiumSectionFor(List<Player> top3) {
    if (top3.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('No data available', style: TextStyle(color: Colors.white))),
      );
    }
    
    if (top3.length < 3) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('Not enough entries for podium', style: TextStyle(color: Colors.white))),
      );
    }

    return SizedBox(
      height: Get.height * 0.47,
      width: Get.width,
      child: Stack(
        children: [
          Transform.scale(
            scale: 1.2,
            child: SvgPicture.asset(
              Assets.imagesImgLeaderBoardBg,
              fit: BoxFit.cover,
            ),
          ).paddingOnly(left: 10, top: 10),
          Center(
            child: Transform.translate(
              offset: Offset(0, 4),
              child: SvgPicture.asset(
                Assets.imagesImgScoreView,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ).paddingOnly(left: 30, right: 30),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(right: Get.width * 0.04),
                    child: _podiumItem(top3[1], 2)),
                Container(
                  margin: EdgeInsets.only(left: Get.width * 0.0),
                  child: _podiumItem(top3[0], 1),
                ),
                Container(
                  margin:
                  EdgeInsets.only(bottom: 30, left: Get.width * 0.04),
                  child: _podiumItem(top3[2], 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _podiumItem(Player player, int position) {
    final heightOffsets = {
      1: Get.height * 0.010,
      2: Get.height * 0.060,
      3: Get.height * 0.090
    }; // 1st highest, 2nd middle, 3rd lowest

    return Padding(
      padding: EdgeInsets.only(top: heightOffsets[position]!),
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: position == 1 ? 37 : 32,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: position == 1 ? 35 : 30,
                    backgroundColor: AppColors.primaryColor,
                    child: player.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: player.imageUrl,
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Text(
                              _getInitials(player.name),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: position == 1 ? 16 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            errorWidget: (context, url, error) => Text(
                              _getInitials(player.name),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: position == 1 ? 16 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            _getInitials(player.name),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: position == 1 ? 16 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (position == 1)
                  Positioned(
                    top: -25,
                    child: Image.asset(
                      Assets.imagesImgCrown,
                      height: 35,
                    ),
                  ),
              ],
            ),

            // 👇 Dynamic name (Player or Club)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Container(
                width: 100,
                color: Colors.transparent,
                child: Text(
                  _formatName(player.name), // ✅ formatted name for overflow
                  textAlign: TextAlign.center,
                  style: Get.textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Score box
            Container(
              height: 16,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.secondaryColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "${player.points} XP", // ✅ dynamic score
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ).paddingOnly(bottom: Get.height * 0.03),

            // Position text (1, 2, 3)
            Text(
              '$position',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
                fontSize: 40,
              ),
            ).paddingOnly(top: 10),
          ],
        ),
      ),
    );
  }


  Widget _buildLeaderboardSheet(BuildContext context, List<Map<String, dynamic>> data, String buttonType) {
    final double minSize = buttonType == "drawer" ? 0.56 : 0.50;
    const double maxSize = 1.0;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final extent = notification.extent;
        final t = ((extent - minSize) / (maxSize - minSize)).clamp(0.0, 1.0);
        controller.isHandleVisible.value = t < 0.98;
        return true;
      },
      child: DraggableScrollableSheet(
        key: ValueKey(controller.selectedCategory.value),
        initialChildSize: minSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        builder: (context, scroll) {
          scroll.addListener(() {
            if (scroll.position.pixels >= scroll.position.maxScrollExtent - 200) {
              controller.loadMoreData();
            }
          });

          return CustomPaint(
            painter: UpwardCurvePainter(),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Positioned.fill(
                    child: Column(
                      children: [
                        const SizedBox(height: 35), // Space for curved top
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scroll,
                            physics: const ClampingScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
                              child: Column(
                                children: [
                                  Obx(() {
                                    if (!controller.showStateFilters.value) return const SizedBox.shrink();
                                    return Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        _buildStateLevelFilters(),
                                      ],
                                    );
                                  }),

                                  if (!controller.isHandleVisible.value) SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xffF9FAFF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 24, child: Text('#', style: Get.textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w700))).paddingOnly(right: 30),
                                        Expanded(child: Text('Player', style: Get.textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w700))),
                                        Text('XP Points', style: Get.textTheme.labelLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w700)).paddingOnly(right: 10),
                                      ],
                                    ),
                                  ),
                                  Obx(() {
                                    if (controller.myRankData.value != null) {
                                      return Column(
                                        children: [
                                          const SizedBox(height: 10),
                                          _buildMyRankCard(controller.myRankData.value!),
                                          const SizedBox(height: 10),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                  Column(
                                    children: [
                                      ...List.generate(
                                        data.length,
                                            (index) => LeaderboardCard(
                                          item: data[index],
                                          index: index,
                                        ),
                                      ),
                                      Obx(() {
                                        if (controller.isLoadingMore.value) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(child: LoadingWidget(color: AppColors.primaryColor)),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                      Obx(() {
                                        if (!controller.hasMoreData.value && data.isNotEmpty) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              'No more data to load',
                                              style: TextStyle(color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Centered dot indicator on top of the curve
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildStateLevelFilters() {
    return Row(
      children: [
        // All Location Dropdown
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.only(left: 12, right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() {
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedCity.value,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  dropdownColor: Colors.white,
                  items: controller.indianCities
                      .map((city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(
                      city,
                      style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.textColor)
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    controller.selectedCity.value = value!;
                  },
                ),
              );
            }),
          ),
        ),

        const SizedBox(width: 10),
        // Search Field
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.textColor),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        filled: true,
                        fillColor: Color(0xFFF7F8FF),
                        hintStyle: Get.textTheme.headlineSmall!.copyWith(color: AppColors.textColor),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 22, color: Colors.grey[300]),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.search, color: AppColors.textColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRankCard(Map<String, dynamic> myRank) {
    return Obx(() {
      final isExpanded = controller.myRankExpanded.value;
      
      return InkWell(
        onTap: () => controller.toggleMyRankExpand(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 25,
                    color: Colors.transparent,
                    child: Text(
                      '${myRank['rank']}',
                      style: Get.textTheme.labelLarge!.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.transparent,
                    width: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${myRank['change'] > 0 ? '+' : ''}${myRank['change']}',
                          style: TextStyle(
                            color: myRank['change'] > 0
                                ? Colors.green
                                : (myRank['change'] < 0 ? Colors.red : Colors.grey),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        if (myRank['change'] > 0)
                          SvgPicture.asset(
                            Assets.imagesIcTreadingUp,
                            height: 14,
                            width: 14,
                          )
                        else if (myRank['change'] < 0)
                          SvgPicture.asset(
                            Assets.imagesIcTradingDown,
                            height: 14,
                            width: 14,
                          ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.primaryColor,
                    child: myRank['image'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: myRank['image'],
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => Text(
                              _getInitials(myRank['name']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            errorWidget: (context, url, error) => Text(
                              _getInitials(myRank['name']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            _getInitials(myRank['name']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${myRank['name']} (You)",
                        style: Get.textTheme.labelLarge!.copyWith(fontSize: 12,fontWeight: FontWeight.w500)
                    ),
                  ),
                  Container(
                    height: 25,
                    width: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${myRank['score']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ).paddingOnly(right: 10),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
              
              // Expandable stats section inside same container
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('${myRank['streak']}', 'Streak'),
                            _buildStat('${myRank['matches']}', 'Matches'),
                            _buildStat('${myRank['wins']}', 'Wins'),
                            _buildStat('${myRank['losses']}', 'Losses'),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryColor)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.black, fontSize: 10)),
      ],
    );
  }

}
class LeaderboardCard extends GetView<LeaderboardController> {
  final Map<String, dynamic> item;
  final int index;

  const LeaderboardCard({super.key, required this.item, required this.index});

  String _getInitials(String name) {
    return name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isExpanded = controller.expandedIndex.value == index;

      return Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => controller.toggleExpand(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          color: Colors.transparent,
                          width: 25,
                          child: Text(
                            '${item['rank']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          color: Colors.transparent,
                          width: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${item['change'] > 0 ? '+' : ''}${item['change']}',
                                style: TextStyle(
                                  color: item['change'] > 0
                                      ? Colors.green
                                      : (item['change'] < 0 ? Colors.red : Colors.grey),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 3),
                              if (item['change'] > 0)
                                SvgPicture.asset(
                                  Assets.imagesIcTreadingUp,
                                  height: 14,
                                  width: 14,
                                )
                              else if (item['change'] < 0)
                                SvgPicture.asset(
                                  Assets.imagesIcTradingDown,
                                  height: 14,
                                  width: 14,
                                ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primaryColor,
                          child: item['image'].toString().isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item['image'],
                                  imageBuilder: (context, imageProvider) => Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  placeholder: (context, url) => Text(
                                    _getInitials(item['name']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Text(
                                    _getInitials(item['name']),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Text(
                                  _getInitials(item['name']),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ).paddingOnly(right: 10),
                        Container(
                          color: Colors.transparent,
                          width: 70,
                          child: Text(
                            item['name'],
                            style: Get.textTheme.labelLarge!.copyWith(fontSize: 12,fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 25,
                          width: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${item['score']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ).paddingOnly(right: 10),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            //
            // // 👇 Add divider line below the row (always visible)
            // Container(
            //   height: 1,
            //   color: Colors.grey.withValues(alpha: 0.2),
            //   margin: const EdgeInsets.symmetric(horizontal: 8),
            // ),

            // 👇 Smooth expand animation
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('${item['streak']}', 'Streak'),
                      _buildStat('${item['matches']}', 'Matches'),
                      _buildStat('${item['wins']}', 'Wins'),
                      _buildStat('${item['losses']}', 'Losses'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: AppColors.primaryColor)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.black, fontSize: 10)),
      ],
    );
  }
}
// Custom painter for upward arch/curve
class UpwardCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();

    // Starting point - bottom left
    path.moveTo(0, size.height);

    // Left edge going up to where rounded corner starts
    path.lineTo(0, 30);

    // Top-left rounded corner (radius ~30)
    path.quadraticBezierTo(
      0, 0,           // Control point for corner
      30, 0,          // End point of corner
    );

    // Straight line to where upward curve starts
    path.lineTo(size.width * 0.42, 0);

    // Left side of upward peak - curve going UP
    path.quadraticBezierTo(
      size.width * 0.46, 0,       // Control point at top edge
      size.width * 0.48, -10,     // Going UP (negative Y)
    );

    // Peak point - highest point of the curve (center)
    path.quadraticBezierTo(
      size.width * 0.5, -18,      // Highest peak point (negative Y means UP)
      size.width * 0.52, -10,     // Coming back down
    );

    // Right side of upward peak - curve coming back to edge
    path.quadraticBezierTo(
      size.width * 0.54, 0,       // Control point at top edge
      size.width * 0.58, 0,       // Back to top edge
    );

    // Straight line to top-right corner
    path.lineTo(size.width - 30, 0);

    // Top-right rounded corner (radius ~30)
    path.quadraticBezierTo(
      size.width, 0,         // Control point for corner
      size.width, 30,        // End point of corner
    );

    // Right edge going down
    path.lineTo(size.width, size.height);

    // Bottom edge
    path.lineTo(0, size.height);

    path.close();

    // Draw the path
    canvas.drawPath(path, paint);

    // Add subtle shadow for depth
    final shadowPath = Path.from(path);
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.1), 3, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}