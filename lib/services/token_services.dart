import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const storage = FlutterSecureStorage();
  
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: 'auth_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }
  
  static Future<String?> getAccessToken() async {
    return await storage.read(key: 'auth_token');
  }
  
  static Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }
  
  static Future<void> clearTokens() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
  }
}