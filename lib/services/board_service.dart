import '../models/board.dart';
import 'api_client.dart';

/// Service for managing board-related API calls
/// 
/// This service handles all HTTP requests related to boards,
/// using the centralized ApiClient for consistent API communication.
/// 
/// All calls go through the IPC gateway (/ipc/boards)
class BoardService {
  /// Fetches the list of all boards from the server
  /// 
  /// Makes a GET request to /ipc/boards (gateway endpoint)
  /// Returns a list of Board objects
  /// Throws an Exception if the request fails
  Future<List<Board>> getBoards() async {
    try {
      final data = await ApiClient.get('/boards');
      
      if (data is List) {
        return data.map((json) => Board.fromJson(json)).toList();
      }
      
      throw Exception('Invalid response format: expected List');
    } catch (e) {
      throw Exception('Error fetching boards: $e');
    }
  }

  /// Fetches a single board by ID
  /// 
  /// Makes a GET request to /ipc/boards/{id}
  /// Returns a Board object
  /// Throws an Exception if the request fails
  Future<Board> getBoardById(String id) async {
    try {
      final data = await ApiClient.get('/boards/$id');
      
      if (data is Map<String, dynamic>) {
        return Board.fromJson(data);
      }
      
      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error fetching board: $e');
    }
  }

  /// Creates a new board
  /// 
  /// Makes a POST request to /ipc/boards
  /// Returns the created Board object
  /// Throws an Exception if the request fails
  Future<Board> createBoard(String name) async {
    try {
      final data = await ApiClient.post(
        '/boards',
        body: {'name': name},
      );
      
      if (data is Map<String, dynamic>) {
        return Board.fromJson(data);
      }
      
      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error creating board: $e');
    }
  }

  /// Deletes a board by ID
  /// 
  /// Makes a DELETE request to /ipc/boards/{id}
  /// Throws an Exception if the request fails
  Future<void> deleteBoard(String id) async {
    try {
      await ApiClient.delete('/boards/$id');
    } catch (e) {
      throw Exception('Error deleting board: $e');
    }
  }
}


