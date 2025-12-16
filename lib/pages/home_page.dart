import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../services/websocket_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF012035),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 150, // Adjust height as needed
                  fit: BoxFit.contain,
                ),
              ),
              // Buttons Area using Wrap for responsiveness
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    _HomeButton(
                      title: 'Board Management',
                      imagePath: 'assets/button/board_management.jpg',
                      onTap: () {
                        context.go(AppRoutes.boardManagement);
                      },
                    ),
                    _HomeButton(
                      title: 'Board Tool',
                      subtitle: 'Work in Progress',
                      imagePath: 'assets/button/board_tool_wip.jpg',
                      isDisabled: true,
                      onTap: () {
                        // Disabled
                      },
                    ),
                    _HomeButton(
                      title: 'Controller Mode',
                      imagePath: 'assets/button/controller_mode.jpg',
                      onTap: () => _showSessionSelectionDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      debugPrint('Error fetching sessions: $e');
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

class _HomeButton extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final bool isDisabled;

  const _HomeButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.imagePath,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDisabled ? null : widget.onTap,
      child: MouseRegion(
        onEnter: (_) {
          if (!widget.isDisabled) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (!widget.isDisabled) {
            setState(() => _isHovered = false);
          }
        },
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Internal Square Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.cover,
                  colorFilter: widget.isDisabled
                      ? const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        )
                      : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.5 : 0.3),
                    blurRadius: _isHovered ? 15 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: const Color(
                    0xFF8FBABF,
                  ).withOpacity(_isHovered ? 1.0 : 0.5),
                  width: _isHovered ? 2 : 1,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _isHovered && !widget.isDisabled
                      ? Colors.black.withOpacity(0.3) // Darken on hover
                      : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Text outside
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
