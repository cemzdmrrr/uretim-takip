// ignore_for_file: invalid_use_of_protected_member
part of 'iplik_stoklari.dart';

/// Order management (Excel, bulk orders, individual orders) for _IplikStoklariPageState.
extension _IplikSiparisExt on _IplikStoklariPageState {









  Future<void> _excelSablonIndir() async {
    try {
      // Excel dosyası oluştur
      final excel = excel_package.Excel.createExcel();
      final excel_package.Sheet sheetObject = excel['İplik Sipariş Formu'];
      
      // Başlık stilini tanımla
      final excel_package.CellStyle headerStyle = excel_package.CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: '#D2B48C',
        fontColorHex: '#000000',
      );
      
      final excel_package.CellStyle titleStyle = excel_package.CellStyle(
        bold: true,
        fontSize: 14,
        backgroundColorHex: '#FFF2CC',
        fontColorHex: '#000000',
      );
      
      // Başlık
      sheetObject.cell(excel_package.CellIndex.indexByString('A1')).value = 'İPLİK SİPARİŞ FORMU';
      sheetObject.cell(excel_package.CellIndex.indexByString('A1')).cellStyle = titleStyle;
      sheetObject.merge(excel_package.CellIndex.indexByString('A1'), excel_package.CellIndex.indexByString('K1'));
      
      // Genel bilgiler
      int row = 3;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'SİPARİŞ GENEL BİLGİLERİ';
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).cellStyle = headerStyle;
      sheetObject.merge(excel_package.CellIndex.indexByString('A$row'), excel_package.CellIndex.indexByString('G$row'));
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Sipariş Tarihi:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = DateFormat('dd.MM.yyyy').format(DateTime.now());
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Tedarikçi Firma:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '[Tedarikçi firma adını yazın]';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Tedarikçi Telefon:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '[Telefon numarası]';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Dokuma Firması:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '[Dokuma firması adını yazın]';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Marka:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '[Marka adını yazın]';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Termin Tarihi:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '[gg.aa.yyyy formatında]';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Genel Açıklama:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '[İsteğe bağlı açıklama]';
      
      // Sipariş detayları başlığı
      row += 2;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'SİPARİŞ DETAYLARI';
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).cellStyle = headerStyle;
      sheetObject.merge(excel_package.CellIndex.indexByString('A$row'), excel_package.CellIndex.indexByString('K$row'));
      
      // Tablo başlıkları
      row++;
      final headers = ['Sıra', 'İplik Adı/Türü', 'Renk', 'Renk Kodu', 'Miktar (kg)', 'Birim Fiyat', 'Para Birimi', 'Toplam', 'Açıklama'];
      for (int i = 0; i < headers.length; i++) {
        sheetObject.cell(excel_package.CellIndex.indexByString('${String.fromCharCode(65 + i)}$row')).value = headers[i];
        sheetObject.cell(excel_package.CellIndex.indexByString('${String.fromCharCode(65 + i)}$row')).cellStyle = headerStyle;
      }
      
      // Örnek veriler ve boş satırlar
      row++;
      
      // Örnek veriler
      final ornekVeriler = [
        ['1', 'Pamuk İplik 30/1', 'Ekru', '', '100', '15.50', 'TL', '', 'Örnek veri'],
        ['2', 'Polyester İplik 20/1', 'Siyah', 'RAL9005', '50', '18.75', 'TL', '', ''],
        ['3', 'Viskon İplik 32/1', 'Beyaz', '#FFFFFF', '75', '22.00', 'TL', '', ''],
      ];
      
      for (var veri in ornekVeriler) {
        for (int i = 0; i < veri.length; i++) {
          if (i == 7) { // Toplam kolonu - hesapla
            if (veri[4].isNotEmpty && veri[5].isNotEmpty) {
              final double miktar = double.tryParse(veri[4]) ?? 0;
              final double fiyat = double.tryParse(veri[5]) ?? 0;
              sheetObject.cell(excel_package.CellIndex.indexByString('${String.fromCharCode(65 + i)}$row')).value = (miktar * fiyat).toStringAsFixed(2);
            }
          } else {
            sheetObject.cell(excel_package.CellIndex.indexByString('${String.fromCharCode(65 + i)}$row')).value = veri[i];
          }
        }
        row++;
      }
      
      // 17 boş satır daha ekle
      for (int i = 0; i < 17; i++) {
        sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = (i + 4).toString();
        row++;
      }
      
      // Özet bölümü
      row += 2;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'ÖZET BİLGİLER';
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).cellStyle = headerStyle;
      sheetObject.merge(excel_package.CellIndex.indexByString('A$row'), excel_package.CellIndex.indexByString('K$row'));
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Toplam Kalem:';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '(Manuel hesaplayın)';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Toplam Miktar (kg):';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '(Manuel hesaplayın)';
      
      row++;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'Genel Toplam (TL):';
      sheetObject.cell(excel_package.CellIndex.indexByString('B$row')).value = '(Manuel hesaplayın)';
      
      // Kullanım talimatları
      row += 3;
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = 'KULLANIM TALİMATLARI';
      sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).cellStyle = headerStyle;
      
      final talimatlar = [
        '1. Yukarıdaki genel bilgileri doldurun',
        '2. Sipariş detayları tablosuna ürün bilgilerini girin',
        '3. Para birimi olarak TL, USD veya EUR kullanın', 
        '4. Boş satırları doldurmak zorunda değilsiniz',
        '5. Dosyayı kaydedin ve uygulamaya yükleyin',
        '',
        'DİKKAT: Bu format yapısını değiştirmeyin!'
      ];
      
      for (var talimat in talimatlar) {
        row++;
        sheetObject.cell(excel_package.CellIndex.indexByString('A$row')).value = talimat;
      }
      
      // Excel dosyasını kaydet
      final fileBytes = excel.save();
      await ExcelHelper.saveExcelFile(fileBytes!, 'Iplik_Siparis_Sablonu.xlsx');
      
      if (mounted) {
        context.showSuccessSnackBar('Excel şablon dosyası başarıyla indirildi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Şablon indirirken hata: $e');
      }
    }
  }

  Future<void> _topluSiparisOlustur() async {
    try {
      // Excel dosyası seç
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        
        // Excel dosyasını oku
        final excel = excel_package.Excel.decodeBytes(bytes);
        
        // İlk sheet'i al
        final sheet = excel.tables.keys.first;
        final table = excel.tables[sheet];
        
        if (table == null) {
          throw 'Excel dosyası okunamadı';
        }
        
        // Genel bilgileri oku
        String? tedarikciAdi;
        String? terminTarihiStr;
        String? genelAciklama;
        String? dokumaFirmasiAdi;
        String? markaAdi;
        
        // Genel bilgileri bul
        for (int row = 0; row < table.maxRows; row++) {
          final cell0 = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
          final cell1 = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
          
          if (cell0.value.toString().contains('Tedarikçi Firma') == true) {
            tedarikciAdi = cell1.value.toString();
          } else if (cell0.value.toString().contains('Dokuma Firması') == true) {
            dokumaFirmasiAdi = cell1.value.toString();
          } else if (cell0.value.toString().contains('Marka') == true) {
            markaAdi = cell1.value.toString();
          } else if (cell0.value.toString().contains('Termin Tarihi') == true) {
            terminTarihiStr = cell1.value.toString();
          } else if (cell0.value.toString().contains('Genel Açıklama') == true) {
            genelAciklama = cell1.value.toString();
          }
        }
        
        // Tedarikçi seçim dialog
        Map<String, dynamic>? seciliTedarikci;
        if (tedarikciAdi != null && tedarikciAdi.isNotEmpty && !tedarikciAdi.startsWith('[')) {
          final tedarikciAdiLower = tedarikciAdi.toLowerCase();
          // Tedarikçi adına göre ara
          seciliTedarikci = tedarikciler.where((t) => 
            (t['sirket']?.toString().toLowerCase().contains(tedarikciAdiLower) == true) ||
            (t['ad']?.toString().toLowerCase().contains(tedarikciAdiLower) == true)
          ).isNotEmpty ? tedarikciler.firstWhere((t) => 
            (t['sirket']?.toString().toLowerCase().contains(tedarikciAdiLower) == true) ||
            (t['ad']?.toString().toLowerCase().contains(tedarikciAdiLower) == true)
          ) : null;
        }
        
        if (seciliTedarikci == null) {
          // Manuel tedarikçi seçimi
          seciliTedarikci = await _tedarikciSecDialog();
          if (seciliTedarikci == null) return;
        }
        
        // Termin tarihi parse et
        DateTime? terminTarihi;
        if (terminTarihiStr != null && terminTarihiStr.isNotEmpty && !terminTarihiStr.startsWith('[')) {
          try {
            if (terminTarihiStr.contains('.')) {
              final parts = terminTarihiStr.split('.');
              if (parts.length == 3) {
                terminTarihi = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0])
                );
              }
            }
          } catch (e) {
            debugPrint('Tarih parse hatası: $e');
          }
        }
        
        // Sipariş detaylarını oku
        final List<Map<String, dynamic>> siparisDetaylari = [];
        bool detayBaslangici = false;
        
        for (int row = 0; row < table.maxRows; row++) {
          final cell0 = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
          
          // Detay başlangıcını bul
          if (cell0.value.toString().contains('SİPARİŞ DETAYLARI') == true) {
            detayBaslangici = true;
            continue;
          }
          
          // Başlık satırını atla
          if (detayBaslangici && cell0.value.toString() == 'Sıra') {
            continue;
          }
          
          // Detay verilerini oku
          if (detayBaslangici) {
            final sira = cell0.value.toString();
            final iplikAdi = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value.toString();
            final renk = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value.toString();
            final renkKodu = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value.toString();
            final miktarStr = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value.toString();
            final birimFiyatStr = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value.toString();
            final paraBirimi = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value.toString();
            final aciklama = table.cell(excel_package.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value.toString();
            
            // Boş satır kontrolü
            if (iplikAdi.isEmpty || miktarStr.isEmpty) {
              continue;
            }
            
            // Özet bölümüne geldiysek dur
            if (iplikAdi.contains('ÖZET') || sira.contains('ÖZET')) {
              break;
            }
            
            final miktar = double.tryParse(miktarStr);
            final birimFiyat = double.tryParse(birimFiyatStr);
            
            // Renk bilgisini birleştir (tekli siparişle aynı format)
            String? renkBilgisi;
            if (renk.isNotEmpty || renkKodu.isNotEmpty) {
              if (renk.isNotEmpty && renkKodu.isNotEmpty) {
                renkBilgisi = '$renk / $renkKodu';
              } else if (renk.isNotEmpty) {
                renkBilgisi = renk;
              } else {
                renkBilgisi = renkKodu;
              }
            }
            
            if (miktar != null && miktar > 0) {
              siparisDetaylari.add({
                'iplik_adi': iplikAdi,
                'renk': renkBilgisi,
                'miktar': miktar,
                'birim_fiyat': birimFiyat,
                'para_birimi': paraBirimi.isNotEmpty ? paraBirimi : 'TL',
                'aciklama': aciklama.isNotEmpty ? aciklama : null,
              });
            }
          }
        }
        
        if (siparisDetaylari.isEmpty) {
          throw 'Excel dosyasında geçerli sipariş detayı bulunamadı';
        }
        
        // Dokuma firması eşleştirme
        Map<String, dynamic>? seciliDokumaFirmasi;
        if (dokumaFirmasiAdi != null && dokumaFirmasiAdi.isNotEmpty && !dokumaFirmasiAdi.startsWith('[')) {
          final dokumaAdiLower = dokumaFirmasiAdi.toLowerCase();
          seciliDokumaFirmasi = tedarikciler.where((t) => 
            (t['sirket']?.toString().toLowerCase().contains(dokumaAdiLower) == true) ||
            (t['ad']?.toString().toLowerCase().contains(dokumaAdiLower) == true)
          ).isNotEmpty ? tedarikciler.firstWhere((t) => 
            (t['sirket']?.toString().toLowerCase().contains(dokumaAdiLower) == true) ||
            (t['ad']?.toString().toLowerCase().contains(dokumaAdiLower) == true)
          ) : null;
        }
        
        // Onay dialog göster
        final onay = await _topluSiparisOnayDialog(siparisDetaylari, seciliTedarikci, terminTarihi, genelAciklama);
        if (!onay) return;
        
        // Siparişleri kaydet
        await _topluSiparisleriKaydet(siparisDetaylari, seciliTedarikci, terminTarihi, genelAciklama, 
          marka: (markaAdi != null && markaAdi.isNotEmpty && !markaAdi.startsWith('[')) ? markaAdi : null,
          dokumaFirmasi: seciliDokumaFirmasi,
        );
        
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Toplu sipariş yüklenirken hata: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _tedarikciSecDialog() async {
    Map<String, dynamic>? seciliTedarikci;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tedarikçi Seçin'),
          content: SizedBox(
            width: 400,
            child: DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: seciliTedarikci,
              decoration: const InputDecoration(
                labelText: 'Tedarikçi',
                border: OutlineInputBorder(),
              ),
              items: tedarikciler.map((tedarikci) {
                return DropdownMenuItem(
                  value: tedarikci,
                  child: Text('${tedarikci['sirket'] ?? tedarikci['ad']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  seciliTedarikci = value;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                seciliTedarikci = null;
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: seciliTedarikci != null ? () => Navigator.pop(context) : null,
              child: const Text('Seç'),
            ),
          ],
        ),
      ),
    );
    
    return seciliTedarikci;
  }

  Future<bool> _topluSiparisOnayDialog(
    List<Map<String, dynamic>> siparisDetaylari,
    Map<String, dynamic> tedarikci,
    DateTime? terminTarihi,
    String? genelAciklama,
  ) async {
    bool onay = false;
    
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFD2B48C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.preview, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Toplu Sipariş Önizleme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genel bilgiler
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tedarikçi: ${tedarikci['sirket'] ?? tedarikci['ad']}'),
                              if (terminTarihi != null)
                                Text('Termin: ${DateFormat('dd.MM.yyyy').format(terminTarihi)}'),
                              if (genelAciklama?.isNotEmpty == true)
                                Text('Açıklama: $genelAciklama'),
                              Text('Toplam Kalem: ${siparisDetaylari.length}'),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      const Text('Sipariş Detayları:', style: TextStyle(fontWeight: FontWeight.bold)),
                      
                      // Sipariş listesi
                      Expanded(
                        child: ListView.builder(
                          itemCount: siparisDetaylari.length,
                          itemBuilder: (context, index) {
                            final detay = siparisDetaylari[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 12,
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(detay['iplik_adi']),
                                subtitle: Text(
                                  '${detay['renk'] ?? 'Renk yok'} - ${detay['miktar']} kg${detay['birim_fiyat'] != null ? ' - ${detay['birim_fiyat']} ${detay['para_birimi']}' : ''}'
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          onay = false;
                          Navigator.pop(context);
                        },
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          onay = true;
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('${siparisDetaylari.length} Siparişi Oluştur'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    return onay;
  }

  Future<void> _topluSiparisleriKaydet(
    List<Map<String, dynamic>> siparisDetaylari,
    Map<String, dynamic> tedarikci,
    DateTime? terminTarihi,
    String? genelAciklama, {
    String? marka,
    Map<String, dynamic>? dokumaFirmasi,
  }) async {
    try {
      int basariliSayisi = 0;
      final List<String> hatalar = [];
      
      for (int i = 0; i < siparisDetaylari.length; i++) {
        try {
          final detay = siparisDetaylari[i];
          final siparisNo = 'SIP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${i + 1}';
          
          final siparisData = {
            'siparis_no': siparisNo,
            'tedarikci_id': tedarikci['id'],
            'iplik_adi': detay['iplik_adi'],
            'renk': detay['renk'],
            'miktar': detay['miktar'],
            'birim': 'kg',
            'birim_fiyat': detay['birim_fiyat'],
            'para_birimi': detay['para_birimi'] ?? 'TL',
            'termin_tarihi': terminTarihi?.toIso8601String(),
            'durum': 'beklemede',
            'aciklama': detay['aciklama'] ?? genelAciklama,
            'siparis_tarihi': DateTime.now().toIso8601String(),
            'firma_id': TenantManager.instance.requireFirmaId,
            if (marka != null) 'marka': marka,
            if (dokumaFirmasi != null) 'orgu_firmasi_id': dokumaFirmasi['id'],
          };

          if (detay['birim_fiyat'] != null) {
            siparisData['toplam_tutar'] = detay['miktar'] * detay['birim_fiyat'];
          }

          await supabase.from(DbTables.iplikSiparisleri).insert(siparisData);
          basariliSayisi++;
          
          // Her 5 siparişte bir kısa bekle
          if (i % 5 == 0) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
        } catch (e) {
          hatalar.add('${i + 1}. sipariş: ${e.toString()}');
        }
      }
      
      await _verileriYukle(); // Veriyi yenile
      
      if (mounted) {
        if (hatalar.isEmpty) {
          context.showSuccessSnackBar('$basariliSayisi sipariş başarıyla oluşturuldu');
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Toplu Sipariş Sonucu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Başarılı: $basariliSayisi'),
                  Text('Hatalı: ${hatalar.length}'),
                  if (hatalar.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Hatalar:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...hatalar.take(5).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
                    if (hatalar.length > 5)
                      Text('... ve ${hatalar.length - 5} hata daha'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Toplu sipariş kaydedilirken hata: $e');
      }
    }
  }


  Future<void> _yeniSiparisOlustur() async {
    final siparisNoController = TextEditingController();
    final iplikAdiController = TextEditingController();
    final renkController = TextEditingController();
    final renkKoduController = TextEditingController();
    final miktarController = TextEditingController();
    final birimFiyatController = TextEditingController();
    final aciklamaController = TextEditingController();
    final markaController = TextEditingController();
    
    Map<String, dynamic>? seciliTedarikci;
    Map<String, dynamic>? seciliDokumaFirmasi;
    String seciliParaBirimi = 'TL';
    DateTime? terminTarihi;
    DateTime siparisTarihi = DateTime.now();
    const String siparisDurumu = 'beklemede';
    
    // İplik firması olan tedarikçileri getir
    // İplik firması olan tedarikçileri getir
    final iplikTedarikcileri = tedarikciler.where((tedarikci) {
      final turu = tedarikci['tedarikci_turu']?.toString().toLowerCase() ?? '';
      final faaliyet = tedarikci['faaliyet']?.toString().toLowerCase() ?? '';
      final faaliyetAlani = tedarikci['faaliyet_alani']?.toString().toLowerCase() ?? '';
      final sirket = tedarikci['sirket']?.toString().toLowerCase() ?? '';
      final ad = tedarikci['ad']?.toString().toLowerCase() ?? '';
      
      // İplik firmalarını filtrele
      return turu == 'iplik firması' ||
             turu.contains('iplik') ||
             faaliyet == 'iplik' ||
             faaliyet.contains('iplik') ||
             faaliyetAlani == 'iplik' ||
             faaliyetAlani.contains('iplik') ||
             sirket.contains('iplik') ||
             ad.contains('iplik');
    }).toList();
    
    // Dokuma firması olan tedarikçileri getir (Dokuma faaliyet alanı)
    final dokumaFirmalari = tedarikciler.where((tedarikci) {
      final turu = tedarikci['tedarikci_turu']?.toString().toLowerCase() ?? '';
      final faaliyet = tedarikci['faaliyet']?.toString().toLowerCase() ?? '';
      final faaliyetAlani = tedarikci['faaliyet_alani']?.toString().toLowerCase() ?? '';
      final sirket = tedarikci['sirket']?.toString().toLowerCase() ?? '';
      final ad = tedarikci['ad']?.toString().toLowerCase() ?? '';
      
      // Debug için
      debugPrint('Tedarikçi: ${tedarikci['sirket'] ?? tedarikci['ad']}, Tür: "$turu", Faaliyet: "$faaliyet", Faaliyet Alanı: "$faaliyetAlani"');
      
      // Dokuma faaliyet alanı olan firmaları filtrele
      return (turu == 'üretici' && faaliyet == 'dokuma') ||
             (turu == 'üretici' && faaliyetAlani == 'dokuma') ||
             turu == 'dokuma firması' || 
             turu.contains('dokuma') ||
             faaliyet == 'dokuma' ||
             faaliyet.contains('dokuma') ||
             faaliyetAlani == 'dokuma' ||
             faaliyetAlani.contains('dokuma') ||
             sirket.contains('dokuma') ||
             ad.contains('dokuma');
    }).toList();
    
    // Debug için sonuç sayısını yazdır
    debugPrint('Toplam tedarikçi sayısı: ${tedarikciler.length}');
    debugPrint('İplik firması sayısı: ${iplikTedarikcileri.length}');
    debugPrint('Dokuma firması sayısı: ${dokumaFirmalari.length}');
    
    // Otomatik sipariş numarası oluştur
    final siparisNo = 'SIP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    siparisNoController.text = siparisNo;
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.85,
            constraints: const BoxConstraints(
              maxWidth: 800,
              maxHeight: 700,
            ),
            child: Column(
              children: [
                // Başlık
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2B48C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_shopping_cart, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Yeni İplik Siparişi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Form içeriği
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sipariş No ve Tarih
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: siparisNoController,
                                decoration: const InputDecoration(
                                  labelText: 'Sipariş No',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final tarih = await showDatePicker(
                                    context: context,
                                    initialDate: siparisTarihi,
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 30)),
                                  );
                                  if (tarih != null) {
                                    setState(() {
                                      siparisTarihi = tarih;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Sipariş Tarihi',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(siparisTarihi),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Tedarikçi Seçimi
                        DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: seciliTedarikci,
                          decoration: const InputDecoration(
                            labelText: 'Tedarikçi (İplik Firması) *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: iplikTedarikcileri.map((tedarikci) {
                            return DropdownMenuItem(
                              value: tedarikci,
                              child: Text(
                                '${tedarikci['sirket'] ?? tedarikci['ad'] ?? 'İsimsiz'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: iplikTedarikcileri.isEmpty ? null : (value) {
                            setState(() {
                              seciliTedarikci = value;
                            });
                          },
                        ),
                        
                        // İplik firması yoksa uyarı göster
                        if (iplikTedarikcileri.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tedarikçi bulunamadı!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      Text(
                                        'Tedarikçiler bölümünden tedarikçi ekleyin.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        
                        // Marka ve Dokuma Firması
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: markaController,
                                decoration: const InputDecoration(
                                  labelText: 'Marka *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.branding_watermark),
                                  hintText: 'Hangi marka için sipariş',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<Map<String, dynamic>>(
                                initialValue: seciliDokumaFirmasi,
                                decoration: const InputDecoration(
                                  labelText: 'Dokuma Firması (Teslimat) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.factory),
                                ),
                                items: dokumaFirmalari.map((firma) {
                                  return DropdownMenuItem(
                                    value: firma,
                                    child: Text(
                                      '${firma['sirket'] ?? firma['ad'] ?? 'İsimsiz'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: dokumaFirmalari.isEmpty ? null : (value) {
                                  setState(() {
                                    seciliDokumaFirmasi = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Dokuma firması yoksa uyarı göster
                        if (dokumaFirmalari.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dokuma firması bulunamadı!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        'Tedarikçiler bölümünden tedarikçi ekleyin.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        
                        // İplik Bilgileri
                        TextField(
                          controller: iplikAdiController,
                          decoration: const InputDecoration(
                            labelText: 'İplik Adı/Türü *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                            hintText: 'Örn: Pamuk İplik 30/1, Polyester İplik 20/1',
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Renk ve Renk Kodu
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: renkController,
                                decoration: const InputDecoration(
                                  labelText: 'Renk',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.palette),
                                  hintText: 'Örn: Beyaz, Siyah, Lacivert',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: renkKoduController,
                                decoration: const InputDecoration(
                                  labelText: 'Renk Kodu',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.color_lens),
                                  hintText: 'Örn: RAL9010, #FFFFFF',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Miktar ve Fiyat
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: miktarController,
                                decoration: const InputDecoration(
                                  labelText: 'Miktar (kg) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.straighten),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: birimFiyatController,
                                decoration: const InputDecoration(
                                  labelText: 'Birim Fiyat',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: seciliParaBirimi,
                                decoration: const InputDecoration(
                                  labelText: 'Para Birimi',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'TL', child: Text('₺ TL')),
                                  DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                                  DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    seciliParaBirimi = value ?? 'TL';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Termin Tarihi
                        InkWell(
                          onTap: () async {
                            final tarih = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (tarih != null) {
                              setState(() {
                                terminTarihi = tarih;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Termin Tarihi',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event),
                            ),
                            child: Text(
                              terminTarihi != null 
                                ? DateFormat('dd.MM.yyyy').format(terminTarihi!)
                                : 'Termin tarihi seçin',
                              style: TextStyle(
                                color: terminTarihi != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Açıklama
                        TextField(
                          controller: aciklamaController,
                          decoration: const InputDecoration(
                            labelText: 'Açıklama / Notlar',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        
                        // Toplam Tutar Gösterimi
                        if (miktarController.text.isNotEmpty && birimFiyatController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD2B48C).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD2B48C).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Toplam Tutar:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_getParaBirimiSembolu(seciliParaBirimi)}${_hesaplaToplamTutar(miktarController.text, birimFiyatController.text)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD2B48C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Alt butonlar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _siparisiKaydet(
                              siparisNo: siparisNoController.text,
                              tedarikci: seciliTedarikci,
                              dokumaFirmasi: seciliDokumaFirmasi,
                              marka: markaController.text,
                              iplikAdi: iplikAdiController.text,
                              renk: renkController.text,
                              renkKodu: renkKoduController.text,
                              miktar: miktarController.text,
                              birimFiyat: birimFiyatController.text,
                              paraBirimi: seciliParaBirimi,
                              terminTarihi: terminTarihi,
                              siparisTarihi: siparisTarihi,
                              durum: siparisDurumu,
                              aciklama: aciklamaController.text,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Siparişi Kaydet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2B48C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _hesaplaToplamTutar(String miktarStr, String birimFiyatStr) {
    final miktar = double.tryParse(miktarStr) ?? 0;
    final birimFiyat = double.tryParse(birimFiyatStr) ?? 0;
    final toplam = miktar * birimFiyat;
    return toplam.toStringAsFixed(2);
  }

  Future<void> _siparisiKaydet({
    required String siparisNo,
    required Map<String, dynamic>? tedarikci,
    required Map<String, dynamic>? dokumaFirmasi,
    required String marka,
    required String iplikAdi,
    required String renk,
    required String renkKodu,
    required String miktar,
    required String birimFiyat,
    required String paraBirimi,
    required DateTime? terminTarihi,
    required DateTime siparisTarihi,
    required String durum,
    required String aciklama,
  }) async {
    try {
      if (tedarikci == null || dokumaFirmasi == null || marka.trim().isEmpty || iplikAdi.trim().isEmpty || miktar.trim().isEmpty) {
        throw 'Tedarikçi, dokuma firması, marka, iplik adı ve miktar zorunludur';
      }

      final miktarSayi = double.tryParse(miktar.trim());
      if (miktarSayi == null || miktarSayi <= 0) {
        throw 'Geçerli bir miktar girin';
      }

      final birimFiyatSayi = birimFiyat.trim().isNotEmpty 
        ? double.tryParse(birimFiyat.trim()) 
        : null;

      // Renk bilgisini birleştir
      String? renkBilgisi;
      if (renk.trim().isNotEmpty || renkKodu.trim().isNotEmpty) {
        if (renk.trim().isNotEmpty && renkKodu.trim().isNotEmpty) {
          renkBilgisi = '${renk.trim()} / ${renkKodu.trim()}';
        } else if (renk.trim().isNotEmpty) {
          renkBilgisi = renk.trim();
        } else {
          renkBilgisi = renkKodu.trim();
        }
      }

      // Sipariş verisini hazırla
      final siparisData = {
        'siparis_no': siparisNo,
        'tedarikci_id': tedarikci['id'],
        'orgu_firmasi_id': dokumaFirmasi['id'], // Dokuma firması ID'si orgu_firmasi_id alanına kaydediliyor
        'marka': marka.trim(),
        'iplik_adi': iplikAdi.trim(),
        'renk': renkBilgisi,
        'miktar': miktarSayi,
        'birim': 'kg',
        'birim_fiyat': birimFiyatSayi,
        'para_birimi': paraBirimi,
        'termin_tarihi': terminTarihi?.toIso8601String(),
        'durum': durum,
        'aciklama': aciklama.trim().isNotEmpty ? aciklama.trim() : null,
        'siparis_tarihi': siparisTarihi.toIso8601String(),
        'firma_id': TenantManager.instance.requireFirmaId,
      };

      if (birimFiyatSayi != null) {
        siparisData['toplam_tutar'] = miktarSayi * birimFiyatSayi;
      }

      // Sipariş tablosuna kaydet (tablo yoksa oluşturulacak)
      await supabase.from(DbTables.iplikSiparisleri).insert(siparisData);

      if (!context.mounted) return;
      await _verileriYukle(); // Veriyi yenile
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      context.showSuccessSnackBar('Sipariş $siparisNo başarıyla oluşturuldu');
    } catch (e) {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar('Hata: $e');
    }
  }
}
