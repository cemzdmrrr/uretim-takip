import 'package:flutter/material.dart';
import 'package:uretim_takip/pages/platform_admin/firma_detay_admin.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class FirmaListesiPage extends StatefulWidget {
  const FirmaListesiPage({super.key});

  @override
  State<FirmaListesiPage> createState() => _FirmaListesiPageState();
}

class _FirmaListesiPageState extends State<FirmaListesiPage> {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _firmalar = [];
  final _aramaController = TextEditingController();
  bool? _aktifFiltre;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final sonuc = await PlatformAdminService.firmalariGetir(
        arama: _aramaController.text,
        sadecAktif: _aktifFiltre,
      );
      if (!mounted) return;
      setState(() => _firmalar = sonuc);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yuklenemedi: $e')),
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
        title: const Text('Firma Yonetimi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltreler(),
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _firmalar.isEmpty
                    ? const Center(child: Text('Firma bulunamadi'))
                    : _buildFirmaListesi(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreler() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final darEkran = constraints.maxWidth < 820;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: darEkran
              ? Column(
                  children: [
                    _buildAramaAlani(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildDurumSecici(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildAramaAlani()),
                    const SizedBox(width: 12),
                    _buildDurumSecici(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAramaAlani() {
    return TextField(
      controller: _aramaController,
      decoration: InputDecoration(
        hintText: 'Firma ara (ad veya kod)',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _aramaController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Temizle',
                onPressed: () {
                  _aramaController.clear();
                  _verileriYukle();
                },
                icon: const Icon(Icons.close),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _verileriYukle(),
    );
  }

  Widget _buildDurumSecici() {
    return SegmentedButton<bool?>(
      segments: const [
        ButtonSegment<bool?>(value: null, label: Text('Tumu')),
        ButtonSegment<bool?>(value: true, label: Text('Aktif')),
        ButtonSegment<bool?>(value: false, label: Text('Pasif')),
      ],
      selected: {_aktifFiltre},
      onSelectionChanged: (secim) {
        setState(() => _aktifFiltre = secim.first);
        _verileriYukle();
      },
    );
  }

  Widget _buildFirmaListesi() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _firmalar.length,
      itemBuilder: (context, index) {
        final firma = _firmalar[index];
        final aktif = firma['aktif'] == true;
        final firmaAdi = firma['firma_adi']?.toString() ?? '-';
        final firmaKodu = firma['firma_kodu']?.toString() ?? '-';
        final abonelikDurumu = firma['abonelik_durumu']?.toString() ?? '-';
        final planAdi = firma['plan_adi']?.toString() ?? '-';
        final kullaniciSayisi = firma['kullanici_sayisi'] ?? 0;
        final modulSayisi = firma['modul_sayisi'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: aktif
                  ? const Color(0xFF2E7D32).withAlpha(70)
                  : Colors.red.withAlpha(70),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final sonuc = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => FirmaDetayAdminPage(
                    firmaId: firma['id']?.toString() ?? '',
                  ),
                ),
              );
              if (!context.mounted) return;
              if (sonuc == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firma kalici olarak silindi'),
                  ),
                );
              }
              _verileriYukle();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: aktif
                            ? const Color(0xFF2E7D32).withAlpha(24)
                            : Colors.red.withAlpha(24),
                        child: Icon(
                          Icons.business,
                          color: aktif ? const Color(0xFF2E7D32) : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firmaAdi,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              firmaKodu,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(abonelikDurumu),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _miniChip(Icons.card_membership, planAdi),
                      _miniChip(Icons.people, '$kullaniciSayisi kullanici'),
                      _miniChip(Icons.extension, '$modulSayisi aktif modul'),
                      _miniChip(
                        aktif ? Icons.check_circle : Icons.cancel,
                        aktif ? 'Aktif' : 'Pasif',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String durum) {
    final renk = _abonelikRenk(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: renk.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        durum,
        style: TextStyle(
          color: renk,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniChip(IconData ikon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Color _abonelikRenk(String durum) {
    switch (durum) {
      case 'aktif':
        return const Color(0xFF2E7D32);
      case 'deneme':
        return const Color(0xFFE65100);
      case 'pasif':
      case 'iptal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
