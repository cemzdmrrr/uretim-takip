// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

/// Uretim raporu tab icerikleri - ozet, fire analizi, termin takibi, tedarikci
extension _TabsRaporExt on _UretimRaporuPageState {
  Widget _buildOzetKartlari() {
    final gecikenSiparis = _ozet['geciken_siparis'] ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        final isMobile = constraints.maxWidth < 500;
        
        final kartlar = [
          _buildOzetKart('Toplam Model', _ozet['toplam_model'] ?? 0, Colors.blue, Icons.inventory, isMobile),
          _buildOzetKart('Devam Eden', _ozet['devam_eden'] ?? 0, Colors.orange, Icons.pending, isMobile),
          _buildOzetKart('Tamamlanan', _ozet['tamamlanan'] ?? 0, Colors.green, Icons.check_circle, isMobile),
          _buildOzetKart('Toplam Adet', _ozet['toplam_adet'] ?? 0, Colors.purple, Icons.numbers, isMobile),
          _buildOzetKart('Toplam Fire', _ozet['toplam_fire'] ?? 0, Colors.red.shade400, Icons.local_fire_department, isMobile),
          _buildOzetKart('Geciken', gecikenSiparis, Colors.red.shade700, Icons.warning_amber, isMobile),
        ];
        
        if (isMobile) {
          // Mobil: 2x3 grid
          return Container(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: kartlar,
            ),
          );
        } else if (isNarrow) {
          // Tablet: 3x2 grid
          return Container(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
              children: kartlar,
            ),
          );
        } else {
          // Desktop: tek satır
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: kartlar.map((k) => Expanded(child: k)).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildOzetKart(String baslik, int deger, Color renk, IconData icon, [bool isMobile = false]) {
    return Card(
      elevation: 3,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [renk.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: renk, size: isMobile ? 20 : 28),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              deger.toString(),
              style: TextStyle(fontSize: isMobile ? 16 : 22, fontWeight: FontWeight.bold, color: renk),
            ),
            Text(baslik, style: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildModelListesi() {
    if (_modeller.isEmpty) {
      return const Center(child: Text('Gösterilecek model bulunamadı'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            _gorunenModelSayisi < _modeller.length) {
          setState(() {
            _gorunenModelSayisi = (_gorunenModelSayisi + _UretimRaporuPageState._sayfaBasinaModel)
                .clamp(0, _modeller.length);
          });
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gorunenModelSayisi.clamp(0, _modeller.length) +
            (_gorunenModelSayisi < _modeller.length ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _gorunenModelSayisi.clamp(0, _modeller.length)) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildModelKart(_modeller[index]);
        },
      ),
    );
  }

  Widget _buildModelKart(Map<String, dynamic> model) {
    final asamalar = model['asamalar'] as Map<String, Map<String, dynamic>>;
    final mevcutAsama = model['mevcut_asama'] as String? ?? 'beklemede';
    final asamaBilgisi = _getAsamaBilgisi(mevcutAsama);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: asamaBilgisi['color'] as Color,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _modelDetayaGit(model),
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (asamaBilgisi['color'] as Color).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            asamaBilgisi['icon'] as IconData,
            color: asamaBilgisi['color'] as Color,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: asamaBilgisi['color'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                asamaBilgisi['label'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Renk: ${model['renk'] ?? '-'} • Adet: ${model['adet'] ?? 0}'),
            const SizedBox(height: 6),
            _buildAsamaProgress(asamalar, mevcutAsama),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text('Aşama Detayları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildAsamaDetayGrid(asamalar),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAsamaProgress(Map<String, Map<String, dynamic>> asamalar, String mevcutAsama) {
    final asamaListesiProgress = [
      {'key': 'dokuma', 'label': 'D', 'color': Colors.brown},
      {'key': 'konfeksiyon', 'label': 'K', 'color': Colors.orange},
      {'key': 'yikama', 'label': 'Y', 'color': Colors.blue},
      {'key': 'utu', 'label': 'Ü', 'color': Colors.purple},
      {'key': 'ilik_dugme', 'label': 'İ', 'color': Colors.teal},
      {'key': 'kalite_kontrol', 'label': 'Q', 'color': Colors.indigo},
      {'key': 'paketleme', 'label': 'P', 'color': Colors.green},
    ];

    return Row(
      children: asamaListesiProgress.map((asama) {
        final data = asamalar[asama['key']] ?? {};
        final durum = data['durum']?.toString() ?? '';
        final tamamlandi = durum == 'tamamlandi';
        final devamEdiyor = durum == 'uretimde' || durum == 'isleniyor';
        final atandi = durum == 'atandi' || durum == 'onaylandi';
        final aktifAsama = asama['key'] == mevcutAsama;
        
        Color bgColor;
        if (tamamlandi) {
          bgColor = Colors.green;
        } else if (devamEdiyor || aktifAsama) {
          bgColor = asama['color'] as Color;
        } else if (atandi) {
          bgColor = Colors.blue;
        } else {
          bgColor = Colors.grey.shade300;
        }
        
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: aktifAsama ? 28 : 24,
          height: aktifAsama ? 28 : 24,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: aktifAsama ? Border.all(color: Colors.black, width: 2) : null,
            boxShadow: aktifAsama ? [
              BoxShadow(
                color: (asama['color'] as Color).withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              asama['label'] as String,
              style: TextStyle(
                color: bgColor == Colors.grey.shade300 ? Colors.grey : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAsamaDetayGrid(Map<String, Map<String, dynamic>> asamalar) {
    final asamaListesi = [
      {'key': 'dokuma', 'label': 'Dokuma', 'icon': Icons.grid_on, 'color': Colors.brown},
      {'key': 'konfeksiyon', 'label': 'Konfeksiyon', 'icon': Icons.checkroom, 'color': Colors.orange},
      {'key': 'yikama', 'label': 'Yıkama', 'icon': Icons.local_laundry_service, 'color': Colors.blue},
      {'key': 'utu', 'label': 'Ütü', 'icon': Icons.iron, 'color': Colors.purple},
      {'key': 'ilik_dugme', 'label': 'İlik Düğme', 'icon': Icons.radio_button_checked, 'color': Colors.teal},
      {'key': 'kalite_kontrol', 'label': 'Kalite Kontrol', 'icon': Icons.verified, 'color': Colors.indigo},
      {'key': 'paketleme', 'label': 'Paketleme', 'icon': Icons.inventory_2, 'color': Colors.green},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: asamaListesi.length,
      itemBuilder: (context, index) {
        final asama = asamaListesi[index];
        final data = asamalar[asama['key']] ?? {};
        final durum = data['durum']?.toString() ?? 'beklemede';
        final tamamlanan = data['tamamlanan_adet'] ?? 0;
        final talep = data['talep_edilen_adet'] ?? data['kontrol_edilecek_adet'] ?? 0;
        final fire = data['fire_adet'] ?? 0;
        
        return _buildAsamaDetayKart(
          asama['label'] as String,
          asama['icon'] as IconData,
          asama['color'] as Color,
          durum,
          tamamlanan,
          talep,
          fire,
        );
      },
    );
  }

  Widget _buildAsamaDetayKart(
    String label,
    IconData icon,
    Color color,
    String durum,
    int tamamlanan,
    int talep,
    int fire,
  ) {
    final durumRenk = _getDurumRenk(durum);
    final durumMetin = _getDurumMetin(durum);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: durumRenk.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              durumMetin,
              style: TextStyle(fontSize: 9, color: durumRenk, fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$tamamlanan/$talep', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              if (fire > 0)
                Text('🔥$fire', style: const TextStyle(fontSize: 10, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: FIRE ANALİZİ ====================
  Widget _buildFireAnaliziTab() {
    final asamaLabels = {
      'dokuma': {'label': 'Dokuma', 'icon': Icons.grid_on, 'color': Colors.brown},
      'nakis': {'label': 'Nakış', 'icon': Icons.brush, 'color': Colors.pink},
      'konfeksiyon': {'label': 'Konfeksiyon', 'icon': Icons.checkroom, 'color': Colors.orange},
      'yikama': {'label': 'Yıkama', 'icon': Icons.local_laundry_service, 'color': Colors.blue},
      'utu': {'label': 'Ütü', 'icon': Icons.iron, 'color': Colors.purple},
      'ilik_dugme': {'label': 'İlik Düğme', 'icon': Icons.radio_button_checked, 'color': Colors.teal},
      'kalite_kontrol': {'label': 'Kalite Kontrol', 'icon': Icons.verified, 'color': Colors.indigo},
      'paketleme': {'label': 'Paketleme', 'icon': Icons.inventory_2, 'color': Colors.green},
    };
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        final isTablet = constraints.maxWidth < 800;
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
        final childAspectRatio = isMobile ? 3.5 : (isTablet ? 2.2 : 1.8);
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔥 Aşama Bazlı Fire Analizi',
                style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: isMobile ? 8 : 12,
                  mainAxisSpacing: isMobile ? 8 : 12,
                ),
                itemCount: _fireAnaliz.length,
                itemBuilder: (context, index) {
                  final asamaKey = _fireAnaliz.keys.elementAt(index);
                  final data = _fireAnaliz[asamaKey]!;
                  final fire = data['fire'] ?? 0;
                  final toplam = data['toplam'] ?? 0;
                  final oran = toplam > 0 ? (fire / toplam * 100) : 0.0;
                  final asamaInfo = asamaLabels[asamaKey] ?? {'label': asamaKey, 'icon': Icons.help_outline, 'color': Colors.grey};
                  
                  return Card(
                    elevation: 3,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            (asamaInfo['color'] as Color).withValues(alpha: 0.1),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(asamaInfo['icon'] as IconData, color: asamaInfo['color'] as Color, size: isMobile ? 28 : 24),
                          SizedBox(width: isMobile ? 12 : 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  asamaInfo['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: asamaInfo['color'] as Color,
                                    fontSize: isMobile ? 14 : 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '🔥 $fire adet',
                                  style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: oran > 5 ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '%${oran.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 12,
                                color: oran > 5 ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                '⚠️ En Çok Fire Veren Modeller',
                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildEnCokFireModeller(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnCokFireModeller() {
    // Fire'a göre sırala
    final fireliModeller = _tumModeller.where((m) {
      final asamalar = m['asamalar'] as Map<String, Map<String, dynamic>>;
      int toplamFire = 0;
      for (var asama in asamalar.values) {
        toplamFire += (asama['fire_adet'] ?? 0) as int;
      }
      return toplamFire > 0;
    }).toList();
    
    fireliModeller.sort((a, b) {
      int fireA = 0, fireB = 0;
      for (var asama in (a['asamalar'] as Map<String, Map<String, dynamic>>).values) {
        fireA += (asama['fire_adet'] ?? 0) as int;
      }
      for (var asama in (b['asamalar'] as Map<String, Map<String, dynamic>>).values) {
        fireB += (asama['fire_adet'] ?? 0) as int;
      }
      return fireB.compareTo(fireA);
    });
    
    final ilk10 = fireliModeller.take(10).toList();
    
    if (ilk10.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Henüz fire kaydı bulunmamaktadır.'),
        ),
      );
    }
    
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ilk10.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final model = ilk10[index];
          int toplamFire = 0;
          for (var asama in (model['asamalar'] as Map<String, Map<String, dynamic>>).values) {
            toplamFire += (asama['fire_adet'] ?? 0) as int;
          }
          
          return ListTile(
            onTap: () => _modelDetayaGit(model),
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text('${index + 1}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            title: Text('${model['marka']} - ${model['item_no']}'),
            subtitle: Text('Renk: ${model['renk']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🔥 $toplamFire',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== TAB 3: TERMİN TAKİBİ ====================
  Widget _buildTerminTakibiTab() {
    final now = DateTime.now();
    
    // Terminli modelleri filtrele ve sırala
    final terminliModeller = _tumModeller.where((m) {
      final terminStr = m['termin_tarihi']?.toString();
      return terminStr != null && terminStr.isNotEmpty && m['tamamlandi'] != true;
    }).toList();
    
    terminliModeller.sort((a, b) {
      final terminA = DateTime.tryParse(a['termin_tarihi'] ?? '') ?? DateTime(2100);
      final terminB = DateTime.tryParse(b['termin_tarihi'] ?? '') ?? DateTime(2100);
      return terminA.compareTo(terminB);
    });
    
    // Geciken ve yaklaşan olarak grupla
    final gecikenler = terminliModeller.where((m) {
      final termin = DateTime.tryParse(m['termin_tarihi'] ?? '');
      return termin != null && termin.isBefore(now);
    }).toList();
    
    final yaklasanlar = terminliModeller.where((m) {
      final termin = DateTime.tryParse(m['termin_tarihi'] ?? '');
      return termin != null && termin.isAfter(now) && termin.isBefore(now.add(const Duration(days: 7)));
    }).toList();
    
    final normal = terminliModeller.where((m) {
      final termin = DateTime.tryParse(m['termin_tarihi'] ?? '');
      return termin != null && termin.isAfter(now.add(const Duration(days: 7)));
    }).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        
        return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet kartları - responsive
          isMobile
              ? Column(
                  children: [
                    _buildTerminOzetKart('Geciken', gecikenler.length, Colors.red, Icons.warning_amber),
                    const SizedBox(height: 8),
                    _buildTerminOzetKart('7 Gün İçinde', yaklasanlar.length, Colors.orange, Icons.schedule),
                    const SizedBox(height: 8),
                    _buildTerminOzetKart('Normal', normal.length, Colors.green, Icons.check_circle_outline),
                  ],
                )
              : Row(
            children: [
              Expanded(
                child: _buildTerminOzetKart(
                  'Geciken',
                  gecikenler.length,
                  Colors.red,
                  Icons.warning_amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTerminOzetKart(
                  '7 Gün İçinde',
                  yaklasanlar.length,
                  Colors.orange,
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTerminOzetKart(
                  'Normal',
                  normal.length,
                  Colors.green,
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (gecikenler.isNotEmpty) ...[
            const Text(
              '🚨 Geciken Siparişler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            _buildTerminListesi(gecikenler, Colors.red),
            const SizedBox(height: 24),
          ],
          
          // Yaklaşan terminler
          if (yaklasanlar.isNotEmpty) ...[
            const Text(
              '⚠️ 7 Gün İçinde Bitmesi Gereken',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 12),
            _buildTerminListesi(yaklasanlar, Colors.orange),
            const SizedBox(height: 24),
          ],
          
          // Normal terminler
          if (normal.isNotEmpty) ...[
            const Text(
              '✅ Diğer Siparişler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            _buildTerminListesi(normal, Colors.green),
          ],
          
          if (terminliModeller.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Termin tarihi tanımlı aktif sipariş bulunmamaktadır.'),
              ),
            ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTerminOzetKart(String baslik, int sayi, Color renk, IconData icon) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: renk.withValues(alpha: 0.1),
        ),
        child: Column(
          children: [
            Icon(icon, color: renk, size: 36),
            const SizedBox(height: 8),
            Text(
              sayi.toString(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: renk),
            ),
            Text(baslik, style: TextStyle(color: renk)),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminListesi(List<Map<String, dynamic>> modeller, Color renk) {
    final now = DateTime.now();
    
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: modeller.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final model = modeller[index];
          final termin = DateTime.tryParse(model['termin_tarihi'] ?? '');
          final kalanGun = termin != null ? termin.difference(now).inDays : 0;
          final mevcutAsama = _getAsamaBilgisi(model['mevcut_asama'] ?? '');
          final tahmini = DateTime.tryParse(model['tahmini_tamamlanma']?.toString() ?? '');
          
          return ListTile(
            onTap: () => _modelDetayaGit(model),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  kalanGun >= 0 ? '$kalanGun\ngün' : '${kalanGun.abs()}\ngecikme',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: renk),
                ),
              ),
            ),
            title: Text('${model['marka']} - ${model['item_no']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Renk: ${model['renk']} • ${model['adet']} adet'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (mevcutAsama['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        mevcutAsama['label'] as String,
                        style: TextStyle(fontSize: 10, color: mevcutAsama['color'] as Color),
                      ),
                    ),
                  ],
                ),
                if (tahmini != null)
                  Text(
                    'Tahmini tamamlanma: ${DateFormat('dd/MM/yyyy').format(tahmini)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: Text(
              termin != null ? DateFormat('dd/MM/yyyy').format(termin) : '-',
              style: TextStyle(fontWeight: FontWeight.bold, color: renk),
            ),
          );
        },
      ),
    );
  }

  // ==================== TAB 4: TEDARİKÇİ BAZLI ====================
  Widget _buildTedarikciTab() {
    final tedarikciIstatistik = (_ozet['tedarikci_istatistik'] as Map<String, Map<String, dynamic>>?) ?? {};
    
    if (tedarikciIstatistik.isEmpty && _tedarikciler.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Henüz tedarikçi verisi bulunmamaktadır.'),
        ),
      );
    }

    // Tedarikçileri toplam modele göre sırala
    final sirali = tedarikciIstatistik.entries.toList()
      ..sort((a, b) => ((b.value['toplam_model'] ?? 0) as int).compareTo((a.value['toplam_model'] ?? 0) as int));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏭 Tedarikçi Performans Özeti',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Tedarikçi kartları
          ...sirali.map((entry) {
            final ad = entry.key;
            final data = entry.value;
            final toplamModel = (data['toplam_model'] ?? 0) as int;
            final toplamAdet = (data['toplam_adet'] ?? 0) as int;
            final toplamFire = (data['toplam_fire'] ?? 0) as int;
            final tamamlanan = (data['tamamlanan'] ?? 0) as int;
            final geciken = (data['geciken'] ?? 0) as int;
            final fireOrani = toplamAdet > 0 ? (toplamFire / toplamAdet * 100) : 0.0;
            final tamamlanmaOrani = toplamModel > 0 ? (tamamlanan / toplamModel * 100) : 0.0;
            final performansPuani = (data['performans_puani'] ?? 0.0) as double;
            
            // Bu tedarikçiye ait modelleri bul
            final tedarikciModelleri = _tumModeller.where(
              (m) => (m['tedarikci_adi']?.toString() ?? '') == ad,
            ).toList();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: geciken > 0 ? Colors.red.shade100 : Colors.green.shade100,
                  child: Icon(
                    Icons.business,
                    color: geciken > 0 ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTedarikciChip('$toplamModel model', Colors.blue),
                      _buildTedarikciChip('$toplamAdet adet', Colors.purple),
                      _buildTedarikciChip('$tamamlanan tamamlandı', Colors.green),
                      if (geciken > 0) _buildTedarikciChip('$geciken geciken', Colors.red),
                    ],
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      performansPuani.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: performansPuani >= 80 ? Colors.green : (performansPuani >= 60 ? Colors.orange : Colors.red),
                      ),
                    ),
                    const Text('puan', style: TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fire oranı göstergesi
                        // Performans puanı göstergesi
                        Row(
                          children: [
                            const Text('Performans: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: performansPuani / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  performansPuani >= 80 ? Colors.green : (performansPuani >= 60 ? Colors.orange : Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${performansPuani.toStringAsFixed(0)}/100',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: performansPuani >= 80 ? Colors.green : (performansPuani >= 60 ? Colors.orange : Colors.red),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tamamlanma oranı
                        Row(
                          children: [
                            const Text('Tamamlanma: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: tamamlanmaOrani / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation(Colors.blue),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '%${tamamlanmaOrani.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Fire oranı
                        Row(
                          children: [
                            const Text('Fire Oranı: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: fireOrani / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  fireOrani > 5 ? Colors.red : (fireOrani > 2 ? Colors.orange : Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '%${fireOrani.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: fireOrani > 5 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Modeller listesi
                        if (tedarikciModelleri.isNotEmpty) ...[
                          Text('Modeller (${tedarikciModelleri.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...tedarikciModelleri.take(5).map((model) {
                            final mevcutAsama = _getAsamaBilgisi(model['mevcut_asama'] ?? '');
                            return ListTile(
                              dense: true,
                              title: Text('${model['marka']} - ${model['item_no']}'),
                              subtitle: Text('Renk: ${model['renk']} • ${model['adet']} adet'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (mevcutAsama['color'] as Color).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  mevcutAsama['label'] as String,
                                  style: TextStyle(fontSize: 10, color: mevcutAsama['color'] as Color),
                                ),
                              ),
                              onTap: () => _modelDetayaGit(model),
                            );
                          }),
                          if (tedarikciModelleri.length > 5)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '... ve ${tedarikciModelleri.length - 5} model daha',
                                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),
          const Text(
            '📊 Marka Bazlı Dağılım',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildMarkaDagilimi(),
        ],
      ),
    );
  }

  Widget _buildTedarikciChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMarkaDagilimi() {
    // Marka bazlı grupla
    final markaBazli = <String, int>{};
    for (var model in _tumModeller) {
      final marka = model['marka']?.toString() ?? 'Belirtilmemiş';
      markaBazli[marka] = (markaBazli[marka] ?? 0) + 1;
    }
    
    // Sırala
    final sirali = markaBazli.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    if (sirali.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Henüz marka verisi bulunmamaktadır.'),
        ),
      );
    }
    
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sirali.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = sirali[index];
          final yuzde = (_tumModeller.isNotEmpty ? entry.value / _tumModeller.length * 100 : 0).toStringAsFixed(1);
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: Text('${index + 1}', style: const TextStyle(color: Colors.indigo)),
            ),
            title: Text(entry.key),
            subtitle: LinearProgressIndicator(
              value: _tumModeller.isNotEmpty ? entry.value / _tumModeller.length : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Colors.indigo.shade400),
            ),
            trailing: Text(
              '${entry.value} (%$yuzde)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // ==================== MODEL KARŞILAŞTIRMA ====================
  void _modelKarsilastirmaDialogu() {
    Map<String, dynamic>? model1;
    Map<String, dynamic>? model2;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Model Karşılaştırma'),
            content: SizedBox(
              width: 600,
              height: 500,
              child: Column(
                children: [
                  // Model seçim
                  Row(
                    children: [
                      Expanded(
                        child: _buildModelSecici(
                          'Model 1',
                          model1,
                          (m) => setDialogState(() => model1 = m),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.compare_arrows, size: 32, color: Colors.indigo),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModelSecici(
                          'Model 2',
                          model2,
                          (m) => setDialogState(() => model2 = m),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // Karşılaştırma tablosu
                  if (model1 != null && model2 != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildKarsilastirmaTablosu(model1!, model2!),
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Karşılaştırmak için iki model seçin',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModelSecici(
    String label,
    Map<String, dynamic>? secili,
    ValueChanged<Map<String, dynamic>> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          isExpanded: true,
          // ignore: deprecated_member_use
          value: secili?['id']?.toString(),
          hint: const Text('Model seçin...', style: TextStyle(fontSize: 12)),
          items: _modeller.take(50).map((m) => DropdownMenuItem(
            value: m['id']?.toString(),
            child: Text(
              '${m['marka']} - ${m['item_no']}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          )).toList(),
          onChanged: (id) {
            final m = _modeller.firstWhere(
              (m) => m['id']?.toString() == id,
              orElse: () => <String, dynamic>{},
            );
            if (m.isNotEmpty) onSelected(m);
          },
        ),
      ],
    );
  }

  Widget _buildKarsilastirmaTablosu(Map<String, dynamic> m1, Map<String, dynamic> m2) {
    final satirlar = <_KarsilastirmaSatir>[
      _KarsilastirmaSatir('Marka', m1['marka']?.toString() ?? '-', m2['marka']?.toString() ?? '-'),
      _KarsilastirmaSatir('Item No', m1['item_no']?.toString() ?? '-', m2['item_no']?.toString() ?? '-'),
      _KarsilastirmaSatir('Renk', m1['renk']?.toString() ?? '-', m2['renk']?.toString() ?? '-'),
      _KarsilastirmaSatir('Adet', m1['adet']?.toString() ?? '0', m2['adet']?.toString() ?? '0'),
      _KarsilastirmaSatir('Mevcut Aşama',
        (_getAsamaBilgisi(m1['mevcut_asama'] ?? ''))['label'] as String,
        (_getAsamaBilgisi(m2['mevcut_asama'] ?? ''))['label'] as String,
      ),
      _KarsilastirmaSatir('Tedarikçi', m1['tedarikci_adi']?.toString() ?? '-', m2['tedarikci_adi']?.toString() ?? '-'),
    ];

    // Aşama bazlı fire karşılaştırma
    final asamalar1 = m1['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};
    final asamalar2 = m2['asamalar'] as Map<String, Map<String, dynamic>>? ?? {};
    int fire1 = 0, fire2 = 0;
    for (var a in asamalar1.values) { fire1 += (a['fire_adet'] ?? 0) as int; }
    for (var a in asamalar2.values) { fire2 += (a['fire_adet'] ?? 0) as int; }
    satirlar.add(_KarsilastirmaSatir('Toplam Fire', fire1.toString(), fire2.toString()));

    // Termin
    final termin1 = m1['termin_tarihi']?.toString();
    final termin2 = m2['termin_tarihi']?.toString();
    satirlar.add(_KarsilastirmaSatir(
      'Termin Tarihi',
      termin1 != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(termin1)) : '-',
      termin2 != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(termin2)) : '-',
    ));

    // Tahmini tamamlanma
    final tahmini1 = m1['tahmini_tamamlanma']?.toString();
    final tahmini2 = m2['tahmini_tamamlanma']?.toString();
    satirlar.add(_KarsilastirmaSatir(
      'Tahmini Tamamlanma',
      tahmini1 != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(tahmini1)) : '-',
      tahmini2 != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(tahmini2)) : '-',
    ));

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.indigo.shade50),
          children: const [
            Padding(padding: EdgeInsets.all(8), child: Text('Özellik', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Model 1', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Model 2', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ...satirlar.map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.all(8), child: Text(s.baslik, style: const TextStyle(fontWeight: FontWeight.w500))),
            Padding(padding: const EdgeInsets.all(8), child: Text(s.deger1)),
            Padding(padding: const EdgeInsets.all(8), child: Text(s.deger2)),
          ],
        )),
      ],
    );
  }
}
