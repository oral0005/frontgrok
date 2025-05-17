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

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _myPosts;
  String? _currentUserId;
  int _selectedTabIndex = 0;
  String? _searchFrom;
  String? _searchTo;
  DateTime? _searchDate;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'date'; // Default sort by date
  bool _sortAscending = false; // Default descending

  final List<String> _kazakhstanCities = [
    'Almaty',
    'Astana',
    'Shymkent',
    'Karaganda',
    'Aktobe',
    'Taraz',
    'Pavlodar',
    'Ust-Kamenogorsk',
    'Semey',
    'Atyrau',
    'Kostanay',
    'Kyzylorda',
    'Uralsk',
    'Petropavl',
    'Aktau',
    'Temirtau',
    'Turkestan',
    'Taldykorgan',
    'Ekibastuz',
    'Rudny',
    'Zhanaozen',
    'Zhezkazgan',
    'Kentau',
    'Balkhash',
    'Satbayev',
    'Kokshetau',
    'Saran',
    'Shakhtinsk',
    'Ridder',
    'Arkalyk',
    'Lisakovsk',
    'Aral',
    'Zhetisay',
    'Saryagash',
    'Aksu',
    'Stepnogorsk',
    'Kapchagay',
  ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading user: $e',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        );
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
        from: post.from,
        to: post.to,
        date: post.sendTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.parcelPrice,
        description: post.description,
      )));

      combinedPosts.addAll(courierPosts.map((post) => Post(
        type: 'courier',
        from: post.from,
        to: post.to,
        date: post.departureTime,
        userLocation: '${post.user.name}, ${post.user.surname}',
        userId: post.user.id,
        postId: post.id,
        price: post.pricePerParcel,
        description: post.description,
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
              'Error deleting post: $e',
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        );
      }
    }
  }

  void _sortPosts(List<Post> posts) {
    if (_sortBy == 'date') {
      posts.sort((a, b) => _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    } else if (_sortBy == 'price') {
      posts.sort((a, b) => _sortAscending
          ? (a.price ?? 0).compareTo(b.price ?? 0)
          : (b.price ?? 0).compareTo(a.price ?? 0));
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
          title: const Text(
            'My Posts',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFFEF7FF),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
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
                              child: const Text(
                                'Retry',
                                style: TextStyle(fontFamily: 'Montserrat'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'You have no posts yet',
                          style: TextStyle(fontFamily: 'Montserrat'),
                        ),
                      );
                    }

                    var posts = _selectedTabIndex == 0
                        ? snapshot.data!.where((post) => post.type == 'courier').toList()
                        : snapshot.data!.where((post) => post.type == 'sender').toList();

                    // Apply search filters
                    if (_searchFrom != null) posts = posts.where((post) => post.from == _searchFrom).toList();
                    if (_searchTo != null) posts = posts.where((post) => post.to == _searchTo).toList();
                    if (_searchDate != null) {
                      posts = posts.where((post) =>
                      post.date.year == _searchDate!.year &&
                          post.date.month == _searchDate!.month &&
                          post.date.day == _searchDate!.day).toList();
                    }
                    if (_minPrice != null) posts = posts.where((post) => (post.price ?? 0) >= _minPrice!).toList();
                    if (_maxPrice != null) posts = posts.where((post) => (post.price ?? 0) <= _maxPrice!).toList();

                    // Apply sorting
                    _sortPosts(posts);

                    if (posts.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedTabIndex == 0 ? 'No courier posts available' : 'No sender posts available',
                          style: const TextStyle(fontFamily: 'Montserrat'),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return PostCard(
                          from: post.from,
                          to: post.to,
                          date: post.date,
                          userLocation: post.userLocation,
                          onMorePressed: () => PostDetailsPopup.show(context, post),
                          onDeletePressed: () => _showDeleteConfirmationDialog(post),
                          leading: Icon(
                            post.type == 'sender' ? Icons.send : Icons.local_shipping,
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