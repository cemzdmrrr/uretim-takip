// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_raporu_page.dart';

/// Uretim raporu filtre widget'lari
extension _FiltrelerExt on _UretimRaporuPageState {
  Widget _buildFiltreler() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              // Arama kutusu
              TextField(
                controller: _aramaController,
                decoration: InputDecoration(
                  hintText: 'Model, marka veya renk ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _aramaMetni.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _aramaController.clear();
                            setState(() => _aramaMetni = '');
                            _filtreleriUygula();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _aramaYap,
              ),
              const SizedBox(height: 12),
              // Filtreler - responsive layout
              if (isMobile) ...[
                // Mobil: Dikey düzen
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  initialValue: _secilenMarka,
                  items: _markaListesi.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (value) {
                    setState(() => _secilenMarka = value!);
                    _filtreleriUygula();
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  initialValue: _secilenDurum,
                  items: const [
                    DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                    DropdownMenuItem(value: 'Devam Eden', child: Text('Devam Eden')),
                    DropdownMenuItem(value: 'Tamamlanan', child: Text('Tamamlanan')),
                  ],
                  onChanged: (value) {
                    setState(() => _secilenDurum = value!);
                    _filtreleriUygula();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(_tarihAraligi == null
                            ? 'Tarih Seç'
                            : '${DateFormat('dd/MM').format(_tarihAraligi!.start)} - ${DateFormat('dd/MM').format(_tarihAraligi!.end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_tarihAraligi != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() => _tarihAraligi = null);
                          _filtreleriUygula();
                        },
                      ),
                  ],
                ),
              ] else ...[
                // Tablet/Desktop: Yatay düzen
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Marka',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: _secilenMarka,
                        items: _markaListesi.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (value) {
                          setState(() => _secilenMarka = value!);
                          _filtreleriUygula();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: _secilenDurum,
                        items: const [
                          DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                          DropdownMenuItem(value: 'Devam Eden', child: Text('Devam Eden')),
                          DropdownMenuItem(value: 'Tamamlanan', child: Text('Tamamlanan')),
                        ],
                        onChanged: (value) {
                          setState(() => _secilenDurum = value!);
                          _filtreleriUygula();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
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
                      icon: const Icon(Icons.date_range),
                      label: Text(_tarihAraligi == null
                          ? 'Tarih Seç'
                          : '${DateFormat('dd/MM').format(_tarihAraligi!.start)} - ${DateFormat('dd/MM').format(_tarihAraligi!.end)}'),
                    ),
                    if (_tarihAraligi != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _tarihAraligi = null);
                          _filtreleriUygula();
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Aşama filtreleri - chip butonları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _asamaListesi.map((asama) {
                    final asamaSayilari = _ozet['asama_sayilari'] as Map<String, int>? ?? {};
                    final sayi = asama['key'] == 'Tümü' 
                        ? _modeller.length 
                        : (asamaSayilari[asama['key']] ?? 0);
                    final secili = _secilenAsama == asama['key'];
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: secili,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(asama['label'] as String, style: TextStyle(fontSize: isMobile ? 11 : 13)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: secili ? Colors.white : (asama['color'] as Color).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                sayi.toString(),
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: secili ? asama['color'] as Color : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selectedColor: (asama['color'] as Color).withValues(alpha: 0.3),
                        checkmarkColor: asama['color'] as Color,
                        onSelected: (selected) {
                          setState(() => _secilenAsama = asama['key'] as String);
                          _filtreleriUygula();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              // Filtre preset aksiyonları
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.bookmark_border, size: 18),
                    label: const Text('Kaydet', style: TextStyle(fontSize: 12)),
                    onPressed: () => _filtrePresetKaydetDialog(),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.bookmarks_outlined, size: 18),
                    label: const Text('Presetler', style: TextStyle(fontSize: 12)),
                    onPressed: () => _filtrePresetListeDialog(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
                          if (preset['marka'] != 'Tümü') 'Marka: ${preset['marka']}',
                          if (preset['durum'] != 'Tümü') 'Durum: ${preset['durum']}',
                          if (preset['asama'] != 'Tümü') 'Aşama: ${preset['asama']}',
                          if ((preset['arama'] ?? '').toString().isNotEmpty) 'Arama: ${preset['arama']}',
                        ].join(' • '),
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
