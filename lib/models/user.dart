//models/user.dart
class User {
  final String id;
  final String username;
  final String phoneNumber;
  final String name;
  final String surname;

  User({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.name,
    required this.surname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
    );
  }
}