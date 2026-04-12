-- Kalite kontrol tablosuna test verisi ekle

-- 1. Önce mevcut verileri kontrol et
SELECT * FROM kalite_kontrol_atamalari;

-- 2. Test verisi ekle (ID 25'teki tamamlanan işi kalite kontrole gönder)
INSERT INTO kalite_kontrol_atamalari (
    model_id,
    durum,
    onceki_asama,
    atama_tarihi,
    created_at,
    notlar
) VALUES (
    (SELECT model_id FROM dokuma_atamalari WHERE id = 25),
    'atandi',
    'Dokuma',
    NOW(),
    NOW(),
    'Test: Dokuma aşaması tamamlandı - Dokuma ID: 25'
);

-- 3. Eklenen veriyi kontrol et
SELECT kk.*, tt.marka, tt.item_no, tt.renk
FROM kalite_kontrol_atamalari kk
LEFT JOIN triko_takip tt ON kk.model_id = tt.id
ORDER BY kk.created_at DESC;