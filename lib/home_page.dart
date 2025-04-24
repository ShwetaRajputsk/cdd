import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'select_your_crop_page.dart';
import 'disease_detect.dart';
import 'account.dart';
import 'community.dart';
import 'chat.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'bottom_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, String>> _selectedCrops = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        List<dynamic> crops = userDoc['crops'] ?? [];
        setState(() {
          _selectedCrops = List<Map<String, String>>.from(crops.map((crop) => Map<String, String>.from(crop)));
        });
      } else {
        setState(() {
          _selectedCrops = [];
        });
      }
    }
  }

  Future<void> _saveCropsToFirestore() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
        await userDocRef.update({
          'crops': _selectedCrops,
        });
      } catch (e) {
        print('Error saving crops to Firestore: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CropDiseaseHome()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Cropfit'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'selectYourCrop'.tr(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.green[700]),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SelectYourCropPage(selectedCrops: _selectedCrops),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedCrops = result;
                        });
                        await _saveCropsToFirestore();
                      }
                    },
                  ),
                ],
              ),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedCrops.length,
                  itemBuilder: (context, index) {
                    return _buildCropCard(
                      _selectedCrops[index]['image']!,
                      _selectedCrops[index]['name']!,
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                'trendingNews'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: ListTile(
                  title: Text('latestNews'.tr()),
                  subtitle: Text('learnMore'.tr()),
                  trailing: Icon(Icons.arrow_forward),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'beYourCropDoctor'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: ListTile(
                  title: Text('takePicture'.tr()),
                  subtitle: Text('seeDiagnosis'.tr()),
                  trailing: Icon(Icons.camera_alt),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CropDiseaseHome(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                'weatherReport'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: WeatherService().fetchWeather('New Delhi'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.error, color: Colors.red),
                        title: Text('error'.tr()),
                        subtitle: Text('weatherLoadFailed'.tr()),
                      ),
                    );
                  } else {
                    final weatherData = snapshot.data;
                    final temperature = weatherData?['current']['temperature'];
                    final description =
                        weatherData?['current']['weather_descriptions'][0];
                    final location = weatherData?['location']['name'];
                    final region = weatherData?['location']['region'];
                    final country = weatherData?['location']['country'];

                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.cloud, color: Colors.blue),
                        title: Text('$location, $region'),
                        subtitle: Text('$country\n$temperature°C, $description'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage()),
          );
        },
        child: Icon(Icons.chat),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCropCard(String imagePath, String cropName) {
    return Card(
      child: Container(
        width: 80,
        child: Column(
          children: [
            Image.asset(imagePath, height: 60, width: 60),
            SizedBox(height: 8),
            Text(cropName, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class WeatherService {
  final String apiKey = '8f55f11d2f02d7c3620e7d4f8860ea70';

  Future<Map<String, dynamic>> fetchWeather(String location) async {
    final response = await http.get(
      Uri.parse(
          'http://api.weatherstack.com/current?access_key=$apiKey&query=$location'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
