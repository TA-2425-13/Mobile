import 'dart:convert';

import 'package:app/model/badge.dart';
import 'package:app/model/user_badge.dart';
import 'package:http/http.dart' as http;
import 'api_cache_service.dart';

import '../global_var.dart';

class BadgeService {

  static Future<List<BadgeModel>> getBadgeListCourseByCourseId(int courseId) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/course/$courseId/badges'));
      final body = response.body;
      final result = jsonDecode(body);
      List<BadgeModel> list = List<BadgeModel>.from(
          result.map((q) => BadgeModel.fromJson(q))
      );
      return list;
    } catch(e){
      throw Exception(e.toString());
    }
  }

  static Future<void> createUserBadgeByChapterId(int userId, int badgeId) async {
    try {
      Map<String, dynamic> request = {
        "userId": userId,
        "badgeId": badgeId,
        "isPurchased": false
      };
      final response = await http.post(Uri.parse('${GlobalVar.baseUrl}/userbadge'), headers: {
        'Content-type' : 'application/json; charset=utf-8',
        'Accept': 'application/json',
      } , body: jsonEncode(request));

      final body = response.body;
      final result = jsonDecode(body);
      print(result['message']);
    } catch(e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<UserBadge>> getUserBadgeListByUserId(int userId) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/user/$userId/badges'));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No assignment found");
      }

      List<UserBadge> list = List<UserBadge>.from(
          result.map((q) => UserBadge.fromJson(q))
      );

      return list;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<List<UserBadge>> getUserBadgeListWithStatusByUserId(int userId) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/user/$userId/badges'));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No assignment found");
      }

      return result;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<BadgeModel> getBadgeById(int badgeId) async {
    try {
      final response = await ApiCacheService.get(Uri.parse('${GlobalVar.baseUrl}/badge/$badgeId'));
      final result = jsonDecode(response.body);

      if (result.isEmpty) {
        throw Exception("No assignment found");
      }

      BadgeModel badge = BadgeModel.fromJson(result);

      return badge;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }


}