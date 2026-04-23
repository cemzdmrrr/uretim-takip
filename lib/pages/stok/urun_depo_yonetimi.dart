import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'urun_depo_yonetimi_dialog.dart';

class UrunDepoYonetimiPage extends StatefulWidget {
  const UrunDepoYonetimiPage({super.key});

  @override
  State<UrunDepoYonetimiPage> createState() => _UrunDepoYonetimiPageState();
}

class _UrunDepoYonetimiPageState extends State<UrunDepoYonetimiPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  late TabController _tabController;

  List<Map<String, dynamic>> urunDepoListesi = [];
  bool yukleniyor = true;
  String arama = '';

  static const Color siyah = Color(0xFF0F172A);
  static const Color beyaz = Colors.white;
  static const Color acikGri = Color(0xFFF1F5F9);
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color successColor = Color(0xFF059669);
  static const Color warningColor = Color(0xFFD97706);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color surfaceColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    urunDepoListesiniGetir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> urunDepoListesiniGetir() async {
    setState(() => yukleniyor = true);
    try {
      final response = await _supabase
          .from(DbTables.urunDepo)
          .select('*')
          .eq('firma_id', _firmaId)
          .order('created_at', ascending: false);

      setState(() {
        urunDepoListesi = List<Map<String, dynamic>>.from(response);
      });
      debugPrint('✅ Ürün depo listesi alındı: ${urunDepoListesi.length} ürün');
    } catch (e) {
      debugPrint('❌ Ürün depo listesi hatası: $e');
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => yukleniyor = false);
      }
    }
  }

  // Tamamlanan siparişlerden markaları getir
  Future<List<String>> _markalariGetir() async {
    try {
      final response = await _supabase
          .from(DbTables.trikoTakip)
          .select('marka')
          .eq('firma_id', _firmaId);

      final markalar = <String>{};
      for (var item in response) {
        if (item['marka'] != null && item['marka'].toString().isNotEmpty) {
          markalar.add(item['marka'].toString());
        }
      }
      final sortedList = markalar.toList()..sort();
      debugPrint('✅ Bulunan markalar: $sortedList');
      return sortedList;
    } catch (e) {
      debugPrint('❌ Markalar hatası: $e');
      return [];
    }
  }

  // Seçilen markaya ait modelleri getir
  Future<List<Map<String, dynamic>>> _modellerGetir(String marka) async {
    try {
      final response = await _supabase
          .from(DbTables.trikoTakip)
          .select('id, item_no, renk, adet, urun_cinsi, marka')
          .eq('firma_id', _firmaId)
          .eq('marka', marka)
          .order('item_no');

      debugPrint('✅ Marka "$marka" için bulunan modeller: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Modeller hatası: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          _buildUrunDepoUstBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _urunTabi('1. Kalite'),
                _urunTabi('2. & 3. Kalite'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrunDepoUstBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.storefront_outlined, color: primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ürün Depo Yönetimi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: siyah,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kalite bazlı ürün stok, kalan adet ve satış takibi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: urunDepoListesiniGetir,
                icon: const Icon(Icons.refresh),
                tooltip: 'Yenile',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: acikGri,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF475569),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.verified), text: '1. Kalite'),
                Tab(icon: Icon(Icons.info_outline), text: '2. & 3. Kalite'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
