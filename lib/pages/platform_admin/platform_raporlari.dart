import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

/// Platform Admin - Platform Raporları ve Gelir Analizi Sayfası.
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

      setState(() {
        _aylikGelir = sonuclar[0];
        _kayitTrendi = sonuclar[1];
        _abonelikDagilimi = sonuclar[2];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Raporları'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Gelir', icon: Icon(Icons.monetization_on, size: 18)),
            Tab(
                text: 'Kayıt Trendi',
                icon: Icon(Icons.trending_up, size: 18)),
            Tab(
                text: 'Abonelik Dağılımı',
                icon: Icon(Icons.pie_chart, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
      return const Center(child: Text('Henüz gelir verisi yok'));
    }

    final toplamGelir = _aylikGelir.fold<double>(
        0.0, (t, e) => t + ((e['gelir'] as num?)?.toDouble() ?? 0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Toplam gelir kartı
        Card(
          color: const Color(0xFF2E7D32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Son 12 Ay Toplam Gelir',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '₺${toplamGelir.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Aylık gelir detayı
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aylık Gelir Detayı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ..._aylikGelir.map((g) {
                  final ay = g['ay']?.toString() ?? '';
                  final gelir = (g['gelir'] as num?)?.toDouble() ?? 0;
                  final maxGelir = _aylikGelir.fold<double>(
                      1.0,
                      (m, e) =>
                          m >
                                  ((e['gelir'] as num?)?.toDouble() ?? 0)
                              ? m
                              : (e['gelir'] as num?)?.toDouble() ?? 0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            ay,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: maxGelir > 0 ? gelir / maxGelir : 0,
                            backgroundColor: Colors.grey[200],
                            color: const Color(0xFF2E7D32),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '₺${gelir.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKayitTrendi() {
    if (_kayitTrendi.isEmpty) {
      return const Center(child: Text('Henüz kayıt verisi yok'));
    }

    final toplamKayit = _kayitTrendi.fold<int>(
        0, (t, e) => t + ((e['kayit_sayisi'] as int?) ?? 0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1565C0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Son 12 Ay Yeni Firma Kayıtları',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '$toplamKayit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aylık Kayıt Detayı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ..._kayitTrendi.map((k) {
                  final ay = k['ay']?.toString() ?? '';
                  final sayi = (k['kayit_sayisi'] as int?) ?? 0;
                  final maxSayi = _kayitTrendi.fold<int>(
                      1,
                      (m, e) => m > ((e['kayit_sayisi'] as int?) ?? 0)
                          ? m
                          : (e['kayit_sayisi'] as int?) ?? 0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            ay,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: maxSayi > 0 ? sayi / maxSayi : 0,
                            backgroundColor: Colors.grey[200],
                            color: const Color(0xFF1565C0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '$sayi',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbonelikDagilimi() {
    if (_abonelikDagilimi.isEmpty) {
      return const Center(child: Text('Henüz abonelik verisi yok'));
    }

    // Plan bazlı gruplama
    final planSayac = <String, int>{};
    final durumSayac = <String, int>{};
    for (final a in _abonelikDagilimi) {
      final planAdi =
          a['abonelik_planlari']?['plan_adi']?.toString() ?? 'Bilinmeyen';
      planSayac[planAdi] = (planSayac[planAdi] ?? 0) + 1;

      final durum = a['durum']?.toString() ?? 'bilinmeyen';
      durumSayac[durum] = (durumSayac[durum] ?? 0) + 1;
    }

    final planSirali = planSayac.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final toplam = _abonelikDagilimi.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Durum Dağılımı
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Durum Dağılımı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ...durumSayac.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _durumRenk(e.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key)),
                        Text(
                          '${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Plan Dağılımı
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan Dağılımı',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                ...planSirali.map((e) {
                  final oran = toplam > 0 ? e.value / toplam : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${e.value} (%${(oran * 100).toStringAsFixed(0)})',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: oran,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF6A1B9A),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
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
