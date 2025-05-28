import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/token_services.dart';

class BatchService {
  final String baseUrl = 'https://flask-backend-207122022079.asia-southeast2.run.app/api';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start a new weighing batch session
  Future<Map<String, dynamic>> initiateBatch() async {
    try {
      // Gunakan Firebase ID Token
      final String? token = await TokenService.getFirebaseIdTokenWithRefresh();
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (token == null || userId == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/batch/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Firebase ID Token
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to initiate batch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to initiate batch: $e'};
    }
  }

  // Complete a weighing batch
  Future<Map<String, dynamic>> completeBatch(String batchId) async {
    try {
      final String? token = await TokenService.getFirebaseIdToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/batch/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Firebase ID Token
        },
        body: jsonEncode({
          'batch_id': batchId,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Failed to complete batch'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to complete batch: $e'};
    }
  }

  // Listen for weight changes from IoT device in Firestore
  Stream<QuerySnapshot> listenForWeightUpdates() {
    return _firestore
        .collection('vegetable_batches')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }
}