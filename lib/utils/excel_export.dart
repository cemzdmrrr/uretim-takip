import 'package:uretim_takip/utils/app_exceptions.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

class ExcelHelper {
  static Future<void> exportToExcel({
    required List<Map<String, dynamic>> data,
    required String fileName,
    Map<String, String>? columns,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    
    // Eğer columns belirtilmemişse, veri içindeki tüm kolonları kullan
    final effectiveColumns = columns ?? {
      for (var key in data.first.keys) key: key.toUpperCase()
    };
    
    // Başlıkları ekle
    int col = 0;
    for (var columnName in effectiveColumns.values) {
      sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      )).value = columnName;
      col++;
    }

    // Tarih olarak formatlanacak alanlar
    const tarihAlanlari = [
      'termin',
      'tarih',
      'orgu_baslangic_tarihi',
      'orgu_bitis_tarihi',
      'konfeksiyon_baslangic_tarihi',
      'konfeksiyon_bitis_tarihi',
      'yikama_baslangic_tarihi',
      'yikama_bitis_tarihi',
      'nakis_baslangic_tarihi',
      'nakis_bitis_tarihi',
      'ilik_dugme_baslangic_tarihi',
      'ilik_dugme_bitis_tarihi',
      'utu_baslangic_tarihi',
      'utu_bitis_tarihi',
    ];

    // Verileri ekle
    for (var i = 0; i < data.length; i++) {
      col = 0;
      for (var key in effectiveColumns.keys) {
        var value = data[i][key];

        // Yüklenen Adet (yukleme_kayitlari) null/boş/[] ise 0 göster
        if (key == DbTables.yuklemeKayitlari) {
          if (value == null || (value is List && value.isEmpty) || value.toString() == '[]') {
            value = 0;
          } else if (value is List) {
            value = value.map((e) => (e['adet'] ?? 0) as int).fold<int>(0, (a, b) => a + b);
          } else if (value is int) {
            // int ise olduğu gibi al
          } else {
            value = int.tryParse(value.toString()) ?? 0;
          }
        }

        // Ana renkler listesi varsa virgülle ayır
        if (key == 'ana_renkler' && value is List) {
          value = value.join(', ');
        }

        // 'iplik_geldi', 'kase_onayi' ve 'tamamlandi' sütunları true/false ise 'Evet'/'Hayır' olarak göster
        if (key == 'iplik_geldi' || key == 'kase_onayi' || key == 'tamamlandi') {
          if (value == true) {
            value = 'Evet';
          } else if (value == false) {
            value = 'Hayır';
          } else {
            value = '';
          }
        }

        // Tarih alanlarını formatla (tüm _tarihi ile bitenler ve özel anahtarlar)
        if ((key.endsWith('_tarihi') || tarihAlanlari.contains(key)) ||
            [
              'orgu_baslangic',
              'orgu_bitis',
              'konfeksiyon_baslangic',
              'konfeksiyon_bitis',
              'yikama_baslangic',
              'yikama_bitis',
              'nakis_baslangic',
              'nakis_bitis',
              'ilik_dugme_baslangic',
              'ilik_dugme_bitis',
              'utu_baslangic',
              'utu_bitis'
            ].contains(key)) {
          if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
            final strVal = value.toString();
            // Eğer değer sadece yıl ise veya 0000-00-00 gibi ise boş bırak
            if (strVal.length < 8 || strVal.startsWith('0000')) {
              value = '';
            } else if (RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(strVal)) {
              // Zaten dd.MM.yyyy formatında ise aynen bırak
            } else {
              // Sık kullanılan tarih formatlarını sırayla dene
              DateTime? date;
              for (final fmt in [
                'yyyy-MM-dd',
                'yyyy-MM-dd HH:mm:ss',
                'yyyy-MM-ddTHH:mm:ss',
                'dd.MM.yyyy',
                'MM/dd/yyyy',
                'yyyy/MM/dd',
                'dd-MM-yyyy',
                'yyyyMMdd',
              ]) {
                try {
                  date = DateFormat(fmt).parseStrict(strVal);
                  break;
                } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
              }
              // Son çare olarak DateTime.tryParse
              date ??= DateTime.tryParse(strVal);
              if (date != null) {
                value = DateFormat('dd.MM.yyyy').format(date);
              } else {
                value = '';
              }
            }
          } else {
            value = '';
          }
        }

        sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: i + 1,
        )).value = value?.toString() ?? '';
        col++;
      }
    }

    final excelBytes = excel.encode();
    if (excelBytes == null) throw Exception('Excel dosyası oluşturulamadı');

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(excelBytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Future<void> saveExcelFile(List<int> bytes, String fileName) async {
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
