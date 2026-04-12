import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonemYonetimiPage extends StatefulWidget {
  const DonemYonetimiPage({super.key});

  @override
  State<DonemYonetimiPage> createState() => _DonemYonetimiPageState();
}

class _DonemYonetimiPageState extends State<DonemYonetimiPage> {
  List<Map<String, dynamic>> donemler = [];
  bool yukleniyor = true;
  String? aktifDonem;

  @override
  void initState() {
    super.initState();
    _loadDonemler();
  }

  Future<void> _loadDonemler() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from(DbTables.donemler)
          .select()
          .order('baslangic_tarihi', ascending: false);
      
      setState(() {
        donemler = List<Map<String, dynamic>>.from(response);
        // Aktif dönemi bul
        aktifDonem = donemler.firstWhere(
          (d) => d['aktif'] == true,
          orElse: () => {},
        )['kod'];
        yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
    }
  }

  Future<void> _yeniDonemEkle() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DonemEkleDialog(),
    );

    if (result != null) {
      try {
        final client = Supabase.instance.client;
        await client.from(DbTables.donemler).insert(result);
        _loadDonemler();
        
        if (!mounted) return;
        context.showSnackBar('Dönem başarıyla eklendi');
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Hata: $e');
      }
    }
  }

  Future<void> _donemAktifYap(String donemKodu) async {
    try {
      final client = Supabase.instance.client;
      
      // Önce tüm dönemleri pasif yap
      await client.from(DbTables.donemler).update({'aktif': false}).neq('kod', '');
      
      // Seçilen dönemi aktif yap
      await client.from(DbTables.donemler).update({'aktif': true}).eq('kod', donemKodu);
      
      if (!mounted) return;
      setState(() {
        aktifDonem = donemKodu;
      });
      
      if (!mounted) return;
      context.showSnackBar('Dönem $donemKodu aktif olarak ayarlandı');
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dönem Yönetimi'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _yeniDonemEkle,
            tooltip: 'Yeni Dönem Ekle',
          ),
        ],
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aktif Dönem: ${aktifDonem ?? "Seçilmemiş"}\n'
                              'Tüm personel işlemleri bu dönem altında kaydedilir.',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dönemler',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: donemler.length,
                      itemBuilder: (context, index) {
                        final donem = donemler[index];
                        final isAktif = donem['aktif'] == true;
                        
                        return Card(
                          elevation: isAktif ? 4 : 1,
                          color: isAktif ? Colors.green.shade50 : null,
                          child: ListTile(
                            leading: Icon(
                              isAktif ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isAktif ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              donem['ad'],
                              style: TextStyle(
                                fontWeight: isAktif ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'Kod: ${donem['kod']}\n'
                              '${donem['baslangic_tarihi']} - ${donem['bitis_tarihi']}',
                            ),
                            trailing: isAktif
                                ? const Chip(
                                    label: Text('AKTİF'),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : TextButton(
                                    onPressed: () => _donemAktifYap(donem['kod']),
                                    child: const Text('Aktif Yap'),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DonemEkleDialog extends StatefulWidget {
  @override
  State<_DonemEkleDialog> createState() => _DonemEkleDialogState();
}

class _DonemEkleDialogState extends State<_DonemEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _kodController = TextEditingController();
  DateTime? _baslangicTarihi;
  DateTime? _bitisTarihi;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Dönem Ekle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _adController,
              decoration: const InputDecoration(labelText: 'Dönem Adı'),
              validator: (value) => value?.isEmpty == true ? 'Dönem adı gerekli' : null,
            ),
            TextFormField(
              controller: _kodController,
              decoration: const InputDecoration(labelText: 'Dönem Kodu (örn: 2025-1)'),
              validator: (value) => value?.isEmpty == true ? 'Dönem kodu gerekli' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _baslangicTarihi = date;
                        });
                      }
                    },
                    child: Text(_baslangicTarihi == null 
                        ? 'Başlangıç Tarihi'
                        : '${_baslangicTarihi!.day}/${_baslangicTarihi!.month}/${_baslangicTarihi!.year}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _bitisTarihi = date;
                        });
                      }
                    },
                    child: Text(_bitisTarihi == null 
                        ? 'Bitiş Tarihi'
                        : '${_bitisTarihi!.day}/${_bitisTarihi!.month}/${_bitisTarihi!.year}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && 
                _baslangicTarihi != null && 
                _bitisTarihi != null) {
              Navigator.of(context).pop({
                'ad': _adController.text,
                'kod': _kodController.text,
                'baslangic_tarihi': _baslangicTarihi!.toIso8601String().split('T')[0],
                'bitis_tarihi': _bitisTarihi!.toIso8601String().split('T')[0],
                'aktif': false,
                'created_at': DateTime.now().toIso8601String(),
              });
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
