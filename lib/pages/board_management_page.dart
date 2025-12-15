import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../router/app_router.dart';
import '../models/board.dart';
import '../services/board_service.dart';

/// Board Management Page
///
/// This page allows users to manage existing boards through a dropdown menu
/// and create new boards via the NEW button.
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2
class BoardManagementPage extends StatefulWidget {
  const BoardManagementPage({super.key});

  @override
  State<BoardManagementPage> createState() => _BoardManagementPageState();
}

class _BoardManagementPageState extends State<BoardManagementPage> {
  final BoardService _boardService = BoardService();
  Board? _selectedBoard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW button in top section
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.boardManagementNew);
              },
              child: const Text('NEW'),
            ),
            const SizedBox(height: 20),
            // Dropdown menu and EDIT button row with API integration
            FutureBuilder<List<Board>>(
              future: _boardService.getBoards(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Error loading boards: ${snapshot.error}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Success state
                final boards = snapshot.data ?? [];

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Board>(
                        decoration: const InputDecoration(
                          labelText: 'Select Board',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedBoard,
                        items: boards.isEmpty
                            ? null
                            : boards.map((board) {
                                return DropdownMenuItem<Board>(
                                  value: board,
                                  child: Text(board.name),
                                );
                              }).toList(),
                        onChanged: boards.isEmpty
                            ? null
                            : (Board? newValue) {
                                setState(() {
                                  _selectedBoard = newValue;
                                });
                              },
                        hint: Text(
                          boards.isEmpty
                              ? 'No boards available'
                              : 'Select a board',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectedBoard == null
                          ? null
                          : () {
                              // Navigate to board detail page
                              context.go(
                                AppRoutes.buildBoardDetailRoute(
                                  _selectedBoard!.name,
                                ),
                              );
                            },
                      child: const Text('EDIT'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
