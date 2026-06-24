import '../auth/forgot_password/widgets/forgot_password_exports.dart'; // Ensure AppColors is defined here

class RoundsScreen extends StatelessWidget {
  const RoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: primaryAppBar(
        centerTitle: true,
          titleTextColor: AppColors.whiteColor,
          leadingButtonColor: AppColors.whiteColor,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backGroundColor: AppColors.primaryColor,
          title: Text("Rounds"), context: context),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: const [
          RoundSection(roundTitle: "Round 1"),
          RoundSection(roundTitle: "Round 2"),
          RoundSection(roundTitle: "Round 3"),
        ],
      ),
    );
  }
}

class RoundSection extends StatelessWidget {
  final String roundTitle;

  const RoundSection({super.key, required this.roundTitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Padding only for round title
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
          child: Text(
            roundTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // ✅ No external margin or padding — full-width light blue container
        Container(
          width: Get.width,
          decoration: BoxDecoration(
            color: AppColors.appBlue,
            borderRadius: BorderRadius.circular(0),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              CourtCard(courtName: "Court 1"),
              SizedBox(height: 16),
              CourtCard(courtName: "Court 2"),
            ],
          ),
        ).paddingOnly(top: 10),
        const SizedBox(height: 0),
      ],
    );
  }
}

class CourtCard extends StatelessWidget {
  final String courtName;

  const CourtCard({super.key, required this.courtName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.roundsColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const PlayerSide(player1: "Bessie", player2: "Kathryn"),
          Expanded(
            child: Column(
              children: [
                Text(
                  courtName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "VS",
                  style: TextStyle(

                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const PlayerSide(player1: "Bessie", player2: "Kathryn"),
        ],
      ),
    );
  }
}

class PlayerSide extends StatelessWidget {
  final String player1;
  final String player2;

  const PlayerSide({super.key, required this.player1, required this.player2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(Assets.images.girls.path),
            ),
            Positioned(
              left: 20,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(Assets.images.girl.path),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          "$player1  +  $player2",
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            "16",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
