// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

/// Export fonksiyonları — CSV ve PDF
extension _ExportExt on _UretimRaporuPageState {

  /// Excel/CSV export
  void _exportExcel() {
    try {
      final StringBuffer csv = StringBuffer();
      csv.write('\uFEFF'); // BOM

      csv.writeln('Marka;Item No;Renk;Toplam Adet;Bedenler;Mevcut Aşama;Termin Tarihi;Durum;Tedarikçi;Dokuma Durumu;Dokuma Adet;Dokuma Fire;Nakış Durumu;Nakış Adet;Nakış Fire;Konfeksiyon Durumu;Konfeksiyon Adet;Konfeksiyon Fire;Yıkama Durumu;Yıkama Adet;İlik/Düğme Durumu;Ütü Durumu;Ütü Adet;Kalite Durumu;Paketleme Durumu;Fire Toplam;Oluşturma Tarihi');

      for (var model in _modeller) {
        final marka = _escapeCsvField(model['marka'] ?? '');
        final itemNo = _escapeCsvField(model['item_no'] ?? '');
        final renk = _escapeCsvField(model['renk'] ?? '');
        final adet = model['adet'] ?? 0;
        
        String bedenlerStr = '';
        if (model['bedenler'] != null) {
          try {
            if (model['bedenler'] is Map) {
              final bedenMap = model['bedenler'] as Map<String, dynamic>;
              bedenlerStr = bedenMap.entries.map((e) => '${e.key}:${e.value}').join(' | ');
            } else {
              bedenlerStr = model['bedenler'].toString();
            }
          } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
        }
        bedenlerStr = _escapeCsvField(bedenlerStr);
        
        final mevcutAsama = _escapeCsvField(_getAsamaBilgisi(model['mevcut_asama'] ?? '')['label'] ?? 'Belirsiz');
        
        String terminStr = '';
        if (model['termin_tarihi'] != null) {
          try {
            final terminDate = DateTime.parse(model['termin_tarihi'].toString());
            terminStr = DateFormat('dd.MM.yyyy').format(terminDate);
          } catch (e) {
            terminStr = model['termin_tarihi'].toString();
          }
        }
        
        final durum = model['tamamlandi'] == true ? 'Tamamlandı' : 'Devam Ediyor';
        final tedarikci = _escapeCsvField(model['tedarikci_adi'] ?? '');
        
        final asamalar = model['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};
        
        final dokumaDurum = _escapeCsvField(_durumMetni(asamalar['dokuma']?['durum']));
        final dokumaAdet = asamalar['dokuma']?['tamamlanan_adet'] ?? '';
        final dokumaFire = asamalar['dokuma']?['fire_adet'] ?? 0;
        
        final nakisDurum = _escapeCsvField(_durumMetni(asamalar['nakis']?['durum']));
        final nakisAdet = asamalar['nakis']?['tamamlanan_adet'] ?? '';
        final nakisFire = asamalar['nakis']?['fire_adet'] ?? 0;
        
        final konfeksiyonDurum = _escapeCsvField(_durumMetni(asamalar['konfeksiyon']?['durum']));
        final konfeksiyonAdet = asamalar['konfeksiyon']?['tamamlanan_adet'] ?? '';
        final konfeksiyonFire = asamalar['konfeksiyon']?['fire_adet'] ?? 0;
        
        final yikamaDurum = _escapeCsvField(_durumMetni(asamalar['yikama']?['durum']));
        final yikamaAdet = asamalar['yikama']?['tamamlanan_adet'] ?? '';
        
        final ilikDugmeDurum = _escapeCsvField(_durumMetni(asamalar['ilik_dugme']?['durum']));
        
        final utuDurum = _escapeCsvField(_durumMetni(asamalar['utu']?['durum']));
        final utuAdet = asamalar['utu']?['tamamlanan_adet'] ?? '';
        
        final kaliteDurum = _escapeCsvField(_durumMetni(asamalar['kalite_kontrol']?['durum']));
        final paketlemeDurum = _escapeCsvField(_durumMetni(asamalar['paketleme']?['durum']));
        
        int toplamFire = 0;
        if (dokumaFire is int) toplamFire += dokumaFire;
        if (nakisFire is int) toplamFire += nakisFire;
        if (konfeksiyonFire is int) toplamFire += konfeksiyonFire;
        
        String olusturmaTarihi = '';
        if (model['created_at'] != null) {
          try {
            final createDate = DateTime.parse(model['created_at'].toString());
            olusturmaTarihi = DateFormat('dd.MM.yyyy HH:mm').format(createDate);
          } catch (e) { AppLogger.debug('Veri isleme hatasi: $e'); }
        }
        
        csv.writeln('$marka;$itemNo;$renk;$adet;$bedenlerStr;$mevcutAsama;$terminStr;$durum;$tedarikci;$dokumaDurum;$dokumaAdet;$dokumaFire;$nakisDurum;$nakisAdet;$nakisFire;$konfeksiyonDurum;$konfeksiyonAdet;$konfeksiyonFire;$yikamaDurum;$yikamaAdet;$ilikDugmeDurum;$utuDurum;$utuAdet;$kaliteDurum;$paketlemeDurum;$toplamFire;$olusturmaTarihi');
      }
      
      final bytes = utf8.encode(csv.toString());
      downloadFileWeb(bytes, 'uretim_raporu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv', mimeType: 'text/csv;charset=utf-8');
      
      if (mounted) context.showSuccessSnackBar('CSV raporu başarıyla indirildi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Export hatası: $e');
    }
  }

  /// PDF export
  void _exportPdf() {
    try {
      final StringBuffer html = StringBuffer();
      html.write('\uFEFF');
      
      // HTML tabanlı yazdırılabilir rapor
      html.writeln('<html><head><meta charset="utf-8">');
      html.writeln('<style>');
      html.writeln('body { font-family: Arial, sans-serif; margin: 20px; font-size: 12px; }');
      html.writeln('h1 { color: #303F9F; border-bottom: 2px solid #303F9F; padding-bottom: 8px; }');
      html.writeln('h2 { color: #455A64; margin-top: 24px; }');
      html.writeln('.kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin: 16px 0; }');
      html.writeln('.kpi-card { text-align: center; padding: 12px; border: 1px solid #ddd; border-radius: 8px; background: #f8f9fa; }');
      html.writeln('.kpi-value { font-size: 24px; font-weight: bold; }');
      html.writeln('.kpi-label { font-size: 11px; color: #666; }');
      html.writeln('table { width: 100%; border-collapse: collapse; margin-top: 12px; }');
      html.writeln('th, td { border: 1px solid #ddd; padding: 6px 8px; text-align: left; font-size: 11px; }');
      html.writeln('th { background: #303F9F; color: white; }');
      html.writeln('tr:nth-child(even) { background: #f5f5f5; }');
      html.writeln('.badge { padding: 2px 8px; border-radius: 10px; font-size: 10px; color: white; }');
      html.writeln('.footer { margin-top: 24px; text-align: center; color: #999; font-size: 10px; }');
      html.writeln('@media print { body { margin: 0; } }');
      html.writeln('</style></head><body>');
      
      // Başlık
      html.writeln('<h1>TexPilot Üretim Raporu</h1>');
      html.writeln('<p>Rapor Tarihi: ${DateFormat('dd MMMM yyyy HH:mm', 'tr').format(DateTime.now())}</p>');
      
      // KPI Kartları
      html.writeln('<div class="kpi-grid">');
      html.writeln('<div class="kpi-card"><div class="kpi-value" style="color:#1565C0">${_ozet['toplam_model'] ?? 0}</div><div class="kpi-label">Toplam Model</div></div>');
      html.writeln('<div class="kpi-card"><div class="kpi-value" style="color:#E65100">${_ozet['devam_eden'] ?? 0}</div><div class="kpi-label">Devam Eden</div></div>');
      html.writeln('<div class="kpi-card"><div class="kpi-value" style="color:#2E7D32">${_ozet['tamamlanan'] ?? 0}</div><div class="kpi-label">Tamamlanan</div></div>');
      html.writeln('<div class="kpi-card"><div class="kpi-value" style="color:#C62828">${_ozet['geciken_siparis'] ?? 0}</div><div class="kpi-label">Geciken</div></div>');
      html.writeln('</div>');
      
      // Verimlilik
      html.writeln('<h2>Verimlilik Metrikleri</h2>');
      html.writeln('<table><tr><th>Metrik</th><th>Değer</th></tr>');
      html.writeln('<tr><td>Üretim Verimliliği</td><td>%${((_ozet['verimlilik_orani'] as double?) ?? 100).toStringAsFixed(1)}</td></tr>');
      html.writeln('<tr><td>Tamamlanma Oranı</td><td>%${((_ozet['tamamlanma_orani'] as double?) ?? 0).toStringAsFixed(1)}</td></tr>');
      html.writeln('<tr><td>Zamanında Teslim</td><td>%${((_ozet['zamaninda_teslim_orani'] as double?) ?? 100).toStringAsFixed(1)}</td></tr>');
      html.writeln('<tr><td>Fire Oranı</td><td>%${((_ozet['fire_orani'] as double?) ?? 0).toStringAsFixed(1)}</td></tr>');
      html.writeln('<tr><td>Ort. Üretim Süresi</td><td>${((_ozet['ortalama_uretim_suresi'] as double?) ?? 0).toStringAsFixed(0)} gün</td></tr>');
      html.writeln('</table>');
      
      // Model Tablosu
      html.writeln('<h2>Model Listesi (${_modeller.length} model)</h2>');
      html.writeln('<table>');
      html.writeln('<tr><th>#</th><th>Marka</th><th>Item No</th><th>Renk</th><th>Adet</th><th>Aşama</th><th>Termin</th><th>Durum</th></tr>');
      
      for (int i = 0; i < _modeller.length; i++) {
        final model = _modeller[i];
        final asamaInfo = _getAsamaBilgisi(model['mevcut_asama'] ?? '');
        String terminStr = '';
        if (model['termin_tarihi'] != null) {
          try {
            terminStr = DateFormat('dd.MM.yyyy').format(DateTime.parse(model['termin_tarihi'].toString()));
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
        html.writeln('<td>${model['tamamlandi'] == true ? 'Tamamlandı' : 'Devam Ediyor'}</td>');
        html.writeln('</tr>');
      }
      
      html.writeln('</table>');
      
      // Fire analizi
      html.writeln('<h2>Fire Analizi</h2>');
      html.writeln('<table><tr><th>Aşama</th><th>Fire</th><th>Toplam</th><th>Oran</th></tr>');
      for (final entry in _fireAnaliz.entries) {
        final fire = entry.value['fire'] ?? 0;
        final toplam = entry.value['toplam'] ?? 0;
        final oran = toplam > 0 ? (fire / toplam * 100).toStringAsFixed(1) : '0.0';
        final info = _getAsamaBilgisi(entry.key);
        html.writeln('<tr><td>${info['label']}</td><td>$fire</td><td>$toplam</td><td>%$oran</td></tr>');
      }
      html.writeln('</table>');
      
      html.writeln('<div class="footer">TexPilot Üretim Yönetim Sistemi — ${DateFormat('yyyy').format(DateTime.now())}</div>');
      html.writeln('</body></html>');
      
      final bytes = utf8.encode(html.toString());
      downloadFileWeb(bytes, 'uretim_raporu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.html', mimeType: 'text/html;charset=utf-8');
      
      if (mounted) context.showSuccessSnackBar('PDF rapor (HTML) başarıyla indirildi. Tarayıcıda açıp Ctrl+P ile yazdırabilirsiniz.');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('PDF export hatası: $e');
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
