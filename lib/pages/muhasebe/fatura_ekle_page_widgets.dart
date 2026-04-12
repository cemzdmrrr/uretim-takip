// ignore_for_file: invalid_use_of_protected_member
part of 'fatura_ekle_page.dart';

/// Fatura ekle - widget builder metotlari
extension _WidgetExt on _FaturaEklePageState {
  Widget _buildTemelBilgilerKarti() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temel Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Fatura No
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _faturaNoController,
                    decoration: const InputDecoration(
                      labelText: 'Fatura No *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Fatura No gerekli';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Fatura Türü
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _secilenFaturaTuru,
                    decoration: const InputDecoration(
                      labelText: 'Fatura Türü *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'satis', child: Text('Satış Faturası')),
                      DropdownMenuItem(value: 'alis', child: Text('Alış Faturası')),
                      DropdownMenuItem(value: 'iade', child: Text('İade Faturası')),
                      DropdownMenuItem(value: 'proforma', child: Text('Proforma Fatura')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _secilenFaturaTuru = value!;
                        _secilenTedarikci = null;
                      });
                      _otomatikFaturaNoOlustur();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Durum
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _secilenDurum,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'taslak', child: Text('Taslak')),
                      DropdownMenuItem(value: 'onaylandi', child: Text('Onaylandı')),
                      DropdownMenuItem(value: 'gonderildi', child: Text('Gönderildi')),
                      DropdownMenuItem(value: 'iptal', child: Text('İptal')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _secilenDurum = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Fatura Tarihi
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final tarih = await showDatePicker(
                        context: context,
                        initialDate: _faturaTarihi,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (tarih != null) {
                        setState(() {
                          _faturaTarihi = tarih;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fatura Tarihi *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(_dateFormat.format(_faturaTarihi)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Vade Tarihi
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final tarih = await showDatePicker(
                        context: context,
                        initialDate: _vadeTarihi ?? _faturaTarihi.add(const Duration(days: 30)),
                        firstDate: _faturaTarihi,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      setState(() {
                        _vadeTarihi = tarih;
                      });
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Vade Tarihi',
                        border: const OutlineInputBorder(),
                        suffixIcon: _vadeTarihi != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _vadeTarihi = null;
                                  });
                                },
                              )
                            : const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _vadeTarihi != null 
                            ? _dateFormat.format(_vadeTarihi!)
                            : 'Seçiniz',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Kur
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _secilenKur,
                          decoration: const InputDecoration(
                            labelText: 'Kur',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _secilenKur = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_secilenKur != 'TRY')
                        Expanded(
                          child: TextFormField(
                            controller: _kurOraniController,
                            decoration: const InputDecoration(
                              labelText: 'Kur Oranı',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Açıklama
            TextFormField(
              controller: _aciklamaController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusteritedarikciKarti() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _secilenFaturaTuru == 'alis' ? 'Tedarikçi Bilgileri' : 'Nakit Satış',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tedarikçi seçimi (sadece alış faturası için)
            if (_secilenFaturaTuru == 'alis')
              DropdownButtonFormField<TedarikciModel>(
                initialValue: _secilenTedarikci,
                decoration: const InputDecoration(
                  labelText: 'Tedarikçi Seçin *',
                  border: OutlineInputBorder(),
                ),
                items: _tedarikciler.map((tedarikci) {
                  return DropdownMenuItem(
                    value: tedarikci,
                    child: Text('${tedarikci.ad} ${tedarikci.soyad ?? ''} - ${tedarikci.sirket ?? ''}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _secilenTedarikci = value;
                    if (value != null) {
                      _faturaAdresController.text = ''; // Adres alanı kaldırıldı
                      _vergiDairesiController.text = ''; // Vergi dairesi alanı kaldırıldı
                      _vergiNoController.text = value.vergiNo ?? '';
                    }
                  });
                },
                validator: (value) {
                  if (_secilenFaturaTuru == 'alis' && value == null) {
                    return 'Alış faturası için tedarikçi seçimi zorunlu';
                  }
                  return null;
                },
              ),
            
            const SizedBox(height: 16),
            
            // Adres
            TextFormField(
              controller: _faturaAdresController,
              decoration: const InputDecoration(
                labelText: 'Fatura Adresi *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Fatura adresi gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Vergi Dairesi
                Expanded(
                  child: TextFormField(
                    controller: _vergiDairesiController,
                    decoration: const InputDecoration(
                      labelText: 'Vergi Dairesi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Vergi No
                Expanded(
                  child: TextFormField(
                    controller: _vergiNoController,
                    decoration: const InputDecoration(
                      labelText: 'Vergi/TC No',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaturaKalemleriKarti() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fatura Kalemleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _faturaKalemiEkle,
                  icon: const Icon(Icons.add),
                  label: const Text('Kalem Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_faturaKalemleri.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Henüz kalem eklenmedi',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fatura kalemi eklemek için "Kalem Ekle" butonuna tıklayın',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faturaKalemleri.length,
                itemBuilder: (context, index) {
                  final kalem = _faturaKalemleri[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(kalem.urunAdi),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (kalem.urunKodu != null && kalem.urunKodu!.isNotEmpty)
                            Text('Kod: ${kalem.urunKodu}'),
                          Text('${kalem.miktar} ${kalem.birim} x ${_currencyFormat.format(kalem.birimFiyat)}'),
                          Text('KDV: %${kalem.kdvOrani}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currencyFormat.format(kalem.miktar * kalem.birimFiyat * (1 + kalem.kdvOrani / 100)),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'duzenle') {
                                _faturaKalemiDuzenle(index);
                              } else if (value == 'sil') {
                                _faturaKalemiSil(index);
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
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToplamTutarlarKarti() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tutar Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ara Toplam:', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(_araToplamTutar),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('KDV Tutarı:', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(_kdvTutari),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GENEL TOPLAM:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(_toplamTutar),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// Fatura kalemi ekleme/düzenleme dialog'u
class _FaturaKalemiEkleDialog extends StatefulWidget {
  final Function(FaturaKalemiModel) onKalemEklendi;
  final FaturaKalemiModel? duzenlenecekKalem;

  const _FaturaKalemiEkleDialog({
    required this.onKalemEklendi,
    this.duzenlenecekKalem,
  });

  @override
  State<_FaturaKalemiEkleDialog> createState() => _FaturaKalemiEkleDialogState();
}

class _FaturaKalemiEkleDialogState extends State<_FaturaKalemiEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urunKoduController = TextEditingController();
  final _urunAdiController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _miktarController = TextEditingController(text: '1');
  final _birimFiyatController = TextEditingController(text: '0');
  final _kdvOraniController = TextEditingController(text: '20');
  
  String _secilenBirim = 'adet';
  
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    
    if (widget.duzenlenecekKalem != null) {
      final kalem = widget.duzenlenecekKalem!;
      _urunKoduController.text = kalem.urunKodu ?? '';
      _urunAdiController.text = kalem.urunAdi;
      _aciklamaController.text = kalem.aciklama ?? '';
      _miktarController.text = kalem.miktar.toString();
      _secilenBirim = kalem.birim;
      _birimFiyatController.text = kalem.birimFiyat.toString();
      _kdvOraniController.text = kalem.kdvOrani.toString();
    }
  }

  @override
  void dispose() {
    _urunKoduController.dispose();
    _urunAdiController.dispose();
    _aciklamaController.dispose();
    _miktarController.dispose();
    _birimFiyatController.dispose();
    _kdvOraniController.dispose();
    super.dispose();
  }

  void _kalemKaydet() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final kalem = FaturaKalemiModel(
      kalemId: widget.duzenlenecekKalem?.kalemId,
      faturaId: 0, // Fatura kaydedilirken atanacak
      urunKodu: _urunKoduController.text.isEmpty ? null : _urunKoduController.text,
      urunAdi: _urunAdiController.text,
      aciklama: _aciklamaController.text.isEmpty ? null : _aciklamaController.text,
      miktar: double.parse(_miktarController.text),
      birim: _secilenBirim,
      birimFiyat: double.parse(_birimFiyatController.text),
      kdvOrani: double.parse(_kdvOraniController.text),
      kdvTutar: 0, // Otomatik hesaplanacak
      satirTutar: 0, // Otomatik hesaplanacak
      siraNo: 1, // Otomatik atanacak
      olusturmaTarihi: DateTime.now(),
    );

    widget.onKalemEklendi(kalem);
    Navigator.pop(context);
  }

  double _hesaplaToplamTutar() {
    try {
      final miktar = double.parse(_miktarController.text);
      final birimFiyat = double.parse(_birimFiyatController.text);
      final kdvOrani = double.parse(_kdvOraniController.text);
      
      final araToplam = miktar * birimFiyat;
      final kdvTutari = araToplam * kdvOrani / 100;
      
      return araToplam + kdvTutari;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.duzenlenecekKalem != null ? 'Kalemi Düzenle' : 'Yeni Kalem Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ürün kodu
              TextFormField(
                controller: _urunKoduController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Kodu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Ürün adı
              TextFormField(
                controller: _urunAdiController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ürün adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Açıklama
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  // Miktar
                  Expanded(
                    child: TextFormField(
                      controller: _miktarController,
                      decoration: const InputDecoration(
                        labelText: 'Miktar *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Miktar gerekli';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Geçerli miktar girin';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Birim
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _secilenBirim,
                      decoration: const InputDecoration(
                        labelText: 'Birim',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'adet', child: Text('Adet')),
                        DropdownMenuItem(value: 'kg', child: Text('Kg')),
                        DropdownMenuItem(value: 'metre', child: Text('Metre')),
                        DropdownMenuItem(value: 'litre', child: Text('Litre')),
                        DropdownMenuItem(value: 'takım', child: Text('Takım')),
                        DropdownMenuItem(value: 'top', child: Text('Top')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _secilenBirim = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  // Birim fiyat
                  Expanded(
                    child: TextFormField(
                      controller: _birimFiyatController,
                      decoration: const InputDecoration(
                        labelText: 'Birim Fiyat *',
                        border: OutlineInputBorder(),
                        suffixText: '₺',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Birim fiyat gerekli';
                        }
                        if (double.tryParse(value) == null || double.parse(value) < 0) {
                          return 'Geçerli fiyat girin';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // KDV oranı
                  Expanded(
                    child: TextFormField(
                      controller: _kdvOraniController,
                      decoration: const InputDecoration(
                        labelText: 'KDV Oranı *',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'KDV oranı gerekli';
                        }
                        if (double.tryParse(value) == null || double.parse(value) < 0) {
                          return 'Geçerli oran girin';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Toplam tutar gösterimi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Toplam Tutar (KDV Dahil)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(_hesaplaToplamTutar()),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _kalemKaydet,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.duzenlenecekKalem != null ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }
}