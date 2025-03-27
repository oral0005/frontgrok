import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';
import '../models/post.dart';
import '../widgets/post_details_popup.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _myPosts;
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
      _myPosts = _fetchMyPosts();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading user: $e')));
      }
    }
  }

  Future<List<Post>> _fetchMyPosts() async {
    try {
      final results = await Future.wait([
        _apiService.fetchMySenderPosts(),
        _apiService.fetchMyCourierPosts(),
      ]);

      final List<SenderPost> senderPosts = results[0] as List<SenderPost>;
      final List<CourierPost> courierPosts = results[1] as List<CourierPost>;

      final List<Post> combinedPosts = [];

      combinedPosts.addAll(senderPosts.map((post) => Post(
        type: 'sender',
        from: post.from,             // Заменено route на from
        to: post.to,                 // Заменено route на to
        date: post.sendTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.parcelPrice,
        description: post.description,
      )));

      combinedPosts.addAll(courierPosts.map((post) => Post(
        type: 'courier',
        from: post.from,             // Заменено route на from
        to: post.to,                 // Заменено route на to
        date: post.departureTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.pricePerParcel,
        description: post.description,
      )));

      combinedPosts.sort((a, b) => b.date.compareTo(a.date));
      return combinedPosts;
    } catch (e) {
      throw Exception('Failed to load my posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() {
        _myPosts = _fetchMyPosts();
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
        child: FutureBuilder<List<Post>>(
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
                  from: post.from,             // Заменено route на from
                  to: post.to,                 // Заменено route на to
                  date: post.date,
                  userLocation: post.userLocation,
                  onMorePressed: () => PostDetailsPopup.show(context, post),
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