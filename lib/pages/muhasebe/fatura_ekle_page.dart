import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/services/tedarikci_service.dart';

part 'fatura_ekle_page_widgets.dart';


class FaturaEklePage extends StatefulWidget {
  final FaturaModel? duzenlenecekFatura;
  
  const FaturaEklePage({super.key, this.duzenlenecekFatura});

  @override
  State<FaturaEklePage> createState() => _FaturaEklePageState();
}

class _FaturaEklePageState extends State<FaturaEklePage> {
  final _formKey = GlobalKey<FormState>();
  final _faturaNoController = TextEditingController();
  final _faturaAdresController = TextEditingController();
  final _vergiDairesiController = TextEditingController();
  final _vergiNoController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _kurOraniController = TextEditingController(text: '1.0000');
  
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  
  bool _yukleniyor = false;
  bool _duzenlemeModu = false;
  
  // Form alanları
  String _secilenFaturaTuru = 'satis';
  DateTime _faturaTarihi = DateTime.now();
  DateTime? _vadeTarihi;
  String _secilenDurum = 'taslak';
  String _secilenOdemeDurumu = 'odenmedi';
  String _secilenKur = 'TRY';
  
  // Tedarikçi
  List<TedarikciModel> _tedarikciler = [];
  TedarikciModel? _secilenTedarikci;
  
  // Fatura kalemleri
  final List<FaturaKalemiModel> _faturaKalemleri = [];
  double _araToplamTutar = 0;
  double _kdvTutari = 0;
  double _toplamTutar = 0;

  @override
  void initState() {
    super.initState();
    _duzenlemeModu = widget.duzenlenecekFatura != null;
    _verileriYukle();
    
    if (_duzenlemeModu) {
      _formuDoldur();
    } else {
      _otomatikFaturaNoOlustur();
    }
  }

  @override
  void dispose() {
    _faturaNoController.dispose();
    _faturaAdresController.dispose();
    _vergiDairesiController.dispose();
    _vergiNoController.dispose();
    _aciklamaController.dispose();
    _kurOraniController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      final tedarikcilerFuture = TedarikciService.tedarikcileriListele();
      
      final results = await Future.wait([tedarikcilerFuture]);
      
      setState(() {
        _tedarikciler = results[0];
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Veriler yüklenirken hata: $e');
      }
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  void _formuDoldur() {
    final fatura = widget.duzenlenecekFatura!;
    
    setState(() {
      _faturaNoController.text = fatura.faturaNo;
      _secilenFaturaTuru = fatura.faturaTuru;
      _faturaTarihi = fatura.faturaTarihi;
      _vadeTarihi = fatura.vadeTarihi;
      _faturaAdresController.text = fatura.faturaAdres;
      _vergiDairesiController.text = fatura.vergiDairesi ?? '';
      _vergiNoController.text = fatura.vergiNo ?? '';
      _secilenDurum = fatura.durum;
      _aciklamaController.text = fatura.aciklama ?? '';
      _secilenOdemeDurumu = fatura.odemeDurumu;
      _secilenKur = fatura.kur;
      _kurOraniController.text = fatura.kurOrani.toString();
    });
  }

  Future<void> _otomatikFaturaNoOlustur() async {
    try {
      final faturaNo = await FaturaService.sonrakiFaturaNoOlustur(_secilenFaturaTuru);
      setState(() {
        _faturaNoController.text = faturaNo;
      });
    } catch (e) {
      // Hata durumunda manuel giriş bırak
    }
  }

  void _faturaKalemiEkle() {
    showDialog(
      context: context,
      builder: (context) => _FaturaKalemiEkleDialog(
        onKalemEklendi: (kalem) {
          setState(() {
            _faturaKalemleri.add(kalem);
            _tuturlariHesapla();
          });
        },
      ),
    );
  }

  void _faturaKalemiDuzenle(int index) {
    showDialog(
      context: context,
      builder: (context) => _FaturaKalemiEkleDialog(
        duzenlenecekKalem: _faturaKalemleri[index],
        onKalemEklendi: (kalem) {
          setState(() {
            _faturaKalemleri[index] = kalem;
            _tuturlariHesapla();
          });
        },
      ),
    );
  }

  void _faturaKalemiSil(int index) {
    setState(() {
      _faturaKalemleri.removeAt(index);
      _tuturlariHesapla();
    });
  }

  void _tuturlariHesapla() {
    double araToplamTutar = 0;
    double kdvTutari = 0;
    double toplamTutar = 0;

    for (final kalem in _faturaKalemleri) {
      final kalemAraToplam = kalem.miktar * kalem.birimFiyat;
      final kalemKdv = kalemAraToplam * kalem.kdvOrani / 100;
      
      araToplamTutar += kalemAraToplam;
      kdvTutari += kalemKdv;
      toplamTutar += kalemAraToplam + kalemKdv;
    }

    setState(() {
      _araToplamTutar = araToplamTutar;
      _kdvTutari = kdvTutari;
      _toplamTutar = toplamTutar;
    });
  }

  Future<void> _faturaKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_faturaKalemleri.isEmpty) {
      context.showErrorSnackBar('En az bir fatura kalemi eklemelisiniz');
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      final fatura = FaturaModel(
        faturaId: _duzenlemeModu ? widget.duzenlenecekFatura!.faturaId : null,
        faturaNo: _faturaNoController.text,
        faturaTuru: _secilenFaturaTuru,
        faturaTarihi: _faturaTarihi,
        musteriId: null,
        tedarikciId: _secilenTedarikci?.tedarikciId,
        faturaAdres: _faturaAdresController.text,
        vergiDairesi: _vergiDairesiController.text.isEmpty ? null : _vergiDairesiController.text,
        vergiNo: _vergiNoController.text.isEmpty ? null : _vergiNoController.text,
        araToplamTutar: _araToplamTutar,
        kdvTutari: _kdvTutari,
        toplamTutar: _toplamTutar,
        durum: _secilenDurum,
        aciklama: _aciklamaController.text.isEmpty ? null : _aciklamaController.text,
        vadeTarihi: _vadeTarihi,
        odemeDurumu: _secilenOdemeDurumu,
        odenenTutar: 0,
        kur: _secilenKur,
        kurOrani: double.tryParse(_kurOraniController.text) ?? 1.0,
        olusturmaTarihi: DateTime.now(),
        olusturanKullanici: Supabase.instance.client.auth.currentUser?.id ?? 'bilinmeyen'
      );

      if (_duzenlemeModu) {
        await FaturaService.faturaGuncelle(fatura, _faturaKalemleri);
      } else {
        await FaturaService.faturaEkle(fatura, _faturaKalemleri);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_duzenlemeModu ? 'Fatura güncellendi' : 'Fatura eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Fatura kaydedilirken hata: $e');
      }
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeModu ? 'Fatura Düzenle' : 'Yeni Fatura'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (!_yukleniyor)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _faturaKaydet,
            ),
        ],
      ),
      body: _yukleniyor
          ? const LoadingWidget()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Temel bilgiler kartı
                    _buildTemelBilgilerKarti(),
                    const SizedBox(height: 16),
                    
                    // Müşteri/Tedarikçi kartı
                    _buildMusteritedarikciKarti(),
                    const SizedBox(height: 16),
                    
                    // Fatura kalemleri kartı
                    _buildFaturaKalemleriKarti(),
                    const SizedBox(height: 16),
                    
                    // Toplam tutarlar kartı
                    _buildToplamTutarlarKarti(),
                    const SizedBox(height: 24),
                    
                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _yukleniyor ? null : _faturaKaydet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _yukleniyor
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_duzenlemeModu ? 'Güncelle' : 'Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

}