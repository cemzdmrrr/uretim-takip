// ignore_for_file: invalid_use_of_protected_member
part of 'odeme_page.dart';

/// Odeme page - dialog, hesaplama ve yardimci metotlar
extension _AksiyonExt on _OdemePageState {
  Future<void> _yeniOdemeEkle() async {
    String tur = 'avans';
    double? tutar;
    String aciklama = '';
    final formKey = GlobalKey<FormState>();
    final tutarController = TextEditingController();
    String? seciliPersonelId = widget.personelId;
    List<Map<String, String>> personelList = [];
    bool yukleniyor = true;
    String? modalDonem = seciliDonem;
    // Personel listesini çek
    try {
      final servis = PersonelService();
      final personeller = await servis.getPersoneller();
      personelList =
          personeller.map((p) => {'id': p.userId, 'ad': p.ad}).toList();
      if ((seciliPersonelId.trim().isEmpty) && personelList.isNotEmpty) {
        seciliPersonelId = personelList.first['id'];
      }
      yukleniyor = false;
    } catch (e) {
      yukleniyor = false;
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Modal açılırken id boşsa ilk id'yi ata
          if (((seciliPersonelId ?? '').trim().isEmpty) &&
              personelList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                seciliPersonelId = personelList.first['id'];
              });
            });
          }
          // Personel rolü için sadece kendi adı ve sadece avans türü göster
          final sadeceKendisi = currentUserRole == DbTables.personel;
          final sadeceAvans = currentUserRole == DbTables.personel;
          final filteredPersonelList = sadeceKendisi
              ? personelList.where((p) => p['id'] == currentUserId).toList()
              : personelList;
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payment,
                            color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Yeni Avans/Ödeme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  yukleniyor
                      ? const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()))
                      : Form(
                          key: formKey,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  children: [
                                    // Dönem seçici
                                    DonemSecici(
                                      seciliDonem: modalDonem,
                                      onDonemChanged: (donem) {
                                        setState(() => modalDonem = donem);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      initialValue: seciliPersonelId,
                                      items: filteredPersonelList
                                          .map((p) => DropdownMenuItem(
                                                value: p['id'],
                                                child: Text(p['ad'] ?? '',
                                                    style: const TextStyle(
                                                        color: Colors.blue)),
                                              ))
                                          .toList(),
                                      onChanged: sadeceKendisi
                                          ? null
                                          : (v) => setState(
                                              () => seciliPersonelId = v),
                                      decoration: InputDecoration(
                                        labelText: 'Personel Seç',
                                        labelStyle:
                                            const TextStyle(color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Zorunlu'
                                          : null,
                                      style:
                                          const TextStyle(color: Colors.blue),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      initialValue: tur,
                                      items: sadeceAvans
                                          ? [
                                              const DropdownMenuItem(
                                                  value: 'avans',
                                                  child: Text('Avans',
                                                      style: TextStyle(
                                                          color: Colors.blue)))
                                            ]
                                          : const [
                                              DropdownMenuItem(
                                                  value: 'avans',
                                                  child: Text('Avans',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                              DropdownMenuItem(
                                                  value: 'prim',
                                                  child: Text('Prim',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                              DropdownMenuItem(
                                                  value: DbTables.mesai,
                                                  child: Text('Fazla Mesai',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                              DropdownMenuItem(
                                                  value: 'ikramiye',
                                                  child: Text('İkramiye',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                              DropdownMenuItem(
                                                  value: 'kesinti',
                                                  child: Text('Kesinti',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                              DropdownMenuItem(
                                                  value: 'banka_odeme',
                                                  child: Text('Banka Ödemesi',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                              DropdownMenuItem(
                                                  value: 'tazminat',
                                                  child: Text('Tazminat',
                                                      style: TextStyle(
                                                          color: Colors.blue))),
                                            ],
                                      onChanged: sadeceAvans
                                          ? null
                                          : (v) => tur = v ?? 'avans',
                                      decoration: InputDecoration(
                                        labelText: 'Tür',
                                        labelStyle:
                                            const TextStyle(color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      style:
                                          const TextStyle(color: Colors.blue),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: tutarController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Tutar',
                                        labelStyle:
                                            const TextStyle(color: Colors.blue),
                                        prefixIcon: const Icon(
                                            Icons.attach_money,
                                            color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      style:
                                          const TextStyle(color: Colors.blue),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Zorunlu';
                                        }
                                        final parsed =
                                            parseLocalizedDecimal(v.trim());
                                        if (parsed == null || parsed <= 0) {
                                          return 'Geçerli bir tutar girin';
                                        }
                                        return null;
                                      },
                                      onChanged: (v) =>
                                          tutar = parseLocalizedDecimal(v),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Açıklama',
                                        labelStyle:
                                            const TextStyle(color: Colors.blue),
                                        prefixIcon: const Icon(Icons.note,
                                            color: Colors.blue),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      style:
                                          const TextStyle(color: Colors.blue),
                                      onChanged: (v) => aciklama = v,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('İptal',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            tutar = parseLocalizedDecimal(tutarController.text);
                            if (tutar == null) return;
                            if ((seciliPersonelId ?? '').trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Geçerli bir personel seçiniz!')),
                              );
                              return;
                            }
                            // Giriş yapan kullanıcının id'sini al
                            final currentUser =
                                Supabase.instance.client.auth.currentUser;
                            final userId = currentUser?.id;
                            if (userId == null || userId.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Kullanıcı oturum bilgisi alınamadı!')),
                              );
                              return;
                            }
                            debugPrint(
                                'Kayıt için seçili personel id: "$seciliPersonelId"');
                            // Dönem'e göre tarih hesapla
                            DateTime odemeTarihi;
                            if (modalDonem != null && modalDonem!.isNotEmpty) {
                              final parts = modalDonem!.split('-');
                              final yil =
                                  int.tryParse(parts[0]) ?? DateTime.now().year;
                              final ay = int.tryParse(parts[1]) ??
                                  DateTime.now().month;
                              final now = DateTime.now();
                              if (yil == now.year && ay == now.month) {
                                odemeTarihi = now;
                              } else {
                                odemeTarihi = DateTime(yil, ay, 1);
                              }
                            } else {
                              odemeTarihi = DateTime.now();
                            }
                            final odeme = OdemeModel(
                              id: null,
                              personelId: seciliPersonelId!,
                              userId:
                                  userId, // Artık oturum açan kullanıcının id'si atanıyor
                              tur: tur,
                              tutar: tutar!,
                              aciklama: aciklama,
                              tarih: odemeTarihi,
                              durum: 'beklemede',
                              onaylayanId: null,
                            );
                            debugPrint(
                                'Gönderilen ödeme map: \x1B[33m\x1B[0m${odeme.toMap()}');
                            try {
                              await OdemeService().addOdeme(odeme);
                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              if (modalDonem != seciliDonem) {
                                this.setState(() => seciliDonem = modalDonem);
                              }
                              // ignore: use_build_context_synchronously
                              context.showSnackBar(
                                  'Avans/Ödeme talebi başarıyla oluşturuldu!');
                              await _getOdemeler();
                            } catch (e) {
                              debugPrint('Ödeme ekleme hatası: $e');
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Kayıt hatası: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Kaydet',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOdemeSummarySection(
    BuildContext context,
    double width, {
    required double mesaiTutar,
    required double kesintiTutar,
    required double mesaiYemekUcreti,
    required double yolUcreti,
  }) {
    final maas = double.tryParse(personel?.netMaas ?? '0') ?? 0;
    final yemek = double.tryParse(personel?.yemekUcreti ?? '0') ?? 0;
    final bankadanMaas = double.tryParse(personel?.bankaMaas ?? '0') ?? 0;
    final gunlukSaat =
        double.tryParse(personel?.gunlukCalismaSaati ?? '0') ?? 0;
    final prim = (ozetBakiyeler['prim'] ?? 0).toDouble();
    final avans = (ozetBakiyeler['avans'] ?? 0).toDouble();
    final ikramiye = (ozetBakiyeler['ikramiye'] ?? 0).toDouble();
    final bankaOdeme = (ozetBakiyeler['banka_odeme'] ?? 0).toDouble();
    final tazminat = (ozetBakiyeler['tazminat'] ?? 0).toDouble();
    final toplamYemekUcreti = yemek + mesaiYemekUcreti;
    final ucretsizIzin = (ucretsizIzinGun ?? 0).toDouble();
    final ucretsizIzinTutari =
        gunlukSaat > 0 ? (maas / 30) * ucretsizIzin : 0.0;
    final toplamKesinti = kesintiTutar + ucretsizIzinTutari;
    final bekleyenTalep =
        odemeler.where((odeme) => odeme.durum == 'beklemede').length;
    final ekKazanc =
        mesaiTutar + prim + ikramiye + tazminat + yolUcreti + toplamYemekUcreti;
    final toplamKazanc = maas +
        mesaiTutar +
        prim +
        ikramiye +
        tazminat +
        yolUcreti +
        toplamYemekUcreti -
        toplamKesinti -
        avans;
    final kalanUcret = toplamKazanc - bankaOdeme;

    final cards = [
      _buildSummaryCard(
        title: 'Kalan Ücret',
        value: _formatTutar(kalanUcret),
        subtitle: 'Maaş, ek kazanç ve kesintiler sonrası',
        icon: kalanUcret >= 0
            ? Icons.account_balance_wallet
            : Icons.warning_amber,
        color:
            kalanUcret >= 0 ? const Color(0xFF2F6FED) : const Color(0xFFDC2626),
      ),
      _buildSummaryCard(
        title: 'Onaylı Avans',
        value: _formatTutar(avans),
        subtitle: 'Bu dönemde maaştan düşülecek avans',
        icon: Icons.payments_outlined,
        color: const Color(0xFF0F766E),
      ),
      _buildSummaryCard(
        title: 'Bekleyen Talep',
        value: '$bekleyenTalep kayıt',
        subtitle: 'Onay bekleyen avans/ödeme hareketi',
        icon: Icons.pending_actions,
        color: const Color(0xFFB45309),
      ),
      _buildSummaryCard(
        title: 'Ek Kazanç',
        value: _formatTutar(ekKazanc),
        subtitle: 'Mesai, prim, ikramiye, tazminat, yol ve yemek',
        icon: Icons.trending_up,
        color: const Color(0xFF7C3AED),
      ),
      _buildSummaryCard(
        title: 'Kesinti',
        value: _formatTutar(toplamKesinti),
        subtitle: 'Kesinti ve ücretsiz izin etkisi',
        icon: Icons.trending_down,
        color: const Color(0xFFDC2626),
      ),
    ];

    final gelirRows = [
      ('Net maaş', maas),
      ('Toplam mesai', mesaiTutar),
      ('Prim', prim),
      ('Tazminat', tazminat),
      ('İkramiye', ikramiye),
      ('Yol', yolUcreti),
      ('Yemek', toplamYemekUcreti),
    ];
    final kesintiRows = [
      ('Avans', avans),
      ('Kesinti kayıtları', kesintiTutar),
      ('Ücretsiz izin', ucretsizIzinTutari),
      ('Tanımlı banka maaşı', bankadanMaas),
      ('Yapılan banka ödemesi', bankaOdeme),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: width >= 700 ? 16 : 10,
          runSpacing: width >= 700 ? 16 : 10,
          children: cards
              .map((card) => SizedBox(
                    width: width >= 1280
                        ? (width - 64) / 3
                        : width >= 760
                            ? (width - 48) / 2
                            : width,
                    child: card,
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6DEEB)),
          ),
          child: width >= 1024
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildFinanceBreakdown(
                        title: 'Gelirler',
                        rows: gelirRows,
                        negative: false,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildFinanceBreakdown(
                        title: 'Kesintiler ve Mahsuplar',
                        rows: kesintiRows,
                        negative: true,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildFinanceSnapshot(
                        toplamKazanc: toplamKazanc,
                        kalanUcret: kalanUcret,
                        avans: avans,
                        ucretsizIzinGun: ucretsizIzinGun ?? 0,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFinanceBreakdown(
                      title: 'Gelirler',
                      rows: gelirRows,
                      negative: false,
                    ),
                    const SizedBox(height: 20),
                    _buildFinanceBreakdown(
                      title: 'Kesintiler ve Mahsuplar',
                      rows: kesintiRows,
                      negative: true,
                    ),
                    const SizedBox(height: 20),
                    _buildFinanceSnapshot(
                      toplamKazanc: toplamKazanc,
                      kalanUcret: kalanUcret,
                      avans: avans,
                      ucretsizIzinGun: ucretsizIzinGun ?? 0,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildOdemeFilterSection(BuildContext context, double width) {
    final hasFilter = filtreTur != null ||
        filtreDurum != null ||
        filtreBaslangic != null ||
        filtreBitis != null;
    final isWide = width >= 1040;
    final isNarrow = width < 560;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6DEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: Color(0xFF2F6FED)),
              ),
              SizedBox(
                width: isNarrow ? width - 92 : width - (hasFilter ? 210 : 92),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kayıt filtreleri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dönem, tür, durum ve tarih aralığı ile ödeme akışını daraltın.',
                      style: TextStyle(color: Color(0xFF64748B)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasFilter)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      filtreTur = null;
                      filtreDurum = null;
                      filtreBaslangic = null;
                      filtreBitis = null;
                    });
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Temizle'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (isWide)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildFilterField(
                    label: 'Dönem',
                    child: DonemSecici(
                      seciliDonem: seciliDonem,
                      onDonemChanged: _donemDegisti,
                      showAll: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _buildFilterField(
                    label: 'Tür',
                    child: DropdownButtonFormField<String?>(
                      initialValue: filtreTur,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                            value: null, child: Text('Tümü')),
                        DropdownMenuItem<String?>(
                            value: 'avans', child: Text('Avans')),
                        DropdownMenuItem<String?>(
                            value: 'prim', child: Text('Prim')),
                        DropdownMenuItem<String?>(
                            value: DbTables.mesai, child: Text('Mesai')),
                        DropdownMenuItem<String?>(
                            value: 'ikramiye', child: Text('İkramiye')),
                        DropdownMenuItem<String?>(
                            value: 'kesinti', child: Text('Kesinti')),
                        DropdownMenuItem<String?>(
                            value: 'banka_odeme', child: Text('Banka Ödemesi')),
                        DropdownMenuItem<String?>(
                            value: 'tazminat', child: Text('Tazminat')),
                      ],
                      onChanged: (value) => setState(() => filtreTur = value),
                      decoration: _filterDecoration(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: _buildFilterField(
                    label: 'Durum',
                    child: DropdownButtonFormField<String?>(
                      initialValue: filtreDurum,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                            value: null, child: Text('Tümü')),
                        DropdownMenuItem<String?>(
                            value: 'beklemede', child: Text('Beklemede')),
                        DropdownMenuItem<String?>(
                            value: 'onaylandi', child: Text('Onaylandı')),
                        DropdownMenuItem<String?>(
                            value: 'red', child: Text('Reddedildi')),
                      ],
                      onChanged: (value) => setState(() => filtreDurum = value),
                      decoration: _filterDecoration(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 170,
                  child: _buildDateRangeButton(context),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildFilterField(
                  label: 'Dönem',
                  child: DonemSecici(
                    seciliDonem: seciliDonem,
                    onDonemChanged: _donemDegisti,
                    showAll: true,
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterField(
                  label: 'Tür',
                  child: DropdownButtonFormField<String?>(
                    initialValue: filtreTur,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem<String?>(
                          value: null, child: Text('Tümü')),
                      DropdownMenuItem<String?>(
                          value: 'avans', child: Text('Avans')),
                      DropdownMenuItem<String?>(
                          value: 'prim', child: Text('Prim')),
                      DropdownMenuItem<String?>(
                          value: DbTables.mesai, child: Text('Mesai')),
                      DropdownMenuItem<String?>(
                          value: 'ikramiye', child: Text('İkramiye')),
                      DropdownMenuItem<String?>(
                          value: 'kesinti', child: Text('Kesinti')),
                      DropdownMenuItem<String?>(
                          value: 'banka_odeme', child: Text('Banka Ödemesi')),
                      DropdownMenuItem<String?>(
                          value: 'tazminat', child: Text('Tazminat')),
                    ],
                    onChanged: (value) => setState(() => filtreTur = value),
                    decoration: _filterDecoration(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterField(
                  label: 'Durum',
                  child: DropdownButtonFormField<String?>(
                    initialValue: filtreDurum,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem<String?>(
                          value: null, child: Text('Tümü')),
                      DropdownMenuItem<String?>(
                          value: 'beklemede', child: Text('Beklemede')),
                      DropdownMenuItem<String?>(
                          value: 'onaylandi', child: Text('Onaylandı')),
                      DropdownMenuItem<String?>(
                          value: 'red', child: Text('Reddedildi')),
                    ],
                    onChanged: (value) => setState(() => filtreDurum = value),
                    decoration: _filterDecoration(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildDateRangeButton(context),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOdemeListSection(BuildContext context, double width) {
    final kayitlar = _filtreliOdemeler;
    final isDesktop = width >= 1180;
    final isNarrow = width < 560;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6DEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!isNarrow) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.view_list, color: Color(0xFF2F6FED)),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kayıt akışı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kayitlar.length} kayıt görüntüleniyor',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (kayitlar.isEmpty)
            _buildEmptyState()
          else if (isDesktop) ...[
            _buildDesktopTableHeader(),
            const SizedBox(height: 8),
            ...kayitlar.map((odeme) => _buildDesktopOdemeRow(context, odeme)),
          ] else
            ...kayitlar.map((odeme) => _buildMobileOdemeCard(context, odeme)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6DEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceBreakdown({
    required String title,
    required List<(String, double)> rows,
    required bool negative,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        ...rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                ),
                Text(
                  _formatTutar(row.$2),
                  style: TextStyle(
                    color: negative && row.$2 > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFinanceSnapshot({
    required double toplamKazanc,
    required double kalanUcret,
    required double avans,
    required int ucretsizIzinGun,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6DEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dönem özeti',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildSnapshotRow('Toplam kazanç', _formatTutar(toplamKazanc)),
          _buildSnapshotRow('Kalan ödeme', _formatTutar(kalanUcret)),
          _buildSnapshotRow('Avans kullanımı', _formatTutar(avans)),
          _buildSnapshotRow('Ücretsiz izin günü', '$ucretsizIzinGun gün'),
        ],
      ),
    );
  }

  Widget _buildSnapshotRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    final selectedText = filtreBaslangic != null && filtreBitis != null
        ? '${_formatDate(filtreBaslangic!)} - ${_formatDate(filtreBitis!)}'
        : 'Tarih aralığı';

    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDateRange: (filtreBaslangic != null && filtreBitis != null)
                ? DateTimeRange(start: filtreBaslangic!, end: filtreBitis!)
                : null,
          );
          if (picked == null) {
            return;
          }
          setState(() {
            filtreBaslangic = picked.start;
            filtreBitis = picked.end;
          });
        },
        icon: const Icon(Icons.date_range_outlined),
        label: Text(selectedText, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFD6DEEB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Gösterilecek kayıt yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Filtreleri temizleyin veya yeni bir ödeme kaydı oluşturun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('Hareket',
                  style: TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 2,
              child:
                  Text('Tarih', style: TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 2,
              child:
                  Text('Durum', style: TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 2,
              child:
                  Text('Tutar', style: TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 3,
              child: Text('Aksiyon',
                  style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildDesktopOdemeRow(BuildContext context, OdemeModel odeme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _odemeRenk(odeme.tur).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(_odemeIcon(odeme.tur), color: _odemeRenk(odeme.tur)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _turEtiketi(odeme.tur),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (odeme.aciklama.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          odeme.aciklama,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(odeme.tarih),
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ),
          Expanded(flex: 2, child: _buildStatusChip(odeme.durum)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatTutar(odeme.tutar),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildOdemeActionArea(context, odeme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOdemeCard(BuildContext context, OdemeModel odeme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
                  color: _odemeRenk(odeme.tur).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(_odemeIcon(odeme.tur), color: _odemeRenk(odeme.tur)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _turEtiketi(odeme.tur),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTutar(odeme.tutar),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(odeme.durum),
            ],
          ),
          if (odeme.aciklama.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              odeme.aciklama,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMiniInfo(
                  Icons.calendar_today_outlined, _formatDate(odeme.tarih)),
              if (odeme.onaylayanId != null)
                _buildMiniInfo(Icons.verified_user_outlined, 'Onaylayan var'),
            ],
          ),
          const SizedBox(height: 14),
          _buildOdemeActionArea(context, odeme),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String durum) {
    final color = _statusColor(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _durumEtiketi(durum),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOdemeActionArea(BuildContext context, OdemeModel odeme) {
    return FutureBuilder<bool>(
      future: kullaniciAdminMi(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final adminMi = snapshot.data == true;
        final buttons = <Widget>[];

        if (adminMi && odeme.durum == 'beklemede') {
          buttons.addAll([
            _actionButton(
              label: 'Onayla',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF059669),
              onPressed: () => _onaylaOdemeKaydi(context, odeme),
            ),
            _actionButton(
              label: 'Düzenle',
              icon: Icons.edit_outlined,
              color: const Color(0xFFB45309),
              onPressed: () =>
                  _duzenleOdemeKaydi(context, odeme, avansTalebi: false),
            ),
            _actionButton(
              label: 'Sil',
              icon: Icons.delete_outline,
              color: const Color(0xFFDC2626),
              onPressed: () =>
                  _silOdemeKaydi(context, odeme, avansTalebi: false),
            ),
          ]);
        }

        if (odeme.tur == 'avans' &&
            odeme.userId == currentUserId &&
            odeme.durum == 'beklemede') {
          buttons.addAll([
            _actionButton(
              label: 'Düzenle',
              icon: Icons.edit_outlined,
              color: const Color(0xFFB45309),
              onPressed: () =>
                  _duzenleOdemeKaydi(context, odeme, avansTalebi: true),
            ),
            _actionButton(
              label: 'Sil',
              icon: Icons.delete_outline,
              color: const Color(0xFFDC2626),
              onPressed: () =>
                  _silOdemeKaydi(context, odeme, avansTalebi: true),
            ),
          ]);
        }

        if (adminMi && odeme.durum == 'onaylandi') {
          buttons.addAll([
            _actionButton(
              label: 'Düzenle',
              icon: Icons.edit_outlined,
              color: const Color(0xFFB45309),
              onPressed: () =>
                  _duzenleOdemeKaydi(context, odeme, avansTalebi: false),
            ),
            _actionButton(
              label: 'Sil',
              icon: Icons.delete_outline,
              color: const Color(0xFFDC2626),
              onPressed: () =>
                  _silOdemeKaydi(context, odeme, avansTalebi: false),
            ),
          ]);
        }

        if (buttons.isEmpty) {
          return const SizedBox.shrink();
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons,
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _onaylaOdemeKaydi(BuildContext context, OdemeModel odeme) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userId = currentUser?.id;
    if (userId == null) {
      return;
    }

    try {
      await OdemeService().updateOdemeDurum(
        odeme.id!,
        'onaylandi',
        onaylayanId: userId,
      );
      try {
        await NotificationService().sendNotification(
          userId: odeme.userId,
          title: 'Avans/Ödeme Talebiniz Onaylandı',
          message: 'Talebiniz yönetici tarafından onaylandı.',
        );
      } catch (bildirimHata) {
        debugPrint('Bildirim gönderme hatası: $bildirimHata');
      }
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(
        'Ödeme onaylandı ve maaş hesaplamalarına dahil edildi.',
      );
      _getOdemeler();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.showSnackBar('Onaylama hatası: $e');
    }
  }

  Future<void> _silOdemeKaydi(
    BuildContext context,
    OdemeModel odeme, {
    required bool avansTalebi,
  }) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(avansTalebi ? 'Avans talebini sil' : 'Ödeme kaydını sil'),
        content: Text(
          avansTalebi
              ? 'Bu avans talebini silmek istediğinizden emin misiniz?'
              : 'Bu ödeme kaydını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true) {
      return;
    }

    try {
      await OdemeService().deleteOdeme(odeme.id!);
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(
        avansTalebi
            ? 'Avans talebi başarıyla silindi.'
            : 'Ödeme kaydı başarıyla silindi.',
      );
      _getOdemeler();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.showSnackBar('Silme hatası: $e');
    }
  }

  Future<void> _duzenleOdemeKaydi(
    BuildContext context,
    OdemeModel odeme, {
    required bool avansTalebi,
  }) async {
    final tutarController = TextEditingController(text: odeme.tutar.toString());
    final aciklamaController = TextEditingController(text: odeme.aciklama);
    final formKey = GlobalKey<FormState>();

    final guncellenen = await showDialog<OdemeModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            avansTalebi ? 'Avans talebini düzenle' : 'Ödeme kaydını düzenle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: tutarController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tutar'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Zorunlu';
                  final parsed = parseLocalizedDecimal(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: aciklamaController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) {
                return;
              }
              final yeniTutar =
                  parseLocalizedDecimal(tutarController.text) ?? odeme.tutar;
              Navigator.pop(
                ctx,
                odeme.copyWith(
                  tutar: yeniTutar,
                  aciklama: aciklamaController.text,
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (guncellenen == null) {
      return;
    }

    try {
      await OdemeService().updateOdeme(odeme.id!, guncellenen.toMap());
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(
        avansTalebi
            ? 'Avans talebi başarıyla güncellendi.'
            : 'Ödeme kaydı başarıyla güncellendi.',
      );
      _getOdemeler();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.showSnackBar('Güncelleme hatası: $e');
    }
  }

  InputDecoration _filterDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DEEB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DEEB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2F6FED), width: 1.4),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String _formatTutar(double value) {
    final isNegative = value < 0;
    final absValue = value.abs().toStringAsFixed(2);
    return isNegative ? '-₺$absValue' : '₺$absValue';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  String _turEtiketi(String tur) {
    switch (tur) {
      case 'avans':
        return 'Avans';
      case 'prim':
        return 'Prim';
      case DbTables.mesai:
        return 'Mesai';
      case 'ikramiye':
        return 'İkramiye';
      case 'kesinti':
        return 'Kesinti';
      case 'banka_odeme':
        return 'Banka Ödemesi';
      case 'tazminat':
        return 'Tazminat';
      default:
        return tur;
    }
  }

  String _durumEtiketi(String durum) {
    switch (durum) {
      case 'onaylandi':
        return 'Onaylandı';
      case 'beklemede':
        return 'Beklemede';
      case 'red':
        return 'Reddedildi';
      default:
        return durum;
    }
  }

  Color _statusColor(String durum) {
    switch (durum) {
      case 'onaylandi':
        return const Color(0xFF059669);
      case 'red':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _odemeIcon(String tur) {
    switch (tur) {
      case 'avans':
        return Icons.payments;
      case 'prim':
        return Icons.star;
      case DbTables.mesai:
        return Icons.access_time;
      case 'ikramiye':
        return Icons.card_giftcard;
      case 'kesinti':
        return Icons.remove_circle;
      case 'banka_odeme':
        return Icons.account_balance;
      case 'tazminat':
        return Icons.request_quote;
      default:
        return Icons.attach_money;
    }
  }

  Color _odemeRenk(String tur) {
    switch (tur) {
      case 'avans':
        return Colors.orange;
      case 'prim':
        return Colors.green;
      case DbTables.mesai:
        return Colors.blue;
      case 'ikramiye':
        return Colors.purple;
      case 'kesinti':
        return Colors.red;
      case 'banka_odeme':
        return Colors.indigo;
      case 'tazminat':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<double> _getAylikToplamMesaiUcreti() async {
    if (personel == null) return 0;
    final raporTarihi = _raporTarihi();
    final mesailer = await MesaiService()
        .getMesailerForPersonel(personel!.userId, donem: seciliDonem);

    final netMaas = double.tryParse(personel!.netMaas) ?? 0;
    final gunlukSaat = double.tryParse(personel!.gunlukCalismaSaati) ?? 0;
    final saatlikUcret =
        netMaas > 0 && gunlukSaat > 0 ? (netMaas / 30 / gunlukSaat) : 0;

    double toplamMesaiUcret = 0;

    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      if (m.tarih.month == raporTarihi.month &&
          m.tarih.year == raporTarihi.year) {
        if (m.saat != null) {
          // Mesai ücretini hesapla - türe göre farklı hesaplama yöntemleri
          double hesaplananUcret = 0;

          if (m.mesaiTuru == 'Pazar') {
            // Pazar mesaisi: Günlük net maaş x 2 (saat bazında değil, günlük sabit ücret)
            final gunlukNetMaas = netMaas / 30;
            hesaplananUcret = gunlukNetMaas * 2.0;
          } else if (m.mesaiTuru == 'Bayram') {
            // Bayram mesaisi: Pazar gibi günlük net maaş x 2
            final gunlukNetMaas = netMaas / 30;
            hesaplananUcret = gunlukNetMaas * 2.0;
          } else if (m.mesaiTuru == 'Saatlik') {
            // Saatlik mesai: Saatlik ücret x 1.5 x saat
            hesaplananUcret = saatlikUcret * 1.5 * m.saat!;
          }

          // Yemek ücreti mesai hesaplamasına dahil edilmiyor, ayrı olarak finansal özette toplanacak
          toplamMesaiUcret += hesaplananUcret;
        }
      }
    }

    return toplamMesaiUcret;
  }

  Future<double> _getAylikMesaiYemekUcreti() async {
    if (personel == null) return 0;
    final raporTarihi = _raporTarihi();
    final mesailer = await MesaiService()
        .getMesailerForPersonel(personel!.userId, donem: seciliDonem);

    double toplamYemekUcreti = 0;

    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      if (m.tarih.month == raporTarihi.month &&
          m.tarih.year == raporTarihi.year) {
        // Pazar ve Bayram mesaileri için yemek ücreti var
        if (m.mesaiTuru == 'Pazar' || m.mesaiTuru == 'Bayram') {
          toplamYemekUcreti += m.yemekUcreti ?? 0;
        }
      }
    }

    return toplamYemekUcreti;
  }

  Future<double> _getKesintiTutari() async {
    if (personel == null) return 0;
    final raporTarihi = _raporTarihi();
    final izinler = await IzinService()
        .getIzinlerForPersonel(personel!.userId, donem: seciliDonem);
    final maas = double.tryParse(personel!.netMaas) ?? 0;
    const toplamGun = 30; // Standart ay
    final gunlukUcret = maas / toplamGun;
    double toplamKesinti = 0;
    for (final izin in izinler) {
      if (izin.onayDurumu != 'onaylandi') continue;
      if (izin.baslangic.month != raporTarihi.month ||
          izin.baslangic.year != raporTarihi.year) {
        continue;
      }
      if (izin.izinTuru == 'Raporlu') {
        // Raporlu günler için
        final raporluGun = izin.gunSayisi;
        if (raporluGun > 2) {
          final odemeGun = raporluGun - 2;
          // IzinModel'de toplamOdeme ve tedaviSekli yok, sadece günlük ücret ve açıklama ile devam et
          // Tedavi şekli açıklamada aranacak
          double oran = 2 / 3; // Varsayılan ayakta tedavi
          if ((izin.aciklama.toLowerCase().contains('yatarak'))) {
            oran = 1 / 2;
          }
          // Ödenmeyen kısım: (1 - oran)
          toplamKesinti += odemeGun * gunlukUcret * (1 - oran);
        }
      } else if (izin.izinTuru == 'Ücretsiz İzin') {
        toplamKesinti += gunlukUcret * izin.gunSayisi;
      }
      // Diğer izin türlerinde kesinti yok
    }
    return toplamKesinti;
  }

  Future<bool> kullaniciAdminMi() async {
    return currentUserRole == 'admin';
  }

  Future<double> _getAylikYolUcreti() async {
    if (personel == null) return 0;
    // Personel tablosundaki yol ücreti + eğer varsa ek yol ücretleri
    final yolUcreti = double.tryParse(personel!.yolUcreti) ?? 0;
    return yolUcreti;
  }

  DateTime _raporTarihi() {
    final donem = seciliDonem;
    if (donem != null && donem.isNotEmpty) {
      final parts = donem.split('-');
      if (parts.length == 2) {
        final yil = int.tryParse(parts[0]);
        final ay = int.tryParse(parts[1]);
        if (yil != null && ay != null) {
          return DateTime(yil, ay, 1);
        }
      }
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
}
