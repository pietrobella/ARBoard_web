import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';

class ARBoardWebSocket {
  late IO.Socket socket;
  bool _isInitialized = false;
  String? sessionId;
  int? currentBoardId;

  // Callbacks
  Function(String)? onSessionCreated;
  Function(String)? onSessionJoined;
  Function(int)? onBoardSelected;
  Function(Map<int, List<bool>>)? onComponentSync; // Changed to List<bool>
  Function(Map<int, bool>)? onNetSync;
  Function(List<Map<String, dynamic>>)? onAIHistory;
  Function(int, List<bool>)? onComponentUpdate; // Changed to List<bool>
  Function(int, bool)? onNetUpdate;
  Function(String, String)? onAIQuestion;
  Function(String, bool)? onAIResponse;
  Function(String)? onError;
  Function(String)? onStatusUpdate; // Callback per aggiornamento status
  Function(String)? onSessionTerminated; // Callback per sessione terminata
  Function(int?)? onPartSelected; // Callback per selezione part

  // Singleton instance
  static final ARBoardWebSocket _instance = ARBoardWebSocket._internal();

  factory ARBoardWebSocket() {
    return _instance;
  }

  ARBoardWebSocket._internal();

  void init(String serverUrl) {
    if (_isInitialized) return;

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _setupListeners();
    _isInitialized = true;
  }

  void _setupListeners() {
    socket.onConnect((_) => print('✅ Connected'));
    socket.onDisconnect((_) => print('❌ Disconnected'));

    socket.on('error', (data) {
      onError?.call(data['message']);
    });

    // Session
    socket.on('session:created', (data) {
      sessionId = data['session_id'];
      onSessionCreated?.call(sessionId!);
    });

    socket.on('session:joined', (data) {
      sessionId = data['session_id'];
      onSessionJoined?.call(sessionId!);
    });

    socket.on('session:status', (data) {
      onStatusUpdate?.call(data['status']);
    });

    socket.on('session:terminated', (data) {
      onSessionTerminated?.call(data['reason'] ?? 'Sessione terminata');
    });

    // Board
    socket.on('board:selected', (data) {
      currentBoardId = data['board_id'];
      onBoardSelected?.call(currentBoardId!);
    });

    socket.on('part:active', (data) {
      final partId = data['part_id'] as int?;
      onPartSelected?.call(partId);
    });

    // Sync
    socket.on('component:sync', (data) {
      onComponentSync?.call(_parseComponentStates(data['states']));
    });

    socket.on('net:sync', (data) {
      onNetSync?.call(_parseNetStates(data['states']));
    });

    socket.on('ai:history', (data) {
      onAIHistory?.call(List<Map<String, dynamic>>.from(data['messages']));
    });

    // Updates
    socket.on('component:state', (data) {
      final rawState = data['state'];
      List<bool> stateTuple = [false, false];

      if (rawState is bool) {
        stateTuple = [rawState, false];
      } else if (rawState is List && rawState.isNotEmpty) {
        stateTuple = rawState
            .map((e) => e as bool)
            .toList(); // Ensure List<bool>
      }
      onComponentUpdate?.call(data['component_id'], stateTuple);
    });

    socket.on('net:state', (data) {
      onNetUpdate?.call(data['net_id'], data['state']);
    });

    // AI
    socket.on('ai:question:broadcast', (data) {
      onAIQuestion?.call(data['question'], data['from']);
    });

    socket.on('ai:response', (data) {
      onAIResponse?.call(data['response'], data['done']);
    });
  }

  Map<int, List<bool>> _parseComponentStates(dynamic states) {
    final result = <int, List<bool>>{};
    if (states is Map) {
      states.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id == null) return;

        if (value is bool) {
          result[id] = [value, false];
        } else if (value is List) {
          result[id] = value.map((e) => e as bool).toList();
        } else {
          // Default fallback
          result[id] = [false, false];
        }
      });
    }
    return result;
  }

  Map<int, bool> _parseNetStates(dynamic states) {
    final result = <int, bool>{};
    if (states is Map) {
      states.forEach((key, value) {
        final id = int.tryParse(key.toString());
        if (id == null) return;

        if (value is bool) {
          result[id] = value;
        } else if (value is List && value.isNotEmpty) {
          result[id] = value[0] as bool;
        } else {
          result[id] = false;
        }
      });
    }
    return result;
  }

  // === Public Methods ===
  void connect() => socket.connect();
  void disconnect() => socket.disconnect();

  void createSession() => socket.emit('session:create', {});
  void joinSession(String sessionId) =>
      socket.emit('session:join', {'session_id': sessionId});
  void leaveSession() => socket.emit('session:leave', {});

  void selectBoard(int boardId) =>
      socket.emit('board:select', {'board_id': boardId});

  void toggleComponent(int componentId, bool visible, bool assembled) {
    print(
      'WS: Emitting component:toggle ($componentId, vis:$visible, asm:$assembled)',
    );
    socket.emit('component:toggle', {
      'component_id': componentId,
      'state': [visible, assembled],
    });
  }

  void toggleNet(int netId, bool state) {
    print('WS: Emitting net:toggle ($netId, $state)');
    socket.emit('net:toggle', {'net_id': netId, 'state': state});
  }

  void askAI(String question) =>
      socket.emit('ai:question', {'question': question});

  // Get active sessions from API
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final response = await ApiClient.get('/sessions');

      if (response != null && response['sessions'] != null) {
        return List<Map<String, dynamic>>.from(response['sessions']);
      }
      return [];
    } catch (e) {
      print('Error fetching sessions: $e');
      return [];
    }
  }

  // === Gestione Status ===
  void setStatus(String status) =>
      socket.emit('session:status', {'status': status});

  // === Gestione Part ===
  void selectPart(int? partId) {
    print('WS: Emitting part:select ($partId)');
    socket.emit('part:select', {'part_id': partId});
  }
}
