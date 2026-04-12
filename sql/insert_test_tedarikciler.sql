-- Test için örnek tedarikciler ekleme
INSERT INTO public.tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum) VALUES 
('Ahmet', 'Örgüoğlu', 'Akdeniz Örgü Tekstil Ltd. Şti.', '+90 532 111 1111', 'ahmet@akdenizorgu.com', 'Üretici', 'Örgü', 'aktif'),
('Mehmet', 'Dokumal', 'İstanbul Dokuma Fabrikası A.Ş.', '+90 532 222 2222', 'mehmet@istdokuma.com', 'Üretici', 'Dokuma', 'aktif'),
('Fatma', 'Konfeksiyon', 'Ege Konfeksiyon Atölyesi', '+90 532 333 3333', 'fatma@egekonfeksiyon.com', 'Atölye', 'Konfeksiyon', 'aktif'),
('Ali', 'Nakışçı', 'Anadolu Nakış Sanatları', '+90 532 444 4444', 'ali@anadolunakis.com', 'Atölye', 'Nakış', 'aktif'),
('Ayşe', 'Yıkamacı', 'Marmara Yıkama Tesisleri', '+90 532 555 5555', 'ayse@marmarayikama.com', 'Tesis', 'Yıkama', 'aktif'),
('Hasan', 'İlik', 'Karadeniz İlik Düğme', '+90 532 666 6666', 'hasan@kdz-ilik.com', 'Üretici', 'İlik Düğme', 'aktif'),
('Zeynep', 'Ütüoğlu', 'Ankara Ütü Presleme', '+90 532 777 7777', 'zeynep@ankarautu.com', 'Atölye', 'Ütü', 'aktif');

-- Eklenen kayıtları kontrol et
SELECT id, ad, soyad, sirket, faaliyet FROM tedarikciler WHERE faaliyet IN ('Örgü', 'Dokuma', 'Konfeksiyon', 'Nakış', 'Yıkama', 'İlik Düğme', 'Ütü');