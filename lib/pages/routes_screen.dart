import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';
import '../models/post.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/post_details_popup.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _posts;
  String? _currentUserId;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      _posts = _fetchPosts();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading user: $e')));
      }
    }
  }

  Future<List<Post>> _fetchPosts() async {
    try {
      final results = await Future.wait([
        _apiService.fetchSenderPosts(),
        _apiService.fetchCourierPosts(),
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
      throw Exception('Failed to load posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() {
        _posts = _fetchPosts();
      });
    }
    return Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: Column(
        children: [
          TabBarWidget(
            firstTab: 'Courier Posts',
            secondTab: 'Sender Posts',
            onTabChanged: (index) => setState(() => _selectedTabIndex = index),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              child: FutureBuilder<List<Post>>(
                future: _posts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No posts available'));
                  }

                  final posts = _selectedTabIndex == 0
                      ? snapshot.data!.where((post) => post.type == 'courier' && post.userId != _currentUserId).toList()
                      : snapshot.data!.where((post) => post.type == 'sender' && post.userId != _currentUserId).toList();

                  if (posts.isEmpty) {
                    return Center(
                      child: Text(_selectedTabIndex == 0
                          ? 'No courier posts available'
                          : 'No sender posts available'),
                    );
                  }

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
          ),
        ],
      ),
    );
  }
}