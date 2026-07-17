import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_ekle_page.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_detay_page.dart';
import 'package:uretim_takip/pages/muhasebe/uyumsoft_gelen_faturalar_page.dart';
import 'package:uretim_takip/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/utils/currency_utils.dart';

class FaturaListesiPage extends StatefulWidget {
  const FaturaListesiPage({super.key});

  @override
  State<FaturaListesiPage> createState() => _FaturaListesiPageState();
}

class _FaturaListesiPageState extends State<FaturaListesiPage> {
  final TextEditingController _aramaController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  List<FaturaModel> _faturalar = [];
  Map<int, List<String>> _faturaKategoriOzetleri = {};
  int _satisFaturaAdedi = 0;
  int _alisFaturaAdedi = 0;
  Map<String, double> _satisFaturaTutarlari = {};
  Map<String, double> _alisFaturaTutarlari = {};
  bool _yukleniyor = false;
  String _secilenFaturaTuru = '';
  String _secilenDurum = '';
  String _secilenOdemeDurumu = '';
  String _secilenKategori = '';
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

  Map<String, double> _toplamMapiniOku(dynamic value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        normalizeCurrencyCode(entry.key.toString()):
            (entry.value as num?)?.toDouble() ?? 0,
    };
  }

  List<String> _toplamSatirlari(Map<String, double> totals) {
    if (totals.isEmpty) return [formatCurrencyAmount(0, 'TRY')];
    return sortedCurrencyTotals(totals)
        .map((entry) => formatCurrencyAmount(entry.value, entry.key))
        .toList();
  }

  Future<void> _faturalariYukle() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      final faturalar = await FaturaService.faturalariListele(
        aramaKelimesi:
            _aramaController.text.isEmpty ? null : _aramaController.text,
        faturaTuru: _secilenFaturaTuru.isEmpty ? null : _secilenFaturaTuru,
        durum: _secilenDurum.isEmpty ? null : _secilenDurum,
        odemeDurumu: _secilenOdemeDurumu.isEmpty ? null : _secilenOdemeDurumu,
        kategori: _secilenKategori.isEmpty ? null : _secilenKategori,
        baslangicTarihi: _baslangicTarihi,
        bitisTarihi: _bitisTarihi,
        limit: 100,
      );
      final finansOzet = await FaturaService.faturaFinansOzetGetir(
        aramaKelimesi:
            _aramaController.text.isEmpty ? null : _aramaController.text,
        faturaTuru: _secilenFaturaTuru.isEmpty ? null : _secilenFaturaTuru,
        durum: _secilenDurum.isEmpty ? null : _secilenDurum,
        odemeDurumu: _secilenOdemeDurumu.isEmpty ? null : _secilenOdemeDurumu,
        kategori: _secilenKategori.isEmpty ? null : _secilenKategori,
        baslangicTarihi: _baslangicTarihi,
        bitisTarihi: _bitisTarihi,
      );
      final kategoriOzetleri = await FaturaService.faturaKategoriOzetleriGetir(
        faturalar.map((fatura) => fatura.faturaId).whereType<int>().toList(),
      );

      setState(() {
        _faturalar = faturalar;
        _faturaKategoriOzetleri = kategoriOzetleri;
        _satisFaturaAdedi = finansOzet['satis_adet'] as int? ?? 0;
        _satisFaturaTutarlari = _toplamMapiniOku(finansOzet['satis_tutarlar']);
        _alisFaturaAdedi = finansOzet['alis_adet'] as int? ?? 0;
        _alisFaturaTutarlari = _toplamMapiniOku(finansOzet['alis_tutarlar']);
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

  Future<void> _uyumsoftGelenFaturalariAc() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UyumsoftGelenFaturalarPage(),
      ),
    );
    _faturalariYukle();
  }

  Future<void> _faturaSil(FaturaModel fatura) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fatura Sil'),
        content: Text(
          '${fatura.faturaNo} numaralı faturayı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay != true || fatura.faturaId == null) return;

    try {
      await FaturaService.faturaSil(fatura.faturaId!);
      if (!mounted) return;
      context.showSuccessSnackBar('Fatura silindi');
      _faturalariYukle();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Fatura silinirken hata: $e');
      }
    }
  }

  void _filtreleriTemizle() {
    setState(() {
      _aramaController.clear();
      _secilenFaturaTuru = '';
      _secilenDurum = '';
      _secilenOdemeDurumu = '';
      _secilenKategori = '';
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
                    labelText: 'Fatura no, firma, kalem veya aciklama ara',
                    helperText:
                        'Cari unvan, fatura bilgileri ve kalemler icinde arar',
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
                        initialValue: _secilenFaturaTuru.isEmpty
                            ? null
                            : _secilenFaturaTuru,
                        decoration: const InputDecoration(
                          labelText: 'Fatura Türü',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tümü')),
                          DropdownMenuItem(
                              value: 'satis', child: Text('Satış')),
                          DropdownMenuItem(value: 'alis', child: Text('Alış')),
                          DropdownMenuItem(value: 'iade', child: Text('İade')),
                          DropdownMenuItem(
                              value: 'proforma', child: Text('Proforma')),
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
                        initialValue:
                            _secilenDurum.isEmpty ? null : _secilenDurum,
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tümü')),
                          DropdownMenuItem(
                              value: 'taslak', child: Text('Taslak')),
                          DropdownMenuItem(
                              value: 'onaylandi', child: Text('Onaylandı')),
                          DropdownMenuItem(
                              value: 'gonderildi', child: Text('Gönderildi')),
                          DropdownMenuItem(
                              value: 'iptal', child: Text('İptal')),
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
                        initialValue: _secilenOdemeDurumu.isEmpty
                            ? null
                            : _secilenOdemeDurumu,
                        decoration: const InputDecoration(
                          labelText: 'Ödeme Durumu',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tümü')),
                          DropdownMenuItem(
                              value: 'odenmedi', child: Text('Ödenmedi')),
                          DropdownMenuItem(
                              value: 'kismi', child: Text('Kısmi Ödendi')),
                          DropdownMenuItem(
                              value: 'odendi', child: Text('Ödendi')),
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

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            _secilenKategori.isEmpty ? null : _secilenKategori,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tümü'),
                          ),
                          ...FaturaKategori.tumu.map(
                            (kategori) => DropdownMenuItem(
                              value: kategori,
                              child: Text(FaturaKategori.etiket(kategori)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _secilenKategori = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox.shrink()),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox.shrink()),
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
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
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
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
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

  Widget _buildKpiCard({
    required String title,
    required List<String> values,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...values.map(
                            (value) => Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: values.length > 1 ? 13 : 16,
                                height: 1.15,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaturaKarti(FaturaModel fatura) {
    final adminMi = context.watch<AuthProvider>().isAdmin;
    final kategoriOzetleri = fatura.faturaId == null
        ? <String>[]
        : _faturaKategoriOzetleri[fatura.faturaId!] ?? <String>[];
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
            if (fatura.cariUnvan != null && fatura.cariUnvan!.trim().isNotEmpty)
              Text(
                fatura.cariUnvan!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            if (kategoriOzetleri.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: kategoriOzetleri
                    .map(
                      (kategori) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          FaturaKategori.etiket(kategori),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrencyAmount(fatura.toplamTutar, fatura.kur),
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
            if (adminMi)
              IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _faturaSil(fatura),
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
          if (context.watch<AuthProvider>().isAdmin ||
              context.watch<AuthProvider>().isFirmaAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Tooltip(
                message: 'Uyumsoft Gelen Faturalar',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final darEkran = MediaQuery.sizeOf(context).width < 520;
                    final style = TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      padding: EdgeInsets.symmetric(
                        horizontal: darEkran ? 10 : 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                    );

                    if (darEkran) {
                      return TextButton(
                        style: style,
                        onPressed: _uyumsoftGelenFaturalariAc,
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 22,
                        ),
                      );
                    }

                    return TextButton.icon(
                      style: style,
                      onPressed: _uyumsoftGelenFaturalariAc,
                      icon: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Uyumsoft',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final ikiSutun = constraints.maxWidth < 760;
                  final satisTutarSatirlari =
                      _toplamSatirlari(_satisFaturaTutarlari);
                  final alisTutarSatirlari =
                      _toplamSatirlari(_alisFaturaTutarlari);
                  final sutunSayisi = ikiSutun ? 2 : 4;
                  final enFazlaTutarSatiri =
                      satisTutarSatirlari.length > alisTutarSatirlari.length
                          ? satisTutarSatirlari.length
                          : alisTutarSatirlari.length;
                  final kartGenisligi =
                      (constraints.maxWidth - (sutunSayisi - 1) * 8) /
                          sutunSayisi;
                  final kartYuksekligi = 72.0 +
                      (enFazlaTutarSatiri > 1
                          ? (enFazlaTutarSatiri - 1) * 16
                          : 0);
                  final kartlar = [
                    _buildKpiCard(
                      title: 'Satış Faturası',
                      values: ['$_satisFaturaAdedi'],
                      icon: Icons.trending_up,
                      color: Colors.green.shade700,
                    ),
                    _buildKpiCard(
                      title: 'Satış Tutarı',
                      values: satisTutarSatirlari,
                      icon: Icons.payments,
                      color: Colors.teal.shade700,
                    ),
                    _buildKpiCard(
                      title: 'Alış Faturası',
                      values: ['$_alisFaturaAdedi'],
                      icon: Icons.trending_down,
                      color: Colors.orange.shade800,
                    ),
                    _buildKpiCard(
                      title: 'Alış Tutarı',
                      values: alisTutarSatirlari,
                      icon: Icons.description,
                      color: Colors.red.shade700,
                    ),
                  ];

                  return GridView.count(
                    crossAxisCount: sutunSayisi,
                    childAspectRatio: kartGenisligi / kartYuksekligi,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: kartlar,
                  );
                },
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
                            Icon(Icons.description,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Henüz fatura bulunmuyor',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
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
