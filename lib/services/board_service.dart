import '../models/board.dart';
import '../models/crop_schematic.dart';
import '../models/user_manual.dart';
import '../models/label.dart';
import '../models/component.dart';
import 'api_client.dart';
import 'package:http/http.dart' as http;

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
      final data = await ApiClient.post('/boards', body: {'name': name});

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

  /// Fetches crop schematics for a board
  ///
  /// Makes a GET request to /ipc/crop_schematics/{boardId}
  Future<List<CropSchematic>> getCropSchematics(String boardId) async {
    try {
      final data = await ApiClient.get('/crop_schematics/$boardId');

      if (data is List) {
        return data.map((json) => CropSchematic.fromJson(json)).toList();
      }

      throw Exception('Invalid response format: expected List');
    } catch (e) {
      throw Exception('Error fetching crop schematics: $e');
    }
  }

  /// Fetches user manuals for a board
  ///
  /// Makes a GET request to /ipc/user_manuals/{boardId}
  Future<List<UserManual>> getUserManuals(String boardId) async {
    try {
      final data = await ApiClient.get('/user_manuals/$boardId');

      if (data is List) {
        return data.map((json) => UserManual.fromJson(json)).toList();
      }

      throw Exception('Invalid response format: expected List');
    } catch (e) {
      throw Exception('Error fetching user manuals: $e');
    }
  }

  /// Fetches a single user manual by ID
  ///
  /// Makes a GET request to /ipc/user_manual/{id}
  Future<UserManual> getUserManualById(int id) async {
    try {
      final data = await ApiClient.get('/user_manual/$id');

      if (data is Map<String, dynamic>) {
        // The API returns 'file_pdf' (base64) in the response
        // We need to ensure the ID is included if not present in the response body explicitly,
        // but the API seems to return board_id and file_pdf.
        // We might need to inject the ID if it's missing, but let's assume standard behavior or check API.
        // API returns: {"board_id": ..., "file_pdf": ...}
        // It does NOT return "id". So we need to add it.
        data['id'] = id;
        return UserManual.fromJson(data);
      }

      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error fetching user manual: $e');
    }
  }

  /// Uploads a user manual for a board
  ///
  /// [boardId] - ID of the board
  /// [fileBytes] - The PDF file content as bytes
  /// [filename] - The name of the file
  ///
  /// Returns the ID of the uploaded user manual
  Future<int> uploadUserManual(
    String boardId,
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      final response = await ApiClient.postMultipart(
        '/user_manual',
        fields: {'board_id': boardId},
        files: [
          http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
        ],
      );

      if (response is Map<String, dynamic> && response.containsKey('id')) {
        return response['id'];
      }

      throw Exception('Invalid response: missing ID');
    } catch (e) {
      throw Exception('Error uploading user manual: $e');
    }
  }

  /// Uploads a crop schematic for a board
  ///
  /// [boardId] - ID of the board
  /// [fileBytes] - The PNG file content as bytes
  /// [filename] - The name of the file
  /// [width] - Width of the cropped image
  /// [height] - Height of the cropped image
  /// [function] - Function/label of the schematic (optional)
  /// [side] - Side of the board (optional)
  ///
  /// Returns the ID of the created crop schematic
  Future<int> uploadCropSchematic(
    String boardId,
    List<int> fileBytes,
    String filename,
    int width,
    int height, {
    String function = '',
    String side = '',
  }) async {
    try {
      final response = await ApiClient.postMultipart(
        '/crop_schematic',
        fields: {
          'board_id': boardId,
          'function': function,
          'side': side,
          'w': width.toString(),
          'h': height.toString(),
        },
        files: [
          http.MultipartFile.fromBytes('file', fileBytes, filename: filename),
        ],
      );

      if (response is Map<String, dynamic> && response.containsKey('id')) {
        return response['id'];
      }

      throw Exception('Invalid response: missing ID');
    } catch (e) {
      throw Exception('Error uploading crop schematic: $e');
    }
  }

  /// Extracts and saves component labels for a crop
  ///
  /// [pdfId] - ID of the PDF manual
  /// [pageNum] - Page number (0-based)
  /// [crop] - List of 4 doubles [x0, y0, x1, y1] in PDF coordinates
  /// [cropSchematicId] - ID of the crop schematic
  /// [boardId] - ID of the board
  Future<void> extractAndSaveComponentLabels({
    required int pdfId,
    required int pageNum,
    required List<double> crop,
    required int cropSchematicId,
    required int boardId,
    required int width,
    required int height,
  }) async {
    try {
      await ApiClient.post(
        '/component_label/extract_and_save',
        body: {
          'pdf_id': pdfId,
          'page_num': pageNum,
          'crop': crop,
          'crop_schematic_id': cropSchematicId,
          'board_id': boardId,
          'w': width,
          'h': height,
        },
      );
    } catch (e) {
      throw Exception('Error extracting labels: $e');
    }
  }

  /// Deletes a crop schematic by ID
  ///
  /// Makes a DELETE request to /ipc/crop_schematic/{id}
  Future<void> deleteCropSchematic(int id) async {
    try {
      await ApiClient.delete('/crop_schematic/$id');
    } catch (e) {
      throw Exception('Error deleting crop schematic: $e');
    }
  }

  /// Deletes a user manual by ID
  ///
  /// Makes a DELETE request to /ipc/user_manual/{id}
  Future<void> deleteUserManual(int id) async {
    try {
      await ApiClient.delete('/user_manual/$id');
    } catch (e) {
      throw Exception('Error deleting user manual: $e');
    }
  }

  /// Fetches labels for a board
  ///
  /// Makes a GET request to /ipc/pin_labels/{boardId}
  Future<List<Label>> getLabels(String boardId) async {
    try {
      final data = await ApiClient.get('/pin_labels/$boardId');

      if (data is List) {
        return data.map((json) => Label.fromJson(json)).toList();
      }

      throw Exception('Invalid response format: expected List');
    } catch (e) {
      throw Exception('Error fetching labels: $e');
    }
  }

  /// Deletes a label by ID
  ///
  /// Makes a DELETE request to /ipc/pin_labels/{id}
  Future<void> deleteLabel(int id) async {
    try {
      await ApiClient.delete('/pin_labels/$id');
    } catch (e) {
      throw Exception('Error deleting label: $e');
    }
  }

  /// Creates a new label
  ///
  /// Makes a POST request to /ipc/pin_labels
  Future<Label> createLabel(
    String name,
    String boardId,
    String? description,
  ) async {
    try {
      final data = await ApiClient.post(
        '/pin_labels',
        body: {
          'name': name,
          'board_id': int.tryParse(boardId) ?? boardId,
          'description': description,
        },
      );

      if (data is Map<String, dynamic>) {
        return Label.fromJson(data);
      }

      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error creating label: $e');
    }
  }

  /// Creates a new sublabel
  ///
  /// Makes a POST request to /ipc/pin_sublabels
  Future<SubLabel> createSubLabel(String name, int labelId) async {
    try {
      final data = await ApiClient.post(
        '/pin_sublabels',
        body: {'name': name, 'label_id': labelId},
      );

      if (data is Map<String, dynamic>) {
        return SubLabel.fromJson(data);
      }

      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error creating sublabel: $e');
    }
  }

  /// Fetches label details (associations)
  ///
  /// Makes a GET request to /ipc/labels/{labelId}/component_pin_sublabel?board_id={boardId}
  Future<Map<String, dynamic>> getLabelDetails(
    int labelId,
    String boardId,
  ) async {
    try {
      final data = await ApiClient.get(
        '/labels/$labelId/component_pin_sublabel?board_id=$boardId',
      );

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error fetching label details: $e');
    }
  }

  /// Fetches components for a board
  ///
  /// Makes a GET request to /ipc/components/board/{boardId}
  Future<List<Component>> getComponents(String boardId) async {
    try {
      final data = await ApiClient.get('/components/board/$boardId');

      if (data is List) {
        return data.map((json) => Component.fromJson(json)).toList();
      }

      throw Exception('Invalid response format: expected List');
    } catch (e) {
      throw Exception('Error fetching components: $e');
    }
  }

  /// Fetches pins for a component
  ///
  /// Makes a GET request to /ipc/component/{componentId}/details
  Future<List<Pin>> getComponentPins(int componentId) async {
    try {
      final data = await ApiClient.get('/component/$componentId/details');

      if (data is Map<String, dynamic>) {
        final packageInfo = data['package_info'];
        final List<dynamic> pinsData = packageInfo['pins'] ?? [];
        return pinsData.map((json) => Pin.fromJson(json)).toList();
      }

      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error fetching component pins: $e');
    }
  }

  /// Gets pad ID for a component pin
  ///
  /// Makes a GET request to /ipc/component/{componentId}/pin/{pinId}/net
  Future<int> getPadId(int componentId, int pinId) async {
    try {
      final data = await ApiClient.get(
        '/component/$componentId/pin/$pinId/net',
      );

      if (data is Map<String, dynamic>) {
        return data['pad_id'];
      }

      throw Exception('Invalid response format: expected Map');
    } catch (e) {
      throw Exception('Error fetching pad ID: $e');
    }
  }

  /// Creates a pad label association
  ///
  /// Makes a POST request to /ipc/pad_labels
  Future<void> createPadLabel(int padId, int labelId, int? sublabelId) async {
    try {
      await ApiClient.post(
        '/pad_labels',
        body: {'pad_id': padId, 'label_id': labelId, 'sublabel_id': sublabelId},
      );
    } catch (e) {
      throw Exception('Error creating pad label: $e');
    }
  }
}
