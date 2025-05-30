import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:lokatech_timbangan/pages/weighing_result.dart';
import 'package:lokatech_timbangan/services/ml_services.dart';
import 'package:lokatech_timbangan/services/batch_services.dart';
class CameraPage extends StatefulWidget {
  final String batchId;

  const CameraPage({super.key, required this.batchId});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);

    _cameraController = CameraController(backCamera, ResolutionPreset.high);
    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<File> _cropToSquare(String imagePath) async {
    // Baca file gambar
    final bytes = await File(imagePath).readAsBytes();
    final originalImage = img.decodeImage(bytes)!;
    
    // Tentukan ukuran square (ambil yang terkecil antara width dan height)
    final size = originalImage.width < originalImage.height 
        ? originalImage.width 
        : originalImage.height;
    
    // Hitung offset untuk crop dari center
    final offsetX = (originalImage.width - size) ~/ 2;
    final offsetY = (originalImage.height - size) ~/ 2;
    
    // Crop gambar menjadi square
    final croppedImage = img.copyCrop(
      originalImage,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );
    
    final croppedBytes = img.encodeJpg(croppedImage);
    final dir = await getTemporaryDirectory();
    final croppedPath = path.join(dir.path, "cropped_${DateTime.now().millisecondsSinceEpoch}.jpg");
    final croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(croppedBytes);
    
    return croppedFile;
  }

  Future<XFile?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(dir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
    );

    return compressedFile;
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final file = await _cameraController!.takePicture();
      
      // crop menjadi rasio 1:1
      final croppedFile = await _cropToSquare(file.path);
      
      // compress
      final compressed = await _compressImage(croppedFile);

      setState(() {
        _isProcessing = false;
      });

      if (compressed != null) {
        _navigateToPreview(compressed.path);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Crop menjadi square terlebih dahulu
        final croppedFile = await _cropToSquare(pickedFile.path);
        
        // Kemudian compress
        final compressed = await _compressImage(croppedFile);
        
        setState(() {
          _isProcessing = false;
        });
        
        if (compressed != null) {
          _navigateToPreview(compressed.path);
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        print('Error processing gallery image: $e');
      }
    }
  }

  void _navigateToPreview(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoPreviewPage(
          imagePath: imagePath,
          batchId: widget.batchId,),
      ),
    );
  }

  Widget _buildSquareCameraPreview() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
        // Fullscreen camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        // Overlay gelap di luar area square
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        // Area di tengah
        Center(
          child: Container(
            width: screenWidth * 0.8,
            height: screenWidth * 0.8,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Pindai Sayuran')),
      body: _isCameraInitialized
          ? Stack(
              children: [
                _isProcessing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Mengoptimalkan gambar...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : _buildSquareCameraPreview(),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo, size: 32, color: Colors.white),
                        onPressed: _pickFromGallery,
                      ),
                      GestureDetector(
                        onTap: _takePicture,
                        child: const Icon(Icons.radio_button_checked,
                            color: Colors.white, size: 80),
                      ),
                      
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on, 
                          size: 32, 
                          color: Colors.white
                        ),
                        onPressed: () async{
                          FlashMode newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
                          await _cameraController!.setFlashMode(newMode);
                          setState(() {
                            _flashMode = newMode;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Posisikan sayur di dalam kotak\nuntuk memulai pendeteksian jenis sayur',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

//Photo Preview Page
class PhotoPreviewPage extends StatefulWidget {
  final String imagePath;
  final String batchId;

  const PhotoPreviewPage({super.key, required this.imagePath, required this.batchId});

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  late String fileSize;
  final MLService _mlService = MLService();
  final BatchService _batchService = BatchService();

  @override
  void initState() {
    super.initState();
    // utk hitung size file gambar
    final file = File(widget.imagePath);
    final bytes = file.lengthSync();
    final kb = bytes / 1024;
    fileSize = '${kb.toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timbang Sayuran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Verifikasi Foto\nApakah fotonya terlihat jelas?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            // Tampilkan foto dalam container square
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.imagePath), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ukuran file: $fileSize',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Foto Ulang'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Kirim Foto'),
                    onPressed: () async {
                      final photoSentTime = DateTime.now();
                      final photoSentTimeStr = DateFormat('HH:mm:ss').format(photoSentTime);

                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      
                      // Send photo to backend
                      final result = await _mlService.identifyVegetable(widget.imagePath, widget.batchId);
                      
                      // Close loading dialog
                      Navigator.of(context).pop();
                      
                      if (result['success']) {
                        // Set up listener for identification results
                        _listenForIdentificationResults(photoSentTimeStr);
                      } else {
                        // Show error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to identify vegetable'))
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _listenForIdentificationResults(String photoSentTimeStr) {
    // Listen for updates to the batch document
    _batchService.listenForVegetableIdentification(widget.batchId)
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        
        // Check if vegetable_type field exists and is not null
        if (data.containsKey('vegetable_type') && data['vegetable_type'] != null) {
          // Record result received timestamp
          final resultReceivedTime = DateTime.now();
          final resultReceivedTimeStr = DateFormat('HH:mm:ss').format(resultReceivedTime);
          
          // Navigate to result page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WeighingResultPage(
                imagePath: data['image_url'] ?? widget.imagePath,
                vegetableName: data['vegetable_type'] ?? 'Unknown',
                totalWeight: '${data['total_weight'] ?? 0} Kg',
                weighingDate: data['created_at'] != null
                    ? DateFormat('dd-MM-yyyy').format((data['created_at'] as Timestamp).toDate())
                    : 'Unknown',
                photoSentTime: photoSentTimeStr,
                resultReceivedTime: resultReceivedTimeStr,
              ),
            ),
          );
        }
      }
    });
  }
}