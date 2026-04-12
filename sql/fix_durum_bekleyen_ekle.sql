-- ==========================================
-- ATAMA TABLOLARI DURUM CHECK DÜZELTME
-- ==========================================
-- "bekleyen", "devam_ediyor" ve "sevk_ediliyor" durumlarını ekle
-- Tarih: 2026-01-17

-- Konfeksiyon atamaları
ALTER TABLE konfeksiyon_atamalari DROP CONSTRAINT IF EXISTS konfeksiyon_atamalari_durum_check;
ALTER TABLE konfeksiyon_atamalari ADD CONSTRAINT konfeksiyon_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Dokuma atamaları
ALTER TABLE dokuma_atamalari DROP CONSTRAINT IF EXISTS dokuma_atamalari_durum_check;
ALTER TABLE dokuma_atamalari ADD CONSTRAINT dokuma_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Yıkama atamaları
ALTER TABLE yikama_atamalari DROP CONSTRAINT IF EXISTS yikama_atamalari_durum_check;
ALTER TABLE yikama_atamalari ADD CONSTRAINT yikama_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Ütü atamaları
ALTER TABLE utu_atamalari DROP CONSTRAINT IF EXISTS utu_atamalari_durum_check;
ALTER TABLE utu_atamalari ADD CONSTRAINT utu_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Paketleme atamaları
ALTER TABLE paketleme_atamalari DROP CONSTRAINT IF EXISTS paketleme_atamalari_durum_check;
ALTER TABLE paketleme_atamalari ADD CONSTRAINT paketleme_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- İlik Düğme atamaları
ALTER TABLE ilik_dugme_atamalari DROP CONSTRAINT IF EXISTS ilik_dugme_atamalari_durum_check;
ALTER TABLE ilik_dugme_atamalari ADD CONSTRAINT ilik_dugme_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Nakış atamaları
ALTER TABLE nakis_atamalari DROP CONSTRAINT IF EXISTS nakis_atamalari_durum_check;
ALTER TABLE nakis_atamalari ADD CONSTRAINT nakis_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Kalite Kontrol atamaları
ALTER TABLE kalite_kontrol_atamalari DROP CONSTRAINT IF EXISTS kalite_kontrol_atamalari_durum_check;
ALTER TABLE kalite_kontrol_atamalari ADD CONSTRAINT kalite_kontrol_atamalari_durum_check 
  CHECK (durum IN ('bekleyen', 'atandi', 'onaylandi', 'baslandi', 'devam_ediyor', 'uretimde', 'baslatildi', 'kismi_tamamlandi', 'tamamlandi', 'beklemede', 'kontrol_bekliyor', 'kontrolde', 'sevk_ediliyor', 'reddedildi', 'iptal'));

-- Başarılı sonuç mesajı
SELECT 'Tüm atama tablolarına bekleyen, devam_ediyor ve sevk_ediliyor durumları eklendi!' as sonuc;
