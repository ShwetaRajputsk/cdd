import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';  // Import main page where image will be shown

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
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: Column(
        children: [
          Expanded(
            child: _controller == null
                ? Center(child: CircularProgressIndicator())
                : FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_controller!);
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error initializing camera: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
          ),
          ElevatedButton.icon(
            onPressed: () => _captureImage(context),
            icon: Icon(Icons.camera_alt),
            label: Text('Capture Image'),
          ),
        ],
      ),
    );
  }
}
