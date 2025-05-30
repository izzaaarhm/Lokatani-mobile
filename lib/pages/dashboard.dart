import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  String _name = '';
  String _userId = '';
  List<DocumentSnapshot> _recentBatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentBatches();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current Firebase user
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Get user ID from Firebase
        _userId = currentUser.uid;

        // Try to get profile data with additional Firestore information
        final userData = await _authService.getProfile(_userId);

        setState(() {
          _name = userData['name'] ?? currentUser.displayName ?? 'User';
        });
      } else {
        // Not logged in
        setState(() {
          _name = 'User';
        });
      }
    } catch (e) {
      setState(() {
        _name = 'User';
      });
      print('Error loading profile: $e');
    }
  }

  // Update method _loadRecentBatches
  void _loadRecentBatches() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Pastikan user sudah terautentikasi dengan benar
        await user.reload();

        // Get recent batches from Firestore
        final snapshot = await FirebaseFirestore.instance
            .collection('vegetable_batches')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('created_at', descending: true)
            .limit(3)
            .get();

        setState(() {
          _recentBatches = snapshot.docs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recent batches: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).toInt()),
                        spreadRadius: 1,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Halo!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A3E06),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selamat Datang, $_name',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF494A50),
                              ),
                            ),
                            // Tutorial button
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to tutorial
                                  Navigator.pushNamed(context, '/tutorial');
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Tutorial Menimbang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F7C35),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(fontSize: 14),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo2.png',
                        width: 90,
                      ),
                    ],
                  ),
                ),

                // Weighing history header
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Penimbangan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),

                // Weighing history list
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        children: _recentBatches
                            .map((batch) => _buildWeighingHistoryItem(batch))
                            .toList(),
                      ),

                // Add weighing button
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to add weighing screen
                      Navigator.pushNamed(context, '/add-weighing');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Mulai Menimbang'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Handle navigation based on index
          // This is a simplified version, you might want to use a more robust navigation approach
          if (index == 1) {
            // Navigate to history page
            Navigator.pushNamed(context, '/history');
          } else if (index == 2) {
            // Navigate to profile page
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildWeighingHistoryItem(DocumentSnapshot batch) {
    final data = batch.data() as Map<String, dynamic>;
    final vegetableType = data['vegetable_type'] ?? 'Unknown';
    final imageUrl = data['image_url'];
    final totalWeight = data['total_weight']?.toString() ?? 'xx';
    final createdAt = data['created_at'] != null
        ? DateFormat('dd-MM-yyyy').format((data['created_at'] as Timestamp).toDate())
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: imageUrl != null ? null : const Color(0xFFF5F5F5),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null, // Hapus DecorationImage default
          ),
          // Tambahkan child untuk icon jika tidak ada imageUrl
          child: imageUrl == null
              ? const Icon(
                  Icons.eco,
                  color: Color(0xFF1E5128),
                  size: 24,
                )
              : null,
        ),
        title: Text(
          vegetableType,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$createdAt\nBerat: $totalWeight kg',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to detail with batch id
          Navigator.pushNamed(
            context,
            '/weighing-detail',
            arguments: batch.id,
          );
        },
      ),
    );
  }
}