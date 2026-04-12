/// Uygulama genelindeki route sabitleri.
/// Magic string'ler yerine bu sabitleri kullanın.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String anasayfa = '/anasayfa';
  static const String login = '/login';
  static const String firmaSecim = '/firma_secim';
  static const String dokuma = '/dokuma';
  static const String tedarikci = '/tedarikci';
  static const String kalite = '/kalite';
  static const String kaliteKontrol = '/kalite_kontrol';
  static const String yikama = '/yikama';
  static const String nakis = '/nakis';
  static const String uretimRaporu = '/uretim_raporu';
  static const String modelDuzenle = '/model_duzenle';

  // Onboarding routes
  static const String firmaKayit = '/onboarding/firma_kayit';
  static const String firmaBilgileri = '/onboarding/firma_bilgileri';
  static const String tekstilDaliSecim = '/onboarding/tekstil_dali_secim';
  static const String modulSecim = '/onboarding/modul_secim';
  static const String firmaKurulumOzet = '/onboarding/firma_kurulum_ozet';
  static const String davetKatil = '/onboarding/davet_katil';

  // Abonelik routes
  static const String planSecim = '/abonelik/plan_secim';
  static const String abonelikYonetimi = '/abonelik/yonetimi';

  // Firma yönetim routes
  static const String firmaKullaniciYonetimi = '/ayarlar/firma_kullanicilari';
  static const String rolYetkiYonetimi = '/ayarlar/rol_yetki';

  // Üretim routes
  static const String genelUretimDashboard = '/uretim/genel';

  // Platform Admin routes
  static const String platformDashboard = '/platform/dashboard';
  static const String platformFirmalar = '/platform/firmalar';
  static const String platformAbonelikler = '/platform/abonelikler';
  static const String platformModuller = '/platform/moduller';
  static const String platformUretimDallari = '/platform/uretim_dallari';
  static const String platformRaporlar = '/platform/raporlar';
  static const String platformDestek = '/platform/destek';
  static const String platformMigrasyon = '/platform/migrasyon';
}
