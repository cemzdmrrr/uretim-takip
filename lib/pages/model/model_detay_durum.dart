// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Model Durumu (Model Status) tab methods for _ModelDetayState.
extension _ModelDurumuTabExt on _ModelDetayState {
  // ==================== MODEL DURUMU SEKMESİ ====================
  Widget _buildModelDurumuTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // First Fit
          _buildDurumKarti(
            'First Fit',
            Icons.person_outline,
            Colors.blue,
            currentModelData?['first_fit_gonderildi'],
            currentModelData?['first_fit_aciklama'],
            'first_fit_gonderildi',
            'first_fit_aciklama',
          ),
          
          const SizedBox(height: 12),
          
          // Size Set
          _buildDurumKarti(
            'Size Set',
            Icons.straighten,
            Colors.purple,
            currentModelData?['size_set_gonderildi'],
            currentModelData?['size_set_aciklama'],
            'size_set_gonderildi',
            'size_set_aciklama',
          ),
          
          const SizedBox(height: 12),
          
          // PPS Numunesi (PP Sample)
          _buildDurumKarti(
            'PP Numunesi',
            Icons.inventory_2,
            Colors.orange,
            currentModelData?['pps_numunesi_gonderildi'],
            currentModelData?['pps_numunesi_aciklama'],
            'pps_numunesi_gonderildi',
            'pps_numunesi_aciklama',
          ),
          
          const SizedBox(height: 12),
          
          // Kaşe Onayı
          _buildKaseOnayi(),
          
          const SizedBox(height: 12),
          
          // İplik Durumu
          _buildIplikDurumu(),
          
          const SizedBox(height: 12),
          
          // Örgüye Başlama Durumu
          _buildOrguBaslama(),
        ],
      ),
    );
  }

  Widget _buildDurumKarti(
    String baslik,
    IconData icon,
    Color color,
    String? durum,
    String? aciklama,
    String durumKey,
    String aciklamaKey,
  ) {
    final bool gonderildi = durum == 'evet';
    final bool gonderilmedi = durum == 'hayir';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    baslik,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gonderildi ? Colors.green : (gonderilmedi ? Colors.red : Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gonderildi ? 'Gönderildi' : (gonderilmedi ? 'Gönderilmedi' : 'Beklemede'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (aciklama != null && aciklama.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(aciklama)),
                  ],
                ),
              ),
            ],
            if (kullaniciRolu == 'admin') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateDurum(durumKey, 'evet', aciklamaKey),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text('Gönderildi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gonderildi ? Colors.white : Colors.green,
                        backgroundColor: gonderildi ? Colors.green : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateDurum(durumKey, 'hayir', aciklamaKey),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Gönderilmedi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gonderilmedi ? Colors.white : Colors.red,
                        backgroundColor: gonderilmedi ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: aciklama ?? '',
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () => _saveAciklama(aciklamaKey, aciklama),
                  ),
                ),
                onChanged: (value) {
                  currentModelData?[aciklamaKey] = value;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKaseOnayi() {
    // Veritabanında 'kase_onayi' sütunu var
    final bool onaylandi = currentModelData?['kase_onayi'] == true;
    DateTime? onayTarihi;
    try {
      // iplik_tarihi sütunu kaşe onay tarihi olarak kullanılabilir veya ayrı bir alan eklenebilir
      if (currentModelData?['updated_at'] != null && onaylandi) {
        onayTarihi = DateTime.parse(currentModelData!['updated_at']);
      }
    } catch (e) {
      // Tarih parse hatası
    }

    return Card(
      elevation: 2,
      color: onaylandi ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: onaylandi ? Colors.green : Colors.grey, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kaşe Onayı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: onaylandi ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    onaylandi ? 'Onaylandı' : 'Onay Bekleniyor',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (onayTarihi != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Onay Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(onayTarihi)}'),
                ],
              ),
            ],
            if (kullaniciRolu == 'admin') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateKaseOnay(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateKaseOnay(false),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Onayı Kaldır'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIplikDurumu() {
    final bool iplikGeldi = currentModelData?['iplik_geldi'] == true;
    DateTime? gelisTarihi;
    try {
      if (currentModelData?['iplik_gelis_tarihi'] != null) {
        gelisTarihi = DateTime.parse(currentModelData!['iplik_gelis_tarihi']);
      }
    } catch (e) {
      // Tarih parse hatası
    }

    return Card(
      elevation: 2,
      color: iplikGeldi ? Colors.teal[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.texture, color: iplikGeldi ? Colors.teal : Colors.grey, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'İplik Durumu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: iplikGeldi ? Colors.teal : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    iplikGeldi ? 'Geldi' : 'Bekleniyor',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (gelisTarihi != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Geliş Tarihi: ${DateFormat('dd.MM.yyyy').format(gelisTarihi)}'),
                ],
              ),
            ],
            if (kullaniciRolu == 'admin') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateIplikDurumu(true),
                      icon: const Icon(Icons.check),
                      label: const Text('İplik Geldi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateIplikDurumu(false),
                      icon: const Icon(Icons.hourglass_empty),
                      label: const Text('Bekleniyor'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrguBaslama() {
    final bool baslayabilir = currentModelData?['orguye_baslayabilir'] == true;

    return Card(
      elevation: 2,
      color: baslayabilir ? Colors.indigo[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle, color: baslayabilir ? Colors.indigo : Colors.grey, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Örgüye Başlama',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: baslayabilir ? Colors.indigo : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    baslayabilir ? 'Başlayabilir' : 'Hazır Değil',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (kullaniciRolu == 'admin') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrguBaslama(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Başlayabilir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateOrguBaslama(false),
                      icon: const Icon(Icons.pause),
                      label: const Text('Hazır Değil'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateDurum(String durumKey, String value, String aciklamaKey) async {
    try {
      await supabase
          .from(DbTables.trikoTakip)
          .update({durumKey: value})
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      setState(() {
        currentModelData?[durumKey] = value;
      });
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Durum güncellendi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  Future<void> _saveAciklama(String key, String? value) async {
    try {
      await supabase
          .from(DbTables.trikoTakip)
          .update({key: currentModelData?[key]})
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      context.showSuccessSnackBar('✅ Açıklama kaydedildi');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  Future<void> _updateKaseOnay(bool onay) async {
    try {
      final Map<String, dynamic> updateData = {
        'kase_onayi': onay,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await supabase
          .from(DbTables.trikoTakip)
          .update(updateData)
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      setState(() {
        currentModelData?['kase_onayi'] = onay;
        currentModelData?['updated_at'] = DateTime.now().toIso8601String();
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(onay ? '✅ Kaşe onaylandı' : '↩️ Onay kaldırıldı'),
          backgroundColor: onay ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  Future<void> _updateIplikDurumu(bool geldi) async {
    try {
      final Map<String, dynamic> updateData = {
        'iplik_geldi': geldi,
      };
      if (geldi) {
        updateData['iplik_gelis_tarihi'] = DateTime.now().toIso8601String();
      }
      
      await supabase
          .from(DbTables.trikoTakip)
          .update(updateData)
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      setState(() {
        currentModelData?['iplik_geldi'] = geldi;
        if (geldi) {
          currentModelData?['iplik_gelis_tarihi'] = DateTime.now().toIso8601String();
        }
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(geldi ? '✅ İplik geldi olarak işaretlendi' : '⏳ İplik bekleniyor olarak işaretlendi'),
          backgroundColor: geldi ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }

  Future<void> _updateOrguBaslama(bool baslayabilir) async {
    try {
      await supabase
          .from(DbTables.trikoTakip)
          .update({'orguye_baslayabilir': baslayabilir})
          .eq('id', widget.modelId);
      
      if (!mounted) return;
      setState(() {
        currentModelData?['orguye_baslayabilir'] = baslayabilir;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(baslayabilir ? '✅ Örgüye başlanabilir' : '⏸️ Örgü beklemede'),
          backgroundColor: baslayabilir ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('❌ Hata: $e');
    }
  }
}
