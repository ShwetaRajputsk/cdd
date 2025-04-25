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
import 'bottom_navigation_bar.dart';

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
  int _currentIndex = 1;
  final Color primaryColor = const Color(0xFF1C4B0C);

  List<String> _prefilledQuestions = [
    'bestCropsSummer'.tr(),
    'protectCropsDiseases'.tr(),
    'idealIrrigationSystem'.tr(),
    'sustainableFarmingPractices'.tr(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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
          _messages.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
      if (mounted) setState(() => _messages.clear());
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

  Future<void> _sendMessage(String userInput) async {
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

    DocumentReference? docRef;
    try {
      docRef = await FirebaseFirestore.instance
          .collection('chat_history')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('messages')
          .add({
        'user_query': userInput,
        'bot_response': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

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
              "content": "You are an agricultural assistant. Provide detailed, professional answers.",
            },
            ..._messages.map((msg) => {"role": msg["role"], "content": msg["content"]})
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

        setState(() => _messages.add({
          'role': 'assistant',
          'content': botResponse,
          'timestamp': DateTime.now(),
        }));

        await docRef.update({
          'bot_response': botResponse,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        throw HttpException("API Error", response.statusCode);
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
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Assistant Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(18),
              height: 100,
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
                          'I\'m your CropFit Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Here to help you with all your agricultural needs. '
                          'Ask me about crop care, disease solutions, or farming best practices.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
          alignment: Alignment.bottomRight,
          child: Image.asset(
            'assets/images/assistant_icon.png',
            height: 180,
            fit: BoxFit.contain,
          ),
        ),
                ],
              ),
            ),
          ),

          // Existing content below
          if (_messages.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'suggestedQuestions'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _prefilledQuestions.map((question) => InkWell(
                      onTap: () => _sendMessage(question),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          question,
                          style: TextStyle(color: primaryColor, fontSize: 14),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: message['role'] == 'user' 
                        ? Alignment.centerRight 
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user' 
                            ? primaryColor 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1)),
                        ],
                      ),
                      child: MarkdownBody(
                        data: message['content'],
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: message['role'] == 'user' 
                                ? Colors.white 
                                : Colors.black87,
                            fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -1)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'typeMessage'.tr(),
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12),
                      ),
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, this.statusCode);

  @override
  String toString() => message;
}
