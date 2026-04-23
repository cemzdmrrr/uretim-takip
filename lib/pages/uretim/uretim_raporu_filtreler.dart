// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

/// Uretim raporu filtre widget'lari
extension _FiltrelerExt on _UretimRaporuPageState {
  Widget _buildFiltreler() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 620;

        return Padding(
          padding: EdgeInsets.fromLTRB(
              isMobile ? 10 : 16, 14, isMobile ? 10 : 16, 8),
          child: Column(
            children: [
              _buildPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Filtreler',
                      Icons.tune_rounded,
                      const Color(0xFF1565C0),
                      trailing: '${_modeller.length} kayıt',
                    ),
                    const SizedBox(height: 14),
                    if (isMobile)
                      Column(
                        children: [
                          _buildAramaAlani(),
                          const SizedBox(height: 10),
                          _buildMarkaDropdown(),
                          const SizedBox(height: 10),
                          _buildDurumDropdown(),
                          const SizedBox(height: 10),
                          _buildTarihButonu(expanded: true),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(flex: 2, child: _buildAramaAlani()),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMarkaDropdown()),
                          const SizedBox(width: 10),
                          Expanded(child: _buildDurumDropdown()),
                          const SizedBox(width: 10),
                          _buildTarihButonu(),
                        ],
                      ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _asamaListesi.map((asama) {
                          final asamaSayilari =
                              _ozet['asama_sayilari'] as Map<String, int>? ??
                                  {};
                          final sayi = asama['key'] == 'Tümü'
                              ? _modeller.length
                              : (asamaSayilari[asama['key']] ?? 0);
                          final secili = _secilenAsama == asama['key'];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: secili,
                              showCheckmark: false,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    asama['label'] as String,
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: secili
                                          ? Colors.white
                                          : (asama['color'] as Color)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      sayi.toString(),
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 11,
                                        fontWeight: FontWeight.w900,
                                        color: secili
                                            ? asama['color'] as Color
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              selectedColor: (asama['color'] as Color)
                                  .withValues(alpha: 0.18),
                              backgroundColor: const Color(0xFFF8FAFC),
                              side: BorderSide(
                                color: secili
                                    ? asama['color'] as Color
                                    : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (_) {
                                setState(() =>
                                    _secilenAsama = asama['key'] as String);
                                _filtreleriUygula();
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.bookmark_border, size: 18),
                          label: const Text('Kaydet',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () => _filtrePresetKaydetDialog(),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.bookmarks_outlined, size: 18),
                          label: const Text('Presetler',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () => _filtrePresetListeDialog(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAramaAlani() {
    return TextField(
      controller: _aramaController,
      decoration: InputDecoration(
        hintText: 'Model, marka veya renk ara...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _aramaMetni.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  _aramaController.clear();
                  setState(() => _aramaMetni = '');
                  _filtreleriUygula();
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.4),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
      ),
      onChanged: _aramaYap,
    );
  }

  Widget _buildMarkaDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _dropdownDecoration('Marka'),
      initialValue: _secilenMarka,
      isExpanded: true,
      items: _markaListesi
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _secilenMarka = value);
        _filtreleriUygula();
      },
    );
  }

  Widget _buildDurumDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _dropdownDecoration('Durum'),
      initialValue: _secilenDurum,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
        DropdownMenuItem(value: 'Devam Eden', child: Text('Devam Eden')),
        DropdownMenuItem(value: 'Tamamlanan', child: Text('Tamamlanan')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _secilenDurum = value);
        _filtreleriUygula();
      },
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD8E0EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.4),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
    );
  }

  Widget _buildTarihButonu({bool expanded = false}) {
    final label = _tarihAraligi == null
        ? 'Tarih Seç'
        : '${DateFormat('dd/MM').format(_tarihAraligi!.start)} - ${DateFormat('dd/MM').format(_tarihAraligi!.end)}';

    final button = OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _tarihAraligi,
          locale: const Locale('tr', 'TR'),
        );
        if (picked != null) {
          setState(() => _tarihAraligi = picked);
          _filtreleriUygula();
        }
      },
      icon: const Icon(Icons.date_range_rounded, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFD8E0EA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );

    final row = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (expanded)
          Expanded(child: button)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 142),
            child: button,
          ),
        if (_tarihAraligi != null)
          IconButton(
            tooltip: 'Tarih filtresini temizle',
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              setState(() => _tarihAraligi = null);
              _filtreleriUygula();
            },
          ),
      ],
    );

    return expanded ? SizedBox(width: double.infinity, child: row) : row;
  }

  void _filtrePresetKaydetDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtre Preseti Kaydet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Preset adı girin...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final ad = controller.text.trim();
              if (ad.isNotEmpty) {
                _filtrePresetKaydet(ad);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$ad" preseti kaydedildi')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _filtrePresetListeDialog() async {
    final presets = await _filtrePresetleriYukle();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtre Presetleri'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: presets.isEmpty
              ? const Center(child: Text('Henüz kaydedilmiş preset yok'))
              : ListView.separated(
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final preset = presets[index];
                    return ListTile(
                      title: Text(preset['ad']?.toString() ?? 'Preset'),
                      subtitle: Text(
                        [
                          if (preset['marka'] != 'Tümü')
                            'Marka: ${preset['marka']}',
                          if (preset['durum'] != 'Tümü')
                            'Durum: ${preset['durum']}',
                          if (preset['asama'] != 'Tümü')
                            'Aşama: ${preset['asama']}',
                          if ((preset['arama'] ?? '').toString().isNotEmpty)
                            'Arama: ${preset['arama']}',
                        ].join(' • '),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () {
                          _filtrePresetSil(index);
                          Navigator.pop(ctx);
                          _filtrePresetListeDialog(); // Yeniden aç
                        },
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _filtrePresetUygula(preset);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
