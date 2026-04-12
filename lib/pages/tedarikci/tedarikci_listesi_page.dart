import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';
import 'package:uretim_takip/services/tedarikci_service.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_ekle_page.dart';
import 'package:uretim_takip/pages/tedarikci/tedarikci_detay_page.dart';

class TedarikciListesiPage extends StatefulWidget {
  const TedarikciListesiPage({Key? key}) : super(key: key);

  @override
  State<TedarikciListesiPage> createState() => _TedarikciListesiPageState();
}

class _TedarikciListesiPageState extends State<TedarikciListesiPage> {
  final TextEditingController _aramaController = TextEditingController();
  List<TedarikciModel> _tedarikciler = [];
  bool _yukleniyor = false;
  String? _secilenTur;
  String? _secilenDurum;
  String? _secilenFaaliyet;
  int _toplamKayit = 0;
  int _mevcutSayfa = 0;
  final int _sayfaBasiKayit = 20;

  // Tedarikçi türleri
  final List<Map<String, String>> _tedarikciTurleri = [
    {'value': '', 'label': 'Tüm Türler'},
    {'value': 'iplik', 'label': 'İplik Tedarikçisi'},
    {'value': 'fason', 'label': 'Fason İşçilik'},
    {'value': 'aksesuar', 'label': 'Aksesuar Tedarikçisi'},
    {'value': 'diger', 'label': 'Diğer'},
  ];

  // Durumlar
  final List<Map<String, String>> _durumlar = [
    {'value': '', 'label': 'Tüm Durumlar'},
    {'value': 'aktif', 'label': 'Aktif'},
    {'value': 'pasif', 'label': 'Pasif'},
    {'value': 'askida', 'label': 'Askıda'},
  ];

  // Fason faaliyetleri
  final List<Map<String, String>> _fasonFaaliyetleri = [
    {'value': '', 'label': 'Tüm Faaliyetler'},
    {'value': 'orgu', 'label': 'Örgü'},
    {'value': 'konfeksiyon', 'label': 'Konfeksiyon'},
    {'value': 'utu', 'label': 'Ütü'},
  ];

  @override
  void initState() {
    super.initState();
    _tedarikcileriYukle();
  }

  Future<void> _tedarikcileriYukle({bool yeniArama = false}) async {
    if (yeniArama) {
      _mevcutSayfa = 0;
      _tedarikciler.clear();
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      final aramaKelimesi = _aramaController.text.trim();
      
      // Toplam kayıt sayısını al
      if (yeniArama || _mevcutSayfa == 0) {
        _toplamKayit = await TedarikciService.tedarikciSayisiGetir(
          aramaKelimesi: aramaKelimesi.isEmpty ? null : aramaKelimesi,
          tedarikciTipi: _secilenTur?.isEmpty == true ? null : _secilenTur,
          durum: _secilenDurum?.isEmpty == true ? null : _secilenDurum,
          faaliyet: _secilenFaaliyet?.isEmpty == true ? null : _secilenFaaliyet,
        );
      }

      final yeniTedarikciler = await TedarikciService.tedarikcileriListele(
        aramaKelimesi: aramaKelimesi.isEmpty ? null : aramaKelimesi,
        tedarikciTipi: _secilenTur?.isEmpty == true ? null : _secilenTur,
        durum: _secilenDurum?.isEmpty == true ? null : _secilenDurum,
        faaliyet: _secilenFaaliyet?.isEmpty == true ? null : _secilenFaaliyet,
        limit: _sayfaBasiKayit,
        offset: _mevcutSayfa * _sayfaBasiKayit,
      );

      setState(() {
        if (yeniArama) {
          _tedarikciler = yeniTedarikciler;
        } else {
          _tedarikciler.addAll(yeniTedarikciler);
        }
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _yukleniyor = false;
      });
      
      if (mounted) {
        context.showErrorSnackBar('Tedarikçiler yüklenirken hata oluştu: $e');
      }
    }
  }

  void _aramaYap() {
    _tedarikcileriYukle(yeniArama: true);
  }

  void _filtreTemizle() {
    setState(() {
      _aramaController.clear();
      _secilenTur = null;
      _secilenDurum = null;
      _secilenFaaliyet = null;
    });
    _tedarikcileriYukle(yeniArama: true);
  }

  void _daliAyciYukle() {
    if (_tedarikciler.length < _toplamKayit) {
      _mevcutSayfa++;
      _tedarikcileriYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tedarikçi Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _tedarikcileriYukle(yeniArama: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve filtre bölümü
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Arama çubuğu
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aramaController,
                        decoration: InputDecoration(
                          hintText: 'Tedarikçi adı ara...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _aramaController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _aramaController.clear();
                                    _aramaYap();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (_) => _aramaYap(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _aramaYap,
                      child: const Text('Ara'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Filtreler
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _secilenTur,
                        decoration: InputDecoration(
                          labelText: 'Tedarikçi Türü',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _tedarikciTurleri.map((tur) {
                          return DropdownMenuItem<String>(
                            value: tur['value']!.isEmpty ? null : tur['value'],
                            child: Text(tur['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _secilenTur = value;
                            // Fason seçilmemişse faaliyet filtresini temizle
                            if (value != 'fason') {
                              _secilenFaaliyet = null;
                            }
                          });
                          _aramaYap();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    if (_secilenTur == 'fason') ...[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _secilenFaaliyet,
                          decoration: InputDecoration(
                            labelText: 'Faaliyet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _fasonFaaliyetleri.map((faaliyet) {
                            return DropdownMenuItem<String>(
                              value: faaliyet['value']!.isEmpty ? null : faaliyet['value'],
                              child: Text(faaliyet['label']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _secilenFaaliyet = value;
                            });
                            _aramaYap();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _secilenDurum,
                        decoration: InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _durumlar.map((durum) {
                          return DropdownMenuItem<String>(
                            value: durum['value']!.isEmpty ? null : durum['value'],
                            child: Text(durum['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _secilenDurum = value;
                          });
                          _aramaYap();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    ElevatedButton(
                      onPressed: _filtreTemizle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sonuç bilgisi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              'Toplam $_toplamKayit tedarikçi bulundu (${_tedarikciler.length} tanesi gösteriliyor)',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Tedarikçi listesi
          Expanded(
            child: _yukleniyor && _tedarikciler.isEmpty
                ? const LoadingWidget()
                : _tedarikciler.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Tedarikçi bulunamadı',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Arama kriterlerinizi değiştirmeyi deneyin',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!_yukleniyor &&
                              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                              _tedarikciler.length < _toplamKayit) {
                            _daliAyciYukle();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: _tedarikciler.length + (_tedarikciler.length < _toplamKayit ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _tedarikciler.length) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: const LoadingWidget(),
                              );
                            }

                            final tedarikci = _tedarikciler[index];
                            return _tedarikciKarti(tedarikci);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TedarikciEklePage(),
            ),
          ).then((result) {
            if (result == true) {
              _tedarikcileriYukle(yeniArama: true);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _tedarikciKarti(TedarikciModel tedarikci) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tedarikci.durumRengi,
          child: Icon(
            _getTurIcon(tedarikci.tedarikciTipi),
            color: Colors.white,
          ),
        ),
        title: Text(
          tedarikci.goruntulemeAdi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tedarikci.telefon),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tedarikci.durumRengi.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tedarikci.durumRengi),
                  ),
                  child: Text(
                    tedarikci.tedarikciTipiAciklama,
                    style: TextStyle(
                      color: tedarikci.durumRengi,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (tedarikci.faaliyet != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      tedarikci.faaliyetAciklama,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tedarikci.durumRengi.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tedarikci.durumAciklama,
            style: TextStyle(
              color: tedarikci.durumRengi,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TedarikciDetayPage(tedarikciId: tedarikci.id!),
            ),
          ).then((result) {
            if (result == true) {
              _tedarikcileriYukle(yeniArama: true);
            }
          });
        },
      ),
    );
  }

  IconData _getTurIcon(String tur) {
    switch (tur) {
      case 'iplik':
        return Icons.texture;
      case 'fason':
        return Icons.work;
      case 'aksesuar':
        return Icons.widgets;
      default:
        return Icons.business;
    }
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }
}
