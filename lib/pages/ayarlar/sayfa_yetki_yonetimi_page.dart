import 'package:flutter/material.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class SayfaYetkiYonetimiPage extends StatefulWidget {
  const SayfaYetkiYonetimiPage({super.key});

  @override
  State<SayfaYetkiYonetimiPage> createState() => _SayfaYetkiYonetimiPageState();
}

class _SayfaYetkiYonetimiPageState extends State<SayfaYetkiYonetimiPage> {
  List<Map<String, dynamic>> _kullanicilar = [];
  Map<String, dynamic>? _secilenKullanici;
  Set<String> _aktifYetkiler = {};
  bool _yukleniyor = true;
  bool _kaydediyor = false;

  @override
  void initState() {
    super.initState();
    _kullanicilariYukle();
  }

  Future<void> _kullanicilariYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final kullanicilar = await SayfaYetkiService.firmaKullanicilariniGetir();
      setState(() {
        _kullanicilar = kullanicilar;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Kullanıcılar yüklenemedi: $e');
      }
    }
  }

  Future<void> _kullaniciSec(Map<String, dynamic> kullanici) async {
    setState(() {
      _secilenKullanici = kullanici;
      _yukleniyor = true;
    });
    try {
      final userId = kullanici['user_id'] as String;
      final yetkiler = await SayfaYetkiService.kullaniciYetkileriniGetir(userId);
      setState(() {
        _aktifYetkiler = yetkiler;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Yetkiler yüklenemedi: $e');
      }
    }
  }

  Future<void> _kaydet() async {
    if (_secilenKullanici == null) return;
    setState(() => _kaydediyor = true);
    try {
      final userId = _secilenKullanici!['user_id'] as String;
      await SayfaYetkiService.yetkileriKaydet(userId, _aktifYetkiler);
      if (mounted) {
        context.showSuccessSnackBar('Yetkiler başarıyla kaydedildi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kaydetme hatası: $e');
      }
    } finally {
      setState(() => _kaydediyor = false);
    }
  }

  void _tumunuSec() {
    setState(() {
      _aktifYetkiler = SayfaRegistry.tumSayfalar.map((s) => s.kod).toSet();
    });
  }

  void _tumunuKaldir() {
    setState(() {
      _aktifYetkiler = {};
    });
  }

  void _kategoriTopluIslem(String kategori, bool sec) {
    setState(() {
      final sayfalar = SayfaRegistry.kategoriyeGore(kategori);
      for (final sayfa in sayfalar) {
        if (sec) {
          _aktifYetkiler.add(sayfa.kod);
        } else {
          _aktifYetkiler.remove(sayfa.kod);
        }
      }
    });
  }

  String _kullaniciAdi(Map<String, dynamic> kullanici) {
    final ad = kullanici['ad'] ?? '';
    final soyad = kullanici['soyad'] ?? '';
    final email = kullanici['email'] ?? '';
    if (ad.toString().isNotEmpty) return '$ad $soyad'.trim();
    if (email.toString().isNotEmpty) return email.toString();
    return kullanici['user_id']?.toString().substring(0, 8) ?? '-';
  }

  String _rolEtiketi(String? rol) {
    const etiketler = {
      'firma_sahibi': 'Firma Sahibi',
      'firma_admin': 'Firma Yöneticisi',
      'yonetici': 'Yönetici',
      'kullanici': 'Kullanıcı',
      'personel': 'Personel',
      'dokumaci': 'Dokumacı',
      'konfeksiyoncu': 'Konfeksiyoncu',
      'kalite_kontrol': 'Kalite Kontrol',
      'sofor': 'Şoför',
      'muhasebeci': 'Muhasebeci',
      'depocu': 'Depocu',
    };
    return etiketler[rol] ?? rol ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayfa Yetki Yönetimi'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          if (_secilenKullanici != null)
            _kaydediyor
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Kaydet',
                    onPressed: _kaydet,
                  ),
        ],
      ),
      body: _yukleniyor && _secilenKullanici == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Sol panel: Kullanıcı listesi
                SizedBox(
                  width: 280,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00897B),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kullanıcılar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Yetki düzenlemek için kullanıcı seçin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _kullanicilar.length,
                            itemBuilder: (context, index) {
                              final k = _kullanicilar[index];
                              final secili = _secilenKullanici?['user_id'] == k['user_id'];
                              final rol = k['rol'] as String?;
                              final isAdmin = rol == 'firma_sahibi' || rol == 'firma_admin';
                              return ListTile(
                                selected: secili,
                                selectedTileColor: const Color(0xFF00897B).withValues(alpha: 0.1),
                                leading: CircleAvatar(
                                  backgroundColor: isAdmin ? const Color(0xFF00897B) : Colors.grey[400],
                                  child: Text(
                                    _kullaniciAdi(k).substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  _kullaniciAdi(k),
                                  style: TextStyle(
                                    fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  _rolEtiketi(rol),
                                  style: TextStyle(fontSize: 11, color: isAdmin ? const Color(0xFF00897B) : Colors.grey[600]),
                                ),
                                trailing: isAdmin
                                    ? const Tooltip(
                                        message: 'Admin - Tüm sayfalara erişim',
                                        child: Icon(Icons.verified, color: Color(0xFF00897B), size: 18),
                                      )
                                    : null,
                                onTap: isAdmin ? null : () => _kullaniciSec(k),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Sağ panel: Sayfa yetkileri
                Expanded(
                  child: _secilenKullanici == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Yetki düzenlemek için soldan bir kullanıcı seçin',
                                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : _yukleniyor 
                        ? const Center(child: CircularProgressIndicator())
                        : _buildYetkiPaneli(),
                ),
              ],
            ),
    );
  }

  Widget _buildYetkiPaneli() {
    final kategoriler = SayfaRegistry.tumKategoriler;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: const Color(0xFF00897B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_kullaniciAdi(_secilenKullanici!)} — ${_rolEtiketi(_secilenKullanici!['rol'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: _tumunuSec,
                icon: const Icon(Icons.select_all, size: 16),
                label: const Text('Tümünü Seç', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _tumunuKaldir,
                icon: const Icon(Icons.deselect, size: 16),
                label: const Text('Tümünü Kaldır', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
        // Kategori listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: kategoriler.length,
            itemBuilder: (context, index) {
              final kategori = kategoriler[index];
              return _buildKategoriKarti(kategori);
            },
          ),
        ),
        // Kaydet butonu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _kaydediyor ? null : _kaydet,
              icon: _kaydediyor
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_kaydediyor ? 'Kaydediliyor...' : 'Yetkileri Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriKarti(String kategori) {
    final sayfalar = SayfaRegistry.kategoriyeGore(kategori);
    final hepsiSecili = sayfalar.every((s) => _aktifYetkiler.contains(s.kod));
    final hicSecili = sayfalar.every((s) => !_aktifYetkiler.contains(s.kod));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // Kategori header
          InkWell(
            onTap: () => _kategoriTopluIslem(kategori, !hepsiSecili),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hepsiSecili
                    ? const Color(0xFF00897B).withValues(alpha: 0.1)
                    : hicSecili
                        ? Colors.grey[50]
                        : Colors.orange.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Icon(
                    hepsiSecili ? Icons.check_circle : hicSecili ? Icons.cancel_outlined : Icons.remove_circle_outline,
                    color: hepsiSecili ? const Color(0xFF00897B) : hicSecili ? Colors.grey : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kategori,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hepsiSecili ? const Color(0xFF00897B) : Colors.grey[800],
                      ),
                    ),
                  ),
                  Text(
                    '${sayfalar.where((s) => _aktifYetkiler.contains(s.kod)).length}/${sayfalar.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          // Sayfa toggle'lar
          ...sayfalar.map((sayfa) {
            final aktif = _aktifYetkiler.contains(sayfa.kod);
            return SwitchListTile(
              dense: true,
              secondary: Icon(sayfa.ikon, size: 20, color: aktif ? const Color(0xFF00897B) : Colors.grey[400]),
              title: Text(sayfa.etiket, style: TextStyle(fontSize: 13, color: aktif ? Colors.black87 : Colors.grey[500])),
              value: aktif,
              activeColor: const Color(0xFF00897B),
              onChanged: (val) {
                setState(() {
                  if (val) {
                    _aktifYetkiler.add(sayfa.kod);
                  } else {
                    _aktifYetkiler.remove(sayfa.kod);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
