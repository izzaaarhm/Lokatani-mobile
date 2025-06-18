import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../config/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current Firebase user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Get user ID from Firebase
        _userId = currentUser.uid;
        
        // Try to get profile data with additional Firestore information
        final userData = await _authService.getProfile(_userId);
        
        setState(() {
          _name = userData['name'] ?? currentUser.displayName ?? 'User';
          _email = userData['email'] ?? currentUser.email ?? 'user@example.com';
          _isLoading = false;
        });
      } else {
        // Not logged in
        setState(() {
          _name = 'User';
          _email = 'user@example.com';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _name = 'User';
        _email = 'user@example.com';
        _isLoading = false;
      });
      print('Error loading profile: $e');
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController _passwordController = TextEditingController();
    bool _obscurePassword = true;
    bool _isDeleting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                          'Hapus Akun',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    const SizedBox(height: 10),
                    // Warning container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tindakan ini akan menghapus akun Anda secara permanen dan tidak dapat dibatalkan.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Password confirmation section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Masukkan kata sandi untuk konfirmasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightGrey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: AppTheme.greyColor, width: 0.5),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: AppTheme.greyColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isDeleting ? null : () async {
                              if (_passwordController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Masukkan password untuk konfirmasi'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isDeleting = true;
                              });

                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null && user.email != null) {
                                  // Re-authenticate the user with their password
                                  final credential = EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: _passwordController.text.trim(),
                                  );
                                  
                                  await user.reauthenticateWithCredential(credential);
                                  
                                  // Delete the user account
                                  await user.delete();
                                  
                                  Navigator.of(context).pop();
                                  Navigator.pushReplacementNamed(context, '/');
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Akun berhasil dihapus'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  _isDeleting = false;
                                });
                                
                                String errorMessage = 'Terjadi kesalahan saat menghapus akun';
                                if (e.toString().contains('wrong-password') || 
                                    e.toString().contains('invalid-credential')) {
                                  errorMessage = 'Password salah. Silakan coba lagi.';
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: const Color.fromRGBO(244, 67, 54, 1),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(179, 38, 30, 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isDeleting
                                ? const SizedBox(
                                    width: 40,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Hapus Akun Saya',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    const SizedBox(height: 16),
                    const Text(
                      'Apakah Anda yakin ingin keluar? Anda perlu login kembali untuk menggunakan aplikasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    
                        const SizedBox(height: 20),                    
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.lightGrey,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: AppTheme.greyColor, width: 0.5),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(color: AppTheme.greyColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _authService.logout();
                              Navigator.of(context).pop();
                              Navigator.pushReplacementNamed(context, '/');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Log out',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),                
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Profile header section
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile image
                        const CircleAvatar(
                          radius: 48,
                          backgroundImage: AssetImage('assets/images/profile_placeholder.jpg'),
                        ),
                        const SizedBox(height: 16),
                        // User name and email
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account Settings section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pengaturan Akun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Account settings options
                  _buildSettingsItem(
                    context,
                    Icons.person_outline,
                    'Ubah Profil',
                    () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.delete_outline,
                    'Hapus Akun',
                    () => _showDeleteAccountDialog(context),
                    textColor: const Color.fromRGBO(179, 38, 30, 1),
                    iconColor: const Color.fromRGBO(179, 38, 30, 1),
                  ),
                  _buildSettingsItem(
                    context,
                    Icons.logout,
                    'Log Out',
                    () => _showLogoutDialog(context),
                    textColor: const Color.fromRGBO(179, 38, 30, 1),
                    iconColor: const Color.fromRGBO(179, 38, 30, 1),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}