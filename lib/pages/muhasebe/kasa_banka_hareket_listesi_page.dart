// =============================================
// KASA/BANKA HAREKETLERİ LİSTESİ SAYFASI
// Tarih: 27.06.2025
// Açıklama: Kasa ve banka hesaplarındaki para hareketlerini listeleyen sayfa
// =============================================

import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/models/kasa_banka_hareket_model.dart';
import 'package:uretim_takip/services/kasa_banka_hareket_service.dart';
import 'package:uretim_takip/pages/muhasebe/kasa_banka_hareket_ekle_page.dart';

class KasaBankaHareketListesiPage extends StatefulWidget {
  final String? kasaBankaId;
  final String? kasaBankaAdi;

  const KasaBankaHareketListesiPage({
    Key? key,
    this.kasaBankaId,
    this.kasaBankaAdi,
  }) : super(key: key);

  @override
  State<KasaBankaHareketListesiPage> createState() => _KasaBankaHareketListesiPageState();
}

class _KasaBankaHareketListesiPageState extends State<KasaBankaHareketListesiPage> {
  final KasaBankaHareketService _hareketService = KasaBankaHareketService();
  List<KasaBankaHareket> _hareketler = [];
  bool _yukleniyor = false;
  String? _secilenHareketTuru;
  String? _secilenKategori;
  bool? _secilenOnayDurumu;
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;

  @override
  void initState() {
    super.initState();
    _hareketleriYukle();
  }

  Future<void> _hareketleriYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      List<KasaBankaHareket> hareketler;
      
      if (widget.kasaBankaId != null) {
        // Belirli hesaba ait hareketleri getir
        hareketler = await _hareketService.hesapHareketleriGetir(
          widget.kasaBankaId!,
          baslangicTarihi: _baslangicTarihi,
          bitisTarihi: _bitisTarihi,
          hareketTipi: _secilenHareketTuru,
          onaylilar: _secilenOnayDurumu,
        );
      } else {
        // Tüm hareketleri getir
        hareketler = await _hareketService.tumHareketleriGetir(
          baslangicTarihi: _baslangicTarihi,
          bitisTarihi: _bitisTarihi,
          hareketTipi: _secilenHareketTuru,
          onaylilar: _secilenOnayDurumu,
        );
      }

      setState(() {
        _hareketler = hareketler;
      });
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hareketler yüklenirken hata oluştu: $e');
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }


  void _yeniHareketEkle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KasaBankaHareketEklePage(
          varsayilanKasaBankaId: widget.kasaBankaId,
        ),
      ),
    ).then((eklendi) {
      if (eklendi == true) {
        _hareketleriYukle();
      }
    });
  }

  void _filtreleriTemizle() {
    setState(() {
      _secilenHareketTuru = null;
      _secilenKategori = null;
      _secilenOnayDurumu = null;
      _baslangicTarihi = null;
      _bitisTarihi = null;
    });
    _hareketleriYukle();
  }

  void _filtreleriGoster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FiltreWidget(
        secilenHareketTuru: _secilenHareketTuru,
        secilenKategori: _secilenKategori,
        secilenOnayDurumu: _secilenOnayDurumu,
        baslangicTarihi: _baslangicTarihi,
        bitisTarihi: _bitisTarihi,
        onFiltreUygula: (hareketTuru, kategori, onayDurumu, baslangic, bitis) {
          setState(() {
            _secilenHareketTuru = hareketTuru;
            _secilenKategori = kategori;
            _secilenOnayDurumu = onayDurumu;
            _baslangicTarihi = baslangic;
            _bitisTarihi = bitis;
          });
          _hareketleriYukle();
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _hareketKarti(KasaBankaHareket hareket) {
    Color? hareketRengi;
    IconData hareketIkonu;

    switch (hareket.hareketTipi) {
      case 'giris':
        hareketRengi = Colors.green;
        hareketIkonu = Icons.arrow_downward;
        break;
      case 'cikis':
        hareketRengi = Colors.red;
        hareketIkonu = Icons.arrow_upward;
        break;
      case 'transfer_giden':
        hareketRengi = Colors.red.shade700;
        hareketIkonu = Icons.arrow_forward;
        break;
      case 'transfer_gelen':
        hareketRengi = Colors.green.shade700;
        hareketIkonu = Icons.arrow_back;
        break;
      default:
        hareketRengi = Colors.grey;
        hareketIkonu = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hareketRengi.withValues(alpha: 0.1),
          child: Icon(hareketIkonu, color: hareketRengi),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hareket.aciklama ?? 'Açıklama yok',
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              hareket.formattedTutar,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hareketRengi,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${hareket.islemTarihi.day}.${hareket.islemTarihi.month}.${hareket.islemTarihi.year}'),
                const SizedBox(width: 16),
                if (hareket.referansNo != null) ...[
                  Icon(Icons.description, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(hareket.referansNo!),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hareket.onaylanmisMi
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hareket.onaylanmisMi ? 'Onaylı' : 'Bekliyor',
                    style: TextStyle(
                      fontSize: 12,
                      color: hareket.onaylanmisMi
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hareket.hareketTipiDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (hareket.kategori != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    hareket.kategoriDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {}, // => _hareketDetayGoster(hareket),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kasaBankaAdi != null 
            ? '${widget.kasaBankaAdi} Hareketleri' 
            : 'Kasa/Banka Hareketleri'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _filtreleriGoster,
          ),
          if (_secilenHareketTuru != null ||
              _secilenKategori != null ||
              _secilenOnayDurumu != null ||
              _baslangicTarihi != null ||
              _bitisTarihi != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _filtreleriTemizle,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hareketleriYukle,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre durumu göstergesi
          if (_secilenHareketTuru != null ||
              _secilenKategori != null ||
              _secilenOnayDurumu != null ||
              _baslangicTarihi != null ||
              _bitisTarihi != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_secilenHareketTuru != null)
                    Chip(
                      label: Text('Tür: $_secilenHareketTuru'),
                      onDeleted: () {
                        setState(() => _secilenHareketTuru = null);
                        _hareketleriYukle();
                      },
                    ),
                  if (_secilenKategori != null)
                    Chip(
                      label: Text('Kategori: $_secilenKategori'),
                      onDeleted: () {
                        setState(() => _secilenKategori = null);
                        _hareketleriYukle();
                      },
                    ),
                  if (_secilenOnayDurumu != null)
                    Chip(
                      label: Text(_secilenOnayDurumu! ? 'Onaylı' : 'Beklemede'),
                      onDeleted: () {
                        setState(() => _secilenOnayDurumu = null);
                        _hareketleriYukle();
                      },
                    ),
                ],
              ),
            ),
          
          // İçerik
          Expanded(
            child: _yukleniyor
                ? const LoadingWidget()
                : _hareketler.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz hareket bulunmuyor',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Yeni hareket eklemek için + butonuna tıklayın',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _hareketleriYukle,
                        child: ListView.builder(
                          itemCount: _hareketler.length,
                          itemBuilder: (context, index) {
                            return _hareketKarti(_hareketler[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniHareketEkle,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hareket'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

// =============================================
// FİLTRE WİDGETİ
// =============================================

class _FiltreWidget extends StatefulWidget {
  final String? secilenHareketTuru;
  final String? secilenKategori;
  final bool? secilenOnayDurumu;
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final Function(String?, String?, bool?, DateTime?, DateTime?) onFiltreUygula;

  const _FiltreWidget({
    required this.secilenHareketTuru,
    required this.secilenKategori,
    required this.secilenOnayDurumu,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.onFiltreUygula,
  });

  @override
  State<_FiltreWidget> createState() => _FiltreWidgetState();
}

class _FiltreWidgetState extends State<_FiltreWidget> {
  String? _hareketTuru;
  String? _kategori;
  bool? _onayDurumu;
  DateTime? _baslangic;
  DateTime? _bitis;

  @override
  void initState() {
    super.initState();
    _hareketTuru = widget.secilenHareketTuru;
    _kategori = widget.secilenKategori;
    _onayDurumu = widget.secilenOnayDurumu;
    _baslangic = widget.baslangicTarihi;
    _bitis = widget.bitisTarihi;
  }

  Future<void> _tarihSec(bool baslangic) async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: (baslangic ? _baslangic : _bitis) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (secilen != null) {
      setState(() {
        if (baslangic) {
          _baslangic = secilen;
        } else {
          _bitis = secilen;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtreler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hareket Türü
          const Text('Hareket Türü', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _hareketTuru,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Tümü'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tümü')),
              DropdownMenuItem(value: 'giris', child: Text('Giriş')),
              DropdownMenuItem(value: 'cikis', child: Text('Çıkış')),
              DropdownMenuItem(value: 'transfer_giden', child: Text('Transfer (Giden)')),
              DropdownMenuItem(value: 'transfer_gelen', child: Text('Transfer (Gelen)')),
            ],
            onChanged: (value) => setState(() => _hareketTuru = value),
          ),
          const SizedBox(height: 16),

          // Kategori
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _kategori,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Tümü'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tümü')),
              DropdownMenuItem(value: 'fatura_odeme', child: Text('Fatura Ödemesi')),
              DropdownMenuItem(value: 'nakit_giris', child: Text('Nakit Giriş')),
              DropdownMenuItem(value: 'bank_transfer', child: Text('Banka Transferi')),
              DropdownMenuItem(value: 'operasyonel', child: Text('Operasyonel')),
              DropdownMenuItem(value: 'diger', child: Text('Diğer')),
            ],
            onChanged: (value) => setState(() => _kategori = value),
          ),
          const SizedBox(height: 16),

          // Onay Durumu
          const Text('Onay Durumu', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<bool>(
            initialValue: _onayDurumu,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Tümü'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tümü')),
              DropdownMenuItem(value: true, child: Text('Onaylı')),
              DropdownMenuItem(value: false, child: Text('Beklemede')),
            ],
            onChanged: (value) => setState(() => _onayDurumu = value),
          ),
          const SizedBox(height: 16),

          // Tarih Aralığı
          const Text('Tarih Aralığı', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _tarihSec(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _baslangic != null
                          ? '${_baslangic!.day.toString().padLeft(2, '0')}.'
                            '${_baslangic!.month.toString().padLeft(2, '0')}.'
                            '${_baslangic!.year}'
                          : 'Başlangıç',
                      style: TextStyle(
                        color: _baslangic != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('-'),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _tarihSec(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _bitis != null
                          ? '${_bitis!.day.toString().padLeft(2, '0')}.'
                            '${_bitis!.month.toString().padLeft(2, '0')}.'
                            '${_bitis!.year}'
                          : 'Bitiş',
                      style: TextStyle(
                        color: _bitis != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _hareketTuru = null;
                      _kategori = null;
                      _onayDurumu = null;
                      _baslangic = null;
                      _bitis = null;
                    });
                  },
                  child: const Text('Temizle'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltreUygula(
                      _hareketTuru,
                      _kategori,
                      _onayDurumu,
                      _baslangic,
                      _bitis,
                    );
                  },
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
