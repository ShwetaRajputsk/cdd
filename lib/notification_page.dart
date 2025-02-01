import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reply.dart';

class NotificationPage extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF4CAF82),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserId) // Ensure this matches the logged-in user
            .orderBy('timestamp', descending: true) // Ensure 'timestamp' field exists
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              // Debug print to check the notification data
              print('Notification Data: $data');

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.notifications, color: Color(0xFF4CAF82)),
                  title: Text(
                    data['message'] ?? 'No message',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Tap to view post'),
                  onTap: () {
                    Navigator.pop(context); // Close Notification Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReplyPage(
                          postId: data['postId'],
                          question: data['question'],
                          description: data['description'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}