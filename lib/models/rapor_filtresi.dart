class RaporFiltresi {
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final String? marka;
  final String? model;
  final String? modelId;
  final int? yil;

  const RaporFiltresi({
    this.baslangicTarihi,
    this.bitisTarihi,
    this.marka,
    this.model,
    this.modelId,
    this.yil,
  });

  bool get modelKapsamiVar =>
      marka != null || model != null || modelId != null || yil != null;

  DateTime? get efektifBaslangicTarihi =>
      baslangicTarihi ?? (yil == null ? null : DateTime(yil!, 1, 1));

  DateTime? get efektifBitisTarihi =>
      bitisTarihi ?? (yil == null ? null : DateTime(yil! + 1, 1, 1));

  bool tarihAraliginda(Map<String, dynamic> data, String alan) {
    final raw = data[alan];
    if (raw == null) {
      return baslangicTarihi == null && bitisTarihi == null && yil == null;
    }

    final tarih = DateTime.tryParse(raw.toString());
    if (tarih == null) return false;

    if (yil != null && tarih.year != yil) return false;
    if (baslangicTarihi != null && tarih.isBefore(baslangicTarihi!)) {
      return false;
    }
    if (bitisTarihi != null) {
      final bitisDahil = DateTime(
        bitisTarihi!.year,
        bitisTarihi!.month,
        bitisTarihi!.day,
        23,
        59,
        59,
        999,
      );
      if (tarih.isAfter(bitisDahil)) return false;
    }

    return true;
  }

  bool modelEslesir(Map<String, dynamic> data) {
    if (marka != null && data['marka']?.toString() != marka) return false;
    if (model != null && data['item_no']?.toString() != model) return false;
    return tarihAraliginda(data, 'created_at');
  }

  bool depoEslesir(Map<String, dynamic> data) {
    if (marka != null && data['marka']?.toString() != marka) return false;
    if (modelId != null && data['model_id']?.toString() != modelId) {
      return false;
    }
    if (model != null && modelId == null) {
      final depoModel = (data['item_no'] ?? data['model'])?.toString();
      if (depoModel != model) return false;
    }

    final tarihAlan =
        data['satis_tarihi'] != null ? 'satis_tarihi' : 'created_at';
    return tarihAraliginda(data, tarihAlan);
  }
}
