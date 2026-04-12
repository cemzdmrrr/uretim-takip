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

  // Renkler - Siyah Beyaz Paleti
  static const Color siyah = Colors.black87;
  static const Color beyaz = Colors.white;
  static const Color acikGri = Color(0xFFEEEEEE);

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
      setState(() => yukleniyor = false);
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
      appBar: AppBar(
        title: const Text(
          'Ürün Depo Yönetimi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: siyah,
        foregroundColor: beyaz,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            labelColor: beyaz,
            unselectedLabelColor: Colors.white70,
            indicatorColor: beyaz,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.verified),
                text: '1. Kalite',
              ),
              Tab(
                icon: Icon(Icons.info),
                text: '2. & 3. Kalite',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _urunTabi('1. Kalite'),
          _urunTabi('2. & 3. Kalite'),
        ],
      ),
    );
  }
}
