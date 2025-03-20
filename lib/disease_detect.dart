import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart'; // Import the camera screen
import 'home_page.dart'; // Import the Home Page
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'custom_app_bar.dart';
import 'bottom_navigation_bar.dart';
import 'prediction.dart'; // Import the prediction screen

class CropDiseaseHome extends StatefulWidget {
  @override
  _CropDiseaseHomeState createState() => _CropDiseaseHomeState();
}

class _CropDiseaseHomeState extends State<CropDiseaseHome> {
  Uint8List? _imageData; // To hold the selected image data
  bool _isLoading = false; // Add loading state
  int _currentIndex = 2; // Track the current index for bottom navigation

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose an option'),
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
              child: Text('Upload from Gallery'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                final imageBytes = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );

                if (imageBytes != null) {
                  setState(() {
                    _imageData = imageBytes; // Set the captured image data
                  });
                  await _sendImage(_imageData!); // Send for disease detection
                }
              },
              child: Text('Take a Picture'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendImage(Uint8List imageData) async {
    setState(() {
      _isLoading = true; // Set loading state to true
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
        _isLoading = false; // Set loading state to false after the response
      });

      // Navigate to the prediction screen after the prediction is ready
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
        _isLoading = false; // Set loading state to false in case of error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      // Navigate to different pages based on selected index
      if (_currentIndex == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
      // You can add more navigation logic for other items if needed
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
              'Health Check',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Take a picture of your crop or upload an image to detect diseases and receive treatment advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF222222)),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.upload),
              label: Text('Upload Image & Detect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3AAA49),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            _imageData == null
                ? Text('No image selected.', style: TextStyle(color: Color(0xFF222222)))
                : Column(
                    children: [
                      // Image.memory(_imageData!, height: 200, width: 200), // Display captured or uploaded image
                      SizedBox(height: 20),
                      // Show loading indicator while processing
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
        onPressed: _pickImage, // Navigate to the image picker page
        child: Icon(Icons.camera_alt),
        backgroundColor: Color(0xFF088A6A),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method to build a loading circle
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
