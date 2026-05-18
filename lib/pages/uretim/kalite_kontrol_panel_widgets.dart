// ignore_for_file: invalid_use_of_protected_member
part of 'kalite_kontrol_panel.dart';

/// Kalite kontrol panel - widget builder ve dialog metotlari
extension _WidgetDialogExt on _KaliteKontrolPanelState {
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
    required int kontrolde,
    required int tamamlanan,
    required int toplam,
    required bool aktifFiltreVar,
  }) {
    const kaliteRengi = Color(0xFF0F766E);
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
                        color: kaliteRengi.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: kaliteRengi,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalite Kontrol Paneli',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Üretimden gelen işler kontrol ediliyor',
                            style: TextStyle(
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
                          onPressed: _showAramaDialog,
                        ),
                        _buildErpAksiyonButonu(
                          icon: Icons.filter_alt,
                          tooltip: 'Filtrele',
                          onPressed: _showFiltreDialog,
                          aktif: aktifFiltreVar,
                        ),
                        _buildErpAksiyonButonu(
                          icon: Icons.analytics_outlined,
                          tooltip: 'Rapor',
                          onPressed: _showKaliteRaporDialog,
                        ),
                        _buildErpAksiyonButonu(
                          icon: Icons.refresh,
                          tooltip: 'Yenile',
                          onPressed: _verileriYukle,
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
                    _buildHeaderMetric(
                      'Toplam',
                      toplam.toString(),
                      Icons.assignment_outlined,
                      kaliteRengi,
                    ),
                    _buildHeaderMetric(
                      'Bekleyen',
                      bekleyen.toString(),
                      Icons.pending_actions,
                      const Color(0xFFEF6C00),
                    ),
                    _buildHeaderMetric(
                      'Kontrolde',
                      kontrolde.toString(),
                      Icons.search,
                      const Color(0xFF1565C0),
                    ),
                    _buildHeaderMetric(
                      'Tamamlanan',
                      tamamlanan.toString(),
                      Icons.task_alt,
                      const Color(0xFF2E7D32),
                    ),
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
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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

  void _showKaliteRaporDialog() {
    final tumKayitlar = [
      ...bekleyenler,
      ...kontrolEdiliyor,
      ...tamamlananlar,
    ];
    final toplamAdet = tumKayitlar.fold<int>(
      0,
      (sum, item) => sum + _kaliteRaporAdet(item),
    );
    final kabulAdet = tamamlananlar
        .where((item) => _kaliteDurum(item) == 'onay')
        .fold<int>(0, (sum, item) => sum + _kaliteRaporAdet(item));
    final redAdet = tamamlananlar
        .where((item) => _kaliteDurum(item) == 'red')
        .fold<int>(0, (sum, item) => sum + _kaliteRaporAdet(item));
    final kontroldeAdet = kontrolEdiliyor.fold<int>(
      0,
      (sum, item) => sum + _kaliteRaporAdet(item),
    );
    final bekleyenAdet = bekleyenler.fold<int>(
      0,
      (sum, item) => sum + _kaliteRaporAdet(item),
    );
    final sonucAdet = kabulAdet + redAdet;
    final kabulOrani = sonucAdet > 0 ? (kabulAdet / sonucAdet) * 100 : 0.0;
    final redOrani = sonucAdet > 0 ? (redAdet / sonucAdet) * 100 : 0.0;
    final asamaDagilimi = <String, int>{};
    for (final item in tumKayitlar) {
      final asama = (item['onceki_asama'] ?? 'Belirsiz').toString();
      asamaDagilimi[asama] = (asamaDagilimi[asama] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('Kalite ERP Raporu'),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildRaporKpi('İş Emri', '${tumKayitlar.length}',
                        Icons.assignment_outlined, const Color(0xFF0F766E)),
                    _buildRaporKpi('Kontrol Adedi', '$toplamAdet',
                        Icons.fact_check_outlined, const Color(0xFF2563EB)),
                    _buildRaporKpi('Bekleyen', '$bekleyenAdet',
                        Icons.pending_actions, const Color(0xFFD97706)),
                    _buildRaporKpi('Kontrolde', '$kontroldeAdet', Icons.search,
                        const Color(0xFF7C3AED)),
                    _buildRaporKpi('Kabul', '$kabulAdet',
                        Icons.verified_outlined, const Color(0xFF059669)),
                    _buildRaporKpi('Red', '$redAdet', Icons.cancel_outlined,
                        const Color(0xFFDC2626)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildRaporBlok(
                  baslik: 'Kalite Sonuçları',
                  satirlar: [
                    MapEntry(
                        'Kabul Oranı', '%${kabulOrani.toStringAsFixed(1)}'),
                    MapEntry('Red Oranı', '%${redOrani.toStringAsFixed(1)}'),
                    MapEntry('Sonuçlanan Adet', '$sonucAdet'),
                    MapEntry('Açık Kontrol Adedi',
                        '${bekleyenAdet + kontroldeAdet}'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRaporBlok(
                  baslik: 'Kaynak Aşama Dağılımı',
                  satirlar: asamaDagilimi.entries.isEmpty
                      ? [const MapEntry('Kayıt', '-')]
                      : asamaDagilimi.entries
                          .map((entry) =>
                              MapEntry(entry.key, '${entry.value} iş'))
                          .toList(),
                ),
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

  int _kaliteRaporAdet(Map<String, dynamic> item) {
    final model = item[DbTables.trikoTakip] as Map<String, dynamic>?;
    return _toInt(item['kontrol_edilecek_adet']) > 0
        ? _toInt(item['kontrol_edilecek_adet'])
        : _toInt(item['kabul_edilen_adet']) > 0
            ? _toInt(item['kabul_edilen_adet'])
            : _toInt(model?['adet']);
  }

  String _kaliteDurum(Map<String, dynamic> item) {
    final durum = (item['durum'] ?? '').toString();
    if (durum == 'reddedildi' || durum == 'kalite_red') return 'red';
    if (durum == 'tamamlandi' ||
        durum == 'onaylandi' ||
        durum == 'kalite_onay') {
      return 'onay';
    }
    return 'acik';
  }

  Widget _buildRaporKpi(
      String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildRaporBlok({
    required String baslik,
    required List<MapEntry<String, String>> satirlar,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Divider(height: 18),
          ...satirlar.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key,
                        style: const TextStyle(color: Color(0xFF475569))),
                  ),
                  Text(entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAktifFiltreSeridi() {
    final filtreler = [
      if (aramaMetni.isNotEmpty) '"$aramaMetni"',
      if (seciliAsama != null) 'Aşama: $seciliAsama',
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

  void _filtreleriTemizle() {
    setState(() {
      aramaMetni = '';
      seciliAsama = null;
      _aramaController.clear();
    });
  }

  Widget _buildKaliteTabSeridi({
    required int bekleyen,
    required int kontrolde,
    required int tamamlanan,
  }) {
    const kaliteRengi = Color(0xFF0F766E);
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
              indicatorColor: kaliteRengi,
              indicatorWeight: 3,
              labelColor: kaliteRengi,
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
                  icon: const Icon(Icons.search),
                  text: 'Kontrolde ($kontrolde)',
                ),
                Tab(
                  icon: const Icon(Icons.task_alt),
                  text: 'Tamamlanan ($tamamlanan)',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKontrolListesi(
      List<Map<String, dynamic>> kontroller, String tip) {
    if (kontroller.isEmpty) {
      return RefreshIndicator(
        onRefresh: _verileriYukle,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tip == 'bekleyen'
                          ? Icons.pending_actions
                          : tip == 'kontrolde'
                              ? Icons.search
                              : Icons.check_circle,
                      size: 72,
                      color: const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tip == 'bekleyen'
                          ? 'Bekleyen kalite kontrol yok'
                          : tip == 'kontrolde'
                              ? 'Kontrol edilen is yok'
                              : 'Tamamlanan is yok',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
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

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        itemCount: kontroller.length,
        itemBuilder: (context, index) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1550),
            child: _buildKontrolKarti(kontroller[index], tip),
          ),
        ),
      ),
    );
  }

  Widget _buildKontrolKarti(Map<String, dynamic> kontrol, String tip) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final durum = kontrol['durum'] as String?;
    final oncekiAsama = kontrol['onceki_asama'] as String? ?? 'Bilinmiyor';
    final kontrolAdet = kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: _getAsamaRengi(oncekiAsama).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAsamaIkonu(oncekiAsama),
                    color: _getAsamaRengi(oncekiAsama),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${model['marka']} - ${model['item_no']}',
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
                            _getAsamaIkonu(oncekiAsama),
                            oncekiAsama,
                            color: _getAsamaRengi(oncekiAsama),
                          ),
                          _buildKisaBilgi(
                            Icons.palette_outlined,
                            (model['renk'] ?? '-').toString(),
                          ),
                          if (kontrol['atama_tarihi'] != null)
                            _buildKisaBilgi(
                              Icons.assignment_ind_outlined,
                              DateFormat('dd.MM.yyyy HH:mm').format(
                                DateTime.parse(kontrol['atama_tarihi']),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDurumBadge(durum),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildKontrolMetric(
                  'Kontrol',
                  '$kontrolAdet',
                  Icons.fact_check_outlined,
                  const Color(0xFF0F766E),
                ),
                FutureBuilder<int>(
                  future: _getModelToplamAdet(model['id']),
                  builder: (context, snapshot) {
                    final toplamAdet = snapshot.data ?? model['adet'] ?? 0;
                    return _buildKontrolMetric(
                      'Model',
                      toplamAdet > 0 ? '$toplamAdet' : '-',
                      Icons.inventory_2_outlined,
                      const Color(0xFF2563EB),
                    );
                  },
                ),
                if (model['termin_tarihi'] != null)
                  _buildKontrolMetric(
                    'Termin',
                    DateFormat('dd.MM.yyyy').format(
                      DateTime.parse(model['termin_tarihi']),
                    ),
                    Icons.event_outlined,
                    const Color(0xFFEA580C),
                  ),
              ],
            ),
            if (kontrol['red_sebebi'] != null &&
                kontrol['red_sebebi'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNotKutusu(
                kontrol['red_sebebi'].toString(),
                color: const Color(0xFFDC2626),
                icon: Icons.report_problem_outlined,
              ),
            ],
            if (kontrol['notlar'] != null &&
                _temizNotMetni(kontrol['notlar']?.toString()).isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNotKutusu(_temizNotMetni(kontrol['notlar']?.toString())),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _buildAksiyonButonlari(kontrol, tip),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKisaBilgi(IconData icon, String value, {Color? color}) {
    final renk = color ?? const Color(0xFF64748B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: renk),
        const SizedBox(width: 5),
        Text(
          value.isEmpty ? '-' : value,
          style: TextStyle(
            fontSize: 12,
            color: renk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildKontrolMetric(
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

  Widget _buildNotKutusu(
    String text, {
    Color color = const Color(0xFF475569),
    IconData icon = Icons.notes_outlined,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumBadge(String? durum) {
    Color renk;
    String metin;

    switch (durum) {
      case 'beklemede':
      case 'atandi':
      case 'kontrol_bekliyor':
        renk = Colors.orange;
        metin = 'Bekliyor';
        break;
      case 'kontrolde':
        renk = Colors.blue;
        metin = 'Kontrol Ediliyor';
        break;
      case 'onaylandi':
      case 'kalite_onay':
      case 'tamamlandi':
        renk = Colors.green;
        metin = 'Onaylandı';
        break;
      case 'reddedildi':
      case 'kalite_red':
        renk = Colors.red;
        metin = 'Reddedildi';
        break;
      default:
        renk = Colors.grey;
        metin = durum ?? 'Bilinmiyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        metin,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAksiyonButonlari(Map<String, dynamic> kontrol, String tip) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Detay butonu
        OutlinedButton.icon(
          onPressed: () => _showDetayDialog(kontrol),
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Detay'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
        ),

        // Bekleyenler icin aksiyonlar
        if (tip == 'bekleyen') ...[
          ElevatedButton.icon(
            onPressed: () => _kontrolBaslat(kontrol),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Kontrole Başla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],

        // Kontrol edilenler icin aksiyonlar
        if (tip == 'kontrolde') ...[
          ElevatedButton.icon(
            onPressed: () => _showOnaylaDialog(kontrol),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showReddetDialog(kontrol),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Color _getAsamaRengi(String asama) {
    switch (asama) {
      case 'Dokuma':
        return Colors.brown;
      case 'Konfeksiyon':
        return Colors.purple;
      case 'Yıkama':
        return Colors.cyan;
      case 'Ütü':
        return Colors.orange;
      case 'İlik Düğme':
        return Colors.indigo;
      case 'Paketleme':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getAsamaIkonu(String asama) {
    switch (asama) {
      case 'Dokuma':
        return Icons.grid_on;
      case 'Konfeksiyon':
        return Icons.checkroom;
      case 'Yıkama':
        return Icons.local_laundry_service;
      case 'Ütü':
        return Icons.iron;
      case 'İlik Düğme':
        return Icons.radio_button_checked;
      case 'Paketleme':
        return Icons.inventory_2;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _kontrolBaslat(Map<String, dynamic> kontrol) async {
    try {
      await _workflowTransitionService.applyTransition(
        tableName: DbTables.kaliteKontrolAtamalari,
        recordId: kontrol['id'],
        firmaId: TenantManager.instance.requireFirmaId,
        fromStatus: kontrol['durum']?.toString(),
        toStatus: 'baslandi',
        idempotencyKey: 'kalite:${kontrol['id']}:baslat',
        extraFields: {
          'baslangic_tarihi': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kalite kontrolü başlatıldı'),
          backgroundColor: Colors.blue,
        ),
      );

      await _verileriYukle();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  String _normalizeAsamaKodu(String? rawAsama) {
    final value = (rawAsama ?? '')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .trim();

    if (value.contains('dokuma')) return 'dokuma';
    if (value.contains('nakis')) return 'nakis';
    if (value.contains('konfeksiyon')) return 'konfeksiyon';
    if (value.contains('yikama')) return 'yikama';
    if (value.contains('utu')) return 'utu';
    if (value.contains('ilik') || value.contains('dugme')) return 'ilik_dugme';
    if (value.contains('paket')) return 'paketleme';
    if (value.contains('kalite')) return 'kalite_kontrol';
    if (value.contains('sevkiyat') || value.contains('depo')) return 'sevkiyat';

    return value.replaceAll(' ', '_');
  }

  String _kaliteSonrasiHedefAsama(String oncekiAsama) {
    switch (_normalizeAsamaKodu(oncekiAsama)) {
      case 'dokuma':
        return 'nakis';
      case 'nakis':
        return 'konfeksiyon';
      case 'konfeksiyon':
        return 'sevkiyat';
      case 'yikama':
        return 'utu';
      case 'utu':
        return 'ilik_dugme';
      case 'ilik_dugme':
      case 'paketleme':
      case 'kalite_kontrol':
      default:
        return 'sevkiyat';
    }
  }

  String _asamaDisplayAdi(String asamaKodu) {
    switch (asamaKodu) {
      case 'dokuma':
        return 'Dokuma';
      case 'nakis':
        return 'Nakış';
      case 'konfeksiyon':
        return 'Konfeksiyon';
      case 'yikama':
        return 'Yıkama';
      case 'utu':
        return 'Ütü';
      case 'ilik_dugme':
        return 'İlik Düğme';
      case 'paketleme':
        return 'Paketleme';
      case 'sevkiyat':
        return 'Sevkiyat';
      default:
        return asamaKodu;
    }
  }

  String? _asamaTablosu(String asamaKodu) {
    switch (asamaKodu) {
      case 'dokuma':
        return DbTables.dokumaAtamalari;
      case 'nakis':
        return DbTables.nakisAtamalari;
      case 'konfeksiyon':
        return DbTables.konfeksiyonAtamalari;
      case 'yikama':
        return DbTables.yikamaAtamalari;
      case 'utu':
        return DbTables.utuAtamalari;
      case 'ilik_dugme':
        return DbTables.ilikDugmeAtamalari;
      case 'paketleme':
        return DbTables.paketlemeAtamalari;
      default:
        return null;
    }
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _toplamAdetMetni(
    Map<String, dynamic> model,
    Map<String, dynamic> kontrol,
  ) {
    final modelAdet = _toInt(model['adet']);
    final kontrolAdet = _toInt(kontrol['kontrol_edilecek_adet']);
    final toplam = modelAdet > 0 ? modelAdet : kontrolAdet;
    return toplam > 0 ? '$toplam' : '-';
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
        final qty = _toInt(adet);
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
        final qty = _toInt(
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

    var dagitilacak = hedefToplam - _toplamBedenAdedi(tabanDegerler);
    kalanlar
        .sort((a, b) => (b['kalan'] as double).compareTo(a['kalan'] as double));

    for (var i = 0; i < dagitilacak; i++) {
      final beden = kalanlar[i % kalanlar.length]['beden'] as String;
      tabanDegerler[beden] = (tabanDegerler[beden] ?? 0) + 1;
    }

    tabanDegerler.removeWhere((_, value) => value <= 0);
    return _siraliBedenMap(tabanDegerler);
  }

  String? _asamaBedenTakipTablosu(String? asamaKodu) {
    switch (_normalizeAsamaKodu(asamaKodu)) {
      case 'dokuma':
        return 'dokuma_beden_takip';
      case 'nakis':
        return 'nakis_beden_takip';
      case 'konfeksiyon':
        return 'konfeksiyon_beden_takip';
      case 'yikama':
        return 'yikama_beden_takip';
      case 'utu':
        return 'utu_beden_takip';
      case 'ilik_dugme':
        return 'ilik_dugme_beden_takip';
      case 'paketleme':
        return 'paketleme_beden_takip';
      default:
        return null;
    }
  }

  Future<Map<String, int>> _asamaBedenGerceklesenAdetleriGetir({
    required String modelId,
    required String? asamaKodu,
  }) async {
    final tablo = _asamaBedenTakipTablosu(asamaKodu);
    if (tablo == null) return const <String, int>{};

    var useFirmaFilter = true;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        var query = supabase.from(tablo).select('*').eq('model_id', modelId);
        if (useFirmaFilter) {
          query = query.eq('firma_id', TenantManager.instance.requireFirmaId);
        }

        final response = await query;
        final sonuc = <String, int>{};

        for (final row in List<Map<String, dynamic>>.from(response)) {
          final beden =
              (row['beden_kodu'] ?? '').toString().trim().toUpperCase();
          if (beden.isEmpty) continue;

          final uretilen = _toInt(row['uretilen_adet']);
          final fire = _toInt(row['fire_adet']);
          final kabul = _toInt(row['kabul_edilen_adet']);
          final hedef = _toInt(row['hedef_adet']);

          final net = uretilen > 0
              ? (uretilen - fire).clamp(0, 999999999).toInt()
              : (kabul > 0 ? kabul : hedef);

          if (net <= 0) continue;
          sonuc[beden] = (sonuc[beden] ?? 0) + net;
        }

        return _siraliBedenMap(sonuc);
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn == 'firma_id' && useFirmaFilter) {
          useFirmaFilter = false;
          continue;
        }
        break;
      }
    }

    return const <String, int>{};
  }

  String? _rpcSonrakiAsamaKodu(String oncekiAsamaKodu) {
    switch (oncekiAsamaKodu) {
      case 'dokuma':
        return 'konfeksiyon';
      case 'konfeksiyon':
        return 'yikama';
      case 'yikama':
        return 'utu';
      case 'utu':
        return 'ilik_dugme';
      case 'ilik_dugme':
        return 'kalite_kontrol';
      case 'paketleme':
        return 'sevkiyat';
      default:
        return null;
    }
  }

  String _bedenDagilimiMetni(Map<String, int> bedenler) {
    if (bedenler.isEmpty) return '-';
    return bedenler.entries.map((e) => '${e.key}:${e.value}').join(' | ');
  }

  Widget _buildBedenDagilimiKutusu(
    Map<String, int> bedenler, {
    Color? color,
  }) {
    if (bedenler.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF0F766E)).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? const Color(0xFF0F766E)).withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beden Dağılımı',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bedenler.entries
                .map(
                  (entry) => Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _kontrolBedenDagilimiGetir({
    required Map<String, dynamic> kontrol,
    required Map<String, dynamic> model,
    required int kontrolAdedi,
  }) async {
    final kayitli = _parseBedenDetayi(
      kontrol['beden_detaylari'] ?? kontrol['beden_dagilimi'],
    );
    if (kayitli.isNotEmpty) {
      return _siraliBedenMap(kayitli);
    }

    final kaynakAtamaBeden = await _kaynakAtamadanBedenDagilimiGetir(
      kontrol: kontrol,
      kontrolAdedi: kontrolAdedi,
    );
    if (kaynakAtamaBeden.isNotEmpty) {
      return _siraliBedenMap(kaynakAtamaBeden);
    }

    final modelId = (kontrol['model_id'] ?? model['id'])?.toString();
    if (modelId == null || modelId.isEmpty) return const <String, int>{};

    final oncekiAsamaKodu = _normalizeAsamaKodu(
      kontrol['onceki_asama']?.toString(),
    );

    final oncekiAsamaGerceklesen = await _asamaBedenGerceklesenAdetleriGetir(
      modelId: modelId,
      asamaKodu: oncekiAsamaKodu,
    );
    if (oncekiAsamaGerceklesen.isNotEmpty) {
      return _siraliBedenMap(oncekiAsamaGerceklesen);
    }

    final rpcSonrakiAsama = _rpcSonrakiAsamaKodu(oncekiAsamaKodu);
    if (rpcSonrakiAsama != null) {
      try {
        final oncekiAsama =
            await _bedenService.getOncekiAsamaGerceklesenAdetler(
          modelId,
          rpcSonrakiAsama,
        );
        if (oncekiAsama.isNotEmpty) {
          return _siraliBedenMap(oncekiAsama);
        }
      } catch (_) {}
    }

    try {
      final response = await supabase
          .from(DbTables.modelBedenDagilimi)
          .select('beden_kodu, siparis_adedi')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('model_id', modelId);

      final dagilim = <String, int>{};
      for (final row in List<Map<String, dynamic>>.from(response)) {
        final beden = (row['beden_kodu'] ?? '').toString().trim().toUpperCase();
        final adet = _toInt(row['siparis_adedi']);
        if (beden.isNotEmpty && adet > 0) {
          dagilim[beden] = adet;
        }
      }

      if (dagilim.isNotEmpty) {
        return _toplamaUyarliBedenMap(dagilim, kontrolAdedi);
      }
    } catch (_) {}

    return const <String, int>{};
  }

  Future<Map<String, int>> _kaynakAtamadanBedenDagilimiGetir({
    required Map<String, dynamic> kontrol,
    required int kontrolAdedi,
  }) async {
    final tablo = (kontrol['kaynak_atama_tablosu'] ?? '').toString().trim();
    if (tablo.isEmpty) return const <String, int>{};

    final hamKaynakAtamaId = kontrol['kaynak_atama_id'];
    if (hamKaynakAtamaId == null) return const <String, int>{};

    final adayKaynakIdler = <dynamic>[hamKaynakAtamaId];
    final kaynakIdMetin = hamKaynakAtamaId.toString().trim();
    final kaynakIdInt = int.tryParse(kaynakIdMetin);
    if (kaynakIdInt != null && kaynakIdInt != hamKaynakAtamaId) {
      adayKaynakIdler.add(kaynakIdInt);
    }

    for (final kaynakId in adayKaynakIdler) {
      try {
        final kaynakAtama = await supabase
            .from(tablo)
            .select('*')
            .eq('id', kaynakId)
            .maybeSingle();

        if (kaynakAtama == null) continue;

        final kaynakBeden = _parseBedenDetayi(
          kaynakAtama['beden_detaylari'] ?? kaynakAtama['beden_dagilimi'],
        );
        if (kaynakBeden.isNotEmpty) {
          return _toplamaUyarliBedenMap(kaynakBeden, kontrolAdedi);
        }
      } catch (_) {
        // Kaynak atama kolonu/erişimi farklı şemada olmayabilir.
      }
    }

    return const <String, int>{};
  }

  String _temizNotMetni(String? raw) {
    final text = (raw ?? '').toString();
    if (text.isEmpty) return '';

    return text
        .replaceAll(RegExp(r'\[(?:IDEMP|REWORK):[^\]]+\]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(' \n', '\n')
        .trim();
  }

  String? _missingColumnName(Object error) {
    if (error is! PostgrestException) return null;
    final message =
        '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();

    // PGRST204: Could not find the 'column_name' column of 'table' in the schema cache
    final pgrst204 = RegExp(
      r"could not find the '([a-z0-9_]+)' column",
    ).firstMatch(message);
    if (pgrst204 != null) return pgrst204.group(1);

    final withTable = RegExp(
      r'column\s+[a-z0-9_]+\.([a-z0-9_]+)\s+does\s+not\s+exist',
    ).firstMatch(message);
    if (withTable != null) return withTable.group(1);

    final plain = RegExp(
      r'column\s+"?([a-z0-9_]+)"?\s+does\s+not\s+exist',
    ).firstMatch(message);
    return plain?.group(1);
  }

  Future<List<Map<String, dynamic>>> _adayAtamaKayitlariGetir({
    required String hedefTablo,
    required String firmaId,
    required dynamic modelId,
  }) async {
    var includeNotlar = true;
    var useFirmaFilter = true;
    var useModelFilter = true;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        final secim = includeNotlar ? 'id, notlar' : 'id';

        final response = useFirmaFilter && useModelFilter
            ? await supabase
                .from(hedefTablo)
                .select(secim)
                .eq('firma_id', firmaId)
                .eq('model_id', modelId)
                .order('created_at', ascending: false)
                .limit(10)
            : useFirmaFilter
                ? await supabase
                    .from(hedefTablo)
                    .select(secim)
                    .eq('firma_id', firmaId)
                    .order('created_at', ascending: false)
                    .limit(10)
                : useModelFilter
                    ? await supabase
                        .from(hedefTablo)
                        .select(secim)
                        .eq('model_id', modelId)
                        .order('created_at', ascending: false)
                        .limit(10)
                    : await supabase
                        .from(hedefTablo)
                        .select(secim)
                        .order('created_at', ascending: false)
                        .limit(10);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn == 'firma_id' && useFirmaFilter) {
          useFirmaFilter = false;
          continue;
        }
        if (missingColumn == 'model_id' && useModelFilter) {
          useModelFilter = false;
          continue;
        }
        if (missingColumn == 'notlar' && includeNotlar) {
          includeNotlar = false;
          continue;
        }

        if (includeNotlar) {
          includeNotlar = false;
          continue;
        }

        rethrow;
      }
    }

    return const <Map<String, dynamic>>[];
  }

  Future<void> _esnekAtamaGuncelle({
    required String hedefTablo,
    required dynamic kayitId,
    required String firmaId,
    required Map<String, dynamic> values,
  }) async {
    final data = Map<String, dynamic>.from(values);
    var useFirmaFilter = true;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        var query = supabase.from(hedefTablo).update(data).eq('id', kayitId);
        if (useFirmaFilter) {
          query = query.eq('firma_id', firmaId);
        }

        await query;
        return;
      } catch (e) {
        final missingColumn = _missingColumnName(e);
        if (missingColumn == 'firma_id' && useFirmaFilter) {
          useFirmaFilter = false;
          continue;
        }
        if (missingColumn != null && data.containsKey(missingColumn)) {
          data.remove(missingColumn);
          continue;
        }

        if (data.containsKey('notlar')) {
          data.remove('notlar');
          continue;
        }

        rethrow;
      }
    }

    throw Exception('$hedefTablo güncellemesi başarısız oldu.');
  }

  Future<void> _esnekAtamaInsert({
    required String hedefTablo,
    required Map<String, dynamic> values,
  }) async {
    final data = Map<String, dynamic>.from(values);
    Object? sonHata;
    const siraliOpsiyonelAlanlar = [
      'model_id',
      'idempotency_key',
      'kaynak_kalite_kontrol_id',
      'kabul_edilen_adet',
      'beden_detaylari',
      'onceki_asama',
      'hedef_asama',
      'kalite_kontrol_id',
      'alis_tarihi',
      'notlar',
    ];

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await supabase.from(hedefTablo).insert(data);
        return;
      } catch (e) {
        sonHata = e;
        final missingColumn = _missingColumnName(e);
        if (missingColumn != null && data.containsKey(missingColumn)) {
          data.remove(missingColumn);
          continue;
        }

        final kaldirilacak = siraliOpsiyonelAlanlar
            .firstWhere((alan) => data.containsKey(alan), orElse: () => '');
        if (kaldirilacak.isNotEmpty) {
          data.remove(kaldirilacak);
          continue;
        }

        break;
      }
    }

    throw Exception('$hedefTablo insert başarısız oldu. Son hata: $sonHata');
  }

  Future<void> _upsertSevkiyatKaydiFromKalite({
    required Map<String, dynamic> kontrol,
    required Map<String, dynamic> model,
    required int kontrolAdet,
    required Map<String, int> bedenDetaylari,
    required String oncekiAsama,
    required String hedefAsama,
    required String idempotencyKey,
  }) async {
    final firmaId = TenantManager.instance.requireFirmaId;
    final idTag = '[IDEMP:$idempotencyKey]';

    final notMetni =
        'Kalite kontrol onaylandı - ${model['marka']} ${model['item_no']} $idTag';

    final insertData = {
      'model_id': kontrol['model_id'],
      'kalite_kontrol_id': kontrol['id'],
      'sevkiyat_personeli_id': supabase.auth.currentUser?.id,
      'onceki_asama': oncekiAsama,
      'hedef_asama': hedefAsama,
      'alinan_adet': kontrolAdet,
      'sevk_edilen_adet': 0,
      'kalan_adet': kontrolAdet,
      'durum': 'beklemede',
      'alis_tarihi': DateTime.now().toIso8601String(),
      'notlar': notMetni,
      if (bedenDetaylari.isNotEmpty) 'beden_detaylari': bedenDetaylari,
      'firma_id': firmaId,
      'idempotency_key': idempotencyKey,
    };

    await AtamaBirlestirmeService(client: supabase).insertOrMerge(
      tableName: DbTables.sevkiyatKayitlari,
      firmaId: firmaId,
      modelId: kontrol['model_id'],
      values: insertData,
      idempotencyKey: idempotencyKey,
      quantityFields: const ['alinan_adet', 'kalan_adet'],
    );
  }

  Future<void> _upsertAsamaAtamasiFromKalite({
    required String hedefAsama,
    required String hedefTablo,
    required Map<String, dynamic> kontrol,
    required Map<String, dynamic> model,
    required int kontrolAdet,
    required String idempotencyKey,
  }) async {
    final firmaId = TenantManager.instance.requireFirmaId;
    final idTag = '[IDEMP:$idempotencyKey]';

    final notMetni =
        'Kalite kontrolden geçti - ${model['marka']} ${model['item_no']} - $kontrolAdet adet $idTag';

    final insertData = {
      'model_id': kontrol['model_id'],
      'durum': 'bekleyen',
      'adet': kontrolAdet,
      'talep_edilen_adet': kontrolAdet,
      'kabul_edilen_adet': kontrolAdet,
      'tamamlanan_adet': 0,
      'atama_tarihi': DateTime.now().toIso8601String(),
      'notlar': notMetni,
      'firma_id': firmaId,
      'kaynak_kalite_kontrol_id': kontrol['id'],
      'idempotency_key': idempotencyKey,
    };

    await AtamaBirlestirmeService(client: supabase).insertOrMerge(
      tableName: hedefTablo,
      firmaId: firmaId,
      modelId: kontrol['model_id'],
      values: insertData,
      idempotencyKey: idempotencyKey,
    );

    await BildirimService().roleGoreBildirimGonder(
      rol: hedefAsama,
      baslik: '✅ Kalite Onayı Tamamlandı',
      mesaj:
          '${model['marka']} ${model['item_no']} - $kontrolAdet adet $hedefAsama aşamasına yönlendirildi.',
      tip: 'kalite_onay_hedef_atama',
      modelId: kontrol['model_id']?.toString(),
      asama: 'Kalite Kontrol',
    );
  }

  Future<void> _kaliteRedReworkAtamasiOlustur({
    required Map<String, dynamic> kontrol,
    required Map<String, dynamic> model,
    required String redSebebi,
  }) async {
    final kaynakAsama =
        _normalizeAsamaKodu(kontrol['onceki_asama']?.toString());
    final hedefTablo = _asamaTablosu(kaynakAsama);
    if (hedefTablo == null) {
      debugPrint('⚠️ Rework için hedef tablo bulunamadı: $kaynakAsama');
      return;
    }

    final firmaId = TenantManager.instance.requireFirmaId;
    final reworkAdet = kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? 0;
    final idempotencyKey = 'kalite_red:${kontrol['id']}';
    final tag = '[REWORK:$idempotencyKey]';
    final notMetni =
        'Kalite redi sonrası rework - ${model['marka']} ${model['item_no']} - $reworkAdet adet | Sebep: $redSebebi $tag';

    final insertData = {
      'model_id': kontrol['model_id'],
      'durum': 'bekleyen',
      'adet': reworkAdet,
      'talep_edilen_adet': reworkAdet,
      'tamamlanan_adet': 0,
      'atama_tarihi': DateTime.now().toIso8601String(),
      'notlar': notMetni,
      'firma_id': firmaId,
      'idempotency_key': idempotencyKey,
      'kaynak_kalite_kontrol_id': kontrol['id'],
    };

    await AtamaBirlestirmeService(client: supabase).insertOrMerge(
      tableName: hedefTablo,
      firmaId: firmaId,
      modelId: kontrol['model_id'],
      values: insertData,
      idempotencyKey: idempotencyKey,
    );

    await BildirimService().roleGoreBildirimGonder(
      rol: kaynakAsama,
      baslik: '🔁 Rework Talebi',
      mesaj:
          '${model['marka']} ${model['item_no']} kalite kontrolden reddedildi. Rework için $reworkAdet adet yeniden işleme alındı.',
      tip: 'kalite_red_rework',
      modelId: kontrol['model_id']?.toString(),
      asama: 'Kalite Kontrol',
    );
  }

  Future<void> _showOnaylaDialog(Map<String, dynamic> kontrol) async {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final kontrolAdet = kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? 0;
    final bedenDetaylari = await _kontrolBedenDagilimiGetir(
      kontrol: kontrol,
      model: model,
      kontrolAdedi: _toInt(kontrolAdet),
    );
    if (!mounted) return;

    final notlarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Kalite Kontrolü Onayla'),
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
                    Text('${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
                    Text('Kontrol Edilen: $kontrolAdet adet'),
                  ],
                ),
              ),
              if (bedenDetaylari.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildBedenDagilimiKutusu(bedenDetaylari, color: Colors.green),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(
                  labelText: 'Kalite Kontrol Notları (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Onay sonrası ürünler bir sonraki aşamaya geçebilir.',
                        style: TextStyle(
                            color: Colors.green.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
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
                final oncekiAsama = (kontrol['onceki_asama'] ?? '').toString();
                final hedefAsama = _kaliteSonrasiHedefAsama(oncekiAsama);
                final hedefAsamaDisplay = _asamaDisplayAdi(hedefAsama);
                final idempotencyKey = 'kalite:${kontrol['id']}:onay';
                final onayNotu = notlarController.text.trim();

                await _workflowTransitionService.applyTransition(
                  tableName: DbTables.kaliteKontrolAtamalari,
                  recordId: kontrol['id'],
                  firmaId: TenantManager.instance.requireFirmaId,
                  fromStatus: kontrol['durum']?.toString(),
                  toStatus: 'tamamlandi',
                  idempotencyKey: idempotencyKey,
                  extraFields: {
                    'tamamlanma_tarihi': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                    if (onayNotu.isNotEmpty) 'notlar': onayNotu,
                  },
                );

                if (bedenDetaylari.isNotEmpty) {
                  await _esnekAtamaGuncelle(
                    hedefTablo: DbTables.kaliteKontrolAtamalari,
                    kayitId: kontrol['id'],
                    firmaId: TenantManager.instance.requireFirmaId,
                    values: {
                      'beden_detaylari': bedenDetaylari,
                      'updated_at': DateTime.now().toIso8601String(),
                    },
                  );
                }

                await _upsertSevkiyatKaydiFromKalite(
                  kontrol: kontrol,
                  model: model,
                  kontrolAdet: kontrolAdet,
                  bedenDetaylari: bedenDetaylari,
                  oncekiAsama: oncekiAsama,
                  hedefAsama: hedefAsama,
                  idempotencyKey: idempotencyKey,
                );

                await BildirimService().roleGoreBildirimGonder(
                  rol: 'sevkiyat',
                  baslik: '📦 Yeni Sevkiyat Talebi',
                  mesaj:
                      '${model['marka']} ${model['item_no']} - $kontrolAdet adet kalite kontrolden geçti. Sevkiyat bekliyor.',
                  tip: 'sevkiyat_hazir',
                  modelId: kontrol['model_id']?.toString(),
                  asama: 'Kalite Kontrol',
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showSuccessSnackBar(
                    '✅ Kalite kontrolü onaylandı - Sevkiyat bekleme listesine alındı (Hedef: $hedefAsamaDisplay)');
                await _verileriYukle();
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showReddetDialog(Map<String, dynamic> kontrol) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final sebebController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Kalite Kontrolü Reddet'),
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
                    Text('${model['marka']} - ${model['item_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sebebController,
                decoration: const InputDecoration(
                  labelText: 'Red Sebebi *',
                  border: OutlineInputBorder(),
                  hintText: 'Kalite problemini açıklayın...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reddedilen ürünler tekrar işleme alınacaktır.',
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
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
              if (sebebController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Red sebebi zorunludur'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final redSebebi = sebebController.text.trim();
                await _workflowTransitionService.applyTransition(
                  tableName: DbTables.kaliteKontrolAtamalari,
                  recordId: kontrol['id'],
                  firmaId: TenantManager.instance.requireFirmaId,
                  fromStatus: kontrol['durum']?.toString(),
                  toStatus: 'reddedildi',
                  idempotencyKey: 'kalite:${kontrol['id']}:red',
                  extraFields: {
                    'red_sebebi': redSebebi,
                    'updated_at': DateTime.now().toIso8601String(),
                  },
                );

                await _kaliteRedReworkAtamasiOlustur(
                  kontrol: kontrol,
                  model: model,
                  redSebebi: redSebebi,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showErrorSnackBar('❌ Kalite kontrolü reddedildi');
                await _verileriYukle();
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Reddet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetayDialog(Map<String, dynamic> kontrol) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
    final kontrolAdedi = _toInt(kontrol['kontrol_edilecek_adet']) > 0
        ? _toInt(kontrol['kontrol_edilecek_adet'])
        : _toInt(model['adet']);
    final kayitliBeden = _parseBedenDetayi(kontrol['beden_detaylari']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.teal.shade600),
            const SizedBox(width: 12),
            const Text('Kalite Kontrol Detayı'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Model Bilgileri',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDetaySatiri('Marka', model['marka']),
                    _buildDetaySatiri('Item No', model['item_no']),
                    _buildDetaySatiri('Renk', model['renk']),
                    FutureBuilder<int>(
                      future: _getModelToplamAdet(model['id']?.toString()),
                      builder: (context, snapshot) {
                        final modelToplam =
                            snapshot.data ?? _toInt(model['adet']);
                        return _buildDetaySatiri(
                          'Toplam Adet',
                          modelToplam > 0 ? '$modelToplam' : '-',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Kontrol bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kontrol Bilgileri',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDetaySatiri('Önceki Aşama', kontrol['onceki_asama']),
                    _buildDetaySatiri('Durum', kontrol['durum']),
                    _buildDetaySatiri(
                      'Dokumadan Çıkan',
                      kontrolAdedi > 0 ? '$kontrolAdedi adet' : '-',
                    ),
                    if (kayitliBeden.isNotEmpty)
                      _buildDetaySatiri(
                        'Beden Dağılımı',
                        _bedenDagilimiMetni(kayitliBeden),
                      ),
                    if (kontrol['atama_tarihi'] != null)
                      _buildDetaySatiri(
                          'Talep Tarihi',
                          DateFormat('dd.MM.yyyy HH:mm')
                              .format(DateTime.parse(kontrol['atama_tarihi']))),
                  ],
                ),
              ),
              if (kayitliBeden.isEmpty) ...[
                const SizedBox(height: 12),
                FutureBuilder<Map<String, int>>(
                  future: _kontrolBedenDagilimiGetir(
                    kontrol: kontrol,
                    model: model,
                    kontrolAdedi: kontrolAdedi,
                  ),
                  builder: (context, snapshot) {
                    final bedenler = snapshot.data ?? const <String, int>{};
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 38,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (bedenler.isEmpty) return const SizedBox.shrink();
                    return _buildBedenDagilimiKutusu(
                      bedenler,
                      color: Colors.teal,
                    );
                  },
                ),
              ],
              if (kontrol['notlar'] != null &&
                  _temizNotMetni(kontrol['notlar']?.toString()).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notlar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_temizNotMetni(kontrol['notlar']?.toString())),
                    ],
                  ),
                ),
              ],
              if (kontrol['red_sebebi'] != null &&
                  kontrol['red_sebebi'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Red Sebebi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700)),
                      const SizedBox(height: 4),
                      Text(kontrol['red_sebebi'],
                          style: TextStyle(color: Colors.red.shade700)),
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

  Widget _buildDetaySatiri(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
              child: Text(value ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showAramaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ara'),
        content: TextField(
          controller: _aramaController,
          decoration: const InputDecoration(
            hintText: 'Marka, model veya renk...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() => aramaMetni = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                aramaMetni = '';
                _aramaController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showFiltreDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtrele'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Önceki Aşama:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: seciliAsama == null,
                      onSelected: (selected) {
                        setDialogState(() => seciliAsama = null);
                        setState(() {});
                      },
                    ),
                    ...asamalar.map((asama) => ChoiceChip(
                          label: Text(asama),
                          selected: seciliAsama == asama,
                          selectedColor:
                              _getAsamaRengi(asama).withValues(alpha: 0.3),
                          onSelected: (selected) {
                            setDialogState(
                                () => seciliAsama = selected ? asama : null);
                            setState(() {});
                          },
                        )),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => seciliAsama = null);
                  Navigator.pop(context);
                },
                child: const Text('Temizle'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      ),
    );
  }
}
