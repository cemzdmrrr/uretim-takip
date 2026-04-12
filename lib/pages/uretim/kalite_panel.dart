import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/bildirim_service.dart';

class KalitePanel extends StatefulWidget {
  const KalitePanel({Key? key}) : super(key: key);

  @override
  State<KalitePanel> createState() => _KalitePanelState();
}

class _KalitePanelState extends State<KalitePanel> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final bildirimService = BildirimService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> bekleyenKaliteKontroller = [];
  List<Map<String, dynamic>> aktifKaliteKontroller = [];
  List<Map<String, dynamic>> tamamlananKaliteKontroller = [];
  List<Map<String, dynamic>> atolyeler = [];
  Map<String, dynamic>? kalitePersoneliInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadKalitePersoneliData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadKalitePersoneliData() async {
    try {
      setState(() => _isLoading = true);
      
      // Önce mevcut kullanıcının kalite personeli bilgilerini al
      final currentUser = supabase.auth.currentUser;
      if (currentUser?.email == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      // Kullanıcı rollerinden kalite kontrol yetkisi kontrolü
      await supabase
          .from(DbTables.userRoles)
          .select('*')
          .eq('user_id', currentUser!.id)
          .eq('role', 'kalite_kontrol')
          .single();
      
      if (!mounted) return;
      setState(() {
        kalitePersoneliInfo = {
          'user_id': currentUser.id,
          'email': currentUser.email,
          'role': 'kalite_kontrol'
        };
      });

      debugPrint('🔍 Kalite kontrol personeli ${currentUser.email} için atamalar yükleniyor...');
      await _loadAtolyeler();
      await _loadKaliteKontroller();
      
    } catch (e) {
      debugPrint('❌ Kalite personeli veri yükleme hatası: $e');
      if (!mounted) return;
      context.showErrorSnackBar('Veri yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadKaliteKontroller() async {
    if (kalitePersoneliInfo == null) return;

    try {
      debugPrint('🔍 Kalite kontrol atamaları yükleniyor...');
      
      // Kalite kontrol atamalari tablosundan tüm atamaları al
      final response = await supabase
          .from(DbTables.kaliteKontrolAtamalari)
          .select('''
            id, model_id, adet, talep_edilen_adet, tamamlanan_adet, 
            durum, created_at, atama_tarihi, onceki_asama, onceki_atama_id,
            kalite_sonucu, kalite_notlari, kalite_tarihi, kalite_personeli_id,
            uretici_notlari,
            triko_takip!inner(marka, item_no, renk, beden, adet)
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .order('created_at', ascending: false);

      debugPrint('📊 Toplam ${response.length} kalite kontrol atması bulundu');
      
      final List<Map<String, dynamic>> tumKaliteKontroller = [];
      for (var atama in response) {
        debugPrint('   - Model: ${atama[DbTables.trikoTakip]['marka']} - ${atama[DbTables.trikoTakip]['item_no']}, Adet: ${atama['adet']}, Durum: ${atama['durum']}, Önceki Aşama: ${atama['onceki_asama']}');
        tumKaliteKontroller.add(atama);
      }

      // Atamaları durumlarına göre ayır
      setState(() {
        bekleyenKaliteKontroller = tumKaliteKontroller.where((a) => 
          a['durum'] == 'beklemede').toList();
        aktifKaliteKontroller = tumKaliteKontroller.where((a) => 
          a['durum'] == 'atandi' || a['durum'] == 'baslandi' || a['durum'] == 'kontrol_ediliyor').toList();
        tamamlananKaliteKontroller = tumKaliteKontroller.where((a) => 
          a['durum'] == 'onaylandi' || a['durum'] == 'reddedildi').toList();
      });

      debugPrint('✅ Kalite kontroller yüklendi: ${bekleyenKaliteKontroller.length} bekleyen, ${aktifKaliteKontroller.length} aktif, ${tamamlananKaliteKontroller.length} tamamlanan');

    } catch (e) {
      debugPrint('❌ Kalite kontroller yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kalite Kontrol Paneli'),
          backgroundColor: Colors.purple,
        ),
        body: const LoadingWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalite Kontrol Paneli'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKalitePersoneliData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!context.mounted) return;
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Bekleyen',
              icon: Badge(
                label: Text('${bekleyenKaliteKontroller.length}'),
                child: const Icon(Icons.pending_actions),
              ),
            ),
            Tab(
              text: 'Kontrol Ediliyor',
              icon: Badge(
                label: Text('${aktifKaliteKontroller.length}'),
                child: const Icon(Icons.search),
              ),
            ),
            Tab(
              text: 'Tamamlanan',
              icon: Badge(
                label: Text('${tamamlananKaliteKontroller.length}'),
                child: const Icon(Icons.verified),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Kalite personeli bilgi kartı
          if (kalitePersoneliInfo != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.verified_user, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kalite Kontrol Personeli',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              kalitePersoneliInfo!['email'] ?? 'Email',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Toplam: ${bekleyenKaliteKontroller.length + aktifKaliteKontroller.length + tamamlananKaliteKontroller.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('kalite kontrol', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKaliteListesi(bekleyenKaliteKontroller, 'bekleyen'),
                _buildKaliteListesi(aktifKaliteKontroller, 'aktif'),
                _buildKaliteListesi(tamamlananKaliteKontroller, 'tamamlanan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaliteListesi(List<Map<String, dynamic>> kontroller, String tip) {
    if (kontroller.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tip == 'bekleyen' ? Icons.pending_actions :
              tip == 'aktif' ? Icons.search : Icons.verified,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              tip == 'bekleyen' ? 'Bekleyen kalite kontrol yok' :
              tip == 'aktif' ? 'Kontrol edilen ürün yok' : 'Tamamlanan kalite kontrol yok',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: kontroller.length,
      itemBuilder: (context, index) {
        final kontrol = kontroller[index];
        final modelData = kontrol[DbTables.trikoTakip];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getKaliteColor(kontrol['onceki_asama']),
              child: Text(
                kontrol['onceki_asama']?[0]?.toUpperCase() ?? 'K',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${modelData['marka']} - ${modelData['item_no']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${kontrol['onceki_asama']} → Kalite Kontrol • ${kontrol['durum']}'),
                Text('Adet: ${kontrol['adet']}'),
                if (kontrol['kalite_sonucu'] != null)
                  Text('Sonuç: ${kontrol['kalite_sonucu']}',
                       style: TextStyle(
                         color: kontrol['kalite_sonucu'] == 'onaylandi' ? Colors.green : Colors.red,
                         fontWeight: FontWeight.bold,
                       )),
              ],
            ),
            trailing: tip == 'bekleyen' ? 
              ElevatedButton.icon(
                onPressed: () => _showKaliteBaslatDialog(kontrol),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ) : tip == 'aktif' ?
              ElevatedButton.icon(
                onPressed: () => _showKaliteTamamlaDialog(kontrol),
                icon: const Icon(Icons.check),
                label: const Text('Sonuçlandır'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ) : 
              Icon(
                kontrol['kalite_sonucu'] == 'onaylandi' ? Icons.check_circle : Icons.cancel,
                color: kontrol['kalite_sonucu'] == 'onaylandi' ? Colors.green : Colors.red,
              ),
            onTap: () => _showKaliteDetay(kontrol),
          ),
        );
      },
    );
  }

  Color _getKaliteColor(String? oncekiAsama) {
    switch (oncekiAsama) {
      case 'Dokuma': return Colors.brown;
      case 'Konfeksiyon': return Colors.purple;
      case 'Nakış': return Colors.pink;
      case 'Yıkama': return Colors.cyan;
      case 'İlik Düğme': return Colors.indigo;
      case 'Ütü': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _showKaliteBaslatDialog(Map<String, dynamic> kontrol) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalite Kontrole Başla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Model: ${kontrol[DbTables.trikoTakip]['marka']} - ${kontrol[DbTables.trikoTakip]['item_no']}'),
            Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
            Text('Kontrol Edilecek Adet: ${kontrol['adet']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Kalite kontrol işlemini başlatmak istiyor musunuz?',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
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
              try {
                await supabase
                    .from(DbTables.kaliteKontrolAtamalari)
                    .update({
                      'durum': 'kontrol_ediliyor',
                      'kalite_personeli_id': kalitePersoneliInfo!['user_id'],
                      'atama_tarihi': DateTime.now().toIso8601String(),
                    })
                    .eq('id', kontrol['id']);
                    
                if (!context.mounted) return;
                Navigator.pop(context);
                await _loadKaliteKontroller();
                
                if (!context.mounted) return;
                context.showSuccessSnackBar('✅ Kalite kontrol başlatıldı');
                
              } catch (e) {
                if (!context.mounted) return;
                context.showErrorSnackBar('Hata: $e');
              }
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  Future<void> _showKaliteTamamlaDialog(Map<String, dynamic> kontrol) async {
    final notlarController = TextEditingController();
    String kaliteSonucu = 'onaylandi';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kalite Kontrol Sonucu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Model: ${kontrol[DbTables.trikoTakip]['marka']} - ${kontrol[DbTables.trikoTakip]['item_no']}'),
              const SizedBox(height: 16),
              
              // Kalite sonucu seçimi
              const Text('Kalite Kontrol Sonucu:', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioGroup<String>(
                groupValue: kaliteSonucu,
                onChanged: (value) => setDialogState(() => kaliteSonucu = value!),
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('✅ Onaylı - Kaliteli'),
                      value: 'onaylandi',
                    ),
                    RadioListTile<String>(
                      title: Text('❌ Reddedildi - Kalitesiz'),
                      value: 'reddedildi',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(
                  labelText: 'Kalite Kontrol Notları',
                  border: OutlineInputBorder(),
                  helperText: 'Detayları ve bulguları belirtin',
                ),
                maxLines: 3,
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
                try {
                  await supabase
                      .from(DbTables.kaliteKontrolAtamalari)
                      .update({
                        'durum': kaliteSonucu,
                        'kalite_sonucu': kaliteSonucu,
                        'kalite_notlari': notlarController.text,
                        'kalite_tarihi': DateTime.now().toIso8601String(),
                      })
                      .eq('id', kontrol['id']);
                      
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await _loadKaliteKontroller();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(kaliteSonucu == 'onaylandi' ? 
                        '✅ Ürün kalite kontrolden geçti' : 
                        '❌ Ürün kalite kontrolden reddedildi'),
                      backgroundColor: kaliteSonucu == 'onaylandi' ? Colors.green : Colors.red,
                    ),
                  );
                  
                } catch (e) {
                  if (!context.mounted) return;
                  context.showErrorSnackBar('Hata: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kaliteSonucu == 'onaylandi' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(kaliteSonucu == 'onaylandi' ? 'Onayla' : 'Reddet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showKaliteDetay(Map<String, dynamic> kontrol) {
    final modelData = kontrol[DbTables.trikoTakip];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalite Kontrol Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${modelData['marka']} - ${modelData['item_no']}'),
            Text('Renk: ${modelData['renk'] ?? 'Belirtilmemiş'}'),
            Text('Beden: ${modelData['beden'] ?? 'Belirtilmemiş'}'),
            const SizedBox(height: 16),
            Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
            Text('Durum: ${kontrol['durum']}'),
            Text('Kontrol Edilecek Adet: ${kontrol['adet']}'),
            if (kontrol['kalite_sonucu'] != null) ...[
              const SizedBox(height: 16),
              Text('Kalite Sonucu: ${kontrol['kalite_sonucu']}',
                   style: TextStyle(
                     color: kontrol['kalite_sonucu'] == 'onaylandi' ? Colors.green : Colors.red,
                     fontWeight: FontWeight.bold,
                   )),
              if (kontrol['kalite_notlari'] != null)
                Text('Kalite Notları: ${kontrol['kalite_notlari']}'),
            ],
            if (kontrol['uretici_notlari'] != null) ...[
              const SizedBox(height: 16),
              Text('Üretici Notları: ${kontrol['uretici_notlari']}'),
            ],
            const SizedBox(height: 16),
            if (kontrol['created_at'] != null)
              Text('Oluşturulma: ${DateTime.parse(kontrol['created_at']).toLocal().toString().split('.')[0]}'),
            if (kontrol['atama_tarihi'] != null)
              Text('Atama: ${DateTime.parse(kontrol['atama_tarihi']).toLocal().toString().split('.')[0]}'),
            if (kontrol['kalite_tarihi'] != null)
              Text('Kalite: ${DateTime.parse(kontrol['kalite_tarihi']).toLocal().toString().split('.')[0]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (kontrol['kalite_sonucu'] == 'onaylandi')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showSevkiyatTalebiDialog(kontrol);
              },
              icon: const Icon(Icons.local_shipping),
              label: const Text('Sevkiyat Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadAtolyeler() async {
    try {
      final response = await supabase
          .from(DbTables.atolyeler)
          .select('id, atolye_adi, atolye_turu, adres, aktif')
          .eq('aktif', true)
          .order('atolye_adi');
      
      setState(() {
        atolyeler = List<Map<String, dynamic>>.from(response);
      });
      debugPrint('✅ ${atolyeler.length} atölye yüklendi');
    } catch (e) {
      debugPrint('❌ Atölyeler yükleme hatası: $e');
    }
  }

  Future<void> _showSevkiyatTalebiDialog(Map<String, dynamic> kontrol) async {
    final modelData = kontrol[DbTables.trikoTakip];
    int? kaynakAtolyeId;
    int? hedefAtolyeId;
    final adetController = TextEditingController(text: kontrol['adet']?.toString() ?? '0');
    final aciklamaController = TextEditingController();
    String onceligi = 'normal';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('🚚 Sevkiyat Talebi Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Model bilgisi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${modelData['marka']} - ${modelData['item_no']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Kalite Onaylı Adet: ${kontrol['adet']}'),
                      Text('Önceki Aşama: ${kontrol['onceki_asama']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Kaynak atölye seçimi
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Kaynak Atölye (Nereden)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  initialValue: kaynakAtolyeId,
                  items: atolyeler.map((a) => DropdownMenuItem<int>(
                    value: a['id'],
                    child: Text('${a['atolye_adi']} (${a['atolye_turu']})'),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => kaynakAtolyeId = value),
                ),
                const SizedBox(height: 16),
                
                // Hedef atölye seçimi
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Hedef Atölye (Nereye)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                  initialValue: hedefAtolyeId,
                  items: atolyeler.map((a) => DropdownMenuItem<int>(
                    value: a['id'],
                    child: Text('${a['atolye_adi']} (${a['atolye_turu']})'),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => hedefAtolyeId = value),
                ),
                const SizedBox(height: 16),
                
                // Sevk adeti
                TextField(
                  controller: adetController,
                  decoration: const InputDecoration(
                    labelText: 'Sevk Adeti',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                    helperText: 'Kısmi sevkiyat yapabilirsiniz',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Öncelik
                const Text('Öncelik:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioGroup<String>(
                  groupValue: onceligi,
                  onChanged: (v) => setDialogState(() => onceligi = v!),
                  child: const Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('Normal'),
                          value: 'normal',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('🚨 Acil'),
                          value: 'acil',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Açıklama
                TextField(
                  controller: aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (İsteğe bağlı)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sevkiyat talebi oluşturulduğunda şoförlere bildirim gönderilecektir.',
                          style: TextStyle(color: Colors.teal.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (kaynakAtolyeId == null || hedefAtolyeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen kaynak ve hedef atölyeleri seçin'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                final sevkAdeti = int.tryParse(adetController.text) ?? 0;
                if (sevkAdeti <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geçerli bir adet giriniz'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  // Sevk talebi oluştur
                  final sevkTalebiId = await bildirimService.sevkTalebiOlustur(
                    modelId: kontrol['model_id'],
                    kaynakAtolyeId: kaynakAtolyeId!,
                    hedefAtolyeId: hedefAtolyeId!,
                    talepEdenUserId: kalitePersoneliInfo!['user_id'],
                    sevkAdeti: sevkAdeti,
                    aciklama: aciklamaController.text.isNotEmpty 
                        ? aciklamaController.text 
                        : 'Kalite kontrol sonrası sevkiyat - ${kontrol['onceki_asama']}',
                    onceligi: onceligi,
                  );

                  if (sevkTalebiId != null) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    
                    if (mounted) {
                      context.showSuccessSnackBar('✅ Sevkiyat talebi oluşturuldu (ID: $sevkTalebiId)');
                    }
                  } else {
                    throw Exception('Sevkiyat talebi oluşturulamadı');
                  }
                } catch (e) {
                  if (mounted) {
                    context.showErrorSnackBar('Hata: $e');
                  }
                }
              },
              icon: const Icon(Icons.local_shipping),
              label: const Text('Sevkiyat Talebi Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
