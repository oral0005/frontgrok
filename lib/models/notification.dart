import './user.dart'; // Assuming you have a User model for sender details

class NotificationModel {
  final String id;
  final String recipient; // User ID
  final User? sender; // Optional: Populated sender details
  final String? postId; 
  final String? postModel; // 'SenderPost' or 'CourierPost'
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipient,
    this.sender,
    this.postId,
    this.postModel,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      recipient: json['recipient'],
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      postId: json['postId'],
      postModel: json['postModel'],
      type: json['type'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 