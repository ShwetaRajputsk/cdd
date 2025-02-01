import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart'; // Import the EditProfileScreen
import 'login.dart'; // Import the LoginPage for logout navigation
import 'bottom_navigation_bar.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? _imageUrl;
  String? _name;
  String? _email;
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile data (name, email, and image) from Firestore
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user profile data from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _imageUrl = doc['imageUrl']; // Fetch the image URL from Firestore
          _name = doc['name']; // Fetch the name from Firestore
          _email = doc['email']; // Fetch the email from Firestore
        });
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Customize the AppBar
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'), // Replace with your logo path
        ),
        title: const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Customize the title color
          ),
        ),
        centerTitle: true,
        elevation: 0, // Remove the shadow
        backgroundColor: Colors.white, // Set the background color
        iconTheme: const IconThemeData(
          color: Colors.black, // Customize the back button color
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            InkWell(
              onTap: () {
                // Navigate to the EditProfileScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              child: Row(
                children: [
                  // Profile Image
                  _imageUrl != null
                      ? CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(_imageUrl!),
                        )
                      : const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 30),
                        ),
                  const SizedBox(width: 16),
                  // Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name ?? 'Shweta Rajput',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email ?? 'shwetarajputskk@gmail.com',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upgrade Plan Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Upgrade Plan to Unlock More!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enjoy all the benefits and explore more possibilities',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle upgrade plan action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Upgrade Plan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Sections
            _buildSettingItem(Icons.notifications, 'Notifications'),
            _buildSettingItem(Icons.security, 'Account & Security'),
            _buildSettingItem(Icons.credit_card, 'Billing & Subscriptions'),
            _buildSettingItem(Icons.language, 'Language & Region'),
            _buildSettingItem(Icons.palette, 'App Appearance'),
            _buildSettingItem(Icons.help_outline, 'Help & Support'),
            const SizedBox(height: 1),

            // Logout Button
            InkWell(
              onTap: () {
                // Navigate to the LoginScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 16),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // Handle bottom navigation item tap
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Helper method to build setting items with icons
  Widget _buildSettingItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

}
