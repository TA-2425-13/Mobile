import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:app/global_var.dart';
import 'package:app/utils/colors.dart';

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _controller.clear();
      _isSending = true;
    });

    _history.add({'role': 'user', 'content': text});

    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text, 'history': _history}),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghubungi server');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = (body['reply'] ?? '').toString().trim();
      setState(() {
        _messages.add(ChatMessage(content: reply.isEmpty ? 'Maaf, aku belum bisa menjawab.' : reply, isUser: false));
      });
      _history.add({'role': 'assistant', 'content': reply});
    } catch (error) {
      setState(() {
        _messages.add(ChatMessage(content: 'Terjadi kesalahan: ${error.toString()}', isUser: false));
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text('Levely Chat', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final alignment =
                          message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                      final bubbleColor = message.isUser
                          ? AppColors.primaryColor
                          : AppColors.accentColor.withOpacity(0.15);
                      final textColor = message.isUser ? Colors.white : Colors.black87;
                      return Column(
                        crossAxisAlignment: alignment,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: message.isUser
                                    ? const Radius.circular(16)
                                    : const Radius.circular(0),
                                bottomRight: message.isUser
                                    ? const Radius.circular(0)
                                    : const Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(color: textColor, fontFamily: 'DIN_Next_Rounded'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Tanya apa saja...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Kirim'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/pictures/background-pattern.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.black45),
            SizedBox(height: 16),
            Text('Mulai ngobrol dengan Levely!', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
