/// Selects text already supplied by the host; never translates or executes it.
///
/// English-only build: only the English variant is ever shown. A host text
/// with no English variant falls back to [fallback] when that reads as
/// English; Chinese text is never surfaced.
String? localizedHostText(Map<String, String?> text, {required String locale, String? fallback}) {
  final english = text['en']?.trim();
  if (english != null && english.isNotEmpty) return english;
  final value = fallback?.trim();
  if (value == null || value.isEmpty) return null;
  return RegExp(r'[\u3400-\u9fff]').hasMatch(value) ? null : value;
}
