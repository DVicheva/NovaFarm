import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class BasePage extends StatelessWidget {
  final Widget child;
  final int? currentIndex;
  final String userId; // Ajout du userId

  const BasePage({
    Key? key,
    required this.child,
    this.currentIndex,
    required this.userId, // Requis
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: currentIndex != null
          ? BottomNavBar(currentIndex: currentIndex!, userId: userId)
          : null,
    );
  }
}
