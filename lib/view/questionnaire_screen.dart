import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../global_var.dart';
import 'login_screen.dart';

/// Layar kuesioner pasca-penggunaan (8 item, 1-5 Likert).
/// Ditampilkan sekali setelah sesi evaluasi berakhir (dipanggil dari logout).
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  static const _submittedKey = 'questionnaire_submitted';

  // Jawaban tiap item (null = belum dipilih)
  final List<int?> _answers = List.filled(8, null);
  bool _isSubmitting = false;

  static const List<Map<String, String>> _questions = [
    // SDT — Motivasi (Leroux et al., 2024)
    {
      'dimension': 'Motivasi — Otonomi',
      'text':
          'Saya merasa memiliki kendali atas cara saya belajar di LeveLearn (misalnya memilih topik, mengatur kecepatan belajar).',
    },
    {
      'dimension': 'Motivasi — Kompetensi',
      'text':
          'Tingkat kesulitan soal dan materi terasa sesuai dengan kemampuan saya saat ini.',
    },
    {
      'dimension': 'Motivasi — Kompetensi',
      'text': 'Saya merasa kemampuan belajar saya berkembang setelah menggunakan LeveLearn.',
    },
    {
      'dimension': 'Motivasi — Keterkaitan',
      'text':
          'Berinteraksi dengan chatbot Levely membuat saya lebih terhubung dan termotivasi dalam mempelajari materi.',
    },
    // Engagement (Albakri et al., 2024)
    {
      'dimension': 'Keterlibatan — Behavioral',
      'text': 'Saya aktif menyelesaikan materi, soal, dan tugas yang tersedia di LeveLearn.',
    },
    {
      'dimension': 'Keterlibatan — Kognitif',
      'text':
          'Saya berpikir lebih mendalam tentang materi yang dipelajari saat menggunakan LeveLearn.',
    },
    {
      'dimension': 'Keterlibatan — Emosional',
      'text': 'Saya menikmati pengalaman belajar di LeveLearn.',
    },
    // Global
    {
      'dimension': 'Penilaian Global',
      'text':
          'Secara keseluruhan, chatbot AI dan sistem gamifikasi adaptif (poin, lencana, tingkat kesulitan) membantu saya belajar lebih baik.',
    },
  ];

  static const List<String> _labels = [
    '1\nSangat\nTidak Setuju',
    '2\nTidak\nSetuju',
    '3\nNetral',
    '4\nSetuju',
    '5\nSangat\nSetuju',
  ];

  bool get _allAnswered => _answers.every((a) => a != null);

  Future<void> _submit() async {
    if (!_allAnswered || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('${GlobalVar.baseUrl}/evaluation/questionnaire'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'q1': _answers[0],
          'q2': _answers[1],
          'q3': _answers[2],
          'q4': _answers[3],
          'q5': _answers[4],
          'q6': _answers[5],
          'q7': _answers[6],
          'q8': _answers[7],
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 409) {
        // 409 = already submitted — still mark as done and proceed
        await prefs.setBool(_submittedKey, true);
        _navigateToLogin();
      } else {
        _showError('Gagal mengirim kuesioner (${response.statusCode}). Coba lagi.');
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server. Periksa koneksi internet.');
      setState(() => _isSubmitting = false);
    }
  }

  void _skip() async {
    // Allow skipping — data log sudah cukup untuk analisis
    _navigateToLogin();
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: GlobalVar.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Kuesioner Evaluasi', style: TextStyle(fontSize: 18)),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Lewati', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: GlobalVar.accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: const Text(
              'Bantu kami memahami pengalamanmu!\n'
              'Pilih angka 1–5 untuk setiap pernyataan berikut.',
              style: TextStyle(fontSize: 13, color: Color(0xFF3D1A6E)),
            ),
          ),
          // Questions
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final q = _questions[index];
                return _QuestionItem(
                  number: index + 1,
                  dimension: q['dimension']!,
                  text: q['text']!,
                  value: _answers[index],
                  labels: _labels,
                  onChanged: (val) => setState(() => _answers[index] = val),
                );
              },
            ),
          ),
          // Submit button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allAnswered
                        ? GlobalVar.primaryColor
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _allAnswered && !_isSubmitting ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _allAnswered
                              ? 'Kirim Kuesioner'
                              : 'Jawab semua pertanyaan dulu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _allAnswered ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionItem extends StatelessWidget {
  final int number;
  final String dimension;
  final String text;
  final int? value;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _QuestionItem({
    required this.number,
    required this.dimension,
    required this.text,
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dimension chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: GlobalVar.accentColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            dimension,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF3D1A6E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Question text
        Text(
          '$number. $text',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 10),
        // Likert scale
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final val = i + 1;
            final selected = value == val;
            return GestureDetector(
              onTap: () => onChanged(val),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? GlobalVar.primaryColor
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: selected
                            ? GlobalVar.primaryColor
                            : Colors.grey.shade400,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$val',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 52,
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected
                            ? GlobalVar.primaryColor
                            : Colors.grey.shade500,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
