import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';
import '../models/user.dart';
import 'dart:io';

String? serverBaseUrl = 'http://192.168.56.1:5050';

class ApiService {
  static const String baseUrl = 'http://192.168.56.1:5050/api';

  /// Retrieves the authentication token from SharedPreferences.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved token: $token');
    return token;
  }

  /// Logs in a user and stores the token and user ID in SharedPreferences.
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['id']);
        print('Token stored: ${data['token']}');
        return data;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Registers a new user.
  Future<void> register(String username, String password, String phoneNumber, String name, String surname) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'phoneNumber': phoneNumber,
          'name': name,
          'surname': surname,
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode != 201) {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  /// Fetches the authenticated user's profile.
  Future<User> getUserProfile() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Get profile response status: ${response.statusCode}');
      print('Get profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Profile fetch error: $e');
    }
  }

  /// Uploads an avatar image for the authenticated user.
  Future<String> uploadAvatar(File imageFile) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/upload-avatar'),
    );
    request.headers['x-auth-token'] = token;
    request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('uploadAvatar responseData: $responseData');
      return responseData['avatarUrl'];
    } else {
      throw Exception('Failed to upload avatar: ${response.statusCode}');
    }
  }

  /// Updates the authenticated user's profile.
  Future<void> updateProfile({
    required String name,
    required String surname,
    String? avatarUrl,
    String? language,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    print('updateProfile body: ${json.encode({
      'name': name,
      'surname': surname,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (language != null) 'language': language,
    })}');

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: json.encode({
        'name': name,
        'surname': surname,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (language != null) 'language': language,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  /// Fetches active sender posts for the authenticated user.
  Future<List<SenderPost>> fetchActiveSenderPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sender-posts/active'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Fetch active sender posts response status: ${response.statusCode}');
      print('Fetch active sender posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => SenderPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load active sender posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Active sender posts fetch error: $e');
    }
  }

  /// Fetches active courier posts for the authenticated user.
  Future<List<CourierPost>> fetchActiveCourierPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courier-posts/active'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Fetch active courier posts response status: ${response.statusCode}');
      print('Fetch active courier posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => CourierPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load active courier posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Active courier posts fetch error: $e');
    }
  }

  /// Fetches completed sender posts for the authenticated user.
  Future<List<SenderPost>> getCompletedSenderPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sender-posts/completed'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Fetch completed sender posts response status: ${response.statusCode}');
      print('Fetch completed sender posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => SenderPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load completed sender posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Completed sender posts fetch error: $e');
    }
  }

  /// Fetches completed courier posts for the authenticated user.
  Future<List<CourierPost>> getCompletedCourierPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courier-posts/completed'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Fetch completed courier posts response status: ${response.statusCode}');
      print('Fetch completed courier posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => CourierPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load completed courier posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Completed courier posts fetch error: $e');
    }
  }

  /// Fetches all courier posts.
  Future<List<CourierPost>> fetchCourierPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/courier-posts'));

      print('Fetch courier posts response status: ${response.statusCode}');
      print('Fetch courier posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => CourierPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load courier posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Courier posts fetch error: $e');
    }
  }

  /// Fetches all sender posts.
  Future<List<SenderPost>> fetchSenderPosts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sender-posts'));

      print('Fetch sender posts response status: ${response.statusCode}');
      print('Fetch sender posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => SenderPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load sender posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Sender posts fetch error: $e');
    }
  }

  /// Fetches the authenticated user's courier posts.
  Future<List<CourierPost>> fetchMyCourierPosts() async {
    final token = await getToken();
    if (token == null) {
      print('No token found in SharedPreferences');
      throw Exception('No token found');
    }
    print('Fetching my courier posts with token: $token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/courier-posts/my-posts'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Fetch my courier posts response status: ${response.statusCode}');
      print('Fetch my courier posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => CourierPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load my courier posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Fetch my courier posts error: $e');
      throw Exception('My courier posts fetch error: $e');
    }
  }

  /// Fetches the authenticated user's sender posts.
  Future<List<SenderPost>> fetchMySenderPosts() async {
    final token = await getToken();
    if (token == null) {
      print('No token found in SharedPreferences');
      throw Exception('No token found');
    }
    print('Fetching my sender posts with token: $token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sender-posts/my-posts'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Fetch my sender posts response status: ${response.statusCode}');
      print('Fetch my sender posts response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response body');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Expected a list of posts, but got: ${decoded.runtimeType}');
        }
        return decoded.map((json) => SenderPost.fromJson(json)).toList();
      } else {
        String errorMessage = 'Failed to load my sender posts: ${response.statusCode}';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['msg']?.toString() ?? errorMessage;
          } catch (e) {
            errorMessage = 'Failed to parse error response: ${response.statusCode} ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Fetch my sender posts error: $e');
      throw Exception('My sender posts fetch error: $e');
    }
  }

  /// Creates a new courier post for the authenticated user.
  Future<void> createCourierPost(String from, String to, DateTime sendTime, double parcelPrice, String description) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courier-posts'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'from': from,
          'to': to,
          'sendTime': sendTime.toIso8601String(),
          'parcelPrice': parcelPrice,
          'description': description,
        }),
      );

      print('Create courier post response status: ${response.statusCode}');
      print('Create courier post response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Failed to create courier post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Create courier post error: $e');
    }
  }

  /// Creates a new sender post for the authenticated user.
  Future<void> createSenderPost(String from, String to, DateTime sendTime, double parcelPrice, String description) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sender-posts'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'from': from,
          'to': to,
          'sendTime': sendTime.toIso8601String(),
          'parcelPrice': parcelPrice,
          'description': description,
        }),
      );

      print('Create sender post response status: ${response.statusCode}');
      print('Create sender post response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Failed to create sender post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Create sender post error: $e');
    }
  }

  /// Fetches the recommended price for a route.
  Future<double?> fetchRecommendedPrice(String from, String to) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/price-predictions/recommended-price?from=$from&to=$to'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetch recommended price response status: ${response.statusCode}');
      print('Fetch recommended price response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recommendedPrice']?.toDouble();
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Failed to fetch recommended price: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch recommended price error: $e');
      return null;
    }
  }

  /// Deletes a sender post by ID for the authenticated user.
  Future<void> deleteSenderPost(String postId) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sender-posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Delete sender post response status: ${response.statusCode}');
      print('Delete sender post response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Failed to delete sender post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Delete sender post error: $e');
    }
  }

  /// Deletes a courier post by ID for the authenticated user.
  Future<void> deleteCourierPost(String postId) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/courier-posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      print('Delete courier post response status: ${response.statusCode}');
      print('Delete courier post response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        throw Exception(errorBody['msg']?.toString() ?? 'Failed to delete courier post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Delete courier post error: $e');
    }
  }

  /// Changes the authenticated user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.put(
      Uri.parse('$baseUrl/users/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(errorBody['msg']?.toString() ?? 'Failed to change password: ${response.statusCode}');
    }
  }

  /// Sends a verification code to the specified phone number.
  Future<void> sendVerificationCode(String phoneNumber) async {
    try {
      print('Sending verification code to: $phoneNumber');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      print('Send verification code response status: ${response.statusCode}');
      print('Send verification code response body: ${response.body}');

      if (response.statusCode != 200) {
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body);
        } catch (e) {
          print('Error parsing response body: $e');
        }
        throw Exception(errorBody['message']?.toString() ?? 'Failed to send verification code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending verification code: $e');
      throw Exception('Failed to send verification code: $e');
    }
  }

  /// Verifies the code sent to the specified phone number.
  Future<void> verifyCode(String phoneNumber, String code) async {
    try {
      print('Verifying code for: $phoneNumber');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'code': code,
        }),
      );

      print('Verify code response status: ${response.statusCode}');
      print('Verify code response body: ${response.body}');

      if (response.statusCode != 200) {
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body);
        } catch (e) {
          print('Error parsing response body: $e');
        }
        throw Exception(errorBody['message']?.toString() ?? 'Failed to verify code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error verifying code: $e');
      throw Exception('Failed to verify code: $e');
    }
  }

  /// Fetches all notifications for the authenticated user.
  Future<List<dynamic>> fetchNotifications() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data;
    } else {
      throw Exception('Failed to fetch notifications: ${response.body}');
    }
  }
}