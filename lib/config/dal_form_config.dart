import 'package:uretim_takip/services/tenant_manager.dart';

/// Üretim dalına göre model form alanlarını yapılandırır.
/// Triko, konfeksiyon, dokuma kumaş vb. her dal için farklı alanlar gösterir.
class DalFormConfig {
  DalFormConfig._();

  /// Firmanın birincil üretim dalını döndürür
  static String get birincilDal {
    final dallar = TenantManager.instance.aktifUretimDallari;
    if (dallar.isEmpty) return 'triko';
    return dallar.first;
  }

  /// Dal kodundan okunabilir etiket
  static String dalEtiketi(String dalKodu) {
    return _dalEtiketleri[dalKodu] ?? dalKodu;
  }

  /// Verilen dal için model AppBar başlığı
  static String modelBaslik(String dalKodu) {
    return 'Yeni ${dalEtiketi(dalKodu)} Modeli';
  }

  /// Verilen dal için "Ürün Tipi" alan etiketi (triko_tipi yerine)
  static String urunTipiEtiketi(String dalKodu) {
    return _urunTipiEtiketleri[dalKodu] ?? 'Ürün Tipi';
  }

  /// Verilen dal için ürün tipi hint örnekleri
  static String urunTipiHint(String dalKodu) {
    return _urunTipiHintleri[dalKodu] ?? 'Ürün tipini giriniz';
  }

  /// Bu dal için iplik/materyal bölümü gösterilecek mi?
  static bool iplikBolumuGoster(String dalKodu) {
    return const ['triko', 'orme_kumas', 'iplik_uretim', 'dokuma_kumas']
        .contains(dalKodu);
  }

  /// Bu dal için teknik örgü bilgileri gösterilecek mi?
  static bool teknikOrguGoster(String dalKodu) {
    return const ['triko', 'orme_kumas'].contains(dalKodu);
  }

  /// Bu dal için kesim/dikim bilgileri gösterilecek mi?
  static bool kesimDikimGoster(String dalKodu) {
    return const ['konfeksiyon'].contains(dalKodu);
  }

  /// Bu dal için boya/terbiye bilgileri gösterilecek mi?
  static bool boyaTerbiyeGoster(String dalKodu) {
    return const ['boya_terbiye', 'baski_desen'].contains(dalKodu);
  }

  /// Bu dal için gramaj alanı gösterilecek mi?
  static bool gramajGoster(String dalKodu) {
    return const ['triko', 'orme_kumas', 'dokuma_kumas', 'konfeksiyon',
        'teknik_tekstil'].contains(dalKodu);
  }

  static const _dalEtiketleri = {
    'triko': 'Triko',
    'konfeksiyon': 'Konfeksiyon',
    'dokuma_kumas': 'Dokuma Kumaş',
    'orme_kumas': 'Örme Kumaş',
    'boya_terbiye': 'Boya & Terbiye',
    'baski_desen': 'Baskı & Desen',
    'iplik_uretim': 'İplik Üretim',
    'teknik_tekstil': 'Teknik Tekstil',
  };

  static const _urunTipiEtiketleri = {
    'triko': 'Triko Tipi',
    'konfeksiyon': 'Ürün Tipi',
    'dokuma_kumas': 'Dokuma Tipi',
    'orme_kumas': 'Örme Tipi',
    'boya_terbiye': 'İşlem Tipi',
    'baski_desen': 'Baskı Tipi',
    'iplik_uretim': 'İplik Tipi',
    'teknik_tekstil': 'Ürün Tipi',
  };

  static const _urunTipiHintleri = {
    'triko': 'örn: Düz örgü, Rib, Kablo, Jakarlı, Fair Isle',
    'konfeksiyon': 'örn: T-Shirt, Gömlek, Pantolon, Ceket, Elbise',
    'dokuma_kumas': 'örn: Bezayağı, Dimi, Saten, Jakar, Dobby',
    'orme_kumas': 'örn: Süprem, Ribana, İnterlok, Penye',
    'boya_terbiye': 'örn: Reaktif, Dispers, Pigment, İndigo',
    'baski_desen': 'örn: Dijital, Rotasyon, Şablon, Transfer',
    'iplik_uretim': 'örn: Ring, Open-end, Kompakt, Fantezi',
    'teknik_tekstil': 'örn: Nonwoven, Kompozit, Membran, Filtre',
  };
}
