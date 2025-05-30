import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'https://flask-backend-207122022079.asia-southeast2.run.app';
  
  static Future<Map<String, String>> getHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth) {
      try {
        // Get current Firebase user
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reload(); 
          headers['X-User-ID'] = user.uid;
          headers['X-User-Email'] = user.email ?? '';
        }
      } catch (e) {
        print('Error getting Firebase auth headers: $e');
      }
    }
    
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool requiresAuth = true}) async {
    final headers = await getHeaders(requiresAuth: requiresAuth);
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final headers = await getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final dynamic body = json.decode(response.body);
    
    if (statusCode >= 200 && statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'API Error: $statusCode');
    }
  }
}