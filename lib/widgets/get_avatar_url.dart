import 'package:flutter_dotenv/flutter_dotenv.dart';

String? serverBaseUrl = dotenv.env['SERVER_AVATAR']; // Or your actual base URL for avatars

String getAvatarUrl(String? avatarPath) {
  if (avatarPath == null || avatarPath.isEmpty) {
    // Return a placeholder or an empty string if you handle that in Image.network
    return ''; // Or a link to a default avatar
  }
  if (avatarPath.startsWith('http') || avatarPath.startsWith('https')) {
    return avatarPath; // Already a full URL
  }
  // Otherwise, prepend the base URL
  return '$serverBaseUrl$avatarPath';
} 