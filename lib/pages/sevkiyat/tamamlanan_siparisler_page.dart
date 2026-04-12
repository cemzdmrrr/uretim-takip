import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uretim_takip/services/tenant_manager.dart';

class TamamlananSiparislerPage extends StatefulWidget {
  const TamamlananSiparislerPage({Key? key}) : super(key: key);

  @override
  State<TamamlananSiparislerPage> createState() => _TamamlananSiparislerPageState();
}

class _TamamlananSiparislerPageState extends State<TamamlananSiparislerPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tamamlananlar = [];
  String arama = '';
  bool yukleniyor = true;
  bool tarihArtan = true;

  // Seçili modellerin id'leri
  Set<int> seciliModelIdler = {};
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
          .select('''
            *,
            yukleme_kayitlari (
              id,
              adet,
              tarih
            )
          ''')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .eq('tamamlandi', true);

      final List<Map<String, dynamic>> liste = List<Map<String, dynamic>>.from(response);
      
      debugPrint('========== TAMAMLANAN SİPARİŞLER ==========');
      debugPrint('Tamamlanan siparişler sayısı: ${liste.length}');
      for (var item in liste) {
        debugPrint('✅ Tamamlanan: ${item['item_no']} - tamamlandi: ${item['tamamlandi']} - ID: ${item['id']}');
      }
      debugPrint('=========================================');

      liste.sort((a, b) {
        final tarihA = DateTime.tryParse(a['yukleme_tarihi'] ?? '') ?? DateTime(2000);
        final tarihB = DateTime.tryParse(b['yukleme_tarihi'] ?? '') ?? DateTime(2000);
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

  Future<void> exportToExcel(List<Map<String, dynamic>> data, {required String fileName}) async {
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
  List<String> getMarkalar() => tamamlananlar.map((m) => m['marka']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList();
  List<String> getModeller() {
    final filtered = seciliMarka != null && seciliMarka!.isNotEmpty
        ? tamamlananlar.where((m) => m['marka'] == seciliMarka)
        : tamamlananlar;
    return filtered.map((m) => m['item_no']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList();
  }
  List<String> getRenkler() {
    final filtered = seciliModel != null && seciliModel!.isNotEmpty
        ? tamamlananlar.where((m) => m['item_no'] == seciliModel)
        : tamamlananlar;
    return filtered.map((m) => m['renk']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList();
  }
  List<String> getIplikCinsleri() => tamamlananlar.map((m) => m['iplik_cinsi']?.toString() ?? '').where((e) => e.isNotEmpty).toSet().toList();

  // Excel için tarih sütunu düzeltildi
  Future<void> exportSeciliToExcel() async {
    final secili = filtreli.where((m) => seciliModelIdler.contains(m['id'])).toList();
    if (secili.isEmpty) return;
    final data = secili.map((m) {
      String? tarih = m['yukleme_tarihi'];
      if (tarih == null || tarih.isEmpty) {
        // En son yükleme kaydının tarihini al
        final kayitlar = (m[DbTables.yuklemeKayitlari] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (kayitlar.isNotEmpty) {
          kayitlar.sort((a, b) => (b['tarih'] ?? '').compareTo(a['tarih'] ?? ''));
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
        seciliModelIdler = filtreli.map((m) => m['id'] as int).toSet();
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
      if (seciliMarka != null && seciliMarka!.isNotEmpty && model['marka'] != seciliMarka) return false;
      if (seciliModel != null && seciliModel!.isNotEmpty && model['item_no'] != seciliModel) return false;
      if (seciliRenk != null && seciliRenk!.isNotEmpty && model['renk'] != seciliRenk) return false;
      if (seciliIplikCinsi != null && seciliIplikCinsi!.isNotEmpty && model['iplik_cinsi'] != seciliIplikCinsi) return false;
      return marka.contains(query) || itemNo.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Toplam model ve toplam adet hesapla
    final toplamModel = filtreli.length;
    final toplamAdet = filtreli.fold<int>(0, (sum, m) => sum + ((m['yuklenen_adet'] ?? 0) as num).toInt());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamamlanan Siparişler'),
        // actions kaldırıldı
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kIsWeb ? 700 : double.infinity,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Toplam Adet: $toplamAdet',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            decoration: const InputDecoration(labelText: 'Marka', border: OutlineInputBorder()),
                            items: getMarkalar().map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
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
                            decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
                            items: getModeller().map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
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
                            decoration: const InputDecoration(labelText: 'Renk', border: OutlineInputBorder()),
                            items: getRenkler().map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => seciliRenk = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: seciliIplikCinsi,
                            isDense: true,
                            decoration: const InputDecoration(labelText: 'İplik Cinsi', border: OutlineInputBorder()),
                            items: getIplikCinsleri().map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => seciliIplikCinsi = v),
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
                      value: seciliModelIdler.length == filtreli.length && filtreli.isNotEmpty,
                      tristate: true,
                      onChanged: (v) => tumunuSec(v ?? false),
                    ),
                    const Text('Tümünü Seç'),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_copy),
                      label: const Text("Excel'e Aktar"),
                      onPressed: seciliModelIdler.isNotEmpty ? exportSeciliToExcel : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: yukleniyor
                      ? const LoadingWidget()
                      : filtreli.isEmpty
                          ? const Center(child: Text('Tamamlanan sipariş bulunamadı'))
                          : ListView.builder(
                              itemCount: filtreli.length,
                              itemBuilder: (context, index) {
                                final m = filtreli[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ExpansionTile(
                                    leading: Checkbox(
                                      value: seciliModelIdler.contains(m['id']),
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            seciliModelIdler.add(m['id'] as int);
                                          } else {
                                            seciliModelIdler.remove(m['id'] as int);
                                          }
                                        });
                                      },
                                    ),
                                    // Renk bilgisi de başlıkta göster
                                    title: Text("${m['marka']} - ${m['item_no']} (${m['renk'] ?? '-'})"),
                                    subtitle: Text("Toplam Adet: ${m['adet']} | Yüklenen: ${m['yuklenen_adet']}", maxLines: 2),
                                    children: [
                                      if (m[DbTables.yuklemeKayitlari] != null)
                                        ...List<Map<String, dynamic>>.from(m[DbTables.yuklemeKayitlari]).map((yukleme) {
                                          final yuklemeTarihi = DateTime.tryParse(yukleme['tarih'])?.toLocal();
                                          return ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.local_shipping, size: 20),
                                            title: Text(
                                              "Adet: ${yukleme['adet']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            trailing: Text(
                                              yuklemeTarihi != null 
                                                ? DateFormat('dd.MM.yyyy').format(yuklemeTarihi)
                                                : '-',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                      const Divider(),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.undo, color: Colors.orange),
                                            tooltip: 'Modeli geri al',
                                            onPressed: () async {
                                              final onay = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('Geri Alma Onayı'),
                                                  content: const Text('Bu modeli aktif listeye geri almak istiyor musunuz?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
                                                  ],
                                                ),
                                              );

                                              if (onay == true) {
                                                await supabase
                                                    .from(DbTables.trikoTakip)
                                                    .update({'tamamlandi': false})
                                                    .eq('id', m['id']);

                                                if (!context.mounted) return;
                                                context.showSnackBar('Model geri alındı');

                                                await tamamlananlariGetir(); // listeyi yenile
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
