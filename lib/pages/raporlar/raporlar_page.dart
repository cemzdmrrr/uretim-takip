import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class RaporlarPage extends StatefulWidget {
  const RaporlarPage({super.key});

  @override
  State<RaporlarPage> createState() => _RaporlarPageState();
}

class _RaporlarPageState extends State<RaporlarPage> {
  bool yukleniyor = true;
  String? hata;

  // Filtre değişkenleri
  String secilenModel = 'Tümü';
  String secilenDurum = 'Tümü';
  DateTimeRange? seciliTarihAraligi;

  // Veri listeleri
  List<Map<String, dynamic>> uretimRaporlari = [];
  List<String> modelListesi = ['Tümü'];
  List<String> durumListesi = ['Tümü', 'Tamamlandı', 'Devam Ediyor', 'Beklemede'];

  // İstatistik değişkenleri
  int toplamSiparis = 0;
  int tamamlananSiparis = 0;
  int devamEdenSiparis = 0;
  double toplamUretimAdedi = 0;
  Map<String, int> aylikUretim = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      yukleniyor = true;
      hata = null;
    });

    try {

      // Önce hangi tabloların mevcut olduğunu kontrol edelim
      await _loadUretimRaporlari();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        hata = 'Veriler yüklenirken hata oluştu: $e';
      });
    }

    setState(() => yukleniyor = false);
  }

  Future<void> _loadUretimRaporlari() async {
    try {
      final client = Supabase.instance.client;
      
      // Önce models tablosunu kontrol et
      try {
        final firmaId = TenantManager.instance.requireFirmaId;
        var checkQuery = client.from(DbTables.models).select('model_adi');
        checkQuery = checkQuery.eq('firma_id', firmaId);
        await checkQuery.limit(1);
            
        // Models tablosu varsa model listesini yükle
        var allModelsQuery = client.from(DbTables.models).select('model_adi');
        allModelsQuery = allModelsQuery.eq('firma_id', firmaId);
        final allModelsResponse = await allModelsQuery.order('model_adi');

        modelListesi = ['Tümü'];
        for (final model in allModelsResponse) {
          if (model['model_adi'] != null) {
            modelListesi.add(model['model_adi'].toString());
          }
        }
        
        // Üretim raporlarını yükle
        await _loadModelsData();
        
      } catch (modelsHata) {
        debugPrint('Models tablosu bulunamadı: $modelsHata');
        // Models tablosu yoksa alternatif veri kaynakları dene
        await _loadAlternativeData();
      }

    } catch (e) {
      debugPrint('Üretim raporları yüklenirken hata: $e');
      rethrow;
    }
  }

  Future<void> _loadModelsData() async {
    try {
      final client = Supabase.instance.client;
      var query = client.from(DbTables.models).select('*');
      final firmaId = TenantManager.instance.requireFirmaId;
      query = query.eq('firma_id', firmaId);

      // Filtreler uygula
      if (secilenModel != 'Tümü') {
        query = query.eq('model_adi', secilenModel);
      }

      if (secilenDurum != 'Tümü') {
        final String durumKodu = _getDurumKodu(secilenDurum);
        query = query.eq('durum', durumKodu);
      }

      if (seciliTarihAraligi != null) {
        final startDate = DateFormat('yyyy-MM-dd').format(seciliTarihAraligi!.start);
        final endDate = DateFormat('yyyy-MM-dd').format(seciliTarihAraligi!.end);
        query = query.gte('created_at', startDate).lte('created_at', endDate);
      }

      final response = await query.order('created_at', ascending: false);
      uretimRaporlari = List<Map<String, dynamic>>.from(response);

      // İstatistikleri hesapla
      _hesaplaIstatistikler();

    } catch (e) {
      debugPrint('Models verisi yüklenirken hata: $e');
      rethrow;
    }
  }

  Future<void> _loadAlternativeData() async {
    // Models tablosu yoksa demo veri oluştur
    uretimRaporlari = [
      {
        'model_adi': 'Demo Model 1',
        'musteri_adi': 'Demo Müşteri A',
        'siparis_tarihi': '2024-01-15',
        'uretim_adet': 100,
        'durum': 'tamamlandi',
        'created_at': '2024-01-15T10:00:00Z',
      },
      {
        'model_adi': 'Demo Model 2',
        'musteri_adi': 'Demo Müşteri B',
        'siparis_tarihi': '2024-01-20',
        'uretim_adet': 150,
        'durum': 'devam_ediyor',
        'created_at': '2024-01-20T10:00:00Z',
      },
    ];
    
    modelListesi = ['Tümü', 'Demo Model 1', 'Demo Model 2'];
    _hesaplaIstatistikler();
  }

  String _getDurumKodu(String durum) {
    switch (durum) {
      case 'Tamamlandı':
        return 'tamamlandi';
      case 'Devam Ediyor':
        return 'devam_ediyor';
      case 'Beklemede':
        return 'beklemede';
      default:
        return '';
    }
  }

  void _hesaplaIstatistikler() {
    toplamSiparis = uretimRaporlari.length;
    tamamlananSiparis = uretimRaporlari.where((item) => item['durum'] == 'tamamlandi').length;
    devamEdenSiparis = uretimRaporlari.where((item) => item['durum'] == 'devam_ediyor').length;
    
    toplamUretimAdedi = 0;
    aylikUretim.clear();
    
    for (final item in uretimRaporlari) {
      final uretimAdet = item['uretim_adet'];
      if (uretimAdet != null) {
        toplamUretimAdedi += (uretimAdet is int) ? uretimAdet.toDouble() : (uretimAdet as double? ?? 0);
      }
      
      // Aylık üretim hesapla
      final tarihStr = item['created_at']?.toString() ?? item['siparis_tarihi']?.toString();
      if (tarihStr != null) {
        try {
          final tarih = DateTime.parse(tarihStr);
          final ayKey = '${tarih.year}-${tarih.month.toString().padLeft(2, '0')}';
          aylikUretim[ayKey] = (aylikUretim[ayKey] ?? 0) + (uretimAdet as int? ?? 0);
        } catch (e) {
          debugPrint('Tarih parse hatası: $e');
        }
      }
    }
  }

  Future<void> _tarihAraliginiSec() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: seciliTarihAraligi,
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        seciliTarihAraligi = picked;
      });
      await _loadUretimRaporlari();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üretim Raporları', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : hata != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(hata!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtreler
                    _buildFiltreler(),
                    
                    // İstatistikler
                    _buildIstatistikler(),
                    
                    // Aylık Üretim Grafiği
                    if (aylikUretim.isNotEmpty) _buildAylikUretimGrafigi(),
                    
                    // Rapor Listesi
                    Expanded(child: _buildRaporListesi()),
                  ],
                ),
    );
  }

  Widget _buildFiltreler() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: secilenModel,
                  items: modelListesi.map((model) {
                    return DropdownMenuItem(value: model, child: Text(model));
                  }).toList(),
                  onChanged: (value) async {
                    setState(() => secilenModel = value!);
                    await _loadUretimRaporlari();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: secilenDurum,
                  items: durumListesi.map((durum) {
                    return DropdownMenuItem(value: durum, child: Text(durum));
                  }).toList(),
                  onChanged: (value) async {
                    setState(() => secilenDurum = value!);
                    await _loadUretimRaporlari();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _tarihAraliginiSec,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    seciliTarihAraligi == null
                        ? 'Tarih Aralığı Seç'
                        : '${DateFormat('dd/MM/yyyy').format(seciliTarihAraligi!.start)} - ${DateFormat('dd/MM/yyyy').format(seciliTarihAraligi!.end)}',
                  ),
                ),
              ),
              if (seciliTarihAraligi != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    setState(() => seciliTarihAraligi = null);
                    await _loadUretimRaporlari();
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Temizle',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistikler() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildIstatistikKarti('Toplam Sipariş', toplamSiparis.toString(), Colors.blue)),
          Expanded(child: _buildIstatistikKarti('Tamamlanan', tamamlananSiparis.toString(), Colors.green)),
          Expanded(child: _buildIstatistikKarti('Devam Eden', devamEdenSiparis.toString(), Colors.orange)),
          Expanded(child: _buildIstatistikKarti('Toplam Üretim', toplamUretimAdedi.toStringAsFixed(0), Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildIstatistikKarti(String baslik, String deger, Color renk) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [renk.withValues(alpha: 0.1), renk.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              deger,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              baslik,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAylikUretimGrafigi() {
    final sortedData = aylikUretim.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Aylık Üretim Trendi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedData.length) {
                            final tarih = sortedData[index].key.split('-');
                            return Text('${tarih[1]}/${tarih[0].substring(2)}', style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: sortedData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaporListesi() {
    if (uretimRaporlari.isEmpty) {
      return const Center(
        child: Text('Seçili kriterlere uygun veri bulunamadı.'),
      );
    }

    return ListView.builder(
      itemCount: uretimRaporlari.length,
      itemBuilder: (context, index) {
        final item = uretimRaporlari[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(item['model_adi']?.toString() ?? 'Bilinmeyen Model'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Müşteri: ${item['musteri_adi'] ?? 'Belirtilmemiş'}'),
                Text('Sipariş Tarihi: ${_formatTarih(item['siparis_tarihi'])}'),
                Text('Üretim Adedi: ${item['uretim_adet'] ?? 0}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDurumRengi(item['durum']?.toString()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDurumMetni(item['durum']?.toString()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTarih(dynamic tarih) {
    if (tarih == null) return 'Belirtilmemiş';
    try {
      if (tarih is String) {
        final date = DateTime.parse(tarih);
        return DateFormat('dd/MM/yyyy').format(date);
      }
      return tarih.toString();
    } catch (e) {
      return tarih.toString();
    }
  }

  Color _getDurumRengi(String? durum) {
    switch (durum) {
      case 'tamamlandi':
        return Colors.green;
      case 'devam_ediyor':
        return Colors.orange;
      case 'beklemede':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDurumMetni(String? durum) {
    switch (durum) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      case 'beklemede':
        return 'Beklemede';
      default:
        return 'Bilinmeyen';
    }
  }
}
