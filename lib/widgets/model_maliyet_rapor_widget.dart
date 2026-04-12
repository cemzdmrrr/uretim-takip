import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/services/model_maliyet_hesaplama_servisi.dart';
import 'package:intl/intl.dart';

/// Model Maliyet Rapor Widget'ı
/// Tamamlanan modellerin maliyetlerini raporlar
class ModelMaliyetRaporWidget extends StatefulWidget {
  const ModelMaliyetRaporWidget({super.key});

  @override
  State<ModelMaliyetRaporWidget> createState() => _ModelMaliyetRaporWidgetState();
}

class _ModelMaliyetRaporWidgetState extends State<ModelMaliyetRaporWidget> {
  final _maliyetServisi = ModelMaliyetHesaplamaServisi();
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _raporlar = [];
  Map<String, dynamic> _karlilkRaporu = {};

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final raporlar = await _maliyetServisi.getTumMaliyetRaporlari();
      final karlilik = await _maliyetServisi.getKarlilikRaporu();

      setState(() {
        _raporlar = raporlar;
        _karlilkRaporu = karlilik;
      });
    } catch (e) {
      debugPrint('Hata: $e');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  String _formatPara(dynamic value) {
    if (value == null) return '₺0.00';
    final num = double.tryParse(value.toString()) ?? 0;
    return '₺${num.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const LoadingWidget();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ÖZET KARTLAR
          if (_karlilkRaporu.isNotEmpty) ...[
            Text(
              'Finansal Özet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildOzetKart(
                  title: 'Toplam Maliyet',
                  value: _formatPara(_karlilkRaporu['toplam_maliyet']),
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
                _buildOzetKart(
                  title: 'Toplam Satış',
                  value: _formatPara(_karlilkRaporu['toplam_satis_geliri']),
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                _buildOzetKart(
                  title: 'Toplam Kar/Zarar',
                  value: _formatPara(_karlilkRaporu['toplam_kar_zarar']),
                  icon: Icons.attach_money,
                  color:
                      ((_karlilkRaporu['toplam_kar_zarar'] as num? ?? 0) > 0)
                          ? Colors.green
                          : Colors.orange,
                ),
                _buildOzetKart(
                  title: 'Kar Oranı',
                  value: '${(_karlilkRaporu['kar_orani_yuzde'] as num? ?? 0).toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // DETAYLI RAPORLAR
          Text(
            'Model Maliyetleri',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (_raporlar.isEmpty)
            const Center(
              child: Text('Henüz tamamlanmış model bulunmamaktadır'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _raporlar.length,
              itemBuilder: (context, index) {
                final rapor = _raporlar[index];
                return _buildMaliyetKarti(rapor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOzetKart({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaliyetKarti(Map<String, dynamic> rapor) {
    final toplamMaliyet = (rapor['toplam_maliyet'] as num? ?? 0).toDouble();
    final satisGeliri = (rapor['toplam_satis_geliri'] as num? ?? 0).toDouble();
    final karZarar = (rapor['toplam_kar_zarar'] as num? ?? 0).toDouble();
    final karOrani = (rapor['kar_marji_yuzde'] as num? ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Model ID: ${rapor['model_id']}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: karZarar > 0 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatPara(karZarar),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: karZarar > 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Temel bilgiler
                _buildMaliyetSatiri('Tamamlanan Adet', '${rapor['tamamlanan_adet']} adet'),
                _buildMaliyetSatiri('Tarih', DateFormat('dd.MM.yyyy').format(DateTime.parse(rapor['created_at'] ?? ''))),
                const SizedBox(height: 12),

                // Maliyet detayları
                Text(
                  'Maliyet Detayları',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
                const Divider(),
                _buildMaliyetSatiri('İplik Maliyeti', _formatPara(rapor['iplik_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Makina Maliyeti', _formatPara(rapor['makina_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Konfeksiyon', _formatPara(rapor['konfeksiyon_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Naksş', _formatPara(rapor['nakis_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Yıkama', _formatPara(rapor['yikama_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Ütü', _formatPara(rapor['utu_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('İlik-Düğme', _formatPara(rapor['ilik_dugme_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Paketleme', _formatPara(rapor['paketleme_maliyeti']), isDetay: true),
                _buildMaliyetSatiri('Genel Giderler', _formatPara(rapor['genel_giderler']), isDetay: true),
                const Divider(),
                const SizedBox(height: 8),

                // Toplam ve kar/zarar
                _buildMaliyetSatiri(
                  'Birim Maliyet',
                  _formatPara(rapor['toplam_maliyet_birimi']),
                  isBold: true,
                ),
                _buildMaliyetSatiri(
                  'Birim Satış Noktası',
                  _formatPara(rapor['birim_satis_noktas']),
                  isBold: true,
                ),
                _buildMaliyetSatiri(
                  'Kar Marjı',
                  '${karOrani.toStringAsFixed(1)}%',
                  isBold: true,
                ),
                const Divider(),
                _buildMaliyetSatiri(
                  'Toplam Maliyet',
                  _formatPara(toplamMaliyet),
                  isBold: true,
                  color: Colors.red,
                ),
                _buildMaliyetSatiri(
                  'Toplam Satış Geliri',
                  _formatPara(satisGeliri),
                  isBold: true,
                  color: Colors.blue,
                ),
                _buildMaliyetSatiri(
                  'Kar/Zarar',
                  _formatPara(karZarar),
                  isBold: true,
                  color: karZarar > 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaliyetSatiri(
    String baslik,
    String deger, {
    bool isBold = false,
    bool isDetay = false,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: isDetay ? 16 : 0,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            baslik,
            style: TextStyle(
              fontSize: isDetay ? 12 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey[700],
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              fontSize: isDetay ? 12 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
