import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';
import 'package:uretim_takip/services/kasa_banka_service.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_ekle_page.dart';

part 'fatura_detay_page_widgets.dart';


class FaturaDetayPage extends StatefulWidget {
  final FaturaModel fatura;

  const FaturaDetayPage({super.key, required this.fatura});

  @override
  State<FaturaDetayPage> createState() => _FaturaDetayPageState();
}

class _FaturaDetayPageState extends State<FaturaDetayPage> {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  late FaturaModel _fatura;
  List<FaturaKalemiModel> _faturaKalemleri = [];
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _fatura = widget.fatura;
    _faturaKalemleriniYukle();
  }

  Future<void> _faturaKalemleriniYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      final kalemler = await FaturaService.faturaKalemleriniGetir(_fatura.faturaId!);
      setState(() {
        _faturaKalemleri = kalemler;
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Fatura kalemleri yüklenirken hata: $e');
      }
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  Future<void> _faturaduzenle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaturaEklePage(duzenlenecekFatura: _fatura),
      ),
    );

    if (result == true) {
      // Faturayı yeniden yükle
      try {
        final guncelFatura = await FaturaService.faturaGetir(_fatura.faturaId!);
        if (guncelFatura != null) {
          setState(() {
            _fatura = guncelFatura;
          });
          _faturaKalemleriniYukle();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Fatura güncellenirken hata: $e');
        }
      }
    }
  }

  Future<void> _faturaSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fatura Sil'),
        content: Text('${_fatura.faturaNo} numaralı faturayı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await FaturaService.faturaSil(_fatura.faturaId!);
        if (mounted) {
          context.showSuccessSnackBar('Fatura silindi');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Fatura silinirken hata: $e');
        }
      }
    }
  }

  Future<void> _faturaDurumGuncelle(String yeniDurum) async {
    try {
      await FaturaService.faturaDurumGuncelle(_fatura.faturaId!, yeniDurum);
      if (!mounted) return;
      setState(() {
        _fatura = _fatura.copyWith(durum: yeniDurum);
      });
      if (mounted) {
        context.showSuccessSnackBar('Fatura durumu "$yeniDurum" olarak güncellendi');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Durum güncellenirken hata: $e');
      }
    }
  }

  void _odemeEkle() {
    showDialog(
      context: context,
      builder: (context) => _OdemeEkleDialog(
        fatura: _fatura,
        onOdemeEklendi: (yeniOdenenTutar, yeniOdemeDurumu) {
          setState(() {
            _fatura = _fatura.copyWith(
              odenenTutar: yeniOdenenTutar,
              odemeDurumu: yeniOdemeDurumu,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fatura - ${_fatura.faturaNo}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'duzenle':
                  _faturaduzenle();
                  break;
                case 'sil':
                  if (_fatura.durum == 'taslak') {
                    _faturaSil();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sadece taslak faturalar silinebilir'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  break;
                case 'onayla':
                  _faturaDurumGuncelle('onaylandi');
                  break;
                case 'gonder':
                  _faturaDurumGuncelle('gonderildi');
                  break;
                case 'iptal':
                  _faturaDurumGuncelle('iptal');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duzenle',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              if (_fatura.durum == 'taslak')
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
              if (_fatura.durum == 'taslak')
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
              if (_fatura.durum == 'onaylandi')
                const PopupMenuItem(
                  value: 'gonder',
                  child: Row(
                    children: [
                      Icon(Icons.send, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Gönder'),
                    ],
                  ),
                ),
              if (_fatura.durum != 'iptal')
                const PopupMenuItem(
                  value: 'iptal',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('İptal Et'),
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
            // Fatura durum kartı
            _buildDurumKarti(),
            const SizedBox(height: 16),
            
            // Temel bilgiler kartı
            _buildTemelBilgilerKarti(),
            const SizedBox(height: 16),
            
            // Müşteri/Tedarikçi bilgileri kartı
            _buildMusteriTedarikciKarti(),
            const SizedBox(height: 16),
            
            // Fatura kalemleri kartı
            _buildFaturaKalemleriKarti(),
            const SizedBox(height: 16),
            
            // Tutar bilgileri kartı
            _buildTutarBilgileriKarti(),
            const SizedBox(height: 16),
            
            // Ödeme bilgileri kartı
            if (_fatura.faturaTuru == 'satis')
              _buildOdemeBilgileriKarti(),
          ],
        ),
      ),
    );
  }

}