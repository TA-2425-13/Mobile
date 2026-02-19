import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/global_var.dart';

class ChatSession {
  final String id;
  final String? title;

  ChatSession({required this.id, this.title});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
    );
  }
}

class ChatSessionApi {
  static Future<List<ChatSession>> fetchSessions(int userId) async {
    final url = Uri.parse('${GlobalVar.baseUrl}/chat/session/user/$userId?t=${DateTime.now().millisecondsSinceEpoch}');
    final response = await http.get(url);
    if (response.statusCode != 200) return [];
    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> data = body['sessions'] ?? [];
    return data.map((e) => ChatSession.fromJson(e)).toList();
  }

  static Future<ChatSession?> createSession(int userId) async {
    final url = Uri.parse('${GlobalVar.baseUrl}/chat/session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    final Map<String, dynamic> data = jsonDecode(response.body);
    final session = data['session'];
    if (session == null) return null;
    return ChatSession.fromJson(session);
  }

  static Future<bool> renameSession(String sessionId, String newTitle) async {
    final url = Uri.parse('${GlobalVar.baseUrl}/chat/session/$sessionId');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': newTitle}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteSession(String sessionId) async {
    final url = Uri.parse('${GlobalVar.baseUrl}/chat/session/$sessionId');
    final response = await http.delete(url);
    return response.statusCode == 200;
  }
}
