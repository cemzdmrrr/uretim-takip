// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_asama_dashboard.dart';

/// Uretim asama model karti, aksiyonlar ve dialog'lar
extension _AksiyonlarAsamaExt on _UretimAsamaDashboardState {
  Widget _buildErpAksiyonButonu({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool aktif = false,
  }) {
    final renk = aktif ? const Color(0xFFEF6C00) : const Color(0xFF334155);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: aktif ? const Color(0xFFFFF3E0) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: renk, size: 21),
                if (aktif)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEF6C00),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErpHeader({
    required int bekleyen,
    required int onaylanan,
    required int islemde,
    required int tamamlanan,
    required int toplam,
    required bool aktifFiltreVar,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDDE5EE))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1550),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.asamaRengi.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.asamaIconu,
                        color: widget.asamaRengi,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.asamaDisplayName} Paneli',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$toplam aktif iş emri izleniyor',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        _buildErpAksiyonButonu(
                          icon: Icons.search,
                          tooltip: 'Ara',
                          onPressed: () async {
                            final result = await showSearch<String>(
                              context: context,
                              delegate: _AsamaModelAramaDelegate(
                                tumModeller: atanmisModeller,
                                asamaRengi: widget.asamaRengi,
                              ),
                            );
                            if (result != null && result.isNotEmpty) {
                              setState(() {
                                aramaMetni = result;
                                _aramaController.text = result;
                              });
                            }
                          },
                        ),
                        _buildErpAksiyonButonu(
                          icon: Icons.filter_alt,
                          tooltip: 'Filtrele',
                          onPressed: _showFilterDialog,
                          aktif: aktifFiltreVar,
                        ),
                        _buildErpAksiyonButonu(
                          icon: Icons.analytics_outlined,
                          tooltip: 'Rapor',
                          onPressed: _showRaporDialog,
                        ),
                        _buildErpAksiyonButonu(
                          icon: Icons.refresh,
                          tooltip: 'Yenile',
                          onPressed: _modelleriGetir,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildHeaderMetric('Toplam', toplam.toString(),
                        Icons.assignment_outlined, widget.asamaRengi),
                    _buildHeaderMetric('Bekleyen', bekleyen.toString(),
                        Icons.pending_actions, const Color(0xFFEF6C00)),
                    _buildHeaderMetric('Onaylanan', onaylanan.toString(),
                        Icons.verified_outlined, const Color(0xFF2E7D32)),
                    _buildHeaderMetric('İşlemde', islemde.toString(),
                        Icons.play_circle_outline, const Color(0xFF1565C0)),
                    _buildHeaderMetric('Tamamlanan', tamamlanan.toString(),
                        Icons.task_alt, const Color(0xFF6A1B9A)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(
      String label, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 142),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAktifFiltreSeridi() {
    final filtreler = [
      if (aramaMetni.isNotEmpty) '"$aramaMetni"',
      if (seciliMarka != null) 'Marka: $seciliMarka',
      if (baslangicTarihi != null)
        'Başlangıç: ${DateFormat('dd.MM.yyyy').format(baslangicTarihi!)}',
      if (bitisTarihi != null)
        'Bitiş: ${DateFormat('dd.MM.yyyy').format(bitisTarihi!)}',
    ].join('  •  ');

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1550),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filtreler,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF78350F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _filtreleriTemizle,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Temizle'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErpTabSeridi({
    required int bekleyen,
    required int onaylanan,
    required int islemde,
    required int toplam,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1550),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDE5EE)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: widget.asamaRengi,
              indicatorWeight: 3,
              labelColor: widget.asamaRengi,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.pending_actions),
                  text: 'Bekleyen ($bekleyen)',
                ),
                Tab(
                  icon: const Icon(Icons.verified_outlined),
                  text: 'Onaylanan ($onaylanan)',
                ),
                Tab(
                  icon: Icon(widget.asamaIconu),
                  text: 'İşlemde ($islemde)',
                ),
                Tab(
                  icon: const Icon(Icons.view_list),
                  text: 'Tümü ($toplam)',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelKarti(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = atama['durum'] as String?;
    final tamamlananAdet = _atamaInt(atama['tamamlanan_adet']);
    final kayitliBedenDagilimi = _parseBedenDetayi(
      atama['beden_detaylari'] ?? atama['beden_dagilimi'],
    );
    final notBedenDagilimi = _notlardanBedenDetayi(
      '${atama['notlar'] ?? ''}\n${atama['aciklama'] ?? ''}',
    );
    final kalanBedenToplam = durum == 'kismi_tamamlandi'
        ? _toplamBedenAdedi(kayitliBedenDagilimi)
        : 0;
    final hamKabulEdilenAdet = _atamaInt(atama['kabul_edilen_adet'] ??
        atama['talep_edilen_adet'] ??
        atama['adet'] ??
        model['adet'] ??
        0);
    final hamTalepEdilenAdet =
        _atamaInt(atama['talep_edilen_adet'] ?? model['adet'] ?? atama['adet']);
    final kaynakBedenToplam = _toplamBedenAdedi(notBedenDagilimi);
    final hesaplananToplam =
        tamamlananAdet + (kalanBedenToplam > 0 ? kalanBedenToplam : 0);
    final kabulEdilenAdet = [
      hamKabulEdilenAdet,
      hamTalepEdilenAdet,
      kaynakBedenToplam,
      hesaplananToplam,
    ].reduce((a, b) => a > b ? a : b);
    final talepEdilenAdet = hamTalepEdilenAdet > kabulEdilenAdet
        ? hamTalepEdilenAdet
        : kabulEdilenAdet;
    final kalanAdet = kalanBedenToplam > 0
        ? kalanBedenToplam
        : (kabulEdilenAdet - tamamlananAdet).clamp(0, 999999999);
    final ilerleme = kabulEdilenAdet <= 0
        ? 0.0
        : (tamamlananAdet / kabulEdilenAdet).clamp(0.0, 1.0);
    final kabulBedenDagilimi =
        _kabulBedenDagilimiGetir(atama, model, kabulEdilenAdet);
    final notMetni = _gecerliNotMetni(atama);
    final durumRengi = _durumRengi(durum);

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
                            color: widget.asamaRengi.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.asamaIconu,
                            color: widget.asamaRengi,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${model['marka'] ?? 'Bilinmeyen Marka'} - ${model['item_no'] ?? 'Bilinmeyen Model'}',
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
                                  _buildKisaBilgi(
                                    Icons.palette_outlined,
                                    (model['renk'] ?? '-').toString(),
                                  ),
                                  _buildKisaBilgi(
                                    Icons.event_outlined,
                                    _kisaTarih(model['termin_tarihi']),
                                  ),
                                  if (atama['atama_tarihi'] != null)
                                    _buildKisaBilgi(
                                      Icons.assignment_ind_outlined,
                                      _kisaTarihSaat(atama['atama_tarihi']),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildDurumPili(durum),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildUretimMetric(
                          'Sipariş',
                          _adetMetni(talepEdilenAdet),
                          Icons.inventory_2_outlined,
                          const Color(0xFF2563EB),
                        ),
                        _buildUretimMetric(
                          'Kabul',
                          _adetMetni(kabulEdilenAdet),
                          Icons.verified_outlined,
                          const Color(0xFF16A34A),
                        ),
                        _buildUretimMetric(
                          'Tamamlanan',
                          _adetMetni(tamamlananAdet),
                          Icons.task_alt,
                          const Color(0xFF0F766E),
                        ),
                        _buildUretimMetric(
                          'Kalan',
                          _adetMetni(kalanAdet),
                          Icons.pending_actions,
                          const Color(0xFFEA580C),
                        ),
                      ],
                    ),
                    if (kabulBedenDagilimi.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          'Kabul Beden: ${_bedenDagilimiMetni(kabulBedenDagilimi)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (kabulEdilenAdet > 0 &&
                        (durum == 'onaylandi' ||
                            durum == 'uretimde' ||
                            durum == 'baslatildi' ||
                            durum == 'kismi_tamamlandi')) ...[
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
                      child: _buildAksiyonButonlari(atama, model, durum),
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

  Widget _buildKisaBilgi(IconData icon, String value) {
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

  Widget _buildUretimMetric(
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

  Widget _buildDurumPili(String? durum) {
    final color = _durumRengi(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _durumMetni(durum),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  int _atamaInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, int> _parseBedenDetayi(dynamic raw) {
    dynamic value = raw;
    if (value == null) return const <String, int>{};

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const <String, int>{};
      try {
        value = jsonDecode(text);
      } catch (_) {
        return const <String, int>{};
      }
    }

    if (value is Map) {
      final result = <String, int>{};
      value.forEach((key, adet) {
        final beden = key.toString().trim().toUpperCase();
        final qty = _atamaInt(adet);
        if (beden.isNotEmpty && qty > 0) {
          result[beden] = qty;
        }
      });
      return _siraliBedenMap(result);
    }

    if (value is List) {
      final result = <String, int>{};
      for (final item in value) {
        if (item is! Map) continue;

        final beden = (item['beden_kodu'] ??
                item['beden'] ??
                item['size'] ??
                item['label'] ??
                '')
            .toString()
            .trim()
            .toUpperCase();
        final qty = _atamaInt(
          item['adet'] ?? item['miktar'] ?? item['quantity'] ?? item['value'],
        );

        if (beden.isNotEmpty && qty > 0) {
          result[beden] = (result[beden] ?? 0) + qty;
        }
      }
      return _siraliBedenMap(result);
    }

    return const <String, int>{};
  }

  Map<String, int> _notlardanBedenDetayi(dynamic rawNot) {
    final text = (rawNot ?? '').toString();
    if (text.isEmpty) return const <String, int>{};

    final match =
        RegExp(r'\[BEDEN:([^\]]+)\]', caseSensitive: false).firstMatch(text);
    if (match == null) return const <String, int>{};

    final result = <String, int>{};
    final body = (match.group(1) ?? '').trim();
    if (body.isEmpty) return const <String, int>{};

    for (final parca in body.split('|')) {
      final kv = parca.split(':');
      if (kv.length < 2) continue;
      final beden = kv.first.trim().toUpperCase();
      final adet = int.tryParse(kv.sublist(1).join(':').trim()) ?? 0;
      if (beden.isNotEmpty && adet > 0) {
        result[beden] = (result[beden] ?? 0) + adet;
      }
    }

    return _siraliBedenMap(result);
  }

  int _bedenSiraSkoru(String beden) {
    const standartSira = <String>[
      'XXS',
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      '3XL',
      '4XL',
      '5XL',
    ];
    final index = standartSira.indexOf(beden.toUpperCase());
    return index >= 0 ? index : 10 + beden.codeUnitAt(0);
  }

  Map<String, int> _siraliBedenMap(Map<String, int> values) {
    final entries = values.entries.toList()
      ..sort((a, b) {
        final sa = _bedenSiraSkoru(a.key);
        final sb = _bedenSiraSkoru(b.key);
        if (sa != sb) return sa.compareTo(sb);
        return a.key.compareTo(b.key);
      });
    return Map<String, int>.fromEntries(entries);
  }

  int _toplamBedenAdedi(Map<String, int> bedenler) {
    return bedenler.values.fold<int>(0, (toplam, adet) => toplam + adet);
  }

  Map<String, int> _toplamaUyarliBedenMap(
    Map<String, int> kaynak,
    int hedefToplam,
  ) {
    final temiz = kaynak
        .map((key, value) => MapEntry(key, value < 0 ? 0 : value))
      ..removeWhere((_, value) => value <= 0);
    if (temiz.isEmpty) return const <String, int>{};

    if (hedefToplam <= 0) return _siraliBedenMap(temiz);

    final mevcutToplam = _toplamBedenAdedi(temiz);
    if (mevcutToplam == hedefToplam) return _siraliBedenMap(temiz);
    if (mevcutToplam <= 0) return const <String, int>{};

    final tabanDegerler = <String, int>{};
    final kalanlar = <Map<String, dynamic>>[];

    for (final entry in temiz.entries) {
      final oransal = (entry.value * hedefToplam) / mevcutToplam;
      final taban = oransal.floor();
      tabanDegerler[entry.key] = taban;
      kalanlar.add({
        'beden': entry.key,
        'kalan': oransal - taban,
      });
    }

    final dagitilacak = hedefToplam - _toplamBedenAdedi(tabanDegerler);
    kalanlar
        .sort((a, b) => (b['kalan'] as double).compareTo(a['kalan'] as double));

    for (var i = 0; i < dagitilacak; i++) {
      final beden = kalanlar[i % kalanlar.length]['beden'] as String;
      tabanDegerler[beden] = (tabanDegerler[beden] ?? 0) + 1;
    }

    tabanDegerler.removeWhere((_, value) => value <= 0);
    return _siraliBedenMap(tabanDegerler);
  }

  Map<String, int> _kabulBedenDagilimiGetir(
    Map<String, dynamic> atama,
    Map<String, dynamic> model,
    int kabulEdilenAdet,
  ) {
    final kayitli = _parseBedenDetayi(
      atama['beden_detaylari'] ?? atama['beden_dagilimi'],
    );
    if (kayitli.isNotEmpty) {
      // Kayitli beden dagilimini orijinal haliyle koru; sevkiyat/kaynak dagilim
      // ile birebir uyum burada daha dogru bir sonuc verir.
      return _siraliBedenMap(kayitli);
    }

    if (_sevkiyatKaynakliAtamaMi(atama)) {
      return const <String, int>{};
    }

    final modelDagilim = _parseBedenDetayi(model['bedenler']);
    if (modelDagilim.isNotEmpty) {
      return _toplamaUyarliBedenMap(modelDagilim, kabulEdilenAdet);
    }

    return const <String, int>{};
  }

  bool _sevkiyatKaynakliAtamaMi(Map<String, dynamic> atama) {
    if (_sevkiyatIdempotencyKeyGetir(atama) != null) {
      return true;
    }

    final notlar =
        '${atama['notlar'] ?? ''}\n${atama['aciklama'] ?? ''}'.toLowerCase();
    return notlar.contains('sevkiyattan geldi') || notlar.contains('sevkiyat');
  }

  String? _sevkiyatIdempotencyKeyGetir(Map<String, dynamic> atama) {
    final explicit = (atama['idempotency_key'] ?? '').toString().trim();
    if (explicit.startsWith('sevk:')) {
      return explicit;
    }

    final notlar =
        '${atama['notlar'] ?? ''}\n${atama['aciklama'] ?? ''}'.toString();
    final match =
        RegExp(r'\[IDEMP:([^\]]+)\]', caseSensitive: false).firstMatch(notlar);
    final parsed = (match?.group(1) ?? '').trim();
    if (parsed.startsWith('sevk:')) {
      return parsed;
    }

    return null;
  }

  String _normalizeAsamaKoduYerel(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<Map<String, int>> _sevkiyattanBedenDagilimiGetir(
      Map<String, dynamic> atama) async {
    Map<String, int> notlardanBedenDetayi(dynamic rawNot) {
      final text = (rawNot ?? '').toString();
      if (text.isEmpty) return const <String, int>{};

      final match =
          RegExp(r'\[BEDEN:([^\]]+)\]', caseSensitive: false).firstMatch(text);
      if (match == null) return const <String, int>{};

      final result = <String, int>{};
      final body = (match.group(1) ?? '').trim();
      if (body.isEmpty) return const <String, int>{};

      for (final parca in body.split('|')) {
        final kv = parca.split(':');
        if (kv.length < 2) continue;
        final beden = kv.first.trim().toUpperCase();
        final adet = int.tryParse(kv.sublist(1).join(':').trim()) ?? 0;
        if (beden.isNotEmpty && adet > 0) {
          result[beden] = (result[beden] ?? 0) + adet;
        }
      }

      return _siraliBedenMap(result);
    }

    final atamaNotBeden = notlardanBedenDetayi(
      '${atama['notlar'] ?? ''}\n${atama['aciklama'] ?? ''}',
    );
    if (atamaNotBeden.isNotEmpty) {
      return atamaNotBeden;
    }

    final key = _sevkiyatIdempotencyKeyGetir(atama);
    if (key == null || key.isEmpty) return const <String, int>{};

    final parts = key.split(':');
    if (parts.length < 3) return const <String, int>{};

    final irsaliyeId = parts[1].trim() == 'irsaliye' && parts.length >= 4
        ? parts[2].trim()
        : '';
    final sevkiyatId = irsaliyeId.isEmpty ? parts[1].trim() : '';
    if (sevkiyatId.isEmpty && irsaliyeId.isEmpty) return const <String, int>{};

    final hedefAsama = _normalizeAsamaKoduYerel(
      irsaliyeId.isEmpty
          ? parts.sublist(2).join(':')
          : parts.sublist(3).join(':'),
    );
    var useFirmaFilter = true;
    var bedenKolonuVar = true;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        var query = supabase.from(DbTables.sevkiyatDetaylari).select(
            bedenKolonuVar
                ? 'beden_detaylari, hedef_asama, notlar'
                : 'hedef_asama, notlar');

        query = irsaliyeId.isNotEmpty
            ? query.eq('irsaliye_id', irsaliyeId)
            : query.eq('sevkiyat_id', sevkiyatId);

        if (useFirmaFilter) {
          query = query.eq('firma_id', TenantManager.instance.requireFirmaId);
        }

        final rows = await query;
        final toplam = <String, int>{};

        for (final row in List<Map<String, dynamic>>.from(rows)) {
          final rowHedef =
              _normalizeAsamaKoduYerel(row['hedef_asama']?.toString());
          if (hedefAsama.isNotEmpty && rowHedef != hedefAsama) continue;

          final bedenler = bedenKolonuVar
              ? _parseBedenDetayi(row['beden_detaylari'])
              : notlardanBedenDetayi(row['notlar']);
          for (final entry in bedenler.entries) {
            toplam[entry.key] = (toplam[entry.key] ?? 0) + entry.value;
          }
        }

        if (toplam.isNotEmpty) {
          return _siraliBedenMap(toplam);
        }
        return const <String, int>{};
      } catch (e) {
        final missing = _missingColumnName(e);
        if (missing == 'firma_id' && useFirmaFilter) {
          useFirmaFilter = false;
          continue;
        }
        if (missing == 'beden_detaylari' && bedenKolonuVar) {
          bedenKolonuVar = false;
          continue;
        }
        break;
      }
    }

    return const <String, int>{};
  }

  String _bedenDagilimiMetni(Map<String, int> bedenler) {
    if (bedenler.isEmpty) return '-';
    return bedenler.entries.map((e) => '${e.key}:${e.value}').join(' | ');
  }

  String _notMetniTemizle(dynamic raw) {
    var metin = (raw ?? '').toString().trim();
    if (metin.isEmpty) return '';

    final alt = metin.toLowerCase();
    if (alt == 'null' || alt == 'undefined' || alt == '[]' || alt == '{}') {
      return '';
    }

    // Sistemsel idempotency etiketlerini kullanıcı ekranından gizle.
    metin = metin
        .replaceAll(
          RegExp(r'\[idemp:[^\]]+\]', caseSensitive: false),
          '',
        )
        .trim();
    metin = metin.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (metin.isEmpty || metin == '-' || metin == '--') return '';
    return metin;
  }

  String _gecerliNotMetni(Map<String, dynamic> atama) {
    final notlar = _notMetniTemizle(atama['notlar']);
    if (notlar.isNotEmpty) return notlar;
    return _notMetniTemizle(atama['aciklama']);
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

  Color _durumRengi(String? durum) {
    switch (durum) {
      case 'atandi':
      case 'bekleyen':
      case 'beklemede':
      case 'kontrol_bekliyor':
        return const Color(0xFFEA580C);
      case 'onaylandi':
        return const Color(0xFF16A34A);
      case 'reddedildi':
        return const Color(0xFFDC2626);
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

  String _durumMetni(String? durum) {
    switch (durum) {
      case 'atandi':
      case 'bekleyen':
      case 'beklemede':
      case 'kontrol_bekliyor':
        return 'Onay Bekliyor';
      case 'onaylandi':
        return 'Onaylandı';
      case 'reddedildi':
        return 'Reddedildi';
      case 'uretimde':
      case 'baslatildi':
        return 'İşlemde';
      case 'kismi_tamamlandi':
        return 'Kısmi Tamamlandı';
      case 'tamamlandi':
        return 'Tamamlandı';
      default:
        return 'Bekliyor';
    }
  }

  Widget _buildAksiyonButonlari(
      Map<String, dynamic> atama, Map<String, dynamic> model, String? durum) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Detay butonu - her zaman görünür
        OutlinedButton.icon(
          onPressed: () => _genericDetayDialog(atama),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Detay'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),

        // Geri Al butonu - tamamlanmış, kısmi tamamlanmış veya reddedilmiş işler için
        if (durum == 'tamamlandi' ||
            durum == 'kismi_tamamlandi' ||
            durum == 'reddedildi')
          OutlinedButton.icon(
            onPressed: () => _showGeriAlDialog(atama),
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Geri Al'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
          ),

        // Kabul Et butonu - sadece bekleyen işler için
        if (durum == 'bekleyen' ||
            durum == 'beklemede' ||
            durum == 'atandi' ||
            durum == 'kontrol_bekliyor')
          ElevatedButton.icon(
            onPressed: () => _showKabulDialog(atama),
            icon: const Icon(Icons.thumb_up, size: 18),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),

        // Reddet butonu - sadece bekleyen işler için
        if (durum == 'bekleyen' ||
            durum == 'beklemede' ||
            durum == 'atandi' ||
            durum == 'kontrol_bekliyor')
          ElevatedButton.icon(
            onPressed: () => _showReddetDialog(atama),
            icon: const Icon(Icons.thumb_down, size: 18),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),

        // Üretime Al butonu - onaylanmış işler için
        if (durum == 'onaylandi' || durum == 'kabul_edildi')
          ElevatedButton.icon(
            onPressed: () => _showUretimeAlDialog(atama),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Üretime Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),

        // Üretimi Tamamla butonu - üretimde olan işler için
        if (durum == 'uretimde' ||
            durum == 'baslatildi' ||
            durum == 'kismi_tamamlandi')
          ElevatedButton.icon(
            onPressed: () => _showTamamlaDialog(atama),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  // Düzenle Dialog'u

  // Sil Dialog'u

  Future<void> _kismiKayitBedenTakibiniSifirla(
      Map<String, dynamic> atama) async {
    final atamaId = atama['id'];
    if (atamaId == null) return;

    final tabloAdi = '${widget.asamaAdi}_beden_takip';
    final firmaId = TenantManager.instance.requireFirmaId;

    List<Map<String, dynamic>> satirlar = const <Map<String, dynamic>>[];
    try {
      final response = await supabase
          .from(tabloAdi)
          .select('*')
          .eq('atama_id', atamaId)
          .eq('firma_id', firmaId);
      satirlar = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (_missingColumnName(e) == 'firma_id') {
        try {
          final response =
              await supabase.from(tabloAdi).select('*').eq('atama_id', atamaId);
          satirlar = List<Map<String, dynamic>>.from(response);
        } catch (_) {
          return;
        }
      } else {
        return;
      }
    }

    if (satirlar.isEmpty) return;

    final now = DateTime.now().toIso8601String();

    for (final satir in satirlar) {
      final satirId = satir['id'];
      if (satirId == null) continue;

      final hedefAdet = _atamaInt(satir['hedef_adet']);
      final kabulAdet = _atamaInt(satir['kabul_edilen_adet']);
      final updateData = <String, dynamic>{
        if (satir.containsKey('hedef_adet'))
          'hedef_adet': (hedefAdet + kabulAdet).clamp(0, 999999999).toInt(),
        if (satir.containsKey('kabul_edilen_adet')) 'kabul_edilen_adet': 0,
        if (satir.containsKey('uretilen_adet')) 'uretilen_adet': 0,
        if (satir.containsKey('fire_adet')) 'fire_adet': 0,
        if (satir.containsKey('guncelleme_tarihi')) 'guncelleme_tarihi': now,
        if (satir.containsKey('updated_at')) 'updated_at': now,
      };

      if (updateData.isEmpty) continue;

      try {
        await supabase
            .from(tabloAdi)
            .update(updateData)
            .eq('id', satirId)
            .eq('atama_id', atamaId)
            .eq('firma_id', firmaId);
      } catch (e) {
        final fallback = Map<String, dynamic>.from(updateData);
        final missing = _missingColumnName(e);
        if (missing != null && fallback.containsKey(missing)) {
          fallback.remove(missing);
        }
        if (fallback.isEmpty) continue;

        try {
          await supabase
              .from(tabloAdi)
              .update(fallback)
              .eq('id', satirId)
              .eq('atama_id', atamaId);
        } catch (_) {
          // Eski şemalarda bazı kolonlar olmayabilir; best-effort ilerle.
        }
      }
    }
  }

  // Geri Al Dialog'u
  void _showGeriAlDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final mevcutDurum = atama['durum'] as String?;
    final kismiKayitGeriAl = mevcutDurum == 'kismi_tamamlandi';

    String hedefDurum = 'onaylandi'; // Varsayılan olarak onaylandı durumuna al
    if (mevcutDurum == 'reddedildi') {
      hedefDurum = 'atandi'; // Reddedilmiş ise bekleyen durumuna al
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durumu Geri Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${model['marka']} - ${model['item_no']}'),
            const SizedBox(height: 16),
            Text(
              kismiKayitGeriAl
                  ? 'Kısmi kaydı geri alıp atamayı "Onaylandı" durumuna döndürmek istiyor musunuz?'
                  : (mevcutDurum == 'tamamlandi'
                      ? 'Tamamlanmış atamayı "Onaylandı" durumuna geri almak istiyor musunuz?'
                      : 'Reddedilmiş atamayı "Beklemede" durumuna geri almak istiyor musunuz?'),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu işlem ile atama tekrar işleme alınabilir.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (kismiKayitGeriAl) {
                  await _kismiKayitBedenTakibiniSifirla(atama);
                }

                final updateData = _eskiAtamaSemasi
                    ? {
                        'durum': hedefDurum,
                        'teslim_tarihi': null,
                        if (kismiKayitGeriAl) 'tamamlanan_adet': 0,
                        if (kismiKayitGeriAl) 'fire_adet': 0,
                        'updated_at': DateTime.now().toIso8601String(),
                        'son_guncelleme_tarihi':
                            DateTime.now().toIso8601String(),
                      }
                    : {
                        'durum': hedefDurum,
                        'tamamlama_tarihi': null,
                        if (kismiKayitGeriAl) 'tamamlanan_adet': 0,
                        if (kismiKayitGeriAl) 'fire_adet': 0,
                        if (kismiKayitGeriAl) 'uretim_baslangic_tarihi': null,
                        'updated_at': DateTime.now().toIso8601String(),
                      };

                final esnekUpdate = Map<String, dynamic>.from(updateData);
                while (true) {
                  try {
                    await supabase
                        .from(widget.atamaTablosu)
                        .update(esnekUpdate)
                        .eq('id', atama['id']);
                    break;
                  } catch (e) {
                    final missing = _missingColumnName(e);
                    if (missing != null && esnekUpdate.containsKey(missing)) {
                      esnekUpdate.remove(missing);
                      if (esnekUpdate.isEmpty) break;
                      continue;
                    }
                    rethrow;
                  }
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(kismiKayitGeriAl
                          ? '↩️ Kısmi kayıt geri alındı, atama "$hedefDurum" durumuna döndü'
                          : '↩️ Atama "$hedefDurum" durumuna geri alındı'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text('Geri Al'),
          ),
        ],
      ),
    );
  }

  // Kabul Et Dialog'u
  Future<void> _showKabulDialog(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final bazTalepEdilenAdet = _atamaInt(
      atama['talep_edilen_adet'] ?? atama['adet'] ?? model['adet'] ?? 0,
    );
    final kayitliBedenDagilimi =
        _kabulBedenDagilimiGetir(atama, model, bazTalepEdilenAdet);
    var talepBedenDagilimi = await _sevkiyattanBedenDagilimiGetir(atama);
    if (talepBedenDagilimi.isEmpty) {
      talepBedenDagilimi = kayitliBedenDagilimi;
    }

    final sevkiyatDagilimiBulundu = talepBedenDagilimi.isNotEmpty;
    final dagilimFarkli = sevkiyatDagilimiBulundu &&
        (talepBedenDagilimi.length != kayitliBedenDagilimi.length ||
            talepBedenDagilimi.entries.any(
              (e) => kayitliBedenDagilimi[e.key] != e.value,
            ));

    if (dagilimFarkli) {
      final senkronToplam = _toplamBedenAdedi(talepBedenDagilimi);
      final updateData = <String, dynamic>{
        'beden_detaylari': talepBedenDagilimi,
        'talep_edilen_adet': senkronToplam,
        'adet': senkronToplam,
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await supabase
            .from(widget.atamaTablosu)
            .update(updateData)
            .eq('id', atama['id'])
            .eq('firma_id', TenantManager.instance.requireFirmaId);
      } catch (e) {
        final fallback = Map<String, dynamic>.from(updateData);
        final missing = _missingColumnName(e);
        if (missing != null && fallback.containsKey(missing)) {
          fallback.remove(missing);
        }

        if (fallback.isNotEmpty) {
          try {
            await supabase
                .from(widget.atamaTablosu)
                .update(fallback)
                .eq('id', atama['id']);
          } catch (_) {
            // Eski şema veya izin kısıtı olabilir; modal yine doğru dagilimi gosterir.
          }
        }
      }
    }

    final talepEdilenAdet = talepBedenDagilimi.isNotEmpty
        ? _toplamBedenAdedi(talepBedenDagilimi)
        : bazTalepEdilenAdet;
    final talepBedenMetni = _bedenDagilimiMetni(talepBedenDagilimi);
    final adetController = TextEditingController(
      text: talepEdilenAdet.toString(),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Kabul Et'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Model: ${model['marka']} - ${model['item_no']}'),
              Text('Talep Edilen: ${_adetMetni(talepEdilenAdet)} adet'),
              if (talepBedenDagilimi.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'Talep Beden: $talepBedenMetni',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: adetController,
                decoration: InputDecoration(
                  labelText: 'Kabul Edilen Adet',
                  border: const OutlineInputBorder(),
                  helperText: talepBedenDagilimi.isNotEmpty
                      ? 'Talep beden dağılımı yukarıda listelendi.'
                      : 'Tamamlayabileceğiniz adet miktarı',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final kabulAdet = int.tryParse(adetController.text) ?? 0;
                if (kabulAdet <= 0) {
                  throw Exception('Geçerli bir adet giriniz');
                }

                final updateData = <String, dynamic>{
                  'kabul_edilen_adet': kabulAdet,
                  'durum': 'onaylandi',
                  'onay_tarihi': DateTime.now().toIso8601String(),
                  if (talepBedenDagilimi.isNotEmpty)
                    'beden_detaylari': talepBedenDagilimi,
                };

                try {
                  await supabase
                      .from(widget.atamaTablosu)
                      .update(updateData)
                      .eq('id', atama['id'])
                      .eq('firma_id', TenantManager.instance.requireFirmaId);
                } catch (e) {
                  final fallback = Map<String, dynamic>.from(updateData);
                  final missing = _missingColumnName(e);
                  if (missing != null && fallback.containsKey(missing)) {
                    fallback.remove(missing);
                  }

                  await supabase
                      .from(widget.atamaTablosu)
                      .update(fallback)
                      .eq('id', atama['id']);
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();

                if (mounted) {
                  context.showSuccessSnackBar('✅ $kabulAdet adet kabul edildi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );
  }

  // Reddet Dialog'u
  void _showReddetDialog(Map<String, dynamic> atama) {
    final sebebController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu atamayı reddetmek istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            TextField(
              controller: sebebController,
              decoration: const InputDecoration(
                labelText: 'Red Sebebi',
                border: OutlineInputBorder(),
                helperText: 'Reddetme nedeninizi yazın',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (sebebController.text.isEmpty) {
                  throw Exception('Lütfen red sebebini belirtin');
                }

                final redNotu = '[RED SEBEBİ] ${sebebController.text}';

                await supabase.from(widget.atamaTablosu).update({
                  'durum': 'reddedildi',
                  'notlar': redNotu,
                  if (_eskiAtamaAciklamaKolonuVar) 'aciklama': redNotu,
                }).eq('id', atama['id']);

                if (!context.mounted) return;
                Navigator.pop(context);
                _modelleriGetir();

                if (mounted) {
                  context.showErrorSnackBar('❌ Atama reddedildi');
                }
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  Future<void> _genericDetayDialog(Map<String, dynamic> atama) async {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final durum = atama['durum'] as String?;

    // Başlık: marka + item_no
    final modelAdi = [
      model['marka']?.toString(),
      model['item_no']?.toString(),
    ].where((s) => s != null && s.isNotEmpty).join(' - ');

    // Adet bilgileri
    final talepAdet =
        (atama['talep_edilen_adet'] ?? atama['adet'] ?? model['adet'])
            ?.toString();
    final kabulAdetInt = _atamaInt(
      atama['kabul_edilen_adet'] ??
          atama['talep_edilen_adet'] ??
          atama['adet'] ??
          model['adet'] ??
          0,
    );
    final kabulAdet = kabulAdetInt > 0 ? kabulAdetInt.toString() : null;
    final tamamlananAdet = atama['tamamlanan_adet']?.toString();
    final kabulBedenDagilimi =
        _kabulBedenDagilimiGetir(atama, model, kabulAdetInt);
    final notMetni = _gecerliNotMetni(atama);

    // Tarih yardımcısı
    String? fmtTarih(dynamic val) {
      if (val == null) return null;
      final dt = DateTime.tryParse(val.toString());
      if (dt == null) return val.toString();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          modelAdi.isEmpty ? widget.asamaDisplayName : modelAdi,
          style: const TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDurumBadge(durum),
              const SizedBox(height: 16),
              // Model bilgileri
              if (model['marka'] != null)
                _buildModelBilgisi('Marka', model['marka']?.toString()),
              if (model['item_no'] != null)
                _buildModelBilgisi('Model No', model['item_no']?.toString()),
              if (model['renk'] != null && model['renk'].toString().isNotEmpty)
                _buildModelBilgisi('Renk', model['renk']?.toString()),
              if (model['bedenler'] != null)
                _buildModelBilgisi('Bedenler', model['bedenler']?.toString()),
              const Divider(height: 16),
              // Adet bilgileri
              _buildModelBilgisi('Sipariş Adeti', talepAdet),
              if (kabulAdet != null)
                _buildModelBilgisi('Kabul Adeti', kabulAdet),
              if (kabulBedenDagilimi.isNotEmpty)
                _buildModelBilgisi(
                  'Kabul Beden',
                  _bedenDagilimiMetni(kabulBedenDagilimi),
                ),
              if (tamamlananAdet != null)
                _buildModelBilgisi('Tamamlanan', tamamlananAdet),
              const Divider(height: 16),
              // Tarih bilgileri
              if (model['termin_tarihi'] != null)
                _buildModelBilgisi('Termin', fmtTarih(model['termin_tarihi'])),
              if ((atama['atama_tarihi'] ?? atama['created_at']) != null)
                _buildModelBilgisi('Atama Tarihi',
                    fmtTarih(atama['atama_tarihi'] ?? atama['created_at'])),
              if ((atama['onay_tarihi'] ?? atama['kabul_tarihi']) != null)
                _buildModelBilgisi('Onay Tarihi',
                    fmtTarih(atama['onay_tarihi'] ?? atama['kabul_tarihi'])),
              if ((atama['uretim_baslangic_tarihi'] ??
                      atama['son_guncelleme_tarihi']) !=
                  null)
                _buildModelBilgisi(
                    'Başlangıç',
                    fmtTarih(atama['uretim_baslangic_tarihi'] ??
                        atama['son_guncelleme_tarihi'])),
              if ((atama['tamamlama_tarihi'] ?? atama['teslim_tarihi']) != null)
                _buildModelBilgisi(
                    'Tamamlanma',
                    fmtTarih(
                        atama['tamamlama_tarihi'] ?? atama['teslim_tarihi'])),
              // Notlar
              if (notMetni.isNotEmpty) ...[
                const Divider(height: 16),
                _buildModelBilgisi('Notlar', notMetni),
              ],
              if (atama['red_sebebi'] != null &&
                  atama['red_sebebi'].toString().isNotEmpty)
                _buildModelBilgisi(
                    'Red Sebebi', atama['red_sebebi']?.toString(),
                    textColor: Colors.red),
            ],
          ),
        ),
        actions: [
          if (durum == 'bekleyen' ||
              durum == 'beklemede' ||
              durum == 'atandi' ||
              durum == 'kontrol_bekliyor' ||
              durum == null) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _aksiyon(atama, 'onaylandi');
              },
              child: const Text('Onayla'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reddet(atama);
              },
              child: const Text('Reddet'),
            ),
          ] else if (durum == 'onaylandi' || durum == 'kabul_edildi') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showUretimeAlDialog(atama);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Üretime Al'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.asamaRengi,
                foregroundColor: Colors.white,
              ),
            ),
          ] else if (durum == 'uretimde') ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showTamamlaDialog(atama);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Tamamla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _aksiyon(Map<String, dynamic> atama, String yeniDurum) async {
    try {
      final now = DateTime.now().toIso8601String();
      final firmaId = TenantManager.instance.requireFirmaId;
      final updateData = <String, dynamic>{
        'updated_at': now,
      };

      if (yeniDurum == 'onaylandi') {
        updateData[_eskiAtamaSemasi ? 'kabul_tarihi' : 'onay_tarihi'] = now;
      } else if (yeniDurum == 'uretimde') {
        if (_eskiAtamaSemasi) {
          updateData['son_guncelleme_tarihi'] = now;
        } else {
          updateData['uretim_baslangic_tarihi'] = now;
        }
      } else if (yeniDurum == 'tamamlandi') {
        updateData[_eskiAtamaSemasi ? 'teslim_tarihi' : 'tamamlama_tarihi'] =
            now;
        // Tamamlanan adeti kabul edilen adete eşitle
        final tamamlananAdet = atama['kabul_edilen_adet'] ??
            atama['talep_edilen_adet'] ??
            atama['adet'] ??
            0;
        updateData['tamamlanan_adet'] = tamamlananAdet;
      }

      await _workflowTransitionService.applyTransition(
        tableName: widget.atamaTablosu,
        recordId: atama['id'],
        firmaId: firmaId,
        fromStatus: atama['durum']?.toString(),
        toStatus: yeniDurum,
        extraFields: updateData,
        idempotencyKey:
            '${widget.atamaTablosu}:${atama['id']}:$yeniDurum:aksiyon',
      );

      // Modeller tablosundaki durumu da güncelle (triko_takip)
      try {
        await supabase.from(DbTables.trikoTakip).update(
            {widget.modelDurumKolonu: yeniDurum}).eq('id', atama['model_id']);
      } catch (e) {
        debugPrint('⚠️ Model durumu güncellenemedi (triko_takip): $e');
      }

      // Konfeksiyon tamamlandiginda once kalite kontrole gider.
      // Yikama ve kalite kontrolden sonra sevkiyat kaydi olusturulur.
      if (yeniDurum == 'tamamlandi') {
        final tamamlananAdet = atama['tamamlanan_adet'] ??
            atama['kabul_edilen_adet'] ??
            atama['talep_edilen_adet'] ??
            atama['adet'] ??
            0;
        final downstreamAtama = {
          ...atama,
          'tamamlanan_adet': tamamlananAdet,
          'idempotency_key': '${widget.atamaTablosu}:${atama['id']}:downstream',
          'kaynak_atama_id': atama['id'],
          'kaynak_atama_tablosu': widget.atamaTablosu,
          'onceki_asama': widget.asamaDisplayName,
        };

        if (widget.asamaAdi == 'konfeksiyon') {
          await _kaliteKontrolAtamasiOlustur(
            downstreamAtama,
            tamamlananAdet: tamamlananAdet,
          );
        } else if (widget.asamaAdi == 'yikama' ||
            widget.asamaAdi == 'kalite_kontrol') {
          await _sevkiyatAtamasiOlustur(
            downstreamAtama,
            tamamlananAdet: tamamlananAdet,
          );
        } else {
          await _kaliteKontrolAtamasiOlustur(
            downstreamAtama,
            tamamlananAdet: tamamlananAdet,
          );
        }
      }

      await _modelleriGetir();

      if (!mounted) return;
      context.showSuccessSnackBar(
          '${widget.asamaDisplayName} durumu güncellendi.');
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  /// Kalite kontrol ataması oluştur
  Future<void> _kaliteKontrolAtamasiOlustur(Map<String, dynamic> atama,
      {int? tamamlananAdet}) async {
    try {
      // Model bilgilerini al
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, adet')
          .eq('id', atama['model_id'])
          .maybeSingle();

      if (modelResponse == null) {
        debugPrint('⚠️ Model bulunamadı: ${atama['model_id']}');
        return;
      }

      // Parametreden gelen adet varsa onu kullan, yoksa atamadan al
      final adet = tamamlananAdet ??
          atama['tamamlanan_adet'] ??
          atama['kabul_edilen_adet'] ??
          atama['talep_edilen_adet'] ??
          atama['adet'] ??
          0;
      final firmaId = TenantManager.instance.requireFirmaId;
      final oncekiAsama =
          (atama['onceki_asama'] ?? widget.asamaDisplayName).toString();
      final kaynakAtamaId =
          int.tryParse('${atama['kaynak_atama_id'] ?? atama['id'] ?? ''}');
      final kaynakAtamaTablosu =
          (atama['kaynak_atama_tablosu'] ?? widget.atamaTablosu).toString();
      final idempotencyKey = (atama['idempotency_key'] ??
              '$kaynakAtamaTablosu:${kaynakAtamaId ?? atama['id']}:downstream')
          .toString();
      final idempotencyTag = '[IDEMP:$idempotencyKey]';
      final yeniNot =
          '$oncekiAsama tamamlandi - ${modelResponse['marka']} ${modelResponse['item_no']} - $adet adet $idempotencyTag';
      final bedenDetaylari = _parseBedenDetayi(
        atama['beden_detaylari'] ?? atama['beden_dagilimi'],
      );

      final insertData = <String, dynamic>{
        'model_id': atama['model_id'],
        'durum': 'beklemede',
        'onceki_asama': oncekiAsama,
        'kontrol_edilecek_adet': adet,
        'atama_tarihi': DateTime.now().toIso8601String(),
        'notlar': yeniNot,
        if (bedenDetaylari.isNotEmpty) 'beden_detaylari': bedenDetaylari,
        'firma_id': firmaId,
        'kaynak_atama_tablosu': kaynakAtamaTablosu,
        if (kaynakAtamaId != null) 'kaynak_atama_id': kaynakAtamaId,
        'idempotency_key': idempotencyKey,
      };

      final mergeResult =
          await AtamaBirlestirmeService(client: supabase).insertOrMerge(
        tableName: DbTables.kaliteKontrolAtamalari,
        firmaId: firmaId,
        modelId: atama['model_id'],
        values: insertData,
        idempotencyKey: idempotencyKey,
        quantityFields: const ['kontrol_edilecek_adet'],
      );

      debugPrint(mergeResult['merged'] == true
          ? '✅ Kalite kontrol ataması beden/adet bazında birleştirildi.'
          : '✅ Kalite kontrol ataması oluşturuldu: ${widget.asamaDisplayName} -> Kalite Kontrol');

      // Kalite kontrol rolüne sahip kullanıcılara bildirim gönder
      try {
        await BildirimService().roleGoreBildirimGonder(
          rol: 'kalite_kontrol',
          baslik: '🔍 Yeni Kalite Kontrol Talebi',
          mesaj:
              '${modelResponse['marka']} ${modelResponse['item_no']} - ${widget.asamaDisplayName} aşaması tamamlandı. $adet adet kalite kontrolü bekliyor.',
          tip: 'kalite_kontrol_bekliyor',
          modelId: atama['model_id']?.toString(),
          asama: widget.asamaDisplayName,
        );
        debugPrint('✅ Kalite kontrol bildirim gönderildi');
      } catch (e) {
        debugPrint('⚠️ Bildirim gönderilemedi: $e');
      }
    } catch (e) {
      debugPrint('❌ Kalite kontrol ataması oluşturulamadı: $e');
    }
  }

  /// Yikama veya kalite kontrol tamamlandiginda sevkiyat kaydi olustur.
  Future<void> _sevkiyatAtamasiOlustur(Map<String, dynamic> atama,
      {int? tamamlananAdet}) async {
    try {
      // Model bilgilerini al
      final modelResponse = await supabase
          .from(DbTables.trikoTakip)
          .select('id, marka, item_no, renk, adet')
          .eq('id', atama['model_id'])
          .maybeSingle();

      if (modelResponse == null) {
        debugPrint('⚠️ Model bulunamadı: ${atama['model_id']}');
        return;
      }

      // Parametre olarak gelen adet varsa onu kullan, yoksa atamadan al
      final adet = tamamlananAdet ??
          atama['tamamlanan_adet'] ??
          atama['kabul_edilen_adet'] ??
          atama['talep_edilen_adet'] ??
          atama['adet'] ??
          modelResponse['adet'] ??
          0;
      final oncekiAsama = atama['onceki_asama'] ?? widget.asamaDisplayName;
      final firmaId = TenantManager.instance.requireFirmaId;
      final kaynakAtamaId =
          int.tryParse('${atama['kaynak_atama_id'] ?? atama['id'] ?? ''}');
      final kaynakAtamaTablosu =
          (atama['kaynak_atama_tablosu'] ?? widget.atamaTablosu).toString();
      final idempotencyKey = (atama['idempotency_key'] ??
              '$kaynakAtamaTablosu:${kaynakAtamaId ?? atama['id']}:downstream')
          .toString();
      final idempotencyTag = '[IDEMP:$idempotencyKey]';
      final yeniNot =
          '$oncekiAsama tamamlandı - ${modelResponse['marka']} ${modelResponse['item_no']} $idempotencyTag';

      debugPrint(
          '📦 Sevkiyat ataması oluşturuluyor - Adet: $adet - Önceki Aşama: $oncekiAsama');

      final bedenDetaylariSevk = _parseBedenDetayi(
        atama['beden_detaylari'] ?? atama['beden_dagilimi'],
      );

      final insertData = <String, dynamic>{
        'model_id': atama['model_id'],
        'alinan_adet': adet,
        'sevk_edilen_adet': 0,
        'kalan_adet': adet,
        'durum': 'beklemede',
        'alis_tarihi': DateTime.now().toIso8601String(),
        'notlar': yeniNot,
        'firma_id': firmaId,
        'onceki_asama': oncekiAsama,
        'kaynak_atama_tablosu': kaynakAtamaTablosu,
        if (kaynakAtamaId != null) 'kaynak_atama_id': kaynakAtamaId,
        'idempotency_key': idempotencyKey,
        if (bedenDetaylariSevk.isNotEmpty)
          'beden_detaylari': bedenDetaylariSevk,
      };

      final mergeResult =
          await AtamaBirlestirmeService(client: supabase).insertOrMerge(
        tableName: DbTables.sevkiyatKayitlari,
        firmaId: firmaId,
        modelId: atama['model_id'],
        values: insertData,
        idempotencyKey: idempotencyKey,
        quantityFields: const ['alinan_adet', 'kalan_adet'],
      );

      debugPrint(mergeResult['merged'] == true
          ? '✅ Sevkiyat kaydı beden/adet bazında birleştirildi.'
          : '✅ Sevkiyat kaydı oluşturuldu - $adet adet');

      // 2. Sevkiyat rolüne sahip kullanıcılara bildirim gönder
      try {
        await BildirimService().roleGoreBildirimGonder(
          rol: 'sevkiyat',
          baslik: '📦 Yeni Sevkiyat Talebi',
          mesaj:
              '${modelResponse['marka']} ${modelResponse['item_no']} - $oncekiAsama tamamlandı. $adet adet sevkiyat bekliyor.',
          tip: 'sevkiyat_hazir',
          modelId: atama['model_id']?.toString(),
          asama: oncekiAsama,
        );
        debugPrint('✅ Sevkiyat bildirimi gönderildi');
      } catch (e) {
        debugPrint('⚠️ Bildirim gönderilemedi: $e');
      }

      debugPrint('✅ $oncekiAsama -> Sevkiyat ataması tamamlandı - $adet adet');
    } catch (e) {
      debugPrint('❌ Sevkiyat ataması oluşturulamadı: $e');
    }
  }

  Future<void> _reddet(Map<String, dynamic> atama) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Red Sebebi'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Red sebebini yazın...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _aksiyon(atama, 'reddedildi');
      // Red sebebini de güncelle
      final redNotu = '[RED SEBEBİ] $result';
      try {
        await supabase
            .from(widget.atamaTablosu)
            .update({
              'red_sebebi': result,
              'notlar': redNotu,
              if (_eskiAtamaAciklamaKolonuVar) 'aciklama': redNotu,
            })
            .eq('id', atama['id'])
            .eq('firma_id', TenantManager.instance.requireFirmaId);
      } catch (_) {
        await supabase.from(widget.atamaTablosu).update({
          'red_sebebi': result,
          'notlar': redNotu,
          if (_eskiAtamaAciklamaKolonuVar) 'aciklama': redNotu,
        }).eq('id', atama['id']);
      }
    }
  }

  // Üretime Al Dialog'u
  void _showUretimeAlDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    DateTime planlananBitisTarihi = DateTime.now().add(const Duration(days: 7));
    final idempotencySeed = (atama['updated_at'] ??
            atama['son_guncelleme_tarihi'] ??
            atama['tamamlama_tarihi'] ??
            atama['teslim_tarihi'] ??
            atama['created_at'] ??
            '')
        .toString();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.asamaRengi.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.play_arrow, color: widget.asamaRengi),
                ),
                const SizedBox(width: 12),
                Text('${widget.asamaDisplayName} Başlat'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Renk: ${model['renk'] ?? '-'}'),
                        Text(
                            'Adet: ${atama['kabul_edilen_adet'] ?? atama['talep_edilen_adet'] ?? '-'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Planlanan Bitiş Tarihi',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: planlananBitisTarihi,
                        firstDate: DateTime(2020, 1, 1),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('tr', 'TR'),
                      );
                      if (picked != null) {
                        setDialogState(() => planlananBitisTarihi = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: widget.asamaRengi.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                        color: widget.asamaRengi.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: widget.asamaRengi),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr')
                                .format(planlananBitisTarihi),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.asamaRengi,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit,
                              color: widget.asamaRengi.withValues(alpha: 0.6),
                              size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickDateChip('1 Hafta', 7, planlananBitisTarihi,
                          (days) {
                        setDialogState(() => planlananBitisTarihi =
                            DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('2 Hafta', 14, planlananBitisTarihi,
                          (days) {
                        setDialogState(() => planlananBitisTarihi =
                            DateTime.now().add(Duration(days: days)));
                      }),
                      _buildQuickDateChip('1 Ay', 30, planlananBitisTarihi,
                          (days) {
                        setDialogState(() => planlananBitisTarihi =
                            DateTime.now().add(Duration(days: days)));
                      }),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _workflowTransitionService.applyTransition(
                      tableName: widget.atamaTablosu,
                      recordId: atama['id'],
                      firmaId: TenantManager.instance.requireFirmaId,
                      fromStatus: atama['durum']?.toString(),
                      toStatus: 'uretimde',
                      idempotencyKey:
                          '${widget.atamaTablosu}:${atama['id']}:uretime_al:$idempotencySeed',
                      extraFields: {
                        'uretim_baslangic_tarihi':
                            DateTime.now().toIso8601String(),
                        'planlanan_bitis_tarihi':
                            planlananBitisTarihi.toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      },
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _modelleriGetir();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✅ ${model['marka']} - ${model['item_no']} ${widget.asamaDisplayName} üretimine alındı'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    context.showErrorSnackBar('Hata: $e');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Üretime Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.asamaRengi,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickDateChip(
      String label, int days, DateTime currentDate, Function(int) onSelect) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected = currentDate.difference(targetDate).inDays.abs() < 1;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? widget.asamaRengi.withValues(alpha: 0.2)
          : Colors.grey.shade200,
      side: BorderSide(
          color: isSelected ? widget.asamaRengi : Colors.grey.shade400),
      onPressed: () => onSelect(days),
    );
  }

  // Tamamla Dialog'u - BEDEN BAZLI
  void _showTamamlaDialog(Map<String, dynamic> atama) {
    final model = atama[DbTables.trikoTakip] as Map<String, dynamic>? ?? {};
    final modelId =
        model['id']?.toString() ?? atama['model_id']?.toString() ?? '';
    final atamaId = atama['id'] as Object;

    // Beden bazlı dialog'u aç
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BedenUretimTamamlaDialogGeneric(
        modelId: modelId,
        modelAdi: '${model['marka']} - ${model['item_no']}',
        atamaId: atamaId,
        atama: atama,
        model: model,
        supabase: supabase,
        asamaAdi: widget.asamaAdi,
        asamaDisplayName: widget.asamaDisplayName,
        atamaTablosu: widget.atamaTablosu,
        asamaRengi: widget.asamaRengi,
        onComplete: () {
          _modelleriGetir();
        },
        onKaliteKontrolOlustur: (a, {required int tamamlananAdet}) =>
            _kaliteKontrolAtamasiOlustur(a, tamamlananAdet: tamamlananAdet),
        onSevkiyatOlustur: (a, {required int tamamlananAdet}) =>
            _sevkiyatAtamasiOlustur(a, tamamlananAdet: tamamlananAdet),
      ),
    );
  }

  // Eski toplam adet bazlı dialog - artık kullanılmıyor, yedek olarak duruyor

  Widget _buildModelBilgisi(String label, String? value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: textColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(String? durum) {
    Color color;
    String text;

    switch (durum) {
      case 'atandi':
        color = Colors.orange;
        text = 'Onay Bekliyor';
        break;
      case 'onaylandi':
        color = Colors.green;
        text = 'Onaylandı';
        break;
      case 'reddedildi':
        color = Colors.red;
        text = 'Reddedildi';
        break;
      case 'uretimde':
        color = Colors.blue;
        text = 'İşlemde';
        break;
      case 'tamamlandi':
        color = Colors.purple;
        text = 'Tamamlandı';
        break;
      default:
        color = Colors.grey;
        text = 'Bekliyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModelListesi(
      List<Map<String, dynamic>> modeller, String bosListeMetni) {
    if (yukleniyor) {
      return const LoadingWidget();
    }

    if (modeller.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.asamaIconu,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                bosListeMetni,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _modelleriGetir,
      child: ListView.builder(
        itemCount: modeller.length,
        itemBuilder: (context, index) => _buildModelKarti(modeller[index]),
      ),
    );
  }
}
