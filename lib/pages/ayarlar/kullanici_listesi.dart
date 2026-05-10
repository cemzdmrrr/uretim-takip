import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/yetki_service.dart';

class KullaniciListesiPage extends StatefulWidget {
  const KullaniciListesiPage({super.key});

  @override
  State<KullaniciListesiPage> createState() => _KullaniciListesiPageState();
}

class _KullaniciListesiPageState extends State<KullaniciListesiPage> {
  static const _yoneticiRoller = {'admin', 'firma_sahibi', 'firma_admin'};
  static const _adminRoller = {'firma_sahibi', 'firma_admin'};

  final _searchController = TextEditingController();
  final _adminClient = SupabaseConfig.adminClient;

  bool _yukleniyor = true;
  bool _islemSuruyor = false;
  bool _yonetebilir = false;
  String? _mevcutRol;
  String _seciliRolFiltresi = 'hepsi';

  List<Map<String, dynamic>> _tumKullanicilar = [];
  List<Map<String, dynamic>> _filtrelenmisKullanicilar = [];

  static final List<_RolSecenegi> _rolSecenekleri = [
    const _RolSecenegi('firma_admin', 'Firma Yöneticisi'),
    const _RolSecenegi('yonetici', 'Yönetici'),
    const _RolSecenegi('kullanici', 'Kullanıcı'),
    const _RolSecenegi('personel', 'Personel'),
    const _RolSecenegi('ik', 'İnsan Kaynakları'),
    const _RolSecenegi('dokuma', 'Dokuma'),
    const _RolSecenegi('konfeksiyon', 'Konfeksiyon'),
    const _RolSecenegi('yikama', 'Yıkama'),
    const _RolSecenegi('utu_paket', 'Ütü / Paket'),
    const _RolSecenegi('ilik_dugme', 'İlik Düğme'),
    const _RolSecenegi('kalite_kontrol', 'Kalite Kontrol'),
    const _RolSecenegi('sevkiyat', 'Sevkiyat'),
    const _RolSecenegi('sofor', 'Şoför'),
    const _RolSecenegi('muhasebe', 'Muhasebe'),
    const _RolSecenegi('tasarim', 'Tasarım'),
    const _RolSecenegi('planlama', 'Planlama'),
    const _RolSecenegi('satis', 'Satış'),
    const _RolSecenegi('depo', 'Depo'),
    const _RolSecenegi('nakis', 'Nakış'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtreleriUygula);
    _verileriYukle();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtreleriUygula);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    if (!mounted) return;
    setState(() => _yukleniyor = true);

    try {
      final firmaId = TenantManager.instance.firmaId;
      if (firmaId == null) {
        throw Exception('Aktif firma seçili değil');
      }

      final sonuclar = await Future.wait([
        YetkiService.kullaniciFirmaRolGetir(),
        YetkiService.firmaKullanicilariGetir(),
      ]);

      _mevcutRol = sonuclar[0] as String?;
      _yonetebilir = _yoneticiRoller.contains(_mevcutRol);
      _tumKullanicilar = List<Map<String, dynamic>>.from(sonuclar[1] as List);
      _filtreleriUygula(notify: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar yüklenemedi: $e')),
      );
      _tumKullanicilar = [];
      _filtrelenmisKullanicilar = [];
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  void _filtreleriUygula({bool notify = true}) {
    final query = _searchController.text.trim().toLowerCase();
    final yeniListe = _tumKullanicilar.where((item) {
      final email = (item['email'] ?? '').toString().toLowerCase();
      final rol = (item['rol'] ?? '').toString().toLowerCase();
      final ad = (item['ad'] ?? '').toString().toLowerCase();
      final soyad = (item['soyad'] ?? '').toString().toLowerCase();
      final displayName = (item['display_name'] ?? '').toString().toLowerCase();

      final aramaUydu = query.isEmpty ||
          email.contains(query) ||
          rol.contains(query) ||
          ad.contains(query) ||
          soyad.contains(query) ||
          displayName.contains(query);

      final rolUydu =
          _seciliRolFiltresi == 'hepsi' || item['rol'] == _seciliRolFiltresi;

      return aramaUydu && rolUydu;
    }).toList();

    if (!notify || mounted) {
      setState(() => _filtrelenmisKullanicilar = yeniListe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firmaAdi = TenantManager.instance.firmaAdi.isEmpty
        ? 'Aktif Firma'
        : TenantManager.instance.firmaAdi;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Kullanıcı Yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      floatingActionButton: _yonetebilir
          ? FloatingActionButton.extended(
              onPressed: _islemSuruyor ? null : _kullaniciOlusturDialoguAc,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Kullanıcı Ekle'),
            )
          : null,
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _verileriYukle,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHero(firmaAdi),
                  const SizedBox(height: 20),
                  _buildFilterPanel(),
                  const SizedBox(height: 20),
                  if (!_yonetebilir) _buildReadOnlyNotice(),
                  if (!_yonetebilir) const SizedBox(height: 20),
                  if (_filtrelenmisKullanicilar.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filtrelenmisKullanicilar.map(_buildKullaniciCard),
                ],
              ),
            ),
    );
  }

  Widget _buildHero(String firmaAdi) {
    final toplam = _tumKullanicilar.length;
    final aktif =
        _tumKullanicilar.where((item) => item['aktif'] == true).length;
    final yonetici = _tumKullanicilar
        .where((item) => _adminRoller.contains(item['rol']))
        .length;
    final departman = _tumKullanicilar
        .map((item) => (item['rol'] ?? '').toString())
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3FAE), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              firmaAdi,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Firma içi kullanıcıları, rolleri ve erişim durumlarını tek ekrandan yönetin.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _heroStat('Toplam kullanıcı', '$toplam', Icons.people_outline),
              _heroStat('Aktif kayıt', '$aktif', Icons.check_circle_outline),
              _heroStat(
                  'Yönetici', '$yonetici', Icons.admin_panel_settings_outlined),
              _heroStat('Rol grubu', '$departman', Icons.hub_outlined),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 860;
          final aramaKutusu = TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'E-posta, ad soyad veya rol ara',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          );

          final rolSecici = DropdownButtonFormField<String>(
            initialValue: _seciliRolFiltresi,
            decoration: const InputDecoration(
              labelText: 'Rol filtresi',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: 'hepsi',
                child: Text('Tüm roller'),
              ),
              ..._filtreRolleri(),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _seciliRolFiltresi = value);
              _filtreleriUygula();
            },
          );

          final sayac = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '${_filtrelenmisKullanicilar.length} kayıt',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          );

          if (dar) {
            return Column(
              children: [
                aramaKutusu,
                const SizedBox(height: 12),
                rolSecici,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: sayac),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: aramaKutusu),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: rolSecici),
              const SizedBox(width: 12),
              sayac,
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFD97706)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu ekranda görüntüleme yetkiniz var. Kullanıcı ekleme ve rol değiştirme işlemleri yalnızca firma yöneticileri için açıktır.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _panelDecoration(),
      child: const Column(
        children: [
          Icon(Icons.people_outline, size: 44, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Bu filtrede kullanıcı bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Arama terimini veya rol filtresini değiştirin.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildKullaniciCard(Map<String, dynamic> kullanici) {
    final rol = (kullanici['rol'] ?? 'kullanici').toString();
    final aktif = kullanici['aktif'] == true;
    final rolRenk = _rolRenk(rol);
    final email = (kullanici['email'] ?? '-').toString();
    final gorunenIsim = _gorunenIsim(kullanici);
    final katilim = _tarihFormat(kullanici['katilim_tarihi']?.toString());
    final sonGiris = _zamanFormat(kullanici['created_at']?.toString());
    final korumali = rol == 'firma_sahibi';
    final rolEtiket = _rolEtiketi(rol);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final dar = constraints.maxWidth < 860;

              final bilgiAlani = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gorunenIsim,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );

              final aksiyonlar = _yonetebilir
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!korumali)
                          OutlinedButton.icon(
                            onPressed: _islemSuruyor
                                ? null
                                : () => _rolDialoguAc(kullanici),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('Rol Değiştir'),
                          ),
                        if (!korumali)
                          OutlinedButton.icon(
                            onPressed: _islemSuruyor
                                ? null
                                : () => _aktifPasifOnayi(kullanici),
                            icon: Icon(
                              aktif
                                  ? Icons.pause_circle_outline
                                  : Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(aktif ? 'Pasifleştir' : 'Aktifleştir'),
                          ),
                        if (!korumali)
                          OutlinedButton.icon(
                            onPressed: _islemSuruyor
                                ? null
                                : () => _firmadanCikarOnayi(kullanici),
                            icon: const Icon(Icons.person_remove_outlined,
                                size: 18),
                            label: const Text('Firmadan Çıkar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB91C1C),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                            ),
                          ),
                      ],
                    )
                  : const SizedBox.shrink();

              if (dar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _avatar(gorunenIsim, rolRenk),
                        const SizedBox(width: 14),
                        bilgiAlani,
                      ],
                    ),
                    if (_yonetebilir) ...[
                      const SizedBox(height: 16),
                      aksiyonlar,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(gorunenIsim, rolRenk),
                  const SizedBox(width: 14),
                  bilgiAlani,
                  const SizedBox(width: 16),
                  Flexible(child: aksiyonlar),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(Icons.badge_outlined, 'Rol', rolEtiket, rolRenk),
              _infoChip(
                aktif ? Icons.check_circle_outline : Icons.block_outlined,
                'Durum',
                aktif ? 'Aktif' : 'Pasif',
                aktif ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              ),
              _infoChip(
                Icons.calendar_today_outlined,
                'Katılım',
                katilim,
                const Color(0xFF2563EB),
              ),
              _infoChip(
                Icons.history_outlined,
                'Kayıt',
                sonGiris,
                const Color(0xFF64748B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String label, Color color) {
    final harf = label.isEmpty ? '?' : label.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 26,
      backgroundColor: color.withAlpha(32),
      child: Text(
        harf,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _kullaniciOlusturDialoguAc() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String seciliRol = 'kullanici';

    final sonuc = await showDialog<_KullaniciFormSonucu>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Kullanıcı Oluştur'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Parola',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: seciliRol,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(),
                    ),
                    items: _rolMenuItems(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => seciliRol = value);
                      }
                    },
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
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isEmpty || password.isEmpty || password.length < 6) {
                  return;
                }
                Navigator.of(ctx).pop(
                  _KullaniciFormSonucu(
                    email: email,
                    password: password,
                    rol: seciliRol,
                  ),
                );
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );

    emailController.dispose();
    passwordController.dispose();

    if (sonuc == null) return;

    try {
      setState(() => _islemSuruyor = true);

      final firmaId = TenantManager.instance.requireFirmaId;
      final response = await _adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: sonuc.email,
          password: sonuc.password,
          emailConfirm: true,
        ),
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Kullanıcı oluşturulamadı');
      }

      await _adminClient.from(DbTables.firmaKullanicilari).upsert({
        'firma_id': firmaId,
        'user_id': user.id,
        'rol': sonuc.rol,
        'aktif': true,
      }, onConflict: 'firma_id,user_id');

      await _senkronizeGlobalRolGuvenli(
        userId: user.id,
        firmaRol: sonuc.rol,
      );

      if (!mounted) return;
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı oluşturuldu')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      final mesaj = e.code == 'email_exists' || e.code == 'user_already_exists'
          ? 'Bu e-posta adresi zaten kullanımda'
          : 'Kullanıcı oluşturulamadı: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
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

  Future<void> _rolDialoguAc(Map<String, dynamic> kullanici) async {
    final mevcutRol = (kullanici['rol'] ?? 'kullanici').toString();
    String seciliRol = mevcutRol;

    final secim = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rol Değiştir'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (kullanici['email'] ?? '-').toString(),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: seciliRol,
                  decoration: const InputDecoration(
                    labelText: 'Yeni rol',
                    border: OutlineInputBorder(),
                  ),
                  items: _rolMenuItems(currentRole: mevcutRol),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => seciliRol = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(seciliRol),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (secim == null || secim == mevcutRol) return;

    try {
      setState(() => _islemSuruyor = true);

      await _adminClient
          .from(DbTables.firmaKullanicilari)
          .update({'rol': secim})
          .eq('id', kullanici['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      await _senkronizeGlobalRolGuvenli(
        userId: kullanici['user_id'].toString(),
        firmaRol: secim,
      );

      if (!mounted) return;
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol güncellendi: ${_rolEtiketi(secim)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol güncellenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Future<void> _aktifPasifOnayi(Map<String, dynamic> kullanici) async {
    final aktif = kullanici['aktif'] == true;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(aktif ? 'Kullanıcıyı Pasifleştir' : 'Kullanıcıyı Aktifleştir'),
        content: Text(
          '${kullanici['email']} için ${aktif ? 'pasif' : 'aktif'} duruma geçilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(aktif ? 'Pasifleştir' : 'Aktifleştir'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      setState(() => _islemSuruyor = true);
      await _adminClient
          .from(DbTables.firmaKullanicilari)
          .update({'aktif': !aktif})
          .eq('id', kullanici['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      await _senkronizeGlobalRolGuvenli(
        userId: kullanici['user_id'].toString(),
        firmaRol: (kullanici['rol'] ?? 'kullanici').toString(),
      );

      if (!mounted) return;
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aktif
              ? 'Kullanıcı pasifleştirildi'
              : 'Kullanıcı aktifleştirildi'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum güncellenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Future<void> _firmadanCikarOnayi(Map<String, dynamic> kullanici) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Firmadan Çıkar'),
        content: Text(
          '${kullanici['email']} kullanıcısı bu firmadan çıkarılacak. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      setState(() => _islemSuruyor = true);
      await _adminClient
          .from(DbTables.firmaKullanicilari)
          .delete()
          .eq('id', kullanici['id'])
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      await _senkronizeGlobalRolGuvenli(
        userId: kullanici['user_id'].toString(),
        firmaRol: 'kullanici',
      );

      if (!mounted) return;
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı firmadan çıkarıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı çıkarılamadı: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Future<void> _senkronizeGlobalRol({
    required String userId,
    required String firmaRol,
  }) async {
    final aktifUyelikler = await _adminClient
        .from(DbTables.firmaKullanicilari)
        .select('rol, aktif')
        .eq('user_id', userId)
        .eq('aktif', true);

    final aktifRoller = List<Map<String, dynamic>>.from(aktifUyelikler)
        .map((item) => (item['rol'] ?? '').toString())
        .where((item) => item.isNotEmpty)
        .toList();

    String hedefRol;
    if (aktifRoller.any(_adminRoller.contains)) {
      hedefRol = 'admin';
    } else if (aktifRoller.isNotEmpty) {
      hedefRol = _globalRoleForFirmaRole(aktifRoller.first);
    } else {
      hedefRol = _globalRoleForFirmaRole(firmaRol);
    }

    final payload = {
      'user_id': userId,
      'role': hedefRol,
      'aktif': true,
    };

    try {
      await _adminClient
          .from(DbTables.userRoles)
          .upsert(payload, onConflict: 'user_id');
      return;
    } catch (_) {
      final mevcut = await _adminClient
          .from(DbTables.userRoles)
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      final kayitlar = List<Map<String, dynamic>>.from(mevcut);
      if (kayitlar.isNotEmpty) {
        await _adminClient
            .from(DbTables.userRoles)
            .update({'role': hedefRol, 'aktif': true}).eq('id', kayitlar.first['id']);
      } else {
        await _adminClient.from(DbTables.userRoles).insert(payload);
      }
    }
  }

  Future<void> _senkronizeGlobalRolGuvenli({
    required String userId,
    required String firmaRol,
  }) async {
    try {
      await _senkronizeGlobalRol(userId: userId, firmaRol: firmaRol);
    } catch (e) {
      debugPrint('⚠️ Global rol senkronizasyonu atlandı: $e');
    }
  }

  List<DropdownMenuItem<String>> _rolMenuItems({String? currentRole}) {
    final secenekler = <_RolSecenegi>[
      ..._rolSecenekleri,
      if (currentRole == 'firma_sahibi')
        const _RolSecenegi('firma_sahibi', 'Firma Sahibi'),
    ];

    return secenekler
        .map(
          (item) => DropdownMenuItem<String>(
            value: item.value,
            child: Text(item.label),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem<String>> _filtreRolleri() {
    final roller = _tumKullanicilar
        .map((item) => (item['rol'] ?? '').toString())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return roller
        .map(
          (rol) => DropdownMenuItem<String>(
            value: rol,
            child: Text(_rolEtiketi(rol)),
          ),
        )
        .toList();
  }

  String _gorunenIsim(Map<String, dynamic> kullanici) {
    final ad = (kullanici['ad'] ?? '').toString().trim();
    final soyad = (kullanici['soyad'] ?? '').toString().trim();
    final displayName = (kullanici['display_name'] ?? '').toString().trim();
    final email = (kullanici['email'] ?? '').toString().trim();

    final tamAd = [ad, soyad].where((item) => item.isNotEmpty).join(' ').trim();
    if (tamAd.isNotEmpty) return tamAd;
    if (displayName.isNotEmpty && displayName != email) return displayName;
    if (email.isNotEmpty) return email;
    return (kullanici['user_id'] ?? '-').toString();
  }

  String _rolEtiketi(String rol) {
    switch (rol) {
      case 'firma_sahibi':
        return 'Firma Sahibi';
      case 'firma_admin':
        return 'Firma Yöneticisi';
      case 'yonetici':
        return 'Yönetici';
      case 'kullanici':
        return 'Kullanıcı';
      case 'personel':
        return 'Personel';
      case 'ik':
        return 'İnsan Kaynakları';
      case 'dokuma':
        return 'Dokuma';
      case 'konfeksiyon':
        return 'Konfeksiyon';
      case 'yikama':
        return 'Yıkama';
      case 'utu':
      case 'utu_paket':
      case 'paketleme':
        return 'Ütü / Paket';
      case 'ilik_dugme':
        return 'İlik Düğme';
      case 'kalite_kontrol':
        return 'Kalite Kontrol';
      case 'sevkiyat':
        return 'Sevkiyat';
      case 'sofor':
        return 'Şoför';
      case 'muhasebe':
      case 'muhasebeci':
        return 'Muhasebe';
      case 'tasarim':
        return 'Tasarım';
      case 'planlama':
        return 'Planlama';
      case 'satis':
        return 'Satış';
      case 'depo':
      case 'depocu':
        return 'Depo';
      case 'nakis':
        return 'Nakış';
      default:
        return rol;
    }
  }

  Color _rolRenk(String rol) {
    switch (rol) {
      case 'firma_sahibi':
        return const Color(0xFFD97706);
      case 'firma_admin':
        return const Color(0xFF7C3AED);
      case 'yonetici':
        return const Color(0xFF2563EB);
      case 'kullanici':
        return const Color(0xFF0F766E);
      case 'personel':
        return const Color(0xFF64748B);
      case 'ik':
        return const Color(0xFF4F46E5);
      case 'dokuma':
      case 'konfeksiyon':
      case 'yikama':
      case 'utu_paket':
      case 'ilik_dugme':
      case 'kalite_kontrol':
      case 'sevkiyat':
      case 'sofor':
      case 'nakis':
        return const Color(0xFF0F766E);
      case 'muhasebe':
      case 'muhasebeci':
        return const Color(0xFFB45309);
      case 'satis':
      case 'tasarim':
      case 'planlama':
      case 'depo':
      case 'depocu':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _globalRoleForFirmaRole(String firmaRole) {
    switch (firmaRole) {
      case 'firma_sahibi':
      case 'firma_admin':
        return 'admin';
      case 'yonetici':
      case 'kullanici':
      case 'ik':
      case 'muhasebe':
      case 'muhasebeci':
      case 'satis':
      case 'tasarim':
      case 'planlama':
        return 'kullanici';
      case 'dokumaci':
      case 'dokuma':
        return 'dokuma';
      case 'konfeksiyon':
      case 'konfeksiyoncu':
        return 'konfeksiyon';
      case 'yikama':
        return 'yikama';
      case 'utu':
      case 'utu_paket':
      case 'paketleme':
        return 'utu_paket';
      case 'ilik_dugme':
        return 'ilik_dugme';
      case 'kalite_kontrol':
        return 'kalite_kontrol';
      case 'sevkiyat':
        return 'sevkiyat';
      case 'sofor':
        return 'sofor';
      case 'depo':
      case 'depocu':
        return 'depo';
      case 'personel':
        return 'personel';
      case 'nakis':
        return 'nakis';
      default:
        return 'kullanici';
    }
  }

  String _tarihFormat(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  String _zamanFormat(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
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
    );
  }
}

class _RolSecenegi {
  final String value;
  final String label;

  const _RolSecenegi(this.value, this.label);
}

class _KullaniciFormSonucu {
  final String email;
  final String password;
  final String rol;

  const _KullaniciFormSonucu({
    required this.email,
    required this.password,
    required this.rol,
  });
}
