import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/models/kasa_banka_model.dart';
import 'package:uretim_takip/services/kasa_banka_service.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_detay_page.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_ekle_page.dart';

class KasaBankaListesiPage extends StatefulWidget {
  const KasaBankaListesiPage({super.key});

  @override
  State<KasaBankaListesiPage> createState() => _KasaBankaListesiPageState();
}

class _KasaBankaListesiPageState extends State<KasaBankaListesiPage> {
  List<KasaBankaModel> _filtrelenmisHesaplar = [];
  bool _yukleniyor = true;
  String _aramaKelimesi = '';
  String? _secilenHesapTuru;
  String? _secilenKur;
  bool? _secilenAktiflik;

  final TextEditingController _aramaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Sayfalama
  int _mevcutSayfa = 0;
  int _toplamSayfa = 0;
  final int _sayfaBasinaItem = 20;
  
  // İstatistikler
  Map<String, double> _toplamBakiyeler = {};
  Map<String, int> _hesapTuruDagilimi = {};

  @override
  void initState() {
    super.initState();
    _hesaplariYukle();
    _istatistikleriYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hesaplariYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      final hesaplar = await KasaBankaService.hesaplariListele(
        aramaKelimesi: _aramaKelimesi.isEmpty ? null : _aramaKelimesi,
        hesapTuru: _secilenHesapTuru,
        aktif: _secilenAktiflik,
        kur: _secilenKur,
        limit: _sayfaBasinaItem,
        offset: _mevcutSayfa * _sayfaBasinaItem,
      );

      final toplam = await KasaBankaService.hesapSayisiGetir(
        aramaKelimesi: _aramaKelimesi.isEmpty ? null : _aramaKelimesi,
        hesapTuru: _secilenHesapTuru,
        aktif: _secilenAktiflik,
        kur: _secilenKur,
      );

      setState(() {
        _filtrelenmisHesaplar = hesaplar;
        _toplamSayfa = (toplam / _sayfaBasinaItem).ceil();
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _yukleniyor = false;
      });
      _hataGoster('Hesaplar yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _istatistikleriYukle() async {
    try {
      final bakiyeler = await KasaBankaService.toplamBakiyeHesapla();
      final dagilim = await KasaBankaService.hesapTuruDagilimi();
      
      setState(() {
        _toplamBakiyeler = bakiyeler;
        _hesapTuruDagilimi = dagilim;
      });
    } catch (e) {
      // İstatistik hatası sessizce geç
    }
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _aramayiUygula() {
    setState(() {
      _aramaKelimesi = _aramaController.text;
      _mevcutSayfa = 0;
    });
    _hesaplariYukle();
  }

  void _filtreyiTemizle() {
    setState(() {
      _aramaController.clear();
      _aramaKelimesi = '';
      _secilenHesapTuru = null;
      _secilenKur = null;
      _secilenAktiflik = null;
      _mevcutSayfa = 0;
    });
    _hesaplariYukle();
  }

  void _sayfaDegistir(int yeniSayfa) {
    setState(() {
      _mevcutSayfa = yeniSayfa;
    });
    _hesaplariYukle();
  }

  Future<void> _hesapSil(KasaBankaModel hesap) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesap Sil'),
        content: Text('${hesap.hesapAdi} hesabını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
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
        await KasaBankaService.hesapSil(hesap.id!);
        _hesaplariYukle();
        _istatistikleriYukle();
        
        if (mounted) {
          context.showSuccessSnackBar('Hesap başarıyla silindi');
        }
      } catch (e) {
        _hataGoster('Hesap silinirken hata oluştu: $e');
      }
    }
  }

  Future<void> _hesapDurumDegistir(KasaBankaModel hesap) async {
    try {
      await KasaBankaService.hesapDurumDegistir(hesap.id!, !hesap.aktif);
      _hesaplariYukle();
      _istatistikleriYukle();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap ${!hesap.aktif ? 'aktif' : 'pasif'} edildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _hataGoster('Hesap durumu değiştirilirken hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa/Banka Yönetimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _hesaplariYukle();
              _istatistikleriYukle();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // İstatistik kartları
          if (_toplamBakiyeler.isNotEmpty) _buildIstatistikler(),
          
          // Arama ve filtre bölümü
          _buildAramaFiltre(),
          
          // Hesap listesi
          Expanded(
            child: _yukleniyor
                ? const LoadingWidget()
                : _filtrelenmisHesaplar.isEmpty
                    ? _buildBosListe()
                    : _buildHesapListesi(),
          ),
          
          // Sayfalama
          if (_toplamSayfa > 1) _buildSayfalama(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final sonuc = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KasaBankaEklePage(),
            ),
          );
          if (sonuc == true) {
            _hesaplariYukle();
            _istatistikleriYukle();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildIstatistikler() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Toplam bakiyeler
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Toplam Bakiye', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._toplamBakiyeler.entries.map((entry) => Text(
                          '${entry.value.toStringAsFixed(2)} ${entry.key}',
                          style: const TextStyle(fontSize: 16),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Hesap Dağılımı', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._hesapTuruDagilimi.entries.map((entry) => Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAramaFiltre() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Arama kutusu
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aramaController,
                    decoration: const InputDecoration(
                      labelText: 'Hesap adı veya banka adı ara...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _aramayiUygula(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _aramayiUygula,
                  child: const Text('Ara'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _filtreyiTemizle,
                  child: const Text('Temizle'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Filtreler
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _secilenHesapTuru,
                    decoration: const InputDecoration(
                      labelText: 'Hesap Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: ['kasa', 'banka'].map((tur) => DropdownMenuItem(
                      value: tur,
                      child: Text(tur == 'kasa' ? 'Kasa' : 'Banka'),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _secilenHesapTuru = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _secilenKur,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi',
                      border: OutlineInputBorder(),
                    ),
                    items: ['TRY', 'USD', 'EUR'].map((kur) => DropdownMenuItem(
                      value: kur,
                      child: Text(kur),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _secilenKur = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    initialValue: _secilenAktiflik,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Aktif')),
                      DropdownMenuItem(value: false, child: Text('Pasif')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _secilenAktiflik = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBosListe() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Henüz hiç kasa/banka hesabı eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHesapListesi() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _filtrelenmisHesaplar.length,
      itemBuilder: (context, index) {
        final hesap = _filtrelenmisHesaplar[index];
        return _buildHesapKarti(hesap);
      },
    );
  }

  Widget _buildHesapKarti(KasaBankaModel hesap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hesap.hesapTuruColor,
          child: Icon(
            hesap.hesapTuru == 'kasa' ? Icons.account_balance_wallet : Icons.account_balance,
            color: Colors.white,
          ),
        ),
        title: Text(
          hesap.hesapAdi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hesap.hesapTuruText),
            if (hesap.bankaAdi != null) Text('Banka: ${hesap.bankaAdi}'),
            Text('Bakiye: ${hesap.formattedBakiye}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Durum göstergesi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hesap.aktif ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hesap.aktif ? 'Aktif' : 'Pasif',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'detay':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KasaBankaDetayPage(kasaBanka: hesap),
                      ),
                    ).then((_) {
                      _hesaplariYukle();
                      _istatistikleriYukle();
                    });
                    break;
                  case 'duzenle':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KasaBankaEklePage(kasaBanka: hesap),
                      ),
                    ).then((sonuc) {
                      if (sonuc == true) {
                        _hesaplariYukle();
                        _istatistikleriYukle();
                      }
                    });
                    break;
                  case 'durum':
                    _hesapDurumDegistir(hesap);
                    break;
                  case 'sil':
                    _hesapSil(hesap);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'detay', child: Text('Detaylar')),
                const PopupMenuItem(value: 'duzenle', child: Text('Düzenle')),
                PopupMenuItem(
                  value: 'durum',
                  child: Text(hesap.aktif ? 'Pasif Yap' : 'Aktif Yap'),
                ),
                const PopupMenuItem(value: 'sil', child: Text('Sil')),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KasaBankaDetayPage(kasaBanka: hesap),
            ),
          ).then((_) {
            _hesaplariYukle();
            _istatistikleriYukle();
          });
        },
      ),
    );
  }

  Widget _buildSayfalama() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _mevcutSayfa > 0 ? () => _sayfaDegistir(_mevcutSayfa - 1) : null,
            child: const Text('Önceki'),
          ),
          const SizedBox(width: 16),
          Text('${_mevcutSayfa + 1} / $_toplamSayfa'),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _mevcutSayfa < _toplamSayfa - 1 ? () => _sayfaDegistir(_mevcutSayfa + 1) : null,
            child: const Text('Sonraki'),
          ),
        ],
      ),
    );
  }
}
