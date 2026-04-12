import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MuhasebeYonetimiPage extends StatefulWidget {
  const MuhasebeYonetimiPage({super.key});

  @override
  State<MuhasebeYonetimiPage> createState() => _MuhasebeYonetimiPageState();
}

class _MuhasebeYonetimiPageState extends State<MuhasebeYonetimiPage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  late TabController _tabController;
  
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  
  Map<String, dynamic> _muhasebeData = {
    'yevmiye_kayitlari': <Map<String, dynamic>>[],
    'hesap_plani': <Map<String, dynamic>>[],
    'mizan': <Map<String, dynamic>>[],
    'kar_zarar': <Map<String, dynamic>>[],
    'bilanco': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMuhasebeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMuhasebeData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _loadYevmiyeKayitlari(),
        _loadHesapPlani(),
        _loadMizan(),
        _loadKarZarar(),
        _loadBilanco(),
      ]);
      
      setState(() {
        _muhasebeData = {
          'yevmiye_kayitlari': results[0],
          'hesap_plani': results[1],
          'mizan': results[2],
          'kar_zarar': results[3],
          'bilanco': results[4],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Muhasebe verileri yüklenirken hata oluştu: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadYevmiyeKayitlari() async {
    try {
      final response = await _supabase
          .from(DbTables.yevmiyeKayitlari)
          .select('*')
          .gte('tarih', DateTime(_selectedDate.year, _selectedDate.month, 1).toIso8601String())
          .lt('tarih', DateTime(_selectedDate.year, _selectedDate.month + 1, 1).toIso8601String())
          .order('tarih', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadHesapPlani() async {
    try {
      final response = await _supabase
          .from(DbTables.hesapPlani)
          .select('*')
          .order('hesap_kodu', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadMizan() async {
    try {
      final response = await _supabase
          .from(DbTables.mizanView)
          .select('*')
          .gte('tarih', DateTime(_selectedDate.year, _selectedDate.month, 1).toIso8601String())
          .lt('tarih', DateTime(_selectedDate.year, _selectedDate.month + 1, 1).toIso8601String());
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadKarZarar() async {
    try {
      final response = await _supabase
          .from(DbTables.karZararView)
          .select('*')
          .gte('tarih', DateTime(_selectedDate.year, 1, 1).toIso8601String())
          .lt('tarih', DateTime(_selectedDate.year + 1, 1, 1).toIso8601String())
          .single();
      
      return response;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadBilanco() async {
    try {
      final response = await _supabase
          .from(DbTables.bilancoView)
          .select('*')
          .eq('tarih', _selectedDate.toIso8601String().substring(0, 10))
          .single();
      
      return response;
    } catch (e) {
      return {};
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _yeniYevmiyeKaydi() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _YevmiyeKaydiDialog(hesapPlani: _muhasebeData['hesap_plani']),
    );
    
    if (result != null) {
      try {
        await _supabase.from(DbTables.yevmiyeKayitlari).insert(result);
        _showSuccess('Yevmiye kaydı başarıyla eklendi');
        _loadMuhasebeData();
      } catch (e) {
        _showError('Yevmiye kaydı eklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _yeniHesapEkle() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _HesapEkleDialog(),
    );
    
    if (result != null) {
      try {
        await _supabase.from(DbTables.hesapPlani).insert(result);
        _showSuccess('Hesap başarıyla eklendi');
        _loadMuhasebeData();
      } catch (e) {
        _showError('Hesap eklenirken hata oluştu: $e');
      }
    }
  }

  Widget _buildYevmiyeTab() {
    final yevmiyeKayitlari = _muhasebeData['yevmiye_kayitlari'] as List<Map<String, dynamic>>;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Yevmiye Defteri - ${DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
              ElevatedButton.icon(
                onPressed: _yeniYevmiyeKaydi,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Kayıt'),
              ),
            ],
          ),
        ),
        Expanded(
          child: yevmiyeKayitlari.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Yevmiye kaydı bulunamadı'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: yevmiyeKayitlari.length,
                  itemBuilder: (context, index) {
                    return _buildYevmiyeCard(yevmiyeKayitlari[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildYevmiyeCard(Map<String, dynamic> kayit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fiş No: ${kayit['fis_no']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(kayit['tarih'])),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(kayit['aciklama'] ?? ''),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Borç', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${kayit['borc_hesap_adi']} (${kayit['borc_hesap_kodu']})'),
                      Text(
                        _currencyFormat.format(kayit['tutar']),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alacak', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${kayit['alacak_hesap_adi']} (${kayit['alacak_hesap_kodu']})'),
                      Text(
                        _currencyFormat.format(kayit['tutar']),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHesapPlaniTab() {
    final hesapPlani = _muhasebeData['hesap_plani'] as List<Map<String, dynamic>>;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Hesap Planı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _yeniHesapEkle,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Hesap'),
              ),
            ],
          ),
        ),
        Expanded(
          child: hesapPlani.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Hesap bulunamadı'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hesapPlani.length,
                  itemBuilder: (context, index) {
                    return _buildHesapCard(hesapPlani[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHesapCard(Map<String, dynamic> hesap) {
    final seviye = (hesap['hesap_kodu'] as String).length;
    final indent = (seviye - 1) * 20.0;
    
    return Card(
      margin: EdgeInsets.only(left: indent, bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getHesapRengi(hesap['hesap_tipi']),
          child: Text(
            hesap['hesap_kodu'].substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${hesap['hesap_kodu']} - ${hesap['hesap_adi']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(hesap['hesap_tipi']),
        trailing: hesap['aktif'] == true 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.red),
      ),
    );
  }

  Color _getHesapRengi(String hesapTipi) {
    switch (hesapTipi) {
      case 'Aktif':
        return Colors.green;
      case 'Pasif':
        return Colors.red;
      case 'Gelir':
        return Colors.blue;
      case 'Gider':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMizanTab() {
    final mizan = _muhasebeData['mizan'] as List<Map<String, dynamic>>;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Mizan - ${DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: mizan.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.balance, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Mizan verisi bulunamadı'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Hesap Kodu')),
                      DataColumn(label: Text('Hesap Adı')),
                      DataColumn(label: Text('Borç')),
                      DataColumn(label: Text('Alacak')),
                      DataColumn(label: Text('Bakiye')),
                    ],
                    rows: mizan.map((item) {
                      final borc = (item['borc_toplam'] ?? 0.0).toDouble();
                      final alacak = (item['alacak_toplam'] ?? 0.0).toDouble();
                      final bakiye = borc - alacak;
                      
                      return DataRow(
                        cells: [
                          DataCell(Text(item['hesap_kodu'] ?? '')),
                          DataCell(Text(item['hesap_adi'] ?? '')),
                          DataCell(Text(_currencyFormat.format(borc))),
                          DataCell(Text(_currencyFormat.format(alacak))),
                          DataCell(
                            Text(
                              _currencyFormat.format(bakiye.abs()),
                              style: TextStyle(
                                color: bakiye >= 0 ? Colors.black : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildKarZararTab() {
    final karZarar = _muhasebeData['kar_zarar'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kar Zarar Tablosu - ${_selectedDate.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildKarZararCard('Satış Gelirleri', karZarar['satis_gelirleri'] ?? 0, Colors.green),
          _buildKarZararCard('Satışların Maliyeti', karZarar['satis_maliyeti'] ?? 0, Colors.red),
          const Divider(),
          _buildKarZararCard('Brüt Kar', (karZarar['satis_gelirleri'] ?? 0) - (karZarar['satis_maliyeti'] ?? 0), Colors.blue),
          _buildKarZararCard('Faaliyet Giderleri', karZarar['faaliyet_giderleri'] ?? 0, Colors.red),
          const Divider(),
          _buildKarZararCard('Faaliyet Karı', karZarar['faaliyet_kari'] ?? 0, Colors.purple),
          _buildKarZararCard('Finansman Giderleri', karZarar['finansman_giderleri'] ?? 0, Colors.red),
          const Divider(thickness: 2),
          _buildKarZararCard('Net Kar/Zarar', karZarar['net_kar'] ?? 0, Colors.indigo, isBold: true),
        ],
      ),
    );
  }

  Widget _buildKarZararCard(String title, double amount, Color color, {bool isBold = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilancoTab() {
    final bilanco = _muhasebeData['bilanco'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bilanço - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AKTİF',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildBilancoKart('Dönen Varlıklar', bilanco['donen_varliklar'] ?? 0),
                    _buildBilancoKart('Duran Varlıklar', bilanco['duran_varliklar'] ?? 0),
                    const Divider(),
                    _buildBilancoKart('TOPLAM AKTİF', bilanco['toplam_aktif'] ?? 0, isBold: true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASİF',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildBilancoKart('Kısa Vadeli Yükümlülükler', bilanco['kisa_vadeli_yukumlulukler'] ?? 0),
                    _buildBilancoKart('Uzun Vadeli Yükümlülükler', bilanco['uzun_vadeli_yukumlulukler'] ?? 0),
                    _buildBilancoKart('Özkaynak', bilanco['ozkaynak'] ?? 0),
                    const Divider(),
                    _buildBilancoKart('TOPLAM PASİF', bilanco['toplam_pasif'] ?? 0, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBilancoKart(String title, double amount, {bool isBold = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              _currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMuhasebeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muhasebe Yönetimi'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Yevmiye', icon: Icon(Icons.book)),
            Tab(text: 'Hesap Planı', icon: Icon(Icons.account_tree)),
            Tab(text: 'Mizan', icon: Icon(Icons.balance)),
            Tab(text: 'Kar/Zarar', icon: Icon(Icons.trending_up)),
            Tab(text: 'Bilanço', icon: Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildYevmiyeTab(),
                _buildHesapPlaniTab(),
                _buildMizanTab(),
                _buildKarZararTab(),
                _buildBilancoTab(),
              ],
            ),
    );
  }
}

class _YevmiyeKaydiDialog extends StatefulWidget {
  final List<Map<String, dynamic>> hesapPlani;
  
  const _YevmiyeKaydiDialog({required this.hesapPlani});

  @override
  State<_YevmiyeKaydiDialog> createState() => _YevmiyeKaydiDialogState();
}

class _YevmiyeKaydiDialogState extends State<_YevmiyeKaydiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fisNoController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _tutarController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedBorcHesap;
  String? _selectedAlacakHesap;

  @override
  void dispose() {
    _fisNoController.dispose();
    _aciklamaController.dispose();
    _tutarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Yevmiye Kaydı'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fisNoController,
                decoration: const InputDecoration(
                  labelText: 'Fiş No',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fiş no gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedBorcHesap,
                decoration: const InputDecoration(
                  labelText: 'Borç Hesabı',
                  border: OutlineInputBorder(),
                ),
                items: widget.hesapPlani.map((hesap) {
                  return DropdownMenuItem<String>(
                    value: hesap['hesap_kodu'],
                    child: Text('${hesap['hesap_kodu']} - ${hesap['hesap_adi']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBorcHesap = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Borç hesabı seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedAlacakHesap,
                decoration: const InputDecoration(
                  labelText: 'Alacak Hesabı',
                  border: OutlineInputBorder(),
                ),
                items: widget.hesapPlani.map((hesap) {
                  return DropdownMenuItem<String>(
                    value: hesap['hesap_kodu'],
                    child: Text('${hesap['hesap_kodu']} - ${hesap['hesap_adi']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAlacakHesap = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Alacak hesabı seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tutarController,
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  border: OutlineInputBorder(),
                  prefixText: '₺ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tutar gerekli';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = {
                'fis_no': _fisNoController.text,
                'tarih': _selectedDate.toIso8601String(),
                'borc_hesap_kodu': _selectedBorcHesap,
                'alacak_hesap_kodu': _selectedAlacakHesap,
                'tutar': double.parse(_tutarController.text),
                'aciklama': _aciklamaController.text,
                'olusturma_tarihi': DateTime.now().toIso8601String(),
              };
              Navigator.pop(context, result);
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _HesapEkleDialog extends StatefulWidget {
  const _HesapEkleDialog();

  @override
  State<_HesapEkleDialog> createState() => _HesapEkleDialogState();
}

class _HesapEkleDialogState extends State<_HesapEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hesapKoduController = TextEditingController();
  final _hesapAdiController = TextEditingController();
  
  String _selectedHesapTipi = 'Aktif';
  bool _aktif = true;
  
  final List<String> _hesapTipleri = ['Aktif', 'Pasif', 'Gelir', 'Gider'];

  @override
  void dispose() {
    _hesapKoduController.dispose();
    _hesapAdiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Hesap Ekle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _hesapKoduController,
              decoration: const InputDecoration(
                labelText: 'Hesap Kodu',
                border: OutlineInputBorder(),
                hintText: 'Örn: 100, 120, 600',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hesap kodu gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hesapAdiController,
              decoration: const InputDecoration(
                labelText: 'Hesap Adı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hesap adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedHesapTipi,
              decoration: const InputDecoration(
                labelText: 'Hesap Tipi',
                border: OutlineInputBorder(),
              ),
              items: _hesapTipleri.map((tip) {
                return DropdownMenuItem(
                  value: tip,
                  child: Text(tip),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHesapTipi = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Aktif'),
              value: _aktif,
              onChanged: (value) {
                setState(() {
                  _aktif = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = {
                'hesap_kodu': _hesapKoduController.text,
                'hesap_adi': _hesapAdiController.text,
                'hesap_tipi': _selectedHesapTipi,
                'aktif': _aktif,
                'olusturma_tarihi': DateTime.now().toIso8601String(),
              };
              Navigator.pop(context, result);
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
