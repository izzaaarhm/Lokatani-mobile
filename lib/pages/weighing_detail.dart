import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

class WeighingDetailScreen extends StatefulWidget {
  const WeighingDetailScreen({super.key});

  @override
  State<WeighingDetailScreen> createState() => _WeighingDetailScreenState();
}

class _WeighingDetailScreenState extends State<WeighingDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _batchData;
  List<Map<String, dynamic>> _weightsData = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get batch ID from route arguments
    final batchId = ModalRoute.of(context)!.settings.arguments as String?;
    if (batchId != null) {
      _loadBatchData(batchId);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBatchData(String batchId) async {
    try {
      DocumentSnapshot? batchDoc;
      List<Map<String, dynamic>> weights = [];
      
      // First try vegetable_batches collection
      batchDoc = await FirebaseFirestore.instance
          .collection('vegetable_batches')
          .doc(batchId)
          .get();
          
      if (batchDoc.exists) {
        // Load weights collection for vegetable batches
        final weightsSnapshot = await FirebaseFirestore.instance
            .collection('vegetable_batches')
            .doc(batchId)
            .collection('weights')
            .orderBy('timestamp')
            .get();
            
        weights = weightsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'weight': data['weight'],
            'timestamp': data['timestamp'],
          };
        }).toList();
      } else {
        // If not found in vegetable_batches, try rompes_batches
        batchDoc = await FirebaseFirestore.instance
            .collection('rompes_batches')
            .doc(batchId)
            .get();
            
        if (batchDoc.exists) {
          // For rompes, there's no weights subcollection
          // The weight data is stored directly in the document
          final data = batchDoc.data() as Map<String, dynamic>;
          final totalWeight = data['total_weight'];
          final createdAt = data['created_at'];
          
          if (totalWeight != null && totalWeight > 0) {
            weights = [{
              'weight': totalWeight,
              'timestamp': createdAt,
            }];
          }
        }
      }
      
      if (batchDoc?.exists == true) {
        setState(() {
          _batchData = batchDoc!.data() as Map<String, dynamic>;
          _weightsData = weights;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading batch data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_batchData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              const Expanded(
                child: Center(
                  child: Text(
                    'Data penimbangan tidak ditemukan',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with back button
            _buildAppBar(context),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vegetable image and info
                    _buildVegetableHeader(),
                    
                    // Weighing info
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWeighingInfo(),
                          const SizedBox(height: 32),
                          _buildWeighingList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildVegetableHeader() {
    final imageUrl = _batchData?['image_url'];
    return Stack(
      children: [
        // Vegetable image
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? const Center(
                  child: Icon(
                    Icons.eco,
                    size: 48,
                    color: Color(0xFF1E5128),
                  ),
                )
              : null,
        ),
      
        const SizedBox(height: 28),
        // Vegetable name
        
      ],
    );
  }

  Widget _buildWeighingInfo() {
    final vegetableName = _batchData?['vegetable_type'] ?? 'Unknown Vegetable';
    final String capitalizedVegetableName = 
        vegetableName.isNotEmpty ? 
        vegetableName[0].toUpperCase() + vegetableName.substring(1).toLowerCase() : 
        '';
    final createdAt = _batchData?['created_at'];
    final totalWeight = _batchData?['total_weight'] ?? 0;
    final weighingCount = _weightsData.length;

    // Format date safely
    String formattedDate = 'Unknown date';
    if (createdAt != null) {
      try {
        final date = (createdAt as Timestamp).toDate();
        // Use simple date formatting to avoid locale issues
        formattedDate = DateFormat('EEEE, dd-MM-yyyy').format(date);
      } catch (e) {
        print('Error formatting date: $e');
        formattedDate = 'Invalid date';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              capitalizedVegetableName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor
              ),
            ),

            Text(
              formattedDate,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Weight info
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah penimbangan: $weighingCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Berat Total: ${totalWeight.toString()} Gram',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeighingList() {
    if (_weightsData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Tidak ada data penimbangan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _weightsData.asMap().entries.map((entry) {
        final index = entry.key;
        final weightData = entry.value;
        
        final weight = weightData['weight']?.toString() ?? 'xx';
        final timestamp = weightData['timestamp'] as Timestamp?;
        
        String timeFormatted = 'Unknown time';
        if (timestamp != null) {
          try {
            timeFormatted = DateFormat('HH:mm:ss').format(timestamp.toDate());
          } catch (e) {
            print('Error formatting time: $e');
            timeFormatted = 'Invalid time';
          }
        }
        
        return _buildWeighingItem(
          index + 1, 
          weight, 
          timeFormatted, 
          true
        );
      }).toList(),
    );
  }

  Widget _buildWeighingItem(int number, String weight, String time, bool isCompleted) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            children: [
              // Check icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 240, 229),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.eco,
                        size: 28,
                        color: Color(0xFF1E5128),
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              
              // Weighing info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penimbangan $number',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Berat: $weight Gram',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Text(
                time,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFBCA371), 
                ),
              ),
            ],
          ),
        ),
        // Add spacing and optional divider
        const SizedBox(height: 20),
        if (number < _weightsData.length) // Don't show divider after last item
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            height: 1,
            color: Colors.grey.shade200,
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}