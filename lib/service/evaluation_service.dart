import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../global_var.dart';

/// Utility untuk log-tracking sesi evaluasi ke backend LeveLearn.
class EvaluationService {
  /// Akhiri sesi (dipanggil saat logout). Mengirim POST /evaluation/session/end.
  static Future<void> endSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('sessionId');
      final token = prefs.getString('token') ?? '';
      if (sessionId == null) return;

      await http.post(
        Uri.parse('${GlobalVar.baseUrl}/evaluation/session/end'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'sessionId': sessionId}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Non-critical — tidak boleh memblokir logout
    }
  }

  /// Kirim heartbeat (dipanggil setiap 60 detik selama pengguna aktif).
  static Future<void> heartbeat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('sessionId');
      final token = prefs.getString('token') ?? '';
      if (sessionId == null) return;

      await http.post(
        Uri.parse('${GlobalVar.baseUrl}/evaluation/session/heartbeat'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'sessionId': sessionId}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Non-critical
    }
  }
}
