import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:flutter/services.dart';
import 'package:uretim_takip/services/kasa_banka_service.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';

class KasaBankaEklePage extends StatefulWidget {
  final KasaBankaModel? kasaBanka; // Düzenleme için

  const KasaBankaEklePage({
    super.key,
    this.kasaBanka,
  });

  @override
  State<KasaBankaEklePage> createState() => _KasaBankaEklePageState();
}

class _KasaBankaEklePageState extends State<KasaBankaEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _kasaBankaService = KasaBankaService();
  
  // Controllers
  final _adController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _hesapNoController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankaAdiController = TextEditingController();
  final _subeKoduController = TextEditingController();
  final _subeAdiController = TextEditingController();
  final _baslangicBakiyeController = TextEditingController();
  
  String _tip = 'KASA';
  String _durumu = 'AKTIF';
  String _dovizTuru = 'TRY';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kasaBanka != null) {
      _loadKasaBankaData();
    }
  }

  void _loadKasaBankaData() {
    final kb = widget.kasaBanka!;
    _adController.text = kb.ad;
    _aciklamaController.text = kb.aciklama ?? '';
    _hesapNoController.text = kb.hesapNo ?? '';
    _ibanController.text = kb.iban ?? '';
    _bankaAdiController.text = kb.bankaAdi ?? '';
    _subeKoduController.text = kb.subeKodu ?? '';
    _subeAdiController.text = kb.subeAdi ?? '';
    _baslangicBakiyeController.text = kb.bakiye.toString();
    _tip = kb.tip;
    _durumu = kb.durumu;
    _dovizTuru = kb.dovizTuru;
  }

  @override
  void dispose() {
    _adController.dispose();
    _aciklamaController.dispose();
    _hesapNoController.dispose();
    _ibanController.dispose();
    _bankaAdiController.dispose();
    _subeKoduController.dispose();
    _subeAdiController.dispose();
    _baslangicBakiyeController.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final kasaBanka = KasaBankaModel(
        id: widget.kasaBanka?.id,
        ad: _adController.text.trim(),
        tip: _tip,
        aciklama: _aciklamaController.text.trim().isNotEmpty 
            ? _aciklamaController.text.trim() 
            : null,
        hesapNo: _hesapNoController.text.trim().isNotEmpty 
            ? _hesapNoController.text.trim() 
            : null,
        iban: _ibanController.text.trim().isNotEmpty 
            ? _ibanController.text.trim() 
            : null,
        bankaAdi: _bankaAdiController.text.trim().isNotEmpty 
            ? _bankaAdiController.text.trim() 
            : null,
        subeKodu: _subeKoduController.text.trim().isNotEmpty 
            ? _subeKoduController.text.trim() 
            : null,
        subeAdi: _subeAdiController.text.trim().isNotEmpty 
            ? _subeAdiController.text.trim() 
            : null,
        bakiye: double.tryParse(_baslangicBakiyeController.text) ?? 0.0,
        dovizTuru: _dovizTuru,
        durumu: _durumu,
        olusturmaTarihi: widget.kasaBanka?.olusturmaTarihi ?? DateTime.now(),
        guncellenmeTarihi: DateTime.now(),
      );

      if (widget.kasaBanka == null) {
        await _kasaBankaService.kasaBankaEkle(kasaBanka);
        if (mounted) {
          context.showSuccessSnackBar('Kasa/Banka hesabı başarıyla eklendi');
        }
      } else {
        await _kasaBankaService.kasaBankaGuncelle(kasaBanka);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kasa/Banka hesabı başarıyla güncellendi'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kasaBanka == null ? 'Kasa/Banka Ekle' : 'Kasa/Banka Düzenle'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _kaydet,
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Genel Bilgiler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tip
                      DropdownButtonFormField<String>(
                        initialValue: _tip,
                        decoration: const InputDecoration(
                          labelText: 'Tip',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'KASA', child: Text('Kasa')),
                          DropdownMenuItem(value: 'BANKA', child: Text('Banka')),
                          DropdownMenuItem(value: 'KREDI_KARTI', child: Text('Kredi Kartı')),
                          DropdownMenuItem(value: 'CEK_HESABI', child: Text('Çek Hesabı')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tip = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tip seçiniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Ad
                      TextFormField(
                        controller: _adController,
                        decoration: const InputDecoration(
                          labelText: 'Hesap Adı',
                          border: OutlineInputBorder(),
                          hintText: 'Örn: Nakit Kasa, Ziraat Bankası, İş Bankası Vadesiz',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Hesap adı gereklidir';
                          }
                          if (value.trim().length < 2) {
                            return 'Hesap adı en az 2 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Açıklama
                      TextFormField(
                        controller: _aciklamaController,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama (Opsiyonel)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Banka Bilgileri
              if (_tip == 'BANKA' || _tip == 'KREDI_KARTI' || _tip == 'CEK_HESABI')
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
                        
                        // Banka Adı
                        TextFormField(
                          controller: _bankaAdiController,
                          decoration: const InputDecoration(
                            labelText: 'Banka Adı',
                            border: OutlineInputBorder(),
                            hintText: 'Örn: T.C. Ziraat Bankası A.Ş.',
                          ),
                          validator: _tip == 'BANKA' || _tip == 'KREDI_KARTI' || _tip == 'CEK_HESABI'
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Banka adı gereklidir';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // Şube Kodu
                            Expanded(
                              child: TextFormField(
                                controller: _subeKoduController,
                                decoration: const InputDecoration(
                                  labelText: 'Şube Kodu',
                                  border: OutlineInputBorder(),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Şube Adı
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _subeAdiController,
                                decoration: const InputDecoration(
                                  labelText: 'Şube Adı',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Hesap No
                        TextFormField(
                          controller: _hesapNoController,
                          decoration: const InputDecoration(
                            labelText: 'Hesap Numarası',
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // IBAN
                        TextFormField(
                          controller: _ibanController,
                          decoration: const InputDecoration(
                            labelText: 'IBAN',
                            border: OutlineInputBorder(),
                            hintText: 'TR12 3456 7890 1234 5678 9012 34',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              String text = newValue.text.replaceAll(' ', '').toUpperCase();
                              if (text.length > 26) text = text.substring(0, 26);
                              
                              // IBAN formatı: TR12 3456 7890 1234 5678 9012 34
                              String formatted = '';
                              for (int i = 0; i < text.length; i++) {
                                if (i > 0 && i % 4 == 0) {
                                  formatted += ' ';
                                }
                                formatted += text[i];
                              }
                              
                              return TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }),
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final String iban = value.replaceAll(' ', '');
                              if (!iban.startsWith('TR') || iban.length != 26) {
                                return 'Geçerli bir Türk IBAN giriniz (26 karakter)';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      
                      Row(
                        children: [
                          // Başlangıç Bakiyesi
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _baslangicBakiyeController,
                              decoration: const InputDecoration(
                                labelText: 'Başlangıç Bakiyesi',
                                border: OutlineInputBorder(),
                                prefixText: '₺ ',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Başlangıç bakiyesi gereklidir';
                                }
                                final double? amount = double.tryParse(value.trim());
                                if (amount == null) {
                                  return 'Geçerli bir tutar giriniz';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Döviz Türü
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _dovizTuru,
                              decoration: const InputDecoration(
                                labelText: 'Döviz',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _dovizTuru = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Durum
                      DropdownButtonFormField<String>(
                        initialValue: _durumu,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'AKTIF', child: Text('Aktif')),
                          DropdownMenuItem(value: 'PASIF', child: Text('Pasif')),
                          DropdownMenuItem(value: 'DONUK', child: Text('Dondurulmuş')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _durumu = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _kaydet,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(widget.kasaBanka == null ? 'Hesap Ekle' : 'Güncelle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
