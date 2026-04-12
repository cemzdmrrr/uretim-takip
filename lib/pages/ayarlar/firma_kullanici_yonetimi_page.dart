import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/services/yetki_service.dart';
import 'package:uretim_takip/services/firma_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

/// Firma bazlı kullanıcı yönetimi — roller, davet, aktif/pasif.
class FirmaKullaniciYonetimiPage extends StatefulWidget {
  const FirmaKullaniciYonetimiPage({super.key});

  @override
  State<FirmaKullaniciYonetimiPage> createState() =>
      _FirmaKullaniciYonetimiPageState();
}

class _FirmaKullaniciYonetimiPageState
    extends State<FirmaKullaniciYonetimiPage> {
  List<Map<String, dynamic>> _kullanicilar = [];
  List<Map<String, dynamic>> _firmalar = [];
  bool _yukleniyor = true;
  String? _seciliFirmaId;
  String _seciliFirmaAdi = '';

  @override
  void initState() {
    super.initState();
    _firmalariYukle();
  }

  Future<void> _firmalariYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final firmalar = await PlatformAdminService.firmalariGetir(sadecAktif: true);
      if (!mounted) return;
      setState(() {
        _firmalar = firmalar;
        // Mevcut aktif firma varsa onu seç
        final mevcutFirmaId = TenantManager.instance.firmaId;
        if (mevcutFirmaId != null &&
            firmalar.any((f) => f['id'] == mevcutFirmaId)) {
          _seciliFirmaId = mevcutFirmaId;
          _seciliFirmaAdi = TenantManager.instance.firmaAdi;
        } else if (firmalar.isNotEmpty) {
          _seciliFirmaId = firmalar.first['id']?.toString();
          _seciliFirmaAdi = firmalar.first['firma_adi']?.toString() ?? '';
        }
      });
      if (_seciliFirmaId != null) {
        await _kullanicilariYukle();
      } else {
        setState(() => _yukleniyor = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firmalar yüklenirken hata: $e')),
      );
    }
  }

  Future<void> _kullanicilariYukle() async {
    if (_seciliFirmaId == null) return;
    setState(() => _yukleniyor = true);
    try {
      final response = await Supabase.instance.client
          .rpc('firma_kullanicilari_detay', params: {'p_firma_id': _seciliFirmaId});
      final kullanicilar = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;
      setState(() {
        _kullanicilar = kullanicilar;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _kullanicilar = [];
        _yukleniyor = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar yüklenirken hata: $e')),
      );
    }
  }

  Future<void> _rolDegistir(Map<String, dynamic> kullanici) async {
    final mevcutRol = kullanici['rol'] as String? ?? 'kullanici';
    String? secilenRol = mevcutRol;

    final onay = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Rol Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kullanıcı: ${kullanici['user_id']}',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: secilenRol,
                decoration: const InputDecoration(
                  labelText: 'Yeni Rol',
                  border: OutlineInputBorder(),
                ),
                items: YetkiService.tumRoller
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              YetkiService.rolEtiketleri[r] ?? r),
                        ))
                    .toList(),
                onChanged: (v) => setDState(() => secilenRol = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, secilenRol),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (onay == null || onay == mevcutRol || !mounted) return;

    try {
      await YetkiService.kullaniciRolDegistir(
        firmaKullaniciId: kullanici['id'],
        yeniRol: onay,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Rol değiştirildi: ${YetkiService.rolEtiketleri[onay] ?? onay}'),
          backgroundColor: Colors.green,
        ),
      );
      _kullanicilariYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol değiştirme hatası: $e')),
      );
    }
  }

  Future<void> _aktifPasifToggle(Map<String, dynamic> kullanici) async {
    final aktif = kullanici['aktif'] as bool? ?? true;
    try {
      await YetkiService.kullaniciAktifPasif(
        firmaKullaniciId: kullanici['id'],
        aktif: !aktif,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(!aktif ? 'Kullanıcı aktifleştirildi' : 'Kullanıcı pasifleştirildi'),
          backgroundColor: !aktif ? Colors.green : Colors.orange,
        ),
      );
      _kullanicilariYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _kullaniciCikar(Map<String, dynamic> kullanici) async {
    // firma_sahibi çıkarılamaz
    if (kullanici['rol'] == 'firma_sahibi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firma sahibi çıkarılamaz')),
      );
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Çıkar'),
        content: const Text(
          'Bu kullanıcıyı firmadan çıkarmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    try {
      await YetkiService.kullaniciCikar(kullanici['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı firmadan çıkarıldı'),
          backgroundColor: Colors.orange,
        ),
      );
      _kullanicilariYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _yeniKullaniciDavetEt() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String secilenRol = 'kullanici';

    final onay = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Kullanıcı Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'kullanici@firma.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  hintText: 'En az 6 karakter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: secilenRol,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  border: OutlineInputBorder(),
                ),
                items: YetkiService.tumRoller
                    .where((r) => r != 'firma_sahibi')
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              YetkiService.rolEtiketleri[r] ?? r),
                        ))
                    .toList(),
                onChanged: (v) => setDState(() => secilenRol = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) return;
                if (password.length < 6) return;
                Navigator.pop(ctx, {'email': email, 'password': password, 'rol': secilenRol});
              },
              child: const Text('Kullanıcı Oluştur'),
            ),
          ],
        ),
      ),
    );

    if (onay == null || !mounted) return;

    try {
      final firmaId = _seciliFirmaId;
      if (firmaId == null) throw Exception('Firma seçili değil');

      // 1. Auth kullanıcısı oluştur
      final adminClient = SupabaseConfig.adminClient;
      final response = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: onay['email']!,
          password: onay['password']!,
          emailConfirm: true,
        ),
      );

      if (response.user == null) throw Exception('Kullanıcı oluşturulamadı');
      final newUserId = response.user!.id;

      // 2. user_roles tablosuna ekle
      try {
        await adminClient.from(DbTables.userRoles).upsert({
          'user_id': newUserId,
          'role': onay['rol'] == 'firma_admin' ? 'admin' : 'user',
        }, onConflict: 'user_id');
      } catch (e) {
        debugPrint('user_roles ekleme hatası: $e');
      }

      // 3. firma_kullanicilari tablosuna ekle (EN ÖNEMLİ ADIM) - RLS bypass için adminClient
      await adminClient.from(DbTables.firmaKullanicilari).upsert({
        'firma_id': firmaId,
        'user_id': newUserId,
        'rol': onay['rol'] ?? 'kullanici',
        'aktif': true,
      }, onConflict: 'firma_id,user_id');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı oluşturuldu: ${onay['email']}'),
          backgroundColor: Colors.green,
        ),
      );
      _kullanicilariYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı oluşturma hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcılar — $_seciliFirmaAdi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _seciliFirmaId != null
          ? FloatingActionButton.extended(
              onPressed: _yeniKullaniciDavetEt,
              icon: const Icon(Icons.person_add),
              label: const Text('Kullanıcı Ekle'),
            )
          : null,
      body: Column(
        children: [
          // Firma seçici
          if (_firmalar.length > 1)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              color: Colors.grey.shade50,
              child: DropdownButtonFormField<String>(
                value: _seciliFirmaId,
                decoration: InputDecoration(
                  labelText: 'Firma Seçin',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _firmalar.map((f) {
                  final id = f['id']?.toString() ?? '';
                  final adi = f['firma_adi']?.toString() ?? '';
                  final kodu = f['firma_kodu']?.toString() ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text('$adi ($kodu)'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final firma = _firmalar.firstWhere(
                      (f) => f['id']?.toString() == v,
                      orElse: () => {});
                  setState(() {
                    _seciliFirmaId = v;
                    _seciliFirmaAdi =
                        firma['firma_adi']?.toString() ?? '';
                  });
                  _kullanicilariYukle();
                },
              ),
            ),
          // Kullanıcı listesi
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _kullanicilariYukle,
                    child: _seciliFirmaId == null
                        ? const Center(
                            child: Text('Firma seçin',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)))
                        : _kullanicilar.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.people_outline,
                                            size: 64, color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text('Henüz kullanıcı yok',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _kullanicilar.length,
                                itemBuilder: (_, i) =>
                                    _kullaniciKarti(_kullanicilar[i]),
                              ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kullaniciKarti(Map<String, dynamic> kullanici) {
    final rol = kullanici['rol'] as String? ?? 'kullanici';
    final aktif = kullanici['aktif'] as bool? ?? true;
    final katilim = kullanici['katilim_tarihi'];
    final rolEtiket = YetkiService.rolEtiketleri[rol] ?? rol;
    final email = kullanici['email']?.toString() ?? '';
    final ad = kullanici['ad']?.toString() ?? '';
    final soyad = kullanici['soyad']?.toString() ?? '';
    final displayName = kullanici['display_name']?.toString() ?? '';
    
    // Görüntülenecek ismi belirle
    String gorunenIsim;
    if (ad.isNotEmpty || soyad.isNotEmpty) {
      gorunenIsim = '$ad $soyad'.trim();
    } else if (displayName.isNotEmpty && displayName != email) {
      gorunenIsim = displayName;
    } else if (email.isNotEmpty) {
      gorunenIsim = email;
    } else {
      gorunenIsim = kullanici['user_id']?.toString()?.substring(0, 8) ?? '-';
    }

    Color rolRenk;
    switch (rol) {
      case 'firma_sahibi':
        rolRenk = Colors.amber.shade800;
      case 'firma_admin':
        rolRenk = Colors.indigo;
      case 'yonetici':
        rolRenk = Colors.blue;
      case 'kullanici':
        rolRenk = Colors.teal;
      case 'personel':
        rolRenk = Colors.grey;
      default:
        rolRenk = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: aktif
            ? BorderSide.none
            : const BorderSide(color: Colors.red, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rolRenk.withValues(alpha: 0.15),
          child: Icon(
            rol == 'firma_sahibi'
                ? Icons.star
                : rol == 'firma_admin'
                    ? Icons.admin_panel_settings
                    : Icons.person,
            color: rolRenk,
          ),
        ),
        title: Text(
          gorunenIsim,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: aktif ? null : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty && gorunenIsim != email)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: rolRenk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rolEtiket,
                    style: TextStyle(
                      color: rolRenk,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (!aktif) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Pasif',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (katilim != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _tarihFormat(katilim.toString()),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'rol':
                _rolDegistir(kullanici);
              case 'toggle':
                _aktifPasifToggle(kullanici);
              case 'cikar':
                _kullaniciCikar(kullanici);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'rol',
              child: ListTile(
                leading: Icon(Icons.swap_horiz),
                title: Text('Rol Değiştir'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(aktif ? Icons.block : Icons.check_circle),
                title: Text(aktif ? 'Pasifleştir' : 'Aktifleştir'),
                dense: true,
              ),
            ),
            if (rol != 'firma_sahibi')
              const PopupMenuItem(
                value: 'cikar',
                child: ListTile(
                  leading:
                      Icon(Icons.person_remove, color: Colors.red),
                  title: Text('Firmadan Çıkar',
                      style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _tarihFormat(String tarihStr) {
    final tarih = DateTime.tryParse(tarihStr);
    if (tarih == null) return '';
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }
}
