import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_ekle_page.dart';
import 'package:uretim_takip/services/kasa_banka_service.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_hareket_listesi_page.dart'; // Yeni import

class KasaBankaDetayPage extends StatefulWidget {
  final KasaBankaModel kasaBanka;

  const KasaBankaDetayPage({
    super.key,
    required this.kasaBanka,
  });

  @override
  State<KasaBankaDetayPage> createState() => _KasaBankaDetayPageState();
}

class _KasaBankaDetayPageState extends State<KasaBankaDetayPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _kasaBankaService = KasaBankaService();
  late KasaBankaModel _kasaBanka;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _kasaBanka = widget.kasaBanka;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _duzenle() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => KasaBankaEklePage(kasaBanka: _kasaBanka),
      ),
    );

    if (result == true) {
      // Veriyi yeniden yükle
      await _veriYenile();
    }
  }

  Future<void> _veriYenile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final guncellenenKasaBanka = await _kasaBankaService.kasaBankaGetir(_kasaBanka.id!);
      if (guncellenenKasaBanka != null) {
        setState(() {
          _kasaBanka = guncellenenKasaBanka;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Veri yenilenirken hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sil() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap Silme'),
        content: Text(
          '${_kasaBanka.ad} hesabını silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem geri alınamaz ve hesaba ait tüm hareketler de silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _kasaBankaService.kasaBankaSil(_kasaBanka.id!);
        if (mounted) {
          context.showSuccessSnackBar('Hesap başarıyla silindi');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Silme hatası: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatTarih(DateTime tarih) {
    return DateFormat('dd.MM.yyyy HH:mm').format(tarih);
  }

  String _formatTutar(double tutar, String doviz) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return '${formatter.format(tutar)} $doviz';
  }

  Color _getDurumRengi(String durum) {
    switch (durum) {
      case 'AKTIF':
        return Colors.green;
      case 'PASIF':
        return Colors.orange;
      case 'DONUK':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Icon _getTipIcon(String tip) {
    switch (tip) {
      case 'KASA':
        return const Icon(Icons.account_balance_wallet, color: Colors.brown);
      case 'BANKA':
        return const Icon(Icons.account_balance, color: Colors.blue);
      case 'KREDI_KARTI':
        return const Icon(Icons.credit_card, color: Colors.purple);
      case 'CEK_HESABI':
        return const Icon(Icons.receipt_long, color: Colors.teal);
      default:
        return const Icon(Icons.account_balance_wallet, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_kasaBanka.ad),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              onPressed: _veriYenile,
              icon: const Icon(Icons.refresh),
              tooltip: 'Yenile',
            ),
            IconButton(
              onPressed: _duzenle,
              icon: const Icon(Icons.edit),
              tooltip: 'Düzenle',
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sil',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'sil') {
                  _sil();
                }
              },
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel', icon: Icon(Icons.info)),
            Tab(text: 'Hareketler', icon: Icon(Icons.list_alt)),
            Tab(text: 'Raporlar', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenelTab(),
          _buildHareketlerTab(),
          _buildRaporlarTab(),
        ],
      ),
    );
  }

  Widget _buildGenelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Özet Kart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getTipIcon(_kasaBanka.tip),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _kasaBanka.ad,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDurumRengi(_kasaBanka.durumu),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _kasaBanka.durumu,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _kasaBanka.tip.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Bakiye
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Güncel Bakiye',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTutar(_kasaBanka.bakiye, _kasaBanka.dovizTuru),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Detay Bilgiler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detay Bilgiler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_kasaBanka.aciklama != null && _kasaBanka.aciklama!.isNotEmpty) ...[
                    _buildDetayItem('Açıklama', _kasaBanka.aciklama!),
                    const SizedBox(height: 12),
                  ],
                  
                  _buildDetayItem('Döviz Türü', _kasaBanka.dovizTuru),
                  const SizedBox(height: 12),
                  
                  _buildDetayItem(
                    'Oluşturma Tarihi',
                    _formatTarih(_kasaBanka.olusturmaTarihi),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetayItem(
                    'Son Güncelleme',
                    _formatTarih(_kasaBanka.guncellenmeTarihi),
                  ),
                ],
              ),
            ),
          ),
          
          // Banka Bilgileri (sadece banka hesapları için)
          if (_kasaBanka.tip == 'BANKA' || 
              _kasaBanka.tip == 'KREDI_KARTI' || 
              _kasaBanka.tip == 'CEK_HESABI') ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Banka Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_kasaBanka.bankaAdi != null) ...[
                      _buildDetayItem('Banka Adı', _kasaBanka.bankaAdi!),
                      const SizedBox(height: 12),
                    ],
                    
                    if (_kasaBanka.subeKodu != null || _kasaBanka.subeAdi != null) ...[
                      _buildDetayItem(
                        'Şube',
                        '${_kasaBanka.subeKodu ?? ''} ${_kasaBanka.subeAdi ?? ''}'.trim(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    if (_kasaBanka.hesapNo != null) ...[
                      _buildDetayItem('Hesap No', _kasaBanka.hesapNo!),
                      const SizedBox(height: 12),
                    ],
                    
                    if (_kasaBanka.iban != null) ...[
                      _buildDetayItem('IBAN', _kasaBanka.iban!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetayItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  Widget _buildHareketlerTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Hesap Hareketleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu hesaba ait para giriş/çıkış ve transfer işlemlerini görüntüleyin.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KasaBankaHareketListesiPage(
                    kasaBankaId: _kasaBanka.id?.toString(),
                    kasaBankaAdi: _kasaBanka.ad,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list),
            label: const Text('Hareketleri Görüntüle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaporlarTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Raporlar modülü hazırlanıyor...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Kasa/Banka raporları burada görüntülenecektir.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
