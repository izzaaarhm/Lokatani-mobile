import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lokatech_timbangan/pages/camera_page.dart';
import 'package:lokatech_timbangan/config/app_theme.dart';
class _WeighingResultConstants {
    static const double padding = 40.0;
    static const double borderRadius = 12.0;
    static const Color textSecondary = Color(0xFF757575);
}
class WeighingResultPage extends StatelessWidget {
  final String imagePath;
  final String vegetableName;
  final String totalWeight;
  final String weighingDate;
  final String photoSentTime;
  final String resultReceivedTime;
  final String batchId;

  const WeighingResultPage({
    super.key,
    required this.imagePath,
    required this.vegetableName,
    required this.totalWeight,
    required this.weighingDate,
    required this.photoSentTime,
    required this.resultReceivedTime,
    required this.batchId,
  });

  @override
  Widget build(BuildContext context) {
    // Capitalize first letter of vegetable name
    final String capitalizedVegetableName = 
        vegetableName.isNotEmpty ? 
        vegetableName[0].toUpperCase() + vegetableName.substring(1).toLowerCase() : 
        '';

    final bool isDetectionFailed = vegetableName == 'Unknown' || vegetableName.isEmpty;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: isDetectionFailed
              ? _buildDetectionFailed(context)
              : _buildDetectionSuccess(context, capitalizedVegetableName),
        ),
      ),
    );
  }

  Widget _buildDetectionSuccess(BuildContext context, String capitalizedVegetableName) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success message
                  const Text(
                    'Sayur berhasil terdeteksi!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 35),
                  
                  // Vegetable image - fixed to display correctly
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
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
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
 ///////////////////////////////////////////////////////////////////////////                 
                  // Weighing information - Updated to match design
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
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
                  
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          
          // Buttons at the bottom
          Column(
            children: [
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
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 1,
                  ),
                  child: const Text(
                    'Kembali ke beranda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildDetectionFailed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_WeighingResultConstants.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline, 
              color: Colors.red.shade400, 
              size: 80
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Deteksi Gagal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Foto tidak dapat dikenali atau terjadi kesalahan saat mendeteksi jenis sayur.\n\nSilakan coba lagi dengan foto yang lebih jelas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              color: _WeighingResultConstants.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _retryCapture(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_WeighingResultConstants.borderRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _retryCapture(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CameraPage(batchId: batchId),
      ),
    );
  }
}