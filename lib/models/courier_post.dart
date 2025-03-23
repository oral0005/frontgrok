//models/courier_post.dart

import 'package:frontgrok/models/user.dart';

class CourierPost {
  final String id;
  final String route;
  final DateTime departureTime;
  final double pricePerParcel;
  final String description;
  final User user;
  final DateTime dateCreated;

  CourierPost({
    required this.id,
    required this.route,
    required this.departureTime,
    required this.pricePerParcel,
    required this.description,
    required this.user,
    required this.dateCreated,
  });

  factory CourierPost.fromJson(Map<String, dynamic> json) {
    return CourierPost(
      id: json['_id']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      departureTime: DateTime.tryParse(json['departureTime']?.toString() ?? '') ?? DateTime.now(),
      pricePerParcel: (json['pricePerParcel'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      user: User.fromJson(json['userId'] is Map<String, dynamic> ? json['userId'] : {}),
      dateCreated: DateTime.tryParse(json['dateCreated']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}