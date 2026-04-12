/// Personel izin kaydı modeli.
///
/// Yıllık, hastalık, mazeret vb. izin türlerini ve onay durumunu tutar.
class IzinModel {
  final String? id;
  final String personelId;
  final String izinTuru;
  final DateTime baslangic;
  final DateTime bitis;
  final String aciklama;
  final String onayDurumu; // beklemede, onaylandi, red
  final String? onaylayanId;
  final int gunSayisi;
  final String? userId;
  final String? firmaId;

  IzinModel({
    this.id,
    required this.personelId,
    required this.izinTuru,
    required this.baslangic,
    required this.bitis,
    required this.aciklama,
    required this.onayDurumu,
    this.onaylayanId,
    required this.gunSayisi,
    this.userId,
    this.firmaId,
  });

  factory IzinModel.fromJson(Map<String, dynamic> json) => IzinModel.fromMap(json);

  factory IzinModel.fromMap(Map<String, dynamic> map) {
    // Veritaban�nda sadece user_id var
    final effectiveUserId = map['user_id']?.toString() ?? '';
    return IzinModel(
      id: map['id']?.toString(),
      personelId: effectiveUserId, // Geriye d�n�k uyumluluk i�in
      izinTuru: map['izin_turu'] as String,
      baslangic: DateTime.parse(map['baslama_tarihi']),
      bitis: DateTime.parse(map['bitis_tarihi'] ?? map['bitis']),
      aciklama: map['aciklama'] ?? '',
      onayDurumu: map['onay_durumu'] ?? 'beklemede',
      onaylayanId: map['onaylayan_user_id']?.toString(),
      gunSayisi: map['gun_sayisi'] is int ? map['gun_sayisi'] : int.tryParse(map['gun_sayisi']?.toString() ?? '0') ?? 0,
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
      'izin_turu': izinTuru,
      'baslama_tarihi': baslangic.toIso8601String(),
      'bitis_tarihi': bitis.toIso8601String(),
      'aciklama': aciklama,
      'onay_durumu': onayDurumu,
      'gun_sayisi': gunSayisi,
    };
    // onaylayan_id sadece doluysa ekle (s�tun yoksa hata vermemesi i�in)
    if (onaylayanId != null && onaylayanId!.isNotEmpty) {
      map['onaylayan_user_id'] = onaylayanId;
    }
    if (firmaId != null) map['firma_id'] = firmaId;
    return map;
  }
}
