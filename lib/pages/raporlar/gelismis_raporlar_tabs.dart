// ignore_for_file: invalid_use_of_protected_member
part of 'gelismis_raporlar_page.dart';

/// Sekme içerik widget'ları for _GelismisRaporlarPageState.
extension _TabsExt on _GelismisRaporlarPageState {
  Widget _buildOzetTab() {
    final ozet = _hesaplaFiltrelenmisOzet();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth < 900;
          
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // AKTİF FİLTRE BİLGİSİ
            if (secilenMarka != null || secilenModel != null || secilenYil != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: isMobile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.filter_alt, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Aktif Filtre', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${secilenMarka ?? 'Tüm Markalar'} / ${secilenModel ?? 'Tüm Modeller'} / ${secilenYil ?? 'Tüm Yıllar'}',
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text('${ozet['toplamUrun']} ürün', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.filter_alt, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtre: ${secilenMarka ?? 'Tüm Markalar'} / ${secilenModel ?? 'Tüm Modeller'} / ${secilenYil ?? 'Tüm Yıllar'}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        Text('${ozet['toplamUrun']} ürün', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
              ),
            
            // FİLTRELENMİŞ ÖZET KARTLARI
            if (isMobile) ...[
              // Mobil: 2'li grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.3,
                children: [
                  _buildKPICard('Toplam Ürün', '${ozet['toplamUrun']}', Icons.inventory_2, Colors.blue),
                  _buildKPICard('Toplam Adet', '${ozet['toplamAdet']}', Icons.shopping_cart, Colors.purple),
                  _buildKPICard('Toplam Maliyet', currencyFormat.format(ozet['toplamMaliyet']), Icons.money_off, Colors.red),
                  _buildKPICard('Toplam Satış', currencyFormat.format(ozet['toplamSatis']), Icons.point_of_sale, Colors.green),
                  _buildKPICard('Net Kâr', currencyFormat.format(ozet['kar']), Icons.trending_up, (ozet['kar'] as double) >= 0 ? Colors.green : Colors.red),
                  _buildKPICard('Kâr Marjı', '%${(ozet['karMarji'] as double).toStringAsFixed(1)}', Icons.pie_chart, Colors.orange),
                  _buildKPICard('Ort. Sipariş Tutarı', currencyFormat.format(ozet['ortSiparisTutari']), Icons.receipt_long, Colors.indigo),
                  _buildKPICard('Ort. Birim Maliyet', currencyFormat.format(ozet['ortBirimMaliyet']), Icons.production_quantity_limits, Colors.brown),
                ],
              ),
            ] else if (isTablet) ...[
              // Tablet: 3'lü grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildKPICard('Toplam Ürün', '${ozet['toplamUrun']}', Icons.inventory_2, Colors.blue),
                  _buildKPICard('Sipariş Adedi', '${ozet['toplamAdet']}', Icons.shopping_cart, Colors.purple),
                  _buildKPICard('Yüklenen Model', '${ozet['yuklenenModelSayisi']}/${ozet['toplamUrun']}', Icons.local_shipping, Colors.teal),
                  _buildKPICard('Yüklenen Adet', '${ozet['toplamYuklenenAdet']}', Icons.check_circle, Colors.cyan),
                  _buildKPICard('Toplam Maliyet', currencyFormat.format(ozet['toplamMaliyet']), Icons.money_off, Colors.red),
                  _buildKPICard('Toplam Satış', currencyFormat.format(ozet['toplamSatis']), Icons.point_of_sale, Colors.green),
                  _buildKPICard('Net Kâr', currencyFormat.format(ozet['kar']), Icons.trending_up, (ozet['kar'] as double) >= 0 ? Colors.green : Colors.red),
                  _buildKPICard('Kâr Marjı', '%${(ozet['karMarji'] as double).toStringAsFixed(1)}', Icons.pie_chart, Colors.orange),
                  _buildKPICard('Ort. Sipariş Tutarı', currencyFormat.format(ozet['ortSiparisTutari']), Icons.receipt_long, Colors.indigo),
                  _buildKPICard('Ort. Birim Maliyet', currencyFormat.format(ozet['ortBirimMaliyet']), Icons.production_quantity_limits, Colors.brown),
                  _buildKPICard('Ort. Birim Satış', currencyFormat.format(ozet['ortBirimSatis']), Icons.sell, Colors.amber),
                ],
              ),
            ] else ...[
              // Masaüstü: Row düzeni
              Row(children: [
                Expanded(child: _buildKPICard('Toplam Ürün', '${ozet['toplamUrun']}', Icons.inventory_2, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard('Sipariş Adedi', '${ozet['toplamAdet']}', Icons.shopping_cart, Colors.purple)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildKPICard('Yüklenen Model', '${ozet['yuklenenModelSayisi']}/${ozet['toplamUrun']}', Icons.local_shipping, Colors.teal)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard('Yüklenen Adet', '${ozet['toplamYuklenenAdet']}', Icons.check_circle, Colors.cyan)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildKPICard('Toplam Maliyet', currencyFormat.format(ozet['toplamMaliyet']), Icons.money_off, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard('Toplam Satış', currencyFormat.format(ozet['toplamSatis']), Icons.point_of_sale, Colors.green)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildKPICard('Net Kâr', currencyFormat.format(ozet['kar']), Icons.trending_up, (ozet['kar'] as double) >= 0 ? Colors.green : Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard('Kâr Marjı', '%${(ozet['karMarji'] as double).toStringAsFixed(1)}', Icons.pie_chart, Colors.orange)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildKPICard('Ort. Sipariş Tutarı', currencyFormat.format(ozet['ortSiparisTutari']), Icons.receipt_long, Colors.indigo)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard('Ort. Birim Maliyet', currencyFormat.format(ozet['ortBirimMaliyet']), Icons.production_quantity_limits, Colors.brown)),
                const SizedBox(width: 12),
                Expanded(child: _buildKPICard('Ort. Birim Satış', currencyFormat.format(ozet['ortBirimSatis']), Icons.sell, Colors.teal)),
              ]),
            ],
            
            // DEPO SATIŞ BİLGİSİ
            if ((ozet['depoSatisGeliri'] as double) > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: isMobile
                  ? Column(
                      children: [
                        Icon(Icons.store, color: Colors.green[700], size: 40),
                        const SizedBox(height: 12),
                        const Text('Depo Satışları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${ozet['depoSatilanAdet']} adet ürün satıldı'),
                        Text(currencyFormat.format(ozet['depoSatisGeliri']), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.store, color: Colors.green[700], size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Depo Satışları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${ozet['depoSatilanAdet']} adet ürün satıldı'),
                              Text(currencyFormat.format(ozet['depoSatisGeliri']), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
            ],
        
            const SizedBox(height: 24),
            _buildSectionTitle('Marka Bazlı Sipariş Dağılımı'),
            const SizedBox(height: 8),
            _buildFiltrelenmisMarkaChart(),
            const SizedBox(height: 24),
            
            // RENK BAZLI ANALİZ
            _buildSectionTitle('Renk Bazlı Analiz'),
            const SizedBox(height: 8),
            _buildRenkAnaliziWidget(),
            const SizedBox(height: 24),
            
            // MALİYET DAĞILIMI
            _buildSectionTitle('Maliyet Dağılımı'),
            const SizedBox(height: 8),
            _buildMaliyetDagilimiWidget(),
            const SizedBox(height: 24),
            
            // STOK DEVİR HIZI
            _buildSectionTitle('Stok Devir Hızı'),
            const SizedBox(height: 8),
            _buildStokDevirWidget(),
            const SizedBox(height: 24),
            
            // SEZON ANALİZİ
            _buildSectionTitle('Sezon Analizi'),
            const SizedBox(height: 8),
            _buildSezonAnaliziWidget(),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Model Bazlı Kâr/Zarar'),
            const SizedBox(height: 8),
            _buildModelKarZararListesi(),
          ]);
        },
      ),
    );
  }

  // RENK ANALİZİ WİDGET
  Widget _buildRenkAnaliziWidget() {
    final renkler = _hesaplaRenkAnalizi();
    
    if (renkler.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Renk verisi bulunamadı'))));
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;
            
            return Column(
              children: renkler.entries.take(8).map((entry) {
                final maxAdet = renkler.entries.first.value['adet'] as int;
                final yuzde = maxAdet > 0 ? (entry.value['adet'] as int) / maxAdet : 0.0;
                
                if (isMobile) {
                  // Mobil: Dikey düzen
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _getRenkFromName(entry.key),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('${entry.value['adet']} adet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: yuzde,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(_getRenkFromName(entry.key)),
                            minHeight: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            currencyFormat.format(entry.value['tutar']),
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Masaüstü: Yatay düzen
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getRenkFromName(entry.key),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 80, child: Text(entry.key, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: yuzde,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(_getRenkFromName(entry.key)),
                            minHeight: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${entry.value['adet']} adet',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          currencyFormat.format(entry.value['tutar']),
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
  
  Color _getRenkFromName(String renkAdi) {
    final lowerName = renkAdi.toLowerCase();
    if (lowerName.contains('siyah') || lowerName.contains('black')) return Colors.black;
    if (lowerName.contains('beyaz') || lowerName.contains('white')) return Colors.grey[300]!;
    if (lowerName.contains('kırmızı') || lowerName.contains('red')) return Colors.red;
    if (lowerName.contains('mavi') || lowerName.contains('blue')) return Colors.blue;
    if (lowerName.contains('yeşil') || lowerName.contains('green')) return Colors.green;
    if (lowerName.contains('sarı') || lowerName.contains('yellow')) return Colors.yellow;
    if (lowerName.contains('turuncu') || lowerName.contains('orange')) return Colors.orange;
    if (lowerName.contains('mor') || lowerName.contains('purple')) return Colors.purple;
    if (lowerName.contains('pembe') || lowerName.contains('pink')) return Colors.pink;
    if (lowerName.contains('gri') || lowerName.contains('grey') || lowerName.contains('gray')) return Colors.grey;
    if (lowerName.contains('kahve') || lowerName.contains('brown')) return Colors.brown;
    if (lowerName.contains('bej') || lowerName.contains('beige')) return const Color(0xFFF5F5DC);
    if (lowerName.contains('lacivert') || lowerName.contains('navy')) return const Color(0xFF000080);
    if (lowerName.contains('ekru') || lowerName.contains('ecru')) return const Color(0xFFF5F5E1);
    return Colors.blueGrey;
  }

  // MALİYET DAĞILIMI WİDGET
  Widget _buildMaliyetDagilimiWidget() {
    final dagilim = _hesaplaMaliyetDagilimi();
    
    if ((dagilim['toplam'] as double) == 0) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Maliyet verisi bulunamadı'))));
    }
    
    final items = [
      {'ad': 'İplik', 'tutar': dagilim['iplik'], 'oran': dagilim['iplikOran'], 'renk': Colors.blue},
      {'ad': 'İşçilik', 'tutar': dagilim['iscilik'], 'oran': dagilim['iscilikOran'], 'renk': Colors.green},
      {'ad': 'Aksesuar', 'tutar': dagilim['aksesuar'], 'oran': dagilim['aksesuarOran'], 'renk': Colors.orange},
      {'ad': 'Genel Gider', 'tutar': dagilim['genelGider'], 'oran': dagilim['genelGiderOran'], 'renk': Colors.purple},
    ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 450;
            
            return Column(
              children: [
                if (isMobile)
                  // Mobil: 2x2 grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: items.map((item) => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item['renk'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (item['renk'] as Color).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '%${(item['oran'] as double).toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: item['renk'] as Color, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(item['ad'] as String, style: TextStyle(fontWeight: FontWeight.w500, color: item['renk'] as Color, fontSize: 12)),
                          Text(currencyFormat.format(item['tutar']), style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    )).toList(),
                  )
                else
                  // Masaüstü: Row düzeni
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: items.map((item) => Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: (item['renk'] as Color).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '%${(item['oran'] as double).toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: item['renk'] as Color),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item['ad'] as String, style: TextStyle(fontWeight: FontWeight.w500, color: item['renk'] as Color)),
                        Text(currencyFormat.format(item['tutar']), style: const TextStyle(fontSize: 12)),
                      ],
                    )).toList(),
                  ),
                const SizedBox(height: 16),
                Container(
                  height: 20,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: items.map((item) => Expanded(
                        flex: ((item['oran'] as double) * 10).round().clamp(1, 1000),
                        child: Container(color: item['renk'] as Color),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toplam: ${currencyFormat.format(dagilim['toplam'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // STOK DEVİR HIZI WİDGET
  Widget _buildStokDevirWidget() {
    final devir = _hesaplaStokDevirHizi();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;
            
            final items = [
              _buildDevirKart(
                icon: Icons.timer,
                color: Colors.blue,
                value: (devir['ortalamaSure'] as double).toStringAsFixed(1),
                label: 'Gün (Ortalama)',
                isValueLarge: true,
              ),
              _buildDevirKart(
                icon: Icons.flash_on,
                color: Colors.green,
                value: devir['enHizli'] as String,
                label: 'En Hızlı Satan',
                isValueLarge: false,
              ),
              _buildDevirKart(
                icon: Icons.hourglass_bottom,
                color: Colors.orange,
                value: devir['enYavas'] as String,
                label: 'En Yavaş Satan',
                isValueLarge: false,
              ),
            ];
            
            if (isMobile) {
              return Column(
                children: items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: item,
                )).toList(),
              );
            }
            
            return Row(
              children: items.map((item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: item,
                ),
              )).toList(),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildDevirKart({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required bool isValueLarge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isValueLarge ? 26 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  // SEZON ANALİZİ WİDGET
  Widget _buildSezonAnaliziWidget() {
    final sezon = _hesaplaSezonAnalizi();
    
    if (sezon.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Sezon verisi bulunamadı'))));
    }
    
    final maxAdet = sezon.values.map((e) => e['adet'] as int).reduce((a, b) => a > b ? a : b);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sezon.entries.map((entry) {
                  final yukseklik = maxAdet > 0 ? ((entry.value['adet'] as int) / maxAdet) * 100 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${entry.value['adet']}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: yukseklik,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              entry.key.substring(0, 3),
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sezon.entries.map((entry) {
                      try {
                        final tutarDynamic = entry.value['tutar'];
                        final tutar = tutarDynamic is double 
                          ? tutarDynamic 
                          : (tutarDynamic is int ? tutarDynamic.toDouble() : 0.0);
                        final formattedTutar = currencyFormat.format(tutar.toInt());
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue[200]!, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedTutar,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrelenmisMarkaChart() {
    // Filtrelenmiş verilerden marka dağılımı
    final markaData = <String, int>{};
    for (var item in filtrelenmisModeller) {
      final marka = item['marka']?.toString() ?? 'Diğer';
      final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
      markaData[marka] = (markaData[marka] ?? 0) + adet;
    }
    
    if (markaData.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Veri bulunamadı'))));
    }
    
    final sortedData = markaData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxAdet = sortedData.first.value;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 450;
            
            return Column(
              children: sortedData.take(10).map((entry) {
                final yuzde = maxAdet > 0 ? entry.value / maxAdet : 0.0;
                
                if (isMobile) {
                  // Mobil: Dikey düzen
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(entry.key, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('${entry.value} adet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: yuzde,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Masaüstü: Yatay düzen
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: Text(entry.key, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: yuzde,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 80, child: Text('${entry.value} adet', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModelKarZararListesi() {
    // Filtrelenmiş modellerin kar/zarar listesi
    final modelVerileri = <Map<String, dynamic>>[];
    
    for (var item in filtrelenmisModeller) {
      final adet = ((item['toplam_adet'] ?? item['adet'] ?? 0) as num).toInt();
      
      final iplik = ((item['iplik_maliyeti'] ?? 0) as num).toDouble();
      final orgu = ((item['orgu_fiyat'] ?? 0) as num).toDouble();
      final dikim = ((item['dikim_fiyat'] ?? 0) as num).toDouble();
      final utu = ((item['utu_fiyat'] ?? 0) as num).toDouble();
      final yikama = ((item['yikama_fiyat'] ?? 0) as num).toDouble();
      final ilikDugme = ((item['ilik_dugme_fiyat'] ?? 0) as num).toDouble();
      final aksesuar = ((item['aksesuar_fiyat'] ?? 0) as num).toDouble();
      final genelAksesuar = ((item['genel_aksesuar_fiyat'] ?? 0) as num).toDouble();
      final genelGider = ((item['genel_gider_fiyat'] ?? 0) as num).toDouble();
      final fermuar = ((item['fermuar_fiyat'] ?? 0) as num).toDouble();
      
      final birimMaliyet = iplik + orgu + dikim + utu + yikama + ilikDugme + aksesuar + genelAksesuar + genelGider + fermuar;
      // Sadece yüklenen adet üzerinden hesapla - yükleme yoksa satış/maliyet yok
      final yuklenenAdet = ((item['yuklenen_adet'] ?? 0) as num).toInt();
      final satis = ((item['pesin_fiyat'] ?? 0) as num).toDouble();
      final toplamMaliyet = yuklenenAdet > 0 ? birimMaliyet * yuklenenAdet : 0.0;
      final toplamSatis = yuklenenAdet > 0 ? satis * yuklenenAdet : 0.0;
      final kar = toplamSatis - toplamMaliyet;
      
      modelVerileri.add({
        'marka': item['marka'] ?? '',
        'itemNo': item['item_no'] ?? '',
        'renk': item['renk'] ?? '',
        'adet': adet,
        'yuklenenAdet': yuklenenAdet,
        'maliyet': toplamMaliyet,
        'satis': toplamSatis,
        'kar': kar,
        'marj': toplamSatis > 0 ? (kar / toplamSatis * 100) : 0.0,
      });
    }
    
    // Kara göre sırala
    modelVerileri.sort((a, b) => (b['kar'] as double).compareTo(a['kar'] as double));
    
    if (modelVerileri.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Veri bulunamadı'))));
    }
    
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(label: Text('Marka', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Model', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Renk', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Sipariş', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Yüklenen', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Maliyet', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Satış', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Kâr', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Marj %', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: modelVerileri.take(20).map((model) {
            final kar = model['kar'] as double;
            final marj = model['marj'] as double;
            final yuklenen = model['yuklenenAdet'] as int;
            final karRenk = kar >= 0 ? Colors.green : Colors.red;
            final yuklenmedi = yuklenen == 0;
            
            return DataRow(
              color: yuklenmedi ? WidgetStateProperty.all(Colors.grey[50]) : null,
              cells: [
                DataCell(Text(model['marka'])),
                DataCell(Text(model['itemNo'])),
                DataCell(Text(model['renk'])),
                DataCell(Text('${model['adet']}')),
                DataCell(Text(yuklenmedi ? '-' : '$yuklenen',
                    style: TextStyle(color: yuklenmedi ? Colors.grey : Colors.teal, fontWeight: FontWeight.w600))),
                DataCell(Text(yuklenmedi ? '-' : currencyFormat.format(model['maliyet']),
                    style: TextStyle(color: yuklenmedi ? Colors.grey : null))),
                DataCell(Text(yuklenmedi ? '-' : currencyFormat.format(model['satis']),
                    style: TextStyle(color: yuklenmedi ? Colors.grey : null))),
                DataCell(Text(yuklenmedi ? '-' : currencyFormat.format(kar),
                    style: TextStyle(color: yuklenmedi ? Colors.grey : karRenk, fontWeight: FontWeight.bold))),
                DataCell(Text(yuklenmedi ? '-' : '%${marj.toStringAsFixed(1)}',
                    style: TextStyle(color: yuklenmedi ? Colors.grey : karRenk))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKarZararTab() {
    final musteriBazli = Map<String, double>.from(karZararVerileri['musteriBazliGelir'] ?? {});
    final kategoriGelir = Map<String, double>.from(karZararVerileri['kategoriGelir'] ?? {});
    final kategoriGider = Map<String, double>.from(karZararVerileri['kategoriGider'] ?? {});
    final isDemoVeri = karZararVerileri['demoVeri'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Demo veri uyarısı
        if (isDemoVeri) Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Demo veriler gösteriliyor. Gerçek verileri görmek için veritabanı tablolarını kontrol edin.',
                style: TextStyle(color: Colors.orange.shade700),
              )),
            ],
          ),
        ),
        // Veri yoksa bilgi mesajı
        if (!isDemoVeri && (karZararVerileri['toplamGelir'] ?? 0) == 0 && (karZararVerileri['toplamGider'] ?? 0) == 0)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  'Seçili dönem için gelir/gider kaydı bulunamadı. Fatura, kasa hareketi veya satış ekleyin.',
                  style: TextStyle(color: Colors.blue.shade700),
                )),
              ],
            ),
          ),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 500;
                
                return Column(children: [
                  if (isMobile) 
                    Column(children: [
                      _buildFinansOzet('Toplam Gelir', karZararVerileri['toplamGelir'] ?? 0, Colors.green),
                      const SizedBox(height: 12),
                      _buildFinansOzet('Toplam Gider', karZararVerileri['toplamGider'] ?? 0, Colors.red),
                      const SizedBox(height: 12),
                      _buildFinansOzet('Net Kâr', karZararVerileri['brutKar'] ?? 0, (karZararVerileri['brutKar'] ?? 0) >= 0 ? Colors.green : Colors.red),
                    ])
                  else
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _buildFinansOzet('Toplam Gelir', karZararVerileri['toplamGelir'] ?? 0, Colors.green),
                      _buildFinansOzet('Toplam Gider', karZararVerileri['toplamGider'] ?? 0, Colors.red),
                      _buildFinansOzet('Net Kâr', karZararVerileri['brutKar'] ?? 0, (karZararVerileri['brutKar'] ?? 0) >= 0 ? Colors.green : Colors.red),
                    ]),
                  const Divider(height: 32),
                  LinearProgressIndicator(value: ((karZararVerileri['karMarji'] ?? 0) as num).toDouble().clamp(0, 100) / 100, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>((karZararVerileri['brutKar'] ?? 0) >= 0 ? Colors.green : Colors.red), minHeight: 12),
                  const SizedBox(height: 8),
                  Text('Kâr Marjı: %${((karZararVerileri['karMarji'] ?? 0) as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // GELİR KAYNAKLARI ÖZET
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gelir Kaynakları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildGelirKaynakSatiri('Fatura Gelirleri', ((karZararVerileri['faturaGeliri'] ?? 0) as num).toDouble(), Icons.receipt, Colors.blue),
              _buildGelirKaynakSatiri('Kasa/Banka Tahsilatları', ((karZararVerileri['kasaGeliri'] ?? 0) as num).toDouble(), Icons.account_balance, Colors.teal),
              _buildGelirKaynakSatiri('Depo Satış Gelirleri', ((karZararVerileri['depoSatisGeliri'] ?? 0) as num).toDouble(), Icons.store, Colors.green),
              const Divider(height: 24),
              _buildGelirKaynakSatiri('Üretim Maliyeti', ((karZararVerileri['toplamGider'] ?? 0) as num).toDouble(), Icons.factory, Colors.red),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        if (musteriBazli.isNotEmpty) ...[
          _buildSectionTitle('Müşteri Bazlı Gelir'),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: musteriBazli.entries.map((entry) {
            final yuzde = (karZararVerileri['toplamGelir'] ?? 1) > 0 ? (entry.value / (karZararVerileri['toplamGelir'] as num)) * 100 : 0;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))), Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: yuzde / 100, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Colors.green)),
              Text('%${yuzde.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]));
          }).toList()))),
          const SizedBox(height: 24),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            if (isMobile) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (kategoriGelir.isNotEmpty) _buildKategoriCard('Gelir Kategorileri', kategoriGelir, Colors.green),
                if (kategoriGelir.isNotEmpty && kategoriGider.isNotEmpty) const SizedBox(height: 16),
                if (kategoriGider.isNotEmpty) _buildKategoriCard('Gider Kategorileri', kategoriGider, Colors.red),
              ]);
            }
            
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (kategoriGelir.isNotEmpty) Expanded(child: _buildKategoriCard('Gelir Kategorileri', kategoriGelir, Colors.green)),
              if (kategoriGelir.isNotEmpty && kategoriGider.isNotEmpty) const SizedBox(width: 16),
              if (kategoriGider.isNotEmpty) Expanded(child: _buildKategoriCard('Gider Kategorileri', kategoriGider, Colors.red)),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _buildMaliyetTab() {
    final maliyetDagilimi = Map<String, double>.from(maliyetVerileri['maliyetDagilimi'] ?? {});
    final modelMaliyetleri = List<Map<String, dynamic>>.from(maliyetVerileri['modelMaliyetleri'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(20), child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;
            
            return Column(children: [
              if (isMobile)
                Column(children: [
                  _buildFinansOzet('Toplam Maliyet', maliyetVerileri['toplamMaliyet'] ?? 0, Colors.red),
                  const SizedBox(height: 12),
                  _buildFinansOzet('Toplam Satış', maliyetVerileri['toplamSatisFiyati'] ?? 0, Colors.green),
                  const SizedBox(height: 12),
                  _buildFinansOzet('Toplam Kâr', maliyetVerileri['toplamKar'] ?? 0, Colors.blue),
                ])
              else
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _buildFinansOzet('Toplam Maliyet', maliyetVerileri['toplamMaliyet'] ?? 0, Colors.red),
                  _buildFinansOzet('Toplam Satış', maliyetVerileri['toplamSatisFiyati'] ?? 0, Colors.green),
                  _buildFinansOzet('Toplam Kâr', maliyetVerileri['toplamKar'] ?? 0, Colors.blue),
                ]),
              const SizedBox(height: 16),
              Text('Ortalama Kâr Marjı: %${((maliyetVerileri['ortalamaKarMarji'] ?? 0) as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]);
          },
        ))),
        const SizedBox(height: 24),
        _buildSectionTitle('Maliyet Dağılımı'),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: maliyetDagilimi.entries.map((entry) {
          final toplamMaliyet = (maliyetVerileri['toplamMaliyet'] ?? 1) as num;
          final yuzde = toplamMaliyet > 0 ? (entry.value / toplamMaliyet) * 100 : 0;
          final renk = {'İplik': Colors.blue, 'Aksesuar': Colors.orange, 'İşçilik': Colors.green}[entry.key] ?? Colors.purple;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: renk, shape: BoxShape.circle)), const SizedBox(width: 8), Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))]),
              Text('${currencyFormat.format(entry.value)} (%${yuzde.toStringAsFixed(1)})', style: TextStyle(fontWeight: FontWeight.bold, color: renk)),
            ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: yuzde / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(renk)),
          ]));
        }).toList()))),
        const SizedBox(height: 24),
        if (modelMaliyetleri.isNotEmpty) ...[
          _buildSectionTitle('Model Bazlı Maliyet Analizi'),
          const SizedBox(height: 8),
          Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            columns: const [DataColumn(label: Text('Marka')), DataColumn(label: Text('Item No')), DataColumn(label: Text('Adet')), DataColumn(label: Text('Birim Maliyet')), DataColumn(label: Text('Satış Fiyatı')), DataColumn(label: Text('Kâr')), DataColumn(label: Text('Marj %'))],
            rows: modelMaliyetleri.take(20).map((model) {
              final kar = (model['kar'] ?? 0) as num;
              return DataRow(cells: [
                DataCell(Text(model['marka'] ?? '')),
                DataCell(Text(model['itemNo'] ?? '')),
                DataCell(Text('${model['adet'] ?? 0}')),
                DataCell(Text(currencyFormat.format(model['birimMaliyet'] ?? 0))),
                DataCell(Text(currencyFormat.format(model['satisFiyati'] ?? 0))),
                DataCell(Text(currencyFormat.format(kar), style: TextStyle(color: kar >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                DataCell(Text('%${((model['karMarji'] ?? 0) as num).toStringAsFixed(1)}', style: TextStyle(color: (model['karMarji'] ?? 0) >= 0 ? Colors.green : Colors.red))),
              ]);
            }).toList(),
          ))),
        ],
      ]),
    );
  }

  Widget _buildTedarikciTab() {
    final tedarikciler = List<Map<String, dynamic>>.from(tedarikciVerileri['tedarikciPerformanslari'] ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;
            
            if (isMobile) {
              return Column(children: [
                _buildKPICard('Toplam Tedarikçi', '${tedarikciVerileri['toplamTedarikci'] ?? 0}', Icons.business, Colors.blue),
                const SizedBox(height: 12),
                _buildKPICard('Ort. Performans', '%${((tedarikciVerileri['ortalamaPerformans'] ?? 0) as num).toStringAsFixed(1)}', Icons.trending_up, Colors.green),
              ]);
            }
            
            return Row(children: [
              Expanded(child: _buildKPICard('Toplam Tedarikçi', '${tedarikciVerileri['toplamTedarikci'] ?? 0}', Icons.business, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('Ort. Performans', '%${((tedarikciVerileri['ortalamaPerformans'] ?? 0) as num).toStringAsFixed(1)}', Icons.trending_up, Colors.green)),
            ]);
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Tedarikçi Performans Tablosu'),
        const SizedBox(height: 8),
        tedarikciler.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tedarikçi verisi bulunamadı'))))
            : Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                columns: const [DataColumn(label: Text('Şirket')), DataColumn(label: Text('Faaliyet')), DataColumn(label: Text('Toplam İş')), DataColumn(label: Text('Tamamlanan')), DataColumn(label: Text('Devam Eden')), DataColumn(label: Text('Bekleyen')), DataColumn(label: Text('Performans'))],
                rows: tedarikciler.map((t) {
                  final performans = (t['tamamlanmaOrani'] ?? 0) as num;
                  final renk = performans >= 80 ? Colors.green : (performans >= 50 ? Colors.orange : Colors.red);
                  return DataRow(cells: [
                    DataCell(Text(t['sirket'] ?? '')),
                    DataCell(Text(t['faaliyet'] ?? '')),
                    DataCell(Text('${t['toplamAtama'] ?? 0}')),
                    DataCell(Text('${t['tamamlanan'] ?? 0}', style: const TextStyle(color: Colors.green))),
                    DataCell(Text('${t['devamEden'] ?? 0}', style: const TextStyle(color: Colors.orange))),
                    DataCell(Text('${t['bekleyen'] ?? 0}', style: const TextStyle(color: Colors.grey))),
                    DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: renk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Text('%${performans.toStringAsFixed(0)}', style: TextStyle(color: renk, fontWeight: FontWeight.bold)))),
                  ]);
                }).toList(),
              ))),
      ]),
    );
  }

  Widget _buildVerimlilikTab() {
    final asamaVerileri = Map<String, Map<String, dynamic>>.from(verimlilikVerileri['asamaVerileri'] ?? {});
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(elevation: 4, color: Colors.purple[50], child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          const Icon(Icons.speed, size: 48, color: Colors.purple),
          const SizedBox(height: 12),
          Text('%${((verimlilikVerileri['genelVerimlilik'] ?? 0) as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.purple)),
          const Text('Genel Üretim Verimliliği', style: TextStyle(fontSize: 16, color: Colors.purple)),
          const SizedBox(height: 12),
          Text('${verimlilikVerileri['toplamTamamlanan'] ?? 0} / ${verimlilikVerileri['toplamIs'] ?? 0} iş tamamlandı'),
        ]))),
        const SizedBox(height: 24),
        _buildSectionTitle('Aşama Bazlı Verimlilik'),
        const SizedBox(height: 8),
        ...asamaVerileri.entries.map((entry) {
          final verimlilik = (entry.value['verimlilik'] ?? 0) as num;
          final renk = verimlilik >= 80 ? Colors.green : (verimlilik >= 50 ? Colors.orange : Colors.red);
          return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: renk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Text('%${verimlilik.toStringAsFixed(0)}', style: TextStyle(color: renk, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: verimlilik / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(renk), minHeight: 8),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildMiniStat('Toplam', entry.value['toplam'] ?? 0, Colors.blue),
              _buildMiniStat('Tamamlanan', entry.value['tamamlanan'] ?? 0, Colors.green),
              _buildMiniStat('Üretimde', entry.value['uretimde'] ?? 0, Colors.orange),
              _buildMiniStat('Bekleyen', entry.value['bekleyen'] ?? 0, Colors.grey),
            ]),
          ])));
        }),
      ]),
    );
  }

  Widget _buildTerminTab() {
    final geciken = List<Map<String, dynamic>>.from(terminVerileri['gecikmisSiparisler'] ?? []);
    final bugun = List<Map<String, dynamic>>.from(terminVerileri['bugunTermin'] ?? []);
    final yaklasan = List<Map<String, dynamic>>.from(terminVerileri['yaklasanTerminler'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;
            
            if (isMobile) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  _buildKPICard('Geciken', '${terminVerileri['toplamGeciken'] ?? 0}', Icons.warning, Colors.red),
                  _buildKPICard('Bugün', '${terminVerileri['toplamBugun'] ?? 0}', Icons.today, Colors.orange),
                  _buildKPICard('7 Gün İçinde', '${terminVerileri['toplamYaklasan'] ?? 0}', Icons.schedule, Colors.blue),
                ],
              );
            }
            
            return Row(children: [
              Expanded(child: _buildKPICard('Geciken', '${terminVerileri['toplamGeciken'] ?? 0}', Icons.warning, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildKPICard('Bugün', '${terminVerileri['toplamBugun'] ?? 0}', Icons.today, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildKPICard('7 Gün İçinde', '${terminVerileri['toplamYaklasan'] ?? 0}', Icons.schedule, Colors.blue)),
            ]);
          },
        ),
        const SizedBox(height: 24),
        if (geciken.isNotEmpty) ...[_buildSectionTitle('🚨 Geciken Siparişler', Colors.red), const SizedBox(height: 8), _buildTerminListe(geciken, Colors.red, 'gecikti'), const SizedBox(height: 24)],
        if (bugun.isNotEmpty) ...[_buildSectionTitle('📅 Bugün Termin', Colors.orange), const SizedBox(height: 8), _buildTerminListe(bugun, Colors.orange, 'bugün'), const SizedBox(height: 24)],
        if (yaklasan.isNotEmpty) ...[_buildSectionTitle('⏰ Yaklaşan Terminler (7 gün)', Colors.blue), const SizedBox(height: 8), _buildTerminListe(yaklasan, Colors.blue, 'kaldı')],
        if (geciken.isEmpty && bugun.isEmpty && yaklasan.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Column(children: [Icon(Icons.check_circle, size: 64, color: Colors.green), SizedBox(height: 16), Text('Tüm siparişler zamanında!', style: TextStyle(fontSize: 18, color: Colors.green))])))),
      ]),
    );
  }

  Widget _buildTerminListe(List<Map<String, dynamic>> liste, Color renk, String suffix) {
    return Card(color: renk.withValues(alpha: 0.1), child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: liste.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final model = liste[index];
        final gun = (model['kalanGun'] as int).abs();
        return ListTile(
          leading: CircleAvatar(backgroundColor: renk, child: Text('$gun', style: const TextStyle(color: Colors.white))),
          title: Text('${model['marka']} - ${model['itemNo']}'),
          subtitle: Text('Renk: ${model['renk']} • Adet: ${model['adet']}'),
          trailing: Text('$gun gün $suffix', style: TextStyle(color: renk, fontWeight: FontWeight.bold)),
        );
      },
    ));
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)), const Spacer()]),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ])));
  }

  Widget _buildSectionTitle(String title, [Color? color]) => Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.black87));

  Widget _buildFinansOzet(String title, num value, Color color) => Column(children: [Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])), const SizedBox(height: 4), Text(currencyFormat.format(value), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]);

  Widget _buildMiniStat(String label, int value, Color color) => Column(children: [Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))]);

  Widget _buildKategoriCard(String title, Map<String, double> data, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildSectionTitle(title),
    const SizedBox(height: 8),
    Card(color: color.withValues(alpha: 0.1), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: data.entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(entry.key), Text(currencyFormat.format(entry.value), style: TextStyle(fontWeight: FontWeight.bold, color: color))]))).toList()))),
  ]);

  Widget _buildGelirKaynakSatiri(String label, double tutar, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(currencyFormat.format(tutar), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ]),
    );
  }

}
