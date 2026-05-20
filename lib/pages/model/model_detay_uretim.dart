// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Uretim durumu tab'i - uretim akis grafigi, asama detay ve atama islemleri
extension _UretimExt on _ModelDetayState {
  Widget _buildUretimDurumuTab() {
    final asamaDurumlari = _getAsamaDurumlari();
    final toplamAdet = _uretimInt(currentModelData?['toplam_adet'] ??
        currentModelData?['adet'] ??
        currentModelData?['siparis_adedi']);
    final atananAdet = _getTotalAtananAdet();
    final tamamlananAdet = _getTotalTamamlananAdet();
    final kalanAdet =
        atananAdet > tamamlananAdet ? atananAdet - tamamlananAdet : 0;
    final aktifAsama = _aktifUretimAsamasi(asamaDurumlari);
    final tamamlananAsamaSayisi =
        asamaDurumlari.where((a) => a['durum'] == 'tamamlandi').length;
    final devamEdenSayisi =
        asamaDurumlari.where((a) => a['durum'] == 'devam_ediyor').length;
    final bekleyenSayisi =
        asamaDurumlari.where((a) => a['durum'] == 'bekliyor').length;
    final ilerleme = atananAdet > 0 ? tamamlananAdet / atananAdet : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUretimErpBaslik(
            toplamAdet: toplamAdet,
            atananAdet: atananAdet,
            tamamlananAdet: tamamlananAdet,
            kalanAdet: kalanAdet,
            aktifAsama: aktifAsama,
            ilerleme: ilerleme,
          ),
          const SizedBox(height: 14),
          _buildUretimKpiSeridi(
            tamamlananAsamaSayisi: tamamlananAsamaSayisi,
            devamEdenSayisi: devamEdenSayisi,
            bekleyenSayisi: bekleyenSayisi,
            atananAdet: atananAdet,
            tamamlananAdet: tamamlananAdet,
            kalanAdet: kalanAdet,
          ),
          const SizedBox(height: 16),
          _buildUretimAkisGrafigi(asamaDurumlari),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1120;
              if (!wide) {
                return Column(
                  children: [
                    _buildAsamaMatrisi(asamaDurumlari),
                    const SizedBox(height: 16),
                    _buildAsamaOperasyonListesi(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildAsamaMatrisi(asamaDurumlari)),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildAsamaOperasyonListesi()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUretimErpBaslik({
    required int toplamAdet,
    required int atananAdet,
    required int tamamlananAdet,
    required int kalanAdet,
    required Map<String, dynamic>? aktifAsama,
    required double ilerleme,
  }) {
    final progress = ilerleme.clamp(0.0, 1.0);
    final aktifAsamaAdi = aktifAsama?['ad']?.toString() ?? 'Plan bekliyor';
    final marka = currentModelData?['marka']?.toString() ?? '-';
    final itemNo = currentModelData?['item_no']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final title = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.factory, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$marka - $itemNo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Aktif aşama: $aktifAsamaAdi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF607D8B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final progressBlock = SizedBox(
            width: compact ? double.infinity : 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Üretim İlerlemesi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF607D8B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '%${(progress * 100).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF102A43),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: progress,
                    backgroundColor: const Color(0xFFE8EEF5),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_adetMetni(tamamlananAdet)} tamamlandı / ${_adetMetni(atananAdet)} atanmış / ${_adetMetni(kalanAdet)} kalan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF607D8B),
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                progressBlock,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              progressBlock,
            ],
          );
        },
      ),
    );
  }

  Widget _buildUretimKpiSeridi({
    required int tamamlananAsamaSayisi,
    required int devamEdenSayisi,
    required int bekleyenSayisi,
    required int atananAdet,
    required int tamamlananAdet,
    required int kalanAdet,
  }) {
    final items = [
      _UretimKpi('Atanmış Adet', _adetMetni(atananAdet), Icons.assignment,
          const Color(0xFF1565C0)),
      _UretimKpi('Tamamlanan', _adetMetni(tamamlananAdet), Icons.check_circle,
          const Color(0xFF2E7D32)),
      _UretimKpi('Kalan İş', _adetMetni(kalanAdet), Icons.pending_actions,
          const Color(0xFFEF6C00)),
      _UretimKpi('Devam Eden Aşama', '$devamEdenSayisi', Icons.autorenew,
          const Color(0xFF7B1FA2)),
      _UretimKpi('Tamamlanan Aşama', '$tamamlananAsamaSayisi', Icons.verified,
          const Color(0xFF00897B)),
      _UretimKpi('Bekleyen Aşama', '$bekleyenSayisi', Icons.schedule,
          const Color(0xFF607D8B)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map(_buildUretimKpi).toList(),
    );
  }

  Widget _buildUretimKpi(_UretimKpi item) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF607D8B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF102A43),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Üretim akış grafiği - Modelin hangi aşamalardan geçtiğini gösterir
  Widget _buildUretimAkisGrafigi(List<Map<String, dynamic>> asamaDurumlari) {
    return _erpPanel(
      title: 'Üretim Akış Durumu',
      icon: Icons.timeline,
      trailing: TextButton.icon(
        onPressed: () => _showAkisDetayDialog(asamaDurumlari),
        icon: const Icon(Icons.info_outline, size: 18),
        label: const Text('Detay'),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildAkisAdimlari(asamaDurumlari),
        ),
      ),
    );
  }

  Widget _erpPanel({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1565C0), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildAsamaMatrisi(List<Map<String, dynamic>> asamaDurumlari) {
    return _erpPanel(
      title: 'Aşama Kontrol Matrisi',
      icon: Icons.view_list,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth < 720 ? 720.0 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 23, child: _UretimTableHeader('Aşama')),
                        Expanded(flex: 14, child: _UretimTableHeader('Durum')),
                        Expanded(flex: 16, child: _UretimTableHeader('Atanan')),
                        Expanded(
                            flex: 16, child: _UretimTableHeader('Tamamlanan')),
                        Expanded(
                            flex: 18, child: _UretimTableHeader('İlerleme')),
                        SizedBox(width: 38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...asamaDurumlari.map(_buildAsamaMatrisiSatiri),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAsamaMatrisiSatiri(Map<String, dynamic> asama) {
    final durum = asama['durum']?.toString() ?? 'bekliyor';
    final toplam = _uretimInt(asama['toplamAdet']);
    final tamamlanan = _uretimInt(asama['tamamlananAdet']);
    final oran = toplam > 0 ? (tamamlanan / toplam).clamp(0.0, 1.0) : 0.0;
    final durumRengi = _asamaDurumRengi(durum);
    final durumMetni = _asamaDurumMetni(durum);

    return InkWell(
      onTap: () => _showAsamaDetayDialog(asama),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7ECF2))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 23,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: durumRengi.withAlpha(20),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(asama['icon'] as IconData,
                        color: durumRengi, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asama['ad']?.toString() ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _durumEtiketi(durumMetni, durumRengi),
              ),
            ),
            Expanded(flex: 16, child: Text(_adetMetni(toplam))),
            Expanded(flex: 16, child: Text(_adetMetni(tamamlanan))),
            Expanded(
              flex: 18,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: oran,
                        backgroundColor: const Color(0xFFE8EEF5),
                        valueColor: AlwaysStoppedAnimation<Color>(durumRengi),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '%${(oran * 100).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF607D8B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 38,
              child: IconButton(
                tooltip: 'Aşama detayını aç',
                onPressed: () => _showAsamaDetayDialog(asama),
                icon: const Icon(Icons.open_in_new, size: 18),
                color: const Color(0xFF607D8B),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _aktifModelAsamaKodlari() {
    const desteklenenAsamalar = {
      'dokuma',
      'konfeksiyon',
      'nakis',
      'yikama',
      'ilik_dugme',
      'utu',
      'kalite_kontrol',
      'paketleme',
    };
    final aktifAsamalar = AsamaRegistry.asamalariGetir(_modelUretimDali)
        .where((asama) => asama.asamaKodu != 'sevkiyat')
        .map((asama) => asama.asamaKodu == 'orgu' ? 'dokuma' : asama.asamaKodu)
        .where(desteklenenAsamalar.contains)
        .toSet();

    if (aktifAsamalar.isNotEmpty) {
      return aktifAsamalar;
    }

    return desteklenenAsamalar;
  }

  Widget _buildAsamaOperasyonListesi() {
    final asamalar = [
      (
        'Örgü/Dokuma',
        orguUretimKayitlari,
        dokumaAtamalari,
        Icons.grain,
        'orgu',
        const Color(0xFF6D4C41)
      ),
      (
        'Konfeksiyon',
        konfeksiyonUretimKayitlari,
        konfeksiyonAtamalari,
        Icons.content_cut,
        'konfeksiyon',
        const Color(0xFF6A1B9A)
      ),
      (
        'Nakış',
        nakisUretimKayitlari,
        nakisAtamalari,
        Icons.brush,
        'nakis',
        const Color(0xFFC2185B)
      ),
      (
        'Yıkama',
        yikamaUretimKayitlari,
        yikamaAtamalari,
        Icons.local_laundry_service,
        'yikama',
        const Color(0xFF00838F)
      ),
      (
        'İlik Düğme',
        ilikDugmeUretimKayitlari,
        ilikDugmeAtamalari,
        Icons.radio_button_unchecked,
        'ilik_dugme',
        const Color(0xFF3949AB)
      ),
      (
        'Ütü',
        utuUretimKayitlari,
        utuAtamalari,
        Icons.iron,
        'utu',
        const Color(0xFFC62828)
      ),
    ];
    asamalar.add((
      'Kalite Kontrol',
      <dynamic>[],
      kaliteKontrolAtamalari,
      Icons.verified,
      'kalite_kontrol',
      const Color(0xFF00897B)
    ));
    asamalar.add((
      'Paketleme',
      <dynamic>[],
      paketlemeAtamalari,
      Icons.inventory_2,
      'paketleme',
      const Color(0xFF2E7D32)
    ));
    final aktifKodlar = _aktifModelAsamaKodlari();
    final gorunenAsamalar = asamalar
        .where((a) => aktifKodlar.contains(a.$5 == 'orgu' ? 'dokuma' : a.$5))
        .toList();

    return _erpPanel(
      title: kullaniciRolu == 'admin' ? 'Operasyon Atamaları' : 'Atanan İşler',
      icon: Icons.assignment_turned_in,
      child: Column(
        children: gorunenAsamalar
            .map((a) => _buildOperasyonKarti(
                  a.$1,
                  a.$2,
                  a.$3,
                  a.$4,
                  a.$5,
                  a.$6,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildOperasyonKarti(
    String baslik,
    List<dynamic> kayitlar,
    List<dynamic> atamaKayitlari,
    IconData icon,
    String asamaKey,
    Color color,
  ) {
    int toplamAdet = 0;
    int tamamlananAdet = 0;
    for (final atama in atamaKayitlari) {
      if (atama is! Map) continue;
      toplamAdet +=
          _uretimInt(atama['adet'] ?? atama['talep_edilen_adet'] ?? 0);
      tamamlananAdet += _uretimInt(atama['tamamlanan_adet']);
    }

    final durum = _operasyonDurumu(atamaKayitlari, toplamAdet, tamamlananAdet);
    final durumRengi = _asamaDurumRengi(durum);
    final kalan = toplamAdet > tamamlananAdet ? toplamAdet - tamamlananAdet : 0;
    final sonKayit = _sonUretimKaydiTarihi(kayitlar);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        baslik,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sonKayit == null
                            ? '${atamaKayitlari.length} atama kaydı'
                            : '${atamaKayitlari.length} atama kaydı, son kayıt $sonKayit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF607D8B),
                        ),
                      ),
                    ],
                  ),
                ),
                _durumEtiketi(_asamaDurumMetni(durum), durumRengi),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _miniUretimMetrik('Atanan', _adetMetni(toplamAdet)),
                _miniUretimMetrik('Tamamlanan', _adetMetni(tamamlananAdet)),
                _miniUretimMetrik('Kalan', _adetMetni(kalan)),
                if (kullaniciRolu == 'admin')
                  IconButton(
                    tooltip: 'Yeni atama yap',
                    onPressed: () => _showAtamaDialog(asamaKey),
                    icon: const Icon(Icons.add_task),
                    color: const Color(0xFF1565C0),
                  ),
              ],
            ),
          ),
          if (atamaKayitlari.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: atamaKayitlari
                    .take(3)
                    .map((atama) => _buildAtamaItem(
                        Map<String, dynamic>.from(atama), asamaKey))
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Bu aşama için atama bulunmuyor.',
                  style: TextStyle(color: Color(0xFF607D8B), fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniUretimMetrik(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF607D8B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF102A43),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Her aşamanın durumunu hesapla
  List<Map<String, dynamic>> _getAsamaDurumlari() {
    final asamalar = [
      {
        'ad': 'Dokuma',
        'kod': 'dokuma',
        'icon': Icons.grain,
        'renk': Colors.brown,
        'atamalar': dokumaAtamalari,
      },
      {
        'ad': 'Konfeksiyon',
        'kod': 'konfeksiyon',
        'icon': Icons.content_cut,
        'renk': Colors.purple,
        'atamalar': konfeksiyonAtamalari,
      },
      {
        'ad': 'Nakış',
        'kod': 'nakis',
        'icon': Icons.brush,
        'renk': Colors.pink,
        'atamalar': nakisAtamalari,
      },
      {
        'ad': 'Yıkama',
        'kod': 'yikama',
        'icon': Icons.local_laundry_service,
        'renk': Colors.cyan,
        'atamalar': yikamaAtamalari,
      },
      {
        'ad': 'İlik/Düğme',
        'kod': 'ilik_dugme',
        'icon': Icons.radio_button_unchecked,
        'renk': Colors.indigo,
        'atamalar': ilikDugmeAtamalari,
      },
      {
        'ad': 'Ütü',
        'kod': 'utu',
        'icon': Icons.iron,
        'renk': Colors.orange,
        'atamalar': utuAtamalari,
      },
      {
        'ad': 'Kalite Kontrol',
        'kod': 'kalite_kontrol',
        'icon': Icons.verified,
        'renk': Colors.teal,
        'atamalar': kaliteKontrolAtamalari,
      },
      {
        'ad': 'Paketleme',
        'kod': 'paketleme',
        'icon': Icons.inventory_2,
        'renk': Colors.green,
        'atamalar': paketlemeAtamalari,
      },
    ];
    final aktifKodlar = _aktifModelAsamaKodlari();
    final gorunenAsamalar =
        asamalar.where((asama) => aktifKodlar.contains(asama['kod'])).toList();

    return gorunenAsamalar.map((asama) {
      final atamalar = asama['atamalar'] as List<dynamic>;
      String durum = 'bekliyor';
      int toplamAdet = 0;
      int tamamlananAdet = 0;
      DateTime? baslangicTarihi;
      DateTime? bitisTarihi;
      String? tedarikciAdi;
      bool tumAtamalarTamamlandi = true;
      bool enAzBirAtamaVar = false;
      bool enAzBirAtamaDevamEdiyor = false;

      for (var atama in atamalar) {
        enAzBirAtamaVar = true;
        final atamaAdet = _uretimInt(atama['adet'] ??
            atama['talep_edilen_adet'] ??
            atama['kontrol_edilecek_adet'] ??
            0);
        final atamaTamamlanan = _uretimInt(atama['tamamlanan_adet']);
        final atamaDurum = atama['durum']?.toString().toLowerCase() ?? '';

        toplamAdet += atamaAdet;
        tamamlananAdet += atamaTamamlanan;

        // Atama durumunu kontrol et
        if (atamaDurum != 'tamamlandi') {
          tumAtamalarTamamlandi = false;
        }
        if (atamaDurum == 'devam_ediyor' ||
            atamaDurum == 'uretimde' ||
            atamaDurum == 'baslatildi' ||
            atamaDurum == 'kismi_tamamlandi') {
          enAzBirAtamaDevamEdiyor = true;
        }

        // Başlangıç tarihini al
        if (atama['created_at'] != null || atama['atama_tarihi'] != null) {
          final tarihStr = atama['atama_tarihi'] ?? atama['created_at'];
          final createdAt = DateTime.tryParse(tarihStr.toString());
          if (createdAt != null &&
              (baslangicTarihi == null ||
                  createdAt.isBefore(baslangicTarihi))) {
            baslangicTarihi = createdAt;
          }
        }

        // Bitiş tarihini al (tamamlanma tarihi)
        if (atamaDurum == 'tamamlandi') {
          final tarihStr = atama['tamamlama_tarihi'] ?? atama['updated_at'];
          if (tarihStr != null) {
            final updatedAt = DateTime.tryParse(tarihStr.toString());
            if (updatedAt != null &&
                (bitisTarihi == null || updatedAt.isAfter(bitisTarihi))) {
              bitisTarihi = updatedAt;
            }
          }
        }

        // Tedarikçi adını al
        if (tedarikciAdi == null && atama['tedarikci_adi'] != null) {
          tedarikciAdi = atama['tedarikci_adi'].toString();
        }
      }

      // Durumu belirle - öncelikli olarak atama durumlarına bak
      if (!enAzBirAtamaVar) {
        durum = 'bekliyor';
      } else if (tumAtamalarTamamlandi && enAzBirAtamaVar) {
        durum = 'tamamlandi';
      } else if (enAzBirAtamaDevamEdiyor || tamamlananAdet > 0) {
        durum = 'devam_ediyor';
      } else {
        durum = 'atandi';
      }

      return {
        'ad': asama['ad'],
        'kod': asama['kod'],
        'icon': asama['icon'],
        'renk': asama['renk'],
        'durum': durum,
        'toplamAdet': toplamAdet,
        'tamamlananAdet': tamamlananAdet,
        'baslangicTarihi': baslangicTarihi,
        'bitisTarihi': bitisTarihi,
        'tedarikciAdi': tedarikciAdi,
        'atamalar': atamalar,
      };
    }).toList();
  }

  /// Akış adımlarını oluştur
  List<Widget> _buildAkisAdimlari(List<Map<String, dynamic>> asamaDurumlari) {
    final List<Widget> widgets = [];

    for (int i = 0; i < asamaDurumlari.length; i++) {
      final asama = asamaDurumlari[i];
      final durum = asama['durum'] as String;

      // Durum rengini belirle
      Color durumRengi;
      IconData durumIkonu;
      switch (durum) {
        case 'tamamlandi':
          durumRengi = Colors.green;
          durumIkonu = Icons.check_circle;
          break;
        case 'devam_ediyor':
          durumRengi = Colors.orange;
          durumIkonu = Icons.autorenew;
          break;
        case 'atandi':
          durumRengi = Colors.blue;
          durumIkonu = Icons.assignment;
          break;
        default:
          durumRengi = Colors.grey;
          durumIkonu = Icons.schedule;
      }

      // Aşama kartı
      widgets.add(
        InkWell(
          onTap: () => _showAsamaDetayDialog(asama),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: durumRengi.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: durumRengi, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Icon(asama['icon'] as IconData,
                        color: durumRengi, size: 32),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: durumRengi, width: 1),
                      ),
                      child: Icon(durumIkonu, color: durumRengi, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  asama['ad'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: durumRengi,
                  ),
                ),
                if (asama['toplamAdet'] as int > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${asama['tamamlananAdet']}/${asama['toplamAdet']}',
                    style: TextStyle(fontSize: 10, color: durumRengi),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

      // Ok işareti (son aşama hariç)
      if (i < asamaDurumlari.length - 1) {
        final okRengi = (durum == 'tamamlandi') ? Colors.green : Colors.grey;

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              color: okRengi,
              size: 24,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Aşama detay dialog'unu göster
  void _showAsamaDetayDialog(Map<String, dynamic> asama) {
    final durum = asama['durum'] as String;
    final atamalar = asama['atamalar'] as List<dynamic>;

    Color durumRengi;
    String durumMetni;
    switch (durum) {
      case 'tamamlandi':
        durumRengi = Colors.green;
        durumMetni = 'Tamamlandı';
        break;
      case 'devam_ediyor':
        durumRengi = Colors.orange;
        durumMetni = 'Devam Ediyor';
        break;
      case 'atandi':
        durumRengi = Colors.blue;
        durumMetni = 'Atandı';
        break;
      default:
        durumRengi = Colors.grey;
        durumMetni = 'Bekliyor';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(asama['icon'] as IconData, color: asama['renk'] as Color),
            const SizedBox(width: 8),
            Text(asama['ad'] as String),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Durum bilgisi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: durumRengi.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: durumRengi),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: durumRengi),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durum: $durumMetni',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: durumRengi),
                            ),
                            Text(
                              'Toplam: ${asama['toplamAdet']} adet, Tamamlanan: ${asama['tamamlananAdet']} adet',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tarih bilgileri
                if (asama['baslangicTarihi'] != null) ...[
                  const SizedBox(height: 16),
                  _buildDetayBilgiSatiri(
                    'Başlangıç Tarihi',
                    DateFormat('dd.MM.yyyy HH:mm')
                        .format(asama['baslangicTarihi'] as DateTime),
                    Icons.play_arrow,
                    Colors.blue,
                  ),
                ],

                if (asama['bitisTarihi'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetayBilgiSatiri(
                    'Bitiş Tarihi',
                    DateFormat('dd.MM.yyyy HH:mm')
                        .format(asama['bitisTarihi'] as DateTime),
                    Icons.stop,
                    Colors.green,
                  ),
                ],

                // Süre hesapla
                if (asama['baslangicTarihi'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetayBilgiSatiri(
                    'Geçen Süre',
                    utils.hesaplaSure(asama['baslangicTarihi'] as DateTime,
                        asama['bitisTarihi'] as DateTime?),
                    Icons.timer,
                    Colors.purple,
                  ),
                ],

                // Tedarikçi bilgisi
                if (asama['tedarikciAdi'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetayBilgiSatiri(
                    'Tedarikçi',
                    asama['tedarikciAdi'] as String,
                    Icons.business,
                    Colors.teal,
                  ),
                ],

                // Atama listesi
                if (atamalar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Atama Geçmişi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...atamalar
                      .map((atama) =>
                          _buildAtamaDetaySatiri(atama, asama['kod'] as String))
                      .toList(),
                ],

                // Admin işlemleri
                if (kullaniciRolu == 'admin' && atamalar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Admin İşlemleri',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (durum == 'tamamlandi')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _yenidenBaslatDialog(asama);
                          },
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Yeniden Başlat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _tumAtamalariSilDialog(asama);
                        },
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Tüm Atamaları Sil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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

  Widget _buildDetayBilgiSatiri(
      String baslik, String deger, IconData icon, Color renk) {
    return Row(
      children: [
        Icon(icon, size: 18, color: renk),
        const SizedBox(width: 8),
        Text('$baslik: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(deger)),
      ],
    );
  }

  Widget _buildAtamaDetaySatiri(Map<String, dynamic> atama, String asamaKodu) {
    final durum = atama['durum']?.toString().toLowerCase() ?? 'bilinmiyor';
    final adet = atama['adet'] ?? atama['talep_edilen_adet'] ?? 0;
    final tamamlanan = atama['tamamlanan_adet'] ?? 0;
    final createdAt = atama['created_at'] != null
        ? DateTime.tryParse(atama['created_at'].toString())
        : null;

    Color durumRengi;
    switch (durum) {
      case 'tamamlandi':
        durumRengi = Colors.green;
        break;
      case 'baslatildi':
      case 'uretimde':
        durumRengi = Colors.blue;
        break;
      case 'atandi':
        durumRengi = Colors.orange;
        break;
      default:
        durumRengi = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: durumRengi.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: durumRengi, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adet: $adet, Tamamlanan: $tamamlanan',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: durumRengi,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              utils.getStatusText(durum),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
          // Admin işlemleri
          if (kullaniciRolu == 'admin') ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                Navigator.pop(context); // Dialog'u kapat
                if (value == 'durum_degistir') {
                  _tekAtamaDurumDegistirDialog(atama, asamaKodu);
                } else if (value == 'sil') {
                  _tekAtamaSilDialog(atama, asamaKodu);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'durum_degistir',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Durum Değiştir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sil',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tüm akış detay dialog'unu göster
  void _showAkisDetayDialog(List<Map<String, dynamic>> asamaDurumlari) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timeline, color: Colors.teal),
            SizedBox(width: 8),
            Text('Üretim Akış Detayları'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              children: asamaDurumlari.map((asama) {
                final durum = asama['durum'] as String;
                Color durumRengi;
                String durumMetni;
                IconData durumIkonu;

                switch (durum) {
                  case 'tamamlandi':
                    durumRengi = Colors.green;
                    durumMetni = 'Tamamlandı';
                    durumIkonu = Icons.check_circle;
                    break;
                  case 'devam_ediyor':
                    durumRengi = Colors.orange;
                    durumMetni = 'Devam Ediyor';
                    durumIkonu = Icons.autorenew;
                    break;
                  case 'atandi':
                    durumRengi = Colors.blue;
                    durumMetni = 'Atandı';
                    durumIkonu = Icons.assignment;
                    break;
                  default:
                    durumRengi = Colors.grey;
                    durumMetni = 'Bekliyor';
                    durumIkonu = Icons.schedule;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          backgroundColor: durumRengi.withAlpha(30),
                          child: Icon(asama['icon'] as IconData,
                              color: asama['renk'] as Color),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: durumRengi, width: 1),
                          ),
                          child: Icon(durumIkonu, color: durumRengi, size: 12),
                        ),
                      ],
                    ),
                    title: Text(asama['ad'] as String),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(durumMetni,
                            style: TextStyle(
                                color: durumRengi,
                                fontWeight: FontWeight.w500)),
                        if ((asama['toplamAdet'] as int) > 0)
                          Text(
                            '${asama['tamamlananAdet']}/${asama['toplamAdet']} adet',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (asama['baslangicTarihi'] != null)
                          Text(
                            'Başlangıç: ${DateFormat('dd.MM.yyyy').format(asama['baslangicTarihi'] as DateTime)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        if (asama['bitisTarihi'] != null)
                          Text(
                            'Bitiş: ${DateFormat('dd.MM.yyyy').format(asama['bitisTarihi'] as DateTime)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAsamaDetayDialog(asama);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showAsamaDetayDialog(asama);
                    },
                  ),
                );
              }).toList(),
            ),
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

  // ignore: unused_element
  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Map<String, dynamic>? _aktifUretimAsamasi(
      List<Map<String, dynamic>> asamaDurumlari) {
    for (final asama in asamaDurumlari) {
      if (asama['durum'] == 'devam_ediyor') return asama;
    }
    for (final asama in asamaDurumlari) {
      if (asama['durum'] == 'atandi') return asama;
    }
    for (final asama in asamaDurumlari.reversed) {
      if (asama['durum'] == 'tamamlandi') return asama;
    }
    return null;
  }

  String _operasyonDurumu(
      List<dynamic> atamalar, int toplamAdet, int tamamlananAdet) {
    if (atamalar.isEmpty) return 'bekliyor';
    final durumlar = atamalar
        .whereType<Map>()
        .map((a) => a['durum']?.toString().toLowerCase() ?? '')
        .toList();
    if (durumlar.isNotEmpty &&
        durumlar.every((d) => d == 'tamamlandi') &&
        toplamAdet > 0) {
      return 'tamamlandi';
    }
    if (durumlar.any((d) =>
            d == 'uretimde' ||
            d == 'baslatildi' ||
            d == 'devam_ediyor' ||
            d == 'kismi_tamamlandi') ||
        tamamlananAdet > 0) {
      return 'devam_ediyor';
    }
    return 'atandi';
  }

  Color _asamaDurumRengi(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return const Color(0xFF2E7D32);
      case 'devam_ediyor':
      case 'kismi_tamamlandi':
      case 'uretimde':
      case 'baslatildi':
        return const Color(0xFFEF6C00);
      case 'atandi':
      case 'onaylandi':
      case 'kabul_edildi':
        return const Color(0xFF1565C0);
      case 'iptal':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF78909C);
    }
  }

  String _asamaDurumMetni(String durum) {
    const panelMetinleri = {
      'devam_ediyor': 'Devam Ediyor',
      'kismi_tamamlandi': 'KÄ±smi TamamlandÄ±',
      'uretimde': 'Ãœretimde',
      'baslatildi': 'BaÅŸlatÄ±ldÄ±',
      'kabul_edildi': 'Kabul Edildi',
    };
    final panelMetni = panelMetinleri[durum];
    if (panelMetni != null) return panelMetni;

    switch (durum) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'devam_ediyor':
      case 'kismi_tamamlandi':
      case 'uretimde':
      case 'baslatildi':
        return 'İşleniyor';
      case 'atandi':
        return 'Atandı';
      case 'onaylandi':
      case 'kabul_edildi':
        return 'Onaylandı';
      case 'iptal':
        return 'İptal';
      default:
        return 'Bekliyor';
    }
  }

  Widget _durumEtiketi(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  int _uretimInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _adetMetni(int value) =>
      NumberFormat.decimalPattern('tr_TR').format(value);

  String? _sonUretimKaydiTarihi(List<dynamic> kayitlar) {
    DateTime? latest;
    for (final kayit in kayitlar.whereType<Map>()) {
      final value =
          kayit['created_at'] ?? kayit['updated_at'] ?? kayit['tarih'];
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed == null) continue;
      if (latest == null || parsed.isAfter(latest)) latest = parsed;
    }
    return latest == null ? null : DateFormat('dd.MM.yyyy').format(latest);
  }

  // ignore: unused_element
  Widget _buildAsamaKarti(
      String baslik,
      List<dynamic> kayitlar,
      List<dynamic> atamaKayitlari,
      IconData icon,
      String asamaKey,
      Color color) {
    int toplamAdet = 0;
    int tamamlananAdet = 0;
    String durum = 'Bekliyor';

    // Atama durumlarını analiz et
    for (var atama in atamaKayitlari) {
      toplamAdet += (atama['adet'] ?? atama['talep_edilen_adet'] ?? 0) as int;
      tamamlananAdet += (atama['tamamlanan_adet'] ?? 0) as int;
    }

    if (atamaKayitlari.isEmpty) {
      durum = 'Atama Yok';
      color = Colors.grey;
    } else if (tamamlananAdet == toplamAdet && toplamAdet > 0) {
      durum = 'Tamamlandı';
      color = Colors.green;
    } else if (tamamlananAdet > 0) {
      durum = 'İşleniyor';
      color = Colors.orange;
    } else if (toplamAdet > 0) {
      durum = 'Atanmış';
      color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baslik,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          durum,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      utils.getDurumIkonu(durum),
                      color: color,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Adet bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Atanmış',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('$toplamAdet',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text('Tamamlanan',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('$tamamlananAdet',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text('Kalan',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                        Text('${toplamAdet - tamamlananAdet}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),

              // Admin atama butonu
              if (kullaniciRolu == 'admin') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAtamaDialog(asamaKey),
                  icon: const Icon(Icons.add_task, size: 20),
                  label: const Text('Yeni Atama Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              // Atamalar listesi
              if (atamaKayitlari.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  kullaniciRolu == 'admin'
                      ? 'Tüm Atamalar:'
                      : 'Size Atanan İşler:',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: atamaKayitlari.length,
                  itemBuilder: (context, index) {
                    final atama = atamaKayitlari[index];
                    return _buildAtamaItem(atama, asamaKey);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtamaItem(Map<String, dynamic> atama, String asamaKey) {
    final durum = atama['durum']?.toLowerCase() ?? '';
    final adet = atama['adet'] ?? atama['talep_edilen_adet'] ?? 0;
    final tamamlanan = atama['tamamlanan_adet'] ?? 0;
    final createdAt = atama['created_at'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: utils.getStatusColor(durum).withAlpha(20),
        border: Border(
            left: BorderSide(width: 3, color: utils.getStatusColor(durum))),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment,
                            size: 16, color: utils.getStatusColor(durum)),
                        const SizedBox(width: 8),
                        Text(
                          'Adet: $adet',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Tamamlanan: $tamamlanan',
                          style: TextStyle(
                            color: tamamlanan > 0 ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null)
                      Text(
                        'Atama: ${createdAt.toString().split('T')[0]}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: utils.getStatusColor(durum),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  utils.getStatusText(durum),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Aksiyon butonları
          if (_getUserActions(atama, asamaKey).isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _getUserActions(atama, asamaKey),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _getUserActions(Map<String, dynamic> atama, String asamaKey) {
    final List<Widget> butonlar = [];
    final durum = atama['durum']?.toLowerCase() ?? '';

    // Sadece kendi atamalarında işlem yapabilir (admin hariç)
    final user = supabase.auth.currentUser;
    if (user == null) return butonlar;

    final bool isOwnAssignment =
        atama['atanan_kullanici_id'] == user.id || kullaniciRolu == 'admin';
    if (!isOwnAssignment) return butonlar;

    // Kabul et butonu (atandı veya firma onay bekliyor durumunda)
    if (durum == 'atandi' || durum == 'firma_onay_bekliyor' || durum == '') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _atamaKabulEt(atama, asamaKey),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // Üretime Başla butonu (onaylandı durumunda - admin için)
    if ((durum == 'onaylandi' || durum == 'kabul_edildi') &&
        kullaniciRolu == 'admin') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _atamaUretimeAl(atama, asamaKey),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Üretime Başla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // Tamamla butonu (üretimde durumunda)
    if (durum == 'baslatildi' ||
        durum == 'uretimde' ||
        durum == 'kismi_tamamlandi') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _showTamamlamaDialog(atama, asamaKey),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    // İptal Et butonu (admin için, tamamlanmamış tüm durumlar)
    if (kullaniciRolu == 'admin' && durum != 'tamamlandi' && durum != 'iptal') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton.icon(
            onPressed: () => _atamaIptalEt(atama, asamaKey),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('İptal Et'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return butonlar;
  }

  Future<void> _atamaUretimeAl(
      Map<String, dynamic> atama, String asamaKey) async {
    try {
      final atamaId = atama['id'];
      final String tableName = utils.getTableNameForStage(asamaKey);
      final now = DateTime.now().toIso8601String();

      await _workflowTransitionService.applyTransition(
        tableName: tableName,
        recordId: atamaId,
        firmaId: TenantManager.instance.requireFirmaId,
        fromStatus: atama['durum']?.toString(),
        toStatus: 'uretimde',
        extraFields: {
          'uretim_baslangic_tarihi': now,
          'updated_at': now,
        },
        idempotencyKey: '$tableName:$atamaId:uretimde:${atama['updated_at']}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Atama üretime alındı'),
          backgroundColor: Colors.blue,
        ),
      );

      await _atamaKayitlariniGetir();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  Future<void> _atamaIptalEt(
      Map<String, dynamic> atama, String asamaKey) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı İptal Et'),
        content:
            const Text('Bu atamayı iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('İptal Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      final atamaId = atama['id'];
      final String tableName = utils.getTableNameForStage(asamaKey);
      final now = DateTime.now().toIso8601String();

      await _workflowTransitionService.applyTransition(
        tableName: tableName,
        recordId: atamaId,
        firmaId: TenantManager.instance.requireFirmaId,
        fromStatus: atama['durum']?.toString(),
        toStatus: 'iptal',
        extraFields: {'updated_at': now},
        idempotencyKey: '$tableName:$atamaId:iptal:${atama['updated_at']}',
      );

      if (!mounted) return;
      context.showErrorSnackBar('⛔ Atama iptal edildi');

      await _atamaKayitlariniGetir();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }
}

class _UretimKpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _UretimKpi(this.label, this.value, this.icon, this.color);
}

class _UretimTableHeader extends StatelessWidget {
  final String text;

  const _UretimTableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF607D8B),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
