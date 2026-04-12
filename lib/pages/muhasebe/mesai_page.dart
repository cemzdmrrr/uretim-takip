import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/services/sistem_ayarlari_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

class MesaiPage extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  final String? initialDonem;
  const MesaiPage({super.key, this.personelId, this.personelAd, this.initialDonem});

  @override
  State<MesaiPage> createState() => _MesaiPageState();
}

class _MesaiPageState extends State<MesaiPage> {
  List<Map<String, dynamic>> mesaiList = [];
  bool yukleniyor = true;
  String? seciliDonem;
  double aylikFazlaMesai = 0;
  double yillikFazlaMesai = 0;
  double saatlikUcret = 0;
  String? currentUserRole;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    seciliDonem = widget.initialDonem;
    debugPrint('MesaiPage.initState: personelId=${widget.personelId}');
    _getCurrentUserRole();
    _getMesailer();
    _getToplamMesai();
  }

  Future<void> _getCurrentUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    currentUserId = user.id;
    final response = await Supabase.instance.client
        .from(DbTables.userRoles)
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
    setState(() {
      currentUserRole = response?['role'] ?? 'user';
    });
  }

  Future<void> _getToplamMesai() async {
    if (widget.personelId == null) return;
    final now = DateTime.now();
    aylikFazlaMesai = await MesaiService().getAylikFazlaMesaiSaati(widget.personelId!, now.year, now.month);
    yillikFazlaMesai = await MesaiService().getYillikFazlaMesaiSaati(widget.personelId!, now.year);
    setState(() {});
  }

  Future<void> _getMesailer() async {
    setState(() => yukleniyor = true);
    if (widget.personelId == null) return;
    final response = await MesaiService().getMesailerForPersonel(widget.personelId!, donem: seciliDonem);
    setState(() {
      mesaiList = response.map((e) => {
        'id': e.id, // <-- id alanı eklendi
        'tarih': e.tarih,
        'baslangic_saati': e.baslangicSaati,
        'bitis_saati': e.bitisSaati,
        'mesai_turu': e.mesaiTuru,
        'onay_durumu': e.onayDurumu,
        'saat': e.saat,
        'yemek_ucreti': e.yemekUcreti ?? 0.0,
        'carpan': e.carpan ?? 1.0,
      }).toList();
      yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesai'),
        backgroundColor: Colors.blue,
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : Column(
              children: [
                // Dönem seçici
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text(
                        'Dönem Seçin:', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DonemSecici(
                          seciliDonem: seciliDonem,
                          onDonemChanged: (donem) {
                            setState(() {
                              seciliDonem = donem;
                            });
                            _getMesailer(); // Yeni döneme göre mesaileri getir
                            _getToplamMesai(); // Özet bilgileri güncelle
                          },
                          showAll: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Aylık Toplam Mesai: ${aylikFazlaMesai.toStringAsFixed(2)} saat', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Yıllık Toplam: ${yillikFazlaMesai.toStringAsFixed(2)} saat', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: mesaiList.isEmpty
                      ? const Center(child: Text('Mesai kaydı yok.'))
                      : ListView.builder(
                          itemCount: mesaiList.length,
                          itemBuilder: (context, i) {
                            final m = mesaiList[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text(m['tarih'] == null ? 'Tarih seçiniz' : '${m['tarih'].day}.${m['tarih'].month}.${m['tarih'].year}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Başlangıç: ${m['baslangic_saati'] ?? '-'}'),
                                    Text('Bitiş: ${m['bitis_saati'] ?? '-'}'),
                                    Text('Tür: ${m['mesai_turu'] ?? '-'}'),
                                    Text('Çalışılan Saat: ${m['saat'] != null ? m['saat'].toString() : '-'}'),
                                    if ((m['yemek_ucreti'] as num?)?.toDouble() != null && (m['yemek_ucreti'] as num?)!.toDouble() > 0)
                                      Text('Yemek Ücreti: ${(m['yemek_ucreti'] as num).toDouble().toStringAsFixed(2)} TL', 
                                           style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Durum: ',
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: m['onay_durumu'] ?? '-',
                                            style: TextStyle(
                                              color: m['onay_durumu'] == 'onaylandi'
                                                  ? Colors.green
                                                  : m['onay_durumu'] == 'red'
                                                      ? Colors.red
                                                      : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      tooltip: 'Düzenle',
                                      onPressed: () async {
                                          final mItem = mesaiList[i];
                                          final mesaiId = mItem['id']?.toString() ?? '';
                                          if (mesaiId.isEmpty) {
                                            context.showSnackBar('Bu kaydın ID bilgisi yok, silme/düzenleme yapılamaz. Lütfen yeni bir kayıt ekleyin.');
                                            return;
                                          }
                                          DateTime? seciliTarih = mItem['tarih'];
                                          final String baslangicSaati = mItem['baslangic_saati']?.toString() ?? '';
                                          final String bitisSaati = mItem['bitis_saati']?.toString() ?? '';
                                          String mesaiTuru = mItem['mesai_turu']?.toString() ?? '';
                                          String onayDurumu = mItem['onay_durumu']?.toString() ?? 'beklemede';
                                          double carpan = (mItem['carpan'] as num?)?.toDouble() ?? 1.0;
                                          double yemekUcreti = (mItem['yemek_ucreti'] as num?)?.toDouble() ?? 0.0;
                                          final yemekUcretiController = TextEditingController(text: yemekUcreti.toString());
                                          TimeOfDay? baslangicTime = baslangicSaati.isNotEmpty && baslangicSaati.contains(':') ? TimeOfDay(
                                            hour: int.tryParse(baslangicSaati.split(':')[0]) ?? 0,
                                            minute: int.tryParse(baslangicSaati.split(':')[1]) ?? 0,
                                          ) : null;
                                          TimeOfDay? bitisTime = bitisSaati.isNotEmpty && bitisSaati.contains(':') ? TimeOfDay(
                                            hour: int.tryParse(bitisSaati.split(':')[0]) ?? 0,
                                            minute: int.tryParse(bitisSaati.split(':')[1]) ?? 0,
                                          ) : null;
                                          await showDialog(
                                            context: context,
                                            builder: (context) => StatefulBuilder(
                                              builder: (context, setDialogState) => AlertDialog(
                                                title: const Text('Mesai Düzenle', style: TextStyle(color: Colors.blue)),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ListTile(
                                                        title: Text(seciliTarih == null ? 'Tarih seçiniz' : '${seciliTarih?.day}.${seciliTarih?.month}.${seciliTarih?.year}', style: const TextStyle(color: Colors.blue)),
                                                        trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                                                        onTap: () async {
                                                          final picked = await showDatePicker(
                                                            context: context,
                                                            initialDate: seciliTarih ?? DateTime.now(),
                                                            firstDate: DateTime(2020),
                                                            lastDate: DateTime(2100),
                                                          );
                                                          if (picked != null) setDialogState(() => seciliTarih = picked);
                                                        },
                                                      ),
                                                      ListTile(
                                                        title: Text(baslangicTime == null ? 'Başlangıç saati seçiniz' : baslangicTime?.format(context) ?? '', style: const TextStyle(color: Colors.blue)),
                                                        trailing: const Icon(Icons.access_time, color: Colors.blue),
                                                        onTap: () async {
                                                          final picked = await showTimePicker(
                                                            context: context,
                                                            initialTime: baslangicTime ?? TimeOfDay.now(),
                                                          );
                                                          if (picked != null) setDialogState(() => baslangicTime = picked);
                                                        },
                                                      ),
                                                      ListTile(
                                                        title: Text(bitisTime == null ? 'Bitiş saati seçiniz' : bitisTime?.format(context) ?? '', style: const TextStyle(color: Colors.blue)),
                                                        trailing: const Icon(Icons.access_time, color: Colors.blue),
                                                        onTap: () async {
                                                          final picked = await showTimePicker(
                                                            context: context,
                                                            initialTime: bitisTime ?? TimeOfDay.now(),
                                                          );
                                                          if (picked != null) setDialogState(() => bitisTime = picked);
                                                        },
                                                      ),
                                                      DropdownButtonFormField<String>(
                                                        initialValue: mesaiTuru.isEmpty ? null : mesaiTuru,
                                                        items: const [
                                                          DropdownMenuItem(value: 'Pazar', child: Text('Pazar Mesaisi (Günlük Ücret x2)')),
                                                          DropdownMenuItem(value: 'Bayram', child: Text('Bayram Mesaisi (Özel Çarpan)')),
                                                          DropdownMenuItem(value: 'Saatlik', child: Text('Saatlik Mesai (x1.5)')),
                                                        ],
                                                        onChanged: (v) async {
                                                          setDialogState(() => mesaiTuru = v ?? '');
                                                          // Mesai türüne göre sistem ayarlarından varsayılan yemek ücretini çek
                                                          if (mesaiTuru == 'Pazar') {
                                                            final pazarUcret = await SistemAyarlariService.getPazarYemekUcreti();
                                                            setDialogState(() {
                                                              yemekUcreti = pazarUcret;
                                                              yemekUcretiController.text = pazarUcret.toString();
                                                            });
                                                          } else if (mesaiTuru == 'Bayram') {
                                                            final bayramUcret = await SistemAyarlariService.getBayramYemekUcreti();
                                                            setDialogState(() {
                                                              yemekUcreti = bayramUcret;
                                                              yemekUcretiController.text = bayramUcret.toString();
                                                            });
                                                          } else {
                                                            setDialogState(() {
                                                              yemekUcreti = 0;
                                                              yemekUcretiController.text = '0';
                                                            });
                                                          }
                                                        },
                                                        decoration: const InputDecoration(labelText: 'Mesai Türü'),
                                                      ),
                                                      if (mesaiTuru == 'Bayram') ...[
                                                        const SizedBox(height: 12),
                                                        TextField(
                                                          decoration: const InputDecoration(labelText: 'Çarpan (Örn: 1.5, 2.0)'),
                                                          keyboardType: TextInputType.number,
                                                          controller: TextEditingController(text: carpan.toString()),
                                                          onChanged: (v) => carpan = double.tryParse(v) ?? 1.0,
                                                        ),
                                                      ],
                                                      if (mesaiTuru == 'Pazar' || mesaiTuru == 'Bayram') ...[
                                                        const SizedBox(height: 12),
                                                        TextField(
                                                          controller: yemekUcretiController,
                                                          keyboardType: TextInputType.number,
                                                          decoration: const InputDecoration(labelText: 'Yemek Ücreti (TL)'),
                                                          onChanged: (v) => yemekUcreti = double.tryParse(v) ?? 0,
                                                        ),
                                                      ],
                                                      DropdownButtonFormField<String>(
                                                        initialValue: onayDurumu,
                                                        items: const [
                                                          DropdownMenuItem(value: 'beklemede', child: Text('Beklemede')),
                                                          DropdownMenuItem(value: 'onaylandi', child: Text('Onaylandı')),
                                                          DropdownMenuItem(value: 'red', child: Text('Reddedildi')),
                                                        ],
                                                        onChanged: (v) => setDialogState(() => onayDurumu = v ?? 'beklemede'),
                                                        decoration: const InputDecoration(labelText: 'Onay Durumu'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                    child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      if (seciliTarih == null || baslangicTime == null || bitisTime == null) return;
                                                      final baslangicStr = '${baslangicTime?.hour.toString().padLeft(2, '0')}:${baslangicTime?.minute.toString().padLeft(2, '0')}';
                                                      final bitisStr = '${bitisTime?.hour.toString().padLeft(2, '0')}:${bitisTime?.minute.toString().padLeft(2, '0')}';
                                                      
                                                      // Mesai saatini hesapla
                                                      final baslangic = DateTime(
                                                        seciliTarih!.year,
                                                        seciliTarih!.month,
                                                        seciliTarih!.day,
                                                        baslangicTime?.hour ?? 0,
                                                        baslangicTime?.minute ?? 0,
                                                      );
                                                      final bitis = DateTime(
                                                        seciliTarih!.year,
                                                        seciliTarih!.month,
                                                        seciliTarih!.day,
                                                        bitisTime?.hour ?? 0,
                                                        bitisTime?.minute ?? 0,
                                                      );
                                                      final mesaiSaati = bitis.difference(baslangic).inMinutes / 60.0;
                                                      
                                                      // Mesai ücretini hesapla
                                                      // Personel bilgisini çekmek için varsayılan değerler
                                                      const double netMaas = 50000; // Bu değer gerçek personel verisiyle değiştirilmeli
                                                      double mesaiUcret = 0;
                                                      
                                                      if (mesaiTuru == 'Pazar') {
                                                        // Pazar mesaisi: Günlük net maaş x 2 (saat bazında değil)
                                                        const gunlukNetMaas = netMaas / 30;
                                                        mesaiUcret = gunlukNetMaas * 2.0;
                                                      } else if (mesaiTuru == 'Bayram') {
                                                        // Bayram mesaisi: Saatlik ücret x çarpan x saat
                                                        const saatlikUcret = netMaas / 30 / 8; // 8 saatlik iş günü varsayımı
                                                        mesaiUcret = saatlikUcret * carpan * mesaiSaati;
                                                      } else if (mesaiTuru == 'Saatlik') {
                                                        // Saatlik mesai: Saatlik ücret x 1.5 x saat
                                                        const saatlikUcret = netMaas / 30 / 8; // 8 saatlik iş günü varsayımı
                                                        mesaiUcret = saatlikUcret * 1.5 * mesaiSaati;
                                                        yemekUcreti = 0; // Saatlik mesai için yemek ücreti yok
                                                      }
                                                      
                                                      final toplamUcret = mesaiUcret + yemekUcreti;
                                                      
                                                      // Çarpan değerini türe göre belirle
                                                      double kayitCarpani = 1.0;
                                                      if (mesaiTuru == 'Pazar') {
                                                        kayitCarpani = 2.0;
                                                      } else if (mesaiTuru == 'Bayram') {
                                                        kayitCarpani = carpan;
                                                      } else if (mesaiTuru == 'Saatlik') {
                                                        kayitCarpani = 1.5;
                                                      }
                                                      
                                                      await MesaiService().updateMesai(
                                                        mesaiId,
                                                        {
                                                          'tarih': seciliTarih?.toIso8601String(),
                                                          'baslangic_saati': baslangicStr,
                                                          'bitis_saati': bitisStr,
                                                          'mesai_turu': mesaiTuru,
                                                          'onay_durumu': onayDurumu,
                                                          'mesai_ucret': toplamUcret,
                                                          'yemek_ucreti': yemekUcreti,
                                                          'carpan': kayitCarpani,
                                                        },
                                                      );
                                                      await _getMesailer();
                                                      _getToplamMesai();
                                                      if (!context.mounted) return;
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                    child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Sil',
                                      onPressed: () async {
                                        final mItem = mesaiList[i];
                                        final mesaiId = mItem['id']?.toString() ?? '';
                                        if (mesaiId.isEmpty) {
                                          context.showSnackBar('Bu kaydın ID bilgisi yok, silme/düzenleme yapılamaz. Lütfen yeni bir kayıt ekleyin.');
                                          return;
                                        }
                                        final onay = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Mesai Sil'),
                                            content: const Text('Bu mesai kaydını silmek istediğinize emin misiniz?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('İptal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Sil'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (onay == true) {
                                          await MesaiService().deleteMesai(mItem['id']);
                                          await _getMesailer();
                                          _getToplamMesai();
                                        }
                                      },
                                    ),
                                    // Admin için onayla butonu
                                    if (m['onay_durumu'] == 'beklemede' && currentUserRole == 'admin')
                                      ElevatedButton(
                                        onPressed: () async {
                                          await MesaiService().updateMesai(m['id'], {'onay_durumu': 'onaylandi'});
                                          await _getMesailer();
                                          _getToplamMesai();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text('Onayla'),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          DateTime? seciliTarih;
          TimeOfDay? baslangicSaati;
          TimeOfDay? bitisSaati;
          String mesaiTuru = '';
          double bayramCarpani = 1.0;
          double yemekUcreti = 0;
          final yemekUcretiController = TextEditingController();
          final formKey = GlobalKey<FormState>();
          // Personel ve dönem seçimi
          String? seciliPersonelId = widget.personelId;
          String? seciliPersonelAd = widget.personelAd;
          String? modalDonem = seciliDonem;
          List<Map<String, String>> personelList = [];
          final bool isAdmin = currentUserRole == 'admin';
          if (isAdmin) {
            try {
              final servis = PersonelService();
              final personeller = await servis.getPersoneller();
              personelList = personeller.map((p) => {'id': p.userId, 'ad': '${p.ad} ${p.soyad}'.trim()}).toList();
            } catch (e) {
              debugPrint('Personel listesi yükleme hatası: $e');
            }
          }
          await showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.access_time, color: Colors.orange, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Mesai Kaydı Ekle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              // Dönem seçici
                              DonemSecici(
                                seciliDonem: modalDonem,
                                onDonemChanged: (donem) {
                                  setState(() => modalDonem = donem);
                                },
                              ),
                              const SizedBox(height: 16),
                              // Personel seçimi
                              isAdmin && personelList.isNotEmpty
                                  ? DropdownButtonFormField<String>(
                                      value: seciliPersonelId,
                                      items: personelList
                                          .map((p) => DropdownMenuItem(
                                                value: p['id'],
                                                child: Text(p['ad'] ?? '', style: const TextStyle(color: Colors.orange)),
                                              ))
                                          .toList(),
                                      onChanged: (v) {
                                        setState(() {
                                          seciliPersonelId = v;
                                          seciliPersonelAd = personelList.firstWhere((p) => p['id'] == v)['ad'];
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Personel Seç',
                                        labelStyle: const TextStyle(color: Colors.orange),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.orange.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.orange.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.orange, width: 2),
                                        ),
                                      ),
                                      style: const TextStyle(color: Colors.orange),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person, color: Colors.orange, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Personel: ${seciliPersonelAd ?? widget.personelAd ?? '-'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) setState(() => seciliTarih = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.orange.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        seciliTarih == null
                                            ? 'Tarih seçiniz'
                                            : '${seciliTarih!.day}.${seciliTarih!.month}.${seciliTarih!.year}',
                                        style: TextStyle(
                                          color: seciliTarih == null ? Colors.grey : Colors.orange,
                                          fontWeight: seciliTarih == null ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) setState(() => baslangicSaati = picked);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.orange.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.play_arrow, color: Colors.orange, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              baslangicSaati == null
                                                  ? 'Başlangıç'
                                                  : baslangicSaati!.format(context),
                                              style: TextStyle(
                                                color: baslangicSaati == null ? Colors.grey : Colors.orange,
                                                fontWeight: baslangicSaati == null ? FontWeight.normal : FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) setState(() => bitisSaati = picked);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.orange.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.stop, color: Colors.orange, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              bitisSaati == null
                                                  ? 'Bitiş'
                                                  : bitisSaati!.format(context),
                                              style: TextStyle(
                                                color: bitisSaati == null ? Colors.grey : Colors.orange,
                                                fontWeight: bitisSaati == null ? FontWeight.normal : FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: mesaiTuru.isEmpty ? null : mesaiTuru,
                                items: const [
                                  DropdownMenuItem(value: 'Pazar', child: Text('Pazar Mesaisi (Günlük Ücret x2)', style: TextStyle(color: Colors.orange))),
                                  DropdownMenuItem(value: 'Bayram', child: Text('Bayram Mesaisi (Özel Çarpan)', style: TextStyle(color: Colors.orange))),
                                  DropdownMenuItem(value: 'Saatlik', child: Text('Saatlik Mesai (x1.5)', style: TextStyle(color: Colors.orange))),
                                ],
                                onChanged: (v) async {
                                  setState(() => mesaiTuru = v ?? '');
                                  // Mesai türüne göre sistem ayarlarından varsayılan yemek ücretini çek
                                  if (mesaiTuru == 'Pazar') {
                                    final pazarUcret = await SistemAyarlariService.getPazarYemekUcreti();
                                    setState(() {
                                      yemekUcreti = pazarUcret;
                                      yemekUcretiController.text = pazarUcret.toString();
                                    });
                                  } else if (mesaiTuru == 'Bayram') {
                                    final bayramUcret = await SistemAyarlariService.getBayramYemekUcreti();
                                    setState(() {
                                      yemekUcreti = bayramUcret;
                                      yemekUcretiController.text = bayramUcret.toString();
                                    });
                                  } else {
                                    setState(() {
                                      yemekUcreti = 0;
                                      yemekUcretiController.text = '0';
                                    }); // Saatlik için yok
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Mesai Türü',
                                  labelStyle: const TextStyle(color: Colors.orange),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.orange.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.orange.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.orange, width: 2),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.orange),
                                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                              ),
                              if (mesaiTuru == 'Bayram') ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Çarpan (Örn: 1.5, 2.0)',
                                    labelStyle: const TextStyle(color: Colors.orange),
                                    prefixIcon: const Icon(Icons.calculate, color: Colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.orange.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.orange.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.orange),
                                  onChanged: (v) => bayramCarpani = double.tryParse(v) ?? 1.0,
                                ),
                              ],
                              if (mesaiTuru == 'Pazar' || mesaiTuru == 'Bayram') ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: yemekUcretiController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Yemek Ücreti (TL)',
                                    labelStyle: const TextStyle(color: Colors.orange),
                                    prefixIcon: const Icon(Icons.restaurant, color: Colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.orange.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.orange.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.orange, width: 2),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.orange),
                                  onChanged: (v) => yemekUcreti = double.tryParse(v) ?? 0,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('İptal', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Validasyon kontrolü
                                if (formKey.currentState?.validate() != true) {
                                  context.showSnackBar('Lütfen tüm alanları doldurun!');
                                  return;
                                }
                                if (seciliTarih == null) {
                                  context.showSnackBar('Lütfen tarih seçin!');
                                  return;
                                }
                                if (baslangicSaati == null) {
                                  context.showSnackBar('Lütfen başlangıç saati seçin!');
                                  return;
                                }
                                if (bitisSaati == null) {
                                  context.showSnackBar('Lütfen bitiş saati seçin!');
                                  return;
                                }
                                if (mesaiTuru.isEmpty) {
                                  context.showSnackBar('Lütfen mesai türü seçin!');
                                  return;
                                }
                                if (seciliPersonelId == null || seciliPersonelId!.isEmpty) {
                                  context.showSnackBar('Personel bilgisi bulunamadı!');
                                  return;
                                }
                                final baslangic = DateTime(
                                  seciliTarih!.year,
                                  seciliTarih!.month,
                                  seciliTarih!.day,
                                  baslangicSaati?.hour ?? 0,
                                  baslangicSaati?.minute ?? 0,
                                );
                                final bitis = DateTime(
                                  seciliTarih!.year,
                                  seciliTarih!.month,
                                  seciliTarih!.day,
                                  bitisSaati?.hour ?? 0,
                                  bitisSaati?.minute ?? 0,
                                );
                                // Çakışan mesai kontrolü
                                final cakisma = await MesaiService().mesaiCakisiyorMu(
                                  seciliPersonelId!,
                                  seciliTarih!,
                                  '${baslangicSaati?.hour.toString().padLeft(2, '0') ?? '00'}:${baslangicSaati?.minute.toString().padLeft(2, '0') ?? '00'}',
                                  '${bitisSaati?.hour.toString().padLeft(2, '0') ?? '00'}:${bitisSaati?.minute.toString().padLeft(2, '0') ?? '00'}',
                                );
                                if (cakisma) {
                                  if (!context.mounted) return;
                                  context.showSnackBar('Bu saat aralığında başka bir mesai kaydı var!');
                                  return;
                                }
                                final mesaiSaati = bitis.difference(baslangic).inMinutes / 60.0;
                                
                                // Mesai ücret hesaplama - türe göre farklı hesaplama yöntemleri
                                const double netMaas = 50000; // Bu değer gerçek personel verisiyle değiştirilmeli
                                double mesaiUcret = 0;
                                double carpan = 1.0;
                                
                                if (mesaiTuru == 'Pazar') {
                                  // Pazar mesaisi: Günlük net maaş x 2 (saat bazında değil)
                                  const gunlukNetMaas = netMaas / 30;
                                  mesaiUcret = gunlukNetMaas * 2.0;
                                  carpan = 2.0;
                                  // Yemek ücreti kullanıcı tarafından belirlendi
                                } else if (mesaiTuru == 'Bayram') {
                                  // Bayram mesaisi: Saatlik ücret x çarpan x saat
                                  const saatlikUcret = netMaas / 30 / 8; // 8 saatlik iş günü varsayımı
                                  mesaiUcret = saatlikUcret * bayramCarpani * mesaiSaati;
                                  carpan = bayramCarpani;
                                  // Yemek ücreti kullanıcı tarafından belirlendi
                                } else if (mesaiTuru == 'Saatlik') {
                                  // Saatlik mesai: Saatlik ücret x 1.5 x saat
                                  const saatlikUcret = netMaas / 30 / 8; // 8 saatlik iş günü varsayımı
                                  mesaiUcret = saatlikUcret * 1.5 * mesaiSaati;
                                  carpan = 1.5;
                                  // Saatlik mesai için yemek ücreti yok
                                  yemekUcreti = 0;
                                }
                                
                                final toplamUcret = mesaiUcret + yemekUcreti;
                                
                                const String onayDurumu = 'beklemede';
                                try {
                                  debugPrint('=== Mesai Ekleme ===');
                                  debugPrint('user_id: $seciliPersonelId');
                                  debugPrint('tarih: ${seciliTarih?.toIso8601String()}');
                                  debugPrint('mesai_turu: $mesaiTuru');
                                  debugPrint('mesai_ucret: $toplamUcret');
                                  
                                  await MesaiService().addMesaiRaw({
                                    'user_id': seciliPersonelId,
                                    'tarih': seciliTarih?.toIso8601String().split('T')[0], // Sadece tarih kısmı
                                    'baslangic_saati': '${baslangicSaati?.hour.toString().padLeft(2, '0') ?? '00'}:${baslangicSaati?.minute.toString().padLeft(2, '0') ?? '00'}',
                                    'bitis_saati': '${bitisSaati?.hour.toString().padLeft(2, '0') ?? '00'}:${bitisSaati?.minute.toString().padLeft(2, '0') ?? '00'}',
                                    'mesai_turu': mesaiTuru,
                                    'onay_durumu': onayDurumu,
                                    'mesai_ucret': toplamUcret,
                                    'yemek_ucreti': yemekUcreti,
                                    'carpan': carpan,
                                  });
                                  debugPrint('Mesai başarıyla eklendi');
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _getMesailer();
                                  _getToplamMesai();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Mesai kaydı başarıyla oluşturuldu!')),
                                  );
                                } catch (e, stackTrace) {
                                  debugPrint('Mesai ekleme hatası: $e');
                                  debugPrint('Stack trace: $stackTrace');
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Mesai kaydı hatası: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 5),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        tooltip: 'Mesai Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
