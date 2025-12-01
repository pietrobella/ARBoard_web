import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

/// Limited Information Page
/// 
/// This page is displayed when a user chooses to create a board
/// with limited information. Currently contains placeholder content.
/// 
/// Requirements: 4.5
class LimitedInfoPage extends StatelessWidget {
  const LimitedInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: const Center(
        child: Text(
          'Limited Information Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
