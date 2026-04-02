import 'package:flutter/material.dart';
import 'package:app/utils/colors.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Example questions
  final List<String> _questions = [
    "Bagaimana pengalaman belajar Anda sejauh ini?",
    "Apakah materi yang diberikan mudah dipahami?",
    "Apakah Anda merasa terbantu dengan chatbot?",
    "Apa saran Anda untuk pengembangan aplikasi ini?"
  ];

  final Map<int, String> _answers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaire', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/pictures/background-pattern.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView.builder(
              itemCount: _questions.length + 1,
              itemBuilder: (context, index) {
                if (index == _questions.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          // Handle submission logic here
                          _showSuccessDialog();
                        }
                      },
                      child: const Text(
                        'Submit Questionnaire',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'DIN_Next_Rounded',
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _questions[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DIN_Next_Rounded',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Ketik jawaban Anda di sini...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onSaved: (value) {
                            _answers[index] = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mohon isi jawaban Anda';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Terima Kasih!', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
        content: const Text(
          'Jawaban Anda telah kami terima. Terima kasih telah memberikan feedback!',
          style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate back to main screen or where appropriate
              Navigator.of(context).pop(); // Pop dialog
              Navigator.of(context).pop(); // Pop questionnaire screen
            },
            child: const Text('Tutup', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
          ),
        ],
      ),
    );
  }
}
