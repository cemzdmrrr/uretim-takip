// ignore_for_file: invalid_use_of_protected_member
part of 'tedarikci_panel.dart';

/// Tedarikci panel - aksiyon ve dialog metotlari
extension _AksiyonExt on _TedarikciPanelState {
  Future<void> _handleAtamaAction(String action, Map<String, dynamic> atama) async {
    try {
      final String tableName = _getTableNameFromAtamaType(atama['atama_tipi']);
      
      if (action == 'kabul') {
        // Kabul edilen adet giriş dialog'ı
        await _showKabulDialog(atama, tableName);
      } else if (action == 'reddet') {
        // Reddetme sebebi sor
        final String? redSebebi = await _showReddetmeDialog();
        if (redSebebi != null) {
          await supabase
              .from(tableName)
              .update({
                'durum': 'reddedildi',
                'red_sebebi': redSebebi,
              })
              .eq('id', atama['id'].toString());
              
          if (!mounted) return;
          context.showErrorSnackBar('❌ Atama reddedildi');
        }
      }
      
      await _loadAtamalar();
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  Future<void> _showKabulDialog(Map<String, dynamic> atama, String tableName) async {
    final kabulAdetController = TextEditingController(
      text: atama['talep_edilen_adet']?.toString() ?? atama['adet']?.toString() ?? '0'
    );
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Kabul Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Model: ${atama[DbTables.trikoTakip]['marka']} - ${atama[DbTables.trikoTakip]['item_no']}'),
            Text('Aşama: ${atama['atama_tipi']}'),
            Text('Talep Edilen: ${atama['talep_edilen_adet'] ?? atama['adet']} adet'),
            const SizedBox(height: 16),
            TextField(
              controller: kabulAdetController,
              decoration: const InputDecoration(
                labelText: 'Kabul Edilen Adet',
                border: OutlineInputBorder(),
                helperText: 'Kaç adet işi kabul ediyorsunuz?',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kabul ettikten sonra atama aktif sekmesine geçecektir.',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final kabulAdet = int.tryParse(kabulAdetController.text) ?? 0;
                final talepEdilen = atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
                
                debugPrint('🔄 Kabul işlemi başlıyor...');
                debugPrint('   Kabul adet: $kabulAdet');
                debugPrint('   Talep edilen: $talepEdilen');
                debugPrint('   Tablo: $tableName');
                debugPrint('   Atama ID: ${atama['id']}');
                
                if (kabulAdet <= 0) {
                  throw Exception('Geçerli bir adet giriniz');
                }
                
                if (kabulAdet > talepEdilen) {
                  throw Exception('Kabul edilen adet talep edilenden fazla olamaz');
                }
                
                final updateData = {
                  'durum': 'onaylandi',
                  // Sadece mevcut kolonları güncelle
                  if (atama['talep_edilen_adet'] == null) 'talep_edilen_adet': kabulAdet,
                  if (atama['adet'] == null) 'adet': kabulAdet,
                };
                
                debugPrint('📤 Güncelleme verisi: $updateData');
                
                final result = await supabase
                    .from(tableName)
                    .update(updateData)
                    .eq('id', atama['id'].toString());
                    
                debugPrint('✅ Güncelleme sonucu: $result');
                
                // Model durumunu "üretim başladı" olarak güncelle
                try {
                  await supabase
                      .from(DbTables.trikoTakip)
                      .update({'uretim_durumu': 'üretim başladı'})
                      .eq('id', atama['model_id']);
                  debugPrint('✅ Model üretim durumu güncellendi: üretim başladı');
                } catch (e) {
                  debugPrint('⚠️ Model üretim durumu güncellenemedi: $e');
                }
                
                if (!context.mounted) return;
                Navigator.pop(context);
                
                context.showSuccessSnackBar('✅ $kabulAdet adet iş kabul edildi');
                
              } catch (e) {
                debugPrint('❌ Kabul işlemi hatası: $e');
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
  }

  String _getTableNameFromAtamaType(String atamaUpi) {
    switch (atamaUpi) {
      case 'Dokuma': return DbTables.dokumaAtamalari;
      case 'Konfeksiyon': return DbTables.konfeksiyonAtamalari;
      case 'Nakış': return DbTables.nakisAtamalari;
      case 'Yıkama': return DbTables.yikamaAtamalari;
      case 'İlik Düğme': return DbTables.ilikDugmeAtamalari;
      case 'Ütü': return DbTables.utuAtamalari;
      default: return DbTables.dokumaAtamalari;
    }
  }

  Future<void> _handleTamamlananAction(String action, Map<String, dynamic> atama) async {
    if (action == 'revize') {
      await _showRevizeDialog(atama);
    } else if (action == 'detay') {
      _showAtamaDetay(atama);
    }
  }

  Future<void> _showRevizeDialog(Map<String, dynamic> atama) async {
    final adetController = TextEditingController();
    final notlarController = TextEditingController();
    
    final mevcutTamamlanan = atama['tamamlanan_adet'] ?? 0;
    final kabulEdilenAdet = atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
    
    adetController.text = mevcutTamamlanan.toString();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tamamlanan Adeti Revize Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${atama[DbTables.trikoTakip]['marka']} - ${atama[DbTables.trikoTakip]['item_no']}'),
            Text('Aşama: ${atama['atama_tipi']}'),
            const SizedBox(height: 16),
            Text('Kabul Edilen: $kabulEdilenAdet adet'),
            Text('Mevcut Tamamlanan: $mevcutTamamlanan adet'),
            const SizedBox(height: 16),
            TextField(
              controller: adetController,
              decoration: const InputDecoration(
                labelText: 'Yeni Tamamlanan Adet',
                border: OutlineInputBorder(),
                helperText: 'Revize edilecek adet miktarını girin',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notlarController,
              decoration: const InputDecoration(
                labelText: 'Revize Nedeni',
                border: OutlineInputBorder(),
                helperText: 'Revize sebebini açıklayın',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revize sonrası durum yeniden değerlendirilecektir.',
                      style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final yeniTamamlanan = int.tryParse(adetController.text) ?? 0;
                if (yeniTamamlanan < 0) {
                  throw Exception('Adet negatif olamaz');
                }
                
                if (yeniTamamlanan > kabulEdilenAdet) {
                  throw Exception('Tamamlanan adet kabul edilenden ($kabulEdilenAdet) fazla olamaz');
                }
                
                // Yeni durumu belirle
                String yeniDurum;
                if (yeniTamamlanan == 0) {
                  yeniDurum = 'onaylandi'; // Hiç tamamlanmamış, aktif sekmesine geri dönsün
                } else if (yeniTamamlanan < kabulEdilenAdet) {
                  yeniDurum = 'kismi_tamamlandi'; // Kısmi tamamlama
                } else {
                  yeniDurum = 'tamamlandi'; // Tam tamamlama
                }
                
                final String tableName = _getTableNameFromAtamaType(atama['atama_tipi']);
                
                final guncellenecekVeri = {
                  'durum': yeniDurum,
                  'tamamlanan_adet': yeniTamamlanan,
                  'tamamlama_tarihi': yeniTamamlanan > 0 ? DateTime.now().toIso8601String() : null,
                  'uretici_notlari': notlarController.text.isNotEmpty ? 
                    '${atama['uretici_notlari'] ?? ''}\n[REVIZE] ${notlarController.text}' : 
                    atama['uretici_notlari'],
                };
                
                // Eğer kabul_edilen_adet yoksa onu da ekle
                if (atama['kabul_edilen_adet'] == null && atama['talep_edilen_adet'] != null) {
                  guncellenecekVeri['kabul_edilen_adet'] = atama['talep_edilen_adet'];
                }
                
                debugPrint('🔄 REVIZE işlemi başlıyor...');
                debugPrint('   Atama ID: ${atama['id']} (tip: ${atama['id'].runtimeType})');
                debugPrint('   Tablo: $tableName');
                debugPrint('   Mevcut Tamamlanan: $mevcutTamamlanan');
                debugPrint('   Yeni Tamamlanan: $yeniTamamlanan');
                debugPrint('   Yeni Durum: $yeniDurum');
                debugPrint('   Güncelleme Verisi: $guncellenecekVeri');
                debugPrint('   Atama Objesi: $atama');
                
                // ID'yi doğru tipte kullan
                final atamaId = atama['id']; // integer olarak bırak
                debugPrint('   Kullanılacak ID: $atamaId (${atamaId.runtimeType})');
                
                // Önce kayıt var mı ve tedarikci'ye ait mi kontrol et
                debugPrint('🔍 Kayıt varlığı kontrol ediliyor: $tableName.id=$atamaId');
                debugPrint('   Tedarikci ID: ${tedarikciInfo?['id']}');
                
                final existingRecord = await supabase
                    .from(tableName)
                    .select('id, durum, tamamlanan_adet, tedarikci_id')
                    .eq('id', atamaId)
                    .eq('tedarikci_id', tedarikciInfo!['id']) // Tedarikci kontrolü ekle
                    .maybeSingle();
                    
                debugPrint('   Mevcut kayıt: $existingRecord');
                    
                if (existingRecord == null) {
                  throw Exception('Kayıt bulunamadı veya size ait değil (ID: $atamaId, Tablo: $tableName, TedarikciID: ${tedarikciInfo!['id']})');
                }
                
                // Tek seferde tüm güncellemeyi yap - sadece temel alanları güncelle
                debugPrint('📤 Güncelleme başlatılıyor...');
                
                // En basit güncelleme - tedarikci_id kontrolü ile
                try {
                  final result = await supabase
                      .from(tableName)
                      .update({
                        'tamamlanan_adet': yeniTamamlanan,
                        'durum': yeniDurum
                      })
                      .eq('id', atamaId)
                      .eq('tedarikci_id', tedarikciInfo!['id']) // RLS için tedarikci kontrolü
                      .select();  // select() ekleyerek sonucu alalım
                      
                  debugPrint('✅ REVIZE güncelleme sonucu: $result');
                  
                  if (result.isEmpty) {
                    throw Exception('Kayıt güncellenemedi - izin hatası veya kayıt bulunamadı');
                  }
                  
                  // Revize sonrası herhangi bir tamamlanan adet varsa kalite kontrol ataması oluştur
                  if (yeniTamamlanan > 0) {
                    debugPrint('✅ Revize sonrası tamamlanan adet mevcut ($yeniTamamlanan) - kalite kontrol ataması kontrol ediliyor...');
                    
                    // Bu model için zaten kalite kontrol ataması var mı kontrol et
                    final mevcutKaliteKontrol = await supabase
                        .from(DbTables.kaliteKontrolAtamalari)
                        .select('id')
                        .eq('model_id', atama['model_id'])
                        .eq('onceki_asama', atama['atama_tipi'])
                        .maybeSingle();
                        
                    if (mevcutKaliteKontrol == null) {
                      debugPrint('🔄 Yeni kalite kontrol ataması oluşturuluyor...');
                      try {
                        await _createKaliteKontrolAtama(atama, yeniTamamlanan);
                        debugPrint('✅ Kalite kontrol ataması başarıyla oluşturuldu');
                      } catch (e) {
                        debugPrint('⚠️ Kalite kontrol ataması oluşturulamadı: $e');
                        // Kalite kontrol ataması başarısız olsa da revize işlemi devam etsin
                      }
                    } else {
                      debugPrint('ℹ️ Bu model için zaten kalite kontrol ataması mevcut');
                    }
                  }
                  
                  debugPrint('✅ REVIZE başarıyla tamamlandı');
                  
                } catch (updateError) {
                  debugPrint('❌ Güncelleme hatası: $updateError');
                  throw Exception('Güncelleme yapılamadı - RLS veya izin hatası: $updateError');
                }
                
                debugPrint('✅ REVIZE başarıyla tamamlandı');
                    
                if (!context.mounted) return;
                Navigator.pop(context, {
                  'success': true,
                  'yeniTamamlanan': yeniTamamlanan,
                  'yeniDurum': yeniDurum,
                  'revizeNedeni': notlarController.text,
                });
                
              } catch (e) {
                debugPrint('❌ REVIZE hatası: $e');
                if (!context.mounted) return;
                Navigator.pop(context, {
                  'success': false,
                  'error': e.toString(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revize Et'),
          ),
        ],
      ),
    );
    
    // Dialog'dan dönen sonucu işle
    if (result != null) {
      await _loadAtamalar();
      
      if (mounted) {
        if (result['success'] == true) {
          final yeniTamamlanan = result['yeniTamamlanan'];
          final yeniDurum = result['yeniDurum'];
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Revize tamamlandı: $yeniTamamlanan adet ($yeniDurum)'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showReddetmeDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reddetme Sebebi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reddetme sebebini yazın...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTamamlamaDialog(Map<String, dynamic> atama) async {
    final adetController = TextEditingController();
    final notlarController = TextEditingController();
    
    final kabulEdilenAdet = atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
    final mevcutTamamlanan = atama['tamamlanan_adet'] ?? 0;
    final kalanAdet = kabulEdilenAdet - mevcutTamamlanan;
    
    // Eğer daha önce kısmi tamamlama yapılmışsa, kalan adeti varsayılan değer olarak ayarla
    adetController.text = kalanAdet.toString();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşi Tamamla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${atama[DbTables.trikoTakip]['marka']} - ${atama[DbTables.trikoTakip]['item_no']}'),
            Text('Aşama: ${atama['atama_tipi']}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kabul Edilen:'),
                      Text('$kabulEdilenAdet adet', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (mevcutTamamlanan > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daha Önce Tamamlanan:'),
                        Text('$mevcutTamamlanan adet', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kalan:'),
                      Text('$kalanAdet adet', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adetController,
              decoration: const InputDecoration(
                labelText: 'Şimdi Tamamlanan Adet',
                border: OutlineInputBorder(),
                helperText: 'Bugün tamamladığınız adet sayısını girin',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notlarController,
              decoration: const InputDecoration(
                labelText: 'Notlar (İsteğe Bağlı)',
                border: OutlineInputBorder(),
                helperText: 'Özel durumlar varsa belirtin',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tüm iş tamamlandıktan sonra kalite kontrol aşamasına geçecektir.',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final simdiTamamlanan = int.tryParse(adetController.text) ?? 0;
                if (simdiTamamlanan <= 0) {
                  throw Exception('Geçerli bir adet giriniz');
                }
                
                if (simdiTamamlanan > kalanAdet) {
                  throw Exception('Tamamlanan adet kalan adetten ($kalanAdet) fazla olamaz');
                }
                
                final toplamTamamlanan = mevcutTamamlanan + simdiTamamlanan;
                final yeniDurum = toplamTamamlanan >= kabulEdilenAdet ? 'tamamlandi' : 'kismi_tamamlandi';
                
                debugPrint('🔄 Tamamlama işlemi başlıyor...');
                debugPrint('   Şimdi Tamamlanan: $simdiTamamlanan');
                debugPrint('   Mevcut Tamamlanan: $mevcutTamamlanan');
                debugPrint('   Toplam Tamamlanan: $toplamTamamlanan');
                debugPrint('   Kabul Edilen: $kabulEdilenAdet');
                debugPrint('   Yeni Durum: $yeniDurum');
                
                // Önce mevcut atamanın durumunu güncelle
                final String tableName = _getTableNameFromAtamaType(atama['atama_tipi']);
                
                final guncellenecekVeri = {
                  'durum': yeniDurum,
                  'tamamlanan_adet': toplamTamamlanan,
                  'tamamlama_tarihi': DateTime.now().toIso8601String(),
                  'uretici_notlari': notlarController.text.isNotEmpty ? notlarController.text : null,
                };
                
                debugPrint('📤 Güncelleme verisi: $guncellenecekVeri');
                debugPrint('   Tablo: $tableName');
                debugPrint('   Atama ID: ${atama['id']}');

                await supabase
                    .from(tableName)
                    .update(guncellenecekVeri)
                    .eq('id', atama['id'].toString());
                    
                debugPrint('✅ Güncelleme başarılı');
                
                // Model üretim durumunu güncelle
                try {
                  final String modelDurumu = yeniDurum == 'tamamlandi' ? 'kalite kontrolde' : 'üretimde';
                  await supabase
                      .from(DbTables.trikoTakip)
                      .update({'uretim_durumu': modelDurumu})
                      .eq('id', atama['model_id']);
                  debugPrint('✅ Model üretim durumu güncellendi: $modelDurumu');
                } catch (e) {
                  debugPrint('⚠️ Model üretim durumu güncellenemedi: $e');
                }
                
                // Herhangi bir tamamlama yapıldığında kalite kontrol ataması oluştur
                if (toplamTamamlanan > 0) {
                  debugPrint('✅ Tamamlanan adet mevcut ($toplamTamamlanan) - kalite kontrol ataması kontrol ediliyor...');
                  
                  // Bu model için zaten kalite kontrol ataması var mı kontrol et
                  final mevcutKaliteKontrol = await supabase
                      .from(DbTables.kaliteKontrolAtamalari)
                      .select('id')
                      .eq('model_id', atama['model_id'])
                      .eq('onceki_asama', atama['atama_tipi'])
                      .maybeSingle();
                      
                  if (mevcutKaliteKontrol == null) {
                    debugPrint('🔄 Yeni kalite kontrol ataması oluşturuluyor...');
                    try {
                      await _createKaliteKontrolAtama(atama, toplamTamamlanan);
                      debugPrint('✅ Kalite kontrol ataması başarıyla oluşturuldu');
                    } catch (e) {
                      debugPrint('⚠️ Kalite kontrol ataması oluşturulamadı: $e');
                      // Kalite kontrol ataması başarısız olsa da tamamlama işlemi devam etsin
                    }
                  } else {
                    debugPrint('ℹ️ Bu model için zaten kalite kontrol ataması mevcut');
                  }
                }
                    
                // Başarılı sonucu döndür
                if (!context.mounted) return;
                Navigator.pop(context, {
                  'success': true,
                  'simdiTamamlanan': simdiTamamlanan,
                  'toplamTamamlanan': toplamTamamlanan,
                  'kabulEdilenAdet': kabulEdilenAdet,
                  'yeniDurum': yeniDurum,
                });
                
              } catch (e) {
                debugPrint('❌ Tamamlama hatası: $e');
                // Hata sonucunu döndür  
                if (!context.mounted) return;
                Navigator.pop(context, {
                  'success': false,
                  'error': e.toString(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
    
    // Dialog'dan dönen sonucu işle
    if (result != null) {
      await _loadAtamalar();
      
      if (mounted) {
        if (result['success'] == true) {
          final yeniDurum = result['yeniDurum'];
          final simdiTamamlanan = result['simdiTamamlanan'];
          final toplamTamamlanan = result['toplamTamamlanan'];
          final kabulEdilenAdet = result['kabulEdilenAdet'];
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(yeniDurum == 'tamamlandi' ? 
                '✅ İş tamamen tamamlandı ve kalite kontrole hazır' :
                '✅ $simdiTamamlanan adet iş tamamlandı (Kalan: ${kabulEdilenAdet - toplamTamamlanan})'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Kalite kontrol ataması oluştur
  Future<void> _createKaliteKontrolAtama(Map<String, dynamic> oncekiAtama, int tamamlananAdet) async {
    try {
      debugPrint('🔄 Kalite kontrol ataması oluşturuluyor...');
      
      // Kalite kontrol tablosuna yeni atama ekle
      await supabase.from(DbTables.kaliteKontrolAtamalari).insert({
        'model_id': oncekiAtama['model_id'],
        'durum': 'atandi',  // atandi olarak başlar
        'onceki_asama': oncekiAtama['atama_tipi'],
        'atanan_kullanici_id': 1, // Geçici olarak 1 (sonra kalite personeli sistemi yapılacak)
        'atama_tarihi': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'notlar': '${oncekiAtama['atama_tipi']} aşaması tamamlandı - ${oncekiAtama['atama_tipi']} ID: ${oncekiAtama['id']} ($tamamlananAdet adet)',
        'firma_id': TenantManager.instance.requireFirmaId,
      });
      
      debugPrint('✅ Kalite kontrol ataması başarıyla oluşturuldu');
      
    } catch (e) {
      debugPrint('❌ Kalite kontrol ataması oluşturma hatası: $e');
      throw Exception('Kalite kontrol ataması oluşturulamadı: $e');
    }
  }

  void _showAtamaDetay(Map<String, dynamic> atama) {
    final modelData = atama[DbTables.trikoTakip];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${atama['atama_tipi']} Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${modelData['marka']} - ${modelData['item_no']}'),
            Text('Renk: ${modelData['renk'] ?? 'Belirtilmemiş'}'),
            Text('Model Adet: ${modelData['adet']}'),
            const SizedBox(height: 16),
            Text('Atama Türü: ${atama['atama_tipi']}'),
            Text('Durum: ${atama['durum']}'),
            Text('İstenen Adet: ${atama['talep_edilen_adet']}'),
            if (atama['tamamlanan_adet'] != null)
              Text('Tamamlanan: ${atama['tamamlanan_adet']}'),
            if (atama['uretici_notlari'] != null)
              Text('Notlar: ${atama['uretici_notlari']}'),
            const SizedBox(height: 16),
            if (atama['created_at'] != null)
              Text('Oluşturulma: ${DateTime.parse(atama['created_at']).toLocal().toString().split('.')[0]}'),
            if (atama['atama_tarihi'] != null)
              Text('Atama: ${DateTime.parse(atama['atama_tarihi']).toLocal().toString().split('.')[0]}'),
            if (atama['tamamlama_tarihi'] != null)
              Text('Tamamlama: ${DateTime.parse(atama['tamamlama_tarihi']).toLocal().toString().split('.')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Belirtilmemiş';
    try {
      final date = DateTime.parse(dateTimeStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildProgressBar(Map<String, dynamic> atama) {
    final kabulEdilen = (atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0).toDouble();
    final tamamlanan = (atama['tamamlanan_adet'] ?? 0).toDouble();
    final progress = kabulEdilen > 0 ? tamamlanan / kabulEdilen : 0.0;
    final yuzde = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('İlerleme: %$yuzde', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${tamamlanan.toInt()}/${kabulEdilen.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }
}
