import 'package:flutter/material.dart' hide Border;
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:uretim_takip/utils/web_download.dart';
import 'package:flutter/painting.dart' show Border, BorderSide;
import 'package:uretim_takip/services/tenant_manager.dart';

part 'stok_yonetimi_aksesuarlar_dialog.dart';


class StokYonetimiAksesuarlarCokluBeden extends StatefulWidget {
  const StokYonetimiAksesuarlarCokluBeden({super.key});

  @override
  State<StokYonetimiAksesuarlarCokluBeden> createState() => _StokYonetimiAksesuarlarCokluBedenState();
}

class _StokYonetimiAksesuarlarCokluBedenState extends State<StokYonetimiAksesuarlarCokluBeden> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> aksesuarlar = [];
  // Aksesuar ID -> Model kullanım listesi (model_adi, toplam_adet, adet_per_model)
  Map<String, List<Map<String, dynamic>>> _modelKullanimlari = {};
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAksesuarlar();
  }

  Future<void> _loadAksesuarlar() async {
    try {
      setState(() => isLoading = true);
      
      final firmaId = TenantManager.instance.requireFirmaId;
      
      // Aksesuarları ve bedenlerini birleştirip getir
      final response = await supabase
          .from(DbTables.aksesuarlar)
          .select('''
            *,
            aksesuar_bedenler (
              id,
              beden,
              stok_miktari,
              durum
            )
          ''')
          .eq('durum', 'aktif')
          .order('created_at', ascending: false);

      // Model-aksesuar ilişkilerini yükle
      final modelAksesuarResponse = await supabase
          .from(DbTables.modelAksesuar)
          .select('aksesuar_id, adet_per_model, miktar, model_id')
          .eq('firma_id', firmaId);

      // İlgili model ID'lerini topla ve model bilgilerini çek
      final modelIds = <String>{};
      for (var ma in modelAksesuarResponse) {
        final modelId = ma['model_id']?.toString();
        if (modelId != null) modelIds.add(modelId);
      }

      Map<String, Map<String, dynamic>> modelBilgileri = {};
      if (modelIds.isNotEmpty) {
        final modellerResponse = await supabase
            .from(DbTables.trikoTakip)
            .select('id, model_adi, toplam_adet, adet, durum, bedenler')
            .inFilter('id', modelIds.toList());

        for (var model in modellerResponse) {
          modelBilgileri[model['id'].toString()] = model;
        }
      }

      // Aksesuar bazında model kullanımlarını grupla
      final Map<String, List<Map<String, dynamic>>> kullanimMap = {};
      for (var ma in modelAksesuarResponse) {
        final aksesuarId = ma['aksesuar_id']?.toString();
        final modelId = ma['model_id']?.toString();
        if (aksesuarId == null || modelId == null) continue;

        final model = modelBilgileri[modelId];
        if (model == null) continue;

        final modelAdi = model['model_adi']?.toString() ?? 'Bilinmeyen Model';
        final int modelAdet = (model['toplam_adet'] ?? model['adet'] ?? 0) as int;
        final int adetPerModel = (ma['adet_per_model'] ?? ma['miktar'] ?? 1) as int;
        final String durum = model['durum']?.toString() ?? '';
        final Map<String, dynamic> modelBedenler = 
            (model['bedenler'] as Map<String, dynamic>?) ?? {};

        kullanimMap.putIfAbsent(aksesuarId, () => []);
        kullanimMap[aksesuarId]!.add({
          'model_id': modelId,
          'model_adi': modelAdi,
          'model_adet': modelAdet,
          'adet_per_model': adetPerModel,
          'gereken_adet': modelAdet * adetPerModel,
          'durum': durum,
          'bedenler': modelBedenler,
        });
      }

      setState(() {
        aksesuarlar = List<Map<String, dynamic>>.from(response);
        _modelKullanimlari = kullanimMap;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Aksesuarlar yükleme hatası: $e');
      setState(() => isLoading = false);
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  /// Tüm modellerin bu aksesuardan toplam talep ettiği adet
  int _getToplamTalep(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return 0;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return 0;
    return kullanimlar.fold(0, (sum, k) => sum + (k['gereken_adet'] as int));
  }

  /// Aksesuar beden adları model beden anahtarlarıyla eşleşiyor mu?
  bool _hasBedenEslesmesi(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return false;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return false;
    
    final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
    for (var beden in bedenler) {
      if (beden['durum'] != 'aktif') continue;
      final bedenAdi = beden['beden']?.toString() ?? '';
      for (var k in kullanimlar) {
        final modelBedenler = k['bedenler'] as Map<String, dynamic>? ?? {};
        if (modelBedenler.containsKey(bedenAdi)) return true;
      }
    }
    return false;
  }

  /// Belirli bir beden için tüm modellerden gelen talep
  /// Eşleşme varsa: model.bedenler[bedenAdi] * adet_per_model
  /// Eşleşme yoksa: toplam talep / aktif beden sayısı (eşit dağılım)
  int _getBedenTalep(Map<String, dynamic> aksesuar, String bedenAdi) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return 0;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return 0;

    // Beden eşleşmesi varsa direkt hesapla
    if (_hasBedenEslesmesi(aksesuar)) {
      int toplam = 0;
      for (var k in kullanimlar) {
        final modelBedenler = k['bedenler'] as Map<String, dynamic>? ?? {};
        final adetPerModel = k['adet_per_model'] as int? ?? 1;
        final bedenAdet = (modelBedenler[bedenAdi] as num?)?.toInt() ?? 0;
        toplam += bedenAdet * adetPerModel;
      }
      return toplam;
    }

    // Eşleşme yoksa toplam talebi aktif bedenler arasında eşit dağıt
    final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
    final aktifBedenSayisi = bedenler.where((b) => b['durum'] == 'aktif').length;
    if (aktifBedenSayisi == 0) return 0;
    final toplamTalep = _getToplamTalep(aksesuar);
    return (toplamTalep / aktifBedenSayisi).ceil();
  }

  /// Stok yeterli mi? Çoklu beden aksesuarlar için beden bazlı kontrol
  bool _isStokYeterli(Map<String, dynamic> aksesuar) {
    final aksesuarId = aksesuar['id']?.toString();
    if (aksesuarId == null) return true;
    final kullanimlar = _modelKullanimlari[aksesuarId];
    if (kullanimlar == null || kullanimlar.isEmpty) return true;
    
    final bedenler = aksesuar['aksesuar_bedenler'] as List? ?? [];
    final aktifBedenler = bedenler.where((b) => b['durum'] == 'aktif').toList();
    
    if (aktifBedenler.isNotEmpty) {
      if (_hasBedenEslesmesi(aksesuar)) {
        // Beden adları eşleşiyor: her bedeni ayrı kontrol et
        for (var beden in aktifBedenler) {
          final bedenAdi = beden['beden']?.toString() ?? '';
          final stok = (beden['stok_miktari'] as int? ?? 0);
          final talep = _getBedenTalep(aksesuar, bedenAdi);
          if (talep > 0 && stok < talep) return false;
        }
        return true;
      } else {
        // Beden adları eşleşmiyor: toplam stok vs toplam talep
        final toplamTalep = _getToplamTalep(aksesuar);
        if (toplamTalep == 0) return true;
        return _getTotalStock(aksesuar) >= toplamTalep;
      }
    }
    
    // Bedensiz aksesuar: toplam kontrol
    final toplamTalep = _getToplamTalep(aksesuar);
    if (toplamTalep == 0) return true;
    return _getTotalStock(aksesuar) >= toplamTalep;
  }

  List<Map<String, dynamic>> get filteredAksesuarlar {
    if (searchQuery.isEmpty) return aksesuarlar;
    
    return aksesuarlar.where((aksesuar) {
      final ad = aksesuar['ad']?.toString().toLowerCase() ?? '';
      final marka = aksesuar['marka']?.toString().toLowerCase() ?? '';
      final sku = aksesuar['sku']?.toString().toLowerCase() ?? '';
      final renk = aksesuar['renk']?.toString().toLowerCase() ?? '';
      
      return ad.contains(searchQuery.toLowerCase()) ||
             marka.contains(searchQuery.toLowerCase()) ||
             sku.contains(searchQuery.toLowerCase()) ||
             renk.contains(searchQuery.toLowerCase());
    }).toList();
  }



  Widget _buildStokCard(Map<String, dynamic> aksesuar) {
    final totalStock = _getTotalStock(aksesuar);
    final toplamTalep = _getToplamTalep(aksesuar);
    final stokYeterli = _isStokYeterli(aksesuar);
    final aksesuarId = aksesuar['id']?.toString();
    final kullanimlar = aksesuarId != null ? _modelKullanimlari[aksesuarId] ?? [] : <Map<String, dynamic>>[];
    final eksikAdet = toplamTalep > totalStock ? toplamTalep - totalStock : 0;

    // Renk durumu: talep varsa talep bazlı, yoksa minimum_stok bazlı
    final bool isLowStock = toplamTalep > 0
        ? !stokYeterli
        : totalStock < (aksesuar['minimum_stok'] ?? 10);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory,
              color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
          title: Text(
            aksesuar['ad'] ?? 'Adsız Aksesuar',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SKU: ${aksesuar['sku'] ?? 'Yok'}'),
              Text('Marka: ${aksesuar['marka'] ?? 'Belirtilmemiş'}'),
              Row(
                children: [
                  Text(
                    'Stok: $totalStock',
                    style: TextStyle(
                      color: isLowStock ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (toplamTalep > 0) ...[
                    Text(
                      ' / Talep: $toplamTalep',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' (${kullanimlar.length} model)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (isLowStock) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    Text(
                      toplamTalep > 0 ? ' $eksikAdet adet eksik' : ' Düşük Stok',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.output_rounded, color: Colors.orange),
                onPressed: () => _showSarfDialog(aksesuar),
                tooltip: 'Sarf',
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showAddEditDialog(aksesuar: aksesuar),
                tooltip: 'Düzenle',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteAksesuar(aksesuar),
                tooltip: 'Sil',
              ),
            ],
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                final stokYeterli = _isStokYeterli(aksesuar);
                return Dialog(
                  insetPadding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory, color: isLowStock ? Colors.red.shade700 : Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              aksesuar['ad'] ?? 'Adsız Aksesuar',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('SKU: ${aksesuar['sku'] ?? 'Yok'}'),
                        Text('Marka: ${aksesuar['marka'] ?? 'Belirtilmemiş'}'),
                        Text('Renk: ${aksesuar['renk'] ?? '-'}'),
                        const Divider(),
                        Row(
                          children: [
                            _buildMiniInfo('Mevcut Stok', '$totalStock', Colors.green),
                            const SizedBox(width: 12),
                            _buildMiniInfo('Toplam Talep', '$toplamTalep', Colors.blue),
                            const SizedBox(width: 12),
                            _buildMiniInfo(
                              stokYeterli ? 'Fazla' : 'Eksik',
                              stokYeterli ? '${totalStock - toplamTalep}' : '$eksikAdet',
                              stokYeterli ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (kullanimlar.isNotEmpty) ...[
                          Text('Model Bazlı Talep Analizi', style: TextStyle(fontWeight: FontWeight.bold, color: stokYeterli ? Colors.blue.shade800 : Colors.red.shade800)),
                          const SizedBox(height: 8),
                          ...kullanimlar.map((k) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.label, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${k['model_adi']} - ${k['gereken_adet']} adet',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Kapat'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${k['model_adet']} adet × ${k['adet_per_model']}/model',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '= $gerekenAdet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Uyarı mesajı
                  if (!stokYeterli)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stok yetersiz! Tüm modeller için $eksikAdet adet daha tedarik edilmeli.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (stokYeterli && toplamTalep > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stok yeterli. ${totalStock - toplamTalep} adet fazla stok mevcut.',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Beden Detayları:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (aksesuar['aksesuar_bedenler'] != null && 
                    (aksesuar['aksesuar_bedenler'] as List).isNotEmpty)
                  ...((aksesuar['aksesuar_bedenler'] as List)
                      .where((beden) => beden['durum'] == 'aktif')
                      .map((beden) {
                        final bedenAdi = beden['beden']?.toString() ?? '';
                        final stok = (beden['stok_miktari'] as int? ?? 0);
                        final bedenTalep = _getBedenTalep(aksesuar, bedenAdi);
                        final bedenYeterli = bedenTalep == 0 || stok >= bedenTalep;
                        final bedenEksik = bedenTalep > stok ? bedenTalep - stok : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  bedenAdi,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              if (bedenTalep > 0) ...[
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (stok / bedenTalep).clamp(0.0, 1.0),
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        bedenYeterli ? Colors.green : Colors.red,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    '$stok / $bedenTalep ${bedenYeterli ? '✓' : '($bedenEksik eksik)'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: bedenYeterli ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: Text(
                                    '$stok adet',
                                    style: TextStyle(
                                      color: stok > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }))
                else
                  const Text(
                    'Beden bilgisi yok',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                
                if (aksesuar['renk'] != null || aksesuar['malzeme'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (aksesuar['renk'] != null)
                    Text('Renk: ${aksesuar['renk']}'),
                  if (aksesuar['malzeme'] != null)
                    Text('Malzeme: ${aksesuar['malzeme']}'),
                  if (aksesuar['birim_fiyat'] != null && aksesuar['birim_fiyat'] > 0)
                    Text('Birim Fiyat: ${aksesuar['birim_fiyat']} TL'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  void _deleteAksesuar(Map<String, dynamic> aksesuar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aksesuar Sil'),
        content: Text('${aksesuar['ad']} adlı aksesuarı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Önce bedenlerini sil
                await supabase.from(DbTables.aksesuarBedenler)
                    .delete()
                    .eq('aksesuar_id', aksesuar['id']);
                
                // Sonra ana kaydı sil
                await supabase.from(DbTables.aksesuarlar)
                    .delete()
                    .eq('id', aksesuar['id']);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                context.showSuccessSnackBar('Aksesuar başarıyla silindi');
                
                await _loadAksesuarlar();
                
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                context.showErrorSnackBar('Hata: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Arama ve ekleme bölümü
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Aksesuar ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Aksesuar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Excel işlemleri
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadExcelTemplate,
                        icon: const Icon(Icons.download),
                        label: const Text('Excel Şablonu İndir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _importFromExcel,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Excel\'den İçe Aktar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // İstatistikler
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${filteredAksesuarlar.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Toplam Aksesuar'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${filteredAksesuarlar.where((a) {
                        final talep = _getToplamTalep(a);
                        if (talep > 0) return !_isStokYeterli(a);
                        return _getTotalStock(a) < (a['minimum_stok'] ?? 10);
                      }).length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const Text('Yetersiz Stok'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${filteredAksesuarlar.fold(0, (sum, a) => sum + _getTotalStock(a))}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text('Toplam Stok'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${filteredAksesuarlar.fold(0, (sum, a) => sum + _getToplamTalep(a))}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Text('Toplam Talep'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Aksesuar listesi
          Expanded(
            child: isLoading
                ? const LoadingWidget()
                : filteredAksesuarlar.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz aksesuar eklenmemiş',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAksesuarlar.length,
                        itemBuilder: (context, index) {
                          return _buildStokCard(filteredAksesuarlar[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Excel şablonu oluşturma
  Future<void> _downloadExcelTemplate() async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Aksesuar_Sablonu'];
      
      // Başlık satırı
      final headers = [
        'SKU Kodu*',
        'Aksesuar Adı*', 
        'Marka',
        'Renk',
        'Renk Kodu',
        'Birim',
        'Birim Fiyat',
        'Malzeme',
        'Minimum Stok',
        'Açıklama',
        'Beden 1*',
        'Beden 1 Stok',
        'Beden 2',
        'Beden 2 Stok',
        'Beden 3',
        'Beden 3 Stok',
        'Beden 4',
        'Beden 4 Stok',
        'Beden 5',
        'Beden 5 Stok'
      ];
      
      // Başlıkları ekle
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        cell.cellStyle = xl.CellStyle(
          backgroundColorHex: '#0066CC',
          fontColorHex: '#FFFFFF',
          bold: true,
        );
      }
      
      // Örnek satır ekle
      final exampleData = [
        'AKS001',
        'Örnek Düğme',
        'Coats',
        'Mavi',
        '#0000FF', 
        'adet',
        '2.50',
        'Plastik',
        '50',
        'Örnek açıklama',
        'S',
        '100',
        'M',
        '150',
        'L',
        '120',
        '',
        '',
        '',
        ''
      ];
      
      for (int i = 0; i < exampleData.length; i++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
        cell.value = exampleData[i];
      }
      
      // Açıklama sayfası ekle
      final instructionSheet = excel['Kullanim_Kilavuzu'];
      final instructions = [
        'AKSESUAR TOPLU EKLEME ŞABLONU KULLANIM KILAVUZU',
        '',
        'ZORUNLU ALANLAR (*):',
        '• SKU Kodu: Benzersiz ürün kodu',
        '• Aksesuar Adı: Ürün adı',
        '• Beden 1: En az bir beden bilgisi zorunlu',
        '',
        'DİĞER ALANLAR:',
        '• Marka: Üretici firma',
        '• Renk: Ürün rengi',
        '• Renk Kodu: Hex renk kodu (#000000)',
        '• Birim: Varsayılan "adet"',
        '• Birim Fiyat: Sayısal değer (TL)',
        '• Malzeme: Ürün malzemesi',
        '• Minimum Stok: Uyarı seviyesi (varsayılan 10)',
        '• Açıklama: Ek bilgiler',
        '',
        'BEDEN BİLGİLERİ:',
        '• En az 1, en fazla 5 beden ekleyebilirsiniz',
        '• Beden: S, M, L, XL, 75cm, 18mm gibi',
        '• Stok: Başlangıç stok miktarı (varsayılan 0)',
        '',
        'NOTLAR:',
        '• Boş satırları silin',
        '• SKU kodları tekrar etmemeli',
        '• Sayısal değerlerde Türkçe karakter kullanmayın'
      ];
      
      for (int i = 0; i < instructions.length; i++) {
        final cell = instructionSheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i));
        cell.value = instructions[i];
        if (i == 0) {
          cell.cellStyle = xl.CellStyle(bold: true, fontSize: 14);
        } else if (instructions[i].endsWith(':')) {
          cell.cellStyle = xl.CellStyle(bold: true);
        }
      }
      
      // Excel dosyasını byte array'e çevir
      final bytes = excel.encode();
      if (bytes != null) {
        // Dosyayı indirme işlemi (web için)
        downloadFileWeb(bytes, 'aksesuar_sablonu.xlsx');
        
        context.showSuccessSnackBar('Excel şablonu indirildi');
      }
    } catch (e) {
      context.showErrorSnackBar('Hata: $e');
    }
  }

  // Excel dosyasından toplu import
  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final excel = xl.Excel.decodeBytes(bytes);
          final sheet = excel.tables.values.first;
          
          
          final List<Map<String, dynamic>> aksesuarListesi = [];
          int successCount = 0;
          int errorCount = 0;
          final List<String> errors = [];
          
          // İlk satır başlık, 2. satırdan itibaren veri
          for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
            try {
              final row = sheet.rows[rowIndex];
              
              // Boş satırları atla
              if (row.isEmpty || row[0]?.value?.toString().trim().isEmpty == true) {
                continue;
              }
              
              final sku = row[0]?.value?.toString().trim() ?? '';
              final ad = row[1]?.value?.toString().trim() ?? '';
              
              if (sku.isEmpty || ad.isEmpty) {
                errors.add('Satır ${rowIndex + 1}: SKU ve Aksesuar Adı zorunlu');
                errorCount++;
                continue;
              }
              
              // Bedenler ve stokları kontrol et
              final List<Map<String, dynamic>> bedenler = [];
              for (int i = 10; i < 20; i += 2) { // Beden sütunları
                final beden = row.length > i ? row[i]?.value?.toString().trim() : null;
                if (beden != null && beden.isNotEmpty) {
                  final stokStr = row.length > (i + 1) ? row[i + 1]?.value?.toString() : '0';
                  final stok = int.tryParse(stokStr ?? '0') ?? 0;
                  bedenler.add({
                    'beden': beden,
                    'stok_miktari': stok,
                  });
                }
              }
              
              if (bedenler.isEmpty) {
                errors.add('Satır ${rowIndex + 1}: En az bir beden bilgisi gerekli');
                errorCount++;
                continue;
              }
              
              // Aksesuar verisini hazırla
              final aksesuarData = {
                'sku': sku,
                'ad': ad,
                'marka': row.length > 2 ? (row[2]?.value?.toString().trim() ?? '') : '',
                'renk': row.length > 3 ? (row[3]?.value?.toString().trim() ?? '') : '',
                'renk_kodu': row.length > 4 ? (row[4]?.value?.toString().trim() ?? '') : '',
                'birim': row.length > 5 ? (row[5]?.value?.toString().trim() ?? 'adet') : 'adet',
                'birim_fiyat': row.length > 6 ? (double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0.0) : 0.0,
                'malzeme': row.length > 7 ? (row[7]?.value?.toString().trim() ?? '') : '',
                'minimum_stok': row.length > 8 ? (int.tryParse(row[8]?.value?.toString() ?? '10') ?? 10) : 10,
                'aciklama': row.length > 9 ? (row[9]?.value?.toString().trim() ?? '') : '',
                'durum': 'aktif',
                'bedenler': bedenler,
              };
              
              aksesuarListesi.add(aksesuarData);
              
            } catch (e) {
              errors.add('Satır ${rowIndex + 1}: $e');
              errorCount++;
            }
          }
          
          // Veritabanına kaydet
          for (final aksesuar in aksesuarListesi) {
            try {
              // Aksesuar kaydını oluştur
              final result = await supabase
                  .from(DbTables.aksesuarlar)
                  .insert({
                    'sku': aksesuar['sku'],
                    'ad': aksesuar['ad'],
                    'marka': aksesuar['marka'],
                    'renk': aksesuar['renk'],
                    'renk_kodu': aksesuar['renk_kodu'],
                    'birim': aksesuar['birim'],
                    'birim_fiyat': aksesuar['birim_fiyat'],
                    'malzeme': aksesuar['malzeme'],
                    'minimum_stok': aksesuar['minimum_stok'],
                    'aciklama': aksesuar['aciklama'],
                    'durum': aksesuar['durum'],
                    'firma_id': TenantManager.instance.requireFirmaId,
                  })
                  .select('id')
                  .single();
              
              final aksesuarId = result['id'];
              
              // Bedenlerini ekle
              for (final beden in aksesuar['bedenler']) {
                await supabase.from(DbTables.aksesuarBedenler).insert({
                  'aksesuar_id': aksesuarId,
                  'beden': beden['beden'],
                  'stok_miktari': beden['stok_miktari'],
                  'durum': 'aktif',
                  'firma_id': TenantManager.instance.requireFirmaId,
                });
              }
              
              successCount++;
              
            } catch (e) {
              errors.add('${aksesuar['sku']}: $e');
              errorCount++;
            }
          }
          
          // Sonuç mesajı
          String message = 'Toplam: ${successCount + errorCount}\n';
          message += 'Başarılı: $successCount\n';
          if (errorCount > 0) {
            message += 'Hatalı: $errorCount\n\n';
            message += 'Hatalar:\n${errors.take(5).join('\n')}';
            if (errors.length > 5) {
              message += '\n... ve ${errors.length - 5} hata daha';
            }
          }
          
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Sonucu'),
              content: SingleChildScrollView(
                child: Text(message),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
          
          if (successCount > 0) {
            await _loadAksesuarlar();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }
}
