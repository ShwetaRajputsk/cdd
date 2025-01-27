import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For platform checking

class AskCommunityScreen extends StatefulWidget {
  const AskCommunityScreen({Key? key}) : super(key: key);

  @override
  State<AskCommunityScreen> createState() => _AskCommunityScreenState();
}

class _AskCommunityScreenState extends State<AskCommunityScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery); // Use camera if needed
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

Future<void> _submitPost() async {
  final question = _questionController.text;
  final description = _descriptionController.text;

  if (question.isNotEmpty && description.isNotEmpty) {
    final postRef = FirebaseFirestore.instance.collection('community_posts').doc();

    Map<String, dynamic> postData = {
      'question': question,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_selectedImage != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref();
        final imageRef = storageRef.child('community_images/${postRef.id}.jpg');
        await imageRef.putFile(_selectedImage!);

        // Get the image URL after upload
        final imageUrl = await imageRef.getDownloadURL();
        postData['imageUrl'] = imageUrl; // Store the image URL in Firestore
        print("Image URL: $imageUrl");
      } catch (e) {
        print("Error uploading image: $e");
      }
    }

    try {
      // Log the post data before saving
      print("Post data before saving: $postData");

      // Save the post data (including image URL if available) in Firestore
      await postRef.set(postData);
      Navigator.pop(context);
    } catch (e) {
      print("Error saving post: $e");
    }
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
        title: const Text(
          'Ask Community',
          style: TextStyle(
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
                label: const Text('Add image'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: kIsWeb // Check if the platform is web
                      ? Image.network(
                          _selectedImage!.path, // Use the network URL for web
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _selectedImage!, // Use the file image on mobile
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Improve the probability of receiving the right answer',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Add crop'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your question to the community',
                style: TextStyle(
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
                      decoration: const InputDecoration(
                        hintText: "Add a question indicating what's wrong with your crop",
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (text) => setState(() {}),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Text(
                        '${_questionController.text.length} / 200 Characters',
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
              const Text(
                'Description of your problem',
                style: TextStyle(
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
                      decoration: const InputDecoration(
                        hintText: 'Describe specialities such as change of leaves, root colour, bugs, tears...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (text) => setState(() {}),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Text(
                        '${_descriptionController.text.length} / 2500 Characters',
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
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
