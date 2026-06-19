import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/models/uyumsoft_gelen_fatura_model.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_detay_page.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/services/uyumsoft_fatura_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class UyumsoftGelenFaturalarPage extends StatefulWidget {
  const UyumsoftGelenFaturalarPage({super.key});

  @override
  State<UyumsoftGelenFaturalarPage> createState() =>
      _UyumsoftGelenFaturalarPageState();
}

class _UyumsoftGelenFaturalarPageState
    extends State<UyumsoftGelenFaturalarPage> {
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _redSebebiController = TextEditingController();
  final _limitController = TextEditingController(text: '50');

  List<UyumsoftGelenFatura> _faturalar = [];
  bool _yukleniyor = false;
  bool _islemde = false;
  String _durumFiltresi = 'beklemede';
  String _apiTarihTipi = 'fatura';
  late DateTime _apiBaslangicTarihi;
  late DateTime _apiBitisTarihi;

  static const _silinebilirDurumlar = {'beklemede', 'reddedildi', 'hata'};

  bool get _topluSilinebilir =>
      _silinebilirDurumlar.contains(_durumFiltresi) && _faturalar.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final bugun = DateTime.now();
    _apiBaslangicTarihi = bugun.subtract(const Duration(days: 30));
    _apiBitisTarihi = bugun;
    _faturalariYukle();
  }

  @override
  void dispose() {
    _redSebebiController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _faturalariYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final faturalar = await UyumsoftFaturaService.bekleyenleriGetir(
        durum: _durumFiltresi == 'tumu' ? null : _durumFiltresi,
      );
      if (!mounted) return;
      setState(() => _faturalar = faturalar);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _apiIleCek() async {
    setState(() => _islemde = true);
    try {
      final sonuc = await UyumsoftFaturaService.apiIleSenkronizeEt(
        baslangicTarihi: _gunBaslangici(_apiBaslangicTarihi),
        bitisTarihi: _gunBitisi(_apiBitisTarihi),
        tarihTipi: _apiTarihTipi,
        limit: int.tryParse(_limitController.text.trim()) ?? 50,
      );
      if (!mounted) return;
      context.showSuccessSnackBar(
        '${sonuc.bulunan} fatura bulundu, ${sonuc.aktarilan} fatura senkronize edildi',
      );
      if (sonuc.hatalar.isNotEmpty) {
        context.showErrorSnackBar(
          '${sonuc.hatalar.length} fatura detay indirilemedi. Hata filtresinde listelendi.',
        );
      }
      await _faturalariYukle();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _xmlYukle() async {
    setState(() => _islemde = true);
    try {
      final sonuc = await UyumsoftFaturaService.xmlUblDosyalariYukle();
      if (!mounted) return;
      context.showSuccessSnackBar(
        '${sonuc.secilen} dosya seçildi, ${sonuc.eklenen} eklendi, '
        '${sonuc.zatenVardi} zaten vardı, ${sonuc.hatali} hatalı',
      );
      if (sonuc.hatalar.isNotEmpty) {
        context.showErrorSnackBar(sonuc.hatalar.take(3).join('\n'));
      }
      await _faturalariYukle();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  DateTime _gunBaslangici(DateTime tarih) {
    return DateTime(tarih.year, tarih.month, tarih.day);
  }

  DateTime _gunBitisi(DateTime tarih) {
    return DateTime(tarih.year, tarih.month, tarih.day, 23, 59, 59, 999);
  }

  Future<void> _tarihAraligiSec() async {
    final secilen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDateRange: DateTimeRange(
        start: _apiBaslangicTarihi,
        end: _apiBitisTarihi,
      ),
      helpText: 'Uyumsoft çekim tarih aralığı',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (secilen == null) return;
    setState(() {
      _apiBaslangicTarihi = secilen.start;
      _apiBitisTarihi = secilen.end;
    });
  }

  Future<void> _onayla(UyumsoftGelenFatura fatura) async {
    setState(() => _islemde = true);
    try {
      final faturaId = await UyumsoftFaturaService.gelenFaturaOnayla(fatura.id);
      if (!mounted) return;
      context.showSuccessSnackBar('Fatura taslak olarak aktarıldı');
      await _faturalariYukle();
      final detayFatura = await FaturaService.faturaGetir(faturaId);
      if (!mounted || detayFatura == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaturaDetayPage(fatura: detayFatura),
        ),
      );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _reddet(UyumsoftGelenFatura fatura) async {
    _redSebebiController.clear();
    final sebep = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faturayı Reddet'),
        content: TextField(
          controller: _redSebebiController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Red sebebi',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgec'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(
              context,
              _redSebebiController.text.trim(),
            ),
            icon: const Icon(Icons.block),
            label: const Text('Reddet'),
          ),
        ],
      ),
    );
    if (sebep == null) return;

    setState(() => _islemde = true);
    try {
      await UyumsoftFaturaService.gelenFaturaReddet(
        fatura.id,
        sebep: sebep.isEmpty ? null : sebep,
      );
      if (!mounted) return;
      context.showSuccessSnackBar('Fatura reddedildi');
      await _faturalariYukle();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _sil(UyumsoftGelenFatura fatura) async {
    if (!_silinebilirDurumlar.contains(fatura.durum)) {
      context.showErrorSnackBar('Aktarilan faturalar buradan silinemez.');
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gelen Faturayi Sil'),
        content: Text(
          '${fatura.faturaNo} numarali gelen fatura kaydi silinsin mi?\n\n'
          'Bu islem mevcut fatura sistemine aktarilmis faturalari silmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgec'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _islemde = true);
    try {
      final silinen = await UyumsoftFaturaService.gelenFaturaSil(fatura.id);
      if (!mounted) return;
      context.showSuccessSnackBar('$silinen gelen fatura kaydi silindi');
      await _faturalariYukle();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _topluSil() async {
    if (!_topluSilinebilir) return;
    final ids = _faturalar
        .where((fatura) => _silinebilirDurumlar.contains(fatura.durum))
        .map((fatura) => fatura.id)
        .toList();
    if (ids.isEmpty) return;

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listedeki Kayitlari Sil'),
        content: Text(
          '${ids.length} adet ${_durumMetni(_durumFiltresi).toLowerCase()} '
          'gelen fatura kaydi silinsin mi?\n\n'
          'Aktarilan fatura kayitlari ve mevcut fatura sistemi etkilenmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgec'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Toplu Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _islemde = true);
    try {
      final silinen = await UyumsoftFaturaService.gelenFaturalariSil(ids);
      if (!mounted) return;
      context.showSuccessSnackBar('$silinen gelen fatura kaydi silindi');
      await _faturalariYukle();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _islemde = false);
    }
  }

  Future<void> _detayGoster(UyumsoftGelenFatura fatura) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        maxChildSize: 0.94,
        minChildSize: 0.45,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Icon(Icons.description, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fatura.faturaNo,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _detaySatiri('ETTN', fatura.ettn),
              _detaySatiri('Tedarikçi', fatura.cariUnvan),
              _detaySatiri('Vergi No', fatura.vergiNo ?? '-'),
              _detaySatiri('Vergi Dairesi', fatura.vergiDairesi ?? '-'),
              _detaySatiri('Adres', fatura.faturaAdres ?? '-'),
              _detaySatiri('Tarih', _dateFormat.format(fatura.faturaTarihi)),
              _detaySatiri(
                  'Ara Toplam', _currencyFormat.format(fatura.araToplamTutar)),
              _detaySatiri('KDV', _currencyFormat.format(fatura.kdvTutari)),
              _detaySatiri(
                  'Toplam', _currencyFormat.format(fatura.toplamTutar)),
              if (fatura.durum == 'hata' &&
                  (fatura.redSebebi?.trim().isNotEmpty ?? false))
                _detaySatiri('Hata', fatura.redSebebi!),
              const Divider(height: 32),
              Text(
                'Kalemler',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (fatura.kalemler.isEmpty)
                const Text('Kalem bulunamadı')
              else
                ...fatura.kalemler.map(
                  (kalem) => Card(
                    child: ListTile(
                      title: Text(kalem.urunAdi),
                      subtitle: Text(
                        '${kalem.miktar} ${kalem.birim} x '
                        '${_currencyFormat.format(kalem.birimFiyat)}',
                      ),
                      trailing: Text(_currencyFormat.format(kalem.toplamTutar)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (fatura.durum == 'beklemede')
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sil(fatura);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _reddet(fatura);
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Reddet'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _onayla(fatura);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                    ),
                  ],
                ),
              if (fatura.durum != 'beklemede' &&
                  _silinebilirDurumlar.contains(fatura.durum))
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _sil(fatura);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _detaySatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              baslik,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(deger)),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'beklemede', label: Text('Bekleyen')),
                ButtonSegment(value: 'aktarildi', label: Text('Aktarılan')),
                ButtonSegment(value: 'reddedildi', label: Text('Reddedilen')),
                ButtonSegment(value: 'hata', label: Text('Hata')),
                ButtonSegment(value: 'tumu', label: Text('Tümü')),
              ],
              selected: {_durumFiltresi},
              onSelectionChanged: (value) {
                setState(() => _durumFiltresi = value.first);
                _faturalariYukle();
              },
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _islemde ? null : _tarihAraligiSec,
              icon: const Icon(Icons.date_range),
              label: Text(
                '${_dateFormat.format(_apiBaslangicTarihi)} - '
                '${_dateFormat.format(_apiBitisTarihi)}',
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                initialValue: _apiTarihTipi,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Tarih tipi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'fatura', child: Text('Fatura')),
                  DropdownMenuItem(
                    value: 'olusturma',
                    child: Text('Oluşturma'),
                  ),
                ],
                onChanged: _islemde
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _apiTarihTipi = value);
                      },
              ),
            ),
            SizedBox(
              width: 92,
              child: TextField(
                controller: _limitController,
                enabled: !_islemde,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Limit',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _islemde ? null : _apiIleCek,
              icon: const Icon(Icons.sync, color: Colors.white),
              label: const Text("Uyumsoft'tan Çek"),
            ),
            OutlinedButton.icon(
              onPressed: _islemde ? null : _xmlYukle,
              icon: const Icon(Icons.file_upload, color: Colors.blue),
              label: const Text('XML/UBL Toplu Yukle'),
            ),
            if (_topluSilinebilir)
              OutlinedButton.icon(
                onPressed: _islemde ? null : _topluSil,
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: Text('Listedekileri Sil (${_faturalar.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            IconButton(
              tooltip: 'Yenile',
              onPressed: _islemde ? null : _faturalariYukle,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaturaCard(UyumsoftGelenFatura fatura) {
    final durumRenk = switch (fatura.durum) {
      'aktarildi' => Colors.green,
      'reddedildi' => Colors.red,
      'hata' => Colors.deepOrange,
      _ => Colors.orange,
    };

    return Card(
      child: InkWell(
        onTap: () => _detayGoster(fatura),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fatura.faturaNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          fatura.cariUnvan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(fatura.toplamTutar),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateFormat.format(fatura.faturaTarihi)),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar:
                        const Icon(Icons.folder, size: 16, color: Colors.blue),
                    label: Text(fatura.kaynak.toUpperCase()),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: durumRenk.withValues(alpha: 0.12),
                    label: Text(
                      _durumMetni(fatura.durum),
                      style: TextStyle(
                        color: durumRenk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${fatura.kalemler.length} kalem'),
                  ),
                ],
              ),
              if (fatura.durum == 'beklemede') ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _islemde ? null : () => _sil(fatura),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Sil'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _islemde ? null : () => _reddet(fatura),
                        icon: const Icon(Icons.block),
                        label: const Text('Reddet'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _islemde ? null : () => _onayla(fatura),
                        icon: const Icon(Icons.check),
                        label: const Text('Onayla'),
                      ),
                    ],
                  ),
                ),
              ],
              if (fatura.durum != 'beklemede' &&
                  _silinebilirDurumlar.contains(fatura.durum)) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _islemde ? null : () => _sil(fatura),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
              if (fatura.durum == 'aktarildi' && fatura.faturaId != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final detayFatura =
                          await FaturaService.faturaGetir(fatura.faturaId!);
                      if (!mounted || detayFatura == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FaturaDetayPage(fatura: detayFatura),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Fatura detayına git'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _durumMetni(String durum) {
    switch (durum) {
      case 'beklemede':
        return 'Beklemede';
      case 'aktarildi':
        return 'Aktarıldı';
      case 'reddedildi':
        return 'Reddedildi';
      case 'hata':
        return 'Hata';
      default:
        return durum;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uyumsoft Gelen Faturalar'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _faturalariYukle,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildToolbar(),
                const SizedBox(height: 12),
                if (_yukleniyor)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_faturalar.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Bu filtrede gelen fatura bulunmuyor'),
                    ),
                  )
                else
                  ..._faturalar.map(_buildFaturaCard),
              ],
            ),
          ),
          if (_islemde)
            Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
