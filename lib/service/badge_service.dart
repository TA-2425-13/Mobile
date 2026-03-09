import 'dart:convert';

import 'package:app/model/badge.dart';
import 'package:app/model/user_badge.dart';
import 'package:http/http.dart' as http;
import 'api_cache_service.dart';

import '../global_var.dart';

class BadgeService {

  static bool _isLegacyBadgeName(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'beginner designer' ||
        normalized == 'intermediate designer' ||
        normalized == 'advance designer' ||
        normalized == 'advanced designer';
  }

  static bool _hasLegacyBadgeNames(List<UserBadge> badges) {
    return badges.any((item) => _isLegacyBadgeName(item.badge.name));
  }

  static Future<List<UserBadge>> _refreshBadgesFromNetwork(
    Uri uri, {
    void Function(List<UserBadge> freshData)? onRevalidated,
  }) async {
    await ApiCacheService.clearCacheForUrl(uri);
    final freshResponse = await ApiCacheService.forceRefresh(uri);
    final freshResult = jsonDecode(freshResponse.body);
    final freshList = _parseUserBadgeList(freshResult);
    if (onRevalidated != null) {
      onRevalidated(freshList);
    }
    return freshList;
  }

  static List<UserBadge> _parseUserBadgeList(dynamic result) {
    if (result is! List) {
      return [];
    }
    return List<UserBadge>.from(result.map((q) => UserBadge.fromJson(q)));
  }

  static Future<List<BadgeModel>> getBadgeListCourseByCourseId(
    int courseId, {
    void Function(List<BadgeModel> freshData)? onRevalidated,
  }) async {
    try {
      final uri = Uri.parse('${GlobalVar.baseUrl}/course/$courseId/badges');
      final response = await ApiCacheService.getSWR(
        uri,
        onRevalidated: (freshResponse) {
          if (onRevalidated == null) {
            return;
          }
          final freshResult = jsonDecode(freshResponse.body);
          final freshList = List<BadgeModel>.from(
            freshResult.map((q) => BadgeModel.fromJson(q)),
          );
          onRevalidated(freshList);
        },
      );
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

  static Future<List<UserBadge>> getUserBadgeListByUserId(
    int userId, {
    void Function(List<UserBadge> freshData)? onRevalidated,
  }) async {
    try {
      final uri = Uri.parse('${GlobalVar.baseUrl}/user/$userId/badges');
      final response = await ApiCacheService.getSWR(
        uri,
        onRevalidated: (freshResponse) {
          if (onRevalidated == null) {
            return;
          }
          final freshResult = jsonDecode(freshResponse.body);
          final freshList = _parseUserBadgeList(freshResult);
          onRevalidated(freshList);
        },
      );
      final result = jsonDecode(response.body);
      final list = _parseUserBadgeList(result);

      if (_hasLegacyBadgeNames(list)) {
        return _refreshBadgesFromNetwork(uri, onRevalidated: onRevalidated);
      }

      if (list.isEmpty) {
        throw Exception("No assignment found");
      }

      return list;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<List<UserBadge>> getUserBadgeListWithStatusByUserId(
    int userId, {
    void Function(List<UserBadge> freshData)? onRevalidated,
  }) async {
    try {
      final uri = Uri.parse('${GlobalVar.baseUrl}/user/$userId/badges');
      final response = await ApiCacheService.getSWR(
        uri,
        onRevalidated: (freshResponse) {
          if (onRevalidated == null) {
            return;
          }
          final freshResult = jsonDecode(freshResponse.body);
          final freshList = _parseUserBadgeList(freshResult);
          onRevalidated(freshList);
        },
      );
      final result = jsonDecode(response.body);
      final list = _parseUserBadgeList(result);

      if (_hasLegacyBadgeNames(list)) {
        return _refreshBadgesFromNetwork(uri, onRevalidated: onRevalidated);
      }

      if (list.isEmpty) {
        throw Exception("No assignment found");
      }

      return list;
    } catch (e) {
      throw Exception("Error fetching assessment: ${e.toString()}");
    }
  }

  static Future<BadgeModel> getBadgeById(
    int badgeId, {
    void Function(BadgeModel freshData)? onRevalidated,
  }) async {
    try {
      final uri = Uri.parse('${GlobalVar.baseUrl}/badge/$badgeId');
      final response = await ApiCacheService.getSWR(
        uri,
        onRevalidated: (freshResponse) {
          if (onRevalidated == null) {
            return;
          }
          final freshResult = jsonDecode(freshResponse.body);
          onRevalidated(BadgeModel.fromJson(freshResult));
        },
      );
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