import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uretim_takip/config/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureCredentialStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isRememberMeEnabled returns false by default', () async {
      final result = await SecureCredentialStorage.isRememberMeEnabled;
      expect(result, isFalse);
    });

    test('isRememberMeEnabled reads rememberMe key', () async {
      SharedPreferences.setMockInitialValues({'rememberMe': true});
      final result = await SecureCredentialStorage.isRememberMeEnabled;
      expect(result, isTrue);
    });

    test('save stores email but not password', () async {
      await SecureCredentialStorage.save(email: 'demo@test.com');

      final prefs = await SharedPreferences.getInstance();
      expect(await SecureCredentialStorage.savedEmail, 'demo@test.com');
      expect(await SecureCredentialStorage.isRememberMeEnabled, isTrue);
      expect(prefs.containsKey('secure_password'), isFalse);
      expect(prefs.containsKey('password'), isFalse);
    });

    test('clear removes stored auth preferences', () async {
      await SecureCredentialStorage.save(email: 'demo@test.com');
      await SecureCredentialStorage.clear();

      expect(await SecureCredentialStorage.savedEmail, isNull);
      expect(await SecureCredentialStorage.isRememberMeEnabled, isFalse);
    });

    test('migrateLegacyStorage moves email and removes legacy passwords',
        () async {
      SharedPreferences.setMockInitialValues({
        'rememberMe': true,
        'email': 'legacy@test.com',
        'password': 'plain-password',
        'secure_password': 'encoded-password',
      });

      await SecureCredentialStorage.migrateLegacyStorage();

      final prefs = await SharedPreferences.getInstance();
      expect(await SecureCredentialStorage.savedEmail, 'legacy@test.com');
      expect(prefs.containsKey('password'), isFalse);
      expect(prefs.containsKey('secure_password'), isFalse);
      expect(prefs.containsKey('email'), isFalse);
    });
  });
}
