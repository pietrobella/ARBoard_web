import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/websocket_service.dart';
import '../services/board_service.dart';
import '../models/component.dart';
import '../models/net.dart';
import '../widgets/filterable_select_widget.dart';

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
  Map<int, bool> _componentStates = {};
  Map<int, bool> _netStates = {}; // Stati delle net
  bool _isSessionTerminated = false; // Stato per sessione terminata

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

  @override
  void initState() {
    super.initState();
    _sessionId = _wsService.sessionId;

    _setupWebSocketListeners();

    if (widget.boardId != null) {
      _loadData();
    }
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
        // print('Status aggiornato da WebSocket: $status');
        setState(() {
          // Normalizza lo status per sicurezza
          if (_validStatuses.contains(status)) {
            _currentStatus = status;
          }
        });
      }
    };

    // Sync Iniziale Componenti
    _wsService.onComponentSync = (states) {
      if (mounted) {
        setState(() => _componentStates = states);
      }
    };

    // Update Real-time Componenti
    _wsService.onComponentUpdate = (id, state) {
      if (mounted) {
        setState(() {
          _componentStates[id] = state;
        });
      }
    };

    // Sync Iniziale Net
    _wsService.onNetSync = (states) {
      if (mounted) {
        setState(() => _netStates = states);
      }
    };

    // Update Real-time Net
    _wsService.onNetUpdate = (id, state) {
      if (mounted) {
        setState(() {
          _netStates[id] = state;
        });
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
  }

  void _changeStatus(String newStatus) {
    if (_currentStatus == newStatus) return;

    // Aggiorna UI locale e invia al server
    setState(() => _currentStatus = newStatus);
    _wsService.setStatus(newStatus);
  }

  void _toggleComponent(int componentId) {
    print('Toggling component $componentId');
    final currentState = _componentStates[componentId] ?? false;

    // Optimistic Update
    setState(() {
      _componentStates[componentId] = !currentState;
    });

    _wsService.toggleComponent(componentId, !currentState);
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
              const Icon(Icons.link_off, size: 64, color: Colors.orange),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildModeSelector(),
        ),
      ),
      body: _buildBody(),
    );
  }

  // Menu selezione modalità
  Widget _buildModeSelector() {
    return SingleChildScrollView(
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
              selectedColor: Colors.blue.shade100,
              // Stile visivo per la selezione
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
      case 'Function':
      case 'Repair':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.grey),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FilterableMultiSelectWidget<Component>(
            items: _components,
            labelBuilder: (c) => c.name,
            isSelected: (c) => _componentStates[c.id] ?? false,
            onToggle: (c, val) => _toggleComponent(c.id),
            hintText: 'Cerca Componenti...',
          ),
        ],
      ),
    );
  }

  Widget _buildNetList() {
    if (_nets.isEmpty) {
      return const Center(child: Text('Nessuna net trovata.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FilterableMultiSelectWidget<Net>(
            items: _nets,
            labelBuilder: (n) => n.name,
            isSelected: (n) => _netStates[n.id] ?? false,
            onToggle: (n, val) => _toggleNet(n.id),
            hintText: 'Cerca Net...',
          ),
        ],
      ),
    );
  }
}
