// ignore_for_file: invalid_use_of_protected_member
part of 'sevk_yonetimi_page.dart';

/// Admin tabs and operations for _SevkYonetimiPageState.
extension _AdminTabsExt on _SevkYonetimiPageState {

  // Admin Tabs
  Widget _buildAdminGenelBakisTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sistem Genel Bakış - Admin Panel',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAdminCard(
                  'Toplam Kullanıcılar',
                  '${atanmisModeller.length + sevkTalepleri.length}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildAdminCard(
                  'Aktif Sevkiyatlar',
                  '${sevkTalepleri.length}',
                  Icons.local_shipping,
                  Colors.green,
                ),
                _buildAdminCard(
                  'Bekleyen Onaylar',
                  '${sevkTalepleri.where((t) => t['durum'] == 'kalite_onay').length}',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildAdminCard(
                  'Tamamlanan İşler',
                  '${atanmisModeller.where((m) => (m['yuklenen_adet'] ?? 0) >= (m['toplam_adet'] ?? 1)).length}',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminKullaniciYonetimiTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Kullanıcı Yönetimi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showKullaniciEkleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Kullanıcı Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tumKullanicilar.isEmpty 
                ? const Center(child: Text('Henüz kullanıcı bulunmuyor'))
                : ListView.builder(
                    itemCount: tumKullanicilar.length,
                    itemBuilder: (context, index) {
                      final user = tumKullanicilar[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user['role'] as String),
                            child: Text(
                              (user['email'] as String).substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user['email'] as String),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rol: ${_getRoleDisplayName(user['role'] as String)}'),
                              if (user['last_sign_in_at'] != null)
                                Text('Son Giriş: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(user['last_sign_in_at']))}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Düzenle'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Sil'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showKullaniciDuzenleDialog(user);
                              } else if (value == 'delete') {
                                _showKullaniciSilDialog(user);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSistemAyarlariTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sistem Ayarları',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildAyarKarti(
                  'Veritabanı Yönetimi',
                  'Tabloları görüntüle ve yönet',
                  Icons.storage,
                  () => _showDatabaseManagement(),
                ),
                _buildAyarKarti(
                  'Yedekleme & Geri Yükleme',
                  'Sistem verilerini yedekle',
                  Icons.backup,
                  () => _showBackupOptions(),
                ),
                _buildAyarKarti(
                  'Güvenlik Ayarları',
                  'RLS politikalarını yönet',
                  Icons.security,
                  () => _showSecuritySettings(),
                ),
                _buildAyarKarti(
                  'Bildirim Ayarları',
                  'Sistem bildirimlerini ayarla',
                  Icons.notifications_active,
                  () => _showNotificationSettings(),
                ),
                _buildAyarKarti(
                  'Raporlar',
                  'Sistem raporlarını görüntüle',
                  Icons.analytics,
                  () => _showSystemReports(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyarKarti(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Future<void> _loadAllUsers() async {
    try {
      // Auth.users tablosundan kullanıcıları çek
      final authUsers = await adminClient.auth.admin.listUsers();
      
      // User_roles tablosundan rolleri çek
      final roles = await supabase
          .from(DbTables.userRoles)
          .select('user_id, role');

      final combined = authUsers.map((user) {
        final roleData = (roles as List).firstWhere(
          (r) => r['user_id'] == user.id,
          orElse: () => {'role': 'user'},
        );
        
        return {
          'user_id': user.id,
          'email': user.email,
          'last_sign_in_at': user.lastSignInAt,
          'role': roleData['role'] ?? 'user',
        };
      }).toList();

      tumKullanicilar = List<Map<String, dynamic>>.from(combined);
    } catch (e) {
      debugPrint('Kullanıcıları yüklerken hata: $e');
      tumKullanicilar = [];
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'orgu_firmasi': return Colors.blue;
      case 'kalite_personeli': return Colors.green;
      case 'sevkiyat_soforu': return Colors.purple;
      case 'atolye_personeli': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin': return 'Administrator';
      case 'orgu_firmasi': return 'Örgü Firması';
      case 'kalite_personeli': return 'Kalite Personeli';
      case 'sevkiyat_soforu': return 'Sevkiyat Şoförü';
      case 'atolye_personeli': return 'Atölye Personeli';
      default: return role;
    }
  }

  void _showKullaniciEkleDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String seciliRol = 'orgu_firmasi';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Kullanıcı Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Rolü',
                  border: OutlineInputBorder(),
                ),
                initialValue: seciliRol,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  DropdownMenuItem(value: 'orgu_firmasi', child: Text('Örgü Firması')),
                  DropdownMenuItem(value: 'kalite_personeli', child: Text('Kalite Personeli')),
                  DropdownMenuItem(value: 'sevkiyat_soforu', child: Text('Sevkiyat Şoförü')),
                  DropdownMenuItem(value: 'atolye_personeli', child: Text('Atölye Personeli')),
                  DropdownMenuItem(value: 'tekstil', child: Text('Tekstil')),
                  DropdownMenuItem(value: 'iplik', child: Text('İplik')),
                  DropdownMenuItem(value: 'orgu', child: Text('Örgü')),
                  DropdownMenuItem(value: 'dokuma', child: Text('Dokuma')),
                  DropdownMenuItem(value: 'konfeksiyon', child: Text('Konfeksiyon')),
                  DropdownMenuItem(value: 'nakis', child: Text('Nakış')),
                  DropdownMenuItem(value: 'utu_paket', child: Text('Ütü Paket')),
                  DropdownMenuItem(value: 'yikama', child: Text('Yıkama')),
                  DropdownMenuItem(value: 'ilik_dugme', child: Text('İlik Düğme')),
                  DropdownMenuItem(value: 'aksesuar', child: Text('Aksesuar')),
                  DropdownMenuItem(value: 'makine', child: Text('Makine')),
                  DropdownMenuItem(value: 'kimyasal', child: Text('Kimyasal')),
                  DropdownMenuItem(value: 'ambalaj', child: Text('Ambalaj')),
                  DropdownMenuItem(value: 'lojistik', child: Text('Lojistik')),
                  DropdownMenuItem(value: 'diger', child: Text('Diğer')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    seciliRol = value ?? 'orgu_firmasi';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _yeniKullaniciEkle(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                  seciliRol,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Kullanıcı Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showKullaniciDuzenleDialog(Map<String, dynamic> user) {
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String seciliRol = user['role'] ?? 'orgu_firmasi';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${user['email']} Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (boş bırakın değiştirmek istemiyorsanız)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Rolü',
                  border: OutlineInputBorder(),
                ),
                initialValue: seciliRol,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  DropdownMenuItem(value: 'orgu_firmasi', child: Text('Örgü Firması')),
                  DropdownMenuItem(value: 'kalite_personeli', child: Text('Kalite Personeli')),
                  DropdownMenuItem(value: 'sevkiyat_soforu', child: Text('Sevkiyat Şoförü')),
                  DropdownMenuItem(value: 'atolye_personeli', child: Text('Atölye Personeli')),
                  DropdownMenuItem(value: 'tekstil', child: Text('Tekstil')),
                  DropdownMenuItem(value: 'iplik', child: Text('İplik')),
                  DropdownMenuItem(value: 'orgu', child: Text('Örgü')),
                  DropdownMenuItem(value: 'dokuma', child: Text('Dokuma')),
                  DropdownMenuItem(value: 'konfeksiyon', child: Text('Konfeksiyon')),
                  DropdownMenuItem(value: 'nakis', child: Text('Nakış')),
                  DropdownMenuItem(value: 'utu_paket', child: Text('Ütü Paket')),
                  DropdownMenuItem(value: 'yikama', child: Text('Yıkama')),
                  DropdownMenuItem(value: 'ilik_dugme', child: Text('İlik Düğme')),
                  DropdownMenuItem(value: 'aksesuar', child: Text('Aksesuar')),
                  DropdownMenuItem(value: 'makine', child: Text('Makine')),
                  DropdownMenuItem(value: 'kimyasal', child: Text('Kimyasal')),
                  DropdownMenuItem(value: 'ambalaj', child: Text('Ambalaj')),
                  DropdownMenuItem(value: 'lojistik', child: Text('Lojistik')),
                  DropdownMenuItem(value: 'diger', child: Text('Diğer')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    seciliRol = value ?? 'orgu_firmasi';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _kullaniciGuncelle(
                  user['user_id'],
                  emailController.text.trim(),
                  passwordController.text.trim(),
                  seciliRol,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showKullaniciSilDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '${user['email']} kullanıcısını kalıcı olarak silmek istediğinizden emin misiniz?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _kullaniciSil(user['user_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _yeniKullaniciEkle(String email, String password, String role) async {
    if (email.isEmpty || password.isEmpty) {
      context.showSnackBar('E-posta ve şifre alanları boş olamaz');
      return;
    }

    try {
      setState(() => yukleniyor = true);

      // Yeni kullanıcı oluştur
      final response = await adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (response.user != null) {
        try {
          // Kullanıcı rolünü ekle - sadece gerekli kolonlar
          final roleData = {
            'user_id': response.user!.id,
            'role': role,
          };
          
          // Eğer yetki_seviyesi kolonu varsa ekle
          try {
            roleData['yetki_seviyesi'] = role;
            await supabase.from(DbTables.userRoles).insert(roleData);
          } catch (columnError) {
            debugPrint('Yetki seviyesi kolonu bulunamadı, sadece role ile ekleniyor: $columnError');
            // Sadece temel kolonlarla tekrar dene
            await supabase.from(DbTables.userRoles).insert({
              'user_id': response.user!.id,
              'role': role,
            });
          }

          if (!mounted) return;
          context.showSnackBar('Kullanıcı başarıyla eklendi');

          // Verileri yenile
          await _loadData();
        } catch (roleError) {
          // Eğer rol eklenemezse kullanıcıyı sil
          debugPrint('Rol ekleme hatası: $roleError');
          try {
            await adminClient.auth.admin.deleteUser(response.user!.id);
          } catch (deleteError) {
            debugPrint('Kullanıcı silme hatası: $deleteError');
          }
          
          if (!mounted) return;
          context.showSnackBar('Kullanıcı rolü eklenemedi: $roleError');
        }
      } else {
        if (!mounted) return;
        context.showSnackBar('Kullanıcı oluşturulamadı');
      }
    } on AuthException catch (e) {
      debugPrint('Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'email_exists' || e.code == 'user_already_exists' || e.code == 'email_already_exists') {
        if (!mounted) return;
        context.showSnackBar('Bu e-posta adresi zaten kullanımda');
      } else {
        if (!mounted) return;
        context.showSnackBar('Auth hatası: ${e.message}');
      }
    } catch (e) {
      debugPrint('Genel hata: $e');
      if (!mounted) return;
      context.showSnackBar('Kullanıcı eklenirken hata oluştu: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _kullaniciGuncelle(String userId, String email, String password, String role) async {
    try {
      setState(() => yukleniyor = true);

      // Şifre güncelle (eğer yeni şifre girilmişse)
      if (password.isNotEmpty) {
        await adminClient.auth.admin.updateUserById(
          userId,
          attributes: AdminUserAttributes(password: password),
        );
      }

      // E-posta güncelle (eğer değişmişse)
      if (email.isNotEmpty) {
        await adminClient.auth.admin.updateUserById(
          userId,
          attributes: AdminUserAttributes(email: email),
        );
      }

      // Rol güncelle
      await supabase.from(DbTables.userRoles).update({
        'role': role,
      }).eq('user_id', userId);

      if (!mounted) return;
      context.showSnackBar('Kullanıcı başarıyla güncellendi');

      // Verileri yenile
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Kullanıcı güncellenirken hata oluştu: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _kullaniciSil(String userId) async {
    try {
      setState(() => yukleniyor = true);

      // Önce user_roles tablosundan sil
      await supabase
          .from(DbTables.userRoles)
          .delete()
          .eq('user_id', userId);

      // Sonra auth.users tablosundan sil
      await adminClient.auth.admin.deleteUser(userId);

      if (!mounted) return;
      context.showSnackBar('Kullanıcı başarıyla silindi');

      // Verileri yenile
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Kullanıcı silinirken hata oluştu: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }



  void _showDatabaseManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veritabanı Yönetimi'),
        content: const Text('Veritabanı yönetim araçları buraya eklenecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedekleme Seçenekleri'),
        content: const Text('Yedekleme ve geri yükleme seçenekleri buraya eklenecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Ayarları'),
        content: const Text('RLS politikaları ve güvenlik ayarları buraya eklenecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Ayarları'),
        content: const Text('Bildirim ayarları buraya eklenecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSystemReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sistem Raporları'),
        content: const Text('Detaylı sistem raporları buraya eklenecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSevkTalebiDialog(Map<String, dynamic> model) async {
    final adetController = TextEditingController();
    String? secilenHedefAsama;
    String? secilenAtolyeId;
    List<Map<String, dynamic>> atolyeler = [];

    try {
      // Mevcut atölyeleri getir
      final atolyeResponse = await supabase.from(DbTables.atolyeler).select().eq('aktif', true).eq('firma_id', TenantManager.instance.requireFirmaId);
      atolyeler = List<Map<String, dynamic>>.from(atolyeResponse);
      
      // Demo atölye ekle (eğer veri yoksa)
      if (atolyeler.isEmpty) {
        atolyeler = [
          {'id': '1', 'atolye_adi': 'Konfeksiyon Atölyesi', 'atolye_tipi': 'konfeksiyon'},
          {'id': '2', 'atolye_adi': 'Yıkama Atölyesi', 'atolye_tipi': 'yikama'},
          {'id': '3', 'atolye_adi': 'İlik Düğme Atölyesi', 'atolye_tipi': 'ilik_dugme'},
          {'id': '4', 'atolye_adi': 'Ütü Atölyesi', 'atolye_tipi': 'utu'},
        ];
      }
    } catch (e) {
      debugPrint('Atölyeler yüklenirken hata: $e');
      // Demo atölye verileri
      atolyeler = [
        {'id': '1', 'atolye_adi': 'Demo Konfeksiyon', 'atolye_tipi': 'konfeksiyon'},
        {'id': '2', 'atolye_adi': 'Demo Yıkama', 'atolye_tipi': 'yikama'},
      ];
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sevk Talebi - ${model['marka']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sevk Edilecek Adet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Hedef Aşama',
                  border: OutlineInputBorder(),
                ),
                initialValue: secilenHedefAsama,
                items: [
                  'konfeksiyon',
                  'yikama',
                  'ilik_dugme',
                  'utu',
                ].map((asama) => DropdownMenuItem(
                  value: asama,
                  child: Text(_getAsamaText(asama)),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    secilenHedefAsama = value;
                    secilenAtolyeId = null; // Reset atölye seçimi
                  });
                },
              ),
              if (secilenHedefAsama != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Hedef Atölye',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: secilenAtolyeId,
                  items: atolyeler
                      .where((atolye) => atolye['atolye_tipi'] == secilenHedefAsama)
                      .map<DropdownMenuItem<String>>((atolye) => DropdownMenuItem<String>(
                        value: atolye['id'].toString(),
                        child: Text(atolye['atolye_adi']),
                      )).toList(),
                  onChanged: (value) {
                    setDialogState(() => secilenAtolyeId = value);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => _sevkTalebiOlustur(
                model['id'],
                int.tryParse(adetController.text) ?? 0,
                secilenHedefAsama ?? '',
                secilenAtolyeId ?? '',
              ),
              child: const Text('Talep Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sevkTalebiOlustur(String modelId, int adet, String hedefAsama, String atolyeId) async {
    try {
      // Sevk talebi oluştur
      await supabase.from(DbTables.sevkTalepleri).insert({
        'model_id': modelId,
        'gonderici_firma_id': kullaniciId,
        'hedef_atolye_id': atolyeId,
        'sevk_edilen_adet': adet,
        'durum': 'kalite_onay',
        'asama': 'orgu',
        'hedef_asama': hedefAsama,
      });

      if (!mounted) return;
      Navigator.pop(context);
      context.showSnackBar('Sevk talebi oluşturuldu');
      
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      context.showSnackBar('Demo modda - Sevk talebi simüle edildi');
      
      // Demo modda da veriyi güncelle
      await _loadData();
    }
  }

  Future<void> _kaliteOnayla(String talepId) async {
    try {
      await supabase.from(DbTables.sevkTalepleri).update({
        'durum': 'sevk_hazir',
        'kalite_onay_tarihi': DateTime.now().toIso8601String(),
        'kalite_personel_id': kullaniciId,
      }).eq('id', talepId);

      // Sevkiyat şoförlerine bildirim gönder
      final sevkiyatSoforleri = await supabase
          .from(DbTables.userRoles)
          .select('user_id')
          .eq('yetki_seviyesi', 'sevkiyat');

      for (final sofor in sevkiyatSoforleri) {
        await supabase.from(DbTables.bildirimler).insert({
          'kullanici_id': sofor['user_id'],
          'baslik': 'Sevkiyat Hazır',
          'mesaj': 'Kalite kontrolü tamamlanan ürünler sevkiyat için hazır.',
          'tip': 'basari',
        });
      }

      if (!mounted) return;
      context.showSnackBar('Kalite onayı verildi');
      
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  Future<void> _kaliteReddet(String talepId) async {
    try {
      await supabase.from(DbTables.sevkTalepleri).update({
        'durum': 'reddedildi',
        'kalite_onay_tarihi': DateTime.now().toIso8601String(),
        'kalite_personel_id': kullaniciId,
        'kalite_notu': 'Kalite standartlarını karşılamıyor',
      }).eq('id', talepId);

      if (!mounted) return;
      context.showSnackBar('Kalite reddi verildi');
      
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  Future<void> _sevkiyatBaslat(String talepId) async {
    try {
      await supabase.from(DbTables.sevkTalepleri).update({
        'durum': 'yolda',
        'sevk_onay_tarihi': DateTime.now().toIso8601String(),
        'sevkiyat_sofor_id': kullaniciId,
      }).eq('id', talepId);

      if (!mounted) return;
      context.showSnackBar('Sevkiyat başlatıldı');
      
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  Future<void> _urunleriKabulEt(String talepId) async {
    try {
      await supabase.from(DbTables.sevkTalepleri).update({
        'durum': 'kabul_edildi',
        'kabul_tarihi': DateTime.now().toIso8601String(),
        'kabul_eden_personel_id': kullaniciId,
      }).eq('id', talepId);

      if (!mounted) return;
      context.showSnackBar('Ürünler kabul edildi');
      
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  void _showBildirimler() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimler'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: bildirimler.length,
            itemBuilder: (context, index) {
              final bildirim = bildirimler[index];
              return ListTile(
                title: Text(bildirim['baslik']),
                subtitle: Text(bildirim['mesaj']),
                trailing: Text(
                  DateFormat('dd.MM HH:mm').format(
                    DateTime.parse(bildirim['created_at']),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _getDurumChip(String durum) {
    Color color;
    String text;
    
    switch (durum) {
      case 'bekliyor':
        color = Colors.orange;
        text = 'Bekliyor';
        break;
      case 'kalite_onay':
        color = Colors.blue;
        text = 'Kalite Onayı';
        break;
      case 'sevk_hazir':
        color = Colors.green;
        text = 'Sevk Hazır';
        break;
      case 'yolda':
        color = Colors.purple;
        text = 'Yolda';
        break;
      case 'teslim_edildi':
        color = Colors.teal;
        text = 'Teslim Edildi';
        break;
      case 'kabul_edildi':
        color = Colors.green[700]!;
        text = 'Kabul Edildi';
        break;
      default:
        color = Colors.grey;
        text = durum;
    }
    
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  String _getDurumText(String durum) {
    switch (durum) {
      case 'bekliyor': return 'Bekliyor';
      case 'kalite_onay': return 'Kalite Onayı Bekliyor';
      case 'sevk_hazir': return 'Sevkiyat Hazır';
      case 'yolda': return 'Yolda';
      case 'teslim_edildi': return 'Teslim Edildi';
      case 'kabul_edildi': return 'Kabul Edildi';
      default: return durum;
    }
  }

  String _getAsamaText(String asama) {
    switch (asama) {
      case 'orgu': return 'Örgü';
      case 'konfeksiyon': return 'Konfeksiyon';
      case 'yikama': return 'Yıkama';
      case 'ilik_dugme': return 'İlik Düğme';
      case 'utu': return 'Ütü';
      default: return asama;
    }
  }
}
