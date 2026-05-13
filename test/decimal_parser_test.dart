import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/utils/decimal_parser.dart';

void main() {
  group('parseLocalizedDecimal', () {
    test('parses comma decimal values', () {
      expect(parseLocalizedDecimal('12,50'), 12.5);
    });

    test('parses dot decimal values', () {
      expect(parseLocalizedDecimal('12.50'), 12.5);
    });

    test('parses Turkish thousands and decimal separators', () {
      expect(parseLocalizedDecimal('1.234,56'), 1234.56);
    });

    test('parses English thousands and decimal separators', () {
      expect(parseLocalizedDecimal('1,234.56'), 1234.56);
    });

    test('returns null for invalid input', () {
      expect(parseLocalizedDecimal('abc'), isNull);
    });
  });
}
