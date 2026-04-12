import 'package:flutter/material.dart';

/// Platform modül kategorileri
enum ModuleCategory {
  uretim('Üretim'),
  finans('Finans'),
  ik('İnsan Kaynakları'),
  stok('Stok & Depo'),
  sevkiyat('Sevkiyat'),
  tedarik('Tedarik'),
  crm('Müşteri'),
  rapor('Raporlar'),
  sistem('Sistem');

  final String ad;
  const ModuleCategory(this.ad);
}

/// Platform tarafından tanımlanan tüm modüller
enum AppModule {
  uretim('uretim', 'Üretim Yönetimi', Icons.factory, ModuleCategory.uretim),
  finans('finans', 'Finans & Muhasebe', Icons.account_balance, ModuleCategory.finans),
  ik('ik', 'İnsan Kaynakları', Icons.people, ModuleCategory.ik),
  stok('stok', 'Stok & Depo', Icons.inventory, ModuleCategory.stok),
  sevkiyat('sevkiyat', 'Sevkiyat & Lojistik', Icons.local_shipping, ModuleCategory.sevkiyat),
  tedarik('tedarik', 'Tedarikçi Yönetimi', Icons.handshake, ModuleCategory.tedarik),
  musteri('musteri', 'Müşteri Yönetimi', Icons.storefront, ModuleCategory.crm),
  rapor('rapor', 'Raporlar & Analiz', Icons.analytics, ModuleCategory.rapor),
  kalite('kalite', 'Kalite Kontrol', Icons.verified, ModuleCategory.uretim),
  ayarlar('ayarlar', 'Sistem Ayarları', Icons.settings, ModuleCategory.sistem);

  final String kod;
  final String ad;
  final IconData ikon;
  final ModuleCategory kategori;
  const AppModule(this.kod, this.ad, this.ikon, this.kategori);

  static AppModule? fromKod(String kod) {
    try {
      return values.firstWhere((m) => m.kod == kod);
    } catch (_) {
      return null;
    }
  }
}

/// Tekstil üretim dalları
enum TekstilDali {
  triko('triko', 'Triko Üretim', [
    'Tasarım', 'Dokuma/Örme', 'Yıkama', 'Nakış', 'İlik Düğme',
    'Konfeksiyon', 'Ütü', 'Paketleme', 'Kalite', 'Sevkiyat',
  ]),
  dokumaKumas('dokuma_kumas', 'Dokuma Kumaş', [
    'Çözgü Hazırlama', 'Dokuma', 'Haşıl', 'Terbiye', 'Kalite', 'Depolama', 'Sevkiyat',
  ]),
  konfeksiyon('konfeksiyon', 'Konfeksiyon', [
    'Tasarım', 'Kalıp', 'Kesim', 'Dikim', 'Ütü/Pres',
    'Aksesuar', 'Kalite', 'Paketleme', 'Sevkiyat',
  ]),
  ormeKumas('orme_kumas', 'Örme Kumaş', [
    'İplik Hazırlama', 'Örme', 'Boyama', 'Terbiye', 'Kalite', 'Depolama', 'Sevkiyat',
  ]),
  boyaTerbiye('boya_terbiye', 'Boya & Terbiye', [
    'Malzeme Kabul', 'Ön Terbiye', 'Boyama', 'Baskı', 'Son Terbiye', 'Kalite', 'Sevkiyat',
  ]),
  baskiDesen('baski_desen', 'Baskı & Desen', [
    'Tasarım', 'Kalıp/Şablon', 'Baskı', 'Kurutma', 'Fiksaj', 'Kalite', 'Sevkiyat',
  ]),
  iplikUretim('iplik_uretim', 'İplik Üretim', [
    'Hammadde Kabul', 'Harman', 'Tarak', 'Fitil', 'Büküm', 'Bobin', 'Kalite', 'Sevkiyat',
  ]),
  teknikTekstil('teknik_tekstil', 'Teknik Tekstil', [
    'Malzeme Seçim', 'Üretim', 'Kaplama/Laminasyon', 'Test', 'Kalite', 'Sevkiyat',
  ]);

  final String kod;
  final String ad;
  final List<String> uretimAsamalari;
  const TekstilDali(this.kod, this.ad, this.uretimAsamalari);

  static TekstilDali? fromKod(String kod) {
    try {
      return values.firstWhere((d) => d.kod == kod);
    } catch (_) {
      return null;
    }
  }
}
