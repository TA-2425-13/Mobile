class LevelyRag {
  static String buildSnippet({
    required String material,
    int maxChars = 0,
  }) {
    final cleaned = _stripHtml(material);
    if (cleaned.isEmpty) return '';
    if (maxChars > 0 && cleaned.length > maxChars) {
      return _truncate(cleaned, maxChars);
    }
    return cleaned;
  }

  static String _stripHtml(String input) {
    var text = input;
    text = text.replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  static String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trim()}...';
  }
}
