import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Üretim aşaması tanımı — DB'den veya statik fallback'ten yüklenir
class AsamaTanim {
  final String tekstilDali;
  final String asamaKodu;
  final String asamaAdi;
  final int siraNo;
  final bool zorunlu;
  final IconData ikon;
  final Color renk;
  final String? eskiTabloAdi; // geriye uyumluluk: eski atama tablosu
  final String? eskiDurumKolonu; // geriye uyumluluk: triko_takip durum kolonu

  const AsamaTanim({
    required this.tekstilDali,
    required this.asamaKodu,
    required this.asamaAdi,
    required this.siraNo,
    this.zorunlu = false,
    this.ikon = Icons.settings,
    this.renk = const Color(0xFF455A64),
    this.eskiTabloAdi,
    this.eskiDurumKolonu,
  });

  factory AsamaTanim.fromJson(Map<String, dynamic> json) {
    return AsamaTanim(
      tekstilDali: json['tekstil_dali'] as String,
      asamaKodu: json['asama_kodu'] as String,
      asamaAdi: json['asama_adi'] as String,
      siraNo: json['sira_no'] as int? ?? 0,
      zorunlu: json['zorunlu'] as bool? ?? false,
      ikon: _ikonCozumle(json['ikon'] as String?),
      renk: _renkCozumle(json['renk'] as String?),
      eskiTabloAdi: json['eski_tablo_adi'] as String?,
      eskiDurumKolonu: json['eski_durum_kolonu'] as String?,
    );
  }

  /// Bu aşama için atama tablosu adını döndürür.
  /// Eski tablo varsa geriye uyumluluk için onu kullanır,
  /// yoksa genel uretim_atamalari tablosunu döndürür.
  String get atamaTablosu => eskiTabloAdi ?? 'uretim_atamalari';

  /// Dashboard'da bu aşamayı göstermek için kullanılır
  bool get dashboardGoster => asamaKodu != 'sevkiyat'; // sevkiyat ayrı modül

  static IconData _ikonCozumle(String? ikonAdi) {
    if (ikonAdi == null) return Icons.settings;
    return _ikonMap[ikonAdi] ?? Icons.settings;
  }

  static Color _renkCozumle(String? hexRenk) {
    if (hexRenk == null || hexRenk.length != 6) return const Color(0xFF455A64);
    return Color(int.parse('FF$hexRenk', radix: 16));
  }

  /// Material icon adı → IconData eşlemesi
  static const Map<String, IconData> _ikonMap = {
    'design_services': Icons.design_services,
    'local_laundry_service': Icons.local_laundry_service,
    'brush': Icons.brush,
    'radio_button_checked': Icons.radio_button_checked,
    'checkroom': Icons.checkroom,
    'iron': Icons.iron,
    'inventory_2': Icons.inventory_2,
    'verified': Icons.verified,
    'local_shipping': Icons.local_shipping,
    'palette': Icons.palette,
    'straighten': Icons.straighten,
    'content_cut': Icons.content_cut,
    'style': Icons.style,
    'linear_scale': Icons.linear_scale,
    'water_drop': Icons.water_drop,
    'science': Icons.science,
    'warehouse': Icons.warehouse,
    'color_lens': Icons.color_lens,
    'inventory': Icons.inventory,
    'print': Icons.print,
    'air': Icons.air,
    'thermostat': Icons.thermostat,
    'blender': Icons.blender,
    'replay': Icons.replay,
    'circle': Icons.circle,
    'category': Icons.category,
    'precision_manufacturing': Icons.precision_manufacturing,
    'layers': Icons.layers,
  };
}

/// Üretim aşamaları merkezi kayıt defteri.
/// DB'den yükler, bellekte cache'ler, eski switch/case mantığını ortadan kaldırır.
class AsamaRegistry {
  static final Map<String, List<AsamaTanim>> _cache = {};
  static bool _yuklendiMi = false;

  /// Tüm dalların aşamalarını DB'den yükler
  static Future<void> yukle() async {
    if (_yuklendiMi) return;

    try {
      final response = await Supabase.instance.client
          .from('asama_tanimlari')
          .select()
          .eq('aktif', true)
          .order('sira_no');

      _cache.clear();
      for (final row in (response as List)) {
        final tanim = AsamaTanim.fromJson(row as Map<String, dynamic>);
        _cache.putIfAbsent(tanim.tekstilDali, () => []).add(tanim);
      }
      _yuklendiMi = true;
    } catch (e) {
      debugPrint('AsamaRegistry yükleme hatası: $e, fallback kullanılacak');
      _fallbackYukle();
    }
  }

  /// Belirtilen tekstil dalının aşamalarını döndürür
  static List<AsamaTanim> asamalariGetir(String tekstilDali) {
    return _cache[tekstilDali] ?? _fallbackAsamalar(tekstilDali);
  }

  /// Belirli bir aşamayı kod ile bulur
  static AsamaTanim? asamaBul(String tekstilDali, String asamaKodu) {
    return asamalariGetir(tekstilDali)
        .where((a) => a.asamaKodu == asamaKodu)
        .firstOrNull;
  }

  /// Aşama kodundan atama tablosu adını döndürür (geriye uyumluluk)
  static String atamaTablosuGetir(String tekstilDali, String asamaKodu) {
    final asama = asamaBul(tekstilDali, asamaKodu);
    return asama?.atamaTablosu ?? 'uretim_atamalari';
  }

  /// Aşama kodundan model durum kolonu adını döndürür (geriye uyumluluk)
  static String? durumKolonuGetir(String tekstilDali, String asamaKodu) {
    final asama = asamaBul(tekstilDali, asamaKodu);
    return asama?.eskiDurumKolonu;
  }

  /// Dashboard'da gösterilecek aşamaları filtreler
  static List<AsamaTanim> dashboardAsamalari(String tekstilDali) {
    return asamalariGetir(tekstilDali)
        .where((a) => a.dashboardGoster)
        .toList();
  }

  /// Tüm yüklü dalları döndürür
  static List<String> get yukluDallar => _cache.keys.toList();

  /// Cache'i temizle
  static void cacheTemizle() {
    _cache.clear();
    _yuklendiMi = false;
  }

  /// DB erişimi olmadığında statik fallback (tüm dallar için)
  static void _fallbackYukle() {
    for (final dal in _tumFallbacklar.keys) {
      _cache[dal] = _tumFallbacklar[dal]!;
    }
    _yuklendiMi = true;
  }

  static List<AsamaTanim> _fallbackAsamalar(String dal) {
    return _tumFallbacklar[dal] ?? [];
  }

  static const Map<String, List<AsamaTanim>> _tumFallbacklar = {
    'triko': [
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'dokuma', asamaAdi: 'Dokuma/Örme', siraNo: 1, zorunlu: true, ikon: Icons.design_services, renk: Color(0xFF1976D2), eskiTabloAdi: 'dokuma_atamalari', eskiDurumKolonu: 'orgu_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'yikama', asamaAdi: 'Yıkama', siraNo: 2, ikon: Icons.local_laundry_service, renk: Color(0xFF00838F), eskiTabloAdi: 'yikama_atamalari', eskiDurumKolonu: 'yikama_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'nakis', asamaAdi: 'Nakış', siraNo: 3, ikon: Icons.brush, renk: Color(0xFFFF6F00), eskiTabloAdi: 'nakis_atamalari', eskiDurumKolonu: 'nakis_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'ilik_dugme', asamaAdi: 'İlik Düğme', siraNo: 4, ikon: Icons.radio_button_checked, renk: Color(0xFF7B1FA2), eskiTabloAdi: 'ilik_dugme_atamalari', eskiDurumKolonu: 'ilik_dugme_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'konfeksiyon', asamaAdi: 'Konfeksiyon', siraNo: 5, zorunlu: true, ikon: Icons.checkroom, renk: Color(0xFFE65100), eskiTabloAdi: 'konfeksiyon_atamalari', eskiDurumKolonu: 'konfeksiyon_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'utu', asamaAdi: 'Ütü', siraNo: 6, zorunlu: true, ikon: Icons.iron, renk: Color(0xFFAD1457), eskiTabloAdi: 'utu_atamalari', eskiDurumKolonu: 'utu_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'paketleme', asamaAdi: 'Paketleme', siraNo: 7, zorunlu: true, ikon: Icons.inventory_2, renk: Color(0xFF4E342E), eskiTabloAdi: 'paketleme_atamalari', eskiDurumKolonu: 'paketleme_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'kalite_kontrol', asamaAdi: 'Kalite Kontrol', siraNo: 8, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32), eskiTabloAdi: 'kalite_kontrol_atamalari', eskiDurumKolonu: 'kalite_durumu'),
      AsamaTanim(tekstilDali: 'triko', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 9, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'konfeksiyon': [
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'tasarim', asamaAdi: 'Tasarım', siraNo: 1, ikon: Icons.design_services, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'kalip', asamaAdi: 'Kalıp', siraNo: 2, ikon: Icons.straighten, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'kesim', asamaAdi: 'Kesim', siraNo: 3, zorunlu: true, ikon: Icons.content_cut, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'dikim', asamaAdi: 'Dikim', siraNo: 4, zorunlu: true, ikon: Icons.checkroom, renk: Color(0xFFE65100)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'utu_pres', asamaAdi: 'Ütü/Pres', siraNo: 5, zorunlu: true, ikon: Icons.iron, renk: Color(0xFFAD1457)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'aksesuar', asamaAdi: 'Aksesuar', siraNo: 6, ikon: Icons.style, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 7, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'paketleme', asamaAdi: 'Paketleme', siraNo: 8, zorunlu: true, ikon: Icons.inventory_2, renk: Color(0xFF4E342E)),
      AsamaTanim(tekstilDali: 'konfeksiyon', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 9, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'dokuma_kumas': [
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'cozgu', asamaAdi: 'Çözgü Hazırlama', siraNo: 1, zorunlu: true, ikon: Icons.linear_scale, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'dokuma', asamaAdi: 'Dokuma', siraNo: 2, zorunlu: true, ikon: Icons.design_services, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'hasil', asamaAdi: 'Haşıl', siraNo: 3, ikon: Icons.water_drop, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'terbiye', asamaAdi: 'Terbiye', siraNo: 4, ikon: Icons.science, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 5, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'depolama', asamaAdi: 'Depolama', siraNo: 6, ikon: Icons.warehouse, renk: Color(0xFF4E342E)),
      AsamaTanim(tekstilDali: 'dokuma_kumas', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 7, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'orme_kumas': [
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'iplik_hazirlama', asamaAdi: 'İplik Hazırlama', siraNo: 1, ikon: Icons.category, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'orme', asamaAdi: 'Örme', siraNo: 2, zorunlu: true, ikon: Icons.design_services, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'boyama', asamaAdi: 'Boyama', siraNo: 3, ikon: Icons.color_lens, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'terbiye', asamaAdi: 'Terbiye', siraNo: 4, ikon: Icons.science, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 5, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'depolama', asamaAdi: 'Depolama', siraNo: 6, ikon: Icons.warehouse, renk: Color(0xFF4E342E)),
      AsamaTanim(tekstilDali: 'orme_kumas', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 7, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'boya_terbiye': [
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'malzeme_kabul', asamaAdi: 'Malzeme Kabul', siraNo: 1, zorunlu: true, ikon: Icons.inventory, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'on_terbiye', asamaAdi: 'Ön Terbiye', siraNo: 2, ikon: Icons.science, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'boyama', asamaAdi: 'Boyama', siraNo: 3, zorunlu: true, ikon: Icons.color_lens, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'baski', asamaAdi: 'Baskı', siraNo: 4, ikon: Icons.print, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'son_terbiye', asamaAdi: 'Son Terbiye', siraNo: 5, ikon: Icons.air, renk: Color(0xFFAD1457)),
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 6, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'boya_terbiye', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 7, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'baski_desen': [
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'tasarim', asamaAdi: 'Tasarım', siraNo: 1, ikon: Icons.design_services, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'kalip_sablon', asamaAdi: 'Kalıp/Şablon', siraNo: 2, ikon: Icons.straighten, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'baski', asamaAdi: 'Baskı', siraNo: 3, zorunlu: true, ikon: Icons.print, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'kurutma', asamaAdi: 'Kurutma', siraNo: 4, ikon: Icons.thermostat, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'fiksaj', asamaAdi: 'Fiksaj', siraNo: 5, ikon: Icons.air, renk: Color(0xFFAD1457)),
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 6, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'baski_desen', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 7, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'iplik_uretim': [
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'hammadde_kabul', asamaAdi: 'Hammadde Kabul', siraNo: 1, zorunlu: true, ikon: Icons.inventory, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'harman', asamaAdi: 'Harman', siraNo: 2, ikon: Icons.blender, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'tarak', asamaAdi: 'Tarak', siraNo: 3, ikon: Icons.layers, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'fitil', asamaAdi: 'Fitil', siraNo: 4, ikon: Icons.linear_scale, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'bukum', asamaAdi: 'Büküm', siraNo: 5, zorunlu: true, ikon: Icons.replay, renk: Color(0xFFAD1457)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'bobin', asamaAdi: 'Bobin', siraNo: 6, zorunlu: true, ikon: Icons.circle, renk: Color(0xFF4E342E)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 7, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'iplik_uretim', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 8, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
    'teknik_tekstil': [
      AsamaTanim(tekstilDali: 'teknik_tekstil', asamaKodu: 'malzeme_secim', asamaAdi: 'Malzeme Seçim', siraNo: 1, ikon: Icons.category, renk: Color(0xFF1976D2)),
      AsamaTanim(tekstilDali: 'teknik_tekstil', asamaKodu: 'uretim', asamaAdi: 'Üretim', siraNo: 2, zorunlu: true, ikon: Icons.precision_manufacturing, renk: Color(0xFF00838F)),
      AsamaTanim(tekstilDali: 'teknik_tekstil', asamaKodu: 'kaplama', asamaAdi: 'Kaplama/Laminasyon', siraNo: 3, ikon: Icons.layers, renk: Color(0xFFFF6F00)),
      AsamaTanim(tekstilDali: 'teknik_tekstil', asamaKodu: 'test', asamaAdi: 'Test', siraNo: 4, ikon: Icons.science, renk: Color(0xFF7B1FA2)),
      AsamaTanim(tekstilDali: 'teknik_tekstil', asamaKodu: 'kalite', asamaAdi: 'Kalite', siraNo: 5, zorunlu: true, ikon: Icons.verified, renk: Color(0xFF2E7D32)),
      AsamaTanim(tekstilDali: 'teknik_tekstil', asamaKodu: 'sevkiyat', asamaAdi: 'Sevkiyat', siraNo: 6, zorunlu: true, ikon: Icons.local_shipping, renk: Color(0xFF1565C0)),
    ],
  };
}
