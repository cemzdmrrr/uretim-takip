import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/utils/currency_utils.dart';

void main() {
  group('normalizeCurrencyCode', () {
    test('bos ve Turk lirasi kodlarini TRY yapar', () {
      expect(normalizeCurrencyCode(null), 'TRY');
      expect(normalizeCurrencyCode(' tl '), 'TRY');
      expect(normalizeCurrencyCode('TRL'), 'TRY');
      expect(normalizeCurrencyCode('ytl'), 'TRY');
    });

    test('diger para birimlerini buyuk harfe cevirir', () {
      expect(normalizeCurrencyCode(' usd '), 'USD');
      expect(normalizeCurrencyCode('eur'), 'EUR');
      expect(normalizeCurrencyCode('aed'), 'AED');
    });
  });

  test('tutari Turkce sayi bicimi ve ISO koduyla gosterir', () {
    expect(formatCurrencyAmount(1234.5, 'usd'), '1.234,50 USD');
  });

  test('toplamlarda TRY once gelir ve es anlamli kodlar birlesir', () {
    final result = sortedCurrencyTotals({
      'USD': 25,
      'TL': 10,
      'TRY': 15,
      'EUR': 20,
    });

    expect(result.map((entry) => entry.key), ['TRY', 'EUR', 'USD']);
    expect(result.first.value, 25);
  });
}
