// ignore_for_file: invalid_use_of_protected_member
part of 'uretim_asama_dashboard.dart';

/// Uretim asama rapor ve filtre dialog'lari
extension _RaporFiltreAsamaExt on _UretimAsamaDashboardState {
  void _showRaporDialog() {
    String? filtreliMarka;
    String? filtreliModel;
    String filtreliDurum = 'tum';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          var filtreliAtamalar = _tumRaporAtamalari();

          if (filtreliMarka != null && filtreliMarka!.isNotEmpty) {
            filtreliAtamalar = filtreliAtamalar.where((atama) {
              final model = _raporModel(atama);
              return model != null && model['marka'] == filtreliMarka;
            }).toList();
          }

          if (filtreliModel != null && filtreliModel!.isNotEmpty) {
            final aranan = filtreliModel!.toLowerCase();
            filtreliAtamalar = filtreliAtamalar.where((atama) {
              final model = _raporModel(atama);
              if (model == null) return false;
              final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
              final renk = (model['renk'] ?? '').toString().toLowerCase();
              return itemNo.contains(aranan) || renk.contains(aranan);
            }).toList();
          }

          if (filtreliDurum != 'tum') {
            filtreliAtamalar = filtreliAtamalar
                .where((atama) =>
                    _raporDurumGrubu(atama['durum']) == filtreliDurum)
                .toList();
          }

          final metrik = _erpRaporMetrikleri(filtreliAtamalar);
          final durumDagilimi = _durumDagilimi(filtreliAtamalar);
          final markaDagilimi = _markaDagilimi(filtreliAtamalar);
          final riskliIsler = _terminRiskliIsler(filtreliAtamalar);

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            title: Row(
              children: [
                Icon(Icons.analytics_outlined, color: widget.asamaRengi),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.asamaDisplayName} ERP Raporu',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 860,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRaporFiltreleri(
                      filtreliMarka: filtreliMarka,
                      filtreliDurum: filtreliDurum,
                      onMarkaChanged: (value) =>
                          setDialogState(() => filtreliMarka = value),
                      onDurumChanged: (value) =>
                          setDialogState(() => filtreliDurum = value ?? 'tum'),
                      onModelChanged: (value) => setDialogState(
                        () =>
                            filtreliModel = value.trim().isEmpty ? null : value,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final dar = constraints.maxWidth < 700;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildKpiKutusu(
                              'İş Emri',
                              '${metrik.toplamIs}',
                              Icons.assignment_outlined,
                              const Color(0xFF0F766E),
                              dar,
                            ),
                            _buildKpiKutusu(
                              'Talep',
                              '${metrik.talepAdet}',
                              Icons.format_list_numbered,
                              const Color(0xFF2563EB),
                              dar,
                            ),
                            _buildKpiKutusu(
                              'Kabul',
                              '${metrik.kabulAdet}',
                              Icons.verified_outlined,
                              const Color(0xFF059669),
                              dar,
                            ),
                            _buildKpiKutusu(
                              'Tamamlanan',
                              '${metrik.tamamlananAdet}',
                              Icons.task_alt,
                              const Color(0xFF16A34A),
                              dar,
                            ),
                            _buildKpiKutusu(
                              'WIP',
                              '${metrik.wipAdet}',
                              Icons.sync,
                              const Color(0xFFD97706),
                              dar,
                            ),
                            _buildKpiKutusu(
                              'Fire',
                              '${metrik.fireAdet}',
                              Icons.warning_amber_rounded,
                              const Color(0xFFDC2626),
                              dar,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRaporPanel(
                            baslik: 'Performans',
                            icon: Icons.speed,
                            color: const Color(0xFF2563EB),
                            children: [
                              _buildRaporSatiri(
                                'Tamamlanma',
                                '%${metrik.tamamlanmaOrani.toStringAsFixed(1)}',
                              ),
                              _buildRaporSatiri(
                                'Verimlilik',
                                '%${metrik.verimlilikOrani.toStringAsFixed(1)}',
                              ),
                              _buildRaporSatiri(
                                'Fire Oranı',
                                '%${metrik.fireOrani.toStringAsFixed(1)}',
                              ),
                              _buildRaporSatiri(
                                'Ort. Çevrim',
                                metrik.ortalamaCevrimGun > 0
                                    ? '${metrik.ortalamaCevrimGun.toStringAsFixed(1)} gün'
                                    : '-',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRaporPanel(
                            baslik: 'Termin ve Risk',
                            icon: Icons.event_available,
                            color: const Color(0xFFD97706),
                            children: [
                              _buildRaporSatiri(
                                  'Geciken İş', '${metrik.gecikenIs}'),
                              _buildRaporSatiri(
                                '7 Gün İçinde Termin',
                                '${metrik.yaklasanTerminIs}',
                              ),
                              _buildRaporSatiri(
                                'Kalan Adet',
                                '${metrik.kalanAdet}',
                              ),
                              _buildRaporSatiri(
                                'Sevk / Devir Bekleyen',
                                '${metrik.devirBekleyenAdet}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRaporPanel(
                            baslik: 'Durum Dağılımı',
                            icon: Icons.bar_chart,
                            color: const Color(0xFF7C3AED),
                            children: durumDagilimi.entries
                                .map((entry) => _buildRaporSatiri(
                                    entry.key, entry.value.toString()))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRaporPanel(
                            baslik: 'Marka Dağılımı',
                            icon: Icons.sell_outlined,
                            color: const Color(0xFF059669),
                            children: markaDagilimi.isEmpty
                                ? [_buildRaporSatiri('Kayıt', '-')]
                                : markaDagilimi.entries
                                    .take(8)
                                    .map(
                                      (entry) => _buildRaporSatiri(
                                        entry.key,
                                        '${entry.value.model} iş / ${entry.value.adet} adet',
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                    if (riskliIsler.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildRaporPanel(
                        baslik: 'Termin Riski Olan İşler',
                        icon: Icons.priority_high,
                        color: const Color(0xFFDC2626),
                        children: riskliIsler
                            .take(6)
                            .map((item) => _buildRiskSatiri(item))
                            .toList(),
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
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _tumRaporAtamalari() => [
        ...bekleyenModeller,
        ...onaylanmisModeller,
        ...uretimdeOlanModeller,
        ...tamamlananModeller,
      ];

  Map<String, dynamic>? _raporModel(Map<String, dynamic> atama) =>
      atama[DbTables.trikoTakip] as Map<String, dynamic>?;

  int _raporInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _raporTarih(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  int _talepAdedi(Map<String, dynamic> atama) {
    final model = _raporModel(atama);
    return _raporInt(
      atama['talep_edilen_adet'] ??
          atama['adet'] ??
          model?['toplam_adet'] ??
          model?['adet'],
    );
  }

  int _kabulAdedi(Map<String, dynamic> atama) {
    final kabul = _raporInt(atama['kabul_edilen_adet']);
    if (kabul > 0) return kabul;
    final durum = _raporDurumGrubu(atama['durum']);
    if (durum == 'bekleyen') return 0;
    return _talepAdedi(atama);
  }

  String _raporDurumGrubu(dynamic value) {
    final durum = (value ?? '').toString().toLowerCase();
    if (durum.contains('tamam')) return 'tamamlanan';
    if (durum.contains('devam') ||
        durum.contains('uretim') ||
        durum.contains('üretim') ||
        durum.contains('basla') ||
        durum.contains('başla')) {
      return 'islemde';
    }
    if (durum.contains('onay') || durum.contains('kabul')) return 'onaylanan';
    if (durum.contains('red') || durum.contains('iptal')) return 'durdurulan';
    return 'bekleyen';
  }

  _ErpRaporMetrik _erpRaporMetrikleri(List<Map<String, dynamic>> atamalar) {
    final today = DateTime.now();
    final toplamIs = atamalar.length;
    var talepAdet = 0;
    var kabulAdet = 0;
    var tamamlananAdet = 0;
    var fireAdet = 0;
    var gecikenIs = 0;
    var yaklasanTerminIs = 0;
    var devirBekleyenAdet = 0;
    var cevrimToplamGun = 0.0;
    var cevrimKayit = 0;

    for (final atama in atamalar) {
      final model = _raporModel(atama);
      final talep = _talepAdedi(atama);
      final kabul = _kabulAdedi(atama);
      final tamam = _raporInt(atama['tamamlanan_adet']);
      final fire = _raporInt(atama['fire_adet']);
      final durum = _raporDurumGrubu(atama['durum']);

      talepAdet += talep;
      kabulAdet += kabul;
      tamamlananAdet += tamam;
      fireAdet += fire;
      if (durum == 'tamamlanan' && tamam > 0) {
        devirBekleyenAdet += tamam;
      }

      final termin = _raporTarih(model?['termin_tarihi']);
      if (termin != null && durum != 'tamamlanan') {
        final kalanGun = termin
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;
        if (kalanGun < 0) {
          gecikenIs++;
        } else if (kalanGun <= 7) {
          yaklasanTerminIs++;
        }
      }

      final baslangic = _raporTarih(
        atama['uretim_baslangic_tarihi'] ??
            atama['baslama_tarihi'] ??
            atama['onay_tarihi'] ??
            atama['atama_tarihi'] ??
            atama['created_at'],
      );
      final bitis = _raporTarih(
        atama['tamamlama_tarihi'] ??
            atama['teslim_tarihi'] ??
            atama['updated_at'],
      );
      if (baslangic != null && bitis != null && !bitis.isBefore(baslangic)) {
        cevrimToplamGun += bitis.difference(baslangic).inHours / 24;
        cevrimKayit++;
      }
    }

    final kalanAdet =
        (kabulAdet > 0 ? kabulAdet : talepAdet) - tamamlananAdet - fireAdet;
    final uretilebilir = tamamlananAdet + fireAdet;
    return _ErpRaporMetrik(
      toplamIs: toplamIs,
      talepAdet: talepAdet,
      kabulAdet: kabulAdet,
      tamamlananAdet: tamamlananAdet,
      fireAdet: fireAdet,
      kalanAdet: kalanAdet.clamp(0, 1 << 31).toInt(),
      wipAdet:
          (kabulAdet - tamamlananAdet - fireAdet).clamp(0, 1 << 31).toInt(),
      devirBekleyenAdet: devirBekleyenAdet,
      gecikenIs: gecikenIs,
      yaklasanTerminIs: yaklasanTerminIs,
      tamamlanmaOrani: talepAdet > 0 ? (tamamlananAdet / talepAdet) * 100 : 0,
      verimlilikOrani:
          uretilebilir > 0 ? (tamamlananAdet / uretilebilir) * 100 : 100,
      fireOrani: uretilebilir > 0 ? (fireAdet / uretilebilir) * 100 : 0,
      ortalamaCevrimGun: cevrimKayit > 0 ? cevrimToplamGun / cevrimKayit : 0,
    );
  }

  Map<String, int> _durumDagilimi(List<Map<String, dynamic>> atamalar) {
    final map = <String, int>{
      'Bekleyen': 0,
      'Onaylanan': 0,
      'İşlemde': 0,
      'Tamamlanan': 0,
      'Durdurulan': 0,
    };
    for (final atama in atamalar) {
      switch (_raporDurumGrubu(atama['durum'])) {
        case 'onaylanan':
          map['Onaylanan'] = map['Onaylanan']! + 1;
          break;
        case 'islemde':
          map['İşlemde'] = map['İşlemde']! + 1;
          break;
        case 'tamamlanan':
          map['Tamamlanan'] = map['Tamamlanan']! + 1;
          break;
        case 'durdurulan':
          map['Durdurulan'] = map['Durdurulan']! + 1;
          break;
        default:
          map['Bekleyen'] = map['Bekleyen']! + 1;
      }
    }
    return map;
  }

  Map<String, _MarkaRapor> _markaDagilimi(List<Map<String, dynamic>> atamalar) {
    final map = <String, _MarkaRapor>{};
    for (final atama in atamalar) {
      final model = _raporModel(atama);
      final marka = (model?['marka'] ?? 'Bilinmeyen').toString();
      final onceki = map[marka] ?? const _MarkaRapor(model: 0, adet: 0);
      map[marka] = _MarkaRapor(
        model: onceki.model + 1,
        adet: onceki.adet + _talepAdedi(atama),
      );
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.adet.compareTo(a.value.adet));
    return Map.fromEntries(entries);
  }

  List<Map<String, dynamic>> _terminRiskliIsler(
      List<Map<String, dynamic>> atamalar) {
    final today = DateTime.now();
    final riskler = <Map<String, dynamic>>[];
    for (final atama in atamalar) {
      if (_raporDurumGrubu(atama['durum']) == 'tamamlanan') continue;
      final model = _raporModel(atama);
      final termin = _raporTarih(model?['termin_tarihi']);
      if (termin == null) continue;
      final kalanGun = termin
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      if (kalanGun <= 7) {
        riskler.add({
          'marka': model?['marka'] ?? '-',
          'item_no': model?['item_no'] ?? '-',
          'renk': model?['renk'] ?? '-',
          'kalan_gun': kalanGun,
          'adet': _talepAdedi(atama),
        });
      }
    }
    riskler.sort(
        (a, b) => (a['kalan_gun'] as int).compareTo(b['kalan_gun'] as int));
    return riskler;
  }

  Widget _buildRaporFiltreleri({
    required String? filtreliMarka,
    required String filtreliDurum,
    required ValueChanged<String?> onMarkaChanged,
    required ValueChanged<String?> onDurumChanged,
    required ValueChanged<String> onModelChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Marka',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: filtreliMarka,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tümü')),
                ...markalar
                    .map((m) => DropdownMenuItem(value: m, child: Text(m))),
              ],
              onChanged: onMarkaChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Durum',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: filtreliDurum,
              items: const [
                DropdownMenuItem(value: 'tum', child: Text('Tümü')),
                DropdownMenuItem(value: 'bekleyen', child: Text('Bekleyen')),
                DropdownMenuItem(value: 'onaylanan', child: Text('Onaylanan')),
                DropdownMenuItem(value: 'islemde', child: Text('İşlemde')),
                DropdownMenuItem(
                    value: 'tamamlanan', child: Text('Tamamlanan')),
                DropdownMenuItem(
                    value: 'durdurulan', child: Text('Durdurulan')),
              ],
              onChanged: onDurumChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Model / Renk Ara',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onModelChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiKutusu(
    String label,
    String value,
    IconData icon,
    Color color,
    bool fullWidth,
  ) {
    return SizedBox(
      width: fullWidth ? double.infinity : 130,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildRaporPanel({
    required String baslik,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(baslik, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRaporSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(baslik,
                  style: const TextStyle(color: Color(0xFF475569)))),
          Text(deger, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildRiskSatiri(Map<String, dynamic> item) {
    final kalanGun = item['kalan_gun'] as int;
    final etiket =
        kalanGun < 0 ? '${kalanGun.abs()} gün gecikti' : '$kalanGun gün kaldı';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item['marka']} - ${item['item_no']} (${item['renk']})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('${item['adet']} adet'),
          const SizedBox(width: 12),
          Text(
            etiket,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: kalanGun < 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_alt, color: widget.asamaRengi),
              const SizedBox(width: 8),
              const Text('Filtrele'),
            ],
          ),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: seciliMarka,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    ...markalar
                        .map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => seciliMarka = value),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Başlangıç Tarihi'),
                  subtitle: Text(baslangicTarihi != null
                      ? DateFormat('dd.MM.yyyy').format(baslangicTarihi!)
                      : 'Seçilmedi'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: baslangicTarihi ??
                            DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => baslangicTarihi = date);
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Bitiş Tarihi'),
                  subtitle: Text(bitisTarihi != null
                      ? DateFormat('dd.MM.yyyy').format(bitisTarihi!)
                      : 'Seçilmedi'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: bitisTarihi ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => bitisTarihi = date);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  seciliMarka = null;
                  baslangicTarihi = null;
                  bitisTarihi = null;
                });
              },
              child: const Text('Temizle'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErpRaporMetrik {
  final int toplamIs;
  final int talepAdet;
  final int kabulAdet;
  final int tamamlananAdet;
  final int fireAdet;
  final int kalanAdet;
  final int wipAdet;
  final int devirBekleyenAdet;
  final int gecikenIs;
  final int yaklasanTerminIs;
  final double tamamlanmaOrani;
  final double verimlilikOrani;
  final double fireOrani;
  final double ortalamaCevrimGun;

  const _ErpRaporMetrik({
    required this.toplamIs,
    required this.talepAdet,
    required this.kabulAdet,
    required this.tamamlananAdet,
    required this.fireAdet,
    required this.kalanAdet,
    required this.wipAdet,
    required this.devirBekleyenAdet,
    required this.gecikenIs,
    required this.yaklasanTerminIs,
    required this.tamamlanmaOrani,
    required this.verimlilikOrani,
    required this.fireOrani,
    required this.ortalamaCevrimGun,
  });
}

class _MarkaRapor {
  final int model;
  final int adet;

  const _MarkaRapor({required this.model, required this.adet});
}
