// ignore_for_file: invalid_use_of_protected_member
part of 'personel_analiz_page.dart';

/// Personel analiz - widget builders ve export
extension _WidgetsExt on _PersonelAnalizPageState {
  Widget _buildHataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(hata!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalizData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
  
  // ========== GENEL TAB ==========
  Widget _buildGenelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet Kartları
          _buildOzetKartlari(),
          const SizedBox(height: 24),
          
          // Personel Sayısı Trendi
          _buildTrendGrafik(
            'Personel Sayısı Trendi (Son 12 Ay)',
            aylikPersonelSayisi,
            'sayi',
            Colors.blue,
          ),
          const SizedBox(height: 24),
          
          // Maaş Yükü Trendi
          _buildTrendGrafik(
            'Toplam Maaş Yükü Trendi (Son 12 Ay)',
            aylikMaasTrendi,
            'tutar',
            Colors.green,
            isMoney: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOzetKartlari() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKart('Toplam Personel', toplamPersonel.toString(), Icons.people, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildKart('Aktif Personel', aktifPersonel.toString(), Icons.check_circle, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKart('Pasif Personel', pasifPersonel.toString(), Icons.cancel, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildKart('Departman Sayısı', departmanIstatistikleri.length.toString(), Icons.business, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKart('Ort. Kıdem', '${ortalamaKidem.toStringAsFixed(1)} yıl', Icons.timer, Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildKart('Ort. Net Maaş', '₺${_formatNumber(ortalamaNetMaas)}', Icons.payments, Colors.teal)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKart('Toplam Maaş Yükü', '₺${_formatNumber(toplamMaasBedeli)}', Icons.account_balance, Colors.indigo)),
            const SizedBox(width: 12),
            Expanded(child: _buildKart('Ort. Yaş', ortalamaYas > 0 ? '${ortalamaYas.toStringAsFixed(0)} yaş' : 'Veri yok', Icons.cake, Colors.pink)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildKart(String baslik, String deger, IconData icon, Color renk) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [renk.withValues(alpha: 0.1), renk.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: renk, size: 28),
            const SizedBox(height: 8),
            Text(
              deger,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: renk),
            ),
            const SizedBox(height: 4),
            Text(baslik, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendGrafik(String baslik, List<Map<String, dynamic>> data, String key, Color renk, {bool isMoney = false}) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length && index % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(data[index]['ay'], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (isMoney) {
                            return Text(_formatNumber(value), style: const TextStyle(fontSize: 10));
                          }
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        final val = entry.value[key];
                        return FlSpot(entry.key.toDouble(), (val is int ? val.toDouble() : val as double));
                      }).toList(),
                      isCurved: true,
                      color: renk,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: renk.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ========== DEPARTMAN TAB ==========
  Widget _buildDepartmanTab() {
    if (departmanIstatistikleri.isEmpty) {
      return const Center(child: Text('Departman verisi bulunamadı'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pasta Grafik
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Departman Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: departmanIstatistikleri.entries.map((entry) {
                          final index = departmanIstatistikleri.keys.toList().indexOf(entry.key);
                          final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.amber, Colors.cyan];
                          return PieChartSectionData(
                            value: (entry.value['sayi'] as int).toDouble(),
                            title: '${entry.key}\n${entry.value['sayi']}',
                            color: colors[index % colors.length],
                            radius: 90,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Departman Detay Tablosu
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Departman Detayları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Aktif', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pasif', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Toplam Maaş', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ort. Kıdem', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: departmanIstatistikleri.entries.map((entry) {
                        final sayi = entry.value['sayi'] as int;
                        final toplamKidem = entry.value['toplamKidem'] as double;
                        final ortKidem = sayi > 0 ? toplamKidem / sayi : 0;
                        
                        return DataRow(cells: [
                          DataCell(Text(entry.key)),
                          DataCell(Text(sayi.toString())),
                          DataCell(Text('${entry.value['aktif']}', style: const TextStyle(color: Colors.green))),
                          DataCell(Text('${entry.value['pasif']}', style: const TextStyle(color: Colors.red))),
                          DataCell(Text('₺${_formatNumber(entry.value['toplamMaas'] as double)}')),
                          DataCell(Text('${ortKidem.toStringAsFixed(1)} yıl')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ========== MAAŞ TAB ==========
  Widget _buildMaasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Maaş İstatistikleri
          Row(
            children: [
              Expanded(child: _buildKart('En Düşük', '₺${_formatNumber(enDusukMaas)}', Icons.arrow_downward, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('Ortalama', '₺${_formatNumber(ortalamaNetMaas)}', Icons.remove, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('Medyan', '₺${_formatNumber(medyanMaas)}', Icons.linear_scale, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('En Yüksek', '₺${_formatNumber(enYuksekMaas)}', Icons.arrow_upward, Colors.green)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Maaş Dilimleri
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maaş Dilimleri Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maasDilimleri.values.isEmpty ? 10 : (maasDilimleri.values.reduce((a, b) => a > b ? a : b) * 1.2),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final keys = maasDilimleri.keys.toList();
                                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(keys[value.toInt()], style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: maasDilimleri.entries.toList().asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value.toDouble(),
                                color: Colors.indigo,
                                width: 30,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ========== İZİN & MESAİ TAB ==========
  Widget _buildIzinMesaiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Özet Kartlar
          Row(
            children: [
              Expanded(child: _buildKart('Kullanılan İzin', '$toplamKullanilanIzin gün', Icons.beach_access, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('Kalan İzin', '$toplamKalanIzin gün', Icons.event_available, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKart('İzin Kullanım %', '${ortalamaIzinKullanimOrani.toStringAsFixed(1)}%', Icons.percent, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('Toplam Mesai', '${toplamMesaiSaati.toStringAsFixed(0)} saat', Icons.access_time, Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKart('Ort. Mesai/Kişi', '${ortalamaMesaiSaati.toStringAsFixed(1)} saat', Icons.person, Colors.teal)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),
          
          // En Çok İzin Kullananlar
          if (enCokIzinKullananlar.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.beach_access, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('En Çok İzin Kullananlar (Top 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...enCokIzinKullananlar.asMap().entries.map((entry) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text('${entry.key + 1}', style: TextStyle(color: Colors.orange.shade800)),
                        ),
                        title: Text(entry.value['ad']),
                        trailing: Text('${entry.value['gunSayisi']} gün', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // En Çok Mesai Yapanlar
          if (enCokMesaiYapanlar.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('En Çok Mesai Yapanlar (Top 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...enCokMesaiYapanlar.asMap().entries.map((entry) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text('${entry.key + 1}', style: TextStyle(color: Colors.purple.shade800)),
                        ),
                        title: Text(entry.value['ad']),
                        trailing: Text('${(entry.value['saat'] as double).toStringAsFixed(1)} saat', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ========== PERFORMANS TAB ==========
  Widget _buildPerformansTab() {
    if (personelPerformans.isEmpty) {
      return const Center(child: Text('Performans verisi bulunamadı'));
    }
    
    // Performans dağılımı hesapla
    final yuksek = personelPerformans.where((p) => (p['puan'] as double) >= 80).length;
    final orta = personelPerformans.where((p) => (p['puan'] as double) >= 60 && (p['puan'] as double) < 80).length;
    final dusuk = personelPerformans.where((p) => (p['puan'] as double) < 60).length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performans Özeti
          Row(
            children: [
              Expanded(child: _buildKart('Yüksek', yuksek.toString(), Icons.sentiment_very_satisfied, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('Orta', orta.toString(), Icons.sentiment_neutral, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildKart('Düşük', dusuk.toString(), Icons.sentiment_dissatisfied, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Performans Listesi
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personel Performans Sıralaması', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Departman', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Puan', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Durum', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Çalışma Günü', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Devamsızlık', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Fazla Mesai', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: personelPerformans.asMap().entries.take(20).map((entry) {
                        final p = entry.value;
                        return DataRow(cells: [
                          DataCell(Text('${entry.key + 1}')),
                          DataCell(Text(p['ad'], style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(p['departman'])),
                          DataCell(Text((p['puan'] as double).toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, color: p['renk'] as Color))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (p['renk'] as Color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p['durum'], style: TextStyle(color: p['renk'] as Color, fontWeight: FontWeight.bold, fontSize: 12)),
                          )),
                          DataCell(Text('${p['calismaGunu']} gün')),
                          DataCell(Text('${p['devamsizlik']}', style: TextStyle(color: (p['devamsizlik'] as int) > 0 ? Colors.red : Colors.grey))),
                          DataCell(Text('${(p['fazlaMesai'] as double).toStringAsFixed(1)} saat')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
  
  void _exportData(String type) async {
    try {
      String csvContent = '';
      String fileName = '';
      
      switch (type) {
        case 'csv_ozet':
          fileName = 'personel_ozet_rapor_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          csvContent = _generateOzetCsv();
          break;
        case 'csv_personel':
          fileName = 'personel_listesi_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          csvContent = await _generatePersonelCsv();
          break;
        case 'csv_performans':
          fileName = 'personel_performans_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          csvContent = _generatePerformansCsv();
          break;
      }
      
      // Web için farklı bir yaklaşım gerekebilir
      // Şimdilik sadece bilgi mesajı gösterelim
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileName hazırlanıyor...'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      
      // Konsola yazdır (debug için)
      debugPrint('=== $fileName ===');
      debugPrint(csvContent);
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Dışa aktarma hatası: $e');
    }
  }
  
  String _generateOzetCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Kategori,Değer');
    buffer.writeln('Toplam Personel,$toplamPersonel');
    buffer.writeln('Aktif Personel,$aktifPersonel');
    buffer.writeln('Pasif Personel,$pasifPersonel');
    buffer.writeln('Departman Sayısı,${departmanIstatistikleri.length}');
    buffer.writeln('Ortalama Kıdem,${ortalamaKidem.toStringAsFixed(1)} yıl');
    buffer.writeln('Ortalama Net Maaş,${ortalamaNetMaas.toStringAsFixed(0)} TL');
    buffer.writeln('Toplam Maaş Yükü,${toplamMaasBedeli.toStringAsFixed(0)} TL');
    buffer.writeln('En Düşük Maaş,${enDusukMaas.toStringAsFixed(0)} TL');
    buffer.writeln('En Yüksek Maaş,${enYuksekMaas.toStringAsFixed(0)} TL');
    buffer.writeln('Medyan Maaş,${medyanMaas.toStringAsFixed(0)} TL');
    buffer.writeln('Toplam İzin Kullanımı,$toplamKullanilanIzin gün');
    buffer.writeln('Toplam Mesai Saati,${toplamMesaiSaati.toStringAsFixed(0)} saat');
    return buffer.toString();
  }
  
  Future<String> _generatePersonelCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('Ad Soyad,TCKN,Pozisyon,Departman,Brüt Maaş,Net Maaş,İşe Başlangıç,Durum');
    
    final client = Supabase.instance.client;
    final personelRes = await client.from(DbTables.personel).select('*').eq('firma_id', TenantManager.instance.requireFirmaId);
    
    for (final p in personelRes) {
      final ad = '${p['ad'] ?? ''} ${p['soyad'] ?? ''}'.trim();
      final tckn = p['tckn'] ?? '';
      final pozisyon = p['pozisyon'] ?? '';
      final departman = p['departman'] ?? '';
      final brutMaas = p['brut_maas'] ?? '';
      final netMaas = p['net_maas'] ?? '';
      final iseBaslangic = p['ise_baslangic'] ?? '';
      final durum = p['durum'] ?? 'aktif';
      
      buffer.writeln('"$ad","$tckn","$pozisyon","$departman",$brutMaas,$netMaas,"$iseBaslangic","$durum"');
    }
    
    return buffer.toString();
  }
  
  String _generatePerformansCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Sıra,Ad Soyad,Departman,Puan,Durum,Çalışma Günü,Devamsızlık,Fazla Mesai');
    
    for (var i = 0; i < personelPerformans.length; i++) {
      final p = personelPerformans[i];
      buffer.writeln('${i + 1},"${p['ad']}","${p['departman']}",${(p['puan'] as double).toStringAsFixed(0)},"${p['durum']}",${p['calismaGunu']},${p['devamsizlik']},${(p['fazlaMesai'] as double).toStringAsFixed(1)}');
    }
    
    return buffer.toString();
  }
}
