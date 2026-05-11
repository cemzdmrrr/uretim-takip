import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class SevkIrsaliyeListesiPage extends StatefulWidget {
  const SevkIrsaliyeListesiPage({super.key});

  @override
  State<SevkIrsaliyeListesiPage> createState() => _SevkIrsaliyeListesiPageState();
}

class _SevkIrsaliyeListesiPageState extends State<SevkIrsaliyeListesiPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _aramaController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  List<Map<String, dynamic>> _irsaliyeler = [];
  Map<int, List<Map<String, dynamic>>> _kalemlerByIrsaliye = {};
  Map<String, Map<String, dynamic>> _modelById = {};
  bool _yukleniyor = false;

  String get _firmaId => TenantManager.instance.requireFirmaId;

  @override
  void initState() {
    super.initState();
    _irsaliyeleriYukle();
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _irsaliyeleriYukle() async {
    setState(() => _yukleniyor = true);

    try {
      final irsaliyeRaw = await _supabase
          .from(DbTables.sevkIrsaliyeleri)
          .select('''
            id,
            irsaliye_no,
            model_id,
            kaynak_asama,
            hedef_asama,
            sevk_adedi,
            durum,
            sevk_tarihi,
            created_at,
            notlar
          ''')
          .eq('firma_id', _firmaId)
          .order('sevk_tarihi', ascending: false)
          .limit(500);

      final irsaliyeler = List<Map<String, dynamic>>.from(irsaliyeRaw);
      final irsaliyeIds = irsaliyeler
          .map((e) => _toInt(e['id']))
          .where((id) => id > 0)
          .toList();

      List<Map<String, dynamic>> kalemler = [];
      if (irsaliyeIds.isNotEmpty) {
        try {
          final kalemRaw = await _supabase
              .from(DbTables.sevkIrsaliyeKalemleri)
              .select('''
                irsaliye_id,
                model_id,
                beden_kodu,
                koli_adedi,
                adet,
                birim,
                aciklama
              ''')
              .eq('firma_id', _firmaId)
              .inFilter('irsaliye_id', irsaliyeIds);
          kalemler = List<Map<String, dynamic>>.from(kalemRaw);
        } catch (e) {
          debugPrint('Irsaliye kalemleri yuklenemedi: $e');
        }
      }

      final kalemlerByIrsaliye = <int, List<Map<String, dynamic>>>{};
      for (final kalem in kalemler) {
        final irsaliyeId = _toInt(kalem['irsaliye_id']);
        if (irsaliyeId <= 0) continue;
        kalemlerByIrsaliye.putIfAbsent(irsaliyeId, () => []).add(kalem);
      }

      final modelIds = <String>{};
      for (final irsaliye in irsaliyeler) {
        final modelId = _toNullableString(irsaliye['model_id']);
        if (modelId != null) modelIds.add(modelId);
      }
      for (final kalem in kalemler) {
        final modelId = _toNullableString(kalem['model_id']);
        if (modelId != null) modelIds.add(modelId);
      }

      final modelById = <String, Map<String, dynamic>>{};
      if (modelIds.isNotEmpty) {
        try {
          final modelRaw = await _supabase
              .from(DbTables.trikoTakip)
              .select('id, marka, item_no, model_adi, renk')
              .eq('firma_id', _firmaId)
              .inFilter('id', modelIds.toList());

          for (final item in List<Map<String, dynamic>>.from(modelRaw)) {
            final id = _toNullableString(item['id']);
            if (id != null) {
              modelById[id] = item;
            }
          }
        } catch (e) {
          debugPrint('Model bilgileri yuklenemedi: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _irsaliyeler = irsaliyeler;
        _kalemlerByIrsaliye = kalemlerByIrsaliye;
        _modelById = modelById;
      });
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Sevk irsaliyeleri yuklenemedi: $e');
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filtreliIrsaliyeler {
    final arama = _aramaController.text.trim().toLowerCase();
    if (arama.isEmpty) return _irsaliyeler;

    return _irsaliyeler.where((irsaliye) {
      final irsaliyeNo =
          _toNullableString(irsaliye['irsaliye_no'])?.toLowerCase() ?? '';
      final kaynakAsama =
          _toNullableString(irsaliye['kaynak_asama'])?.toLowerCase() ?? '';
      final hedefAsama =
          _toNullableString(irsaliye['hedef_asama'])?.toLowerCase() ?? '';
      final durum = _toNullableString(irsaliye['durum'])?.toLowerCase() ?? '';
      final modelEtiket =
          _modelEtiketi(_toNullableString(irsaliye['model_id'])).toLowerCase();

      return irsaliyeNo.contains(arama) ||
          kaynakAsama.contains(arama) ||
          hedefAsama.contains(arama) ||
          durum.contains(arama) ||
          modelEtiket.contains(arama);
    }).toList();
  }

  int get _toplamIrsaliyeSayisi => _filtreliIrsaliyeler.length;

  int get _toplamSevkAdedi {
    return _filtreliIrsaliyeler.fold<int>(
      0,
      (sum, irsaliye) => sum + _toInt(irsaliye['sevk_adedi']),
    );
  }

  int get _toplamKalemSayisi {
    return _filtreliIrsaliyeler.fold<int>(0, (sum, irsaliye) {
      final irsaliyeId = _toInt(irsaliye['id']);
      return sum + (_kalemlerByIrsaliye[irsaliyeId]?.length ?? 0);
    });
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _toDate(dynamic value) {
    final text = _toNullableString(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  String _formatDate(dynamic value) {
    final dt = _toDate(value);
    if (dt == null) return '-';
    return _dateFormat.format(dt.toLocal());
  }

  String _durumEtiketi(String? durum) {
    switch ((durum ?? '').toLowerCase()) {
      case 'onaylandi':
        return 'Onaylandi';
      case 'taslak':
        return 'Taslak';
      case 'iptal':
        return 'Iptal';
      case 'tamamlandi':
        return 'Tamamlandi';
      default:
        return durum ?? 'Bilinmiyor';
    }
  }

  Color _durumRenk(String? durum) {
    switch ((durum ?? '').toLowerCase()) {
      case 'onaylandi':
      case 'tamamlandi':
        return Colors.green;
      case 'taslak':
        return Colors.orange;
      case 'iptal':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _modelEtiketi(String? modelId) {
    if (modelId == null) return 'Model bilgisi yok';

    final model = _modelById[modelId];
    if (model == null) return 'Model #$modelId';

    final marka = _toNullableString(model['marka']) ?? '-';
    final itemNo = _toNullableString(model['item_no']) ??
        _toNullableString(model['model_adi']) ??
        modelId;

    return '$marka - $itemNo';
  }

  @override
  Widget build(BuildContext context) {
    final irsaliyeler = _filtreliIrsaliyeler;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sevk Irsaliyeleri'),
        actions: [
          IconButton(
            onPressed: _irsaliyeleriYukle,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _aramaController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Irsaliye No, model, asama ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _aramaController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _aramaController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildOzetKart(
                  icon: Icons.receipt_long,
                  label: 'Toplam Irsaliye',
                  value: _toplamIrsaliyeSayisi.toString(),
                  color: Colors.indigo,
                ),
                _buildOzetKart(
                  icon: Icons.inventory_2,
                  label: 'Toplam Sevk Adedi',
                  value: _toplamSevkAdedi.toString(),
                  color: Colors.teal,
                ),
                _buildOzetKart(
                  icon: Icons.list_alt,
                  label: 'Toplam Kalem',
                  value: _toplamKalemSayisi.toString(),
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _yukleniyor
                ? const LoadingWidget()
                : irsaliyeler.isEmpty
                    ? const Center(
                        child: Text('Goruntulenecek irsaliye kaydi bulunamadi.'),
                      )
                    : RefreshIndicator(
                        onRefresh: _irsaliyeleriYukle,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: irsaliyeler.length,
                          itemBuilder: (context, index) =>
                              _buildIrsaliyeCard(irsaliyeler[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOzetKart({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrsaliyeCard(Map<String, dynamic> irsaliye) {
    final irsaliyeId = _toInt(irsaliye['id']);
    final irsaliyeNo = _toNullableString(irsaliye['irsaliye_no']) ?? '-';
    final modelId = _toNullableString(irsaliye['model_id']);
    final modelEtiket = _modelEtiketi(modelId);
    final kaynakAsama = _toNullableString(irsaliye['kaynak_asama']) ?? '-';
    final hedefAsama = _toNullableString(irsaliye['hedef_asama']) ?? '-';
    final sevkAdedi = _toInt(irsaliye['sevk_adedi']);
    final durum = _toNullableString(irsaliye['durum']);
    final notlar = _toNullableString(irsaliye['notlar']);
    final sevkTarihi = irsaliye['sevk_tarihi'] ?? irsaliye['created_at'];
    final kalemler = _kalemlerByIrsaliye[irsaliyeId] ?? const [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
          foregroundColor: Colors.indigo,
          child: const Icon(Icons.receipt_long),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                irsaliyeNo,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _durumRenk(durum).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _durumEtiketi(durum),
                style: TextStyle(
                  color: _durumRenk(durum),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(modelEtiket),
              const SizedBox(height: 2),
              Text('Asama: $kaynakAsama -> $hedefAsama'),
              const SizedBox(height: 2),
              Text('Sevk: $sevkAdedi adet  •  Tarih: ${_formatDate(sevkTarihi)}'),
            ],
          ),
        ),
        children: [
          if (notlar != null && notlar.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Not: $notlar'),
            ),
          if (kalemler.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Kalem detayi bulunamadi.'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                children: kalemler.map(_buildKalemSatiri).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKalemSatiri(Map<String, dynamic> kalem) {
    final modelId = _toNullableString(kalem['model_id']);
    final modelEtiket = _modelEtiketi(modelId);
    final beden = _toNullableString(kalem['beden_kodu']) ?? '-';
    final koli = _toInt(kalem['koli_adedi']);
    final adet = _toInt(kalem['adet']);
    final birim = _toNullableString(kalem['birim']) ?? 'adet';
    final aciklama = _toNullableString(kalem['aciklama']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modelEtiket,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Beden: $beden  •  Koli: $koli  •  Miktar: $adet $birim'),
          if (aciklama != null && aciklama.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('Aciklama: $aciklama'),
          ],
        ],
      ),
    );
  }
}