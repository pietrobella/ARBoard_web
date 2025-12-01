import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

/// Service for handling file uploads to the server
///
/// This service manages CVG file uploads with progress tracking
/// and asynchronous processing status polling.
class FileUploadService {
  /// Uploads a CVG file and polls for processing completion
  ///
  /// [fileBytes] - The CVG file content as bytes
  /// [fileName] - The name of the file
  /// [progressCallback] - Optional callback for progress updates (message, progress 0-100)
  ///
  /// Returns a Map with the processing result including board_id
  /// Throws an Exception if upload or processing fails
  static Future<Map<String, dynamic>> uploadCvgAsync(
    Uint8List fileBytes,
    String fileName, {
    Function(String message, int progress)? progressCallback,
    Function(String taskId)? onTaskIdReceived,
    bool Function()? isCancelled,
  }) async {
    final serverUrl = ApiConfig.buildUrl('/upload');
    var request = http.MultipartRequest('POST', Uri.parse(serverUrl));

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    try {
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 202) {
        var responseJson = json.decode(responseData.body);
        String taskId = responseJson['task_id'];
        String statusUrl = responseJson['status_url'];

        if (onTaskIdReceived != null) {
          onTaskIdReceived(taskId);
        }

        // Start polling for status
        return await _pollUploadStatus(
          statusUrl,
          taskId,
          progressCallback,
          isCancelled,
        );
      } else {
        throw Exception("Failed to start CVG upload: ${responseData.body}");
      }
    } catch (e) {
      throw Exception("An error occurred while uploading CVG file: $e");
    }
  }

  /// Polls the server for upload processing status
  ///
  /// [statusUrl] - The relative URL to check status (already includes /ipc prefix)
  /// [taskId] - The task ID for tracking
  /// [progressCallback] - Optional callback for progress updates
  ///
  /// Returns the final processing result
  /// Throws an Exception if processing fails
  static Future<Map<String, dynamic>> _pollUploadStatus(
    String statusUrl,
    String taskId,
    Function(String, int)? progressCallback,
    bool Function()? isCancelled,
  ) async {
    // statusUrl already includes /ipc prefix, so just prepend baseUrl
    String fullStatusUrl = '${ApiConfig.baseUrl}$statusUrl';

    while (true) {
      // Check local cancellation
      if (isCancelled != null && isCancelled()) {
        throw Exception('Upload cancelled by user');
      }

      try {
        final response = await http.get(Uri.parse(fullStatusUrl));

        if (response.statusCode == 200) {
          var statusData = json.decode(response.body);
          String status = statusData['status'];
          int progress = statusData['progress'] ?? 0;
          String message = statusData['message'] ?? '';

          // Call progress callback if provided
          if (progressCallback != null) {
            progressCallback(message, progress);
          }

          if (status == 'completed') {
            // Trigger LLM data generation
            await _triggerLLMDataGeneration(statusData['board_id'].toString());
            return statusData;
          } else if (status == 'error') {
            throw Exception('CVG processing failed: ${statusData['error']}');
          } else if (status == 'cancelled') {
            throw Exception('Upload cancelled by user');
          }

          // Wait before next poll (2 seconds)
          await Future.delayed(const Duration(seconds: 2));
        } else if (response.statusCode == 404) {
          throw Exception('Upload task not found');
        } else {
          throw Exception('Failed to check upload status: ${response.body}');
        }
      } catch (e) {
        throw Exception('Error polling upload status: $e');
      }
    }
  }

  /// Triggers LLM data generation for a board
  ///
  /// [boardId] - The ID of the board to generate LLM data for
  static Future<void> _triggerLLMDataGeneration(String boardId) async {
    String url = ApiConfig.buildUrl('/generate_llm_data/$boardId');
    final response = await http.post(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to generate LLM data: ${response.body}');
    }
  }

  /// Gets board details by ID
  ///
  /// [boardId] - The ID of the board
  /// Returns a Map with board details including name
  static Future<Map<String, dynamic>> getBoardDetails(String boardId) async {
    String url = ApiConfig.buildUrl('/board/$boardId');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get board details: ${response.body}');
    }
  }

  /// Cancels an ongoing upload task
  ///
  /// [taskId] - The ID of the task to cancel
  static Future<void> cancelUpload(String taskId) async {
    final url = ApiConfig.buildUrl('/upload-cancel/$taskId');
    final response = await http.post(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel upload: ${response.body}');
    }
  }
}
