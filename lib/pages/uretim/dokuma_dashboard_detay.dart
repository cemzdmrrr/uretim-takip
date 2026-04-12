// ignore_for_file: invalid_use_of_protected_member
part of 'dokuma_dashboard.dart';

/// Dokuma dashboard atama detay goruntuleme
extension _DetayExt on _DokumaDashboardState {
  void _showAtamaDetay(Map<String, dynamic> atama, Map<String, dynamic> model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${model['marka']} - ${model['item_no']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model Bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Model Bilgileri', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _buildDetayRow('Marka', model['marka']),
                    _buildDetayRow('Item No', model['item_no']),
                    _buildDetayRow('Renk', model['renk']),
                    _buildDetayRow('Toplam Adet', model['adet']?.toString()),
                    if (model['termin_tarihi'] != null)
                      _buildDetayRow('Termin', DateFormat('dd.MM.yyyy').format(
                        DateTime.parse(model['termin_tarihi']))),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Atama Bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Atama Bilgileri', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _buildDetayRow('Durum', _getDurumText(atama['durum']),
                      valueColor: _getDurumColor(atama['durum'])),
                    _buildDetayRow('Talep Edilen', atama['talep_edilen_adet']?.toString()),
                    _buildDetayRow('Kabul Edilen', atama['kabul_edilen_adet']?.toString()),
                    if (atama['tamamlanan_adet'] != null && atama['tamamlanan_adet'] > 0)
                      _buildDetayRow('Tamamlanan', atama['tamamlanan_adet']?.toString(),
                        valueColor: Colors.green),
                    if ((atama['fire_adet'] ?? 0) > 0)
                      _buildDetayRow('Fire Adet', atama['fire_adet']?.toString(),
                        valueColor: Colors.red),
                    if (atama['atama_tarihi'] != null)
                      _buildDetayRow('Atama Tarihi', DateFormat('dd.MM.yyyy HH:mm').format(
                        DateTime.parse(atama['atama_tarihi']))),
                    if (atama['tamamlama_tarihi'] != null)
                      _buildDetayRow('Tamamlama Tarihi', DateFormat('dd.MM.yyyy HH:mm').format(
                        DateTime.parse(atama['tamamlama_tarihi'])),
                        valueColor: Colors.green),
                  ],
                ),
              ),
              
              // Fire Bilgileri (varsa detaylı göster)
              if ((atama['fire_adet'] ?? 0) > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text('Fire Bilgileri', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetayRow('Toplam Fire', '${atama['fire_adet']} adet', valueColor: Colors.red),
                      if (atama['tamamlanan_adet'] != null && atama['tamamlanan_adet'] > 0)
                        _buildDetayRow('Fire Oranı', 
                          '%${((atama['fire_adet'] ?? 0) / ((atama['tamamlanan_adet'] ?? 0) + (atama['fire_adet'] ?? 0)) * 100).toStringAsFixed(1)}',
                          valueColor: Colors.red),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showBedenFireDetay(atama, model);
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Beden Bazlı Fire Detayı'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Notlar
              if (atama['notlar'] != null && atama['notlar'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notlar', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(atama['notlar'].toString()),
                    ],
                  ),
                ),
              ],
              
              // İlerleme Çubuğu
              if (atama['kabul_edilen_adet'] != null && atama['kabul_edilen_adet'] > 0) ...[
                const SizedBox(height: 16),
                _buildProgressSection(atama),
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

  Widget _buildDetayRow(String label, String? value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', 
              style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Map<String, dynamic> atama) {
    final kabulEdilen = (atama['kabul_edilen_adet'] ?? 0).toDouble();
    final tamamlanan = (atama['tamamlanan_adet'] ?? 0).toDouble();
    final progress = kabulEdilen > 0 ? tamamlanan / kabulEdilen : 0.0;
    final yuzde = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('İlerleme', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              Text('%$yuzde', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progress >= 1.0 ? Colors.green : Colors.blue,
                )),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${tamamlanan.toInt()} / ${kabulEdilen.toInt()} adet tamamlandı',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Beden bazlı fire detay dialog'u
}
