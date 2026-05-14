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
                    if (isMixKoli &&
                        mixBedenDetay != null &&
                        mixBedenDetay.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildDetayRow('Beden',
                          mixBedenDetay.map((b) => b['beden']).join(', ')),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          color: gonderildi
                              ? Colors.green[700]
                              : Colors.orange[700],
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
                    _buildInfoBadge(Icons.format_list_numbered, '$adet adet',
                        Colors.purple),
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
                      border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.2)),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: mixBedenDetay.map<Widget>((item) {
                        final beden = item['beden'] ?? '-';
                        final adetPer = item['adet'] ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.3)),
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
    final durum = (atama['durum'] ?? 'bekleyen').toString();
    final talepEdilenAdet = _atamaInt(
        atama['talep_edilen_adet'] ?? atama['adet'] ?? model?['adet']);
    final kabulEdilenAdet = _atamaInt(
      atama['kabul_edilen_adet'] ??
          atama['talep_edilen_adet'] ??
          atama['adet'] ??
          model?['adet'],
    );
    final tamamlananAdet = _atamaInt(atama['tamamlanan_adet']);
    final kalanAdet = (kabulEdilenAdet - tamamlananAdet).clamp(0, 999999999);
    final ilerleme = kabulEdilenAdet <= 0
        ? 0.0
        : (tamamlananAdet / kabulEdilenAdet).clamp(0.0, 1.0);
    final durumRengi = _utuPaketDurumRengi(durum);
    final asamaRengi =
        tip == 'utu' ? const Color(0xFFD97706) : const Color(0xFF7C2D12);
    final asamaIconu = tip == 'utu' ? Icons.iron : Icons.inventory_2_outlined;
    final notMetni = _temizNotMetni(atama['notlar'] ?? atama['aciklama']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _atamaDetayGoster(atama, tip),
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: durumRengi,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: asamaRengi.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                Icon(asamaIconu, color: asamaRengi, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${model?['marka'] ?? 'Bilinmeyen Marka'} - ${model?['item_no'] ?? 'Bilinmeyen Model'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    _buildUtuPaketKisaBilgi(
                                      Icons.palette_outlined,
                                      (model?['renk'] ?? '-').toString(),
                                    ),
                                    _buildUtuPaketKisaBilgi(
                                      Icons.event_outlined,
                                      _kisaTarih(model?['termin_tarihi']),
                                    ),
                                    if (atama['atama_tarihi'] != null)
                                      _buildUtuPaketKisaBilgi(
                                        Icons.assignment_ind_outlined,
                                        _kisaTarihSaat(atama['atama_tarihi']),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildUtuPaketDurumPili(durum),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildUtuPaketMetric(
                            'Sipariş',
                            _adetMetni(talepEdilenAdet),
                            Icons.inventory_2_outlined,
                            const Color(0xFF2563EB),
                          ),
                          _buildUtuPaketMetric(
                            'Kabul',
                            _adetMetni(kabulEdilenAdet),
                            Icons.verified_outlined,
                            const Color(0xFF16A34A),
                          ),
                          _buildUtuPaketMetric(
                            'Tamamlanan',
                            _adetMetni(tamamlananAdet),
                            Icons.task_alt,
                            const Color(0xFF0F766E),
                          ),
                          _buildUtuPaketMetric(
                            'Kalan',
                            _adetMetni(kalanAdet),
                            Icons.pending_actions,
                            const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                      if (kabulEdilenAdet > 0 &&
                          (durum == 'onaylandi' ||
                              durum == 'devam_ediyor' ||
                              durum == 'uretimde')) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  minHeight: 8,
                                  value: ilerleme,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(durumRengi),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '%${(ilerleme * 100).round()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: durumRengi,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (notMetni.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            notMetni,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildUtuPaketAksiyonButonlari(
                          atama,
                          tip,
                          durum,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtuPaketKisaBilgi(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildUtuPaketMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 126),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUtuPaketDurumPili(String? durum) {
    final color = _utuPaketDurumRengi(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _durumMetni(durum ?? 'bekleyen'),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildUtuPaketAksiyonButonlari(
    Map<String, dynamic> atama,
    String tip,
    String durum,
  ) {
    final bekliyor = durum == 'bekleyen' || durum == 'atandi';
    final islemde = durum == 'devam_ediyor' || durum == 'uretimde';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => _atamaDetayGoster(atama, tip),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Detay'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
          ),
        ),
        if (bekliyor) ...[
          ElevatedButton.icon(
            onPressed: () => _onayla(atama, tip),
            icon: const Icon(Icons.thumb_up, size: 18),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _reddet(atama, tip),
            icon: const Icon(Icons.thumb_down, size: 18),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
          ),
        ],
        if (durum == 'onaylandi')
          ElevatedButton.icon(
            onPressed: () => _basla(atama, tip),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Üretime Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
          ),
        if (islemde)
          ElevatedButton.icon(
            onPressed: () => _utuBedenliBitirDialogu(atama),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Ütü Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  int _atamaInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _adetMetni(int value) =>
      NumberFormat.decimalPattern('tr_TR').format(value);

  String _kisaTarih(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  String _kisaTarihSaat(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
  }

  Color _utuPaketDurumRengi(String? durum) {
    switch (durum) {
      case 'atandi':
      case 'bekleyen':
      case 'beklemede':
        return const Color(0xFFEA580C);
      case 'onaylandi':
        return const Color(0xFF16A34A);
      case 'reddedildi':
        return const Color(0xFFDC2626);
      case 'devam_ediyor':
      case 'uretimde':
      case 'baslatildi':
      case 'kismi_tamamlandi':
        return const Color(0xFF2563EB);
      case 'tamamlandi':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF64748B);
    }
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
