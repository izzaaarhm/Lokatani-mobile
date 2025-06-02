import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lokatech_timbangan/pages/camera_page.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Penimbangan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: isDetectionFailed
              ? _buildDetectionFailed(context)
              : _buildDetectionSuccess(context, capitalizedVegetableName),
        ),
      ),
    );
  }

  Widget _buildDetectionSuccess(BuildContext context, String capitalizedVegetableName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 24),
        Text(
          capitalizedVegetableName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3F7C35),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Berat: $totalWeight',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tanggal: $weighingDate',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        // Debug info (optional)
        Text(
          'Foto dikirim: $photoSentTime\nHasil diterima: $resultReceivedTime',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to Profil page and clear stack up to main navigation
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/profile',
              (route) => false,
            );
          },
          icon: const Icon(Icons.check),
          label: const Text('Selesai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F7C35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionFailed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.error_outline, color: Colors.red, size: 80),
        const SizedBox(height: 16),
        const Text(
          'Deteksi gagal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Foto tidak dapat dikenali atau terjadi kesalahan saat mendeteksi jenis sayur.\nSilakan coba lagi dengan foto yang lebih jelas.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            // Replace the result page with CameraPage for the same batch
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CameraPage(batchId: batchId),
              ),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}