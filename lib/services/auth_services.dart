import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Register user dengan Firebase
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Make sure the user exists before proceeding
      if (userCredential.user == null) {
        return {'success': false, 'message': 'User creation failed'};
      }
      
      // Send email verification
      await userCredential.user!.sendEmailVerification();
    
      // Update profile display name directly in Firebase Auth
      await userCredential.user!.updateDisplayName(name);
      
      return {
        'success': true,
        'verificationSent': true,
        'user': {
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
        }
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah digunakan.';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid. Anda hanya dapat menggunakan email dengan domain @lokatani.id';
          break;
        default:
          message = 'Registrasi gagal: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Registrasi gagal: $e'};
    }
  }

  // Login dengan Firebase
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        return {'success': false, 'message': 'Login gagal'};
      }
      
      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        return {
          'success': false, 
          'emailVerified': false,
          'message': 'Silahkan verifikasi email Anda sebelum Login. Cek kotak masuk email Anda untuk mengakses link verifikasi.'
        };
      }
      
      return {
        'success': true,
        'user': {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName ?? 'User',
        }
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak ditemukan.';
          break;
        case 'wrong-password':
          message = 'Password salah.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        default:
          message = 'Login gagal: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login gagal: $e'};
    }
  }
  
  // Get profile data dari Firebase Auth
  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null && currentUser.uid == userId) {
        return {
          'name': currentUser.displayName ?? 'User',
          'email': currentUser.email ?? 'user@example.com',
        };
      }
      
      return {'name': 'User', 'email': 'user@example.com'};
    } catch (e) {
      print('Error getting profile: $e');
      return {'name': 'User', 'email': 'user@example.com'};
    }
  }

  // Update profile di Firebase Auth
  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId && profileData.containsKey('name')) {
        await currentUser.updateDisplayName(profileData['name']);
      }
      
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengubah profil: $e'};
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout gagal: $e');
    }
  }
}