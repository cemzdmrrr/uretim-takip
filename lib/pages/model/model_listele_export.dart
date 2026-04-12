// ignore_for_file: invalid_use_of_protected_member
part of 'model_listele.dart';

/// Model listele - Excel export islemleri
extension _ExportListeleExt on _ModelListeleState {
  Future<void> _seciliModelleriUrunBilgileriExcelAktar() async {
    try {
      // Seçili modelleri filtrele
      final seciliModeller = modeller.where((model) => 
        seciliIdler.contains(model['id'].toString())
      ).toList();

      if (seciliModeller.isEmpty) {
        context.showSnackBar('Aktarılacak model bulunamadı');
        return;
      }

      // Ürün bilgileri Excel sütunları
      final columns = <String, String>{
        'marka': 'MARKA',
        'item_no': 'ITEM NO',
        'model_adi': 'MODEL ADI',
        'sezon': 'SEZON',
        'koleksiyon': 'KOLEKSİYON',
        'urun_kategorisi': 'ÜRÜN KATEGORİSİ',
        'triko_tipi': 'ÜRÜN TİPİ',
        'cinsiyet': 'CİNSİYET',
        'yas_grubu': 'YAŞ GRUBU',
        'ana_iplik_turu': 'ANA İPLİK TÜRÜ',
        'iplik_karisimi': 'İPLİK KARIŞIMI',
        'ana_renkler': 'ANA RENKLER',
        'toplam_adet': 'TOPLAM ADET',
        'siparis_tarihi': 'SİPARİŞ TARİHİ',
        'termin_tarihi': 'TERMİN TARİHİ',
        'durum': 'DURUM',
        'tamamlandi': 'TAMAMLANDI',
      };

      // Dosya adı
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'urun_bilgileri_$timestamp.xlsx';

      // Excel'e aktar
      await ExcelHelper.exportToExcel(
        data: seciliModeller,
        fileName: fileName,
        columns: columns,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${seciliModeller.length} modelin ürün bilgileri Excel\'e aktarıldı: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ürün bilgileri Excel aktarma hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Excel aktarma hatası: $e');
      }
    }
  }

  // Seçili modellerin üretim durumunu Excel'e aktar
  Future<void> _seciliModelleriUretimDurumuExcelAktar() async {
    try {
      // Seçili modelleri filtrele
      final seciliModeller = modeller.where((model) => 
        seciliIdler.contains(model['id'].toString())
      ).toList();

      if (seciliModeller.isEmpty) {
        context.showSnackBar('Aktarılacak model bulunamadı');
        return;
      }

      // Her model için üretim aşama tarihlerini al
      final List<Map<String, dynamic>> enrichedData = [];
      
      for (var model in seciliModeller) {
        final Map<String, dynamic> modelData = Map.from(model);
        
        // Bu model için üretim kayıtlarını al
        try {
          final uretimKayitlari = await supabase
              .from(DbTables.uretimKayitlari)
              .select('asama, baslama_tarihi, bitis_tarihi, firma_id')
              .eq('model_id', model['id']);
          
          // Her aşama için tarih bilgilerini ekle
          for (var kayit in uretimKayitlari) {
            final asama = kayit['asama'] as String;
            modelData['${asama}_baslangic_tarihi'] = kayit['baslama_tarihi'];
            modelData['${asama}_bitis_tarihi'] = kayit['bitis_tarihi'];
            
            // Firma bilgilerini de ekle/güncelle (firma_id'den firma adını al)
            if (kayit['firma_id'] != null) {
              try {
                final firma = await supabase
                    .from(DbTables.tedarikciler)
                    .select('sirket, ad')
                    .eq('id', kayit['firma_id'])
                    .maybeSingle();
                if (firma != null) {
                  modelData['${asama}_firmasi'] = firma['sirket'] ?? firma['ad'] ?? 'Bilinmiyor';
                }
              } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
            }
          }
        } catch (e) {
          debugPrint('Üretim kayıtları alınırken hata: $e');
        }
        
        enrichedData.add(modelData);
      }

      // Üretim durumu Excel sütunları
      final columns = <String, String>{
        'marka': 'MARKA',
        'item_no': 'ITEM NO', 
        'ana_renkler': 'RENK',
        'urun_kategorisi': 'ÜRÜN CİNSİ',
        'toplam_adet': 'ADET',
        'termin_tarihi': 'TERMİN TARİHİ',
        'iplik_geldi': 'İPLİK GELDİ',
        'kase_onayi': 'KAŞE ONAYI',
        'orgu_firmasi': 'ÖRGÜ FİRMA',
        'orgu_baslangic_tarihi': 'ÖRGÜ BAŞLANGIÇ',
        'orgu_bitis_tarihi': 'ÖRGÜ BİTİŞ',
        'konfeksiyon_firmasi': 'KONFEKSİYON FİRMA',
        'konfeksiyon_baslangic_tarihi': 'KONFEKSİYON BAŞLANGIÇ',
        'konfeksiyon_bitis_tarihi': 'KONFEKSİYON BİTİŞ',
        'yikama_firmasi': 'YIKAMA FİRMA',
        'yikama_baslangic_tarihi': 'YIKAMA BAŞLANGIÇ',
        'yikama_bitis_tarihi': 'YIKAMA BİTİŞ',
        'nakis_firmasi': 'NAKIŞ FİRMA',
        'nakis_baslangic_tarihi': 'NAKIŞ BAŞLANGIÇ',
        'nakis_bitis_tarihi': 'NAKIŞ BİTİŞ',
        'ilik_dugme_firmasi': 'İLİK DÜĞME FİRMA',
        'ilik_dugme_baslangic_tarihi': 'İLİK DÜĞME BAŞLANGIÇ',
        'ilik_dugme_bitis_tarihi': 'İLİK DÜĞME BİTİŞ',
        'utu_pres_firmasi': 'ÜTÜ FİRMA',
        'utu_baslangic_tarihi': 'ÜTÜ BAŞLANGIÇ',
        'utu_bitis_tarihi': 'ÜTÜ BİTİŞ',
        'durum': 'DURUM',
        'tamamlandi': 'TAMAMLANDI',
      };

      // Dosya adı
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'uretim_durumu_$timestamp.xlsx';

      // Excel'e aktar
      await ExcelHelper.exportToExcel(
        data: enrichedData,
        fileName: fileName,
        columns: columns,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${enrichedData.length} modelin üretim durumu Excel\'e aktarıldı: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Üretim durumu Excel aktarma hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Excel aktarma hatası: $e');
      }
    }
  }

}
