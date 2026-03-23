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

  ChatSession copyWith({
    String? id,
    String? title,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }
}

class ChatSessionApi {
  static Future<List<ChatSession>> fetchSessions(int userId, {int? chapterId}) async {
    final params = <String, String>{
      't': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    if (chapterId != null && chapterId > 0) {
      params['chapterId'] = chapterId.toString();
    }
    final url = Uri.parse('${GlobalVar.baseUrl}/chat/session/user/$userId').replace(queryParameters: params);
    final response = await http.get(url);
    if (response.statusCode != 200) return [];
    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> data = body['sessions'] ?? [];
    return data.map((e) => ChatSession.fromJson(e)).toList();
  }

  static Future<ChatSession?> createSession(int userId, {int? chapterId}) async {
    final url = Uri.parse('${GlobalVar.baseUrl}/chat/session');
    final payload = <String, dynamic>{'userId': userId};
    if (chapterId != null && chapterId > 0) {
      payload['chapterId'] = chapterId;
    }
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
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
