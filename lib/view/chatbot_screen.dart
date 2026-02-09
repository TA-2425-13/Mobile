import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _sessionPrefsKey = 'levely_chat_session_id';

  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _history = [];
  final TextEditingController _controller = TextEditingController();

  bool _isSending = false;
  bool _isLoadingHistory = false;
  int? _userId;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSessionId = prefs.getString(_sessionPrefsKey);
    final storedUserId = prefs.getInt('userId');

    if (!mounted) {
      return;
    }

    setState(() {
      _userId = storedUserId;
      _sessionId = (storedSessionId != null && storedSessionId.isNotEmpty)
        ? storedSessionId
        : null;
    });

    if (storedSessionId != null && storedSessionId.isNotEmpty) {
      await _fetchHistory(storedSessionId);
    } else if (storedUserId != null) {
      await _fetchHistoryByUser(storedUserId);
    }
  }

  Future<void> _fetchHistory(String sessionId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await http
        .get(Uri.parse('${GlobalVar.baseUrl}/chat/history/$sessionId'));

      if (response.statusCode != 200) {
        if (response.statusCode == 400 || response.statusCode == 404) {
          await _clearPersistedSession();
        }
        _showSnack('Gagal memuat riwayat chat (${response.statusCode})');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await _applyHistoryResponse(body, fallbackSessionId: sessionId);
    } catch (error) {
      _showSnack('Gagal memuat riwayat chat');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _fetchHistoryByUser(int userId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await http
        .get(Uri.parse('${GlobalVar.baseUrl}/chat/history/user/$userId'));

      if (response.statusCode != 200) {
        _showSnack('Gagal memuat riwayat chat (${response.statusCode})');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await _applyHistoryResponse(body);
    } catch (error) {
      _showSnack('Gagal memuat riwayat chat');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _applyHistoryResponse(Map<String, dynamic> body,
    {String? fallbackSessionId}) async {
    final rawSession = body['sessionId'];
    final sessionCandidate = rawSession != null
      ? rawSession.toString().trim()
      : (fallbackSessionId ?? '').trim();
    final payload = body['messages'] as List<dynamic>? ?? [];
    final loadedMessages = _mapPayloadToMessages(payload);

    if (!mounted) {
      return;
    }

    setState(() {
      _messages
        ..clear()
        ..addAll(loadedMessages);
      _syncHistoryFromMessages(_messages);
    });

    await _persistSessionId(sessionCandidate);
  }

  Future<void> _persistSessionId(String? value) async {
    final next = value?.trim();
    if (next == null || next.isEmpty || next.toLowerCase() == 'null' || next == _sessionId) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionPrefsKey, next);

    if (!mounted) {
      return;
    }

    setState(() {
      _sessionId = next;
    });
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionPrefsKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _sessionId = null;
      _history.clear();
    });
  }

  void _addToHistory({required bool isUser, required String content}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _history.add({'role': isUser ? 'user' : 'assistant', 'content': trimmed});
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }
  }

  void _syncHistoryFromMessages(List<ChatMessage> messages) {
    _history
      ..clear()
      ..addAll(messages.map((message) => {
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.content,
        }));
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }
  }

  List<ChatMessage> _mapPayloadToMessages(List<dynamic> payload) {
    return payload
      .map((raw) {
        final map = (raw as Map<String, dynamic>? ?? {});
        final content = (map['content'] ?? '').toString().trim();
        if (content.isEmpty) {
          return null;
        }
        final role = (map['role'] ?? 'user').toString();
        return ChatMessage(content: content, isUser: role == 'user');
      })
      .whereType<ChatMessage>()
      .toList();
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _addToHistory(isUser: true, content: text);
      _controller.clear();
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'history': _history,
          'sessionId': _sessionId,
          'userId': _userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghubungi server');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = (body['reply'] ?? '').toString().trim();
      final normalizedReply =
        reply.isEmpty ? 'Maaf, aku belum bisa menjawab.' : reply;

      await _persistSessionId(body['sessionId']?.toString());

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(ChatMessage(content: normalizedReply, isUser: false));
        _addToHistory(isUser: false, content: normalizedReply);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(ChatMessage(
          content: 'Terjadi kesalahan: ${error.toString()}', isUser: false));
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
          if (_isLoadingHistory)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _messages.isEmpty
              ? (_isLoadingHistory ? _buildLoadingState() : _buildEmptyState())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final alignment = message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start;
                  final bubbleColor = message.isUser
                    ? AppColors.primaryColor
                    : AppColors.accentColor.withOpacity(0.15);
                  final textColor =
                    message.isUser ? Colors.white : Colors.black87;
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
                        child: message.isUser
                          ? Text(
                            message.content,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'DIN_Next_Rounded',
                              height: 1.4,
                            ),
                          )
                        : _FormattedMessage(
                          text: message.content,
                          color: textColor,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
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
            Text('Mulai ngobrol dengan Levely!',
              style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _FormattedMessage extends StatelessWidget {
  final String text;
  final Color color;

  const _FormattedMessage({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    final baseStyle =
        TextStyle(color: color, fontFamily: 'DIN_Next_Rounded', height: 1.4);

    if (blocks.isEmpty) {
      return Text(text, style: baseStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          _buildBlock(blocks[i], baseStyle),
          if (i < blocks.length - 1) const SizedBox(height: 6),
        ]
      ],
    );
  }

  static Widget _buildBlock(_TextBlock block, TextStyle baseStyle) {
    switch (block.type) {
      case _BlockType.heading:
        return Text.rich(
          TextSpan(
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
            children: _buildInlineSpans(
                block.text, baseStyle.copyWith(fontWeight: FontWeight.w700)),
          ),
        );
      case _BlockType.bullet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•', style: baseStyle),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                    style: baseStyle,
                    children: _buildInlineSpans(block.text, baseStyle)),
              ),
            ),
          ],
        );
      case _BlockType.numbered:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.prefix ?? '', style: baseStyle),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                    style: baseStyle,
                    children: _buildInlineSpans(block.text, baseStyle)),
              ),
            ),
          ],
        );
      case _BlockType.paragraph:
      default:
        return Text.rich(
          TextSpan(
              style: baseStyle,
              children: _buildInlineSpans(block.text, baseStyle)),
        );
    }
  }

  static List<_TextBlock> _parseBlocks(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final blocks = <_TextBlock>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isEmpty) {
        return;
      }
      final paragraph = buffer.toString().trim();
      if (paragraph.isNotEmpty) {
        blocks.add(_TextBlock(_BlockType.paragraph, paragraph));
      }
      buffer.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushBuffer();
        continue;
      }

      final bulletMatch = RegExp(r'^[-*+•]\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        flushBuffer();
        blocks.add(_TextBlock(_BlockType.bullet, bulletMatch.group(1)!.trim()));
        continue;
      }

      final numberMatch = RegExp(r'^(\d+)[\.)]\s+(.*)$').firstMatch(line);
      if (numberMatch != null) {
        flushBuffer();
        blocks.add(_TextBlock(
          _BlockType.numbered,
          numberMatch.group(2)!.trim(),
          prefix: '${numberMatch.group(1)}.',
        ));
        continue;
      }

      final hashHeading = RegExp(r'^#{1,6}\s+(.*)$').firstMatch(line);
      if (hashHeading != null) {
        flushBuffer();
        blocks
            .add(_TextBlock(_BlockType.heading, hashHeading.group(1)!.trim()));
        continue;
      }

      final strongHeading = RegExp(r'^\*\*(.+)\*\*$').firstMatch(line);
      if (strongHeading != null &&
          strongHeading.group(1)!.trim().length <= 120) {
        flushBuffer();
        blocks.add(
            _TextBlock(_BlockType.heading, strongHeading.group(1)!.trim()));
        continue;
      }

      final colonHeading = RegExp(r'^(.+):$').firstMatch(line);
      if (colonHeading != null && colonHeading.group(1)!.trim().length <= 120) {
        flushBuffer();
        blocks
            .add(_TextBlock(_BlockType.heading, colonHeading.group(1)!.trim()));
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(line);
    }

    flushBuffer();
    return blocks;
  }

  static List<TextSpan> _buildInlineSpans(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|__[^_]+__|\*[^*]+\*|_[^_]+_)');
    int currentIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      final token = match.group(0)!;
      final isBold = token.startsWith('**') || token.startsWith('__');
      final isItalic =
          !isBold && (token.startsWith('*') || token.startsWith('_'));
      final normalized = _stripFormatting(token);

      spans.add(
        TextSpan(
          text: normalized,
          style: baseStyle.copyWith(
            fontWeight: isBold ? FontWeight.w700 : baseStyle.fontWeight,
            fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
          ),
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  static String _stripFormatting(String token) {
    if (token.length >= 4 && token.startsWith('**') && token.endsWith('**')) {
      return token.substring(2, token.length - 2);
    }
    if (token.length >= 4 && token.startsWith('__') && token.endsWith('__')) {
      return token.substring(2, token.length - 2);
    }
    if (token.length >= 2 && token.startsWith('*') && token.endsWith('*')) {
      return token.substring(1, token.length - 1);
    }
    if (token.length >= 2 && token.startsWith('_') && token.endsWith('_')) {
      return token.substring(1, token.length - 1);
    }
    return token;
  }
}

enum _BlockType { heading, paragraph, bullet, numbered }

class _TextBlock {
  final _BlockType type;
  final String text;
  final String? prefix;

  const _TextBlock(this.type, this.text, {this.prefix});
}
