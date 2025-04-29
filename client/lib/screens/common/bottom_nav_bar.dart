import 'package:flutter/material.dart';
import '../../config/color_system.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          activeIcon: Icon(Icons.list_alt, color: AppColors.primary),
          label: '여행',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_walk),
          activeIcon: Icon(Icons.directions_walk, color: AppColors.primary),
          label: '진행중',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          activeIcon: Icon(Icons.person, color: AppColors.primary),
          label: '프로필',
        ),
      ],
    );
  }
} 