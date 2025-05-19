import 'api_services.dart';
import 'token_services.dart';

class AuthService {
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await ApiService.post(
      '/auth/register', 
      {
        'email': email,
        'password': password,
        'name': name
      },
      requiresAuth: false
    );
    
    // Store tokens
    await TokenService.saveTokens(response['access_token'], response['refresh_token']);
    
    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      '/auth/login', 
      {
        'email': email,
        'password': password
      },
      requiresAuth: false
    );
    
    // Store tokens
    await TokenService.saveTokens(response['access_token'], response['refresh_token']);
    
    return response;
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    return await ApiService.get('/auth/profile/$userId');
  }

  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> profileData) async {
    return await ApiService.put(
      '/auth/profile',
      {
        'user_id': userId,
        ...profileData
      }
    );
  }

  Future<Map<String, dynamic>> changePassword(String userId, String currentPassword, String newPassword) async {
    return await ApiService.put(
      '/auth/password',
      {
        'user_id': userId,
        'current_password': currentPassword,
        'new_password': newPassword
      }
    );
  }
  
  Future<void> logout() async {
    await TokenService.clearTokens();
  }
}