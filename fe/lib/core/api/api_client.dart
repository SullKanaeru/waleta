import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // Removed FlutterSecureStorage
  static const _tokenKey = 'jwt_token';

  String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    // iOS simulator, desktop, etc.
    return 'http://127.0.0.1:3000/api/v1';
  }

  // Token management
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // HTTP Headers
  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // GET request
  Future<ApiResponse> get(String endpoint, {bool withAuth = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers(withAuth: withAuth),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: e.toString());
    }
  }

  // POST request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: e.toString());
    }
  }

  // PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers(withAuth: withAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: e.toString());
    }
  }

  // DELETE request
  Future<ApiResponse> delete(String endpoint, {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$_baseUrl$endpoint'));
      request.headers.addAll(await _headers(withAuth: withAuth));
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, statusCode: 0, error: e.toString());
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(success: true, statusCode: response.statusCode, data: body);
    } else {
      final errorMsg = body is Map ? (body['error'] ?? 'Terjadi kesalahan') : 'Terjadi kesalahan';
      return ApiResponse(success: false, statusCode: response.statusCode, error: errorMsg.toString(), data: body);
    }
  }
}

class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String? error;

  ApiResponse({required this.success, required this.statusCode, this.data, this.error});
}
