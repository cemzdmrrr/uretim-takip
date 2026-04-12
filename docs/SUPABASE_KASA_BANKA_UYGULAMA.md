# 🔧 SUPABASE KASA/BANKA ŞEMASI - UYGULAMA TALİMATI

## ⚠️ ÖNEMLİ UYARI
Kasa/Banka modülünü test etmek için önce Supabase veritabanınızda şemayı çalıştırmanız gerekiyor.

## 🚀 UYGULAMA ADIMLARI

### 1. Supabase Console'a Giriş
1. https://supabase.com adresine gidin
2. Projenize giriş yapın
3. "SQL Editor" bölümüne tıklayın

### 2. Şema Dosyasını Çalıştırın
1. `supabase_kasa_banka_schema.sql` dosyasının içeriğini kopyalayın
2. Supabase SQL Editor'e yapıştırın
3. "Run" butonuna tıklayın

### 3. Düzeltilen Hatalar
✅ **Tedarikçi Referansı Düzeltildi**
- `tedarikci` → `tedarikciler` (doğru tablo adı)

✅ **Field İsimleri Güncellendi**
- `hesap_adi` → `ad`
- `hesap_turu` → `tip`
- `iban_no` → `iban`
- `kur` → `doviz_turu`
- `aktif` → `durumu`

### 4. Oluşturulacak Tablolar
- ✅ `kasa_banka_hesaplari` - Ana hesap tablosu
- ✅ `kasa_banka_hareketleri` - Hareket tablosu (gelecekte kullanılacak)
- ✅ Views ve trigger'lar
- ✅ Örnek veri (3 test hesabı)

### 5. Test Verileri
Şema çalıştırıldığında aşağıdaki test hesapları otomatik oluşturulacak:

1. **Ana Kasa** (KASA)
   - Bakiye: 10,000.00 TRY
   
2. **İş Bankası Vadesiz** (BANKA)
   - Bakiye: 50,000.00 TRY
   - IBAN: TR320006400000011234567890
   
3. **İş Bankası USD** (BANKA)
   - Bakiye: 1,000.00 USD
   - IBAN: TR320006400000011234567891

## 📱 UYGULAMA TESTİ

Şema uygulandıktan sonra:

1. Flutter uygulamasını çalıştırın
2. Ana sayfada "Kasa & Banka" butonuna tıklayın
3. 3 test hesabını görmeniz gerekiyor
4. Yeni hesap ekleme/düzenleme/silme işlemlerini test edin

## 🐛 SORUN GİDERME

**Hata: "relation does not exist"**
- Şema dosyasının tamamen çalıştırıldığından emin olun
- SQL Editor'de hata mesajları varsa düzeltin

**Hesaplar gözükmüyor**
- RLS (Row Level Security) kurallarını kontrol edin
- Supabase auth token'ının geçerli olduğundan emin olun

**Hata: "permission denied"**
- Supabase project ayarlarında gerekli izinleri kontrol edin

## 📞 YARDIM

Herhangi bir sorun yaşarsanız:
1. Supabase logs bölümünü kontrol edin
2. Flutter debug console'unu kontrol edin
3. Şema dosyasını tekrar çalıştırmayı deneyin

**Şema hazır ve test edilmeye hazır! 🎉**
