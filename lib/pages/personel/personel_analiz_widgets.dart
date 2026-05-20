// ignore_for_file: invalid_use_of_protected_member
part of 'personel_analiz_page.dart';

/// Personel analiz - widget builders ve export
extension _WidgetsExt on _PersonelAnalizPageState {
  Widget _buildErpHeader() {
    final aktifOran =
        toplamPersonel == 0 ? 0.0 : (aktifPersonel / toplamPersonel) * 100;
    final kisiBasiMaliyet =
        aktifPersonel == 0 ? 0.0 : toplamMaasBedeli / aktifPersonel;
    final donemMetni = raporTipi == 'monthly'
        ? '${_ayAdi(seciliAy)} $seciliYil'
        : raporTipi == 'yearly'
            ? '$seciliYil'
            : raporTipi == 'custom' &&
                    baslangicTarihFiltresi != null &&
                    bitisTarihFiltresi != null
                ? '${DateFormat('dd.MM.yyyy').format(baslangicTarihFiltresi!)} - ${DateFormat('dd.MM.yyyy').format(bitisTarihFiltresi!)}'
                : 'Son 12 ay';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E1EC)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 880;
          final baslik = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personel Raporlama ve Analiz',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dönem: $donemMetni • Bordro, izin, mesai ve ekip kapasitesi',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final kpis = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderMetric(
                  'Aktif oran', '${aktifOran.toStringAsFixed(1)}%'),
              _buildHeaderMetric(
                  'Kişi başı maliyet', '₺${_formatNumber(kisiBasiMaliyet)}'),
              _buildHeaderMetric('Mesai/kişi',
                  '${ortalamaMesaiSaati.toStringAsFixed(1)} saat'),
              _buildHeaderMetric('İzin kullanım',
                  '${ortalamaIzinKullanimOrani.toStringAsFixed(1)}%'),
            ],
          );

          if (dar) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                baslik,
                const SizedBox(height: 14),
                kpis,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: baslik),
              const SizedBox(width: 16),
              kpis,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOzetKartlari(),
          const SizedBox(height: 16),
          _buildYonetimUyariPaneli(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final dar = constraints.maxWidth < 980;
              final trendler = [
                Expanded(
                  child: _buildTrendGrafik(
                    'Personel Kadro Trendi',
                    aylikPersonelSayisi,
                    'sayi',
                    const Color(0xFF2563EB),
                  ),
                ),
                Expanded(
                  child: _buildTrendGrafik(
                    'Bordro Yükü Trendi',
                    aylikMaasTrendi,
                    'tutar',
                    const Color(0xFF0F9D58),
                    isMoney: true,
                  ),
                ),
              ];
              if (dar) {
                return Column(
                  children: [
                    trendler.first,
                    const SizedBox(height: 16),
                    trendler.last,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  trendler.first,
                  const SizedBox(width: 16),
                  trendler.last,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOzetKartlari() {
    final aktifOran =
        toplamPersonel == 0 ? 0.0 : (aktifPersonel / toplamPersonel) * 100;
    final kisiBasiMaliyet =
        aktifPersonel == 0 ? 0.0 : toplamMaasBedeli / aktifPersonel;
    final kartlar = [
      _KpiData('Toplam Personel', toplamPersonel.toString(), 'Kadro',
          Icons.people_alt_outlined, const Color(0xFF2563EB)),
      _KpiData(
          'Aktif Personel',
          aktifPersonel.toString(),
          '${aktifOran.toStringAsFixed(1)}%',
          Icons.verified_user_outlined,
          const Color(0xFF0F9D58)),
      _KpiData('Pasif Personel', pasifPersonel.toString(), 'Takip',
          Icons.person_off_outlined, const Color(0xFFDC2626)),
      _KpiData('Departman', departmanIstatistikleri.length.toString(),
          'Organizasyon', Icons.apartment_outlined, const Color(0xFFF57C00)),
      _KpiData(
          'Toplam Bordro Yükü',
          '₺${_formatNumber(toplamMaasBedeli)}',
          'Aylık maliyet',
          Icons.account_balance_outlined,
          const Color(0xFF4F46E5)),
      _KpiData('Kişi Başı Maliyet', '₺${_formatNumber(kisiBasiMaliyet)}',
          'Aktif kadro', Icons.payments_outlined, const Color(0xFF0891B2)),
      _KpiData('Ortalama Kıdem', '${ortalamaKidem.toStringAsFixed(1)} yıl',
          'Tecrübe', Icons.history_outlined, const Color(0xFF7C3AED)),
      _KpiData(
          'Ortalama Yaş',
          ortalamaYas > 0
              ? '${ortalamaYas.toStringAsFixed(0)} yaş'
              : 'Veri yok',
          'Demografi',
          Icons.cake_outlined,
          const Color(0xFFBE185D)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width < 620
            ? width
            : width < 1040
                ? (width - 12) / 2
                : (width - 36) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kartlar
              .map((item) =>
                  SizedBox(width: itemWidth, child: _buildKpiKart(item)))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiKart(_KpiData item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(item.footnote,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKart(String baslik, String deger, IconData icon, Color renk) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: renk, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(deger,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: renk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYonetimUyariPaneli() {
    final uyarilar = <_AlertData>[];
    if (pasifPersonel > 0) {
      uyarilar.add(_AlertData(Icons.person_off_outlined, 'Pasif personel',
          '$pasifPersonel kayıt pasif durumda.', const Color(0xFFDC2626)));
    }
    if (ortalamaIzinKullanimOrani >= 80) {
      uyarilar.add(_AlertData(
          Icons.beach_access_outlined,
          'İzin yükü yüksek',
          'Kullanım oranı ${ortalamaIzinKullanimOrani.toStringAsFixed(1)}%.',
          const Color(0xFFF57C00)));
    }
    if (ortalamaMesaiSaati >= 20) {
      uyarilar.add(_AlertData(
          Icons.timer_outlined,
          'Mesai yoğunluğu',
          'Kişi başı ${ortalamaMesaiSaati.toStringAsFixed(1)} saat.',
          const Color(0xFF7C3AED)));
    }
    if (toplamKalanIzin <= aktifPersonel && aktifPersonel > 0) {
      uyarilar.add(_AlertData(Icons.event_busy_outlined, 'Kalan izin düşük',
          'Toplam kalan izin $toplamKalanIzin gün.', const Color(0xFF0891B2)));
    }
    if (uyarilar.isEmpty) {
      uyarilar.add(const _AlertData(
          Icons.check_circle_outline,
          'Kritik uyarı yok',
          'Seçili dönem için takip gerektiren ana risk görünmüyor.',
          Color(0xFF0F9D58)));
    }

    final departmanlar = departmanIstatistikleri.entries.toList()
      ..sort(
          (a, b) => (b.value['sayi'] as int).compareTo(a.value['sayi'] as int));

    return LayoutBuilder(
      builder: (context, constraints) {
        final dar = constraints.maxWidth < 920;
        final riskPanel = _buildErpPanel(
          title: 'Yönetim Uyarıları',
          subtitle: 'Aksiyon gerektiren İK göstergeleri',
          child: Column(
            children: uyarilar
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildAlertRow(item),
                    ))
                .toList(),
          ),
        );
        final departmanPanel = _buildErpPanel(
          title: 'Departman Yükü',
          subtitle: 'En yüksek kadro ve maliyet yoğunluğu',
          child: departmanlar.isEmpty
              ? const Text('Departman verisi bulunamadı',
                  style: TextStyle(color: Color(0xFF64748B)))
              : Column(
                  children: departmanlar.take(5).map((entry) {
                    final sayi = entry.value['sayi'] as int;
                    final toplamMaas = entry.value['toplamMaas'] as double;
                    final pay =
                        toplamPersonel == 0 ? 0.0 : sayi / toplamPersonel;
                    return _buildDepartmentLoadRow(
                      entry.key,
                      sayi,
                      toplamMaas,
                      pay,
                    );
                  }).toList(),
                ),
        );

        if (dar) {
          return Column(
            children: [
              riskPanel,
              const SizedBox(height: 16),
              departmanPanel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: riskPanel),
            const SizedBox(width: 16),
            Expanded(child: departmanPanel),
          ],
        );
      },
    );
  }

  Widget _buildErpPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildAlertRow(_AlertData item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(item.message,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentLoadRow(
      String departman, int sayi, double toplamMaas, double oran) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(departman,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
              ),
              Text('$sayi kişi • ₺${_formatNumber(toplamMaas)}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: oran.clamp(0, 1),
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendGrafik(
      String baslik, List<Map<String, dynamic>> data, String key, Color renk,
      {bool isMoney = false}) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          if (index >= 0 &&
                              index < data.length &&
                              index % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(data[index]['ay'],
                                  style: const TextStyle(fontSize: 10)),
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
                            return Text(_formatNumber(value),
                                style: const TextStyle(fontSize: 10));
                          }
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        final val = entry.value[key];
                        return FlSpot(entry.key.toDouble(),
                            (val is int ? val.toDouble() : val as double));
                      }).toList(),
                      isCurved: true,
                      color: renk,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: renk.withValues(alpha: 0.1)),
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
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 240,
          child: Center(child: Text('Departman verisi bulunamadı')),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pasta Grafik
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Departman Dağılımı',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: departmanIstatistikleri.entries.map((entry) {
                          final index = departmanIstatistikleri.keys
                              .toList()
                              .indexOf(entry.key);
                          final colors = [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.red,
                            Colors.teal,
                            Colors.amber,
                            Colors.cyan
                          ];
                          return PieChartSectionData(
                            value: (entry.value['sayi'] as int).toDouble(),
                            title: '${entry.key}\n${entry.value['sayi']}',
                            color: colors[index % colors.length],
                            radius: 90,
                            titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Departman Detayları',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                            label: Text('Departman',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Personel',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Aktif',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Pasif',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Toplam Maaş',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Ort. Kıdem',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: departmanIstatistikleri.entries.map((entry) {
                        final sayi = entry.value['sayi'] as int;
                        final toplamKidem =
                            entry.value['toplamKidem'] as double;
                        final ortKidem = sayi > 0 ? toplamKidem / sayi : 0;

                        return DataRow(cells: [
                          DataCell(Text(entry.key)),
                          DataCell(Text(sayi.toString())),
                          DataCell(Text('${entry.value['aktif']}',
                              style: const TextStyle(color: Colors.green))),
                          DataCell(Text('${entry.value['pasif']}',
                              style: const TextStyle(color: Colors.red))),
                          DataCell(Text(
                              '₺${_formatNumber(entry.value['toplamMaas'] as double)}')),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Maaş İstatistikleri
          Row(
            children: [
              Expanded(
                  child: _buildKart(
                      'En Düşük',
                      '₺${_formatNumber(enDusukMaas)}',
                      Icons.arrow_downward,
                      Colors.red)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart(
                      'Ortalama',
                      '₺${_formatNumber(ortalamaNetMaas)}',
                      Icons.remove,
                      Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart('Medyan', '₺${_formatNumber(medyanMaas)}',
                      Icons.linear_scale, Colors.purple)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart(
                      'En Yüksek',
                      '₺${_formatNumber(enYuksekMaas)}',
                      Icons.arrow_upward,
                      Colors.green)),
            ],
          ),
          const SizedBox(height: 24),

          // Maaş Dilimleri
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maaş Dilimleri Dağılımı',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maasDilimleri.values.isEmpty
                            ? 10
                            : (maasDilimleri.values
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final keys = maasDilimleri.keys.toList();
                                if (value.toInt() >= 0 &&
                                    value.toInt() < keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(keys[value.toInt()],
                                        style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: true)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: maasDilimleri.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Özet Kartlar
          Row(
            children: [
              Expanded(
                  child: _buildKart(
                      'Kullanılan İzin',
                      '$toplamKullanilanIzin gün',
                      Icons.beach_access,
                      Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart('Kalan İzin', '$toplamKalanIzin gün',
                      Icons.event_available, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildKart(
                      'İzin Kullanım %',
                      '${ortalamaIzinKullanimOrani.toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart(
                      'Toplam Mesai',
                      '${toplamMesaiSaati.toStringAsFixed(0)} saat',
                      Icons.access_time,
                      Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildKart(
                      'Ort. Mesai/Kişi',
                      '${ortalamaMesaiSaati.toStringAsFixed(1)} saat',
                      Icons.person,
                      Colors.teal)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),

          // En Çok İzin Kullananlar
          if (enCokIzinKullananlar.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.beach_access, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('En Çok İzin Kullananlar (Top 5)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...enCokIzinKullananlar.asMap().entries.map((entry) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text('${entry.key + 1}',
                              style: TextStyle(color: Colors.orange.shade800)),
                        ),
                        title: Text(entry.value['ad']),
                        trailing: Text('${entry.value['gunSayisi']} gün',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('En Çok Mesai Yapanlar (Top 5)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...enCokMesaiYapanlar.asMap().entries.map((entry) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text('${entry.key + 1}',
                              style: TextStyle(color: Colors.purple.shade800)),
                        ),
                        title: Text(entry.value['ad']),
                        trailing: Text(
                            '${(entry.value['saat'] as double).toStringAsFixed(1)} saat',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple)),
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
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 240,
          child: Center(child: Text('Performans verisi bulunamadı')),
        ),
      );
    }

    // Performans dağılımı hesapla
    final yuksek =
        personelPerformans.where((p) => (p['puan'] as double) >= 80).length;
    final orta = personelPerformans
        .where((p) => (p['puan'] as double) >= 60 && (p['puan'] as double) < 80)
        .length;
    final dusuk =
        personelPerformans.where((p) => (p['puan'] as double) < 60).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performans Özeti
          Row(
            children: [
              Expanded(
                  child: _buildKart('Yüksek', yuksek.toString(),
                      Icons.sentiment_very_satisfied, Colors.green)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart('Orta', orta.toString(),
                      Icons.sentiment_neutral, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildKart('Düşük', dusuk.toString(),
                      Icons.sentiment_dissatisfied, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),

          // Performans Listesi
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personel Performans Sıralaması',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                            label: Text('#',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Personel',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Departman',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Puan',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Durum',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Çalışma Günü',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Devamsızlık',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Fazla Mesai',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: personelPerformans
                          .asMap()
                          .entries
                          .take(20)
                          .map((entry) {
                        final p = entry.value;
                        return DataRow(cells: [
                          DataCell(Text('${entry.key + 1}')),
                          DataCell(Text(p['ad'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(p['departman'])),
                          DataCell(Text(
                              (p['puan'] as double).toStringAsFixed(0),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p['renk'] as Color))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  (p['renk'] as Color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p['durum'],
                                style: TextStyle(
                                    color: p['renk'] as Color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          )),
                          DataCell(Text('${p['calismaGunu']} gün')),
                          DataCell(Text('${p['devamsizlik']}',
                              style: TextStyle(
                                  color: (p['devamsizlik'] as int) > 0
                                      ? Colors.red
                                      : Colors.grey))),
                          DataCell(Text(
                              '${(p['fazlaMesai'] as double).toStringAsFixed(1)} saat')),
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

  String _ayAdi(int ay) {
    const aylar = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    if (ay < 1 || ay > 12) return '';
    return aylar[ay];
  }

  void _exportData(String type) async {
    try {
      String csvContent = '';
      String fileName = '';

      switch (type) {
        case 'csv_ozet':
          fileName =
              'personel_ozet_rapor_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          csvContent = _generateOzetCsv();
          break;
        case 'csv_personel':
          fileName =
              'personel_listesi_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          csvContent = await _generatePersonelCsv();
          break;
        case 'csv_performans':
          fileName =
              'personel_performans_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
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
    buffer
        .writeln('Ortalama Net Maaş,${ortalamaNetMaas.toStringAsFixed(0)} TL');
    buffer
        .writeln('Toplam Maaş Yükü,${toplamMaasBedeli.toStringAsFixed(0)} TL');
    buffer.writeln('En Düşük Maaş,${enDusukMaas.toStringAsFixed(0)} TL');
    buffer.writeln('En Yüksek Maaş,${enYuksekMaas.toStringAsFixed(0)} TL');
    buffer.writeln('Medyan Maaş,${medyanMaas.toStringAsFixed(0)} TL');
    buffer.writeln('Toplam İzin Kullanımı,$toplamKullanilanIzin gün');
    buffer.writeln(
        'Toplam Mesai Saati,${toplamMesaiSaati.toStringAsFixed(0)} saat');
    return buffer.toString();
  }

  Future<String> _generatePersonelCsv() async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Ad Soyad,TCKN,Pozisyon,Departman,Brüt Maaş,Net Maaş,İşe Başlangıç,Durum');

    final client = Supabase.instance.client;
    final personelRes = await client
        .from(DbTables.personel)
        .select('*')
        .eq('firma_id', TenantManager.instance.requireFirmaId);

    for (final p in personelRes) {
      final ad = '${p['ad'] ?? ''} ${p['soyad'] ?? ''}'.trim();
      final tckn = p['tckn'] ?? '';
      final pozisyon = p['pozisyon'] ?? '';
      final departman = p['departman'] ?? '';
      final brutMaas = p['brut_maas'] ?? '';
      final netMaas = p['net_maas'] ?? '';
      final iseBaslangic = p['ise_baslangic'] ?? '';
      final durum = p['durum'] ?? 'aktif';

      buffer.writeln(
          '"$ad","$tckn","$pozisyon","$departman",$brutMaas,$netMaas,"$iseBaslangic","$durum"');
    }

    return buffer.toString();
  }

  String _generatePerformansCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Sıra,Ad Soyad,Departman,Puan,Durum,Çalışma Günü,Devamsızlık,Fazla Mesai');

    for (var i = 0; i < personelPerformans.length; i++) {
      final p = personelPerformans[i];
      buffer.writeln(
          '${i + 1},"${p['ad']}","${p['departman']}",${(p['puan'] as double).toStringAsFixed(0)},"${p['durum']}",${p['calismaGunu']},${p['devamsizlik']},${(p['fazlaMesai'] as double).toStringAsFixed(1)}');
    }

    return buffer.toString();
  }
}

class _KpiData {
  final String title;
  final String value;
  final String footnote;
  final IconData icon;
  final Color color;

  const _KpiData(
    this.title,
    this.value,
    this.footnote,
    this.icon,
    this.color,
  );
}

class _AlertData {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _AlertData(this.icon, this.title, this.message, this.color);
}
