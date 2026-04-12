-- İplik firması test verisi ekleme
INSERT INTO tedarikciler (
    sirket, 
    ad, 
    telefon, 
    tedarikci_turu, 
    faaliyet_alani, 
    durum
) VALUES 
(
    'Akar Tekstil İplik San. Tic. Ltd. Şti.', 
    'Ahmet AKAR', 
    '0532 123 45 67', 
    'İplik Firması', 
    'İplik üretimi ve satışı', 
    'aktif'
),
(
    'Güven İplik Fabrikası', 
    'Mehmet GÜL', 
    '0535 234 56 78', 
    'İplik Firması', 
    'Pamuk ve polyester iplik', 
    'aktif'
),
(
    'Elit İplik ve Tekstil A.Ş.', 
    'Fatma ÖZTÜRK', 
    '0542 345 67 89', 
    'İplik Firması', 
    'Kaliteli iplik üretimi', 
    'aktif'
)
ON CONFLICT (sirket) DO UPDATE SET
    tedarikci_turu = EXCLUDED.tedarikci_turu,
    faaliyet_alani = EXCLUDED.faaliyet_alani,
    durum = EXCLUDED.durum;
