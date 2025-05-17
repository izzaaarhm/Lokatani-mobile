import 'package:flutter/material.dart';
import 'dart:async';
import 'camera_page.dart';

// Main weighing page that includes the dialog and weighing functionality
class WeighingPage extends StatefulWidget {
  const WeighingPage({super.key});

  @override
  State<WeighingPage> createState() => _WeighingPageState();
}

class _WeighingPageState extends State<WeighingPage> {
  bool _isLoading = true;
  List<VegetableItem> _detectedItems = [];
  bool _showDialog = true;
  
  @override
  void initState() {
    super.initState();
    // Show the dialog after the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWeighingTypeDialog();
    });
    
    // Simulate loading data
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _detectedItems = [
            VegetableItem(id: 1, weight: "xx", time: "09:30"),
            VegetableItem(id: 2, weight: "xx", time: "09:33"),
            VegetableItem(id: 3, weight: "xx", time: "09:37"),
          ];
        });
      }
    });
  }
  
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
                        onPressed: () => Navigator.of(context).pop(),
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
                    'Klik "Produk" jika sekarang Anda ingin menimbang sayur yang akan dikemas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _showDialog = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1E5128)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Rompes',
                            style: TextStyle(color: Color(0xFF1E5128)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _showDialog = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5128),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Produk'),
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
    }
  }

  void _navigateToCameraPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black54, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
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
                          'Loading...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _detectedItems.length + 1, // +1 for the loading indicator at the end
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      if (index < _detectedItems.length) {
                        final item = _detectedItems[index];
                        return VegetableListItem(vegetable: item);
                      } else {
                        // Show loading indicator at the end
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E5128)),
                                strokeWidth: 4,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1E5128),
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: Container(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Model class for vegetable items
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

// Widget for each vegetable item in the list
class VegetableListItem extends StatelessWidget {
  final VegetableItem vegetable;

  const VegetableListItem({
    super.key,
    required this.vegetable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.eco,
              color: Color(0xFF1E5128),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
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
                  'Berat: ${vegetable.weight} Kg',
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