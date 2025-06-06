import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/post_card.dart';
import '../services/api_service.dart';
import '../models/courier_post.dart';
import '../models/sender_post.dart';
import '../models/post.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/post_details_popup.dart';
import '../widgets/custom_text_field.dart';
import 'package:easy_localization/easy_localization.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ApiService _apiService = ApiService();
  Future<List<Post>>? _myPosts;
  String? _currentUserId;
  int _selectedTabIndex = 0;
  String? _searchFrom;
  String? _searchTo;
  DateTime? _searchDate;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _myPosts = _loadCurrentUserId();
  }

  Future<List<Post>> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      print('Loaded userId: $_currentUserId');
      if (_currentUserId == null) {
        print('Warning: userId is null. User might not be logged in.');
      }
      return await _fetchMyPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading user: $e',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        );
      }
      return [];
    }
  }

  Future<List<Post>> _fetchMyPosts() async {
    try {
      if (_currentUserId == null) {
        return [];
      }

      final results = await Future.wait([
        _apiService.fetchMySenderPosts(), // Fetch all sender posts
        _apiService.fetchMyCourierPosts(), // Fetch all courier posts
      ]);

      final List<SenderPost> senderPosts = results[0] as List<SenderPost>;
      final List<CourierPost> courierPosts = results[1] as List<CourierPost>;

      final List<Post> combinedPosts = [];

      // Add sender posts, excluding those with status 'active'
      combinedPosts.addAll(senderPosts.where((post) => post.status != 'active').map((post) => Post(
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
        status: post.status, // Use actual status from backend
        avatarUrl: post.user.avatarUrl,
      )));

      // Add courier posts, excluding those with status 'active'
      combinedPosts.addAll(courierPosts.where((post) => post.status != 'active').map((post) => Post(
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
        status: post.status, // Use actual status from backend
        avatarUrl: post.user.avatarUrl,
      )));

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

  Future<void> _deletePost(Post post) async {
    try {
      if (post.type == 'sender') {
        await _apiService.deleteSenderPost(post.postId);
      } else {
        await _apiService.deleteCourierPost(post.postId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Post deleted successfully',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        );
      }
      _refreshPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'error_deleting_post'.tr(),
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        );
      }
    }
  }

  void _sortPosts(List<Post> posts) {
    if (_sortBy == 'date') {
      posts.sort((a, b) => _sortAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
    } else if (_sortBy == 'price') {
      posts.sort((a, b) => _sortAscending
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price));
    }
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
            'my_posts'.tr(),
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFFEF7FF),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            DefaultTabController(
              length: 2,
              initialIndex: _selectedTabIndex,
              child: TabBar(
                onTap: (index) => setState(() => _selectedTabIndex = index),
                labelColor: Color(0xFF201731),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF201731),
                labelStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'courier_posts'.tr()),
                  Tab(text: 'sender_posts'.tr()),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
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
                              child: Text(
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

                    var filteredPosts = _selectedTabIndex == 0
                        ? posts.where((post) => post.type == 'courier').toList()
                        : posts.where((post) => post.type == 'sender').toList();

                    if (_searchFrom != null) {
                      filteredPosts =
                          filteredPosts.where((post) => post.from == _searchFrom).toList();
                    }
                    if (_searchTo != null) {
                      filteredPosts =
                          filteredPosts.where((post) => post.to == _searchTo).toList();
                    }
                    if (_searchDate != null) {
                      filteredPosts = filteredPosts
                          .where((post) =>
                      post.date.year == _searchDate!.year &&
                          post.date.month == _searchDate!.month &&
                          post.date.day == _searchDate!.day)
                          .toList();
                    }
                    if (_minPrice != null) {
                      filteredPosts = filteredPosts
                          .where((post) => post.price >= _minPrice!)
                          .toList();
                    }
                    if (_maxPrice != null) {
                      filteredPosts = filteredPosts
                          .where((post) => post.price <= _maxPrice!)
                          .toList();
                    }

                    _sortPosts(filteredPosts);

                    if (filteredPosts.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedTabIndex == 0
                              ? 'No courier posts available'
                              : 'No sender posts available',
                          style: const TextStyle(fontFamily: 'Montserrat'),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        return PostCard(
                          from: post.from.tr(),
                          to: post.to.tr(),
                          date: post.date,
                          userLocation: post.userLocation,
                          price: post.price,
                          onMorePressed: () => PostDetailsPopup.show(context, post),
                          onDeletePressed: () => _showDeleteConfirmationDialog(post),
                          leading: Icon(
                            post.type == 'sender'
                                ? Icons.send
                                : Icons.local_shipping,
                            color: const Color(0xFF201731),
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
      ),
    );
  }

  void _showDeleteConfirmationDialog(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFEF7FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Post',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete the post from ${post.from} to ${post.to}?',
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(post);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF201731),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        ],
      ),
    );
  }
}