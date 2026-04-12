/// Personel ödeme kaydı modeli (avans, prim, mesai, ikramiye, kesinti).
///
/// [personelId] ödemenin ait olduğu personeli, [userId] ise alternative
/// erişim anahtarını temsil eder. Supabase `user_id` sütununa eşlenir.
class OdemeModel {
  final int? id;
  final String personelId;
  final String userId;
  final String tur; // avans, prim, mesai, ikramiye, kesinti - varsay�lan: 'avans'
  final double tutar;
  final String aciklama; // varsay�lan: ''
  final DateTime tarih;
  final String durum; // beklemede, onaylandi, red - varsay�lan: 'beklemede'
  final String? onaylayanId;  final String? firmaId;
  OdemeModel({
    this.id,
    required this.personelId,
    required this.userId,
    this.tur = 'avans', // varsay�lan de�er ekle
    required this.tutar,
    this.aciklama = '', // varsay�lan de�er ekle
    required this.tarih,
    this.durum = 'beklemede', // varsay�lan de�er ekle
    this.onaylayanId,    this.firmaId,  });

  factory OdemeModel.fromJson(Map<String, dynamic> json) => OdemeModel.fromMap(json);

  factory OdemeModel.fromMap(Map<String, dynamic> map) {
    // Veritaban�nda sadece user_id var
    final userId = map['user_id']?.toString() ?? '';
    return OdemeModel(
      id: map['id'] as int?,
      personelId: userId, // user_id'yi personelId olarak da ata (geriye d�n�k uyumluluk)
      userId: userId,
      tur: map['odeme_turu']?.toString() ?? 'avans',
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      aciklama: map['aciklama']?.toString() ?? '',
      tarih: map['odeme_tarihi'] != null ? DateTime.parse(map['odeme_tarihi']) : DateTime.now(),
      durum: map['durum']?.toString() ?? 'beklemede',
      onaylayanId: map['onaylayan_user_id']?.toString(),
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    // Veritaban�nda sadece user_id var
    // personelId, �demenin kime ait oldu�unu g�sterir (se�ilen personel)
    // userId ise i�lemi yapan kullan�c�d�r
    // �deme kayd� se�ilen personele ait olmal�, bu y�zden personelId �ncelikli
    final effectiveUserId = (personelId).trim().isNotEmpty 
        ? personelId 
        : ((userId).trim().isNotEmpty ? userId : null);
    
    return {
      'user_id': effectiveUserId,
      'odeme_turu': tur.isEmpty ? 'avans' : tur,
      'tutar': tutar,
      'aciklama': aciklama.isEmpty ? '' : aciklama,
      'odeme_tarihi': tarih.toIso8601String(),
      'durum': durum.isEmpty ? 'beklemede' : durum,
      'onaylayan_user_id': onaylayanId,
      'firma_id': firmaId,
    };
  }

  OdemeModel copyWith({
    int? id,
    String? personelId,
    String? userId,
    String? tur,
    double? tutar,
    String? aciklama,
    DateTime? tarih,
    String? durum,
    String? onaylayanId,
    String? firmaId,
  }) {
    return OdemeModel(
      id: id ?? this.id,
      personelId: personelId ?? this.personelId,
      userId: userId ?? this.userId,
      tur: tur ?? this.tur,
      tutar: tutar ?? this.tutar,
      aciklama: aciklama ?? this.aciklama,
      tarih: tarih ?? this.tarih,
      durum: durum ?? this.durum,
      onaylayanId: onaylayanId ?? this.onaylayanId,
      firmaId: firmaId ?? this.firmaId,
    );
  }
}