double? parseLocalizedDecimal(String? value) {
  if (value == null) return null;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final compact = trimmed.replaceAll(RegExp(r'\s+'), '');
  final commaIndex = compact.lastIndexOf(',');
  final dotIndex = compact.lastIndexOf('.');

  String normalized;
  if (commaIndex >= 0 && dotIndex >= 0) {
    if (commaIndex > dotIndex) {
      normalized = compact.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = compact.replaceAll(',', '');
    }
  } else if (commaIndex >= 0) {
    normalized = compact.replaceAll(',', '.');
  } else {
    normalized = compact;
  }

  return double.tryParse(normalized);
}
