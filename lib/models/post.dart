class Post {
  final String type;
  final String route;
  final DateTime date;
  final String userLocation;
  final String userId;
  final String postId;
  final double price;
  final String description;

  Post({
    required this.type,
    required this.route,
    required this.date,
    required this.userLocation,
    required this.userId,
    required this.postId,
    required this.price,
    required this.description,
  });
}