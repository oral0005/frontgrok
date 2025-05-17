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

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  _RoutesScreenState createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final ApiService _apiService = ApiService();
  Future<List<Post>>? _posts; // Remove `late` and make nullable
  String? _currentUserId;
  int _selectedTabIndex = 0;
  String? _searchFrom;
  String? _searchTo;
  DateTime? _searchDate;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'date';
  bool _sortAscending = false;

  final List<String> _kazakhstanCities = [
    'Almaty', 'Astana', 'Shymkent', 'Karaganda', 'Aktobe', 'Taraz', 'Pavlodar',
    'Ust-Kamenogorsk', 'Semey', 'Atyrau', 'Kostanay', 'Kyzylorda', 'Uralsk',
    'Petropavl', 'Aktau', 'Temirtau', 'Turkestan', 'Taldykorgan', 'Ekibastuz',
    'Rudny', 'Zhanaozen', 'Zhezkazgan', 'Kentau', 'Balkhash', 'Satbayev',
    'Kokshetau', 'Saran', 'Shakhtinsk', 'Ridder', 'Arkalyk', 'Lisakovsk', 'Aral',
    'Zhetisay', 'Saryagash', 'Aksu', 'Stepnogorsk', 'Kapchagay',
  ];

  @override
  void initState() {
    super.initState();
    _posts = _loadCurrentUserId(); // Initialize immediately
  }

  Future<List<Post>> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      return await _fetchPosts();
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
      return []; // Return empty list on error
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

      print('Fetched ${senderPosts.length} sender posts and ${courierPosts.length} courier posts');

      return combinedPosts;
    } catch (e) {
      print('Error fetching posts: $e');
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

  void _showSearchDialog() {
    String? tempFrom = _searchFrom;
    String? tempTo = _searchTo;
    DateTime? tempDate = _searchDate;
    double? tempMinPrice = _minPrice;
    double? tempMaxPrice = _maxPrice;
    final minPriceController = TextEditingController(text: tempMinPrice?.toString());
    final maxPriceController = TextEditingController(text: tempMaxPrice?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFEF7FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Search Routes',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'From',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF201731)),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: const TextStyle(
                      fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
                ),
                value: tempFrom,
                items: _kazakhstanCities
                    .map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city,
                      style: const TextStyle(fontFamily: 'Montserrat')),
                ))
                    .toList(),
                onChanged: (value) => tempFrom = value,
                menuMaxHeight: 200,
                isExpanded: true,
                dropdownColor: Colors.white,
                style:
                const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'To',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF201731)),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: const TextStyle(
                      fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
                ),
                value: tempTo,
                items: _kazakhstanCities
                    .map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city,
                      style: const TextStyle(fontFamily: 'Montserrat')),
                ))
                    .toList(),
                onChanged: (value) => tempTo = value,
                menuMaxHeight: 200,
                isExpanded: true,
                dropdownColor: Colors.white,
                style:
                const TextStyle(fontFamily: 'Montserrat', color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: tempDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (selectedDate != null) {
                    tempDate = selectedDate;
                    setState(() {});
                  }
                },
                child: Text(
                  tempDate == null
                      ? 'Select Date'
                      : 'Date: ${tempDate.toString().substring(0, 10)}',
                  style: const TextStyle(
                      fontFamily: 'Montserrat', color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Min Price',
                controller: minPriceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Max Price',
                controller: maxPriceController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              minPriceController.dispose();
              maxPriceController.dispose();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchFrom = tempFrom;
                _searchTo = tempTo;
                _searchDate = tempDate;
                _minPrice = minPriceController.text.isNotEmpty
                    ? double.tryParse(minPriceController.text)
                    : null;
                _maxPrice = maxPriceController.text.isNotEmpty
                    ? double.tryParse(maxPriceController.text)
                    : null;
              });
              minPriceController.dispose();
              maxPriceController.dispose();
              Navigator.pop(context);
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
              'Search',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        ],
      ),
    );
  }

  void _sortPosts(List<Post> posts) {
    if (_sortBy == 'date') {
      posts.sort((a, b) => _sortAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
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
          title: const Text('Routes',
              style: TextStyle(fontFamily: 'Montserrat')),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  if (value == 'date_asc' || value == 'date_desc') {
                    _sortBy = 'date';
                    _sortAscending = value == 'date_asc';
                  } else if (value == 'price_asc' || value == 'price_desc') {
                    _sortBy = 'price';
                    _sortAscending = value == 'price_asc';
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'date_desc',
                  child: Text('Sort by Date (Newest First)',
                      style: TextStyle(fontFamily: 'Montserrat')),
                ),
                const PopupMenuItem(
                  value: 'date_asc',
                  child: Text('Sort by Date (Oldest First)',
                      style: TextStyle(fontFamily: 'Montserrat')),
                ),
                const PopupMenuItem(
                  value: 'price_asc',
                  child: Text('Sort by Price (Low to High)',
                      style: TextStyle(fontFamily: 'Montserrat')),
                ),
                const PopupMenuItem(
                  value: 'price_desc',
                  child: Text('Sort by Price (High to Low)',
                      style: TextStyle(fontFamily: 'Montserrat')),
                ),
              ],
            ),
          ],
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
                  future: _posts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Snapshot error: ${snapshot.error}');
                      return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(fontFamily: 'Montserrat')),
                      );
                    }
                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      print('No posts available in snapshot');
                      return const Center(
                        child: Text('No posts available',
                            style: TextStyle(fontFamily: 'Montserrat')),
                      );
                    }

                    var filteredPosts = _selectedTabIndex == 0
                        ? posts
                        .where((post) =>
                    post.type == 'courier' &&
                        post.userId != _currentUserId)
                        .toList()
                        : posts
                        .where((post) =>
                    post.type == 'sender' &&
                        post.userId != _currentUserId)
                        .toList();

                    print(
                        'Filtered ${_selectedTabIndex == 0 ? 'courier' : 'sender'} posts: ${filteredPosts.length}');

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
                          .where((post) => (post.price ?? 0) >= _minPrice!)
                          .toList();
                    }
                    if (_maxPrice != null) {
                      filteredPosts = filteredPosts
                          .where((post) => (post.price ?? 0) <= _maxPrice!)
                          .toList();
                    }

                    _sortPosts(filteredPosts);

                    if (filteredPosts.isEmpty) {
                      print(
                          'No posts after filtering for ${_selectedTabIndex == 0 ? 'courier' : 'sender'}');
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
                          from: post.from,
                          to: post.to,
                          date: post.date,
                          userLocation: post.userLocation,
                          onMorePressed: () => PostDetailsPopup.show(context, post),
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
}