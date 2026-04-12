import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/models/izin_model.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

class IzinKaydi {
  final String personelAd;
  final String izinTuru;
  final DateTime baslangic;
  final DateTime bitis;
  final String aciklama;

  IzinKaydi({
    required this.personelAd,
    required this.izinTuru,
    required this.baslangic,
    required this.bitis,
    required this.aciklama,
  });
}

class IzinPage extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  final String? initialDonem;
  const IzinPage({super.key, this.personelId, this.personelAd, this.initialDonem});

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  List<IzinModel> izinler = [];
  bool yukleniyor = true;
  String? seciliDonem;
  String? currentUserId;
  String? currentUserAd;
  String? currentUserRole;

  int kalanYillikIzin = 0;
  int kullanilanYillikIzin = 0;
  int yillikIzinHakki = 14;
  int devredenIzin = 0;
  int toplamIzinHakki = 14;
  PersonelModel? personel;

  @override
  void initState() {
    super.initState();
    seciliDonem = widget.initialDonem;
    debugPrint('IzinPage.initState: personelId=${widget.personelId}');
    _getCurrentUser();
    _getIzinler();
    _getPersonel();
  }

  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id;
    // Personel adı çek
    if (currentUserId != null) {
      final servis = PersonelService();
      final personeller = await servis.getPersoneller();
      PersonelModel? me;
      try {
        me = personeller.firstWhere((p) => p.userId == currentUserId);
      } catch (e) {
        me = null;
      }
      currentUserAd = me?.ad;
    }
    // Rol çek
    if (currentUserId != null) {
      final response = await Supabase.instance.client.from(DbTables.userRoles).select().eq('user_id', currentUserId as Object).maybeSingle();
      currentUserRole = response?['role'] ?? 'user';
    }
    setState(() {});
  }

  Future<void> _getIzinler() async {
    if (!mounted) return; // mounted kontrolü ekle
    setState(() => yukleniyor = true);
    final servis = IzinService();
    if (currentUserRole == 'admin') {
      if (widget.personelId != null) {
        // Admin başka bir personel detayından bakıyorsa sadece o personelin izinleri
        izinler = await servis.getIzinlerForPersonel(widget.personelId!, donem: seciliDonem);
      } else {
        // Admin genel bakışta ise tüm izinler
        izinler = await servis.getTumIzinler();
      }
    } else if (widget.personelId != null) {
      izinler = await servis.getIzinlerForPersonel(widget.personelId!, donem: seciliDonem);
    } else if (currentUserId != null) {
      izinler = await servis.getIzinlerForPersonel(currentUserId!, donem: seciliDonem);
    }
    if (mounted) setState(() => yukleniyor = false); // mounted kontrolü ekle
  }

  Future<void> _izinEkle() async {
    final yeniIzin = await showDialog<IzinModel>(
      context: context,
      builder: (context) => IzinEkleDialog(
        personelId: currentUserId,
        personelAd: currentUserAd,
        isAdmin: currentUserRole == 'admin',
      ),
    );
    if (yeniIzin != null && mounted) { // mounted kontrolü ekle
      try {
        await IzinService().addIzin(yeniIzin);
        if (mounted) {
          context.showSnackBar('İzin kaydı başarıyla oluşturuldu!');
          await _getIzinler();
        }
      } catch (e) {
        debugPrint('İzin ekleme hatası: $e');
        if (mounted) {
          context.showSnackBar('İzin kaydı hatası: $e');
        }
      }
    }
  }

  Future<void> _getPersonel() async {
    final String? pid = widget.personelId ?? currentUserId;
    if (pid == null) return;
    final servis = PersonelService();
    final p = await servis.getPersonelById(pid);
    if (p != null) {
      personel = p;
      yillikIzinHakki = int.tryParse(p.yillikIzinHakki) ?? 14;
      
      // İzin özeti hesapla (devir dahil)
      try {
        final izinOzeti = await IzinService().getIzinOzeti(pid, yillikIzinHakki);
        devredenIzin = izinOzeti['devredenIzin'] ?? 0;
        toplamIzinHakki = izinOzeti['toplamHak'] ?? yillikIzinHakki;
        kullanilanYillikIzin = izinOzeti['buYilKullanilan'] ?? 0;
        kalanYillikIzin = izinOzeti['kalan'] ?? 0;
      } catch (e) {
        debugPrint('İzin özeti hesaplanamadı: $e');
      }
    }
    if (mounted) setState(() {}); // mounted kontrolü ekle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İzin ve Devamsızlık Yönetimi'),
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
                            _getIzinler(); // Yeni döneme göre izinleri getir
                          },
                          showAll: true,
                        ),
                      ),
                    ],
                  ),
                ),
                if (personel != null)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 500;
                            
                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Yıllık Hak: $yillikIzinHakki gün', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (devredenIzin > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('+$devredenIzin devir', style: TextStyle(color: Colors.purple.shade700, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Toplam: $toplamIzinHakki gün', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('Kullanılan: $kullanilanYillikIzin gün', style: const TextStyle(color: Colors.orange)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Kalan: $kalanYillikIzin gün',
                                      style: TextStyle(
                                        color: kalanYillikIzin > 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Yıllık Hak: $yillikIzinHakki gün', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (devredenIzin > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('+$devredenIzin gün devir', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.w500)),
                                  ),
                                Text('Toplam: $toplamIzinHakki gün', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('Kullanılan: $kullanilanYillikIzin gün', style: const TextStyle(color: Colors.orange)),
                                Text(
                                  'Kalan: $kalanYillikIzin gün',
                                  style: TextStyle(
                                    color: kalanYillikIzin > 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: izinler.isEmpty
                      ? const Center(child: Text('Henüz izin kaydı yok.'))
                      : ListView.builder(
                          itemCount: izinler.length,
                          itemBuilder: (context, i) {
                            final izin = izinler[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                title: Text('${izin.izinTuru} - ${izin.gunSayisi} gün'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${izin.baslangic.day}.${izin.baslangic.month}.${izin.baslangic.year} - ${izin.bitis.day}.${izin.bitis.month}.${izin.bitis.year}'),
                                    if (izin.aciklama.isNotEmpty) Text(izin.aciklama),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Durum: ',
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: izin.onayDurumu,
                                            style: TextStyle(
                                              color: izin.onayDurumu == 'onaylandi'
                                                  ? Colors.green
                                                  : izin.onayDurumu == 'red'
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
                                    if (currentUserRole == 'admin' && izin.onayDurumu == 'beklemede')
                                      ElevatedButton(
                                        onPressed: () async {
                                          final user = Supabase.instance.client.auth.currentUser;
                                          final userId = user?.id;
                                          if (userId == null) return;
                                          await IzinService().updateIzinDurum(
                                            izin.id!,
                                            'onaylandi',
                                            onaylayanId: userId,
                                          );
                                          if (!context.mounted) return;
                                          context.showSnackBar('İzin onaylandı.');
                                          if (mounted) _getIzinler(); // mounted kontrolü ekle
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text('Onayla'),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      tooltip: 'Düzenle',
                                      onPressed: () async {
                                        final guncellenen = await showDialog<IzinModel>(
                                          context: context,
                                          builder: (context) => IzinEkleDialog(
                                            personelId: izin.personelId,
                                            personelAd: widget.personelAd,
                                            isAdmin: currentUserRole == 'admin',
                                            initialDonem: seciliDonem,
                                          ),
                                        );
                                        if (guncellenen != null) {
                                          // Tüm izin bilgilerini güncelle
                                          await IzinService().updateIzin(
                                            izin.id!,
                                            guncellenen.toMap(),
                                          );
                                          if (mounted) _getIzinler(); // mounted kontrolü ekle
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Sil',
                                      onPressed: () async {
                                        if (izin.id == null || izin.id!.isEmpty) {
                                          context.showSnackBar('Bu kaydın ID bilgisi yok, silme yapılamaz. Lütfen yeni bir kayıt ekleyin.');
                                          return;
                                        }
                                        final onay = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('İzin Sil', style: TextStyle(color: Colors.blue)),
                                            content: const Text('Bu izin kaydını silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.blue)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (onay == true) {
                                          await IzinService().deleteIzin(izin.id!);
                                          if (mounted) _getIzinler(); // mounted kontrolü ekle
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _izinEkle,
        backgroundColor: Colors.blue,
        tooltip: 'İzin Kaydı Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class IzinEkleDialog extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  final bool isAdmin;
  final String? initialDonem;
  const IzinEkleDialog({super.key, this.personelId, this.personelAd, this.isAdmin = false, this.initialDonem});
  @override
  State<IzinEkleDialog> createState() => _IzinEkleDialogState();
}

class _IzinEkleDialogState extends State<IzinEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  String izinTuru = 'Yıllık İzin';
  DateTime? baslangic;
  DateTime? bitis;
  String aciklama = '';
  String? seciliPersonelId;
  String? seciliPersonelAd;
  List<Map<String, String>> personelList = [];
  bool yukleniyor = true;
  String? modalDonem;

  @override
  void initState() {
    super.initState();
    modalDonem = widget.initialDonem;
    _loadPersoneller();
  }

  Future<void> _loadPersoneller() async {
    if (widget.isAdmin) {
      try {
        final servis = PersonelService();
        final personeller = await servis.getPersoneller();
        setState(() {
          personelList = personeller.map((p) => {'id': p.userId, 'ad': p.ad}).toList();
          if (personelList.isNotEmpty) {
            seciliPersonelId = personelList.first['id'];
            seciliPersonelAd = personelList.first['ad'];
          }
          yukleniyor = false;
        });
      } catch (e) {
        setState(() => yukleniyor = false);
      }
    } else {
      seciliPersonelId = widget.personelId;
      seciliPersonelAd = widget.personelAd;
      yukleniyor = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.beach_access, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'İzin Kaydı Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            yukleniyor
                ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [                          // Dönem seçici
                          DonemSecici(
                            seciliDonem: modalDonem,
                            onDonemChanged: (donem) {
                              setState(() => modalDonem = donem);
                            },
                          ),
                          const SizedBox(height: 16),                          widget.isAdmin
                              ? DropdownButtonFormField<String>(
                                  initialValue: seciliPersonelId,
                                  items: personelList
                                      .map((p) => DropdownMenuItem(
                                            value: p['id'],
                                            child: Text(p['ad'] ?? '', style: const TextStyle(color: Colors.green)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      seciliPersonelId = v;
                                      seciliPersonelAd = personelList.firstWhere((p) => p['id'] == v)['ad'];
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Personel',
                                    labelStyle: const TextStyle(color: Colors.green),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.green.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.green, width: 2),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.green),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        seciliPersonelAd ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: izinTuru,
                            items: const [
                              DropdownMenuItem(value: 'Yıllık İzin', child: Text('Yıllık İzin', style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(value: 'Mazeret İzni', child: Text('Mazeret İzni', style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(value: 'Raporlu', child: Text('Raporlu', style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(value: 'Ücretsiz İzin', child: Text('Ücretsiz İzin', style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(value: 'Devamsızlık', child: Text('Devamsızlık', style: TextStyle(color: Colors.green))),
                            ],
                            onChanged: (v) => setState(() => izinTuru = v ?? 'Yıllık İzin'),
                            decoration: InputDecoration(
                              labelText: 'İzin Türü',
                              labelStyle: const TextStyle(color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.green.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.green.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.green, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.green),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final secilen = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (secilen != null) setState(() => baslangic = secilen);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          baslangic == null
                                              ? 'Başlangıç Tarihi'
                                              : '${baslangic!.day}.${baslangic!.month}.${baslangic!.year}',
                                          style: TextStyle(
                                            color: baslangic == null ? Colors.grey : Colors.green,
                                            fontWeight: baslangic == null ? FontWeight.normal : FontWeight.bold,
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
                                    final secilen = await showDatePicker(
                                      context: context,
                                      initialDate: baslangic ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (secilen != null) setState(() => bitis = secilen);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event, color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          bitis == null
                                              ? 'Bitiş Tarihi'
                                              : '${bitis!.day}.${bitis!.month}.${bitis!.year}',
                                          style: TextStyle(
                                            color: bitis == null ? Colors.grey : Colors.green,
                                            fontWeight: bitis == null ? FontWeight.normal : FontWeight.bold,
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
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Açıklama',
                              labelStyle: const TextStyle(color: Colors.green),
                              prefixIcon: const Icon(Icons.note, color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.green.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.green.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.green, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.green),
                            onChanged: (v) => aciklama = v,
                          ),
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
                    onPressed: _izinKaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
    );
  }

  void _izinKaydet() {
    if (_formKey.currentState?.validate() ?? false) {
      if (baslangic == null || bitis == null) return;
      final gunSayisi = bitis!.difference(baslangic!).inDays + 1;
      Navigator.pop(
        context,
        IzinModel(
          id: null,
          personelId: seciliPersonelId!,
          izinTuru: izinTuru,
          baslangic: baslangic!,
          bitis: bitis!,
          aciklama: aciklama,
          onayDurumu: 'beklemede',
          onaylayanId: null,
          gunSayisi: gunSayisi,
          userId: seciliPersonelId!, // user_id ve personel_id aynı olacak
        ),
      );
    }
  }
}
