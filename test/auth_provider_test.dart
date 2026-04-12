import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/providers/auth_provider.dart';

void main() {
  late AuthProvider auth;

  setUp(() {
    auth = AuthProvider();
  });

  group('AuthProvider - başlangıç durumu', () {
    test('user null', () {
      expect(auth.user, isNull);
    });

    test('isLoggedIn false', () {
      expect(auth.isLoggedIn, isFalse);
    });

    test('userId boş string', () {
      expect(auth.userId, '');
    });

    test('userEmail boş string', () {
      expect(auth.userEmail, '');
    });

    test('isAdmin false', () {
      expect(auth.isAdmin, isFalse);
    });

    test('role null', () {
      expect(auth.role, isNull);
    });

    test('firmaRol null', () {
      expect(auth.firmaRol, isNull);
    });

    test('yetkiler boş', () {
      expect(auth.yetkiler, isEmpty);
    });
  });

  group('AuthProvider - isAdmin', () {
    test('admin rolünde true', () {
      auth.testDurumAyarla(role: 'admin');
      expect(auth.isAdmin, isTrue);
    });

    test('user rolünde false', () {
      auth.testDurumAyarla(role: 'user');
      expect(auth.isAdmin, isFalse);
    });

    test('null rolde false', () {
      auth.testDurumAyarla(role: null);
      expect(auth.isAdmin, isFalse);
    });
  });

  group('AuthProvider - isFirmaAdmin', () {
    test('firma_sahibi true', () {
      auth.testDurumAyarla(firmaRol: 'firma_sahibi');
      expect(auth.isFirmaAdmin, isTrue);
    });

    test('firma_admin true', () {
      auth.testDurumAyarla(firmaRol: 'firma_admin');
      expect(auth.isFirmaAdmin, isTrue);
    });

    test('kullanici false', () {
      auth.testDurumAyarla(firmaRol: 'kullanici');
      expect(auth.isFirmaAdmin, isFalse);
    });

    test('null false', () {
      auth.testDurumAyarla(firmaRol: null);
      expect(auth.isFirmaAdmin, isFalse);
    });
  });

  group('AuthProvider - isFirmaSahibi', () {
    test('firma_sahibi true', () {
      auth.testDurumAyarla(firmaRol: 'firma_sahibi');
      expect(auth.isFirmaSahibi, isTrue);
    });

    test('firma_admin false (sadece sahibi değil)', () {
      auth.testDurumAyarla(firmaRol: 'firma_admin');
      expect(auth.isFirmaSahibi, isFalse);
    });
  });

  group('AuthProvider - hasRole', () {
    test('admin her zaman true', () {
      auth.testDurumAyarla(role: 'admin');
      expect(auth.hasRole(['user', 'editor']), isTrue);
    });

    test('rol listede varsa true', () {
      auth.testDurumAyarla(role: 'user');
      expect(auth.hasRole(['user', 'editor']), isTrue);
    });

    test('rol listede yoksa false', () {
      auth.testDurumAyarla(role: 'viewer');
      expect(auth.hasRole(['user', 'editor']), isFalse);
    });

    test('rol null false', () {
      auth.testDurumAyarla(role: null);
      expect(auth.hasRole(['user']), isFalse);
    });
  });

  group('AuthProvider - hasExactRole', () {
    test('eşleşen rol true', () {
      auth.testDurumAyarla(role: 'user');
      expect(auth.hasExactRole('user'), isTrue);
    });

    test('farklı rol false', () {
      auth.testDurumAyarla(role: 'admin');
      expect(auth.hasExactRole('user'), isFalse);
    });

    test('admin bile exactRole admin olmalı', () {
      auth.testDurumAyarla(role: 'admin');
      expect(auth.hasExactRole('admin'), isTrue);
    });
  });

  group('AuthProvider - yetkiVarMi', () {
    test('admin her zaman true', () {
      auth.testDurumAyarla(role: 'admin');
      expect(auth.yetkiVarMi('uretim', 'yazma'), isTrue);
    });

    test('firma_sahibi her zaman true', () {
      auth.testDurumAyarla(firmaRol: 'firma_sahibi');
      expect(auth.yetkiVarMi('finans', 'silme'), isTrue);
    });

    test('firma_admin her zaman true', () {
      auth.testDurumAyarla(firmaRol: 'firma_admin');
      expect(auth.yetkiVarMi('stok', 'yonetim'), isTrue);
    });

    test('spesifik yetki eşleşir', () {
      auth.testDurumAyarla(
        role: 'user',
        firmaRol: 'kullanici',
        yetkiler: ['uretim:okuma', 'uretim:yazma'],
      );
      expect(auth.yetkiVarMi('uretim', 'okuma'), isTrue);
      expect(auth.yetkiVarMi('uretim', 'yazma'), isTrue);
    });

    test('yetki yoksa false', () {
      auth.testDurumAyarla(
        role: 'user',
        firmaRol: 'kullanici',
        yetkiler: ['uretim:okuma'],
      );
      expect(auth.yetkiVarMi('uretim', 'silme'), isFalse);
      expect(auth.yetkiVarMi('finans', 'okuma'), isFalse);
    });
  });

  group('AuthProvider - modulErisimVarMi', () {
    test('admin erişim var', () {
      auth.testDurumAyarla(role: 'admin');
      expect(auth.modulErisimVarMi('uretim'), isTrue);
    });

    test('firma_admin erişim var', () {
      auth.testDurumAyarla(firmaRol: 'firma_admin');
      expect(auth.modulErisimVarMi('finans'), isTrue);
    });

    test('okuma yetkisi varsa erişim var', () {
      auth.testDurumAyarla(
        role: 'user',
        firmaRol: 'kullanici',
        yetkiler: ['uretim:okuma'],
      );
      expect(auth.modulErisimVarMi('uretim'), isTrue);
    });

    test('okuma yetkisi yoksa erişim yok', () {
      auth.testDurumAyarla(
        role: 'user',
        firmaRol: 'kullanici',
        yetkiler: ['uretim:yazma'],
      );
      expect(auth.modulErisimVarMi('uretim'), isFalse);
    });
  });

  group('AuthProvider - isLoading', () {
    test('varsayılan loading true (başlatılmamış)', () {
      // Yeni AuthProvider başlangıçta _loading = true
      expect(auth.isLoading, isTrue);
    });

    test('testDurumAyarla loading false yapar', () {
      auth.testDurumAyarla(loading: false);
      expect(auth.isLoading, isFalse);
    });
  });

  group('AuthProvider - ChangeNotifier', () {
    test('testDurumAyarla sonrası değerler güncellenir', () {
      auth.testDurumAyarla(
        role: 'admin',
        firmaRol: 'firma_sahibi',
        yetkiler: ['*'],
        loading: false,
      );

      expect(auth.isAdmin, isTrue);
      expect(auth.isFirmaAdmin, isTrue);
      expect(auth.isFirmaSahibi, isTrue);
      expect(auth.yetkiler, ['*']);
      expect(auth.isLoading, isFalse);
    });
  });
}
