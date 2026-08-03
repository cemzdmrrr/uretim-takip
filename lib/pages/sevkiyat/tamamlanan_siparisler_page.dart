import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/widgets/responsive_horizontal_table.dart';

class TamamlananSiparislerPage extends StatefulWidget {
  const TamamlananSiparislerPage({Key? key}) : super(key: key);

  @override
  State<TamamlananSiparislerPage> createState() =>
      _TamamlananSiparislerPageState();
}

class _TamamlananSiparislerPageState extends State<TamamlananSiparislerPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tamamlananlar = [];
  String arama = '';
  bool yukleniyor = true;
  bool tarihArtan = true;

  // Seçili modellerin id'leri
  Set<String> seciliModelIdler = {};
  // Filtre seçenekleri
  String? seciliMarka;
  String? seciliModel;
  String? seciliRenk;
  String? seciliIplikCinsi;

  @override
  void initState() {
    super.initState();
    tamamlananlariGetir();
  }

  Future<void> tamamlananlariGetir() async {
    setState(() => yukleniyor = true);

    try {
      final response = await supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      final List<Map<String, dynamic>> liste =
          List<Map<String, dynamic>>.from(response);

      await _yuklemeKayitlariniEkle(liste);
      liste.removeWhere(
        (model) =>
            (model[DbTables.yuklemeKayitlari] as List? ?? const []).isEmpty,
      );

      debugPrint('========== TAMAMLANAN SİPARİŞLER ==========');
      debugPrint('Tamamlanan siparişler sayısı: ${liste.length}');
      for (var item in liste) {
        debugPrint(
            '✅ Tamamlanan: ${item['item_no']} - tamamlandi: ${item['tamamlandi']} - durum: ${item['durum']} - ID: ${item['id']}');
      }
      debugPrint('=========================================');

      liste.sort((a, b) {
        final tarihA =
            DateTime.tryParse(a['yukleme_tarihi'] ?? '') ?? DateTime(2000);
        final tarihB =
            DateTime.tryParse(b['yukleme_tarihi'] ?? '') ?? DateTime(2000);
        return tarihArtan ? tarihA.compareTo(tarihB) : tarihB.compareTo(tarihA);
      });

      setState(() {
        tamamlananlar = liste;
      });
    } catch (e) {
      debugPrint('Hata: $e');
    } finally {
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _yuklemeKayitlariniEkle(
      List<Map<String, dynamic>> modeller) async {
    if (modeller.isEmpty) return;

    try {
      final modelIdleri = modeller.map((m) => m['id'].toString()).toList();
      final response = await supabase
          .from(DbTables.yuklemeKayitlari)
          .select('id, model_id, adet, tarih')
          .inFilter('model_id', modelIdleri);

      final kayitlar = List<Map<String, dynamic>>.from(response);
      final kayitlarByModel = <String, List<Map<String, dynamic>>>{};
      for (final kayit in kayitlar) {
        final modelId = kayit['model_id']?.toString();
        if (modelId == null) continue;
        kayitlarByModel.putIfAbsent(modelId, () => []).add(kayit);
      }

      for (final model in modeller) {
        final modelKayitlari =
            kayitlarByModel[model['id'].toString()] ?? <Map<String, dynamic>>[];
        modelKayitlari.sort(
          (a, b) => (b['tarih'] ?? '').toString().compareTo(
                (a['tarih'] ?? '').toString(),
              ),
        );
        model[DbTables.yuklemeKayitlari] = modelKayitlari;
        model['yuklenen_adet'] = modelKayitlari.fold<int>(
          0,
          (toplam, kayit) => toplam + ((kayit['adet'] as num?)?.toInt() ?? 0),
        );
        model['yukleme_tarihi'] =
            modelKayitlari.isEmpty ? null : modelKayitlari.first['tarih'];
      }
    } catch (e) {
      debugPrint('Yükleme kayıtları eklenemedi: $e');
      for (final model in modeller) {
        model[DbTables.yuklemeKayitlari] = <Map<String, dynamic>>[];
      }
    }
  }

  Future<void> exportToExcel(List<Map<String, dynamic>> data,
      {required String fileName}) async {
    try {
      await ExcelHelper.exportToExcel(
        data: data,
        fileName: fileName,
        columns: {
          'marka': 'Marka',
          'item_no': 'Item No',
          'renk': 'Renk',
          'urun_cinsi': 'Ürün',
          'iplik_cinsi': 'İplik Cinsi',
          'uretici': 'Üretici',
          'adet': 'Sipariş Adedi',
          'yuklenen_adet': 'Yüklenen Adet',
          'termin': 'Termin',
          'orgu_firma': 'Örgü Firma',
          'orgu_bitis': 'Örgü Bitiş',
          'konfeksiyon_firma': 'Konfeksiyon Firma',
          'konfeksiyon_bitis': 'Konfeksiyon Bitiş',
          'utu_firma': 'Ütü Firma',
          'utu_bitis': 'Ütü Bitiş',
          'tamamlanma_tarihi': 'Tamamlanma Tarihi'
        },
      );
      if (mounted) {
        context.showSuccessSnackBar('Excel dosyası başarıyla oluşturuldu');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Excel oluşturulurken hata: $e');
      }
    }
  }

  // Dinamik filtreler için yardımcılar
  List<String> getMarkalar() => tamamlananlar
      .map((m) => m['marka']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();
  List<String> getModeller() {
    final filtered = seciliMarka != null && seciliMarka!.isNotEmpty
        ? tamamlananlar.where((m) => m['marka'] == seciliMarka)
        : tamamlananlar;
    return filtered
        .map((m) => m['item_no']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> getRenkler() {
    final filtered = seciliModel != null && seciliModel!.isNotEmpty
        ? tamamlananlar.where((m) => m['item_no'] == seciliModel)
        : tamamlananlar;
    return filtered
        .map((m) => m['renk']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> getIplikCinsleri() => tamamlananlar
      .map((m) => m['iplik_cinsi']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  // Excel için tarih sütunu düzeltildi
  Future<void> exportSeciliToExcel() async {
    final secili =
        filtreli.where((m) => seciliModelIdler.contains(m['id'])).toList();
    if (secili.isEmpty) return;
    final data = secili.map((m) {
      String? tarih = m['yukleme_tarihi'];
      if (tarih == null || tarih.isEmpty) {
        // En son yükleme kaydının tarihini al
        final kayitlar = (m[DbTables.yuklemeKayitlari] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        if (kayitlar.isNotEmpty) {
          kayitlar
              .sort((a, b) => (b['tarih'] ?? '').compareTo(a['tarih'] ?? ''));
          tarih = kayitlar.first['tarih'];
        }
      }
      String tarihStr = '';
      if (tarih != null && tarih.isNotEmpty) {
        final dt = DateTime.tryParse(tarih);
        if (dt != null) {
          tarihStr = DateFormat('dd.MM.yyyy').format(dt.toLocal());
        }
      }
      return {
        'marka': m['marka'],
        'item_no': m['item_no'],
        'renk': m['renk'],
        'adet': m['adet'],
        'yuklenen_adet': m['yuklenen_adet'],
        'yukleme_tarihi': tarihStr,
      };
    }).toList();
    await ExcelHelper.exportToExcel(
      data: data,
      fileName: 'Secili_Tamamlanan_Siparisler',
      columns: {
        'marka': 'Marka',
        'item_no': 'Model',
        'renk': 'Renk',
        'adet': 'Adet',
        'yuklenen_adet': 'Yüklenen Adet',
        'yukleme_tarihi': 'Tarih',
      },
    );
    if (mounted) {
      context.showSuccessSnackBar('Excel dosyası başarıyla oluşturuldu');
    }
  }

  void tumunuSec(bool sec) {
    setState(() {
      if (sec) {
        seciliModelIdler = filtreli.map((m) => m['id'].toString()).toSet();
      } else {
        seciliModelIdler.clear();
      }
    });
  }

  List<Map<String, dynamic>> get filtreli {
    return tamamlananlar.where((model) {
      final marka = (model['marka'] ?? '').toString().toLowerCase();
      final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
      final query = arama.toLowerCase();
      if (seciliMarka != null &&
          seciliMarka!.isNotEmpty &&
          model['marka'] != seciliMarka) {
        return false;
      }
      if (seciliModel != null &&
          seciliModel!.isNotEmpty &&
          model['item_no'] != seciliModel) {
        return false;
      }
      if (seciliRenk != null &&
          seciliRenk!.isNotEmpty &&
          model['renk'] != seciliRenk) {
        return false;
      }
      if (seciliIplikCinsi != null &&
          seciliIplikCinsi!.isNotEmpty &&
          model['iplik_cinsi'] != seciliIplikCinsi) {
        return false;
      }
      return marka.contains(query) || itemNo.contains(query);
    }).toList();
  }

  String _tarihMetni(dynamic value) {
    final tarih = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return tarih == null ? '-' : DateFormat('dd.MM.yyyy').format(tarih);
  }

  int _siparisAdedi(Map<String, dynamic> model) =>
      (model['adet'] as num?)?.toInt() ?? 0;

  int _yuklenenAdet(Map<String, dynamic> model) =>
      (model['yuklenen_adet'] as num?)?.toInt() ?? 0;

  Future<void> _yuklemeDetaylariniGoster(
    Map<String, dynamic> model,
  ) async {
    final kayitlar = List<Map<String, dynamic>>.from(
      model[DbTables.yuklemeKayitlari] as List? ?? const [],
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}'),
        content: SizedBox(
          width: 520,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: kayitlar.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final kayit = kayitlar[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text('${kayit['adet'] ?? 0} adet'),
                trailing: Text(_tarihMetni(kayit['tarih'])),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildTamamlananlarListesi() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return ListView.separated(
            itemCount: filtreli.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final model = filtreli[index];
              final siparis = _siparisAdedi(model);
              final yuklenen = _yuklenenAdet(model);
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: Checkbox(
                    value: seciliModelIdler.contains(model['id'].toString()),
                    onChanged: (value) => _modelSeciminiDegistir(model, value),
                  ),
                  title: Text(
                    '${model['marka'] ?? '-'} - ${model['item_no'] ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Yüklenen: $yuklenen adet • Sipariş: $siparis adet\n'
                    'Son yükleme: ${_tarihMetni(model['yukleme_tarihi'])}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Yükleme detayları',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _yuklemeDetaylariniGoster(model),
                  ),
                ),
              );
            },
          );
        }

        return SingleChildScrollView(
          child: ResponsiveHorizontalTable(
            minWidth: 1250,
            showScrollbar: true,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text('Seç')),
                DataColumn(label: Text('Marka')),
                DataColumn(label: Text('Model / Item No')),
                DataColumn(label: Text('Renk')),
                DataColumn(label: Text('Sipariş Adedi'), numeric: true),
                DataColumn(label: Text('Yüklenen Adet'), numeric: true),
                DataColumn(label: Text('Kalan'), numeric: true),
                DataColumn(label: Text('Yükleme Sayısı'), numeric: true),
                DataColumn(label: Text('Son Yükleme')),
                DataColumn(label: Text('İşlem')),
              ],
              rows: filtreli.map((model) {
                final siparis = _siparisAdedi(model);
                final yuklenen = _yuklenenAdet(model);
                final kayitSayisi =
                    (model[DbTables.yuklemeKayitlari] as List? ?? const [])
                        .length;
                return DataRow(
                  selected: seciliModelIdler.contains(model['id'].toString()),
                  cells: [
                    DataCell(
                      Checkbox(
                        value:
                            seciliModelIdler.contains(model['id'].toString()),
                        onChanged: (value) =>
                            _modelSeciminiDegistir(model, value),
                      ),
                    ),
                    DataCell(Text(model['marka']?.toString() ?? '-')),
                    DataCell(Text(model['item_no']?.toString() ?? '-')),
                    DataCell(Text(model['renk']?.toString() ?? '-')),
                    DataCell(Text('$siparis')),
                    DataCell(
                      Text(
                        '$yuklenen',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    DataCell(Text('${(siparis - yuklenen).clamp(0, siparis)}')),
                    DataCell(Text('$kayitSayisi')),
                    DataCell(Text(_tarihMetni(model['yukleme_tarihi']))),
                    DataCell(
                      IconButton(
                        tooltip: 'Yükleme detayları',
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _yuklemeDetaylariniGoster(model),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _modelSeciminiDegistir(
    Map<String, dynamic> model,
    bool? secili,
  ) {
    setState(() {
      final id = model['id'].toString();
      if (secili == true) {
        seciliModelIdler.add(id);
      } else {
        seciliModelIdler.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Toplam model ve toplam adet hesapla
    final toplamModel = filtreli.length;
    final toplamAdet = filtreli.fold<int>(
        0, (sum, m) => sum + ((m['yuklenen_adet'] ?? 0) as num).toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamamlanan Siparişler'),
        // actions kaldırıldı
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kIsWeb ? 1600 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(kIsWeb ? 32 : 12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Marka veya Item No ile Ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => arama = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Tarihe Göre: '),
                    Switch(
                      value: tarihArtan,
                      onChanged: (val) {
                        setState(() {
                          tarihArtan = val;
                          tamamlananlariGetir();
                        });
                      },
                    ),
                    Text(tarihArtan ? 'Artan' : 'Azalan'),
                  ],
                ),
                const SizedBox(height: 10),
                // Toplam model ve adet bilgisi üstte göster
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Toplam Model: $toplamModel',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Toplam Adet: $toplamAdet',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filtreleme seçenekleri
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: seciliMarka,
                            isDense: true,
                            decoration: const InputDecoration(
                                labelText: 'Marka',
                                border: OutlineInputBorder()),
                            items: getMarkalar()
                                .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                seciliMarka = v;
                                seciliModel = null;
                                seciliRenk = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: seciliModel,
                            isDense: true,
                            decoration: const InputDecoration(
                                labelText: 'Model',
                                border: OutlineInputBorder()),
                            items: getModeller()
                                .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                seciliModel = v;
                                seciliRenk = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: seciliRenk,
                            isDense: true,
                            decoration: const InputDecoration(
                                labelText: 'Renk',
                                border: OutlineInputBorder()),
                            items: getRenkler()
                                .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setState(() => seciliRenk = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: seciliIplikCinsi,
                            isDense: true,
                            decoration: const InputDecoration(
                                labelText: 'İplik Cinsi',
                                border: OutlineInputBorder()),
                            items: getIplikCinsleri()
                                .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => seciliIplikCinsi = v),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() {
                          seciliMarka = null;
                          seciliModel = null;
                          seciliRenk = null;
                          seciliIplikCinsi = null;
                        }),
                        child: const Text('Filtreleri Temizle'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Seçim ve Excel butonu
                Row(
                  children: [
                    Checkbox(
                      value: seciliModelIdler.length == filtreli.length &&
                          filtreli.isNotEmpty,
                      tristate: true,
                      onChanged: (v) => tumunuSec(v ?? false),
                    ),
                    const Text('Tümünü Seç'),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_copy),
                      label: const Text("Excel'e Aktar"),
                      onPressed: seciliModelIdler.isNotEmpty
                          ? exportSeciliToExcel
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: yukleniyor
                      ? const LoadingWidget()
                      : filtreli.isEmpty
                          ? const Center(
                              child: Text('Tamamlanan sipariş bulunamadı'))
                          : _buildTamamlananlarListesi(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
