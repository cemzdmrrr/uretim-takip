import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/dal_form_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class TopluModelEkle extends StatefulWidget {
  const TopluModelEkle({Key? key}) : super(key: key);

  @override
  State<TopluModelEkle> createState() => _TopluModelEkleState();
}

class _TopluModelEkleState extends State<TopluModelEkle> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Map<String, dynamic>> _importedData = [];
  String? _selectedFileName;

  // Excel sütun başlıkları ve karşılık gelen veritabanı alanları
  final Map<String, String> _excelColumns = {
    // 1. Temel Model Bilgileri
    'Marka': 'marka',
    'Model Kodu': 'item_no',
    'Model Adı': 'model_adi',
    'Sezon': 'sezon',
    // 2. Ürün Detayları
    'Ürün Kategorisi': 'urun_kategorisi',
    'Triko Tipi': 'triko_tipi',
    'Ürün Tipi': 'triko_tipi',
    'Cinsiyet': 'cinsiyet',
    'Yaka Tipi': 'yaka_tipi',
    // 3. İplik ve Materyal
    'Ana İplik Türü': 'ana_iplik_turu',
    'İplik Karışımı': 'iplik_karisimi',
    'İplik Markası': 'iplik_markasi',
    'İplik Renk Kodu': 'iplik_renk_kodu',
    'İplik Numarası': 'iplik_numarasi',
    // 4. Renk ve Desen
    'Desen Tipi': 'desen_tipi',
    'Desen Detayı': 'desen_detayi',
    'Ana Renk': 'renk_kombinasyonu',
    // 5. Ölçü
    'Gramaj': 'gramaj',
    // 6. Teknik Örgü
    'Makine Tipi': 'makine_tipi',
    'İğne No': 'igne_no',
    'Gauge': 'gauge',
    'Örgü Sıklığı': 'orgu_sikligi',
    'Teknik Gramaj': 'teknik_gramaj',
    // 7. Tarihler ve Durum
    'Sipariş Tarihi (YYYY-MM-DD)': 'siparis_tarihi',
    'Termin Tarihi (YYYY-MM-DD)': 'termin_tarihi',
    'Durum': 'durum',
    // 8. Notlar
    'Özel Talimatlar': 'ozel_talimatlar',
    'Genel Notlar': 'genel_notlar',
    // 9. Fiyatlandırma
    'İplik KG Fiyatı': 'iplik_kg_fiyati',
    'Makine Çıkış Süresi (DK)': 'makina_cikis_suresi',
    'Makina DK Fiyatı': 'makina_dk_fiyati',
    'Dikim Fiyatı': 'dikim_fiyat',
    'Ütü Fiyatı': 'utu_fiyat',
    'Yıkama Fiyatı': 'yikama_fiyat',
    'İlik Düğme Fiyatı': 'ilik_dugme_fiyat',
    'Fermuar Fiyatı': 'fermuar_fiyat',
    'Baskı/Nakış Fiyatı': 'aksesuar_fiyat',
    'Genel Aksesuar Fiyatı': 'genel_aksesuar_fiyat',
    'Genel Gider Fiyatı': 'genel_gider_fiyat',
    'Kar Marjı (%)': 'kar_marji',
    'Vade (Ay)': 'vade_ay',
    'Vade Oranı (%)': 'vade_orani',
    // Beden alanları
    'XXS': 'beden_xxs',
    'XS': 'beden_xs',
    'S': 'beden_s',
    'M': 'beden_m',
    'L': 'beden_l',
    'XL': 'beden_xl',
    'XXL': 'beden_xxl',
    'XXXL': 'beden_xxxl',
    '34': 'beden_34',
    '36': 'beden_36',
    '38': 'beden_38',
    '40': 'beden_40',
    '42': 'beden_42',
    '44': 'beden_44',
    '46': 'beden_46',
    '48': 'beden_48',
    '50': 'beden_50',
    '52': 'beden_52',
    '54': 'beden_54',
    '56': 'beden_56',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toplu Model Ekleme'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama kartı
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplu Model Ekleme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Excel dosyası kullanarak birden fazla model ekleyebilirsiniz.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _downloadTemplate,
                          icon: const Icon(Icons.download),
                          label: const Text('Excel Şablonunu İndir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Excel Dosyası Seç'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Seçilen dosya gösterici
            if (_selectedFileName != null)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seçilen dosya: $_selectedFileName',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_importedData.isNotEmpty)
                        Text(
                          '${_importedData.length} model okundu',
                          style: const TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Veri önizlemesi
            if (_importedData.isNotEmpty) ...[
              const Text(
                'Veri Önizlemesi:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: _importedData.length,
                      itemBuilder: (context, index) {
                        final model = _importedData[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text('${model['marka']} - ${model['item_no']}'),
                          subtitle: Text(
                            'Model: ${model['model_adi'] ?? 'Belirtilmemiş'}\n'
                            'Kategori: ${model['urun_kategorisi'] ?? 'Belirtilmemiş'}\n'
                            'Toplam Adet: ${model['toplam_adet'] ?? 0}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveAllModels,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Kaydediliyor...' : 'Tüm Modelleri Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      // Excel şablonu oluştur
      final excel = Excel.createExcel();
      final sheet = excel['Şablon'];
      
      // Başlık satırını ekle
      final headers = _excelColumns.keys.toList();
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = CellStyle(
          backgroundColorHex: 'FF0000FF', // Mavi renk
          fontColorHex: 'FFFFFFFF', // Beyaz renk
          bold: true,
        );
      }
      
      // Örnek veri satırı ekle
      final exampleData = [
        'Marka A', // Marka
        'MODEL001', // Model Kodu
        'Test Model', // Model Adı
        '2024 Kış', // Sezon
        'Triko', // Ürün Kategorisi
        'Basic', // Triko Tipi
        'Unisex', // Cinsiyet
        'Bisiklet Yaka', // Yaka Tipi
        'Pamuk', // Ana İplik Türü
        '100% Pamuk', // İplik Karışımı
        'İplik Markası A', // İplik Markası
        'Mavi 123', // İplik Renk Kodu
        'Ne 30/1', // İplik Numarası
        'Düz', // Desen Tipi
        'Düz örgü', // Desen Detayı
        'Siyah', // Ana Renk
        '180', // Gramaj
        'Düz Örgü', // Makine Tipi
        '12', // İğne No
        '12GG', // Gauge
        'Normal', // Örgü Sıklığı
        '180 gr/m2', // Teknik Gramaj
        '2024-01-15', // Sipariş Tarihi
        '2024-02-15', // Termin Tarihi
        'Beklemede', // Durum
        'Özel talimat yok', // Özel Talimatlar
        'Genel not yok', // Genel Notlar
        '25', // İplik KG Fiyatı
        '8', // Makine Çıkış Süresi (DK)
        '1.5', // Makina DK Fiyatı
        '5', // Dikim Fiyatı
        '2', // Ütü Fiyatı
        '3', // Yıkama Fiyatı
        '1.5', // İlik Düğme Fiyatı
        '0', // Fermuar Fiyatı
        '2', // Baskı/Nakış Fiyatı
        '1', // Genel Aksesuar Fiyatı
        '3', // Genel Gider Fiyatı
        '30', // Kar Marjı (%)
        '0', // Vade (Ay)
        '0', // Vade Oranı (%)
      ];
      
      // Beden alanları için örnek değerler
      final bedenOrnekleri = ['0', '10', '20', '30', '20', '10', '5', '3', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'];
      exampleData.addAll(bedenOrnekleri);
      
      for (int i = 0; i < exampleData.length && i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = exampleData[i];
      }
      
      // Excel dosyasını bytes olarak al
      final bytes = excel.encode();
      
      // Dosyayı kaydet
      await ExcelHelper.saveExcelFile(
        bytes!,
        'model_ekleme_sablonu.xlsx',
      );
      
      if (mounted) {
        context.showSuccessSnackBar('Excel şablonu başarıyla indirildi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Şablon indirme hatası: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
          _isLoading = true;
        });

        await _processExcelFile(file.bytes!);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Dosya seçme hatası: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processExcelFile(Uint8List bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      
      if (sheet.rows.isEmpty) {
        throw Exception('Excel dosyası boş');
      }

      // Başlık satırını al
      final headerRow = sheet.rows.first;
      final headers = headerRow.map((cell) => cell?.value?.toString() ?? '').toList();
      
      // Veri satırlarını işle
      final List<Map<String, dynamic>> importedModels = [];
      
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> modelData = {};
        
        // Temel alanları işle
        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          final cellValue = row[j]?.value?.toString() ?? '';
          
          if (cellValue.isNotEmpty && _excelColumns.containsKey(header)) {
            final dbField = _excelColumns[header]!;
            
            // Özel alan işlemeleri
            if (dbField == 'toplam_adet' || dbField == 'vade_ay') {
              modelData[dbField] = int.tryParse(cellValue) ?? 0;
            } else if (dbField == 'siparis_tarihi' || dbField == 'termin_tarihi') {
              final date = DateTime.tryParse(cellValue);
              if (date != null) {
                modelData[dbField] = date.toIso8601String();
              }
            } else if (dbField.startsWith('beden_')) {
              // Beden alanları daha sonra işlenecek
              continue;
            } else if (const [
              'iplik_kg_fiyati', 'makina_cikis_suresi', 'makina_dk_fiyati',
              'dikim_fiyat', 'utu_fiyat', 'yikama_fiyat',
              'ilik_dugme_fiyat', 'fermuar_fiyat', 'aksesuar_fiyat',
              'genel_aksesuar_fiyat', 'genel_gider_fiyat',
              'kar_marji', 'vade_orani',
            ].contains(dbField)) {
              final numVal = double.tryParse(cellValue.replaceAll(',', '.'));
              if (numVal != null) {
                modelData[dbField] = numVal;
              }
            } else {
              modelData[dbField] = cellValue;
            }
          }
        }
        
        // Beden dağılımını işle
        final Map<String, dynamic> bedenler = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          final cellValue = row[j]?.value?.toString() ?? '';
          
          if (_excelColumns.containsKey(header) && _excelColumns[header]!.startsWith('beden_')) {
            final bedenName = header;
            final adet = int.tryParse(cellValue) ?? 0;
            if (adet > 0) {
              bedenler[bedenName] = adet;
            }
          }
        }
        
        if (bedenler.isNotEmpty) {
          modelData['bedenler'] = bedenler;
          
          // Toplam adeti yeniden hesapla
          final toplamAdet = bedenler.values.fold<int>(0, (sum, adet) => sum + (adet as int));
          modelData['toplam_adet'] = toplamAdet;
        }
        
        // Zorunlu alanları kontrol et
        if (modelData['marka'] != null && modelData['item_no'] != null) {
          // Varsayılan değerleri ekle
          modelData['durum'] = modelData['durum'] ?? 'Beklemede';
          modelData['tamamlandi'] = false;
          
          // Fiyatlandırma otomatik hesaplamaları
          final gramaj = (modelData['gramaj'] != null) ? double.tryParse(modelData['gramaj'].toString().replaceAll(',', '.')) ?? 0.0 : 0.0;
          final iplikKgFiyati = (modelData['iplik_kg_fiyati'] as double?) ?? 0.0;
          if (iplikKgFiyati > 0 && gramaj > 0) {
            modelData['iplik_maliyeti'] = iplikKgFiyati * gramaj;
          }
          final makinaSuresi = (modelData['makina_cikis_suresi'] as double?) ?? 0.0;
          final makinaDkFiyati = (modelData['makina_dk_fiyati'] as double?) ?? 0.0;
          if (makinaSuresi > 0 && makinaDkFiyati > 0) {
            modelData['orgu_fiyat'] = makinaSuresi * makinaDkFiyati;
          }
          
          importedModels.add(modelData);
        }
      }
      
      setState(() {
        _importedData = importedModels;
      });
      
      if (mounted) {
        context.showSuccessSnackBar('${importedModels.length} model başarıyla okundu');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Excel işleme hatası: $e');
      }
    }
  }

  Future<void> _saveAllModels() async {
    if (_importedData.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      int successCount = 0;
      int errorCount = 0;
      
      for (final modelData in _importedData) {
        try {
          modelData['uretim_dali'] = DalFormConfig.birincilDal;
          modelData['firma_id'] = TenantManager.instance.requireFirmaId;
          await _supabase.from(DbTables.trikoTakip).insert(modelData);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Model kaydetme hatası: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$successCount model başarıyla kaydedildi${errorCount > 0 ? ', $errorCount model kaydedilemedi' : ''}',
            ),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );
        
        if (successCount > 0) {
          Navigator.pop(context, true); // Başarılı ise geri dön
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Toplu kaydetme hatası: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
