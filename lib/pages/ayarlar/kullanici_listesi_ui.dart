// ignore_for_file: invalid_use_of_protected_member
part of 'kullanici_listesi.dart';

/// Kullanici listesi - dialog metotlari
extension _DialogExt on _KullaniciListesiPageState {
  Future<void> _kullaniciDuzenleDialog(Map<String, dynamic> user) async {
    final emailController = TextEditingController(text: user['email']);
    final passwordController = TextEditingController();
    String rol = user['role'] ?? 'orgu_firmasi';
    
    // Eğer rol listede yoksa varsayılan değer ata
    final validRoles = _KullaniciListesiPageState.rolItems.map((item) => item.value).toList();
    if (!validRoles.contains(rol)) {
      rol = 'orgu_firmasi';
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Kullanıcı Düzenle'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (değiştirmek için doldurun)',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return DropdownButtonFormField<String>(
                    initialValue: rol,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: const Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _KullaniciListesiPageState.rolItems,
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          rol = val;
                        });
                      }
                    },
                  );
                }
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
            onPressed: () async {
              final yeniEmail = emailController.text.trim();
              final yeniSifre = passwordController.text.trim();
              
              try {
                // Email güncelle
                if (yeniEmail.isNotEmpty && yeniEmail != user['email']) {
                  await adminClient.auth.admin.updateUserById(
                    user['user_id'],
                    attributes: AdminUserAttributes(email: yeniEmail),
                  );
                }
                
                // Şifre güncelle (adminClient ile)
                if (yeniSifre.isNotEmpty) {
                  await adminClient.auth.admin.updateUserById(
                    user['user_id'],
                    attributes: AdminUserAttributes(password: yeniSifre),
                  );
                }
                
                // Rol güncelle
                if (rol != user['role']) {
                  await Supabase.instance.client
                      .from(DbTables.userRoles)
                      .update({'role': rol})
                      .eq('user_id', user['user_id']);
                }
                
                if (!context.mounted) return;
                Navigator.pop(ctx);
                _kullanicilariGetir();
                // ignore: use_build_context_synchronously
                context.showSuccessSnackBar('Kullanıcı başarıyla güncellendi');
              } catch (e) {
                if (!context.mounted) return;
                // ignore: use_build_context_synchronously
                context.showErrorSnackBar('Güncelleme hatası: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  String formatLastSignIn(dynamic dateTime) {
    if (dateTime == null) return 'Hiç giriş yapmamış';
    try {
      final parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);
      
      if (difference.inDays > 7) {
        return DateFormat('dd.MM.yyyy').format(parsed);
      } else if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red.shade600;
      case 'ik':
        return Colors.indigo.shade600;
      case DbTables.personel:
        return Colors.teal.shade600;
      case 'orgu_firmasi':
        return Colors.blue.shade600;
      case 'kalite_personeli':
        return Colors.green.shade600;
      case 'sevkiyat_soforu':
        return Colors.orange.shade600;
      case 'atolye_personeli':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'ik':
        return 'İnsan Kaynakları';
      case DbTables.personel:
        return 'Personel';
      case 'orgu_firmasi':
        return 'Örgü Firması';
      
      // Yeni Üretim Aşamaları
      case 'dokuma':
        return 'Dokuma';
      case 'konfeksiyon':
        return 'Konfeksiyon';
      case 'yikama':
        return 'Yıkama';
      case 'utu':
        return 'Ütü';
      case 'ilik_dugme':
        return 'İlik Düğme';
      case 'kalite_kontrol':
        return 'Kalite Kontrol';
      case 'paketleme':
        return 'Paketleme';
      
      // Diğer Departmanlar
      case 'sevkiyat':
        return 'Sevkiyat';
      case 'muhasebe':
        return 'Muhasebe';
      case 'satis':
        return 'Satış';
      case 'tasarim':
        return 'Tasarım';
      case 'planlama':
        return 'Planlama';
      case 'depo':
        return 'Depo';
      
      // Eski Roller (uyumluluk için)
      case 'kalite_personeli':
        return 'Kalite Personeli (Eski)';
      case 'sevkiyat_soforu':
        return 'Sevkiyat Şoförü (Eski)';
      case 'atolye_personeli':
        return 'Atölye Personeli (Eski)';
      case 'tekstil':
        return 'Tekstil (Eski)';
      case 'iplik':
        return 'İplik (Eski)';
      case 'orgu':
        return 'Örgü (Eski)';
      case 'nakis':
        return 'Nakış (Eski)';
      case 'utu_paket':
        return 'Ütü Paket (Eski)';
      case 'aksesuar':
        return 'Aksesuar (Eski)';
      case 'makine':
        return 'Makine (Eski)';
      case 'kimyasal':
        return 'Kimyasal (Eski)';
      case 'ambalaj':
        return 'Ambalaj (Eski)';
      case 'lojistik':
        return 'Lojistik (Eski)';
      case 'diger':
        return 'Diğer';
      default:
        return role ?? 'Bilinmiyor';
    }
  }

}
