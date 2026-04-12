import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';
import 'package:uretim_takip/services/tedarikci_service.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_ekle_page.dart';

class TedarikciDetayPage extends StatefulWidget {
  final int tedarikciId;

  const TedarikciDetayPage({
    Key? key,
    required this.tedarikciId,
  }) : super(key: key);

  @override
  State<TedarikciDetayPage> createState() => _TedarikciDetayPageState();
}

class _TedarikciDetayPageState extends State<TedarikciDetayPage> {
  TedarikciModel? _tedarikci;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _tedarikciYukle();
  }

  Future<void> _tedarikciYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      final tedarikci = await TedarikciService.tedarikciGetir(widget.tedarikciId);
      setState(() {
        _tedarikci = tedarikci;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _yukleniyor = false;
      });
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  Future<void> _tedarikciSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tedarikçi Sil'),
        content: const Text(
          'Bu tedarikçiyi silmek istediğinizden emin misiniz?\n\n'
          'Not: Tedarikçiye ait stok ve sipariş kayıtlarındaki referanslar temizlenecektir.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await TedarikciService.tedarikciSil(widget.tedarikciId);
        if (mounted) {
          context.showSuccessSnackBar('Tedarikçi başarıyla silindi');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String hataMesaji = 'Tedarikçi silinirken bir hata oluştu';
          
          // Foreign key hatası kontrolü
          if (e.toString().contains('foreign key') || 
              e.toString().contains('still referenced') ||
              e.toString().contains('23503')) {
            hataMesaji = 'Bu tedarikçiye bağlı kayıtlar var. '
                'Lütfen önce ilgili stok ve sipariş kayıtlarını düzenleyin.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(hataMesaji),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedarikçi Detayı'),
        actions: [
          if (_tedarikci != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final sonuc = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TedarikciEklePage(tedarikci: _tedarikci),
                  ),
                );
                if (sonuc == true) {
                  _tedarikciYukle();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _tedarikciSil,
            ),
          ],
        ],
      ),
      body: _yukleniyor
          ? const LoadingWidget()
          : _tedarikci == null
              ? const Center(
                  child: Text(
                    'Tedarikçi bulunamadı',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temel Bilgiler
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Temel Bilgiler',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _tedarikci!.goruntulemeAdi,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tedarikci!.durumRengi,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _tedarikci!.durumAciklama,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _bilgiSatiri('ID', _tedarikci!.id.toString()),
                              _bilgiSatiri('Ad', _tedarikci!.ad),
                              if (_tedarikci!.soyad != null)
                                _bilgiSatiri('Soyad', _tedarikci!.soyad!),
                              if (_tedarikci!.sirket != null)
                                _bilgiSatiri('Şirket', _tedarikci!.sirket!),
                              _bilgiSatiri('Telefon', _tedarikci!.telefon),
                              if (_tedarikci!.email != null)
                                _bilgiSatiri('E-posta', _tedarikci!.email!),
                              _bilgiSatiri('Tedarikçi Türü', _tedarikci!.tedarikciTipiAciklama),
                              if (_tedarikci!.faaliyet != null)
                                _bilgiSatiri('Faaliyet Alanı', _tedarikci!.faaliyetAciklama),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Mali Bilgiler
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mali Bilgiler',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_tedarikci!.vergiNo != null)
                                _bilgiSatiri('Vergi Numarası', _tedarikci!.vergiNo!),
                              if (_tedarikci!.tcKimlik != null)
                                _bilgiSatiri('TC Kimlik Numarası', _tedarikci!.tcKimlik!),
                              if (_tedarikci!.ibanNo != null)
                                _bilgiSatiri('IBAN Numarası', _tedarikci!.ibanNo!),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Kayıt Bilgileri
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kayıt Bilgileri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _bilgiSatiri(
                                'Kayıt Tarihi',
                                '${_tedarikci!.kayitTarihi.day.toString().padLeft(2, '0')}/${_tedarikci!.kayitTarihi.month.toString().padLeft(2, '0')}/${_tedarikci!.kayitTarihi.year}',
                              ),
                              if (_tedarikci!.guncellemeTarihi != null)
                                _bilgiSatiri(
                                  'Güncelleme Tarihi',
                                  '${_tedarikci!.guncellemeTarihi!.day.toString().padLeft(2, '0')}/${_tedarikci!.guncellemeTarihi!.month.toString().padLeft(2, '0')}/${_tedarikci!.guncellemeTarihi!.year}',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _bilgiSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$baslik:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
