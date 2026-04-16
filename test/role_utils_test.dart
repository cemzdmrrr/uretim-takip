import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/utils/role_utils.dart';

void main() {
  group('RoleUtils', () {
    test('user aliases normalize to kullanici', () {
      expect(RoleUtils.normalizeUserRole('user'), 'kullanici');
      expect(RoleUtils.normalizeUserRole('kullanici'), 'kullanici');
      expect(RoleUtils.sameUserRole('user', 'kullanici'), isTrue);
    });

    test('dashboard aliases normalize to shared dashboards', () {
      expect(RoleUtils.normalizeDashboardRole('dokumaci'), 'dokuma');
      expect(RoleUtils.normalizeDashboardRole('depocu'), 'depo');
      expect(RoleUtils.normalizeDashboardRole('paketleme'), 'utu_paket');
    });

    test('admin and standard user helpers work with aliases', () {
      expect(RoleUtils.isAdmin('admin'), isTrue);
      expect(RoleUtils.isStandardUser('user'), isTrue);
      expect(RoleUtils.isStandardUser('kullanici'), isTrue);
    });
  });
}
