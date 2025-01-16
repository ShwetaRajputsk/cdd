import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'select_your_crop_page.dart';
import 'disease_detect.dart';
import 'account.dart'; // Import the Account Page
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_app_bar.dart';
import 'bottom_navigation_bar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cropfit',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto', // Set the global font family
      ),
      home: HomePage(),
      routes: {
        '/selectYourCrop': (context) => SelectYourCropPage(selectedCrops: []),
        '/home': (context) => CropDiseaseHome(),
        '/account': (context) => AccountPage(), // Add the Account Page route
      },
    );
  }
}

class WeatherService {
  final String apiKey = 'YOUR_API_KEY_HERE';

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

  // 🔵 Load crops from Firestore
  Future<void> _loadCrops() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        // Ensure the 'crops' field exists, or initialize it to an empty list
        List<dynamic> crops = userDoc['crops'] ?? [];
        setState(() {
          _selectedCrops = List<Map<String, String>>.from(crops.map((crop) => Map<String, String>.from(crop)));
        });
        print('Crops loaded: $_selectedCrops');
      } else {
        // If the document doesn't exist, initialize _selectedCrops as an empty list
        setState(() {
          _selectedCrops = [];
        });
        print('No crops found, initializing empty list');
      }
    } else {
      print('No user is currently signed in');
    }
  }

  // Save crops to Firestore
  Future<void> _saveCropsToFirestore() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
        await userDocRef.set({
          'crops': _selectedCrops,
        });
        print('Crops saved: $_selectedCrops');
      } catch (e) {
        print('Error saving crops to Firestore: $e');
      }
    } else {
      print('No user is currently signed in');
    }
  }

  // 🔁 Handle bottom navigation bar item taps
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
              // 🧩 Select Your Crop Section
              Row(
                children: [
                  Text(
                    'Select Your Crop',
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

              // 📰 Trending News Section
              Text(
                'Trending News',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: ListTile(
                  title: Text('Latest News on Agriculture Technology'),
                  subtitle: Text(
                      'Learn more about the latest advancements in farming.'),
                  trailing: Icon(Icons.arrow_forward),
                ),
              ),
              SizedBox(height: 16),

              // 📸 Be your Crop Doctor Section
              Text(
                'Be your Crop Doctor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: ListTile(
                  title: Text('Take a Picture'),
                  subtitle: Text('See a diagnosis and get a solution.'),
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

              // 🌦️ Weather Report Section
              Text(
                'Weather Report',
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
                        title: Text('Error'),
                        subtitle: Text('Failed to load weather data.'),
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
    );
  }
}

// 🖼️ Build Crop Card Widget
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