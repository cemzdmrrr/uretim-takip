import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class SoforPanel extends StatefulWidget {
  const SoforPanel({Key? key}) : super(key: key);

  @override
  State<SoforPanel> createState() => _SoforPanelState();
}

class _SoforPanelState extends State<SoforPanel> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> bekleyenSevkiyatlar = [];
  List<Map<String, dynamic>> aktifSevkiyatlar = [];
  List<Map<String, dynamic>> tamamlananSevkiyatlar = [];
  Map<String, dynamic>? soforInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSoforData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSoforData() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = supabase.auth.currentUser;
      if (currentUser?.email == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      // Şoför bilgilerini al
      setState(() {
        soforInfo = {
          'user_id': currentUser!.id,
          'email': currentUser.email,
          'role': 'sofor'
        };
      });

      debugPrint('🚗 Şoför ${currentUser?.email} için sevkiyatlar yükleniyor...');
      await _loadSevkiyatlar();
      
    } catch (e) {
      debugPrint('❌ Şoför veri yükleme hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Veri yükleme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSevkiyatlar() async {
    if (soforInfo == null) return;

    try {
      debugPrint('🔍 Sevkiyat talepleri yükleniyor...');
      
      // Sevk talepleri tablosundan şoföre atanmış veya bekleyen sevkiyatları al
      final response = await supabase
          .from(DbTables.sevkTalepleri)
          .select('''
            id, model_id, sevk_adeti, durum, onceligi, aciklama,
            kaynak_atolye_id, hedef_atolye_id,
            kalite_kontrol_user_id, kalite_onay_durumu, kalite_notlari,
            sofor_user_id, alinan_tarih, sevkiyat_baslama_tarihi,
            tahmini_teslim_tarihi, gercek_teslim_tarihi,
            teslim_alan_user_id, teslim_notlari, hasar_raporu,
            created_at, updated_at,
            triko_takip!inner(marka, item_no, renk, adet),
            kaynak_atolye:atolyeler!sevk_talepleri_kaynak_atolye_id_fkey(atolye_adi, adres),
            hedef_atolye:atolyeler!sevk_talepleri_hedef_atolye_id_fkey(atolye_adi, adres)
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .or('sofor_user_id.eq.${soforInfo!['user_id']},durum.eq.bekliyor')
          .order('created_at', ascending: false);

      debugPrint('📊 Toplam ${response.length} sevkiyat talebi bulundu');
      
      final List<Map<String, dynamic>> tumSevkiyatlar = [];
      for (var sevkiyat in response) {
        debugPrint('   - Model: ${sevkiyat[DbTables.trikoTakip]['marka']} - ${sevkiyat[DbTables.trikoTakip]['item_no']}, Adet: ${sevkiyat['sevk_adeti']}, Durum: ${sevkiyat['durum']}');
        tumSevkiyatlar.add(sevkiyat);
      }

      // Sevkiyatları durumlarına göre ayır
      setState(() {
        bekleyenSevkiyatlar = tumSevkiyatlar.where((s) => 
          s['durum'] == 'bekliyor' || s['durum'] == 'kalite_onaylandi').toList();
        aktifSevkiyatlar = tumSevkiyatlar.where((s) => 
          s['durum'] == 'alindi' || s['durum'] == 'yolda' || s['durum'] == 'teslimde').toList();
        tamamlananSevkiyatlar = tumSevkiyatlar.where((s) => 
          s['durum'] == 'teslim_edildi' || s['durum'] == 'iptal').toList();
      });

      debugPrint('✅ Sevkiyatlar yüklendi: ${bekleyenSevkiyatlar.length} bekleyen, ${aktifSevkiyatlar.length} aktif, ${tamamlananSevkiyatlar.length} tamamlanan');

    } catch (e) {
      debugPrint('❌ Sevkiyatlar yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Şoför Paneli'),
          backgroundColor: Colors.teal,
        ),
        body: const LoadingWidget(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şoför Paneli'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSoforData,
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
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Bekleyen',
              icon: Badge(
                label: Text('${bekleyenSevkiyatlar.length}'),
                child: const Icon(Icons.pending_actions),
              ),
            ),
            Tab(
              text: 'Aktif',
              icon: Badge(
                label: Text('${aktifSevkiyatlar.length}'),
                child: const Icon(Icons.local_shipping),
              ),
            ),
            Tab(
              text: 'Tamamlanan',
              icon: Badge(
                label: Text('${tamamlananSevkiyatlar.length}'),
                child: const Icon(Icons.done_all),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Şoför bilgi kartı
          if (soforInfo != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.teal,
                        radius: 28,
                        child: Icon(Icons.local_shipping, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sevkiyat Şoförü',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              soforInfo!['email'] ?? 'Email',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${bekleyenSevkiyatlar.length + aktifSevkiyatlar.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 24,
                              color: Colors.teal,
                            ),
                          ),
                          const Text('aktif görev', style: TextStyle(color: Colors.grey)),
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
                _buildSevkiyatListesi(bekleyenSevkiyatlar, 'bekleyen'),
                _buildSevkiyatListesi(aktifSevkiyatlar, 'aktif'),
                _buildSevkiyatListesi(tamamlananSevkiyatlar, 'tamamlanan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSevkiyatListesi(List<Map<String, dynamic>> sevkiyatlar, String tip) {
    if (sevkiyatlar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tip == 'bekleyen' ? Icons.pending_actions :
              tip == 'aktif' ? Icons.local_shipping : Icons.done_all,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              tip == 'bekleyen' ? 'Bekleyen sevkiyat yok' :
              tip == 'aktif' ? 'Aktif sevkiyat yok' : 'Tamamlanan sevkiyat yok',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sevkiyatlar.length,
      itemBuilder: (context, index) {
        final sevkiyat = sevkiyatlar[index];
        final modelData = sevkiyat[DbTables.trikoTakip];
        final kaynakAtelye = sevkiyat['kaynak_atolye'];
        final hedefAtelye = sevkiyat['hedef_atolye'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getSevkiyatColor(sevkiyat['durum']),
                  child: const Icon(Icons.local_shipping, color: Colors.white),
                ),
                title: Text(
                  '${modelData['marka']} - ${modelData['item_no']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${sevkiyat['sevk_adeti']} adet • ${_getDurumText(sevkiyat['durum'])}'),
                    if (sevkiyat['onceligi'] == 'acil')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🚨 ACİL',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                trailing: _buildActionButton(sevkiyat, tip),
                onTap: () => _showSevkiyatDetay(sevkiyat),
              ),
              
              // Kaynak ve Hedef Bilgileri
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📍 Kaynak:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            kaynakAtelye?['atolye_adi'] ?? 'Belirtilmemiş',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (kaynakAtelye?['adres'] != null)
                            Text(
                              kaynakAtelye['adres'],
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.teal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('🏭 Hedef:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            hedefAtelye?['atolye_adi'] ?? 'Belirtilmemiş',
                            style: const TextStyle(fontSize: 13),
                            textAlign: TextAlign.right,
                          ),
                          if (hedefAtelye?['adres'] != null)
                            Text(
                              hedefAtelye['adres'],
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(Map<String, dynamic> sevkiyat, String tip) {
    if (tip == 'bekleyen') {
      return ElevatedButton.icon(
        onPressed: () => _sevkiyatiAl(sevkiyat),
        icon: const Icon(Icons.check),
        label: const Text('Al'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      );
    } else if (tip == 'aktif') {
      final durum = sevkiyat['durum'];
      if (durum == 'alindi') {
        return ElevatedButton.icon(
          onPressed: () => _yolaBasla(sevkiyat),
          icon: const Icon(Icons.directions_car),
          label: const Text('Yola Çık'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
      } else if (durum == 'yolda') {
        return ElevatedButton.icon(
          onPressed: () => _teslimEt(sevkiyat),
          icon: const Icon(Icons.check_circle),
          label: const Text('Teslim Et'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        );
      } else {
        return ElevatedButton.icon(
          onPressed: () => _teslimTamamla(sevkiyat),
          icon: const Icon(Icons.done_all),
          label: const Text('Tamamla'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        );
      }
    } else {
      return Icon(
        sevkiyat['durum'] == 'teslim_edildi' ? Icons.check_circle : Icons.cancel,
        color: sevkiyat['durum'] == 'teslim_edildi' ? Colors.green : Colors.red,
        size: 28,
      );
    }
  }

  Color _getSevkiyatColor(String? durum) {
    switch (durum) {
      case 'bekliyor': return Colors.orange;
      case 'kalite_onaylandi': return Colors.purple;
      case 'alindi': return Colors.blue;
      case 'yolda': return Colors.teal;
      case 'teslimde': return Colors.cyan;
      case 'teslim_edildi': return Colors.green;
      case 'iptal': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDurumText(String? durum) {
    switch (durum) {
      case 'bekliyor': return 'Şoför Bekliyor';
      case 'kalite_onaylandi': return 'Kalite Onaylandı - Hazır';
      case 'alindi': return 'Şoför Aldı';
      case 'yolda': return 'Yolda';
      case 'teslimde': return 'Teslim Ediliyor';
      case 'teslim_edildi': return 'Teslim Edildi';
      case 'iptal': return 'İptal Edildi';
      default: return durum ?? 'Bilinmiyor';
    }
  }

  Future<void> _sevkiyatiAl(Map<String, dynamic> sevkiyat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sevkiyatı Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${sevkiyat[DbTables.trikoTakip]['marka']} - ${sevkiyat[DbTables.trikoTakip]['item_no']}'),
            Text('Adet: ${sevkiyat['sevk_adeti']}'),
            Text('Kaynak: ${sevkiyat['kaynak_atolye']?['atolye_adi'] ?? 'Belirtilmemiş'}'),
            Text('Hedef: ${sevkiyat['hedef_atolye']?['atolye_adi'] ?? 'Belirtilmemiş'}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bu sevkiyatı almanızla birlikte size atanacak ve sevkiyat listenize eklenecektir.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Sevkiyatı Al'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await supabase
            .from(DbTables.sevkTalepleri)
            .update({
              'durum': 'alindi',
              'sofor_user_id': soforInfo!['user_id'],
              'alinan_tarih': DateTime.now().toIso8601String(),
            })
            .eq('id', sevkiyat['id']);
            
        await _loadSevkiyatlar();
        
        if (mounted) {
          context.showSuccessSnackBar('✅ Sevkiyat alındı');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  Future<void> _yolaBasla(Map<String, dynamic> sevkiyat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yola Çık'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${sevkiyat['sevk_adeti']} adet ürün ile yola çıkmak istediğinizi onaylıyor musunuz?'),
            const SizedBox(height: 16),
            Text(
              'Hedef: ${sevkiyat['hedef_atolye']?['atolye_adi'] ?? 'Belirtilmemiş'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sevkiyat['hedef_atolye']?['adres'] != null)
              Text(
                '📍 ${sevkiyat['hedef_atolye']['adres']}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.directions_car),
            label: const Text('Yola Çık'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await supabase
            .from(DbTables.sevkTalepleri)
            .update({
              'durum': 'yolda',
              'sevkiyat_baslama_tarihi': DateTime.now().toIso8601String(),
            })
            .eq('id', sevkiyat['id']);
            
        await _loadSevkiyatlar();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚗 Yola çıkıldı - İyi yolculuklar!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  Future<void> _teslimEt(Map<String, dynamic> sevkiyat) async {
    final teslimAdetController = TextEditingController(
      text: sevkiyat['sevk_adeti'].toString()
    );
    final notlarController = TextEditingController();
    final hasarController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teslimat Bilgileri'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hedef: ${sevkiyat['hedef_atolye']?['atolye_adi'] ?? 'Belirtilmemiş'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teslimAdetController,
                decoration: const InputDecoration(
                  labelText: 'Teslim Edilen Adet',
                  border: OutlineInputBorder(),
                  helperText: 'Teslim edilen toplam adet',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notlarController,
                decoration: const InputDecoration(
                  labelText: 'Teslimat Notları (İsteğe bağlı)',
                  border: OutlineInputBorder(),
                  helperText: 'Teslim alan kişi, özel durumlar vb.',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hasarController,
                decoration: const InputDecoration(
                  labelText: 'Hasar Raporu (Varsa)',
                  border: OutlineInputBorder(),
                  helperText: 'Teslimat sırasında hasar oluştuysa belirtin',
                ),
                maxLines: 2,
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
            onPressed: () {
              Navigator.pop(context, {
                'teslim_adeti': int.tryParse(teslimAdetController.text) ?? sevkiyat['sevk_adeti'],
                'notlar': notlarController.text,
                'hasar': hasarController.text,
              });
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Teslim Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await supabase
            .from(DbTables.sevkTalepleri)
            .update({
              'durum': 'teslim_edildi',
              'gercek_teslim_tarihi': DateTime.now().toIso8601String(),
              'teslim_notlari': result['notlar'],
              'hasar_raporu': result['hasar'].isNotEmpty ? result['hasar'] : null,
              'teslim_onay_durumu': true,
            })
            .eq('id', sevkiyat['id']);
        
        // Kısmi teslimat durumu
        final sevkAdeti = sevkiyat['sevk_adeti'] ?? 0;
        final teslimAdeti = result['teslim_adeti'] ?? sevkAdeti;
        
        if (teslimAdeti < sevkAdeti) {
          // Kısmi teslimat - kalan için yeni sevk talebi oluştur
          await supabase.from(DbTables.sevkTalepleri).insert({
            'model_id': sevkiyat['model_id'],
            'kaynak_atolye_id': sevkiyat['kaynak_atolye_id'],
            'hedef_atolye_id': sevkiyat['hedef_atolye_id'],
            'talep_eden_user_id': sevkiyat['talep_eden_user_id'],
            'sevk_adeti': sevkAdeti - teslimAdeti,
            'durum': 'bekliyor',
            'aciklama': 'Kısmi sevkiyat kalıntısı - Önceki Talep ID: ${sevkiyat['id']}',
          });
        }
            
        await _loadSevkiyatlar();
        
        if (mounted) {
          context.showSuccessSnackBar('✅ Teslimat tamamlandı');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Hata: $e');
        }
      }
    }
  }

  Future<void> _teslimTamamla(Map<String, dynamic> sevkiyat) async {
    // Aynı teslim işlemi
    await _teslimEt(sevkiyat);
  }

  void _showSevkiyatDetay(Map<String, dynamic> sevkiyat) {
    final modelData = sevkiyat[DbTables.trikoTakip];
    final kaynakAtelye = sevkiyat['kaynak_atolye'];
    final hedefAtelye = sevkiyat['hedef_atolye'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sevkiyat Detayı #${sevkiyat['id']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailSection('Model Bilgileri', [
                'Marka: ${modelData['marka']}',
                'Item No: ${modelData['item_no']}',
                'Renk: ${modelData['renk'] ?? 'Belirtilmemiş'}',
                'Toplam Sipariş: ${modelData['adet']} adet',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Sevkiyat Bilgileri', [
                'Sevk Adeti: ${sevkiyat['sevk_adeti']} adet',
                'Durum: ${_getDurumText(sevkiyat['durum'])}',
                'Öncelik: ${sevkiyat['onceligi'] == 'acil' ? '🚨 ACİL' : 'Normal'}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Kaynak', [
                'Atölye: ${kaynakAtelye?['atolye_adi'] ?? 'Belirtilmemiş'}',
                'Adres: ${kaynakAtelye?['adres'] ?? 'Belirtilmemiş'}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('Hedef', [
                'Atölye: ${hedefAtelye?['atolye_adi'] ?? 'Belirtilmemiş'}',
                'Adres: ${hedefAtelye?['adres'] ?? 'Belirtilmemiş'}',
              ]),
              if (sevkiyat['aciklama'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection('Açıklama', [sevkiyat['aciklama']]),
              ],
              if (sevkiyat['kalite_notlari'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection('Kalite Notları', [sevkiyat['kalite_notlari']]),
              ],
              if (sevkiyat['teslim_notlari'] != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection('Teslimat Notları', [sevkiyat['teslim_notlari']]),
              ],
              if (sevkiyat['hasar_raporu'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ Hasar Raporu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(sevkiyat['hasar_raporu']),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildDetailSection('Tarihler', [
                'Oluşturulma: ${_formatDate(sevkiyat['created_at'])}',
                if (sevkiyat['alinan_tarih'] != null)
                  'Alınma: ${_formatDate(sevkiyat['alinan_tarih'])}',
                if (sevkiyat['sevkiyat_baslama_tarihi'] != null)
                  'Yola Çıkış: ${_formatDate(sevkiyat['sevkiyat_baslama_tarihi'])}',
                if (sevkiyat['gercek_teslim_tarihi'] != null)
                  'Teslim: ${_formatDate(sevkiyat['gercek_teslim_tarihi'])}',
              ]),
            ],
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

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
        const Divider(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item, style: const TextStyle(fontSize: 13)),
        )),
      ],
    );
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Belirtilmemiş';
    try {
      final date = DateTime.parse(dateTimeStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
