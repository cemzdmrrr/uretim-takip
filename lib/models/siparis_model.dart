import 'package:flutter/material.dart';

class SiparisModel {
  final int? id;
  final String marka;
  final String itemNo;
  final String? renk;
  final String? urunCinsi;
  final String? iplikCinsi;
  final String? uretici;
  final Map<String, dynamic>? bedenler;
  final DateTime? termin;
  final bool? tamamlandi;
  final int? musteriId;
  final String? musteriAd;
  final String? musteriSoyad;
  final String? musteriSirket;
  final String? musteriTipi;
  final DateTime? siparisTarihi;
  final String? siparisNotu;
  final double? toplamMaliyet;
  final String? kur;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Genel üretim bilgileri
  final String? uretimDali; // triko, konfeksiyon, dokuma_kumas vb.
  final String? urunTipi; // dalın alt tipi
  final Map<String, dynamic>? dalOzelAlanlar; // dal'a özgü JSONB alanlar

  // Üretim süreçleri (triko geriye uyumluluk)
  final dynamic orguFirma;
  final dynamic konfeksiyonFirma;
  final dynamic utuFirma;
  final int? yuklenenAdet;
  final bool? iplikGeldi;
  final DateTime? iplikTarihi;
  final String? firmaId;

  SiparisModel({
    this.id,
    required this.marka,
    required this.itemNo,
    this.renk,
    this.urunCinsi,
    this.iplikCinsi,
    this.uretici,
    this.bedenler,
    this.termin,
    this.tamamlandi,
    this.musteriId,
    this.musteriAd,
    this.musteriSoyad,
    this.musteriSirket,
    this.musteriTipi,
    this.siparisTarihi,
    this.siparisNotu,
    this.toplamMaliyet,
    this.kur = 'TRY',
    this.createdAt,
    this.updatedAt,
    this.uretimDali,
    this.urunTipi,
    this.dalOzelAlanlar,
    this.orguFirma,
    this.konfeksiyonFirma,
    this.utuFirma,
    this.yuklenenAdet,
    this.iplikGeldi,
    this.iplikTarihi,
    this.firmaId,
  });

  factory SiparisModel.fromJson(Map<String, dynamic> json) {
    return SiparisModel(
      id: json['id'] as int?,
      marka: json['marka'] ?? '',
      itemNo: json['item_no'] ?? '',
      renk: json['renk'],
      urunCinsi: json['urun_cinsi'],
      iplikCinsi: json['iplik_cinsi'],
      uretici: json['uretici'],
      bedenler: json['bedenler'] as Map<String, dynamic>?,
      termin: json['termin'] != null ? DateTime.tryParse(json['termin']) : null,
      tamamlandi: json['tamamlandi'] as bool?,
      musteriId: json['musteri_id'] as int?,
      musteriAd: json['musteri_ad'],
      musteriSoyad: json['musteri_soyad'],
      musteriSirket: json['musteri_sirket'],
      musteriTipi: json['musteri_tipi'],
      siparisTarihi: json['siparis_tarihi'] != null ? DateTime.tryParse(json['siparis_tarihi']) : null,
      siparisNotu: json['siparis_notu'],
      toplamMaliyet: json['toplam_maliyet']?.toDouble(),
      kur: json['kur'] ?? 'TRY',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      uretimDali: json['uretim_dali'] as String?,
      urunTipi: json['urun_tipi'] as String?,
      dalOzelAlanlar: json['dal_ozel_alanlar'] as Map<String, dynamic>?,
      orguFirma: json['orgu_firma'],
      konfeksiyonFirma: json['konfeksiyon_firma'],
      utuFirma: json['utu_firma'],
      yuklenenAdet: json['yuklenen_adet'] as int?,
      iplikGeldi: json['iplik_geldi'] as bool?,
      iplikTarihi: json['iplik_tarihi'] != null ? DateTime.tryParse(json['iplik_tarihi']) : null,
      firmaId: json['firma_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marka': marka,
      'item_no': itemNo,
      'renk': renk,
      'urun_cinsi': urunCinsi,
      'iplik_cinsi': iplikCinsi,
      'uretici': uretici,
      'bedenler': bedenler,
      'termin': termin?.toIso8601String(),
      'tamamlandi': tamamlandi,
      'musteri_id': musteriId,
      'siparis_tarihi': siparisTarihi?.toIso8601String(),
      'siparis_notu': siparisNotu,
      'toplam_maliyet': toplamMaliyet,
      'kur': kur,
      'uretim_dali': uretimDali,
      'urun_tipi': urunTipi,
      'dal_ozel_alanlar': dalOzelAlanlar,
      'orgu_firma': orguFirma,
      'konfeksiyon_firma': konfeksiyonFirma,
      'utu_firma': utuFirma,
      'yuklenen_adet': yuklenenAdet,
      'iplik_geldi': iplikGeldi,
      'iplik_tarihi': iplikTarihi?.toIso8601String(),
      'firma_id': firmaId,
    };
  }

  // Müşteri bilgisini getiren getter
  String get musteriInfo {
    if (musteriSirket != null && musteriSirket!.isNotEmpty) {
      return musteriSirket!;
    }
    final String ad = musteriAd ?? '';
    final String soyad = musteriSoyad ?? '';
    return '$ad $soyad'.trim();
  }

  // Müşteri var mı kontrolü
  bool get musteriVar => musteriId != null;

  // Sipariş durumu
  String get siparisDurumu {
    if (tamamlandi == true) return 'Tamamlandı';
    
    // Üretim aşamalarına göre durum belirleme
    if (iplikGeldi != true) return 'İplik Bekleniyor';
    if (orguFirma == null || (orguFirma is List && (orguFirma as List).isEmpty)) {
      return 'Örgü Bekliyor';
    }
    if (konfeksiyonFirma == null || (konfeksiyonFirma is List && (konfeksiyonFirma as List).isEmpty)) {
      return 'Konfeksiyon Bekliyor';
    }
    if (utuFirma == null || (utuFirma is List && (utuFirma as List).isEmpty)) {
      return 'Ütü Bekliyor';
    }
    return 'Üretimde';
  }

  // Termin durumu rengi
  Color get terminRengi {
    if (termin == null) return Colors.grey.shade100;
    
    final now = DateTime.now();
    final kalanGun = termin!.difference(now).inDays;
    
    if (kalanGun < 0) {
      return Colors.red.shade100; // Termin geçmiş
    } else if (kalanGun <= 7) {
      return Colors.orange.shade100; // Son 7 gün
    } else if (kalanGun <= 15) {
      return Colors.yellow.shade100; // Son 15 gün
    }
    return Colors.green.shade50; // Normal durum
  }

  // Kalan gün sayısı
  String get kalanGunText {
    if (termin == null) return 'Termin yok';
    
    final now = DateTime.now();
    final kalanGun = termin!.difference(now).inDays;
    
    if (kalanGun < 0) {
      return '${kalanGun.abs()} gün geçikme';
    } else if (kalanGun == 0) {
      return 'Bugün teslim';
    } else {
      return '$kalanGun gün kaldı';
    }
  }

  // Toplam beden adedi hesaplama
  int get toplamBedenAdet {
    if (bedenler == null) return 0;
    int toplam = 0;
    bedenler!.forEach((key, value) {
      if (value is int) toplam += value;
      if (value is String) toplam += int.tryParse(value) ?? 0;
    });
    return toplam;
  }

  // Kopya oluşturma
  SiparisModel copyWith({
    int? id,
    String? marka,
    String? itemNo,
    String? renk,
    String? urunCinsi,
    String? iplikCinsi,
    String? uretici,
    Map<String, dynamic>? bedenler,
    DateTime? termin,
    bool? tamamlandi,
    int? musteriId,
    String? musteriAd,
    String? musteriSoyad,
    String? musteriSirket,
    String? musteriTipi,
    DateTime? siparisTarihi,
    String? siparisNotu,
    double? toplamMaliyet,
    String? kur,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? uretimDali,
    String? urunTipi,
    Map<String, dynamic>? dalOzelAlanlar,
    dynamic orguFirma,
    dynamic konfeksiyonFirma,
    dynamic utuFirma,
    int? yuklenenAdet,
    bool? iplikGeldi,
    DateTime? iplikTarihi,
    String? firmaId,
  }) {
    return SiparisModel(
      id: id ?? this.id,
      marka: marka ?? this.marka,
      itemNo: itemNo ?? this.itemNo,
      renk: renk ?? this.renk,
      urunCinsi: urunCinsi ?? this.urunCinsi,
      iplikCinsi: iplikCinsi ?? this.iplikCinsi,
      uretici: uretici ?? this.uretici,
      bedenler: bedenler ?? this.bedenler,
      termin: termin ?? this.termin,
      tamamlandi: tamamlandi ?? this.tamamlandi,
      musteriId: musteriId ?? this.musteriId,
      musteriAd: musteriAd ?? this.musteriAd,
      musteriSoyad: musteriSoyad ?? this.musteriSoyad,
      musteriSirket: musteriSirket ?? this.musteriSirket,
      musteriTipi: musteriTipi ?? this.musteriTipi,
      siparisTarihi: siparisTarihi ?? this.siparisTarihi,
      siparisNotu: siparisNotu ?? this.siparisNotu,
      toplamMaliyet: toplamMaliyet ?? this.toplamMaliyet,
      kur: kur ?? this.kur,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      uretimDali: uretimDali ?? this.uretimDali,
      urunTipi: urunTipi ?? this.urunTipi,
      dalOzelAlanlar: dalOzelAlanlar ?? this.dalOzelAlanlar,
      orguFirma: orguFirma ?? this.orguFirma,
      konfeksiyonFirma: konfeksiyonFirma ?? this.konfeksiyonFirma,
      utuFirma: utuFirma ?? this.utuFirma,
      yuklenenAdet: yuklenenAdet ?? this.yuklenenAdet,
      iplikGeldi: iplikGeldi ?? this.iplikGeldi,
      iplikTarihi: iplikTarihi ?? this.iplikTarihi,
      firmaId: firmaId ?? this.firmaId,
    );
  }
}

// Müşteri istatistikleri modeli
class MusteriIstatistikModel {
  final int toplamSiparis;
  final int aktifSiparis;
  final int tamamlananSiparis;
  final double toplamCiro;
  final double ortalamaSiparisDegeri;
  final DateTime? ilkSiparis;
  final DateTime? sonSiparis;
  final String? enCokSiparisVerilenMarka;

  MusteriIstatistikModel({
    required this.toplamSiparis,
    required this.aktifSiparis,
    required this.tamamlananSiparis,
    required this.toplamCiro,
    required this.ortalamaSiparisDegeri,
    this.ilkSiparis,
    this.sonSiparis,
    this.enCokSiparisVerilenMarka,
  });

  factory MusteriIstatistikModel.fromJson(Map<String, dynamic> json) {
    return MusteriIstatistikModel(
      toplamSiparis: json['toplam_siparis'] ?? 0,
      aktifSiparis: json['aktif_siparis'] ?? 0,
      tamamlananSiparis: json['tamamlanan_siparis'] ?? 0,
      toplamCiro: (json['toplam_ciro'] ?? 0).toDouble(),
      ortalamaSiparisDegeri: (json['ortalama_siparis_degeri'] ?? 0).toDouble(),
      ilkSiparis: json['ilk_siparis'] != null ? DateTime.tryParse(json['ilk_siparis']) : null,
      sonSiparis: json['son_siparis'] != null ? DateTime.tryParse(json['son_siparis']) : null,
      enCokSiparisVerilenMarka: json['en_cok_siparis_verilen_marka'],
    );
  }
}
