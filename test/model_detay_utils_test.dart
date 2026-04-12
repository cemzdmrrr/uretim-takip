import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/pages/model/model_detay_utils.dart';

void main() {
  group('formatDate', () {
    test('formats ISO date string correctly', () {
      expect(formatDate('2025-03-08T10:30:00'), '08.03.2025');
    });

    test('returns null for null input', () {
      expect(formatDate(null), isNull);
    });

    test('returns string for unparseable input', () {
      expect(formatDate('invalid-date'), 'invalid-date');
    });
  });

  group('hesaplaSure', () {
    test('shows days and hours for multi-day duration', () {
      final start = DateTime(2025, 3, 1, 10, 0);
      final end = DateTime(2025, 3, 4, 14, 30);
      expect(hesaplaSure(start, end), '3 gün 4 saat');
    });

    test('shows hours and minutes for sub-day duration', () {
      final start = DateTime(2025, 3, 1, 10, 0);
      final end = DateTime(2025, 3, 1, 13, 45);
      expect(hesaplaSure(start, end), '3 saat 45 dakika');
    });

    test('shows minutes for short duration', () {
      final start = DateTime(2025, 3, 1, 10, 0);
      final end = DateTime(2025, 3, 1, 10, 25);
      expect(hesaplaSure(start, end), '25 dakika');
    });

    test('uses DateTime.now when bitis is null', () {
      final start = DateTime.now().subtract(const Duration(hours: 2));
      final result = hesaplaSure(start, null);
      expect(result, contains('saat'));
    });
  });

  group('getTabloAdi', () {
    test('maps dokuma to dokuma_atamalari', () {
      expect(getTabloAdi('dokuma'), 'dokuma_atamalari');
    });

    test('maps konfeksiyon to konfeksiyon_atamalari', () {
      expect(getTabloAdi('konfeksiyon'), 'konfeksiyon_atamalari');
    });

    test('is case-insensitive', () {
      expect(getTabloAdi('DOKUMA'), 'dokuma_atamalari');
      expect(getTabloAdi('Yikama'), 'yikama_atamalari');
    });

    test('returns null for unknown code', () {
      expect(getTabloAdi('bilinmeyen'), isNull);
    });

    test('maps all known stages', () {
      expect(getTabloAdi('utu'), 'utu_atamalari');
      expect(getTabloAdi('paketleme'), 'paketleme_atamalari');
      expect(getTabloAdi('ilik_dugme'), 'ilik_dugme_atamalari');
      expect(getTabloAdi('nakis'), 'nakis_atamalari');
      expect(getTabloAdi('kalite_kontrol'), 'kalite_kontrol_atamalari');
    });
  });

  group('getTableNameForStage', () {
    test('maps orgu to dokuma_atamalari', () {
      expect(getTableNameForStage('orgu'), 'dokuma_atamalari');
    });

    test('defaults to dokuma_atamalari for unknown', () {
      expect(getTableNameForStage('unknown'), 'dokuma_atamalari');
    });
  });

  group('getAsamaDisplayName', () {
    test('maps orgu to Dokuma/Örgü', () {
      expect(getAsamaDisplayName('orgu'), 'Dokuma/Örgü');
    });

    test('returns raw key for unknown', () {
      expect(getAsamaDisplayName('bilinmeyen'), 'bilinmeyen');
    });
  });

  group('getStatusColor', () {
    test('returns orange for atandi', () {
      expect(getStatusColor('atandi'), Colors.orange);
    });

    test('returns blue for uretimde', () {
      expect(getStatusColor('uretimde'), Colors.blue);
    });

    test('returns green for tamamlandi', () {
      expect(getStatusColor('tamamlandi'), Colors.green);
    });

    test('returns red for iptal', () {
      expect(getStatusColor('iptal'), Colors.red);
    });

    test('returns grey for null', () {
      expect(getStatusColor(null), Colors.grey);
    });

    test('is case-insensitive', () {
      expect(getStatusColor('TAMAMLANDI'), Colors.green);
    });
  });

  group('getStatusText', () {
    test('maps status codes to Turkish display text', () {
      expect(getStatusText('atandi'), 'Atandı');
      expect(getStatusText('baslatildi'), 'Başlatıldı');
      expect(getStatusText('uretimde'), 'Üretimde');
      expect(getStatusText('tamamlandi'), 'Tamamlandı');
      expect(getStatusText('iptal'), 'İptal');
    });

    test('returns Bilinmiyor for null', () {
      expect(getStatusText(null), 'Bilinmiyor');
    });

    test('returns raw value for unknown status', () {
      expect(getStatusText('ozel_durum'), 'ozel_durum');
    });
  });

  group('getDurumIkonu', () {
    test('returns check icon for Tamamlandı', () {
      expect(getDurumIkonu('Tamamlandı'), Icons.check_circle);
    });

    test('returns autorenew for İşleniyor', () {
      expect(getDurumIkonu('İşleniyor'), Icons.autorenew);
    });

    test('returns schedule for unknown', () {
      expect(getDurumIkonu('bilinmeyen'), Icons.schedule);
    });
  });

  group('getDosyaIcon', () {
    test('returns architecture for teknik_cizim', () {
      expect(getDosyaIcon('teknik_cizim'), Icons.architecture);
    });

    test('returns default icon for null', () {
      expect(getDosyaIcon(null), Icons.insert_drive_file);
    });
  });
}
