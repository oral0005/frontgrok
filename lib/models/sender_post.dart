//models/sender_post.dart

import 'package:frontgrok/models/user.dart'; // Add this import
class SenderPost {
  final String id;
  final String from; // Новое поле
  final String to;   // Новое поле
  final DateTime sendTime;
  final double parcelPrice;
  final String description;
  final User user;

  SenderPost({
    required this.id,
    required this.from,
    required this.to,
    required this.sendTime,
    required this.parcelPrice,
    required this.description,
    required this.user,
  });

  factory SenderPost.fromJson(Map<String, dynamic> json) {
    return SenderPost(
      id: json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '', // Замена route на from
      to: json['to']?.toString() ?? '',     // Замена route на to
      sendTime: DateTime.tryParse(json['sendTime']?.toString() ?? '') ?? DateTime.now(),
      parcelPrice: (json['parcelPrice'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      user: User.fromJson(json['userId'] is Map<String, dynamic> ? json['userId'] : {}),
    );
  }
}