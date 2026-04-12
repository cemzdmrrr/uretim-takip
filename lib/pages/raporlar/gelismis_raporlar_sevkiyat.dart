part of 'gelismis_raporlar_page.dart';

/// Sevkiyat (Shipping) tab methods for _GelismisRaporlarPageState.
extension _SevkiyatTabExt on _GelismisRaporlarPageState {
  // ==============================================
  // SEVKİYAT SEKMESİ
  // ==============================================
  Widget _buildSevkiyatTab() {
    final toplamSevkiyat = (sevkiyatVerileri['toplamSevkiyat'] ?? 0) as int;
    final tamamlanan = (sevkiyatVerileri['tamamlananSevkiyat'] ?? 0) as int;
    final bekleyen = (sevkiyatVerileri['bekleyenSevkiyat'] ?? 0) as int;
    final geciken = (sevkiyatVerileri['gecikanSevkiyat'] ?? 0) as int;
    final zamanindaOrani = (sevkiyatVerileri['zamanindaOrani'] ?? 0) as num;
    final tamamlanmaOrani = (sevkiyatVerileri['tamamlanmaOrani'] ?? 0) as num;
    final musteriBazli = Map<String, dynamic>.from(sevkiyatVerileri['musteriBazliSevk'] ?? {});
    final gecikanler = List<Map<String, dynamic>>.from(sevkiyatVerileri['gecikanler'] ?? []);
    final talepAnalizi = Map<String, dynamic>.from(sevkiyatVerileri['talepAnalizi'] ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ÖZET KARTLARI
        Row(children: [
          Expanded(child: _buildKPICard('Toplam Sevkiyat', '$toplamSevkiyat', Icons.local_shipping, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Tamamlanan', '$tamamlanan', Icons.check_circle, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Bekleyen', '$bekleyen', Icons.hourglass_empty, Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Geciken', '$geciken', Icons.warning, Colors.red)),
        ]),
        const SizedBox(height: 24),

        // PERFORMANS ORANLARI
        _buildSectionTitle('Sevkiyat Performansı'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Column(children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: zamanindaOrani / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              zamanindaOrani >= 80 ? Colors.green : zamanindaOrani >= 60 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ),
                        Text('%${zamanindaOrani.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Zamanında Teslimat', textAlign: TextAlign.center),
                  ]),
                ),
                Expanded(
                  child: Column(children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: tamamlanmaOrani / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tamamlanmaOrani >= 80 ? Colors.green : tamamlanmaOrani >= 60 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ),
                        Text('%${tamamlanmaOrani.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Tamamlanma Oranı', textAlign: TextAlign.center),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // GECİKEN SEVKİYATLAR
        if (gecikanler.isNotEmpty) ...[
          _buildSectionTitle('Geciken Sevkiyatlar', Colors.red),
          const SizedBox(height: 8),
          Card(
            color: Colors.red[50],
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gecikanler.length > 5 ? 5 : gecikanler.length,
              itemBuilder: (context, index) {
                final g = gecikanler[index];
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(g['musteri'] ?? 'Bilinmeyen'),
                  subtitle: Text('Planlanan: ${g['planliTarih']}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                    child: Text('${g['gecikmeGun']} gün', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // MÜŞTERİ BAZLI SEVKİYAT
        if (musteriBazli.isNotEmpty) ...[
          _buildSectionTitle('Müşteri Bazlı Sevkiyat'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: musteriBazli.entries.take(8).map((e) {
                  final maxVal = musteriBazli.values.fold(0, (m, v) => (v) > m ? (v) : m);
                  final yuzde = maxVal > 0 ? (e.value as int) / maxVal : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(width: 120, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                      Expanded(child: LinearProgressIndicator(value: yuzde, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue))),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // TALEP ANALİZİ
        _buildSectionTitle('Sevk Talep Durumu'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildKPICard('Toplam Talep', '${talepAnalizi['toplamTalep'] ?? 0}', Icons.description, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Onaylanan', '${talepAnalizi['onaylanan'] ?? 0}', Icons.check, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Bekleyen', '${talepAnalizi['bekleyen'] ?? 0}', Icons.pending, Colors.orange)),
        ]),
      ]),
    );
  }
}
