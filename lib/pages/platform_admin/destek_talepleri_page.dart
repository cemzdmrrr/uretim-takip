import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class DestekTalepleriPage extends StatefulWidget {
  const DestekTalepleriPage({super.key});

  @override
  State<DestekTalepleriPage> createState() => _DestekTalepleriPageState();
}

class _DestekTalepleriPageState extends State<DestekTalepleriPage> {
  static const _durumlar = <String?>[
    null,
    'acik',
    'inceleniyor',
    'cevaplandi',
    'kapali'
  ];

  bool _yukleniyor = true;
  bool _islemSuruyor = false;
  String? _durumFiltre;
  List<Map<String, dynamic>> _talepler = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    if (mounted) {
      setState(() => _yukleniyor = true);
    }
    try {
      _talepler = await PlatformAdminService.destekTalepleriGetir(
        durumFiltre: _durumFiltre,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Destek Talepleri'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _verileriYukle,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHero(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _panelDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilter(),
                        const SizedBox(height: 12),
                        Text(
                          '${_talepler.length} talep listeleniyor',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_talepler.isEmpty)
                    _buildEmptyState()
                  else
                    ..._talepler.map(_buildTalepCard),
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    final acik = _talepler.where((item) => item['durum'] == 'acik').length;
    final inceleniyor =
        _talepler.where((item) => item['durum'] == 'inceleniyor').length;
    final cevaplandi =
        _talepler.where((item) => item['durum'] == 'cevaplandi').length;
    final acil = _talepler.where((item) => item['oncelik'] == 'acil').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Operasyon görünümü',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Açık destek yükünü, yanıt trafiğini ve kritik talepleri tek akışta izleyin.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _heroStat('Açık', '$acik', Icons.mark_email_unread_outlined),
              _heroStat('İnceleniyor', '$inceleniyor', Icons.search_outlined),
              _heroStat('Cevaplandı', '$cevaplandi', Icons.reply_outlined),
              _heroStat('Acil öncelik', '$acil', Icons.priority_high_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    final seciliIndex = _durumlar.indexOf(_durumFiltre);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Tümü')),
          ButtonSegment(value: 1, label: Text('Açık')),
          ButtonSegment(value: 2, label: Text('İnceleniyor')),
          ButtonSegment(value: 3, label: Text('Cevaplandı')),
          ButtonSegment(value: 4, label: Text('Kapalı')),
        ],
        selected: {seciliIndex < 0 ? 0 : seciliIndex},
        onSelectionChanged: (selection) {
          setState(() => _durumFiltre = _durumlar[selection.first]);
          _verileriYukle();
        },
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildTalepCard(Map<String, dynamic> item) {
    final firmaData = item['firmalar'];
    final firmaAdi =
        firmaData is Map ? firmaData['firma_adi']?.toString() ?? '-' : '-';
    final konu = item['konu']?.toString() ?? '-';
    final mesaj = item['mesaj']?.toString() ?? '';
    final kategori = item['kategori']?.toString() ?? 'genel';
    final durum = item['durum']?.toString() ?? 'acik';
    final oncelik = item['oncelik']?.toString() ?? 'normal';
    final cevap = item['cevap']?.toString();
    final tarih = _formatDate(item['created_at']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _panelDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _islemSuruyor ? null : () => _talepDetay(item),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _oncelikRenk(oncelik),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                konu,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _durumChip(durum),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mesaj,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _infoChip(Icons.business_outlined, 'Firma', firmaAdi),
                  _infoChip(Icons.category_outlined, 'Kategori', kategori),
                  _infoChip(
                      Icons.flag_outlined, 'Öncelik', _oncelikEtiketi(oncelik)),
                  _infoChip(Icons.schedule_outlined, 'Tarih', tarih),
                  if (cevap != null && cevap.isNotEmpty)
                    _infoChip(Icons.reply_outlined, 'Yanıt', 'Mevcut'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _panelDecoration(),
      child: const Column(
        children: [
          Icon(Icons.support_agent_outlined,
              size: 42, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Seçili filtrede destek talebi bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Filtreyi değiştirin veya yeni kayıtları kontrol edin.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Future<void> _talepDetay(Map<String, dynamic> talep) async {
    final cevapController =
        TextEditingController(text: talep['cevap']?.toString() ?? '');
    final talepId = talep['id'] as String;
    final durum = talep['durum']?.toString() ?? 'acik';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(talep['konu']?.toString() ?? 'Destek talebi'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogSection(
                  'Talep mesajı',
                  talep['mesaj']?.toString() ?? '-',
                ),
                const SizedBox(height: 16),
                _dialogSection(
                  'Yanıt',
                  '',
                  child: TextField(
                    controller: cevapController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Yanıtı yazın',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (durum != 'kapali')
            TextButton(
              onPressed: _islemSuruyor
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      await _destegiKapat(talepId);
                    },
              child: const Text('Talebi kapat'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton.icon(
            onPressed: _islemSuruyor || durum == 'kapali'
                ? null
                : () async {
                    final cevap = cevapController.text.trim();
                    if (cevap.isEmpty) return;
                    Navigator.of(ctx).pop();
                    await _cevapGonder(talepId, cevap);
                  },
            icon: const Icon(Icons.reply_outlined),
            label: const Text('Yanıtla'),
          ),
        ],
      ),
    );

    cevapController.dispose();
  }

  Future<void> _cevapGonder(String talepId, String cevap) async {
    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.destekCevapla(talepId, cevap);
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destek talebi yanıtlandı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Future<void> _destegiKapat(String talepId) async {
    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.destekKapat(talepId);
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destek talebi kapatıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Widget _dialogSection(String title, String value, {Widget? child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        if (child != null)
          child
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(value),
          ),
      ],
    );
  }

  Widget _durumChip(String durum) {
    final renk = _durumRenk(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: renk.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: renk.withAlpha(60)),
      ),
      child: Text(
        _durumEtiketi(durum),
        style: TextStyle(
          color: renk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'acik':
        return const Color(0xFF2563EB);
      case 'inceleniyor':
        return const Color(0xFFD97706);
      case 'cevaplandi':
        return const Color(0xFF15803D);
      case 'kapali':
      default:
        return const Color(0xFF64748B);
    }
  }

  String _durumEtiketi(String durum) {
    switch (durum) {
      case 'acik':
        return 'Açık';
      case 'inceleniyor':
        return 'İnceleniyor';
      case 'cevaplandi':
        return 'Cevaplandı';
      case 'kapali':
        return 'Kapalı';
      default:
        return durum;
    }
  }

  Color _oncelikRenk(String oncelik) {
    switch (oncelik) {
      case 'acil':
        return const Color(0xFFDC2626);
      case 'yuksek':
        return const Color(0xFFEA580C);
      case 'dusuk':
        return const Color(0xFF64748B);
      case 'normal':
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _oncelikEtiketi(String oncelik) {
    switch (oncelik) {
      case 'acil':
        return 'Acil';
      case 'yuksek':
        return 'Yüksek';
      case 'dusuk':
        return 'Düşük';
      case 'normal':
      default:
        return 'Normal';
    }
  }
}
