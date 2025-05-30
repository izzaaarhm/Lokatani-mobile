import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/token_services.dart';

class MLService {
  final String baseUrl = 'https://flask-backend-207122022079.asia-southeast2.run.app/api';
  
  Future<Map<String, dynamic>> identifyVegetable(String imagePath, String batchId) async {
    try {
      final token = await TokenService.getFirebaseIdTokenWithRefresh();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (token == null || userId == null) {
        return {'success': false, 'message': 'Authentication required'};
      }
      
      // Create multipart request for image upload
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/ml/identify-vegetable')
      );
      
      // Add headers and fields
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['batch_id'] = batchId;
      request.fields['user_id'] = userId;
      
      // Add the image file
      var file = await http.MultipartFile.fromPath(
        'file', imagePath, filename: basename(imagePath)
      );
      request.files.add(file);
      
      // Send the request and get response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {
          'success': false, 
          'message': 'Failed to identify: ${json.decode(response.body)['message']}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}