import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GelismisChartWidgetlari {
  
  // ==============================================
  // ÜRETİM PERFORMANS GRAFİĞİ
  // ==============================================
  
  static Widget buildUretimPerformansGrafigi({
    required Map<String, double> ortalamaAsasmaSureleri,
    double height = 300,
  }) {
    if (ortalamaAsasmaSureleri.isEmpty) {
      return SizedBox(
        height: height,
        child: const Card(
          child: Center(
            child: Text(
              'Üretim verisi bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> asamaAdlari = ortalamaAsasmaSureleri.keys.toList();
    
    for (int i = 0; i < asamaAdlari.length; i++) {
      final asama = asamaAdlari[i];
      final sure = ortalamaAsasmaSureleri[asama] ?? 0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sure,
              color: _getAsamaRengi(i),
              width: 30,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Üretim Aşaması Performansı (Ortalama Saat)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: height - 80,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < asamaAdlari.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  asamaAdlari[value.toInt()],
                                  style: const TextStyle(fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // SİPARİŞ DURUM DAĞİLIMI
  // ==============================================
  
  static Widget buildSiparisDurumDagilimi({
    required Map<String, int> durumSayilari,
    double height = 300,
  }) {
    if (durumSayilari.isEmpty) {
      return SizedBox(
        height: height,
        child: const Card(
          child: Center(
            child: Text(
              'Sipariş verisi bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final List<PieChartSectionData> sections = [];
    final List<String> durumlar = durumSayilari.keys.toList();
    final int toplam = durumSayilari.values.reduce((a, b) => a + b);
    
    for (int i = 0; i < durumlar.length; i++) {
      final durum = durumlar[i];
      final sayi = durumSayilari[durum] ?? 0;
      final yuzde = (sayi / toplam * 100);
      
      sections.add(
        PieChartSectionData(
          value: sayi.toDouble(),
          title: '${yuzde.toStringAsFixed(1)}%',
          color: _getDurumRengi(durum),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sipariş Durum Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: height - 120,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: durumlar.map((durum) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _getDurumRengi(durum),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$durum (${durumSayilari[durum]})',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // MALİ PERFORMANS GRAFİĞİ
  // ==============================================
  
  static Widget buildMaliPerformansGrafigi({
    required double toplamGelir,
    required double toplamGider,
    required Map<String, double> kategoriGelirler,
    required Map<String, double> kategoriGiderler,
    double height = 300,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mali Performans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Gelir-Gider Karşılaştırması
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Gelir vs Gider',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 150,
                        child: BarChart(
                          BarChartData(
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: toplamGelir,
                                    color: Colors.green,
                                    width: 40,
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: toplamGider,
                                    color: Colors.red,
                                    width: 40,
                                  ),
                                ],
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return const Text('Gelir');
                                      case 1:
                                        return const Text('Gider');
                                      default:
                                        return const Text('');
                                    }
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      _formatTutar(value),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Özet Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMaliOzetKarti(
                        'Toplam Gelir',
                        toplamGelir,
                        Colors.green,
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 10),
                      _buildMaliOzetKarti(
                        'Toplam Gider',
                        toplamGider,
                        Colors.red,
                        Icons.trending_down,
                      ),
                      const SizedBox(height: 10),
                      _buildMaliOzetKarti(
                        'Net Kar',
                        toplamGelir - toplamGider,
                        (toplamGelir - toplamGider) >= 0 ? Colors.green : Colors.red,
                        Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // STOK SEVİYE GRAFİĞİ
  // ==============================================
  
  static Widget buildStokSeviyeGrafigi({
    required Map<String, Map<String, dynamic>> stokDurumlari,
    double height = 300,
  }) {
    if (stokDurumlari.isEmpty) {
      return SizedBox(
        height: height,
        child: const Card(
          child: Center(
            child: Text(
              'Stok verisi bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> urunAdlari = stokDurumlari.keys.take(10).toList(); // İlk 10 ürün
    
    for (int i = 0; i < urunAdlari.length; i++) {
      final urun = urunAdlari[i];
      final stok = stokDurumlari[urun]!['mevcutStok'] as int;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stok.toDouble(),
              color: stok < 10 ? Colors.red : (stok < 50 ? Colors.orange : Colors.green),
              width: 25,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stok Seviyeleri (İlk 10 Ürün)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                _StokSeviyeLegend(color: Colors.red, label: 'Kritik (<10)'),
                SizedBox(width: 16),
                _StokSeviyeLegend(color: Colors.orange, label: 'Düşük (<50)'),
                SizedBox(width: 16),
                _StokSeviyeLegend(color: Colors.green, label: 'Normal (≥50)'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: height - 120,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < urunAdlari.length) {
                            final urunAdi = urunAdlari[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  urunAdi.length > 15 ? '${urunAdi.substring(0, 15)}...' : urunAdi,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // YARDIMCI METHODLAR
  // ==============================================
  
  static Color _getAsamaRengi(int index) {
    final renkler = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return renkler[index % renkler.length];
  }

  static Color _getDurumRengi(String durum) {
    switch (durum.toLowerCase()) {
      case 'tamamlandi':
      case 'tamamlandı':
        return Colors.green;
      case 'devam_ediyor':
      case 'devam ediyor':
        return Colors.orange;
      case 'beklemede':
        return Colors.red;
      case 'iptal':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  static String _formatTutar(double tutar) {
    if (tutar >= 1000000) {
      return '${(tutar / 1000000).toStringAsFixed(1)}M';
    } else if (tutar >= 1000) {
      return '${(tutar / 1000).toStringAsFixed(1)}K';
    } else {
      return tutar.toStringAsFixed(0);
    }
  }

  static Widget _buildMaliOzetKarti(String baslik, double tutar, Color renk, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: renk, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'tr_TR',
                    symbol: '₺',
                    decimalDigits: 2,
                  ).format(tutar),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: renk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StokSeviyeLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _StokSeviyeLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
