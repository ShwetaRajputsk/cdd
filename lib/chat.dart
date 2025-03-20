import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // Stores chat history
  bool _isLoading = false;
  final String _apiKey = "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";
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

@override
  void initState() {
    super.initState();
    _loadChatHistory(); // Load history on page load
  }

  // Method to load chat history from Firestore
 // ...existing code...

Future<void> _loadChatHistory() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Ensure user is logged in
  final userId = user.uid; // Get the current user's unique ID

  final chatHistoryRef = FirebaseFirestore.instance
      .collection('chat_history')
      .doc(userId)
      .collection('messages')
      .orderBy('timestamp', descending: true);

  final querySnapshot = await chatHistoryRef.get();
  final List<Map<String, String>> historyMessages = [];

  for (var doc in querySnapshot.docs) {
    historyMessages.add({
      'role': 'assistant',
      'content': doc['bot_response'],
    });
    historyMessages.add({
      'role': 'user',
      'content': doc['user_query'],
    });
  }

  setState(() {
    _messages.insertAll(0, historyMessages.reversed.toList());
  });
}
// ...existing code...

  // Method to clear chat history
Future<void> _clearChatHistory() async {
  final userId = "user_unique_id"; // Use the current user's unique ID
  final chatHistoryRef = FirebaseFirestore.instance
      .collection('chat_history')
      .doc(userId)
      .collection('messages');

  // Delete all messages
  final batch = FirebaseFirestore.instance.batch();
  final querySnapshot = await chatHistoryRef.get();
  for (var doc in querySnapshot.docs) {
    batch.delete(doc.reference);
  }

  await batch.commit();
  setState(() {
    _messages.clear(); // Clear the local chat messages as well
  });
}

  // Prefilled Questions (Initially Static)
List<String> _prefilledQuestions = [
  'What are the best crops to grow in Haryana during the summer?',
  'How can I protect my crops from common diseases?',
  'What is the ideal irrigation system for my crops?',
  'Can you suggest sustainable farming practices for my farm?',
];


  // Function to Update Prefilled Questions Dynamically
void _updatePrefilledQuestions(String userQuery) async {
  String apiKey = "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"; // Use your actual key
  String model = "llama3-8b-8192"; 
  String prompt = "Generate exactly 4 short, clear follow-up questions based on this query: \"$userQuery\". Only return the 4 questions in a numbered list format, without any extra text.";

  try {
    var response = await http.post(
      Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": model,
        "messages": [
          {"role": "system", "content": "You are an expert in agriculture. Generate only logical follow-up questions."},
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 100,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data["choices"] != null && data["choices"].isNotEmpty) {
        String content = data["choices"][0]["message"]["content"];

        // Extract questions by removing numbering
        List<String> generatedQuestions = content
            .split(RegExp(r'\d+\.\s')) // Splitting based on "1. ", "2. " etc.
            .where((q) => q.trim().isNotEmpty)
            .toList();
        setState(() {
          _prefilledQuestions = generatedQuestions.take(4).toList();
        });
      } else {
        setState(() {
          _prefilledQuestions = ["No follow-up questions generated. Try again!"];
        });
      }
    } else {
      setState(() {
        _prefilledQuestions = ["Couldn't generate follow-up questions. Please try again!"];
      });
    }
  } catch (e) {
    setState(() {
      _prefilledQuestions = ["Error occurred. Please try again!"];
    });
  }
}
  // Function to send message to Groq API with better response handling
Future<void> _sendMessage() async {
  String userInput = _controller.text.trim();
  if (userInput.isEmpty) return;

  setState(() {
    _messages.add({"role": "user", "content": userInput});
    _controller.clear();
    _isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        "Authorization": "Bearer $_apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "llama3-8b-8192",
        "messages": _messages,
        "temperature": 0.7,
        "max_tokens": 800,
        "top_p": 1,
        "n": 1,
        "stream": false
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String botResponse = data['choices'][0]['message']['content'] ?? '';
      botResponse = botResponse.replaceAll("\n\n", "\n").trim();

      setState(() {
        _messages.add({"role": "assistant", "content": botResponse});
        _updatePrefilledQuestions(userInput); // Update follow-up questions
      });

      // Store question and response in Firestore
      await _saveMessageToHistory(userInput, botResponse);
    } else {
      throw Exception("API Error: ${response.statusCode}");
    }
  } catch (e) {
    setState(() {
      _messages.add({
        "role": "assistant",
        "content": "Sorry, I couldn't process your request. Please try again."
      });
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// ...existing code...

Future<void> _saveMessageToHistory(String userQuery, String botResponse) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return; // Ensure user is logged in
  final userId = user.uid; // Get the current user's unique ID

  final chatHistoryRef = FirebaseFirestore.instance.collection('chat_history').doc(userId);

  await chatHistoryRef.collection('messages').add({
    'user_query': userQuery,
    'bot_response': botResponse,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
// ...existing code...

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(60), // Adjust the height of your custom AppBar
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Cropfit Digital Assistant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
             
IconButton(
  icon: const Icon(Icons.delete, color: Colors.red), // Trash bin icon
  onPressed: () async {
    await _clearChatHistory(); // Clear chat history when tapped
  },
),
          ],
        ),
      ),
    ),
      body: SafeArea(
        child: Column(
          children: [
           // Welcoming Message Section
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFE1F5FE),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.emoji_emotions,
        color: Colors.blue,
        size: 24,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Welcome to the Cropfit Digital Assistant! How can I assist you today?',
          style: TextStyle(color: Colors.blue[800]),
        ),
      ),
    ],
  ),
),

           // Suggested Questions Section
Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      Text(
        'Ask your queries or choose from the questions below:',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 50, // Adjust height to avoid taking too much space
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _prefilledQuestions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return ActionChip(
              label: Text(_prefilledQuestions[index]),
              onPressed: () {
                _controller.text = _prefilledQuestions[index];
                _sendMessage();
              },
            );
          },
        ),
      ),
    ],
  ),
),
            // Chat Messages Section
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  bool isUser = msg["role"] == "user";

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
               child: Container(
  margin: const EdgeInsets.symmetric(vertical: 4),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: isUser ? Colors.blue[100] : Colors.green[100],
    borderRadius: BorderRadius.circular(8),
  ),
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
    child: Text(
      msg["content"]!,
      style: TextStyle(color: isUser ? Colors.blue[900] : Colors.green[900]),
      softWrap: true,
    ),
  ),
),

                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),

            // Input Area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: Colors.blue[600],
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
