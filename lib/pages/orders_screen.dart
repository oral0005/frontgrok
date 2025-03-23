import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/sender_post.dart';
import '../models/courier_post.dart';

// Create a union type to hold both SenderPost and CourierPost
class Post {
  final String type; // "sender" or "courier"
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

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _posts;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    _posts = _fetchAllPosts();
  }

  Future<List<Post>> _fetchAllPosts() async {
    try {
      // Fetch both sender and courier posts concurrently
      final results = await Future.wait([
        _apiService.fetchSenderPosts(),
        _apiService.fetchCourierPosts(),
      ]);

      final List<SenderPost> senderPosts = results[0] as List<SenderPost>;
      final List<CourierPost> courierPosts = results[1] as List<CourierPost>;

      // Combine sender and courier posts into a single list
      final List<Post> combinedPosts = [];

      // Add sender posts
      combinedPosts.addAll(senderPosts.map((post) => Post(
        type: 'sender',
        route: post.route,
        date: post.sendTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.userId,
        postId: post.id,
      )));

      // Add courier posts
      combinedPosts.addAll(courierPosts.map((post) => Post(
        type: 'courier',
        route: post.route,
        date: post.departureTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.userId,
        postId: post.id,
      )));

      // Sort posts by date (optional, if you want the most recent first)
      combinedPosts.sort((a, b) => b.date.compareTo(a.date));

      return combinedPosts;
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() => _loadPosts());
    }
    return Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>(
          future: _posts,
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

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final post = snapshot.data![index];
                return PostCard(
                  route: post.route,
                  date: post.date,
                  userLocation: post.userLocation,
                  onMorePressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Details for ${post.type == 'sender' ? 'Sender' : 'Courier'} Post: ${post.route}',
                        ),
                      ),
                    );
                  },
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