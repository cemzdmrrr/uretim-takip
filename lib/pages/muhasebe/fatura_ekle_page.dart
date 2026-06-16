import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';
import 'package:uretim_takip/models/tedarikci_model.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/services/tedarikci_service.dart';
import 'package:uretim_takip/utils/decimal_parser.dart';

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
  final _cariUnvanController = TextEditingController();
  final _cariUnvanFocusNode = FocusNode();
  final _faturaAdresController = TextEditingController();
  final _vergiDairesiController = TextEditingController();
  final _vergiNoController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _kurOraniController = TextEditingController(text: '1.0000');

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

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
    _cariUnvanController.dispose();
    _cariUnvanFocusNode.dispose();
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
      final tedarikciler = await TedarikciService.tedarikcileriListele();
      final kalemler =
          _duzenlemeModu && widget.duzenlenecekFatura?.faturaId != null
              ? await FaturaService.faturaKalemleriniGetir(
                  widget.duzenlenecekFatura!.faturaId!,
                )
              : <FaturaKalemiModel>[];

      setState(() {
        _tedarikciler = tedarikciler;
        if (_duzenlemeModu) {
          final tedarikciId = widget.duzenlenecekFatura!.tedarikciId;
          _secilenTedarikci = tedarikciId == null
              ? null
              : _tedarikciler
                  .where((tedarikci) => tedarikci.tedarikciId == tedarikciId)
                  .firstOrNull;
          if (_secilenTedarikci != null) {
            if (_cariUnvanController.text.trim().isEmpty) {
              _cariUnvanController.text = _secilenTedarikci!.unvan;
            }
          }
          _faturaKalemleri
            ..clear()
            ..addAll(kalemler);
          _tutarDegerleriniHesapla();
        }
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
      _cariUnvanController.text = fatura.cariUnvan ?? '';
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
      final faturaNo =
          await FaturaService.sonrakiFaturaNoOlustur(_secilenFaturaTuru);
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
    _tutarDegerleriniHesapla();
  }

  void _tutarDegerleriniHesapla() {
    double araToplamTutar = 0;
    double kdvTutari = 0;
    double toplamTutar = 0;

    for (final kalem in _faturaKalemleri) {
      araToplamTutar += kalem.kdvHaricTutar;
      kdvTutari += kalem.hesaplananKdvTutar;
      toplamTutar += kalem.kdvDahilTutar;
    }

    _araToplamTutar = araToplamTutar;
    _kdvTutari = kdvTutari;
    _toplamTutar = toplamTutar;
  }

  String _tedarikciUnvani(TedarikciModel tedarikci) {
    return tedarikci.unvan.trim();
  }

  String _tedarikciAltBilgi(TedarikciModel tedarikci) {
    final parcalar = <String>[
      if ((tedarikci.vergiNo ?? '').trim().isNotEmpty)
        'Vergi No: ${tedarikci.vergiNo}',
      if ((tedarikci.telefon).trim().isNotEmpty) 'Tel: ${tedarikci.telefon}',
      if ((tedarikci.email ?? '').trim().isNotEmpty) tedarikci.email!,
    ];
    return parcalar.join(' • ');
  }

  void _tedarikciBilgileriniDoldur(TedarikciModel? tedarikci) {
    setState(() {
      _secilenTedarikci = tedarikci;
      if (tedarikci == null) return;
      _cariUnvanController.text = _tedarikciUnvani(tedarikci);
      final adres = tedarikci.adres?.trim();
      if (adres != null && adres.isNotEmpty) {
        _faturaAdresController.text = adres;
      }
      final vergiDairesi = tedarikci.vergiDairesi?.trim();
      if (vergiDairesi != null && vergiDairesi.isNotEmpty) {
        _vergiDairesiController.text = vergiDairesi;
      }
      _vergiNoController.text = tedarikci.vergiNo ?? '';
    });
  }

  Future<void> _faturaKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_secilenFaturaTuru != 'satis' && _faturaKalemleri.isEmpty) {
      context.showErrorSnackBar('En az bir fatura kalemi eklemelisiniz');
      return;
    }

    setState(() {
      _yukleniyor = true;
    });

    try {
      final kaydedilecekKalemler = _secilenFaturaTuru == 'satis'
          ? <FaturaKalemiModel>[]
          : _faturaKalemleri;
      final araToplamTutar =
          _secilenFaturaTuru == 'satis' ? 0.0 : _araToplamTutar;
      final kdvTutari = _secilenFaturaTuru == 'satis' ? 0.0 : _kdvTutari;
      final toplamTutar = _secilenFaturaTuru == 'satis' ? 0.0 : _toplamTutar;

      final fatura = FaturaModel(
          faturaId: _duzenlemeModu ? widget.duzenlenecekFatura!.faturaId : null,
          faturaNo: _faturaNoController.text,
          faturaTuru: _secilenFaturaTuru,
          faturaTarihi: _faturaTarihi,
          musteriId: null,
          tedarikciId: _secilenTedarikci?.tedarikciId,
          cariUnvan: _cariUnvanController.text.trim().isEmpty
              ? null
              : _cariUnvanController.text.trim(),
          faturaAdres: _faturaAdresController.text,
          vergiDairesi: _vergiDairesiController.text.isEmpty
              ? null
              : _vergiDairesiController.text,
          vergiNo:
              _vergiNoController.text.isEmpty ? null : _vergiNoController.text,
          araToplamTutar: araToplamTutar,
          kdvTutari: kdvTutari,
          toplamTutar: toplamTutar,
          durum: _secilenDurum,
          aciklama: _aciklamaController.text.isEmpty
              ? null
              : _aciklamaController.text,
          vadeTarihi: _vadeTarihi,
          odemeDurumu: _secilenOdemeDurumu,
          odenenTutar: 0,
          kur: _secilenKur,
          kurOrani: parseLocalizedDecimal(_kurOraniController.text) ?? 1.0,
          olusturmaTarihi: DateTime.now(),
          olusturanKullanici:
              Supabase.instance.client.auth.currentUser?.id ?? 'bilinmeyen');

      if (_duzenlemeModu) {
        await FaturaService.faturaGuncelle(fatura, kaydedilecekKalemler);
      } else {
        await FaturaService.faturaEkle(fatura, kaydedilecekKalemler);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_duzenlemeModu ? 'Fatura güncellendi' : 'Fatura eklendi'),
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

                    if (_secilenFaturaTuru != 'satis') ...[
                      // Fatura kalemleri kartı
                      _buildFaturaKalemleriKarti(),
                      const SizedBox(height: 16),

                      // Toplam tutarlar kartı
                      _buildToplamTutarlarKarti(),
                      const SizedBox(height: 24),
                    ],

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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
