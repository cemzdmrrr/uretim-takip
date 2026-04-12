class KasaBankaHareket {
  final String id;
  final String kasaBankaId;
  final String hareketTipi; // 'giris', 'cikis', 'transfer_giden', 'transfer_gelen'
  final double tutar;
  final String paraBirimi;
  final String? aciklama;
  final String? kategori; // 'fatura_odeme', 'nakit_giris', 'bank_transfer', 'operasyonel', 'diger'
  final String? faturaId; // Fatura ödemesi ise
  final String? transferKasaBankaId; // Transfer işlemi ise hedef hesap
  final String? referansNo;
  final DateTime islemTarihi;
  final DateTime olusturmaTarihi;
  final String olusturanKullanici;
  final bool onaylanmisMi;
  final String? onaylayanKullanici;
  final DateTime? onaylamaTarihi;
  final String? notlar;

  // İlişkili objeler
  final String? kasaBankaAdi;
  final String? kasaBankaTuru;
  final String? faturaNo;
  final String? musteriAdi;
  final String? tedarikciAdi;
  final String? firmaId;

  KasaBankaHareket({
    required this.id,
    required this.kasaBankaId,
    required this.hareketTipi,
    required this.tutar,
    required this.paraBirimi,
    this.aciklama,
    this.kategori,
    this.faturaId,
    this.transferKasaBankaId,
    this.referansNo,
    required this.islemTarihi,
    required this.olusturmaTarihi,
    required this.olusturanKullanici,
    this.onaylanmisMi = false,
    this.onaylayanKullanici,
    this.onaylamaTarihi,
    this.notlar,
    this.kasaBankaAdi,
    this.kasaBankaTuru,
    this.faturaNo,
    this.musteriAdi,
    this.tedarikciAdi,
    this.firmaId,
  });

  factory KasaBankaHareket.fromJson(Map<String, dynamic> json) {
    return KasaBankaHareket(
      id: json['id'] ?? '',
      kasaBankaId: json['kasa_banka_id'] ?? '',
      hareketTipi: json['hareket_tipi'] ?? '',
      tutar: (json['tutar'] ?? 0).toDouble(),
      paraBirimi: json['doviz_turu'] ?? 'TRY',
      aciklama: json['aciklama'],
      kategori: json['kategori'],
      faturaId: json['fatura_id'],
      transferKasaBankaId: json['hedef_kasa_banka_id']?.toString(),
      referansNo: json['referans_no'],
      islemTarihi: DateTime.parse(json['islem_tarihi']),
      olusturmaTarihi: DateTime.parse(json['created_at']),
      olusturanKullanici: json['created_by'] ?? '',
      onaylanmisMi: json['onaylanmis_mi'] ?? false,
      onaylayanKullanici: json['onaylayan_kullanici'],
      onaylamaTarihi: json['onaylama_tarihi'] != null 
          ? DateTime.parse(json['onaylama_tarihi']) 
          : null,
      notlar: json['notlar'],
      kasaBankaAdi: json['kasa_banka_adi'],
      kasaBankaTuru: json['kasa_banka_turu'],
      faturaNo: json['fatura_no'],
      musteriAdi: json['musteri_adi'],
      tedarikciAdi: json['tedarikci_adi'],
      firmaId: json['firma_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kasa_banka_id': kasaBankaId,
      'hareket_tipi': hareketTipi,
      'tutar': tutar,
      'doviz_turu': paraBirimi,
      'aciklama': aciklama,
      'kategori': kategori,
      'fatura_id': faturaId,
      'hedef_kasa_banka_id': transferKasaBankaId != null ? int.tryParse(transferKasaBankaId!) : null,
      'referans_no': referansNo,
      'islem_tarihi': islemTarihi.toIso8601String(),
      'created_at': olusturmaTarihi.toIso8601String(),
      'created_by': olusturanKullanici,
      'onaylanmis_mi': onaylanmisMi,
      'onaylayan_kullanici': onaylayanKullanici,
      'onaylama_tarihi': onaylamaTarihi?.toIso8601String(),
      'notlar': notlar,
      'firma_id': firmaId,
    };
  }

  // Hareket tipi display adları
  String get hareketTipiDisplay {
    switch (hareketTipi) {
      case 'giris':
        return 'Giriş';
      case 'cikis':
        return 'Çıkış';
      case 'transfer_giden':
        return 'Transfer (Giden)';
      case 'transfer_gelen':
        return 'Transfer (Gelen)';
      default:
        return hareketTipi;
    }
  }

  // Kategori display adları
  String get kategoriDisplay {
    switch (kategori) {
      case 'fatura_odeme':
        return 'Fatura Ödemesi';
      case 'nakit_giris':
        return 'Nakit Giriş';
      case 'bank_transfer':
        return 'Banka Transferi';
      case 'operasyonel':
        return 'Operasyonel';
      case 'diger':
        return 'Diğer';
      default:
        return kategori ?? 'Belirtilmemiş';
    }
  }

  // Giriş/Çıkış kontrolü
  bool get isGiris => hareketTipi == 'giris' || hareketTipi == 'transfer_gelen';
  bool get isCikis => hareketTipi == 'cikis' || hareketTipi == 'transfer_giden';

  // Tutar formatlama
  String get formattedTutar {
    final formatlanmisTutar = tutar.toStringAsFixed(2);
    final symbol = _getParaBirimiSymbol();
    return '$formatlanmisTutar $symbol';
  }

  String _getParaBirimiSymbol() {
    switch (paraBirimi) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return paraBirimi;
    }
  }

  KasaBankaHareket copyWith({
    String? id,
    String? kasaBankaId,
    String? hareketTipi,
    double? tutar,
    String? paraBirimi,
    String? aciklama,
    String? kategori,
    String? faturaId,
    String? transferKasaBankaId,
    String? referansNo,
    DateTime? islemTarihi,
    DateTime? olusturmaTarihi,
    String? olusturanKullanici,
    bool? onaylanmisMi,
    String? onaylayanKullanici,
    DateTime? onaylamaTarihi,
    String? notlar,
    String? kasaBankaAdi,
    String? kasaBankaTuru,
    String? faturaNo,
    String? musteriAdi,
    String? tedarikciAdi,
    String? firmaId,
  }) {
    return KasaBankaHareket(
      id: id ?? this.id,
      kasaBankaId: kasaBankaId ?? this.kasaBankaId,
      hareketTipi: hareketTipi ?? this.hareketTipi,
      tutar: tutar ?? this.tutar,
      paraBirimi: paraBirimi ?? this.paraBirimi,
      aciklama: aciklama ?? this.aciklama,
      kategori: kategori ?? this.kategori,
      faturaId: faturaId ?? this.faturaId,
      transferKasaBankaId: transferKasaBankaId ?? this.transferKasaBankaId,
      referansNo: referansNo ?? this.referansNo,
      islemTarihi: islemTarihi ?? this.islemTarihi,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      olusturanKullanici: olusturanKullanici ?? this.olusturanKullanici,
      onaylanmisMi: onaylanmisMi ?? this.onaylanmisMi,
      onaylayanKullanici: onaylayanKullanici ?? this.onaylayanKullanici,
      onaylamaTarihi: onaylamaTarihi ?? this.onaylamaTarihi,
      notlar: notlar ?? this.notlar,
      kasaBankaAdi: kasaBankaAdi ?? this.kasaBankaAdi,
      kasaBankaTuru: kasaBankaTuru ?? this.kasaBankaTuru,
      faturaNo: faturaNo ?? this.faturaNo,
      musteriAdi: musteriAdi ?? this.musteriAdi,
      tedarikciAdi: tedarikciAdi ?? this.tedarikciAdi,
      firmaId: firmaId ?? this.firmaId,
    );
  }
}

// Transfer işlemi için wrapper class
class TransferIslemi {
  final String cikanHesapId;
  final String girenHesapId;
  final double tutar;
  final String paraBirimi;
  final String? aciklama;
  final String? referansNo;
  final DateTime islemTarihi;

  TransferIslemi({
    required this.cikanHesapId,
    required this.girenHesapId,
    required this.tutar,
    required this.paraBirimi,
    this.aciklama,
    this.referansNo,
    required this.islemTarihi,
  });
}

// Hareket özeti için model
class HareketOzeti {
  final double toplamGiris;
  final double toplamCikis;
  final double bakiye;
  final int islemSayisi;
  final String paraBirimi;

  HareketOzeti({
    required this.toplamGiris,
    required this.toplamCikis,
    required this.bakiye,
    required this.islemSayisi,
    required this.paraBirimi,
  });

  factory HareketOzeti.fromJson(Map<String, dynamic> json) {
    return HareketOzeti(
      toplamGiris: (json['toplam_giris'] ?? 0).toDouble(),
      toplamCikis: (json['toplam_cikis'] ?? 0).toDouble(),
      bakiye: (json['bakiye'] ?? 0).toDouble(),
      islemSayisi: json['islem_sayisi'] ?? 0,
      paraBirimi: json['para_birimi'] ?? 'TRY',
    );
  }
}

// Transfer işlemi için detay sınıfı
class TransferDetay {
  final String kasaBankaId;
  final double tutar;
  final String paraBirimi;
  final String? aciklama;
  final String? referansNo;
  final DateTime islemTarihi;

  TransferDetay({
    required this.kasaBankaId,
    required this.tutar,
    required this.paraBirimi,
    this.aciklama,
    this.referansNo,
    required this.islemTarihi,
  });
}
