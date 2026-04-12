part of 'utu_paket_dashboard.dart';

/// Çeki Listesi (Pull List) panel methods for _UtuPaketDashboardState.
extension _CekiListesiExt on _UtuPaketDashboardState {
  // ============ ÇEKİ LİSTESİ PANELİ ============

  Widget _buildCekiListesiPanel() {
    // Çeki listesini model bazında grupla
    final Map<String, List<Map<String, dynamic>>> modelBazliKoliler = {};
    for (var kayit in cekiListesi) {
      final modelId = kayit['model_id']?.toString() ?? 'unknown';
      if (!modelBazliKoliler.containsKey(modelId)) {
        modelBazliKoliler[modelId] = [];
      }
      modelBazliKoliler[modelId]!.add(kayit);
    }

    return Column(
      children: [
        // Özet kartları
        _buildCekiOzet(),
        // Çeki listesi
        Expanded(
          child: cekiListesi.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Çeki listesinde kayıt yok',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _verileriYukle,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: modelBazliKoliler.length,
                    itemBuilder: (context, index) {
                      final modelId = modelBazliKoliler.keys.elementAt(index);
                      final koliler = modelBazliKoliler[modelId]!;
                      return _buildModelGrupKarti(koliler);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCekiOzet() {
    final toplamKoli = cekiListesi.fold<int>(
        0, (sum, item) => sum + ((item['koli_adedi'] ?? 1) as int));
    final toplamAdet = cekiListesi.fold<int>(
        0,
        (sum, item) =>
            sum + ((item['adet'] ?? item['tamamlanan_adet'] ?? 0) as int));
    final bekleyenler = cekiListesi
        .where((item) => item['gonderim_durumu'] != 'gonderildi')
        .length;
    final gonderilenler = cekiListesi
        .where((item) => item['gonderim_durumu'] == 'gonderildi')
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.amber[50],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 500;

          if (isMobile) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildOzetKart('Toplam Koli', '$toplamKoli',
                            Icons.inventory_2, Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildOzetKart('Toplam Adet', '$toplamAdet',
                            Icons.format_list_numbered, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildOzetKart('Bekleyen', '$bekleyenler',
                            Icons.hourglass_empty, Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildOzetKart('Gönderilen', '$gonderilenler',
                            Icons.local_shipping, Colors.green)),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                  child: _buildOzetKart('Toplam Koli', '$toplamKoli',
                      Icons.inventory_2, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildOzetKart('Toplam Adet', '$toplamAdet',
                      Icons.format_list_numbered, Colors.purple)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildOzetKart('Bekleyen', '$bekleyenler',
                      Icons.hourglass_empty, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildOzetKart('Gönderilen', '$gonderilenler',
                      Icons.local_shipping, Colors.green)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOzetKart(
      String baslik, String deger, IconData icon, Color renk) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: renk, size: 24),
            const SizedBox(height: 6),
            Text(deger,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: renk)),
            Text(baslik,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }


  // Çeki detay göster
  void _cekiDetayGoster(Map<String, dynamic> kayit) {
    final model = kayit[DbTables.trikoTakip] as Map<String, dynamic>?;
    final koliNo = kayit['koli_no'] ?? 'KOL-${kayit['id']}';
    final koliAdedi = kayit['koli_adedi'] ?? 1;
    final adet = kayit['adet'] ?? 0;
    final bedenKodu = kayit['beden_kodu'] ?? '-';
    final adetPerKoli = kayit['adet_per_koli'] ?? '-';
    final gonderimDurumu = kayit['gonderim_durumu'] ?? 'bekliyor';
    final paketlemeTarihi = kayit['paketleme_tarihi'];
    final gonderimTarihi = kayit['gonderim_tarihi'];
    final notlar = kayit['notlar'];
    final isMixKoli = kayit['is_mix_koli'] == true;
    final mixBedenDetay = kayit['mix_beden_detay'] as List<dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Expanded(child: Text(koliNo.toString())),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model Bilgisi
              if (model != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Model Bilgisi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900])),
                      const Divider(),
                      Text('${model['marka']} - ${model['item_no']}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (model['renk'] != null)
                        Text('Renk: ${model['renk']}',
                            style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Koli Bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Koli Bilgileri',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900])),
                    const Divider(),
                    _buildDetayRow('Koli Sayısı', '$koliAdedi koli'),
                    _buildDetayRow('Toplam Adet', '$adet adet'),
                    if (!isMixKoli) ...[
                      _buildDetayRow('Beden', bedenKodu),
                      _buildDetayRow('Koli Başı Adet', adetPerKoli.toString()),
                    ],
                    if (isMixKoli && mixBedenDetay != null && mixBedenDetay.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildDetayRow('Beden', mixBedenDetay.map((b) => b['beden']).join(', ')),
                      _buildDetayRow('Koli Başı Adet', adetPerKoli.toString()),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shuffle,
                                    size: 16, color: Colors.purple[700]),
                                const SizedBox(width: 4),
                                Text('Beden Dağılımı',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[700])),
                              ],
                            ),
                            const Divider(),
                            ...mixBedenDetay.map((b) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${b['beden']}:'),
                                      Text('${b['adet']} adet',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Durum Bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gonderimDurumu == 'gonderildi'
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Durum Bilgileri',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gonderimDurumu == 'gonderildi'
                                ? Colors.green[900]
                                : Colors.orange[900])),
                    const Divider(),
                    _buildDetayRow(
                        'Durum',
                        gonderimDurumu == 'gonderildi'
                            ? '✅ Gönderildi'
                            : '⏳ Bekliyor'),
                    if (paketlemeTarihi != null)
                      _buildDetayRow('Paketleme Tarihi',
                          dateFormat.format(DateTime.parse(paketlemeTarihi))),
                    if (gonderimTarihi != null)
                      _buildDetayRow('Gönderim Tarihi',
                          dateFormat.format(DateTime.parse(gonderimTarihi))),
                  ],
                ),
              ),

              // Notlar
              if (notlar != null && notlar.toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notlar',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                      const Divider(),
                      Text(notlar.toString()),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Model bazında gruplandırılmış çeki kartı
  Widget _buildModelGrupKarti(List<Map<String, dynamic>> koliler) {
    if (koliler.isEmpty) return const SizedBox.shrink();

    final ilkKayit = koliler.first;
    final model = ilkKayit[DbTables.trikoTakip] as Map<String, dynamic>?;
    final toplamKoliAdet =
        koliler.fold<int>(0, (sum, k) => sum + ((k['koli_adedi'] ?? 1) as int));
    final toplamUrunAdet =
        koliler.fold<int>(0, (sum, k) => sum + ((k['adet'] ?? 0) as int));
    final bekleyenKoli =
        koliler.where((k) => k['gonderim_durumu'] != 'gonderildi').length;
    final gonderilenKoli =
        koliler.where((k) => k['gonderim_durumu'] == 'gonderildi').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.view_module, color: Colors.amber[700]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            tooltip: 'Tüm çekileri sil',
            onPressed: () => _modelCekileriniTopluSil(koliler),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${model?['marka'] ?? '-'} • ${model?['item_no'] ?? '-'}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              if (model?['renk'] != null)
                Text(
                  'Renk: ${model!['renk']}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoBadge(
                    Icons.inventory_2, '$toplamKoliAdet koli', Colors.blue),
                _buildInfoBadge(Icons.format_list_numbered,
                    '$toplamUrunAdet adet', Colors.purple),
                if (gonderilenKoli > 0)
                  _buildInfoBadge(Icons.local_shipping,
                      '$gonderilenKoli gönderildi', Colors.green),
                if (bekleyenKoli > 0)
                  _buildInfoBadge(Icons.hourglass_empty,
                      '$bekleyenKoli bekliyor', Colors.orange),
              ],
            ),
          ),
          children:
              koliler.map((kayit) => _buildCekiKartiKucuk(kayit)).toList(),
        ),
      ),
    );
  }

  // Grup içinde gösterilen küçük çeki kartı
  Widget _buildCekiKartiKucuk(Map<String, dynamic> kayit) {
    final koliNo = kayit['koli_no'] ?? 'KOL-${kayit['id']}';
    final koliAdedi = kayit['koli_adedi'] ?? 1;
    final adet = kayit['adet'] ?? kayit['tamamlanan_adet'] ?? 0;
    final bedenKodu = kayit['beden_kodu'] ?? '-';
    final adetPerKoli = kayit['adet_per_koli'] ?? '-';
    final gonderimDurumu = kayit['gonderim_durumu'] ?? 'bekliyor';
    final gonderildi = gonderimDurumu == 'gonderildi';
    final isMixKoli = kayit['is_mix_koli'] == true;
    final mixBedenDetay = kayit['mix_beden_detay'] as List<dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: gonderildi ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gonderildi ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tıklanabilir bilgi alanı
          InkWell(
            onTap: () => _cekiDetayGoster(kayit),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
            children: [
              Icon(
                isMixKoli ? Icons.shuffle : Icons.inventory_2,
                size: 20,
                color: isMixKoli ? Colors.purple[600] : Colors.amber[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      koliNo.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    if (isMixKoli)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MİX',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700]),
                        ),
                      )
                    else if (bedenKodu != '-')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bedenKodu.toString(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700]),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gonderildi
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  gonderildi ? 'Gönderildi' : 'Bekliyor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: gonderildi ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildInfoBadge(
                  Icons.inventory_2, '$koliAdedi koli', Colors.blue),
              _buildInfoBadge(
                  Icons.format_list_numbered, '$adet adet', Colors.purple),
              if (adetPerKoli != '-' && !isMixKoli)
                _buildInfoBadge(
                    Icons.all_inbox, '$adetPerKoli/koli', Colors.orange),
            ],
          ),
          // Mix Koli detayı
          if (isMixKoli &&
              mixBedenDetay != null &&
              mixBedenDetay.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: mixBedenDetay.map<Widget>((item) {
                  final beden = item['beden'] ?? '-';
                  final adetPer = item['adet'] ?? 0;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$beden: $adetPer',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple[700]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          // Kargo bilgisi
          if (gonderildi &&
              (kayit['kargo_firmasi'] != null ||
                  kayit['takip_no'] != null)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping,
                      size: 14, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kayit['kargo_firmasi'] != null)
                          Text(
                            '${kayit['kargo_firmasi']}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700]),
                          ),
                        if (kayit['takip_no'] != null)
                          Text(
                            'Takip: ${kayit['takip_no']}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
              ],
            ),
          ),
          // InkWell bitti - Butonlar aşağıda
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _cekiDuzenleDialogu(kayit),
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: Colors.blue,
                tooltip: 'Düzenle',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (currentUserRole == 'admin' || currentUserRole == 'mudur')
                IconButton(
                  onPressed: () => _cekiSil(kayit),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: Colors.red,
                  tooltip: 'Sil',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              if (!gonderildi)
                ElevatedButton.icon(
                  onPressed: () => _gonderimDurumuGuncelle(kayit),
                  icon: const Icon(Icons.local_shipping, size: 14),
                  label: const Text('Gönder', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildAtamaKarti(Map<String, dynamic> atama, String tip) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>?;
    final durum = atama['durum'] ?? 'bekleyen';
    final adet =
        atama['talep_edilen_adet'] ?? atama['adet'] ?? model?['adet'] ?? 0;
    final tamamlananAdet = atama['tamamlanan_adet'] ?? 0;

    Color durumRengi;
    switch (durum) {
      case 'bekleyen':
        durumRengi = Colors.orange;
        break;
      case 'onaylandi':
        durumRengi = Colors.green;
        break;
      case 'devam_ediyor':
      case 'uretimde':
        durumRengi = Colors.blue;
        break;
      case 'tamamlandi':
        durumRengi = Colors.grey;
        break;
      case 'reddedildi':
        durumRengi = Colors.red;
        break;
      default:
        durumRengi = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _atamaDetayGoster(atama, tip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: Marka, Model, Durum
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (tip == 'utu' ? Colors.amber : Colors.brown)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      tip == 'utu' ? Icons.iron : Icons.inventory_2,
                      color: tip == 'utu' ? Colors.amber[700] : Colors.brown,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model?['marka'] ?? 'Bilinmiyor',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${model?['item_no'] ?? '-'} • ${model?['renk'] ?? '-'}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: durumRengi.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _durumMetni(durum),
                      style: TextStyle(
                          color: durumRengi,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              // Alt satır: Bilgiler ve aksiyonlar
              Row(
                children: [
                  _buildInfoBadge(
                      Icons.format_list_numbered, '$adet adet', Colors.purple),
                  const SizedBox(width: 8),
                  if (tamamlananAdet > 0)
                    _buildInfoBadge(
                        Icons.check, '$tamamlananAdet yapıldı', Colors.green),
                  const Spacer(),
                  // Aksiyon butonları - tüm kullanıcılar görür
                  if (durum == 'bekleyen' || durum == 'atandi') ...[
                    _buildActionButton(
                        Icons.check, Colors.green, () => _onayla(atama, tip)),
                    const SizedBox(width: 4),
                    _buildActionButton(
                        Icons.close, Colors.red, () => _reddet(atama, tip)),
                  ],
                  if (durum == 'onaylandi') ...[
                    _buildActionButton(Icons.play_arrow, Colors.blue,
                        () => _basla(atama, tip)),
                  ],
                  if (durum == 'devam_ediyor' || durum == 'uretimde') ...[
                    // Paketleme için Mix Koli butonu
                    if (tip == 'paketleme') ...[
                      _buildActionButton(Icons.shuffle, Colors.purple,
                          () => _mixKoliDialogu(atama)),
                      const SizedBox(width: 4),
                    ],
                    _buildActionButton(Icons.done, Colors.green,
                        () => _tamamlaDialoguGoster(atama, tip)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }


  String _durumMetni(String durum) {
    switch (durum) {
      case 'bekleyen':
        return 'Bekliyor';
      case 'onaylandi':
        return 'Onaylandı';
      case 'devam_ediyor':
      case 'uretimde':
        return 'İşlemde';
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'reddedildi':
        return 'Reddedildi';
      default:
        return durum;
    }
  }
}
