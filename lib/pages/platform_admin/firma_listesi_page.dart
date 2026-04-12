import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';
import 'package:uretim_takip/pages/platform_admin/firma_detay_admin.dart';

/// Platform Admin - Tüm Firmaları Listeleme Sayfası.
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
      _firmalar = await PlatformAdminService.firmalariGetir(
        arama: _aramaController.text,
        sadecAktif: _aktifFiltre,
      );
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
        title: const Text('Firma Yönetimi'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                    ? const Center(child: Text('Firma bulunamadı'))
                    : _buildFirmaListesi(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreler() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aramaController,
              decoration: InputDecoration(
                hintText: 'Firma ara (ad veya kod)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
              ),
              onSubmitted: (_) => _verileriYukle(),
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Tümü')),
              ButtonSegment(value: true, label: Text('Aktif')),
              ButtonSegment(value: false, label: Text('Pasif')),
            ],
            selected: {_aktifFiltre},
            onSelectionChanged: (Set<bool?> secim) {
              setState(() => _aktifFiltre = secim.first);
              _verileriYukle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFirmaListesi() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _firmalar.length,
      itemBuilder: (context, index) {
        final firma = _firmalar[index];
        final aktif = firma['aktif'] == true;
        final abonelikDurum = firma['abonelik_durumu']?.toString() ?? '-';
        final planAdi = firma['plan_adi']?.toString() ?? '-';
        final kullaniciSayisi = firma['kullanici_sayisi'] ?? 0;
        final modulSayisi = firma['modul_sayisi'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: aktif ? Colors.green.withAlpha(75) : Colors.red.withAlpha(75),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: aktif
                  ? const Color(0xFF2E7D32).withAlpha(25)
                  : Colors.red.withAlpha(25),
              child: Icon(
                Icons.business,
                color: aktif ? const Color(0xFF2E7D32) : Colors.red,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    firma['firma_adi']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _abonelikRenk(abonelikDurum).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    abonelikDurum,
                    style: TextStyle(
                      fontSize: 11,
                      color: _abonelikRenk(abonelikDurum),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _miniChip(Icons.code, firma['firma_kodu']?.toString() ?? ''),
                  const SizedBox(width: 8),
                  _miniChip(Icons.card_membership, planAdi),
                  const SizedBox(width: 8),
                  _miniChip(Icons.people, '$kullaniciSayisi kullanıcı'),
                  const SizedBox(width: 8),
                  _miniChip(Icons.extension, '$modulSayisi modül'),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FirmaDetayAdminPage(firmaId: firma['id']?.toString() ?? ''),
                ),
              );
              _verileriYukle();
            },
          ),
        );
      },
    );
  }

  Widget _miniChip(IconData ikon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
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
