/// Supabase veritabanı tablo adları sabitleri.
///
/// Tüm tablo referansları burada merkezi olarak yönetilir.
/// Kullanım: `Supabase.instance.client.from(DbTables.modeller)`
class DbTables {
  DbTables._();

  // ─── Model & Üretim ───
  static const modeller = 'modeller';
  /// Tüm üretim dallarının model tablosu (eski adıyla triko_takip, geriye uyumluluk)
  static const trikoTakip = 'triko_takip';
  static const uretimKayitlari = 'uretim_kayitlari';
  static const modelKritikleri = 'model_kritikleri';
  static const modelToplamAdetler = 'model_toplam_adetler';

  // ─── Beden Yönetimi ───
  static const bedenTanimlari = 'beden_tanimlari';
  static const modelBedenDagilimi = 'model_beden_dagilimi';
  static const modelBedenOzet = 'model_beden_ozet';
  static const dokumaBedeTakip = 'dokuma_beden_takip';

  // ─── Atama Tabloları ───
  static const dokumaAtamalari = 'dokuma_atamalari';
  static const konfeksiyonAtamalari = 'konfeksiyon_atamalari';
  static const kaliteKontrolAtamalari = 'kalite_kontrol_atamalari';
  static const paketlemeAtamalari = 'paketleme_atamalari';
  static const utuAtamalari = 'utu_atamalari';
  static const yikamaAtamalari = 'yikama_atamalari';
  static const nakisAtamalari = 'nakis_atamalari';
  static const ilikDugmeAtamalari = 'ilik_dugme_atamalari';
  static const atamaIstatistikleri = 'atama_istatistikleri';

  // ─── İplik & Stok ───
  static const iplikStoklari = 'iplik_stoklari';
  static const iplikHareketleri = 'iplik_hareketleri';
  static const iplikSiparisleri = 'iplik_siparisleri';
  static const iplikStokHareketleri = 'iplik_stok_hareketleri';
  static const stokHareketleri = 'stok_hareketleri';

  // ─── Aksesuar ───
  static const aksesuarlar = 'aksesuarlar';
  static const aksesuarStok = 'aksesuar_stok';
  static const aksesuarKullanim = 'aksesuar_kullanim';
  static const aksesuarBedenler = 'aksesuar_bedenler';
  static const modelAksesuar = 'model_aksesuar';

  // ─── Finans ───
  static const faturalar = 'faturalar';
  static const faturaKalemleri = 'fatura_kalemleri';
  static const kasaBankaHesaplari = 'kasa_banka_hesaplari';
  static const kasaBankaHareketleri = 'kasa_banka_hareketleri';
  static const odemeKayitlari = 'odeme_kayitlari';
  static const odemeGecmisi = 'odeme_gecmisi';
  static const maliyetHesaplama = 'maliyet_hesaplama';
  static const yevmiyeKayitlari = 'yevmiye_kayitlari';
  static const hesapPlani = 'hesap_plani';
  static const donemler = 'donemler';
  static const gelirVergisiDilimleri = 'gelir_vergisi_dilimleri';

  // ─── Finans View'lar ───
  static const bilancoView = 'bilanco_view';
  static const karZararView = 'kar_zarar_view';
  static const mizanView = 'mizan_view';

  // ─── Tedarikçi ───
  static const tedarikciler = 'tedarikciler';
  static const tedarikciSiparisleri = 'tedarikci_siparisleri';
  static const tedarikciOdemeleri = 'tedarikci_odemeleri';

  // ─── Müşteri ───
  static const musteriler = 'musteriler';

  // ─── Sevkiyat ───
  static const sevkiyatKayitlari = 'sevkiyat_kayitlari';
  static const sevkiyatDetaylari = 'sevkiyat_detaylari';
  static const sevkTalepleri = 'sevk_talepleri';
  static const cekiListesi = 'ceki_listesi';
  static const yuklemeKayitlari = 'yukleme_kayitlari';

  // ─── Personel & İK ───
  static const personel = 'personel';
  static const personelDonem = 'personel_donem';
  static const bordro = 'bordro';
  static const mesai = 'mesai';
  static const mesaiKayitlari = 'mesai_kayitlari';
  static const puantaj = 'puantaj';
  static const izinler = 'izinler';
  static const izinKayitlari = 'izin_kayitlari';

  // ─── Kullanıcı & Sistem ───
  static const kullanicilar = 'kullanicilar';
  static const firmaKullanicilari = 'firma_kullanicilari';
  static const userRoles = 'user_roles';
  static const users = 'users';
  static const bildirimler = 'bildirimler';
  static const notifications = 'notifications';
  static const sistemAyarlari = 'sistem_ayarlari';
  static const sirketBilgileri = 'sirket_bilgileri';
  static const atolyeler = 'atolyeler';

  // ─── Dosya & Diğer ───
  static const dosyalar = 'dosyalar';
  static const teknikDosyalar = 'teknik_dosyalar';
  static const urunDepo = 'urun_depo';

  // ─── Multi-Tenant & SaaS ───
  static const firmalar = 'firmalar';
  static const firmaAyarlari = 'firma_ayarlari';
  static const kullaniciAktifFirma = 'kullanici_aktif_firma';
  static const firmaDavetleri = 'firma_davetleri';
  static const modulTanimlari = 'modul_tanimlari';
  static const uretimModulleri = 'uretim_modulleri';
  static const firmaModulleri = 'firma_modulleri';
  static const firmaUretimModulleri = 'firma_uretim_modulleri';
  static const abonelikPlanlari = 'abonelik_planlari';
  static const firmaAbonelikleri = 'firma_abonelikleri';
  static const abonelikOdemeleri = 'abonelik_odemeleri';
  static const yetkiTanimlari = 'yetki_tanimlari';
  static const kullaniciSayfaYetkileri = 'kullanici_sayfa_yetkileri';
  static const firmaSayfaYetkileri = 'firma_sayfa_yetkileri';

  // ─── Genel Üretim (Phase 8) ───
  static const uretimAtamalari = 'uretim_atamalari';
  static const dalFormAlanlari = 'dal_form_alanlari';
  static const asamaTanimlari = 'asama_tanimlari';

  // ─── Platform Admin (Phase 9) ───
  static const destekTalepleri = 'destek_talepleri';
  static const platformLoglari = 'platform_loglari';
  static const platformDuyurulari = 'platform_duyurulari';

  // ─── Migrasyon (Phase 10) ───
  static const migrasyonDurumu = 'migrasyon_durumu';

  // ─── View'lar ───
  static const vFirmaKullanicilariDetay = 'v_firma_kullanicilari_detay';
  static const vSiparisTakip = 'v_siparis_takip';
  static const models = 'models';
}
