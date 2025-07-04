import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/token_services.dart';

class BatchService {
  final String baseUrl = 'https://flask-backend-207122022079.asia-southeast2.run.app/api';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Start a new weighing batch session
  Future<Map<String, dynamic>> initiateBatch({
    required String sessionType,
    String? vegetableType,
  }) async {
    try {
      final String? token = await TokenService.getFirebaseIdToken();
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (token == null || userId == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'session_type': sessionType,
      };

      // Add vegetable_type ONLY if provided and not empty (for rompes sessions)
      if (vegetableType != null && vegetableType.isNotEmpty) {
        requestBody['vegetable_type'] = vegetableType;
      }

      print('DEBUG: Sending request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/weighing/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Use the requestBody you built above
        body: jsonEncode(requestBody),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'session_type': sessionType,
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
        Uri.parse('$baseUrl/weighing/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': batchId,
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

  // Listen for weight changes from IoT device in Firestore while weighing
  Stream<QuerySnapshot> listenForProductWeightUpdates(String batchId) {
  print('DEBUG: Starting product weights listener for: $batchId');
  return _firestore
    .collection('vegetable_batches')
    .doc(batchId)
    .collection('weights')
    .orderBy('timestamp', descending: false)
    .snapshots();
}

  Stream<DocumentSnapshot> listenForRompesWeightUpdates(String batchId) {
    print('DEBUG: Starting rompes document listener for: $batchId');
    return _firestore
        .collection('rompes_batches')
        .doc(batchId)
        .snapshots();
  }

  // Listen for vegetable identification results in Firestore (only for product batches)
  Stream<DocumentSnapshot> listenForVegetableIdentification(String batchId) {
    return _firestore
        .collection('vegetable_batches')
        .doc(batchId)
      .snapshots();
  }
}