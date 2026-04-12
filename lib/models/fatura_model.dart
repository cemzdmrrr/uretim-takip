import 'package:flutter/material.dart';

/// Türk Ticaret Kanunu ve Vergi Usul Kanunu'na uygun fatura modeli
/// E-fatura entegrasyonu için hazır
class FaturaModel {
  final int? faturaId;
  final String faturaNo;
  final String faturaTuru; // 'satis', 'alis', 'iade', 'proforma'
  final DateTime faturaTarihi;
  final int? musteriId; // null ise nakit satış
  final int? tedarikciId; // alış faturaları için
  final String faturaAdres;
  final String? vergiDairesi;
  final String? vergiNo;
  final double araToplamTutar; // KDV hariç
  final double kdvTutari;
  final double toplamTutar; // KDV dahil
  final String durum; // 'taslak', 'onaylandi', 'iptal', 'gonderildi'
  final String? aciklama;
  final DateTime? vadeTarihi;
  final String odemeDurumu; // 'odenmedi', 'kismi', 'odendi'
  final double odenenTutar;
  final String kur; // 'TRY', 'USD', 'EUR'
  final double kurOrani;
  final String? efatturaUuid; // E-fatura için
  final DateTime? efaturaTarihi;
  final String? efaturaDurum;
  final DateTime olusturmaTarihi;
  final DateTime? guncellemeTarihi;
  final String olusturanKullanici;
  final String? firmaId;

  const FaturaModel({
    this.faturaId,
    required this.faturaNo,
    required this.faturaTuru,
    required this.faturaTarihi,
    this.musteriId,
    this.tedarikciId,
    required this.faturaAdres,
    this.vergiDairesi,
    this.vergiNo,
    required this.araToplamTutar,
    required this.kdvTutari,
    required this.toplamTutar,
    this.durum = 'taslak',
    this.aciklama,
    this.vadeTarihi,
    this.odemeDurumu = 'odenmedi',
    this.odenenTutar = 0.0,
    this.kur = 'TRY',
    this.kurOrani = 1.0,
    this.efatturaUuid,
    this.efaturaTarihi,
    this.efaturaDurum,
    required this.olusturmaTarihi,
    this.guncellemeTarihi,
    required this.olusturanKullanici,
    this.firmaId,
  });

  // JSON'dan model oluşturma
  factory FaturaModel.fromJson(Map<String, dynamic> json) {
    return FaturaModel(
      faturaId: json['fatura_id']?.toInt(),
      faturaNo: json['fatura_no'] ?? '',
      faturaTuru: json['fatura_turu'] ?? 'satis',
      faturaTarihi: json['fatura_tarihi'] != null 
          ? DateTime.parse(json['fatura_tarihi']) 
          : DateTime.now(),
      musteriId: json['musteri_id']?.toInt(),
      tedarikciId: json['tedarikci_id']?.toInt(),
      faturaAdres: json['fatura_adres'] ?? '',
      vergiDairesi: json['vergi_dairesi'],
      vergiNo: json['vergi_no'],
      araToplamTutar: (json['ara_toplam_tutar'] ?? 0.0).toDouble(),
      kdvTutari: (json['kdv_tutari'] ?? 0.0).toDouble(),
      toplamTutar: (json['toplam_tutar'] ?? 0.0).toDouble(),
      durum: json['durum'] ?? 'taslak',
      aciklama: json['aciklama'],
      vadeTarihi: json['vade_tarihi'] != null 
          ? DateTime.parse(json['vade_tarihi']) 
          : null,
      odemeDurumu: json['odeme_durumu'] ?? 'odenmedi',
      odenenTutar: (json['odenen_tutar'] ?? 0.0).toDouble(),
      kur: json['kur'] ?? 'TRY',
      kurOrani: (json['kur_orani'] ?? 1.0).toDouble(),
      efatturaUuid: json['efatura_uuid'],
      efaturaTarihi: json['efatura_tarihi'] != null 
          ? DateTime.parse(json['efatura_tarihi']) 
          : null,
      efaturaDurum: json['efatura_durum'],
      olusturmaTarihi: json['olusturma_tarihi'] != null 
          ? DateTime.parse(json['olusturma_tarihi']) 
          : DateTime.now(),
      guncellemeTarihi: json['guncelleme_tarihi'] != null 
          ? DateTime.parse(json['guncelleme_tarihi']) 
          : null,
      olusturanKullanici: json['olusturan_kullanici'] ?? '',
      firmaId: json['firma_id'],
    );
  }

  // Model'i JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      if (faturaId != null) 'fatura_id': faturaId,
      'fatura_no': faturaNo,
      'fatura_turu': faturaTuru,
      'fatura_tarihi': faturaTarihi.toIso8601String(),
      if (musteriId != null) 'musteri_id': musteriId,
      if (tedarikciId != null) 'tedarikci_id': tedarikciId,
      'fatura_adres': faturaAdres,
      if (vergiDairesi != null) 'vergi_dairesi': vergiDairesi,
      if (vergiNo != null) 'vergi_no': vergiNo,
      'ara_toplam_tutar': araToplamTutar,
      'kdv_tutari': kdvTutari,
      'toplam_tutar': toplamTutar,
      'durum': durum,
      if (aciklama != null) 'aciklama': aciklama,
      if (vadeTarihi != null) 'vade_tarihi': vadeTarihi!.toIso8601String(),
      'odeme_durumu': odemeDurumu,
      'odenen_tutar': odenenTutar,
      'kur': kur,
      'kur_orani': kurOrani,
      if (efatturaUuid != null) 'efatura_uuid': efatturaUuid,
      if (efaturaTarihi != null) 'efatura_tarihi': efaturaTarihi!.toIso8601String(),
      if (efaturaDurum != null) 'efatura_durum': efaturaDurum,
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
      if (guncellemeTarihi != null) 'guncelleme_tarihi': guncellemeTarihi!.toIso8601String(),
      'olusturan_kullanici': olusturanKullanici,
      if (firmaId != null) 'firma_id': firmaId,
    };
  }

  // Model'i Map'e çevirme (toMap alias for compatibility)
  Map<String, dynamic> toMap() => toJson();

  // Getter metodları
  String get formattedFaturaNo => faturaNo;
  String get formattedTarih => "${faturaTarihi.day.toString().padLeft(2, '0')}.${faturaTarihi.month.toString().padLeft(2, '0')}.${faturaTarihi.year}";
  String get formattedTutar => '${toplamTutar.toStringAsFixed(2)} $kur';
  String get durumText {
    switch (durum) {
      case 'taslak': return 'Taslak';
      case 'onaylandi': return 'Onaylandı';
      case 'iptal': return 'İptal';
      case 'gonderildi': return 'Gönderildi';
      default: return durum;
    }
  }
  
  String get odemeDurumuText {
    switch (odemeDurumu) {
      case 'odenmedi': return 'Ödenmedi';
      case 'kismi': return 'Kısmi Ödendi';
      case 'odendi': return 'Ödendi';
      default: return odemeDurumu;
    }
  }

  Color get durumColor {
    switch (durum) {
      case 'taslak': return Colors.orange;
      case 'onaylandi': return Colors.green;
      case 'iptal': return Colors.red;
      case 'gonderildi': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color get odemeDurumuColor {
    switch (odemeDurumu) {
      case 'odenmedi': return Colors.red;
      case 'kismi': return Colors.orange;
      case 'odendi': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Kalan tutar hesaplama
  double get kalanTutar => toplamTutar - odenenTutar;

  // Vadesi geçmiş mi kontrolü
  bool get vadesiGecmis {
    if (vadeTarihi == null) return false;
    return DateTime.now().isAfter(vadeTarihi!) && odemeDurumu != 'odendi';
  }

  // KDV oranı hesaplama
  double get kdvOrani {
    if (araToplamTutar == 0) return 0;
    return (kdvTutari / araToplamTutar) * 100;
  }

  // Copy with metodu
  FaturaModel copyWith({
    int? faturaId,
    String? faturaNo,
    String? faturaTuru,
    DateTime? faturaTarihi,
    int? musteriId,
    int? tedarikciId,
    String? faturaAdres,
    String? vergiDairesi,
    String? vergiNo,
    double? araToplamTutar,
    double? kdvTutari,
    double? toplamTutar,
    String? durum,
    String? aciklama,
    DateTime? vadeTarihi,
    String? odemeDurumu,
    double? odenenTutar,
    String? kur,
    double? kurOrani,
    String? efatturaUuid,
    DateTime? efaturaTarihi,
    String? efaturaDurum,
    DateTime? olusturmaTarihi,
    DateTime? guncellemeTarihi,
    String? olusturanKullanici,
    String? firmaId,
  }) {
    return FaturaModel(
      faturaId: faturaId ?? this.faturaId,
      faturaNo: faturaNo ?? this.faturaNo,
      faturaTuru: faturaTuru ?? this.faturaTuru,
      faturaTarihi: faturaTarihi ?? this.faturaTarihi,
      musteriId: musteriId ?? this.musteriId,
      tedarikciId: tedarikciId ?? this.tedarikciId,
      faturaAdres: faturaAdres ?? this.faturaAdres,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      vergiNo: vergiNo ?? this.vergiNo,
      araToplamTutar: araToplamTutar ?? this.araToplamTutar,
      kdvTutari: kdvTutari ?? this.kdvTutari,
      toplamTutar: toplamTutar ?? this.toplamTutar,
      durum: durum ?? this.durum,
      aciklama: aciklama ?? this.aciklama,
      vadeTarihi: vadeTarihi ?? this.vadeTarihi,
      odemeDurumu: odemeDurumu ?? this.odemeDurumu,
      odenenTutar: odenenTutar ?? this.odenenTutar,
      kur: kur ?? this.kur,
      kurOrani: kurOrani ?? this.kurOrani,
      efatturaUuid: efatturaUuid ?? this.efatturaUuid,
      efaturaTarihi: efaturaTarihi ?? this.efaturaTarihi,
      efaturaDurum: efaturaDurum ?? this.efaturaDurum,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
      olusturanKullanici: olusturanKullanici ?? this.olusturanKullanici,
      firmaId: firmaId ?? this.firmaId,
    );
  }

  @override
  String toString() {
    return 'FaturaModel(faturaId: $faturaId, faturaNo: $faturaNo, faturaTuru: $faturaTuru, toplamTutar: $toplamTutar, durum: $durum)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaturaModel && other.faturaId == faturaId;
  }

  @override
  int get hashCode => faturaId.hashCode;
}
