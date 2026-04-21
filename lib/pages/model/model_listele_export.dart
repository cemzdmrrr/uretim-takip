// ignore_for_file: invalid_use_of_protected_member
part of 'model_listele.dart';

const List<Map<String, String>> _uretimDurumuExcelAsamalari = [
  {
    'key': 'orgu_durumu_export',
    'label': 'DOKUMA/ÖRME',
    'table': DbTables.dokumaAtamalari,
    'legacy': 'orgu_durumu',
  },
  {
    'key': 'konfeksiyon_durumu_export',
    'label': 'KONFEKSİYON',
    'table': DbTables.konfeksiyonAtamalari,
    'legacy': 'konfeksiyon_durumu',
  },
  {
    'key': 'nakis_durumu_export',
    'label': 'NAKIŞ',
    'table': DbTables.nakisAtamalari,
    'legacy': 'nakis_durumu',
  },
  {
    'key': 'yikama_durumu_export',
    'label': 'YIKAMA',
    'table': DbTables.yikamaAtamalari,
    'legacy': 'yikama_durumu',
  },
  {
    'key': 'ilik_dugme_durumu_export',
    'label': 'İLİK DÜĞME',
    'table': DbTables.ilikDugmeAtamalari,
    'legacy': 'ilik_dugme_durumu',
  },
  {
    'key': 'utu_durumu_export',
    'label': 'ÜTÜ',
    'table': DbTables.utuAtamalari,
    'legacy': 'utu_durumu',
  },
  {
    'key': 'kalite_kontrol_durumu_export',
    'label': 'KALİTE KONTROL',
    'table': DbTables.kaliteKontrolAtamalari,
    'legacy': 'kalite_durumu',
  },
  {
    'key': 'paketleme_durumu_export',
    'label': 'PAKETLEME',
    'table': DbTables.paketlemeAtamalari,
    'legacy': 'paketleme_durumu',
  },
];

/// Model listele - Excel export islemleri
extension _ExportListeleExt on _ModelListeleState {
  Future<void> _seciliModelleriUrunBilgileriExcelAktar() async {
    try {
      // Seçili modelleri filtrele
      final seciliModeller = modeller
          .where((model) => seciliIdler.contains(model['id'].toString()))
          .toList();

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
            content: Text(
                '${seciliModeller.length} modelin ürün bilgileri Excel\'e aktarıldı: $fileName'),
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
      final seciliModeller = modeller
          .where((model) => seciliIdler.contains(model['id'].toString()))
          .toList();

      if (seciliModeller.isEmpty) {
        context.showSnackBar('Aktarılacak model bulunamadı');
        return;
      }

      final seciliModelIdleri =
          seciliModeller.map((model) => model['id'].toString()).toList();
      final detayliModeller =
          await _seciliModelDetaylariniGetir(seciliModelIdleri);

      final List<Map<String, dynamic>> enrichedData = [];

      for (var model in seciliModeller) {
        final modelId = model['id'].toString();
        final Map<String, dynamic> modelData =
            Map<String, dynamic>.from(detayliModeller[modelId] ?? model);

        final toplamAdet =
            _intDeger(modelData['toplam_adet'] ?? modelData['adet']);
        final gonderilenAdet = await _modelGonderilenAdetGetir(modelId);

        modelData['model_adi_export'] = _textDeger(
          modelData['model_adi'] ?? modelData['item_no'],
        );
        modelData['ana_renk_export'] = _anaRenkDeger(modelData);
        modelData['toplam_adet_export'] = toplamAdet;
        modelData['gonderilen_adet_export'] = gonderilenAdet;
        modelData['kalan_adet_export'] =
            (toplamAdet - gonderilenAdet).clamp(0, toplamAdet);

        for (final asama in _uretimDurumuExcelAsamalari) {
          final atamalar =
              await _asamaAtamalariniGetir(modelId, asama['table']!);
          modelData[asama['key']!] = _asamaDurumMetni(
            atamalar: atamalar,
            legacyDurum: modelData[asama['legacy']],
          );
        }

        enrichedData.add(modelData);
      }

      // Üretim durumu Excel sütunları
      final columns = <String, String>{
        'model_adi_export': 'MODEL ADI',
        'ana_renk_export': 'ANA RENK',
        'yaka_tipi': 'YAKA TİPİ',
        'iplik_karisimi': 'İPLİK KARIŞIMI',
        'termin_tarihi': 'TERMİN TARİHİ',
        'toplam_adet_export': 'TOPLAM ADET',
        'gonderilen_adet_export': 'GÖNDERİLEN ADET',
        'kalan_adet_export': 'KALAN ADET',
        for (final asama in _uretimDurumuExcelAsamalari)
          asama['key']!: asama['label']!,
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
            content: Text(
                '${enrichedData.length} modelin üretim durumu Excel\'e aktarıldı: $fileName'),
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

  Future<Map<String, Map<String, dynamic>>> _seciliModelDetaylariniGetir(
    List<String> modelIdleri,
  ) async {
    try {
      final response = await supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', _firmaId)
          .filter('id', 'in', '(${modelIdleri.join(',')})');

      return {
        for (final model in List<Map<String, dynamic>>.from(response))
          model['id'].toString(): model,
      };
    } catch (e) {
      debugPrint('Model detayları alınırken hata: $e');
      return {};
    }
  }

  Future<int> _modelGonderilenAdetGetir(String modelId) async {
    try {
      final response = await supabase
          .from(DbTables.yuklemeKayitlari)
          .select('adet')
          .eq('model_id', modelId);

      return List<Map<String, dynamic>>.from(response).fold<int>(
        0,
        (toplam, kayit) => toplam + _intDeger(kayit['adet']),
      );
    } catch (e) {
      debugPrint('Yükleme kayıtları alınırken hata: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _asamaAtamalariniGetir(
    String modelId,
    String tableName,
  ) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('adet, talep_edilen_adet, tamamlanan_adet, durum')
          .eq('model_id', modelId)
          .eq('firma_id', _firmaId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      try {
        final response = await supabase
            .from(tableName)
            .select('adet, talep_edilen_adet, tamamlanan_adet, durum')
            .eq('model_id', modelId);

        return List<Map<String, dynamic>>.from(response);
      } catch (fallbackError) {
        debugPrint('$tableName atamaları alınırken hata: $fallbackError');
        return [];
      }
    }
  }

  String _asamaDurumMetni({
    required List<Map<String, dynamic>> atamalar,
    dynamic legacyDurum,
  }) {
    if (atamalar.isEmpty) {
      final legacy = _textDeger(legacyDurum);
      return legacy.isEmpty ? 'Bekliyor' : _durumEtiketi(legacy);
    }

    var toplamAdet = 0;
    var tamamlananAdet = 0;
    var tamamlananSayisi = 0;
    var iptalSayisi = 0;
    var devamEdiyor = false;
    var atandi = false;

    for (final atama in atamalar) {
      final talep = _intDeger(atama['adet'] ?? atama['talep_edilen_adet']);
      final tamamlanan = _intDeger(atama['tamamlanan_adet']);
      final durum = atama['durum']?.toString().toLowerCase() ?? '';

      toplamAdet += talep;
      tamamlananAdet += tamamlanan;

      if (durum == 'tamamlandi') tamamlananSayisi++;
      if (durum == 'iptal') iptalSayisi++;
      if (durum == 'baslatildi' ||
          durum == 'uretimde' ||
          durum == 'devam_ediyor' ||
          durum == 'kismi_tamamlandi' ||
          tamamlanan > 0) {
        devamEdiyor = true;
      }
      if (durum == 'atandi' ||
          durum == 'firma_onay_bekliyor' ||
          durum == 'onaylandi' ||
          durum == 'kabul_edildi') {
        atandi = true;
      }
    }

    String durum;
    if (iptalSayisi == atamalar.length) {
      durum = 'İptal';
    } else if (tamamlananSayisi == atamalar.length && atamalar.isNotEmpty) {
      durum = 'Tamamlandı';
    } else if (devamEdiyor) {
      durum = 'Devam Ediyor';
    } else if (atandi) {
      durum = 'Atandı';
    } else {
      durum = _durumEtiketi(atamalar.first['durum']);
    }

    if (toplamAdet <= 0) return durum;
    return '$durum ($tamamlananAdet/$toplamAdet)';
  }

  String _anaRenkDeger(Map<String, dynamic> modelData) {
    final anaRenkler = modelData['ana_renkler'];
    if (anaRenkler is List) {
      return anaRenkler.map((renk) => renk.toString()).join(', ');
    }

    return _textDeger(
      modelData['ana_renkler'] ?? modelData['ana_renk'] ?? modelData['renk'],
    );
  }

  String _durumEtiketi(dynamic durum) {
    switch (durum?.toString().toLowerCase()) {
      case 'atandi':
        return 'Atandı';
      case 'firma_onay_bekliyor':
        return 'Onay Bekliyor';
      case 'onaylandi':
      case 'kabul_edildi':
        return 'Onaylandı';
      case 'baslatildi':
        return 'Başlatıldı';
      case 'uretimde':
      case 'devam_ediyor':
      case 'kismi_tamamlandi':
        return 'Devam Ediyor';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'iptal':
        return 'İptal';
      case null:
      case '':
        return 'Bekliyor';
      default:
        return durum.toString();
    }
  }

  int _intDeger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _textDeger(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }
}
