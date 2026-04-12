/// Abonelik planı modeli (abonelik_planlari tablosu).
class AbonelikPlani {
  final String id;
  final String planKodu;
  final String planAdi;
  final String? aciklama;
  final double aylikUcret;
  final double? yillikUcret;
  final int? maxKullanici;
  final int? maxModul;
  final List<String> dahilModuller;
  final Map<String, dynamic> ozellikler;
  final bool aktif;
  final int siraNo;

  const AbonelikPlani({
    required this.id,
    required this.planKodu,
    required this.planAdi,
    this.aciklama,
    required this.aylikUcret,
    this.yillikUcret,
    this.maxKullanici,
    this.maxModul,
    this.dahilModuller = const [],
    this.ozellikler = const {},
    this.aktif = true,
    this.siraNo = 0,
  });

  factory AbonelikPlani.fromJson(Map<String, dynamic> json) {
    final modullerRaw = json['dahil_moduller'];
    final moduller = modullerRaw is List
        ? modullerRaw.map((e) => e.toString()).toList()
        : <String>[];

    return AbonelikPlani(
      id: json['id'] as String,
      planKodu: json['plan_kodu'] as String,
      planAdi: json['plan_adi'] as String,
      aciklama: json['aciklama'] as String?,
      aylikUcret: (json['aylik_ucret'] as num).toDouble(),
      yillikUcret: (json['yillik_ucret'] as num?)?.toDouble(),
      maxKullanici: json['max_kullanici'] as int?,
      maxModul: json['max_modul'] as int?,
      dahilModuller: moduller,
      ozellikler: json['ozellikler'] is Map
          ? Map<String, dynamic>.from(json['ozellikler'] as Map)
          : {},
      aktif: json['aktif'] as bool? ?? true,
      siraNo: json['sira_no'] as int? ?? 0,
    );
  }

  /// Enterprise planı mı (özel fiyatlandırma)?
  bool get enterpriseMi => planKodu == 'enterprise';

  /// Deneme planı mı?
  bool get denemeMi => planKodu == 'deneme';

  /// Yıllık indirim yüzdesi.
  double get yillikIndirimYuzdesi {
    if (yillikUcret == null || aylikUcret <= 0) return 0;
    final yillikNormal = aylikUcret * 12;
    return ((yillikNormal - yillikUcret!) / yillikNormal * 100);
  }
}

/// Firma abonelik durumu.
enum AbonelikDurum {
  aktif,
  pasif,
  deneme,
  iptal,
  odemeBekleniyor;

  static AbonelikDurum fromString(String? value) {
    switch (value) {
      case 'aktif':
        return AbonelikDurum.aktif;
      case 'pasif':
        return AbonelikDurum.pasif;
      case 'deneme':
        return AbonelikDurum.deneme;
      case 'iptal':
        return AbonelikDurum.iptal;
      case 'odeme_bekleniyor':
        return AbonelikDurum.odemeBekleniyor;
      default:
        return AbonelikDurum.deneme;
    }
  }

  String get dpiValue {
    switch (this) {
      case AbonelikDurum.aktif:
        return 'aktif';
      case AbonelikDurum.pasif:
        return 'pasif';
      case AbonelikDurum.deneme:
        return 'deneme';
      case AbonelikDurum.iptal:
        return 'iptal';
      case AbonelikDurum.odemeBekleniyor:
        return 'odeme_bekleniyor';
    }
  }

  String get etiket {
    switch (this) {
      case AbonelikDurum.aktif:
        return 'Aktif';
      case AbonelikDurum.pasif:
        return 'Pasif';
      case AbonelikDurum.deneme:
        return 'Deneme';
      case AbonelikDurum.iptal:
        return 'İptal Edildi';
      case AbonelikDurum.odemeBekleniyor:
        return 'Ödeme Bekleniyor';
    }
  }
}

/// Firma abonelik modeli (firma_abonelikleri tablosu).
class FirmaAbonelik {
  final String id;
  final String firmaId;
  final String planId;
  final AbonelikDurum durum;
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final DateTime? denemeBitis;
  final String odemePeriyodu;
  final DateTime? sonOdemeTarihi;
  final DateTime? sonrakiOdemeTarihi;
  final DateTime? iptalTarihi;
  final AbonelikPlani? plan;

  const FirmaAbonelik({
    required this.id,
    required this.firmaId,
    required this.planId,
    required this.durum,
    this.baslangicTarihi,
    this.bitisTarihi,
    this.denemeBitis,
    this.odemePeriyodu = 'aylik',
    this.sonOdemeTarihi,
    this.sonrakiOdemeTarihi,
    this.iptalTarihi,
    this.plan,
  });

  factory FirmaAbonelik.fromJson(Map<String, dynamic> json) {
    return FirmaAbonelik(
      id: json['id'] as String,
      firmaId: json['firma_id'] as String,
      planId: json['plan_id'] as String,
      durum: AbonelikDurum.fromString(json['durum'] as String?),
      baslangicTarihi: _parseDate(json['baslangic_tarihi']),
      bitisTarihi: _parseDate(json['bitis_tarihi']),
      denemeBitis: _parseDate(json['deneme_bitis']),
      odemePeriyodu: json['odeme_periyodu'] as String? ?? 'aylik',
      sonOdemeTarihi: _parseDate(json['son_odeme_tarihi']),
      sonrakiOdemeTarihi: _parseDate(json['sonraki_odeme_tarihi']),
      iptalTarihi: _parseDate(json['iptal_tarihi']),
      plan: json['abonelik_planlari'] != null
          ? AbonelikPlani.fromJson(
              json['abonelik_planlari'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Deneme süresi dolmuş mu?
  bool get denemeSuresiDolmusMu {
    if (durum != AbonelikDurum.deneme) return false;
    if (denemeBitis == null) return false;
    return DateTime.now().isAfter(denemeBitis!);
  }

  /// Abonelik aktif veya deneme süresi devam ediyor mu?
  bool get gecerliMi {
    if (durum == AbonelikDurum.aktif) return true;
    if (durum == AbonelikDurum.deneme && !denemeSuresiDolmusMu) return true;
    return false;
  }

  /// Deneme süresinin bitimine kalan gün.
  int get kalanDenemeGunu {
    if (denemeBitis == null) return 0;
    final kalan = denemeBitis!.difference(DateTime.now()).inDays;
    return kalan > 0 ? kalan : 0;
  }
}

/// Abonelik ödemesi modeli (abonelik_odemeleri tablosu).
class AbonelikOdeme {
  final String id;
  final String firmaId;
  final String abonelikId;
  final double tutar;
  final String paraBirimi;
  final DateTime? odemeTarihi;
  final String? odemeYontemi;
  final String? odemeReferans;
  final String durum;
  final String? faturaNo;

  const AbonelikOdeme({
    required this.id,
    required this.firmaId,
    required this.abonelikId,
    required this.tutar,
    this.paraBirimi = 'TRY',
    this.odemeTarihi,
    this.odemeYontemi,
    this.odemeReferans,
    this.durum = 'basarili',
    this.faturaNo,
  });

  factory AbonelikOdeme.fromJson(Map<String, dynamic> json) {
    return AbonelikOdeme(
      id: json['id'] as String,
      firmaId: json['firma_id'] as String,
      abonelikId: json['abonelik_id'] as String,
      tutar: (json['tutar'] as num).toDouble(),
      paraBirimi: json['para_birimi'] as String? ?? 'TRY',
      odemeTarihi: _parseDate(json['odeme_tarihi']),
      odemeYontemi: json['odeme_yontemi'] as String?,
      odemeReferans: json['odeme_referans'] as String?,
      durum: json['durum'] as String? ?? 'basarili',
      faturaNo: json['fatura_no'] as String?,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
