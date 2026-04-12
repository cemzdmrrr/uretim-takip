// ignore_for_file: invalid_use_of_protected_member
part of 'advanced_reports_page.dart';

/// Advanced reports - rapor icerikleri ve export islemleri
extension _ContentExt on _AdvancedReportsPageState {
  Widget _buildReportContent() {
    if (_reportData.isEmpty) {
      return const Center(child: Text('Rapor verisi bulunamadı'));
    }

    switch (_selectedReportType) {
      case 'sales':
        return _buildSalesReportContent();
      case 'financial':
        return _buildFinancialReportContent();
      case 'inventory':
        return _buildInventoryReportContent();
      case 'employee':
        return _buildEmployeeReportContent();
      case 'model_cost':
        return const ModelMaliyetRaporWidget();
      default:
        return _buildGenericReportContent();
    }
  }

  Widget _buildSalesReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards([
            {
              'title': 'Toplam Satış',
              'value': '₺${_reportData['total_sales']?.toStringAsFixed(2) ?? '0'}',
              'icon': Icons.trending_up,
              'color': Colors.green,
            },
            {
              'title': 'Fatura Sayısı',
              'value': '${_reportData['total_invoices'] ?? 0}',
              'icon': Icons.receipt,
              'color': Colors.blue,
            },
            {
              'title': 'Ortalama Fatura',
              'value': '₺${_reportData['average_invoice']?.toStringAsFixed(2) ?? '0'}',
              'icon': Icons.analytics,
              'color': Colors.orange,
            },
            {
              'title': 'KDV Toplamı',
              'value': '₺${_reportData['total_tax']?.toStringAsFixed(2) ?? '0'}',
              'icon': Icons.account_balance,
              'color': Colors.purple,
            },
          ]),
          const SizedBox(height: 20),
          _buildTopCustomersChart(),
        ],
      ),
    );
  }

  Widget _buildFinancialReportContent() {
    final double netProfit = _reportData['net_profit'] ?? 0;
    final Color profitColor = netProfit >= 0 ? Colors.green : Colors.red;
    
    final double totalRevenue = _reportData['total_revenue'] ?? 0;
    final double productionCost = _reportData['production_cost'] ?? 0;
    final double materialCost = _reportData['material_cost'] ?? 0;
    final double fireCost = _reportData['fire_cost'] ?? 0;
    final double personnelCosts = _reportData['personnel_costs'] ?? 0;
    final double otherExpenses = _reportData['other_expenses'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana Özet Kartları
          _buildSummaryCards([
            {
              'title': 'Toplam Gelir',
              'value': '₺${totalRevenue.toStringAsFixed(2)}',
              'subtitle': '${_reportData['completed_orders'] ?? 0} sipariş',
              'icon': Icons.trending_up,
              'color': Colors.green,
            },
            {
              'title': 'Brüt Kar',
              'value': '₺${(_reportData['gross_profit'] ?? 0).toStringAsFixed(2)}',
              'subtitle': '%${(_reportData['gross_margin'] ?? 0).toStringAsFixed(1)} marj',
              'icon': Icons.monetization_on,
              'color': Colors.blue,
            },
            {
              'title': 'Net Kar/Zarar',
              'value': '₺${netProfit.toStringAsFixed(2)}',
              'subtitle': '%${(_reportData['profit_margin'] ?? 0).toStringAsFixed(1)} marj',
              'icon': Icons.account_balance_wallet,
              'color': profitColor,
            },
            {
              'title': 'Toplam Gider',
              'value': '₺${(_reportData['total_expenses'] ?? 0).toStringAsFixed(2)}',
              'subtitle': 'Tüm giderler',
              'icon': Icons.trending_down,
              'color': Colors.red,
            },
          ]),
          
          const SizedBox(height: 24),
          
          // Gider Detayları Başlığı
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.indigo, size: 24),
              SizedBox(width: 8),
              Text(
                'Gider Dağılımı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Gider Detay Kartları
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildExpenseCard(
                'Üretim Maliyeti',
                productionCost,
                totalRevenue,
                Icons.factory,
                Colors.blue,
              ),
              _buildExpenseCard(
                'Malzeme Maliyeti',
                materialCost,
                totalRevenue,
                Icons.inventory_2,
                Colors.orange,
              ),
              _buildExpenseCard(
                'Fire Kaybı',
                fireCost,
                totalRevenue,
                Icons.warning_amber,
                Colors.red,
              ),
              _buildExpenseCard(
                'Personel Gideri',
                personnelCosts,
                totalRevenue,
                Icons.people,
                Colors.purple,
              ),
              _buildExpenseCard(
                'Diğer Giderler',
                otherExpenses,
                totalRevenue,
                Icons.receipt_long,
                Colors.teal,
              ),
              _buildExpenseCard(
                'Toplam Gider',
                _reportData['total_expenses'] ?? 0,
                totalRevenue,
                Icons.account_balance,
                Colors.grey,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Kar/Zarar Özeti
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: netProfit >= 0 
                    ? [Colors.green.shade50, Colors.green.shade100]
                    : [Colors.red.shade50, Colors.red.shade100],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: profitColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        netProfit >= 0 ? 'KAR' : 'ZARAR',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Toplam Gelir:', style: TextStyle(fontSize: 16)),
                      Text('₺${totalRevenue.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Toplam Gider:', style: TextStyle(fontSize: 16)),
                      Text('₺${(_reportData['total_expenses'] ?? 0).toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Kar/Zarar:', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₺${netProfit.toStringAsFixed(2)}', 
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: profitColor,
                        )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseCard(String title, double amount, double totalRevenue, IconData icon, Color color) {
    final double percentage = totalRevenue > 0 ? (amount / totalRevenue) * 100 : 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₺${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '%${percentage.toStringAsFixed(1)} / Gelir',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInventoryReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards([
            {
              'title': 'Toplam Stok Değeri',
              'value': '₺${_reportData['total_value']?.toStringAsFixed(2) ?? '0'}',
              'icon': Icons.inventory,
              'color': Colors.blue,
            },
            {
              'title': 'İplik Çeşidi',
              'value': '${_reportData['total_yarn_items'] ?? 0}',
              'icon': Icons.category,
              'color': Colors.green,
            },
            {
              'title': 'Aksesuar Çeşidi',
              'value': '${_reportData['total_accessories'] ?? 0}',
              'icon': Icons.build,
              'color': Colors.orange,
            },
            {
              'title': 'Düşük Stoklar',
              'value': '${(_reportData['low_stock_items'] as List?)?.length ?? 0}',
              'icon': Icons.warning,
              'color': Colors.red,
            },
          ]),
          const SizedBox(height: 20),
          _buildLowStockTable(),
        ],
      ),
    );
  }

  Widget _buildEmployeeReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCards([
            {
              'title': 'Toplam Personel',
              'value': '${_reportData['total_employees'] ?? 0}',
              'icon': Icons.people,
              'color': Colors.blue,
            },
            {
              'title': 'Aktif Personel',
              'value': '${_reportData['active_employees'] ?? 0}',
              'icon': Icons.person,
              'color': Colors.green,
            },
            {
              'title': 'Toplam İzin',
              'value': '${_reportData['total_leaves'] ?? 0}',
              'icon': Icons.event_busy,
              'color': Colors.orange,
            },
            {
              'title': 'Mesai Saatleri',
              'value': '${_reportData['total_overtime_hours']?.toStringAsFixed(1) ?? '0'}',
              'icon': Icons.access_time,
              'color': Colors.purple,
            },
          ]),
          const SizedBox(height: 20),
          _buildDepartmentChart(),
        ],
      ),
    );
  }

  Widget _buildGenericReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _reportTypes[_selectedReportType] ?? 'Rapor',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rapor Dönemi: ${_startDate.toString().substring(0, 10)} - ${_endDate.toString().substring(0, 10)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ..._reportData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            entry.value.toString(),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> cards) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  card['icon'],
                  size: 30,
                  color: card['color'],
                ),
                const SizedBox(height: 8),
                Text(
                  card['value'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: card['color'],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card['title'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (card['subtitle'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    card['subtitle'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCustomersChart() {
    final topCustomers = _reportData['top_customers'] as List? ?? [];
    
    if (topCustomers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('En çok satış yapılan müşteri bulunamadı'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En Çok Satış Yapılan Müşteriler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topCustomers.take(5).map((customer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        customer.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '₺${customer.value.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockTable() {
    final lowStockItems = _reportData['low_stock_items'] as List? ?? [];
    
    if (lowStockItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Düşük stoklu ürün bulunamadı'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Düşük Stoklu Ürünler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Ürün Adı')),
                  DataColumn(label: Text('Tür')),
                  DataColumn(label: Text('Miktar')),
                  DataColumn(label: Text('Birim')),
                ],
                rows: lowStockItems.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item['name'] ?? '')),
                      DataCell(Text(item['type'] ?? '')),
                      DataCell(Text('${item['quantity'] ?? 0}')),
                      DataCell(Text(item['unit'] ?? '')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentChart() {
    final departmentDist = _reportData['department_distribution'] as Map<String, dynamic>? ?? {};
    
    if (departmentDist.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Departman dağılımı bulunamadı'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Departman Dağılımı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...departmentDist.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value} kişi',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raporu Dışa Aktar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel Olarak Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Olarak Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportToExcel() {
    // Excel export implementation
    context.showSnackBar('Excel dışa aktarım başlatıldı...');
  }

  void _exportToPDF() {
    // PDF export implementation
    context.showSnackBar('PDF dışa aktarım başlatıldı...');
  }
}
