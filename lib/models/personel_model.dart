/// Personel bilgilerini tutan veri modeli.
///
/// Supabase `personeller` tablosuyla eşleşir. [userId] (uuid) ana anahtardır.
/// SGK, maaş ve izin bilgileri dahil tüm HR verilerini barındırır.
class PersonelModel {
  final String userId; // uuid, art�k ana anahtar
  final String ad;
  final String soyad;
  final String tckn;
  final String pozisyon;
  final String departman;
  final String email;
  final String telefon;
  final String iseBaslangic;
  final String brutMaas;
  final String sgkSicilNo;
  final String gunlukCalismaSaati;
  final String haftalikCalismaGunu;
  final String yolUcreti;
  final String yemekUcreti;
  final String ekstraPrim;
  final String eldenMaas;
  final String bankaMaas;
  final String adres;
  final String netMaas;
  final String yillikIzinHakki;
  final String? firmaId;

  PersonelModel({
    required this.userId,
    required this.ad,
    required this.soyad,
    required this.tckn,
    required this.pozisyon,
    required this.departman,
    required this.email,
    required this.telefon,
    this.iseBaslangic = '',
    this.brutMaas = '',
    this.sgkSicilNo = '',
    this.gunlukCalismaSaati = '',
    this.haftalikCalismaGunu = '',
    this.yolUcreti = '',
    this.yemekUcreti = '',
    this.ekstraPrim = '',
    this.eldenMaas = '',
    this.bankaMaas = '',
    this.adres = '',
    this.netMaas = '',
    this.yillikIzinHakki = '14',
    this.firmaId,
  });

  factory PersonelModel.fromJson(Map<String, dynamic> json) => PersonelModel.fromMap(json);

  factory PersonelModel.fromMap(Map<String, dynamic> e) {
    return PersonelModel(
      userId: e['user_id'] ?? e['id']?.toString() ?? '',
      ad: e['ad'] ?? '',
      soyad: e['soyad'] ?? '',
      tckn: e['tckn'] ?? e['tc_kimlik_no'] ?? '',
      pozisyon: e['pozisyon'] ?? '',
      departman: e['departman'] ?? '',
      email: e['email'] ?? '',
      telefon: e['telefon'] ?? '',
      iseBaslangic: e['ise_baslangic'] ?? '',
      brutMaas: e['brut_maas']?.toString() ?? '',
      sgkSicilNo: e['sgk_sicil_no'] ?? '',
      gunlukCalismaSaati: e['gunluk_calisma_saati']?.toString() ?? '',
      haftalikCalismaGunu: e['haftalik_calisma_gunu']?.toString() ?? '',
      yolUcreti: e['yol_ucreti']?.toString() ?? '',
      yemekUcreti: e['yemek_ucreti']?.toString() ?? '',
      ekstraPrim: e['ekstra_prim']?.toString() ?? '',
      eldenMaas: e['elden_maas']?.toString() ?? '',
      bankaMaas: e['banka_maas']?.toString() ?? '',
      adres: e['adres'] ?? '',
      netMaas: e['net_maas']?.toString() ?? '',
      yillikIzinHakki: e['yillik_izin_hakki']?.toString() ?? '14',
      firmaId: e['firma_id'],
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'ad': ad,
      'soyad': soyad,
      'tckn': tckn,
      'pozisyon': pozisyon,
      'departman': departman,
      'email': email,
      'telefon': telefon,
      'ise_baslangic': iseBaslangic,
      'brut_maas': brutMaas,
      'sgk_sicil_no': sgkSicilNo,
      'gunluk_calisma_saati': gunlukCalismaSaati,
      'haftalik_calisma_gunu': haftalikCalismaGunu,
      'yol_ucreti': yolUcreti,
      'yemek_ucreti': yemekUcreti,
      'ekstra_prim': ekstraPrim,
      'elden_maas': eldenMaas,
      'banka_maas': bankaMaas,
      'adres': adres,
      'net_maas': netMaas,
      'yillik_izin_hakki': yillikIzinHakki,
      'firma_id': firmaId,
    };
  }
}
