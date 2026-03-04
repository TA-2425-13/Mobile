import 'dart:convert';
import 'package:app/global_var.dart';
import 'package:app/model/assignment.dart';
import 'package:http/http.dart' as http;
import 'api_cache_service.dart';
import '../model/assessment.dart';
import '../model/chapter.dart';
import '../model/learning_material.dart';

class ChapterService {

  static Future<LearningMaterial> getMaterialByChapterId(int id) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/chapter/$id/materials'));
      final body = response.body;
      final result = jsonDecode(body);
      LearningMaterial chapter = LearningMaterial(
                  id: result['id'],
                  chapterId: result['chapterId'],
                  name: result['name'],
                  content: result['content'],
                  createdAt: DateTime.parse(result['createdAt']),
                  updatedAt: DateTime.parse(result['updatedAt']),
          );
      return chapter;
    } catch(e){
      throw Exception(e.toString());
    }
  }

  static Future<Assessment> getAssessmentByChapterId(int id) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/chapter/$id/assessments'));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No assessments found");
      }

      final List<dynamic> decodeQuestion = result['questions'] == null 
          ? [] 
          : (result['questions'] is String 
              ? jsonDecode(result['questions']) 
              : result['questions']);
      List<Question> questions = decodeQuestion.map((q) => Question(
        id: q['id'],
        question: q['question'] ?? 'No question text',
        option: q['options'] != null ? List<String>.from(q['options']) : [],
        correctedAnswer: q['correctedAnswer'] ?? q['answer'] ?? '',
        type: q['type'] ?? 'PG',
        elo: q['elo'] ?? 1200,
      )).toList();

      // Decode answers safely (null-safe handling)
      final List<String>? decodedAnswers = result['answers'] != null
          ? List<String>.from(jsonDecode(result['answers']))
          : null;

      Assessment assessment = Assessment(
        id: result['id'],
        chapterId: result['chapterId'],
        instruction: result['instruction'],
        questions: questions,
        answers: decodedAnswers,
        createdAt: DateTime.parse(result['createdAt']),
        updatedAt: DateTime.parse(result['updatedAt']),
      );

      return assessment;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<Assignment> getAssignmentByChapterId(int id) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/chapter/$id/assignments'));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No assignment found");
      }

      Assignment assignment = Assignment.fromJson(result);

      return assignment;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<Chapter> getChapterById(int id) async{
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/chapter/$id'));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No Chapter found");
      }

      Chapter chapter = Chapter.fromJson(result);

      return chapter;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<double> checkSimiliarity (String reference, String answer) async {
    Map<String, dynamic> request = {
      'reference': reference,
      'essay': answer
    };
    try {
      final response = await http.post(Uri.parse(GlobalVar.similiarityEssayUrl), headers: {
        'Content-type' : 'application/json',
        'Accept': 'application/json',
      } , body: jsonEncode(request));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No Chapter found");
      }

      double similiarity = result['similarity_score'];

      return similiarity;
    } catch (e) {
      throw Exception("Error get Response Essay Similiarity: ${e.toString()}");
    }
  }
}