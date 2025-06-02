import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final _ = context.locale;
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Color(0xFF352C47),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w400,
      ),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'routes'.tr()),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'create'.tr()),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'my_posts'.tr()),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'history'.tr()),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'profile'.tr()),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}