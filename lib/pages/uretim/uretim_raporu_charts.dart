// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

/// Grafik tabı — fl_chart ile görselleştirmeler
extension _ChartsExt on _UretimRaporuPageState {

  Widget _buildGrafiklerTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Aşama Dağılımı — Pasta Grafik
              _buildSectionTitle('Aşama Dağılımı', Icons.pie_chart),
              const SizedBox(height: 12),
              _buildAsamaPieChart(isMobile),
              const SizedBox(height: 24),
              
              // 2. Fire Oranları — Bar Chart
              _buildSectionTitle('Aşama Bazlı Fire Oranları', Icons.bar_chart),
              const SizedBox(height: 12),
              _buildFireBarChart(isMobile),
              const SizedBox(height: 24),
              
              // 3. Marka Dağılımı — Horizontal Bar
              _buildSectionTitle('Marka Bazlı Model Sayısı', Icons.analytics),
              const SizedBox(height: 12),
              _buildMarkaBarChart(isMobile),
              const SizedBox(height: 24),
              
              // 4. Tamamlanma Trendi — Line Chart
              _buildSectionTitle('Aylık Üretim Trendi', Icons.show_chart),
              const SizedBox(height: 12),
              _buildUretimTrendChart(isMobile),
              const SizedBox(height: 24),
              
              // 5. Verimlilik Gauge
              _buildSectionTitle('Genel Verimlilik', Icons.speed),
              const SizedBox(height: 12),
              _buildVerimlilikGauge(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Pasta grafik — aşama dağılımı
  Widget _buildAsamaPieChart(bool isMobile) {
    final asamaSayilari = _ozet['asama_sayilari'] as Map<String, int>? ?? {};
    
    if (asamaSayilari.values.every((v) => v == 0)) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Veri yok'))));
    }

    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];
    final toplam = asamaSayilari.values.fold(0, (a, b) => a + b);
    
    for (final entry in asamaSayilari.entries) {
      if (entry.value == 0) continue;
      final info = _getAsamaBilgisi(entry.key);
      final color = info['color'] as Color;
      final label = info['label'] as String;
      final yuzde = toplam > 0 ? (entry.value / toplam * 100) : 0.0;
      
      sections.add(PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${yuzde.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        radius: isMobile ? 50 : 70,
      ));
      
      legends.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text('$label (${entry.value})', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? Column(
                children: [
                  SizedBox(height: 200, child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 30))),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 4, children: legends),
                ],
              )
            : Row(
                children: [
                  Expanded(child: SizedBox(height: 250, child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40)))),
                  const SizedBox(width: 24),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: legends),
                ],
              ),
      ),
    );
  }

  /// Bar chart — aşama bazlı fire oranları
  Widget _buildFireBarChart(bool isMobile) {
    if (_fireAnaliz.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Fire verisi yok'))));
    }

    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    int idx = 0;

    for (final entry in _fireAnaliz.entries) {
      final fire = entry.value['fire'] ?? 0;
      final toplam = entry.value['toplam'] ?? 0;
      final oran = toplam > 0 ? (fire / toplam * 100) : 0.0;
      final info = _getAsamaBilgisi(entry.key);
      
      bars.add(BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: oran,
            color: oran > 5 ? Colors.red : (oran > 2 ? Colors.orange : Colors.green),
            width: isMobile ? 16 : 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
      labels.add(info['label'] as String);
      idx++;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: isMobile ? 220 : 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: bars.map((b) => b.barRods.first.toY).fold(0.0, (a, b) => a > b ? a : b) + 2,
              barGroups: bars,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text('%${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i], style: TextStyle(fontSize: isMobile ? 8 : 10), textAlign: TextAlign.center),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  /// Marka bazlı horizontal bar chart
  Widget _buildMarkaBarChart(bool isMobile) {
    final markaBazli = <String, int>{};
    for (var model in _tumModeller) {
      final marka = model['marka']?.toString() ?? 'Belirtilmemiş';
      markaBazli[marka] = (markaBazli[marka] ?? 0) + 1;
    }
    
    final sirali = markaBazli.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final gosterilecek = sirali.take(10).toList();
    
    if (gosterilecek.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Marka verisi yok'))));
    }

    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    final maxVal = gosterilecek.first.value.toDouble();

    for (int i = 0; i < gosterilecek.length; i++) {
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: gosterilecek[i].value.toDouble(),
            color: Colors.indigo.shade400,
            width: isMobile ? 14 : 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
      labels.add(gosterilecek[i].key);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: isMobile ? 220 : 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal + 2,
              barGroups: bars,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: RotatedBox(
                            quarterTurns: isMobile ? 1 : 0,
                            child: Text(labels[i], style: TextStyle(fontSize: isMobile ? 8 : 10)),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  /// Aylık üretim trendi — line chart
  Widget _buildUretimTrendChart(bool isMobile) {
    // Aylık bazda tamamlanan ve oluşturulan model sayılarını hesapla
    final aylikOlusturulan = <String, int>{};
    final aylikTamamlanan = <String, int>{};
    
    for (var model in _tumModeller) {
      if (model['created_at'] != null) {
        final tarih = DateTime.tryParse(model['created_at'].toString());
        if (tarih != null) {
          final ayKey = DateFormat('yyyy-MM').format(tarih);
          aylikOlusturulan[ayKey] = (aylikOlusturulan[ayKey] ?? 0) + 1;
        }
      }
      if (model['tamamlandi'] == true && model['updated_at'] != null) {
        final tarih = DateTime.tryParse(model['updated_at'].toString());
        if (tarih != null) {
          final ayKey = DateFormat('yyyy-MM').format(tarih);
          aylikTamamlanan[ayKey] = (aylikTamamlanan[ayKey] ?? 0) + 1;
        }
      }
    }
    
    // Son 6 ayı al
    final simdi = DateTime.now();
    final aylar = <String>[];
    for (int i = 5; i >= 0; i--) {
      final ay = DateTime(simdi.year, simdi.month - i, 1);
      aylar.add(DateFormat('yyyy-MM').format(ay));
    }

    if (aylar.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Trend verisi yok'))));
    }

    final olusturulanSpots = <FlSpot>[];
    final tamamlananSpots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < aylar.length; i++) {
      final ol = (aylikOlusturulan[aylar[i]] ?? 0).toDouble();
      final ta = (aylikTamamlanan[aylar[i]] ?? 0).toDouble();
      olusturulanSpots.add(FlSpot(i.toDouble(), ol));
      tamamlananSpots.add(FlSpot(i.toDouble(), ta));
      if (ol > maxY) maxY = ol;
      if (ta > maxY) maxY = ta;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: isMobile ? 200 : 260,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: olusturulanSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
                    ),
                    LineChartBarData(
                      spots: tamamlananSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= 0 && i < aylar.length) {
                            final ay = DateTime.tryParse('${aylar[i]}-01');
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                ay != null ? DateFormat('MMM', 'tr').format(ay) : aylar[i],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  maxY: maxY + 2,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Oluşturulan', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Tamamlanan', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Verimlilik gauge göstergesi
  Widget _buildVerimlilikGauge(bool isMobile) {
    final verimlilik = (_ozet['verimlilik_orani'] as double?) ?? 100.0;
    final tamamlanma = (_ozet['tamamlanma_orani'] as double?) ?? 0.0;
    final zamaninda = (_ozet['zamaninda_teslim_orani'] as double?) ?? 100.0;
    final fireOrani = (_ozet['fire_orani'] as double?) ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildGaugeKart('Verimlilik', verimlilik, Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGaugeKart('Tamamlanma', tamamlanma, Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildGaugeKart('Zamanında Teslim', zamaninda, Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGaugeKart('Fire Oranı', fireOrani, Colors.red, ters: true)),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildGaugeKart('Verimlilik', verimlilik, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGaugeKart('Tamamlanma', tamamlanma, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGaugeKart('Zamanında Teslim', zamaninda, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGaugeKart('Fire Oranı', fireOrani, Colors.red, ters: true)),
                ],
              ),
      ),
    );
  }

  Widget _buildGaugeKart(String label, double yuzde, Color renk, {bool ters = false}) {
    final displayYuzde = yuzde.clamp(0.0, 100.0);
    final iyi = ters ? displayYuzde < 3 : displayYuzde > 80;
    final orta = ters ? displayYuzde < 5 : displayYuzde > 50;
    final gostergeRenk = iyi ? Colors.green : (orta ? Colors.orange : Colors.red);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gostergeRenk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gostergeRenk.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: displayYuzde / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(gostergeRenk),
                ),
                Text(
                  '%${displayYuzde.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gostergeRenk),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
