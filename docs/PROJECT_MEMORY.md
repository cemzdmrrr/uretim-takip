# Proje Hafizasi

Bu dosya, uretim_takip projesinde context kaybini azaltmak icin kalici mimari hafizadir. Kod degistirmeden once ilgili bolum okunmali, yeni mimari kararlar buraya eklenmelidir.

## Proje Ozeti

- Uygulama: Flutter + Supabase tabanli tekstil uretim ERP sistemi.
- Ana alanlar: uretim takip, model detay, sevkiyat, kalite kontrol, stok/depo, finans, fatura, personel, bordro, raporlama.
- Multi-tenant yapi vardir. Hemen hemen tum operasyonel tablolar `firma_id` ile firma kapsaminda calisir.
- Tablo adlari merkezi kaynak: `lib/config/database_tables.dart`.
- Tenant/firma merkezi kaynak: `lib/services/tenant_manager.dart`.

## Mimari Ilkeler

- Sayfa icinde agir is kurali yazmak yerine mevcut servisleri kullan.
- Supabase sorgularinda sabit string tablo adi yazmak yerine `DbTables` kullan.
- `firma_id` filtreleri unutulmamali. Kullanici yetki ve aktif firma bilgisi `TenantManager` uzerinden alinmali.
- Dinamik uretim asamalari icin `AsamaRegistry` kullanilmali; firma konfiguasyonuna duyarsiz sabit asama listeleri yeni kodda tercih edilmemeli.
- Uretim zincirinde durum, adet ve beden bilgisi birbirine baglidir. Birini degistirirken digerlerini kontrol et.
- UI degisikliklerinde ERP tarzina uygun, yogun ama okunabilir ekranlar hedeflenir. Mobilde butun ana sayfalar asagi kaydirilabilir olmalidir.

## Kritik Servisler

### WorkflowTransitionService

Dosya: `lib/services/workflow_transition_service.dart`

- Uretim atamalarinda durum gecisleri icin ana servistir.
- RPC: `apply_workflow_transition`.
- Idempotency, tenant guard ve fallback update mantigi vardir.
- Model detay veya panel icinde dogrudan `durum` update etmek yerine bu servis kullanilmalidir.
- Idempotency key formati daha once model detay icin su sekilde kullanildi:
  `${tablo}:${atamaId}:${yeniDurum}:${atama['updated_at']}`

### BedenService

Dosya: `lib/services/beden_service.dart`

- Model beden dagilimi, asama beden takip ve asama arasi beden aktarimindan sorumludur.
- `model_beden_dagilimi`, `model_beden_ozet`, `*_beden_takip` tablolarini kullanir.
- Kismi/tam tamamlama islemleri beden bazli calismalidir.
- Toplam adet uzerinden bolme veya esit dagitma, ancak modelin ilk beden dagilimi yoksa fallback olarak dusunulmelidir.
- Onemli metodlar:
  - `getModelBedenDagilimi`
  - `updateUretimBedenlerToplu`
  - `getOncekiAsamaGerceklesenAdetler`
  - `updateSonrakiAsamaHedefAdetler`
  - `hedefAdetleriOncekiAsamadanAl`

### AsamaRegistry

Dosya: `lib/config/asama_registry.dart`

- Firma/tekstil dali bazli asama tanimlarini DB'den yukler.
- Fallback olarak triko ve diger tekstil dallari icin sabit asamalar vardir.
- `dashboardAsamalari`, `asamaBul`, `atamaTablosuGetir` kullanilmalidir.
- Paketleme ve sevkiyat dashboard gosteriminde ozel davranir; sevkiyat ayri modul, paketleme bazi ekranlarda gizli olabilir.

### DashboardEventBus

Dosya: `lib/services/dashboard_event_bus.dart`

- Uretim paneli ve model detay gibi ekranlar arasi yenileme/event haberlesmesi icin kullanilir.
- Atama/durum/uretim degisikliklerinden sonra ilgili ekranlarin stale kalmamasi icin event yayinlama/dinleme kontrol edilmelidir.

## Uretim Zinciri Hafizasi

Temel akış:

Dokuma -> Konfeksiyon -> Nakış -> Yıkama -> İlik/Düğme -> Ütü -> Kalite Kontrol -> Paketleme -> Sevkiyat

Notlar:

- Firma aktif uretim dallarina gore asamalar degisebilir; bu nedenle statik akis her ekranda dogrudan kullanilmamali.
- Konfeksiyondan tamamlanan adet kalite kontrol paneline gelmeli; kaliteden onaylanirsa sevkiyat paneline gecmeli.
- Uretim islemleri beden adetleri uzerinden yurumeli.
- Sevkiyat veya diger panellerden sonraki asamaya giden adetler siparis beden sayisina bolunmemeli; gelen beden adetleri korunmali.
- Ayni uretim asamasina ayni modelden tekrar adet gelirse kayitlar beden adetleri gozetilerek birlestirilmeli.
- Uretim, kalite kontrol ve sevkiyat panellerinde ayni `model_id` ayni durum grubunda birden fazla kart olarak listelenmemeli. Listeleme tarafinda `AtamaBirlestirmeService.mergeForDisplay`, yazma tarafinda `AtamaBirlestirmeService.insertOrMerge` kullanilmalidir.
- Kismi kayitte:
  - Girilen beden adedi tamamlanan/kismi olarak kaydedilir.
  - Hedef adet ilgili beden icin `hedef - girilen` olarak azalir.
  - Tamamlanan/kismi adet sonraki asamaya beden bazli aktarilir.
  - Bir beden tamamen uretildiyse sonraki modalda hedefi 0 gorunmelidir.

## Uretim Atama Tablolari

Merkezi sabitler `DbTables` icindedir:

- `dokuma_atamalari`
- `konfeksiyon_atamalari`
- `nakis_atamalari`
- `yikama_atamalari`
- `ilik_dugme_atamalari`
- `utu_atamalari`
- `kalite_kontrol_atamalari`
- `paketleme_atamalari`
- `sevkiyat_kayitlari`

Legacy ve genel yapi birlikte bulunur:

- Eski/ozel atama tablolari halen aktif kullanilir.
- Phase 8 genel uretim icin `uretim_atamalari`, `asama_tanimlari`, `dal_form_alanlari` da vardir.
- Yeni kodda hangi tablo kullanilacaksa `AsamaRegistry` ve mevcut ekran paterni kontrol edilmelidir.

## Durum Degerleri

Uretim atamalarinda yaygin durumlar:

- `bekleyen`
- `atandi`
- `onaylandi`
- `baslandi`
- `devam_ediyor`
- `uretimde`
- `baslatildi`
- `kismi_tamamlandi`
- `tamamlandi`
- `sevk_ediliyor`
- `reddedildi`
- `iptal`

Notlar:

- `kismi_tamamlandi` islemde/devam eden durum gibi ele alinmalidir.
- Durum etiketi metinleri panel ve model detay arasinda tutarli tutulmalidir.
- Durum gecisleri `WorkflowStateMachine` kurallarina takilabilir; yeni gecis gerekiyorsa state machine kontrol edilmelidir.

## Model Detay ve Uretim Paneli Baglantisi

Ilgili dosyalar:

- `lib/pages/model/model_detay_admin.dart`
- `lib/pages/model/model_detay_uretim.dart`
- `lib/pages/model/model_detay.dart`
- `lib/pages/uretim/uretim_asama_dashboard.dart`
- `lib/pages/uretim/uretim_asama_aksiyonlar.dart`
- `lib/pages/uretim/uretim_asama_dashboard_dialog.dart`

Kurallar:

- Model detaydaki atama kabul/uretime alma/iptal islemleri de uretim paneli gibi `WorkflowTransitionService` kullanmalidir.
- Yeni atama yapilirken downstream beden zinciri kirilmamali; onceki asama gerceklesen beden adetleri `beden_detaylari` olarak tasinmalidir.
- Tamamlama dialoglari per-beden calismali ve ilgili `*_beden_takip` tablosuna yazmalidir.

## Utu, Paketleme, Ceki Listesi

Ilgili dosyalar:

- `lib/pages/uretim/utu_paket_dashboard.dart`
- `lib/pages/uretim/utu_paket_paketleme.dart`
- `lib/pages/uretim/utu_paket_dialoglar.dart`
- `lib/pages/uretim/utu_paket_ceki_islemleri.dart`

Notlar:

- Sekme adi kullanici istegiyle `Ütü` olarak sadeleştirildi veya sadeleştirilmesi beklenir.
- Ütü işlemde kısmında kısmi kaydet ve tamamla davranışları beden bazlı olmalıdır.
- Çeki listesi sadece ütüde tamamlanan beden adedi kadar oluşturulabilmelidir; fazla/eksik girişte kullanıcı uyarılmalıdır.
- Fire kaynakları adet bazlı ve birden fazla kaynak aşamaya bölünebilir olmalıdır.

## Finans ve Fatura Hafizasi

Ilgili tablolar:

- `faturalar`
- `fatura_kalemleri`
- `kasa_banka_hesaplari`
- `kasa_banka_hareketleri`
- `odeme_kayitlari`
- `yapilacak_odemeler`

Notlar:

- Fatura kalemlerinde virgullu/ondalik birim fiyat kabul edilmelidir.
- Fatura olusturulduktan sonra detayda KDV tutar ve toplam hesaplamalari calismalidir.
- Fatura duzenlemede mevcut kalemler sifirlanmamali; kalem bazli duzenle/sil olmalidir.
- Finans operasyon panelleri ERP ekranlari gibi kompakt ve tek satir KPI kullanacak sekilde tasarlanmalidir.

## Personel, Bordro ve Donem Hafizasi

Ilgili tablolar:

- `personel`
- `personel_donem`
- `bordro`
- `puantaj`
- `mesai`
- `izinler`
- `donemler`

Ilgili dosyalar:

- `lib/pages/personel/personel_anasayfa.dart`
- `lib/pages/personel/personel_listesi_page.dart`
- `lib/pages/personel/personel_analiz_page.dart`
- `lib/pages/personel/personel_analiz_widgets.dart`
- `lib/pages/personel/personel_ayarlar_page.dart`
- `lib/pages/muhasebe/bordro_page.dart`
- `lib/services/donem_service.dart`
- `lib/services/puantaj_service.dart`

Notlar:

- Personel raporlama ve analiz ekranlari ERP rapor merkezi gibi tasarlanir.
- Tum personel sayfalari mobilde asagi kaydirilabilir olmalidir.
- Bordro sayfasi kapanis kontrolu, arama, filtre, onayli/onaysiz/bordrosuz durumlari, PDF ve yazdirma aksiyonlarini desteklemelidir.
- Donem bazli filtreleme `donemler` ve secili yil/ay mantigiyla uyumlu olmalidir.

## Stok, Iplik, Aksesuar Hafizasi

Ilgili tablolar:

- `iplik_stoklari`
- `iplik_hareketleri`
- `iplik_siparisleri`
- `iplik_stok_hareketleri`
- `aksesuarlar`
- `aksesuar_stok`
- `aksesuar_kullanim`
- `model_aksesuar`

Notlar:

- Iplik depoda ayni renk kodu ve lot numarasina sahip girisler stok deposunda birlestirilmelidir.
- Model aksesuar kullaniminda model basina adet 0.025 gibi ondalikli degerleri desteklemelidir.

## UI / Responsive Hafiza

- Web ve mobil birlikte dusunulmeli.
- Ana sayfalar ve paneller dikey scroll'a izin vermelidir.
- Mobilde sabit `Column + Expanded` yapilari ust filtre/tab alanlarini kilitleyebilir; gerekirse `SingleChildScrollView`, `CustomScrollView` veya `NestedScrollView` kullan.
- Buton ikonlari icin mevcut Material Icons veya yerel ikon setleri kullanilmali; gorunmeyen ikonlar kontrol edilmelidir.
- ERP ekranlari genelde kompakt KPI satirlari, filtre paneli, tablo/kart listesi ve aksiyon butonlariyla tasarlanir.

## Degisiklik Sonrasi Zorunlu Kontrol

1. Ilgili dosyalari formatla:
   `dart format <dosyalar>`
2. Ilgili dosya veya klasoru analiz et:
   `flutter analyze <dosya-veya-klasor>`
3. Uretim zinciri etkileniyorsa beden/durum/sonraki asama akisini manuel kontrol et.
4. Finans/personel ekranlari etkileniyorsa mobil scroll ve tablo yatay scroll kontrol et.

## Hafiza Guncelleme Kurali

Asagidaki durumlardan biri olursa bu dosyayi guncelle:

- Yeni kritik servis eklendi.
- Supabase tablo/kolon sozlesmesi degisti.
- Uretim asama akisi veya durum gecisi degisti.
- Beden bazli uretim davranisi degisti.
- Personel/bordro/finans gibi modul mimarisi degisti.
- Kullanici ayni hatayi tekrar bildirdi ve kalici kural gerekiyorsa.
