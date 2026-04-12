/// Beden bazl� �retim takip modelleri

class BedenTanimi {
  final int id;
  final String bedenKodu;
  final String? bedenAdi;
  final int siraNo;
  final bool aktif;
  final String? firmaId;

  BedenTanimi({
    required this.id,
    required this.bedenKodu,
    this.bedenAdi,
    this.siraNo = 0,
    this.aktif = true,
    this.firmaId,
  });

  factory BedenTanimi.fromJson(Map<String, dynamic> json) => BedenTanimi.fromMap(json);

  factory BedenTanimi.fromMap(Map<String, dynamic> map) {
    return BedenTanimi(
      id: map['id'] ?? 0,
      bedenKodu: map['beden_kodu'] ?? '',
      bedenAdi: map['beden_adi'],
      siraNo: map['sira_no'] ?? 0,
      aktif: map['aktif'] ?? true,
      firmaId: map['firma_id'],
    );
  }
}

class ModelBedenDagilimi {
  final int? id;
  final String modelId;
  final String bedenKodu;
  int siparisAdedi;
  final String? firmaId;

  ModelBedenDagilimi({
    this.id,
    required this.modelId,
    required this.bedenKodu,
    required this.siparisAdedi,
    this.firmaId,
  });

  factory ModelBedenDagilimi.fromJson(Map<String, dynamic> json) => ModelBedenDagilimi.fromMap(json);

  factory ModelBedenDagilimi.fromMap(Map<String, dynamic> map) {
    return ModelBedenDagilimi(
      id: map['id'],
      modelId: map['model_id']?.toString() ?? '',
      bedenKodu: map['beden_kodu'] ?? '',
      siparisAdedi: map['siparis_adedi'] ?? 0,
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'model_id': modelId,
      'beden_kodu': bedenKodu,
      'siparis_adedi': siparisAdedi,
      'firma_id': firmaId,
    };
  }
}

class BedenUretimTakip {
  final int? id;
  final int atamaId;
  final String modelId;
  final String bedenKodu;
  int hedefAdet;
  int uretilenAdet;
  int kabulEdilenAdet;
  int fireAdet;
  final DateTime? kayitTarihi;
  DateTime? guncellemeTarihi;
  final String? firmaId;

  BedenUretimTakip({
    this.id,
    required this.atamaId,
    required this.modelId,
    required this.bedenKodu,
    this.hedefAdet = 0,
    this.uretilenAdet = 0,
    this.kabulEdilenAdet = 0,
    this.fireAdet = 0,
    this.kayitTarihi,
    this.guncellemeTarihi,
    this.firmaId,
  });

  factory BedenUretimTakip.fromJson(Map<String, dynamic> json) => BedenUretimTakip.fromMap(json);

  factory BedenUretimTakip.fromMap(Map<String, dynamic> map) {
    return BedenUretimTakip(
      id: map['id'],
      atamaId: map['atama_id'] ?? 0,
      modelId: map['model_id']?.toString() ?? '',
      bedenKodu: map['beden_kodu'] ?? '',
      hedefAdet: map['hedef_adet'] ?? 0,
      uretilenAdet: map['uretilen_adet'] ?? 0,
      kabulEdilenAdet: map['kabul_edilen_adet'] ?? 0,
      fireAdet: map['fire_adet'] ?? 0,
      kayitTarihi: map['kayit_tarihi'] != null 
          ? DateTime.tryParse(map['kayit_tarihi'].toString()) 
          : null,
      guncellemeTarihi: map['guncelleme_tarihi'] != null 
          ? DateTime.tryParse(map['guncelleme_tarihi'].toString()) 
          : null,
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'atama_id': atamaId,
      'model_id': modelId,
      'beden_kodu': bedenKodu,
      'hedef_adet': hedefAdet,
      'uretilen_adet': uretilenAdet,
      'kabul_edilen_adet': kabulEdilenAdet,
      'fire_adet': fireAdet,
      'firma_id': firmaId,
    };
  }

  int get kalanAdet => hedefAdet - uretilenAdet;
  double get tamamlanmaOrani => hedefAdet > 0 ? (uretilenAdet / hedefAdet) * 100 : 0;
}

/// Model i�in t�m beden verilerini tutan �zet s�n�f
class ModelBedenOzet {
  final String modelId;
  final String? itemNo;
  final String? marka;
  final String? renk;
  final List<BedenDetay> bedenler;

  ModelBedenOzet({
    required this.modelId,
    this.itemNo,
    this.marka,
    this.renk,
    required this.bedenler,
  });

  int get toplamSiparis => bedenler.fold(0, (sum, b) => sum + b.siparisAdedi);
  int get toplamDokumaUretilen => bedenler.fold(0, (sum, b) => sum + b.dokumaUretilen);
  int get toplamKonfeksiyonUretilen => bedenler.fold(0, (sum, b) => sum + b.konfeksiyonUretilen);
  int get toplamYikamaUretilen => bedenler.fold(0, (sum, b) => sum + b.yikamaUretilen);
  int get toplamUtuUretilen => bedenler.fold(0, (sum, b) => sum + b.utuUretilen);
  int get toplamIlikDugmeUretilen => bedenler.fold(0, (sum, b) => sum + b.ilikDugmeUretilen);
  int get toplamFire => bedenler.fold(0, (sum, b) => sum + b.toplamFire);
}

class BedenDetay {
  final String bedenKodu;
  final int siparisAdedi;
  final int dokumaUretilen;
  final int konfeksiyonUretilen;
  final int yikamaUretilen;
  final int utuUretilen;
  final int ilikDugmeUretilen;
  final int toplamFire;

  BedenDetay({
    required this.bedenKodu,
    this.siparisAdedi = 0,
    this.dokumaUretilen = 0,
    this.konfeksiyonUretilen = 0,
    this.yikamaUretilen = 0,
    this.utuUretilen = 0,
    this.ilikDugmeUretilen = 0,
    this.toplamFire = 0,
  });

  factory BedenDetay.fromJson(Map<String, dynamic> json) => BedenDetay.fromMap(json);

  factory BedenDetay.fromMap(Map<String, dynamic> map) {
    return BedenDetay(
      bedenKodu: map['beden_kodu'] ?? '',
      siparisAdedi: map['siparis_adedi'] ?? 0,
      dokumaUretilen: map['dokuma_uretilen'] ?? 0,
      konfeksiyonUretilen: map['konfeksiyon_uretilen'] ?? 0,
      yikamaUretilen: map['yikama_uretilen'] ?? 0,
      utuUretilen: map['utu_uretilen'] ?? 0,
      ilikDugmeUretilen: map['ilik_dugme_uretilen'] ?? 0,
      toplamFire: map['toplam_fire'] ?? 0,
    );
  }

  int get dokumaKalan => siparisAdedi - dokumaUretilen;
  int get konfeksiyonBekleyen => dokumaUretilen - konfeksiyonUretilen;
}
