// ignore_for_file: invalid_use_of_protected_member
part of 'gelismis_raporlar_page.dart';

/// PDF ve Excel dışa aktarma işlemleri for _GelismisRaporlarPageState.
extension _ExportExt on _GelismisRaporlarPageState {
  Future<void> _pdfOlustur() async {
    final ozet = _hesaplaFiltrelenmisOzet();
    final maliyetDagilimi = _hesaplaMaliyetDagilimi();
    final renkAnalizi = _hesaplaRenkAnalizi();
    final stokDevir = _hesaplaStokDevirHizi();
    final sezonAnalizi = _hesaplaSezonAnalizi();
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            header: (pw.Context ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TexPilot - Rapor Ozeti', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Olusturulma: $now', style: const pw.TextStyle(fontSize: 10)),
                if (secilenMarka != null) pw.Text('Marka: $secilenMarka', style: const pw.TextStyle(fontSize: 10)),
                if (secilenModel != null) pw.Text('Model: $secilenModel', style: const pw.TextStyle(fontSize: 10)),
                pw.Divider(),
              ],
            ),
            footer: (pw.Context ctx) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Sayfa ${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
            ),
            build: (pw.Context ctx) => [
              // ÖZET KPI'lar
              pw.Text('Ozet Bilgiler', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Metrik', 'Deger'],
                data: [
                  ['Toplam Model Sayisi', '${ozet['toplamUrun']}'],
                  ['Toplam Uretim Adedi', '${ozet['toplamAdet']}'],
                  ['Toplam Maliyet', currencyFormat.format(ozet['toplamMaliyet'])],
                  ['Toplam Gelir', currencyFormat.format(ozet['toplamSatis'])],
                  ['Net Kar', currencyFormat.format(ozet['kar'])],
                  ['Kar Marji', '%${(ozet['karMarji'] as num).toStringAsFixed(1)}'],
                ],
              ),
              pw.SizedBox(height: 16),

              // MALİYET DAĞILIMI
              pw.Text('Maliyet Dagilimi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Kalem', 'Tutar', 'Oran'],
                data: [
                  ['Iplik', currencyFormat.format(maliyetDagilimi['iplik']), '%${maliyetDagilimi['iplikOran'].toStringAsFixed(1)}'],
                  ['Iscilik', currencyFormat.format(maliyetDagilimi['iscilik']), '%${maliyetDagilimi['iscilikOran'].toStringAsFixed(1)}'],
                  ['Aksesuar', currencyFormat.format(maliyetDagilimi['aksesuar']), '%${maliyetDagilimi['aksesuarOran'].toStringAsFixed(1)}'],
                  ['Genel Gider', currencyFormat.format(maliyetDagilimi['genelGider']), '%${maliyetDagilimi['genelGiderOran'].toStringAsFixed(1)}'],
                ],
              ),
              pw.SizedBox(height: 16),

              // RENK ANALİZİ
              pw.Text('Renk Bazli Satis Analizi (ilk 10)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Renk', 'Adet', 'Tutar'],
                data: renkAnalizi.entries.take(10).map((e) => [
                  e.key,
                  '${e.value['adet']}',
                  currencyFormat.format(e.value['tutar']),
                ]).toList(),
              ),
              pw.SizedBox(height: 16),

              // STOK DEVİR HIZI
              pw.Text('Stok Devir Hizi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Metrik', 'Deger'],
                data: [
                  ['Ortalama Satis Suresi', '${stokDevir['ortalamaSure'].toStringAsFixed(1)} gun'],
                  ['En Hizli Satan', '${stokDevir['enHizli']}'],
                  ['En Yavas Satan', '${stokDevir['enYavas']}'],
                ],
              ),
              pw.SizedBox(height: 16),

              // SEZON ANALİZİ
              pw.Text('Sezon Analizi', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Ay', 'Adet', 'Tutar'],
                data: sezonAnalizi.entries.map((e) => [
                  e.key,
                  '${e.value['adet']}',
                  currencyFormat.format(e.value['tutar']),
                ]).toList(),
              ),
              pw.SizedBox(height: 16),

              // MODEL DETAY TABLOSU
              pw.Text('Model Detaylari (${filtrelenmisModeller.length} kayit)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headers: ['Marka', 'Model', 'Renk', 'Adet', 'Maliyet', 'Gelir', 'Kar'],
                data: filtrelenmisModeller.take(100).map((item) {
                  final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
                  final iplik = (item['iplik_maliyeti'] ?? 0).toDouble();
                  final orgu = (item['orgu_fiyat'] ?? 0).toDouble();
                  final dikim = (item['dikim_fiyat'] ?? 0).toDouble();
                  final utu = (item['utu_fiyat'] ?? 0).toDouble();
                  final yikama = (item['yikama_fiyat'] ?? 0).toDouble();
                  final ilik = (item['ilik_dugme_fiyat'] ?? 0).toDouble();
                  final aks = (item['aksesuar_fiyat'] ?? 0).toDouble();
                  final genelAks = (item['genel_aksesuar_fiyat'] ?? 0).toDouble();
                  final genelGid = (item['genel_gider_fiyat'] ?? 0).toDouble();
                  final pesin = (item['pesin_fiyat'] ?? 0).toDouble();
                  final fermuar = (item['fermuar_fiyat'] ?? 0).toDouble();
                  final topMaliyet = (iplik + orgu + dikim + utu + yikama + ilik + aks + genelAks + genelGid + fermuar) * adet;
                  final gelir = pesin * adet;
                  return [
                    item['marka'] ?? '',
                    item['item_no'] ?? '',
                    item['renk'] ?? '',
                    '$adet',
                    currencyFormat.format(topMaliyet),
                    currencyFormat.format(gelir),
                    currencyFormat.format(gelir - topMaliyet),
                  ];
                }).toList(),
              ),
            ],
          ),
        );

        return pdf.save();
      },
    );
  }

  // EXCEL OLUŞTUR
  Future<void> _excelOlustur() async {
    final exportData = <Map<String, dynamic>>[];
    
    for (var item in filtrelenmisModeller) {
      final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
      final iplik = (item['iplik_maliyeti'] ?? 0).toDouble();
      final orgu = (item['orgu_fiyat'] ?? 0).toDouble();
      final dikim = (item['dikim_fiyat'] ?? 0).toDouble();
      final utu = (item['utu_fiyat'] ?? 0).toDouble();
      final yikama = (item['yikama_fiyat'] ?? 0).toDouble();
      final ilik = (item['ilik_dugme_fiyat'] ?? 0).toDouble();
      final aksesuar = (item['aksesuar_fiyat'] ?? 0).toDouble();
      final genelAksesuar = (item['genel_aksesuar_fiyat'] ?? 0).toDouble();
      final genelGider = (item['genel_gider_fiyat'] ?? 0).toDouble();
      final pesinFiyat = (item['pesin_fiyat'] ?? 0).toDouble();
      final fermuar = (item['fermuar_fiyat'] ?? 0).toDouble();
      
      final toplamMaliyet = (iplik + orgu + dikim + utu + yikama + ilik + aksesuar + genelAksesuar + genelGider + fermuar) * adet;
      final gelir = pesinFiyat * adet;
      final kar = gelir - toplamMaliyet;
      final karMarji = gelir > 0 ? (kar / gelir * 100) : 0.0;
      
      exportData.add({
        'marka': item['marka'] ?? '',
        'item_no': item['item_no'] ?? '',
        'renk': item['renk'] ?? '',
        'adet': adet,
        'iplik_maliyeti': iplik.toStringAsFixed(2),
        'iscilik_maliyeti': (orgu + dikim + utu + yikama + ilik).toStringAsFixed(2),
        'aksesuar_maliyeti': (aksesuar + genelAksesuar + fermuar).toStringAsFixed(2),
        'genel_gider': genelGider.toStringAsFixed(2),
        'toplam_maliyet': toplamMaliyet.toStringAsFixed(2),
        'birim_satis': pesinFiyat.toStringAsFixed(2),
        'toplam_gelir': gelir.toStringAsFixed(2),
        'kar': kar.toStringAsFixed(2),
        'kar_marji': '${karMarji.toStringAsFixed(1)}%',
        'tarih': item['created_at'] ?? '',
      });
    }

    if (exportData.isEmpty) {
      if (mounted) {
        context.showSnackBar('Dışa aktarılacak veri bulunamadı');
      }
      return;
    }
    
    try {
      final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await ExcelHelper.exportToExcel(
        data: exportData,
        fileName: 'rapor_$now.xlsx',
        columns: {
          'marka': 'MARKA',
          'item_no': 'MODEL',
          'renk': 'RENK',
          'adet': 'ADET',
          'iplik_maliyeti': 'İPLİK MALİYETİ',
          'iscilik_maliyeti': 'İŞÇİLİK MALİYETİ',
          'aksesuar_maliyeti': 'AKSESUAR MALİYETİ',
          'genel_gider': 'GENEL GİDER',
          'toplam_maliyet': 'TOPLAM MALİYET',
          'birim_satis': 'BİRİM SATIŞ',
          'toplam_gelir': 'TOPLAM GELİR',
          'kar': 'KAR',
          'kar_marji': 'KAR MARJI',
          'tarih': 'TARİH',
        },
      );
      if (mounted) {
        context.showSuccessSnackBar('Excel dosyası oluşturuldu');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Excel oluşturma hatası: $e');
      }
    }
  }

}
