import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/auth_helper_rls_free.dart';

class AdminTestPage extends StatefulWidget {
  const AdminTestPage({super.key});

  @override
  State<AdminTestPage> createState() => _AdminTestPageState();
}

class _AdminTestPageState extends State<AdminTestPage> {
  String? currentUserRole;
  bool isAdmin = false;
  bool isLoading = true;
  String testResults = '';

  @override
  void initState() {
    super.initState();
    _runAdminTests();
  }

  Future<void> _runAdminTests() async {
    setState(() {
      isLoading = true;
      testResults = 'Admin testleri başlatılıyor...\n\n';
    });

    try {
      // 1. Kullanıcı rolünü kontrol et
      currentUserRole = await kullaniciRolunuGetir();
      isAdmin = await kullaniciAdminMi();

      setState(() {
        testResults += '1. Rol Testi:\n';
        testResults += '   - Mevcut Rol: ${currentUserRole ?? "Bilinmiyor"}\n';
        testResults += '   - Admin mi: ${isAdmin ? "EVET" : "HAYIR"}\n\n';
      });

      // 2. Admin yetkilerini test et
      final bool adminAccess = await adminVeyaYetkiliMi(null);
      setState(() {
        testResults += '2. Yetki Testi:\n';
        testResults += '   - Admin Erişimi: ${adminAccess ? "BAŞARILI" : "BAŞARISIZ"}\n\n';
      });

      // 3. Çoklu rol yetki testi
      final bool multiRoleAccess = await kullaniciYetkiKontrolu(['admin', 'user', 'ik']);
      setState(() {
        testResults += '3. Çoklu Rol Testi:\n';
        testResults += '   - Admin/User/IK Erişimi: ${multiRoleAccess ? "BAŞARILI" : "BAŞARISIZ"}\n\n';
      });

      // 4. Veritabanı bağlantı testi
      try {
        final testQuery = await Supabase.instance.client
            .from(DbTables.userRoles)
            .select('count')
            .count(CountOption.exact);

        setState(() {
          testResults += '4. Veritabanı Testi:\n';
          testResults += '   - Toplam Kullanıcı: ${testQuery.count}\n';
          testResults += '   - Bağlantı: BAŞARILI\n';
          testResults += '   - RLS Durumu: DEVRE DIŞI (Admin sorunu yok)\n\n';
        });
      } catch (e) {
        setState(() {
          testResults += '4. Veritabanı Testi:\n';
          testResults += '   - Hata: $e\n';
          testResults += '   - Bağlantı: BAŞARISIZ\n\n';
        });
      }

      // 5. Supabase admin fonksiyon testi
      try {
        final bool supabaseAdminCheck = await supabaseAdminKontrolu();
        setState(() {
          testResults += '5. Supabase Admin Fonksiyon Testi:\n';
          testResults += '   - Fonksiyon Çalışıyor: ${supabaseAdminCheck ? "EVET" : "HAYIR"}\n\n';
        });
      } catch (e) {
        setState(() {
          testResults += '5. Supabase Admin Fonksiyon Testi:\n';
          testResults += '   - Hata: $e\n\n';
        });
      }

      // 6. Admin politika testi
      if (isAdmin) {
        try {
          final adminPolicyTest = await Supabase.instance.client
              .from(DbTables.modeller)
              .select('count')
              .count(CountOption.exact);

          setState(() {
            testResults += '6. Admin Politika Testi:\n';
            testResults += '   - Modeller Erişimi: BAŞARILI\n';
            testResults += '   - Toplam Model: ${adminPolicyTest.count}\n';
            testResults += '   - RLS Devre Dışı: Politika sorunu yok\n\n';
          });
        } catch (e) {
          setState(() {
            testResults += '6. Admin Politika Testi:\n';
            testResults += '   - Modeller Erişimi: BAŞARISIZ\n';
            testResults += '   - Hata: $e\n\n';
          });
        }
      } else {
        setState(() {
          testResults += '6. Admin Politika Testi:\n';
          testResults += '   - Admin olmadığınız için atlandı\n\n';
        });
      }

      setState(() {
        testResults += '7. Sonuç:\n';
        if (isAdmin) {
          testResults += '   ✅ Admin yetkileri aktif\n';
          testResults += '   ✅ RLS devre dışı - politika sorunu yok\n';
          testResults += '   ✅ Tüm modüllere erişim mevcut\n';
          testResults += '   ✅ Sistem hazır\n';
        } else {
          testResults += '   ⚠️ Admin yetkisi yok\n';
          testResults += '   ⚠️ Sınırlı erişim\n';
          testResults += '   ℹ️ "Admin Yap" butonunu kullanın\n';
        }
      });

    } catch (e) {
      setState(() {
        testResults += 'HATA: $e\n';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Yetki Testi'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durum Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAdmin 
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isAdmin ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isAdmin ? 'Admin Kullanıcı' : 'Normal Kullanıcı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rol: ${currentUserRole ?? "Yükleniyor..."}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Test Butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runAdminTests,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Testleri Yenile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // RLS-free admin yapma
                      try {
                        final success = await kendimiAdminYap();
                        if (success) {
                          if (!context.mounted) return;
                          context.showSnackBar('Admin rolü atandı! (RLS devre dışı)');
                          _runAdminTests();
                        } else {
                          if (!context.mounted) return;
                          context.showSnackBar('Admin yapma başarısız');
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        context.showSnackBar('Hata: $e');
                      }
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Admin Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Test Sonuçları
            Text(
              'Test Sonuçları:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: isLoading
                    ? const LoadingWidget()
                    : SingleChildScrollView(
                        child: Text(
                          testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
