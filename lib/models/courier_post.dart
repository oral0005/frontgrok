//models/courier_post.dart

import 'package:frontgrok/models/user.dart';
class CourierPost {
  final String id;
  final String from; // Новое поле
  final String to;   // Новое поле
  final DateTime sendTime;
  final double pricePerParcel;
  final String description;
  final User user;
  final DateTime dateCreated;

  CourierPost({
    required this.id,
    required this.from,
    required this.to,
    required this.sendTime,
    required this.pricePerParcel,
    required this.description,
    required this.user,
    required this.dateCreated,
  });

  factory CourierPost.fromJson(Map<String, dynamic> json) {
    return CourierPost(
      id: json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '', // Замена route на from
      to: json['to']?.toString() ?? '',     // Замена route на to
      sendTime: DateTime.tryParse(json['sendTime']?.toString() ?? '') ?? DateTime.now(),
      pricePerParcel: (json['pricePerParcel'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      user: User.fromJson(json['userId'] is Map<String, dynamic> ? json['userId'] : {}),
      dateCreated: DateTime.tryParse(json['dateCreated']?.toString() ?? '') ?? DateTime.now(),
    );
  }


}