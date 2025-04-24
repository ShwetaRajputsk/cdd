import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'custom_app_bar.dart';
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

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('chooseOption'.tr()),
          actions: [
            TextButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                
                if (pickedFile != null) {
                  _imageData = await pickedFile.readAsBytes();
                  Navigator.of(context).pop();
                  await _sendImage(_imageData!);
                }
              },
              child: Text('uploadFromGallery'.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final imageBytes = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );

                if (imageBytes != null) {
                  setState(() {
                    _imageData = imageBytes;
                  });
                  await _sendImage(_imageData!);
                }
              },
              child: Text('takePicture'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendImage(Uint8List imageData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse('https://cddnew-2.onrender.com/predict'));
      request.files.add(http.MultipartFile.fromBytes('image', imageData, filename: 'image.jpg'));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(result);

      String prediction = jsonResponse['prediction'];
      String symptoms = (jsonResponse['symptoms'] as List).join('\n');

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantHealthScreen(
            imageData: _imageData!,
            diseaseName: prediction,
            symptoms: symptoms,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errorOccurred'.tr())),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (_currentIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'CropFit'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/graphic_image.png', height: 200, width: 200),
            SizedBox(height: 20),
            Text(
              'healthCheck'.tr(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'healthCheckDescription'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF222222)),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.upload),
              label: Text('uploadImageDetect'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3AAA49),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            _imageData == null
                ? Text('noImageSelected'.tr(), style: TextStyle(color: Color(0xFF222222)))
                : Column(
                    children: [
                      SizedBox(height: 20),
                      if (_isLoading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLoadingCircle(Colors.green),
                            SizedBox(width: 10),
                            _buildLoadingCircle(Colors.green),
                            SizedBox(width: 10),
                            _buildLoadingCircle(Colors.green),
                          ],
                        ),
                    ],
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.camera_alt),
        backgroundColor: Color(0xFF088A6A),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildLoadingCircle(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
