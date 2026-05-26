import 'package:flutter/cupertino.dart';
import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';

class AmericanoScreen extends StatelessWidget {
  final String? buttonType;
  final AmericanoController controller = Get.put(AmericanoController());

  AmericanoScreen({super.key, this.buttonType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: primaryAppBar(title: Text("Americano"), centerTitle: true,context: context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: Get.width*0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Ongoing"),
            _matchList(count: 2, add: false),
            _sectionTitle("Upcoming"),
            _matchList(count: 5, add: true),
          ],
        ),
      ),
    );
  }

  /// Section title widget
  Widget _sectionTitle(String title) => Text(
        title,
        style: Get.textTheme.headlineSmall!.copyWith(color: AppColors.blackColor),
      ).paddingOnly(bottom: Get.height * 0.01, top: Get.height * 0.02);

  /// Matches list builder
  Widget _matchList({required int count, required bool add}) => ListView.builder(
        shrinkWrap: true,
        itemCount: count,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => buildMatchesList(add: add),
      );

  Widget buildMatchesList({required bool add}) {
    return GestureDetector(
      onTap: () => add
          ? showAmericanoBottomSheet(Get.context!)
          : Get.toNamed(RoutesName.scoreView),
      child: Container(
        width: Get.width,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              color: Colors.grey.withAlpha(60),
              blurRadius: 9.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("23 June | 9:00am",
                        style: Get.textTheme.bodySmall)
                        .paddingOnly(right: 5),
                    Container(
                      height: 17,
                      width: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.secondaryColor,
                      ),
                      child: Text("A",
                          style: Get.textTheme.bodySmall!
                              .copyWith(color: AppColors.whiteColor,fontSize: 10)),
                    ),
                  ],
                ),
                avatarGroup(add: add)
              ],
            ),
            Row(
              children: [
                const Icon(Icons.female, size: 15),
                Text("Female Only", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)),
              ],
            ).paddingOnly(bottom: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.person_crop_circle, size: 14),
                    Text("12 Players", style: Get.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w400)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(left: 8,right: 4,top: 3,bottom: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)

                  ),
                  child: Row(
                    children: [
                      Text(add ? "Join Now!  " : "View Score  ",
                          style: Get.textTheme.displaySmall!.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      CircleAvatar(
                        radius: 11,
                        foregroundColor: AppColors.primaryColor,
                        child: Icon(Icons.arrow_forward,
                            size: 14, color: AppColors.whiteColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).paddingOnly(bottom: Get.height * 0.015),
    );
  }

  Widget avatarGroup({required bool add}) {
    final totalItems = controller.avatarUrls.length + 1;
    return SizedBox(
      height: 40,
      width: totalItems * 22.0 + 20,
      child: Stack(
        children: [
          ...List.generate(controller.avatarUrls.length, (index) {
            return Positioned(
              left: index * 22.0,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(controller.avatarUrls[index]),
                ),
              ),
            );
          }),
          Positioned(
            left: controller.avatarUrls.length * 22.0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    add ? const Color(0xFF1E40AF) : Colors.grey.shade400,
                child: Text(
                  add ? '+' : '+5',
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
    );
  }

  void showAmericanoBottomSheet(BuildContext context) {
    final DraggableScrollableController draggableController =
        DraggableScrollableController();

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