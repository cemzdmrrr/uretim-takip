// =============================================
// KASA/BANKA HAREKET DETAY SAYFASI
// Tarih: 27.06.2025
// Açıklama: Kasa/banka hareket detaylarını gösteren sayfa
// =============================================

import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/models/kasa_banka_hareket_model.dart';
import 'package:uretim_takip/services/kasa_banka_hareket_service.dart';

class KasaBankaHareketDetayPage extends StatefulWidget {
  final KasaBankaHareket hareket;

  const KasaBankaHareketDetayPage({
    Key? key,
    required this.hareket,
  }) : super(key: key);

  @override
  State<KasaBankaHareketDetayPage> createState() => _KasaBankaHareketDetayPageState();
}

class _KasaBankaHareketDetayPageState extends State<KasaBankaHareketDetayPage> {
  late KasaBankaHareket _hareket;
  final KasaBankaHareketService _hareketService = KasaBankaHareketService();

  @override
  void initState() {
    super.initState();
    _hareket = widget.hareket;
  }

  Future<void> _hareketOnayla() async {
    if (_hareket.onaylanmisMi) return;

    try {
      final basarili = await _hareketService.hareketOnayla(_hareket.id);
      if (basarili != null) {
        setState(() {
          _hareket = basarili;
        });
        if (!mounted) return;
        context.showSnackBar('Hareket onaylandı');
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  Future<void> _hareketSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hareket Sil'),
        content: const Text('Bu hareketi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        final basarili = await _hareketService.hareketSil(_hareket.id);
        if (basarili) {
          if (!mounted) return;
          Navigator.pop(context, true);
          context.showSnackBar('Hareket silindi');
        }
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Hata: $e');
      }
    }
  }

  Color _getHareketRengi() {
    switch (_hareket.hareketTipi) {
      case 'giris':
        return Colors.green;
      case 'cikis':
        return Colors.red;
      case 'transfer_giden':
        return Colors.orange;
      case 'transfer_gelen':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getHareketIkonu() {
    switch (_hareket.hareketTipi) {
      case 'giris':
        return Icons.arrow_downward;
      case 'cikis':
        return Icons.arrow_upward;
      case 'transfer_giden':
        return Icons.call_made;
      case 'transfer_gelen':
        return Icons.call_received;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getHareketTipiText() {
    switch (_hareket.hareketTipi) {
      case 'giris':
        return 'Para Girişi';
      case 'cikis':
        return 'Para Çıkışı';
      case 'transfer_giden':
        return 'Transfer (Giden)';
      case 'transfer_gelen':
        return 'Transfer (Gelen)';
      default:
        return 'Bilinmiyor';
    }
  }

  String _getKategoriText() {
    switch (_hareket.kategori) {
      case 'fatura_odeme':
        return 'Fatura Ödemesi';
      case 'nakit_giris':
        return 'Nakit Girişi';
      case 'bank_transfer':
        return 'Banka Transferi';
      case 'operasyonel':
        return 'Operasyonel';
      case 'diger':
        return 'Diğer';
      default:
        return 'Belirtilmemiş';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hareket Detayı'),
        elevation: 0,
        backgroundColor: _getHareketRengi(),
        foregroundColor: Colors.white,
        actions: [
          if (!_hareket.onaylanmisMi)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'onayla':
                    _hareketOnayla();
                    break;
                  case 'sil':
                    _hareketSil();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'onayla',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Onayla'),
                    ],
                  ),
                ),
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
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hareket Özeti Kartı
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getHareketRengi().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getHareketIkonu(),
                            color: _getHareketRengi(),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getHareketTipiText(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _hareket.onaylanmisMi
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _hareket.onaylanmisMi ? 'Onaylandı' : 'Beklemede',
                                  style: TextStyle(
                                    color: _hareket.onaylanmisMi
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_hareket.tutar.toStringAsFixed(2)} ${_hareket.paraBirimi}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getHareketRengi(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Detay Bilgileri
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detay Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_hareket.aciklama != null)
                      _buildDetayItem('Açıklama', _hareket.aciklama!),
                    
                    _buildDetayItem('İşlem Tarihi', 
                      '${_hareket.islemTarihi.day.toString().padLeft(2, '0')}.'
                      '${_hareket.islemTarihi.month.toString().padLeft(2, '0')}.'
                      '${_hareket.islemTarihi.year} '
                      '${_hareket.islemTarihi.hour.toString().padLeft(2, '0')}:'
                      '${_hareket.islemTarihi.minute.toString().padLeft(2, '0')}'),
                    
                    _buildDetayItem('Oluşturma Tarihi', 
                      '${_hareket.olusturmaTarihi.day.toString().padLeft(2, '0')}.'
                      '${_hareket.olusturmaTarihi.month.toString().padLeft(2, '0')}.'
                      '${_hareket.olusturmaTarihi.year} '
                      '${_hareket.olusturmaTarihi.hour.toString().padLeft(2, '0')}:'
                      '${_hareket.olusturmaTarihi.minute.toString().padLeft(2, '0')}'),
                    
                    if (_hareket.referansNo != null)
                      _buildDetayItem('Referans No', _hareket.referansNo!),
                    
                    if (_hareket.kategori != null)
                      _buildDetayItem('Kategori', _getKategoriText()),
                    
                    if (_hareket.transferKasaBankaId != null)
                      _buildDetayItem('Transfer Hedef Hesap ID', _hareket.transferKasaBankaId!),
                    
                    if (_hareket.faturaId != null) ...[
                      _buildDetayItem('Fatura ID', _hareket.faturaId!),
                      if (_hareket.faturaNo != null)
                        _buildDetayItem('Fatura No', _hareket.faturaNo!),
                    ],
                    
                    _buildDetayItem('Oluşturan', _hareket.olusturanKullanici),
                    
                    if (_hareket.onaylanmisMi) ...[
                      const Divider(),
                      const Text(
                        'Onay Bilgileri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_hareket.onaylayanKullanici != null)
                        _buildDetayItem('Onaylayan', _hareket.onaylayanKullanici!),
                      
                      if (_hareket.onaylamaTarihi != null)
                        _buildDetayItem('Onaylama Tarihi',
                          '${_hareket.onaylamaTarihi!.day.toString().padLeft(2, '0')}.'
                          '${_hareket.onaylamaTarihi!.month.toString().padLeft(2, '0')}.'
                          '${_hareket.onaylamaTarihi!.year} '
                          '${_hareket.onaylamaTarihi!.hour.toString().padLeft(2, '0')}:'
                          '${_hareket.onaylamaTarihi!.minute.toString().padLeft(2, '0')}'),
                    ],
                    
                    if (_hareket.notlar != null) ...[
                      const Divider(),
                      _buildDetayItem('Notlar', _hareket.notlar!),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hesap Bilgileri
            if (_hareket.kasaBankaAdi != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hesap Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetayItem('Hesap Adı', _hareket.kasaBankaAdi!),
                      
                      if (_hareket.kasaBankaTuru != null)
                        _buildDetayItem('Hesap Türü', _hareket.kasaBankaTuru!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetayItem(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              baslik,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
