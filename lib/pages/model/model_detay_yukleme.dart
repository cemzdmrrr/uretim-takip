part of 'model_detay.dart';

/// Yükleme (Shipping/Files) tab extension for _ModelDetayState.
extension _YuklemeTabExt on _ModelDetayState {
  // ==================== YÜKLEME SEKMESİ ====================
  Widget _buildYuklemeTab() {
    return Column(
      children: [
        // Üst kısım - Yükleme ekle ve dosya yükle butonları
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showYuklemeKaydiEkleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Yükleme Kaydı Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _dosyaYukle,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Dosya Yükle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Sekmeler: Yükleme Kayıtları ve Teknik Dosyalar
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.teal,
                  tabs: [
                    Tab(text: 'Yükleme Kayıtları'),
                    Tab(text: 'Teknik Dosyalar'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildYuklemeKayitlariList(),
                      _buildTeknikDosyalarList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYuklemeKayitlariList() {
    if (yuklemeKayitlari.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz yükleme kaydı yok', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    int toplamYuklenen = 0;
    for (var kayit in yuklemeKayitlari) {
      toplamYuklenen += (kayit['adet'] ?? 0) as int;
    }
    
    return Column(
      children: [
        // Özet
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Toplam Adet', style: TextStyle(color: Colors.grey)),
                  Text('${currentModelData?['toplam_adet'] ?? 0}', 
                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  const Text('Yüklenen', style: TextStyle(color: Colors.grey)),
                  Text('$toplamYuklenen', 
                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              Column(
                children: [
                  const Text('Kalan', style: TextStyle(color: Colors.grey)),
                  Text('${(currentModelData?['toplam_adet'] ?? 0) - toplamYuklenen}', 
                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ],
          ),
        ),
        
        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: yuklemeKayitlari.length,
            itemBuilder: (context, index) {
              final kayit = yuklemeKayitlari[index];
              DateTime? tarih;
              try {
                tarih = DateTime.parse(kayit['tarih']);
              } catch (e) {
                // Tarih parse hatası
              }
              
              final kaynak = kayit['kaynak'] ?? 'manual';
              final cekidenMi = kaynak == DbTables.cekiListesi;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: cekidenMi ? Colors.blue[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cekidenMi ? Colors.blue : Colors.teal,
                    child: Text('${kayit['adet']}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Row(
                    children: [
                      Text('${kayit['adet']} adet yüklendi'),
                      const SizedBox(width: 8),
                      if (cekidenMi)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_shipping, size: 12, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text('Çekiden', style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  subtitle: tarih != null
                      ? Text(DateFormat('dd.MM.yyyy HH:mm').format(tarih))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteYuklemeKaydi(kayit['id']),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeknikDosyalarList() {
    if (teknikDosyalar.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz teknik dosya yok', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teknikDosyalar.length,
      itemBuilder: (context, index) {
        final dosya = teknikDosyalar[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              utils.getDosyaIcon(dosya['dosya_tipi']),
              color: utils.getDosyaColor(dosya['dosya_tipi']),
              size: 32,
            ),
            title: Text(dosya['dosya_adi'] ?? 'Dosya'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dosya['dosya_tipi'] ?? 'Bilinmeyen'),
                if (dosya['aciklama'] != null)
                  Text(dosya['aciklama'], style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dosya['dosya_url'] != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.blue),
                    onPressed: () => _openDosya(dosya['dosya_url']),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteTeknikDosya(dosya['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showYuklemeKaydiEkleDialog() {
    final adetController = TextEditingController();
    DateTime secilenTarih = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yükleme Kaydı Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: adetController,
                decoration: const InputDecoration(
                  labelText: 'Yüklenen Adet',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd.MM.yyyy').format(secilenTarih)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: secilenTarih,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => secilenTarih = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => _addYuklemeKaydi(
                int.tryParse(adetController.text) ?? 0,
                secilenTarih,
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addYuklemeKaydi(int adet, DateTime tarih) async {
    if (adet <= 0) {
      context.showErrorSnackBar('Geçerli bir adet giriniz');
      return;
    }
    
    try {
      await supabase.from(DbTables.yuklemeKayitlari).insert({
        'model_id': widget.modelId,
        'adet': adet,
        'tarih': tarih.toIso8601String(),
        'kaynak': 'manual',
      });
      
      // Gelişmiş raporlar için hesaplamaları tetikle
      await _guncelleGelismisRaporlar();
      
      if (!mounted) return;
      Navigator.pop(context);
      await _yuklemeKayitlariniGetir();
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Yükleme kaydı eklendi - Raporlar güncellendi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  Future<void> _deleteYuklemeKaydi(String id) async {
    try {
      await supabase.from(DbTables.yuklemeKayitlari).delete().eq('id', id);
      await _yuklemeKayitlariniGetir();
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Kayıt silindi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  Future<void> _dosyaYukle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      String? dosyaTipi;
      
      // Dosya tipi seçimi dialog'u
      if (!mounted) return;
      dosyaTipi = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Dosya Türü Seçin'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'teknik_cizim'),
              child: const Text('Teknik Çizim'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'olcu_tablosu'),
              child: const Text('Ölçü Tablosu'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'renk_karti'),
              child: const Text('Renk Kartı'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'diger'),
              child: const Text('Diğer'),
            ),
          ],
        ),
      );
      
      if (dosyaTipi == null) return;
      
      try {
        final file = result.files.first;
        final fileBytes = file.bytes!;
        final fileName = file.name;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'teknik_dosyalar/${widget.modelId}/${timestamp}_$fileName';
        
        // Storage'a yükle
        await supabase.storage.from(DbTables.dosyalar).uploadBinary(storagePath, fileBytes);
        
        // URL al
        final url = supabase.storage.from(DbTables.dosyalar).getPublicUrl(storagePath);
        
        // Veritabanına kaydet
        await supabase.from(DbTables.teknikDosyalar).insert({
          'model_id': widget.modelId,
          'dosya_adi': fileName,
          'dosya_tipi': dosyaTipi,
          'dosya_url': url,
          'dosya_boyutu': file.size,
        });
        
        await _teknikDosyalariGetir();
        
        if (!mounted) return;
        context.showSuccessSnackBar('✅ Dosya yüklendi');
      } catch (e) {
        if (!mounted) return;
        context.showErrorSnackBar('❌ Hata: $e');
      }
    }
  }

  Future<void> _openDosya(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Dosya açılamadı: $e');
    }
  }

  Future<void> _deleteTeknikDosya(String id) async {
    try {
      await supabase.from(DbTables.teknikDosyalar).delete().eq('id', id);
      await _teknikDosyalariGetir();
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Dosya silindi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  // Gelişmiş raporlar için model hesaplamalarını güncelle
  Future<void> _guncelleGelismisRaporlar() async {
    try {
      // Yükleme kayıtlarını topla
      final yukleme = await supabase
          .from(DbTables.yuklemeKayitlari)
          .select('adet')
          .eq('model_id', widget.modelId);
      
      int toplamYuklenen = 0;
      for (var kayit in yukleme) {
        toplamYuklenen += (kayit['adet'] as num?)?.toInt() ?? 0;
      }

      // Model verilerini güncelle (cache için)
      if (currentModelData != null) {
        final modelAdet = (currentModelData!['toplam_adet'] ?? currentModelData!['adet'] ?? 0) as num;
        final kalanAdet = modelAdet.toInt() - toplamYuklenen;
        
        // triko_takip tablosunu güncelle
        await supabase.from(DbTables.trikoTakip).update({
          'yuklenen_adet': toplamYuklenen,
          'kalan_adet': kalanAdet > 0 ? kalanAdet : 0,
        }).eq('id', widget.modelId);
        
        debugPrint('📊 Model raporları güncellendi - Yüklenen: $toplamYuklenen, Kalan: $kalanAdet');
      }
    } catch (e) {
      debugPrint('⚠️ Rapor güncelleme hatası: $e');
      // Hata olsa da devam et
    }
  }
}
