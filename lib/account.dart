import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'bottom_navigation_bar.dart';
import 'edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Import the Login screen
import 'home_page.dart';
import 'disease_detect.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 4; // Set the current index for the bottom navigation bar
  String _name = '';
  String _email = '';
  String _profileImage = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'] ?? '';
          _email = userDoc['email'] ?? '';
          _profileImage = userDoc['profileImage'] ?? '';
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
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
      } else if (_currentIndex == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CropDiseaseHome()),
        );
      }
      // Add more navigation logic for other items if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage.isNotEmpty ? NetworkImage(_profileImage) : AssetImage('assets/profile_picture.png'), // Replace with your profile picture asset
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Colors.green),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfilePage()),
                        );
                        _loadProfile(); // Reload profile after editing
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // User Information Section
            Text(
              'Name: $_name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Email: $_email',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // Account Settings Section
            Text(
              'Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Change Password'),
              onTap: () {
                // Handle change password
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notification Settings'),
              onTap: () {
                // Handle notification settings
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}