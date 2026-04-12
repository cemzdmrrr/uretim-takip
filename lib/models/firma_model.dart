/// Firma (Tenant) modeli.
///
/// SaaS multi-tenant yapısında her firmayı temsil eder.
class FirmaModel {
  final String id;
  final String firmaAdi;
  final String firmaKodu;
  final String? vergiNo;
  final String? vergiDairesi;
  final String? sicilNo;
  final String? sgkSicilNo;
  final String? adres;
  final String? telefon;
  final String? email;
  final String? web;
  final String? logoUrl;
  final String? yetkili;
  final String? iban;
  final String? banka;
  final String sektor;
  final String? faaliyet;
  final int? kurulusYili;
  final bool aktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FirmaModel({
    required this.id,
    required this.firmaAdi,
    required this.firmaKodu,
    this.vergiNo,
    this.vergiDairesi,
    this.sicilNo,
    this.sgkSicilNo,
    this.adres,
    this.telefon,
    this.email,
    this.web,
    this.logoUrl,
    this.yetkili,
    this.iban,
    this.banka,
    this.sektor = 'tekstil',
    this.faaliyet,
    this.kurulusYili,
    this.aktif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FirmaModel.fromJson(Map<String, dynamic> json) {
    return FirmaModel(
      id: json['id'] as String,
      firmaAdi: json['firma_adi'] as String? ?? '',
      firmaKodu: json['firma_kodu'] as String? ?? '',
      vergiNo: json['vergi_no'] as String?,
      vergiDairesi: json['vergi_dairesi'] as String?,
      sicilNo: json['sicil_no'] as String?,
      sgkSicilNo: json['sgk_sicil_no'] as String?,
      adres: json['adres'] as String?,
      telefon: json['telefon'] as String?,
      email: json['email'] as String?,
      web: json['web'] as String?,
      logoUrl: json['logo_url'] as String?,
      yetkili: json['yetkili'] as String?,
      iban: json['iban'] as String?,
      banka: json['banka'] as String?,
      sektor: json['sektor'] as String? ?? 'tekstil',
      faaliyet: json['faaliyet'] as String?,
      kurulusYili: json['kurulus_yili'] as int?,
      aktif: json['aktif'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firma_adi': firmaAdi,
      'firma_kodu': firmaKodu,
      if (vergiNo != null) 'vergi_no': vergiNo,
      if (vergiDairesi != null) 'vergi_dairesi': vergiDairesi,
      if (sicilNo != null) 'sicil_no': sicilNo,
      if (sgkSicilNo != null) 'sgk_sicil_no': sgkSicilNo,
      if (adres != null) 'adres': adres,
      if (telefon != null) 'telefon': telefon,
      if (email != null) 'email': email,
      if (web != null) 'web': web,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (yetkili != null) 'yetkili': yetkili,
      if (iban != null) 'iban': iban,
      if (banka != null) 'banka': banka,
      'sektor': sektor,
      if (faaliyet != null) 'faaliyet': faaliyet,
      if (kurulusYili != null) 'kurulus_yili': kurulusYili,
      'aktif': aktif,
    };
  }

  FirmaModel copyWith({
    String? id,
    String? firmaAdi,
    String? firmaKodu,
    String? vergiNo,
    String? vergiDairesi,
    String? sicilNo,
    String? sgkSicilNo,
    String? adres,
    String? telefon,
    String? email,
    String? web,
    String? logoUrl,
    String? yetkili,
    String? iban,
    String? banka,
    String? sektor,
    String? faaliyet,
    int? kurulusYili,
    bool? aktif,
  }) {
    return FirmaModel(
      id: id ?? this.id,
      firmaAdi: firmaAdi ?? this.firmaAdi,
      firmaKodu: firmaKodu ?? this.firmaKodu,
      vergiNo: vergiNo ?? this.vergiNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      sicilNo: sicilNo ?? this.sicilNo,
      sgkSicilNo: sgkSicilNo ?? this.sgkSicilNo,
      adres: adres ?? this.adres,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      web: web ?? this.web,
      logoUrl: logoUrl ?? this.logoUrl,
      yetkili: yetkili ?? this.yetkili,
      iban: iban ?? this.iban,
      banka: banka ?? this.banka,
      sektor: sektor ?? this.sektor,
      faaliyet: faaliyet ?? this.faaliyet,
      kurulusYili: kurulusYili ?? this.kurulusYili,
      aktif: aktif ?? this.aktif,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Firma-Kullanıcı ilişki modeli
class FirmaKullaniciModel {
  final String id;
  final String firmaId;
  final String userId;
  final String rol;
  final List<String> yetkiGrubu;
  final bool aktif;
  final DateTime? davetTarihi;
  final DateTime? katilimTarihi;

  // Join'den gelen ek bilgiler
  final String? firmaAdi;
  final String? kullaniciEmail;

  FirmaKullaniciModel({
    required this.id,
    required this.firmaId,
    required this.userId,
    required this.rol,
    this.yetkiGrubu = const [],
    this.aktif = true,
    this.davetTarihi,
    this.katilimTarihi,
    this.firmaAdi,
    this.kullaniciEmail,
  });

  factory FirmaKullaniciModel.fromJson(Map<String, dynamic> json) {
    List<String> yetkiler = [];
    if (json['yetki_grubu'] != null) {
      if (json['yetki_grubu'] is List) {
        yetkiler = (json['yetki_grubu'] as List).cast<String>();
      }
    }

    return FirmaKullaniciModel(
      id: json['id'] as String,
      firmaId: json['firma_id'] as String,
      userId: json['user_id'] as String,
      rol: json['rol'] as String? ?? 'kullanici',
      yetkiGrubu: yetkiler,
      aktif: json['aktif'] as bool? ?? true,
      davetTarihi: json['davet_tarihi'] != null
          ? DateTime.tryParse(json['davet_tarihi'].toString())
          : null,
      katilimTarihi: json['katilim_tarihi'] != null
          ? DateTime.tryParse(json['katilim_tarihi'].toString())
          : null,
      firmaAdi: json['firmalar'] != null
          ? (json['firmalar'] as Map<String, dynamic>)['firma_adi'] as String?
          : null,
      kullaniciEmail: json['kullanici_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firma_id': firmaId,
      'user_id': userId,
      'rol': rol,
      'yetki_grubu': yetkiGrubu,
      'aktif': aktif,
    };
  }

  bool get isFirmaSahibi => rol == 'firma_sahibi';
  bool get isFirmaAdmin => rol == 'firma_admin' || rol == 'firma_sahibi';
  bool get isYonetici => isFirmaAdmin || rol == 'yonetici';
}

/// Firma davet modeli
class FirmaDavetModel {
  final String id;
  final String firmaId;
  final String davetEdenId;
  final String email;
  final String rol;
  final String davetKodu;
  final String durum;
  final DateTime? createdAt;
  final DateTime? gecerlilikTarihi;

  FirmaDavetModel({
    required this.id,
    required this.firmaId,
    required this.davetEdenId,
    required this.email,
    this.rol = 'kullanici',
    required this.davetKodu,
    this.durum = 'beklemede',
    this.createdAt,
    this.gecerlilikTarihi,
  });

  factory FirmaDavetModel.fromJson(Map<String, dynamic> json) {
    return FirmaDavetModel(
      id: json['id'] as String,
      firmaId: json['firma_id'] as String,
      davetEdenId: json['davet_eden_id'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String? ?? 'kullanici',
      davetKodu: json['davet_kodu'] as String,
      durum: json['durum'] as String? ?? 'beklemede',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      gecerlilikTarihi: json['gecerlilik_tarihi'] != null
          ? DateTime.tryParse(json['gecerlilik_tarihi'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firma_id': firmaId,
      'davet_eden_id': davetEdenId,
      'email': email,
      'rol': rol,
      'davet_kodu': davetKodu,
    };
  }

  bool get suresiGecmis =>
      gecerlilikTarihi != null && DateTime.now().isAfter(gecerlilikTarihi!);
}

/// Modül tanım modeli
class ModulTanimModel {
  final String id;
  final String modulKodu;
  final String modulAdi;
  final String? aciklama;
  final String kategori;
  final String? ikon;
  final int siraNo;
  final List<String> bagimliliklar;
  final bool aktif;

  ModulTanimModel({
    required this.id,
    required this.modulKodu,
    required this.modulAdi,
    this.aciklama,
    required this.kategori,
    this.ikon,
    this.siraNo = 0,
    this.bagimliliklar = const [],
    this.aktif = true,
  });

  factory ModulTanimModel.fromJson(Map<String, dynamic> json) {
    List<String> deps = [];
    if (json['bagimliliklar'] != null && json['bagimliliklar'] is List) {
      deps = (json['bagimliliklar'] as List).cast<String>();
    }

    return ModulTanimModel(
      id: json['id'] as String,
      modulKodu: json['modul_kodu'] as String,
      modulAdi: json['modul_adi'] as String,
      aciklama: json['aciklama'] as String?,
      kategori: json['kategori'] as String? ?? '',
      ikon: json['ikon'] as String?,
      siraNo: json['sira_no'] as int? ?? 0,
      bagimliliklar: deps,
      aktif: json['aktif'] as bool? ?? true,
    );
  }
}

/// Üretim modülü (tekstil dalı) modeli
class UretimModulModel {
  final String id;
  final String modulKodu;
  final String modulAdi;
  final String tekstilDali;
  final String? aciklama;
  final List<UretimAsamaTanim> uretimAsamalari;
  final List<String> varsayilanAsamalar;
  final bool aktif;

  UretimModulModel({
    required this.id,
    required this.modulKodu,
    required this.modulAdi,
    required this.tekstilDali,
    this.aciklama,
    this.uretimAsamalari = const [],
    this.varsayilanAsamalar = const [],
    this.aktif = true,
  });

  factory UretimModulModel.fromJson(Map<String, dynamic> json) {
    List<UretimAsamaTanim> asamalar = [];
    if (json['uretim_asamalari'] != null && json['uretim_asamalari'] is List) {
      asamalar = (json['uretim_asamalari'] as List)
          .map((e) => UretimAsamaTanim.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<String> varsayilan = [];
    if (json['varsayilan_asamalar'] != null &&
        json['varsayilan_asamalar'] is List) {
      varsayilan = (json['varsayilan_asamalar'] as List).cast<String>();
    }

    return UretimModulModel(
      id: json['id'] as String,
      modulKodu: json['modul_kodu'] as String,
      modulAdi: json['modul_adi'] as String,
      tekstilDali: json['tekstil_dali'] as String,
      aciklama: json['aciklama'] as String?,
      uretimAsamalari: asamalar,
      varsayilanAsamalar: varsayilan,
      aktif: json['aktif'] as bool? ?? true,
    );
  }
}

/// Üretim aşaması tanımı (JSON içinden parse edilen)
class UretimAsamaTanim {
  final String kod;
  final String ad;
  final int sira;
  final bool zorunlu;

  UretimAsamaTanim({
    required this.kod,
    required this.ad,
    required this.sira,
    this.zorunlu = false,
  });

  factory UretimAsamaTanim.fromJson(Map<String, dynamic> json) {
    return UretimAsamaTanim(
      kod: json['kod'] as String,
      ad: json['ad'] as String,
      sira: json['sira'] as int? ?? 0,
      zorunlu: json['zorunlu'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kod': kod,
      'ad': ad,
      'sira': sira,
      'zorunlu': zorunlu,
    };
  }
}

/// Abonelik planı modeli
class AbonelikPlanModel {
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

  AbonelikPlanModel({
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

  factory AbonelikPlanModel.fromJson(Map<String, dynamic> json) {
    List<String> moduller = [];
    if (json['dahil_moduller'] != null && json['dahil_moduller'] is List) {
      moduller = (json['dahil_moduller'] as List).cast<String>();
    }

    return AbonelikPlanModel(
      id: json['id'] as String,
      planKodu: json['plan_kodu'] as String,
      planAdi: json['plan_adi'] as String,
      aciklama: json['aciklama'] as String?,
      aylikUcret: (json['aylik_ucret'] as num?)?.toDouble() ?? 0,
      yillikUcret: (json['yillik_ucret'] as num?)?.toDouble(),
      maxKullanici: json['max_kullanici'] as int?,
      maxModul: json['max_modul'] as int?,
      dahilModuller: moduller,
      ozellikler: json['ozellikler'] as Map<String, dynamic>? ?? {},
      aktif: json['aktif'] as bool? ?? true,
      siraNo: json['sira_no'] as int? ?? 0,
    );
  }

  bool get sinirliKullanici => maxKullanici != null;
  bool get sinirliModul => maxModul != null;
  bool get ucretsiz => aylikUcret == 0;
}

/// Firma abonelik durumu modeli
class FirmaAbonelikModel {
  final String id;
  final String firmaId;
  final String planId;
  final String durum;
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final DateTime? denemeBitis;
  final String odemePeriyodu;
  final DateTime? sonOdemeTarihi;
  final DateTime? sonrakiOdemeTarihi;
  final DateTime? iptalTarihi;

  // Join'den gelen
  final AbonelikPlanModel? plan;

  FirmaAbonelikModel({
    required this.id,
    required this.firmaId,
    required this.planId,
    this.durum = 'deneme',
    this.baslangicTarihi,
    this.bitisTarihi,
    this.denemeBitis,
    this.odemePeriyodu = 'aylik',
    this.sonOdemeTarihi,
    this.sonrakiOdemeTarihi,
    this.iptalTarihi,
    this.plan,
  });

  factory FirmaAbonelikModel.fromJson(Map<String, dynamic> json) {
    return FirmaAbonelikModel(
      id: json['id'] as String,
      firmaId: json['firma_id'] as String,
      planId: json['plan_id'] as String,
      durum: json['durum'] as String? ?? 'deneme',
      baslangicTarihi: json['baslangic_tarihi'] != null
          ? DateTime.tryParse(json['baslangic_tarihi'].toString())
          : null,
      bitisTarihi: json['bitis_tarihi'] != null
          ? DateTime.tryParse(json['bitis_tarihi'].toString())
          : null,
      denemeBitis: json['deneme_bitis'] != null
          ? DateTime.tryParse(json['deneme_bitis'].toString())
          : null,
      odemePeriyodu: json['odeme_periyodu'] as String? ?? 'aylik',
      sonOdemeTarihi: json['son_odeme_tarihi'] != null
          ? DateTime.tryParse(json['son_odeme_tarihi'].toString())
          : null,
      sonrakiOdemeTarihi: json['sonraki_odeme_tarihi'] != null
          ? DateTime.tryParse(json['sonraki_odeme_tarihi'].toString())
          : null,
      iptalTarihi: json['iptal_tarihi'] != null
          ? DateTime.tryParse(json['iptal_tarihi'].toString())
          : null,
      plan: json['abonelik_planlari'] != null
          ? AbonelikPlanModel.fromJson(
              json['abonelik_planlari'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get aktif => durum == 'aktif' || durum == 'deneme';
  bool get denemeSurecinde => durum == 'deneme';
  bool get iptalEdilmis => durum == 'iptal';

  bool get denemeSuresiDolmus =>
      denemeSurecinde &&
      denemeBitis != null &&
      DateTime.now().isAfter(denemeBitis!);
}
