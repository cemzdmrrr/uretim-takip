import 'package:flutter/material.dart';
import 'package:uretim_takip/services/yapilacak_service.dart';

class YapilacaklarPopup extends StatefulWidget {
  const YapilacaklarPopup({super.key});

  static Future<void> openPanel(BuildContext context) {
    return _showYapilacaklarPanel(context);
  }

  @override
  State<YapilacaklarPopup> createState() => _YapilacaklarPopupState();
}

class _YapilacaklarPopupState extends State<YapilacaklarPopup> {
  final _service = YapilacakService();
  int _bekleyenSayisi = 0;

  @override
  void initState() {
    super.initState();
    _sayiyiYukle();
  }

  Future<void> _sayiyiYukle() async {
    try {
      final sayi = await _service.tamamlanmamisSayisi();
      if (!mounted) return;
      setState(() => _bekleyenSayisi = sayi);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bekleyenSayisi = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: IconButton(
        tooltip: 'Yapılacaklar',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.add_task,
              color: Colors.white,
              size: 24,
            ),
            if (_bekleyenSayisi > 0)
              Positioned(
                right: -9,
                top: -9,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    _bekleyenSayisi > 99 ? '99+' : _bekleyenSayisi.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () async {
          await YapilacaklarPopup.openPanel(context);
          await _sayiyiYukle();
        },
      ),
    );
  }
}

Future<void> _showYapilacaklarPanel(BuildContext context) async {
  final service = YapilacakService();
  final baslikController = TextEditingController();
  final aciklamaController = TextEditingController();
  String kapsam = 'kisisel';
  String periyot = 'gunluk';
  String oncelik = 'normal';
  DateTime? hatirlaticiTarihi;
  bool loading = true;
  bool saving = false;
  String kapsamFiltre = 'tumu';
  List<Map<String, dynamic>> items = [];

  Future<void> yukle(StateSetter setDialogState) async {
    setDialogState(() => loading = true);
    try {
      items = await service.getGecerliYapilacaklar(kapsam: kapsamFiltre);
    } catch (e) {
      items = [];
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Yapılacaklar tablosu hazır değil. Lütfen Supabase migration dosyasını çalıştırın.',
            ),
          ),
        );
      }
    } finally {
      setDialogState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> filtrele(String tab) {
    if (tab == 'tumu') return items;
    return items.where((item) => item['periyot'] == tab).toList();
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          if (loading && items.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) yukle(setDialogState);
            });
          }

          Future<void> kaydet() async {
            final baslik = baslikController.text.trim();
            if (baslik.isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Başlık girin')),
              );
              return;
            }

            setDialogState(() => saving = true);
            try {
              await service.yapilacakEkle(
                baslik: baslik,
                aciklama: aciklamaController.text,
                kapsam: kapsam,
                periyot: periyot,
                oncelik: oncelik,
                hatirlaticiTarihi: hatirlaticiTarihi,
              );
              baslikController.clear();
              aciklamaController.clear();
              hatirlaticiTarihi = null;
              await yukle(setDialogState);
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Yapılacak kaydedilemedi: $e')),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => saving = false);
              }
            }
          }

          final dialogWidth = MediaQuery.of(context).size.width < 720
              ? MediaQuery.of(context).size.width * 0.94
              : 720.0;

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                const Icon(Icons.add_task, color: Color(0xFF1565C0)),
                const SizedBox(width: 10),
                const Expanded(child: Text('Yapılacaklar')),
                IconButton(
                  tooltip: 'Yenile',
                  icon: const Icon(Icons.refresh, color: Color(0xFF1565C0)),
                  onPressed: () => yukle(setDialogState),
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              height: MediaQuery.of(context).size.height * 0.74,
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    _HizliEkleAlani(
                      baslikController: baslikController,
                      aciklamaController: aciklamaController,
                      kapsam: kapsam,
                      periyot: periyot,
                      oncelik: oncelik,
                      hatirlaticiTarihi: hatirlaticiTarihi,
                      saving: saving,
                      onKapsamChanged: (value) =>
                          setDialogState(() => kapsam = value),
                      onPeriyotChanged: (value) =>
                          setDialogState(() => periyot = value),
                      onOncelikChanged: (value) =>
                          setDialogState(() => oncelik = value),
                      onHatirlaticiChanged: (value) =>
                          setDialogState(() => hatirlaticiTarihi = value),
                      onSave: kaydet,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'tumu', label: Text('Tümü')),
                            ButtonSegment(
                                value: 'kisisel', label: Text('Kişisel')),
                            ButtonSegment(value: 'firma', label: Text('Firma')),
                          ],
                          selected: {kapsamFiltre},
                          onSelectionChanged: (value) async {
                            kapsamFiltre = value.first;
                            await yukle(setDialogState);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Bugün'),
                        Tab(text: 'Haftalık'),
                        Tab(text: 'Aylık'),
                        Tab(text: 'Tümü'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              children: [
                                _YapilacakListe(
                                  items: filtrele('gunluk'),
                                  service: service,
                                  onRefresh: () => yukle(setDialogState),
                                ),
                                _YapilacakListe(
                                  items: filtrele('haftalik'),
                                  service: service,
                                  onRefresh: () => yukle(setDialogState),
                                ),
                                _YapilacakListe(
                                  items: filtrele('aylik'),
                                  service: service,
                                  onRefresh: () => yukle(setDialogState),
                                ),
                                _YapilacakListe(
                                  items: filtrele('tumu'),
                                  service: service,
                                  onRefresh: () => yukle(setDialogState),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      );
    },
  );

  baslikController.dispose();
  aciklamaController.dispose();
}

class _HizliEkleAlani extends StatelessWidget {
  const _HizliEkleAlani({
    required this.baslikController,
    required this.aciklamaController,
    required this.kapsam,
    required this.periyot,
    required this.oncelik,
    required this.hatirlaticiTarihi,
    required this.saving,
    required this.onKapsamChanged,
    required this.onPeriyotChanged,
    required this.onOncelikChanged,
    required this.onHatirlaticiChanged,
    required this.onSave,
  });

  final TextEditingController baslikController;
  final TextEditingController aciklamaController;
  final String kapsam;
  final String periyot;
  final String oncelik;
  final DateTime? hatirlaticiTarihi;
  final bool saving;
  final ValueChanged<String> onKapsamChanged;
  final ValueChanged<String> onPeriyotChanged;
  final ValueChanged<String> onOncelikChanged;
  final ValueChanged<DateTime?> onHatirlaticiChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final dar = MediaQuery.of(context).size.width < 700;

    Widget baslikField() => TextField(
          controller: baslikController,
          decoration: const InputDecoration(
            labelText: 'Yeni iş',
            prefixIcon: Icon(Icons.add_task, color: Color(0xFF1565C0)),
          ),
          onSubmitted: (_) => onSave(),
        );

    Widget periyotField() => DropdownButtonFormField<String>(
          initialValue: periyot,
          decoration: const InputDecoration(labelText: 'Periyot'),
          items: const [
            DropdownMenuItem(value: 'gunluk', child: Text('Günlük')),
            DropdownMenuItem(value: 'haftalik', child: Text('Haftalık')),
            DropdownMenuItem(value: 'aylik', child: Text('Aylık')),
            DropdownMenuItem(value: 'tek_seferlik', child: Text('Tek sefer')),
          ],
          onChanged: (value) => onPeriyotChanged(value ?? 'gunluk'),
        );

    Widget kapsamField() => DropdownButtonFormField<String>(
          initialValue: kapsam,
          decoration: const InputDecoration(labelText: 'Kapsam'),
          items: const [
            DropdownMenuItem(value: 'kisisel', child: Text('Kişisel')),
            DropdownMenuItem(value: 'firma', child: Text('Firma')),
          ],
          onChanged: (value) => onKapsamChanged(value ?? 'kisisel'),
        );

    Widget noteField() => TextField(
          controller: aciklamaController,
          decoration: const InputDecoration(
            labelText: 'Not',
            prefixIcon: Icon(Icons.notes, color: Color(0xFF1565C0)),
          ),
        );

    Widget priorityField() => DropdownButtonFormField<String>(
          initialValue: oncelik,
          decoration: const InputDecoration(labelText: 'Öncelik'),
          items: const [
            DropdownMenuItem(value: 'dusuk', child: Text('Düşük')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'yuksek', child: Text('Yüksek')),
          ],
          onChanged: (value) => onOncelikChanged(value ?? 'normal'),
        );

    final firstRow = dar
        ? Column(
            children: [
              baslikField(),
              const SizedBox(height: 8),
              periyotField(),
              const SizedBox(height: 8),
              kapsamField(),
            ],
          )
        : Row(
            children: [
              Expanded(flex: 2, child: baslikField()),
              const SizedBox(width: 8),
              Expanded(child: periyotField()),
              const SizedBox(width: 8),
              Expanded(child: kapsamField()),
            ],
          );

    final secondRow = dar
        ? Column(
            children: [
              noteField(),
              const SizedBox(height: 8),
              priorityField(),
              const SizedBox(height: 8),
              _ReminderAndSaveActions(
                hatirlaticiTarihi: hatirlaticiTarihi,
                saving: saving,
                onHatirlaticiChanged: onHatirlaticiChanged,
                onSave: onSave,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(flex: 2, child: noteField()),
              const SizedBox(width: 8),
              Expanded(child: priorityField()),
              const SizedBox(width: 8),
              _ReminderAndSaveActions(
                hatirlaticiTarihi: hatirlaticiTarihi,
                saving: saving,
                onHatirlaticiChanged: onHatirlaticiChanged,
                onSave: onSave,
              ),
            ],
          );

    return Column(
      children: [
        firstRow,
        const SizedBox(height: 8),
        secondRow,
      ],
    );
  }
}

class _ReminderAndSaveActions extends StatelessWidget {
  const _ReminderAndSaveActions({
    required this.hatirlaticiTarihi,
    required this.saving,
    required this.onHatirlaticiChanged,
    required this.onSave,
  });

  final DateTime? hatirlaticiTarihi;
  final bool saving;
  final ValueChanged<DateTime?> onHatirlaticiChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1565C0),
            side: const BorderSide(color: Color(0xFF1565C0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          icon: Icon(
            hatirlaticiTarihi == null ? Icons.access_time : Icons.alarm,
            color: hatirlaticiTarihi == null
                ? const Color(0xFF1565C0)
                : Colors.orange,
            size: 18,
          ),
          label: Text(
            hatirlaticiTarihi == null
                ? 'Hatırlatıcı ekle'
                : _formatDateTime(hatirlaticiTarihi!),
            overflow: TextOverflow.ellipsis,
          ),
          onPressed: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: hatirlaticiTarihi ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 3),
            );
            if (date == null || !context.mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(hatirlaticiTarihi ?? now),
            );
            if (time == null) return;
            onHatirlaticiChanged(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          },
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
          tooltip: 'Kaydet',
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
        ),
      ],
    );
  }
}

class _YapilacakListe extends StatelessWidget {
  const _YapilacakListe({
    required this.items,
    required this.service,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> items;
  final YapilacakService service;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Kayıt yok'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final tamamlandi = item['gecerli_donem_tamamlandi'] == true;
        final oncelik = item['oncelik']?.toString() ?? 'normal';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Checkbox(
                value: tamamlandi,
                onChanged: (_) async {
                  await service.donemTamamla(item);
                  await onRefresh();
                },
              ),
              title: Text(
                item['baslik']?.toString() ?? '',
                style: TextStyle(
                  decoration: tamamlandi ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: _subtitle(item),
              trailing: Wrap(
                spacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _OncelikChip(oncelik: oncelik),
                  IconButton(
                    tooltip: 'Düzenle',
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFF1565C0),
                    ),
                    onPressed: () async {
                      await _duzenle(context, service, item);
                      await onRefresh();
                    },
                  ),
                  IconButton(
                    tooltip: 'Sil',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await service.yapilacakSil(item['id'].toString());
                      await onRefresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _subtitle(Map<String, dynamic> item) {
    final parcalar = <String>[
      _periyotLabel(item['periyot']?.toString()),
      _kapsamLabel(item['kapsam']?.toString()),
      if ((item['aciklama']?.toString() ?? '').isNotEmpty)
        item['aciklama'].toString(),
      if (item['hatirlatici_tarihi'] != null)
        'Hatırlatıcı: ${_formatDateTime(DateTime.parse(item['hatirlatici_tarihi'].toString()).toLocal())}',
    ].where((e) => e.isNotEmpty).toList();

    return Text(parcalar.join(' - '));
  }

  Future<void> _duzenle(
    BuildContext context,
    YapilacakService service,
    Map<String, dynamic> item,
  ) async {
    final baslikController =
        TextEditingController(text: item['baslik']?.toString() ?? '');
    final aciklamaController =
        TextEditingController(text: item['aciklama']?.toString() ?? '');
    String kapsam = item['kapsam']?.toString() ?? 'kisisel';
    String periyot = item['periyot']?.toString() ?? 'gunluk';
    String oncelik = item['oncelik']?.toString() ?? 'normal';
    DateTime? hatirlatici = item['hatirlatici_tarihi'] == null
        ? null
        : DateTime.tryParse(item['hatirlatici_tarihi'].toString())?.toLocal();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Yapılacağı düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: baslikController,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  TextField(
                    controller: aciklamaController,
                    decoration: const InputDecoration(labelText: 'Not'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: periyot,
                    decoration: const InputDecoration(labelText: 'Periyot'),
                    items: const [
                      DropdownMenuItem(value: 'gunluk', child: Text('Günlük')),
                      DropdownMenuItem(
                          value: 'haftalik', child: Text('Haftalık')),
                      DropdownMenuItem(value: 'aylik', child: Text('Aylık')),
                      DropdownMenuItem(
                          value: 'tek_seferlik', child: Text('Tek sefer')),
                    ],
                    onChanged: (value) =>
                        setState(() => periyot = value ?? 'gunluk'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: kapsam,
                    decoration: const InputDecoration(labelText: 'Kapsam'),
                    items: const [
                      DropdownMenuItem(
                          value: 'kisisel', child: Text('Kişisel')),
                      DropdownMenuItem(value: 'firma', child: Text('Firma')),
                    ],
                    onChanged: (value) =>
                        setState(() => kapsam = value ?? 'kisisel'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: oncelik,
                    decoration: const InputDecoration(labelText: 'Öncelik'),
                    items: const [
                      DropdownMenuItem(value: 'dusuk', child: Text('Düşük')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'yuksek', child: Text('Yüksek')),
                    ],
                    onChanged: (value) =>
                        setState(() => oncelik = value ?? 'normal'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: hatirlatici ?? DateTime.now(),
                    firstDate: DateTime(DateTime.now().year - 1),
                    lastDate: DateTime(DateTime.now().year + 3),
                  );
                  if (date == null || !dialogContext.mounted) return;
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime:
                        TimeOfDay.fromDateTime(hatirlatici ?? DateTime.now()),
                  );
                  if (time == null) return;
                  setState(() {
                    hatirlatici = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                icon: const Icon(Icons.alarm_add, color: Color(0xFF1565C0)),
                label: Text(
                  hatirlatici == null
                      ? 'Hatırlatıcı'
                      : _formatDateTime(hatirlatici!),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await service.yapilacakGuncelle(
                    id: item['id'].toString(),
                    baslik: baslikController.text,
                    aciklama: aciklamaController.text,
                    kapsam: kapsam,
                    periyot: periyot,
                    oncelik: oncelik,
                    hatirlaticiTarihi: hatirlatici,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );

    baslikController.dispose();
    aciklamaController.dispose();
  }
}

class _OncelikChip extends StatelessWidget {
  const _OncelikChip({required this.oncelik});

  final String oncelik;

  @override
  Widget build(BuildContext context) {
    final color = switch (oncelik) {
      'yuksek' => Colors.red,
      'dusuk' => Colors.blueGrey,
      _ => Colors.green,
    };
    return Chip(
      label: Text(_oncelikLabel(oncelik)),
      labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

String _formatDateTime(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _periyotLabel(String? value) {
  return switch (value) {
    'haftalik' => 'Haftalık',
    'aylik' => 'Aylık',
    'tek_seferlik' => 'Tek sefer',
    _ => 'Günlük',
  };
}

String _kapsamLabel(String? value) {
  return switch (value) {
    'firma' => 'Firma',
    'atanan' => 'Atanan',
    _ => 'Kişisel',
  };
}

String _oncelikLabel(String? value) {
  return switch (value) {
    'yuksek' => 'Yüksek',
    'dusuk' => 'Düşük',
    _ => 'Normal',
  };
}
