-- Test tedarikciler ekle
INSERT INTO tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum) VALUES
('Ahmet', 'Yılmaz', 'Akdeniz Örgü Tekstil Ltd.', '+90 532 123 4567', 'ahmet@akdenizorgu.com', 'Tedarikci', 'Dokuma', 'aktif'),
('Mehmet', 'Kaya', 'İstanbul Konfeksiyon Atölyesi', '+90 536 987 6543', 'mehmet@istanbulkonf.com', 'Tedarikci', 'Konfeksiyon', 'aktif'),
('Fatma', 'Demir', 'Ege Nakış Sanatları', '+90 505 111 2233', 'fatma@egenakis.com', 'Tedarikci', 'Nakış', 'aktif'),
('Ali', 'Çetin', 'Marmara Yıkama Fabrikası', '+90 543 444 5566', 'ali@marmarayikama.com', 'Tedarikci', 'Yıkama', 'aktif'),
('Ayşe', 'Şahin', 'Anadolu İlik Düğme', '+90 532 777 8899', 'ayse@anadoluilik.com', 'Tedarikci', 'İlik Düğme', 'aktif'),
('Hasan', 'Özkan', 'Bursa Ütü Atölyesi', '+90 505 333 4455', 'hasan@bursautu.com', 'Tedarikci', 'Ütü', 'aktif')
ON CONFLICT DO NOTHING;