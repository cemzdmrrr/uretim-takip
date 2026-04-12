part of 'gelismis_raporlar_page.dart';

/// Kalite (Quality) tab methods for _GelismisRaporlarPageState.
extension _KaliteTabExt on _GelismisRaporlarPageState {
  // ==============================================
  // KALİTE SEKMESİ
  // ==============================================
  Widget _buildKaliteTab() {
    final toplamKontrol = (kaliteVerileri['toplamKontrol'] ?? 0) as int;
    final basarili = (kaliteVerileri['basariliKontrol'] ?? 0) as int;
    final basarisiz = (kaliteVerileri['basarisizKontrol'] ?? 0) as int;
    final bekleyen = (kaliteVerileri['bekleyenKontrol'] ?? 0) as int;
    final basariOrani = (kaliteVerileri['basariOrani'] ?? 0) as num;
    final fireAnalizi = Map<String, dynamic>.from(kaliteVerileri['fireAnalizi'] ?? {});
    final kaliteDagilimi = Map<String, dynamic>.from(kaliteVerileri['kaliteDagilimi'] ?? {});
    final sorunluModeller = List<Map<String, dynamic>>.from(kaliteVerileri['sorunluModeller'] ?? []);

    final fireOrani = (fireAnalizi['fireOrani'] ?? 0) as num;
    final birinciKaliteOrani = (kaliteDagilimi['birinciKaliteOrani'] ?? 0) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ÖZET KARTLARI
        Row(children: [
          Expanded(child: _buildKPICard('Toplam Kontrol', '$toplamKontrol', Icons.fact_check, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Başarılı', '$basarili', Icons.check_circle, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Başarısız', '$basarisiz', Icons.cancel, Colors.red)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPICard('Bekleyen', '$bekleyen', Icons.hourglass_empty, Colors.orange)),
        ]),
        const SizedBox(height: 24),

        // KALİTE PERFORMANSI
        _buildSectionTitle('Kalite Performansı'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: basariOrani / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            basariOrani >= 90 ? Colors.green : basariOrani >= 70 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      Text('%${basariOrani.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Başarı Oranı', textAlign: TextAlign.center),
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
                          value: birinciKaliteOrani / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ),
                      Text('%${birinciKaliteOrani.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Kalite Oranı', textAlign: TextAlign.center),
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
                          value: fireOrani / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            fireOrani <= 3 ? Colors.green : fireOrani <= 5 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      Text('%${fireOrani.toStringAsFixed(1)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Fire Oranı', textAlign: TextAlign.center),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // FİRE ANALİZİ
        _buildSectionTitle('Fire Analizi'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  Text(((fireAnalizi['toplamFireAdet'] ?? 0) as num).toStringAsFixed(0), 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  const Text('Toplam Fire Adet'),
                ]),
                Column(children: [
                  Text(((fireAnalizi['toplamKontrolAdet'] ?? 0) as num).toStringAsFixed(0), 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Text('Kontrol Edilen'),
                ]),
              ]),
              if (fireAnalizi['hataTipiDagilimi'] != null) ...[
                const Divider(height: 24),
                const Text('Hata Tipi Dağılımı', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(fireAnalizi['hataTipiDagilimi'] as Map<String, dynamic>).entries.take(5).map((e) {
                  final total = (fireAnalizi['hataTipiDagilimi'] as Map<String, dynamic>).values.fold(0, (s, v) => s + (v as int));
                  final yuzde = total > 0 ? (e.value as int) / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(width: 120, child: Text(e.key, overflow: TextOverflow.ellipsis)),
                      Expanded(child: LinearProgressIndicator(value: yuzde, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Colors.red))),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  );
                }),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // KALİTE DAĞILIMI
        _buildSectionTitle('Kalite Dağılımı'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    const Icon(Icons.star, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(((kaliteDagilimi['birinciKaliteAdet'] ?? 0) as num).toStringAsFixed(0), 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('${kaliteDagilimi['birinciKaliteSayisi'] ?? 0} parti', style: TextStyle(color: Colors.grey[600])),
                    const Text('1. Kalite', style: TextStyle(color: Colors.green)),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    const Icon(Icons.star_half, color: Colors.orange, size: 32),
                    const SizedBox(height: 8),
                    Text(((kaliteDagilimi['ikinciKaliteAdet'] ?? 0) as num).toStringAsFixed(0), 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text('${kaliteDagilimi['ikinciKaliteSayisi'] ?? 0} parti', style: TextStyle(color: Colors.grey[600])),
                    const Text('2. & 3. Kalite', style: TextStyle(color: Colors.orange)),
                  ]),
                ),
              ),
            ]),
          ),
        ),

        // SORUNLU MODELLER
        if (sorunluModeller.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('En Sorunlu Modeller', Colors.red),
          const SizedBox(height: 8),
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorunluModeller.length > 5 ? 5 : sorunluModeller.length,
              itemBuilder: (context, index) {
                final m = sorunluModeller[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.red)),
                  ),
                  title: Text('Model: ${m['modelId']}'),
                  subtitle: Text('Fire: ${m['fireAdet']} / ${m['kontrolAdet']} adet'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (m['fireOrani'] as num) > 10 ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('%${(m['fireOrani'] as num).toStringAsFixed(1)}', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }
}
