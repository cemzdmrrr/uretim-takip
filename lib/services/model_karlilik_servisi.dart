class MaliyetKalemi {
  final String kod;
  final String ad;
  final double planBirim;
  final double gercekBirim;

  const MaliyetKalemi({
    required this.kod,
    required this.ad,
    required this.planBirim,
    required this.gercekBirim,
  });

  double get sapmaBirim => gercekBirim - planBirim;
  double get sapmaOrani => planBirim > 0 ? (sapmaBirim / planBirim) * 100 : 0;
}

class ModelKarlilikOzeti {
  final int siparisAdedi;
  final int tamamlananAdet;
  final int fireAdedi;
  final double planBirimMaliyet;
  final double gercekBirimMaliyet;
  final double planToplamMaliyet;
  final double gercekToplamMaliyet;
  final double satisBirimFiyati;
  final double satisGeliri;
  final double brutKar;
  final double brutKarMarji;
  final double maliyetSapmasi;
  final double maliyetSapmaOrani;
  final double fireOrani;
  final double tamamlanmaOrani;
  final double hedefKarMarji;
  final double minimumFiyat;
  final double onerilenFiyat;
  final String tamamlananAdetKaynak;
  final String tamamlananAsama;
  final List<MaliyetKalemi> kalemler;

  const ModelKarlilikOzeti({
    required this.siparisAdedi,
    required this.tamamlananAdet,
    required this.fireAdedi,
    required this.planBirimMaliyet,
    required this.gercekBirimMaliyet,
    required this.planToplamMaliyet,
    required this.gercekToplamMaliyet,
    required this.satisBirimFiyati,
    required this.satisGeliri,
    required this.brutKar,
    required this.brutKarMarji,
    required this.maliyetSapmasi,
    required this.maliyetSapmaOrani,
    required this.fireOrani,
    required this.tamamlanmaOrani,
    required this.hedefKarMarji,
    required this.minimumFiyat,
    required this.onerilenFiyat,
    required this.tamamlananAdetKaynak,
    required this.tamamlananAsama,
    required this.kalemler,
  });

  bool get satisFiyatiEksik => satisBirimFiyati <= 0;
  bool get uretimGerceklesmedi => tamamlananAdet <= 0 && fireAdedi <= 0;
  double get hedefBrutKarMarji =>
      hedefKarMarji <= -100 ? 0 : (hedefKarMarji / (100 + hedefKarMarji)) * 100;
  double get gercekKarOrani =>
      gercekToplamMaliyet > 0 ? (brutKar / gercekToplamMaliyet) * 100 : 0;
  bool get zararRiski => !satisFiyatiEksik && brutKar < 0;
  bool get hedefAltinda =>
      !satisFiyatiEksik && gercekKarOrani + 0.05 < hedefKarMarji;
}

class ModelKarlilikServisi {
  const ModelKarlilikServisi();

  ModelKarlilikOzeti hesapla({
    required Map<String, dynamic> model,
    required List<dynamic> uretimKayitlari,
    required List<dynamic> modelAksesuarlari,
  }) {
    final siparisAdedi = _intDeger(model['toplam_adet'] ?? model['adet']);
    final tamamlananSonucu = _tamamlananAdet(model, uretimKayitlari);
    final tamamlananAdet = tamamlananSonucu.adet;
    final fireAdedi = _fireAdedi(model, uretimKayitlari);
    final maliyetKalemleri = _maliyetKalemleri(model);
    final planBirimMaliyet =
        maliyetKalemleri.fold<double>(0, (sum, item) => sum + item.planBirim);
    final hedefKarMarji = _doubleDeger(model['kar_marji']);
    final satisBirimFiyati = _satisBirimFiyati(model, planBirimMaliyet);
    final maliyetYuklenenAdet = tamamlananAdet > 0
        ? tamamlananAdet + fireAdedi
        : (siparisAdedi > 0 ? siparisAdedi + fireAdedi : 0);
    final gercekToplamMaliyet = planBirimMaliyet * maliyetYuklenenAdet;
    final gercekBirimMaliyet = tamamlananAdet > 0
        ? gercekToplamMaliyet / tamamlananAdet
        : planBirimMaliyet;
    final planToplamMaliyet = planBirimMaliyet * siparisAdedi;
    final satisAdedi = tamamlananAdet > 0 ? tamamlananAdet : siparisAdedi;
    final satisGeliri = satisBirimFiyati * satisAdedi;
    final brutKar = satisGeliri - gercekToplamMaliyet;
    final brutKarMarji = satisGeliri > 0 ? (brutKar / satisGeliri) * 100 : 0.0;
    final maliyetSapmasi = gercekBirimMaliyet - planBirimMaliyet;
    final maliyetSapmaOrani =
        planBirimMaliyet > 0 ? (maliyetSapmasi / planBirimMaliyet) * 100 : 0.0;
    final fireOrani = siparisAdedi > 0 ? (fireAdedi / siparisAdedi) * 100 : 0.0;
    final tamamlanmaOrani =
        siparisAdedi > 0 ? (tamamlananAdet / siparisAdedi) * 100 : 0.0;
    final minimumFiyat = gercekBirimMaliyet;
    final onerilenFiyat = gercekBirimMaliyet * (1 + hedefKarMarji / 100);
    final gercekKalemler = maliyetKalemleri
        .map((kalem) => MaliyetKalemi(
              kod: kalem.kod,
              ad: kalem.ad,
              planBirim: kalem.planBirim,
              gercekBirim: planBirimMaliyet > 0
                  ? kalem.planBirim * (gercekBirimMaliyet / planBirimMaliyet)
                  : kalem.planBirim,
            ))
        .toList();

    return ModelKarlilikOzeti(
      siparisAdedi: siparisAdedi,
      tamamlananAdet: tamamlananAdet,
      fireAdedi: fireAdedi,
      planBirimMaliyet: planBirimMaliyet,
      gercekBirimMaliyet: gercekBirimMaliyet,
      planToplamMaliyet: planToplamMaliyet,
      gercekToplamMaliyet: gercekToplamMaliyet,
      satisBirimFiyati: satisBirimFiyati,
      satisGeliri: satisGeliri,
      brutKar: brutKar,
      brutKarMarji: brutKarMarji,
      maliyetSapmasi: maliyetSapmasi,
      maliyetSapmaOrani: maliyetSapmaOrani,
      fireOrani: fireOrani,
      tamamlanmaOrani: tamamlanmaOrani,
      hedefKarMarji: hedefKarMarji,
      minimumFiyat: minimumFiyat,
      onerilenFiyat: onerilenFiyat,
      tamamlananAdetKaynak: tamamlananSonucu.kaynak,
      tamamlananAsama: tamamlananSonucu.asama,
      kalemler: gercekKalemler,
    );
  }

  List<MaliyetKalemi> _maliyetKalemleri(Map<String, dynamic> model) {
    final kalemler = <MaliyetKalemi>[
      _kalem('iplik', 'Iplik', model['iplik_maliyeti']),
      _kalem('orgu', 'Orgu', model['orgu_fiyat']),
      _kalem('dikim', 'Dikim', model['dikim_fiyat']),
      _kalem('utu', 'Utu', model['utu_fiyat']),
      _kalem('yikama', 'Yikama', model['yikama_fiyat']),
      _kalem('ilik_dugme', 'Ilik Dugme', model['ilik_dugme_fiyat']),
      _kalem('fermuar', 'Fermuar', model['fermuar_fiyat']),
      _kalem('baski_nakis', 'Baski / Nakis', model['aksesuar_fiyat']),
      _kalem('genel_aksesuar', 'Genel Aksesuar', model['genel_aksesuar_fiyat']),
      _kalem('genel_gider', 'Genel Gider', model['genel_gider_fiyat']),
    ];

    return kalemler.where((kalem) => kalem.planBirim > 0).toList();
  }

  MaliyetKalemi _kalem(String kod, String ad, dynamic value) {
    final tutar = _doubleDeger(value);
    return MaliyetKalemi(
        kod: kod, ad: ad, planBirim: tutar, gercekBirim: tutar);
  }

  _TamamlananAdetSonucu _tamamlananAdet(
      Map<String, dynamic> model, List<dynamic> kayitlar) {
    final modelTamamlanan = _intDeger(model['tamamlanan_adet']);
    if (modelTamamlanan > 0) {
      return _TamamlananAdetSonucu(
        adet: modelTamamlanan,
        kaynak: 'Model kartı',
        asama: 'model',
      );
    }

    final asamaToplamlari = <String, int>{};
    for (final kayit in kayitlar) {
      if (kayit is! Map) continue;
      final asama = kayit['asama']?.toString() ?? 'genel';
      final adet = _intDeger(kayit['kabul_edilen_adet'] ??
          kayit['tamamlanan_adet'] ??
          kayit['uretilen_adet']);
      asamaToplamlari[asama] = (asamaToplamlari[asama] ?? 0) + adet;
    }
    if (asamaToplamlari.isEmpty) {
      return const _TamamlananAdetSonucu(
        adet: 0,
        kaynak: 'Üretim kaydı yok',
        asama: '-',
      );
    }

    for (final asama in modelKarlilikAsamaOnceligi) {
      final adet = asamaToplamlari[asama] ?? 0;
      if (adet > 0) {
        return _TamamlananAdetSonucu(
          adet: adet,
          kaynak: 'En ileri üretim aşaması',
          asama: asama,
        );
      }
    }

    final fallback =
        asamaToplamlari.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return _TamamlananAdetSonucu(
      adet: fallback.value,
      kaynak: 'Tanımsız aşama toplamı',
      asama: fallback.key,
    );
  }

  int _fireAdedi(Map<String, dynamic> model, List<dynamic> kayitlar) {
    int toplam = _intDeger(model['fire_adet']);
    for (final kayit in kayitlar) {
      if (kayit is! Map) continue;
      toplam += _intDeger(kayit['fire_adet']);
    }
    return toplam;
  }

  double _satisBirimFiyati(
      Map<String, dynamic> model, double planBirimMaliyet) {
    final karMarji = _doubleDeger(model['kar_marji']);
    var satisFiyati = planBirimMaliyet * (1 + karMarji / 100);
    final vadeAy = _intDeger(model['vade_ay']);
    final vadeOrani = _doubleDeger(model['vade_orani']);
    if (vadeAy > 0 && vadeOrani > 0) {
      satisFiyati *= 1 + vadeOrani / 100;
    }
    return satisFiyati;
  }

  int _intDeger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleDeger(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    final text = (value?.toString() ?? '').trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
          0.0;
    }
    return double.tryParse(text) ?? 0.0;
  }
}

class _TamamlananAdetSonucu {
  final int adet;
  final String kaynak;
  final String asama;

  const _TamamlananAdetSonucu({
    required this.adet,
    required this.kaynak,
    required this.asama,
  });
}

const modelKarlilikAsamaOnceligi = <String>[
  'sevkiyat',
  'yukleme',
  'depolama',
  'paketleme',
  'kalite_kontrol',
  'kalite',
  'test',
  'utu',
  'utu_pres',
  'ilik_dugme',
  'yikama',
  'son_terbiye',
  'terbiye',
  'nakis',
  'baski',
  'konfeksiyon',
  'dikim',
  'kesim',
  'orgu',
  'orme',
  'dokuma',
  'boyama',
  'iplik_hazirlama',
];
