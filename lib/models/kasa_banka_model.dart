import 'package:flutter/material.dart';

/// Kasa/Banka hesapları modeli
class KasaBankaModel {
  final int? id;
  final String ad; // hesap adı
  final String tip; // 'KASA', 'BANKA', 'KREDI_KARTI', 'CEK_HESABI'
  final String? bankaAdi;
  final String? hesapNo;
  final String? iban;
  final String? subeKodu;
  final String? subeAdi;
  final double bakiye;
  final String dovizTuru; // 'TRY', 'USD', 'EUR'
  final String durumu; // 'AKTIF', 'PASIF', 'DONUK'
  final String? aciklama;
  final DateTime olusturmaTarihi;
  final DateTime guncellenmeTarihi;
  final String? firmaId;

  const KasaBankaModel({
    this.id,
    required this.ad,
    required this.tip,
    this.bankaAdi,
    this.hesapNo,
    this.iban,
    this.subeKodu,
    this.subeAdi,
    this.bakiye = 0.0,
    this.dovizTuru = 'TRY',
    this.durumu = 'AKTIF',
    this.aciklama,
    required this.olusturmaTarihi,
    required this.guncellenmeTarihi,
    this.firmaId,
  });

  // JSON'dan model oluşturma (her iki DB şemasıyla uyumlu)
  factory KasaBankaModel.fromJson(Map<String, dynamic> json) {
    return KasaBankaModel(
      id: json['id']?.toInt(),
      ad: json['hesap_adi'] ?? json['ad'] ?? '',
      tip: (json['tip'] ?? 'KASA').toString().toUpperCase(),
      bankaAdi: json['banka_adi'],
      hesapNo: json['hesap_no'],
      iban: json['iban'],
      subeKodu: json['sube_kodu'],
      subeAdi: json['sube_adi'],
      bakiye: (json['bakiye'] ?? 0.0).toDouble(),
      dovizTuru: (json['doviz_turu'] ?? json['doviz_kodu'] ?? 'TRY').toString().toUpperCase(),
      durumu: (json['durumu'] ?? 'AKTIF').toString().toUpperCase(),
      aciklama: json['aciklama'],
      olusturmaTarihi: json['olusturma_tarihi'] != null 
          ? DateTime.parse(json['olusturma_tarihi'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      guncellenmeTarihi: json['guncelleme_tarihi'] != null 
          ? DateTime.parse(json['guncelleme_tarihi'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      firmaId: json['firma_id'],
    );
  }

  // Model'i JSON'a çevirme (DB sütun adlarıyla uyumlu)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'hesap_adi': ad,
      'tip': tip.toLowerCase(),
      if (hesapNo != null) 'hesap_no': hesapNo,
      if (iban != null) 'iban': iban,
      'bakiye': bakiye,
      'doviz_kodu': dovizTuru,
      'durumu': durumu.toLowerCase(),
      if (firmaId != null) 'firma_id': firmaId,
    };
  }

  // Map'e çevirme (toMap alias for compatibility)
  Map<String, dynamic> toMap() => toJson();

  // Backwards compatibility getters
  String get hesapAdi => ad;
  String get hesapTuru => tip.toLowerCase().replaceAll('_', '');
  String? get ibanNo => iban;
  String get kur => dovizTuru;
  bool get aktif => durumu == 'AKTIF';
  String get hesapTuruText => tipText;
  Color get hesapTuruColor => tipColor;

  // Getter metodları
  String get tipText {
    switch (tip) {
      case 'KASA': return 'Kasa';
      case 'BANKA': return 'Banka';
      case 'KREDI_KARTI': return 'Kredi Kartı';
      case 'CEK_HESABI': return 'Çek Hesabı';
      default: return tip;
    }
  }

  String get formattedBakiye => '${bakiye.toStringAsFixed(2)} $dovizTuru';
  String get maskedHesapNo => hesapNo != null ? '**** **** **** ${hesapNo!.substring(hesapNo!.length - 4)}' : '';
  String get maskedIban => iban != null ? 'TR** **** **** ****' : '';

  Color get tipColor {
    switch (tip) {
      case 'KASA': return Colors.brown;
      case 'BANKA': return Colors.blue;
      case 'KREDI_KARTI': return Colors.purple;
      case 'CEK_HESABI': return Colors.teal;
      default: return Colors.grey;
    }
  }

  // Copy with metodu
  KasaBankaModel copyWith({
    int? id,
    String? ad,
    String? tip,
    String? bankaAdi,
    String? hesapNo,
    String? iban,
    String? subeKodu,
    String? subeAdi,
    double? bakiye,
    String? dovizTuru,
    String? durumu,
    String? aciklama,
    DateTime? olusturmaTarihi,
    DateTime? guncellenmeTarihi,
    String? firmaId,
  }) {
    return KasaBankaModel(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      tip: tip ?? this.tip,
      bankaAdi: bankaAdi ?? this.bankaAdi,
      hesapNo: hesapNo ?? this.hesapNo,
      iban: iban ?? this.iban,
      subeKodu: subeKodu ?? this.subeKodu,
      subeAdi: subeAdi ?? this.subeAdi,
      bakiye: bakiye ?? this.bakiye,
      dovizTuru: dovizTuru ?? this.dovizTuru,
      durumu: durumu ?? this.durumu,
      aciklama: aciklama ?? this.aciklama,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      guncellenmeTarihi: guncellenmeTarihi ?? this.guncellenmeTarihi,
      firmaId: firmaId ?? this.firmaId,
    );
  }

  @override
  String toString() {
    return 'KasaBankaModel(id: $id, ad: $ad, tip: $tip, bakiye: $formattedBakiye)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KasaBankaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
