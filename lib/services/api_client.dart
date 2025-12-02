import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Generic API client for making HTTP requests
///
/// This class provides reusable methods for all API calls,
/// handling common concerns like headers, error handling, and URL building.
class ApiClient {
  /// Default headers for all requests
  static Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Makes a GET request
  ///
  /// [endpoint] - API endpoint (e.g., '/boards' or '/boards/123')
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map or List
  /// Throws an Exception if the request fails
  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      final response = await http.get(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed for $endpoint: $e');
    }
  }

  /// Makes a POST request
  ///
  /// [endpoint] - API endpoint
  /// [body] - Request body (will be JSON encoded)
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map or List
  /// Throws an Exception if the request fails
  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      final response = await http.post(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed for $endpoint: $e');
    }
  }

  /// Makes a PUT request
  ///
  /// [endpoint] - API endpoint
  /// [body] - Request body (will be JSON encoded)
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map or List
  /// Throws an Exception if the request fails
  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      final response = await http.put(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed for $endpoint: $e');
    }
  }

  /// Makes a DELETE request
  ///
  /// [endpoint] - API endpoint
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map or List
  /// Throws an Exception if the request fails
  static Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      final response = await http.delete(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed for $endpoint: $e');
    }
  }

  /// Makes a multipart POST request
  ///
  /// [endpoint] - API endpoint
  /// [fields] - Form fields
  /// [files] - List of files to upload
  /// [headers] - Optional additional headers
  ///
  /// Returns the response body as a Map or List
  /// Throws an Exception if the request fails
  static Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      request.headers.addAll({..._defaultHeaders, ...?headers});
      // Remove Content-Type as it is set automatically for multipart
      request.headers.remove('Content-Type');

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Multipart POST request failed for $endpoint: $e');
    }
  }

  /// Handles HTTP response and extracts data
  ///
  /// Checks status code and parses JSON response
  /// Throws an Exception for non-2xx status codes
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
