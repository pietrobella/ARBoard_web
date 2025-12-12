import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../services/websocket_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.boardManagement);
              },
              child: const Text('Board Management'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go(AppRoutes.boardTool);
              },
              child: const Text('Board Tool'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showSessionSelectionDialog(context),
              child: const Text('Controller Mode'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSessionSelectionDialog(BuildContext context) async {
    final wsService = ARBoardWebSocket();
    // Initialize if not already done (assuming localhost for now, or use config)
    // TODO: Load URL from config
    wsService.init('http://localhost:5090');

    // Fetch sessions
    List<Map<String, dynamic>> sessions = [];
    try {
      sessions = await wsService.getActiveSessions();
    } catch (e) {
      print('Error fetching sessions: $e');
    }

    if (!context.mounted) return;

    String? selectedSessionId;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Session'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sessions.isEmpty)
                    const Text('No active sessions found.')
                  else
                    DropdownButton<String>(
                      value: selectedSessionId,
                      hint: const Text('Choose a session'),
                      isExpanded: true,
                      items: sessions.map((session) {
                        final id = session['id'] as String;
                        final clientCount = session['clients'];
                        final boardId = session['board_id'];

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            '$id (Clients: $clientCount${boardId != null ? ", Board: $boardId" : ""})',
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSessionId = newValue;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedSessionId == null
                      ? null
                      : () {
                          // Join session
                          wsService.connect();
                          wsService.joinSession(selectedSessionId!);
                          Navigator.of(context).pop();

                          // Find selected session to get boardId
                          final session = sessions.firstWhere(
                            (s) => s['id'] == selectedSessionId,
                          );
                          final boardId = session['board_id'];

                          context.go(
                            Uri(
                              path: AppRoutes.controllerMode,
                              queryParameters: boardId != null
                                  ? {'boardId': boardId.toString()}
                                  : null,
                            ).toString(),
                          );
                        },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
