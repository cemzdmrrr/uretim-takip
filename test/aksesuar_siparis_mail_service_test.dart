import 'package:flutter_test/flutter_test.dart';
import 'package:uretim_takip/services/aksesuar_siparis_mail_service.dart';

void main() {
  test('tedarikci ve firma adresleriyle mailto taslagi olusturur', () {
    final taslak = AksesuarSiparisMailService.taslakOlustur(
      aksesuar: {
        'ad': 'Metal Düğme',
        'sku': 'DÜĞ-01',
        'birim': 'adet',
        'renk': 'Gümüş',
        'aksesuar_bedenler': [
          {'beden': '18 mm', 'stok_miktari': 4, 'durum': 'aktif'},
        ],
      },
      siparisMiktari: 12,
      mevcutStok: 4,
      minimumStok: 10,
      tedarikciAdi: 'Örnek Tedarik',
      tedarikciEmail: 'tedarik@example.com',
      firmaSiparisEmail: 'satinalma@example.com',
    );

    expect(taslak.uri.scheme, 'mailto');
    expect(taslak.uri.path, 'tedarik@example.com');
    expect(taslak.uri.queryParameters['cc'], 'satinalma@example.com');
    expect(taslak.govde, contains('Metal Düğme'));
    expect(taslak.govde, contains('18 mm: 4 adet'));
  });

  test('tedarikci emaili olmadan alicisiz taslak olusturur', () {
    final taslak = AksesuarSiparisMailService.taslakOlustur(
      aksesuar: {'ad': 'Fermuar', 'sku': 'FR-1'},
      siparisMiktari: 1,
      mevcutStok: 20,
      minimumStok: 10,
    );

    expect(taslak.uri.path, isEmpty);
    expect(taslak.uri.queryParameters['subject'], contains('FR-1'));
  });

  test('mailto konu ve govdesinde bosluklari arti isaretine cevirmez', () {
    final taslak = AksesuarSiparisMailService.taslakOlustur(
      aksesuar: {
        'ad': 'Koli + Maliyet',
        'sku': 'BSKSZ2',
        'birim': 'adet',
      },
      siparisMiktari: 2,
      mevcutStok: 10,
      minimumStok: 5,
    );

    final mailto = taslak.uri.toString();
    expect(mailto, isNot(contains('+')));
    expect(mailto, contains('%20'));
    expect(mailto, contains('%2B'));
    expect(
      taslak.uri.queryParameters['subject'],
      'Aksesuar Siparişi - BSKSZ2 - Koli + Maliyet',
    );
    expect(
      taslak.uri.queryParameters['body'],
      contains('Aşağıdaki ürün için sipariş oluşturulmasını rica ederiz:'),
    );
  });

  test('gecersiz siparis miktarini reddeder', () {
    expect(
      () => AksesuarSiparisMailService.taslakOlustur(
        aksesuar: const {},
        siparisMiktari: 0,
        mevcutStok: 0,
        minimumStok: 10,
      ),
      throwsArgumentError,
    );
  });
}
