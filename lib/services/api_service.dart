import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved token: $token');
    return token;
  }

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

  Future<User> getUserProfile() async {
    final token = await _getToken();
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

  // Fetch all courier posts
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

  // Fetch all sender posts
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

  // Fetch the user's own courier posts
  Future<List<CourierPost>> fetchMyCourierPosts() async {
    final token = await _getToken();
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

  // Fetch the user's own sender posts (new method)
  Future<List<SenderPost>> fetchMySenderPosts() async {
    final token = await _getToken();
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

  // Create a courier post
  Future<void> createCourierPost(String route, DateTime departureTime, double pricePerParcel, String description) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/courier-posts'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'route': route,
          'departureTime': departureTime.toIso8601String(),
          'pricePerParcel': pricePerParcel,
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

  // Create a sender post
  Future<void> createSenderPost(String route, DateTime sendTime, double parcelPrice, String description) async {
    final token = await _getToken();
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sender-posts'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'route': route,
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
}