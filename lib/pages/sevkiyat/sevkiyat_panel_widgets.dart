// ignore_for_file: invalid_use_of_protected_member
part of 'sevkiyat_panel.dart';

/// Sevkiyat panel - widget builders, dialoglar ve aksiyonlar
extension _WidgetsExt on _SevkiyatPanelState {
  Widget _buildSevkListesi(List<Map<String, dynamic>> liste, String tip) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tip == 'bekleyen' ? Icons.inbox : 
              tip == 'devam' ? Icons.local_shipping : Icons.check_circle,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              tip == 'bekleyen' ? 'Sevk bekleyen ürün yok' :
              tip == 'devam' ? 'Sevk edilen ürün yok' : 'Tamamlanan sevk yok',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (context, index) => _buildSevkCard(liste[index], tip),
      ),
    );
  }

  Widget _buildSevkCard(Map<String, dynamic> sevk, String tip) {
    final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = sevk['durum'] as String?;
    final adet = sevk['adet'] ?? sevk['talep_edilen_adet'] ?? model['adet'] ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2, color: Colors.indigo.shade600, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${model['marka'] ?? 'Bilinmiyor'} - ${model['item_no'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Kalite Kontrolden Geldi',
                        style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _buildDurumBadge(durum),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Bilgiler
            _buildBilgiSatiri('Renk', model['renk']),
            _buildBilgiSatiri('Sevk Edilecek Adet', '$adet adet', isBold: true),
            
            if (model['termin_tarihi'] != null)
              _buildBilgiSatiri(
                'Termin',
                DateFormat('dd.MM.yyyy').format(DateTime.parse(model['termin_tarihi'])),
                textColor: Colors.orange,
              ),

            if (sevk['atama_tarihi'] != null)
              _buildBilgiSatiri(
                'Sevk Talebi',
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(sevk['atama_tarihi'])),
              ),

            if (sevk['hedef_asama'] != null)
              _buildBilgiSatiri('Hedef Aşama', sevk['hedef_asama'], textColor: Colors.blue),

            if (sevk['notlar'] != null && sevk['notlar'].toString().isNotEmpty)
              _buildBilgiSatiri('Notlar', sevk['notlar']),

            // Aksiyon butonları
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildAksiyonButonlari(sevk, tip),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiSatiri(String label, String? value, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                color: textColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(String? durum) {
    Color renk;
    String text;
    
    switch (durum) {
      case 'atandi':
      case 'beklemede':
        renk = Colors.orange;
        text = 'Sevk Bekliyor';
        break;
      case 'baslandi':
      case 'sevk_ediliyor':
        renk = Colors.blue;
        text = 'Sevk Ediliyor';
        break;
      case 'tamamlandi':
      case 'sevk_edildi':
        renk = Colors.green;
        text = 'Tamamlandı';
        break;
      default:
        renk = Colors.grey;
        text = durum ?? 'Bilinmiyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildAksiyonButonlari(Map<String, dynamic> sevk, String tip) {
    if (tip == 'bekleyen') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDetayDialog(sevk),
              icon: const Icon(Icons.info_outline),
              label: const Text('Detay'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _showSevkDialog(sevk),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Sevk Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (tip == 'devam') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDetayDialog(sevk),
              icon: const Icon(Icons.info_outline),
              label: const Text('Detay'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _sevkTamamla(sevk),
              icon: const Icon(Icons.check),
              label: const Text('Tamamla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _showDetayDialog(sevk),
        icon: const Icon(Icons.info_outline),
        label: const Text('Detay Görüntüle'),
      );
    }
  }

  void _showAramaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ara'),
        content: TextField(
          controller: _aramaController,
          decoration: const InputDecoration(
            hintText: 'Marka, model veya renk ara...',
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
              _aramaController.clear();
              setState(() => aramaMetni = '');
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ara'),
          ),
        ],
      ),
    );
  }

  void _showSevkDialog(Map<String, dynamic> sevk) {
    final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final mevcutAdet = sevk['adet'] ?? sevk['talep_edilen_adet'] ?? model['adet'] ?? 0;
    final adetController = TextEditingController(text: mevcutAdet.toString());
    final notlarController = TextEditingController();
    String? secilenHedefAsama;
    Map<String, dynamic>? secilenTedarikci;
    List<Map<String, dynamic>> tedarikciler = [];
    bool tedarikcilerYukleniyor = false;

    // Dış atölye gerektiren aşamalar (firma seçimi gerektirenler)
    final disAtolyeAsamalar = ['yikama', 'nakis', 'konfeksiyon', 'dokuma', 'utu', 'ilik_dugme'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              const Text('Sevk Et'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Model bilgisi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (model['renk'] != null)
                        Text('Renk: ${model['renk']}'),
                      Text('Mevcut Adet: $mevcutAdet'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sevk adeti
                TextField(
                  controller: adetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sevk Edilecek Adet',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                    helperText: 'Maksimum: $mevcutAdet adet',
                  ),
                ),
                const SizedBox(height: 16),

                // Hedef aşama seçimi
                const Text(
                  'Hedef Aşama Seçin:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hedefAsamalar.map((asama) {
                    final isSelected = secilenHedefAsama == asama['key'];
                    return InkWell(
                      onTap: () async {
                        setDialogState(() {
                          secilenHedefAsama = asama['key'];
                          secilenTedarikci = null;
                          tedarikciler = [];
                        });
                        
                        // Dış atölye aşaması ise tedarikcileri yükle
                        if (disAtolyeAsamalar.contains(asama['key'])) {
                          setDialogState(() => tedarikcilerYukleniyor = true);
                          try {
                            // Faaliyet değerini belirle - birden fazla varyasyonu ara
                            if (asama['key'] == 'yikama') {
                            } else if (asama['key'] == 'nakis') {
                            }
                            
                            // Tüm tedarikcileri çek ve faaliyet içerenleri filtrele
                            final response = await supabase
                                .from(DbTables.tedarikciler)
                                .select('id, sirket, faaliyet');
                            
                            final tumTedarikciler = List<Map<String, dynamic>>.from(response);
                            
                            // Faaliyet alanında arama yap (case-insensitive)
                            final filtrelenmis = tumTedarikciler.where((t) {
                              final faaliyet = (t['faaliyet'] ?? '').toString().toLowerCase();
                              final asamaKey = asama['key'];
                              if (asamaKey == 'yikama') {
                                return faaliyet.contains('yikama') || faaliyet.contains('yıkama');
                              } else if (asamaKey == 'nakis') {
                                return faaliyet.contains('nakis') || faaliyet.contains('nakış');
                              } else if (asamaKey == 'konfeksiyon') {
                                return faaliyet.contains('konfeksiyon') || faaliyet.contains('dikim');
                              } else if (asamaKey == 'dokuma') {
                                return faaliyet.contains('dokuma') || faaliyet.contains('orgu') || faaliyet.contains('örgü');
                              } else if (asamaKey == 'utu') {
                                return faaliyet.contains('utu') || faaliyet.contains('ütü');
                              } else if (asamaKey == 'ilik_dugme') {
                                return faaliyet.contains('ilik') || faaliyet.contains('dugme') || faaliyet.contains('düğme');
                              }
                              return false;
                            }).toList();
                            
                            setDialogState(() {
                              tedarikciler = filtrelenmis;
                              tedarikcilerYukleniyor = false;
                            });
                            debugPrint('📦 ${asama['key']} tedarikcileri: ${tedarikciler.length} (toplam: ${tumTedarikciler.length})');
                            
                            // Debug: Tüm faaliyetleri listele
                            for (var t in tumTedarikciler) {
                              debugPrint('   - ${t['sirket']}: ${t['faaliyet']}');
                            }
                          } catch (e) {
                            debugPrint('❌ Tedarikci yükleme hatası: $e');
                            setDialogState(() => tedarikcilerYukleniyor = false);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? (asama['color'] as Color) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? (asama['color'] as Color) : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              asama['icon'] as IconData,
                              color: isSelected ? Colors.white : (asama['color'] as Color),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              asama['name'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Dış atölye seçilmişse tedarikci seçimi göster
                if (secilenHedefAsama != null && disAtolyeAsamalar.contains(secilenHedefAsama)) ...[
                  const Text(
                    'Tedarikci/Firma Seçin:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (tedarikcilerYukleniyor)
                    const LoadingWidget()
                  else if (tedarikciler.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu aşama için kayıtlı tedarikci bulunamadı.',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: tedarikciler.map((tedarikci) {
                          final isSelected = secilenTedarikci?['id'] == tedarikci['id'];
                          return InkWell(
                            onTap: () {
                              setDialogState(() => secilenTedarikci = tedarikci);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.indigo.shade50 : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? Colors.indigo : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tedarikci['sirket'] ?? 'Bilinmiyor',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // Notlar
                TextField(
                  controller: notlarController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (İsteğe Bağlı)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
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
              onPressed: secilenHedefAsama == null ? null : () async {
                final sevkAdet = int.tryParse(adetController.text) ?? 0;
                
                if (sevkAdet <= 0) {
                  context.showErrorSnackBar('Geçerli bir adet giriniz');
                  return;
                }
                
                if (sevkAdet > mevcutAdet) {
                  context.showErrorSnackBar('Sevk adeti mevcut adetten ($mevcutAdet) fazla olamaz');
                  return;
                }

                // Dış atölye için tedarikci kontrolü
                if (disAtolyeAsamalar.contains(secilenHedefAsama) && secilenTedarikci == null) {
                  context.showErrorSnackBar('Lütfen bir tedarikci/firma seçin');
                  return;
                }

                await _sevkYap(
                  sevk: sevk,
                  hedefAsama: secilenHedefAsama!,
                  adet: sevkAdet,
                  notlar: notlarController.text,
                  tedarikciId: secilenTedarikci?['id'],
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Sevk Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sevkYap({
    required Map<String, dynamic> sevk,
    required String hedefAsama,
    required int adet,
    String? notlar,
    int? tedarikciId,
  }) async {
    try {
      final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
      final hedefAsamaInfo = hedefAsamalar.firstWhere((a) => a['key'] == hedefAsama);
      final currentUser = supabase.auth.currentUser;
      
      // 1. Kaynak tabloyu belirle ve güncelle
      // Önce onceki_asama'ya bak, sonra kaynak_tablo'ya, en son default olarak sevkiyat_kayitlari
      final oncekiAsama = sevk['onceki_asama']?.toString().toLowerCase();
      String kaynakTablo;
      
      if (sevk['kaynak_tablo'] != null) {
        kaynakTablo = sevk['kaynak_tablo'];
      } else if (sevk['alinan_adet'] != null) {
        kaynakTablo = DbTables.sevkiyatKayitlari;
      } else if (oncekiAsama != null) {
        // Önceki aşamaya göre kaynak tabloyu belirle
        kaynakTablo = _getTabloAdi(oncekiAsama) ?? DbTables.sevkiyatKayitlari;
      } else {
        kaynakTablo = DbTables.sevkiyatKayitlari;
      }
      
      debugPrint('📦 Sevk işlemi - Kaynak tablo: $kaynakTablo, Önceki aşama: $oncekiAsama');
      
      if (kaynakTablo == DbTables.sevkiyatKayitlari) {
        // sevkiyat_kayitlari tablosunu güncelle
        final mevcutSevkEdilen = sevk['sevk_edilen_adet'] ?? 0;
        final alinanAdet = sevk['alinan_adet'] ?? 0;
        final yeniSevkEdilen = mevcutSevkEdilen + adet;
        final kalanAdet = alinanAdet - yeniSevkEdilen;
        final yeniDurum = kalanAdet <= 0 ? 'tamamlandi' : 'kismen_sevk';
        
        await supabase
            .from(DbTables.sevkiyatKayitlari)
            .update({
              'sevk_edilen_adet': yeniSevkEdilen,
              'kalan_adet': kalanAdet < 0 ? 0 : kalanAdet,
              'hedef_asama': hedefAsama,
              'hedef_tedarikci_id': tedarikciId,
              'sevkiyat_personeli_id': currentUser?.id,
              'durum': yeniDurum,
              'sevk_tarihi': DateTime.now().toIso8601String(),
              'tamamlanma_tarihi': yeniDurum == 'tamamlandi' ? DateTime.now().toIso8601String() : null,
              'updated_at': DateTime.now().toIso8601String(),
              'notlar': notlar != null && notlar.isNotEmpty
                  ? '${sevk['notlar'] ?? ''}\n[SEVK] $hedefAsama aşamasına $adet adet gönderildi. $notlar'
                  : '${sevk['notlar'] ?? ''}\n[SEVK] $hedefAsama aşamasına $adet adet gönderildi.',
            })
            .eq('id', sevk['id']);
        
        // 2. Sevkiyat detayı kaydet
        try {
          await supabase.from(DbTables.sevkiyatDetaylari).insert({
            'sevkiyat_id': sevk['id'],
            'sevk_adet': adet,
            'hedef_asama': hedefAsama,
            'hedef_tedarikci_id': tedarikciId,
            'sevk_eden_id': currentUser?.id,
            'sevk_tarihi': DateTime.now().toIso8601String(),
            'notlar': notlar,
          });
          debugPrint('✅ Sevkiyat detayı kaydedildi');
        } catch (e) {
          debugPrint('⚠️ Sevkiyat detayı kaydedilemedi: $e');
        }
        
        debugPrint('✅ sevkiyat_kayitlari güncellendi - Yeni durum: $yeniDurum');
      } else {
        // Kaynak tabloyu güncelle (yikama_atamalari, paketleme_atamalari vb.)
        debugPrint('📦 Kaynak tablo güncelleniyor: $kaynakTablo');
        await supabase
            .from(kaynakTablo)
            .update({
              'durum': 'sevk_ediliyor',
              'hedef_asama': hedefAsama,
              'updated_at': DateTime.now().toIso8601String(),
              'notlar': notlar != null && notlar.isNotEmpty
                  ? '${sevk['notlar'] ?? ''}\n[SEVK] $hedefAsama aşamasına $adet adet gönderildi. $notlar'
                  : '${sevk['notlar'] ?? ''}\n[SEVK] $hedefAsama aşamasına $adet adet gönderildi.',
            })
            .eq('id', sevk['id']);
        debugPrint('✅ $kaynakTablo güncellendi');
      }

      // 3. Hedef aşamaya atama yap
      final hedefTabloAdi = _getTabloAdi(hedefAsama);
      if (hedefTabloAdi != null) {
        // Atama verisi hazırla
        final atamaData = {
          'model_id': sevk['model_id'],
          'adet': adet,
          'talep_edilen_adet': adet,
          'tamamlanan_adet': 0,
          'durum': 'bekleyen', // ÖNEMLİ: Önce bekleyen durumunda gelsin, sonra onaylansın
          'atama_tarihi': DateTime.now().toIso8601String(),
          'notlar': 'Sevkiyattan geldi - ${model['marka']} ${model['item_no']} - $adet adet',
        };
        
        // Tedarikci ID varsa ekle (yıkama, nakış gibi dış atölyeler için)
        if (tedarikciId != null) {
          atamaData['tedarikci_id'] = tedarikciId;
        }

        // HER ZAMAN YENİ KAYIT EKLE (update yapma)
        await supabase.from(hedefTabloAdi).insert(atamaData);
        debugPrint('✅ $hedefTabloAdi tablosuna yeni atama oluşturuldu (tedarikci_id: $tedarikciId)');

        // 4. Hedef aşama personeline bildirim gönder
        try {
          await BildirimService().roleGoreBildirimGonder(
            rol: hedefAsama,
            baslik: '📦 Yeni Sevkiyat Geldi',
            mesaj: '${model['marka']} ${model['item_no']} - $adet adet sevkiyattan geldi. İşleme alınmayı bekliyor.',
            tip: 'sevkiyat_geldi',
            modelId: sevk['model_id']?.toString(),
            asama: 'Sevkiyat',
          );
          debugPrint('✅ $hedefAsama rolüne bildirim gönderildi');
        } catch (e) {
          debugPrint('⚠️ Bildirim gönderilemedi: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $adet adet ${hedefAsamaInfo['name']} aşamasına sevk edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _verileriYukle();

    } catch (e) {
      debugPrint('❌ Sevk hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  String? _getTabloAdi(String asama) {
    switch (asama) {
      case 'nakis':
        return DbTables.nakisAtamalari;
      case 'konfeksiyon':
        return DbTables.konfeksiyonAtamalari;
      case 'yikama':
        return DbTables.yikamaAtamalari;
      case 'utu':
        return DbTables.utuAtamalari;
      case 'ilik_dugme':
        return DbTables.ilikDugmeAtamalari;
      case 'paketleme':
        return DbTables.paketlemeAtamalari;
      default:
        return null;
    }
  }

  Future<void> _sevkTamamla(Map<String, dynamic> sevk) async {
    try {
      await supabase
          .from(DbTables.paketlemeAtamalari)
          .update({
            'durum': 'tamamlandi',
            'tamamlanma_tarihi': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sevk['id']);

      if (mounted) {
        context.showSuccessSnackBar('✅ Sevkiyat tamamlandı');
      }

      await _verileriYukle();

    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  void _showDetayDialog(Map<String, dynamic> sevk) {
    final model = sevk[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final modelId = sevk['model_id'] ?? model['id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${model['marka']} - ${model['item_no']}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetaySatiri('Marka', model['marka']),
                _buildDetaySatiri('Model No', model['item_no']),
                _buildDetaySatiri('Renk', model['renk']),
                _buildDetaySatiri('Adet', '${sevk['adet'] ?? model['adet']}'),
                _buildDetaySatiri('Durum', sevk['durum']),
                if (sevk['hedef_asama'] != null)
                  _buildDetaySatiri('Hedef Aşama', sevk['hedef_asama']),
                if (model['termin_tarihi'] != null)
                  _buildDetaySatiri('Termin', DateFormat('dd.MM.yyyy').format(DateTime.parse(model['termin_tarihi']))),
                if (sevk['atama_tarihi'] != null)
                  _buildDetaySatiri('Atama Tarihi', DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(sevk['atama_tarihi']))),
                if (sevk['notlar'] != null)
                  _buildDetaySatiri('Notlar', sevk['notlar']),
                
                // Üretim Aşamaları Bölümü
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.timeline, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Üretim Aşamaları',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (modelId != null)
                  _UretimAsamalariWidget(modelId: modelId.toString(), supabase: supabase)
                else
                  const Text('Model bilgisi bulunamadı', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetaySatiri(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }
}
