import 'package:flutter/material.dart';
import 'routes_screen.dart';
import 'create_form_screen.dart';
import 'my_posts_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import '../widgets/bottom_navigation.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  final User currentUser; // Assuming you pass the current user
  const HomeScreen({super.key, required this.currentUser});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RoutesScreen(),
      CreateFormScreen(currentUser: widget.currentUser),
      const MyPostsScreen(),
      HistoryScreen(currentUser: widget.currentUser),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}