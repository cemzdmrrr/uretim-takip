part of 'model_detay.dart';

/// Aksesuarlar (Accessories) tab extension for _ModelDetayState.
extension _AksesuarlarTabExt on _ModelDetayState {
  // ==================== AKSESUARLAR SEKMESİ ====================
  Widget _buildAksesuarlarTab() {
    // Sipariş adedi: toplam_adet, adet veya siparis_adedi
    final int siparisAdedi = (currentModelData?['toplam_adet'] ?? currentModelData?['adet'] ?? currentModelData?['siparis_adedi'] ?? 0) as int;
    
    // Toplam aksesuar maliyeti hesapla
    double toplamAksesuarMaliyeti = 0.0;
    double birModelMaliyeti = 0.0; // 1 modeldeki aksesuar maliyeti
    for (var aksesuar in modelAksesuarlari) {
      final aksesuarDetay = aksesuar[DbTables.aksesuarlar];
      final double birimFiyat = (aksesuarDetay?['birim_fiyat'] as num?)?.toDouble() ?? 0.0;
      final int adetPerModel = (aksesuar['adet_per_model'] ?? aksesuar['miktar'] ?? 1) as int;
      final int gerekenAdet = siparisAdedi * adetPerModel;
      toplamAksesuarMaliyeti += birimFiyat * gerekenAdet;
      birModelMaliyeti += birimFiyat * adetPerModel; // 1 model için maliyet
    }
    
    return Column(
      children: [
        // Üst kısım - Toplam maliyet ve Ekle butonu
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                border: Border(bottom: BorderSide(color: Colors.teal.shade200)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: buildModelMaliyetCard(birModelMaliyeti)),
                            const SizedBox(width: 8),
                            Expanded(child: buildToplamMaliyetCard(toplamAksesuarMaliyeti, siparisAdedi)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (kullaniciRolu == 'admin')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAksesuarEkleDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Aksesuar Ekle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: buildModelMaliyetCard(birModelMaliyeti)),
                        const SizedBox(width: 8),
                        Expanded(child: buildToplamMaliyetCard(toplamAksesuarMaliyeti, siparisAdedi)),
                        const SizedBox(width: 16),
                        if (kullaniciRolu == 'admin')
                          ElevatedButton.icon(
                            onPressed: _showAksesuarEkleDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Aksesuar Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
            );
          },
        ),
        
        // Aksesuar listesi
        Expanded(
          child: modelAksesuarlari.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Bu modele henüz aksesuar eklenmemiş', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : StatefulBuilder(
                  builder: (context, setState) {
                    final Set<int> expandedIndexes = {};
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: modelAksesuarlari.length,
                      itemBuilder: (context, index) {
                        final aksesuar = modelAksesuarlari[index];
                        final aksesuarDetay = aksesuar[DbTables.aksesuarlar];
                        
                        // Stok ve fiyat hesaplaması
                        final int stokMiktari = (aksesuarDetay?['toplam_stok'] ?? aksesuarDetay?['miktar'] ?? 0) as int;
                        final int minimumStok = (aksesuarDetay?['minimum_stok'] ?? 0) as int;
                        final double birimFiyat = (aksesuarDetay?['birim_fiyat'] as num?)?.toDouble() ?? 0.0;
                        final int adetPerModel = (aksesuar['adet_per_model'] ?? aksesuar['miktar'] ?? 1) as int;
                        // Sipariş adedi: toplam_adet, adet veya siparis_adedi
                        final int siparisAdedi = (currentModelData?['toplam_adet'] ?? currentModelData?['adet'] ?? currentModelData?['siparis_adedi'] ?? 0) as int;
                        // Gereken Toplam = Sipariş Adedi * Model Başına Adet
                        final int gerekenAdet = siparisAdedi * adetPerModel;
                        // Toplam Maliyet = Gereken Adet * Birim Fiyat
                        final double toplamFiyat = birimFiyat * gerekenAdet;
                        final int eksikAdet = gerekenAdet > stokMiktari ? gerekenAdet - stokMiktari : 0;
                        final bool stokYeterli = stokMiktari >= gerekenAdet;
                        final bool stokKritik = stokMiktari <= minimumStok;
                        
                        return ExpansionTile(
                          key: PageStorageKey('aksesuar_$index'),
                          initiallyExpanded: expandedIndexes.contains(index),
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (expanded) {
                                expandedIndexes.add(index);
                              } else {
                                expandedIndexes.remove(index);
                              }
                            });
                          },
                          title: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: stokYeterli ? Colors.teal[100] : Colors.red[100],
                                child: Icon(
                                  stokYeterli ? Icons.category : Icons.warning,
                                  color: stokYeterli ? Colors.teal : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      aksesuarDetay?['ad'] ?? aksesuarDetay?['aksesuar_adi'] ?? 'Aksesuar',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (aksesuarDetay?['sku'] != null)
                                      Text(
                                        'SKU: ${aksesuarDetay?['sku']}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    if (aksesuarDetay?['kategori'] != null || aksesuarDetay?['aksesuar_tipi'] != null)
                                      Text(
                                        aksesuarDetay?['kategori'] ?? aksesuarDetay?['aksesuar_tipi'] ?? '',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              // Birim fiyat gösterimi
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('Birim', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                    Text('₺${birimFiyat.toStringAsFixed(2)}', 
                                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (kullaniciRolu == 'admin')
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAksesuar(aksesuar['id']),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Üst satır - aksesuar adı ve silme butonu
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: stokYeterli ? Colors.teal[100] : Colors.red[100],
                                        child: Icon(
                                          stokYeterli ? Icons.category : Icons.warning,
                                          color: stokYeterli ? Colors.teal : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              aksesuarDetay?['ad'] ?? aksesuarDetay?['aksesuar_adi'] ?? 'Aksesuar',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            if (aksesuarDetay?['sku'] != null)
                                              Text(
                                                'SKU: ${aksesuarDetay?['sku']}',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            if (aksesuarDetay?['kategori'] != null || aksesuarDetay?['aksesuar_tipi'] != null)
                                              Text(
                                                aksesuarDetay?['kategori'] ?? aksesuarDetay?['aksesuar_tipi'] ?? '',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Birim fiyat gösterimi
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            Text('Birim', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                            Text('₺${birimFiyat.toStringAsFixed(2)}', 
                                                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (kullaniciRolu == 'admin')
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteAksesuar(aksesuar['id']),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  // Stok ve fiyat bilgileri
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStokInfoTile(
                                          'Mevcut Stok',
                                          '$stokMiktari adet',
                                          stokKritik ? Colors.orange : Colors.green,
                                          Icons.inventory_2,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildStokInfoTile(
                                          'Model Başına',
                                          '$adetPerModel adet',
                                          Colors.blue,
                                          Icons.layers,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStokInfoTile(
                                          'Gereken Toplam',
                                          '$gerekenAdet adet',
                                          Colors.indigo,
                                          Icons.calculate,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildStokInfoTile(
                                          'Toplam Maliyet',
                                          '₺${toplamFiyat.toStringAsFixed(2)}',
                                          Colors.purple,
                                          Icons.payments,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStokInfoTile(
                                          stokYeterli ? 'Stok Durumu' : 'Eksik Miktar',
                                          stokYeterli ? 'Yeterli ✓' : '$eksikAdet adet eksik',
                                          stokYeterli ? Colors.green : Colors.red,
                                          stokYeterli ? Icons.check_circle : Icons.error,
                                        ),
                                      ),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                  // Beden bazlı stok dağılımı
                                  if ((aksesuarDetay?['aksesuar_bedenler'] as List?)?.isNotEmpty == true) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.straighten, size: 16, color: Colors.teal),
                                              SizedBox(width: 6),
                                              Text('Beden Bazlı Stok Durumu',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ...() {
                                            final bedenlerList = aksesuarDetay!['aksesuar_bedenler'] as List;
                                            final modelBedenler = currentModelData?['bedenler'] as Map<String, dynamic>? ?? {};
                                            return bedenlerList.map<Widget>((b) {
                                              final bedenAdi = b['beden']?.toString() ?? '';
                                              final stok = (b['stok_miktari'] as int? ?? 0);
                                              final modelBedenAdet = (modelBedenler[bedenAdi] as num?)?.toInt() ?? 0;
                                              final gerekenBedenAdet = modelBedenAdet * adetPerModel;
                                              final bedenYeterli = stok >= gerekenBedenAdet;
                                              final bedenEksik = gerekenBedenAdet > stok ? gerekenBedenAdet - stok : 0;
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 3),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 50,
                                                      child: Text(bedenAdi,
                                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                    ),
                                                    Expanded(
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: LinearProgressIndicator(
                                                          value: gerekenBedenAdet > 0
                                                              ? (stok / gerekenBedenAdet).clamp(0.0, 1.0)
                                                              : 1.0,
                                                          backgroundColor: Colors.grey.shade200,
                                                          valueColor: AlwaysStoppedAnimation(
                                                              bedenYeterli ? Colors.green : Colors.red),
                                                          minHeight: 8,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    SizedBox(
                                                      width: 120,
                                                      child: Text(
                                                        gerekenBedenAdet > 0
                                                            ? '$stok / $gerekenBedenAdet ${bedenYeterli ? '✓' : '($bedenEksik eksik)'}'
                                                            : '$stok adet',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: bedenYeterli ? Colors.green.shade700 : Colors.red.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          }(),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (!stokYeterli)
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Bu sipariş için $eksikAdet adet daha tedarik edilmeli!',
                                              style: TextStyle(color: Colors.red[700], fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (stokKritik && stokYeterli)
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Stok kritik seviyede (Min: $minimumStok)',
                                              style: TextStyle(color: Colors.orange[700], fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (birimFiyat > 0 && kullaniciRolu == 'admin')
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.purple.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Birim Fiyat: ₺${birimFiyat.toStringAsFixed(2)}', 
                                               style: TextStyle(color: Colors.grey[700])),
                                          Text(
                                            'Toplam: ₺${toplamFiyat.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAksesuarEkleDialog() async {
    // Mevcut aksesuarları getir
    List<Map<String, dynamic>> tumAksesuarlar = [];
    try {
      final response = await supabase.from(DbTables.aksesuarlar).select('*').eq('firma_id', TenantManager.instance.requireFirmaId);
      tumAksesuarlar = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Aksesuarlar getirilemedi
    }
    
    if (tumAksesuarlar.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz aksesuar tanımlanmamış'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Zaten ekli olan aksesuar ID'lerini bul
    final mevcutAksesuarIds = modelAksesuarlari.map((a) {
      final id = a['aksesuar_id'] ?? a[DbTables.aksesuarlar]?['id'];
      return id?.toString();
    }).whereType<String>().toSet();

    // Marka listesini çıkar
    final markalar = tumAksesuarlar
        .map((a) => (a['marka'] as String?) ?? '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    
    // Filtre ve seçim state'leri
    String aramaText = '';
    String? seciliMarka;
    // secilenler: aksesuar id -> adet_per_model
    final Map<String, int> secilenler = {};
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Filtreleme
          final filtrelenmis = tumAksesuarlar.where((a) {
            final ad = (a['ad'] ?? a['aksesuar_adi'] ?? '').toString().toLowerCase();
            final sku = (a['sku'] ?? '').toString().toLowerCase();
            final marka = (a['marka'] ?? '').toString();
            final arama = aramaText.toLowerCase();
            
            if (arama.isNotEmpty && !ad.contains(arama) && !sku.contains(arama)) {
              return false;
            }
            if (seciliMarka != null && marka != seciliMarka) {
              return false;
            }
            return true;
          }).toList();

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.teal.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aksesuar Ekle${secilenler.isNotEmpty ? ' (${secilenler.length} seçili)' : ''}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  // Filtreler
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        // Arama
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Ad veya SKU ile ara...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              suffixIcon: aramaText.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setDialogState(() => aramaText = ''),
                                    )
                                  : null,
                            ),
                            onChanged: (v) => setDialogState(() => aramaText = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Marka filtresi
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            value: seciliMarka,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Marka',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('Tüm Markalar')),
                              ...markalar.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (v) => setDialogState(() => seciliMarka = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sonuç sayısı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${filtrelenmis.length} aksesuar listeleniyor',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        if (secilenler.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.deselect, size: 16),
                            label: const Text('Seçimi Temizle', style: TextStyle(fontSize: 12)),
                            onPressed: () => setDialogState(() => secilenler.clear()),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Aksesuar listesi
                  Expanded(
                    child: filtrelenmis.isEmpty
                        ? Center(
                            child: Text('Sonuç bulunamadı', style: TextStyle(color: Colors.grey[500])),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filtrelenmis.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                            itemBuilder: (_, index) {
                              final aksesuar = filtrelenmis[index];
                              final id = aksesuar['id'].toString();
                              final ad = aksesuar['ad'] ?? aksesuar['aksesuar_adi'] ?? 'Aksesuar';
                              final sku = aksesuar['sku'] ?? '';
                              final marka = aksesuar['marka'] ?? '';
                              final stok = (aksesuar['miktar'] as num?)?.toInt() ?? 0;
                              final fiyat = (aksesuar['birim_fiyat'] as num?)?.toDouble() ?? 0.0;
                              final zatenEkli = mevcutAksesuarIds.contains(id);
                              final secili = secilenler.containsKey(id);
                              final adet = secilenler[id] ?? 1;

                              return Opacity(
                                opacity: zatenEkli ? 0.5 : 1.0,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  leading: Checkbox(
                                    value: secili,
                                    onChanged: zatenEkli
                                        ? null
                                        : (val) {
                                            setDialogState(() {
                                              if (val == true) {
                                                secilenler[id] = 1;
                                              } else {
                                                secilenler.remove(id);
                                              }
                                            });
                                          },
                                    activeColor: Colors.teal,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ad,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: zatenEkli ? Colors.grey : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              children: [
                                                if (sku.isNotEmpty)
                                                  Text('SKU: $sku', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                                if (sku.isNotEmpty && marka.isNotEmpty)
                                                  Text('  •  ', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                                if (marka.isNotEmpty)
                                                  Text(marka, style: TextStyle(fontSize: 11, color: Colors.blue[700])),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Stok & Fiyat badge'leri
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: stok > 0 ? Colors.green[50] : Colors.red[50],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Stok: $stok',
                                          style: TextStyle(fontSize: 10, color: stok > 0 ? Colors.green[800] : Colors.red[800]),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple[50],
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '₺${fiyat.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 10, color: Colors.purple[800]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: zatenEkli
                                      ? Text('Zaten ekli', style: TextStyle(fontSize: 11, color: Colors.orange[700], fontStyle: FontStyle.italic))
                                      : null,
                                  // Adet input - sadece seçiliyse göster
                                  trailing: secili
                                      ? SizedBox(
                                          width: 70,
                                          height: 32,
                                          child: TextField(
                                            controller: TextEditingController(text: adet.toString()),
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13),
                                            decoration: InputDecoration(
                                              labelText: 'Adet',
                                              labelStyle: const TextStyle(fontSize: 10),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (v) {
                                              final parsed = int.tryParse(v);
                                              if (parsed != null && parsed > 0) {
                                                secilenler[id] = parsed;
                                              }
                                            },
                                          ),
                                        )
                                      : null,
                                  onTap: zatenEkli
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            if (secili) {
                                              secilenler.remove(id);
                                            } else {
                                              secilenler[id] = 1;
                                            }
                                          });
                                        },
                                ),
                              );
                            },
                          ),
                  ),
                  // Alt aksiyon çubuğu
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        if (secilenler.isNotEmpty)
                          Expanded(
                            child: Text(
                              '${secilenler.length} aksesuar seçildi',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.teal[800]),
                            ),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('İptal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(secilenler.isEmpty ? 'Seçim Yapın' : '${secilenler.length} Aksesuar Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: secilenler.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(dialogContext);
                                  // Toplu ekleme
                                  int basarili = 0;
                                  int hatali = 0;
                                  final modelIdStr = widget.modelId.toString();
                                  final firmaId = TenantManager.instance.requireFirmaId;
                                  for (final entry in secilenler.entries) {
                                    try {
                                      try {
                                        await supabase.from(DbTables.modelAksesuar).insert({
                                          'model_id': modelIdStr,
                                          'aksesuar_id': entry.key,
                                          'miktar': 1,
                                          'adet_per_model': entry.value,
                                          'firma_id': firmaId,
                                        });
                                      } catch (_) {
                                        await supabase.from(DbTables.modelAksesuar).insert({
                                          'model_id': modelIdStr,
                                          'aksesuar_id': entry.key,
                                          'firma_id': firmaId,
                                        });
                                      }
                                      basarili++;
                                    } catch (_) {
                                      hatali++;
                                    }
                                  }
                                  // Tek seferde yenile
                                  await _aksesuarlariGetir();
                                  if (mounted) {
                                    if (hatali == 0) {
                                      context.showSuccessSnackBar('$basarili aksesuar eklendi');
                                    } else {
                                      context.showErrorSnackBar('$basarili eklendi, $hatali hata oluştu');
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addAksesuar(dynamic aksesuarId, [int adetPerModel = 1]) async {
    try {
      final modelIdStr = widget.modelId.toString();
      final aksesuarIdStr = aksesuarId.toString();
      
      try {
        // Tüm kolonlarla dene (miktar, adet_per_model varsa)
        await supabase.from(DbTables.modelAksesuar).insert({
          'model_id': modelIdStr,
          'aksesuar_id': aksesuarIdStr,
          'miktar': 1,
          'adet_per_model': adetPerModel,
          'firma_id': TenantManager.instance.requireFirmaId,
        });
      } catch (_) {
        // Yalnız zorunlu kolonlarla dene
        await supabase.from(DbTables.modelAksesuar).insert({
          'model_id': modelIdStr,
          'aksesuar_id': aksesuarIdStr,
          'firma_id': TenantManager.instance.requireFirmaId,
        });
      }
      
      // Aksesuarları yeniden yükle
      await _aksesuarlariGetir();
      
      if (mounted) {
        context.showSuccessSnackBar('✅ Aksesuar eklendi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('❌ Hata: $e');
      }
    }
  }

  Widget _buildStokInfoTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAksesuar(dynamic id) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aksesuar Sil'),
        content: const Text('Bu aksesuarı modelden kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (onay == true) {
      try {
        await supabase.from(DbTables.modelAksesuar).delete().eq('id', id);
        await _aksesuarlariGetir();
        
        if (!mounted) return;
        context.showSuccessSnackBar('✅ Aksesuar kaldırıldı');
      } catch (e) {
        if (!mounted) return;
        context.showErrorSnackBar('❌ Hata: $e');
      }
    }
  }
}

Widget buildModelMaliyetCard(double birModelMaliyeti) {
  return Card(
    color: Colors.white,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            child: const Icon(Icons.looks_one, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1 Model Maliyeti', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '₺${birModelMaliyeti.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget buildToplamMaliyetCard(double toplamAksesuarMaliyeti, int siparisAdedi) {
  return Card(
    color: Colors.white,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.shade100,
            child: const Icon(Icons.calculate, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Toplam Maliyet ($siparisAdedi adet)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '₺${toplamAksesuarMaliyeti.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
