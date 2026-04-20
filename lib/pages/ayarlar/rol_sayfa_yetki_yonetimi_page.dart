import 'package:flutter/material.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class RolSayfaYetkiYonetimiPage extends StatefulWidget {
  const RolSayfaYetkiYonetimiPage({super.key});

  @override
  State<RolSayfaYetkiYonetimiPage> createState() => _RolSayfaYetkiYonetimiPageState();
}

class _RolSayfaYetkiYonetimiPageState extends State<RolSayfaYetkiYonetimiPage> {
  List<String> _roller = [];
  String? _secilenRol;
  Set<String> _aktifYetkiler = {};
  bool _yukleniyor = true;
  bool _kaydediyor = false;

  // Tüm roller - önceden tanımlı
  static const Map<String, String> _tumRoller = {
    'kullanici': 'Kullanıcı',
    'personel': 'Personel',
    'yonetici': 'Yönetici',
    'dokumaci': 'Dokumacı',
    'konfeksiyoncu': 'Konfeksiyoncu',
    'kalite_kontrol': 'Kalite Kontrol',
    'sofor': 'Şoför',
    'muhasebeci': 'Muhasebeci',
    'depocu': 'Depocu',
  };

  @override
  void initState() {
    super.initState();
    _rolleriYukle();
  }

  Future<void> _rolleriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      // Firmadaki aktif rolleri al
      final firmaRolleri = await SayfaYetkiService.firmaRolleriniGetir();
      
      // Tüm tanımlı rolleri göster (firmada kullanılmasa bile)
      setState(() {
        _roller = _tumRoller.keys.toList();
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Roller yüklenemedi: $e');
      }
    }
  }

  Future<void> _rolSec(String rol) async {
    setState(() {
      _secilenRol = rol;
      _yukleniyor = true;
    });
    try {
      debugPrint('🎭 Rol seçildi: $rol');
      final yetkiler = await SayfaYetkiService.rolYetkileriniGetir(rol);
      debugPrint('✅ Yüklenen yetkiler: $yetkiler');
      setState(() {
        _aktifYetkiler = yetkiler;
        _yukleniyor = false;
      });
    } catch (e) {
      debugPrint('❌ Yetki yükleme hatası: $e');
      setState(() => _yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Yetkiler yüklenemedi: $e');
      }
    }
  }

  Future<void> _kaydet() async {
    if (_secilenRol == null) return;
    setState(() => _kaydediyor = true);
    try {
      debugPrint('💾 Kaydediliyor: $_secilenRol');
      debugPrint('📋 Yetkiler: $_aktifYetkiler');
      await SayfaYetkiService.rolYetkileriniKaydet(_secilenRol!, _aktifYetkiler);
      debugPrint('✅ Kayıt başarılı, tekrar yükleniyor...');
      
      // Kayıttan sonra verileri tekrar yükle
      final yeniYetkiler = await SayfaYetkiService.rolYetkileriniGetir(_secilenRol!);
      debugPrint('📋 Yüklenen yeni yetkiler: $yeniYetkiler');
      setState(() {
        _aktifYetkiler = yeniYetkiler;
        _kaydediyor = false;
      });
      
      if (mounted) {
        context.showSuccessSnackBar('Rol yetkileri başarıyla kaydedildi');
      }
    } catch (e) {
      debugPrint('❌ Kaydetme hatası: $e');
      setState(() => _kaydediyor = false);
      if (mounted) {
        context.showErrorSnackBar('Kaydetme hatası: $e');
      }
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

  String _rolEtiketi(String rol) => _tumRoller[rol] ?? rol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol Bazlı Sayfa Yetkileri'),
        backgroundColor: const Color(0xFF5E35B1),
        foregroundColor: Colors.white,
        actions: [
          if (_secilenRol != null)
            _kaydediyor
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Kaydet',
                    onPressed: _kaydet,
                  ),
        ],
      ),
      body: _yukleniyor && _secilenRol == null
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Sol panel: Rol listesi
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
                            color: Color(0xFF5E35B1),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Roller',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Yetki düzenlemek için rol seçin',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _roller.length,
                            itemBuilder: (context, index) {
                              final rol = _roller[index];
                              final secili = _secilenRol == rol;
                              return ListTile(
                                selected: secili,
                                selectedTileColor: const Color(0xFF5E35B1)
                                    .withValues(alpha: 0.1),
                                leading: CircleAvatar(
                                  backgroundColor: secili
                                      ? const Color(0xFF5E35B1)
                                      : Colors.grey[400],
                                  child: Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  _rolEtiketi(rol),
                                  style: TextStyle(
                                    fontWeight: secili
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  rol,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                onTap: () => _rolSec(rol),
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
                  child: _secilenRol == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Yetki düzenlemek için soldan bir rol seçin',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: const Color(0xFF5E35B1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_rolEtiketi(_secilenRol!)} Rolü',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _tumunuSec,
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text(
                      'Tümünü Seç',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _tumunuKaldir,
                    icon: const Icon(Icons.deselect, size: 16),
                    label: const Text(
                      'Tümünü Kaldır',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bu role sahip kullanıcılar seçilen sayfaları görebilir.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
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
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _kaydediyor ? 'Kaydediliyor...' : 'Yetkileri Kaydet',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E35B1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriKarti(String kategori) {
    final sayfalar = SayfaRegistry.kategoriyeGore(kategori);
    if (sayfalar.isEmpty) return const SizedBox.shrink();
    
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
                    ? const Color(0xFF5E35B1).withValues(alpha: 0.1)
                    : hicSecili
                        ? Colors.grey[50]
                        : Colors.orange.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hepsiSecili
                        ? Icons.check_circle
                        : hicSecili
                            ? Icons.cancel_outlined
                            : Icons.remove_circle_outline,
                    color: hepsiSecili
                        ? const Color(0xFF5E35B1)
                        : hicSecili
                            ? Colors.grey
                            : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kategori,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hepsiSecili
                            ? const Color(0xFF5E35B1)
                            : Colors.grey[800],
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
              secondary: Icon(
                sayfa.ikon,
                size: 20,
                color: aktif
                    ? const Color(0xFF5E35B1)
                    : Colors.grey[400],
              ),
              title: Text(
                sayfa.etiket,
                style: TextStyle(
                  fontSize: 13,
                  color: aktif ? Colors.black87 : Colors.grey[500],
                ),
              ),
              value: aktif,
              activeColor: const Color(0xFF5E35B1),
              onChanged: (val) {
                debugPrint('🔄 Checkbox değişti: ${sayfa.etiket} ($val) - ${sayfa.kod}');
                debugPrint('📋 Önce: $_aktifYetkiler');
                setState(() {
                  if (val) {
                    _aktifYetkiler.add(sayfa.kod);
                  } else {
                    _aktifYetkiler.remove(sayfa.kod);
                  }
                });
                debugPrint('📋 Sonra: $_aktifYetkiler');
              },
            );
          }),
        ],
      ),
    );
  }
}
