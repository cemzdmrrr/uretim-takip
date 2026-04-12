/// Test için sabit veriler ve fixture'lar.
class TestFixtures {
  TestFixtures._();

  // ── Firma ──
  static const firmaId1 = '11111111-1111-1111-1111-111111111111';
  static const firmaId2 = '22222222-2222-2222-2222-222222222222';
  static const userId1 = 'aaaa-bbbb-cccc-dddd';
  static const userId2 = 'eeee-ffff-gggg-hhhh';

  static Map<String, dynamic> firmaDetay({
    String? id,
    String firmaAdi = 'Test Firma',
    String firmaKodu = 'TST',
  }) =>
      {
        'id': id ?? firmaId1,
        'firma_adi': firmaAdi,
        'firma_kodu': firmaKodu,
        'aktif': true,
      };

  // ── Abonelik Planı ──
  static Map<String, dynamic> abonelikPlaniJson({
    String planKodu = 'profesyonel',
    String planAdi = 'Profesyonel',
    double aylikUcret = 499.0,
    double? yillikUcret = 4990.0,
    int? maxKullanici = 10,
    int? maxModul = 5,
    List<String> dahilModuller = const ['uretim', 'finans', 'stok'],
  }) =>
      {
        'id': 'plan-001',
        'plan_kodu': planKodu,
        'plan_adi': planAdi,
        'aciklama': '$planAdi plan açıklaması',
        'aylik_ucret': aylikUcret,
        'yillik_ucret': yillikUcret,
        'max_kullanici': maxKullanici,
        'max_modul': maxModul,
        'dahil_moduller': dahilModuller,
        'ozellikler': {'destek': 'email'},
        'aktif': true,
        'sira_no': 2,
      };

  static Map<String, dynamic> denemePlaniJson() => abonelikPlaniJson(
        planKodu: 'deneme',
        planAdi: 'Deneme',
        aylikUcret: 0,
        yillikUcret: null,
        maxKullanici: 5,
        maxModul: null,
        dahilModuller: ['uretim','finans','ik','stok','sevkiyat','tedarik','musteri','rapor','kalite','ayarlar'],
      );

  static Map<String, dynamic> enterprisePlaniJson() => abonelikPlaniJson(
        planKodu: 'enterprise',
        planAdi: 'Enterprise',
        aylikUcret: 1999,
        yillikUcret: 19990,
        maxKullanici: null,
        maxModul: null,
        dahilModuller: [],
      );

  // ── Firma Abonelik ──
  static Map<String, dynamic> firmaAbonelikJson({
    String durum = 'aktif',
    String? denemeBitis,
    Map<String, dynamic>? plan,
  }) =>
      {
        'id': 'abone-001',
        'firma_id': firmaId1,
        'plan_id': 'plan-001',
        'durum': durum,
        'baslangic_tarihi': '2025-01-01T00:00:00',
        'bitis_tarihi': null,
        'deneme_bitis': denemeBitis,
        'odeme_periyodu': 'aylik',
        'son_odeme_tarihi': '2025-06-01T00:00:00',
        'sonraki_odeme_tarihi': '2025-07-01T00:00:00',
        'iptal_tarihi': null,
        'abonelik_planlari': plan ?? abonelikPlaniJson(),
      };

  // ── Abonelik Ödeme ──
  static Map<String, dynamic> abonelikOdemeJson() => {
        'id': 'odeme-001',
        'firma_id': firmaId1,
        'abonelik_id': 'abone-001',
        'tutar': 499.0,
        'para_birimi': 'TRY',
        'odeme_tarihi': '2025-06-01T00:00:00',
        'odeme_yontemi': 'kredi_karti',
        'odeme_referans': 'REF-12345',
        'durum': 'basarili',
        'fatura_no': 'FTR-001',
      };

  // ── TenantManager Durumları ──
  static Map<String, dynamic> aktifAbonelikData({String durum = 'aktif'}) => {
        'durum': durum,
        'deneme_bitis':
            DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      };

  static Map<String, dynamic> suresiDolmusAbonelik() => {
        'durum': 'deneme',
        'deneme_bitis':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      };
}
