import 'package:flutter/material.dart';
import 'dart:async';
import 'camera_page.dart';
import '../services/batch_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

class WeighingPage extends StatefulWidget {
  const WeighingPage({super.key});

  @override
  State<WeighingPage> createState() => _WeighingPageState();
}

class _WeighingPageState extends State<WeighingPage> {
  bool _isLoading = false; 
  List<VegetableItem> _detectedItems = [];
  bool _showDialog = true;
  String? _batchId;
  String? _sessionType;
  StreamSubscription? _weightSubscription;
  final BatchService _batchService = BatchService();
  
  @override
  void initState() {
    super.initState();
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
  Future<void> _initializeBatchAndListenForWeights(String sessionType) async {
    setState(() {
      _isLoading = true;
    });

    final result = await _batchService.initiateBatch(sessionType: sessionType);
    
    if (result['success']) {
      _batchId = result['data']['session_id'];
      _sessionType = sessionType;
      
      // Start listening for weight updates
      _startListeningForWeightUpdates();
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal memulai sesi penimbangan'))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Listen for real-time weight updates from Firestore
  void _startListeningForWeightUpdates() {
    if (_batchId == null || _sessionType == null) {
      print('DEBUG: sessionid is null, cannot listen for weights');
      return;
    }
  
    print('DEBUG: Starting to listen for weights in batch: $_batchId, type: $_sessionType');
    
    _weightSubscription = _batchService.listenForWeightUpdates(_batchId!, _sessionType!)
        .listen((snapshot) {
      print('DEBUG: Received weight snapshot with ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isNotEmpty) {
        final newItems = <VegetableItem>[];
        
        if (_sessionType == 'product') {
          for (int i = snapshot.docs.length - 1; i >= 0; i--) {
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
                itemType: 'Sayur',
              )
            );
          }
        } else {
          final doc = snapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final totalWeight = data['total_weight'];
          
          if (totalWeight != null && totalWeight > 0) {
            final timeString = DateFormat('HH:mm:ss').format(DateTime.now());
            
            newItems.add(
              VegetableItem(
                id: 1,
                weight: totalWeight.toString(),
                time: timeString,
                itemType: 'Rompes',
              )
            );
          }
        }
        
        setState(() {
          _detectedItems = newItems;
          _isLoading = false;
        });
      } else {
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
  }

  // Complete the current batch and navigate to camera page
  Future<void> _navigateToCameraPage() async {
    if (_batchId != null) {
      final result = await _batchService.completeBatch(_batchId!);
      
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menyelesaikan sesi penimbangan'))
        );
        return;
      }
      
      if (_sessionType == 'product') {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => CameraPage(batchId: _batchId!))
        );
      } else {
        // For rompes, go directly to dashboard
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/dashboard', 
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penimbangan rompes selesai'))
        );
      }
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Mau Menimbang Apa?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih "Produk" untuk sayur yang akan dikemas atau "Rompes" untuk sayur yang defect',
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
                          _initializeBatchAndListenForWeights('product');
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
                          _initializeBatchAndListenForWeights('rompes');
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
          border: Border.all(color: AppTheme.greyColor, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 8, width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
            fontSize: 24,
            color: Colors.black,
            fontWeight: FontWeight.w600
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
                  'Pilih jenis penimbangan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _sessionType == 'product' ? 'Sedang menimbang produk...' : 'Sedang menimbang rompes...',
                style: const TextStyle(
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _sessionType == 'product' ? Icons.scale : Icons.recycling,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _sessionType == 'product' 
                                    ? 'Letakkan sayur di atas timbangan'
                                    : 'Letakkan rompes di atas timbangan',
                                style: const TextStyle(
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
                label: Text(_sessionType == 'product' ? 'Selesai Menimbang' : 'Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5128),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Model class for vegetable items
class VegetableItem {
  final int id;
  final String weight;
  final String time;
  final String itemType;

  VegetableItem({
    required this.id,
    required this.weight,
    required this.time, 
    this.itemType = 'Produk',
  });
}
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
                  vegetable.itemType == 'Rompes' 
                    ? 'Rompes terdeteksi'
                    : '${vegetable.itemType} ${vegetable.id} terdeteksi',
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