/// Arabic text utilities for search and normalization
class ArabicUtils {
  ArabicUtils._();

  /// Normalize Arabic text for search by:
  /// - Removing diacritics (تشكيل)
  /// - Normalizing hamza variations (أ، إ، آ → ا)
  /// - Normalizing alef maqsura (ى → ي)
  /// - Normalizing taa marbouta (ة → ه)
  static String normalize(String text) {
    if (text.isEmpty) return text;

    String normalized = text;

    // Remove Arabic diacritics (تشكيل)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F]'), '');

    // Normalize Alef variations (أ، إ، آ، ٱ → ا)
    normalized = normalized
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا');

    // Normalize Alef Maqsura (ى → ي)
    normalized = normalized.replaceAll('ى', 'ي');

    // Normalize Taa Marbouta (ة → ه)
    normalized = normalized.replaceAll('ة', 'ه');

    return normalized;
  }

  /// Check if text contains Arabic characters
  static bool containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Search-friendly comparison
  /// Returns true if searchQuery is found in text (case-insensitive, normalized)
  static bool searchMatch(String text, String searchQuery) {
    if (text.isEmpty || searchQuery.isEmpty) return false;

    final normalizedText = normalize(text.toLowerCase());
    final normalizedQuery = normalize(searchQuery.toLowerCase());

    return normalizedText.contains(normalizedQuery);
  }

  /// Get all variations of a search query for better matching
  static List<String> getSearchVariations(String query) {
    if (query.isEmpty) return [query];

    final variations = <String>{
      query,
      normalize(query),
      query.toLowerCase(),
      normalize(query.toLowerCase()),
    };

    return variations.toList();
  }
}
