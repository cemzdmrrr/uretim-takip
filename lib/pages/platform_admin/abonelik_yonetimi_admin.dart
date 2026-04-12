import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';
import 'package:intl/intl.dart';

/// Platform Admin - Abonelik Takip ve Müdahale Sayfası.
class AbonelikYonetimiAdminPage extends StatefulWidget {
  const AbonelikYonetimiAdminPage({super.key});

  @override
  State<AbonelikYonetimiAdminPage> createState() =>
      _AbonelikYonetimiAdminPageState();
}

class _AbonelikYonetimiAdminPageState extends State<AbonelikYonetimiAdminPage> {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _abonelikler = [];
  String? _durumFiltre;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      _abonelikler = await PlatformAdminService.tumAbonelikleriGetir();

      if (_durumFiltre != null) {
        _abonelikler = _abonelikler
            .where((a) => a['durum'] == _durumFiltre)
            .toList();
      }
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
        title: const Text('Abonelik Yönetimi'),
        backgroundColor: const Color(0xFF00695C),
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
                : _abonelikler.isEmpty
                    ? const Center(child: Text('Abonelik bulunamadı'))
                    : _buildAbonelikListesi(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreler() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filtreChip(null, 'Tümü'),
            _filtreChip('aktif', 'Aktif'),
            _filtreChip('deneme', 'Deneme'),
            _filtreChip('pasif', 'Pasif'),
            _filtreChip('iptal', 'İptal'),
            _filtreChip('odeme_bekleniyor', 'Ödeme Bekleniyor'),
          ],
        ),
      ),
    );
  }

  Widget _filtreChip(String? durum, String etiket) {
    final secili = _durumFiltre == durum;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(etiket),
        selected: secili,
        onSelected: (_) {
          setState(() => _durumFiltre = durum);
          _verileriYukle();
        },
      ),
    );
  }

  Widget _buildAbonelikListesi() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _abonelikler.length,
      itemBuilder: (context, index) {
        final a = _abonelikler[index];
        final durum = a['durum']?.toString() ?? '-';
        final firmaAdi =
            a['firmalar']?['firma_adi']?.toString() ?? '-';
        final planAdi =
            a['abonelik_planlari']?['plan_adi']?.toString() ?? '-';
        final planKodu =
            a['abonelik_planlari']?['plan_kodu']?.toString() ?? '';
        final aylikUcret =
            a['abonelik_planlari']?['aylik_ucret'];
        final denemeBitis = a['deneme_bitis']?.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        firmaAdi,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _durumChip(durum),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniInfo(Icons.card_membership, '$planAdi ($planKodu)'),
                    if (aylikUcret != null)
                      _miniInfo(Icons.monetization_on,
                          '₺${(aylikUcret as num).toStringAsFixed(0)}/ay'),
                    if (durum == 'deneme' && denemeBitis != null) ...[
                      _miniInfo(
                        Icons.hourglass_bottom,
                        'Deneme bitiş: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(denemeBitis))}',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (durum != 'aktif')
                      TextButton.icon(
                        onPressed: () =>
                            _durumDegistir(a['id'] as String, 'aktif'),
                        icon: const Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                        label: const Text('Aktif Yap',
                            style: TextStyle(fontSize: 12)),
                      ),
                    if (durum != 'pasif' && durum != 'iptal')
                      TextButton.icon(
                        onPressed: () =>
                            _durumDegistir(a['id'] as String, 'pasif'),
                        icon: const Icon(Icons.pause_circle,
                            size: 16, color: Colors.orange),
                        label: const Text('Duraklat',
                            style: TextStyle(fontSize: 12)),
                      ),
                    if (durum != 'iptal')
                      TextButton.icon(
                        onPressed: () =>
                            _durumDegistir(a['id'] as String, 'iptal'),
                        icon: const Icon(Icons.cancel,
                            size: 16, color: Colors.red),
                        label: const Text('İptal Et',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _durumChip(String durum) {
    Color renk;
    switch (durum) {
      case 'aktif':
        renk = Colors.green;
        break;
      case 'deneme':
        renk = Colors.orange;
        break;
      case 'pasif':
        renk = Colors.grey;
        break;
      case 'iptal':
        renk = Colors.red;
        break;
      case 'odeme_bekleniyor':
        renk = Colors.blue;
        break;
      default:
        renk = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withAlpha(75)),
      ),
      child: Text(
        durum,
        style: TextStyle(
          fontSize: 12,
          color: renk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniInfo(IconData ikon, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _durumDegistir(String abonelikId, String yeniDurum) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abonelik Durumu Değiştir'),
        content:
            Text('Abonelik durumu "$yeniDurum" olarak değiştirilecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      await PlatformAdminService.abonelikDurumGuncelle(
          abonelikId, yeniDurum);
      await _verileriYukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abonelik durumu güncellendi: $yeniDurum')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
