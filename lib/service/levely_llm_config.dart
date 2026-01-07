class LevelyLlmOverrides {
  final String? apiKey;
  final String? model;
  final String? baseUrl;

  const LevelyLlmOverrides({
    this.apiKey,
    this.model,
    this.baseUrl,
  });

  LevelyLlmOverrides normalized() {
    return LevelyLlmOverrides(
      apiKey: _clean(apiKey),
      model: _clean(model),
      baseUrl: _clean(baseUrl),
    );
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class LevelyLlmConfig {
  final String apiKey;
  final String model;
  final String baseUrl;

  const LevelyLlmConfig({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
  });

  bool get enabled => apiKey.trim().isNotEmpty;
}

class LevelyLlmConfigResolver {
  static const String defaultGeminiModel = 'gemini-3-flash';
  static const String defaultGeminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  static LevelyLlmConfig defaults() {
    return const LevelyLlmConfig(
      apiKey: '',
      model: defaultGeminiModel,
      baseUrl: defaultGeminiBaseUrl,
    );
  }

  static LevelyLlmConfig resolve({
    required bool allowOverrides,
    required LevelyLlmOverrides overrides,
  }) {
    if (!allowOverrides) {
      final apiKey = _firstNonEmpty([
        const String.fromEnvironment('LEVELY_GEMINI_API_KEY'),
      ]);
      return LevelyLlmConfig(
        apiKey: apiKey,
        model: defaultGeminiModel,
        baseUrl: defaultGeminiBaseUrl,
      );
    }

    final apiKey = _firstNonEmpty([
      overrides.apiKey,
      const String.fromEnvironment('LEVELY_GEMINI_API_KEY'),
    ]);
    final model = _firstNonEmpty([
      overrides.model,
      const String.fromEnvironment('LEVELY_GEMINI_MODEL'),
      defaultGeminiModel,
    ]);
    final baseUrl = _firstNonEmpty([
      overrides.baseUrl,
      const String.fromEnvironment('LEVELY_GEMINI_BASE_URL'),
      defaultGeminiBaseUrl,
    ]);
    return LevelyLlmConfig(
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final trimmed = v?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
