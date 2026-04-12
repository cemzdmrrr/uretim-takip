// ignore_for_file: invalid_use_of_protected_member
part of 'sevk_yonetimi_page.dart';

/// Sevk yonetimi - tab widgetlari ve dialoglar
extension _TabsExt on _SevkYonetimiPageState {
  Widget _buildAtanmisModellerTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.assignment, size: 32, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atanmış Modeller',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${atanmisModeller.length} model aktif',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter and search bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Model ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () => _showFilterDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Models list
          Expanded(
            child: ListView.builder(
              itemCount: atanmisModeller.length,
              itemBuilder: (context, index) {
                final model = atanmisModeller[index];
                final toplamAdet = model['toplam_adet'] ?? 0;
                final yuklenenAdet = model['yuklenen_adet'] ?? 0;
                final kalanAdet = toplamAdet - yuklenenAdet;
                final completionPercentage = toplamAdet > 0 ? (yuklenenAdet / toplamAdet) : 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Icon(
                                Icons.checkroom,
                                color: Colors.blue.shade700,
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Model: ${model['model_adi']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: completionPercentage >= 1.0 ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(completionPercentage * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Progress section
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Toplam: $toplamAdet',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Kalan: $kalanAdet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: kalanAdet == 0 ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: completionPercentage,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      completionPercentage >= 1.0 ? Colors.green : Colors.blue,
                                    ),
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: ElevatedButton.icon(
                                onPressed: kalanAdet > 0 ? () => _showSevkTalebiDialog(model) : null,
                                icon: const Icon(Icons.local_shipping, size: 18),
                                label: const Text('Sevk Talebi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kalanAdet > 0 ? Colors.blue : Colors.grey,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Tamamlananlar'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Devam Edenler'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Bekleyenler'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  Widget _buildSevkTalepleriTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.pending_actions, size: 32, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sevk Talepleri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        '${sevkTalepleri.length} aktif talep',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showYeniSevkTalebiDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni Talep'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Talep listesi
          Expanded(
            child: ListView.builder(
              itemCount: sevkTalepleri.length,
              itemBuilder: (context, index) {
                final talep = sevkTalepleri[index];
                final durum = talep['durum'] ?? 'bilinmeyen';
                final durumColor = _getDurumColor(durum);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: durumColor, width: 4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: durumColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                talep[DbTables.trikoTakip] != null 
                                    ? '${talep[DbTables.trikoTakip]['marka']} - ${talep[DbTables.trikoTakip]['item_no']}'
                                    : 'Model bilgisi yok',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _getDurumChip(durum),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            _buildInfoChip(Icons.production_quantity_limits, 'Adet: ${talep['sevk_edilen_adet'] ?? 'N/A'}'),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.timeline, 'Aşama: ${_getAsamaText(talep['asama'] ?? '')}'),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Oluşturulma: ${_formatDate(DateTime.now())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showTalepDetayDialog(talep),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('Detay'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDurumColor(String durum) {
    switch (durum) {
      case 'bekliyor': return Colors.orange;
      case 'kalite_onay': return Colors.blue;
      case 'sevk_hazir': return Colors.green;
      case 'yolda': return Colors.purple;
      case 'teslim_edildi': return Colors.teal;
      case 'kabul_edildi': return Colors.green.shade700;
      case 'reddedildi': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showYeniSevkTalebiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sevk Talebi'),
        content: const Text('Hızlı sevk talebi oluşturma özelliği geliştirilmekte...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showTalepDetayDialog(Map<String, dynamic> talep) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talep Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetayRow('Model', talep[DbTables.trikoTakip]?['model_adi'] ?? 'N/A'),
              _buildDetayRow('Marka', talep[DbTables.trikoTakip]?['marka'] ?? 'N/A'),
              _buildDetayRow('Adet', '${talep['sevk_edilen_adet'] ?? 'N/A'}'),
              _buildDetayRow('Durum', _getDurumText(talep['durum'] ?? '')),
              _buildDetayRow('Aşama', _getAsamaText(talep['asama'] ?? '')),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Talep Durumu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDurumText(talep['durum'] ?? ''),
                      style: TextStyle(color: Colors.blue.shade600),
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
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildGecmisTab() {
    return const Center(child: Text('Geçmiş sevkiyatlar burada gösterilecek'));
  }

  Widget _buildKaliteBekleyenTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sevkTalepleri.length,
      itemBuilder: (context, index) {
        final talep = sevkTalepleri[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${talep[DbTables.trikoTakip]['marka']} - ${talep[DbTables.trikoTakip]['item_no']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adet: ${talep['sevk_edilen_adet']}'),
                Text('Aşama: ${_getAsamaText(talep['asama'])}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _kaliteOnayla(talep['id']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Onayla'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _kaliteReddet(talep['id']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reddet'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKaliteOnaylananTab() {
    return const Center(child: Text('Onaylanan ürünler'));
  }

  Widget _buildKaliteReddedilenTab() {
    return const Center(child: Text('Reddedilen ürünler'));
  }

  Widget _buildSevkiyatHazirTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sevkTalepleri.length,
      itemBuilder: (context, index) {
        final talep = sevkTalepleri[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${talep[DbTables.trikoTakip]['marka']} - ${talep[DbTables.trikoTakip]['item_no']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adet: ${talep['sevk_edilen_adet']}'),
                Text('Hedef: ${talep['atolyeler']['atolye_adi']}'),
                Text('Adres: ${talep['atolyeler']['adres']}'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _sevkiyatBaslat(talep['id']),
              child: const Text('Araca Al'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSevkiyatDevamTab() {
    return const Center(child: Text('Devam eden sevkiyatlar'));
  }

  Widget _buildSevkiyatTamamTab() {
    return const Center(child: Text('Tamamlanan sevkiyatlar'));
  }

  Widget _buildAtolyeGelenTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sevkTalepleri.length,
      itemBuilder: (context, index) {
        final talep = sevkTalepleri[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${talep[DbTables.trikoTakip]['marka']} - ${talep[DbTables.trikoTakip]['item_no']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gelen Adet: ${talep['sevk_edilen_adet']}'),
                Text('Durum: ${_getDurumText(talep['durum'])}'),
              ],
            ),
            trailing: talep['durum'] == 'teslim_edildi'
                ? ElevatedButton(
                    onPressed: () => _urunleriKabulEt(talep['id']),
                    child: const Text('Kabul Et'),
                  )
                : _getDurumChip(talep['durum']),
          ),
        );
      },
    );
  }

  Widget _buildAtolyeUretimTab() {
    return const Center(child: Text('Üretim aşamasındaki ürünler'));
  }

  Widget _buildAtolyeTamamTab() {
    return const Center(child: Text('Tamamlanan ürünler'));
  }

}
