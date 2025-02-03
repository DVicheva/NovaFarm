import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String? userId; // userId devient optionnel

  const BottomNavBar({Key? key, required this.currentIndex, this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/statistics',
                arguments: userId);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/home',
                arguments: userId);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/settings',
                arguments: userId);
          }
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.bar_chart,
            color: currentIndex == 0 ? Colors.green : Colors.grey,
          ),
          label: 'Statistiques',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
            color: currentIndex == 1 ? Colors.green : Colors.grey,
          ),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: currentIndex == 2 ? Colors.green : Colors.grey,
          ),
          label: 'Paramètres',
        ),
      ],
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    );
  }
}
