import 'dart:async';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/supabase_config.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'kullanici_listesi_ui.dart';


class KullaniciListesiPage extends StatefulWidget {
  const KullaniciListesiPage({super.key});

  @override
  State<KullaniciListesiPage> createState() => _KullaniciListesiPageState();
}

class _KullaniciListesiPageState extends State<KullaniciListesiPage> {
  List<Map<String, dynamic>> kullanicilar = [];
  List<Map<String, dynamic>> filtrelenmisKullanicilar = [];
  bool yukleniyor = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController aramaController = TextEditingController();
  String seciliRol = 'orgu_firmasi'; // ✅ Güvenli varsayılan rol
  String seciliFiltre = 'hepsi'; // Rol filtresi

  // Roller için tekil liste tanımı - En güvenli roller başta
  static const List<DropdownMenuItem<String>> rolItems = [
    DropdownMenuItem(value: 'orgu_firmasi', child: Text('Örgü Firması')),
    DropdownMenuItem(value: 'admin', child: Text('Admin')),
    DropdownMenuItem(value: DbTables.personel, child: Text('Personel')),
    DropdownMenuItem(value: 'ik', child: Text('İnsan Kaynakları')),
    
    // Üretim Aşamaları
    DropdownMenuItem(value: 'dokuma', child: Text('Dokuma')),
    DropdownMenuItem(value: 'konfeksiyon', child: Text('Konfeksiyon')),
    DropdownMenuItem(value: 'yikama', child: Text('Yıkama')),
    DropdownMenuItem(value: 'utu', child: Text('Ütü')),
    DropdownMenuItem(value: 'ilik_dugme', child: Text('İlik Düğme')),
    DropdownMenuItem(value: 'kalite_kontrol', child: Text('Kalite Kontrol')),
    DropdownMenuItem(value: 'paketleme', child: Text('Paketleme')),
    
    // Diğer Departmanlar
    DropdownMenuItem(value: 'sevkiyat', child: Text('Sevkiyat')),
    DropdownMenuItem(value: 'muhasebe', child: Text('Muhasebe')),
    DropdownMenuItem(value: 'satis', child: Text('Satış')),
    DropdownMenuItem(value: 'tasarim', child: Text('Tasarım')),
    DropdownMenuItem(value: 'planlama', child: Text('Planlama')),
    DropdownMenuItem(value: 'depo', child: Text('Depo')),
    
    // Eski Roller (uyumluluk için)
    DropdownMenuItem(value: 'kalite_personeli', child: Text('Kalite Personeli (Eski)')),
    DropdownMenuItem(value: 'sevkiyat_soforu', child: Text('Sevkiyat Şoförü (Eski)')),
    DropdownMenuItem(value: 'atolye_personeli', child: Text('Atölye Personeli (Eski)')),
    DropdownMenuItem(value: 'tekstil', child: Text('Tekstil (Eski)')),
    DropdownMenuItem(value: 'iplik', child: Text('İplik (Eski)')),
    DropdownMenuItem(value: 'orgu', child: Text('Örgü (Eski)')),
    DropdownMenuItem(value: 'nakis', child: Text('Nakış (Eski)')),
    DropdownMenuItem(value: 'utu_paket', child: Text('Ütü Paket (Eski)')),
    DropdownMenuItem(value: 'aksesuar', child: Text('Aksesuar (Eski)')),
    DropdownMenuItem(value: 'makine', child: Text('Makine (Eski)')),
    DropdownMenuItem(value: 'kimyasal', child: Text('Kimyasal (Eski)')),
    DropdownMenuItem(value: 'ambalaj', child: Text('Ambalaj (Eski)')),
    DropdownMenuItem(value: 'lojistik', child: Text('Lojistik (Eski)')),
    DropdownMenuItem(value: 'diger', child: Text('Diğer')),
  ];

  final adminClient = SupabaseConfig.adminClient;

  @override
  void initState() {
    super.initState();
    _kullanicilariGetir();
    // Debounce için timer ekleyelim
    aramaController.addListener(_onSearchChanged);
  }

  Timer? _debounceTimer;
  
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _aramaFiltrele();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    aramaController.removeListener(_onSearchChanged);
    emailController.dispose();
    passwordController.dispose();
    aramaController.dispose();
    super.dispose();
  }

  void _aramaFiltrele() {
    if (!mounted) return; // Widget dispose edildiyse çıkış yap
    
    final arama = aramaController.text.toLowerCase();
    final yeniFiltrelenmisListe = kullanicilar.where((kullanici) {
      final email = (kullanici['email'] ?? '').toString().toLowerCase();
      final rol = (kullanici['role'] ?? '').toString().toLowerCase();
      
      // Arama filtresi
      final aramaUygun = arama.isEmpty || 
          email.contains(arama) || 
          rol.contains(arama);
      
      // Rol filtresi
      final rolUygun = seciliFiltre == 'hepsi' || kullanici['role'] == seciliFiltre;
      
      return aramaUygun && rolUygun;
    }).toList();

    // Sadece liste gerçekten değiştiyse setState çağır
    if (mounted && _listeIcerikDegistiMi(yeniFiltrelenmisListe, filtrelenmisKullanicilar)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            filtrelenmisKullanicilar = yeniFiltrelenmisListe;
          });
        }
      });
    }
  }

  bool _listeIcerikDegistiMi(List<Map<String, dynamic>> yeniListe, List<Map<String, dynamic>> eskiListe) {
    if (yeniListe.length != eskiListe.length) return true;
    
    for (int i = 0; i < yeniListe.length; i++) {
      if (yeniListe[i]['user_id'] != eskiListe[i]['user_id']) return true;
      if (yeniListe[i]['email'] != eskiListe[i]['email']) return true;
      if (yeniListe[i]['role'] != eskiListe[i]['role']) return true;
    }
    return false;
  }

  Future<void> _kullanicilariGetir() async {
    setState(() => yukleniyor = true);
    try {
      // Auth.users tablosundan kullanıcıları çek
      final authUsers = await adminClient.auth.admin.listUsers();
      
      // User_roles tablosundan rolleri çek
      final roles = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select('user_id, role');

      final combined = authUsers.map((user) {
        final roleData = (roles as List).firstWhere(
          (r) => r['user_id'] == user.id,
          orElse: () => {'role': 'orgu_firmasi'},
        );
        
        return {
          'user_id': user.id,
          'email': user.email,
          'last_sign_in_at': user.lastSignInAt,
          'role': roleData['role'] ?? 'orgu_firmasi',
          'aktif': true, // Varsayılan olarak aktif kabul et
        };
      }).toList();

      setState(() {
        kullanicilar = List<Map<String, dynamic>>.from(combined);
        filtrelenmisKullanicilar = List<Map<String, dynamic>>.from(combined);
        yukleniyor = false;
      });
      _aramaFiltrele(); // Filtrelemeyi uygula
    } catch (e) {
      debugPrint('Kullanıcıları getirme hatası: $e');
      setState(() => yukleniyor = false);
      if (mounted) {
        context.showSnackBar('Kullanıcılar yüklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _rolDegistir(String userId, String yeniRol) async {
    try {
      // Geçerli rol değerlerini kontrol et
      final validRoles = rolItems.map((item) => item.value).toList();
      if (!validRoles.contains(yeniRol)) {
        context.showSnackBar('Geçersiz rol: $yeniRol');
        return;
      }

      final response = await Supabase.instance.client
          .from(DbTables.userRoles)
          .update({'role': yeniRol})
          .eq('user_id', userId);
      
      debugPrint('Rol güncelleme sonucu: $userId -> $yeniRol, response: $response');
      
      // Sadece yerel listede güncelle, tam yenileme yapma
      if (mounted) {
        setState(() {
          final userIndex = kullanicilar.indexWhere((u) => u['user_id'] == userId);
          if (userIndex != -1) {
            kullanicilar[userIndex]['role'] = yeniRol;
          }
          final filteredUserIndex = filtrelenmisKullanicilar.indexWhere((u) => u['user_id'] == userId);
          if (filteredUserIndex != -1) {
            filtrelenmisKullanicilar[filteredUserIndex]['role'] = yeniRol;
          }
        });
      }
      
      if (!mounted) return;
      context.showSnackBar('Rol başarıyla ${_getRoleDisplayName(yeniRol)} olarak değiştirildi');
    } catch (e) {
      debugPrint('Rol güncelleme hatası: $e');
      if (!mounted) return;
      context.showSnackBar('Rol güncellenirken hata oluştu: $e');
    }
  }

  Future<void> _aktifPasifDegistir(String userId, bool aktif) async {
    try {
      // aktif sütunu olmadığı için şimdilik bu işlemi devre dışı bırakıyoruz
      // Gelecekte aktif sütunu eklenirse bu kodu aktifleştirip kullanabiliriz
      debugPrint('Aktif/Pasif değiştirme: $userId -> $aktif (şimdilik devre dışı)');
      context.showSnackBar('Aktif/Pasif özelliği şu anda kullanılamıyor');
      // _kullanicilariGetir();
    } catch (e) {
      debugPrint('Aktif/Pasif hatası: $e');
    }
  }


  Future<void> _yeniKullaniciEkle() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      context.showSnackBar('E-posta ve şifre boş olamaz');
      return;
    }
    
    debugPrint('Seçili rol: $seciliRol'); // Debug için ekledik
    
    FocusScope.of(context).unfocus(); // Klavyeyi kapat
    setState(() => yukleniyor = true);
    try {
      // Admin kontrolü
      final currentUser = Supabase.instance.client.auth.currentUser;
      // Admin tüm yetkilere sahip - kullanıcı yönetimi yapabilir
      if (currentUser == null || !await _isAdmin(currentUser.id)) {
        if (!mounted) return;
        context.showSnackBar('Bu işlemi yapmak için yetkiniz yok.');
        setState(() => yukleniyor = false);
        return;
      }

      final response = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (response.user != null) {
        try {
          debugPrint('Kullanıcı oluşturuldu: ${response.user!.id}, rol ekleniyor: $seciliRol'); // Debug
          
          // Önce user_roles tablosundaki mevcut kaydı kontrol et
          final existingRole = await adminClient
              .from(DbTables.userRoles)
              .select('role')
              .eq('user_id', response.user!.id)
              .maybeSingle();

          if (existingRole == null) {
            // Sadece kayıt yoksa ekle
            debugPrint('Yeni rol kaydı ekleniyor...'); // Debug
            await adminClient.from(DbTables.userRoles).insert({
              'user_id': response.user!.id,
              'role': seciliRol,
            });
            debugPrint('Rol başarıyla eklendi'); // Debug
          } else {
            // Kayıt varsa güncelle
            debugPrint('Mevcut rol güncelleniyor...'); // Debug
            await adminClient
                .from(DbTables.userRoles)
                .update({'role': seciliRol})
                .eq('user_id', response.user!.id);
            debugPrint('Rol başarıyla güncellendi'); // Debug
          }

          // Kullanıcıyı aktif firmaya ekle (firma_kullanicilari) - RLS bypass için adminClient
          final firmaId = TenantManager.instance.firmaId;
          if (firmaId != null) {
            try {
              await adminClient.from(DbTables.firmaKullanicilari).upsert({
                'firma_id': firmaId,
                'user_id': response.user!.id,
                'rol': seciliRol == 'admin' ? 'firma_admin' : 'kullanici',
                'aktif': true,
              }, onConflict: 'firma_id,user_id');
              debugPrint('Kullanıcı firmaya eklendi: $firmaId');
            } catch (e) {
              debugPrint('firma_kullanicilari ekleme hatası: $e');
            }
          }

          // Formu temizle ve state'i güncelle
          emailController.clear();
          passwordController.clear();
          if (!mounted) return;
          setState(() {
            seciliRol = 'orgu_firmasi';
          });

          // Kullanıcı listesini yenile
          await _kullanicilariGetir();

          if (mounted) {
            context.showSnackBar('Kullanıcı başarıyla eklendi');
          }
        } catch (e) {
          debugPrint('user_roles tablosuna ekleme hatası: $e');
          // Constraint hatası için özel mesaj
          if (e.toString().contains('user_roles_role_check')) {
            if (mounted) {
              context.showSnackBar('Seçilen rol ($seciliRol) database\'de tanımlı değil. Lütfen geçerli bir rol seçin.');
            }
          } else {
            if (mounted) {
              context.showSnackBar('Rol eklenemedi: $e');
            }
          }
        }
      } else {
        if (mounted) {
          context.showSnackBar('Kullanıcı oluşturulamadı');
        }
      }
    } on AuthException catch (e) {
      if (e.code == 'email_exists' || e.code == 'user_already_exists') {
        // Auth sistemindeki mevcut kullanıcıyı bul
        try {
          final authUsers = await adminClient.auth.admin.listUsers();
          final existingUser = authUsers.firstWhere(
            (user) => user.email == email,
          );

          try {
            await adminClient.from(DbTables.userRoles).upsert({
              'user_id': existingUser.id,
              'role': seciliRol,
            }, onConflict: 'user_id');

            // Kullanıcıyı aktif firmaya ekle (firma_kullanicilari) - RLS bypass için adminClient
            final firmaId = TenantManager.instance.firmaId;
            if (firmaId != null) {
              try {
                await adminClient.from(DbTables.firmaKullanicilari).upsert({
                  'firma_id': firmaId,
                  'user_id': existingUser.id,
                  'rol': seciliRol == 'admin' ? 'firma_admin' : 'kullanici',
                  'aktif': true,
                }, onConflict: 'firma_id,user_id');
                debugPrint('Mevcut kullanıcı firmaya eklendi: $firmaId');
              } catch (e) {
                debugPrint('firma_kullanicilari ekleme hatası: $e');
              }
            }

            emailController.clear();
            passwordController.clear();
            if (!mounted) return;
            setState(() {
              seciliRol = 'orgu_firmasi';
            });
            await _kullanicilariGetir();
            if (mounted) {
              context.showSnackBar('Mevcut kullanıcıya rol eklendi');
            }
          } catch (roleError) {
            debugPrint('user_roles tablosuna ekleme hatası (mevcut kullanıcı): $roleError');
            if (mounted) {
              context.showSnackBar('Bu kullanıcının zaten bir rolü var veya rol eklenemedi: $roleError');
            }
          }
        } catch (findError) {
          debugPrint('Mevcut kullanıcı bulma hatası: $findError');
          if (mounted) {
            context.showSnackBar('Bu e-posta adresi zaten kullanımda');
          }
        }
      } else {
        debugPrint('Yeni kullanıcı ekleme hatası: $e');
        if (mounted) {
          context.showSnackBar('Hata: ${e.message}');
        }
      }
    } catch (e) {
      debugPrint('Yeni kullanıcı ekleme hatası: $e');
      if (mounted) {
        context.showSnackBar('Hata: $e');
      }
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  Future<void> _kullaniciSil(String userId) async {
    try {
      // Önce user_roles tablosundan kayıtları sil (foreign key constraints'lerden dolayı)
      await Supabase.instance.client
          .from(DbTables.userRoles)
          .delete()
          .eq('user_id', userId);

      // Sonra auth.users kaydını sil (Admin API Key ile)
      await adminClient.auth.admin.deleteUser(userId);

      // Listeyi yenile
      await _kullanicilariGetir();

      if (mounted) {
        setState(() {}); // Ekranı güncelle
        context.showSnackBar('Kullanıcı başarıyla silindi');
      }
    } catch (e) {
      debugPrint('Kullanıcı silme hatası: $e');
      if (mounted) {
        context.showSnackBar('Kullanıcı silinemedi: $e');
      }
    }
  }
  Future<bool> _isAdmin(String userId) async {
    try {
      debugPrint('Admin kontrolü yapılıyor: $userId');
      final response = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null || response['role'] == null) {
        debugPrint('Kullanıcı rolü bulunamadı');
        return false;
      }
      debugPrint('Kullanıcı rolü: ${response['role']}');
      return response['role'] == 'admin';
    } catch (e) {
      debugPrint('Admin kontrol hatası: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800; // 800px üzerinde masaüstü kabul et
    
    debugPrint('Mevcut kullanıcı: ${currentUser?.id}');
    
    return FutureBuilder<bool>(
      future: currentUser != null ? _isAdmin(currentUser.id) : Future.value(false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          debugPrint('Admin kontrolünde hata: ${snapshot.error}');
          return Scaffold(
            body: Center(child: Text('Bir hata oluştu: ${snapshot.error}')),
          );
        }
          if (!snapshot.hasData || !snapshot.data!) {
          debugPrint('Kullanıcı admin değil veya aktif değil');
          Navigator.of(context).popUntil((route) => route.isFirst);
          return const Scaffold(
            body: Center(child: Text('Bu sayfayı görüntüleme yetkiniz yok. Ana sayfaya yönlendiriliyorsunuz...')),
          );
        }
        
        // Admin kontrolü başarılı, normal sayfayı göster
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kullanıcı Yönetimi'),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: yukleniyor
              ? const LoadingWidget()
              : SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1000 : double.infinity,
                        minHeight: MediaQuery.of(context).size.height - 100,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 24 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          // Yeni kullanıcı ekleme kartı
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person_add, color: Colors.blue.shade700, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Yeni Kullanıcı Ekle',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  isDesktop ? Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: emailController,
                                          decoration: InputDecoration(
                                            labelText: 'E-posta',
                                            prefixIcon: const Icon(Icons.email),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: passwordController,
                                          decoration: InputDecoration(
                                            labelText: 'Parola',
                                            prefixIcon: const Icon(Icons.lock),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          obscureText: true,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: seciliRol,
                                          decoration: InputDecoration(
                                            labelText: 'Rol',
                                            prefixIcon: const Icon(Icons.admin_panel_settings),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          items: rolItems,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                seciliRol = val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: _yeniKullaniciEkle,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Ekle'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) : Column(
                                    children: [
                                      TextField(
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          labelText: 'E-posta',
                                          prefixIcon: const Icon(Icons.email),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Parola',
                                          prefixIcon: const Icon(Icons.lock),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        obscureText: true,
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: seciliRol,
                                        decoration: InputDecoration(
                                          labelText: 'Rol',
                                          prefixIcon: const Icon(Icons.admin_panel_settings),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: rolItems,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              seciliRol = val;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: _yeniKullaniciEkle,
                                          icon: const Icon(Icons.add),
                                          label: const Text('Kullanıcı Ekle'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Arama ve filtreleme kartı
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.search, color: Colors.blue.shade700, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Kullanıcı Ara ve Filtrele',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  isDesktop ? Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: aramaController,
                                          decoration: InputDecoration(
                                            hintText: 'E-posta veya rol ara...',
                                            prefixIcon: const Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: seciliFiltre,
                                          decoration: InputDecoration(
                                            labelText: 'Rol Filtresi',
                                            prefixIcon: const Icon(Icons.filter_list),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'hepsi', child: Text('Tüm Roller')),
                                            ...rolItems,
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                seciliFiltre = val;
                                              });
                                              _aramaFiltrele();
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Text(
                                          '${filtrelenmisKullanicilar.length} kullanıcı',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ) : Column(
                                    children: [
                                      TextField(
                                        controller: aramaController,
                                        decoration: InputDecoration(
                                          hintText: 'E-posta veya rol ara...',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: seciliFiltre,
                                        decoration: InputDecoration(
                                          labelText: 'Rol Filtresi',
                                          prefixIcon: const Icon(Icons.filter_list),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'hepsi', child: Text('Tüm Roller')),
                                          ...rolItems,
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              seciliFiltre = val;
                                            });
                                            _aramaFiltrele();
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${filtrelenmisKullanicilar.length} kullanıcı bulundu',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Kullanıcı listesi
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6, // Ekran yüksekliğinin %60'ı
                            child: filtrelenmisKullanicilar.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Kullanıcı bulunamadı',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Arama kriterlerinizi değiştirmeyi deneyin',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filtrelenmisKullanicilar.length,
                                    itemBuilder: (context, index) {
                                      final user = filtrelenmisKullanicilar[index];
                                      final aktif = user['aktif'] == true;
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor: Colors.blue.shade100,
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.blue.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          user['email'] ?? '-',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: _getRoleColor(user['role']),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            _getRoleDisplayName(user['role']),
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Son Giriş: ${formatLastSignIn(user['last_sign_in_at'])}',
                                                              style: TextStyle(
                                                                color: Colors.grey.shade600,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Switch(
                                                        value: aktif,
                                                        onChanged: (val) => _aktifPasifDegistir(user['user_id'], val),
                                                        activeThumbColor: Colors.green,
                                                      ),
                                                      PopupMenuButton<String>(
                                                        icon: const Icon(Icons.more_vert),
                                                        onSelected: (value) async {
                                                          switch (value) {
                                                            case 'edit':
                                                              await _kullaniciDuzenleDialog(user);
                                                              break;
                                                            case 'delete':
                                                              final onay = await showDialog<bool>(
                                                                context: context,
                                                                builder: (ctx) => AlertDialog(
                                                                  title: const Text('Kullanıcıyı Sil'),
                                                                  content: Text('${user['email']} kullanıcısını silmek istediğinize emin misiniz?'),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(ctx, false),
                                                                      child: const Text('İptal'),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () => Navigator.pop(ctx, true),
                                                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                                      child: const Text('Sil'),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                              if (onay == true) {
                                                                await _kullaniciSil(user['user_id']);
                                                              }
                                                              break;
                                                          }
                                                        },
                                                        itemBuilder: (context) => [
                                                          const PopupMenuItem(
                                                            value: 'edit',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.edit, size: 20),
                                                                SizedBox(width: 8),
                                                                Text('Düzenle'),
                                                              ],
                                                            ),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.delete, size: 20, color: Colors.red),
                                                                SizedBox(width: 8),
                                                                Text('Sil', style: TextStyle(color: Colors.red)),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              isDesktop ? Row(
                                                children: [
                                                  Expanded(
                                                    child: DropdownButtonFormField<String>(
                                                      initialValue: rolItems.any((item) => item.value == user['role']) 
                                                          ? user['role'] 
                                                          : 'orgu_firmasi',
                                                      decoration: InputDecoration(
                                                        labelText: 'Rol Değiştir',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      ),
                                                      items: rolItems,
                                                      onChanged: (val) {
                                                        if (val != null && val != user['role']) {
                                                          _rolDegistir(user['user_id'], val);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ) : DropdownButtonFormField<String>(
                                                initialValue: rolItems.any((item) => item.value == user['role']) 
                                                    ? user['role'] 
                                                    : 'orgu_firmasi',
                                                decoration: InputDecoration(
                                                  labelText: 'Rol Değiştir',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                ),
                                                items: rolItems,
                                                onChanged: (val) {
                                                  if (val != null && val != user['role']) {
                                                    _rolDegistir(user['user_id'], val);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ), // Column
                    ), // Padding
                  ), // ConstrainedBox
                ), // Center
              ), // SingleChildScrollView
        ); // Scaffold
      },
    );
  }
}
