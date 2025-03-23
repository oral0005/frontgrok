//models/sender_post.dart

import 'package:frontgrok/models/user.dart'; // Add this import

class SenderPost {
  final String id;
  final String route;
  final DateTime sendTime;
  final double parcelPrice;
  final String description;
  final User user; // Now recognized because of the import

  SenderPost({
    required this.id,
    required this.route,
    required this.sendTime,
    required this.parcelPrice,
    required this.description,
    required this.user,
  });

  factory SenderPost.fromJson(Map<String, dynamic> json) {
    return SenderPost(
      id: json['_id'],
      route: json['route'],
      sendTime: DateTime.parse(json['sendTime']),
      parcelPrice: json['parcelPrice'].toDouble(),
      description: json['description'] ?? '',
      user: User.fromJson(json['userId']), // Now works with the imported User class
    );
  }
}