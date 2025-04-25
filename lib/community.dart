import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:easy_localization/easy_localization.dart'; // Import for FirebaseAuth
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
  int _currentIndex = 1;
  String? _userName;
  String? _userImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _userName = data?['name'];
            _userImageUrl = data?['imageUrl'];
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Grow with nature';
    if (hour < 17) return 'Care for your crops';
    return 'Evening check-up time';
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _userImageUrl != null && _userImageUrl!.isNotEmpty
                  ? NetworkImage(_userImageUrl!) as ImageProvider
                  : AssetImage('assets/profile.png'),
              radius: 20,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
               'Hi, ${_userName ?? 'User'}!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_outlined, color: Colors.grey[800]),
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
      body: Column(
        children: [
          // Help Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1C4B0C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('community.help_card_title'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          tr('community.help_card_description'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AskCommunityScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF1C4B0C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            tr('community.ask_community'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/assistant_icon.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1C4B0C)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          tr('community.no_posts'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          tr('community.start_discussion'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final posts = snapshot.data!.docs;
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _buildPostCard(posts[index], context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot post, BuildContext context) {
    final postData = post.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(post),
          _buildPostContent(post),
          _buildPostFooter(post),
        ],
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: userProfileImage.isNotEmpty
                      ? NetworkImage(userProfileImage)
                      : null,
                  child: userProfileImage.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1C4B0C),
                                Color(0xFF2E7D32),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              userName[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      color: Color(0xFF1C4B0C),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '2 d',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
              PopupMenuItem(
                value: 'facebook',
                child: Row(
                  children: [
                    Icon(Icons.facebook, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(tr('community.share.facebook')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'twitter',
                child: Row(
                  children: [
                    Icon(Icons.alternate_email, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(tr('community.share.twitter')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.message, color: Colors.green),
                    SizedBox(width: 8),
                    Text(tr('community.share.whatsapp')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(tr('community.share.other')),
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
                            foregroundColor: const Color(0xFF1C4B0C),
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
                            foregroundColor: const Color(0xFF1C4B0C),
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
                    Text(
                      tr('community.answers', args: [0.toString()]),
                      style: const TextStyle(color: Colors.grey),
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
                              ? const Color(0xFF1C4B0C)
                              : Colors.grey,
                        ),
                        label: Text(
                          '${tr('community.like')} ($likes)',
                          style: TextStyle(
                            color: voteType == 'like'
                                ? const Color(0xFF1C4B0C)
                                : Colors.grey,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1C4B0C),
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
                              ? const Color(0xFF1C4B0C)
                              : Colors.grey,
                        ),
                        label: Text(
                          '${tr('community.dislike')} ($dislikes)',
                          style: TextStyle(
                            color: voteType == 'dislike'
                                ? const Color(0xFF1C4B0C)
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
