import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ReplyPage extends StatefulWidget {
  final String postId;
  final String? imageUrl;  // Make it nullable
  final String question;
  final String description;

  ReplyPage({
    required this.postId,
    this.imageUrl,  // Allow null values
    required this.question,
    required this.description,
  });

  @override
  _ReplyPageState createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  final TextEditingController replyController = TextEditingController();
  dynamic selectedImage;
  String _name = "Anonymous User";
  String? _imageUrl;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user profile data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _name = doc['name'] ?? "Anonymous User"; // User's display name
            _imageUrl = doc['imageUrl']; // URL for user profile image
            _email = doc['email']; // User's email
          });
        }
      } catch (e) {
        print("Error loading user profile: $e");
        setState(() {
          _name = "Anonymous User";
        });
      }
    }
  }

  Future<void> _submitReply() async {
    final replyText = replyController.text.trim();
    if (replyText.isEmpty && selectedImage == null) {
      return; // Don't submit empty replies
    }

    try {
      String? imageUrl;

      // Upload the image if selected
      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('replies')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (kIsWeb && selectedImage is Uint8List) {
          // For web, use putData
          await ref.putData(selectedImage);
        } else if (selectedImage is File) {
          // For mobile, use putFile
          await ref.putFile(selectedImage);
        }

        imageUrl = await ref.getDownloadURL();
      }

      // Add the reply to Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .add({
        'reply': replyText,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'user': _name,
        'profileImage': _imageUrl,
      });

      // Send notification to the post owner
      final postDoc = await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .get();
      final postOwnerId = postDoc['userId'];
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (postOwnerId != currentUserId) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'recipientId': postOwnerId,
          'senderId': currentUserId,
          'message': 'Someone replied to your post',
          'postId': widget.postId,
          'question': widget.question,
          'description': widget.description,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Clear the input field and image
      replyController.clear();
      selectedImage = null;
      setState(() {});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Reply submitted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      if (kIsWeb) {
        // For web, store image as bytes
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImage = imageBytes; // Store as Uint8List
        });
      } else {
        // For mobile, use File directly
        setState(() {
          selectedImage = File(pickedFile.path); // Store as File
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Post'),
      ),
      body: Column(
        children: [
          // Post Image, Question, and Description
          Card(
            margin: EdgeInsets.all(10),
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  Image.network(
                    widget.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                else
                  SizedBox(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    widget.question,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 5),
                  child: Text(
                    widget.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),

          // Replies Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('replies')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text('No replies yet. Be the first to reply!'));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String? imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] as String? : null;

                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        leading: data['profileImage'] != null
                            ? CircleAvatar(
                                backgroundImage:
                                    NetworkImage(data['profileImage']),
                              )
                            : CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                        title: Text(data['user'] ?? 'Anonymous'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['reply'] != null) Text(data['reply']),
                            if (data['imageUrl'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.network(data['imageUrl']),
                              ),
                          ],
                        ),
                        trailing: Text(
                          (data['timestamp'] as Timestamp?)
                                  ?.toDate()
                                  .toString() ??
                              '',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Write Your Answer Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    decoration: InputDecoration(
                      hintText: 'Write your answer...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _pickImage,
                ),
                ElevatedButton(
                  onPressed: _submitReply,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: kIsWeb
                  ? Image.memory(
                      selectedImage, // Display Uint8List for web
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      selectedImage, // Display File for mobile
                      height: 100,
                      fit: BoxFit.cover,
                    ),
            ),
        ],
      ),
    );
  }
}