import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/pages/abonelik/abonelik_plan_fiyat_yonetimi_page.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class AbonelikYonetimiAdminPage extends StatefulWidget {
  const AbonelikYonetimiAdminPage({super.key});

  @override
  State<AbonelikYonetimiAdminPage> createState() =>
      _AbonelikYonetimiAdminPageState();
}

class _AbonelikYonetimiAdminPageState extends State<AbonelikYonetimiAdminPage> {
  static const _durumlar = <String?>[
    null,
    'aktif',
    'deneme',
    'odeme_bekleniyor',
    'pasif',
    'iptal',
  ];

  bool _yukleniyor = true;
  bool _islemSuruyor = false;
  String? _durumFiltre;
  List<Map<String, dynamic>> _tumAbonelikler = [];

  List<Map<String, dynamic>> get _abonelikler {
    if (_durumFiltre == null) {
      return _tumAbonelikler;
    }
    return _tumAbonelikler
        .where((item) => item['durum']?.toString() == _durumFiltre)
        .toList();
  }

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
      _tumAbonelikler = await PlatformAdminService.tumAbonelikleriGetir();
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

  Future<void> _durumDegistir(String abonelikId, String durum) async {
    if (_islemSuruyor) return;

    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.abonelikDurumGuncelle(abonelikId, durum);
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Abonelik durumu güncellendi: ${_durumEtiketi(durum)}')),
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

  @override
  Widget build(BuildContext context) {
    final seciliIndex = _durumlar.indexOf(_durumFiltre);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Abonelik Yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Plan fiyatları',
            icon: const Icon(Icons.sell_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AbonelikPlanFiyatYonetimiPage(),
                ),
              );
            },
          ),
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
                  _buildHero(theme),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _panelDecoration(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final dar = constraints.maxWidth < 720;
                        return dar
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSegmentedFilter(seciliIndex),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_abonelikler.length} kayıt',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                      child:
                                          _buildSegmentedFilter(seciliIndex)),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${_abonelikler.length} kayıt',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_abonelikler.isEmpty)
                    _buildEmptyState()
                  else
                    ..._abonelikler.map(_buildAbonelikCard),
                ],
              ),
            ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    final aktif =
        _tumAbonelikler.where((item) => item['durum'] == 'aktif').length;
    final deneme =
        _tumAbonelikler.where((item) => item['durum'] == 'deneme').length;
    final odemeBekleyen = _tumAbonelikler
        .where((item) => item['durum'] == 'odeme_bekleniyor')
        .length;
    final aylikToplam = _tumAbonelikler.fold<double>(0, (toplam, item) {
      final plan = item['abonelik_planlari'];
      if (plan is Map && plan['aylik_ucret'] is num) {
        return toplam + (plan['aylik_ucret'] as num).toDouble();
      }
      return toplam;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
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
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Platform abonelik akışı',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tüm firma planlarını, durumlarını ve tahsilat ritmini tek ekrandan yönetin.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _heroStat('Aktif abonelik', '$aktif', Icons.check_circle_outline),
              _heroStat('Deneme', '$deneme', Icons.hourglass_bottom_outlined),
              _heroStat(
                  'Ödeme bekleyen', '$odemeBekleyen', Icons.schedule_outlined),
              _heroStat(
                'Plan toplamı',
                NumberFormat.currency(
                  locale: 'tr_TR',
                  symbol: '₺',
                  decimalDigits: 0,
                ).format(aylikToplam),
                Icons.payments_outlined,
              ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter(int seciliIndex) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Tümü')),
        ButtonSegment(value: 1, label: Text('Aktif')),
        ButtonSegment(value: 2, label: Text('Deneme')),
        ButtonSegment(value: 3, label: Text('Ödeme')),
        ButtonSegment(value: 4, label: Text('Pasif')),
        ButtonSegment(value: 5, label: Text('İptal')),
      ],
      selected: {seciliIndex < 0 ? 0 : seciliIndex},
      onSelectionChanged: (selection) {
        final index = selection.first;
        setState(() => _durumFiltre = _durumlar[index]);
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildAbonelikCard(Map<String, dynamic> item) {
    final firma = item['firmalar'];
    final plan = item['abonelik_planlari'];
    final firmaAdi = firma is Map ? firma['firma_adi']?.toString() ?? '-' : '-';
    final firmaKodu = firma is Map ? firma['firma_kodu']?.toString() ?? '' : '';
    final planAdi = plan is Map ? plan['plan_adi']?.toString() ?? '-' : '-';
    final planKodu = plan is Map ? plan['plan_kodu']?.toString() ?? '-' : '-';
    final aylikUcret = plan is Map && plan['aylik_ucret'] is num
        ? plan['aylik_ucret'] as num
        : null;
    final durum = item['durum']?.toString() ?? '-';
    final periyot = item['odeme_periyodu']?.toString() ?? 'aylik';
    final denemeBitis = _formatDate(item['deneme_bitis']?.toString());
    final baslangic = _formatDate(item['baslangic_tarihi']?.toString());
    final sonrakiOdeme = _formatDate(item['sonraki_odeme_tarihi']?.toString());
    final paraFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final dar = constraints.maxWidth < 820;
              final header = [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              firmaAdi,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _durumChip(durum),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        firmaKodu.isEmpty ? planKodu : '$firmaKodu • $planKodu',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ];

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (durum != 'aktif')
                    _actionButton(
                      label: 'Aktif yap',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF15803D),
                      onPressed: _islemSuruyor
                          ? null
                          : () => _durumDegistir(item['id'] as String, 'aktif'),
                    ),
                  if (durum != 'pasif' && durum != 'iptal')
                    _actionButton(
                      label: 'Duraklat',
                      icon: Icons.pause_circle_outline,
                      color: const Color(0xFFB45309),
                      onPressed: _islemSuruyor
                          ? null
                          : () => _durumDegistir(item['id'] as String, 'pasif'),
                    ),
                  if (durum != 'iptal')
                    _actionButton(
                      label: 'İptal et',
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFB91C1C),
                      onPressed: _islemSuruyor
                          ? null
                          : () => _durumDegistir(item['id'] as String, 'iptal'),
                    ),
                ],
              );

              if (dar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...header,
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...header,
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: actions,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(Icons.layers_outlined, 'Plan', planAdi),
              if (aylikUcret != null)
                _infoChip(
                  Icons.payments_outlined,
                  'Aylık ücret',
                  paraFormat.format(aylikUcret),
                ),
              _infoChip(Icons.event_outlined, 'Başlangıç', baslangic),
              _infoChip(
                  Icons.repeat_outlined, 'Periyot', _periyotEtiketi(periyot)),
              if (sonrakiOdeme != '-')
                _infoChip(
                    Icons.schedule_outlined, 'Sonraki ödeme', sonrakiOdeme),
              if (durum == 'deneme' && denemeBitis != '-')
                _infoChip(Icons.hourglass_bottom_outlined, 'Deneme bitişi',
                    denemeBitis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _panelDecoration(),
      child: const Column(
        children: [
          Icon(Icons.subscriptions_outlined,
              size: 42, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Seçili filtrede abonelik bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Filtreyi değiştirin veya sayfayı yenileyin.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withAlpha(80)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
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
          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
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

  String _durumEtiketi(String durum) {
    switch (durum) {
      case 'aktif':
        return 'Aktif';
      case 'deneme':
        return 'Deneme';
      case 'odeme_bekleniyor':
        return 'Ödeme bekleniyor';
      case 'pasif':
        return 'Pasif';
      case 'iptal':
        return 'İptal';
      default:
        return durum;
    }
  }

  String _periyotEtiketi(String periyot) {
    switch (periyot) {
      case 'yillik':
        return 'Yıllık';
      case 'aylik':
      default:
        return 'Aylık';
    }
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'aktif':
        return const Color(0xFF15803D);
      case 'deneme':
        return const Color(0xFFD97706);
      case 'odeme_bekleniyor':
        return const Color(0xFF2563EB);
      case 'iptal':
        return const Color(0xFFB91C1C);
      case 'pasif':
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy').format(parsed);
  }
}
