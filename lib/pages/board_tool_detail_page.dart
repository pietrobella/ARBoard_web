import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

/// Board Tool Detail Page
/// 
/// This page displays details for a specific board identified by boardName.
/// Currently shows placeholder content.
/// 
/// Requirements: 5.4, 5.5
class BoardToolDetailPage extends StatelessWidget {
  final String boardName;

  const BoardToolDetailPage({super.key, required this.boardName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Board Tool Detail',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Board: $boardName',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              const Text(
                'Placeholder content - to be implemented',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
