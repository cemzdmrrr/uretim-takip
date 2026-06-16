import 'package:uretim_takip/models/fatura_kalemi_model.dart';

class UyumsoftGelenFaturaKalemi {
  final String? id;
  final String? gelenFaturaId;
  final int siraNo;
  final String kategori;
  final String? urunKodu;
  final String urunAdi;
  final String? aciklama;
  final double miktar;
  final String birim;
  final double birimFiyat;
  final double iskontoOrani;
  final double iskontoTutari;
  final double kdvOrani;
  final double kdvTutari;
  final double toplamTutar;

  const UyumsoftGelenFaturaKalemi({
    this.id,
    this.gelenFaturaId,
    required this.siraNo,
    this.kategori = FaturaKategori.diger,
    this.urunKodu,
    required this.urunAdi,
    this.aciklama,
    required this.miktar,
    this.birim = 'adet',
    required this.birimFiyat,
    this.iskontoOrani = 0,
    this.iskontoTutari = 0,
    this.kdvOrani = 20,
    required this.kdvTutari,
    required this.toplamTutar,
  });

  factory UyumsoftGelenFaturaKalemi.fromJson(Map<String, dynamic> json) {
    return UyumsoftGelenFaturaKalemi(
      id: json['id']?.toString(),
      gelenFaturaId: json['gelen_fatura_id']?.toString(),
      siraNo: (json['sira_no'] as num?)?.toInt() ?? 1,
      kategori: FaturaKategori.normalize(json['kategori']?.toString()),
      urunKodu: json['urun_kodu']?.toString(),
      urunAdi: json['urun_adi']?.toString() ?? '',
      aciklama: json['aciklama']?.toString(),
      miktar: (json['miktar'] as num?)?.toDouble() ?? 0,
      birim: json['birim']?.toString() ?? 'adet',
      birimFiyat: (json['birim_fiyat'] as num?)?.toDouble() ?? 0,
      iskontoOrani: (json['iskonto_orani'] as num?)?.toDouble() ?? 0,
      iskontoTutari: (json['iskonto_tutari'] as num?)?.toDouble() ?? 0,
      kdvOrani: (json['kdv_orani'] as num?)?.toDouble() ?? 20,
      kdvTutari: (json['kdv_tutari'] as num?)?.toDouble() ?? 0,
      toplamTutar: (json['toplam_tutar'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap(String gelenFaturaId, String firmaId) {
    return {
      'gelen_fatura_id': gelenFaturaId,
      'firma_id': firmaId,
      'sira_no': siraNo,
      'kategori': FaturaKategori.normalize(kategori),
      if (urunKodu != null && urunKodu!.trim().isNotEmpty)
        'urun_kodu': urunKodu,
      'urun_adi': urunAdi,
      if (aciklama != null && aciklama!.trim().isNotEmpty) 'aciklama': aciklama,
      'miktar': miktar,
      'birim': birim,
      'birim_fiyat': birimFiyat,
      'iskonto_orani': iskontoOrani,
      'iskonto_tutari': iskontoTutari,
      'kdv_orani': kdvOrani,
      'kdv_tutari': kdvTutari,
      'toplam_tutar': toplamTutar,
    };
  }
}

class UyumsoftGelenFatura {
  final String id;
  final String kaynak;
  final String durum;
  final String ettn;
  final String faturaNo;
  final DateTime faturaTarihi;
  final String? senaryo;
  final String cariUnvan;
  final String? vergiNo;
  final String? vergiDairesi;
  final String? faturaAdres;
  final String paraBirimi;
  final double araToplamTutar;
  final double kdvTutari;
  final double toplamTutar;
  final int? tedarikciId;
  final int? faturaId;
  final String? redSebebi;
  final DateTime? createdAt;
  final List<UyumsoftGelenFaturaKalemi> kalemler;

  const UyumsoftGelenFatura({
    required this.id,
    required this.kaynak,
    required this.durum,
    required this.ettn,
    required this.faturaNo,
    required this.faturaTarihi,
    this.senaryo,
    required this.cariUnvan,
    this.vergiNo,
    this.vergiDairesi,
    this.faturaAdres,
    this.paraBirimi = 'TRY',
    required this.araToplamTutar,
    required this.kdvTutari,
    required this.toplamTutar,
    this.tedarikciId,
    this.faturaId,
    this.redSebebi,
    this.createdAt,
    this.kalemler = const [],
  });

  factory UyumsoftGelenFatura.fromJson(Map<String, dynamic> json) {
    final kalemJson = json['uyumsoft_gelen_fatura_kalemleri'];
    return UyumsoftGelenFatura(
      id: json['id'].toString(),
      kaynak: json['kaynak']?.toString() ?? 'xml',
      durum: json['durum']?.toString() ?? 'beklemede',
      ettn: json['ettn']?.toString() ?? '',
      faturaNo: json['fatura_no']?.toString() ?? '',
      faturaTarihi:
          DateTime.tryParse(json['fatura_tarihi']?.toString() ?? '') ??
              DateTime.now(),
      senaryo: json['senaryo']?.toString(),
      cariUnvan: json['cari_unvan']?.toString() ?? '',
      vergiNo: json['vergi_no']?.toString(),
      vergiDairesi: json['vergi_dairesi']?.toString(),
      faturaAdres: json['fatura_adres']?.toString(),
      paraBirimi: json['para_birimi']?.toString() ?? 'TRY',
      araToplamTutar: (json['ara_toplam_tutar'] as num?)?.toDouble() ?? 0,
      kdvTutari: (json['kdv_tutari'] as num?)?.toDouble() ?? 0,
      toplamTutar: (json['toplam_tutar'] as num?)?.toDouble() ?? 0,
      tedarikciId: (json['tedarikci_id'] as num?)?.toInt(),
      faturaId: (json['fatura_id'] as num?)?.toInt(),
      redSebebi: json['red_sebebi']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      kalemler: kalemJson is List
          ? kalemJson
              .whereType<Map<String, dynamic>>()
              .map(UyumsoftGelenFaturaKalemi.fromJson)
              .toList()
          : const [],
    );
  }
}
