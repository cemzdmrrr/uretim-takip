# Admin Kurulum Rehberi

## Admin Rolü Güncellemeleri Tamamlandı ✅

### Yapılan Değişiklikler:

#### 1. Flutter Uygulama Tarafı:
- **Ana Sayfa (ana_sayfa.dart)**: Admin kullanıcılar artık tüm dashboard'lara ve modüllere erişebilir
- **Generic Dashboard (uretim_asama_dashboard.dart)**: Admin kontrolü eklendi
- **Model Listele (model_listele.dart)**: Gerçek admin kontrolü entegrasyonu
- **Personel Ana Sayfa (personel_anasayfa.dart)**: Admin+IK yetkileri güncellendi
- **Kullanıcı Listesi (kullanici_listesi.dart)**: Admin kontrolü yorumlandı
- **Auth Helper (auth_helper_new.dart)**: Kapsamlı yetki kontrol sistemi

#### 2. Admin Test Sistemi:
- **Admin Test Sayfası (admin_test_page.dart)**: Admin yetkilerini test etmek için kapsamlı test paneli
- Ana sayfadan "Admin Test Paneli" ile erişilebilir
- Rol kontrolü, yetki testi, veritabanı bağlantı testi

#### 3. Veritabanı Politikaları:
- **admin_tam_yetki_politikalari.sql**: Tüm tablolar için admin tam yetki politikaları
- **admin_setup_kontrol.sql**: Admin kullanıcı oluşturma ve kontrol script'i

### Admin Özellikleri:

#### ✅ Tam Erişim:
- **Tüm Üretim Dashboardları**: Dokuma, Konfeksiyon, Yıkama, Ütü, İlik Düğme, Kalite Kontrol, Paketleme
- **Finansal Yönetim**: Tedarikçi, Faturalar, Kasa/Banka, Hareketler, Dosyalar
- **İnsan Kaynakları**: Personel Yönetimi, Kullanıcı Listesi
- **Stok & Üretim**: Model ekleme, listeleme, raporlar, sevkiyat, depo yönetimi

#### ✅ Özel Yetkiler:
- Tüm veritabanı tablolarına SELECT, INSERT, UPDATE, DELETE
- Kullanıcı rol yönetimi
- Sistem ayarları değiştirme
- Dönem yönetimi
- İzin/mesai onayları

### Kullanım:

#### Admin Olmak İçin:
1. Uygulamaya kayıt olun/giriş yapın
2. Admin Test Paneli'ne gidin
3. "Admin Yap" butonuna tıklayın
4. Sayfayı yenileyin

#### Veritabanından Admin Yapmak:
```sql
-- Kullanıcı ID'sini değiştirin
UPDATE public.user_roles 
SET role = 'admin', aktif = true 
WHERE user_id = 'KULLANICI_UUID_BURAYA';
```

#### Manuel Kontrol:
```sql
-- Admin kullanıcıları listele
SELECT ur.user_id, ur.role, u.email 
FROM public.user_roles ur
JOIN auth.users u ON ur.user_id = u.id 
WHERE ur.role = 'admin';
```

### Test Edilecekler:

1. **✅ Ana Sayfa**: Admin kullanıcıyla giriş yaptığınızda tüm modülleri görmeli
2. **✅ Dashboard Erişimi**: Tüm üretim aşaması dashboard'larına erişebilmeli
3. **✅ Admin Test Paneli**: Yeşil "Admin Kullanıcı" durumu görmeli
4. **✅ Veritabanı İşlemleri**: Tüm CRUD işlemleri çalışmalı
5. **✅ Finansal Modüller**: Fatura, tedarikçi, kasa/banka işlemleri

### Sorun Giderme:

#### Admin Yetkileri Çalışmıyorsa:
1. `admin_tam_yetki_politikalari.sql` dosyasını çalıştırın
2. Kullanıcı rolünü kontrol edin: `SELECT * FROM user_roles WHERE user_id = auth.uid()`
3. Tarayıcı cache'ini temizleyin
4. Uygulamadan çıkış yapıp tekrar giriş yapın

#### Veritabanı Bağlantı Sorunu:
1. Supabase bağlantı ayarlarını kontrol edin
2. RLS politikalarının aktif olduğundan emin olun
3. `admin_setup_kontrol.sql` ile sistem durumunu kontrol edin

### Geliştirici Notları:

- **Admin Politikaları**: Her yeni tablo için admin politikası eklenmeli
- **Frontend Kontrolü**: Yeni sayfalarda `currentUserRole == 'admin'` kontrolü eklenmeli  
- **Güvenlik**: Admin yetkileri production'da dikkatli yönetilmeli
- **Test Sistemi**: `AdminTestPage` sürekli güncel tutulmalı

### Son Durum:
🎉 **Admin rolü sistemi tamamen entegre edildi!**
Admin kullanıcılar artık tüm yetkilere sahip ve tüm modülleri kullanabilir.
