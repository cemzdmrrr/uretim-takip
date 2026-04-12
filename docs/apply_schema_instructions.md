# Supabase Şema Uygulama Talimatları

## Yöntem 1: Supabase Dashboard (Önerilen)

1. https://supabase.com/dashboard adresine gidin
2. Projenizi seçin
3. Sol menüden "SQL Editor" seçin
4. "New query" butonuna tıklayın
5. `comprehensive_database_schema.sql` dosyasının tüm içeriğini kopyalayıp yapıştırın
6. "Run" butonuna tıklayın

## Yöntem 2: psql ile Bağlantı

Eğer psql kuruluysa:

```bash
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" -f comprehensive_database_schema.sql
```

PROJECT_REF ve PASSWORD bilgilerini Supabase Dashboard > Settings > Database bölümünden alabilirsiniz.

## Yöntem 3: pgAdmin veya diğer PostgreSQL araçları

1. Supabase veritabanına bağlanın
2. comprehensive_database_schema.sql dosyasını çalıştırın

## Şema Uygulandıktan Sonra Kontrol

Şema başarıyla uygulandıktan sonra şu tabloların oluştuğunu kontrol edin:

- user_roles
- kullanicilar  
- adminler
- notifications
- personel (tckn kolunu kontrol edin!)
- musteriler
- tedarikciler
- triko_takip
- faturalar
- kasa_banka_hesaplari
- Ve diğer tüm tablolar...

## TCKN Hatası Çözümü

Eğer "column tckn does not exist" hatası alırsanız:

1. Önce eski indeksi silin:
```sql
DROP INDEX IF EXISTS idx_personel_tckn;
```

2. Sonra personel tablosuna tckn kolonunu ekleyin:
```sql
ALTER TABLE public.personel ADD COLUMN IF NOT EXISTS tckn TEXT UNIQUE;
```

3. İndeksi yeniden oluşturun:
```sql
CREATE INDEX IF NOT EXISTS idx_personel_tckn ON public.personel(tckn);
```
