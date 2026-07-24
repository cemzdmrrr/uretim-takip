import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/uretim_raporu_service.dart';

class GenelUretimDashboard extends StatefulWidget {
  const GenelUretimDashboard({super.key});

  @override
  State<GenelUretimDashboard> createState() => _GenelUretimDashboardState();
}

class _GenelUretimDashboardState extends State<GenelUretimDashboard> {
  final UretimRaporuService _service = UretimRaporuService();
  final TextEditingController _aramaController = TextEditingController();

  List<Map<String, dynamic>> _modeller = const [];
  bool _yukleniyor = true;
  String? _hata;
  String _arama = '';
  String _asama = 'Tümü';
  String _tedarikci = 'Tümü';
  String _durum = 'Aktif';

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    if (mounted) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }

    try {
      final sonuc = await _service.verileriYukle();
      if (!mounted) return;
      setState(() {
        _modeller = sonuc.modeller;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Üretim verileri yüklenemedi: $e';
        _yukleniyor = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtrelenmisModeller {
    final arama = _arama.trim().toLowerCase();
    final sonuc = _modeller.where((model) {
      final mevcutAsama = _metin(model['mevcut_asama'], 'beklemede');
      final tedarikci = _metin(model['tedarikci_adi']);
      final tamamlandi = mevcutAsama == 'tamamlandi' ||
          model['tamamlandi'] == true ||
          _durumAnahtari(_mevcutAsamaVerisi(model)['durum']) == 'tamamlandi';

      if (_asama != 'Tümü' && mevcutAsama != _asama) return false;
      if (_tedarikci != 'Tümü') {
        if (_tedarikci == 'Atanmamış') {
          if (tedarikci.isNotEmpty) return false;
        } else if (tedarikci != _tedarikci) {
          return false;
        }
      }
      if (_durum == 'Aktif' && tamamlandi) return false;
      if (_durum == 'Tamamlanan' && !tamamlandi) return false;

      if (arama.isNotEmpty) {
        final aranabilir = [
          model['marka'],
          model['item_no'],
          model['model_adi'],
          model['renk'],
          tedarikci,
          _asamaEtiketi(mevcutAsama),
        ].map((deger) => _metin(deger).toLowerCase()).join(' ');
        if (!aranabilir.contains(arama)) return false;
      }
      return true;
    }).toList();

    sonuc.sort((a, b) {
      final aTermin = DateTime.tryParse(_metin(a['termin_tarihi']));
      final bTermin = DateTime.tryParse(_metin(b['termin_tarihi']));
      if (aTermin == null && bTermin == null) {
        return _modelEtiketi(a).compareTo(_modelEtiketi(b));
      }
      if (aTermin == null) return 1;
      if (bTermin == null) return -1;
      return aTermin.compareTo(bTermin);
    });
    return sonuc;
  }

  List<String> get _asamaSecenekleri {
    final degerler = _modeller
        .map((model) => _metin(model['mevcut_asama'], 'beklemede'))
        .where((deger) => deger.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => _asamaEtiketi(a).compareTo(_asamaEtiketi(b)));
    return ['Tümü', ...degerler];
  }

  List<String> get _tedarikciSecenekleri {
    final degerler = _modeller
        .map((model) => _metin(model['tedarikci_adi']))
        .where((deger) => deger.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Tümü', 'Atanmamış', ...degerler];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Üretim',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              'Model, aşama ve tedarikçi takibi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F3D56),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _verileriYukle,
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _icerik(),
    );
  }

  Widget _icerik() {
    if (_yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hata != null) {
      return _DurumGorunumu(
        icon: Icons.cloud_off_outlined,
        baslik: 'Veriler alınamadı',
        aciklama: _hata!,
        butonMetni: 'Yeniden Dene',
        onPressed: _verileriYukle,
      );
    }

    final modeller = _filtrelenmisModeller;
    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            sliver: SliverToBoxAdapter(child: _ozetAlani(modeller)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(child: _filtreAlani()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: _listeSliver(modeller),
          ),
        ],
      ),
    );
  }

  Widget _ozetAlani(List<Map<String, dynamic>> modeller) {
    final toplamAdet = modeller.fold<int>(
      0,
      (toplam, model) => toplam + _sayi(model['adet'] ?? model['toplam_adet']),
    );
    final geciken = modeller.where(_gecikmisMi).length;
    final tedarikciSayisi = modeller
        .map((model) => _metin(model['tedarikci_adi']))
        .where((ad) => ad.isNotEmpty)
        .toSet()
        .length;
    final atanmamis = modeller
        .where((model) => _metin(model['tedarikci_adi']).isEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Üretim görünümü',
          style: TextStyle(
            color: Color(0xFF102A43),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aktif üretim kayıtlarını model, aşama ve tedarikçi bazında izleyin.',
          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final genislik = constraints.maxWidth;
            final kolon = genislik >= 1050
                ? 4
                : genislik >= 620
                    ? 2
                    : 1;
            final kartGenisligi = (genislik - ((kolon - 1) * 10)) / kolon;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _OzetKarti(
                  width: kartGenisligi,
                  icon: Icons.inventory_2_outlined,
                  baslik: 'Model',
                  deger: '${modeller.length}',
                  altMetin: 'Filtrelenen kayıt',
                  renk: const Color(0xFF2563EB),
                ),
                _OzetKarti(
                  width: kartGenisligi,
                  icon: Icons.layers_outlined,
                  baslik: 'Üretim Adedi',
                  deger: _adetFormatla(toplamAdet),
                  altMetin: 'Toplam sipariş adedi',
                  renk: const Color(0xFF059669),
                ),
                _OzetKarti(
                  width: kartGenisligi,
                  icon: Icons.factory_outlined,
                  baslik: 'Tedarikçi',
                  deger: '$tedarikciSayisi',
                  altMetin: atanmamis > 0
                      ? '$atanmamis atanmamış model'
                      : 'Tümü atandı',
                  renk: const Color(0xFF7C3AED),
                ),
                _OzetKarti(
                  width: kartGenisligi,
                  icon: Icons.schedule_outlined,
                  baslik: 'Geciken',
                  deger: '$geciken',
                  altMetin: 'Termin tarihi geçen',
                  renk: const Color(0xFFDC2626),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _filtreAlani() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102A43),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dar = constraints.maxWidth < 760;
          final arama = TextField(
            controller: _aramaController,
            onChanged: (value) => setState(() => _arama = value),
            decoration: InputDecoration(
              labelText: 'Model, marka, renk veya tedarikçi ara',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _arama.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: () {
                        _aramaController.clear();
                        setState(() => _arama = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          );
          final filtreler = [
            _secimAlani(
              etiket: 'Aşama',
              deger: _asama,
              secenekler: _asamaSecenekleri,
              etiketleyici: _asamaEtiketi,
              onChanged: (value) => setState(() => _asama = value),
            ),
            _secimAlani(
              etiket: 'Tedarikçi',
              deger: _tedarikci,
              secenekler: _tedarikciSecenekleri,
              onChanged: (value) => setState(() => _tedarikci = value),
            ),
            _secimAlani(
              etiket: 'Durum',
              deger: _durum,
              secenekler: const ['Aktif', 'Tümü', 'Tamamlanan'],
              onChanged: (value) => setState(() => _durum = value),
            ),
          ];

          if (dar) {
            return Column(
              children: [
                arama,
                const SizedBox(height: 10),
                for (var i = 0; i < filtreler.length; i++) ...[
                  filtreler[i],
                  if (i != filtreler.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: arama),
              const SizedBox(width: 10),
              for (final filtre in filtreler) ...[
                Expanded(child: filtre),
                if (filtre != filtreler.last) const SizedBox(width: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _secimAlani({
    required String etiket,
    required String deger,
    required List<String> secenekler,
    required ValueChanged<String> onChanged,
    String Function(String value)? etiketleyici,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: secenekler.contains(deger) ? deger : secenekler.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: etiket,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: secenekler
          .map(
            (secenek) => DropdownMenuItem(
              value: secenek,
              child: Text(
                etiketleyici?.call(secenek) ?? secenek,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _listeSliver(List<Map<String, dynamic>> modeller) {
    if (modeller.isEmpty) {
      return SliverToBoxAdapter(
        child: _DurumGorunumu(
          icon: Icons.filter_alt_off_outlined,
          baslik: 'Kayıt bulunamadı',
          aciklama: 'Seçili filtrelerle eşleşen üretim kaydı yok.',
          butonMetni: 'Filtreleri Temizle',
          onPressed: _filtreleriTemizle,
          compact: true,
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        if (constraints.crossAxisExtent < 820) {
          return SliverList.separated(
            itemCount: modeller.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _mobilKart(modeller[index]),
          );
        }
        return SliverToBoxAdapter(child: _masaustuTablo(modeller));
      },
    );
  }

  Widget _masaustuTablo(List<Map<String, dynamic>> modeller) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A102A43),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabloGenisligi =
              constraints.maxWidth < 1120 ? 1120.0 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tabloGenisligi,
              child: DataTable(
                headingRowHeight: 50,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 70,
                headingRowColor:
                    const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
                dividerThickness: 0.6,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: _TabloBasligi('MODEL')),
                  DataColumn(label: _TabloBasligi('RENK')),
                  DataColumn(numeric: true, label: _TabloBasligi('ADET')),
                  DataColumn(label: _TabloBasligi('MEVCUT AŞAMA')),
                  DataColumn(
                      numeric: true, label: _TabloBasligi('AŞAMA ADEDİ')),
                  DataColumn(label: _TabloBasligi('TEDARİKÇİ')),
                  DataColumn(label: _TabloBasligi('DURUM')),
                  DataColumn(label: _TabloBasligi('TERMİN')),
                ],
                rows: modeller.map(_tabloSatiri).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _tabloSatiri(Map<String, dynamic> model) {
    final asamaKodu = _metin(model['mevcut_asama'], 'beklemede');
    final asama = _mevcutAsamaVerisi(model);
    final durum = _metin(
        asama['durum'], asamaKodu == 'tamamlandi' ? 'tamamlandi' : 'bekleyen');
    final tedarikci = _metin(model['tedarikci_adi'], 'Atanmamış');

    return DataRow(
      onSelectChanged: (_) => _detayGoster(model),
      cells: [
        DataCell(_modelHucre(model)),
        DataCell(Text(_metin(model['renk'], '-'))),
        DataCell(_adetMetni(_sayi(model['adet'] ?? model['toplam_adet']))),
        DataCell(
            _AsamaRozeti(kod: asamaKodu, etiket: _asamaEtiketi(asamaKodu))),
        DataCell(_adetMetni(_asamaAdedi(model))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tedarikci == 'Atanmamış'
                    ? Icons.person_off_outlined
                    : Icons.factory_outlined,
                size: 17,
                color: tedarikci == 'Atanmamış'
                    ? Colors.orange.shade700
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(tedarikci, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        DataCell(_DurumRozeti(durum: durum)),
        DataCell(_terminHucre(model)),
      ],
    );
  }

  Widget _mobilKart(Map<String, dynamic> model) {
    final asamaKodu = _metin(model['mevcut_asama'], 'beklemede');
    final asama = _mevcutAsamaVerisi(model);
    final durum = _metin(
        asama['durum'], asamaKodu == 'tamamlandi' ? 'tamamlandi' : 'bekleyen');
    final tedarikci = _metin(model['tedarikci_adi'], 'Atanmamış');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _detayGoster(model),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE6EF)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _modelHucre(model)),
                  const SizedBox(width: 8),
                  _DurumRozeti(durum: durum),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _mobilBilgi(
                      'Toplam Adet',
                      _adetFormatla(
                          _sayi(model['adet'] ?? model['toplam_adet'])),
                      Icons.layers_outlined,
                    ),
                  ),
                  Expanded(
                    child: _mobilBilgi(
                      'Aşama Adedi',
                      _adetFormatla(_asamaAdedi(model)),
                      Icons.precision_manufacturing_outlined,
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _AsamaRozeti(
                      kod: asamaKodu, etiket: _asamaEtiketi(asamaKodu)),
                  _bilgiPili(Icons.factory_outlined, tedarikci),
                  _bilgiPili(
                    Icons.calendar_today_outlined,
                    _tarihMetni(model['termin_tarihi']),
                    uyari: _gecikmisMi(model),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modelHucre(Map<String, dynamic> model) {
    final marka = _metin(model['marka'], 'Markasız');
    final itemNo = _metin(model['item_no'] ?? model['model_adi'], '-');
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 230),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemNo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF102A43),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            marka,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _terminHucre(Map<String, dynamic> model) {
    final gecikmis = _gecikmisMi(model);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          gecikmis
              ? Icons.warning_amber_rounded
              : Icons.calendar_today_outlined,
          size: 16,
          color: gecikmis ? const Color(0xFFDC2626) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Text(
          _tarihMetni(model['termin_tarihi']),
          style: TextStyle(
            color: gecikmis ? const Color(0xFFB91C1C) : const Color(0xFF334155),
            fontWeight: gecikmis ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _mobilBilgi(String baslik, String deger, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            Text(deger,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  Widget _bilgiPili(IconData icon, String metin, {bool uyari = false}) {
    final renk = uyari ? const Color(0xFFB91C1C) : const Color(0xFF475569);
    final zemin = uyari ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration:
          BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: renk),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              metin,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: renk, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _detayGoster(Map<String, dynamic> model) {
    final asamaKodu = _metin(model['mevcut_asama'], 'beklemede');
    final asama = _mevcutAsamaVerisi(model);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _modelEtiketi(model),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _metin(model['renk'], 'Renk belirtilmemiş'),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              _detaySatiri('Toplam adet',
                  _adetFormatla(_sayi(model['adet'] ?? model['toplam_adet']))),
              _detaySatiri('Mevcut aşama', _asamaEtiketi(asamaKodu)),
              _detaySatiri('Aşamadaki adet', _adetFormatla(_asamaAdedi(model))),
              _detaySatiri(
                  'Tedarikçi', _metin(model['tedarikci_adi'], 'Atanmamış')),
              _detaySatiri('Durum', _durumEtiketi(asama['durum'])),
              _detaySatiri(
                  'Termin tarihi', _tarihMetni(model['termin_tarihi'])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detaySatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child:
                Text(baslik, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          Expanded(
              child: Text(deger,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _filtreleriTemizle() {
    _aramaController.clear();
    setState(() {
      _arama = '';
      _asama = 'Tümü';
      _tedarikci = 'Tümü';
      _durum = 'Aktif';
    });
  }

  Map<String, dynamic> _mevcutAsamaVerisi(Map<String, dynamic> model) {
    final asamalar = model['asamalar'];
    if (asamalar is! Map) return const <String, dynamic>{};
    final asama = asamalar[_metin(model['mevcut_asama'])];
    return asama is Map
        ? Map<String, dynamic>.from(asama)
        : const <String, dynamic>{};
  }

  int _asamaAdedi(Map<String, dynamic> model) {
    final asama = _mevcutAsamaVerisi(model);
    return _sayi(
      asama['talep_edilen_adet'] ??
          asama['kontrol_edilecek_adet'] ??
          asama['kabul_edilen_adet'] ??
          asama['adet'] ??
          model['adet'],
    );
  }

  bool _gecikmisMi(Map<String, dynamic> model) {
    final termin = DateTime.tryParse(_metin(model['termin_tarihi']));
    if (termin == null) return false;
    final tamamlandi = _metin(model['mevcut_asama']) == 'tamamlandi' ||
        model['tamamlandi'] == true;
    final bugun = DateTime.now();
    final bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);
    return !tamamlandi && termin.isBefore(bugunBaslangic);
  }

  static String _metin(dynamic value, [String varsayilan = '']) {
    final sonuc = value?.toString().trim() ?? '';
    return sonuc.isEmpty ? varsayilan : sonuc;
  }

  static int _sayi(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _durumAnahtari(dynamic value) {
    return _metin(value)
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static String _asamaEtiketi(String kod) {
    const etiketler = {
      'dokuma': 'Dokuma',
      'nakis': 'Nakış',
      'konfeksiyon': 'Konfeksiyon',
      'yikama': 'Yıkama',
      'ilik_dugme': 'İlik / Düğme',
      'utu': 'Ütü',
      'kalite_kontrol': 'Kalite Kontrol',
      'paketleme': 'Paketleme',
      'sevkiyat': 'Sevkiyat',
      'tamamlandi': 'Tamamlandı',
      'beklemede': 'Henüz Başlamadı',
      'Tümü': 'Tüm Aşamalar',
    };
    return etiketler[kod] ?? kod.replaceAll('_', ' ');
  }

  static String _durumEtiketi(dynamic value) {
    final durum = _durumAnahtari(value);
    const etiketler = {
      'bekleyen': 'Bekleyen',
      'beklemede': 'Bekleyen',
      'atandi': 'Atandı',
      'onaylandi': 'Onaylandı',
      'uretimde': 'İşlemde',
      'baslandi': 'İşlemde',
      'baslatildi': 'İşlemde',
      'devam_ediyor': 'İşlemde',
      'kontrolde': 'Kontrolde',
      'kismi_tamamlandi': 'Kısmi Tamamlandı',
      'tamamlandi': 'Tamamlandı',
      'reddedildi': 'Reddedildi',
      'iptal': 'İptal',
    };
    return etiketler[durum] ??
        (durum.isEmpty ? 'Bekleyen' : durum.replaceAll('_', ' '));
  }

  static String _modelEtiketi(Map<String, dynamic> model) {
    final marka = _metin(model['marka']);
    final item = _metin(model['item_no'] ?? model['model_adi'], 'Model');
    return [marka, item].where((value) => value.isNotEmpty).join(' • ');
  }

  static String _adetFormatla(int adet) =>
      NumberFormat.decimalPattern('tr_TR').format(adet);

  static String _tarihMetni(dynamic value) {
    final tarih = DateTime.tryParse(_metin(value));
    return tarih == null
        ? 'Belirtilmedi'
        : DateFormat('dd.MM.yyyy', 'tr_TR').format(tarih);
  }

  static Widget _adetMetni(int adet) {
    return Text(
      _adetFormatla(adet),
      style: const TextStyle(
          color: Color(0xFF102A43), fontWeight: FontWeight.w800),
    );
  }
}

class _TabloBasligi extends StatelessWidget {
  final String text;

  const _TabloBasligi(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF475569),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
      ),
    );
  }
}

class _OzetKarti extends StatelessWidget {
  final double width;
  final IconData icon;
  final String baslik;
  final String deger;
  final String altMetin;
  final Color renk;

  const _OzetKarti({
    required this.width,
    required this.icon,
    required this.baslik,
    required this.deger,
    required this.altMetin,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: renk, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11)),
                Text(
                  deger,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  altMetin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AsamaRozeti extends StatelessWidget {
  final String kod;
  final String etiket;

  const _AsamaRozeti({required this.kod, required this.etiket});

  @override
  Widget build(BuildContext context) {
    final renk = _renk(kod);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renk.withValues(alpha: 0.22)),
      ),
      child: Text(
        etiket,
        style:
            TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  static Color _renk(String kod) {
    const renkler = {
      'dokuma': Color(0xFF8B5E34),
      'nakis': Color(0xFFDB2777),
      'konfeksiyon': Color(0xFFEA580C),
      'yikama': Color(0xFF0891B2),
      'ilik_dugme': Color(0xFF4F46E5),
      'utu': Color(0xFF059669),
      'kalite_kontrol': Color(0xFF0F766E),
      'paketleme': Color(0xFF7C3AED),
      'sevkiyat': Color(0xFF2563EB),
      'tamamlandi': Color(0xFF16A34A),
    };
    return renkler[kod] ?? const Color(0xFF64748B);
  }
}

class _DurumRozeti extends StatelessWidget {
  final String durum;

  const _DurumRozeti({required this.durum});

  @override
  Widget build(BuildContext context) {
    final anahtar = _GenelUretimDashboardState._durumAnahtari(durum);
    final tamam = {'tamamlandi', 'sevk_edildi'}.contains(anahtar);
    final red = {'reddedildi', 'iptal', 'kalite_red'}.contains(anahtar);
    final islem = {
      'uretimde',
      'baslandi',
      'baslatildi',
      'devam_ediyor',
      'kontrolde',
      'kismi_tamamlandi',
    }.contains(anahtar);
    final renk = tamam
        ? const Color(0xFF15803D)
        : red
            ? const Color(0xFFB91C1C)
            : islem
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _GenelUretimDashboardState._durumEtiketi(durum),
        style:
            TextStyle(color: renk, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DurumGorunumu extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String aciklama;
  final String butonMetni;
  final VoidCallback onPressed;
  final bool compact;

  const _DurumGorunumu({
    required this.icon,
    required this.baslik,
    required this.aciklama,
    required this.butonMetni,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 28 : 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 48 : 60, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(baslik,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(aciklama,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(butonMetni),
            ),
          ],
        ),
      ),
    );
  }
}
