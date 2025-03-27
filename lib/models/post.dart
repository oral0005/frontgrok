class Post {
  final String type;
  final String from; // Новое поле
  final String to;   // Новое поле
  final DateTime date;
  final String userLocation;
  final String userId;
  final String postId;
  final double price;
  final String description;

  Post({
    required this.type,
    required this.from,
    required this.to,
    required this.date,
    required this.userLocation,
    required this.userId,
    required this.postId,
    required this.price,
    required this.description,
  });
}