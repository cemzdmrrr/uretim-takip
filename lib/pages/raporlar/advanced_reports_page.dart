import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/widgets/model_maliyet_rapor_widget.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'advanced_reports_content.dart';


class AdvancedReportsPage extends StatefulWidget {
  const AdvancedReportsPage({super.key});
  @override
  State<AdvancedReportsPage> createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage> {
  final _supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  
  String _selectedReportType = 'sales';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic> _reportData = {};

  final Map<String, String> _reportTypes = {
    'sales': 'Satış Raporu',
    'purchases': 'Alış Raporu',
    'inventory': 'Stok Raporu',
    'financial': 'Mali Durum Raporu',
    'employee': 'Personel Raporu',
    'customer': 'Müşteri Analizi',
    'supplier': 'Tedarikçi Analizi',
    'production': 'Üretim Raporu',
    'profitability': 'Karlılık Analizi',
    'model_cost': 'Model Maliyetleri',
  };

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    
    try {
      Map<String, dynamic> data = {};
      
      switch (_selectedReportType) {
        case 'sales':
          data = await _generateSalesReport();
          break;
        case 'purchases':
          data = await _generatePurchasesReport();
          break;
        case 'inventory':
          data = await _generateInventoryReport();
          break;
        case 'financial':
          data = await _generateFinancialReport();
          break;
        case 'employee':
          data = await _generateEmployeeReport();
          break;
        case 'customer':
          data = await _generateCustomerAnalysis();
          break;
        case 'supplier':
          data = await _generateSupplierAnalysis();
          break;
        case 'production':
          data = await _generateProductionReport();
          break;
        case 'profitability':
          data = await _generateProfitabilityReport();
          break;
        case 'model_cost':
          // Model maliyetleri için özel işlem yok, widget'ta gösterilecek
          data = {'type': 'model_cost'};
          break;
      }
      
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      context.showSnackBar('Rapor oluşturulurken hata: $e');
    }
  }

  Future<Map<String, dynamic>> _generateSalesReport() async {
    final faturalar = await _supabase
        .from(DbTables.faturalar)
        .select('''
          *,
          musteriler (ad, soyad, sirket),
          fatura_kalemleri (*)
        ''')
        .eq('firma_id', _firmaId)
        .eq('fatura_turu', 'satis')
        .gte('fatura_tarihi', _startDate.toIso8601String().substring(0, 10))
        .lte('fatura_tarihi', _endDate.toIso8601String().substring(0, 10))
        .order('fatura_tarihi', ascending: false);

    double totalSales = 0;
    double totalTax = 0;
    final Map<String, double> customerSales = {};
    final Map<String, int> monthlySales = {};

    for (var fatura in faturalar) {
      totalSales += (fatura['toplam_tutar'] ?? 0).toDouble();
      totalTax += (fatura['kdv_tutari'] ?? 0).toDouble();
      
      // Müşteri bazlı satışlar
      String customerName = '${fatura[DbTables.musteriler]?['ad'] ?? ''} ${fatura[DbTables.musteriler]?['soyad'] ?? ''}';
      if (fatura[DbTables.musteriler]?['sirket'] != null) {
        customerName = fatura[DbTables.musteriler]['sirket'];
      }
      customerSales[customerName] = (customerSales[customerName] ?? 0) + (fatura['toplam_tutar'] ?? 0).toDouble();
      
      // Aylık satışlar
      final String month = DateTime.parse(fatura['fatura_tarihi']).toString().substring(0, 7);
      monthlySales[month] = (monthlySales[month] ?? 0) + 1;
    }

    // En çok satan müşteriler
    final topCustomers = customerSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_sales': totalSales,
      'total_tax': totalTax,
      'total_invoices': faturalar.length,
      'top_customers': topCustomers.take(10).toList(),
      'monthly_sales': monthlySales,
      'invoices': faturalar,
      'average_invoice': faturalar.isNotEmpty ? totalSales / faturalar.length : 0,
    };
  }

  Future<Map<String, dynamic>> _generatePurchasesReport() async {
    final faturalar = await _supabase
        .from(DbTables.faturalar)
        .select('''
          *,
          tedarikciler (ad, soyad, sirket),
          fatura_kalemleri (*)
        ''')
        .eq('firma_id', _firmaId)
        .eq('fatura_turu', 'alis')
        .gte('fatura_tarihi', _startDate.toIso8601String().substring(0, 10))
        .lte('fatura_tarihi', _endDate.toIso8601String().substring(0, 10))
        .order('fatura_tarihi', ascending: false);

    double totalPurchases = 0;
    final Map<String, double> supplierPurchases = {};

    for (var fatura in faturalar) {
      totalPurchases += (fatura['toplam_tutar'] ?? 0).toDouble();
      
      String supplierName = '${fatura[DbTables.tedarikciler]?['ad'] ?? ''} ${fatura[DbTables.tedarikciler]?['soyad'] ?? ''}';
      if (fatura[DbTables.tedarikciler]?['sirket'] != null) {
        supplierName = fatura[DbTables.tedarikciler]['sirket'];
      }
      supplierPurchases[supplierName] = (supplierPurchases[supplierName] ?? 0) + (fatura['toplam_tutar'] ?? 0).toDouble();
    }

    final topSuppliers = supplierPurchases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_purchases': totalPurchases,
      'total_invoices': faturalar.length,
      'top_suppliers': topSuppliers.take(10).toList(),
      'invoices': faturalar,
      'average_purchase': faturalar.isNotEmpty ? totalPurchases / faturalar.length : 0,
    };
  }

  Future<Map<String, dynamic>> _generateInventoryReport() async {
    final iplikStoklar = await _supabase
        .from(DbTables.iplikStoklari)
        .select('*')
        .eq('firma_id', _firmaId);
    
    final aksesuarlar = await _supabase
        .from(DbTables.aksesuarlar)
        .select('*')
        .eq('firma_id', _firmaId);

    double totalInventoryValue = 0;
    final List<Map<String, dynamic>> lowStockItems = [];
    final List<Map<String, dynamic>> highValueItems = [];

    // İplik stokları analizi
    for (var iplik in iplikStoklar) {
      final double value = ((iplik['miktar'] ?? 0) * (iplik['birim_fiyat'] ?? 0)).toDouble();
      totalInventoryValue += value;
      
      if ((iplik['miktar'] ?? 0) < 10) {
        lowStockItems.add({
          'name': iplik['ad'],
          'type': 'İplik',
          'quantity': iplik['miktar'],
          'unit': iplik['birim'],
        });
      }
      
      if (value > 1000) {
        highValueItems.add({
          'name': iplik['ad'],
          'type': 'İplik',
          'value': value,
          'quantity': iplik['miktar'],
        });
      }
    }

    // Aksesuar analizi
    for (var aksesuar in aksesuarlar) {
      final double value = ((aksesuar['stok_adet'] ?? 0) * (aksesuar['birim_fiyat'] ?? 0)).toDouble();
      totalInventoryValue += value;
      
      if ((aksesuar['stok_adet'] ?? 0) < 5) {
        lowStockItems.add({
          'name': aksesuar['ad'],
          'type': 'Aksesuar',
          'quantity': aksesuar['stok_adet'],
          'unit': 'adet',
        });
      }
    }

    return {
      'total_value': totalInventoryValue,
      'total_yarn_items': iplikStoklar.length,
      'total_accessories': aksesuarlar.length,
      'low_stock_items': lowStockItems,
      'high_value_items': highValueItems..sort((a, b) => b['value'].compareTo(a['value'])),
    };
  }

  Future<Map<String, dynamic>> _generateFinancialReport() async {
    double totalRevenue = 0;
    double totalProductionCost = 0;
    double totalMaterialCost = 0;
    double totalFireCost = 0;
    double personnelCosts = 0;
    double otherExpenses = 0;
    int completedOrdersCount = 0;
    
    // 1. Tamamlanan siparişlerden gelir hesapla
    try {
      final tamamlananSiparisler = await _supabase
          .from(DbTables.trikoTakip)
          .select('adet, satis_fiyati, maliyet, created_at')
          .eq('firma_id', _firmaId)
          .eq('tamamlandi', true)
          .gte('created_at', _startDate.toIso8601String())
          .lte('created_at', _endDate.toIso8601String());
      
      completedOrdersCount = tamamlananSiparisler.length;
      
      for (var siparis in tamamlananSiparisler) {
        final int adet = siparis['adet'] ?? 0;
        final double satisFiyati = (siparis['satis_fiyati'] ?? 0).toDouble();
        final double maliyet = (siparis['maliyet'] ?? 0).toDouble();
        
        totalRevenue += (adet * satisFiyati);
        totalProductionCost += (adet * maliyet);
      }
    } catch (e) {
      debugPrint('Sipariş verileri alınamadı: $e');
    }

    // 2. Malzeme maliyetleri (İplik + Aksesuar)
    try {
      // İplik stok hareketleri
      final iplikCikislar = await _supabase
          .from(DbTables.iplikStokHareketleri)
          .select('miktar, birim_fiyat')
          .eq('firma_id', _firmaId)
          .eq('islem_turu', 'cikis')
          .gte('created_at', _startDate.toIso8601String())
          .lte('created_at', _endDate.toIso8601String());
      
      for (var hareket in iplikCikislar) {
        final double miktar = (hareket['miktar'] ?? 0).toDouble();
        final double fiyat = (hareket['birim_fiyat'] ?? 0).toDouble();
        totalMaterialCost += (miktar * fiyat);
      }
    } catch (e) {
      debugPrint('İplik maliyetleri alınamadı: $e');
    }

    try {
      // Aksesuar kullanımları
      final aksesuarKullanimlari = await _supabase
          .from(DbTables.aksesuarKullanim)
          .select('miktar, birim_fiyat')
          .eq('firma_id', _firmaId)
          .gte('created_at', _startDate.toIso8601String())
          .lte('created_at', _endDate.toIso8601String());
      
      for (var kullanim in aksesuarKullanimlari) {
        final double miktar = (kullanim['miktar'] ?? 0).toDouble();
        final double fiyat = (kullanim['birim_fiyat'] ?? 0).toDouble();
        totalMaterialCost += (miktar * fiyat);
      }
    } catch (e) {
      debugPrint('Aksesuar maliyetleri alınamadı: $e');
    }

    // 3. Fire maliyetleri (tüm aşamalardan)
    try {
      final asamalar = [DbTables.dokumaAtamalari, DbTables.konfeksiyonAtamalari, DbTables.yikamaAtamalari, 
                       DbTables.utuAtamalari, DbTables.ilikDugmeAtamalari, DbTables.kaliteKontrolAtamalari];
      
      for (var asama in asamalar) {
        try {
          final fireData = await _supabase
              .from(asama)
              .select('fire_adet, model_id')
              .eq('firma_id', _firmaId)
              .gte('created_at', _startDate.toIso8601String())
              .lte('created_at', _endDate.toIso8601String());
          
          for (var data in fireData) {
            final int fireAdet = data['fire_adet'] ?? 0;
            if (fireAdet > 0 && data['model_id'] != null) {
              // Model maliyetini al
              try {
                final model = await _supabase
                    .from(DbTables.trikoTakip)
                    .select('maliyet')
                    .eq('id', data['model_id'])
                    .maybeSingle();
                
                if (model != null) {
                  final double birimMaliyet = (model['maliyet'] ?? 0).toDouble();
                  totalFireCost += (fireAdet * birimMaliyet);
                }
              } catch (e) {
                // Model bulunamadı, devam et
              }
            }
          }
        } catch (e) {
          // Tablo yoksa devam et
        }
      }
    } catch (e) {
      debugPrint('Fire maliyetleri alınamadı: $e');
    }

    // 4. Personel giderleri
    try {
      final bordro = await _supabase
          .from(DbTables.bordro)
          .select('net_maas')
          .eq('firma_id', _firmaId)
          .gte('created_at', _startDate.toIso8601String())
          .lte('created_at', _endDate.toIso8601String());
      
      personnelCosts = bordro.fold(0, (sum, item) => sum + (item['net_maas'] ?? 0).toDouble());
    } catch (e) {
      debugPrint('Bordro verileri alınamadı: $e');
    }

    // 5. Diğer giderler (Faturalar - Alış)
    try {
      final giderFaturalar = await _supabase
          .from(DbTables.faturalar)
          .select('toplam_tutar')
          .eq('firma_id', _firmaId)
          .eq('fatura_turu', 'alis')
          .gte('fatura_tarihi', _startDate.toIso8601String().substring(0, 10))
          .lte('fatura_tarihi', _endDate.toIso8601String().substring(0, 10));
      
      otherExpenses = giderFaturalar.fold(0, (sum, item) => sum + (item['toplam_tutar'] ?? 0).toDouble());
    } catch (e) {
      debugPrint('Gider faturaları alınamadı: $e');
    }

    // Toplam giderler
    final double totalExpenses = totalProductionCost + totalMaterialCost + totalFireCost + personnelCosts + otherExpenses;
    
    // Net kar/zarar
    final double netProfit = totalRevenue - totalExpenses;
    final double profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;
    
    // Brüt kar (sadece üretim maliyeti düşüldükten sonra)
    final double grossProfit = totalRevenue - totalProductionCost - totalMaterialCost;
    final double grossMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0;

    return {
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'production_cost': totalProductionCost,
      'material_cost': totalMaterialCost,
      'fire_cost': totalFireCost,
      'personnel_costs': personnelCosts,
      'other_expenses': otherExpenses,
      'gross_profit': grossProfit,
      'gross_margin': grossMargin,
      'net_profit': netProfit,
      'profit_margin': profitMargin,
      'completed_orders': completedOrdersCount,
    };
  }

  Future<Map<String, dynamic>> _generateEmployeeReport() async {
    final personeller = await _supabase
        .from(DbTables.personel)
        .select('*')
        .eq('firma_id', _firmaId);

    final izinler = await _supabase
        .from(DbTables.izinler)
        .select('*')
        .eq('firma_id', _firmaId)
        .gte('baslama_tarihi', _startDate.toIso8601String().substring(0, 10)) // Database column: baslama_tarihi
        .lte('bitis_tarihi', _endDate.toIso8601String().substring(0, 10)); // Database column: bitis_tarihi

    final mesailer = await _supabase
        .from(DbTables.mesai)
        .select('*')
        .eq('firma_id', _firmaId)
        .gte('tarih', _startDate.toIso8601String().substring(0, 10))
        .lte('tarih', _endDate.toIso8601String().substring(0, 10));

    final Map<String, int> departmanDagilimi = {};
    final Map<String, double> maasAraliklari = {
      '0-5000': 0,
      '5000-10000': 0,
      '10000-15000': 0,
      '15000+': 0,
    };

    for (var personel in personeller) {
      // Departman dağılımı
      final String departman = personel['departman'] ?? 'Belirtilmemiş';
      departmanDagilimi[departman] = (departmanDagilimi[departman] ?? 0) + 1;
      
      // Maaş aralıkları
      final double maas = (personel['brut_maas'] ?? 0).toDouble();
      if (maas < 5000) {
        maasAraliklari['0-5000'] = maasAraliklari['0-5000']! + 1;
      } else if (maas < 10000) {
        maasAraliklari['5000-10000'] = maasAraliklari['5000-10000']! + 1;
      } else if (maas < 15000) {
        maasAraliklari['10000-15000'] = maasAraliklari['10000-15000']! + 1;
      } else {
        maasAraliklari['15000+'] = maasAraliklari['15000+']! + 1;
      }
    }

    return {
      'total_employees': personeller.length,
      'total_leaves': izinler.length,
      'total_overtime_hours': mesailer.fold(0.0, (sum, item) => sum + (item['saat'] ?? 0).toDouble()),
      'department_distribution': departmanDagilimi,
      'salary_ranges': maasAraliklari,
      'active_employees': personeller.where((p) => p['durum'] == 'aktif').length,
    };
  }

  Future<Map<String, dynamic>> _generateCustomerAnalysis() async {
    final musteriler = await _supabase
        .from(DbTables.musteriler)
        .select('*')
        .eq('firma_id', _firmaId);

    final siparisler = await _supabase
        .from(DbTables.trikoTakip)
        .select('*, musteriler(ad, soyad, sirket)')
        .eq('firma_id', _firmaId)
        .gte('created_at', _startDate.toIso8601String())
        .lte('created_at', _endDate.toIso8601String());

    final Map<String, Map<String, dynamic>> customerAnalysis = {};

    for (var siparis in siparisler) {
      final String customerId = siparis['musteri_id']?.toString() ?? 'unknown';
      final String customerName = siparis[DbTables.musteriler]?['sirket'] ?? 
          '${siparis[DbTables.musteriler]?['ad'] ?? ''} ${siparis[DbTables.musteriler]?['soyad'] ?? ''}';
      
      if (!customerAnalysis.containsKey(customerId)) {
        customerAnalysis[customerId] = {
          'name': customerName,
          'order_count': 0,
          'total_pieces': 0,
          'completed_orders': 0,
        };
      }
      
      customerAnalysis[customerId]!['order_count']++;
      customerAnalysis[customerId]!['total_pieces'] += (siparis['adet'] ?? 0);
      if (siparis['tamamlandi'] == true) {
        customerAnalysis[customerId]!['completed_orders']++;
      }
    }

    final topCustomers = customerAnalysis.values.toList()
      ..sort((a, b) => b['order_count'].compareTo(a['order_count']));

    return {
      'total_customers': musteriler.length,
      'active_customers': customerAnalysis.length,
      'customer_analysis': topCustomers.take(10).toList(),
      'new_customers': musteriler.where((m) => 
          DateTime.parse(m['kayit_tarihi']).isAfter(_startDate)).length,
    };
  }

  Future<Map<String, dynamic>> _generateSupplierAnalysis() async {
    final tedarikciler = await _supabase
        .from(DbTables.tedarikciler)
        .select('*')
        .eq('firma_id', _firmaId);

    return {
      'total_suppliers': tedarikciler.length,
      'active_suppliers': tedarikciler.where((t) => t['durum'] == 'aktif').length,
      'supplier_types': tedarikciler.fold<Map<String, int>>({}, (map, supplier) {
        final String type = supplier['tedarikci_tipi'] ?? 'Diğer';
        map[type] = (map[type] ?? 0) + 1;
        return map;
      }),
    };
  }

  Future<Map<String, dynamic>> _generateProductionReport() async {
    final siparisler = await _supabase
        .from(DbTables.trikoTakip)
        .select('*')
        .eq('firma_id', _firmaId)
        .gte('created_at', _startDate.toIso8601String())
        .lte('created_at', _endDate.toIso8601String());

    final int totalOrders = siparisler.length;
    final int completedOrders = siparisler.where((s) => s['tamamlandi'] == true).length;
    final int totalPieces = siparisler.fold(0, (sum, item) => sum + ((item['adet'] ?? 0) as int));
    final int producedPieces = siparisler.fold(0, (sum, item) => sum + ((item['yuklenen_adet'] ?? 0) as int));

    final Map<String, int> brandAnalysis = {};
    for (var siparis in siparisler) {
      final String brand = siparis['marka'] ?? 'Belirtilmemiş';
      brandAnalysis[brand] = (brandAnalysis[brand] ?? 0) + ((siparis['adet'] ?? 0) as int);
    }

    final topBrands = brandAnalysis.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'completion_rate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0,
      'total_pieces': totalPieces,
      'produced_pieces': producedPieces,
      'production_rate': totalPieces > 0 ? (producedPieces / totalPieces) * 100 : 0,
      'top_brands': topBrands.take(10).toList(),
    };
  }

  Future<Map<String, dynamic>> _generateProfitabilityReport() async {
    final salesData = await _generateSalesReport();
    final purchaseData = await _generatePurchasesReport();
    final financialData = await _generateFinancialReport();

    final double revenue = salesData['total_sales'] ?? 0;
    final double costs = purchaseData['total_purchases'] ?? 0;
    final double grossProfit = revenue - costs;
    final double grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0;

    return {
      'revenue': revenue,
      'costs': costs,
      'gross_profit': grossProfit,
      'gross_margin': grossMargin,
      'net_profit': financialData['net_profit'] ?? 0,
      'net_margin': financialData['profit_margin'] ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş Raporlar'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedReportType,
              decoration: const InputDecoration(
                labelText: 'Rapor Türü',
                border: OutlineInputBorder(),
              ),
              items: _reportTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                });
                _generateReport();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                        _generateReport();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Başlangıç Tarihi',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startDate.toString().substring(0, 10)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                        _generateReport();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Bitiş Tarihi',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_endDate.toString().substring(0, 10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
