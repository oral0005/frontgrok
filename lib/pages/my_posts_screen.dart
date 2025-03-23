import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<CourierPost>> _myPosts;
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
      _myPosts = _apiService.fetchCourierPosts();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading user: $e')));
      }
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() {
        _myPosts = _apiService.fetchCourierPosts();
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
        child: FutureBuilder<List<CourierPost>>(
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
              return const Center(child: Text('No posts available'));
            }

            final posts = snapshot.data!
                .where((post) => post.user.id == _currentUserId)
                .toList();

            if (posts.isEmpty) {
              return const Center(child: Text('You have no posts yet'));
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  route: post.route,
                  date: post.departureTime,
                  userLocation: '${post.user.name}, ${post.user.surname}',
                  onMorePressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('More details for ${post.route}'))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}