import 'package:flutter/material.dart';
import 'dart:async';
import 'camera_page.dart';
import '../services/batch_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WeighingPage extends StatefulWidget {
  const WeighingPage({super.key});

  @override
  State<WeighingPage> createState() => _WeighingPageState();
}

class _WeighingPageState extends State<WeighingPage> {
  bool _isLoading = false; // Ubah dari true ke false
  List<VegetableItem> _detectedItems = [];
  bool _showDialog = true;
  String? _batchId;
  StreamSubscription? _weightSubscription;
  final BatchService _batchService = BatchService();
  
  @override
  void initState() {
    super.initState();
    // Show the dialog after the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWeighingTypeDialog();
    });
  }
  
  @override
  void dispose() {
    _weightSubscription?.cancel();
    super.dispose();
  }

  // Initialize a new batch and start listening for weight updates
  Future<void> _initializeBatchAndListenForWeights() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _batchService.initiateBatch();
    
    if (result['success']) {
      _batchId = result['data']['batch_id'];
      
      // Start listening for weight updates
      _startListeningForWeightUpdates();
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to start weighing session'))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Listen for real-time weight updates from Firestore
  void _startListeningForWeightUpdates() {
    if (_batchId == null ) {
      print('DEBUG: batchId is null, cannot listen for weights');
      return;
    }
  
    print('DEBUG: Starting to listen for weights in batch: $_batchId');
    
    _weightSubscription = _batchService.listenForWeightUpdates(_batchId!)
        .listen((snapshot) {
      print('DEBUG: Received weight snapshot with ${snapshot.docs.length} documents');
      
      // Debug: Print all documents in the snapshot
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        print('DEBUG: Weight document $i: ${doc.id} - Data: $data');
      }
      
      if (snapshot.docs.isNotEmpty) {
        final newItems = <VegetableItem>[];
        
        for (int i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final timeString = DateFormat('HH:mm:ss').format(timestamp);
          final weight = (data['weight'] ?? 'xx').toString();
          
          newItems.add(
            VegetableItem(
              id: i + 1,
              weight: weight,
              time: timeString,
            )
          );
        }
        
        setState(() {
          _detectedItems = newItems;
          _isLoading = false;
        });
        print('DEBUG: Updated _detectedItems with ${newItems.length} items');
      } else {
        print('DEBUG: No weight documents found');
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('DEBUG: Error listening for weight updates: $error');
      setState(() {
        _isLoading = false;
      });
    });
    
    print('DEBUG: Weight listener setup complete');
  }

  // Complete the current batch and navigate to camera page
  Future<void> _navigateToCameraPage() async {
    if (_batchId != null) {
      final result = await _batchService.completeBatch(_batchId!);
      
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to complete weighing session'))
        );
        return;
      }
      
      // Navigate to camera page WITH batch_id
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => CameraPage(batchId: _batchId!))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active weighing session'))
      );
    }
  }

  // Dialog to select weighing type 
  void _showWeighingTypeDialog() {
    if (_showDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop(); // balik ke dashboard
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Text(
                    'Mau menimbang apa?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih "Produk" jika sekarang Anda ingin menimbang sayur yang akan dikemas',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton(
                        icon: Icons.shopping_basket,
                        label: 'Produk',
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _showDialog = false;
                          });
                          _initializeBatchAndListenForWeights();
                        }
                      ),
                      _buildOptionButton(
                        icon: Icons.recycling,
                        label: 'Rompes',
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _showDialog = false;
                          });
                          // nanti bakal diganti utk logic rompes
                          _initializeBatchAndListenForWeights();
                        }
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildOptionButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFF3F7C35)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Timbang Sayuran',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tampilkan dialog jika belum memilih tipe penimbangan
          if (_showDialog)
            const Expanded(
              child: Center(
                child: Text(
                  'Silakan pilih jenis penimbangan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sedang menimbang...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E5128)),
                              strokeWidth: 5,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memulai sesi penimbangan...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _detectedItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.scale,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Letakkan sayur di atas timbangan',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _detectedItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final item = _detectedItems[index];
                            return VegetableListItem(vegetable: item);
                          },
                        ),
            ),
          ],
        ],
      ),
      floatingActionButton: !_showDialog && !_isLoading && _detectedItems.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 60),
              child: ElevatedButton.icon(
                onPressed: _navigateToCameraPage,
                icon: const Icon(Icons.check),
                label: const Text('Selesai Menimbang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5128),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Model class for vegetable items tetap sama
class VegetableItem {
  final int id;
  final String weight;
  final String time;

  VegetableItem({
    required this.id,
    required this.weight,
    required this.time,
  });
}

// VegetableListItem widget tetap sama
class VegetableListItem extends StatelessWidget {
  final VegetableItem vegetable;

  const VegetableListItem({super.key, required this.vegetable});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF326229),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sayur ${vegetable.id} terdeteksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Berat: ${vegetable.weight} Gram',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            vegetable.time,
            style: const TextStyle(
              color: Color(0xFFD1A159),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}