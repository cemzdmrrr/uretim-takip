-- Test tedarikci hesabı ekle
INSERT INTO tedarikciler (ad, soyad, sirket, telefon, email, tedarikci_tipi, faaliyet, durum) 
VALUES (
    'Test', 
    'Tedarikci', 
    'Test Dokuma Ltd', 
    '+90 555 123 4567', 
    'test@tedarikci.com', 
    'Tedarikci', 
    'Dokuma', 
    'aktif'
) 
ON CONFLICT (email) DO UPDATE SET
    sirket = EXCLUDED.sirket,
    faaliyet = EXCLUDED.faaliyet,
    durum = EXCLUDED.durum;