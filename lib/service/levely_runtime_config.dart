import 'package:app/service/levely_llm_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelyRuntimeConfig {
  static const String _kApiKey = 'levely_llm_api_key';
  static const String _kModel = 'levely_llm_model';
  static const String _kBaseUrl = 'levely_llm_base_url';

  static LevelyLlmOverrides _overrides = const LevelyLlmOverrides();
  static int _revision = 0;

  static LevelyLlmOverrides get overrides => _overrides;
  static int get revision => _revision;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _overrides = LevelyLlmOverrides(
      apiKey: _clean(prefs.getString(_kApiKey)),
      model: _clean(prefs.getString(_kModel)),
      baseUrl: _clean(prefs.getString(_kBaseUrl)),
    );
  }

  static Future<void> save(LevelyLlmOverrides overrides) async {
    final normalized = overrides.normalized();
    final prefs = await SharedPreferences.getInstance();
    await _setOrRemove(prefs, _kApiKey, normalized.apiKey);
    await _setOrRemove(prefs, _kModel, normalized.model);
    await _setOrRemove(prefs, _kBaseUrl, normalized.baseUrl);
    _overrides = normalized;
    _revision++;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiKey);
    await prefs.remove(_kModel);
    await prefs.remove(_kBaseUrl);
    _overrides = const LevelyLlmOverrides();
    _revision++;
  }

  static Future<void> _setOrRemove(SharedPreferences prefs, String key, String? value) async {
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
