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
- Utu tamamla/kismi kaydet fire girisleri `fire_kayitlari` tablosuna yazilir. Mevcut semada `asama` alani fire kaynak asamasi olarak kullanilir; uretim raporu utu fire kaynak verisini once bu tablodan okur, kayit yoksa eski not fallback'ini kullanir.
- Utu sekmesinde `Tamamla`, kalan beden adedi varsa isi kapatir ve kalanlari `fire_kayitlari.asama='kayip'` olarak yazar; yeni islemde kayit acmaz. Kalan adet uretimde devam edecekse kullanici `Kismi Kaydet` kullanmalidir.
- Utu tamamla modalinda tamamlanan adet hedef adedi asabilir; fazla girilen adet fire veya kayip sayilmaz. Kalan hesaplamasi `max(hedef - tamamlanan - fire, 0)` olarak kalir ve UI fazla adedi bilgi olarak gosterir.

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
- Satis faturasi eklerken fatura kalemi secme/girme zorunlulugu yoktur; kalem karti satis turunde de gorunur. Kullanici kalem girerse tutarlar kalemlerden hesaplanir, kalem girmezse satis faturasi kalemsiz kaydedilebilir. Satis faturasi kalem modalinda kategori secimi pasiftir ve kalem kategorisi `diger` olarak tutulur.
- Alis faturasi eklerken kayitli tedarikci secimi zorunlu degildir. Kullanicinin yazdigi sirket/cari unvan `faturalar.cari_unvan` alaninda saklanir; kayitli tedarikci secilirse mevcut bilgiler fatura formuna otomatik doldurulur.
- Tedarikci kaydinda fatura adresi ve vergi dairesi `tedarikciler.adres` ve `tedarikciler.vergi_dairesi` alanlarinda tutulur; alis faturasi formunda kayitli tedarikci secilince bu bilgiler otomatik doldurulur.
- Fatura gider/alis kategorileri fatura basliginda degil `fatura_kalemleri.kategori` alaninda tutulur. Tek faturada birden fazla kategori olabilir; kategori ozetleri ve filtreler kalemlerden hesaplanir. Gecerli kategoriler: `iplik`, `aksesuar`, `fason_uretim`, `genel_gider`, `nakliye`, `personel`, `diger`.
- Fatura detay ekraninda kalem kategorileri tek tek veya toplu guncellenebilir. Toplu kategori islemi sadece ilgili `fatura_id + firma_id` kapsamindaki `fatura_kalemleri.kategori` alanini degistirir; fatura tutarlarini degistirmez.
- Faturalar sayfasi arama filtresi hem `faturalar` ust bilgilerini (`fatura_no`, `cari_unvan`, vergi/adres/aciklama alanlari) hem de `fatura_kalemleri` satirlarini (`urun_adi`, `urun_kodu`, `aciklama`, `kategori`) kapsar. Kalem eslesmeleri once `fatura_id` listesine cevrilir, sonra ana fatura sorgusundaki ust bilgi aramasiyla OR mantiginda birlestirilir.
- Uyumsoft gelen faturalar mevcut `faturalar` tablosuna dogrudan yazilmaz. Once `uyumsoft_gelen_faturalar` ve `uyumsoft_gelen_fatura_kalemleri` onay kuyruguna alinir; admin onaylarsa mevcut fatura sistemine `fatura_turu='alis'` ve `durum='taslak'` olarak aktarilir. Reddedilen veya bekleyen kayitlar normal fatura listesinde gorunmez.
- Uyumsoft XML/UBL yukleme Flutter tarafinda `UyumsoftFaturaService.xmlUblDosyasiYukle()` ile kuyruga eklenir. API senkronizasyonu `uyumsoft-gelen-faturalar-sync` Edge Function uzerinden tasarlanmistir; credential istemciye gomulmemelidir.
- Uyumsoft API credential bilgileri repo veya Flutter kodunda tutulmaz. Edge Function `UYUMSOFT_USERNAME`, `UYUMSOFT_PASSWORD`, `UYUMSOFT_VKN` ve opsiyonel `UYUMSOFT_ENDPOINT` Supabase secret'larini okur. "Uyumsoft'tan Cek" butonu bu Edge Function'i cagirir.
- Uyumsoft API icin portal giris kullanicisi degil, Uyumsoft'un verdigi Web Servis Kullanicisi ve Web Servis Sifresi kullanilir. Varsayilan e-Fatura endpointi `https://edonusumapi.uyum.com.tr/Services/Integration` olmalidir.
- Uyumsoft API cekimi tarih araligi, tarih tipi (`fatura` veya `olusturma`) ve limit parametreleriyle calisir. XML/UBL yukleme tek tek degil coklu dosya secimiyle de onay kuyruguna ekleme yapar; duplicate kontrolu `firma_id,kaynak,ettn` uzerinden korunur.
- Uyumsoft API cekiminde varsayilan tarih tipi `tum`dur; Edge Function hem fatura tarihi hem olusturma tarihi ile sayfali sorgu yapar ve arÅŸiv filtresini bos gondererek portalda gorunen kayitlari dislamamaya calisir. Limit her tarih tipi icin ayrÄ± uygulanir.
- Uyumsoft API liste sorgusunda bulunup detay XML/UBL verisi indirilemeyen faturalar kaybolmaz; `uyumsoft_gelen_faturalar.durum='hata'` olarak kuyrukta tutulur ve `red_sebebi` alaninda Uyumsoft detay hatasi saklanir. Bekleyen faturalarla karismamasi icin Uyumsoft gelen faturalar ekraninda `Hata` filtresi vardir.
- Uyumsoft gelen faturalar ekraninda sadece `beklemede`, `reddedildi` ve `hata` durumundaki onay kuyrugu kayitlari silinebilir. Silme once `uyumsoft_gelen_fatura_kalemleri`, sonra `uyumsoft_gelen_faturalar` uzerinden `firma_id` ve durum filtresiyle yapilir; `aktarildi` kayitlari ve mevcut `faturalar` sistemi bu islemden etkilenmez. Toplu silme yalnizca aktif filtrede listelenen silinebilir kayitlari kapsar.
- Uyumsoft veya XML/UBL kaynakli gelen faturalarda ayni firma icinde ayni `fatura_no` ya da `efatura_uuid` zaten mevcutsa yeni fatura numarasi uretmek icin suffix eklenmez. Kayit `aktarildi` olarak mevcut faturaya baglanir veya onay aninda islem durdurulur; ayni fatura numarasiyla ikinci fatura olusturulmaz.
- Uyumsoft aktariminda duplicate kontrolu `(firma_id, kaynak, ettn)` ve mevcut fatura tarafinda `efatura_uuid` ile yapilir. Tedarikci `vergi_no` ile eslesirse `tedarikci_id` doldurulur, eslesmezse `cari_unvan` ile taslak fatura olusturulur.
- Finans operasyon panelleri ERP ekranlari gibi kompakt ve tek satir KPI kullanacak sekilde tasarlanmalidir.
- Gelismis raporlar sayfasi yukleme finans raporu olarak tek amacli calisir. Ana veri `yukleme_kayitlari`dir; tarih filtresi yukleme tarihine uygulanir. Gerceklesen maliyet yoksa model fiyatlandirma/aktif plan maliyetiyle proforma analiz yapilir; gerceklesen maliyet varsa yalnizca ilgili maliyet kaleminin birim degeri degisir.
- Gelismis raporlar model bazli finans detayinda model satiri acilarak maliyet kirilimi gosterilir. Kirma verisi once aktif `model_maliyet_planlari` + `model_maliyet_kalemleri`, yoksa model detay fiyatlandirma alanlarindan (`iplik_maliyeti`, `orgu_fiyat`, `dikim_fiyat`, vb.) alinir.
- Gelismis raporlar finans merkezi olarak toplam ciro, uretim maliyeti, operasyonel gider, fire maliyeti, kayip kazanc, brut/net kar, marka bazli karlilik, aylik ciro/kar ve en karli/zararli model listelerini ayni servis ciktisindan uretir. Satis fiyati model detay fiyatlandirma verisinden gelir; fire maliyeti birim maliyet x fire adedi, kalan/yuklenmeyen adet ise zarar degil `kayipKazanc` olarak hesaplanir.
- Gelismis raporlar fire adedini once `fire_kayitlari`, yoksa uretim atama tablolarindaki `fire_adet`, en son `model_karlilik_ozetleri.fire_adedi` kaynaklarindan okur. Ayni fireyi cift saymamak icin kaynaklar toplanmaz; model bazinda en yuksek gecerli adet kullanilir.
- Gelismis raporlar ana kar orani fiyatlandirma sekmesiyle ayni bazdadir: `gercekKarOrani = netKar / genelToplamMaliyet * 100`. Satis gelirine gore oran ayrica `netKarMarji = netKar / satisGeliri * 100` olarak tutulur; ana tablo ve hedef karsilastirmasi maliyet bazli oranla calisir.
- Gelismis raporlar satis fiyatini eski `pesin_fiyat`, aktif plan `plan_satis_fiyati` veya `model_karlilik_ozetleri.satis_birim_fiyati` degerinden okumaz. Fiyatlandirma sekmesiyle ayni formul kullanilir: `planBirimMaliyet * (1 + kar_marji / 100)`, varsa vade orani uygulanir. `model_aksesuar` kaynakli otomatik `aksesuar` plan satirlari toplam maliyete alinmaz; manuel genel aksesuar `genel_aksesuar_fiyat` olarak kullanilir.
- Gelismis raporlar hesaplarina faturalar bolumundeki girilen faturalar simdilik dahil edilmez. Operasyonel gider hesabi gecici olarak yalnizca `kasa_banka_hareketleri` gider/cikis/odeme hareketlerinden beslenir; satis geliri model detay fiyatlandirma/yukleme verisinden gelir.
- Gelismis raporlar filtrelerinde tarih araligi `yukleme_kayitlari.tarih` bos ise `created_at` uzerinden degerlendirilir. Marka, durum ve arama filtreleri sayfa icinde donem model listesinden KPI, durum, marka analizi, maliyet dagilimi ve kar/zarar listelerini yeniden hesaplar; marka filtresi servise gonderilip secenek listesini daraltmaz.
- Model detay maliyet/karlilik sayfasi fiyatlandirma sekmesiyle ayni maliyet tabanini kullanir. `genel_aksesuar_fiyat` yalnizca fiyatlandirma sekmesindeki manuel genel aksesuar degeridir; `model_aksesuar` tablosundan hesaplanan aksesuar maliyeti bu iki sekmenin toplam maliyetine otomatik eklenmez.
- Model detay maliyet/karlilik sayfasinda satis fiyati aktif planin eski `plan_satis_fiyati` veya `model_karlilik_ozetleri.satis_birim_fiyati` degerinden okunmaz. Fiyatlandirma sekmesiyle ayni formul kullanilir: `planBirimMaliyet * (1 + kar_marji / 100)`, varsa vade orani ayrica uygulanir.
- Model detay maliyet/karlilik sayfasinda gerceklesen maliyet kaydi varsa yalnizca ilgili kalemin gercek birim maliyeti degisir. Kaydi olmayan maliyet kalemleri plan birim maliyetle hesaba dahil edilmeye devam eder; aksi halde tek kalemlik gerceklesen kayit modelin toplam maliyetini eksik gosterir.
- Gerceklesen maliyet kaydi "ek maliyet" degil, ilgili kalemin kullanici tarafindan girilen gercek tutaridir. Plan aksesuar 20 TL iken kullanici gercek tutari 11 TL girerse 9 TL model basina maliyet tasarrufu olarak kar etkisine yansir; negatif tutar girilmez.
- Model detay maliyet/karlilik sayfasinda `model_maliyet_gerceklesen` kayitlari satir bazinda duzenlenebilir ve silinebilir. Duzenleme/silme islemlerinde `id + firma_id + model_id` filtresi kullanilir ve ardindan `model_karlilik_ozeti_yenile` RPC calistirilir.
- Model detay maliyet/karlilik sayfasindaki Hesap Denetimi bolumunde `Tamamlanan` gostergesi uretim tamamlanan adetinden degil, `yukleme_kayitlari` / gonderim yapilan adet toplamindan okunur.
- Model detay maliyet/karlilik sayfasindaki Maliyet Kalemleri tablosunda `Sapma`, finansal etki olarak gosterilir: `plan birim - gercek birim`. Gercek maliyet planin altindaysa pozitif/tasarruf, ustundeyse negatif/ek maliyet gosterilir.

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
- Personel olusturma/yonetme Edge Function'lari `user_roles` kaydini firma kapsamli tutar: `user_id + firma_id + role='personel'`. `user_roles` icin tek basina `onConflict: 'user_id'` kullanilmaz; kayit once sorgulanir, varsa `aktif=true` yapilir, yoksa `firma_id` ile insert edilir.
- Personel detayindaki Avans/Odeme ve Puantaj sekmeleri secili donemle tutarli calisir. Avans/odeme finans ozeti, mesai/yemek/kesinti ve liste ayni donem kapsaminda hesaplanir. Puantaj sekmesi bu asamada `puantaj` tablosuna otomatik kayit yazmaz; izin, mesai ve personel ayarlarindan anlik hesaplanir. Calisilabilir gun hesabi `haftalik_calisma_gunu` ve `gunluk_calisma_saati` kullanir; bos degerlerde 6 gun / 8 saat varsayilir.
- Personel arşivinde bordro varsa kesinti `sgk_iscilik + gelir_vergisi + damga_vergisi` toplamıdır. Bordro yoksa brüt maaş üzerinden yaklaşık %20 kesinti yönetici tercihine bağlıdır; yönetici anahtarı açarsa toplam kesintiye ve net ödemeye yansır, kapalıysa otomatik düşülmez.
- İşten çıkışta kıdem/ihbar tazminatı önerisi hesaplanır, yönetici tutarı elle değiştirebilir. Tazminat ödemesi mevcut `odeme_kayitlari` tablosunda `odeme_turu='tazminat'` olarak beklemede oluşturulur; yalnızca onaylı tazminat rapor, puantaj ve arşiv toplamlarına ek kazanç olarak yansır.

## Bildirim Sistemi Hafizasi

Ilgili dosyalar:

- `lib/services/bildirim_service.dart`
- `lib/services/bildirim_navigation_service.dart`
- `lib/widgets/bildirim_popup.dart`
- `lib/pages/ayarlar/bildirimler_page.dart`

Notlar:

- Bildirimler firma kapsaminda calisir; alici/rol sorgularinda `firma_id` ve `aktif=true` filtresi kullanilmalidir.
- Bildirim hedef navigasyonu `ek_bilgi.target` icinde tutulur. Ornek hedefler: `izin`, `mesai`, `avans`, `stok`, `model`.
- Duplicate sistem uyarilari icin `bildirimler.event_key` kullanilir. Stok ve termin uyarilari gunluk tekil uretilmelidir.
- Admin kullanici bildirimler sayfasindan ayni firmadaki tek veya birden fazla aktif kullaniciya `genel` bildirim gonderebilir.
- Personel tarafindan girilen izin, mesai ve avans kayitlari servis katmaninda adminlere bildirim uretir; sayfa icinde kopya bildirim dongusu yazilmamalidir.
- Bildirime tiklandiginda once okundu isaretlenir, sonra `BildirimNavigationService` ile ilgili ekrana gidilir. Hedef yoksa detay modalinda kalinir.
- Yapilacak hatirlaticilari `tip='yapilacak_hatirlatici'` ve `ek_bilgi.target.page='yapilacak_popup'` ile tutulur; tiklaninca ana sayfadaki popup acilir.

## Yapilacaklar / Rutin Gorev Hafizasi

Ilgili dosyalar:

- `lib/services/yapilacak_service.dart`
- `lib/widgets/yapilacaklar_popup.dart`
- `supabase/migrations/20260614000100_yapilacaklar.sql`

Notlar:

- Gunluk/haftalik/aylik/tek seferlik rutinler `yapilacaklar` tablosunda, donem bazli tamamlanma bilgisi `yapilacak_tamamlanma_kayitlari` tablosunda tutulur.
- Donem reseti kayit silerek degil `donem_anahtari` ile hesaplanir: gunluk `YYYY-MM-DD`, haftalik `YYYY-WNN`, aylik `YYYY-MM`.
- Popup icinde dogrudan Supabase is kurali yazilmaz; ekleme, guncelleme, silme, tamamlama ve hatirlatici kontrolu `YapilacakService` uzerinden calisir.
- Tum sorgular `TenantManager.instance.requireFirmaId` ve `DbTables` sabitlerini kullanmalidir.
- Hatirlatici duplicate engeli `BildirimService` `event_key` sozlesmesiyle yapilir: `yapilacak:<id>:<donem>`.

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
- Model detay aksesuar sekmesinde aksesuar birim maliyeti `model basina kullanilacak adet * aksesuar birim fiyat` olarak hesaplanir; siparis maliyeti bu birim maliyetin siparis adediyle carpimidir.

## UI / Responsive Hafiza

- Web ve mobil birlikte dusunulmeli.
- Ana sayfalar ve paneller dikey scroll'a izin vermelidir.
- Ana sayfa KPI ozetinde toplam/yuklenen/kalan adetler model toplam adetleri ve `yukleme_kayitlari` toplamlari uzerinden hesaplanir. `Kapanan Is`, yukleme kaydi bulunan benzersiz model sayisidir.
- Ana sayfa KPI ozet kartlari yalnizca admin kullaniciya gosterilir.
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
