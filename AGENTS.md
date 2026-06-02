# Codex Proje Hafizasi

Bu repo buyuk olcekli Flutter + Supabase tabanli tekstil ERP sistemidir. Yeni bir isleme baslamadan once bu dosya ve `docs/PROJECT_MEMORY.md` okunmalidir.

## Calisma Kurallari

- Once mevcut mimariyi ve ilgili servisleri kontrol et; dogrudan sayfa icinde kopya is mantigi yazma.
- Supabase tablo adlari icin her zaman `lib/config/database_tables.dart` icindeki `DbTables` sabitlerini kullan.
- Firma/tenant kapsami gereken sorgularda `TenantManager.instance.requireFirmaId` kullan ve `firma_id` filtresini unutma.
- Uretim durum gecislerinde direkt `update({'durum': ...})` yazma; `WorkflowTransitionService.applyTransition()` kullan.
- Uretim asamalari icin statik switch/case eklemeden once `AsamaRegistry` ve firma aktif uretim dallarini kontrol et.
- Beden bazli uretim akisini toplam adet uzerinden basitlestirme; `BedenService`, `beden_detaylari` ve `*_beden_takip` zincirini koru.
- Kismi tamamlama islemlerinde kalan hedef adet beden bazli hesaplanmali; tamamlanan/kismi adet sonraki asamaya beden bazli aktarilmali.
- Mevcut kullanici degisikliklerini geri alma. Ilgisiz refactor yapma.
- Frontend degisikliklerinde mobil gorunumu ve dikey scroll davranisini kontrol et.
- Yeni veya degisen mimari karar varsa `docs/PROJECT_MEMORY.md` dosyasini guncelle.

## Hata Onleme Kontrol Listesi

- Degisiklikten sonra ilgili dosya icin `dart format` calistir.
- En az ilgili dosya veya klasor icin `flutter analyze` calistir.
- Uretim paneli, model detay, sevkiyat, kalite, utu/paket gibi zincir ekranlarinda tablo/beden/durum baglantilarini ayrica kontrol et.
