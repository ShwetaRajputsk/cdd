import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      // Convert image to bytes
      final bytes = await image.readAsBytes();

      // Navigate back to main screen with image data (using Navigator.pop)
      Navigator.pop(context, bytes);
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1C4B0C);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Camera', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            Positioned.fill(
              child: _controller == null
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CameraPreview(_controller!),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error initializing camera: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        } else {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: primaryColor));
                        }
                      },
                    ),
            ),
            // Capture Button
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: GestureDetector(
                  onTap: () => _captureImage(context),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        Icon(Icons.camera_alt, color: primaryColor, size: 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
