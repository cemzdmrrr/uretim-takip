import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/iplik_model_tahsis_service.dart';

void main() {
  group('IplikModelTahsisService.toplamTahsis', () {
    test('sayisal tahsisleri toplar', () {
      final sonuc = IplikModelTahsisService.toplamTahsis([
        {'model_id': 'model-1', 'tahsis_miktari': 12.5},
        {'model_id': 'model-2', 'tahsis_miktari': 7},
      ]);

      expect(sonuc, 19.5);
    });

    test('bos veya sayisal olmayan degerleri sifir kabul eder', () {
      final sonuc = IplikModelTahsisService.toplamTahsis([
        {'model_id': 'model-1', 'tahsis_miktari': null},
        {'model_id': 'model-2', 'tahsis_miktari': '5'},
      ]);

      expect(sonuc, 0);
    });
  });
}
