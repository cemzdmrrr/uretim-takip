part of 'iplik_stoklari.dart';

extension _IplikLokasyonSayimUi on _IplikStoklariPageState {
  bool get _sayimYoneticisi =>
      _kullaniciRolleri.contains('firma_sahibi') ||
      _kullaniciRolleri.contains('firma_admin');

  String _lokasyonEtiketi(dynamic id) {
    for (final item in iplikLokasyonlari) {
      if (item['id']?.toString() == id?.toString()) {
        return '${item['kod']} - ${item['ad']}';
      }
    }
    return '-';
  }

  List<Map<String, dynamic>> _stokLokasyonlari(Map<String, dynamic> stok) =>
      iplikStokLokasyonlari
          .where(
              (item) => item['stok_id']?.toString() == stok['id']?.toString())
          .toList();

  Widget _buildLokasyonSayfasi() {
    final toplamlar = <String, double>{};
    for (final row in iplikStokLokasyonlari) {
      final id = row['lokasyon_id']?.toString() ?? '';
      toplamlar[id] =
          (toplamlar[id] ?? 0) + ((row['miktar'] as num?)?.toDouble() ?? 0);
    }
    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('İplik Lokasyonları',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              if (_sayimYoneticisi)
                FilledButton.icon(
                  onPressed: () => _lokasyonDuzenleDialogu(),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Lokasyon Ekle'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...iplikLokasyonlari.map((lokasyon) {
            final sistem = lokasyon['sistem_lokasyonu'] == true;
            final aktif = lokasyon['aktif'] != false;
            return Card(
              child: ListTile(
                leading: Icon(
                  sistem ? Icons.inventory_2_outlined : Icons.location_on,
                  color: aktif
                      ? _IplikStoklariPageState._primaryColor
                      : Colors.grey,
                ),
                title: Text('${lokasyon['kod']} - ${lokasyon['ad']}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${lokasyon['aciklama'] ?? 'Açıklama yok'} • '
                  '${(toplamlar[lokasyon['id']?.toString()] ?? 0).toStringAsFixed(2)} kg',
                ),
                trailing: sistem || !_sayimYoneticisi
                    ? Chip(label: Text(sistem ? 'Sistem' : 'Salt okunur'))
                    : Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Düzenle',
                            onPressed: () => _lokasyonDuzenleDialogu(lokasyon),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: aktif ? 'Pasife al' : 'Aktifleştir',
                            onPressed: () async {
                              await IplikLokasyonSayimService
                                  .lokasyonAktiflikDegistir(
                                lokasyon['id'].toString(),
                                !aktif,
                              );
                              await _verileriYukle();
                            },
                            icon: Icon(aktif
                                ? Icons.toggle_on
                                : Icons.toggle_off_outlined),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _lokasyonDuzenleDialogu([Map<String, dynamic>? lokasyon]) async {
    final kod = TextEditingController(text: lokasyon?['kod']?.toString() ?? '');
    final ad = TextEditingController(text: lokasyon?['ad']?.toString() ?? '');
    final aciklama =
        TextEditingController(text: lokasyon?['aciklama']?.toString() ?? '');
    if (!mounted) return;
    final kaydet = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lokasyon == null ? 'Lokasyon Ekle' : 'Lokasyon Düzenle'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: kod,
                decoration: const InputDecoration(
                    labelText: 'Lokasyon kodu *',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: ad,
                decoration: const InputDecoration(
                    labelText: 'Lokasyon adı *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: aciklama,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Açıklama', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet')),
        ],
      ),
    );
    try {
      if (kaydet == true) {
        if (kod.text.trim().isEmpty || ad.text.trim().isEmpty) {
          throw 'Kod ve ad zorunludur';
        }
        await IplikLokasyonSayimService.lokasyonKaydet(
          id: lokasyon?['id']?.toString(),
          kod: kod.text,
          ad: ad.text,
          aciklama: aciklama.text,
        );
        await _verileriYukle();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Lokasyon hatası: $e');
    } finally {
      kod.dispose();
      ad.dispose();
      aciklama.dispose();
    }
  }

  Widget _buildSayimSayfasi() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: IplikLokasyonSayimService.sayimlariGetir(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LoadingWidget());
        final sayimlar = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              const Expanded(
                child: Text('İplik Sayımı',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              if (_sayimYoneticisi)
                FilledButton.icon(
                  onPressed: _sayimAcDialogu,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Sayım Aç'),
                ),
            ]),
            const SizedBox(height: 12),
            if (sayimlar.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Henüz sayım oturumu yok')),
                ),
              ),
            ...sayimlar.map((sayim) {
              final satirlar = (sayim['iplik_sayim_satirlari'] as List?) ?? [];
              final sayilan = satirlar
                  .where((item) => (item as Map)['sayilan_miktar'] != null)
                  .length;
              final fark = satirlar.fold<double>(0, (sum, item) {
                final row = item as Map;
                if (row['sayilan_miktar'] == null) return sum;
                return sum +
                    (row['sayilan_miktar'] as num).toDouble() -
                    (row['beklenen_miktar'] as num).toDouble();
              });
              final lokasyonlar =
                  (sayim['iplik_sayim_oturum_lokasyonlari'] as List? ?? [])
                      .map((item) {
                final l = (item as Map)['iplik_lokasyonlari'] as Map?;
                return '${l?['kod'] ?? ''} - ${l?['ad'] ?? ''}';
              }).join(', ');
              return Card(
                child: ListTile(
                  onTap: () => _sayimDetayDialogu(sayim),
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(sayim['sayim_no']?.toString() ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '$lokasyonlar • $sayilan/${satirlar.length} satır • '
                    'Fark ${fark >= 0 ? '+' : ''}${fark.toStringAsFixed(2)} kg • '
                    '${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(sayim['acilis_tarihi']))}',
                  ),
                  trailing: Chip(
                    label: Text(sayim['durum']?.toString() ?? '-'),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _sayimAcDialogu() async {
    final secilen = <String>{};
    final aciklama = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Kör Sayım'),
          content: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Sayılacak lokasyonlar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              ...iplikLokasyonlari
                  .where((item) => item['aktif'] != false)
                  .map((item) => CheckboxListTile(
                        value: secilen.contains(item['id'].toString()),
                        title: Text('${item['kod']} - ${item['ad']}'),
                        onChanged: (value) => setDialogState(() {
                          value == true
                              ? secilen.add(item['id'].toString())
                              : secilen.remove(item['id'].toString());
                        }),
                      )),
              TextField(
                controller: aciklama,
                decoration: const InputDecoration(
                    labelText: 'Açıklama', border: OutlineInputBorder()),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal')),
            FilledButton(
                onPressed:
                    secilen.isEmpty ? null : () => Navigator.pop(context, true),
                child: const Text('Sayımı Aç')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        final id = await IplikLokasyonSayimService.sayimAc(
          lokasyonIds: secilen.toList(),
          aciklama: aciklama.text,
        );
        if (mounted) setState(() {});
        final tumSayimlar = await IplikLokasyonSayimService.sayimlariGetir();
        final sayim = tumSayimlar.firstWhere(
          (item) => item['id']?.toString() == id,
          orElse: () => {
            'id': id,
            'durum': 'taslak',
            'sayim_no': 'Yeni Sayım',
          },
        );
        await _sayimDetayDialogu(sayim);
      } catch (e) {
        if (mounted) context.showErrorSnackBar('Sayım açılamadı: $e');
      }
    }
    aciklama.dispose();
  }

  Future<void> _sayimDetayDialogu(Map<String, dynamic> sayim) async {
    var satirlar = await IplikLokasyonSayimService.sayimSatirlariGetir(
        sayim['id'].toString());
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Kör Sayım - ${sayim['sayim_no'] ?? ''}'),
          content: SizedBox(
            width: 850,
            height: 520,
            child: ListView.separated(
              itemCount: satirlar.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final row = satirlar[index];
                final stok = row['iplik_stoklari'] as Map? ?? {};
                final lok = row['iplik_lokasyonlari'] as Map? ?? {};
                final controller = TextEditingController(
                    text: row['sayilan_miktar']?.toString() ?? '');
                final sayildi = row['sayilan_miktar'] != null;
                return ListTile(
                  title: Text(
                      '${stok['ad'] ?? '-'} • ${stok['renk'] ?? '-'} • Lot ${stok['lot_no'] ?? '-'}'),
                  subtitle: Text(
                    '${lok['kod']} - ${lok['ad']}'
                    '${sayildi ? ' • Beklenen ${row['beklenen_miktar']} • Fark ${((row['sayilan_miktar'] as num).toDouble() - (row['beklenen_miktar'] as num).toDouble()).toStringAsFixed(2)}' : ''}',
                  ),
                  trailing: SizedBox(
                    width: 190,
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: sayim['durum'] == 'taslak',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Fiziksel kg', isDense: true),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kaydet',
                        onPressed: sayim['durum'] != 'taslak'
                            ? null
                            : () async {
                                final value = _parseDecimal(controller.text);
                                if (value == null || value < 0) return;
                                await IplikLokasyonSayimService
                                    .sayimSatiriKaydet(
                                  sayimId: sayim['id'].toString(),
                                  lokasyonId: row['lokasyon_id'].toString(),
                                  stokId: row['stok_id'].toString(),
                                  sayilan: value,
                                );
                                satirlar = await IplikLokasyonSayimService
                                    .sayimSatirlariGetir(
                                        sayim['id'].toString());
                                setDialogState(() {});
                              },
                        icon: const Icon(Icons.save_outlined),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Kapat')),
            OutlinedButton.icon(
              onPressed: () => _sayimExcelIndir(sayim, satirlar),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Excel'),
            ),
            if (sayim['durum'] == 'taslak')
              TextButton.icon(
                onPressed: () async {
                  await _beklenmeyenSayimSatiriEkle(
                    sayim['id'].toString(),
                    satirlar,
                    ((sayim['iplik_sayim_oturum_lokasyonlari'] as List?) ??
                            const [])
                        .map((item) => (item as Map)['lokasyon_id']?.toString())
                        .whereType<String>()
                        .toSet(),
                  );
                  satirlar =
                      await IplikLokasyonSayimService.sayimSatirlariGetir(
                          sayim['id'].toString());
                  setDialogState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Beklenmeyen İplik'),
              ),
            if (sayim['durum'] == 'taslak' && _sayimYoneticisi)
              TextButton(
                onPressed: () async {
                  await IplikLokasyonSayimService.sayimIptal(
                      sayim['id'].toString());
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) setState(() {});
                },
                child: const Text('İptal Et'),
              ),
            if (sayim['durum'] == 'taslak' && _sayimYoneticisi)
              FilledButton(
                onPressed: () async {
                  try {
                    await IplikLokasyonSayimService.sayimKapat(
                        sayim['id'].toString());
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    await _verileriYukle();
                  } catch (e) {
                    if (dialogContext.mounted)
                      dialogContext.showErrorSnackBar('Kapanış engellendi: $e');
                  }
                },
                child: const Text('Sayımı Kapat'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sayimExcelIndir(
    Map<String, dynamic> sayim,
    List<Map<String, dynamic>> satirlar,
  ) async {
    final rows = satirlar.map((row) {
      final stok = row['iplik_stoklari'] as Map? ?? {};
      final lokasyon = row['iplik_lokasyonlari'] as Map? ?? {};
      final sayilan = row['sayilan_miktar'] as num?;
      final beklenen = row['beklenen_miktar'] as num? ?? 0;
      return <String, dynamic>{
        'sayim_no': sayim['sayim_no'],
        'lokasyon': '${lokasyon['kod'] ?? ''} - ${lokasyon['ad'] ?? ''}',
        'iplik': stok['ad'],
        'renk': stok['renk'],
        'lot': stok['lot_no'],
        'beklenen': sayilan == null ? null : beklenen,
        'sayilan': sayilan,
        'fark':
            sayilan == null ? null : sayilan.toDouble() - beklenen.toDouble(),
      };
    }).toList();
    await ExcelHelper.exportToExcel(
      data: rows,
      fileName: 'Iplik_Sayim_${sayim['sayim_no'] ?? ''}',
      columns: const {
        'sayim_no': 'Sayım No',
        'lokasyon': 'Lokasyon',
        'iplik': 'İplik',
        'renk': 'Renk',
        'lot': 'Lot',
        'beklenen': 'Beklenen',
        'sayilan': 'Sayılan',
        'fark': 'Fark',
      },
    );
  }

  Future<void> _beklenmeyenSayimSatiriEkle(
    String sayimId,
    List<Map<String, dynamic>> satirlar,
    Set<String> oturumLokasyonIds,
  ) async {
    String? stokId;
    final lokasyonIds = satirlar
        .map((item) => item['lokasyon_id']?.toString())
        .whereType<String>()
        .toSet()
      ..addAll(oturumLokasyonIds);
    String? lokasyonId = lokasyonIds.isEmpty ? null : lokasyonIds.first;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Beklenmeyen Mevcut İplik'),
          content: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: stokId,
                decoration: const InputDecoration(
                    labelText: 'Stok kartı', border: OutlineInputBorder()),
                items: iplikStoklari
                    .map((item) => DropdownMenuItem(
                          value: item['id']?.toString(),
                          child: Text(
                            '${item['ad']} • ${item['renk'] ?? '-'} • Lot ${item['lot_no'] ?? '-'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setDialogState(() => stokId = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: lokasyonId,
                decoration: const InputDecoration(
                    labelText: 'Sayım lokasyonu', border: OutlineInputBorder()),
                items: lokasyonIds
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(_lokasyonEtiketi(id)),
                        ))
                    .toList(),
                onChanged: (value) => setDialogState(() => lokasyonId = value),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal')),
            FilledButton(
                onPressed: stokId == null || lokasyonId == null
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Ekle')),
          ],
        ),
      ),
    );
    if (ok == true) {
      await IplikLokasyonSayimService.sayimSatiriKaydet(
        sayimId: sayimId,
        lokasyonId: lokasyonId!,
        stokId: stokId!,
        sayilan: 0,
      );
    }
  }

  Future<void> _lokasyonTransferDialogu(Map<String, dynamic> stok) async {
    final dagilim = _stokLokasyonlari(stok)
        .where((x) => (x['miktar'] as num?)?.toDouble() != 0)
        .toList();
    String? kaynak =
        dagilim.isEmpty ? null : dagilim.first['lokasyon_id'].toString();
    String? hedef;
    final miktar = TextEditingController();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Lokasyon Transferi - ${stok['ad']}'),
          content: SizedBox(
              width: 480,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: kaynak,
                  decoration: const InputDecoration(
                      labelText: 'Kaynak lokasyon',
                      border: OutlineInputBorder()),
                  items: dagilim
                      .map((x) => DropdownMenuItem(
                          value: x['lokasyon_id'].toString(),
                          child: Text(
                              '${_lokasyonEtiketi(x['lokasyon_id'])} (${x['miktar']} kg)')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => kaynak = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: hedef,
                  decoration: const InputDecoration(
                      labelText: 'Hedef lokasyon',
                      border: OutlineInputBorder()),
                  items: iplikLokasyonlari
                      .where((x) =>
                          x['aktif'] != false && x['id'].toString() != kaynak)
                      .map((x) => DropdownMenuItem(
                          value: x['id'].toString(),
                          child: Text('${x['kod']} - ${x['ad']}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => hedef = v),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: miktar,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Miktar (kg)',
                        border: OutlineInputBorder())),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Transfer Et')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        final value = _parseDecimal(miktar.text);
        if (kaynak == null || hedef == null || value == null || value <= 0)
          throw 'Kaynak, hedef ve miktar zorunludur';
        await IplikLokasyonSayimService.transferEt(
            stokId: stok['id'].toString(),
            kaynakLokasyonId: kaynak!,
            hedefLokasyonId: hedef!,
            miktar: value);
        await _verileriYukle();
      } catch (e) {
        if (mounted) context.showErrorSnackBar('Transfer hatası: $e');
      }
    }
    miktar.dispose();
  }
}
