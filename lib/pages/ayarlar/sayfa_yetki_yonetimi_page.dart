import 'package:flutter/material.dart';
import 'package:uretim_takip/services/sayfa_yetki_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/yetki_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class SayfaYetkiYonetimiPage extends StatefulWidget {
  const SayfaYetkiYonetimiPage({super.key});

  @override
  State<SayfaYetkiYonetimiPage> createState() => _SayfaYetkiYonetimiPageState();
}

class _SayfaYetkiYonetimiPageState extends State<SayfaYetkiYonetimiPage> {
  static const _anaRenk = Color(0xFF00897B);
  static const _adminRoller = {'admin', 'firma_sahibi', 'firma_admin'};

  final _aramaController = TextEditingController();

  List<Map<String, dynamic>> _kullanicilar = [];
  Map<String, dynamic>? _secilenKullanici;
  Set<String> _aktifYetkiler = {};
  Set<String> _duzenlemeYetkileri = {};
  Set<String> _silmeYetkileri = {};
  Set<String> _firmaAktifSayfalar = {};
  bool _yukleniyor = true;
  bool _detayYukleniyor = false;
  bool _kaydediyor = false;
  bool _explicitKayitVar = false;
  String? _secilenRol;
  String _arama = '';

  List<String> get _duzenlenebilirRoller => YetkiService.tumRoller
      .where((rol) => !_adminRoller.contains(rol))
      .toList();

  bool get _seciliKullaniciAdminMi => _adminRoller.contains(_secilenRol);

  List<SayfaTanimi> get _firmaIzinliSayfalar {
    if (_firmaAktifSayfalar.isEmpty) return SayfaRegistry.tumSayfalar;
    return SayfaRegistry.tumSayfalar
        .where((s) => _firmaAktifSayfalar.contains(s.kod))
        .toList();
  }

  List<String> get _firmaIzinliKategoriler {
    return _firmaIzinliSayfalar.map((s) => s.kategori).toSet().toList();
  }

  List<Map<String, dynamic>> get _filtreliKullanicilar {
    final q = _arama.trim().toLowerCase();
    if (q.isEmpty) return _kullanicilar;
    return _kullanicilar.where((k) {
      return _kullaniciAdi(k).toLowerCase().contains(q) ||
          (k['email'] ?? '').toString().toLowerCase().contains(q) ||
          (k['rol'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _kullanicilariYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _kullanicilariYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      final results = await Future.wait([
        SayfaYetkiService.firmaKullanicilariniGetir(),
        SayfaYetkiService.firmaYetkileriniGetir(firmaId),
      ]);

      if (!mounted) return;
      setState(() {
        _kullanicilar = results[0] as List<Map<String, dynamic>>;
        _firmaAktifSayfalar = results[1] as Set<String>;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      context.showErrorSnackBar('Kullanıcılar yüklenemedi: $e');
    }
  }

  Future<void> _kullaniciSec(Map<String, dynamic> kullanici) async {
    final userId = kullanici['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;

    setState(() {
      _secilenKullanici = kullanici;
      _secilenRol = kullanici['rol']?.toString() ?? 'kullanici';
      _detayYukleniyor = true;
      _aktifYetkiler = {};
      _duzenlemeYetkileri = {};
      _silmeYetkileri = {};
      _explicitKayitVar = false;
    });

    try {
      final adminMi = _adminRoller.contains(_secilenRol);
      final explicitKayitVar =
          await SayfaYetkiService.kullaniciSayfaYetkiKaydiVarMi(userId);
      final tumSayfalar = SayfaRegistry.tumSayfalar.map((s) => s.kod).toSet();
      final paket = adminMi
          ? SayfaYetkiPaketi(
              goruntuleme: tumSayfalar,
              duzenleme: tumSayfalar,
              silme: tumSayfalar,
            )
          : explicitKayitVar
              ? await SayfaYetkiService.kullaniciYetkiPaketiniGetir(userId)
              : SayfaYetkiPaketi(
                  goruntuleme: await SayfaYetkiService.rolYetkileriniGetir(
                    _secilenRol ?? 'kullanici',
                  ),
                );

      if (!mounted) return;
      setState(() {
        _aktifYetkiler = _firmaSayfalariylaSinirla(paket.goruntuleme);
        _duzenlemeYetkileri = _firmaSayfalariylaSinirla(
          paket.duzenleme.intersection(_aktifYetkiler),
        );
        _silmeYetkileri = _firmaSayfalariylaSinirla(
          paket.silme.intersection(_aktifYetkiler),
        );
        _explicitKayitVar = explicitKayitVar;
        _detayYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _detayYukleniyor = false);
      context.showErrorSnackBar('Yetkiler yüklenemedi: $e');
    }
  }

  Future<void> _rolSablonunuUygula() async {
    if (_secilenRol == null || _seciliKullaniciAdminMi) return;
    setState(() => _detayYukleniyor = true);
    try {
      final rolYetkileri =
          await SayfaYetkiService.rolYetkileriniGetir(_secilenRol!);
      if (!mounted) return;
      setState(() {
        _aktifYetkiler = _firmaSayfalariylaSinirla(rolYetkileri);
        _duzenlemeYetkileri = {};
        _silmeYetkileri = {};
        _detayYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _detayYukleniyor = false);
      context.showErrorSnackBar('Rol şablonu yüklenemedi: $e');
    }
  }

  Future<void> _kaydet() async {
    if (_secilenKullanici == null || _secilenRol == null) return;
    if (_seciliKullaniciAdminMi) {
      context.showErrorSnackBar('Admin rollerinin sayfa yetkisi kısıtlanamaz');
      return;
    }

    setState(() => _kaydediyor = true);
    try {
      final userId = _secilenKullanici!['user_id']?.toString();
      final firmaKullaniciId = _secilenKullanici!['id']?.toString();
      if (userId == null || userId.isEmpty) {
        throw StateError('Kullanıcı ID bulunamadı');
      }
      if (firmaKullaniciId == null || firmaKullaniciId.isEmpty) {
        throw StateError('Firma kullanıcı ID bulunamadı');
      }

      final mevcutRol = _secilenKullanici!['rol']?.toString();
      if (mevcutRol != _secilenRol) {
        await YetkiService.kullaniciRolDegistir(
          firmaKullaniciId: firmaKullaniciId,
          yeniRol: _secilenRol!,
        );
      }

      final kaydedilecekYetkiler = _firmaSayfalariylaSinirla(_aktifYetkiler);
      final kaydedilecekDuzenleme = _firmaSayfalariylaSinirla(
        _duzenlemeYetkileri.intersection(kaydedilecekYetkiler),
      );
      final kaydedilecekSilme = _firmaSayfalariylaSinirla(
        _silmeYetkileri.intersection(kaydedilecekYetkiler),
      );
      await SayfaYetkiService.yetkileriKaydet(
        userId,
        kaydedilecekYetkiler,
        duzenlemeYetkileri: kaydedilecekDuzenleme,
        silmeYetkileri: kaydedilecekSilme,
      );

      if (!mounted) return;
      setState(() {
        _secilenKullanici = {
          ..._secilenKullanici!,
          'rol': _secilenRol,
        };
        _aktifYetkiler = kaydedilecekYetkiler;
        _duzenlemeYetkileri = kaydedilecekDuzenleme;
        _silmeYetkileri = kaydedilecekSilme;
        _explicitKayitVar = true;
        _kaydediyor = false;
      });
      await _kullanicilariYukle();
      if (mounted) {
        context.showSuccessSnackBar(
            'Kullanıcı rolü ve sayfa yetkileri kaydedildi');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      context.showErrorSnackBar('Kaydetme hatası: $e');
    }
  }

  Set<String> _firmaSayfalariylaSinirla(Set<String> yetkiler) {
    final normalized =
        yetkiler.map(SayfaYetkiService.normalizeSayfaKodu).toSet();
    if (_firmaAktifSayfalar.isEmpty) return normalized;
    return normalized.intersection(_firmaAktifSayfalar);
  }

  void _tumunuSec() {
    if (_seciliKullaniciAdminMi) return;
    setState(() {
      _aktifYetkiler = _firmaIzinliSayfalar.map((s) => s.kod).toSet();
    });
  }

  void _tumunuKaldir() {
    if (_seciliKullaniciAdminMi) return;
    setState(() {
      _aktifYetkiler = {};
      _duzenlemeYetkileri = {};
      _silmeYetkileri = {};
    });
  }

  void _kategoriTopluIslem(String kategori, bool sec) {
    if (_seciliKullaniciAdminMi) return;
    setState(() {
      final sayfalar =
          _firmaIzinliSayfalar.where((s) => s.kategori == kategori);
      for (final sayfa in sayfalar) {
        if (sec) {
          _aktifYetkiler.add(sayfa.kod);
        } else {
          _aktifYetkiler.remove(sayfa.kod);
          _duzenlemeYetkileri.remove(sayfa.kod);
          _silmeYetkileri.remove(sayfa.kod);
        }
      }
    });
  }

  void _sayfaGoruntulemeAyarla(String sayfaKodu, bool aktif) {
    if (_seciliKullaniciAdminMi) return;
    setState(() {
      if (aktif) {
        _aktifYetkiler.add(sayfaKodu);
      } else {
        _aktifYetkiler.remove(sayfaKodu);
        _duzenlemeYetkileri.remove(sayfaKodu);
        _silmeYetkileri.remove(sayfaKodu);
      }
    });
  }

  void _sayfaDuzenlemeAyarla(String sayfaKodu, bool aktif) {
    if (_seciliKullaniciAdminMi) return;
    setState(() {
      if (aktif) {
        _aktifYetkiler.add(sayfaKodu);
        _duzenlemeYetkileri.add(sayfaKodu);
      } else {
        _duzenlemeYetkileri.remove(sayfaKodu);
      }
    });
  }

  void _sayfaSilmeAyarla(String sayfaKodu, bool aktif) {
    if (_seciliKullaniciAdminMi) return;
    setState(() {
      if (aktif) {
        _aktifYetkiler.add(sayfaKodu);
        _silmeYetkileri.add(sayfaKodu);
      } else {
        _silmeYetkileri.remove(sayfaKodu);
      }
    });
  }

  String _kullaniciAdi(Map<String, dynamic> kullanici) {
    final ad = kullanici['ad'] ?? '';
    final soyad = kullanici['soyad'] ?? '';
    final email = kullanici['email'] ?? '';
    if (ad.toString().trim().isNotEmpty) return '$ad $soyad'.trim();
    if (email.toString().trim().isNotEmpty) return email.toString();
    final userId = kullanici['user_id']?.toString() ?? '';
    return userId.length > 8 ? userId.substring(0, 8) : '-';
  }

  String _rolEtiketi(String? rol) {
    if (rol == 'admin') return 'Admin';
    return YetkiService.rolEtiketleri[rol] ?? rol ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yetkileri'),
        backgroundColor: _anaRenk,
        foregroundColor: Colors.white,
        actions: [
          if (_secilenKullanici != null)
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
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final dar = constraints.maxWidth < 820;
                if (dar) {
                  return Column(
                    children: [
                      SizedBox(height: 260, child: _buildKullaniciPaneli()),
                      Expanded(child: _buildDetayAlani()),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 320, child: _buildKullaniciPaneli()),
                    Expanded(child: _buildDetayAlani()),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildKullaniciPaneli() {
    final kullanicilar = _filtreliKullanicilar;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _anaRenk,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kullanıcılar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _aramaController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Ara',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _arama = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: kullanicilar.isEmpty
                ? const Center(child: Text('Kullanıcı bulunamadı'))
                : ListView.builder(
                    itemCount: kullanicilar.length,
                    itemBuilder: (context, index) {
                      final k = kullanicilar[index];
                      final secili =
                          _secilenKullanici?['user_id'] == k['user_id'];
                      final rol = k['rol']?.toString();
                      final adminMi = _adminRoller.contains(rol);
                      return ListTile(
                        selected: secili,
                        selectedTileColor: _anaRenk.withValues(alpha: 0.1),
                        leading: CircleAvatar(
                          backgroundColor:
                              adminMi ? _anaRenk : Colors.grey[500],
                          child: Text(
                            _kullaniciAdi(k).substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          _kullaniciAdi(k),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                secili ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          _rolEtiketi(rol),
                          style: TextStyle(
                            fontSize: 11,
                            color: adminMi ? _anaRenk : Colors.grey[600],
                          ),
                        ),
                        trailing: adminMi
                            ? const Tooltip(
                                message: 'Admin rolü kısıtlanamaz',
                                child: Icon(
                                  Icons.verified,
                                  color: _anaRenk,
                                  size: 18,
                                ),
                              )
                            : null,
                        onTap: () => _kullaniciSec(k),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayAlani() {
    if (_secilenKullanici == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Yetki düzenlemek için kullanıcı seçin',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_detayYukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildYetkiHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _firmaIzinliKategoriler.length,
            itemBuilder: (context, index) {
              return _buildKategoriKarti(_firmaIzinliKategoriler[index]);
            },
          ),
        ),
        _buildKaydetAlani(),
      ],
    );
  }

  Widget _buildYetkiHeader() {
    final toplamSayfa = _firmaIzinliSayfalar.length;
    final aktifSayfa = _aktifYetkiler.length;
    final duzenlemeAdet = _duzenlemeYetkileri.length;
    final silmeAdet = _silmeYetkileri.length;
    final rolDropdownDegeri =
        _duzenlenebilirRoller.contains(_secilenRol) ? _secilenRol : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person, color: _anaRenk, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kullaniciAdi(_secilenKullanici!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _explicitKayitVar
                          ? 'Kullanıcıya özel sayfa yetkisi var'
                          : 'Özel kayıt yok, rol yetkileri temel alınıyor',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$aktifSayfa / $toplamSayfa sayfa'),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$duzenlemeAdet düzenleme'),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$silmeAdet silme'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: rolDropdownDegeri,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _duzenlenebilirRoller
                      .map(
                        (rol) => DropdownMenuItem(
                          value: rol,
                          child: Text(_rolEtiketi(rol)),
                        ),
                      )
                      .toList(),
                  onChanged: _seciliKullaniciAdminMi
                      ? null
                      : (value) => setState(() => _secilenRol = value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Rol şablonunu uygula',
                onPressed: _seciliKullaniciAdminMi ? null : _rolSablonunuUygula,
                icon: const Icon(Icons.content_copy_rounded),
              ),
              IconButton(
                tooltip: 'Tümünü seç',
                onPressed: _seciliKullaniciAdminMi ? null : _tumunuSec,
                icon: const Icon(Icons.select_all),
              ),
              IconButton(
                tooltip: 'Tümünü kaldır',
                onPressed: _seciliKullaniciAdminMi ? null : _tumunuKaldir,
                color: Colors.red,
                icon: const Icon(Icons.deselect),
              ),
            ],
          ),
          if (_seciliKullaniciAdminMi) ...[
            const SizedBox(height: 10),
            _buildBilgiKutusu(
              Icons.lock_rounded,
              'Admin, firma sahibi ve firma yöneticisi rolleri tüm sayfaları görür.',
            ),
          ],
          if (_firmaAktifSayfalar.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildBilgiKutusu(
              Icons.business_rounded,
              'Liste firma seviyesinde aktif sayfalarla sınırlandırıldı.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBilgiKutusu(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _anaRenk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _anaRenk.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _anaRenk, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _anaRenk),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaydetAlani() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _kaydediyor || _seciliKullaniciAdminMi ? null : _kaydet,
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
          label: Text(_kaydediyor ? 'Kaydediliyor...' : 'Kaydet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _anaRenk,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildKategoriKarti(String kategori) {
    final sayfalar =
        _firmaIzinliSayfalar.where((s) => s.kategori == kategori).toList();
    if (sayfalar.isEmpty) return const SizedBox.shrink();

    final hepsiSecili = sayfalar.every((s) => _aktifYetkiler.contains(s.kod));
    final hicSecili = sayfalar.every((s) => !_aktifYetkiler.contains(s.kod));
    final aktifAdet =
        sayfalar.where((s) => _aktifYetkiler.contains(s.kod)).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          InkWell(
            onTap: _seciliKullaniciAdminMi
                ? null
                : () => _kategoriTopluIslem(kategori, !hepsiSecili),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hepsiSecili
                    ? _anaRenk.withValues(alpha: 0.1)
                    : hicSecili
                        ? Colors.grey[50]
                        : Colors.orange.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
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
                        ? _anaRenk
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
                        color: hepsiSecili ? _anaRenk : Colors.grey[800],
                      ),
                    ),
                  ),
                  Text(
                    '$aktifAdet/${sayfalar.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          ...sayfalar.map((sayfa) {
            final aktif = _aktifYetkiler.contains(sayfa.kod);
            final duzenleme = _duzenlemeYetkileri.contains(sayfa.kod);
            final silme = _silmeYetkileri.contains(sayfa.kod);
            return _buildSayfaYetkiSatiri(
              sayfa: sayfa,
              goruntuleme: aktif,
              duzenleme: duzenleme,
              silme: silme,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSayfaYetkiSatiri({
    required SayfaTanimi sayfa,
    required bool goruntuleme,
    required bool duzenleme,
    required bool silme,
  }) {
    final pasif = _seciliKullaniciAdminMi;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dar = constraints.maxWidth < 620;
        final bilgi = Row(
          children: [
            Icon(
              sayfa.ikon,
              size: 20,
              color: goruntuleme ? _anaRenk : Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sayfa.etiket,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: goruntuleme ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                  Text(
                    sayfa.kod,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        );

        final kontroller = Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildYetkiKutusu(
              label: 'Göster',
              value: goruntuleme,
              icon: Icons.visibility_rounded,
              enabled: !pasif,
              onChanged: (value) => _sayfaGoruntulemeAyarla(sayfa.kod, value),
            ),
            _buildYetkiKutusu(
              label: 'Düzenle',
              value: duzenleme,
              icon: Icons.edit_rounded,
              enabled: !pasif,
              onChanged: (value) => _sayfaDuzenlemeAyarla(sayfa.kod, value),
            ),
            _buildYetkiKutusu(
              label: 'Sil',
              value: silme,
              icon: Icons.delete_rounded,
              enabled: !pasif,
              onChanged: (value) => _sayfaSilmeAyarla(sayfa.kod, value),
              danger: true,
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: dar
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bilgi,
                    const SizedBox(height: 8),
                    kontroller,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: bilgi),
                    kontroller,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildYetkiKutusu({
    required String label,
    required bool value,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    bool danger = false,
  }) {
    final color = danger ? Colors.red : _anaRenk;
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 106),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? color.withValues(alpha: 0.45) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? (val) => onChanged(val ?? false) : null,
              visualDensity: VisualDensity.compact,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Icon(icon, size: 16, color: value ? color : Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: value ? color : Colors.grey[700],
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
