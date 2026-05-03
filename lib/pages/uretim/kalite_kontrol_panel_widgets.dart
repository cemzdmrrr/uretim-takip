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
                            'Ãœretimden gelen iÅŸler kontrol ediliyor',
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

  Widget _buildAktifFiltreSeridi() {
    final filtreler = [
      if (aramaMetni.isNotEmpty) '"$aramaMetni"',
      if (seciliAsama != null) 'AÅŸama: $seciliAsama',
    ].join('  â€¢  ');

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
                kontrol['notlar'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildNotKutusu(kontrol['notlar'].toString()),
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
        metin = 'OnaylandÄ±';
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

        // Bekleyenler iÃ§in aksiyonlar
        if (tip == 'bekleyen') ...[
          ElevatedButton.icon(
            onPressed: () => _kontrolBaslat(kontrol),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Kontrole BaÅŸla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],

        // Kontrol edilenler iÃ§in aksiyonlar
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
      case 'YÄ±kama':
        return Colors.cyan;
      case 'ÃœtÃ¼':
        return Colors.orange;
      case 'Ä°lik DÃ¼ÄŸme':
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
      case 'YÄ±kama':
        return Icons.local_laundry_service;
      case 'ÃœtÃ¼':
        return Icons.iron;
      case 'Ä°lik DÃ¼ÄŸme':
        return Icons.radio_button_checked;
      case 'Paketleme':
        return Icons.inventory_2;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _kontrolBaslat(Map<String, dynamic> kontrol) async {
    try {
      await supabase.from(DbTables.kaliteKontrolAtamalari).update({
        'durum': 'baslandi',
        'baslangic_tarihi': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', kontrol['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('âœ… Kalite kontrolÃ¼ baÅŸlatÄ±ldÄ±'),
          backgroundColor: Colors.blue,
        ),
      );

      await _verileriYukle();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  void _showOnaylaDialog(Map<String, dynamic> kontrol) {
    final model = kontrol[DbTables.trikoTakip] as Map<String, dynamic>;
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
            const Text('Kalite KontrolÃ¼ Onayla'),
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
                    Text('Ã–nceki AÅŸama: ${kontrol['onceki_asama']}'),
                    Text(
                        'Kontrol Edilen: ${kontrol['kontrol_edilecek_adet'] ?? model['adet']} adet'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(
                  labelText: 'Kalite Kontrol NotlarÄ± (Ä°steÄŸe BaÄŸlÄ±)',
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
                        'Onay sonrasÄ± Ã¼rÃ¼nler bir sonraki aÅŸamaya geÃ§ebilir.',
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
            child: const Text('Ä°ptal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Kalite kontrolÃ¼nÃ¼ tamamla
                await supabase.from(DbTables.kaliteKontrolAtamalari).update({
                  'durum': 'tamamlandi',
                  'tamamlanma_tarihi': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                  'notlar': notlarController.text.isNotEmpty
                      ? notlarController.text
                      : null,
                }).eq('id', kontrol['id']);

                // Sevkiyat kaydÄ± oluÅŸtur
                final kontrolAdet =
                    kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? 0;
                debugPrint(
                    'ğŸ“¦ Kalite kontrol onaylandÄ± - $kontrolAdet adet sevkiyata gÃ¶nderilecek');

                // 1. paketleme_atamalari tablosuna YENÄ° KAYIT ekle (her zaman insert)
                try {
                  await supabase.from(DbTables.paketlemeAtamalari).insert({
                    'model_id': kontrol['model_id'],
                    'durum': 'atandi',
                    'adet': kontrolAdet,
                    'talep_edilen_adet': kontrolAdet,
                    'tamamlanan_adet': 0,
                    'atama_tarihi': DateTime.now().toIso8601String(),
                    'notlar':
                        'Kalite kontrol onaylandÄ± - ${model['marka']} ${model['item_no']} - $kontrolAdet adet sevkiyata hazÄ±r',
                    'firma_id': TenantManager.instance.requireFirmaId,
                  });
                  debugPrint(
                      'âœ… Paketleme atamasÄ± oluÅŸturuldu (yeni kayÄ±t)');
                } catch (e) {
                  debugPrint('âŒ Paketleme atamasÄ± hatasÄ±: $e');
                }

                // 2. sevkiyat_kayitlari tablosuna YENÄ° KAYIT ekle (her zaman insert)
                try {
                  await supabase.from(DbTables.sevkiyatKayitlari).insert({
                    'model_id': kontrol['model_id'],
                    'kalite_kontrol_id': kontrol['id'],
                    'alinan_adet': kontrolAdet,
                    'sevk_edilen_adet': 0,
                    'kalan_adet': kontrolAdet,
                    'durum': 'beklemede',
                    'alis_tarihi': DateTime.now().toIso8601String(),
                    'notlar':
                        'Kalite kontrol onaylandÄ± - ${model['marka']} ${model['item_no']}',
                    'firma_id': TenantManager.instance.requireFirmaId,
                  });
                  debugPrint('âœ… Sevkiyat kaydÄ± oluÅŸturuldu (yeni kayÄ±t)');
                } catch (e) {
                  debugPrint(
                      'âš ï¸ sevkiyat_kayitlari tablosu henÃ¼z oluÅŸturulmamÄ±ÅŸ olabilir: $e');
                }

                // 3. Sevkiyat rolÃ¼ne sahip kullanÄ±cÄ±lara bildirim gÃ¶nder
                try {
                  await BildirimService().roleGoreBildirimGonder(
                    rol: 'sevkiyat',
                    baslik: 'ğŸ“¦ Yeni Sevkiyat Talebi',
                    mesaj:
                        '${model['marka']} ${model['item_no']} - $kontrolAdet adet kalite kontrolden geÃ§ti. Sevkiyat bekliyor.',
                    tip: 'sevkiyat_hazir',
                    modelId: kontrol['model_id']?.toString(),
                    asama: 'Kalite Kontrol',
                  );
                  debugPrint('âœ… Sevkiyat bildirimi gÃ¶nderildi');
                } catch (e) {
                  debugPrint('âš ï¸ Bildirim gÃ¶nderilemedi: $e');
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showSuccessSnackBar(
                    'âœ… Kalite kontrolÃ¼ onaylandÄ± - Sevkiyata gÃ¶nderildi');
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
            const Text('Kalite KontrolÃ¼ Reddet'),
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
                    Text('Ã–nceki AÅŸama: ${kontrol['onceki_asama']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sebebController,
                decoration: const InputDecoration(
                  labelText: 'Red Sebebi *',
                  border: OutlineInputBorder(),
                  hintText: 'Kalite problemini aÃ§Ä±klayÄ±n...',
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
                        'Red edilen Ã¼rÃ¼nler tekrar iÅŸleme alÄ±nacaktÄ±r.',
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
            child: const Text('Ä°ptal'),
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
                await supabase.from(DbTables.kaliteKontrolAtamalari).update({
                  'durum': 'reddedildi',
                  'red_sebebi': sebebController.text.trim(),
                }).eq('id', kontrol['id']);

                if (!context.mounted) return;
                Navigator.pop(context);
                context.showErrorSnackBar('âŒ Kalite kontrolÃ¼ reddedildi');
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.teal.shade600),
            const SizedBox(width: 12),
            const Text('Kalite Kontrol DetayÄ±'),
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
                    _buildDetaySatiri('Toplam Adet', model['adet']?.toString()),
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
                    _buildDetaySatiri(
                        'Ã–nceki AÅŸama', kontrol['onceki_asama']),
                    _buildDetaySatiri('Durum', kontrol['durum']),
                    _buildDetaySatiri('Kontrol Edilecek',
                        '${kontrol['kontrol_edilecek_adet'] ?? model['adet'] ?? '-'} adet'),
                    if (kontrol['atama_tarihi'] != null)
                      _buildDetaySatiri(
                          'Talep Tarihi',
                          DateFormat('dd.MM.yyyy HH:mm')
                              .format(DateTime.parse(kontrol['atama_tarihi']))),
                  ],
                ),
              ),
              if (kontrol['notlar'] != null &&
                  kontrol['notlar'].toString().isNotEmpty) ...[
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
                      Text(kontrol['notlar']),
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
                const Text('Ã–nceki AÅŸama:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('TÃ¼mÃ¼'),
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
