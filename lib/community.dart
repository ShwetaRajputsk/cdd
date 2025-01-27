import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'ask.dart'; // Import AskCommunityScreen

class CommunityPage extends StatelessWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF82),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Community',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notification action here
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(post);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to "Ask Community" page or functionality
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AskCommunityScreen()),
          );
        },
        backgroundColor: const Color(0xFF4CAF82),
        label: const Row(
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text('Ask Community', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(),
          _buildPostContent(post),
          _buildPostFooter(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                child: const Text('AB'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Aaki Babu',
                    style: TextStyle(
                      color: Color(0xFF4CAF82),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '2 d',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              // Handle "Share Post" action here
            },
            icon: const Icon(Icons.share, size: 20),
            label: const Text('Share'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(DocumentSnapshot post) {
  // Log the post data when retrieving
  print("Post data retrieved: ${post.data()}");

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post['question'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          post['description'],
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        // Image display logic: Check if imageUrl is available in the post
        if (post.data() != null && (post.data() as Map<String, dynamic>).containsKey('imageUrl') && post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
          kIsWeb
              ? Image.network(
                  post['imageUrl'],
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                )
              : Image.network(
                  post['imageUrl'], // Replace this line with Image.file for mobile
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
        const SizedBox(height: 12),
      ],
    ),
  );
}
  Widget _buildPostFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  // Handle "Like" action here
                },
                icon: const Icon(Icons.thumb_up_outlined),
                label: const Text('Like'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF82),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // Handle "Dislike" action here
                },
                icon: const Icon(Icons.thumb_down_outlined),
                label: const Text('Dislike'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            ],
          ),
          const Text(
            '2 answers',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
