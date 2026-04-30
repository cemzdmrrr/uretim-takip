import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/model_karlilik_servisi.dart';

void main() {
  group('ModelKarlilikServisi', () {
    test('planlanan maliyet ve hedef fiyat hesaplar', () {
      final ozet = const ModelKarlilikServisi().hesapla(
        model: {
          'toplam_adet': 100,
          'iplik_maliyeti': 40,
          'orgu_fiyat': 20,
          'dikim_fiyat': 10,
          'kar_marji': 25,
        },
        uretimKayitlari: const [],
        modelAksesuarlari: const [],
      );

      expect(ozet.planBirimMaliyet, 70);
      expect(ozet.gercekBirimMaliyet, 70);
      expect(ozet.onerilenFiyat, 87.5);
      expect(ozet.brutKarMarji, closeTo(20, 0.001));
    });

    test('fire gerçek birim maliyeti yukarı taşır', () {
      final ozet = const ModelKarlilikServisi().hesapla(
        model: {
          'toplam_adet': 100,
          'iplik_maliyeti': 50,
          'orgu_fiyat': 50,
          'pesin_fiyat': 130,
          'kar_marji': 30,
        },
        uretimKayitlari: const [
          {
            'asama': 'utu',
            'tamamlanan_adet': 90,
            'fire_adet': 10,
          }
        ],
        modelAksesuarlari: const [],
      );

      expect(ozet.planBirimMaliyet, 100);
      expect(ozet.tamamlananAdet, 90);
      expect(ozet.fireAdedi, 10);
      expect(ozet.gercekBirimMaliyet, closeTo(111.111, 0.001));
      expect(ozet.brutKarMarji, closeTo(14.529, 0.001));
      expect(ozet.hedefAltinda, isTrue);
    });

    test('tamamlanan adet en ileri üretim aşamasından alınır', () {
      final ozet = const ModelKarlilikServisi().hesapla(
        model: {
          'toplam_adet': 1000,
          'iplik_maliyeti': 40,
          'orgu_fiyat': 20,
          'pesin_fiyat': 90,
          'kar_marji': 25,
        },
        uretimKayitlari: const [
          {
            'asama': 'orgu',
            'tamamlanan_adet': 1000,
          },
          {
            'asama': 'utu',
            'tamamlanan_adet': 600,
          },
        ],
        modelAksesuarlari: const [],
      );

      expect(ozet.tamamlananAdet, 600);
      expect(ozet.tamamlananAsama, 'utu');
      expect(ozet.tamamlananAdetKaynak, 'En ileri üretim aşaması');
      expect(ozet.satisGeliri, 54000);
    });
  });
}
