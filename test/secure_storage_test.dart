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
  });
}
