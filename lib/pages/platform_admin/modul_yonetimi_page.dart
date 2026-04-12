import 'package:flutter/material.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

/// Platform Admin - Modül Tanım ve Fiyatlandırma Sayfası.
class ModulYonetimiPage extends StatefulWidget {
  const ModulYonetimiPage({super.key});

  @override
  State<ModulYonetimiPage> createState() => _ModulYonetimiPageState();
}

class _ModulYonetimiPageState extends State<ModulYonetimiPage> {
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _moduller = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      _moduller = await PlatformAdminService.modulTanimlariGetir();
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
        title: const Text('Modül Yönetimi'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _yeniModulEkle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _moduller.isEmpty
              ? const Center(child: Text('Henüz modül tanımı yok'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _moduller.length,
                  onReorder: _siralaDegistir,
                  itemBuilder: (context, index) {
                    final m = _moduller[index];
                    final aktif = m['aktif'] == true;
                    final modulKodu = m['modul_kodu']?.toString() ?? '';
                    final modulAdi = m['modul_adi']?.toString() ?? '';
                    final kategori = m['kategori']?.toString() ?? '';
                    final aciklama = m['aciklama']?.toString();

                    return Card(
                      key: ValueKey(m['id']),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: aktif
                              ? const Color(0xFF6A1B9A).withAlpha(50)
                              : Colors.grey.withAlpha(50),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: aktif
                              ? const Color(0xFF6A1B9A).withAlpha(25)
                              : Colors.grey.withAlpha(25),
                          child: Icon(
                            _modulIkon(modulKodu),
                            color: aktif
                                ? const Color(0xFF6A1B9A)
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              modulAdi,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                modulKodu,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kategori: $kategori',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (aciklama != null && aciklama.isNotEmpty)
                              Text(
                                aciklama,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: aktif,
                              onChanged: (val) =>
                                  _durumDegistir(m['id'] as String, val),
                              activeTrackColor: const Color(0xFF6A1B9A),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _modulDuzenle(m),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _modulIkon(String kod) {
    const map = {
      'uretim': Icons.factory,
      'finans': Icons.account_balance,
      'ik': Icons.people,
      'stok': Icons.inventory,
      'sevkiyat': Icons.local_shipping,
      'tedarik': Icons.handshake,
      'musteri': Icons.storefront,
      'rapor': Icons.analytics,
      'kalite': Icons.verified,
      'ayarlar': Icons.settings,
    };
    return map[kod] ?? Icons.extension;
  }

  Future<void> _durumDegistir(String modulId, bool aktif) async {
    try {
      await PlatformAdminService.modulTanimGuncelle(
          modulId, {'aktif': aktif});
      await _verileriYukle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _siralaDegistir(int eskiIndex, int yeniIndex) {
    if (yeniIndex > eskiIndex) yeniIndex--;
    setState(() {
      final item = _moduller.removeAt(eskiIndex);
      _moduller.insert(yeniIndex, item);
    });

    // Sıra numaralarını güncelle
    for (int i = 0; i < _moduller.length; i++) {
      final id = _moduller[i]['id'] as String;
      PlatformAdminService.modulTanimGuncelle(id, {'sira_no': i + 1});
    }
  }

  Future<void> _yeniModulEkle() async {
    final sonuc = await _modulDialogGoster();
    if (sonuc == null) return;

    try {
      await PlatformAdminService.modulTanimEkle(sonuc);
      await _verileriYukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modül eklendi')),
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

  Future<void> _modulDuzenle(Map<String, dynamic> modul) async {
    final sonuc = await _modulDialogGoster(mevcutVeri: modul);
    if (sonuc == null) return;

    try {
      await PlatformAdminService.modulTanimGuncelle(
          modul['id'] as String, sonuc);
      await _verileriYukle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modül güncellendi')),
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

  Future<Map<String, dynamic>?> _modulDialogGoster(
      {Map<String, dynamic>? mevcutVeri}) async {
    final kodController =
        TextEditingController(text: mevcutVeri?['modul_kodu']?.toString());
    final adiController =
        TextEditingController(text: mevcutVeri?['modul_adi']?.toString());
    final aciklamaController =
        TextEditingController(text: mevcutVeri?['aciklama']?.toString());
    String kategori =
        mevcutVeri?['kategori']?.toString() ?? 'uretim';

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mevcutVeri == null ? 'Yeni Modül' : 'Modül Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kodController,
                decoration: const InputDecoration(
                  labelText: 'Modül Kodu',
                  hintText: 'orn: uretim',
                ),
                enabled: mevcutVeri == null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adiController,
                decoration: const InputDecoration(
                  labelText: 'Modül Adı',
                  hintText: 'orn: Üretim Yönetimi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aciklamaController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: kategori,
                items: const [
                  DropdownMenuItem(value: 'uretim', child: Text('Üretim')),
                  DropdownMenuItem(value: 'finans', child: Text('Finans')),
                  DropdownMenuItem(value: 'ik', child: Text('İK')),
                  DropdownMenuItem(value: 'stok', child: Text('Stok')),
                  DropdownMenuItem(
                      value: 'sevkiyat', child: Text('Sevkiyat')),
                  DropdownMenuItem(
                      value: 'tedarik', child: Text('Tedarik')),
                  DropdownMenuItem(value: 'crm', child: Text('CRM')),
                  DropdownMenuItem(value: 'rapor', child: Text('Rapor')),
                  DropdownMenuItem(value: 'sistem', child: Text('Sistem')),
                ],
                decoration: const InputDecoration(labelText: 'Kategori'),
                onChanged: (val) => kategori = val ?? kategori,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (kodController.text.isEmpty || adiController.text.isEmpty) {
                return;
              }
              Navigator.pop(ctx, {
                'modul_kodu': kodController.text.trim(),
                'modul_adi': adiController.text.trim(),
                'aciklama': aciklamaController.text.trim(),
                'kategori': kategori,
                'aktif': true,
                'sira_no': _moduller.length + 1,
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
