/// Personel ödeme kaydı modeli (avans, prim, mesai, ikramiye, kesinti).
///
/// [personelId] ödemenin ait olduğu personeli, [userId] ise alternative
/// erişim anahtarını temsil eder. Supabase `user_id` sütununa eşlenir.
class OdemeModel {
  final int? id;
  final String personelId;
  final String userId;
  final String
      tur; // avans, prim, mesai, ikramiye, kesinti - varsayılan: 'avans'
  final double tutar;
  final String aciklama; // varsayılan: ''
  final DateTime tarih;
  final String durum; // beklemede, onaylandi, red - varsayılan: 'beklemede'
  final String? onaylayanId;
  final String? firmaId;
  OdemeModel({
    this.id,
    required this.personelId,
    required this.userId,
    this.tur = 'avans', // varsayılan değer ekle
    required this.tutar,
    this.aciklama = '', // varsayılan değer ekle
    required this.tarih,
    this.durum = 'beklemede', // varsayılan değer ekle
    this.onaylayanId,
    this.firmaId,
  });

  factory OdemeModel.fromJson(Map<String, dynamic> json) =>
      OdemeModel.fromMap(json);

  factory OdemeModel.fromMap(Map<String, dynamic> map) {
    final userId =
        map['user_id']?.toString() ?? map['personel_id']?.toString() ?? '';
    final rawTarih =
        map['odeme_tarihi']?.toString() ?? map['tarih']?.toString();
    final tarih = DateTime.tryParse(rawTarih ?? '');
    if (tarih == null) {
      throw FormatException('Geçersiz ödeme tarihi', rawTarih);
    }
    return OdemeModel(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? ''),
      personelId: userId,
      userId: userId,
      tur: map['odeme_turu']?.toString() ?? map['tur']?.toString() ?? 'avans',
      tutar: (map['tutar'] as num?)?.toDouble() ?? 0.0,
      aciklama: map['aciklama']?.toString() ?? '',
      tarih: tarih,
      durum: map['durum']?.toString() ?? 'beklemede',
      onaylayanId: map['onaylayan_user_id']?.toString() ??
          map['onaylayan_id']?.toString(),
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    // Veritabanında sadece user_id var
    // personelId, ödemenin kime ait olduğunu gösterir (seçilen personel)
    // userId ise işlemi yapan kullanıcıdır
    // Ödeme kaydı seçilen personele ait olmalı, bu yüzden personelId öncelikli
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
