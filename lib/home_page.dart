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
  String? _userName;
  String? _userImageUrl;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'greeting.morning'.tr();
    } else if (hour < 17) {
      return 'greeting.afternoon'.tr();
    } else {
      return 'greeting.evening'.tr();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCrops();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          Map<String, dynamic>? data = doc.data();
          if (data != null) {
            setState(() {
              _userName = data['name'];
              _userImageUrl = data['imageUrl'];
            });
          }
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: _userImageUrl != null && _userImageUrl!.isNotEmpty
                              ? NetworkImage(_userImageUrl!) as ImageProvider
                              : AssetImage('assets/profile.png'),
                          radius: 25,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${_userName ?? 'User'}!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications_none_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10), // Added extra spacing

              // Select Your Crop Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'home.selectCrop'.tr(), // Localized text
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Color(0xFF1C4B0C)),
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
                    SizedBox(height: 16),
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedCrops.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 80,
                            margin: EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      _selectedCrops[index]['image']!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _selectedCrops[index]['name']!,
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Did You Know Section
     Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1C4B0C),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, // to align with image top
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // let content define height
            children: [
              Text(
                'home.didYouKnow'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'home.didYouKnowText'.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 13),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1C4B0C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('home.seeMore'.tr()),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Image.asset(
            'assets/images/logoimage.jpg',
            height: 120, // slightly smaller to avoid overflow
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  ),
),
const SizedBox(height: 24),

              // Help Your Crop Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.helpCrop'.tr(), // Localized text
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStepItem(Icons.camera_alt, 'home.stepTakePhoto'.tr()), // Localized text
                              Text('»', style: TextStyle(fontSize: 24, color: Color(0xFF1C4B0C))),
                              _buildStepItem(Icons.search, 'home.stepAnalyze'.tr()), // Localized text
                              Text('»', style: TextStyle(fontSize: 24, color: Color(0xFF1C4B0C))),
                              _buildStepItem(Icons.description, 'home.stepReport'.tr()), // Localized text
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CropDiseaseHome(),
                                ),
                              );
                            },
                            child: Text(
                              'home.takePicture'.tr(), // Localized text
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1C4B0C),
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Weather Report Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.weatherReport'.tr(), // Localized text
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: WeatherService().fetchWeather('New Delhi'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else {
                          final hasError = snapshot.hasError || snapshot.data == null;
                          final currentData = snapshot.data?['current'] as Map<String, dynamic>?;
                          final locationData = snapshot.data?['location'] as Map<String, dynamic>?;

                          final temperature = hasError
                              ? '--'
                              : (currentData?['temperature']?.toString() ?? '--');
                          final description = hasError
                              ? '--'
                              : (currentData?['weather_descriptions']?.first?.toString() ?? '--');
                          final location = hasError
                              ? 'New Delhi'
                              : (locationData?['name']?.toString() ?? 'New Delhi');

                          return _buildWeatherCard(
                            '$location, Delhi',
                            'India\n${temperature}°C, $description',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
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
        child: const Icon(Icons.chat_rounded, color: Colors.white),
        backgroundColor: const Color(0xFF1C4B0C),
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

  Widget _buildStepItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Color(0xFF1C4B0C), size: 24),
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeatherCard(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud, color: Colors.blue, size: 24),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeatherService {
  final String apiKey = '3425e18a2e2aa355b35af5bd268e3dfe';

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
