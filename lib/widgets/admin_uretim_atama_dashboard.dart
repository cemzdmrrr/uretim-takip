// ADMİN ÜRETİM ATAMA DASHBOARD'U
// Tüm aşamaları yönetebilir, email bazlı atama

import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/services/uretim_zinciri_service.dart';
import 'package:uretim_takip/widgets/guvenli_atama_dialog.dart';

class AdminUretimAtamaDashboard extends StatefulWidget {
  const AdminUretimAtamaDashboard({Key? key}) : super(key: key);

  @override
  State<AdminUretimAtamaDashboard> createState() => _AdminUretimAtamaDashboardState();
}

class _AdminUretimAtamaDashboardState extends State<AdminUretimAtamaDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = UretimZinciriService();
  
  List<Map<String, dynamic>> _istatistikler = [];
  Map<String, List<Map<String, dynamic>>> _asamaAtamalari = {};
  
  bool _yukleniyor = true;
  String _seciliAsama = 'dokuma';
  final List<String> _seciliModelIdleri = [];

  final List<Map<String, dynamic>> _asamalar = [
    {'kod': 'dokuma', 'ad': 'Dokuma', 'icon': Icons.design_services, 'color': const Color(0xFF2196F3)},
    {'kod': 'konfeksiyon', 'ad': 'Konfeksiyon', 'icon': Icons.checkroom, 'color': const Color(0xFF4CAF50)},
    {'kod': 'yikama', 'ad': 'Yıkama', 'icon': Icons.local_laundry_service, 'color': const Color(0xFF00BCD4)},
    {'kod': 'utu', 'ad': 'Ütü', 'icon': Icons.iron, 'color': const Color(0xFFFF9800)},
    {'kod': 'ilik_dugme', 'ad': 'İlik Düğme', 'icon': Icons.radio_button_checked, 'color': const Color(0xFF9C27B0)},
    {'kod': 'kalite_kontrol', 'ad': 'Kalite Kontrol', 'icon': Icons.verified, 'color': const Color(0xFF795548)},
    {'kod': 'paketleme', 'ad': 'Paketleme', 'icon': Icons.inventory, 'color': const Color(0xFF607D8B)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _asamalar.length, vsync: this);
    _verileriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    
    try {
      // Tüm modelleri yükle
      await _service.getAuthorizedModels();
      
      // İstatistikleri yükle
      final istatistikler = await _service.getAssignmentStatistics();
      
      // Her aşama için atamaları yükle
      final Map<String, List<Map<String, dynamic>>> asamaAtamalari = {};
      for (final asama in _asamalar) {
        final atamaListesi = await _service.getAssignedModels(asama['kod']);
        asamaAtamalari[asama['kod']] = atamaListesi;
      }
      
      setState(() {
        _istatistikler = istatistikler;
        _asamaAtamalari = asamaAtamalari;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      _showError('Veriler yüklenemedi: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _atamaDialogAc() async {
    if (_seciliModelIdleri.isEmpty) {
      _showError('Lütfen atanacak modelleri seçin');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => GuvenliAtamaDialog(
        seciliModelIdleri: _seciliModelIdleri,
        varsayilanAsama: _seciliAsama,
      ),
    );

    if (result == true) {
      _showSuccess('Atama işlemi başarılı!');
      _seciliModelIdleri.clear();
      _verileriYukle();
    }
  }

  Widget _buildIstatistikKartlari() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _istatistikler.length,
        itemBuilder: (context, index) {
          final stat = _istatistikler[index];
          final asama = _asamalar.firstWhere(
            (a) => a['kod'] == stat['asama'],
            orElse: () => {'ad': stat['asama'], 'icon': Icons.work, 'color': Colors.grey},
          );
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(asama['icon'], color: asama['color'], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            asama['ad'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Toplam: ${stat['toplam_atama']}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      'Bekleyen: ${stat['bekleyen']}',
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                    Text(
                      'Tamamlanan: ${stat['tamamlanan']}',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModelListesi() {
    final asamaModelleri = _asamaAtamalari[_seciliAsama] ?? [];
    
    if (asamaModelleri.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bu aşamada henüz atama yok'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: asamaModelleri.length,
      itemBuilder: (context, index) {
        final model = asamaModelleri[index];
        final modelId = model['model_id']?.toString() ?? '';
        final isSelected = _seciliModelIdleri.contains(modelId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Colors.blue.shade50 : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _seciliModelIdleri.add(modelId);
                  } else {
                    _seciliModelIdleri.remove(modelId);
                  }
                });
              },
            ),
            title: Text(
              model['model_adi'] ?? 'Model ${model['model_id']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Müşteri: ${model['musteri_adi'] ?? 'Belirtilmemiş'}'),
                Text('Adet: ${model['siparis_adedi'] ?? 0}'),
                if (model['notlar'] != null && model['notlar'].isNotEmpty)
                  Text('Not: ${model['notlar']}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDurumRengi(model['durum']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDurumMetni(model['durum']),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _seciliModelIdleri.remove(modelId);
                } else {
                  _seciliModelIdleri.add(modelId);
                }
              });
            },
          ),
        );
      },
    );
  }

  Color _getDurumRengi(String? durum) {
    switch (durum) {
      case 'atandi': return Colors.blue;
      case 'baslatildi': return Colors.orange;
      case 'tamamlandi': return Colors.green;
      case 'iptal': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDurumMetni(String? durum) {
    switch (durum) {
      case 'atandi': return 'Atandı';
      case 'baslatildi': return 'Başlatıldı';
      case 'tamamlandi': return 'Tamamlandı';
      case 'iptal': return 'İptal';
      default: return 'Bilinmiyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenli Üretim Atama Sistemi'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            setState(() {
              _seciliAsama = _asamalar[index]['kod'];
              _seciliModelIdleri.clear();
            });
          },
          tabs: _asamalar.map((asama) {
            return Tab(
              icon: Icon(asama['icon']),
              text: asama['ad'],
            );
          }).toList(),
        ),
      ),
      body: _yukleniyor
          ? const LoadingWidget()
          : Column(
              children: [
                // İstatistik kartları
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Üretim Aşaması İstatistikleri',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _buildIstatistikKartlari(),
                    ],
                  ),
                ),
                
                // Seçili model sayısı
                if (_seciliModelIdleri.isNotEmpty)
                  Container(
                    color: Colors.blue.shade50,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text('${_seciliModelIdleri.length} model seçildi'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() => _seciliModelIdleri.clear()),
                          icon: const Icon(Icons.clear),
                          label: const Text('Temizle'),
                        ),
                      ],
                    ),
                  ),
                
                // Model listesi
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _asamalar.map((asama) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildModelListesi(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: _seciliModelIdleri.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _atamaDialogAc,
              icon: const Icon(Icons.assignment),
              label: const Text('Atama Yap'),
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            )
          : FloatingActionButton(
              onPressed: _verileriYukle,
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              child: const Icon(Icons.refresh),
            ),
    );
  }
}
