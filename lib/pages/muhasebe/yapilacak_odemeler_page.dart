import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class YapilacakOdemelerPage extends StatefulWidget {
  const YapilacakOdemelerPage({super.key});

  @override
  State<YapilacakOdemelerPage> createState() => _YapilacakOdemelerPageState();
}

class _YapilacakOdemelerPageState extends State<YapilacakOdemelerPage> {
  final _supabase = Supabase.instance.client;
  final _aramaController = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _moneyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '');

  List<Map<String, dynamic>> _odemeler = [];
  bool _yukleniyor = false;
  String _arama = '';
  String _durumFiltresi = 'bekleyen';

  @override
  void initState() {
    super.initState();
    _odemeleriYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _odemeleriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final data = await _supabase
          .from(DbTables.yapilacakOdemeler)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .order('odeme_tarihi');
      setState(() {
        _odemeler = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Ödemeler yüklenemedi: $e');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  List<Map<String, dynamic>> get _filtreliOdemeler {
    final arama = _arama.trim().toLowerCase();
    final result = _odemeler.where((odeme) {
      final durum = odeme['durum']?.toString() ?? 'bekleyen';
      final metin =
          '${odeme['baslik']} ${odeme['alici']} ${odeme['kategori']} ${odeme['notlar']}'
              .toLowerCase();
      final aramaUygun = arama.isEmpty || metin.contains(arama);
      final durumUygun = _durumFiltresi == 'tum' ||
          (_durumFiltresi == 'bekleyen'
              ? durum != 'odendi' && durum != 'iptal'
              : durum == _durumFiltresi);
      return aramaUygun && durumUygun;
    }).toList();
    result.sort((a, b) {
      final aDate = _parseDate(a['odeme_tarihi']) ?? DateTime(2100);
      final bDate = _parseDate(b['odeme_tarihi']) ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });
    return result;
  }

  Future<void> _odemeKaydet(Map<String, dynamic> data, {String? id}) async {
    final kayit = {
      ...data,
      'firma_id': TenantManager.instance.requireFirmaId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (id == null) {
      kayit['created_at'] = DateTime.now().toIso8601String();
      await _supabase.from(DbTables.yapilacakOdemeler).insert(kayit);
    } else {
      await _supabase
          .from(DbTables.yapilacakOdemeler)
          .update(kayit)
          .eq('id', id)
          .eq('firma_id', TenantManager.instance.requireFirmaId);
    }
    await _odemeleriYukle();
  }

  Future<void> _durumGuncelle(Map<String, dynamic> odeme, String durum) async {
    try {
      await _supabase
          .from(DbTables.yapilacakOdemeler)
          .update({
            'durum': durum,
            'odendi_tarihi': durum == 'odendi'
                ? DateTime.now().toIso8601String().split('T').first
                : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', odeme['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);
      if (durum == 'odendi') {
        await _sonrakiDuzenliOdemeyiOlustur(odeme);
      }
      await _odemeleriYukle();
      if (mounted) context.showSuccessSnackBar('Ödeme durumu güncellendi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Durum güncellenemedi: $e');
    }
  }

  Future<void> _sonrakiDuzenliOdemeyiOlustur(
    Map<String, dynamic> odeme,
  ) async {
    if (odeme['odeme_turu']?.toString() != 'duzenli') return;

    final oncekiTarih = _parseDate(odeme['odeme_tarihi']);
    final tekrarTipi = odeme['tekrar_tipi']?.toString();
    if (oncekiTarih == null || tekrarTipi == null || tekrarTipi.isEmpty) {
      return;
    }

    final sonrakiTarih = _sonrakiOdemeTarihi(oncekiTarih, tekrarTipi);
    if (sonrakiTarih == null) return;

    final firmaId = TenantManager.instance.requireFirmaId;
    final sonrakiTarihText = sonrakiTarih.toIso8601String().split('T').first;
    final mevcut = await _supabase
        .from(DbTables.yapilacakOdemeler)
        .select('id')
        .eq('firma_id', firmaId)
        .eq('baslik', odeme['baslik'])
        .eq('tutar', odeme['tutar'])
        .eq('para_birimi', odeme['para_birimi'] ?? 'TRY')
        .eq('odeme_tarihi', sonrakiTarihText)
        .limit(1);
    if (List<Map<String, dynamic>>.from(mevcut).isNotEmpty) return;

    await _supabase.from(DbTables.yapilacakOdemeler).insert({
      'firma_id': firmaId,
      'baslik': odeme['baslik'],
      'alici': odeme['alici'],
      'kategori': odeme['kategori'] ?? 'Genel',
      'tutar': odeme['tutar'],
      'para_birimi': odeme['para_birimi'] ?? 'TRY',
      'odeme_tarihi': sonrakiTarihText,
      'odeme_turu': 'duzenli',
      'tekrar_tipi': tekrarTipi,
      'durum': 'bekliyor',
      'notlar': odeme['notlar'],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _odemeSil(Map<String, dynamic> odeme) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeyi Sil'),
        content: Text(
          '"${odeme['baslik'] ?? '-'}" ödeme planı silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    try {
      await _supabase
          .from(DbTables.yapilacakOdemeler)
          .delete()
          .eq('id', odeme['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);
      await _odemeleriYukle();
      if (mounted) context.showSuccessSnackBar('Ödeme planı silindi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Ödeme silinemedi: $e');
    }
  }

  Future<void> _odemeDialog({Map<String, dynamic>? odeme}) async {
    final baslikController =
        TextEditingController(text: odeme?['baslik']?.toString() ?? '');
    final aliciController =
        TextEditingController(text: odeme?['alici']?.toString() ?? '');
    final tutarController = TextEditingController(
      text: odeme == null ? '' : _num(odeme['tutar']).toStringAsFixed(2),
    );
    final notController =
        TextEditingController(text: odeme?['notlar']?.toString() ?? '');
    final kategoriController =
        TextEditingController(text: odeme?['kategori']?.toString() ?? 'Genel');
    var paraBirimi = odeme?['para_birimi']?.toString() ?? 'TRY';
    var odemeTuru = odeme?['odeme_turu']?.toString() ?? 'tek_seferlik';
    var tekrarTipi = odeme?['tekrar_tipi']?.toString() ?? 'aylik';
    var durum = odeme?['durum']?.toString() ?? 'bekliyor';
    var odemeTarihi = _parseDate(odeme?['odeme_tarihi']) ?? DateTime.now();

    final kayit = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(odeme == null ? 'Yeni Ödeme Planı' : 'Ödeme Planı Düzenle'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: baslikController,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme başlığı *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aliciController,
                    decoration: const InputDecoration(
                      labelText: 'Alıcı / firma',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: tutarController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Tutar *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paraBirimi,
                          decoration: const InputDecoration(
                            labelText: 'Para',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => paraBirimi = v ?? 'TRY'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ödeme tarihi'),
                    subtitle: Text(_dateFormat.format(odemeTarihi)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final secilen = await showDatePicker(
                        context: context,
                        initialDate: odemeTarihi,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (secilen != null) {
                        setDialogState(() => odemeTarihi = secilen);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: odemeTuru,
                          decoration: const InputDecoration(
                            labelText: 'Ödeme türü',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'tek_seferlik',
                              child: Text('Tek seferlik'),
                            ),
                            DropdownMenuItem(
                              value: 'duzenli',
                              child: Text('Düzenli'),
                            ),
                          ],
                          onChanged: (v) => setDialogState(
                            () => odemeTuru = v ?? 'tek_seferlik',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: tekrarTipi,
                          decoration: const InputDecoration(
                            labelText: 'Tekrar',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'haftalik', child: Text('Haftalık')),
                            DropdownMenuItem(
                                value: 'aylik', child: Text('Aylık')),
                            DropdownMenuItem(
                                value: 'yillik', child: Text('Yıllık')),
                          ],
                          onChanged: odemeTuru == 'duzenli'
                              ? (v) => setDialogState(
                                    () => tekrarTipi = v ?? 'aylik',
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: kategoriController,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: durum,
                          decoration: const InputDecoration(
                            labelText: 'Durum',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'bekliyor', child: Text('Bekliyor')),
                            DropdownMenuItem(
                                value: 'odendi', child: Text('Ödendi')),
                            DropdownMenuItem(
                                value: 'iptal', child: Text('İptal')),
                          ],
                          onChanged: (v) =>
                              setDialogState(() => durum = v ?? 'bekliyor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notlar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final tutar = _parseDecimal(tutarController.text);
                if (baslikController.text.trim().isEmpty ||
                    tutar == null ||
                    tutar <= 0) {
                  context.showErrorSnackBar('Başlık ve geçerli tutar zorunlu');
                  return;
                }
                Navigator.pop(dialogContext, {
                  'baslik': baslikController.text.trim(),
                  'alici': aliciController.text.trim().isEmpty
                      ? null
                      : aliciController.text.trim(),
                  'tutar': tutar,
                  'para_birimi': paraBirimi,
                  'odeme_tarihi':
                      odemeTarihi.toIso8601String().split('T').first,
                  'odeme_turu': odemeTuru,
                  'tekrar_tipi': odemeTuru == 'duzenli' ? tekrarTipi : null,
                  'kategori': kategoriController.text.trim().isEmpty
                      ? 'Genel'
                      : kategoriController.text.trim(),
                  'durum': durum,
                  'notlar': notController.text.trim().isEmpty
                      ? null
                      : notController.text.trim(),
                  'odendi_tarihi': durum == 'odendi'
                      ? DateTime.now().toIso8601String().split('T').first
                      : null,
                });
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    baslikController.dispose();
    aliciController.dispose();
    tutarController.dispose();
    notController.dispose();
    kategoriController.dispose();

    if (kayit == null) return;
    try {
      await _odemeKaydet(kayit, id: odeme?['id']?.toString());
      if (mounted) context.showSuccessSnackBar('Ödeme planı kaydedildi');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Ödeme kaydedilemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final liste = _filtreliOdemeler;
    final bekleyenToplam = _odemeler
        .where((o) => o['durum'] != 'odendi' && o['durum'] != 'iptal')
        .fold<double>(0, (sum, o) => sum + _num(o['tutar']));
    final geciken = _odemeler.where(_gecikmisMi).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Yapılacak Ödemeler'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _odemeleriYukle,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _odemeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ödeme'),
      ),
      body: _yukleniyor
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: _odemeleriYukle,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummary(bekleyenToplam, geciken),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 12),
                  if (liste.isEmpty)
                    _panel(
                      child: const SizedBox(
                        height: 180,
                        child: Center(child: Text('Ödeme planı bulunamadı')),
                      ),
                    )
                  else
                    ...liste.map(_buildOdemeCard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary(double bekleyenToplam, int geciken) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final cards = [
          _summaryCard(
              'Bekleyen Toplam',
              '${_moneyFormat.format(bekleyenToplam)} TRY',
              Icons.payments_outlined,
              const Color(0xFF2563EB)),
          _summaryCard('Planlı Ödeme', _odemeler.length.toString(),
              Icons.event_note_outlined, const Color(0xFF0F766E)),
          _summaryCard('Geciken', geciken.toString(),
              Icons.warning_amber_outlined, const Color(0xFFDC2626)),
        ];
        if (compact) {
          return Column(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: card,
                    ))
                .toList(),
          );
        }
        return Row(children: cards.map((c) => Expanded(child: c)).toList());
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return _panel(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _aramaController,
              decoration: const InputDecoration(
                labelText: 'Başlık, alıcı, kategori veya not ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _arama = v),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: _durumFiltresi,
              decoration: const InputDecoration(
                labelText: 'Durum',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'bekleyen', child: Text('Bekleyen')),
                DropdownMenuItem(value: 'odendi', child: Text('Ödendi')),
                DropdownMenuItem(value: 'iptal', child: Text('İptal')),
                DropdownMenuItem(value: 'tum', child: Text('Tümü')),
              ],
              onChanged: (v) =>
                  setState(() => _durumFiltresi = v ?? 'bekleyen'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdemeCard(Map<String, dynamic> odeme) {
    final tarih = _parseDate(odeme['odeme_tarihi']);
    final durum = odeme['durum']?.toString() ?? 'bekliyor';
    final gecikmis = _gecikmisMi(odeme);
    final color = _durumRengi(gecikmis ? 'gecikti' : durum);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gecikmis ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
          width: gecikmis ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                odeme['baslik']?.toString() ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  odeme['alici']?.toString(),
                  odeme['kategori']?.toString(),
                ].where((e) => e != null && e.trim().isNotEmpty).join(' | '),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          );
          final detailWidgets = [
            _infoBlock(
              'Tarih',
              tarih == null ? '-' : _dateFormat.format(tarih),
              Icons.calendar_today_outlined,
            ),
            _infoBlock(
              'Tutar',
              '${_moneyFormat.format(_num(odeme['tutar']))} ${odeme['para_birimi'] ?? 'TRY'}',
              Icons.payments_outlined,
            ),
            _chip(
              gecikmis ? 'Gecikti' : _durumMetni(durum),
              color,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (durum != 'odendi' && durum != 'iptal')
                  IconButton(
                    tooltip: 'Ödendi işaretle',
                    onPressed: () => _durumGuncelle(odeme, 'odendi'),
                    icon: const Icon(Icons.check_circle_outline),
                    color: const Color(0xFF16A34A),
                  ),
                IconButton(
                  tooltip: 'Düzenle',
                  onPressed: () => _odemeDialog(odeme: odeme),
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF2563EB),
                ),
                IconButton(
                  tooltip: 'Sil',
                  onPressed: () => _odemeSil(odeme),
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 10, children: detailWidgets),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: titleBlock),
              ...detailWidgets.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: w,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoBlock(String label, String value, IconData icon) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  bool _gecikmisMi(Map<String, dynamic> odeme) {
    final durum = odeme['durum']?.toString() ?? 'bekliyor';
    if (durum == 'odendi' || durum == 'iptal') return false;
    final tarih = _parseDate(odeme['odeme_tarihi']);
    if (tarih == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tarih.isBefore(today);
  }

  String _durumMetni(String durum) {
    switch (durum) {
      case 'odendi':
        return 'Ödendi';
      case 'iptal':
        return 'İptal';
      default:
        return 'Bekliyor';
    }
  }

  Color _durumRengi(String durum) {
    switch (durum) {
      case 'odendi':
        return const Color(0xFF16A34A);
      case 'iptal':
        return const Color(0xFF64748B);
      case 'gecikti':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFD97706);
    }
  }

  DateTime? _sonrakiOdemeTarihi(DateTime tarih, String tekrarTipi) {
    switch (tekrarTipi) {
      case 'haftalik':
        return tarih.add(const Duration(days: 7));
      case 'aylik':
        return _ayEkle(tarih, 1);
      case 'yillik':
        return _ayEkle(tarih, 12);
      default:
        return null;
    }
  }

  DateTime _ayEkle(DateTime tarih, int aySayisi) {
    final hedefAyIndex = tarih.month - 1 + aySayisi;
    final hedefYil = tarih.year + hedefAyIndex ~/ 12;
    final hedefAy = hedefAyIndex % 12 + 1;
    final hedefAySonGunu = DateTime(hedefYil, hedefAy + 1, 0).day;
    final hedefGun = tarih.day > hedefAySonGunu ? hedefAySonGunu : tarih.day;
    return DateTime(hedefYil, hedefAy, hedefGun);
  }

  DateTime? _parseDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  double? _parseDecimal(String value) {
    final text = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }
}
