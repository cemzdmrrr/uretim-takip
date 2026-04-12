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
  List<Map<String, dynamic>> ayarlar = [];
  bool yukleniyor = true;
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _getAyarlar();
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
    final ayarlarListesi = await SistemAyarlariService.getTumAyarlar();
    setState(() {
      ayarlar = ayarlarListesi;
      yukleniyor = false;
    });
  }

  Future<void> _updateAyar(String ayarKodu, double yeniDeger) async {
    final basarili = await SistemAyarlariService.updateAyarDegeri(ayarKodu, yeniDeger);
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
    final controller = TextEditingController(text: ayar['ayar_degeri'].toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ayar['ayar_adi']} Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ayar['aciklama'] ?? '', style: TextStyle(color: Colors.grey[600])),
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
                await _updateAyar(ayar['ayar_kodu'], yeniDeger);
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
        title: const Text('Sistem Ayarları', style: TextStyle(color: Colors.white)),
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
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                                ayar['ayar_kodu'] == 'PAZAR_YEMEK_UCRETI' 
                                    ? Icons.weekend
                                    : Icons.celebration,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              ayar['ayar_adi'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(ayar['aciklama'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${ayar['ayar_degeri']} ${ayar['birim']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
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
