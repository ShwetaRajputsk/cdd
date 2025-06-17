import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
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
  bool _showImageError = false;
  int _currentIndex = 2;
  final Color primaryColor = const Color(0xFF1C4B0C);
  final Color errorColor = const Color(0xFFD32F2F);

  Future<void> _pickImage() async {
    setState(() {
      _showImageError = false; // Reset error when picking new image
    });
    
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
                  Navigator.of(context).pop();
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  
                  if (pickedFile != null) {
                    try {
                      _imageData = await pickedFile.readAsBytes();
                      setState(() {});
                      await _sendImage(_imageData!);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('errorReadingImage'.tr())),
                      );
                    }
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
    setState(() {
      _isLoading = true;
      _showImageError = false;
    });

    try {
      // Check image size before sending
      if (imageData.lengthInBytes > 5 * 1024 * 1024) { // 5MB
        throw Exception('imageTooLarge'.tr());
      }

      final request = http.MultipartRequest('POST', Uri.parse('https://cddnew-15.onrender.com/predict'));
      request.files.add(http.MultipartFile.fromBytes('image', imageData, filename: 'image.jpg'));

      // Set timeout to 30 seconds
      final response = await request.send().timeout(const Duration(seconds: 30));
      
      // Get response data before handling status codes
      final responseData = await response.stream.toBytes();
      final result = String.fromCharCodes(responseData);
      
      // Handle different status codes
      if (response.statusCode == 500) {
        throw Exception('serverProcessingError'.tr());
      } 
      else if (response.statusCode == 400) {
        setState(() => _showImageError = true);
        return;
      } 
      else if (response.statusCode != 200) {
        throw Exception('serverError ${response.statusCode}'.tr());
      }

      // Process successful response
      final jsonResponse = jsonDecode(result);

      // Handle null values safely
      final diseaseName = jsonResponse['prediction']?.toString() ?? 'unknownDisease'.tr();
      final symptomsList = jsonResponse['symptoms'] as List?;
      final symptoms = symptomsList?.join('\n') ?? 'noSymptomsAvailable'.tr();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantHealthScreen(
            imageData: imageData,
            diseaseName: diseaseName,
            symptoms: symptoms,
          ),
        ),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('requestTimedOut'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: errorColor),
              const SizedBox(width: 8),
              Text(
                'invalidImageTitle'.tr(),
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'invalidImageDescription'.tr(),
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildGuidelineRow(Icons.check_circle, 'guideline1'.tr()),
          _buildGuidelineRow(Icons.check_circle, 'guideline2'.tr()),
          _buildGuidelineRow(Icons.check_circle, 'guideline3'.tr()),
          const SizedBox(height: 8),
          _buildGuidelineRow(Icons.cancel, 'avoid1'.tr(), isError: true),
          _buildGuidelineRow(Icons.cancel, 'avoid2'.tr(), isError: true),
        ],
      ),
    );
  }

  Widget _buildGuidelineRow(IconData icon, String text, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isError ? errorColor : primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isError ? errorColor : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
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
            const SizedBox(height: 24),
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
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
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
                        if (_showImageError) _buildErrorCard(),
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
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        backgroundColor: primaryColor,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
