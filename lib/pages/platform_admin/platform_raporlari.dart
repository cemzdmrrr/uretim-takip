import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class PlatformRaporlari extends StatefulWidget {
  const PlatformRaporlari({super.key});

  @override
  State<PlatformRaporlari> createState() => _PlatformRaporlariState();
}

class _PlatformRaporlariState extends State<PlatformRaporlari>
    with SingleTickerProviderStateMixin {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _aylikGelir = [];
  List<Map<String, dynamic>> _kayitTrendi = [];
  List<Map<String, dynamic>> _abonelikDagilimi = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verileriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final sonuclar = await Future.wait([
        PlatformAdminService.aylikGelirRaporu(),
        PlatformAdminService.yeniKayitTrendi(),
        PlatformAdminService.abonelikDagilimi(),
      ]);

      if (!mounted) return;
      setState(() {
        _aylikGelir = List<Map<String, dynamic>>.from(sonuclar[0]);
        _kayitTrendi = List<Map<String, dynamic>>.from(sonuclar[1]);
        _abonelikDagilimi = List<Map<String, dynamic>>.from(sonuclar[2]);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Raporlar yuklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Platform Raporlari'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(text: 'Gelir', icon: Icon(Icons.monetization_on, size: 18)),
            Tab(text: 'Kayit Trendi', icon: Icon(Icons.trending_up, size: 18)),
            Tab(text: 'Abonelik', icon: Icon(Icons.pie_chart, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGelirRaporu(),
                _buildKayitTrendi(),
                _buildAbonelikDagilimi(),
              ],
            ),
    );
  }

  Widget _buildGelirRaporu() {
    if (_aylikGelir.isEmpty) {
      return const Center(child: Text('Henuz gelir verisi yok'));
    }

    final toplamGelir = _aylikGelir.fold<double>(
      0.0,
      (toplam, kayit) => toplam + ((kayit['gelir'] as num?)?.toDouble() ?? 0),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            width >= 1000 ? 24 : 16,
            16,
            width >= 1000 ? 24 : 16,
            32,
          ),
          children: [
            _buildHighlightCard(
              title: 'Son 12 Ay Toplam Gelir',
              value: '₺${toplamGelir.toStringAsFixed(0)}',
              color: const Color(0xFF2E7D32),
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 16),
            _buildBarPanel(
              title: 'Aylik Gelir Detayi',
              color: const Color(0xFF2E7D32),
              values: _aylikGelir
                  .map(
                    (kayit) => _BarItem(
                      label: kayit['ay']?.toString() ?? '-',
                      value: ((kayit['gelir'] as num?)?.toDouble() ?? 0),
                      trailing:
                          '₺${((kayit['gelir'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKayitTrendi() {
    if (_kayitTrendi.isEmpty) {
      return const Center(child: Text('Henuz kayit verisi yok'));
    }

    final toplamKayit = _kayitTrendi.fold<int>(
      0,
      (toplam, kayit) => toplam + ((kayit['kayit_sayisi'] as int?) ?? 0),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            width >= 1000 ? 24 : 16,
            16,
            width >= 1000 ? 24 : 16,
            32,
          ),
          children: [
            _buildHighlightCard(
              title: 'Son 12 Ay Yeni Firma Kaydi',
              value: '$toplamKayit',
              color: const Color(0xFF1565C0),
              icon: Icons.domain_add,
            ),
            const SizedBox(height: 16),
            _buildBarPanel(
              title: 'Aylik Kayit Detayi',
              color: const Color(0xFF1565C0),
              values: _kayitTrendi
                  .map(
                    (kayit) => _BarItem(
                      label: kayit['ay']?.toString() ?? '-',
                      value: ((kayit['kayit_sayisi'] as int?) ?? 0).toDouble(),
                      trailing: '${kayit['kayit_sayisi'] ?? 0}',
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAbonelikDagilimi() {
    if (_abonelikDagilimi.isEmpty) {
      return const Center(child: Text('Henuz abonelik verisi yok'));
    }

    final planSayac = <String, int>{};
    final durumSayac = <String, int>{};

    for (final kayit in _abonelikDagilimi) {
      final planAdi =
          kayit['abonelik_planlari']?['plan_adi']?.toString() ?? 'Bilinmeyen';
      planSayac[planAdi] = (planSayac[planAdi] ?? 0) + 1;

      final durum = kayit['durum']?.toString() ?? 'bilinmeyen';
      durumSayac[durum] = (durumSayac[durum] ?? 0) + 1;
    }

    final planSirali = planSayac.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final panelWidth = width >= 1180 ? (width - 16) / 2 : double.infinity;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            width >= 1000 ? 24 : 16,
            16,
            width >= 1000 ? 24 : 16,
            32,
          ),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: panelWidth,
                  child: _buildStatusPanel(durumSayac),
                ),
                SizedBox(
                  width: panelWidth,
                  child: _buildPlanPanel(planSirali, _abonelikDagilimi.length),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(230), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
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

  Widget _buildBarPanel({
    required String title,
    required Color color,
    required List<_BarItem> values,
  }) {
    final maxValue = values.fold<double>(
      1,
      (mevcut, item) => mevcut > item.value ? mevcut : item.value,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
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
          const SizedBox(height: 12),
          ...values.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: maxValue > 0 ? item.value / maxValue : 0,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 84,
                    child: Text(
                      item.trailing,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusPanel(Map<String, int> durumSayac) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durum Dagilimi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...durumSayac.entries.map((girdi) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _durumRenk(girdi.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      girdi.key,
                      style: const TextStyle(color: Color(0xFF334155)),
                    ),
                  ),
                  Text(
                    '${girdi.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlanPanel(List<MapEntry<String, int>> planSirali, int toplam) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Dagilimi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...planSirali.map((girdi) {
            final oran = toplam > 0 ? girdi.value / toplam : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          girdi.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        '${girdi.value} (%${(oran * 100).toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: oran,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: const Color(0xFF6A1B9A),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'aktif':
        return Colors.green;
      case 'deneme':
        return Colors.orange;
      case 'pasif':
        return Colors.grey;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class _BarItem {
  final String label;
  final double value;
  final String trailing;

  const _BarItem({
    required this.label,
    required this.value,
    required this.trailing,
  });
}
