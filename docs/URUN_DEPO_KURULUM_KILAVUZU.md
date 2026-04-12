# ÜRÜN DEPO YÖNETİMİ KURULUM KILAVUZU

## 📋 Özet
DEPO YÖNETİMİ sayfasına yeni bir "ÜRÜN DEPO" sekmesi eklendi. Bu sekme, üretimden artan ve kalite kontrolünü geçen ürünleri depolamak için kullanılır.

---

## 🎯 Özellikler

### 1️⃣ KALITE SEKMESI
- **1. Kalite Ürünleri**: Kalitesi iyi olan ürünlerin depolanması
- İstatistikler:
  - Toplam ürün sayısı
  - Toplam adet
- Ürün Ekle / Sil işlemleri

### 2️⃣ & 3️⃣ KALİTE SEKMESI
- **2. Kalite & 3. Kalite Ürünleri**: Kalitesi orta ve düşük olan ürünler
- Aynı istatistikler ve işlemler

---

## 📱 KULLANIM

### Ürün Ekleme Adımları:
1. **Depo Yönetimi** → **Ürün Depo** sekmesine git
2. İstediğin kalite sekmesine (1. Kalite veya 2. & 3. Kalite) geç
3. **"Ürün Ekle"** butonuna tıkla
4. Aşağıdaki bilgileri doldur:
   - **Sipariş Seç**: Tamamlanmış siparişlerden seç (Marka - Item No - Renk)
   - **Adet**: Kaç adet ürün depoya eklenecek
   - **Açıklama**: İsteğe bağlı not (örn: "Lekeyle geldi", "Renk sorunu")
5. **Ekle** butonuna tıkla

### Ürün Silme:
1. Silmek istediğin ürüne tıkla
2. **Sil** ikonuna tıkla
3. Onay ver

### Filtreleme:
- Arama alanını kullanarak açıklama ile ara

---

## 🗄️ DATABASE KURULUMU

### 1. SQL Tablosu Oluşturma

⚠️ **ÖNEMLİ**: Aşağıdaki SQL komutlarını **Supabase Dashboard** → **SQL Editor**'de çalıştırmalısın.

**Dosya**: `create_urun_depo_table.sql`

### Adımlar:
1. Supabase Dashboard'a gir (https://app.supabase.com)
2. Proje seç → **SQL Editor** tıkla
3. **New Query** → **New Blank Query** seç
4. `create_urun_depo_table.sql` dosyasının içeriğini kopyala
5. Paste et ve **RUN** butonuna tıkla

### Tablo Yapısı:
```
urun_depo (Ürün Depo Tablosu)
├── id (UUID, Primary Key)
├── model_id (BIGINT, FK → triko_takip)
├── kalite_tipi (VARCHAR: '1. Kalite' veya '2. & 3. Kalite')
├── adet (INT, > 0)
├── aciklama (TEXT, opsiyonel)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### Indexes:
- `idx_urun_depo_kalite` - Kalite tipi ile hızlı sorgulama
- `idx_urun_depo_model` - Model ID ile hızlı sorgulama
- `idx_urun_depo_created` - Tarih sıraları için

### RLS (Row Level Security) Politikaları:
- **Admin**: Tüm ürünleri görebilir ve yönetebilir
- **Depo Personeli** (depo, depocu): Görüntüleyebilir, ekleyebilir, silebilir
- **Diğer Roller**: Sadece görüntüleyebilir

---

## 📊 VERİ SORGULAMA

### Tüm Ürünleri Listele:
```sql
SELECT * FROM urun_depo ORDER BY created_at DESC;
```

### Kalite Tipine Göre Adet:
```sql
SELECT kalite_tipi, COUNT(*) as urun_sayisi, SUM(adet) as toplam_adet
FROM urun_depo
GROUP BY kalite_tipi;
```

### Belirli Siparişe Ait Ürünler:
```sql
SELECT u.*, t.marka, t.item_no, t.renk
FROM urun_depo u
JOIN triko_takip t ON u.model_id = t.id
WHERE u.model_id = [MODEL_ID]
ORDER BY u.created_at DESC;
```

---

## 🔒 YETKI KONTROL

| Rol | Select | Insert | Delete |
|-----|--------|--------|--------|
| Admin | ✅ | ✅ | ✅ |
| Depo/Depocu | ✅ | ✅ | ✅ |
| Diğer Roller | ✅ | ❌ | ❌ |
| Anonim | ❌ | ❌ | ❌ |

---

## 🛠️ SORUN GIDERME

### 1. "Tablo bulunamadı" hatası
→ `create_urun_depo_table.sql` dosyasını Supabase'de çalıştır

### 2. "İzin reddedildi" hatası
→ RLS politikalarını Supabase'de kontrol et
→ Kullanıcı rolünün `depo` veya `depocu` olduğundan emin ol

### 3. Ürün ekleme boş sipariş listesi gösteriyor
→ `triko_takip` tablosunda `tamamlandi = true` olan siparişler olduğundan emin ol

### 4. Veritabanı bağlantısı başarısız
→ Supabase URL ve Key'in `pubspec.yaml`'da doğru olduğundan emin ol

---

## 📁 İLGİLİ DOSYALAR

- **Frontend**: `lib/urun_depo_yonetimi.dart` - Ürün Depo sayfası
- **Frontend**: `lib/stok_yonetimi.dart` - Ana Stok Yönetimi (güncellenmiş)
- **Database**: `create_urun_depo_table.sql` - Tablo oluşturma SQL'i

---

## ✅ KONTROL LİSTESİ

- [x] Dart UI sayfası oluşturuldu
- [x] Stok Yönetimi'ne 3. sekme eklendi
- [x] SQL tablo şeması hazırlandı
- [ ] SQL tablo Supabase'de oluşturuldu
- [ ] RLS politikaları aktif
- [ ] Test edilerek onaylandı

---

## 📞 NOTLAR

- Ürünler otomatik olarak tamamlanan siparişlerden seçilir
- Her ürüne açıklama ekleyebilirsin (isteğe bağlı)
- Silinen ürünler geri alınamaz (cascade delete)
- Depo sorumlusu ürün eklediğinde otomatik tarih/saat kaydedilir

---

**Son Güncelleme**: 3 Ocak 2026
**Versiyon**: 1.0
