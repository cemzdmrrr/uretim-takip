import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

Future<void> exportToPdf(List<Map<String, dynamic>> raporlar) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('Model Bazlı Raporlar', style: const pw.TextStyle(fontSize: 20)),
        ),
        pw.SizedBox(height: 20),
        _createTable(raporlar),
      ],
    ),
  );

  final directory = await getApplicationDocumentsDirectory();
  final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File('${directory.path}/model_rapor_$now.pdf');
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}

pw.Table _createTable(List<Map<String, dynamic>> raporlar) {
  return pw.Table(
    border: pw.TableBorder.all(),
    columnWidths: {
      0: const pw.FlexColumnWidth(2), // Marka
      1: const pw.FlexColumnWidth(2), // Item No
      2: const pw.FlexColumnWidth(2), // İplik Türü
      3: const pw.FlexColumnWidth(2), // Renk
      4: const pw.FlexColumnWidth(1.5), // Kalınlık
      5: const pw.FlexColumnWidth(1.5), // Miktar
      6: const pw.FlexColumnWidth(1.5), // Fire Oranı
      7: const pw.FlexColumnWidth(1.5), // Üretim Adedi
      8: const pw.FlexColumnWidth(2), // Tarih
    },
    children: _buildRows(raporlar),
  );
}


List<pw.TableRow> _buildRows(List<Map<String, dynamic>> raporlar) {
  final rows = <pw.TableRow>[];

  for (final rapor in raporlar) {
    final iplikSarfiyat = rapor['iplik_sarfiyat'] as List? ?? [];
    
    if (iplikSarfiyat.isEmpty) {
      rows.add(_createRow([
        rapor['marka'] ?? '',
        rapor['item_no'] ?? '',
        '-',
        '-',
        '-',
        '0',
        _hesaplaFireOrani(rapor).toStringAsFixed(2),
        rapor['adet']?.toString() ?? '0',
        _formatDate(rapor['created_at']),
      ]));
    } else {
      for (final sarf in iplikSarfiyat) {
        rows.add(_createRow([
          rapor['marka'] ?? '',
          rapor['item_no'] ?? '',
          sarf['iplik_turu'] ?? '',
          sarf['renk'] ?? '',
          sarf['kalinlik']?.toString() ?? '',
          sarf['miktar_kg']?.toString() ?? '0',
          _hesaplaFireOrani(rapor).toStringAsFixed(2),
          rapor['adet']?.toString() ?? '0',
          _formatDate(rapor['created_at']),
        ]));
      }
    }
  }

  return rows;
}

pw.TableRow _createRow(List<String> cells) {
  return pw.TableRow(
    children: cells
        .map((cell) => pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                cell,
                textAlign: pw.TextAlign.center,
              ),
            ))
        .toList(),
  );
}

String _formatDate(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd.MM.yyyy').format(date);
  } catch (e) {
    return '';
  }
}

double _hesaplaFireOrani(Map<String, dynamic> model) {
  final toplamIplik = (model['iplik_sarfiyat'] as List?)?.fold<double>(
    0,
    (sum, item) => sum + (item['miktar_kg'] ?? 0),
  ) ?? 0;
  
  final uretimAdedi = model['adet'] ?? 0;
  if (uretimAdedi == 0) return 0;
  
  return toplamIplik / uretimAdedi;
}
