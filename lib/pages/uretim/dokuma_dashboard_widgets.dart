// ignore_for_file: invalid_use_of_protected_member
part of 'dokuma_dashboard.dart';

/// Dokuma dashboard model karti ve liste widget'lari
extension _WidgetsExt on _DokumaDashboardState {
  Widget _buildModelKarti(Map<String, dynamic> atama) {
    // Atama verisi ve içinde triko_takip model verisi
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = atama['durum'] as String?;
    final tamamlananAdet = atama['tamamlanan_adet'] ?? 0;
    final kabulEdilenAdet = atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? atama['adet'] ?? 0;
    
    // Model verisi yoksa atama tablosundaki adet'i kullan
    final displayAdet = model['adet']?.toString() ?? atama['adet']?.toString();
    final displayRenk = model['renk'] ?? '-';
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDurumColor(durum),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDurumText(durum),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
            // Fire adetini göster (tamamlanan işler için)
            if ((atama['fire_adet'] ?? 0) > 0)
              _buildModelBilgisi('Fire', '${atama['fire_adet']}', textColor: Colors.red),
            
            // İlerleme çubuğu (sadece aktif işler için)
            if (kabulEdilenAdet > 0 && (durum == 'onaylandi' || durum == 'uretimde' || durum == 'baslatildi' || durum == 'kismi_tamamlandi')) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: tamamlananAdet / kabulEdilenAdet,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tamamlananAdet >= kabulEdilenAdet ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '%${((tamamlananAdet / kabulEdilenAdet) * 100).toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
            
            if (atama['atama_tarihi'] != null)
              _buildModelBilgisi(
                'Atama Tarihi',
                DateFormat('dd.MM.yyyy HH:mm').format(
                  DateTime.parse(atama['atama_tarihi']),
                ),
              ),
            
            // Üretim başlangıç ve planlanan bitiş tarihleri (üretimde durumu için)
            if (durum == 'uretimde' || durum == 'baslatildi' || durum == 'kismi_tamamlandi') ...[
              if (atama['baslama_tarihi'] != null)
                _buildModelBilgisi(
                  'Başlangıç',
                  DateFormat('dd.MM.yyyy HH:mm').format(
                    DateTime.parse(atama['baslama_tarihi']),
                  ),
                  textColor: Colors.blue,
                ),
              if (atama['planlanan_bitis_tarihi'] != null)
                _buildModelBilgisi(
                  'Planlanan Bitiş',
                  DateFormat('dd.MM.yyyy').format(
                    DateTime.parse(atama['planlanan_bitis_tarihi']),
                  ),
                  textColor: Colors.orange,
                ),
            ],
            
            if (atama['tamamlama_tarihi'] != null)
              _buildModelBilgisi(
                'Tamamlama Tarihi',
                DateFormat('dd.MM.yyyy HH:mm').format(
                  DateTime.parse(atama['tamamlama_tarihi']),
                ),
                textColor: Colors.green,
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
          onPressed: () => _showAtamaDetay(atama, model),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Detay'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
        
        // Düzenle butonu - admin için her zaman, diğerleri için tamamlanmamış işlerde
        if (currentUserRole == 'admin' || durum != 'tamamlandi')
          OutlinedButton.icon(
            onPressed: () => _showDuzenleDialog(atama, model),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Düzenle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
        
        // Üretime Al butonu - onaylanmış işler için
        if (durum == 'onaylandi')
          ElevatedButton.icon(
            onPressed: () => _showUretimeAlDialog(atama, model),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Üretime Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        
        // Üretimi Tamamla butonu - üretimde olan işler için (kalan adet kontrolü kaldırıldı)
        if (durum == 'uretimde' || durum == 'baslatildi' || durum == 'kismi_tamamlandi')
          ElevatedButton.icon(
            onPressed: () => _showTamamlaDialog(atama, model),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Üretimi Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        
        // Kabul Et butonu - sadece bekleyen işler için
        if (durum == 'atandi' || durum == 'beklemede')
          ElevatedButton.icon(
            onPressed: () => _showKabulDialog(atama, model),
            icon: const Icon(Icons.thumb_up, size: 18),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        
        // Reddet butonu - sadece bekleyen işler için
        if (durum == 'atandi' || durum == 'beklemede')
          ElevatedButton.icon(
            onPressed: () => _showReddetDialog(atama),
            icon: const Icon(Icons.thumb_down, size: 18),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

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


  Widget _buildModelListesi(List<Map<String, dynamic>> modeller, String bosListeMetni) {
    if (yukleniyor) {
      return const LoadingWidget();
    }

    if (modeller.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 40,
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
