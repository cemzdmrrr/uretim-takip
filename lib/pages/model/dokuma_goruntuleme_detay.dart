import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DokumaGoruntulemeDetay extends StatefulWidget {
  final String modelId;
  final Map<String, dynamic>? modelData;

  const DokumaGoruntulemeDetay({
    Key? key,
    required this.modelId,
    this.modelData,
  }) : super(key: key);

  @override
  State<DokumaGoruntulemeDetay> createState() => _DokumaGoruntulemeDetayState();
}

class _DokumaGoruntulemeDetayState extends State<DokumaGoruntulemeDetay> {
  Map<String, dynamic>? currentModelData;
  bool yukleniyor = true;
  String? currentUserRole;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _kullaniciRolunuKontrolEt();
    _modelBilgileriniGetir();
  }

  Future<void> _kullaniciRolunuKontrolEt() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      try {
        final response = await supabase
            .from(DbTables.userRoles)
            .select('role')
            .eq('user_id', currentUser.id)
            .maybeSingle();
        
        setState(() {
          currentUserRole = response?['role'];
        });
      } catch (e) {
        debugPrint('Rol kontrolü hatası: $e');
      }
    }
  }

  Future<void> _modelBilgileriniGetir() async {
    setState(() => yukleniyor = true);
    try {
      final response = await supabase
          .from(DbTables.modeller)
          .select('''
            *,
            dokuma_atama:dokuma_atamalari(
              id,
              atama_tarihi,
              durum,
              onay_tarihi,
              red_sebebi,
              uretim_baslangic_tarihi,
              notlar
            )
          ''')
          .eq('id', widget.modelId)
          .single();

      setState(() {
        currentModelData = response;
        yukleniyor = false;
      });
    } catch (e) {
      debugPrint('Model bilgileri getirme hatası: $e');
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _dokumaKarariniGuncelle(String karar, {String? redSebebi}) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      setState(() => yukleniyor = true);

      // Dokuma ataması tablosunu güncelle
      final updateData = {
        'durum': karar,
        'onay_tarihi': karar == 'onaylandi' ? DateTime.now().toIso8601String() : null,
        'red_sebebi': redSebebi,
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
      };

      await supabase
          .from(DbTables.dokumaAtamalari)
          .update(updateData)
          .eq('model_id', widget.modelId)
          .eq('atanan_kullanici_id', currentUser.id);

      // Modeller tablosundaki durumu da güncelle
      if (karar == 'onaylandi') {
        await supabase
            .from(DbTables.modeller)
            .update({
              'dokuma_durumu': 'onaylandi',
              'dokuma_onay_tarihi': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.modelId);
      } else if (karar == 'reddedildi') {
        await supabase
            .from(DbTables.modeller)
            .update({
              'dokuma_durumu': 'reddedildi',
              'dokuma_red_sebebi': redSebebi,
            })
            .eq('id', widget.modelId);
      }

      await _modelBilgileriniGetir();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            karar == 'onaylandi' 
                ? 'Model başarıyla onaylandı' 
                : 'Model reddedildi'
          ),
          backgroundColor: karar == 'onaylandi' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Dokuma kararı güncelleme hatası: $e');
      if (!mounted) return;
      context.showSnackBar('Hata oluştu: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _uretimeBastla() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      setState(() => yukleniyor = true);

      // Dokuma ataması tablosunu güncelle
      await supabase
          .from(DbTables.dokumaAtamalari)
          .update({
            'uretim_baslangic_tarihi': DateTime.now().toIso8601String(),
            'durum': 'uretimde',
            'guncelleme_tarihi': DateTime.now().toIso8601String(),
          })
          .eq('model_id', widget.modelId)
          .eq('atanan_kullanici_id', currentUser.id);

      // Modeller tablosundaki durumu güncelle
      await supabase
          .from(DbTables.modeller)
          .update({
            'dokuma_durumu': 'uretimde',
            'dokuma_uretim_baslangic': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.modelId);

      await _modelBilgileriniGetir();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Üretime başlandı!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('Üretime başlama hatası: $e');
      if (!mounted) return;
      context.showSnackBar('Hata oluştu: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Widget _buildDokumaAksiyonlari() {
    if (currentModelData == null) return const SizedBox();

    final dokumaAtama = currentModelData!['dokuma_atama'] as List?;
    if (dokumaAtama == null || dokumaAtama.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Bu model size atanmamış.'),
        ),
      );
    }

    final atama = dokumaAtama.first;
    final durum = atama['durum'] as String?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dokuma İşlemleri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDurumBilgisi(durum),
            const SizedBox(height: 16),

            if (durum == 'atandi' || durum == null) ...[
              Text(
                'Bu model size atanmış. Lütfen onaylayın veya reddedin.',
                style: TextStyle(color: Colors.orange.shade700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _dokumaKarariniGuncelle('onaylandi'),
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _redSebebiDialog(),
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (durum == 'onaylandi') ...[
              Text(
                'Model onaylandı. Üretime başlayabilirsiniz.',
                style: TextStyle(color: Colors.green.shade700),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _uretimeBastla(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Üretime Başla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (durum == 'uretimde') ...[
              Text(
                'Model şu anda üretimde.',
                style: TextStyle(color: Colors.blue.shade700),
              ),
              if (atama['uretim_baslangic_tarihi'] != null)
                Text(
                  'Üretime başlama: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(atama['uretim_baslangic_tarihi']))}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ] else if (durum == 'reddedildi') ...[
              Text(
                'Model reddedildi.',
                style: TextStyle(color: Colors.red.shade700),
              ),
              if (atama['red_sebebi'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Red sebebi: ${atama['red_sebebi']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDurumBilgisi(String? durum) {
    Color color;
    String text;
    IconData icon;

    switch (durum) {
      case 'atandi':
        color = Colors.orange;
        text = 'Atandı - Onay Bekliyor';
        icon = Icons.pending;
        break;
      case 'onaylandi':
        color = Colors.green;
        text = 'Onaylandı';
        icon = Icons.check_circle;
        break;
      case 'reddedildi':
        color = Colors.red;
        text = 'Reddedildi';
        icon = Icons.cancel;
        break;
      case 'uretimde':
        color = Colors.blue;
        text = 'Üretimde';
        icon = Icons.settings;
        break;
      default:
        color = Colors.grey;
        text = 'Durum Belirsiz';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redSebebiDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Red Sebebi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lütfen reddetme sebebinizi açıklayın:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Red sebebini yazın...',
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _dokumaKarariniGuncelle('reddedildi', redSebebi: result);
    }
  }

  Widget _buildModelBilgileri() {
    if (currentModelData == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Bilgileri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBilgiSatiri('Model Adı', currentModelData!['model_adi']),
            _buildBilgiSatiri('Müşteri', currentModelData!['musteri_adi']),
            _buildBilgiSatiri('Sipariş Adedi', currentModelData!['siparis_adedi']?.toString()),
            _buildBilgiSatiri('Kumaş Cinsi', currentModelData!['kumas_cinsi']),
            _buildBilgiSatiri('Renk', currentModelData!['renk']),
            if (currentModelData!['teslim_tarihi'] != null)
              _buildBilgiSatiri(
                'Teslim Tarihi',
                DateFormat('dd.MM.yyyy').format(
                  DateTime.parse(currentModelData!['teslim_tarihi']),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiSatiri(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? '-'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Yükleme durumu - rol henüz belirlenmemişse de yükleniyor göster
    if (yukleniyor || currentUserRole == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Model Detayı'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (currentUserRole != 'dokuma' && currentUserRole != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erişim Reddedildi'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Bu sayfaya erişim yetkiniz yok.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentModelData?['model_adi'] ?? 'Model Detayı'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildModelBilgileri(),
                  _buildDokumaAksiyonlari(),
                ],
              ),
            ),
    );
  }
}
