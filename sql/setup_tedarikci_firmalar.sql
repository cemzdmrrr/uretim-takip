-- Tüm üretim aşamaları için tedarikçi/firma verileri ayarla
-- Bu script, her aşama için gerçek firma verilerini ekler

-- UYARI: Bu script mevcut tedarikcileri silmez, sadece eksik olanları ekler

-- 1. Dokuma/Örgü Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Akdeniz Örgü Tekstil Ltd. Şti.', '+90 532 123 4567', 'info@akdenizorgu.com', 'Üretici', 'Dokuma', 'aktif'),
  ('', '', 'Marmara Dokuma San. ve Tic. A.Ş.', '+90 212 345 6789', 'uretim@marmaradokuma.com', 'Üretici', 'Dokuma', 'aktif'),
  ('', '', 'İzmir Örme Fabrikası Ltd.', '+90 232 456 7890', 'info@izmirorme.com', 'Üretici', 'Dokuma', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 2. Konfeksiyon Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'İstanbul Konfeksiyon Atölyesi', '+90 536 987 6543', 'uretim@istanbulkonf.com', 'Üretici', 'Konfeksiyon', 'aktif'),
  ('', '', 'Ege Tekstil Konfeksiyon Ltd.', '+90 232 567 8901', 'info@egetekstil.com', 'Üretici', 'Konfeksiyon', 'aktif'),
  ('', '', 'Bursa Konfeksiyon San. A.Ş.', '+90 224 678 9012', 'uretim@burskonf.com', 'Üretici', 'Konfeksiyon', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 3. Nakış Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Sanat Nakış Atölyesi', '+90 544 234 5678', 'info@saratnakis.com', 'Hizmet Sağlayıcı', 'Nakış', 'aktif'),
  ('', '', 'Bursa Nakış ve Süsleme Ltd.', '+90 224 789 0123', 'nakis@bursanakis.com', 'Hizmet Sağlayıcı', 'Nakış', 'aktif'),
  ('', '', 'İstanbul Bordür Nakış Ltd.', '+90 212 890 1234', 'bordur@istanbulbordur.com', 'Hizmet Sağlayıcı', 'Nakış', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 4. Yıkama Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Temiz Yıkama Fabrikası', '+90 555 123 4567', 'info@temizedestir.com', 'Hizmet Sağlayıcı', 'Yıkama', 'aktif'),
  ('', '', 'Karadeniz Tekstil Yıkama A.Ş.', '+90 462 234 5678', 'yikama@karadenizyikama.com', 'Hizmet Sağlayıcı', 'Yıkama', 'aktif'),
  ('', '', 'Antalya Tekstil Yıkama Ltd.', '+90 242 345 6789', 'yikama@antalyayikama.com', 'Hizmet Sağlayıcı', 'Yıkama', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 5. İlik Düğme Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Düğme Dünyası San. Tic. Ltd.', '+90 532 456 7890', 'info@dugnedunya.com', 'Tedarikçi', 'İlik Düğme', 'aktif'),
  ('', '', 'Aksesuvar Plus İlik Düğme', '+90 533 567 8901', 'aksesuvar@aksesuar.com', 'Tedarikçi', 'İlik Düğme', 'aktif'),
  ('', '', 'İstanbul Aksesuar Merkezi', '+90 212 567 8901', 'aksesuar@istanbulaksesuar.com', 'Tedarikçi', 'İlik Düğme', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 6. Ütü/Pres Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Profesyonel Ütü Hizmetleri', '+90 534 678 9012', 'utu@profesyonelutu.com', 'Hizmet Sağlayıcı', 'Ütü', 'aktif'),
  ('', '', 'Ankara Ütü ve Paketleme A.Ş.', '+90 312 678 9012', 'utu@ankarapaketleme.com', 'Hizmet Sağlayıcı', 'Ütü', 'aktif'),
  ('', '', 'Pres ve Ütü Hizmetleri Ltd.', '+90 532 789 0123', 'pres@preshumet.com', 'Hizmet Sağlayıcı', 'Ütü', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 7. Kalite Kontrol (iç kontrol, normalde kurumsal)
-- Kalite kontrol genellikle kendi personeli tarafından yapılır, ama tedarikçi seçeneği de olabilir
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Kalite Kontrol Laboratuvarı Ltd.', '+90 535 890 1234', 'lab@kalitelaboratuvar.com', 'Hizmet Sağlayıcı', 'Kalite Kontrol', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- 8. Paketleme Firmaları
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum)
VALUES
  ('', '', 'Modern Paketleme Çözümleri Ltd.', '+90 536 901 2345', 'paket@modernpaketleme.com', 'Hizmet Sağlayıcı', 'Paketleme', 'aktif'),
  ('', '', 'İstanbul Kargo ve Paketleme', '+90 537 012 3456', 'paket@istanbulkargo.com', 'Hizmet Sağlayıcı', 'Paketleme', 'aktif'),
  ('', '', 'Ankara Lojistik ve Paketleme A.Ş.', '+90 312 789 0123', 'logistik@ankaralogistik.com', 'Hizmet Sağlayıcı', 'Paketleme', 'aktif')
ON CONFLICT (sirket) DO NOTHING;

-- Kontrol: Tüm faaliyet alanlarında kaç firma var?
SELECT faaliyet, COUNT(*) as firma_sayisi, STRING_AGG(sirket, ', ') as firmalar
FROM public.tedarikciler
WHERE durum = 'aktif'
GROUP BY faaliyet
ORDER BY faaliyet;
