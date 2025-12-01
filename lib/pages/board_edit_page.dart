import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../models/board.dart';
import '../services/board_service.dart';
import '../router/app_router.dart';

/// Board Edit Page
/// 
/// This page allows editing a specific board.
/// If the board doesn't exist, shows an error message.
class BoardEditPage extends StatelessWidget {
  final String boardName;
  final BoardService _boardService = BoardService();

  BoardEditPage({super.key, required this.boardName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: FutureBuilder<List<Board>>(
        future: _boardService.getBoards(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Errore nel caricamento',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.go(AppRoutes.boardManagement);
                      },
                      child: const Text('Torna a Board Management'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Success - check if board exists
          final boards = snapshot.data ?? [];
          final board = boards.firstWhere(
            (b) => b.name == boardName,
            orElse: () => Board(id: '', name: ''),
          );

          // Board not found
          if (board.id.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Board non trovata',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La board "$boardName" non esiste',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go(AppRoutes.boardManagement);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Torna a Board Management'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Board found - show edit page
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Questa è la pagina di edit di',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    board.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${board.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go(AppRoutes.boardManagement);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Torna a Board Management'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
