import 'assessment.dart';

class AssessmentAttempt {
  final int attemptId;
  final int chapterId;
  final String instruction;
  final List<Question> questions;
  final bool resumed;
  final String source;
  final String? status;
  final DateTime? submittedAt;

  AssessmentAttempt({
    required this.attemptId,
    required this.chapterId,
    required this.instruction,
    required this.questions,
    required this.resumed,
    required this.source,
    this.status,
    this.submittedAt,
  });

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] is List ? json['questions'] as List : const [];
    final questions = rawQuestions
        .whereType<Map<String, dynamic>>()
        .map(_questionFromJson)
        .toList();

    final submittedAtRaw = json['submittedAt'];

    return AssessmentAttempt(
      attemptId: json['attemptId'],
      chapterId: json['chapterId'],
      instruction: (json['instruction'] ?? '').toString(),
      questions: questions,
      resumed: json['resumed'] == true,
      source: (json['source'] ?? 'GENERATED').toString(),
      status: json['status']?.toString(),
      submittedAt: submittedAtRaw is String && submittedAtRaw.isNotEmpty
          ? DateTime.tryParse(submittedAtRaw)
          : null,
    );
  }

  Assessment toAssessment() {
    return Assessment(
      id: attemptId,
      chapterId: chapterId,
      instruction: instruction,
      questions: questions,
      answers: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Question _questionFromJson(Map<String, dynamic> map) {
    final optionsRaw = map['options'];
    final options = optionsRaw is List
        ? optionsRaw.map((item) => item.toString()).toList()
        : <String>[];
    final question = Question(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      question: (map['question'] ?? '').toString(),
      option: options,
      correctedAnswer: (map['correctedAnswer'] ?? map['answer'] ?? '').toString(),
      type: (map['type'] ?? 'MC').toString(),
      elo: map['elo'] is int ? map['elo'] as int : int.tryParse('${map['elo']}') ?? 1200,
    );

    final submittedAnswer = (map['submittedAnswer'] ?? '').toString();
    if (submittedAnswer.isNotEmpty) {
      question.selectedAnswer = submittedAnswer;
    }

    question.isCorrect = map['isCorrect'] == true;
    question.score = map['score'] is int
        ? map['score'] as int
        : int.tryParse('${map['score']}') ?? 0;
    return question;
  }
}
