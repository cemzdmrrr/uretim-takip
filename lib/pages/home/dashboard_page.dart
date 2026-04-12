import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'dart:math';
import 'package:uretim_takip/pages/raporlar/gelismis_raporlar_page.dart';
import 'package:uretim_takip/pages/model/model_ekle.dart';
import 'package:uretim_takip/pages/muhasebe/fatura_listesi_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  
  // Dashboard verileri
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _monthlyStats = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Genel istatistikler
      final stats = await Future.wait([
        _getTotalPersonel(),
        _getTotalMusteriler(),
        _getTotalTedarikciler(),
        _getAktifSiparisler(),
        _getToplameGelir(),
        _getToplamGider(),
        _getPendingTasks(),
        _getCompletedOrders(),
      ]);

      // Son aktiviteler
      final activities = await _getRecentActivities();
      
      // Aylık istatistikler
      final monthlyData = await _getMonthlyStats();

      setState(() {
        _dashboardData = {
          'toplam_personel': stats[0],
          'toplam_musteriler': stats[1],
          'toplam_tedarikciler': stats[2],
          'aktif_siparisler': stats[3],
          'toplam_gelir': stats[4],
          'toplam_gider': stats[5],
          'bekleyen_gorevler': stats[6],
          'tamamlanan_siparisler': stats[7],
        };
        _recentActivities = activities;
        _monthlyStats = monthlyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Veriler yüklenirken hata: $e');
    }
  }

  Future<int> _getTotalPersonel() async {
    final response = await _supabase.from(DbTables.personel).select('count()').eq('firma_id', _firmaId);
    return response[0]['count'] ?? 0;
  }

  Future<int> _getTotalMusteriler() async {
    final response = await _supabase.from(DbTables.musteriler).select('count()').eq('firma_id', _firmaId);
    return response[0]['count'] ?? 0;
  }

  Future<int> _getTotalTedarikciler() async {
    final response = await _supabase.from(DbTables.tedarikciler).select('count()').eq('firma_id', _firmaId);
    return response[0]['count'] ?? 0;
  }

  Future<int> _getAktifSiparisler() async {
    final response = await _supabase
        .from(DbTables.trikoTakip)
        .select('count()')
        .eq('firma_id', _firmaId)
        .eq('tamamlandi', false);
    return response[0]['count'] ?? 0;
  }

  Future<double> _getToplameGelir() async {
    final response = await _supabase
        .from(DbTables.faturalar)
        .select('toplam_tutar')
        .eq('firma_id', _firmaId)
        .eq('fatura_turu', 'satis')
        .eq('durum', 'onaylandi');
    
    double total = 0;
    for (var item in response) {
      total += (item['toplam_tutar'] ?? 0).toDouble();
    }
    return total;
  }

  Future<double> _getToplamGider() async {
    final response = await _supabase
        .from(DbTables.faturalar)
        .select('toplam_tutar')
        .eq('firma_id', _firmaId)
        .eq('fatura_turu', 'alis')
        .eq('durum', 'onaylandi');
    
    double total = 0;
    for (var item in response) {
      total += (item['toplam_tutar'] ?? 0).toDouble();
    }
    return total;
  }

  Future<int> _getPendingTasks() async {
    final response = await _supabase
        .from(DbTables.izinler)
        .select('count()')
        .eq('firma_id', _firmaId)
        .eq('onay_durumu', 'beklemede');
    return response[0]['count'] ?? 0;
  }

  Future<int> _getCompletedOrders() async {
    final response = await _supabase
        .from(DbTables.trikoTakip)
        .select('count()')
        .eq('firma_id', _firmaId)
        .eq('tamamlandi', true);
    return response[0]['count'] ?? 0;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    // Son aktiviteler için birden fazla tablodan veri çekme
    final List<Map<String, dynamic>> activities = [];
    
    // Son eklenen müşteriler
    final customers = await _supabase
        .from(DbTables.musteriler)
        .select('ad, soyad, kayit_tarihi')
        .eq('firma_id', _firmaId)
        .order('kayit_tarihi', ascending: false)
        .limit(5);
    
    for (var customer in customers) {
      activities.add({
        'type': 'customer',
        'title': 'Yeni Müşteri',
        'description': '${customer['ad']} ${customer['soyad']} eklendi',
        'date': customer['kayit_tarihi'],
        'icon': Icons.person_add,
        'color': Colors.green,
      });
    }
    
    // Son siparişler
    final orders = await _supabase
        .from(DbTables.trikoTakip)
        .select('marka, item_no, created_at')
        .eq('firma_id', _firmaId)
        .order('created_at', ascending: false)
        .limit(5);
    
    for (var order in orders) {
      activities.add({
        'type': 'order',
        'title': 'Yeni Sipariş',
        'description': '${order['marka']} - ${order['item_no']}',
        'date': order['created_at'],
        'icon': Icons.shopping_cart,
        'color': Colors.blue,
      });
    }
    
    // Tarihe göre sırala
    activities.sort((a, b) => 
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    
    return activities.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> _getMonthlyStats() async {
    final List<Map<String, dynamic>> stats = [];
    
    for (int i = 11; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 30));
      final startDate = DateTime(date.year, date.month, 1);
      final endDate = DateTime(date.year, date.month + 1, 0);
      
      final orders = await _supabase
          .from(DbTables.trikoTakip)
          .select('count()')
          .eq('firma_id', _firmaId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());
      
      final revenue = await _supabase
          .from(DbTables.faturalar)
          .select('toplam_tutar')
          .eq('firma_id', _firmaId)
          .eq('fatura_turu', 'satis')
          .gte('olusturma_tarihi', startDate.toIso8601String())
          .lte('olusturma_tarihi', endDate.toIso8601String());
      
      double totalRevenue = 0;
      for (var item in revenue) {
        totalRevenue += (item['toplam_tutar'] ?? 0).toDouble();
      }
      
      stats.add({
        'month': _getMonthName(date.month),
        'orders': orders[0]['count'] ?? 0,
        'revenue': totalRevenue,
      });
    }
    
    return stats;
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ERP Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hoş geldin kartı
                    _buildWelcomeCard(),
                    const SizedBox(height: 12),
                    
                    // Ana istatistikler
                    _buildStatsGrid(),
                    const SizedBox(height: 12),
                    
                    // Grafikler ve chartlar
                    _buildChartsSection(),
                    const SizedBox(height: 12),
                    
                    // Son aktiviteler
                    _buildRecentActivities(),
                    const SizedBox(height: 12),
                    
                    // Hızlı aksiyonlar
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final hour = now.hour;
    final String greeting = hour < 12 ? 'Günaydın' : hour < 18 ? 'İyi günler' : 'İyi akşamlar';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bugün ${_dashboardData['aktif_siparisler'] ?? 0} aktif siparişiniz var.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              now.toString().substring(0, 10),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Toplam Personel',
          '${_dashboardData['toplam_personel'] ?? 0}',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Müşteriler',
          '${_dashboardData['toplam_musteriler'] ?? 0}',
          Icons.business,
          Colors.green,
        ),
        _buildStatCard(
          'Tedarikçiler',
          '${_dashboardData['toplam_tedarikciler'] ?? 0}',
          Icons.local_shipping,
          Colors.orange,
        ),
        _buildStatCard(
          'Aktif Siparişler',
          '${_dashboardData['aktif_siparisler'] ?? 0}',
          Icons.shopping_cart,
          Colors.purple,
        ),
        _buildStatCard(
          'Toplam Gelir',
          '₺${(_dashboardData['toplam_gelir'] ?? 0).toStringAsFixed(0)}',
          Icons.trending_up,
          Colors.teal,
        ),
        _buildStatCard(
          'Bekleyen Görevler',
          '${_dashboardData['bekleyen_gorevler'] ?? 0}',
          Icons.pending_actions,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aylık İstatistikler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _buildSimpleChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart() {
    if (_monthlyStats.isEmpty) return const Center(child: Text('Veri yok'));
    
    final double maxRevenue = _monthlyStats
        .map((e) => e['revenue'] as double)
        .reduce((a, b) => a > b ? a : b);
    
    return Row(
      children: _monthlyStats.map((stat) {
        final double height = maxRevenue > 0 ? (stat['revenue'] / maxRevenue) * 150 : 0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: height,
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['month'].substring(0, 3),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _recentActivities.isEmpty
                ? const Center(child: Text('Henüz aktivite yok'))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: min(_recentActivities.length, 5),
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final activity = _recentActivities[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: activity['color'].withValues(alpha: 0.1),
                          child: Icon(
                            activity['icon'],
                            color: activity['color'],
                          ),
                        ),
                        title: Text(activity['title']),
                        subtitle: Text(activity['description']),
                        trailing: Text(
                          DateTime.parse(activity['date'])
                              .toString()
                              .substring(0, 10),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Aksiyonlar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Yeni Sipariş',
                    Icons.add_shopping_cart,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelEkle())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Yeni Fatura',
                    Icons.receipt_long,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaturaListesiPage())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Yeni Fatura',
                    Icons.receipt,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaturaListesiPage())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Gelişmiş Raporlar',
                    Icons.analytics,
                    Colors.purple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GelismisRaporlarPage())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
