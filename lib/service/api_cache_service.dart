import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheService {
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'api_cache_${url.toString()}';

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
}
