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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Routes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: tempFrom,
                items: _kazakhstanCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                onChanged: (value) => tempFrom = value,
                menuMaxHeight: 200,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: tempTo,
                items: _kazakhstanCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                onChanged: (value) => tempTo = value,
                menuMaxHeight: 200,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: tempDate ?? DateTime.now(),
                    firstDate: DateTime.now(), // Ограничиваем выбор дат прошлым
                    lastDate: DateTime(2030),
                  );
                  if (selectedDate != null) tempDate = selectedDate;
                },
                child: Text(tempDate == null ? 'Select Date' : 'Date: ${tempDate.toString().substring(0, 10)}'),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Min Price',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => tempMinPrice = value.isNotEmpty ? double.tryParse(value) : null,
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Max Price',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => tempMaxPrice = value.isNotEmpty ? double.tryParse(value) : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchFrom = tempFrom;
                _searchTo = tempTo;
                _searchDate = tempDate;
                _minPrice = tempMinPrice;
                _maxPrice = tempMaxPrice;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Search'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearchDialog),
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
              const PopupMenuItem(value: 'date_desc', child: Text('Sort by Date (Newest First)')),
              const PopupMenuItem(value: 'date_asc', child: Text('Sort by Date (Oldest First)')),
              const PopupMenuItem(value: 'price_asc', child: Text('Sort by Price (Low to High)')),
              const PopupMenuItem(value: 'price_desc', child: Text('Sort by Price (High to Low)')),
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
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No posts available'));
                  }

                  // Фильтрация постов
                  var posts = _selectedTabIndex == 0
                      ? snapshot.data!.where((post) => post.type == 'courier' && post.userId != _currentUserId).toList()
                      : snapshot.data!.where((post) => post.type == 'sender' && post.userId != _currentUserId).toList();

                  // Фильтр для исключения прошедших постов
                  final now = DateTime.now();
                  posts = posts.where((post) => post.date.isAfter(now)).toList();

                  // Применение поисковых фильтров
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

                  // Применение сортировки
                  _sortPosts(posts);

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
                        from: post.from,
                        to: post.to,
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