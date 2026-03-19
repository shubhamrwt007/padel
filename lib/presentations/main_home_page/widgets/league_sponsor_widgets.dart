import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/generated/assets.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart' as LeagueModel;

class BuildLeagueTitleSponsor extends StatelessWidget {
  final LeagueModel.Data league;
  const BuildLeagueTitleSponsor({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            "Sponsors",
            style: Get.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w400),
          ).paddingOnly(bottom: 6),
          if (league.titleSponsor?.logo != null)
            CachedNetworkImage(
              imageUrl: league.titleSponsor!.logo!,
              height: 40,
              placeholder: (context, url) => Container(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Image.asset(
                Assets.imagesImgDummyLogo2,
                height: 40,
              ),
            )
          else
            Image.asset(
              Assets.imagesImgDummyLogo2,
              height: 40,
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: Colors.black26,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (league.sponsors != null && league.sponsors!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: () {
                final items = league.sponsors!.take(3).toList();
                final children = <Widget>[];

                for (final sponsor in items) {
                  children.add(
                    Expanded(
                      child: sponsor.logo != null
                          ? CachedNetworkImage(
                              imageUrl: sponsor.logo!,
                              height: 25,
                              placeholder: (context, url) => Container(
                                height: 25,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_not_supported,
                                size: 25,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(
                              Icons.image_not_supported,
                              size: 25,
                              color: Colors.grey,
                            ),
                    ),
                  );
                  children.add(Container(
                    height: 30,
                    width: 1,
                    color: Colors.black26,
                  ));
                }

                if (children.isNotEmpty) children.removeLast();
                return children;
              }(),
            ),
        ],
      ),
    );
  }
}

class BuildLeagueMoreSponsor extends StatelessWidget {
  final LeagueModel.Data league;
  const BuildLeagueMoreSponsor({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    if (league.sponsors == null || league.sponsors!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 30,
      width: Get.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3513EA),
            Color(0xFF002091),
          ],
        ),
      ),
      child: ListView.builder(
        itemCount: league.sponsors!.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final sponsor = league.sponsors![index];
          return Row(
            children: [
              if (sponsor.logo != null)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: sponsor.logo!,
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey,
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ).paddingOnly(right: 5)
              else
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey,
                ).paddingOnly(right: 5),
              Text(
                sponsor.name ?? "Sponsor",
                style: Get.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )
            ],
          ).paddingOnly(right: 8);
        },
      ).paddingOnly(left: 10),
    ).paddingOnly(top: 10);
  }
}
