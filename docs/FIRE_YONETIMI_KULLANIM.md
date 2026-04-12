# AŞAMA ARASI FİRE YÖNETİMİ SİSTEMİ

## Genel Bakış

Bu sistem, üretim aşamaları arasında fire (kayıp/hatalı ürün) durumunda gerçek adetlerin bir sonraki aşamaya aktarılmasını sağlar.

## Senaryo Örneği

### Başlangıç Adetleri
```
S: 100 adet
M: 100 adet
L: 100 adet
```

### 1. DOKUMA Aşaması
```
Üretilen:        S:100, M:100, L:100
Fire:            S:10,  M:0,   L:0
Gerçekleşen:     S:90,  M:100, L:100  → Bir sonraki aşamaya bunlar geçer
```

### 2. KONFEKSİYON Aşaması
```
Hedef (Otomatik): S:90,  M:100, L:100  (Dokumadan gelen)
Üretilen:         S:90,  M:100, L:100
Fire:             S:0,   M:20,  L:0
Gerçekleşen:      S:90,  M:80,  L:100  → Bir sonraki aşamaya bunlar geçer
```

### 3. YIKAMA Aşaması
```
Hedef (Otomatik): S:90, M:80, L:100  (Konfeksiyondan gelen)
```

## SQL Kurulum

### 1. SQL Dosyasını Çalıştır
```sql
-- Supabase SQL Editor'de çalıştır:
psql -f asama_adet_aktarimi.sql
```

veya Supabase Dashboard > SQL Editor'de `asama_adet_aktarimi.sql` dosyasının içeriğini çalıştır.

## Flutter/Dart Kullanımı

### 1. Otomatik Aktarım (Önerilen)

Bir aşama tamamlandığında, uygulama tarafında şunu çağır:

```dart
import 'package:uretim_takip/services/beden_service.dart';

final _bedenService = BedenService();

// Dokuma tamamlandığında
Future<void> dokumaTamamla() async {
  // 1. Dokuma için üretim kaydet
  await _bedenService.updateUretimBedenlerToplu(
    asama: 'dokuma',
    atamaId: dokumaAtamaId,
    modelId: modelId,
    bedenVerileri: {
      'S': {'hedef_adet': 100, 'uretilen_adet': 100, 'fire_adet': 10},
      'M': {'hedef_adet': 100, 'uretilen_adet': 100, 'fire_adet': 0},
      'L': {'hedef_adet': 100, 'uretilen_adet': 100, 'fire_adet': 0},
    },
  );

  // 2. Konfeksiyonun hedef adetlerini otomatik güncelle
  await _bedenService.updateSonrakiAsamaHedefAdetler(
    modelId: modelId,
    tamamlananAsama: 'dokuma',
    sonrakiAtamaId: konfeksiyonAtamaId,
  );
}
```

### 2. Manuel Aktarım

Bir aşama başlarken, önceki aşamadan adetleri manuel çekebilirsiniz:

```dart
// Konfeksiyon başlarken
Future<void> konfeksiyonBaslat() async {
  // Dokumadan gerçekleşen adetleri çek ve hedef olarak ayarla
  await _bedenService.hedefAdetleriOncekiAsamadanAl(
    modelId: modelId,
    asama: 'konfeksiyon',
    atamaId: konfeksiyonAtamaId,
  );
}
```

### 3. Önceki Aşama Adetlerini Görüntüleme

```dart
// Bir sonraki aşamaya geçecek adetleri göster
Future<Map<String, int>> getGecisAdetleri() async {
  final adetler = await _bedenService.getOncekiAsamaGerceklesenAdetler(
    modelId,
    'konfeksiyon', // Hangi aşamaya geçecek?
  );
  
  print(adetler); // {'S': 90, 'M': 100, 'L': 100}
  return adetler;
}
```

## Dashboard Entegrasyonu

### Üretim Tamamlama Dialog'unda

`_BedenUretimTamamlaDialog` widget'ında kaydet butonuna ekle:

```dart
Future<void> _kaydet() async {
  setState(() => kaydediliyor = true);
  
  try {
    // 1. Mevcut üretim kaydetme kodu...
    await _bedenService.updateUretimBedenlerToplu(...);
    
    // 2. ✨ YENİ: Bir sonraki aşamaya adetleri aktar
    if (widget.atama['durum'] == 'tamamlandi') {
      // Sonraki atama ID'sini bulun (veya parametre olarak alın)
      final sonrakiAtamaId = await _getSonrakiAtamaId();
      
      if (sonrakiAtamaId != null) {
        await _bedenService.updateSonrakiAsamaHedefAdetler(
          modelId: widget.modelId,
          tamamlananAsama: 'dokuma', // widget.asama
          sonrakiAtamaId: sonrakiAtamaId,
        );
      }
    }
    
    widget.onComplete();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Kaydedildi ve sonraki aşamaya aktarıldı')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Hata: $e')),
    );
  } finally {
    setState(() => kaydediliyor = false);
  }
}
```

## Aşama Sırası

```
1. Dokuma       → 2. Konfeksiyon
2. Konfeksiyon  → 3. Yıkama
3. Yıkama       → 4. Ütü
4. Ütü          → 5. İlik Düğme
5. İlik Düğme   → 6. Kalite Kontrol
```

## UI Gösterimi

### Önceki Aşama Bilgisi Göster

```dart
Widget buildOncekiAsamaBilgi() {
  return FutureBuilder<Map<String, int>>(
    future: _bedenService.getOncekiAsamaGerceklesenAdetler(modelId, 'konfeksiyon'),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return SizedBox();
      
      final adetler = snapshot.data!;
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📦 Dokumadan Gelen Adetler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...adetler.entries.map((e) => 
                Text('${e.key}: ${e.value} adet')
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

## Hata Durumları

### 1. Önceki Aşama Henüz Tamamlanmamış

```dart
final adetler = await _bedenService.getOncekiAsamaGerceklesenAdetler(modelId, 'yikama');

if (adetler.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('⚠️ Konfeksiyon aşaması henüz tamamlanmamış')),
  );
  return;
}
```

### 2. Sonraki Atama Bulunamadı

Sisteminizde bir sonraki aşamanın atama ID'sini bulmak için:

```dart
Future<int?> _getSonrakiAtamaId(String modelId, String sonrakiAsama) async {
  try {
    final tabloAdi = '${sonrakiAsama}_atamalari';
    final response = await Supabase.instance.client
        .from(tabloAdi)
        .select('id')
        .eq('model_id', modelId)
        .maybeSingle();
    
    return response?['id'] as int?;
  } catch (e) {
    print('Sonraki atama bulunamadı: $e');
    return null;
  }
}
```

## Test Senaryosu

```dart
void main() async {
  final bedenService = BedenService();
  final modelId = 'test-model-uuid';
  
  // 1. Dokuma tamamla (10 adet S fire)
  await bedenService.updateUretimBedenlerToplu(
    asama: 'dokuma',
    atamaId: 1,
    modelId: modelId,
    bedenVerileri: {
      'S': {'hedef_adet': 100, 'uretilen_adet': 100, 'fire_adet': 10},
      'M': {'hedef_adet': 100, 'uretilen_adet': 100, 'fire_adet': 0},
      'L': {'hedef_adet': 100, 'uretilen_adet': 100, 'fire_adet': 0},
    },
  );
  
  // 2. Konfeksiyona aktar
  await bedenService.updateSonrakiAsamaHedefAdetler(
    modelId: modelId,
    tamamlananAsama: 'dokuma',
    sonrakiAtamaId: 2,
  );
  
  // 3. Kontrol et
  final konfeksiyonAdetler = await bedenService.getAsamaBedenTakip('konfeksiyon', 2);
  print('Konfeksiyon hedef adetler:');
  for (final beden in konfeksiyonAdetler) {
    print('${beden.bedenKodu}: ${beden.hedefAdet} adet'); 
    // Beklenen: S:90, M:100, L:100
  }
}
```

## Önemli Notlar

1. ✅ **Otomatik Güncelleme**: Bir aşama tamamlandığında mutlaka `updateSonrakiAsamaHedefAdetler` çağrılmalı
2. ✅ **Fire Hesabı**: Gerçekleşen adet = Üretilen adet - Fire adet
3. ✅ **Sıfırdan Küçük Olamaz**: SQL fonksiyonu GREATEST(0, ...) kullanır
4. ⚠️ **Atama ID Gerekli**: Sonraki aşamanın atama ID'si önceden bilinmeli
5. 📝 **Log Takibi**: Tüm işlemler console'a loglanır

## Veritabanı Sorgularıyla Kontrol

```sql
-- Model için tüm aşamaların beden durumunu göster
SELECT 
    'dokuma' as asama,
    beden_kodu,
    hedef_adet,
    uretilen_adet,
    fire_adet,
    (uretilen_adet - fire_adet) as gerceklesen
FROM dokuma_beden_takip
WHERE model_id = 'uuid-buraya'

UNION ALL

SELECT 
    'konfeksiyon',
    beden_kodu,
    hedef_adet,
    uretilen_adet,
    fire_adet,
    (uretilen_adet - fire_adet)
FROM konfeksiyon_beden_takip
WHERE model_id = 'uuid-buraya'

ORDER BY asama, beden_kodu;
```

## Sorun Giderme

### Fonksiyon Bulunamadı Hatası

Eğer `Function get_onceki_asama_gerceklesen_adetler does not exist` hatası alırsanız:

1. Supabase Dashboard > SQL Editor
2. `asama_adet_aktarimi.sql` dosyasını çalıştır
3. Fonksiyonların oluşturulduğunu kontrol et:
   ```sql
   SELECT proname FROM pg_proc WHERE proname LIKE '%asama%';
   ```

### Adetler Güncellenmiyor

- Önceki aşamada `uretilen_adet > 0` olduğundan emin olun
- `fire_adet` sütununun doğru değerde olduğunu kontrol edin
- Sonraki aşamanın atama ID'sinin doğru olduğundan emin olun
