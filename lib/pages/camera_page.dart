import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

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

    final file = await _cameraController!.takePicture();
    final compressed = await _compressImage(File(file.path));

    setState(() {
      _isProcessing = false;
    });

    if (compressed != null) {
      _navigateToPreview(compressed.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isProcessing = true;
      });

      final compressed = await _compressImage(File(pickedFile.path));
      
      setState(() {
        _isProcessing = false;
      });
      
      if (compressed != null) {
        _navigateToPreview(compressed.path);
      }
    }
  }

  void _navigateToPreview(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoPreviewPage(imagePath: imagePath),
      ),
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
                    : CameraPreview(_cameraController!),
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
                      'Ambil foto sayur untuk memulai \npendeteksian jenis sayur',
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

class PhotoPreviewPage extends StatefulWidget {
  final String imagePath;

  const PhotoPreviewPage({super.key, required this.imagePath});

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  late String fileSize;

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
            Image.file(File(widget.imagePath), height: 300),
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
                    onPressed: () {
                      // ini nanti lanjut proses kirim foot ke backend
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
}
