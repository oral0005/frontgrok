class User {
  final String id;
  final String username;
  final String phoneNumber;
  final String name;
  final String surname;
  final String? avatarUrl;
  final String? language;
  final bool isVerified;

  User({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.name,
    required this.surname,
    this.avatarUrl,
    this.language,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      language: json['language'] as String?,
      isVerified: json['isVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'name': name,
      'surname': surname,
      'avatarUrl': avatarUrl,
      'language': language,
      'isVerified': isVerified,
    };
  }
}