// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_asama_dashboard.dart';

/// Uretim asama model karti, aksiyonlar ve dialog'lar
extension _AksiyonlarAsamaExt on _UretimAsamaDashboardState {
  Widget _buildModelKarti(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = atama['durum'] as String?;
    final tamamlananAdet = atama['tamamlanan_adet'] ?? 0;
    final kabulEdilenAdet = atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? model['adet'] ?? 0;
    
    // Model verisi yoksa atama tablosundaki adet'i kullan
    final displayAdet = model['adet']?.toString() ?? atama['adet']?.toString();
    final displayRenk = model['renk'] ?? '-';
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve durum badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${model['marka'] ?? 'Bilinmeyen Marka'} - ${model['item_no'] ?? 'Bilinmeyen Model'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDurumBadge(durum),
              ],
            ),
            const SizedBox(height: 12),
            
            // Model bilgileri
            _buildModelBilgisi('Adet', displayAdet),
            _buildModelBilgisi('Renk', displayRenk),
            
            // Atama bilgileri
            if (atama['talep_edilen_adet'] != null)
              _buildModelBilgisi('Talep Edilen', atama['talep_edilen_adet']?.toString()),
            if (atama['kabul_edilen_adet'] != null)
              _buildModelBilgisi('Kabul Edilen', atama['kabul_edilen_adet']?.toString()),
            if (tamamlananAdet > 0)
              _buildModelBilgisi('Tamamlanan', '$tamamlananAdet', textColor: Colors.green),
            
            // İlerleme çubuğu (sadece aktif işler için)
            if (kabulEdilenAdet > 0 && (durum == 'onaylandi' || durum == 'uretimde' || durum == 'baslatildi' || durum == 'kismi_tamamlandi')) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (tamamlananAdet as num) / (kabulEdilenAdet as num),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tamamlananAdet >= kabulEdilenAdet ? Colors.green : widget.asamaRengi,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '%${(((tamamlananAdet) / (kabulEdilenAdet)) * 100).toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
            
            if (model['termin_tarihi'] != null)
              _buildModelBilgisi(
                'Termin',
                DateFormat('dd.MM.yyyy').format(DateTime.parse(model['termin_tarihi'])),
                textColor: Colors.red,
              ),
            
            if (atama['atama_tarihi'] != null)
              _buildModelBilgisi(
                'Atama Tarihi',
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(atama['atama_tarihi'])),
              ),

            if (atama['onay_tarihi'] != null)
              _buildModelBilgisi(
                'Onay Tarihi',
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(atama['onay_tarihi'])),
                textColor: Colors.green,
              ),

            if (atama['uretim_baslangic_tarihi'] != null)
              _buildModelBilgisi(
                'Başlangıç',
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(atama['uretim_baslangic_tarihi'])),
                textColor: Colors.blue,
              ),

            if (atama['planlanan_bitis_tarihi'] != null)
              _buildModelBilgisi(
                'Planlanan Bitiş',
                DateFormat('dd.MM.yyyy').format(DateTime.parse(atama['planlanan_bitis_tarihi'])),
                textColor: Colors.orange,
              ),

            if (atama['tamamlama_tarihi'] != null)
              _buildModelBilgisi(
                'Tamamlama',
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(atama['tamamlama_tarihi'])),
                textColor: Colors.purple,
              ),
            
            if (atama['notlar'] != null && atama['notlar'].toString().isNotEmpty)
              _buildModelBilgisi('Notlar', atama['notlar']),
            
            // Aksiyon butonları
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildAksiyonButonlari(atama, model, durum),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAksiyonButonlari(Map<String, dynamic> atama, Map<String, dynamic> model, String? durum) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Detay butonu - her zaman görünür
        OutlinedButton.icon(
          onPressed: () => _genericDetayDialog(atama),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Detay'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
        
        // Geri Al butonu - tamamlanmış veya reddedilmiş işler için
        if (durum == 'tamamlandi' || durum == 'reddedildi')
          OutlinedButton.icon(
            onPressed: () => _showGeriAlDialog(atama),
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Geri Al'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),
        
        // Kabul Et butonu - sadece bekleyen işler için
        if (durum == 'bekleyen' || durum == 'beklemede' || durum == 'atandi' || durum == 'kontrol_bekliyor')
          ElevatedButton.icon(
            onPressed: () => _showKabulDialog(atama),
            icon: const Icon(Icons.thumb_up, size: 18),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        
        // Reddet butonu - sadece bekleyen işler için
        if (durum == 'bekleyen' || durum == 'beklemede' || durum == 'atandi' || durum == 'kontrol_bekliyor')
          ElevatedButton.icon(
            onPressed: () => _showReddetDialog(atama),
            icon: const Icon(Icons.thumb_down, size: 18),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        
        // Üretime Al butonu - onaylanmış işler için
        if (durum == 'onaylandi')
          ElevatedButton.icon(
            onPressed: () => _showUretimeAlDialog(atama),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Üretime Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        
        // Üretimi Tamamla butonu - üretimde olan işler için
        if (durum == 'uretimde' || durum == 'baslatildi' || durum == 'kismi_tamamlandi')
          ElevatedButton.icon(
            onPressed: () => _showTamamlaDialog(atama),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
  
  // Düzenle Dialog'u
  
  // Sil Dialog'u
  
  // Geri Al Dialog'u
  void _showGeriAlDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final mevcutDurum = atama['durum'] as String?;
    
    String hedefDurum = 'onaylandi'; // Varsayılan olarak onaylandı durumuna al
    if (mevcutDurum == 'reddedildi') {
      hedefDurum = 'atandi'; // Reddedilmiş ise bekleyen durumuna al
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durumu Geri Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${model['marka']} - ${model['item_no']}'),
            const SizedBox(height: 16),
            Text(
              mevcutDurum == 'tamamlandi'
                ? 'Tamamlanmış atamayı "Onaylandı" durumuna geri almak istiyor musunuz?'
                : 'Reddedilmiş atamayı "Beklemede" durumuna geri almak istiyor musunuz?',
            ),
            const SizedBox(height: 8),
            Text(
              'Bu işlem ile atama tekrar işleme alınabilir.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                await supabase
                    .from(widget.atamaTablosu)
                    .update({
                      'durum': hedefDurum,
                      'tamamlama_tarihi': null,
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', atama['id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('↩️ Atama "$hedefDurum" durumuna geri alındı'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text('Geri Al'),
          ),
        ],
      ),
    );
  }
  
  // Kabul Et Dialog'u
  void _showKabulDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final adetController = TextEditingController(
      text: (atama['talep_edilen_adet'] ?? atama['adet'] ?? model['adet'] ?? 0).toString()
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Kabul Et'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model: ${model['marka']} - ${model['item_no']}'),
              Text('Talep Edilen: ${atama['talep_edilen_adet'] ?? atama['adet'] ?? model['adet']} adet'),
              const SizedBox(height: 16),
              TextField(
                controller: adetController,
                decoration: const InputDecoration(
                  labelText: 'Kabul Edilen Adet',
                  border: OutlineInputBorder(),
                  helperText: 'Tamamlayabileceğiniz adet miktarı',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final kabulAdet = int.tryParse(adetController.text) ?? 0;
                if (kabulAdet <= 0) {
                  throw Exception('Geçerli bir adet giriniz');
                }
                
                await supabase
                    .from(widget.atamaTablosu)
                    .update({
                      'kabul_edilen_adet': kabulAdet,
                      'durum': 'onaylandi',
                      'onay_tarihi': DateTime.now().toIso8601String(),
                    })
                    .eq('id', atama['id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();
                
                if (mounted) {
                  context.showSuccessSnackBar('✅ $kabulAdet adet kabul edildi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
  }
  
  // Reddet Dialog'u
  void _showReddetDialog(Map<String, dynamic> atama) {
    final sebebController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu atamayı reddetmek istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            TextField(
              controller: sebebController,
              decoration: const InputDecoration(
                labelText: 'Red Sebebi',
                border: OutlineInputBorder(),
                helperText: 'Reddetme nedeninizi yazın',
              ),
              maxLines: 2,
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
                if (sebebController.text.isEmpty) {
                  throw Exception('Lütfen red sebebini belirtin');
                }
                
                await supabase
                    .from(widget.atamaTablosu)
                    .update({
                      'durum': 'reddedildi',
                      'notlar': '[RED SEBEBİ] ${sebebController.text}',
                    })
                    .eq('id', atama['id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();
                
                if (mounted) {
                  context.showErrorSnackBar('❌ Atama reddedildi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }


  Future<void> _genericDetayDialog(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = atama['durum'] as String?;
    
    // Model verisi yoksa atama tablosundaki adet'i kullan
    final displayAdet = model['adet']?.toString() ?? atama['adet']?.toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.asamaDisplayName} - ${model['model_adi']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDurumBadge(durum),
              const SizedBox(height: 16),
              _buildModelBilgisi('Adet', displayAdet),
              _buildModelBilgisi('Renk', model['renk'] ?? '-'),
              if (atama['notlar'] != null)
                _buildModelBilgisi('Notlar', atama['notlar']),
            ],
          ),
        ),
        actions: [
          if (durum == 'bekleyen' || durum == 'beklemede' || durum == 'atandi' || durum == 'kontrol_bekliyor' || durum == null) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _aksiyon(atama, 'onaylandi');
              },
              child: const Text('Onayla'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reddet(atama);
              },
              child: const Text('Reddet'),
            ),
          ] else if (durum == 'onaylandi') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showUretimeAlDialog(atama);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Üretime Al'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.asamaRengi,
                foregroundColor: Colors.white,
              ),
            ),
          ] else if (durum == 'uretimde') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showTamamlaDialog(atama);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Tamamla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _aksiyon(Map<String, dynamic> atama, String yeniDurum) async {
    try {
      final updateData = <String, dynamic>{
        'durum': yeniDurum,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (yeniDurum == 'onaylandi') {
        updateData['onay_tarihi'] = DateTime.now().toIso8601String();
      } else if (yeniDurum == 'uretimde') {
        updateData['uretim_baslangic_tarihi'] = DateTime.now().toIso8601String();
      } else if (yeniDurum == 'tamamlandi') {
        updateData['tamamlama_tarihi'] = DateTime.now().toIso8601String();
        // Tamamlanan adeti kabul edilen adete eşitle
        final tamamlananAdet = atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
        updateData['tamamlanan_adet'] = tamamlananAdet;
      }

      await supabase
          .from(widget.atamaTablosu)
          .update(updateData)
          .eq('id', atama['id']);

      // Modeller tablosundaki durumu da güncelle (triko_takip)
      try {
        await supabase
            .from(DbTables.trikoTakip)
            .update({widget.modelDurumKolonu: yeniDurum})
            .eq('id', atama['model_id']);
      } catch (e) {
        debugPrint('⚠️ Model durumu güncellenemedi (triko_takip): $e');
      }

      // Yıkama ve Kalite Kontrol aşamaları için direkt sevkiyat, diğerleri için kalite kontrol
      if (yeniDurum == 'tamamlandi') {
        final tamamlananAdet = atama['tamamlanan_adet'] ?? atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
        if (widget.asamaAdi == 'yikama' || widget.asamaAdi == 'kalite_kontrol') {
          await _sevkiyatAtamasiOlustur(atama, tamamlananAdet: tamamlananAdet);
        } else {
          await _kaliteKontrolAtamasiOlustur(atama);
        }
      }

      await _modelleriGetir();
      
      if (!mounted) return;
      context.showSuccessSnackBar('${widget.asamaDisplayName} durumu güncellendi.');
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  /// Kalite kontrol ataması oluştur
  Future<void> _kaliteKontrolAtamasiOlustur(Map<String, dynamic> atama, {int? tamamlananAdet}) async {
    try {
      // Model bilgilerini al
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, adet')
          .eq('id', atama['model_id'])
          .maybeSingle();

      if (modelResponse == null) {
        debugPrint('⚠️ Model bulunamadı: ${atama['model_id']}');
        return;
      }

      // Parametreden gelen adet varsa onu kullan, yoksa atamadan al
      final adet = tamamlananAdet ?? atama['tamamlanan_adet'] ?? atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

      // Her zaman yeni kayıt oluştur (duplicate kontrolü kaldırıldı)
      await supabase.from(DbTables.kaliteKontrolAtamalari).insert({
        'model_id': atama['model_id'],
        'durum': 'beklemede',
        'onceki_asama': widget.asamaDisplayName,
        'kontrol_edilecek_adet': adet,
        'atama_tarihi': DateTime.now().toIso8601String(),
        'notlar': '${widget.asamaDisplayName} tamamlandı - ${modelResponse['marka']} ${modelResponse['item_no']} - $adet adet [$uniqueId]',
        'firma_id': TenantManager.instance.requireFirmaId,
      });
      
      debugPrint('✅ Kalite kontrol ataması oluşturuldu: ${widget.asamaDisplayName} -> Kalite Kontrol');
      
      // Kalite kontrol rolüne sahip kullanıcılara bildirim gönder
      try {
        await BildirimService().roleGoreBildirimGonder(
          rol: 'kalite_kontrol',
          baslik: '🔍 Yeni Kalite Kontrol Talebi',
          mesaj: '${modelResponse['marka']} ${modelResponse['item_no']} - ${widget.asamaDisplayName} aşaması tamamlandı. $adet adet kalite kontrolü bekliyor.',
          tip: 'kalite_kontrol_bekliyor',
          modelId: atama['model_id']?.toString(),
          asama: widget.asamaDisplayName,
        );
        debugPrint('✅ Kalite kontrol bildirim gönderildi');
      } catch (e) {
        debugPrint('⚠️ Bildirim gönderilemedi: $e');
      }
    } catch (e) {
      debugPrint('❌ Kalite kontrol ataması oluşturulamadı: $e');
    }
  }

  /// Yıkama veya Kalite Kontrol tamamlandığında direkt sevkiyat ataması oluştur
  Future<void> _sevkiyatAtamasiOlustur(Map<String, dynamic> atama, {int? tamamlananAdet}) async {
    try {
      // Model bilgilerini al
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, adet')
          .eq('id', atama['model_id'])
          .maybeSingle();

      if (modelResponse == null) {
        debugPrint('⚠️ Model bulunamadı: ${atama['model_id']}');
        return;
      }

      // Parametre olarak gelen adet varsa onu kullan, yoksa atamadan al
      final adet = tamamlananAdet ?? atama['tamamlanan_adet'] ?? atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? modelResponse['adet'] ?? 0;
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final oncekiAsama = atama['onceki_asama'] ?? widget.asamaDisplayName;
      
      debugPrint('📦 Sevkiyat ataması oluşturuluyor - Adet: $adet - Önceki Aşama: $oncekiAsama');

      // 1. Paketleme ataması oluştur
      try {
        await supabase.from(DbTables.paketlemeAtamalari).insert({
          'model_id': atama['model_id'],
          'durum': 'atandi',
          'adet': adet,
          'talep_edilen_adet': adet,
          'tamamlanan_adet': 0,
          'atama_tarihi': DateTime.now().toIso8601String(),
          'notlar': '$oncekiAsama tamamlandı - ${modelResponse['marka']} ${modelResponse['item_no']} - $adet adet [$uniqueId]',
          'firma_id': TenantManager.instance.requireFirmaId,
        });
        debugPrint('✅ Paketleme ataması oluşturuldu - $adet adet');
      } catch (e) {
        debugPrint('⚠️ Paketleme ataması oluşturulamadı: $e');
      }

      // 2. Sevkiyat kaydı oluştur
      try {
        await supabase.from(DbTables.sevkiyatKayitlari).insert({
          'model_id': atama['model_id'],
          'alinan_adet': adet,
          'sevk_edilen_adet': 0,
          'kalan_adet': adet,
          'durum': 'beklemede',
          'alis_tarihi': DateTime.now().toIso8601String(),
          'notlar': '$oncekiAsama tamamlandı - ${modelResponse['marka']} ${modelResponse['item_no']} [$uniqueId]',
          'firma_id': TenantManager.instance.requireFirmaId,
        });
        debugPrint('✅ Sevkiyat kaydı oluşturuldu - $adet adet');
      } catch (e) {
        debugPrint('⚠️ Sevkiyat kaydı oluşturulamadı: $e');
      }
      
      // 3. Sevkiyat rolüne sahip kullanıcılara bildirim gönder
      try {
        await BildirimService().roleGoreBildirimGonder(
          rol: 'sevkiyat',
          baslik: '📦 Yeni Sevkiyat Talebi',
          mesaj: '${modelResponse['marka']} ${modelResponse['item_no']} - $oncekiAsama tamamlandı. $adet adet sevkiyat bekliyor.',
          tip: 'sevkiyat_hazir',
          modelId: atama['model_id']?.toString(),
          asama: oncekiAsama,
        );
        debugPrint('✅ Sevkiyat bildirimi gönderildi');
      } catch (e) {
        debugPrint('⚠️ Bildirim gönderilemedi: $e');
      }
      
      debugPrint('✅ $oncekiAsama -> Sevkiyat ataması tamamlandı - $adet adet');
    } catch (e) {
      debugPrint('❌ Sevkiyat ataması oluşturulamadı: $e');
    }
  }

  Future<void> _reddet(Map<String, dynamic> atama) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Red Sebebi'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Red sebebini yazın...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _aksiyon(atama, 'reddedildi');
      // Red sebebini de güncelle
      await supabase
          .from(widget.atamaTablosu)
          .update({'red_sebebi': result})
          .eq('id', atama['id']);
    }
  }

  // Üretime Al Dialog'u
  void _showUretimeAlDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    DateTime planlananBitisTarihi = DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.asamaRengi.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_arrow, color: widget.asamaRengi),
                ),
                const SizedBox(width: 12),
                Text('${widget.asamaDisplayName} Başlat'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Renk: ${model['renk'] ?? '-'}'),
                        Text('Adet: ${atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? '-'}'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text('Planlanan Bitiş Tarihi', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: planlananBitisTarihi,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('tr', 'TR'),
                      );
                      if (picked != null) {
                        setDialogState(() => planlananBitisTarihi = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.asamaRengi.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                        color: widget.asamaRengi.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: widget.asamaRengi),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr').format(planlananBitisTarihi),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.asamaRengi,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit, color: widget.asamaRengi.withValues(alpha: 0.6), size: 20),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickDateChip('1 Hafta', 7, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('2 Hafta', 14, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('1 Ay', 30, planlananBitisTarihi, (days) {
                        setDialogState(() => planlananBitisTarihi = DateTime.now().add(Duration(days: days)));
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await supabase
                        .from(widget.atamaTablosu)
                        .update({
                          'durum': 'uretimde',
                          'uretim_baslangic_tarihi': DateTime.now().toIso8601String(),
                          'planlanan_bitis_tarihi': planlananBitisTarihi.toIso8601String(),
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', atama['id']);
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _modelleriGetir();
                    
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ ${model['marka']} - ${model['item_no']} ${widget.asamaDisplayName} üretimine alındı'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    context.showErrorSnackBar('Hata: $e');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Üretime Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.asamaRengi,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int days, DateTime currentDate, Function(int) onSelect) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected = currentDate.difference(targetDate).inDays.abs() < 1;
    
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? widget.asamaRengi.withValues(alpha: 0.2) : Colors.grey.shade200,
      side: BorderSide(color: isSelected ? widget.asamaRengi : Colors.grey.shade400),
      onPressed: () => onSelect(days),
    );
  }

  // Tamamla Dialog'u - BEDEN BAZLI
  void _showTamamlaDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final modelId = model['id']?.toString() ?? atama['model_id']?.toString() ?? '';
    final atamaId = atama['id'] as int;
    
    // Beden bazlı dialog'u aç
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BedenUretimTamamlaDialogGeneric(
        modelId: modelId,
        modelAdi: '${model['marka']} - ${model['item_no']}',
        atamaId: atamaId,
        atama: atama,
        model: model,
        supabase: supabase,
        asamaAdi: widget.asamaAdi,
        asamaDisplayName: widget.asamaDisplayName,
        atamaTablosu: widget.atamaTablosu,
        asamaRengi: widget.asamaRengi,
        onComplete: () {
          _modelleriGetir();
        },
        onKaliteKontrolOlustur: (a, {required int tamamlananAdet}) => _kaliteKontrolAtamasiOlustur(a, tamamlananAdet: tamamlananAdet),
        onSevkiyatOlustur: (a, {required int tamamlananAdet}) => _sevkiyatAtamasiOlustur(a, tamamlananAdet: tamamlananAdet),
      ),
    );
  }

  // Eski toplam adet bazlı dialog - artık kullanılmıyor, yedek olarak duruyor

  Widget _buildModelBilgisi(String label, String? value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: textColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(String? durum) {
    Color color;
    String text;
    
    switch (durum) {
      case 'atandi':
        color = Colors.orange;
        text = 'Onay Bekliyor';
        break;
      case 'onaylandi':
        color = Colors.green;
        text = 'Onaylandı';
        break;
      case 'reddedildi':
        color = Colors.red;
        text = 'Reddedildi';
        break;
      case 'uretimde':
        color = Colors.blue;
        text = 'İşlemde';
        break;
      case 'tamamlandi':
        color = Colors.purple;
        text = 'Tamamlandı';
        break;
      default:
        color = Colors.grey;
        text = 'Bekliyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModelListesi(List<Map<String, dynamic>> modeller, String bosListeMetni) {
    if (yukleniyor) {
      return const LoadingWidget();
    }

    if (modeller.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.asamaIconu,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                bosListeMetni,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _modelleriGetir,
      child: ListView.builder(
        itemCount: modeller.length,
        itemBuilder: (context, index) => _buildModelKarti(modeller[index]),
      ),
    );
  }

}
