import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiService {
  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final base = ApiEndpoints.baseUrl;
    final fullUrl = '$base$path';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  static Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error or connection timed out: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> put(
    String path, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> patch(
    String path, {
    dynamic body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  static Future<ApiResponse<dynamic>> delete(
    String path, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  static ApiResponse<dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final String msg = data['message'] ?? (isSuccess ? 'Success' : 'Request failed');

      return ApiResponse(
        success: data['success'] ?? isSuccess,
        message: msg,
        data: data['data'] ?? data,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Response status: ${response.statusCode}',
        data: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
