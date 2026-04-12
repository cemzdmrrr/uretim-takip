import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/utils/app_exceptions.dart';

void main() {
  group('AppException hierarchy', () {
    test('NetworkException stores message and code', () {
      const e = NetworkException('Bağlantı hatası', code: 'TIMEOUT');
      expect(e.message, 'Bağlantı hatası');
      expect(e.code, 'TIMEOUT');
      expect(e.originalError, isNull);
      expect(e.toString(), contains('TIMEOUT'));
      expect(e.toString(), contains('Bağlantı hatası'));
    });

    test('AuthException stores originalError', () {
      final original = Exception('token expired');
      final e = AuthException('Oturum süresi doldu', originalError: original);
      expect(e.message, 'Oturum süresi doldu');
      expect(e.originalError, original);
    });

    test('ValidationException without code', () {
      const e = ValidationException('E-posta gerekli');
      expect(e.code, isNull);
      expect(e.toString(), contains('null'));
    });

    test('BusinessException is AppException', () {
      const e = BusinessException('Stok yetersiz', code: 'STOCK_LOW');
      expect(e, isA<AppException>());
      expect(e, isA<BusinessException>());
    });

    test('sealed class allows exhaustive switch', () {
      const AppException e = NetworkException('test');
      final result = switch (e) {
        NetworkException() => 'network',
        AuthException() => 'auth',
        ValidationException() => 'validation',
        BusinessException() => 'business',
      };
      expect(result, 'network');
    });

    test('all subtypes implement Exception', () {
      expect(const NetworkException('a'), isA<Exception>());
      expect(const AuthException('b'), isA<Exception>());
      expect(const ValidationException('c'), isA<Exception>());
      expect(const BusinessException('d'), isA<Exception>());
    });
  });

  group('AppLogger', () {
    test('error does not throw', () {
      expect(
        () => AppLogger.error('Test error', Exception('detail'), StackTrace.current),
        returnsNormally,
      );
    });

    test('warning does not throw', () {
      expect(
        () => AppLogger.warning('Test warning', 'some detail'),
        returnsNormally,
      );
    });

    test('info does not throw', () {
      expect(() => AppLogger.info('Test info'), returnsNormally);
    });

    test('debug does not throw', () {
      expect(() => AppLogger.debug('Test debug'), returnsNormally);
    });
  });
}
