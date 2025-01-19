import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'custom_app_bar.dart';
import 'bottom_navigation_bar.dart';
import 'camera_screen.dart';
import 'home_page.dart';

class CropDiseaseHome extends StatefulWidget {
  @override
  _CropDiseaseHomeState createState() => _CropDiseaseHomeState();
}

class _CropDiseaseHomeState extends State<CropDiseaseHome> {
  Uint8List? _imageData;
  String _prediction = '';
  String _symptoms = '';
  bool _isLoading = false;
  int _currentIndex = 2;
  Map<String, dynamic> _symptomsData = {};

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadSymptomsData();
  }

  // Load TFLite model
  Future<void> _loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: "assets/crop_disease_model.tflite",
        labels: "assets/data/labels.txt",
      );
      print("Model loaded: $res");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  // Load symptoms data from JSON file
  Future<void> _loadSymptomsData() async {
    try {
      String data = await rootBundle.loadString("assets/data/labels_with_symptoms.json");
      setState(() {
        _symptomsData = json.decode(data);
      });
    } catch (e) {
      print("Failed to load symptoms data: $e");
    }
  }

  // Image picker function
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
                final pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);

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

  // Send image to model for prediction
  Future<void> _sendImage(Uint8List imageData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_image.jpg';
      final imageFile = File(filePath)..writeAsBytesSync(imageData);

      var result = await Tflite.runModelOnImage(
        path: filePath,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _prediction = result[0]['label'] ?? 'No prediction available';
        });
        await _loadSymptoms(); // Load symptoms for the predicted label
      } else {
        setState(() {
          _prediction = 'No result found';
          _symptoms = 'No symptoms found';
        });
      }
    } catch (e) {
      setState(() {
        _prediction = 'Error: $e';
        _symptoms = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load symptoms for the predicted label
  Future<void> _loadSymptoms() async {
    try {
      final List<String>? symptomsList = _symptomsData[_prediction]?['symptoms']?.cast<String>();
      setState(() {
        _symptoms = symptomsList != null
            ? symptomsList.join("\n") // Join the list items into a single string
            : 'Symptoms not available for this label';
      });
    } catch (e) {
      print("Failed to load symptoms for prediction: $e");
      setState(() {
        _symptoms = 'Error loading symptoms data';
      });
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
                      Image.memory(_imageData!, height: 200, width: 200),
                      SizedBox(height: 20),
                      Card(
                        color: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prediction:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF088A6A),
                                ),
                              ),
                              SizedBox(height: 10),
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : Text(
                                      _prediction,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Card(
                        color: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Symptoms:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF088A6A),
                                ),
                              ),
                              SizedBox(height: 10),
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : Text(
                                      _symptoms,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                            ],
                          ),
                        ),
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
}
