import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart'; // For .tr()

class AskCommunityScreen extends StatefulWidget {
  const AskCommunityScreen({Key? key}) : super(key: key);

  @override
  State<AskCommunityScreen> createState() => _AskCommunityScreenState();
}

class _AskCommunityScreenState extends State<AskCommunityScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImageFile; // For mobile
  Uint8List? _selectedImageBytes; // For web
  String? _selectedImageName; // For web (file name)

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web file picker
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } else {
      // Mobile file picker
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    }
  }

  Future<void> _submitPost() async {
    final question = _questionController.text.trim();
    final description = _descriptionController.text.trim();

    // Validate fields
    if (question.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ask_community.validation_empty".tr())),
      );
      return;
    }

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc();

    // Get the current user's data
    final user = FirebaseAuth.instance.currentUser;

    // Fetch the user's name from Firestore
    String userName = '';
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userName = userDoc.data()?['name'] ?? '';
      }
    }

    // If name is not set, fallback to 'Anonymous'
    userName = userName.isEmpty ? 'ask_community.anonymous'.tr() : userName;

    final userId = user?.uid ?? ''; // Use user ID

    // Fetch the user's profile image from Firestore
    String userProfileImage = '';
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userProfileImage = userDoc.data()?['imageUrl'] ?? ''; // Fetch imageUrl from Firestore
      }
    }

    Map<String, dynamic> postData = {
      'question': question,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'userName': userName, // Use the fetched userName
      'userId': userId, // Add user's ID
      'userProfileImage': userProfileImage, // Add user's profile image URL
    };

    // Upload image if selected
    if (_selectedImageFile != null || _selectedImageBytes != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef = storageRef.child('community_images/${postRef.id}.jpg');

        if (kIsWeb && _selectedImageBytes != null) {
          // Upload image as bytes (web)
          await imageRef.putData(_selectedImageBytes!);
        } else if (_selectedImageFile != null) {
          // Upload image file (mobile)
          await imageRef.putFile(_selectedImageFile!);
        }

        final imageUrl = await imageRef.getDownloadURL();
        postData['imageUrl'] = imageUrl;
        print("Image URL: $imageUrl");
      } catch (e) {
        print("Error uploading image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ask_community.image_upload_error".tr())),
        );
        return;
      }
    }

    try {
      await postRef.set(postData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ask_community.post_success".tr())),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error saving post: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${"ask_community.post_error".tr()}: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ask_community.title'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text('ask_community.add_image'.tr()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              if (_selectedImageFile != null || _selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: kIsWeb
                      ? Image.memory(
                          _selectedImageBytes!,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _selectedImageFile!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                ),
              const SizedBox(height: 16),
              Text(
                'ask_community.improve_probability'.tr(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                child: Text('ask_community.add_crop'.tr()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ask_community.your_question'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _questionController,
                      maxLength: 200,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "ask_community.question_hint".tr(),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (text) => setState(() {}),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Text(
                        '${_questionController.text.length} / 200 ${"ask_community.characters".tr()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ask_community.description'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLength: 2500,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'ask_community.description_hint'.tr(),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (text) => setState(() {}),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Text(
                        '${_descriptionController.text.length} / 2500 ${"ask_community.characters".tr()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitPost,
                  child: Text('ask_community.send'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
