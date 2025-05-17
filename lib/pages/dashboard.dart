import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

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
                            const Text(
                              'Selamat Datang, User',
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
                _buildWeighingHistoryItem(),
                _buildWeighingHistoryItem(),
                _buildWeighingHistoryItem(),
                _buildWeighingHistoryItem(),
                
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

  Widget _buildWeighingHistoryItem() {
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
            image: const DecorationImage(
              image: AssetImage('assets/images/vegetable_placeholder.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: const Text(
          'Jenis Sayur',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Day, dd-mm-yy\nBerat: xx kg',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to detail
          Navigator.pushNamed(context, '/weighing-detail');
        },
      ),
    );
  }
}