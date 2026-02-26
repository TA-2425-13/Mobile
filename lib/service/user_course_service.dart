import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_cache_service.dart';

import '../global_var.dart';
import '../model/user_course.dart';

class UserCourseService {

  static Future<UserCourse> getUserCourse(int idUser, int idCourse) async {
    try {
      late UserCourse status;
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/usercourse/$idUser/$idCourse'));
      final body = response.body;
      final result = jsonDecode(body);
      print(result);
      if (result is List && result.isNotEmpty) {
        status = UserCourse.fromJson(result[0]);
      }
      return status;
    } catch(e){
      throw Exception(e.toString());
    }
  }

  static Future<void> updateUserCourse(int id, UserCourse uc) async {
    try {
      Map<String, dynamic> request = {
        "userId": uc.userId,
        "courseId": uc.courseId,
        "progress": uc.progress,
        "currentChapter": uc.currentChapter,
        "isCompleted": uc.isCompleted,
        "enrolledAt": uc.enrolledAt.toIso8601String()
      };
      final responsePut = await http.put(Uri.parse('${GlobalVar.baseUrl}/usercourse/$id'), headers: {
        'Content-type' : 'application/json; charset=utf-8',
        'Accept': 'application/json',
      }, body: jsonEncode(request));

      if (responsePut.statusCode == 200) {
        print("Update Successful");
      }
    } catch(e){
      throw Exception(e.toString());
    }
  }
}