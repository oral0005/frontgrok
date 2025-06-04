import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';
import '../models/post.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/post_card_history.dart'; // Updated import
import '../widgets/tab_bar_widget.dart';
import '../widgets/post_details_history.dart'; // Updated import
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  final User currentUser;

  const HistoryScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    try {
      final results = await Future.wait([
        _apiService.fetchActiveSenderPosts(),
        _apiService.fetchActiveCourierPosts(),
        _apiService.getCompletedSenderPosts(),
        _apiService.getCompletedCourierPosts(),
      ]);

      final List<SenderPost> activeSenderPosts = results[0] as List<SenderPost>;
      final List<CourierPost> activeCourierPosts = results[1] as List<CourierPost>;
      final List<SenderPost> completedSenderPosts = results[2] as List<SenderPost>;
      final List<CourierPost> completedCourierPosts = results[3] as List<CourierPost>;

      final List<Post> combinedPosts = [];

      combinedPosts.addAll(activeSenderPosts.map((post) => Post(
        type: 'sender',
        from: post.from,
        to: post.to,
        date: post.sendTime,
        userLocation: '${post.user.name} ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.parcelPrice,
        description: post.description,
        phoneNumber: post.user.phoneNumber,
        status: post.status,
        avatarUrl: post.user.avatarUrl,
      )));

      combinedPosts.addAll(activeCourierPosts.map((post) => Post(
        type: 'courier',
        from: post.from,
        to: post.to,
        date: post.sendTime,
        userLocation: '${post.user.name} ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.parcelPrice,
        description: post.description,
        phoneNumber: post.user.phoneNumber,
        status: post.status,
        avatarUrl: post.user.avatarUrl,
      )));

      combinedPosts.addAll(completedSenderPosts.map((post) => Post(
        type: 'sender',
        from: post.from,
        to: post.to,
        date: post.sendTime,
        userLocation: '${post.user.name} ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.parcelPrice,
        description: post.description,
        phoneNumber: post.user.phoneNumber,
        status: post.status,
        avatarUrl: post.user.avatarUrl,
      )));

      combinedPosts.addAll(completedCourierPosts.map((post) => Post(
        type: 'courier',
        from: post.from,
        to: post.to,
        date: post.sendTime,
        userLocation: '${post.user.name} ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.parcelPrice,
        description: post.description,
        phoneNumber: post.user.phoneNumber,
        status: post.status,
        avatarUrl: post.user.avatarUrl,
      )));

      return combinedPosts;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading posts: $e',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        );
      }
      return [];
    }
  }

  Future<void> _refreshPosts() async {
    if (mounted) {
      setState(() {
        _postsFuture = _fetchPosts();
      });
    }
    return Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Montserrat',
          fontFamilyFallback: ['Roboto'],
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7FF),
        appBar: AppBar(
          title: Text(
            'history'.tr(),
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFFEF7FF),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPosts,
                child: FutureBuilder<List<Post>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Montserrat'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshPosts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF201731),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(fontFamily: 'Montserrat'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      return Center(
                        child: Text(
                          'you_have_no_posts_yet'.tr(),
                          style: const TextStyle(fontFamily: 'Montserrat'),
                        ),
                      );
                    }

                    final filteredPosts = posts.where((post) => post.status == 'active').toList();
                    if (filteredPosts.isEmpty) {
                      return Center(
                        child: Text(
                          'no_active_posts'.tr(),
                          style: const TextStyle(fontFamily: 'Montserrat'),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        return Column(
                          children: [
                            PostCardHistory(
                              from: post.from.tr(),
                              to: post.to.tr(),
                              date: post.date,
                              userLocation: post.userLocation,
                              price: post.price,
                              onMorePressed: () => PostDetailsHistory.show(context, post),
                              leading: Icon(
                                post.type == 'sender' ? Icons.send : Icons.local_shipping,
                                color: const Color(0xFF201731),
                              ),
                            ),
                            if (index < filteredPosts.length - 1) const Divider(),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension HistoryApi on ApiService {
  Future<List<SenderPost>> fetchActiveSenderPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/sender-posts/active'),
      headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((json) => SenderPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch active sender posts: ${response.body}');
    }
  }

  Future<List<CourierPost>> fetchActiveCourierPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/courier-posts/active'),
      headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((json) => CourierPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch active courier posts: ${response.body}');
    }
  }

  Future<List<SenderPost>> getCompletedSenderPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/sender-posts/completed'),
      headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((json) => SenderPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch completed sender posts: ${response.body}');
    }
  }

  Future<List<CourierPost>> getCompletedCourierPosts() async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/courier-posts/completed'),
      headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List).map((json) => CourierPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch completed courier posts: ${response.body}');
    }
  }
}