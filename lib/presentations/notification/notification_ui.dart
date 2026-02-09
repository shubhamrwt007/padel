import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:padel_mobile/configs/app_colors.dart';
import 'package:padel_mobile/configs/components/app_bar.dart';
import 'package:padel_mobile/configs/components/loader_widgets.dart';
import 'package:padel_mobile/configs/routes/routes_name.dart';
import 'package:padel_mobile/presentations/notification/notification_controller.dart';
class NotificationScreen extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());
  NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchNotifications();
    return Scaffold(
      appBar: primaryAppBar(title: Text("Notification"), context: context,centerTitle: true,
          // action: [
          //   // Obx(() {
          //   //   final hasUnread = controller.notifications
          //   //       .any((n) => n['isRead'] == false);
          //   //   return hasUnread
          //   //       ? IconButton(
          //   //     icon: const Icon(Icons.mark_email_read),
          //   //     tooltip: "Mark all as read",
          //   //     // onPressed: controller.markAllNotificationsAsRead,
          //   //     onPressed: (){},
          //   //   )
          //   //       : const SizedBox.shrink();
          //   // }),
          //   IconButton(onPressed: (){
          //     Get.toNamed(RoutesName.tutorial);
          //   }, icon: Icon(Icons.eighteen_mp))
          // ]
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: LoadingWidget(color: AppColors.primaryColor,));
        }
        if (controller.notifications.isEmpty) {
          return  Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No notification available.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final grouped = _groupByDate(controller.notifications);

        return ListView.builder(
          padding: const EdgeInsets.only(top: 5),
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final date = grouped.keys.elementAt(index);
            final items = grouped[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ).paddingOnly(left: 20),
                const SizedBox(height: 8),
                ...items.map((n) => _NotificationTile(
                  id: n['id'],
                  title: n['title'],
                  message: n['message'],
                  time: n['time'],
                  icon: n['icon'],
                  payload: n['payload'],
                  redirect: n['redirect'] ?? '',
                  bookingId: n['bookingId'],
                  matchId: n['matchId'],
                  isRead: n['isRead'] ?? false,
                  bookingStatus: n['bookingStatus'],
                  notificationType: n['notificationType'] ?? '',
                  profileImage: n['profileImage'] ?? '',
                  userName: n['userName'] ?? '',
                )),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      }),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var n in notifications) {
      final time = n['time'] as DateTime;
      String key;

      if (DateUtils.isSameDay(now, time)) {
        key = 'Today';
      } else if (DateUtils.isSameDay(now.subtract(const Duration(days: 1)), time)) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMM dd, yyyy').format(time);
      }

      grouped.putIfAbsent(key, () => []).add(n);
    }

    return grouped;
  }
}

class _NotificationTile extends StatelessWidget {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final IconData icon;
  final String payload;
  final String redirect;
  final String bookingStatus;
  final String bookingId;
  final String matchId;
  final bool isRead;
  final String notificationType;
  final String profileImage;
  final String userName;
  const _NotificationTile({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.payload,
    required this.redirect,
    required this.bookingId,
    required this.matchId,
    required this.isRead,
    required this.bookingStatus,
    required this.notificationType,
    required this.profileImage,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.find();

    return InkWell(
      onTap: () {
        controller.markNotificationAsRead(id);
        if (payload.isNotEmpty) {
          controller.handleNotificationRoute(payload, redirect: redirect,matchId: matchId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 0),
        color: isRead? Colors.transparent:AppColors.primaryColor.withValues(alpha: 0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isRead
                  ? Colors.grey.withValues(alpha: 0.1)
                  : AppColors.primaryColor.withValues(alpha: 0.1),
              child: profileImage.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profileImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Text(
                          NotificationController.instance.getInitials(userName),
                          style: TextStyle(
                            color: isRead ? Colors.grey : AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      NotificationController.instance.getInitials(userName),
                      style: TextStyle(
                        color: isRead ? Colors.grey : AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.capitalizeWords(title),
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('hh:mm a').format(time),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}