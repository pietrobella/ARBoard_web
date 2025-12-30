import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/websocket_service.dart';
import '../services/board_service.dart';
import '../models/component.dart';
import '../models/net.dart';
import '../models/label.dart';

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

  // Function Mode State
  List<Label> _labels = [];
  Label? _selectedFunction;
  List<SubLabel> _currentSubLabels = [];
  Map<int, bool> _subLabelStates = {};
  bool _noSubLabelActive = false;
  bool _isLoadingFunctions = false;
  bool _isLoadingSubLabels = false;

  // Pending updates (for sync when data is loading)
  int? _pendingFunctionId;
  bool? _pendingFunctionState;
  bool _hasPendingFunction = false;

  // Search controller for components
  final TextEditingController _componentSearchController =
      TextEditingController();
  final TextEditingController _netSearchController = TextEditingController();
  final TextEditingController _functionSearchController =
      TextEditingController();

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

    _componentSearchController.addListener(() => setState(() {}));
    _netSearchController.addListener(() => setState(() {}));
    _functionSearchController.addListener(() => setState(() {}));

    // Initialize with current WebSocket state if available
    // (This fixes the issue where events fired before this page loaded are missed)
    if (_wsService.currentFunctionId != null ||
        _wsService.currentFunctionVisible != true) {
      _pendingFunctionId = _wsService.currentFunctionId;
      _pendingFunctionState = _wsService.currentFunctionVisible;
      _hasPendingFunction = true;
      // We can't call _applyPendingFunction here because labels aren't loaded yet.
      // logic in _loadFunctions will pick this up.
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _componentSearchController.dispose();
    _netSearchController.dispose();
    _functionSearchController.dispose();
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

    // Function Selected
    // Function Selected
    // Function Selected
    _wsService.onFunctionSelected = (functionId, state) {
      if (mounted) {
        print('Function selected from server: $functionId, visible: $state');
        _pendingFunctionId = functionId;
        _pendingFunctionState = state;
        _hasPendingFunction = true;
        _applyPendingFunction();
      }
    };

    _wsService.onSubLabelUpdate = (subLabelId, state) {
      if (mounted) {
        setState(() => _subLabelStates[subLabelId] = state);
      }
    };
  }

  _Part _nullPart() => _Part(id: null, name: 'Any');
  Label _nullLabel() =>
      Label(id: -1, name: 'None'); // Using -1 for 'None' as ID is int

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
    await _loadParts();
    await _loadFunctions();
    await _syncSessionState();
  }

  Future<void> _syncSessionState() async {
    final sessionId = _sessionId ?? _wsService.sessionId;
    if (sessionId == null) return;

    try {
      final sessions = await _wsService.getActiveSessions();
      final session = sessions.firstWhere(
        (s) => s['session_id'] == sessionId || s['id'] == sessionId,
        orElse: () => {},
      );

      if (session.isEmpty) return;

      if (mounted) {
        // Sync Mode
        final mode = session['mode'] as String?;
        if (mode != null && _validStatuses.contains(mode)) {
          if (_currentStatus != mode) {
            _changeStatus(mode);
          }
        }

        // Sync Function
        final funcData = session['function'];
        if (funcData != null && funcData is Map) {
          final name = funcData['name'] as String?;
          final visible = funcData['visible'] as bool? ?? true;

          if (name != null) {
            // Find label by name
            final label = _labels.firstWhere(
              (l) => l.name == name,
              orElse: () => _nullLabel(),
            );

            // Apply if valid or explicitly None
            if (label.id != -1 || name == 'None') {
              // Update if different
              if (_selectedFunction?.id != label.id) {
                setState(() {
                  _selectedFunction = label;
                  _noSubLabelActive = visible;
                  _currentSubLabels = [];
                });
                if (label.id != -1) {
                  _loadSubLabels(label.id);
                }
              } else {
                // Update visibility if same label
                if (_noSubLabelActive != visible) {
                  setState(() => _noSubLabelActive = visible);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error syncing session state: $e');
    }
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
    // Rimuovi il focus dal dropdown per evitare effetti visivi persistenti
    FocusScope.of(context).requestFocus(FocusNode());

    if (newValue != null && newValue != _selectedPart) {
      // Show loader immediately to avoid seeing previous components turn off
      setState(() => _isLoadingParts = true);

      // Send socket event to server
      // Server will respond with 'part:selected', triggering update.
      _wsService.selectPart(newValue.id);

      // We do NOT update state locally here, we wait for server confirmation.
    }
  }

  void _onFunctionSelected(Label newValue) {
    if (newValue.id != _selectedFunction?.id) {
      _wsService.setFunction(newValue.id == -1 ? null : newValue.id);
      // Wait for server confirmation
    }
  }

  Future<void> _loadFunctions() async {
    if (widget.boardId == null) return;
    setState(() => _isLoadingFunctions = true);
    try {
      final labels = await _boardService.getLabels(widget.boardId!);
      if (mounted) {
        // Add "None" (Any) option.
        if (!labels.any((l) => l.id == -1)) {
          labels.insert(0, _nullLabel()); // -1 for None
        }
        setState(() {
          _labels = labels;
          _isLoadingFunctions = false;

          // Retry pending function selection
          if (_hasPendingFunction) {
            _applyPendingFunction();
          } else {
            // Default selection if not set
            if (_selectedFunction == null && _labels.isNotEmpty) {
              _selectedFunction = labels.first;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading functions: $e');
      if (mounted) setState(() => _isLoadingFunctions = false);
    }
  }

  Future<void> _loadSubLabels(int labelId) async {
    setState(() => _isLoadingSubLabels = true);
    try {
      final subLabels = await _boardService.getSubLabels(labelId);
      if (mounted) {
        setState(() {
          _currentSubLabels = subLabels;
          _isLoadingSubLabels = false;
        });
      }
    } catch (e) {
      print('Error loading sublabels: $e');
      if (mounted) setState(() => _isLoadingSubLabels = false);
    }
  }

  void _applyPendingFunction() {
    if (!mounted) return;

    // Check if we actually have labels loaded.
    // If not, we can't map the ID to a Label object yet.
    if (_labels.isEmpty) {
      return;
    }

    // Capture pending values and reset flag?
    // Ideally we keep them until successfully applied or overwritten.
    final targetId = _pendingFunctionId;

    // Find the label. If targetId is null, it maps to None (which should be present as -1 or initialized)
    // We used _nullLabel() which has id = -1.
    // So if targetId is null, we look for -1.
    final searchId = targetId ?? -1;

    final newFunction = _labels.firstWhere(
      (l) => l.id == searchId,
      orElse: () => _nullLabel(),
    );

    // Update if changed OR if state (visibility) needs update
    final bool stateChanged =
        _noSubLabelActive != (_pendingFunctionState ?? true);

    if (_selectedFunction?.id != newFunction.id) {
      setState(() {
        _selectedFunction = newFunction;
        _currentSubLabels = [];
        // Apply the pending state (Bug 1 Fix)
        if (_pendingFunctionState != null) {
          _noSubLabelActive = _pendingFunctionState!;
        } else {
          _noSubLabelActive = true; // Default
        }
      });
      if (newFunction.id != -1) {
        _loadSubLabels(newFunction.id);
      }
    } else if (stateChanged) {
      // Same function, but visibility toggled
      setState(() {
        _noSubLabelActive = _pendingFunctionState ?? true;
      });
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
        return _buildFunctionMode();
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

  Widget _buildFunctionMode() {
    // Filter functions
    final query = _functionSearchController.text.toLowerCase();
    final filteredLabels = _labels.where((l) {
      return l.name.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(
                  controller: _functionSearchController,
                  hint: 'Search Functions...',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
                    child: _isLoadingFunctions
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: filteredLabels.length,
                            itemBuilder: (context, index) {
                              final label = filteredLabels[index];
                              final isSelected =
                                  _selectedFunction?.id == label.id;
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(label.name),
                                    selected: isSelected,
                                    selectedTileColor: Colors.transparent,
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () => _onFunctionSelected(label),
                                  ),
                                  if (isSelected &&
                                      label.id != -1 &&
                                      _currentSubLabels.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                      ),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      child: _isLoadingSubLabels
                                          ? const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : Column(
                                              children: _currentSubLabels.map((
                                                sub,
                                              ) {
                                                final isActive =
                                                    _subLabelStates[sub.id] ??
                                                    false;
                                                return SwitchListTile(
                                                  title: Text(sub.name),
                                                  value: isActive,
                                                  onChanged: (val) {
                                                    setState(
                                                      () =>
                                                          _subLabelStates[sub
                                                                  .id] =
                                                              val,
                                                    );
                                                    _wsService.toggleSubLabel(
                                                      sub.id,
                                                      val,
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                    ),
                                ],
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
                _buildTopHeader(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Show no-sublabel component'),
                      const SizedBox(width: 8),
                      Switch(
                        value: _noSubLabelActive,
                        onChanged: (val) {
                          if (_selectedFunction != null &&
                              _selectedFunction!.id != -1) {
                            setState(() => _noSubLabelActive = val);
                            _wsService.toggleNoSubLabel(
                              _selectedFunction!.id,
                              val,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Active Components',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Expanded(child: _buildActiveComponentsList()),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Active Nets',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Expanded(child: _buildActiveNetsList()),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildActiveComponentsList() {
    final activeComponents = _components.where((c) {
      final state = _componentStates[c.id];
      return state != null && state.isNotEmpty && state[0];
    }).toList();

    if (activeComponents.isEmpty) {
      return const Center(child: Text('No active components'));
    }
    return ListView.builder(
      itemCount: activeComponents.length,
      itemBuilder: (context, index) {
        return ListTile(
          dense: true,
          title: Text(activeComponents[index].name),
          leading: const Icon(
            Icons.settings_input_component,
            color: Colors.green,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildActiveNetsList() {
    final activeNets = _nets.where((n) {
      return _netStates[n.id] == true;
    }).toList();

    if (activeNets.isEmpty) {
      return const Center(child: Text('No active nets'));
    }

    return ListView.builder(
      itemCount: activeNets.length,
      itemBuilder: (context, index) {
        return ListTile(
          dense: true,
          title: Text(activeNets[index].name),
          leading: const Icon(Icons.hub, color: Colors.blue, size: 20),
        );
      },
    );
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
          // Left Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(
                  controller: _componentSearchController,
                  hint: 'Cerca Componenti...',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
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
                            onTap: null,
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
                _buildTopHeader(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Attivi (${activeComponents.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
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
                            onTap: null,
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
    // Show columns even if empty (Giant Box style)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Search (Part Selector) + Unassembled
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Part Selector styled as Search Field
                InputDecorator(
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(),
                    hintText: 'Seleziona una Part...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_Part>(
                      value: _selectedPart,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
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
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
                    child: _isLoadingParts
                        ? const Center(child: CircularProgressIndicator())
                        : _buildUnassembledList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right Column: Header + Assembled
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(
                  // Empty or title for the right column
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Assemblati',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
                    child: _isLoadingParts
                        ? const Center(child: CircularProgressIndicator())
                        : _buildAssembledList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassembledList() {
    // Left: Non-Assembled (state[1] == false)
    final nonAssembled = _assemblyComponents.where((c) {
      final state = _componentStates[c.id];
      // Default to non-assembled if state is missing
      return state == null || state.length < 2 || !state[1];
    }).toList();

    if (nonAssembled.isEmpty) {
      if (_selectedPart == null || _selectedPart!.id == null) {
        return const Center(child: Text('Seleziona una part specifica.'));
      }
      return const Center(child: Text('Tutti i componenti sono assemblati.'));
    }

    return ListView.builder(
      itemCount: nonAssembled.length,
      itemBuilder: (context, index) {
        final item = nonAssembled[index];
        final state = _componentStates[item.id] ?? [false, false];
        final isVisible = state.isNotEmpty ? state[0] : false;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
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
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    color: isVisible
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  onPressed: () =>
                      _toggleComponentVisibility(item.id, !isVisible),
                ),
                // Flag as Assembled
                IconButton(
                  icon: const Icon(Icons.flag), // Flag icon
                  color: Theme.of(context).colorScheme.tertiary,
                  onPressed: () => _setComponentAssembled(item.id, true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssembledList() {
    // Right: Assembled (state[1] == true)
    final assembled = _assemblyComponents.where((c) {
      final state = _componentStates[c.id];
      return state != null && state.length >= 2 && state[1];
    }).toList();

    if (assembled.isEmpty) {
      return const Center(child: Text('Nessun componente assemblato.'));
    }
    return ListView.builder(
      itemCount: assembled.length,
      itemBuilder: (context, index) {
        final item = assembled[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: ListTile(
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.undo),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _setComponentAssembled(item.id, false),
              tooltip: 'Sposta nei non assemblati',
            ),
          ),
        );
      },
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
          // Left Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(
                  controller: _netSearchController,
                  hint: 'Cerca Net...',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
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
                            onTap: null,
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
                _buildTopHeader(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Attivi (${activeNets.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildGiantBox(
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
                            onTap: null,
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
              )
            : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      ),
    );
  }

  Widget _buildGiantBox({required Widget? child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget _buildTopHeader({
    required Widget child,
    AlignmentGeometry alignment = Alignment.centerLeft,
  }) {
    // Aligns the header to a standard height (e.g. 48 for search field)
    return SizedBox(
      height: 48,
      child: Align(alignment: alignment, child: child),
    );
  }
}
