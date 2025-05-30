import 'package:flutter/material.dart';
import 'dart:io';

class WeighingResultPage extends StatelessWidget {
  final String imagePath;
  final String vegetableName;
  final String totalWeight;
  final String weighingDate;
  final String photoSentTime;
  final String resultReceivedTime;

  const WeighingResultPage({
    super.key,
    required this.imagePath,
    required this.vegetableName,
    required this.totalWeight,
    required this.weighingDate,
    required this.photoSentTime,
    required this.resultReceivedTime,
  });

  @override
  Widget build(BuildContext context) {
    // Capitalize first letter of vegetable name
    final String capitalizedVegetableName = 
        vegetableName.isNotEmpty ? 
        vegetableName[0].toUpperCase() + vegetableName.substring(1).toLowerCase() : 
        '';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success message
                const Text(
                  'Sayur berhasil terdeteksi!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A3E06),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 35),
                
                // Vegetable image - fixed to display correctly
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imagePath.startsWith('http')
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : imagePath.startsWith('assets/')
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Vegetable name - Now properly capitalized
                Text(
                  capitalizedVegetableName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Weighing information - Updated to match design
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Berat Total:', totalWeight),
                      const SizedBox(height: 8),
                      _buildInfoRow('Tanggal penimbangan:', weighingDate),
                      const SizedBox(height: 8),
                      _buildInfoRow('Waktu pengiriman data:', photoSentTime),
                      const SizedBox(height: 8),
                      _buildInfoRow('Waktu data diterima:', resultReceivedTime),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Action buttons - Updated to match design
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/history');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0A3E06)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Lihat riwayat penimbangan',
                          style: TextStyle(
                            color: Color(0xFF0A3E06),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/dashboard', 
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3E06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Kembali ke beranda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}