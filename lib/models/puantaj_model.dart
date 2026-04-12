/// Aylık puantaj (devam) kaydı modeli.
///
/// Personelin çalışma günü, saat, fazla mesai ve devamsızlık bilgilerini tutar.
class PuantajModel {
  final String id;
  final String personelId;
  final String ad;
  final int ay;
  final int yil;
  int gun;
  int calismaSaati;
  int fazlaMesai;
  int eksikGun;
  int devamsizlik;
  final String? firmaId;

  PuantajModel({
    required this.id,
    required this.personelId,
    required this.ad,
    required this.ay,
    required this.yil,
    required this.gun,
    required this.calismaSaati,
    required this.fazlaMesai,
    required this.eksikGun,
    required this.devamsizlik,
    this.firmaId,
  });

  factory PuantajModel.fromJson(Map<String, dynamic> json) => PuantajModel.fromMap(json);

  factory PuantajModel.fromMap(Map<String, dynamic> map) {
    return PuantajModel(
      id: map['id']?.toString() ?? '',
      personelId: map['user_id']?.toString() ?? '',
      ad: map['ad'] ?? '',
      ay: map['ay'] is int ? map['ay'] : int.tryParse(map['ay'].toString()) ?? 0,
      yil: map['yil'] is int ? map['yil'] : int.tryParse(map['yil'].toString()) ?? 0,
      gun: map['gun'] is int ? map['gun'] : int.tryParse(map['gun'].toString()) ?? 0,
      calismaSaati: map['calisma_saati'] is int ? map['calisma_saati'] : int.tryParse(map['calisma_saati'].toString()) ?? 0,
      fazlaMesai: map['fazla_mesai'] is int ? map['fazla_mesai'] : int.tryParse(map['fazla_mesai'].toString()) ?? 0,
      eksikGun: map['eksik_gun'] is int ? map['eksik_gun'] : int.tryParse(map['eksik_gun'].toString()) ?? 0,
      devamsizlik: map['devamsizlik'] is int ? map['devamsizlik'] : int.tryParse(map['devamsizlik'].toString()) ?? 0,
      firmaId: map['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap({bool sendId = true}) {
    final map = {
      'user_id': personelId,
      'ad': ad,
      'ay': ay,
      'yil': yil,
      'gun': gun,
      'calisma_saati': calismaSaati,
      'fazla_mesai': fazlaMesai,
      'eksik_gun': eksikGun,
      'devamsizlik': devamsizlik,
      'firma_id': firmaId,
    };
    if (sendId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
