import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/websocket_service.dart';
import '../services/board_service.dart';
import '../models/component.dart';
import '../models/net.dart';

class _AIChatMessage {
  final String text;
  final bool isUser;
  _AIChatMessage(this.text, this.isUser);
}

class _Part {
  final int? id;
  final String name;

  _Part({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Part &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class ControllerModePage extends StatefulWidget {
  final String? boardId;

  const ControllerModePage({super.key, this.boardId});

  @override
  State<ControllerModePage> createState() => _ControllerModePageState();
}

class _ControllerModePageState extends State<ControllerModePage> {
  final _wsService = ARBoardWebSocket();
  final _boardService = BoardService();

  String? _sessionId;
  List<Component> _components = [];
  List<Net> _nets = []; // Lista delle net
  Map<int, List<bool>> _componentStates = {}; // [visible, assembled]
  Map<int, bool> _netStates = {};
  bool _isSessionTerminated = false;

  // Assembly Mode State
  List<_Part> _parts = [];
  _Part? _selectedPart;
  List<Component> _assemblyComponents = [];
  bool _isLoadingParts = false;

  // Search controller for components
  final TextEditingController _componentSearchController =
      TextEditingController();
  final TextEditingController _netSearchController = TextEditingController();

  // Status corrente: 'Component', 'Net', 'Assembly', 'Function', 'Repair'
  String _currentStatus = 'Component';
  final List<String> _validStatuses = const [
    'Component',
    'Net',
    'Assembly',
    'Function',
    'Repair',
  ];

  bool _isLoading = false;
  String? _error;

  // AI Chat State
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_AIChatMessage> _chatMessages = [];
  bool _waitingForAnswer = false;

  @override
  void initState() {
    super.initState();
    _sessionId = _wsService.sessionId;

    _setupWebSocketListeners();

    if (widget.boardId != null) {
      _loadData();
    }

    _componentSearchController.addListener(() {
      setState(() {});
    });
    _netSearchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _componentSearchController.dispose();
    _netSearchController.dispose();
    super.dispose();
  }

  void _setupWebSocketListeners() {
    // Session joined (se non già fatto)
    _wsService.onSessionJoined = (sessionId) {
      if (mounted) {
        setState(() => _sessionId = sessionId);
      }
    };

    // Callback cambio status
    _wsService.onStatusUpdate = (status) {
      if (mounted) {
        setState(() {
          if (_validStatuses.contains(status)) {
            _currentStatus = status;
          }
        });
      }
    };

    // Sync Componenti & Net
    _wsService.onComponentSync = (states) {
      if (mounted) setState(() => _componentStates = states);
    };
    _wsService.onNetSync = (states) {
      if (mounted) setState(() => _netStates = states);
    };

    // Updates Real-time
    _wsService.onComponentUpdate = (id, state) {
      if (mounted) setState(() => _componentStates[id] = state);
    };
    _wsService.onNetUpdate = (id, state) {
      if (mounted) setState(() => _netStates[id] = state);
    };

    // AI Listeners
    _wsService.onAIQuestion = (question, from) {
      if (mounted) {
        setState(() {
          _chatMessages.add(_AIChatMessage(question, true));
          _waitingForAnswer = true;
        });
        _scrollToBottom();

        // Auto-trigger answer generation removed as per new flow requirements.
        // The app now waits passively for the answer.
      }
    };

    _wsService.onAIResponse = (response, done) {
      if (mounted) {
        setState(() {
          _chatMessages.add(_AIChatMessage(response, false));
          _waitingForAnswer = false;
        });
        _scrollToBottom();
      }
    };

    // Session terminated
    _wsService.onSessionTerminated = (reason) {
      if (mounted) {
        setState(() {
          _isSessionTerminated = true;
          _sessionId = null;
          _components = [];
          _nets = [];
        });
      }
    };

    // Part Selected
    _wsService.onPartSelected = (partId) {
      if (mounted) {
        print('Part selected from server: $partId');
        // Find the part object matching the ID
        final newPart = _parts.firstWhere(
          (p) => p.id == partId,
          orElse: () => _nullPart(), // Default to Any/Null if not found
        );

        if (_selectedPart != newPart) {
          setState(() {
            _selectedPart = newPart;
            _assemblyComponents = [];
          });
          if (newPart.id != null) {
            _loadAssemblyComponents();
          }
        }
      }
    };
  }

  _Part _nullPart() => _Part(id: null, name: 'Any');

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendQuestion() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || widget.boardId == null || _sessionId == null) return;

    _chatController.clear();
    // Non aggiungiamo nulla alla lista locale, aspettiamo il broadcast

    try {
      await _boardService.sendTextAssistance(
        widget.boardId!,
        _sessionId!,
        text,
      );
    } catch (e) {
      print('Errore invio domanda: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final boardId = widget.boardId!;

      // Carica componenti e net in parallelo
      final results = await Future.wait([
        _boardService.getComponents(boardId),
        _boardService.getNets(boardId),
      ]);

      final components = results[0] as List<Component>;
      final nets = results[1] as List<Net>;

      // Ordina per nome
      components.sort((a, b) => a.name.compareTo(b.name));
      nets.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _components = components;
          _nets = nets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Errore caricamento dati: $e';
          _isLoading = false;
        });
      }
    }

    // Load parts if we are in Assembly mode or just preload them
    await _loadParts();
  }

  Future<void> _loadParts() async {
    if (widget.boardId == null) return;
    try {
      final result = await _boardService.getDistinctParts(
        widget.boardId!,
        includeNull: true,
      );
      if (mounted) {
        final List<dynamic> rawParts = result['parts'] ?? [];
        final List<_Part> parsedParts = rawParts.map((p) {
          return _Part(id: p['id'] as int?, name: p['name'] as String);
        }).toList();

        // Add 'Any' option at the beginning if not present
        // (Assuming server might not return explicit null part if includeNull is just for filtering?
        // User request: "Uno di quei campi sarà anche 'Any'")
        // We'll manually add 'Any' (id: null)
        if (!parsedParts.any((p) => p.id == null)) {
          parsedParts.insert(0, _nullPart());
        }

        setState(() {
          _parts = parsedParts;
          // Verify current selection is still valid
          if (_selectedPart != null && !_parts.contains(_selectedPart)) {
            _selectedPart = parsedParts.first; // Default to Any
          } else if (_selectedPart == null && _parts.isNotEmpty) {
            _selectedPart = parsedParts.first;
          }
        });
      }
    } catch (e) {
      print('Error loading parts: $e');
    }
  }

  Future<void> _loadAssemblyComponents() async {
    if (widget.boardId == null ||
        _selectedPart == null ||
        _selectedPart!.id == null)
      return;
    setState(() => _isLoadingParts = true);
    try {
      final components = await _boardService.getComponentsByPart(
        widget.boardId!,
        _selectedPart!.id!,
      );
      if (mounted) {
        setState(() {
          _assemblyComponents = components;
          _isLoadingParts = false;
        });
      }
    } catch (e) {
      print('Error loading assembly components: $e');
      if (mounted) setState(() => _isLoadingParts = false);
    }
  }

  void _onPartChanged(_Part? newValue) {
    if (newValue != null && newValue != _selectedPart) {
      // Send socket event to server
      // Server will respond with 'part:selected', triggering update.
      _wsService.selectPart(newValue.id);

      // We do NOT update state locally here, we wait for server confirmation.
    }
  }

  void _changeStatus(String newStatus) {
    if (_currentStatus == newStatus) return;

    // Aggiorna UI locale e invia al server
    setState(() => _currentStatus = newStatus);
    _wsService.setStatus(newStatus);
  }

  void _toggleComponent(int componentId) {
    print('Toggling component $componentId');
    final currentState = _componentStates[componentId] ?? [false, false];
    final isVisible = currentState.isNotEmpty ? currentState[0] : false;
    final isAssembled = currentState.length > 1 ? currentState[1] : false;

    // In Component Mode, we typically just toggle visibility
    final newVisible = !isVisible;

    // Optimistic Update
    setState(() {
      _componentStates[componentId] = [newVisible, isAssembled];
    });

    _wsService.toggleComponent(componentId, newVisible, isAssembled);
  }

  void _setComponentAssembled(int componentId, bool assembled) {
    final currentState = _componentStates[componentId] ?? [false, false];
    final isVisible = currentState.isNotEmpty ? currentState[0] : false;

    // Optimistic Update
    setState(() {
      _componentStates[componentId] = [isVisible, assembled];
    });

    _wsService.toggleComponent(componentId, isVisible, assembled);
  }

  void _toggleComponentVisibility(int componentId, bool visible) {
    final currentState = _componentStates[componentId] ?? [false, false];
    final isAssembled = currentState.length > 1 ? currentState[1] : false;

    setState(() {
      _componentStates[componentId] = [visible, isAssembled];
    });

    _wsService.toggleComponent(componentId, visible, isAssembled);
  }

  void _toggleNet(int netId) {
    print('Toggling net $netId');
    final currentState = _netStates[netId] ?? false;

    // Optimistic Update
    setState(() {
      _netStates[netId] = !currentState;
    });

    _wsService.toggleNet(netId, !currentState);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionTerminated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off,
                size: 64,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Sessione terminata',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('L\'amministratore ha chiuso la sessione.'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Ritorna alla Home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Controller Mode'),
            Text(
              'Session: ${_sessionId ?? "..."}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint arbitrario per Desktop/Mobile (700px)
          if (constraints.maxWidth > 700) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panello Sinistro: Mode Selector + Content
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildModeSelector(),
              Expanded(child: _buildContentArea()),
            ],
          ),
        ),
        // Separatore
        const VerticalDivider(width: 1),
        // Pannello Destro: AI Chat
        Expanded(flex: 1, child: _buildAIChatSection()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildModeSelector(),
        Expanded(child: _buildContentArea()),
        const Divider(height: 1),
        // Sezione AI Chat in fondo
        SizedBox(height: 300, child: _buildAIChatSection()),
      ],
    );
  }

  // Menu selezione modalità
  Widget _buildModeSelector() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: _validStatuses.map((status) {
            final isSelected = _currentStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (_) => _changeStatus(status),
                selectedColor: Theme.of(context).colorScheme.tertiary,
                // Stile visivo per la selezione
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onTertiary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAIChatSection() {
    return Column(
      children: [
        // Header Chat
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.primaryContainer,
          width: double.infinity,
          child: Text(
            'AI Assistant',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        // History
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              return Align(
                alignment: msg.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.surface,
                    border: msg.isUser
                        ? null
                        : Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser
                          ? Theme.of(context).colorScheme.onTertiary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Input Area
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  enabled: !_waitingForAnswer,
                  onSubmitted: (_) =>
                      !_waitingForAnswer ? _sendQuestion() : null,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi una domanda...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _waitingForAnswer
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _waitingForAnswer ? null : _sendQuestion,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.boardId != null ? _loadData() : null,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (widget.boardId == null) {
      return const Center(
        child: Text('Nessuna board associata a questa sessione.'),
      );
    }

    // Switch contenuto in base alla modalità corrente
    switch (_currentStatus) {
      case 'Component':
        return _buildComponentList();
      case 'Net':
        return _buildNetList();
      case 'Assembly':
        return _buildAssemblyMode();
      case 'Function':
      case 'Repair':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Modalità $_currentStatus',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Nessun controllo disponibile per questa modalità.'),
            ],
          ),
        );
      default:
        return const Center(child: Text('Stato sconosciuto'));
    }
  }

  Widget _buildComponentList() {
    if (_components.isEmpty) {
      return const Center(child: Text('Nessun componente trovato.'));
    }

    final activeComponents = _components.where((c) {
      final state = _componentStates[c.id];
      return state != null && state.isNotEmpty && state[0];
    }).toList();
    final inactiveComponents = _components.where((c) {
      final state = _componentStates[c.id];
      return state == null || state.isEmpty || !state[0];
    }).toList();

    // Filter inactive components based on search
    final query = _componentSearchController.text.toLowerCase();
    final filteredInactive = inactiveComponents.where((c) {
      return c.name.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Available / Inactive
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _componentSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Cerca Componenti...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: filteredInactive.length,
                      itemBuilder: (context, index) {
                        final item = filteredInactive[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(item.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => _toggleComponent(item.id),
                            ),

                            onTap: null, // Interaction moved to IconButton
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column: Active
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header to align with search bar height (approx 48)
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attivi (${activeComponents.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: activeComponents.length,
                      itemBuilder: (context, index) {
                        final item = activeComponents[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => _toggleComponent(item.id),
                            ),

                            onTap: null, // Interaction moved to IconButton
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssemblyMode() {
    if (_parts.isEmpty) {
      if (_isLoadingParts) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Nessuna Part disponibile.'));
    }

    return Column(
      children: [
        // Parts Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Row(
            children: [
              const Text(
                'Seleziona Part:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<_Part>(
                  value: _selectedPart,
                  isExpanded: true,
                  isDense: true, // More compact
                  hint: const Text('Seleziona una part'),
                  items: _parts.map((_Part part) {
                    return DropdownMenuItem<_Part>(
                      value: part,
                      child: Text(part.name),
                    );
                  }).toList(),
                  onChanged: _onPartChanged,
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingParts)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_assemblyComponents.isEmpty)
          const Expanded(
            child: Center(child: Text('Nessun componente in questa part.')),
          )
        else
          Expanded(child: _buildAssemblyColumns()),
      ],
    );
  }

  Widget _buildAssemblyColumns() {
    // Left: Non-Assembled (state[1] == false)
    // Right: Assembled (state[1] == true)
    final nonAssembled = _assemblyComponents.where((c) {
      final state = _componentStates[c.id];
      // Default to non-assembled if state is missing
      return state == null || state.length < 2 || !state[1];
    }).toList();

    final assembled = _assemblyComponents.where((c) {
      final state = _componentStates[c.id];
      return state != null && state.length >= 2 && state[1];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Da Assemblare (${nonAssembled.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: nonAssembled.length,
                      itemBuilder: (context, index) {
                        final item = nonAssembled[index];
                        final state =
                            _componentStates[item.id] ?? [false, false];
                        final isVisible = state.isNotEmpty ? state[0] : false;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(item.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Toggle Visibility
                                IconButton(
                                  icon: Icon(
                                    isVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: isVisible
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleComponentVisibility(
                                    item.id,
                                    !isVisible,
                                  ),
                                ),
                                // Flag as Assembled
                                IconButton(
                                  icon: const Icon(Icons.flag), // Flag icon
                                  color: Theme.of(context).colorScheme.tertiary,
                                  onPressed: () =>
                                      _setComponentAssembled(item.id, true),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Assemblati (${assembled.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: assembled.length,
                      itemBuilder: (context, index) {
                        final item = assembled[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.undo),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () =>
                                  _setComponentAssembled(item.id, false),
                              tooltip: 'Sposta nei non assemblati',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetList() {
    if (_nets.isEmpty) {
      return const Center(child: Text('Nessuna net trovata.'));
    }

    final activeNets = _nets.where((n) => _netStates[n.id] == true).toList();
    final inactiveNets = _nets.where((n) => _netStates[n.id] != true).toList();

    // Filter inactive nets based on search
    final query = _netSearchController.text.toLowerCase();
    final filteredInactive = inactiveNets.where((n) {
      return n.name.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Available / Inactive
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _netSearchController,
                  decoration: const InputDecoration(
                    hintText: 'Cerca Net...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: filteredInactive.length,
                      itemBuilder: (context, index) {
                        final item = filteredInactive[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(item.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => _toggleNet(item.id),
                            ),

                            onTap: null, // Interaction moved to IconButton
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column: Active
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header to align with search bar height (approx 48)
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attivi (${activeNets.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: activeNets.length,
                      itemBuilder: (context, index) {
                        final item = activeNets[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => _toggleNet(item.id),
                            ),

                            onTap: null, // Interaction moved to IconButton
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
