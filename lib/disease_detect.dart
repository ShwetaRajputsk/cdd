import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'bottom_navigation_bar.dart';
import 'prediction.dart';
import 'package:easy_localization/easy_localization.dart';

class CropDiseaseHome extends StatefulWidget {
  @override
  _CropDiseaseHomeState createState() => _CropDiseaseHomeState();
}

class _CropDiseaseHomeState extends State<CropDiseaseHome> {
  Uint8List? _imageData;
  bool _isLoading = false;
  int _currentIndex = 2;
  final Color primaryColor = const Color(0xFF1C4B0C);

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'chooseOption'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: Text('uploadFromGallery'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  
                  if (pickedFile != null) {
                    _imageData = await pickedFile.readAsBytes();
                    Navigator.of(context).pop();
                    await _sendImage(_imageData!);
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: Text('takePicture'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imageBytes = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CameraScreen()),
                  );

                  if (imageBytes != null) {
                    setState(() => _imageData = imageBytes);
                    await _sendImage(_imageData!);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendImage(Uint8List imageData) async {
    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse('https://cddnew-2.onrender.com/predict'));
      request.files.add(http.MultipartFile.fromBytes('image', imageData, filename: 'image.jpg'));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(result);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantHealthScreen(
            imageData: _imageData!,
            diseaseName: jsonResponse['prediction'],
            symptoms: (jsonResponse['symptoms'] as List).join('\n'),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errorOccurred'.tr())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (_currentIndex == 0) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'CropFit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24), // Added space after AppBar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/graphic_image.png',
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'healthCheck'.tr(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'healthCheckDescription'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt, color: Colors.white), // Camera icon in white
                            label: Text(
                              'uploadImageDetect'.tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        if (_imageData != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              color: Colors.grey[50],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageData!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        if (_isLoading) ...[
                          const SizedBox(height: 24),
                          Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'analyzing'.tr(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white), // Camera icon in white
        backgroundColor: primaryColor,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
