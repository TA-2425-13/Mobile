import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheService {
  static String cacheKeyFor(Uri url) => 'api_cache_${url.toString()}';

  static Future<void> clearCacheForUrl(Uri url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKeyFor(url));
  }

  static Future<void> clearCacheContaining(String needle) async {
    final prefs = await SharedPreferences.getInstance();
    final keysToDelete = prefs
        .getKeys()
        .where((key) => key.startsWith('api_cache_') && key.contains(needle))
        .toList();

    for (final key in keysToDelete) {
      await prefs.remove(key);
    }
  }

  static Future<http.Response> forceRefresh(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = cacheKeyFor(url);
    return _fetchAndCache(url, headers: headers, prefs: prefs, cacheKey: cacheKey);
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = cacheKeyFor(url);

    // 1. Try to load from cache
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      // 2. Return cached data immediately for fast UI
      // But silently fetch in the background to update the cache for next time
      _fetchAndCache(url, headers: headers, prefs: prefs, cacheKey: cacheKey)
          .catchError((_) => http.Response('error', 500));

      return http.Response(
        cachedData, 
        200, 
        headers: {'content-type': 'application/json; charset=utf-8'}
      );
    }

    // 3. First time fetching data (cache miss)
    return await _fetchAndCache(url, headers: headers, prefs: prefs, cacheKey: cacheKey);
  }

  static Future<http.Response> _fetchAndCache(
      Uri url, 
      {Map<String, String>? headers, 
      required SharedPreferences prefs, 
      required String cacheKey}
  ) async {
    final response = await http.get(url, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await prefs.setString(cacheKey, response.body);
    }
    return response;
  }

  static Future<http.Response> getSWR(
    Uri url, {
    Map<String, String>? headers,
    required void Function(http.Response freshResponse) onRevalidated,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = cacheKeyFor(url);
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      unawaited(
        _fetchAndCache(url, headers: headers, prefs: prefs, cacheKey: cacheKey)
            .then((freshResponse) {
          if (freshResponse.statusCode >= 200 && freshResponse.statusCode < 300) {
            onRevalidated(freshResponse);
          }
        }).catchError((_) {}),
      );

      return http.Response(
        cachedData,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    return _fetchAndCache(url, headers: headers, prefs: prefs, cacheKey: cacheKey);
  }
}
