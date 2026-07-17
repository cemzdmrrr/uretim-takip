import 'package:intl/intl.dart';

String normalizeCurrencyCode(String? value) {
  final code = value?.trim().toUpperCase() ?? '';
  if (code.isEmpty) return 'TRY';
  if (const {'TL', 'TRL', 'YTL'}.contains(code)) return 'TRY';
  return code;
}

String formatCurrencyAmount(num value, String? currencyCode) {
  final code = normalizeCurrencyCode(currencyCode);
  final amount = NumberFormat('#,##0.00', 'tr_TR').format(value);
  return '$amount $code';
}

List<MapEntry<String, double>> sortedCurrencyTotals(
  Map<String, double> totals,
) {
  final normalized = <String, double>{};
  for (final entry in totals.entries) {
    final code = normalizeCurrencyCode(entry.key);
    normalized[code] = (normalized[code] ?? 0) + entry.value;
  }
  final entries = normalized.entries.toList();
  entries.sort((left, right) {
    if (left.key == 'TRY' && right.key != 'TRY') return -1;
    if (right.key == 'TRY' && left.key != 'TRY') return 1;
    return left.key.compareTo(right.key);
  });
  return entries;
}
