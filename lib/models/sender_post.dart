import 'package:frontgrok/models/user.dart';

class SenderPost {
  final String id;
  final String from;
  final String to;
  final DateTime sendTime;
  final double parcelPrice;
  final String description;
  final User user;
  final String status; // Added status field

  SenderPost({
    required this.id,
    required this.from,
    required this.to,
    required this.sendTime,
    required this.parcelPrice,
    required this.description,
    required this.user,
    required this.status, // Required parameter
  });

  factory SenderPost.fromJson(Map<String, dynamic> json) {
    return SenderPost(
      id: json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      sendTime: DateTime.tryParse(json['sendTime']?.toString() ?? '') ?? DateTime.now(),
      parcelPrice: (json['parcelPrice'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      user: User.fromJson(json['userId'] is Map<String, dynamic> ? json['userId'] : {}),
      status: json['status']?.toString() ?? 'open', // Default to 'open' if not present
    );
  }
}