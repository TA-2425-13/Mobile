
import 'dart:convert';

class ChapterStatus {
  int id;
  int userId;
  int chapterId;
  bool isCompleted;
  bool isStarted;
  bool materialDone;
  bool assessmentDone;
  bool assignmentDone;
  List<String> assessmentAnswer;
  int assessmentGrade;
  int assessmentEloDelta;
  String? submission;
  DateTime timeStarted;
  DateTime timeFinished;
  int assignmentScore;
  String assignmentFeedback;
  DateTime createdAt;
  DateTime updatedAt;

  ChapterStatus({
    required this.id,
    required this.userId,
    required this.chapterId,
    required this.isCompleted,
    required this.isStarted,
    required this.materialDone,
    required this.assessmentDone,
    required this.assignmentDone,
    required this.assessmentAnswer,
    required this.assessmentGrade,
    required this.assessmentEloDelta,
    this.submission,
    required this.timeStarted,
    required this.timeFinished,
    required this.assignmentScore,
    required this.assignmentFeedback,
    required this.createdAt,
    required this.updatedAt
  });

  factory ChapterStatus.fromJson(Map<String, dynamic> json) {
    if (json['assessmentAnswer'].runtimeType == String) {
      final resultListAnswer = (jsonDecode(json['assessmentAnswer']) as List)
          .map((item) => item.toString()) // Convert each item to String
          .toList();
      return ChapterStatus(
        id: json['id'],
        userId: json['userId'],
        chapterId: json['chapterId'],
        isStarted: json['isStarted'],
        isCompleted: json['isCompleted'],
        materialDone: json['materialDone'],
        assessmentDone: json['assessmentDone'],
        assignmentDone: json['assignmentDone'],
        assessmentAnswer: resultListAnswer,
        assessmentGrade: json['assessmentGrade'],
        assessmentEloDelta: json['assessmentEloDelta'] ?? 0,
        submission: json['submission'],
        timeStarted: DateTime.parse(json['timeStarted']),
        timeFinished: DateTime.parse(json['timeFinished']),
        assignmentScore: json['assignmentScore'] ?? 0,
        assignmentFeedback: json['assignmentFeedback'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
    } else {
      return ChapterStatus(
        id: json['id'],
        userId: json['userId'],
        chapterId: json['chapterId'],
        isStarted: json['isStarted'],
        isCompleted: json['isCompleted'],
        materialDone: json['materialDone'],
        assessmentDone: json['assessmentDone'],
        assignmentDone: json['assignmentDone'],
        assessmentAnswer: json['assessmentAnswer'],
        assessmentGrade: json['assessmentGrade'],
        assessmentEloDelta: json['assessmentEloDelta'] ?? 0,
        submission: json['submission'],
        timeStarted: DateTime.parse(json['timeStarted']),
        timeFinished: DateTime.parse(json['timeFinished']),
        assignmentScore: json['assignmentScore'] ?? 0,
        assignmentFeedback: json['assignmentFeedback'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'chapterId': chapterId,
      'isCompleted': isCompleted,
      'isStarted': isStarted,
      'materialDone': materialDone,
      'assessmentDone': assessmentDone,
      'assignmentDone': assignmentDone,
      'assessmentAnswer': assessmentAnswer,
      'assessmentGrade': assessmentGrade,
      'assessmentEloDelta': assessmentEloDelta,
      'submission': submission,
      'timeStarted': timeStarted.toUtc().toIso8601String(),
      'timeFinished': timeFinished.toUtc().toIso8601String(),
      'assignmentScore': assignmentScore,
      'assignmentFeedback': assignmentFeedback,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}