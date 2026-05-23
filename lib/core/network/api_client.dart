import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// API Client to communicate with the Laravel backend.
/// Handles Authentication Token insertion, JSON serialization, and error parsing.
class ApiClient {
  final http.Client _client;
  String? _token;
  static const String _tokenKey = 'auth_token';

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Initialize the API client by loading the persisted token from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      if (_token != null) {
        debugPrint('🔑 [ApiClient] Loaded persisted auth token.');
      }
    } catch (e) {
      debugPrint('⚠️ [ApiClient] Failed to load auth token: $e');
    }
  }

  /// Check if the user is authenticated (has a token).
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Set the token in memory and persist it to SharedPreferences.
  Future<void> setToken(String? token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString(_tokenKey, token);
      } else {
        await prefs.remove(_tokenKey);
      }
    } catch (e) {
      debugPrint('⚠️ [ApiClient] Failed to persist/remove auth token: $e');
    }
  }

  /// Clear the token (on logout).
  Future<void> clearToken() async {
    await setToken(null);
  }

  /// Get the current auth token (for manual multipart requests).
  Future<String?> getToken() async => _token;

  /// Get the base URL for the API.
  String get baseUrl => AppConstants.apiBaseUrl;

  /// Parse raw JSON string (for manual HTTP responses).
  dynamic parseJson(String body) {
    try {
      return jsonDecode(body);
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  /// Get headers for the API request.
  Map<String, String> _getHeaders(Map<String, String>? extraHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  /// Execute a GET request.
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    debugPrint('🌐 [ApiClient] GET $url');
    try {
      final response = await _client.get(
        url,
        headers: _getHeaders(headers),
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Failed to connect to the server: $e');
    }
  }

  /// Execute a POST request.
  Future<dynamic> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    debugPrint('🌐 [ApiClient] POST $url');
    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Failed to connect to the server: $e');
    }
  }

  /// Execute a PUT request.
  Future<dynamic> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    debugPrint('🌐 [ApiClient] PUT $url');
    try {
      final response = await _client.put(
        url,
        headers: _getHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Failed to connect to the server: $e');
    }
  }

  /// Execute a DELETE request.
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    debugPrint('🌐 [ApiClient] DELETE $url');
    try {
      final response = await _client.delete(
        url,
        headers: _getHeaders(headers),
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Failed to connect to the server: $e');
    }
  }

  /// Process HTTP Response and throw custom exceptions if needed.
  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;
    debugPrint('📥 [ApiClient] Response $statusCode: $bodyString');

    dynamic decodedBody;
    try {
      if (bodyString.isNotEmpty) {
        decodedBody = jsonDecode(bodyString);
      }
    } catch (e) {
      debugPrint('⚠️ [ApiClient] Failed to decode JSON: $e');
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody;
    }

    final message = decodedBody != null && decodedBody is Map
        ? (decodedBody['message'] ?? 'Unknown error occurred')
        : 'Unknown server error ($statusCode)';

    if (statusCode == 401) {
      throw AuthException(message, code: 'unauthorized');
    }

    if (statusCode == 422) {
      throw ValidationException(message, code: 'validation_error');
    }

    throw ServerException(message, code: statusCode.toString());
  }

  /// Upload a file using multipart request.
  Future<dynamic> uploadFile(
    String endpoint, {
    required List<int> bytes,
    required String fieldName,
    required String fileName,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    debugPrint('🌐 [ApiClient] Multipart POST $url');
    try {
      final request = http.MultipartRequest('POST', url);
      
      // Add Authorization header
      final authHeaders = _getHeaders(headers);
      request.headers.addAll(authHeaders);
      // Remove content-type as MultipartRequest sets its own boundary content-type
      request.headers.remove('Content-Type');

      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Add fields if any
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Failed to upload file: $e');
    }
  }
}
