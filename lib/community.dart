import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'ask.dart'; // Import AskCommunityScreen
import 'reply.dart'; // Import ReplyPage
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_page.dart';
import 'bottom_navigation_bar.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _currentIndex = 1; // Define _currentIndex

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
        ],
      ),
       bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
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
              return _buildPostCard(post, context); // Pass context
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
        backgroundColor: Colors.green,
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

  Widget _buildPostCard(DocumentSnapshot post, BuildContext context) {
    final postData = post.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () {
        // Navigate to the ReplyPage and pass the post details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReplyPage(
              postId: post.id,
              imageUrl: postData.containsKey('imageUrl')
                  ? postData['imageUrl']
                  : null,
              question: postData['question'],
              description: postData['description'],
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(post),
            _buildPostContent(post),
            _buildPostFooter(post),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(DocumentSnapshot post) {
    String userName = post['userName'] ?? 'Anonymous';
    String userProfileImage = post['userProfileImage'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: userProfileImage.isNotEmpty
                    ? NetworkImage(userProfileImage)
                    : null,
                child: userProfileImage.isEmpty
                    ? Text(
                        userName[0],
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Color(0xFF4CAF82),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '2 d',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share, size: 20, color: Colors.grey),
            onSelected: (value) async {
              final postData = post.data() as Map<String, dynamic>;
              final postId = post.id;
              final postUrl = 'https://yourapp.com/community/$postId'; // Replace with your app's URL
              final shareText = 'Check out this post: ${postData['question']}\n$postUrl';

              switch (value) {
                case 'facebook':
                  final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=$postUrl';
                  if (await canLaunch(facebookUrl)) {
                    await launch(facebookUrl);
                  }
                  break;
                case 'twitter':
                  final twitterUrl = 'https://twitter.com/intent/tweet?text=$shareText';
                  if (await canLaunch(twitterUrl)) {
                    await launch(twitterUrl);
                  }
                  break;
                case 'whatsapp':
                  final whatsappUrl = 'https://wa.me/?text=$shareText';
                  if (await canLaunch(whatsappUrl)) {
                    await launch(whatsappUrl);
                  }
                  break;
                case 'share':
                  Share.share(shareText);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'facebook',
                child: Row(
                  children: [
                    Icon(Icons.facebook, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Share on Facebook'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'twitter',
                child: Row(
                  children: [
                    Icon(Icons.alternate_email, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Share on Twitter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.message, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Share on WhatsApp'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Share via...'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(DocumentSnapshot post) {
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
          if (post.data() != null &&
              (post.data() as Map<String, dynamic>).containsKey('imageUrl') &&
              post['imageUrl'] != null &&
              post['imageUrl'].isNotEmpty)
            kIsWeb
                ? Image.network(
                    post['imageUrl'],
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  )
                : Image.network(
                    post['imageUrl'],
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPostFooter(DocumentSnapshot post) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('community_posts')
          .doc(post.id)
          .collection('votes')
          .doc(currentUserId)
          .get(),
      builder: (context, voteSnapshot) {
        final hasVoted = voteSnapshot.hasData && voteSnapshot.data!.exists;
        final voteType = hasVoted ? voteSnapshot.data!['type'] : null;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .doc(post.id)
              .collection('votes')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.thumb_up_outlined),
                          label: const Text('Like'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4CAF82),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.thumb_down_outlined),
                          label: const Text('Dislike'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.grey),
                        ),
                      ],
                    ),
                    const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.thumb_up_outlined),
                          label: const Text('Like'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4CAF82),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.thumb_down_outlined),
                          label: const Text('Dislike'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.grey),
                        ),
                      ],
                    ),
                    const Text(
                      '0 answers',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Calculate total likes and dislikes
            int likes = 0;
            int dislikes = 0;
            for (final vote in snapshot.data!.docs) {
              if (vote['type'] == 'like') {
                likes++;
              } else if (vote['type'] == 'dislike') {
                dislikes++;
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          if (currentUserId.isEmpty) {
                            // Handle case where user is not logged in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'You must be logged in to like a post')),
                            );
                            return;
                          }

                          final voteRef = FirebaseFirestore.instance
                              .collection('community_posts')
                              .doc(post.id)
                              .collection('votes')
                              .doc(currentUserId);

                          if (voteType == 'like') {
                            // If already liked, remove the like
                            await voteRef.delete();
                          } else {
                            // If disliked, remove the dislike
                            if (voteType == 'dislike') {
                              await voteRef.delete();
                            }
                            // Add like
                            await voteRef.set({'type': 'like'});
                          }

                          // Send notification to the post owner
                          final postOwnerId = post['userId'];
                          if (postOwnerId != currentUserId) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .add({
                              'recipientId': postOwnerId,
                              'senderId': currentUserId,
                              'message': 'Someone liked your post',
                              'postId': post.id,
                              'question': post['question'],
                              'description': post['description'],
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                          }

                          setState(() {}); // Update the UI
                        },
                        icon: Icon(
                          Icons.thumb_up_outlined,
                          color: voteType == 'like'
                              ? const Color(0xFF4CAF82)
                              : Colors.grey,
                        ),
                        label: Text(
                          'Like ($likes)',
                          style: TextStyle(
                            color: voteType == 'like'
                                ? const Color(0xFF4CAF82)
                                : Colors.grey,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF82),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          if (currentUserId.isEmpty) {
                            // Handle case where user is not logged in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'You must be logged in to dislike a post')),
                            );
                            return;
                          }

                          final voteRef = FirebaseFirestore.instance
                              .collection('community_posts')
                              .doc(post.id)
                              .collection('votes')
                              .doc(currentUserId);

                          if (voteType == 'dislike') {
                            // If already disliked, remove the dislike
                            await voteRef.delete();
                          } else {
                            // If liked, remove the like
                            if (voteType == 'like') {
                              await voteRef.delete();
                            }
                            // Add dislike
                            await voteRef.set({'type': 'dislike'});
                          }

                          // Send notification to the post owner
                          final postOwnerId = post['userId'];
                          if (postOwnerId != currentUserId) {
                            await FirebaseFirestore.instance
                                .collection('notifications')
                                .add({
                              'recipientId': postOwnerId,
                              'senderId': currentUserId,
                              'message': 'Someone disliked your post',
                              'postId': post.id,
                              'question': post['question'],
                              'description': post['description'],
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                          }

                          setState(() {}); // Update the UI
                        },
                        icon: Icon(
                          Icons.thumb_down_outlined,
                          color: voteType == 'dislike'
                              ? const Color(0xFF4CAF82)
                              : Colors.grey,
                        ),
                        label: Text(
                          'Dislike ($dislikes)',
                          style: TextStyle(
                            color: voteType == 'dislike'
                                ? const Color(0xFF4CAF82)
                                : Colors.grey,
                          ),
                        ),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.grey),
                      ),
                    ],
                  ),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(post.id)
                        .collection('replies') // Fetch the answers count
                        .get(),
                    builder: (context, answersSnapshot) {
                      int answersCount = answersSnapshot.hasData ? answersSnapshot.data!.docs.length : 0;
                      return Text(
                        '$answersCount answers',
                        style: TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
