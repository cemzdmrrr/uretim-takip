// ignore_for_file: invalid_use_of_protected_member
part of 'kalite_kontrol_panel.dart';

/// Kalite kontrol panel - widget builder ve dialog metotlari
extension _WidgetDialogExt on _KaliteKontrolPanelState {
  Widget _buildKontrolListesi(List<Map<String, dynamic>> kontroller, String tip) {
    if (kontroller.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tip == 'bekleyen' ? Icons.pending_actions :
              tip == 'kontrolde' ? Icons.search : Icons.check_circle,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              tip == 'bekleyen' ? 'Bekleyen kalite kontrol yok' :
              tip == 'kontrolde' ? 'Kontrol edilen iş yok' : 'Tamamlanan iş yok',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: kontroller.length,
        itemBuilder: (context, index) => _buildKontrolKarti(kontroller[index], tip),
      ),
    );
  }

  Widget _buildKontrolKarti(Map<String, dynamic> kontrol, String tip) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final durum = kontrol['durum'] as String?;
    final oncekiAsama = kontrol['onceki_asama'] as String? ?? 'Bilinmiyor';
    final kontrolAdet = kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve durum badge
            Row(
              children: [
                // Aşama ikonu
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAsamaRengi(oncekiAsama).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAsamaIkonu(oncekiAsama),
                    color: _getAsamaRengi(oncekiAsama),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        oncekiAsama,
                        style: TextStyle(color: _getAsamaRengi(oncekiAsama), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Adet göstergesi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$kontrolAdet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'adet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDurumBadge(durum),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Model bilgileri
            _buildBilgiSatiri('Renk', model['renk'] ?? '-'),
            _buildBilgiSatiri('Kontrol Edilecek', '${kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? '-'} adet', isBold: true),
            FutureBuilder<int>(
              future: _getModelToplamAdet(model['id']),
              builder: (context, snapshot) {
                final toplamAdet = snapshot.data ?? model['adet'] ?? 0;
                return _buildBilgiSatiri('Model Toplam Adet', toplamAdet > 0 ? '$toplamAdet' : '-');
              },
            ),
            
            if (model['termin_tarihi'] != null)
              _buildBilgiSatiri(
                'Termin',
                DateFormat('dd.MM.yyyy').format(DateTime.parse(model['termin_tarihi'])),
                textColor: Colors.orange,
              ),

            if (kontrol['atama_tarihi'] != null)
              _buildBilgiSatiri(
                'Kontrol Talebi',
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(kontrol['atama_tarihi'])),
              ),

            if (kontrol['red_sebebi'] != null && kontrol['red_sebebi'].toString().isNotEmpty)
              _buildBilgiSatiri('Red Sebebi', kontrol['red_sebebi'], textColor: Colors.red),

            if (kontrol['notlar'] != null && kontrol['notlar'].toString().isNotEmpty)
              _buildBilgiSatiri('Notlar', kontrol['notlar']),

            // Aksiyon butonları
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildAksiyonButonlari(kontrol, tip),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiSatiri(String label, String? value, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: isBold || textColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(String? durum) {
    Color renk;
    String metin;
    
    switch (durum) {
      case 'beklemede':
      case 'atandi':
      case 'kontrol_bekliyor':
        renk = Colors.orange;
        metin = 'Bekliyor';
        break;
      case 'kontrolde':
        renk = Colors.blue;
        metin = 'Kontrol Ediliyor';
        break;
      case 'onaylandi':
      case 'kalite_onay':
      case 'tamamlandi':
        renk = Colors.green;
        metin = 'Onaylandı';
        break;
      case 'reddedildi':
      case 'kalite_red':
        renk = Colors.red;
        metin = 'Reddedildi';
        break;
      default:
        renk = Colors.grey;
        metin = durum ?? 'Bilinmiyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        metin,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAksiyonButonlari(Map<String, dynamic> kontrol, String tip) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Detay butonu
        OutlinedButton.icon(
          onPressed: () => _showDetayDialog(kontrol),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Detay'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
        ),

        // Bekleyenler için aksiyonlar
        if (tip == 'bekleyen') ...[
          ElevatedButton.icon(
            onPressed: () => _kontrolBaslat(kontrol),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Kontrole Başla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],

        // Kontrol edilenler için aksiyonlar
        if (tip == 'kontrolde') ...[
          ElevatedButton.icon(
            onPressed: () => _showOnaylaDialog(kontrol),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showReddetDialog(kontrol),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Color _getAsamaRengi(String asama) {
    switch (asama) {
      case 'Dokuma': return Colors.brown;
      case 'Konfeksiyon': return Colors.purple;
      case 'Yıkama': return Colors.cyan;
      case 'Ütü': return Colors.orange;
      case 'İlik Düğme': return Colors.indigo;
      case 'Paketleme': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _getAsamaIkonu(String asama) {
    switch (asama) {
      case 'Dokuma': return Icons.grid_on;
      case 'Konfeksiyon': return Icons.checkroom;
      case 'Yıkama': return Icons.local_laundry_service;
      case 'Ütü': return Icons.iron;
      case 'İlik Düğme': return Icons.radio_button_checked;
      case 'Paketleme': return Icons.inventory_2;
      default: return Icons.help_outline;
    }
  }

  Future<void> _kontrolBaslat(Map<String, dynamic> kontrol) async {
    try {
      await supabase
          .from(DbTables.kaliteKontrolAtamalari)
          .update({
            'durum': 'baslandi',
            'baslangic_tarihi': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', kontrol['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kalite kontrolü başlatıldı'),
          backgroundColor: Colors.blue,
        ),
      );

      await _verileriYukle();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  void _showOnaylaDialog(Map<String, dynamic> kontrol) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final notlarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Kalite Kontrolü Onayla'),
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
                    Text('${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
                    Text('Kontrol Edilen: ${kontrol['kontrol_edilecek_adet'] ?? model['adet']} adet'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(
                  labelText: 'Kalite Kontrol Notları (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Onay sonrası ürünler bir sonraki aşamaya geçebilir.',
                        style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
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
                // Kalite kontrolünü tamamla
                await supabase
                    .from(DbTables.kaliteKontrolAtamalari)
                    .update({
                      'durum': 'tamamlandi',
                      'tamamlanma_tarihi': DateTime.now().toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                      'notlar': notlarController.text.isNotEmpty ? notlarController.text : null,
                    })
                    .eq('id', kontrol['id']);

                // Sevkiyat kaydı oluştur
                final kontrolAdet = kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? 0;
                debugPrint('📦 Kalite kontrol onaylandı - $kontrolAdet adet sevkiyata gönderilecek');
                
                // 1. paketleme_atamalari tablosuna YENİ KAYIT ekle (her zaman insert)
                try {
                  await supabase.from(DbTables.paketlemeAtamalari).insert({
                    'model_id': kontrol['model_id'],
                    'durum': 'atandi',
                    'adet': kontrolAdet,
                    'talep_edilen_adet': kontrolAdet,
                    'tamamlanan_adet': 0,
                    'atama_tarihi': DateTime.now().toIso8601String(),
                    'notlar': 'Kalite kontrol onaylandı - ${model['marka']} ${model['item_no']} - $kontrolAdet adet sevkiyata hazır',
                    'firma_id': TenantManager.instance.requireFirmaId,
                  });
                  debugPrint('✅ Paketleme ataması oluşturuldu (yeni kayıt)');
                } catch (e) {
                  debugPrint('❌ Paketleme ataması hatası: $e');
                }

                // 2. sevkiyat_kayitlari tablosuna YENİ KAYIT ekle (her zaman insert)
                try {
                  await supabase.from(DbTables.sevkiyatKayitlari).insert({
                    'model_id': kontrol['model_id'],
                    'kalite_kontrol_id': kontrol['id'],
                    'alinan_adet': kontrolAdet,
                    'sevk_edilen_adet': 0,
                    'kalan_adet': kontrolAdet,
                    'durum': 'beklemede',
                    'alis_tarihi': DateTime.now().toIso8601String(),
                    'notlar': 'Kalite kontrol onaylandı - ${model['marka']} ${model['item_no']}',
                    'firma_id': TenantManager.instance.requireFirmaId,
                  });
                  debugPrint('✅ Sevkiyat kaydı oluşturuldu (yeni kayıt)');
                } catch (e) {
                  debugPrint('⚠️ sevkiyat_kayitlari tablosu henüz oluşturulmamış olabilir: $e');
                }
                    
                // 3. Sevkiyat rolüne sahip kullanıcılara bildirim gönder
                try {
                  await BildirimService().roleGoreBildirimGonder(
                    rol: 'sevkiyat',
                    baslik: '📦 Yeni Sevkiyat Talebi',
                    mesaj: '${model['marka']} ${model['item_no']} - $kontrolAdet adet kalite kontrolden geçti. Sevkiyat bekliyor.',
                    tip: 'sevkiyat_hazir',
                    modelId: kontrol['model_id']?.toString(),
                    asama: 'Kalite Kontrol',
                  );
                  debugPrint('✅ Sevkiyat bildirimi gönderildi');
                } catch (e) {
                  debugPrint('⚠️ Bildirim gönderilemedi: $e');
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showSuccessSnackBar('✅ Kalite kontrolü onaylandı - Sevkiyata gönderildi');
                await _verileriYukle();
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showReddetDialog(Map<String, dynamic> kontrol) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final sebebController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Kalite Kontrolü Reddet'),
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
                    Text('${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sebebController,
                decoration: const InputDecoration(
                  labelText: 'Red Sebebi *',
                  border: OutlineInputBorder(),
                  hintText: 'Kalite problemini açıklayın...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Red edilen ürünler tekrar işleme alınacaktır.',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
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
              if (sebebController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Red sebebi zorunludur'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await supabase
                    .from(DbTables.kaliteKontrolAtamalari)
                    .update({
                      'durum': 'reddedildi',
                      'red_sebebi': sebebController.text.trim(),
                    })
                    .eq('id', kontrol['id']);

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showErrorSnackBar('❌ Kalite kontrolü reddedildi');
                await _verileriYukle();
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetayDialog(Map<String, dynamic> kontrol) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.teal.shade600),
            const SizedBox(width: 12),
            const Text('Kalite Kontrol Detayı'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Model Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDetaySatiri('Marka', model['marka']),
                    _buildDetaySatiri('Item No', model['item_no']),
                    _buildDetaySatiri('Renk', model['renk']),
                    _buildDetaySatiri('Toplam Adet', model['adet']?.toString()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Kontrol bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kontrol Bilgileri', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDetaySatiri('Önceki Aşama', kontrol['onceki_asama']),
                    _buildDetaySatiri('Durum', kontrol['durum']),
                    _buildDetaySatiri('Kontrol Edilecek', '${kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? '-'} adet'),
                    if (kontrol['atama_tarihi'] != null)
                      _buildDetaySatiri('Talep Tarihi', 
                        DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(kontrol['atama_tarihi']))),
                  ],
                ),
              ),
              if (kontrol['notlar'] != null && kontrol['notlar'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notlar', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(kontrol['notlar']),
                    ],
                  ),
                ),
              ],
              if (kontrol['red_sebebi'] != null && kontrol['red_sebebi'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Red Sebebi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      const SizedBox(height: 4),
                      Text(kontrol['red_sebebi'], style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ],
            ],
          ),
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

  Widget _buildDetaySatiri(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showAramaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ara'),
        content: TextField(
          controller: _aramaController,
          decoration: const InputDecoration(
            hintText: 'Marka, model veya renk...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() => aramaMetni = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                aramaMetni = '';
                _aramaController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showFiltreDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtrele'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Önceki Aşama:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: seciliAsama == null,
                      onSelected: (selected) {
                        setDialogState(() => seciliAsama = null);
                        setState(() {});
                      },
                    ),
                    ...asamalar.map((asama) => ChoiceChip(
                      label: Text(asama),
                      selected: seciliAsama == asama,
                      selectedColor: _getAsamaRengi(asama).withValues(alpha: 0.3),
                      onSelected: (selected) {
                        setDialogState(() => seciliAsama = selected ? asama : null);
                        setState(() {});
                      },
                    )),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => seciliAsama = null);
                  Navigator.pop(context);
                },
                child: const Text('Temizle'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      ),
    );
  }
}
