import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/presentations/tournaments/fip_promises/fip_promises_controller.dart';
class FipPromisesScreen extends StatelessWidget {
  final FipPromisesController controller =Get.put(FipPromisesController());
  FipPromisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
     ()=> Scaffold(
       backgroundColor: controller.selectedTab.value == 1
           ? AppColors.primaryColor  // dark blue for leaderboard
           : Colors.white,
       appBar: primaryAppBar(
         systemOverlayStyle: controller.selectedTab.value == 1? SystemUiOverlayStyle.light:SystemUiOverlayStyle.dark,
         leadingButtonColor: controller.selectedTab.value == 1
       ? Colors.white
           : Colors.black,
           titleTextColor: controller.selectedTab.value == 1
       ? Colors.white
           : Colors.black,
           title: Text("FIP Promises"),centerTitle: true, context: context,
        action: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xffE3E8F8),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.list, size: 20,color: Color(0xff2E4DB7)),
          )
        ]
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            // In your body Column, where you show the tab content:
            Expanded(
              child: controller.selectedTab.value == 0
                  ? _liveMatchContent().paddingOnly(top: 20)   // your existing live match UI
                  : const LeaderBoardWidget().paddingOnly(top: 20),  // new leaderboard
            ),
          ],
        ),
      ),
    );
  }
  Widget _liveMatchContent(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _liveMatchCard(),
        Text(
            "Upcoming  Matches",
            style: Get.textTheme.headlineMedium
        ).paddingOnly(left: 16,top: 10,bottom: 10),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context,index){
              return UpcomingMatchCard();
            },
          ),
        ),
      ],
    );
  }
  /// TAB SELECTOR
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.creamColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow:  [
          BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0.3,
              offset: Offset(0, 6))
        ],
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
      ),
      child: Obx(() => Row(
        children: [
          // Padel Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 0,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: controller.selectedTab.value == 0
                    ? AppColors.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: controller.selectedTab.value == 0
                    ? Border.all(
                  color: const Color(0xFF3B5BDB),
                  width: 1.5,
                )
                    : null,
                boxShadow: controller.selectedTab.value == 0
                    ? [
                  BoxShadow(
                    color: const Color(0xFF3B5BDB).withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: -1,
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SvgPicture.asset(
                  //   Assets.images.icPadel.path,
                  //   height: 18, // Add this line - adjust value as needed
                  //   color: controller.selectedSportTab.value == 0
                  //       ? const Color(0xFF3B5BDB)
                  //       : const Color(0xFF252525),
                  // ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      color: controller.selectedTab.value == 0
                          ?Colors.white
                          : const Color(0xFF252525),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: const Text('Live Match'),
                  ),
                ],
              ),
            ),
            ),
          ),

          // Pickleball Tab
          Expanded(
            child: GestureDetector(
              onTap: () => controller.selectedTab.value = 1,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: controller.selectedTab.value == 1
                    ? AppColors.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: controller.selectedTab.value == 1
                    ? [
                  BoxShadow(
                    color: const Color(0xFF3B5BDB).withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: -1,
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      color: controller.selectedTab.value == 1
                          ? Colors.white
                          : const Color(0xFF252525),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: const Text('Leader Board'),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      )),
    );
  }
  Widget _liveMatchCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 0),
          decoration:  BoxDecoration(
            // gradient: LinearGradient(
            //   colors: [
            //     Color(0xff1f41bb).withValues(alpha: 0.2),
            //     Colors.white,
            //     Colors.white.withValues(alpha: 0.5),
            //     Color(0xff3dbe64).withValues(alpha: 0.2),
            //   ],
            // ),
          ),
          child: Stack(
            children: [
              SvgPicture.asset(Assets.images.fipPromesisBg.path,fit: BoxFit.cover,width: Get.width,),
              Column(
                children: [
                  /// LIVE TAG
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFCD3529),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "LIVE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ).paddingOnly(top: 10),
                  /// SCORE ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _teamColumn("A1",
                          "https://i.pravatar.cc/150?img=1",
                          "https://i.pravatar.cc/150?img=2",
                        "Eleanor Pena",
                        "Kristin Watson",
                          AppColors.primaryColor,),

                      Transform.translate(
                        offset: Offset(0, 8),
                        child: Text(
                          "2 : 0",
                          style: Get.textTheme.titleLarge!.copyWith(color: AppColors.blackColor,fontSize: 42)),
                        ),
                      _teamColumn("A2",
                          "https://i.pravatar.cc/150?img=3",
                          "https://i.pravatar.cc/150?img=4",
                          "Theresa Webb",
                          "Ronald Richards",
                          AppColors.secondaryColor),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// WATCH LIVE BUTTON
        GestureDetector(
          onTap: (){
            Get.toNamed(RoutesName.liveTournament);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xff27AE60),
                borderRadius:
                BorderRadius.circular(30)),
            child:  Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.primaryColor,
                  child: Icon(Icons.play_arrow,
                      color: Colors.white, size: 18),
                ),
                SizedBox(width: 8),
                Text("Watch Live",
                    style: Get.textTheme.labelMedium!.copyWith(color: Colors.white,fontWeight: FontWeight.w500))
              ],
            ),
          ),
        ),

        // /// INDICATORS
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     _dot(true),
        //     _dot(false),
        //     _dot(false),
        //   ],
        // )
      ],
    );
  }

  Widget _teamColumn(
      String team,
      String img1,
      String img2,
      String name1,
      String name2,
      Color color,
      ) {
    return SizedBox(
      width: 130,
      child: Column(
        children: [
          /// TEAM LABEL
          Text(
            team,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 15),

          /// STACKED AVATARS
          SizedBox(
            height: 40,
            width: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _avatar(img1, 0),
                _avatar(img2, 24),
              ],
            ),
          ),


          /// NAMES
          Text(
            "$name1 &\n$name2",
            textAlign: TextAlign.center,
            style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }
  Widget _avatar(String url, double left) {
    return Positioned(
      left: left,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class UpcomingMatchCard extends StatelessWidget {
  const UpcomingMatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [

          /// MAIN Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Color(0xffF2F4F9),
                  Color(0xffDCE4F7),
                ],
              ),
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
                /// DATE + UPCOMING
                Row(
                  children: [
                    Text(
                      "05Jun, 2025",
                      style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600,color: Colors.black)
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(30),
                      ),
                      child: Text(
                        "Upcoming",
                          style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: AppColors.primaryColor)
                      ),
                    )
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Eleanor Pena &\nKristin Watson",
                          style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)
                      ),
                    ),
                    Text(
                      "A1",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E4DB7),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "vs",
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "A2",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E4DB7),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Theresa Webb &\nRonald Richards",
                        textAlign: TextAlign.right,
                        style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500)
                      ),
                    ),
                  ],
                )
              ],
            ).paddingOnly(top: 10,left: 20,bottom: 10,right: 20),
            ],
            ),
          ),
/// BLUE COURT TAB (fills notch)
          Container(
            height: 30,
            width: 100,
            decoration: const BoxDecoration(
              color: Color(0xff2E4DB7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              "Court 1",
              style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500,color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }
}
class CourtCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double cornerRadius = 28;
    const double notchWidth = 200;
    const double notchDepth = 40;

    final double center = size.width / 2;
    final double notchStart = center - notchWidth / 2;
    final double notchEnd = center + notchWidth / 2;

    Path path = Path();

    /// Top Left Corner
    path.moveTo(cornerRadius, 0);
    path.quadraticBezierTo(0, 0, 0, cornerRadius);

    /// Left Side
    path.lineTo(0, size.height - cornerRadius);
    path.quadraticBezierTo(
        0, size.height, cornerRadius, size.height);

    /// Bottom
    path.lineTo(size.width - cornerRadius, size.height);
    path.quadraticBezierTo(size.width, size.height,
        size.width, size.height - cornerRadius);

    /// Right Side
    path.lineTo(size.width, cornerRadius);
    path.quadraticBezierTo(
        size.width, 0, size.width - cornerRadius, 0);

    /// Move to start of notch
    path.lineTo(notchEnd, 0);

    /// Smooth inward concave curve
    path.cubicTo(
      notchEnd - 20, 0,
      center + 40, notchDepth,
      center, notchDepth,
    );

    path.cubicTo(
      center - 40, notchDepth,
      notchStart + 20, 0,
      notchStart, 0,
    );

    /// Continue top edge
    path.lineTo(cornerRadius, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
/// ─────────────────────────────────────────────
///  MODEL
/// ─────────────────────────────────────────────
class LeaderBoardEntry {
  final int rank;
  final String player1Name;
  final String player2Name;
  final String player1Avatar;
  final String player2Avatar;
  final String wlt;      // e.g. "8-2-1"
  final String diff;     // e.g. "+12"
  final int points;

  const LeaderBoardEntry({
    required this.rank,
    required this.player1Name,
    required this.player2Name,
    required this.player1Avatar,
    required this.player2Avatar,
    required this.wlt,
    required this.diff,
    required this.points,
  });
}

/// ─────────────────────────────────────────────
///  DUMMY DATA
/// ─────────────────────────────────────────────
const _entries = [
  LeaderBoardEntry(
    rank: 1,
    player1Name: 'Annette Black',
    player2Name: 'Ronald Richards',
    player1Avatar: 'https://i.pravatar.cc/150?img=5',
    player2Avatar: 'https://i.pravatar.cc/150?img=6',
    wlt: '8-2-1',
    diff: '+12',
    points: 56,
  ),
  LeaderBoardEntry(
    rank: 2,
    player1Name: 'Courtney Henry',
    player2Name: 'Kristin Watson',
    player1Avatar: 'https://i.pravatar.cc/150?img=7',
    player2Avatar: 'https://i.pravatar.cc/150?img=8',
    wlt: '8-2-1',
    diff: '+12',
    points: 56,
  ),
  LeaderBoardEntry(
    rank: 3,
    player1Name: 'Devon Lane',
    player2Name: 'Albert Flores',
    player1Avatar: 'https://i.pravatar.cc/150?img=9',
    player2Avatar: 'https://i.pravatar.cc/150?img=10',
    wlt: '8-2-1',
    diff: '+12',
    points: 56,
  ),
  LeaderBoardEntry(
    rank: 4,
    player1Name: 'Floyd Miles',
    player2Name: 'Guy Hawkins',
    player1Avatar: 'https://i.pravatar.cc/150?img=11',
    player2Avatar: 'https://i.pravatar.cc/150?img=12',
    wlt: '8-2-1',
    diff: '+12',
    points: 56,
  ),
  LeaderBoardEntry(
    rank: 5,
    player1Name: 'Jenny Wilson',
    player2Name: 'Jacob Jones',
    player1Avatar: 'https://i.pravatar.cc/150?img=13',
    player2Avatar: 'https://i.pravatar.cc/150?img=14',
    wlt: '7-3-1',
    diff: '+8',
    points: 50,
  ),
];

/// ─────────────────────────────────────────────
///  TOP 3 PODIUM DATA (same entries reused)
/// ─────────────────────────────────────────────
const _top3 = [
  // index 0 → rank 2  (left)
  _LeaderPodiumData(
    rank: 2,
    name: 'Rameha Kumar',
    avatar1: 'https://i.pravatar.cc/150?img=20',
    avatar2: 'https://i.pravatar.cc/150?img=21',
    points: 90,
    isFirst: false,
  ),
  // index 1 → rank 1  (center)
  _LeaderPodiumData(
    rank: 1,
    name: 'Anubhav Kumar',
    avatar1: 'https://i.pravatar.cc/150?img=22',
    avatar2: 'https://i.pravatar.cc/150?img=23',
    points: 122,
    isFirst: true,
  ),
  // index 2 → rank 3  (right)
  _LeaderPodiumData(
    rank: 3,
    name: 'Varunab Dube',
    avatar1: 'https://i.pravatar.cc/150?img=24',
    avatar2: 'https://i.pravatar.cc/150?img=25',
    points: 80,
    isFirst: false,
  ),
];

class _LeaderPodiumData {
  final int rank;
  final String name;
  final String avatar1;
  final String avatar2;
  final int points;
  final bool isFirst;

  const _LeaderPodiumData({
    required this.rank,
    required this.name,
    required this.avatar1,
    required this.avatar2,
    required this.points,
    required this.isFirst,
  });
}

/// ─────────────────────────────────────────────
///  MAIN WIDGET
/// ─────────────────────────────────────────────
class LeaderBoardWidget extends StatelessWidget {
  const LeaderBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ── TOP BLUE SECTION ──────────────────
        _TopPodiumSection(),

        /// ── WHITE LIST SECTION ────────────────
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                /// Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text('#',
                            style: Get.textTheme.bodySmall!
                                .copyWith(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Text('Player',
                            style: Get.textTheme.bodySmall!
                                .copyWith(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      _headerCell('W-L-T'),
                      _headerCell('Diff'),
                      _headerCell('Points'),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xffF0F0F0)),

                /// List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) =>
                        _LeaderBoardRow(entry: _entries[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return SizedBox(
      width: 52,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Get.textTheme.bodySmall!
            .copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  TOP PODIUM (blue background section)
/// ─────────────────────────────────────────────
class _TopPodiumSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 0, bottom: 30),
      color: AppColors.primaryColor, // deep blue
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(Assets.images.imgTournamentLeaderboard.path, fit: BoxFit.contain),
          ),
          Padding(
            padding: EdgeInsets.only(top: 0,left: 20,right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _PodiumItem(data: _top3[0]), // rank 2
                _PodiumItem(data: _top3[1]), // rank 1 (center / tallest)
                _PodiumItem(data: _top3[2]), // rank 3
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final _LeaderPodiumData data;
  const _PodiumItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final double avatarSize = data.isFirst ? 80.0 : 64.0;
    final double circleBackground = data.isFirst ? 100.0 : 84.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Rank number (with up arrow) — hidden for first place
        if (!data.isFirst)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${data.rank}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_drop_up,
                  color: Color(0xff27AE60), size: 30),
            ],
          ),

        /// Avatar circle with glow
        Stack(
          alignment: Alignment.center,
          children: [
            /// Glow circle background
            Container(
              width: circleBackground,
              height: circleBackground,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:Colors.transparent,
              ),
            ),

            /// Stacked avatars
            SizedBox(
              width: avatarSize,
              height: avatarSize * 0.6,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _circleAvatar(data.avatar1, avatarSize * 0.69, 0),
                  _circleAvatar(
                      data.avatar2, avatarSize * 0.69, avatarSize * 0.3),
                ],
              ),
            ),

            /// Crown for rank 1
            if (data.isFirst)
              Positioned(
                top: -5,
                child: Text('👑', style: TextStyle(fontSize: 26)),
              ),
          ],
        ),

        const SizedBox(height: 25),

        /// Name
        Text(
          data.name,
          style: Get.textTheme.labelLarge!.copyWith(color: Colors.white,fontSize: data.isFirst ? 14 : 12,)
        ),

        const SizedBox(height: 6),

        /// Points badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xff27AE60),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '${data.points}',
            style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500,color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _circleAvatar(String url, double size, double left) {
    return Positioned(
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
///  LEADERBOARD ROW
/// ─────────────────────────────────────────────
class _LeaderBoardRow extends StatelessWidget {
  final LeaderBoardEntry entry;
  const _LeaderBoardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF8F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffEEF0F8), width: 1),
      ),
      child: Row(
        children: [
          /// Rank
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              style: Get.textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

          const SizedBox(width: 8),

          /// Stacked avatars
          SizedBox(
            width: 48,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _miniAvatar(entry.player1Avatar, 0),
                _miniAvatar(entry.player2Avatar, 20),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// Names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.player1Name,
                  style: Get.textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(
                  entry.player2Name,
                  style: Get.textTheme.bodySmall!
                      .copyWith(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),

          /// W-L-T
          SizedBox(
            width: 52,
            child: Text(
              entry.wlt,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodySmall!
                  .copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ),

          /// Diff
          SizedBox(
            width: 36,
            child: Text(
              entry.diff,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodySmall!.copyWith(
                  color: const Color(0xff27AE60), fontWeight: FontWeight.w600),
            ),
          ),

          /// Points badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff27AE60),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.points}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniAvatar(String url, double left) {
    return Positioned(
      left: left,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}