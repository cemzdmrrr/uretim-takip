// =============================================
// KASA/BANKA HAREKET EKLE SAYFASI  
// Tarih: 27.06.2025
// Açıklama: Yeni kasa/banka hareketi ekleme sayfası
// =============================================

import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/kasa_banka_hareket_model.dart';
import 'package:uretim_takip/services/kasa_banka_hareket_service.dart';
import 'package:uretim_takip/services/kasa_banka_service.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';

class KasaBankaHareketEklePage extends StatefulWidget {
  final String? varsayilanKasaBankaId;

  const KasaBankaHareketEklePage({
    Key? key,
    this.varsayilanKasaBankaId,
  }) : super(key: key);

  @override
  State<KasaBankaHareketEklePage> createState() => _KasaBankaHareketEklePageState();
}

class _KasaBankaHareketEklePageState extends State<KasaBankaHareketEklePage> {
  final _formKey = GlobalKey<FormState>();
  final KasaBankaHareketService _hareketService = KasaBankaHareketService();

  // Form controllers
  final _tutarController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _referansNoController = TextEditingController();

  // Form verileri
  String? _secilenHesapId;
  String _secilenHareketTipi = 'giris';
  String? _secilenKategori = 'operasyonel';
  String? _secilenTransferHesapId; // Transfer için
  DateTime _secilenTarih = DateTime.now();
  String _secilenParaBirimi = 'TRY';

  // Hesap listesi
  List<KasaBankaModel> _hesaplar = [];
  bool _yukleniyor = false;

  // Hareket tipleri
  final List<Map<String, String>> _hareketTipleri = [
    {'value': 'giris', 'text': 'Para Girişi'},
    {'value': 'cikis', 'text': 'Para Çıkışı'},
    {'value': 'transfer_giden', 'text': 'Transfer (Başka Hesaba)'},
  ];

  // Kategoriler
  final List<Map<String, String>> _kategoriler = [
    {'value': 'fatura_odeme', 'text': 'Fatura Ödemesi'},
    {'value': 'nakit_giris', 'text': 'Nakit Girişi'},
    {'value': 'bank_transfer', 'text': 'Banka Transferi'},
    {'value': 'operasyonel', 'text': 'Operasyonel'},
    {'value': 'diger', 'text': 'Diğer'},
  ];

  // Para birimleri
  final List<String> _paraBirimleri = ['TRY', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _secilenHesapId = widget.varsayilanKasaBankaId;
    _hesaplariYukle();
  }

  Future<void> _hesaplariYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final hesaplar = await KasaBankaService.hesaplariListele();
      setState(() {
        _hesaplar = hesaplar;
        // Eğer varsayılan hesap ID'si verildiyse o hesabı seç
        if (widget.varsayilanKasaBankaId != null) {
          final varsayilanHesap = hesaplar.firstWhere(
            (h) => h.id?.toString() == widget.varsayilanKasaBankaId,
            orElse: () => hesaplar.first,
          );
          _secilenHesapId = varsayilanHesap.id?.toString();
          _secilenParaBirimi = varsayilanHesap.dovizTuru;
        }
      });
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hesaplar yüklenirken hata: $e');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _hareketKaydet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_secilenHesapId == null) {
      context.showSnackBar('Lütfen bir hesap seçin');
      return;
    }

    // Transfer işlemi kontrolü
    if (_secilenHareketTipi == 'transfer_giden' && _secilenTransferHesapId == null) {
      context.showSnackBar('Transfer için hedef hesap seçin');
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      if (_secilenHareketTipi == 'transfer_giden') {
        // Transfer işlemi
        final basarili = await _hareketService.transferYap(TransferIslemi(
          cikanHesapId: _secilenHesapId!,
          girenHesapId: _secilenTransferHesapId!,
          tutar: double.parse(_tutarController.text),
          paraBirimi: _secilenParaBirimi,
          aciklama: _aciklamaController.text.isEmpty ? null : _aciklamaController.text,
          referansNo: _referansNoController.text.isEmpty ? null : _referansNoController.text,
          islemTarihi: _secilenTarih,
        ));

        if (basarili.isNotEmpty) {
          if (!mounted) return;
          Navigator.pop(context, true);
          context.showSnackBar('Transfer başarıyla kaydedildi');
        }
      } else {
        // Normal hareket
        final hareket = KasaBankaHareket(
          id: '', // Supabase otomatik üretecek
          kasaBankaId: _secilenHesapId!,
          hareketTipi: _secilenHareketTipi,
          tutar: double.parse(_tutarController.text),
          paraBirimi: _secilenParaBirimi,
          aciklama: _aciklamaController.text.isEmpty ? null : _aciklamaController.text,
          kategori: _secilenKategori,
          referansNo: _referansNoController.text.isEmpty ? null : _referansNoController.text,
          islemTarihi: _secilenTarih,
          olusturmaTarihi: DateTime.now(),
          olusturanKullanici: Supabase.instance.client.auth.currentUser?.id ?? 'bilinmeyen'
        );

        final eklenenHareket = await _hareketService.hareketEkle(hareket);
        if (eklenenHareket != null) {
          if (!mounted) return;
          Navigator.pop(context, true);
          context.showSnackBar('Hareket başarıyla kaydedildi');
        }
      }
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Hareket'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _yukleniyor ? null : _hareketKaydet,
            child: _yukleniyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'KAYDET',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hesap Seçimi
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hesap Bilgileri',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            DropdownButtonFormField<String>(
                              initialValue: _secilenHesapId,
                              decoration: const InputDecoration(
                                labelText: 'Kasa/Banka Hesabı',
                                border: OutlineInputBorder(),
                              ),
                              items: _hesaplar.map((hesap) => DropdownMenuItem<String>(
                                value: hesap.id?.toString(),
                                child: Text('${hesap.ad} (${hesap.formattedBakiye})'),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _secilenHesapId = value;
                                  // Seçilen hesabın para birimini ayarla
                                  if (value != null) {
                                    final hesap = _hesaplar.firstWhere((h) => h.id?.toString() == value);
                                    _secilenParaBirimi = hesap.dovizTuru;
                                  }
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Lütfen bir hesap seçin' : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Hareket Detayları
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hareket Detayları',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            // Hareket Tipi
                            DropdownButtonFormField<String>(
                              initialValue: _secilenHareketTipi,
                              decoration: const InputDecoration(
                                labelText: 'Hareket Tipi',
                                border: OutlineInputBorder(),
                              ),
                              items: _hareketTipleri.map((tip) => DropdownMenuItem<String>(
                                value: tip['value']!,
                                child: Text(tip['text']!),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => _secilenHareketTipi = value!);
                              },
                            ),

                            const SizedBox(height: 16),

                            // Transfer için hedef hesap seçimi
                            if (_secilenHareketTipi == 'transfer_giden') ...[
                              DropdownButtonFormField<String>(
                                initialValue: _secilenTransferHesapId,
                                decoration: const InputDecoration(
                                  labelText: 'Hedef Hesap',
                                  border: OutlineInputBorder(),
                                ),
                                items: _hesaplar
                                    .where((hesap) => hesap.id?.toString() != _secilenHesapId)
                                    .map((hesap) => DropdownMenuItem<String>(
                                          value: hesap.id?.toString(),
                                          child: Text('${hesap.ad} (${hesap.formattedBakiye})'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _secilenTransferHesapId = value);
                                },
                                validator: (value) {
                                  if (_secilenHareketTipi == 'transfer_giden' && value == null) {
                                    return 'Lütfen hedef hesap seçin';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Tutar
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _tutarController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tutar',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Lütfen tutar girin';
                                      }
                                      final tutar = double.tryParse(value);
                                      if (tutar == null || tutar <= 0) {
                                        return 'Geçerli bir tutar girin';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _secilenParaBirimi,
                                    decoration: const InputDecoration(
                                      labelText: 'Para Birimi',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _paraBirimleri.map((pb) => DropdownMenuItem<String>(
                                      value: pb,
                                      child: Text(pb),
                                    )).toList(),
                                    onChanged: (value) {
                                      setState(() => _secilenParaBirimi = value!);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Kategori
                            if (_secilenHareketTipi != 'transfer_giden') ...[
                              DropdownButtonFormField<String>(
                                initialValue: _secilenKategori,
                                decoration: const InputDecoration(
                                  labelText: 'Kategori',
                                  border: OutlineInputBorder(),
                                ),
                                items: _kategoriler.map((kat) => DropdownMenuItem<String>(
                                  value: kat['value']!,
                                  child: Text(kat['text']!),
                                )).toList(),
                                onChanged: (value) {
                                  setState(() => _secilenKategori = value);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Referans No
                            TextFormField(
                              controller: _referansNoController,
                              decoration: const InputDecoration(
                                labelText: 'Referans No (Opsiyonel)',
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // İşlem Tarihi
                            InkWell(
                              onTap: () async {
                                final tarih = await showDatePicker(
                                  context: context,
                                  initialDate: _secilenTarih,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (tarih != null) {
                                  if (!context.mounted) return;
                                  final saat = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_secilenTarih),
                                  );
                                  if (saat != null) {
                                    setState(() {
                                      _secilenTarih = DateTime(
                                        tarih.year,
                                        tarih.month,
                                        tarih.day,
                                        saat.hour,
                                        saat.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'İşlem Tarihi',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_secilenTarih.day.toString().padLeft(2, '0')}.'
                                  '${_secilenTarih.month.toString().padLeft(2, '0')}.'
                                  '${_secilenTarih.year} '
                                  '${_secilenTarih.hour.toString().padLeft(2, '0')}:'
                                  '${_secilenTarih.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Açıklama
                            TextFormField(
                              controller: _aciklamaController,
                              decoration: const InputDecoration(
                                labelText: 'Açıklama (Opsiyonel)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _yukleniyor ? null : _hareketKaydet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _yukleniyor
                            ? const CircularProgressIndicator()
                            : const Text(
                                'HAREKET KAYDET',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tutarController.dispose();
    _aciklamaController.dispose();
    _referansNoController.dispose();
    super.dispose();
  }
}
