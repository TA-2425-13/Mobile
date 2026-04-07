import 'package:flutter/material.dart';
import 'package:app/utils/colors.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Questions based on LLM-as-a-judge / Human Scoring concepts
  final List<String> _likertQuestions = [
    "Seberapa relevan respon chatbot dengan instruksi/pertanyaan Anda? (Relevance)",
    "Seberapa akurat informasi yang diberikan oleh chatbot? (Accuracy)",
    "Seberapa jelas dan mudah dipahami gaya bahasa chatbot? (Clarity)",
    "Seberapa terbantunya Anda oleh chatbot dalam memahami materi? (Helpfulness)",
  ];

  final Map<int, int> _likertAnswers = {};
  String _essayFeedback = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaire Evaluasi', style: TextStyle(fontFamily: 'DIN_Next_Rounded')),
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
              itemCount: _likertQuestions.length + 2, // Likert + Essay + Submit
              itemBuilder: (context, index) {
                // Submit Button
                if (index == _likertQuestions.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Validate that all Likert scales are answered
                          if (_likertAnswers.length < _likertQuestions.length) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Mohon isi semua pertanyaan pilihan 1-5.', style: TextStyle(fontFamily: 'DIN_Next_Rounded'))),
                             );
                             return;
                          }
                          _formKey.currentState!.save();
                          // Handle submission logic here
                          _showSuccessDialog();
                        }
                      },
                      child: const Text(
                        'Submit Evaluasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'DIN_Next_Rounded',
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  );
                }

                // Essay Question (Optional Feedback)
                if (index == _likertQuestions.length) {
                   return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kritik & Saran Tambahan (Opsional)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DIN_Next_Rounded',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Tuliskan kesan atau saran Anda terkait performa chatbot...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onSaved: (value) {
                              _essayFeedback = value ?? '';
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Likert Questions
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _likertQuestions[index],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DIN_Next_Rounded',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("1\nSangat\nKurang", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'DIN_Next_Rounded')),
                            ...List.generate(5, (optionIndex) {
                              int value = optionIndex + 1;
                              bool isSelected = _likertAnswers[index] == value;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _likertAnswers[index] = value;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryColor : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    border: isSelected 
                                      ? Border.all(color: AppColors.secondaryColor, width: 2) 
                                      : Border.all(color: Colors.grey.shade300, width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    value.toString(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'DIN_Next_Rounded'
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const Text("5\nSangat\nBaik", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'DIN_Next_Rounded')),
                          ],
                        ),
                        if (_likertAnswers[index] == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'Wajib diisi',
                                  style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontFamily: 'DIN_Next_Rounded'),
                                ),
                              ],
                            ),
                          )
                        else 
                          const SizedBox(height: 26) // Keep spacing consistent when answered
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
          'Evaluasi Anda telah kami terima. Terima kasih telah membantu penilaian performa chatbot!',
          style: TextStyle(fontFamily: 'DIN_Next_Rounded'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Pop dialog
              Navigator.of(context).pop(); // Pop questionnaire screen
            },
            child: const Text('Tutup', style: TextStyle(fontFamily: 'DIN_Next_Rounded', color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
