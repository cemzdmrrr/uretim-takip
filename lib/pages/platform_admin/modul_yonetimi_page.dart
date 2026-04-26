import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class ModulYonetimiPage extends StatefulWidget {
  const ModulYonetimiPage({super.key});

  @override
  State<ModulYonetimiPage> createState() => _ModulYonetimiPageState();
}

class _ModulYonetimiPageState extends State<ModulYonetimiPage> {
  bool _yukleniyor = true;
  bool _islemSuruyor = false;
  List<Map<String, dynamic>> _moduller = [];

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
      _moduller = await PlatformAdminService.modulTanimlariGetir();
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
        title: const Text('Modül Yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Yeni modül',
            icon: const Icon(Icons.add),
            onPressed: _yeniModulEkle,
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildHero(),
                ),
                Expanded(
                  child: _moduller.isEmpty
                      ? const Center(child: Text('Henüz modül tanımı yok'))
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _moduller.length,
                          onReorder: _siralaDegistir,
                          itemBuilder: (context, index) {
                            final item = _moduller[index];
                            return _buildModulCard(item, index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniModulEkle,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Modül'),
      ),
    );
  }

  Widget _buildHero() {
    final aktif = _moduller.where((item) => item['aktif'] == true).length;
    final pasif = _moduller.length - aktif;
    final kategoriler = _moduller
        .map((item) => item['kategori']?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF581C87), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform modül kataloğu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sıra, durum ve açıklama yapısını düzenleyin. Firma bazlı dağıtım bunun üstünden okunur.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _heroStat('Toplam modül', '${_moduller.length}',
                  Icons.extension_outlined),
              _heroStat('Aktif', '$aktif', Icons.check_circle_outline),
              _heroStat('Pasif', '$pasif', Icons.pause_circle_outline),
              _heroStat('Kategori', '$kategoriler', Icons.category_outlined),
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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModulCard(Map<String, dynamic> item, int index) {
    final aktif = item['aktif'] == true;
    final modulKodu = item['modul_kodu']?.toString() ?? '';
    final modulAdi = item['modul_adi']?.toString() ?? '';
    final kategori = item['kategori']?.toString() ?? '-';
    final aciklama = item['aciklama']?.toString() ?? '';

    return Container(
      key: ValueKey(item['id']),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.drag_indicator),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: aktif ? const Color(0xFFF3E8FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _modulIkon(modulKodu),
              color: aktif ? const Color(0xFF7E22CE) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      modulAdi,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    _pill(modulKodu, const Color(0xFFE2E8F0),
                        const Color(0xFF334155)),
                    _pill(kategori, const Color(0xFFF1F5F9),
                        const Color(0xFF475569)),
                    _pill(
                      aktif ? 'Aktif' : 'Pasif',
                      aktif ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      aktif ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    ),
                  ],
                ),
                if (aciklama.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    aciklama,
                    style:
                        const TextStyle(color: Color(0xFF475569), height: 1.45),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _islemSuruyor
                          ? null
                          : () => _durumDegistir(item['id'] as String, !aktif),
                      icon: Icon(
                        aktif
                            ? Icons.pause_circle_outline
                            : Icons.check_circle_outline,
                        size: 18,
                      ),
                      label: Text(aktif ? 'Pasif Yap' : 'Aktif Yap'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _islemSuruyor ? null : () => _modulDuzenle(item),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Düzenle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _durumDegistir(String modulId, bool aktif) async {
    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.modulTanimGuncelle(modulId, {'aktif': aktif});
      await _verileriYukle();
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

  Future<void> _yeniModulEkle() async {
    final sonuc = await _modulDialogGoster();
    if (sonuc == null) return;

    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.modulTanimEkle(sonuc);
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modül eklendi')),
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

  Future<void> _modulDuzenle(Map<String, dynamic> modul) async {
    final sonuc = await _modulDialogGoster(mevcutVeri: modul);
    if (sonuc == null) return;

    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.modulTanimGuncelle(
          modul['id'] as String, sonuc);
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modül güncellendi')),
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

  Future<Map<String, dynamic>?> _modulDialogGoster({
    Map<String, dynamic>? mevcutVeri,
  }) async {
    final kodController =
        TextEditingController(text: mevcutVeri?['modul_kodu']?.toString());
    final adController =
        TextEditingController(text: mevcutVeri?['modul_adi']?.toString());
    final aciklamaController =
        TextEditingController(text: mevcutVeri?['aciklama']?.toString());
    final siraController = TextEditingController(
      text: mevcutVeri?['sira_no']?.toString() ?? '${_moduller.length + 1}',
    );
    String kategori = mevcutVeri?['kategori']?.toString() ?? 'uretim';

    final sonuc = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(mevcutVeri == null ? 'Yeni Modül' : 'Modülü Düzenle'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: adController,
                    decoration: const InputDecoration(
                      labelText: 'Modül adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kodController,
                    decoration: const InputDecoration(
                      labelText: 'Modül kodu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: kategori,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'uretim', child: Text('Üretim')),
                      DropdownMenuItem(value: 'finans', child: Text('Finans')),
                      DropdownMenuItem(
                          value: 'ik', child: Text('İnsan kaynakları')),
                      DropdownMenuItem(value: 'stok', child: Text('Stok')),
                      DropdownMenuItem(value: 'rapor', child: Text('Rapor')),
                      DropdownMenuItem(value: 'diger', child: Text('Diğer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => kategori = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: siraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sıra numarası',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: aciklamaController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                final ad = adController.text.trim();
                final kod = kodController.text.trim();
                if (ad.isEmpty || kod.isEmpty) return;
                Navigator.of(ctx).pop({
                  'modul_adi': ad,
                  'modul_kodu': kod,
                  'kategori': kategori,
                  'sira_no': int.tryParse(siraController.text.trim()) ??
                      (_moduller.length + 1),
                  'aciklama': aciklamaController.text.trim(),
                  'aktif': mevcutVeri?['aktif'] ?? true,
                });
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    kodController.dispose();
    adController.dispose();
    aciklamaController.dispose();
    siraController.dispose();

    return sonuc;
  }

  void _siralaDegistir(int eskiIndex, int yeniIndex) {
    if (yeniIndex > eskiIndex) yeniIndex--;

    setState(() {
      final item = _moduller.removeAt(eskiIndex);
      _moduller.insert(yeniIndex, item);
    });

    for (int i = 0; i < _moduller.length; i++) {
      final id = _moduller[i]['id'] as String;
      PlatformAdminService.modulTanimGuncelle(id, {'sira_no': i + 1});
    }
  }

  Widget _pill(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }

  IconData _modulIkon(String kod) {
    switch (kod) {
      case 'uretim':
        return Icons.precision_manufacturing_outlined;
      case 'finans':
        return Icons.account_balance_wallet_outlined;
      case 'ik':
        return Icons.badge_outlined;
      case 'stok':
        return Icons.inventory_2_outlined;
      case 'sevkiyat':
        return Icons.local_shipping_outlined;
      case 'tedarik':
        return Icons.store_mall_directory_outlined;
      case 'musteri':
        return Icons.store_outlined;
      case 'rapor':
        return Icons.analytics_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}
