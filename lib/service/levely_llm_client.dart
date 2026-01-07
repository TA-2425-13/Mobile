import 'dart:convert';

import 'package:http/http.dart' as http;

class LevelyLlmClient {
  Future<String> complete({
    required String system,
    required String context,
    required List<({String role, String content})> messages,
  }) async {
    throw UnimplementedError();
  }
}

class GeminiApiClient extends LevelyLlmClient {
  final String apiKey;
  final String model;
  final String baseUrl;

  GeminiApiClient({
    required this.apiKey,
    this.model = 'gemini-1.5-pro',
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models',
  });

  @override
  Future<String> complete({
    required String system,
    required String context,
    required List<({String role, String content})> messages,
  }) async {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$base/$model:generateContent?key=$apiKey');
    final instruction = _mergeInstruction(system: system, context: context);
    final contents = messages
        .map((m) => {
              'role': m.role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m.content},
              ],
            })
        .toList();

    final payload = <String, dynamic>{
      'contents': contents,
      'generationConfig': {'temperature': 0.3},
    };
    if (instruction.isNotEmpty) {
      payload['systemInstruction'] = {
        'parts': [
          {'text': instruction},
        ],
      };
    }

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('LLM error ${res.statusCode}: ${res.body}');
    }

    final json = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    final candidates = (json['candidates'] as List?)?.cast<dynamic>() ?? const [];
    if (candidates.isEmpty) return '';
    final content = (candidates.first as Map).cast<String, dynamic>()['content'] as Map?;
    final parts = (content?['parts'] as List?)?.cast<dynamic>() ?? const [];
    final text = parts
        .map((p) => (p as Map).cast<String, dynamic>()['text'] as String?)
        .where((t) => t != null && t.trim().isNotEmpty)
        .join('\n');
    return text.trim();
  }

  String _mergeInstruction({required String system, required String context}) {
    final sys = system.trim();
    final ctx = context.trim();
    if (sys.isEmpty && ctx.isEmpty) return '';
    if (sys.isEmpty) return ctx;
    if (ctx.isEmpty) return sys;
    return '$sys\n\n$ctx';
  }
}
