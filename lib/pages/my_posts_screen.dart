//pages/my_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';

// Определяем объединенный тип Post для поддержки SenderPost и CourierPost
class Post {
  final String type; // "sender" или "courier"
  final String route;
  final DateTime date;
  final String userLocation;
  final String userId;
  final String postId;

  Post({
    required this.type,
    required this.route,
    required this.date,
    required this.userLocation,
    required this.userId,
    required this.postId,
  });
}

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _myPosts; // Изменено на List<Post>
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      print('Loaded userId: $_currentUserId');
      if (_currentUserId == null) {
        print('Warning: userId is null. User might not be logged in.');
      }
      _myPosts = _fetchMyPosts(); // Загружаем свои посты
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading user: $e')));
      }
    }
  }

  // Новая функция для получения и объединения своих постов
  Future<List<Post>> _fetchMyPosts() async {
    try {
      final results = await Future.wait([
        _apiService.fetchMySenderPosts(),
        _apiService.fetchMyCourierPosts(),
      ]);

      final List<SenderPost> senderPosts = results[0] as List<SenderPost>;
      final List<CourierPost> courierPosts = results[1] as List<CourierPost>;

      final List<Post> combinedPosts = [];

      // Добавляем посты отправителя
      combinedPosts.addAll(senderPosts.map((post) => Post(
        type: 'sender',
        route: post.route,
        date: post.sendTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
      )));

      // Добавляем посты курьера
      combinedPosts.addAll(courierPosts.map((post) => Post(
        type: 'courier',
        route: post.route,
        date: post.departureTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
      )));

      // Сортируем по дате (самые новые сверху)
      combinedPosts.sort((a, b) => b.date.compareTo(a.date));

      return combinedPosts;
    } catch (e) {
      throw Exception('Failed to load my posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() {
        _myPosts = _fetchMyPosts(); // Обновляем список постов
      });
    }
    return Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posts')),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>( // Изменено на List<Post>
          future: _myPosts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPosts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('You have no posts yet'));
            }

            final posts = snapshot.data!;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  route: post.route,
                  date: post.date,
                  userLocation: post.userLocation,
                  onMorePressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('More details for ${post.route}')),
                  ),
                  leading: Icon(
                    post.type == 'sender' ? Icons.send : Icons.local_shipping,
                    color: post.type == 'sender' ? Colors.blue : Colors.green,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}