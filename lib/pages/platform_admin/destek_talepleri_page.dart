import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';
import 'package:intl/intl.dart';

/// Platform Admin - Destek Talepleri Yönetimi Sayfası.
class DestekTalepleriPage extends StatefulWidget {
  const DestekTalepleriPage({super.key});

  @override
  State<DestekTalepleriPage> createState() => _DestekTalepleriPageState();
}

class _DestekTalepleriPageState extends State<DestekTalepleriPage> {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _talepler = [];
  String? _durumFiltre;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      _talepler = await PlatformAdminService.destekTalepleriGetir(
        durumFiltre: _durumFiltre,
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
        title: const Text('Destek Talepleri'),
        backgroundColor: const Color(0xFFC62828),
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
                : _talepler.isEmpty
                    ? const Center(child: Text('Destek talebi bulunamadı'))
                    : _buildTalepListesi(),
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
            _filtreChip('acik', 'Açık'),
            _filtreChip('inceleniyor', 'İnceleniyor'),
            _filtreChip('cevaplandi', 'Cevaplanmış'),
            _filtreChip('kapali', 'Kapalı'),
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
        selectedColor: const Color(0xFFC62828).withAlpha(30),
        onSelected: (_) {
          setState(() => _durumFiltre = durum);
          _verileriYukle();
        },
      ),
    );
  }

  Widget _buildTalepListesi() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _talepler.length,
      itemBuilder: (context, index) {
        final t = _talepler[index];
        final durum = t['durum']?.toString() ?? 'acik';
        final oncelik = t['oncelik']?.toString() ?? 'normal';
        final kategori = t['kategori']?.toString() ?? 'genel';
        final firmaAdi = t['firmalar']?['firma_adi']?.toString() ?? '-';
        final konu = t['konu']?.toString() ?? '';
        final mesaj = t['mesaj']?.toString() ?? '';
        final tarihStr = t['created_at']?.toString();
        final tarih = tarihStr != null
            ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(tarihStr))
            : '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _oncelikRenk(oncelik).withAlpha(75),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _talepDetay(t),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _oncelikBadge(oncelik),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          konu,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _durumChip(durum),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mesaj,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        firmaAdi,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Icon(Icons.label, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        kategori,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        tarih,
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _oncelikBadge(String oncelik) {
    return Container(
      width: 4,
      height: 32,
      decoration: BoxDecoration(
        color: _oncelikRenk(oncelik),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _durumChip(String durum) {
    Color renk;
    String etiket;
    switch (durum) {
      case 'acik':
        renk = Colors.blue;
        etiket = 'Açık';
        break;
      case 'inceleniyor':
        renk = Colors.orange;
        etiket = 'İnceleniyor';
        break;
      case 'cevaplandi':
        renk = Colors.green;
        etiket = 'Cevaplanmış';
        break;
      case 'kapali':
        renk = Colors.grey;
        etiket = 'Kapalı';
        break;
      default:
        renk = Colors.grey;
        etiket = durum;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: renk.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: renk.withAlpha(75)),
      ),
      child: Text(
        etiket,
        style: TextStyle(
          fontSize: 11,
          color: renk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _oncelikRenk(String oncelik) {
    switch (oncelik) {
      case 'acil':
        return Colors.red;
      case 'yuksek':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'dusuk':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _talepDetay(Map<String, dynamic> talep) async {
    final talepId = talep['id'] as String;
    final konu = talep['konu']?.toString() ?? '';
    final mesaj = talep['mesaj']?.toString() ?? '';
    final durum = talep['durum']?.toString() ?? 'acik';
    final cevap = talep['cevap']?.toString();
    final cevapController = TextEditingController(text: cevap);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(konu),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mesaj:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(mesaj),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cevap:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: cevapController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Cevabınızı yazın...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
              onPressed: () async {
                await PlatformAdminService.destekKapat(talepId);
                if (ctx.mounted) Navigator.pop(ctx);
                _verileriYukle();
              },
              child: const Text('Kapat', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          if (durum != 'kapali')
            ElevatedButton(
              onPressed: () async {
                final cevapText = cevapController.text.trim();
                if (cevapText.isEmpty) return;
                await PlatformAdminService.destekCevapla(
                    talepId, cevapText);
                if (ctx.mounted) Navigator.pop(ctx);
                _verileriYukle();
              },
              child: const Text('Cevapla'),
            ),
        ],
      ),
    );

    cevapController.dispose();
  }
}
