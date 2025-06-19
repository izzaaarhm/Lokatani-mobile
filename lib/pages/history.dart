import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isFiltered = false;
  bool _isLoading = true;
  List<DocumentSnapshot> _allBatches = [];
  List<DocumentSnapshot> _filteredBatches = [];

  @override
  void initState() {
    super.initState();
    _loadAllBatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBatches() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load both vegetable and rompes batches
        final [vegetableBatchesSnapshot, rompesBatchesSnapshot] = await Future.wait([
          FirebaseFirestore.instance
              .collection('vegetable_batches')
              .where('user_id', isEqualTo: user.uid)
              .orderBy('created_at', descending: true)
              .get(),
          FirebaseFirestore.instance
              .collection('rompes_batches')
              .where('user_id', isEqualTo: user.uid)
              .orderBy('created_at', descending: true)
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
        }).toList();

        setState(() {
          _allBatches = validBatches;
          _filteredBatches = validBatches;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading batches: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterBatches(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredBatches = _allBatches;
        _isFiltered = false;
      });
    } else {
      setState(() {
        _filteredBatches = _allBatches.where((batch) {
          final data = batch.data() as Map<String, dynamic>;
          final vegetableType = data['vegetable_type']?.toString().toLowerCase() ?? '';
          return vegetableType.contains(query.toLowerCase());
        }).toList();
        _isFiltered = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Penimbangan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari jenis sayuran...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterBatches,
            ),
          ),

          // Filter chip
          if (_isFiltered)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Difilter',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _isFiltered = false;
                              _filteredBatches = _allBatches;
                            });
                          },
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // History list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBatches.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat penimbangan',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredBatches.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(_filteredBatches[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(DocumentSnapshot batch) {
    final data = batch.data() as Map<String, dynamic>;
    final totalWeight = data['total_weight']?.toString() ?? 'xx';
    final createdAt = data['created_at'] != null
        ? DateFormat('EEEE, dd-MM-yyyy', 'id_ID').format((data['created_at'] as Timestamp).toDate())
        : 'Unknown date';

    // Determine batch type and display info
    String vegetableType;
    String? imageUrl;
    
    if (batch.reference.parent.id == 'rompes_batches') {
      vegetableType = 'Sayur Rompes';
      imageUrl = null; // Rompes don't have images
    } else {
      vegetableType = data['vegetable_type'] ?? 'Unknown';
      imageUrl = data['image_url'];
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context, 
          '/weighing-detail',
          arguments: batch.id,
        );
      },
      child: Container(
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
              color: imageUrl != null ? null :  Color.fromARGB(255, 245, 240, 229),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
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
            '$createdAt\nBerat: $totalWeight Gram',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}