import 'package:flutter/material.dart';

class TedarikciModel {
  final int? id;
  final String ad;
  final String? soyad;
  final String? sirket;
  final String telefon;
  final String? email;
  final String tedarikciTipi; // 'Üretici', 'İthalatçı', 'Distribütör', 'Bayi', 'Hizmet Sağlayıcı', 'Diğer'
  final String? faaliyet; // 'Tekstil', 'İplik', 'Aksesuar', 'Makine', 'Kimyasal', 'Ambalaj', 'Lojistik', 'Diğer'
  final String durum; // 'aktif', 'pasif', 'beklemede'
  final String? vergiNo;
  final String? tcKimlik;
  final String? ibanNo;
  final DateTime kayitTarihi;
  final DateTime? guncellemeTarihi;
  final String? firmaId;

  // Getter'lar TedarikciDetayPage için
  String get unvan => sirket?.isNotEmpty == true ? sirket! : '$ad${soyad != null ? ' $soyad' : ''}';
  String get kod => id?.toString() ?? '';
  String get tur => tedarikciTipi;
  String? get fasonFaaliyet => faaliyet;
  DateTime get olusturmaTarihi => kayitTarihi;

  // Getter for backwards compatibility with fatura module
  int? get tedarikciId => id;

  TedarikciModel({
    this.id,
    required this.ad,
    this.soyad,
    this.sirket,
    required this.telefon,
    this.email,
    this.tedarikciTipi = 'Üretici',
    this.faaliyet,
    this.durum = 'aktif',
    this.vergiNo,
    this.tcKimlik,
    this.ibanNo,
    required this.kayitTarihi,
    this.guncellemeTarihi,
    this.firmaId,
  });

  // JSON'dan model oluşturma
  factory TedarikciModel.fromJson(Map<String, dynamic> json) {
    return TedarikciModel(
      id: json['id'] as int?,
      ad: json['ad'] as String,
      soyad: json['soyad'] as String?,
      sirket: json['sirket'] as String?,
      telefon: json['telefon'] as String,
      email: json['email'] as String?,
      tedarikciTipi: json['tedarikci_tipi'] as String? ?? 'Üretici',
      faaliyet: json['faaliyet'] as String?,
      durum: json['durum'] as String? ?? 'aktif',
      vergiNo: json['vergi_no'] as String?,
      tcKimlik: json['tc_kimlik'] as String?,
      ibanNo: json['iban_no'] as String?,
      kayitTarihi: DateTime.parse(json['kayit_tarihi'] as String),
      guncellemeTarihi: json['guncelleme_tarihi'] != null
          ? DateTime.parse(json['guncelleme_tarihi'] as String)
          : null,
      firmaId: json['firma_id'],
    );
  }

  // Model'i JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'soyad': soyad,
      'sirket': sirket,
      'telefon': telefon,
      'email': email,
      'tedarikci_tipi': tedarikciTipi,
      'faaliyet': faaliyet,
      'durum': durum,
      'vergi_no': vergiNo,
      'tc_kimlik': tcKimlik,
      'iban_no': ibanNo,
      'kayit_tarihi': kayitTarihi.toIso8601String(),
      'guncelleme_tarihi': guncellemeTarihi?.toIso8601String(),
      'firma_id': firmaId,
    };
  }

  // Tedarikçi tipi açıklaması
  String get tedarikciTipiAciklama {
    switch (tedarikciTipi) {
      case 'Üretici':
        return 'Üretici';
      case 'İthalatçı':
        return 'İthalatçı';
      case 'Distribütör':
        return 'Distribütör';
      case 'Bayi':
        return 'Bayi';
      case 'Hizmet Sağlayıcı':
        return 'Hizmet Sağlayıcı';
      case 'Diğer':
        return 'Diğer';
      default:
        return 'Belirtilmemiş';
    }
  }

  // Faaliyet açıklaması
  String get faaliyetAciklama {
    if (faaliyet == null) return '';
    switch (faaliyet!) {
      case 'Tekstil':
        return 'Tekstil';
      case 'İplik':
        return 'İplik';
      case 'Aksesuar':
        return 'Aksesuar';
      case 'Makine':
        return 'Makine';
      case 'Kimyasal':
        return 'Kimyasal';
      case 'Ambalaj':
        return 'Ambalaj';
      case 'Lojistik':
        return 'Lojistik';
      case 'Diğer':
        return 'Diğer';
      default:
        return faaliyet!;
    }
  }

  // Durum açıklaması
  String get durumAciklama {
    switch (durum) {
      case 'aktif':
        return 'Aktif';
      case 'pasif':
        return 'Pasif';
      case 'beklemede':
        return 'Beklemede';
      default:
        return 'Belirtilmemiş';
    }
  }

  // Durum rengi (UI için)
  Color get durumRengi {
    switch (durum) {
      case 'aktif':
        return Colors.green;
      case 'pasif':
        return Colors.grey;
      case 'beklemede':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Görüntüleme adı (şirket varsa şirket, yoksa ad soyad)
  String get goruntulemeAdi {
    if (sirket != null && sirket!.isNotEmpty) {
      return sirket!;
    }
    return '$ad${soyad != null ? ' $soyad' : ''}';
  }

  @override
  String toString() {
    return 'TedarikciModel{id: $id, ad: $ad, soyad: $soyad, sirket: $sirket, tedarikciTipi: $tedarikciTipi, durum: $durum}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TedarikciModel &&
      other.id == id &&
      other.ad == ad &&
      other.soyad == soyad &&
      other.telefon == telefon &&
      other.tedarikciTipi == tedarikciTipi;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      ad.hashCode ^
      soyad.hashCode ^
      telefon.hashCode ^
      tedarikciTipi.hashCode;
  }
}
