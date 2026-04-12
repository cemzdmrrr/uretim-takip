part of 'gelismis_raporlar_page.dart';

/// Stok (Stock) tab methods for _GelismisRaporlarPageState.
extension _StokTabExt on _GelismisRaporlarPageState {
  // ==============================================
  // STOK SEKMESİ
  // ==============================================
  Widget _buildStokTab() {
    final iplikStok = Map<String, dynamic>.from(stokVerileri['iplikStok'] ?? {});
    final iplikHareket = Map<String, dynamic>.from(stokVerileri['iplikHareket'] ?? {});
    final aksesuarStok = Map<String, dynamic>.from(stokVerileri['aksesuarStok'] ?? {});
    final toplamStokDeger = (stokVerileri['toplamStokDeger'] ?? 0) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ÖZET KARTLARI
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            if (isMobile) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.3,
                children: [
                  _buildKPICard('Toplam Stok Değeri', currencyFormat.format(toplamStokDeger), Icons.account_balance, Colors.blue),
                  _buildKPICard('İplik Miktarı', '${((iplikStok['toplamMiktar'] ?? 0) as num).toStringAsFixed(0)} kg', Icons.cable, Colors.orange),
                  _buildKPICard('Aksesuar Çeşidi', '${aksesuarStok['cesitSayisi'] ?? 0}', Icons.category, Colors.purple),
                ],
              );
            }
            
            return Row(children: [
              Expanded(child: _buildKPICard('Toplam Stok Değeri', currencyFormat.format(toplamStokDeger), Icons.account_balance, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('İplik Miktarı', '${((iplikStok['toplamMiktar'] ?? 0) as num).toStringAsFixed(0)} kg', Icons.cable, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('Aksesuar Çeşidi', '${aksesuarStok['cesitSayisi'] ?? 0}', Icons.category, Colors.purple)),
            ]);
          },
        ),
        const SizedBox(height: 24),

        // İPLİK STOK DETAY
        _buildSectionTitle('İplik Stok Durumu'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildFinansOzet('İplik Değeri', iplikStok['toplamDeger'] ?? 0, Colors.blue),
                _buildFinansOzet('Stok Sayısı', iplikStok['stokSayisi'] ?? 0, Colors.green),
              ]),
              const Divider(height: 24),
              // İplik Tipi Dağılımı
              if (iplikStok['tipDagilimi'] != null) ...[
                const Text('İplik Tipi Dağılımı', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...((iplikStok['tipDagilimi'] as Map<String, dynamic>).entries.take(5).map((e) {
                  final total = (iplikStok['toplamMiktar'] ?? 1) as num;
                  final yuzde = total > 0 ? (e.value as num) / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(width: 100, child: Text(e.key)),
                      Expanded(child: LinearProgressIndicator(value: yuzde, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange))),
                      const SizedBox(width: 8),
                      Text('${(e.value as num).toStringAsFixed(0)} kg'),
                    ]),
                  );
                })),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // İPLİK TÜKETİM ANALİZİ
        _buildSectionTitle('Hammadde Tüketim Analizi'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Icon(Icons.arrow_downward, color: Colors.green, size: 32),
                      const SizedBox(height: 8),
                      Text('${((iplikHareket['toplamGiris'] ?? 0) as num).toStringAsFixed(0)} kg', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      const Text('Toplam Giriş', style: TextStyle(color: Colors.green)),
                    ]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Icon(Icons.arrow_upward, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text('${((iplikHareket['toplamCikis'] ?? 0) as num).toStringAsFixed(0)} kg', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                      const Text('Toplam Çıkış', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Icon(Icons.autorenew, color: Colors.blue, size: 32),
                      const SizedBox(height: 8),
                      Text('${((iplikHareket['stokDevirSuresi'] ?? 0) as num).toStringAsFixed(0)} gün', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const Text('Stok Devir Süresi', style: TextStyle(color: Colors.blue)),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Text('Ortalama Günlük Tüketim: ${((iplikHareket['ortalamaGunlukTuketim'] ?? 0) as num).toStringAsFixed(1)} kg/gün',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // AKSESUAR STOK
        _buildSectionTitle('Aksesuar Stok Durumu'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Column(children: [
                  Text(currencyFormat.format(aksesuarStok['toplamDeger'] ?? 0), 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const Text('Toplam Değer'),
                ]),
                Column(children: [
                  Text('${aksesuarStok['cesitSayisi'] ?? 0}', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const Text('Çeşit Sayısı'),
                ]),
              ]),
              if (aksesuarStok['kategoriDagilimi'] != null) ...[
                const Divider(height: 24),
                const Text('Kategori Dağılımı', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (aksesuarStok['kategoriDagilimi'] as Map<String, dynamic>).entries.map((e) => 
                    Chip(
                      label: Text('${e.key}: ${e.value}'),
                      backgroundColor: Colors.purple[50],
                    )
                  ).toList(),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
