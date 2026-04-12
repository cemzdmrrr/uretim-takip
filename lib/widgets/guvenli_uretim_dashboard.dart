// GÜVENLİ ÜRETİM DASHBOARD'U
// Sadece atanmış modelleri gösterir, firma izolasyonu sağlar

import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/uretim_zinciri_service.dart';

class GuvenliUretimDashboard extends StatefulWidget {
  final String asamaAdi; // 'dokuma', 'konfeksiyon', vs.

  const GuvenliUretimDashboard({
    Key? key,
    required this.asamaAdi,
  }) : super(key: key);

  @override
  State<GuvenliUretimDashboard> createState() => _GuvenliUretimDashboardState();
}

class _GuvenliUretimDashboardState extends State<GuvenliUretimDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = UretimZinciriService();
  
  List<Map<String, dynamic>> _atanmisModeller = [];
  List<Map<String, dynamic>> _bekleyenModeller = [];
  List<Map<String, dynamic>> _devamEdenModeller = [];
  List<Map<String, dynamic>> _tamamlananModeller = [];
  
  bool _yukleniyor = true;
  String? _kullaniciEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _kullaniciKontrolEt();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _kullaniciKontrolEt() async {
    try {
      final rol = await _service.getCurrentUserRole();
      final currentUser = _service.supabase.auth.currentUser;
      
      setState(() {
        _kullaniciEmail = currentUser?.email;
      });

      if (rol == null) {
        _yonlendir(AppRoutes.login);
        return;
      }

      // Admin veya ilgili aşama personeli değilse erişim engelle
      if (rol != 'admin' && rol != widget.asamaAdi) {
        _showError('Bu aşamaya erişim yetkiniz yok: ${widget.asamaAdi}');
        _yonlendir('/');
        return;
      }

      await _modelleriYukle();
    } catch (e) {
      _showError('Kullanıcı kontrolü hatası: $e');
    }
  }

  Future<void> _modelleriYukle() async {
    if (!mounted) return;
    setState(() => _yukleniyor = true);

    try {
      final modeller = await _service.getAssignedModels(widget.asamaAdi);
      
      setState(() {
        _atanmisModeller = modeller;
        _bekleyenModeller = modeller
            .where((m) => m['durum'] == 'atandi')
            .toList();
        _devamEdenModeller = modeller
            .where((m) => m['durum'] == 'baslatildi')
            .toList();
        _tamamlananModeller = modeller
            .where((m) => m['durum'] == 'tamamlandi')
            .toList();
      });
    } catch (e) {
      _showError('Modeller yüklenemedi: $e');
    }

    setState(() => _yukleniyor = false);
  }

  Future<void> _durumGuncelle(int modelId, String yeniDurum) async {
    try {
      final success = await _service.updateModelStatus(
        modelId: modelId,
        stageName: widget.asamaAdi,
        newStatus: yeniDurum,
      );

      if (success) {
        if (!mounted) return;
        context.showSuccessSnackBar('Model durumu güncellendi: $yeniDurum');
        await _modelleriYukle(); // Listeyi yenile
      } else {
        _showError('Durum güncellenemedi');
      }
    } catch (e) {
      _showError('Durum güncelleme hatası: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _yonlendir(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  String _getAsamaDisplayName() {
    final asamaMap = {
      'dokuma': 'Dokuma',
      'konfeksiyon': 'Konfeksiyon',
      'yikama': 'Yıkama',
      'utu': 'Ütü',
      'ilik_dugme': 'İlik Düğme',
      'kalite_kontrol': 'Kalite Kontrol',
      'paketleme': 'Paketleme',
    };
    return asamaMap[widget.asamaAdi] ?? widget.asamaAdi.toUpperCase();
  }

  Color _getAsamaColor() {
    final colorMap = {
      'dokuma': Colors.blue,
      'konfeksiyon': Colors.deepOrange,
      'yikama': Colors.cyan,
      'utu': Colors.amber,
      'ilik_dugme': Colors.indigo,
      'kalite_kontrol': Colors.teal,
      'paketleme': Colors.brown,
    };
    return colorMap[widget.asamaAdi] ?? Colors.grey;
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    final durum = model['durum'] as String? ?? 'atandi';
    final modelId = model['model_id'] as int;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve durum
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    model['model_adi'] ?? 'Model Adı Yok',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(durum),
              ],
            ),
            const SizedBox(height: 8),

            // Müşteri ve adet
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  model['musteri_adi'] ?? 'Müşteri Yok',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.production_quantity_limits, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${model['siparis_adedi'] ?? 0} adet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Atama tarihi ve notlar
            if (model['atama_tarihi'] != null)
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Atanma: ${_formatDate(model['atama_tarihi'])}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            
            if (model['notlar'] != null && model['notlar'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          model['notlar'].toString(),
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Aksiyon butonları
            _buildActionButtons(modelId, durum),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String durum) {
    Color color;
    String text;
    IconData icon;

    switch (durum) {
      case 'atandi':
        color = Colors.orange;
        text = 'Bekliyor';
        icon = Icons.schedule;
        break;
      case 'baslatildi':
        color = Colors.blue;
        text = 'Devam Ediyor';
        icon = Icons.play_arrow;
        break;
      case 'tamamlandi':
        color = Colors.green;
        text = 'Tamamlandı';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        text = durum;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int modelId, String durum) {
    final List<Widget> buttons = [];

    switch (durum) {
      case 'atandi':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _durumGuncelle(modelId, 'baslatildi'),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Başlat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        );
        break;
      case 'baslatildi':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _durumGuncelle(modelId, 'tamamlandi'),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        );
        break;
      case 'tamamlandi':
        buttons.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Tamamlandı',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: buttons,
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildTabContent(List<Map<String, dynamic>> modeller, String tabName) {
    if (_yukleniyor) {
      return const LoadingWidget();
    }

    if (modeller.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$tabName listesinde model bulunmuyor',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _modelleriYukle,
      child: ListView.builder(
        itemCount: modeller.length,
        itemBuilder: (context, index) => _buildModelCard(modeller[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asamaColor = _getAsamaColor();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_getAsamaDisplayName()} Dashboard',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: asamaColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Kullanıcı bilgisi
          if (_kullaniciEmail != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _kullaniciEmail!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          
          // Yenile butonu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _modelleriYukle,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Bekleyen (${_bekleyenModeller.length})'),
            Tab(text: 'Devam Eden (${_devamEdenModeller.length})'),
            Tab(text: 'Tamamlanan (${_tamamlananModeller.length})'),
            Tab(text: 'Tümü (${_atanmisModeller.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_bekleyenModeller, 'Bekleyen'),
          _buildTabContent(_devamEdenModeller, 'Devam Eden'),
          _buildTabContent(_tamamlananModeller, 'Tamamlanan'),
          _buildTabContent(_atanmisModeller, 'Tüm'),
        ],
      ),
    );
  }
}
