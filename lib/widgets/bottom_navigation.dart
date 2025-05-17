import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white, // Complementary to #FEF7FF
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(0xFF352C47), // Matches button color #201731
      unselectedItemColor: Colors.grey, // Matches grey text in Login/Signup
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600, // SemiBold for selected labels
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w400, // Regular for unselected labels
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Routes'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Posts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}