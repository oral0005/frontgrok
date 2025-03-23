//pages/routes_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';
import '../widgets/tab_bar_widget.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<CourierPost>> _courierPosts;
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
      _courierPosts = _apiService.fetchCourierPosts();
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
        _courierPosts = _apiService.fetchCourierPosts();
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
              child: FutureBuilder<List<CourierPost>>(
                future: _courierPosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No courier posts available'));
                  }

                  final posts = _selectedTabIndex == 0
                      ? snapshot.data!.where((post) => post.user.id != _currentUserId).toList()
                      : snapshot.data!.where((post) => post.user.id == _currentUserId).toList();

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
          ),
        ],
      ),
    );
  }
}