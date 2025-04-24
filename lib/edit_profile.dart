import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;
  String? _selectedBirthdate;
  File? _selectedImageFile; // For mobile
  Uint8List? _selectedImageBytes; // For web
  String? _selectedImageName; // For web (file name)
  String? _imageUrl; // To store the image URL fetched from Firestore

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Load user profile data (name, email, and image) from Firestore
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user profile data
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _emailController.text = doc['email'] ?? '';
          _phoneController.text = doc['phone'] ?? '';
          _selectedGender = doc['gender'] ?? 'Male';
          _selectedBirthdate = doc['birthdate'] ?? 'Select Date';
          _imageUrl = doc['imageUrl']; // Fetch the image URL from Firestore
        });
      }
    }
  }

  // Pick image (mobile or web)
  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web file picker is not supported in this version
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image picking is not supported on web in this version.")),
      );
    } else {
      // Mobile file picker
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    }
  }

  // Update profile details (name, email, and image)
  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final gender = _selectedGender ?? 'Male';
      final birthdate = _selectedBirthdate ?? 'Select Date';

      if (name.isEmpty || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Name and email cannot be empty")),
        );
        return;
      }

      Map<String, dynamic> profileData = {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
      };

      // Upload image if selected
      if (_selectedImageFile != null) {
        try {
          final storageRef = FirebaseStorage.instance.ref();
          final imageRef = storageRef.child('profile_images/${user.uid}.jpg');

          String imageUrl = _imageUrl ?? '';

          // Upload image file (mobile)
          await imageRef.putFile(_selectedImageFile!);
          imageUrl = await imageRef.getDownloadURL();

          profileData['imageUrl'] = imageUrl; // Store image URL in Firestore
          setState(() {
            _imageUrl = imageUrl; // Update the displayed image URL
          });
        } catch (e) {
          print("Error uploading image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error uploading image")),
          );
          return;
        }
      }
      // Update Firestore profile data
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(profileData, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully")),
        );
      } catch (e) {
        print("Error updating profile: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile")),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Added vertical padding
        child: Column(
          children: [
            SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!) // Mobile
                      : _imageUrl != null
                          ? NetworkImage(_imageUrl!) // Firestore URL
                          : null,
                  child: _selectedImageFile == null && _imageUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            buildTextField('Full Name', 'your name', controller: _nameController),
            SizedBox(height: 20),
            buildTextField('Email', 'yourid@gmail.com', controller: _emailController, icon: Icons.email),
            SizedBox(height: 20),
            buildTextField('Phone Number', '1234567890', controller: _phoneController, icon: Icons.phone),
            SizedBox(height: 20),
            // Gender Dropdown (styled like other fields)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gender',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender ?? 'Male',
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      isExpanded: true, // Ensures the dropdown takes full width
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            // Save Button (moved slightly higher)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 40), // Added extra space at the bottom
          ],
        ),
      ),
    );
  }
  Widget buildTextField(String label, String placeholder, {IconData? icon, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: icon != null ? Icon(icon) : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}
