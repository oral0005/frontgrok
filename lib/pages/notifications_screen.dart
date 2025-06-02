import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import '../models/notification.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/get_avatar_url.dart'; // Assuming getAvatarUrl is in a shared utility

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  Future<List<NotificationModel>>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _apiService.fetchNotifications();
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _apiService.markNotificationAsRead(notification.id);
        _loadNotifications(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_marking_notification_read'.tr()}: $e')),
        );
      }
    }
    // Potentially navigate to post details or related screen
    // if (notification.postId != null) { ... }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsAsRead();
      _loadNotifications(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_marking_all_notifications_read'.tr()}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr(), style: const TextStyle(fontFamily: 'Montserrat')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'mark_all_read'.tr(),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadNotifications();
        },
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${'error_loading_notifications'.tr()}: ${snapshot.error}'));
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return Center(child: Text('no_notifications_available'.tr()));
            }

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final bool isUnread = !notification.isRead;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: notification.sender?.avatarUrl != null && notification.sender!.avatarUrl!.isNotEmpty
                        ? NetworkImage(getAvatarUrl(notification.sender!.avatarUrl!))
                        : null,
                    child: notification.sender?.avatarUrl == null || notification.sender!.avatarUrl!.isEmpty
                        ? Icon(Icons.person, size: 20, color: Colors.blueGrey[700])
                        : null,
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'Montserrat',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    timeago.format(notification.createdAt, locale: context.locale.languageCode),
                    style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12),
                  ),
                  trailing: isUnread
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () => _markAsRead(notification),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 