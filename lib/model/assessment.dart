
class Assessment {
  final int id;
  final int chapterId;
  final String instruction;
  final List<Question> questions;
  List<String>? answers;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assessment({
    required this.id,
    required this.chapterId,
    required this.instruction,
    required this.questions,
    required this.answers,
    required this.createdAt,
    required this.updatedAt
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'],
      chapterId: json['chapterId'],
      instruction: json['instruction'],
      questions: json['questions'],
      answers: json['answers'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Question {
  String question;
  List<String> option;
  String correctedAnswer;
  String type;
  String _selectedAnswer = '';
  int score = 0;
  List<String> _selectedMultiAnswer = [];
  bool isCorrect = false;

  Question({
    required this.question,
    required this.option,
    required this.correctedAnswer,
    required this.type
  });

  String get selectedAnswer => _selectedAnswer;
  List<String> get selectedMultAnswer => _selectedMultiAnswer;

  set selectedAnswer(String value) {
    _selectedAnswer = value;
  }
  set selectedMultiAnswer(List<String> list) {
    _selectedMultiAnswer = list;
  }
}