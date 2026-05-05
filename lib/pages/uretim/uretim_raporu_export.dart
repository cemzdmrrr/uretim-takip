// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

const List<Map<String, String>> _uretimRaporuExcelAsamalari = [
  {'key': 'dokuma', 'label': 'DOKUMA/ORME'},
  {'key': 'nakis', 'label': 'NAKIS'},
  {'key': 'konfeksiyon', 'label': 'KONFEKSIYON'},
  {'key': 'yikama', 'label': 'YIKAMA'},
  {'key': 'ilik_dugme', 'label': 'ILIK DUGME'},
  {'key': 'utu', 'label': 'UTU'},
  {'key': 'kalite_kontrol', 'label': 'KALITE KONTROL'},
  {'key': 'paketleme', 'label': 'PAKETLEME'},
];

extension _ExportExt on _UretimRaporuPageState {
  Future<void> _exportExcel() async {
    try {
      final data = _modeller.map(_excelSatiriOlustur).toList();
      final fileName =
          'uretim_raporu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      const columns = <String, String>{
        'model_adi': 'Model Adı',
        'ana_renk': 'Renk',
        'iplik_karisimi': 'Karışım',
        'toplam_adet': 'Adet',
        'termin_tarihi': 'Termin',
        'tamamlanan_adet': 'Tamamlanan Adet',
        'kalan_adet': 'Kalan Adet',
        'dokuma_firma': 'Dokumayı Yapan Firma',
        'dokuma_baslangic': 'Dokuma Başlama Tarihi',
        'dokuma_bitis': 'Dokuma Bitiş Tarihi',
        'konfeksiyon_firma': 'Konfeksiyonu Yapan Firma',
        'konfeksiyon_baslangic': 'Konfeksiyon Başlama Tarihi',
        'konfeksiyon_bitis': 'Konfeksiyon Bitiş Tarihi',
        'utu_firma': 'Ütü Paket Yapan Firma',
        'utu_baslangic': 'Ütü Başlama Tarihi',
        'utu_bitis': 'Ütü Bitiş Tarihi',
      };

      await ExcelHelper.exportToExcel(
        data: data,
        fileName: fileName,
        columns: columns,
      );

      if (mounted) {
        context.showSuccessSnackBar(
          'Excel raporu başarıyla indirildi: $fileName',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Export hatası: $e');
      }
    }
  }

  // ignore: unused_element
  void _exportExcelLegacy() {
    try {
      final StringBuffer csv = StringBuffer();
      csv.write('\uFEFF');

      csv.writeln(
        'Marka;Item No;Renk;Toplam Adet;Bedenler;Mevcut Asama;Termin Tarihi;Durum;Tedarikci;Dokuma Durumu;Dokuma Adet;Dokuma Fire;Nakis Durumu;Nakis Adet;Nakis Fire;Konfeksiyon Durumu;Konfeksiyon Adet;Konfeksiyon Fire;Yikama Durumu;Yikama Adet;Ilik/Dugme Durumu;Utu Durumu;Utu Adet;Kalite Durumu;Paketleme Durumu;Fire Toplam;Olusturma Tarihi',
      );

      for (final model in _modeller) {
        final marka = _escapeCsvField(model['marka'] ?? '');
        final itemNo = _escapeCsvField(model['item_no'] ?? '');
        final renk = _escapeCsvField(model['renk'] ?? '');
        final adet = model['adet'] ?? 0;

        String bedenlerStr = '';
        if (model['bedenler'] != null) {
          try {
            if (model['bedenler'] is Map) {
              final bedenMap = model['bedenler'] as Map<String, dynamic>;
              bedenlerStr = bedenMap.entries
                  .map((e) => '${e.key}:${e.value}')
                  .join(' | ');
            } else {
              bedenlerStr = model['bedenler'].toString();
            }
          } catch (e) {
            AppLogger.debug('Veri isleme hatasi: $e');
          }
        }
        bedenlerStr = _escapeCsvField(bedenlerStr);

        final mevcutAsama = _escapeCsvField(_mevcutAsamaExportMetni(model));

        String terminStr = '';
        if (model['termin_tarihi'] != null) {
          try {
            final terminDate =
                DateTime.parse(model['termin_tarihi'].toString());
            terminStr = DateFormat('dd.MM.yyyy').format(terminDate);
          } catch (_) {
            terminStr = model['termin_tarihi'].toString();
          }
        }

        final durum =
            model['tamamlandi'] == true ? 'Tamamlandi' : 'Devam Ediyor';
        final tedarikci = _escapeCsvField(model['tedarikci_adi'] ?? '');

        final asamalar =
            model['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};

        final dokumaDurum =
            _escapeCsvField(_durumMetni(asamalar['dokuma']?['durum']));
        final dokumaAdet = asamalar['dokuma']?['tamamlanan_adet'] ?? '';
        final dokumaFire = asamalar['dokuma']?['fire_adet'] ?? 0;

        final nakisDurum =
            _escapeCsvField(_durumMetni(asamalar['nakis']?['durum']));
        final nakisAdet = asamalar['nakis']?['tamamlanan_adet'] ?? '';
        final nakisFire = asamalar['nakis']?['fire_adet'] ?? 0;

        final konfeksiyonDurum =
            _escapeCsvField(_durumMetni(asamalar['konfeksiyon']?['durum']));
        final konfeksiyonAdet =
            asamalar['konfeksiyon']?['tamamlanan_adet'] ?? '';
        final konfeksiyonFire = asamalar['konfeksiyon']?['fire_adet'] ?? 0;

        final yikamaDurum =
            _escapeCsvField(_durumMetni(asamalar['yikama']?['durum']));
        final yikamaAdet = asamalar['yikama']?['tamamlanan_adet'] ?? '';

        final ilikDugmeDurum =
            _escapeCsvField(_durumMetni(asamalar['ilik_dugme']?['durum']));

        final utuDurum =
            _escapeCsvField(_durumMetni(asamalar['utu']?['durum']));
        final utuAdet = asamalar['utu']?['tamamlanan_adet'] ?? '';

        final kaliteDurum = _escapeCsvField(
          _durumMetni(asamalar['kalite_kontrol']?['durum']),
        );
        final paketlemeDurum =
            _escapeCsvField(_durumMetni(asamalar['paketleme']?['durum']));

        var toplamFire = 0;
        if (dokumaFire is int) toplamFire += dokumaFire;
        if (nakisFire is int) toplamFire += nakisFire;
        if (konfeksiyonFire is int) toplamFire += konfeksiyonFire;

        String olusturmaTarihi = '';
        if (model['created_at'] != null) {
          try {
            final createDate = DateTime.parse(model['created_at'].toString());
            olusturmaTarihi = DateFormat('dd.MM.yyyy HH:mm').format(createDate);
          } catch (e) {
            AppLogger.debug('Veri isleme hatasi: $e');
          }
        }

        csv.writeln(
          '$marka;$itemNo;$renk;$adet;$bedenlerStr;$mevcutAsama;$terminStr;$durum;$tedarikci;$dokumaDurum;$dokumaAdet;$dokumaFire;$nakisDurum;$nakisAdet;$nakisFire;$konfeksiyonDurum;$konfeksiyonAdet;$konfeksiyonFire;$yikamaDurum;$yikamaAdet;$ilikDugmeDurum;$utuDurum;$utuAdet;$kaliteDurum;$paketlemeDurum;$toplamFire;$olusturmaTarihi',
        );
      }

      final bytes = utf8.encode(csv.toString());
      downloadFileWeb(
        bytes,
        'uretim_raporu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        mimeType: 'text/csv;charset=utf-8',
      );

      if (mounted) {
        context.showSuccessSnackBar('CSV raporu basariyla indirildi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Export hatasi: $e');
      }
    }
  }

  Map<String, dynamic> _excelSatiriOlustur(Map<String, dynamic> model) {
    final asamalar =
        model['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};
    final toplamAdet = _intDeger(model['toplam_adet'] ?? model['adet']);
    final gonderilenAdet =
        _intDeger(model['gonderilen_adet'] ?? model['yuklenen_adet']);
    final kalanAdet =
        _intDeger(model['kalan_adet'] ?? (toplamAdet - gonderilenAdet));

    String _asamaFirma(String key) =>
        asamalar[key]?['firma_adi']?.toString() ?? '';
    String _asamaBaslangic(String key) =>
        _formatTarih(asamalar[key]?['uretim_baslangic_tarihi']);
    String _asamaBitis(String key) =>
        _formatTarih(asamalar[key]?['planlanan_bitis_tarihi']);

    return {
      'model_adi': model['model_adi'] ?? model['item_no'] ?? '',
      'ana_renk': _anaRenkDeger(model),
      'iplik_karisimi': model['iplik_karisimi'] ?? '',
      'toplam_adet': toplamAdet,
      'termin_tarihi': _formatTarih(model['termin_tarihi']),
      'tamamlanan_adet': gonderilenAdet,
      'kalan_adet': kalanAdet < 0 ? 0 : kalanAdet,
      'dokuma_firma': _asamaFirma('dokuma'),
      'dokuma_baslangic': _asamaBaslangic('dokuma'),
      'dokuma_bitis': _asamaBitis('dokuma'),
      'konfeksiyon_firma': _asamaFirma('konfeksiyon'),
      'konfeksiyon_baslangic': _asamaBaslangic('konfeksiyon'),
      'konfeksiyon_bitis': _asamaBitis('konfeksiyon'),
      'utu_firma': _asamaFirma('utu'),
      'utu_baslangic': _asamaBaslangic('utu'),
      'utu_bitis': _asamaBitis('utu'),
    };
  }

  String _asamaDurumExportMetni(Map<String, dynamic>? asama) {
    if (asama == null || asama.isEmpty) return 'Bekliyor';

    final durum = _durumMetni(asama['durum']);
    final tamamlananAdet = _intDeger(asama['tamamlanan_adet']);
    final toplamAdet = _intDeger(
      asama['talep_edilen_adet'] ??
          asama['kontrol_edilecek_adet'] ??
          asama['adet'],
    );

    if (toplamAdet <= 0) return durum;
    return '$durum ($tamamlananAdet/$toplamAdet)';
  }

  int _asamaTamamlananAdet(Map<String, dynamic>? asama) {
    if (asama == null || asama.isEmpty) return 0;
    return _intDeger(asama['tamamlanan_adet']);
  }

  int _asamaFireAdet(Map<String, dynamic>? asama) {
    if (asama == null || asama.isEmpty) return 0;
    return _intDeger(asama['fire_adet']);
  }

  String _mevcutAsamaExportMetni(Map<String, dynamic> model) {
    final asamaInfo = _getAsamaBilgisi(model['mevcut_asama'] ?? '');
    return (asamaInfo['label'] ?? 'Beklemede').toString();
  }

  String _anaRenkDeger(Map<String, dynamic> model) {
    final anaRenkler = model['ana_renkler'];
    if (anaRenkler is List) {
      return anaRenkler.map((renk) => renk.toString()).join(', ');
    }
    return (model['ana_renkler'] ?? model['ana_renk'] ?? model['renk'] ?? '')
        .toString();
  }

  String _formatTarih(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final tarih = DateTime.tryParse(value.toString());
    if (tarih == null) return value.toString();
    return DateFormat('dd.MM.yyyy').format(tarih);
  }

  int _intDeger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _exportPdf() {
    try {
      final StringBuffer html = StringBuffer();
      html.write('\uFEFF');
      html.writeln('<html><head><meta charset="utf-8">');
      html.writeln('<style>');
      html.writeln(
        'body { font-family: Arial, sans-serif; margin: 20px; font-size: 12px; }',
      );
      html.writeln(
        'h1 { color: #303F9F; border-bottom: 2px solid #303F9F; padding-bottom: 8px; }',
      );
      html.writeln('h2 { color: #455A64; margin-top: 24px; }');
      html.writeln(
        '.kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin: 16px 0; }',
      );
      html.writeln(
        '.kpi-card { text-align: center; padding: 12px; border: 1px solid #ddd; border-radius: 8px; background: #f8f9fa; }',
      );
      html.writeln('.kpi-value { font-size: 24px; font-weight: bold; }');
      html.writeln('.kpi-label { font-size: 11px; color: #666; }');
      html.writeln(
        'table { width: 100%; border-collapse: collapse; margin-top: 12px; }',
      );
      html.writeln(
        'th, td { border: 1px solid #ddd; padding: 6px 8px; text-align: left; font-size: 11px; }',
      );
      html.writeln('th { background: #303F9F; color: white; }');
      html.writeln('tr:nth-child(even) { background: #f5f5f5; }');
      html.writeln(
          '.footer { margin-top: 24px; text-align: center; color: #999; font-size: 10px; }');
      html.writeln('@media print { body { margin: 0; } }');
      html.writeln('</style></head><body>');

      html.writeln('<h1>TexPilot Uretim Raporu</h1>');
      html.writeln(
        '<p>Rapor Tarihi: ${DateFormat('dd MMMM yyyy HH:mm', 'tr').format(DateTime.now())}</p>',
      );

      html.writeln('<div class="kpi-grid">');
      html.writeln(
        '<div class="kpi-card"><div class="kpi-value" style="color:#1565C0">${_ozet['toplam_model'] ?? 0}</div><div class="kpi-label">Toplam Model</div></div>',
      );
      html.writeln(
        '<div class="kpi-card"><div class="kpi-value" style="color:#E65100">${_ozet['devam_eden'] ?? 0}</div><div class="kpi-label">Devam Eden</div></div>',
      );
      html.writeln(
        '<div class="kpi-card"><div class="kpi-value" style="color:#2E7D32">${_ozet['tamamlanan'] ?? 0}</div><div class="kpi-label">Tamamlanan</div></div>',
      );
      html.writeln(
        '<div class="kpi-card"><div class="kpi-value" style="color:#C62828">${_ozet['geciken_siparis'] ?? 0}</div><div class="kpi-label">Geciken</div></div>',
      );
      html.writeln('</div>');

      html.writeln('<h2>Verimlilik Metrikleri</h2>');
      html.writeln('<table><tr><th>Metrik</th><th>Deger</th></tr>');
      html.writeln(
        '<tr><td>Uretim Verimliligi</td><td>%${((_ozet['verimlilik_orani'] as double?) ?? 100).toStringAsFixed(1)}</td></tr>',
      );
      html.writeln(
        '<tr><td>Tamamlanma Orani</td><td>%${((_ozet['tamamlanma_orani'] as double?) ?? 0).toStringAsFixed(1)}</td></tr>',
      );
      html.writeln(
        '<tr><td>Zamaninda Teslim</td><td>%${((_ozet['zamaninda_teslim_orani'] as double?) ?? 100).toStringAsFixed(1)}</td></tr>',
      );
      html.writeln(
        '<tr><td>Fire Orani</td><td>%${((_ozet['fire_orani'] as double?) ?? 0).toStringAsFixed(1)}</td></tr>',
      );
      html.writeln(
        '<tr><td>Ort. Uretim Suresi</td><td>${((_ozet['ortalama_uretim_suresi'] as double?) ?? 0).toStringAsFixed(0)} gun</td></tr>',
      );
      html.writeln('</table>');

      html.writeln('<h2>Model Listesi (${_modeller.length} model)</h2>');
      html.writeln('<table>');
      html.writeln(
        '<tr><th>#</th><th>Marka</th><th>Item No</th><th>Renk</th><th>Adet</th><th>Asama</th><th>Termin</th><th>Durum</th></tr>',
      );

      for (var i = 0; i < _modeller.length; i++) {
        final model = _modeller[i];
        final asamaInfo = _getAsamaBilgisi(model['mevcut_asama'] ?? '');
        String terminStr = '';
        if (model['termin_tarihi'] != null) {
          try {
            terminStr = DateFormat('dd.MM.yyyy')
                .format(DateTime.parse(model['termin_tarihi'].toString()));
          } catch (_) {}
        }

        html.writeln('<tr>');
        html.writeln('<td>${i + 1}</td>');
        html.writeln('<td>${_htmlEscape(model['marka'] ?? '-')}</td>');
        html.writeln('<td>${_htmlEscape(model['item_no'] ?? '-')}</td>');
        html.writeln('<td>${_htmlEscape(model['renk'] ?? '-')}</td>');
        html.writeln('<td>${model['adet'] ?? 0}</td>');
        html.writeln('<td>${asamaInfo['label']}</td>');
        html.writeln('<td>$terminStr</td>');
        html.writeln(
          '<td>${model['tamamlandi'] == true ? 'Tamamlandi' : 'Devam Ediyor'}</td>',
        );
        html.writeln('</tr>');
      }

      html.writeln('</table>');

      html.writeln('<h2>Fire Analizi</h2>');
      html.writeln(
          '<table><tr><th>Asama</th><th>Fire</th><th>Toplam</th><th>Oran</th></tr>');
      for (final entry in _fireAnaliz.entries) {
        final fire = entry.value['fire'] ?? 0;
        final toplam = entry.value['toplam'] ?? 0;
        final oran =
            toplam > 0 ? (fire / toplam * 100).toStringAsFixed(1) : '0.0';
        final info = _getAsamaBilgisi(entry.key);
        html.writeln(
          '<tr><td>${info['label']}</td><td>$fire</td><td>$toplam</td><td>%$oran</td></tr>',
        );
      }
      html.writeln('</table>');

      html.writeln(
        '<div class="footer">TexPilot Uretim Yonetim Sistemi - ${DateFormat('yyyy').format(DateTime.now())}</div>',
      );
      html.writeln('</body></html>');

      final bytes = utf8.encode(html.toString());
      downloadFileWeb(
        bytes,
        'uretim_raporu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.html',
        mimeType: 'text/html;charset=utf-8',
      );

      if (mounted) {
        context.showSuccessSnackBar(
          'PDF rapor (HTML) basariyla indirildi. Tarayicida acip Ctrl+P ile yazdirabilirsiniz.',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('PDF export hatasi: $e');
      }
    }
  }

  String _htmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
