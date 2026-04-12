import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_ekle_page.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_detay_page.dart';

class FaturaListesiPage extends StatefulWidget {
  const FaturaListesiPage({super.key});

  @override
  State<FaturaListesiPage> createState() => _FaturaListesiPageState();
}

class _FaturaListesiPageState extends State<FaturaListesiPage> {
  final TextEditingController _aramaController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  List<FaturaModel> _faturalar = [];
  bool _yukleniyor = false;
  String _secilenFaturaTuru = '';
  String _secilenDurum = '';
  String _secilenOdemeDurumu = '';
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;

  @override
  void initState() {
    super.initState();
    // Test için hata ayıklama eklendi
    debugPrint('FaturaListesiPage: initState() çağrıldı');
    _faturalariYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _faturalariYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      final faturalar = await FaturaService.faturalariListele(
        aramaKelimesi: _aramaController.text.isEmpty ? null : _aramaController.text,
        faturaTuru: _secilenFaturaTuru.isEmpty ? null : _secilenFaturaTuru,
        durum: _secilenDurum.isEmpty ? null : _secilenDurum,
        odemeDurumu: _secilenOdemeDurumu.isEmpty ? null : _secilenOdemeDurumu,
        baslangicTarihi: _baslangicTarihi,
        bitisTarihi: _bitisTarihi,
        limit: 100,
      );

      setState(() {
        _faturalar = faturalar;
      });
    } catch (e) {
      debugPrint('Fatura yükleme hatası: $e'); // Debug için
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Faturalar yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  Future<void> _faturaEkle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaturaEklePage(),
      ),
    );

    if (result == true) {
      _faturalariYukle();
    }
  }

  Future<void> _faturaDetayGoster(FaturaModel fatura) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaturaDetayPage(fatura: fatura),
      ),
    );

    if (result == true) {
      _faturalariYukle();
    }
  }

  void _filtreleriTemizle() {
    setState(() {
      _aramaController.clear();
      _secilenFaturaTuru = '';
      _secilenDurum = '';
      _secilenOdemeDurumu = '';
      _baslangicTarihi = null;
      _bitisTarihi = null;
    });
    _faturalariYukle();
  }

  Widget _buildFiltreler() {
    return Card(
      child: ExpansionTile(
        title: const Text('Filtreler'),
        leading: const Icon(Icons.filter_list),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Arama kutusu
                TextField(
                  controller: _aramaController,
                  decoration: const InputDecoration(
                    labelText: 'Fatura No veya Açıklama Ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _faturalariYukle(),
                ),
                const SizedBox(height: 16),
                
                // Filtre satırı
                Row(
                  children: [
                    // Fatura türü
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _secilenFaturaTuru.isEmpty ? null : _secilenFaturaTuru,
                        decoration: const InputDecoration(
                          labelText: 'Fatura Türü',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tümü')),
                          DropdownMenuItem(value: 'satis', child: Text('Satış')),
                          DropdownMenuItem(value: 'alis', child: Text('Alış')),
                          DropdownMenuItem(value: 'iade', child: Text('İade')),
                          DropdownMenuItem(value: 'proforma', child: Text('Proforma')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _secilenFaturaTuru = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Durum
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _secilenDurum.isEmpty ? null : _secilenDurum,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tümü')),
                          DropdownMenuItem(value: 'taslak', child: Text('Taslak')),
                          DropdownMenuItem(value: 'onaylandi', child: Text('Onaylandı')),
                          DropdownMenuItem(value: 'gonderildi', child: Text('Gönderildi')),
                          DropdownMenuItem(value: 'iptal', child: Text('İptal')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _secilenDurum = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Ödeme durumu
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _secilenOdemeDurumu.isEmpty ? null : _secilenOdemeDurumu,
                        decoration: const InputDecoration(
                          labelText: 'Ödeme Durumu',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tümü')),
                          DropdownMenuItem(value: 'odenmedi', child: Text('Ödenmedi')),
                          DropdownMenuItem(value: 'kismi', child: Text('Kısmi Ödendi')),
                          DropdownMenuItem(value: 'odendi', child: Text('Ödendi')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _secilenOdemeDurumu = value ?? '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tarih aralığı
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final tarih = await showDatePicker(
                            context: context,
                            initialDate: _baslangicTarihi ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (tarih != null) {
                            setState(() {
                              _baslangicTarihi = tarih;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Başlangıç Tarihi',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _baslangicTarihi != null
                                ? _dateFormat.format(_baslangicTarihi!)
                                : 'Seçiniz',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final tarih = await showDatePicker(
                            context: context,
                            initialDate: _bitisTarihi ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (tarih != null) {
                            setState(() {
                              _bitisTarihi = tarih;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Bitiş Tarihi',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _bitisTarihi != null
                                ? _dateFormat.format(_bitisTarihi!)
                                : 'Seçiniz',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _faturalariYukle,
                      icon: const Icon(Icons.search),
                      label: const Text('Filtrele'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _filtreleriTemizle,
                      icon: const Icon(Icons.clear),
                      label: const Text('Temizle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaturaKarti(FaturaModel fatura) {
    Color durumRengi;
    Color odemeDurumRengi;
    
    switch (fatura.durum) {
      case 'taslak':
        durumRengi = Colors.orange;
        break;
      case 'onaylandi':
        durumRengi = Colors.green;
        break;
      case 'gonderildi':
        durumRengi = Colors.blue;
        break;
      case 'iptal':
        durumRengi = Colors.red;
        break;
      default:
        durumRengi = Colors.grey;
    }

    switch (fatura.odemeDurumu) {
      case 'odenmedi':
        odemeDurumRengi = Colors.red;
        break;
      case 'kismi':
        odemeDurumRengi = Colors.orange;
        break;
      case 'odendi':
        odemeDurumRengi = Colors.green;
        break;
      default:
        odemeDurumRengi = Colors.grey;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getFaturaTuruColor(fatura.faturaTuru),
          child: Text(
            _getFaturaTuruKisaltma(fatura.faturaTuru),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          fatura.faturaNo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateFormat.format(fatura.faturaTarihi)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: durumRengi.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: durumRengi),
                  ),
                  child: Text(
                    _getDurumMetin(fatura.durum),
                    style: TextStyle(
                      color: durumRengi,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: odemeDurumRengi.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: odemeDurumRengi),
                  ),
                  child: Text(
                    _getOdemeDurumMetin(fatura.odemeDurumu),
                    style: TextStyle(
                      color: odemeDurumRengi,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(fatura.toplamTutar),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (fatura.vadeTarihi != null)
              Text(
                'Vade: ${_dateFormat.format(fatura.vadeTarihi!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: fatura.vadeTarihi!.isBefore(DateTime.now()) && 
                         fatura.odemeDurumu != 'odendi'
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
          ],
        ),
        onTap: () => _faturaDetayGoster(fatura),
      ),
    );
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

  String _getFaturaTuruKisaltma(String tur) {
    switch (tur) {
      case 'satis':
        return 'S';
      case 'alis':
        return 'A';
      case 'iade':
        return 'İ';
      case 'proforma':
        return 'P';
      default:
        return '?';
    }
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

  String _getOdemeDurumMetin(String durum) {
    switch (durum) {
      case 'odenmedi':
        return 'Ödenmedi';
      case 'kismi':
        return 'Kısmi';
      case 'odendi':
        return 'Ödendi';
      default:
        return durum;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturalar'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _faturalariYukle,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltreler(),
          const SizedBox(height: 8),
          
          // İstatistik kartları
          if (_faturalar.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_faturalar.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'Toplam Fatura',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currencyFormat.format(
                                _faturalar.fold<double>(
                                  0,
                                  (sum, fatura) => sum + fatura.toplamTutar,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Toplam Tutar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currencyFormat.format(
                                _faturalar.fold<double>(
                                  0,
                                  (sum, fatura) => sum + (fatura.toplamTutar - fatura.odenenTutar),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text(
                              'Alacak',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Fatura listesi
          Expanded(
            child: _yukleniyor
                ? const LoadingWidget()
                : _faturalar.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Henüz fatura bulunmuyor',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Yeni fatura eklemek için + butonuna tıklayın',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _faturalar.length,
                        itemBuilder: (context, index) {
                          return _buildFaturaKarti(_faturalar[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _faturaEkle,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
