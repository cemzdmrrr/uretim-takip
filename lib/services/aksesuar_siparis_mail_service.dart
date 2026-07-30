class AksesuarSiparisMailTaslagi {
  final String konu;
  final String govde;
  final Uri uri;

  const AksesuarSiparisMailTaslagi({
    required this.konu,
    required this.govde,
    required this.uri,
  });
}

class AksesuarSiparisMailService {
  static AksesuarSiparisMailTaslagi taslakOlustur({
    required Map<String, dynamic> aksesuar,
    required int siparisMiktari,
    required int mevcutStok,
    required int minimumStok,
    String? tedarikciAdi,
    String? tedarikciEmail,
    String? firmaSiparisEmail,
  }) {
    if (siparisMiktari <= 0) {
      throw ArgumentError.value(siparisMiktari, 'siparisMiktari');
    }

    final ad = _metin(aksesuar['ad'], 'Aksesuar');
    final sku = _metin(aksesuar['sku'], '-');
    final birim = _metin(aksesuar['birim'], 'adet');
    final renk = _metin(aksesuar['renk'], '-');
    final marka = _metin(aksesuar['marka'], '-');
    final malzeme = _metin(aksesuar['malzeme'], '-');
    final muhatap = _temiz(tedarikciAdi);
    final firmaEmail = _temiz(firmaSiparisEmail);
    final bedenler = (aksesuar['aksesuar_bedenler'] as List? ?? const [])
        .where((beden) => beden is Map && beden['durum'] == 'aktif')
        .map((beden) =>
            '- ${_metin(beden['beden'], '-')}: ${beden['stok_miktari'] ?? 0} $birim')
        .join('\n');

    final konu = 'Aksesuar Siparişi - $sku - $ad';
    final satirlar = <String>[
      'Merhaba${muhatap.isEmpty ? '' : ' $muhatap'},',
      '',
      'Aşağıdaki ürün için sipariş oluşturulmasını rica ederiz:',
      '',
      'Ürün: $ad',
      'SKU: $sku',
      'Marka: $marka',
      'Renk: $renk',
      'Malzeme: $malzeme',
      'Sipariş miktarı: $siparisMiktari $birim',
      'Mevcut stok: $mevcutStok $birim',
      'Minimum stok: $minimumStok $birim',
      if (bedenler.isNotEmpty) ...['', 'Beden stokları:', bedenler],
      if (firmaEmail.isNotEmpty) ...[
        '',
        'Sipariş iletişim adresi: $firmaEmail'
      ],
      '',
      'İyi çalışmalar.',
    ];
    final govde = satirlar.join('\n');
    final query = <String, String>{
      'subject': konu,
      'body': govde,
      if (firmaEmail.isNotEmpty) 'cc': firmaEmail,
    };
    final uri = Uri(
      scheme: 'mailto',
      path: _temiz(tedarikciEmail),
      queryParameters: query,
    );
    return AksesuarSiparisMailTaslagi(konu: konu, govde: govde, uri: uri);
  }

  static String _temiz(dynamic value) => value?.toString().trim() ?? '';
  static String _metin(dynamic value, String fallback) {
    final text = _temiz(value);
    return text.isEmpty ? fallback : text;
  }
}
