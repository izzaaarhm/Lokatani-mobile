import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../config/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  void _loadRecentBatches() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();

        // Load both vegetable and rompes batches
        final [vegetableBatchesSnapshot, rompesBatchesSnapshot] = await Future.wait([
          FirebaseFirestore.instance
              .collection('vegetable_batches')
              .where('user_id', isEqualTo: user.uid)
              .orderBy('created_at', descending: true)
              .limit(5)
              .get(),
          FirebaseFirestore.instance
              .collection('rompes_batches')
              .where('user_id', isEqualTo: user.uid)
              .orderBy('created_at', descending: true)
              .limit(5)
              .get(),
        ]);

        // Combine both collections
        final allDocs = <DocumentSnapshot>[];
        allDocs.addAll(vegetableBatchesSnapshot.docs);
        allDocs.addAll(rompesBatchesSnapshot.docs);

        // Sort by created_at descending
        allDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['created_at'] as Timestamp?;
          final bTime = bData['created_at'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime);
        });

        // Filter out batches without valid weighing data
        final validBatches = allDocs.where((batch) {
          final data = batch.data() as Map<String, dynamic>;
          final totalWeight = data['total_weight'];
          
          // For rompes, we don't need vegetable_type validation
          if (batch.reference.parent.id == 'rompes_batches') {
            return totalWeight != null && totalWeight > 0;
          }
          
          // For vegetable batches, keep existing validation
          final vegetableType = data['vegetable_type'];
          return totalWeight != null &&
              totalWeight > 0 &&
              vegetableType != null &&
              vegetableType != 'Unknown' &&
              vegetableType.toString().trim().isNotEmpty;
        }).take(3).toList(); // Take only first 3 valid batches

        setState(() {
          _recentBatches = validBatches;
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting
                Container(
                  padding: const EdgeInsets.all(20),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Selamat Datang, $_name',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF494A50),
                              ),
                            ),
                            // Tutorial button
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to tutorial
                                  Navigator.pushNamed(context, '/tutorial');
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Tutorial Menimbang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        width: 95,
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Navigate to history page
                          Navigator.pushNamed(context, '/history');
                        },
                        icon: Icon(Icons.arrow_forward,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
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
      // Remove the bottomNavigationBar
    );
  }

  Widget _buildWeighingHistoryItem(DocumentSnapshot batch) {
    final data = batch.data() as Map<String, dynamic>;
    final totalWeight = data['total_weight']?.toString() ?? 'xx';
    final createdAt = data['created_at'] != null
        ? DateFormat('dd-MM-yyyy').format((data['created_at'] as Timestamp).toDate())
        : 'Unknown date';

    // Determine batch type and display info
    String itemType;
    String displayName;
    IconData iconData;
    String? imageUrl;
    
    if (batch.reference.parent.id == 'vegetable_batches') {
      itemType = 'Produk';
      displayName = data['vegetable_type'] ?? 'Sayur Teridentifikasi';
      iconData = Icons.eco;
      imageUrl = data['image_url'];
    } else {
      itemType = 'Rompes';
      displayName = 'Sayur Rompes';
      iconData = Icons.eco;
    }

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
            color: const Color.fromARGB(255, 245, 240, 229),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        iconData,
                        color: const Color(0xFF1E5128),
                        size: 32,
                      );
                    },
                  ),
                )
              : Icon(
                  iconData,
                  color: const Color(0xFF1E5128),
                  size: 32,
                ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$itemType - $totalWeight Gram',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            Text(
              createdAt,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
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