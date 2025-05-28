import 'package:firebase_auth/firebase_auth.dart';

class TokenService {
  // Mendapatkan Firebase ID Token untuk API calls
  static Future<String?> getFirebaseIdToken() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        return await currentUser.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting Firebase ID token: $e');
      return null;
    }
  }
  
  // Method untuk refresh Firebase ID Token jika diperlukan
  static Future<String?> getFirebaseIdTokenWithRefresh({bool forceRefresh = false}) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        return await currentUser.getIdToken(forceRefresh);
      }
      return null;
    } catch (e) {
      print('Error getting Firebase ID token: $e');
      return null;
    }
  }
  
  static Future<void> clearTokens() async {}
}