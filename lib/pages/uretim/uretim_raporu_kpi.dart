// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

/// KPI Dashboard tab — özet metrikler, verimlilik, trendler
extension _KpiExt on _UretimRaporuPageState {

  Widget _buildKpiDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 900;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ana KPI kartları
              _buildAnaKpiKartlari(isMobile, isTablet),
              const SizedBox(height: 16),
              
              // Verimlilik göstergeleri
              _buildVerimlilikBolumu(isMobile),
              const SizedBox(height: 16),
              
              // Üretim akış özeti
              _buildUretimAkisOzeti(isMobile),
              const SizedBox(height: 16),
              
              // Darboğaz uyarıları
              _buildDarbogazUyarilari(isMobile),
              const SizedBox(height: 16),
              
              // Bu ay vs geçen ay karşılaştırma
              _buildDonemKarsilastirma(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnaKpiKartlari(bool isMobile, bool isTablet) {
    final gecikenSiparis = _ozet['geciken_siparis'] ?? 0;
    final ortSure = (_ozet['ortalama_uretim_suresi'] as double?) ?? 0.0;

    final kartlar = [
      _buildKpiKart('Toplam Model', '${_ozet['toplam_model'] ?? 0}', Colors.blue, Icons.inventory, isMobile),
      _buildKpiKart('Devam Eden', '${_ozet['devam_eden'] ?? 0}', Colors.orange, Icons.pending, isMobile),
      _buildKpiKart('Tamamlanan', '${_ozet['tamamlanan'] ?? 0}', Colors.green, Icons.check_circle, isMobile),
      _buildKpiKart('Toplam Adet', '${_ozet['toplam_adet'] ?? 0}', Colors.purple, Icons.numbers, isMobile),
      _buildKpiKart('Toplam Fire', '${_ozet['toplam_fire'] ?? 0}', Colors.red.shade400, Icons.local_fire_department, isMobile),
      _buildKpiKart('Geciken', '$gecikenSiparis', Colors.red.shade700, Icons.warning_amber, isMobile),
      _buildKpiKart('Ort. Süre', '${ortSure.toStringAsFixed(0)} gün', Colors.teal, Icons.timer, isMobile),
      _buildKpiKart('Verimlilik', '%${((_ozet['verimlilik_orani'] as double?) ?? 100).toStringAsFixed(1)}', Colors.indigo, Icons.speed, isMobile),
    ];
    
    final crossAxisCount = isMobile ? 2 : (isTablet ? 4 : 4);
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: isMobile ? 1.4 : 1.6,
      children: kartlar,
    );
  }

  Widget _buildKpiKart(String baslik, String deger, Color renk, IconData icon, bool isMobile) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [renk.withValues(alpha: 0.12), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: renk, size: isMobile ? 22 : 28),
            SizedBox(height: isMobile ? 4 : 8),
            FittedBox(
              child: Text(
                deger,
                style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: renk),
              ),
            ),
            Text(baslik, style: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerimlilikBolumu(bool isMobile) {
    final verimlilik = (_ozet['verimlilik_orani'] as double?) ?? 100.0;
    final tamamlanma = (_ozet['tamamlanma_orani'] as double?) ?? 0.0;
    final zamaninda = (_ozet['zamaninda_teslim_orani'] as double?) ?? 100.0;
    final fireOrani = (_ozet['fire_orani'] as double?) ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Verimlilik Göstergeleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar('Üretim Verimliliği', verimlilik, Colors.blue),
            const SizedBox(height: 12),
            _buildProgressBar('Tamamlanma Oranı', tamamlanma, Colors.green),
            const SizedBox(height: 12),
            _buildProgressBar('Zamanında Teslim', zamaninda, Colors.orange),
            const SizedBox(height: 12),
            _buildProgressBar('Fire Oranı', fireOrani, Colors.red, ters: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double yuzde, Color renk, {bool ters = false}) {
    final deger = yuzde.clamp(0.0, 100.0);
    final iyi = ters ? deger < 3 : deger > 80;
    final gostergeRenk = iyi ? Colors.green : (ters ? (deger > 5 ? Colors.red : Colors.orange) : (deger > 50 ? Colors.orange : Colors.red));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('%${deger.toStringAsFixed(1)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gostergeRenk)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: deger / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(gostergeRenk),
          ),
        ),
      ],
    );
  }

  /// Üretim akış özeti — bir pipeline/funnel görünümü
  Widget _buildUretimAkisOzeti(bool isMobile) {
    final asamaSayilari = _ozet['asama_sayilari'] as Map<String, int>? ?? {};
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.linear_scale, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Üretim Hattı Akışı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: UretimRaporuService.asamaSirasi.map((asamaKey) {
                  final sayi = asamaSayilari[asamaKey] ?? 0;
                  final info = _getAsamaBilgisi(asamaKey);
                  final color = info['color'] as Color;
                  final isLast = asamaKey == UretimRaporuService.asamaSirasi.last;
                  
                  return Row(
                    children: [
                      Container(
                        width: isMobile ? 70 : 90,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(info['icon'] as IconData, color: color, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              sayi.toString(),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                            ),
                            Text(
                              info['label'] as String,
                              style: TextStyle(fontSize: isMobile ? 9 : 10, color: color),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, color: Colors.grey.shade400, size: 16),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Tamamlanan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Tamamlanan: ${asamaSayilari['tamamlandi'] ?? 0}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Darboğaz uyarıları — bir aşamada çok fazla model birikiyorsa uyarı
  Widget _buildDarbogazUyarilari(bool isMobile) {
    final asamaSayilari = _ozet['asama_sayilari'] as Map<String, int>? ?? {};
    final toplamAktif = asamaSayilari.entries
        .where((e) => e.key != 'tamamlandi')
        .fold(0, (sum, e) => sum + e.value);
    
    if (toplamAktif == 0) {
      return const SizedBox.shrink();
    }
    
    final ortalamaPerAsama = toplamAktif / 7; // 7 aşama
    final darbogazlar = <MapEntry<String, int>>[];
    
    for (final entry in asamaSayilari.entries) {
      if (entry.key == 'tamamlandi') continue;
      // Ortalamanın 2 katından fazla model biriken aşama = darboğaz
      if (entry.value > ortalamaPerAsama * 2 && entry.value > 2) {
        darbogazlar.add(entry);
      }
    }
    
    if (darbogazlar.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Üretim hattında darboğaz bulunmuyor.', style: TextStyle(color: Colors.green))),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red),
                SizedBox(width: 8),
                Text('Darboğaz Uyarıları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            ...darbogazlar.map((entry) {
              final info = _getAsamaBilgisi(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(info['icon'] as IconData, color: info['color'] as Color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${info['label']} aşamasında ${entry.value} model birikmiş durumda!',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Bu ay vs geçen ay karşılaştırma
  Widget _buildDonemKarsilastirma(bool isMobile) {
    final simdi = DateTime.now();
    final buAyBaslangic = DateTime(simdi.year, simdi.month, 1);
    final gecenAyBaslangic = DateTime(simdi.year, simdi.month - 1, 1);
    
    int buAyOlusturulan = 0, gecenAyOlusturulan = 0;
    int buAyTamamlanan = 0, gecenAyTamamlanan = 0;
    int buAyFire = 0, gecenAyFire = 0;
    
    for (var model in _tumModeller) {
      final createdAt = DateTime.tryParse(model['created_at']?.toString() ?? '');
      if (createdAt != null) {
        if (createdAt.isAfter(buAyBaslangic)) {
          buAyOlusturulan++;
        } else if (createdAt.isAfter(gecenAyBaslangic) && createdAt.isBefore(buAyBaslangic)) {
          gecenAyOlusturulan++;
        }
      }
      
      final updatedAt = DateTime.tryParse(model['updated_at']?.toString() ?? '');
      if (model['tamamlandi'] == true && updatedAt != null) {
        if (updatedAt.isAfter(buAyBaslangic)) {
          buAyTamamlanan++;
        } else if (updatedAt.isAfter(gecenAyBaslangic) && updatedAt.isBefore(buAyBaslangic)) {
          gecenAyTamamlanan++;
        }
      }
      
      // Fire hesapla
      final asamalar = model['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};
      for (var asama in asamalar.values) {
        final fire = (asama['fire_adet'] ?? 0) as int;
        final atamaCreatedAt = DateTime.tryParse(asama['created_at']?.toString() ?? '');
        if (atamaCreatedAt != null) {
          if (atamaCreatedAt.isAfter(buAyBaslangic)) {
            buAyFire += fire;
          } else if (atamaCreatedAt.isAfter(gecenAyBaslangic) && atamaCreatedAt.isBefore(buAyBaslangic)) {
            gecenAyFire += fire;
          }
        }
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMMM', 'tr').format(simdi)} vs ${DateFormat('MMMM', 'tr').format(gecenAyBaslangic)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    const Padding(padding: EdgeInsets.all(8), child: Text('Metrik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(DateFormat('MMM', 'tr').format(gecenAyBaslangic), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                    Padding(padding: const EdgeInsets.all(8), child: Text(DateFormat('MMM', 'tr').format(simdi), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                    const Padding(padding: EdgeInsets.all(8), child: Text('Fark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                  ],
                ),
                _buildKarsilastirmaSatir('Oluşturulan', gecenAyOlusturulan, buAyOlusturulan),
                _buildKarsilastirmaSatir('Tamamlanan', gecenAyTamamlanan, buAyTamamlanan),
                _buildKarsilastirmaSatir('Fire', gecenAyFire, buAyFire, ters: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildKarsilastirmaSatir(String label, int onceki, int simdiki, {bool ters = false}) {
    final fark = simdiki - onceki;
    final pozitif = ters ? fark < 0 : fark > 0;
    final farkRenk = fark == 0 ? Colors.grey : (pozitif ? Colors.green : Colors.red);
    final farkIcon = fark == 0 ? '' : (fark > 0 ? '▲' : '▼');
    
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(label, style: const TextStyle(fontSize: 12))),
        Padding(padding: const EdgeInsets.all(8), child: Text('$onceki', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
        Padding(padding: const EdgeInsets.all(8), child: Text('$simdiki', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '$farkIcon${fark.abs()}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: farkRenk, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
