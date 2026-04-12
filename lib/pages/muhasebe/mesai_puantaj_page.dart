import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/models/puantaj_model.dart';
import 'package:uretim_takip/services/puantaj_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/personel_service.dart';

class MesaiPuantajPage extends StatefulWidget {
  const MesaiPuantajPage({super.key});

  @override
  State<MesaiPuantajPage> createState() => _MesaiPuantajPageState();
}

class _MesaiPuantajPageState extends State<MesaiPuantajPage> {
  List<PuantajModel> puantajlar = [];
  List<PersonelModel> personeller = [];
  bool yukleniyor = true;
  int seciliAy = DateTime.now().month;
  int seciliYil = DateTime.now().year;
  
  final puantajService = PuantajService();
  final personelService = PersonelService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => yukleniyor = true);
    
    try {
      // Personel listesini yükle
      personeller = await personelService.getPersoneller();
      
      // Puantaj verilerini yükle
      puantajlar = await puantajService.getPuantajlar(ay: seciliAy, yil: seciliYil);
      
      // Eğer seçili ay/yıl için puantaj yoksa, personeller için otomatik oluştur
      if (puantajlar.isEmpty && personeller.isNotEmpty) {
        await _createDefaultPuantaj();
      }
      
    } catch (e) {
      debugPrint('Puantaj verisi yükleme hatası: $e');
    }
    
    if (!mounted) return;
    setState(() => yukleniyor = false);
  }
  
  Future<void> _createDefaultPuantaj() async {
    try {
      for (final personel in personeller) {
        final puantaj = PuantajModel(
          id: '',
          personelId: personel.userId,
          ad: '${personel.ad} ${personel.soyad}',
          ay: seciliAy,
          yil: seciliYil,
          gun: 22, // Varsayılan çalışma günü
          calismaSaati: 176, // 22 gün * 8 saat
          fazlaMesai: 0,
          eksikGun: 0,
          devamsizlik: 0,
        );
        
        await puantajService.addPuantaj(puantaj, sendId: false);
      }
      
      // Verileri yeniden yükle
      puantajlar = await puantajService.getPuantajlar(ay: seciliAy, yil: seciliYil);
    } catch (e) {
      debugPrint('Varsayılan puantaj oluşturma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantaj Yönetimi', style: TextStyle(color: Colors.white)),
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
          : Column(
              children: [
                // Dönem Seçici
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text('Dönem:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: seciliAy,
                        items: List.generate(12, (index) {
                          final ay = index + 1;
                          return DropdownMenuItem(
                            value: ay,
                            child: Text(_getAyAdi(ay)),
                          );
                        }),
                        onChanged: (ay) {
                          if (ay != null) {
                            setState(() => seciliAy = ay);
                            _loadData();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: seciliYil,
                        items: List.generate(5, (index) {
                          final yil = DateTime.now().year - 2 + index;
                          return DropdownMenuItem(
                            value: yil,
                            child: Text(yil.toString()),
                          );
                        }),
                        onChanged: (yil) {
                          if (yil != null) {
                            setState(() => seciliYil = yil);
                            _loadData();
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Yeni Puantaj', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _showPuantajDialog(),
                      ),
                    ],
                  ),
                ),
                
                // Puantaj Tablosu
                Expanded(
                  child: puantajlar.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_chart, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Bu dönem için puantaj kaydı bulunamadı.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Personel', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Çalışma Günü', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Çalışma Saati', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Fazla Mesai', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Eksik Gün', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Devamsızlık', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: puantajlar.map((puantaj) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(puantaj.ad)),
                                    DataCell(Text('${puantaj.gun} gün')),
                                    DataCell(Text('${puantaj.calismaSaati} saat')),
                                    DataCell(Text('${puantaj.fazlaMesai} saat', style: const TextStyle(color: Colors.green))),
                                    DataCell(Text('${puantaj.eksikGun} gün', style: const TextStyle(color: Colors.orange))),
                                    DataCell(Text('${puantaj.devamsizlik} gün', style: const TextStyle(color: Colors.red))),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showPuantajDialog(puantaj: puantaj),
                                            tooltip: 'Düzenle',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deletePuantaj(puantaj),
                                            tooltip: 'Sil',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
  
  String _getAyAdi(int ay) {
    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return aylar[ay - 1];
  }
  
  void _showPuantajDialog({PuantajModel? puantaj}) {
    final isEdit = puantaj != null;
    String seciliPersonelId = puantaj?.personelId ?? '';
    int gun = puantaj?.gun ?? 22;
    int calismaSaati = puantaj?.calismaSaati ?? 176;
    int fazlaMesai = puantaj?.fazlaMesai ?? 0;
    int eksikGun = puantaj?.eksikGun ?? 0;
    int devamsizlik = puantaj?.devamsizlik ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Puantaj Düzenle' : 'Yeni Puantaj'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit)
                  DropdownButtonFormField<String>(
                    initialValue: seciliPersonelId.isEmpty ? null : seciliPersonelId,
                    decoration: const InputDecoration(labelText: 'Personel'),
                    items: personeller.map((p) => DropdownMenuItem(
                      value: p.userId,
                      child: Text('${p.ad} ${p.soyad}'),
                    )).toList(),
                    onChanged: (value) {
                      setDialogState(() => seciliPersonelId = value ?? '');
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: gun.toString(),
                  decoration: const InputDecoration(labelText: 'Çalışma Günü'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => gun = int.tryParse(value) ?? gun,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: calismaSaati.toString(),
                  decoration: const InputDecoration(labelText: 'Çalışma Saati'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => calismaSaati = int.tryParse(value) ?? calismaSaati,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: fazlaMesai.toString(),
                  decoration: const InputDecoration(labelText: 'Fazla Mesai (saat)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => fazlaMesai = int.tryParse(value) ?? fazlaMesai,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: eksikGun.toString(),
                  decoration: const InputDecoration(labelText: 'Eksik Gün'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => eksikGun = int.tryParse(value) ?? eksikGun,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: devamsizlik.toString(),
                  decoration: const InputDecoration(labelText: 'Devamsızlık (gün)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => devamsizlik = int.tryParse(value) ?? devamsizlik,
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
              onPressed: () async {
                if (!isEdit && seciliPersonelId.isEmpty) {
                  context.showSnackBar('Lütfen personel seçiniz');
                  return;
                }
                
                try {
                  final personelAd = personeller.firstWhere((p) => p.userId == seciliPersonelId).ad;
                  
                  final yeniPuantaj = PuantajModel(
                    id: puantaj?.id ?? '',
                    personelId: seciliPersonelId,
                    ad: personelAd,
                    ay: seciliAy,
                    yil: seciliYil,
                    gun: gun,
                    calismaSaati: calismaSaati,
                    fazlaMesai: fazlaMesai,
                    eksikGun: eksikGun,
                    devamsizlik: devamsizlik,
                  );
                  
                  if (isEdit) {
                    await puantajService.updatePuantaj(yeniPuantaj);
                  } else {
                    await puantajService.addPuantaj(yeniPuantaj, sendId: false);
                  }
                  
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Puantaj güncellendi' : 'Puantaj eklendi')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  context.showSnackBar('Hata: $e');
                }
              },
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deletePuantaj(PuantajModel puantaj) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Puantaj Sil'),
        content: Text('${puantaj.ad} personelinin puantaj kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (onay == true) {
      try {
        await puantajService.deletePuantaj(puantaj.id);
        _loadData();
        if (!mounted) return;
        context.showSnackBar('Puantaj kaydı silindi');
      } catch (e) {
        if (!mounted) return;
        context.showSnackBar('Silme hatası: $e');
      }
    }
  }
}
