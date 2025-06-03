import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/user.dart';

class Notification {
  final String id;
  final String message;
  final User sender;
  final DateTime createdAt;
  final bool read;
  final String type;
  final String postId;
  final String postType;

  Notification({
    required this.id,
    required this.message,
    required this.sender,
    required this.createdAt,
    required this.read,
    required this.type,
    required this.postId,
    required this.postType,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      sender: User.fromJson(json['sender'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      read: json['read'] ?? false,
      type: json['type'] ?? '',
      postId: json['postId'] ?? '',
      postType: json['postType'] ?? '',
    );
  }

  String get formattedCreatedAt => DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Notification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Notification>> _fetchNotifications() async {
    final token = await _apiService.getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notifications'),
      headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((json) => Notification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch notifications: ${response.body}');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final token = await _apiService.getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/notifications/$notificationId/read'),
      headers: {'x-auth-test': token},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read: ${response.body}');
    }
  }

  Future<void> _respondToActivation(String postId, String postType, bool accept) async {
    final token = await _apiService.getToken();
    if (token == null) throw Exception('No token found');
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/${postType}-posts/$postId/activation-response'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({'accept': accept}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to respond to activation: ${response.body}');
      }
    } catch (e) {
      print('Error responding to activation: $e');
      throw Exception('Failed to respond to activation: $e');
    }
  }

  void _showActivationDialog(Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('activation_request'.tr()),
        content: Text('accept_request'.tr(args: [notification.sender.username, notification.postType])),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _respondToActivation(notification.postId, notification.postType, false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('request_rejected'.tr())));
                setState(() {
                  _notificationsFuture = _fetchNotifications();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                Navigator.pop(context);
              }
            },
            child: Text('reject'.tr()),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _respondToActivation(notification.postId, notification.postType, true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('request_accepted'.tr())));
                setState(() {
                  _notificationsFuture = _fetchNotifications();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                Navigator.pop(context);
              }
            },
            child: Text('accept'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('notifications'.tr())),
      body: FutureBuilder<List<Notification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(child: Text('no_notifications'.tr()));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                title: Text(notification.message),
                subtitle: Text('${'from'.tr()}: ${notification.sender.username} • ${notification.formattedCreatedAt}'),
                trailing: notification.read
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.circle, color: Colors.red),
                onTap: () async {
                  if (!notification.read) {
                    try {
                      await _markAsRead(notification.id);
                      setState(() {
                        _notificationsFuture = _fetchNotifications();
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                  if (notification.type == 'activation_request') {
                    _showActivationDialog(notification);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}