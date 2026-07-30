import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/sistem_ayarlari_service.dart';

class SistemAyarlariPage extends StatefulWidget {
  const SistemAyarlariPage({super.key});

  @override
  State<SistemAyarlariPage> createState() => _SistemAyarlariPageState();
}

class _SistemAyarlariPageState extends State<SistemAyarlariPage> {
  static const _aksesuarSiparisMailAnahtari = 'AKSESUAR_SIPARIS_MAIL_ADRESI';
  List<Map<String, dynamic>> ayarlar = [];
  bool yukleniyor = true;
  String? currentUserRole;
  final _aksesuarSiparisMailController = TextEditingController();
  bool _mailAyariKaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _getAyarlar();
  }

  @override
  void dispose() {
    _aksesuarSiparisMailController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final response = await Supabase.instance.client
        .from(DbTables.userRoles)
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    setState(() {
      currentUserRole = response?['role'] ?? 'user';
    });
  }

  Future<void> _getAyarlar() async {
    setState(() => yukleniyor = true);
    final sonuclar = await Future.wait([
      SistemAyarlariService.getTumAyarlar(),
      SistemAyarlariService.getMetinAyarDegeri(_aksesuarSiparisMailAnahtari),
    ]);
    final ayarlarListesi = sonuclar[0] as List<Map<String, dynamic>>;
    _aksesuarSiparisMailController.text = sonuclar[1] as String;
    if (!mounted) return;
    setState(() {
      ayarlar = ayarlarListesi;
      yukleniyor = false;
    });
  }

  Future<void> _mailAyariniKaydet() async {
    setState(() => _mailAyariKaydediliyor = true);
    final basarili = await SistemAyarlariService.updateMetinAyarDegeri(
      _aksesuarSiparisMailAnahtari,
      _aksesuarSiparisMailController.text,
      aciklama: 'Aksesuar sipariş e-postalarında CC olarak kullanılan adres',
    );
    if (!mounted) return;
    setState(() => _mailAyariKaydediliyor = false);
    if (basarili) {
      context.showSuccessSnackBar('Sipariş e-posta adresi kaydedildi');
    } else {
      context.showErrorSnackBar('Sipariş e-posta adresi kaydedilemedi');
    }
  }

  Future<void> _updateAyar(String ayarKodu, double yeniDeger) async {
    final basarili =
        await SistemAyarlariService.updateAyarDegeri(ayarKodu, yeniDeger);
    if (basarili) {
      if (!mounted) return;
      context.showSnackBar('Ayar başarıyla güncellendi');
      _getAyarlar(); // Listeyi yenile
    } else {
      if (!mounted) return;
      context.showSnackBar('Ayar güncellenirken hata oluştu');
    }
  }

  void _showEditDialog(Map<String, dynamic> ayar) {
    final ayarKodu = (ayar['anahtar'] ?? ayar['ayar_kodu']).toString();
    final controller = TextEditingController(
        text: (ayar['deger'] ?? ayar['ayar_degeri'] ?? '').toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$ayarKodu Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ayar['aciklama'] ?? '',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Değer (${ayar['birim']})',
                border: const OutlineInputBorder(),
              ),
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
              final yeniDeger = double.tryParse(controller.text);
              if (yeniDeger != null) {
                await _updateAyar(ayarKodu, yeniDeger);
                if (!context.mounted) return;
                Navigator.pop(context);
              } else {
                context.showSnackBar('Geçerli bir sayı giriniz');
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserRole != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sistem Ayarları'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Bu sayfaya erişim yetkiniz yok.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistem Ayarları',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Yemek Ücretleri',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mesai türlerine göre uygulanacak yemek ücretlerini buradan ayarlayabilirsiniz.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final alan = TextField(
                            controller: _aksesuarSiparisMailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Aksesuar Sipariş E-posta Adresi',
                              helperText:
                                  'Hazırlanan sipariş taslaklarına CC olarak eklenir.',
                              prefixIcon: Icon(Icons.alternate_email),
                              border: OutlineInputBorder(),
                            ),
                          );
                          final buton = FilledButton.icon(
                            onPressed: _mailAyariKaydediliyor
                                ? null
                                : _mailAyariniKaydet,
                            icon: _mailAyariKaydediliyor
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Kaydet'),
                          );
                          if (constraints.maxWidth < 620) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                alan,
                                const SizedBox(height: 12),
                                buton,
                              ],
                            );
                          }
                          return Row(children: [
                            Expanded(child: alan),
                            const SizedBox(width: 12),
                            buton,
                          ]);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: ayarlar.length,
                      itemBuilder: (context, index) {
                        final ayar = ayarlar[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                (ayar['anahtar'] ?? ayar['ayar_kodu']) ==
                                        'PAZAR_YEMEK_UCRETI'
                                    ? Icons.weekend
                                    : Icons.celebration,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              (ayar['anahtar'] ?? ayar['ayar_adi'] ?? 'Ayar')
                                  .toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(ayar['aciklama'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (ayar['deger'] ?? ayar['ayar_degeri'] ?? '')
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _showEditDialog(ayar),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
