import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';

/// Board Tool Page
/// 
/// This page allows users to select a board from a dropdown menu
/// and navigate to the board tool detail page via the EDIT button.
/// 
/// Requirements: 5.1, 5.2, 5.3, 5.4
class BoardToolPage extends StatefulWidget {
  const BoardToolPage({super.key});

  @override
  State<BoardToolPage> createState() => _BoardToolPageState();
}

class _BoardToolPageState extends State<BoardToolPage> {
  String? _selectedBoard;
  
  // Mock board list - will be replaced with actual data later
  final List<String> _boards = ['Board 1', 'Board 2', 'Board 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Board',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBoard,
                items: _boards.map((String board) {
                  return DropdownMenuItem<String>(
                    value: board,
                    child: Text(board),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBoard = newValue;
                  });
                },
                hint: const Text('Select a board'),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _selectedBoard != null
                  ? () {
                      context.go('/arboard/board_tool/$_selectedBoard');
                    }
                  : null,
              child: const Text('EDIT'),
            ),
          ],
        ),
      ),
    );
  }
}
