// ignore_for_file: invalid_use_of_protected_member
part of 'fatura_detay_page.dart';

/// Fatura detay - widget builder metotlari
extension _WidgetExt on _FaturaDetayPageState {
  Widget _buildDurumKarti() {
    Color durumRengi;
    IconData durumIkonu;
    
    switch (_fatura.durum) {
      case 'taslak':
        durumRengi = Colors.orange;
        durumIkonu = Icons.edit;
        break;
      case 'onaylandi':
        durumRengi = Colors.green;
        durumIkonu = Icons.check_circle;
        break;
      case 'gonderildi':
        durumRengi = Colors.blue;
        durumIkonu = Icons.send;
        break;
      case 'iptal':
        durumRengi = Colors.red;
        durumIkonu = Icons.cancel;
        break;
      default:
        durumRengi = Colors.grey;
        durumIkonu = Icons.help;
    }

    return Card(
      color: durumRengi.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(durumIkonu, color: durumRengi, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fatura Durumu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _getDurumMetin(_fatura.durum),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: durumRengi,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getFaturaTuruColor(_fatura.faturaTuru),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getFaturaTuruMetin(_fatura.faturaTuru),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            
            _buildBilgiSatiri('Fatura No', _fatura.faturaNo),
            _buildBilgiSatiri('Fatura Tarihi', _dateFormat.format(_fatura.faturaTarihi)),
            if (_fatura.vadeTarihi != null)
              _buildBilgiSatiri('Vade Tarihi', _dateFormat.format(_fatura.vadeTarihi!)),
            _buildBilgiSatiri('Kur', '${_fatura.kur} (${_fatura.kurOrani})'),
            if (_fatura.aciklama != null && _fatura.aciklama!.isNotEmpty)
              _buildBilgiSatiri('Açıklama', _fatura.aciklama!),
            _buildBilgiSatiri('Oluşturma Tarihi', _dateTimeFormat.format(_fatura.olusturmaTarihi)),
            _buildBilgiSatiri('Oluşturan', _fatura.olusturanKullanici),
          ],
        ),
      ),
    );
  }

  Widget _buildMusteriTedarikciKarti() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fatura.faturaTuru == 'alis' ? 'Tedarikçi Bilgileri' : 'Müşteri Bilgileri',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildBilgiSatiri('Fatura Adresi', _fatura.faturaAdres),
            if (_fatura.vergiDairesi != null && _fatura.vergiDairesi!.isNotEmpty)
              _buildBilgiSatiri('Vergi Dairesi', _fatura.vergiDairesi!),
            if (_fatura.vergiNo != null && _fatura.vergiNo!.isNotEmpty)
              _buildBilgiSatiri('Vergi/TC No', _fatura.vergiNo!),
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
            const Text(
              'Fatura Kalemleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_yukleniyor)
              const LoadingWidget()
            else if (_faturaKalemleri.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Fatura kalemi bulunamadı',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Sıra')),
                    DataColumn(label: Text('Ürün Kodu')),
                    DataColumn(label: Text('Ürün Adı')),
                    DataColumn(label: Text('Miktar')),
                    DataColumn(label: Text('Birim')),
                    DataColumn(label: Text('Birim Fiyat')),
                    DataColumn(label: Text('KDV %')),
                    DataColumn(label: Text('KDV Tutarı')),
                    DataColumn(label: Text('Toplam')),
                  ],
                  rows: _faturaKalemleri.asMap().entries.map((entry) {
                    final index = entry.key;
                    final kalem = entry.value;
                    
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(kalem.urunKodu ?? '-')),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  kalem.urunAdi,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (kalem.aciklama != null && kalem.aciklama!.isNotEmpty)
                                  Text(
                                    kalem.aciklama!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(kalem.miktar.toString())),
                        DataCell(Text(kalem.birim)),
                        DataCell(Text(_currencyFormat.format(kalem.birimFiyat))),
                        DataCell(Text('${kalem.kdvOrani}%')),
                        DataCell(Text(_currencyFormat.format(kalem.kdvTutar))),
                        DataCell(
                          Text(
                            _currencyFormat.format(kalem.satirTutar),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutarBilgileriKarti() {
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
                  _currencyFormat.format(_fatura.araToplamTutar),
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
                  _currencyFormat.format(_fatura.kdvTutari),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(thickness: 2),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GENEL TOPLAM:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(_fatura.toplamTutar),
                  style: const TextStyle(
                    fontSize: 24,
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

  Widget _buildOdemeBilgileriKarti() {
    final kalanBorc = _fatura.toplamTutar - _fatura.odenenTutar;
    
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
                  'Ödeme Bilgileri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (kalanBorc > 0 && _fatura.durum != 'iptal')
                  ElevatedButton.icon(
                    onPressed: _odemeEkle,
                    icon: const Icon(Icons.payment),
                    label: const Text('Ödeme Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ödeme Durumu:', style: TextStyle(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getOdemeDurumRengi(_fatura.odemeDurumu).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getOdemeDurumRengi(_fatura.odemeDurumu)),
                  ),
                  child: Text(
                    _getOdemeDurumMetin(_fatura.odemeDurumu),
                    style: TextStyle(
                      color: _getOdemeDurumRengi(_fatura.odemeDurumu),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ödenen Tutar:', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(_fatura.odenenTutar),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kalan Borç:', style: TextStyle(fontSize: 16)),
                Text(
                  _currencyFormat.format(kalanBorc),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kalanBorc > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiSatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$baslik:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
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

  String _getDurumMetin(String durum) {
    switch (durum) {
      case 'taslak':
        return 'Taslak';
      case 'onaylandi':
        return 'Onaylandı';
      case 'gonderildi':
        return 'Gönderildi';
      case 'iptal':
        return 'İptal';
      default:
        return durum;
    }
  }

  String _getFaturaTuruMetin(String tur) {
    switch (tur) {
      case 'satis':
        return 'Satış Faturası';
      case 'alis':
        return 'Alış Faturası';
      case 'iade':
        return 'İade Faturası';
      case 'proforma':
        return 'Proforma Fatura';
      default:
        return tur;
    }
  }

  Color _getFaturaTuruColor(String tur) {
    switch (tur) {
      case 'satis':
        return Colors.green;
      case 'alis':
        return Colors.blue;
      case 'iade':
        return Colors.red;
      case 'proforma':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getOdemeDurumMetin(String durum) {
    switch (durum) {
      case 'odenmedi':
        return 'Ödenmedi';
      case 'kismi':
        return 'Kısmi Ödendi';
      case 'odendi':
        return 'Ödendi';
      default:
        return durum;
    }
  }

  Color _getOdemeDurumRengi(String durum) {
    switch (durum) {
      case 'odenmedi':
        return Colors.red;
      case 'kismi':
        return Colors.orange;
      case 'odendi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Ödeme ekleme dialog'u
class _OdemeEkleDialog extends StatefulWidget {
  final FaturaModel fatura;
  final Function(double, String) onOdemeEklendi;

  const _OdemeEkleDialog({
    required this.fatura,
    required this.onOdemeEklendi,
  });

  @override
  State<_OdemeEkleDialog> createState() => _OdemeEkleDialogState();
}

class _OdemeEkleDialogState extends State<_OdemeEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _odemeController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _referansController = TextEditingController();
  
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  bool _yukleniyor = false;
  double get _kalanBorc => widget.fatura.toplamTutar - widget.fatura.odenenTutar;
  
  // Kasa/Banka hesapları
  List<KasaBankaModel> _kasaBankaHesaplari = [];
  String? _secilenKasaBankaId;
  String _secilenParaBirimi = 'TRY';
  DateTime _secilenTarih = DateTime.now();
  bool _kasaBankaYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _kasaBankaHesaplariniYukle();
  }

  Future<void> _kasaBankaHesaplariniYukle() async {
    setState(() {
      _kasaBankaYukleniyor = true;
    });

    try {
      final hesaplar = await KasaBankaService.hesaplariListele(
        aktif: true,
        limit: 100,
      );
      setState(() {
        _kasaBankaHesaplari = hesaplar;
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kasa/Banka hesapları yüklenirken hata: $e');
      }
    } finally {
      setState(() {
        _kasaBankaYukleniyor = false;
      });
    }
  }

  @override
  void dispose() {
    _odemeController.dispose();
    _aciklamaController.dispose();
    _referansController.dispose();
    super.dispose();
  }

  Future<void> _odemeKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      final odemeTutari = double.parse(_odemeController.text);
      final yeniToplamOdeme = widget.fatura.odenenTutar + odemeTutari;
      
      String yeniOdemeDurumu;
      if (yeniToplamOdeme >= widget.fatura.toplamTutar) {
        yeniOdemeDurumu = 'odendi';
      } else if (yeniToplamOdeme > 0) {
        yeniOdemeDurumu = 'kismi';
      } else {
        yeniOdemeDurumu = 'odenmedi';
      }

      await FaturaService.odemeEkle(
        widget.fatura.faturaId!,
        odemeTutari,
        _aciklamaController.text.isEmpty ? null : _aciklamaController.text,
        kasaBankaId: _secilenKasaBankaId,
        paraBirimi: _secilenParaBirimi,
        referansNo: _referansController.text.isEmpty ? null : _referansController.text,
        islemTarihi: _secilenTarih,
      );

      widget.onOdemeEklendi(yeniToplamOdeme, yeniOdemeDurumu);

      if (mounted) {
        context.showSuccessSnackBar('Ödeme başarıyla eklendi ve kasa/banka hareketine kaydedildi');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Ödeme eklenirken hata: $e');
      }
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ödeme Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kalan borç bilgisi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kalan Borç',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(_kalanBorc),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kasa/Banka hesabı seçimi
              DropdownButtonFormField<String>(
                initialValue: _secilenKasaBankaId,
                decoration: const InputDecoration(
                  labelText: 'Kasa/Banka Hesabı *',
                  border: OutlineInputBorder(),
                ),
                hint: _kasaBankaYukleniyor 
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Yükleniyor...'),
                        ],
                      )
                    : const Text('Hesap seçin'),
                items: _kasaBankaHesaplari.map((hesap) {
                  return DropdownMenuItem<String>(
                    value: hesap.id?.toString(),
                    child: Text('${hesap.ad} (${hesap.dovizTuru})'),
                  );
                }).toList(),
                onChanged: (hesapId) {
                  setState(() {
                    _secilenKasaBankaId = hesapId;
                    if (hesapId != null) {
                      final hesap = _kasaBankaHesaplari.firstWhere((h) => h.id?.toString() == hesapId);
                      _secilenParaBirimi = hesap.dovizTuru;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kasa/Banka hesabı seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Ödeme tutarı
              TextFormField(
                controller: _odemeController,
                decoration: InputDecoration(
                  labelText: 'Ödeme Tutarı *',
                  border: const OutlineInputBorder(),
                  suffixText: _getParaBirimiSymbol(_secilenParaBirimi),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ödeme tutarı gerekli';
                  }
                  final tutar = double.tryParse(value);
                  if (tutar == null || tutar <= 0) {
                    return 'Geçerli bir tutar girin';
                  }
                  if (tutar > _kalanBorc) {
                    return 'Ödeme tutarı kalan borçtan fazla olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // İşlem tarihi
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'İşlem Tarihi',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final tarih = await showDatePicker(
                        context: context,
                        initialDate: _secilenTarih,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (tarih != null) {
                        setState(() {
                          _secilenTarih = tarih;
                        });
                      }
                    },
                  ),
                ),
                controller: TextEditingController(
                  text: DateFormat('dd.MM.yyyy').format(_secilenTarih),
                ),
              ),
              const SizedBox(height: 16),

              // Referans No
              TextFormField(
                controller: _referansController,
                decoration: const InputDecoration(
                  labelText: 'Referans No',
                  border: OutlineInputBorder(),
                  hintText: 'Opsiyonel',
                ),
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
      ),
      actions: [
        TextButton(
          onPressed: _yukleniyor ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _yukleniyor ? null : _odemeKaydet,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _yukleniyor
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Ödeme Ekle'),
        ),
      ],
    );
  }

  String _getParaBirimiSymbol(String paraBirimi) {
    switch (paraBirimi) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return paraBirimi;
    }
  }
}