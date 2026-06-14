/// Fatura kalemi modeli - Her fatura satırı için
class FaturaKategori {
  static const iplik = 'iplik';
  static const aksesuar = 'aksesuar';
  static const fasonUretim = 'fason_uretim';
  static const genelGider = 'genel_gider';
  static const nakliye = 'nakliye';
  static const personel = 'personel';
  static const diger = 'diger';

  static const tumu = [
    iplik,
    aksesuar,
    fasonUretim,
    genelGider,
    nakliye,
    personel,
    diger,
  ];

  static String etiket(String kategori) {
    switch (kategori) {
      case iplik:
        return 'İplik';
      case aksesuar:
        return 'Aksesuar';
      case fasonUretim:
        return 'Fason Üretim';
      case genelGider:
        return 'Genel Gider';
      case nakliye:
        return 'Nakliye';
      case personel:
        return 'Personel';
      case diger:
        return 'Diğer';
      default:
        return kategori;
    }
  }

  static String normalize(String? kategori) {
    if (kategori == null || kategori.isEmpty) return diger;
    return tumu.contains(kategori) ? kategori : diger;
  }
}

class FaturaKalemiModel {
  final int? kalemId;
  final int faturaId;
  final int siraNo;
  final String kategori;
  final String? urunKodu;
  final String urunAdi;
  final String? aciklama;
  final double miktar;
  final String birim;
  final double birimFiyat;
  final double iskonto; // yüzde
  final double iskontoTutar;
  final double kdvOrani; // yüzde
  final double kdvTutar;
  final double satirTutar; // KDV dahil
  final int? modelId; // mevcut model sistemi ile entegrasyon
  final int? stokId; // stok sistemi ile entegrasyon
  final DateTime olusturmaTarihi;
  final String? firmaId;

  const FaturaKalemiModel({
    this.kalemId,
    required this.faturaId,
    required this.siraNo,
    this.kategori = FaturaKategori.diger,
    this.urunKodu,
    required this.urunAdi,
    this.aciklama,
    required this.miktar,
    this.birim = 'adet',
    required this.birimFiyat,
    this.iskonto = 0.0,
    this.iskontoTutar = 0.0,
    this.kdvOrani = 20.0,
    required this.kdvTutar,
    required this.satirTutar,
    this.modelId,
    this.stokId,
    required this.olusturmaTarihi,
    this.firmaId,
  });

  // JSON'dan model oluşturma
  factory FaturaKalemiModel.fromJson(Map<String, dynamic> json) {
    return FaturaKalemiModel(
      kalemId: (json['id'] ?? json['kalem_id'])?.toInt(),
      faturaId: json['fatura_id']?.toInt() ?? 0,
      siraNo: json['sira_no']?.toInt() ?? (json['id']?.toInt() ?? 1),
      kategori: FaturaKategori.normalize(json['kategori']?.toString()),
      urunKodu: json['urun_kodu'],
      urunAdi: json['urun_adi'] ?? '',
      aciklama: json['aciklama'],
      miktar: (json['miktar'] ?? 0.0).toDouble(),
      birim: json['birim'] ?? 'adet',
      birimFiyat: (json['birim_fiyat'] ?? 0.0).toDouble(),
      iskonto: (json['iskonto_orani'] ?? json['iskonto'] ?? 0.0).toDouble(),
      iskontoTutar:
          (json['iskonto_tutari'] ?? json['iskonto_tutar'] ?? 0.0).toDouble(),
      kdvOrani: (json['kdv_orani'] ?? 20.0).toDouble(),
      kdvTutar: (json['kdv_tutari'] ?? json['kdv_tutar'] ?? 0.0).toDouble(),
      satirTutar:
          (json['toplam_tutar'] ?? json['satir_tutar'] ?? 0.0).toDouble(),
      modelId: json['model_id']?.toInt(),
      stokId: json['stok_id']?.toInt(),
      olusturmaTarihi: json['olusturma_tarihi'] != null
          ? DateTime.parse(json['olusturma_tarihi'])
          : DateTime.now(),
      firmaId: json['firma_id'],
    );
  }

  // Model'i JSON'a çevirme (DB sütun adlarına uygun)
  Map<String, dynamic> toJson() {
    return {
      if (kalemId != null) 'kalem_id': kalemId,
      'fatura_id': faturaId,
      'kategori': kategori,
      if (urunKodu != null) 'urun_kodu': urunKodu,
      'urun_adi': urunAdi,
      if (aciklama != null) 'aciklama': aciklama,
      'miktar': miktar,
      'birim': birim,
      'birim_fiyat': birimFiyat,
      'iskonto_orani': iskonto,
      'iskonto_tutari': iskontoTutar,
      'kdv_orani': kdvOrani,
      'kdv_tutari': kdvTutar,
      'toplam_tutar': satirTutar,
      if (modelId != null) 'model_id': modelId,
      if (firmaId != null) 'firma_id': firmaId,
      'olusturma_tarihi': olusturmaTarihi.toIso8601String(),
    };
  }

  // Hesaplama metodları
  double get hesaplananIskontoTutar {
    if (iskontoTutar > 0) return iskontoTutar;
    return (miktar * birimFiyat * iskonto) / 100;
  }

  double get araToplamTutar => (miktar * birimFiyat) - hesaplananIskontoTutar;
  double get kdvHaricTutar => araToplamTutar;
  double get hesaplananKdvTutar => hesaplaKdvTutar(kdvHaricTutar, kdvOrani);
  double get kdvDahilTutar => kdvHaricTutar + hesaplananKdvTutar;
  double get gosterilecekKdvTutar =>
      kdvTutar > 0 ? kdvTutar : hesaplananKdvTutar;
  double get gosterilecekSatirTutar =>
      satirTutar > 0 ? satirTutar : kdvDahilTutar;

  // Fiyat hesaplama (KDV hariç)
  static double hesaplaKdvHaricTutar(
      double miktar, double birimFiyat, double iskonto) {
    final araToplamTutar = miktar * birimFiyat;
    final iskontoTutar = (araToplamTutar * iskonto) / 100;
    return araToplamTutar - iskontoTutar;
  }

  // KDV tutarı hesaplama
  static double hesaplaKdvTutar(double kdvHaricTutar, double kdvOrani) {
    return (kdvHaricTutar * kdvOrani) / 100;
  }

  // Toplam tutar hesaplama
  static double hesaplaSatirTutar(
      double miktar, double birimFiyat, double iskonto, double kdvOrani) {
    final kdvHaricTutar = hesaplaKdvHaricTutar(miktar, birimFiyat, iskonto);
    final kdvTutar = hesaplaKdvTutar(kdvHaricTutar, kdvOrani);
    return kdvHaricTutar + kdvTutar;
  }

  // Formatlanmış değerler
  String get formattedMiktar =>
      miktar.toStringAsFixed(miktar == miktar.roundToDouble() ? 0 : 2);
  String get formattedBirimFiyat => birimFiyat.toStringAsFixed(2);
  String get formattedSatirTutar => gosterilecekSatirTutar.toStringAsFixed(2);
  String get formattedKdvTutar => gosterilecekKdvTutar.toStringAsFixed(2);

  // Copy with metodu
  FaturaKalemiModel copyWith({
    int? kalemId,
    int? faturaId,
    int? siraNo,
    String? kategori,
    String? urunKodu,
    String? urunAdi,
    String? aciklama,
    double? miktar,
    String? birim,
    double? birimFiyat,
    double? iskonto,
    double? iskontoTutar,
    double? kdvOrani,
    double? kdvTutar,
    double? satirTutar,
    int? modelId,
    int? stokId,
    DateTime? olusturmaTarihi,
    String? firmaId,
  }) {
    return FaturaKalemiModel(
      kalemId: kalemId ?? this.kalemId,
      faturaId: faturaId ?? this.faturaId,
      siraNo: siraNo ?? this.siraNo,
      kategori: kategori ?? this.kategori,
      urunKodu: urunKodu ?? this.urunKodu,
      urunAdi: urunAdi ?? this.urunAdi,
      aciklama: aciklama ?? this.aciklama,
      miktar: miktar ?? this.miktar,
      birim: birim ?? this.birim,
      birimFiyat: birimFiyat ?? this.birimFiyat,
      iskonto: iskonto ?? this.iskonto,
      iskontoTutar: iskontoTutar ?? this.iskontoTutar,
      kdvOrani: kdvOrani ?? this.kdvOrani,
      kdvTutar: kdvTutar ?? this.kdvTutar,
      satirTutar: satirTutar ?? this.satirTutar,
      modelId: modelId ?? this.modelId,
      stokId: stokId ?? this.stokId,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      firmaId: firmaId ?? this.firmaId,
    );
  }

  @override
  String toString() {
    return 'FaturaKalemiModel(kalemId: $kalemId, kategori: $kategori, urunAdi: $urunAdi, miktar: $miktar, satirTutar: $satirTutar)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaturaKalemiModel && other.kalemId == kalemId;
  }

  @override
  int get hashCode => kalemId.hashCode;
}
