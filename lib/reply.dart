import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ReplyPage extends StatefulWidget {
  final String postId;
  final String? imageUrl;
  final String question;
  final String description;

  ReplyPage({
    required this.postId,
    this.imageUrl,
    required this.question,
    required this.description,
  });

  @override
  _ReplyPageState createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  final Color primaryColor = const Color(0xFF1C4B0C);
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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _name = doc['name'] ?? "Anonymous User";
            _imageUrl = doc['imageUrl'];
            _email = doc['email'];
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
      return;
    }

    try {
      String? imageUrl;

      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('replies')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (kIsWeb && selectedImage is Uint8List) {
          await ref.putData(selectedImage);
        } else if (selectedImage is File) {
          await ref.putFile(selectedImage);
        }

        imageUrl = await ref.getDownloadURL();
      }

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

      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({
        'answersCount': FieldValue.increment(1),
      });

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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImage = imageBytes;
        });
      } else {
        setState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          'Community Post',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Post Section (no Card, just clean container)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(height: 12),
                Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Replies Section
          Expanded(
            child: Container(
              color: Colors.white, // plain white background
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
                        child: Text(
                      'No replies yet. Be the first to reply!',
                      style: TextStyle(color: Colors.grey[600]),
                    ));
                  }

                  return ListView(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String? imageUrl = data['imageUrl'] as String?;
                      final String user = data['user'] ?? 'Anonymous';
                      final String? profileImage = data['profileImage'];
                      final Timestamp? timestamp =
                          data['timestamp'] as Timestamp?;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: profileImage != null &&
                                      profileImage.isNotEmpty
                                  ? NetworkImage(profileImage)
                                  : null,
                              child:
                                  (profileImage == null || profileImage.isEmpty)
                                      ? Text(
                                          user[0].toUpperCase(),
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _formatTimeAgo(timestamp),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data['reply'] != null &&
                                      data['reply'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        data['reply'],
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          imageUrl,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // Write Your Answer Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: kIsWeb
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              selectedImage,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              selectedImage,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write your answer...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.image, color: primaryColor),
                      onPressed: _pickImage,
                      tooltip: 'Add Image',
                    ),
                    SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: _submitReply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
