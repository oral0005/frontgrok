import 'package:frontgrok/models/user.dart';
import 'package:intl/intl.dart';

class CourierPost {
  final String id;
  final String from;
  final String to;
  final DateTime sendTime;
  final double parcelPrice;
  final String description;
  final User user;
  final DateTime dateCreated;
  final String status;
  final User? assignedSender;
  final User? assignedCourier;// Populated User object from API

  CourierPost({
    required this.id,
    required this.from,
    required this.to,
    required this.sendTime,
    required this.parcelPrice,
    required this.description,
    required this.user,
    required this.dateCreated,
    required this.status,
    this.assignedSender,
    this.assignedCourier,
  });

  factory CourierPost.fromJson(Map<String, dynamic> json) {
    return CourierPost(
      id: json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      sendTime: DateTime.tryParse(json['sendTime']?.toString() ?? '') ?? DateTime.now(),
      parcelPrice: (json['parcelPrice'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      user: User.fromJson(json['userId'] is Map<String, dynamic> ? json['userId'] : {}),
      dateCreated: DateTime.tryParse(json['dateCreated']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'open',
      assignedSender: json['assignedSender'] != null ? User.fromJson(json['assignedSender']) : null,
    );
  }

  String get formattedDate => DateFormat('dd.MM.yyyy').format(dateCreated);
}