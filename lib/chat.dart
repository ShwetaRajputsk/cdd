import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final String _apiKey = "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";
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  List<String> _prefilledQuestions = [
    'bestCropsSummer'.tr(),
    'protectCropsDiseases'.tr(),
    'idealIrrigationSystem'.tr(),
    'sustainableFarmingPractices'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chat_history')
          .doc(user.uid)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      if (mounted) {
        setState(() {
          _messages.clear();
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            _messages.add({
              'role': 'user',
              'content': data['user_query'] ?? '',
              'timestamp': data['timestamp']?.toDate(),
            });
            if (data['bot_response'] != null && data['bot_response'].isNotEmpty) {
              _messages.add({
                'role': 'assistant',
                'content': data['bot_response'] ?? '',
                'timestamp': data['timestamp']?.toDate(),
              });
            }
          }
          // Sort messages by timestamp
          _messages.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint("Error loading chat history: $e");
    }
  }

  Future<void> _clearChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chat_history')
          .doc(user.uid)
          .collection('messages')
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      if (mounted) {
        setState(() {
          _messages.clear();
        });
      }
    } catch (e) {
      debugPrint("Error clearing chat history: $e");
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'clearHistoryError'.tr(),
            'timestamp': DateTime.now(),
          });
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty || _isLoading) return;

    final userMessage = {
      'role': 'user',
      'content': userInput,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Save user message to Firestore first
    final docRef = await FirebaseFirestore.instance
        .collection('chat_history')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('messages')
        .add({
      'user_query': userInput,
      'bot_response': '',
      'timestamp': FieldValue.serverTimestamp(),
    });
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "llama3-70b-8192",
          "messages": [
           {
      "role": "system",
      "content": "You are a agricultural assistant. You can ask questions or choose from the suggestions below.",
    },
            ..._messages.map((msg) => {
              "role": msg["role"],
              "content": msg["content"]
            }).toList()
          ],
          "temperature": 0.7,
          "max_tokens": 1024,
          "top_p": 1,
          "stream": false
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['choices'][0]['message']['content']?.trim() ?? '';
        
        if (botResponse.isEmpty) throw Exception("Empty response");

        final botMessage = {
          'role': 'assistant',
          'content': botResponse,
          'timestamp': DateTime.now(),
        };

        setState(() {
          _messages.add(botMessage);
        });

        // Update Firestore with bot response
        await docRef.update({
          'bot_response': botResponse,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        _scrollToBottom();
      } else {
        throw HttpException("API Error", statusCode: response.statusCode);
      }
    } on TimeoutException {
      _showErrorMessage("timeoutError".tr());
    } on SocketException {
      _showErrorMessage("connectionFailed".tr());
    } on HttpException catch (e) {
      _showErrorMessage("apiError".tr(args: [e.statusCode.toString()]));
    } catch (e) {
      _showErrorMessage("errorProcessingRequest".tr());
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": message,
          "timestamp": DateTime.now(),
        });
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copiedToClipboard'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('digitalAssistant'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChatHistory,
            tooltip: 'clearChat'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome Message
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'welcomeMessage'.tr(),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suggested Questions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'askOrChoose'.tr(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _prefilledQuestions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(question),
                          onPressed: () {
                            _controller.text = question;
                            _sendMessage();
                          },
                          backgroundColor: Colors.green[50],
                          labelStyle: TextStyle(color: Colors.green[800]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return GestureDetector(
                  onLongPress: () => _copyToClipboard(msg["content"]!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        child: Card(
                          elevation: 1,
                          color: isUser ? Colors.blue[50] : Colors.green[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUser ? 'You' : 'Assistant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isUser ? Colors.blue[800] : Colors.green[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                               MarkdownBody(
  data: msg["content"]!,
  styleSheet: MarkdownStyleSheet(
    p: TextStyle(
      color: isUser ? Colors.blue[900] : Colors.green[900],
      fontSize: 14, // Match your existing text size
    ),
    strong: TextStyle(
      color: isUser ? Colors.blue[900] : Colors.green[900],
      fontWeight: FontWeight.bold,
    ),
  ),
),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
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
                      hintText: 'askQuestionHint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}
