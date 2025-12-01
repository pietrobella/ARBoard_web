import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../router/app_router.dart';

/// New Board Page
/// 
/// This page allows users to choose between creating a board with
/// complete information or limited information.
/// 
/// Requirements: 4.2, 4.3, 4.4, 4.5
class NewBoardPage extends StatelessWidget {
  const NewBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.boardManagementComplete);
              },
              child: const Text('Complete Information'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.boardManagementLimited);
              },
              child: const Text('Limited Information'),
            ),
          ],
        ),
      ),
    );
  }
}
