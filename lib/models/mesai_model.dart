/// Fazla mesai kaydı modeli.
///
/// Personelin mesai saati, türü, onay durumu ve ücret bilgilerini içerir.
class MesaiModel {
  final String? id;
  final String personelId;
  final DateTime tarih;
  final String baslangicSaati;
  final String bitisSaati;
  final String mesaiTuru;
  final String onayDurumu;
  final double? saat;
  final String? onaylayanId;
  final double? mesaiUcret;
  final double? yemekUcreti;
  final double? carpan;
  final String? userId; // user_id alanını ekle
  final String? firmaId;

  MesaiModel({
    this.id,
    required this.personelId,
    required this.tarih,
    required this.baslangicSaati,
    required this.bitisSaati,
    required this.mesaiTuru,
    required this.onayDurumu,
    this.saat,
    this.onaylayanId,
    this.mesaiUcret,
    this.yemekUcreti,
    this.carpan,
    this.userId,
    this.firmaId,
  });

  factory MesaiModel.fromJson(Map<String, dynamic> json) => MesaiModel.fromMap(json);

  factory MesaiModel.fromMap(Map<String, dynamic> map) {
    // Veritaban�nda sadece user_id var
    final effectiveUserId = map['user_id']?.toString() ?? '';
    return MesaiModel(
      id: map['id']?.toString(),
      personelId: effectiveUserId, // Geriye d�n�k uyumluluk i�in
      tarih: DateTime.parse(map['tarih']),
      baslangicSaati: map['baslangic_saati'] ?? '',
      bitisSaati: map['bitis_saati'] ?? '',
      mesaiTuru: map['mesai_turu'] ?? '',
      onayDurumu: map['onay_durumu'] ?? '',
      saat: map['saat'] != null ? (map['saat'] is num ? map['saat'].toDouble() : double.tryParse(map['saat'].toString())) : null,
      onaylayanId: map['onaylayan_user_id']?.toString(),
      mesaiUcret: map['mesai_ucret'] != null ? (map['mesai_ucret'] is num ? map['mesai_ucret'].toDouble() : double.tryParse(map['mesai_ucret'].toString())) : null,
      yemekUcreti: map['yemek_ucreti'] != null ? (map['yemek_ucreti'] is num ? map['yemek_ucreti'].toDouble() : double.tryParse(map['yemek_ucreti'].toString())) : null,
      carpan: map['carpan'] != null ? (map['carpan'] is num ? map['carpan'].toDouble() : double.tryParse(map['carpan'].toString())) : null,
      userId: effectiveUserId,
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    // Veritaban�nda sadece user_id var, personelId'yi user_id olarak g�nder
    final effectiveUserId = (userId ?? '').trim().isNotEmpty ? userId : personelId;
    final map = <String, dynamic>{
      'user_id': effectiveUserId,
      'tarih': tarih.toIso8601String(),
      'baslangic_saati': baslangicSaati,
      'bitis_saati': bitisSaati,
      'mesai_turu': mesaiTuru,
      'onay_durumu': onayDurumu,
      'mesai_ucret': mesaiUcret,
      'yemek_ucreti': yemekUcreti,
      'carpan': carpan,
    };
    // onaylayan_user_id sadece doluysa ekle
    if (onaylayanId != null && onaylayanId!.isNotEmpty) {
      map['onaylayan_user_id'] = onaylayanId;
    }
    if (saat != null) map['saat'] = saat.toString();
    if (firmaId != null) map['firma_id'] = firmaId;
    return map;
  }
}
