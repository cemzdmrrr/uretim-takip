import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/models/odeme_model.dart';
import 'package:uretim_takip/services/odeme_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/notification_service.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

part 'odeme_page_aksiyonlar.dart';

class OdemePage extends StatefulWidget {
  final String personelId;
  final String? initialDonem;
  const OdemePage({super.key, required this.personelId, this.initialDonem});

  @override
  State<OdemePage> createState() => _OdemePageState();
}

class _OdemePageState extends State<OdemePage> {
  List<OdemeModel> odemeler = [];
  bool yukleniyor = true;
  String? seciliDonem;
  
  Map<String, double> ozetBakiyeler = {
    'avans': 0,
    'prim': 0,
    DbTables.mesai: 0,
    'ikramiye': 0,
    'kesinti': 0,
  };

  // Filtreleme için state
  String? filtreTur;
  String? filtreDurum;
  DateTime? filtreBaslangic;
  DateTime? filtreBitis;

  PersonelModel? personel;
  int? ucretsizIzinGun;

  String? currentUserRole;
  String? currentUserId;

  List<OdemeModel> get _filtreliOdemeler {
    return odemeler.where((o) {
      if (filtreTur != null && filtreTur!.isNotEmpty && o.tur != filtreTur) return false;
      if (filtreDurum != null && filtreDurum!.isNotEmpty && o.durum != filtreDurum) return false;
      if (filtreBaslangic != null && o.tarih.isBefore(filtreBaslangic!)) return false;
      if (filtreBitis != null && o.tarih.isAfter(filtreBitis!)) return false;
      return true;
    }).toList();
  }



  Future<void> _getEkBilgiler() async {
    if (personel == null) return;
    final izinServis = IzinService();
    ucretsizIzinGun = await izinServis.getKullanilanUcretsizIzinGun(personel!.userId);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    seciliDonem = widget.initialDonem;
    debugPrint('OdemePage.initState: personelId=${widget.personelId}');
    _getPersonel();
    _getOdemeler();
    _getOzetBakiyeler();
    _getEkBilgiler();
    _getCurrentUserRole();
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

  Future<void> _getPersonel() async {
    final servis = PersonelService();
    personel = await servis.getPersonelById(widget.personelId);
    setState(() {});
  }

  Future<void> _getOdemeler() async {
    setState(() => yukleniyor = true);
    final servis = OdemeService();
    final liste = await servis.getOdemelerForPersonel(widget.personelId, donem: seciliDonem);
    setState(() {
      odemeler = liste;
      yukleniyor = false;
    });
    _getOzetBakiyeler(); // Yeni ödeme eklenince özetler de güncellensin
  }

  Future<void> _getOzetBakiyeler() async {
    final servis = OdemeService();
    final ozet = await servis.getOnayliBakiyeOzet(widget.personelId, donem: seciliDonem);
    setState(() {
      ozetBakiyeler = ozet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avans ve Ödeme Geçmişi'),
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
                            _getOdemeler(); // Yeni döneme göre ödemeleri getir
                            _getOzetBakiyeler(); // Özet bakiyeleri güncelle
                          },
                          showAll: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _bakiyeCard('Avans', (ozetBakiyeler['avans'] ?? 0).toDouble(), Colors.blue),
                        _bakiyeCard('Prim', (ozetBakiyeler['prim'] ?? 0).toDouble(), Colors.blue),
                        FutureBuilder<double>(
                          future: _getAylikToplamMesaiUcreti(),
                          builder: (context, snapshot) {
                            final mesaiTutar = snapshot.data ?? 0.0;
                            return _bakiyeCard('Mesai', mesaiTutar, Colors.blue);
                          },
                        ),
                        _bakiyeCard('İkramiye', (ozetBakiyeler['ikramiye'] ?? 0).toDouble(), Colors.blue),
                        FutureBuilder<double>(
                          future: _getKesintiTutari(),
                          builder: (context, snapshot) {
                            final kesintiTutar = snapshot.data ?? 0.0;
                            return _bakiyeCard('Kesinti', kesintiTutar, Colors.blue);
                          },
                        ),
                        FutureBuilder<double>(
                          future: _getAylikYolUcreti(),
                          builder: (context, snapshot) {
                            final yolTutar = snapshot.data ?? 0.0;
                            return _bakiyeCard('Yol', yolTutar, Colors.blue);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
               
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: FutureBuilder<List<double>>(
                    future: Future.wait([
                      _getAylikToplamMesaiUcreti(),
                      _getKesintiTutari(),
                      _getAylikMesaiYemekUcreti(),
                      _getAylikYolUcreti(),
                    ]),
                    builder: (context, snapshot) {
                      double mesaiTutar = 0.0;
                      double kesintiTutar = 0.0;
                      double mesaiYemekUcreti = 0.0;
                      double yolUcreti = 0.0;
                      if (snapshot.hasData && personel != null) {
                        final results = snapshot.data!;
                        mesaiTutar = results[0];
                        kesintiTutar = results[1];
                        mesaiYemekUcreti = results[2];
                        yolUcreti = results[3];
                      }
                      // Finansal hesaplamalar
                      final maas = personel != null ? double.tryParse(personel!.netMaas) ?? 0.0 : 0.0;
                      final yemek = personel != null ? double.tryParse(personel!.yemekUcreti) ?? 0.0 : 0.0;
                      final toplamYemekUcreti = yemek + mesaiYemekUcreti; // Personel yemek ücreti + mesai yemek ücretleri
                      final prim = (ozetBakiyeler['prim'] ?? 0).toDouble();
                      final avans = (ozetBakiyeler['avans'] ?? 0).toDouble();
                      final bankadanMaas = personel != null ? double.tryParse(personel!.bankaMaas) ?? 0.0 : 0.0;
                      final gunlukSaat = personel != null ? double.tryParse(personel!.gunlukCalismaSaati) ?? 0.0 : 0.0;
                      final ucretsizIzin = (ucretsizIzinGun ?? 0).toDouble();
                      final ucretsizIzinTutari = gunlukSaat > 0 ? (maas / 30) * ucretsizIzin : 0.0;
                      
                      // Net Alınan hesabı (Sadece maaş, mesai ayrı gösterilecek)
                      final netAlinan = maas;
                      
                      // Toplam Kesinti hesabı (İzin kesintileri + Ücretsiz izin)
                      final toplamKesinti = kesintiTutar + ucretsizIzinTutari;
                      
                      // Toplam Kazanç = Net Alınan + Mesai + Primler + Yol Ücreti + Yemek Ücreti - Toplam Kesinti - Avanslar
                      final toplamKazanc = netAlinan + mesaiTutar + prim + yolUcreti + toplamYemekUcreti - toplamKesinti - avans;
                      
                      // Kalan ücret hesabı (bankadan alınan düşülürse)
                      final kalanUcret = bankadanMaas > 0 ? toplamKazanc - bankadanMaas : toplamKazanc;
                      return Column(
                        children: [
                          // Kalan Ücret Kartı
                          Card(
                            color: toplamKazanc >= 0 ? Colors.blue.shade50 : Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(toplamKazanc >= 0 ? Icons.account_balance_wallet : Icons.warning, color: toplamKazanc >= 0 ? Colors.blue : Colors.red),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Kalan Ücret: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800),
                                  ),
                                  Text(
                                    '${kalanUcret.toStringAsFixed(2)} TL',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: toplamKazanc >= 0 ? Colors.blue : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (bankadanMaas > 0)
                            Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance, color: Colors.green),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Bankadan Alınan: ',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800),
                                    ),
                                    Text(
                                      '${bankadanMaas.toStringAsFixed(2)} TL',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: filtreTur,
                          hint: const Text('Tür'),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tümü')),
                            DropdownMenuItem(value: 'avans', child: Text('Avans')),
                            DropdownMenuItem(value: 'prim', child: Text('Prim')),
                            DropdownMenuItem(value: DbTables.mesai, child: Text('Mesai')),
                            DropdownMenuItem(value: 'ikramiye', child: Text('İkramiye')),
                            DropdownMenuItem(value: 'kesinti', child: Text('Kesinti')),
                          ],
                          onChanged: (v) => setState(() => filtreTur = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: filtreDurum,
                          hint: const Text('Durum'),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tümü')),
                            DropdownMenuItem(value: 'beklemede', child: Text('Beklemede')),
                            DropdownMenuItem(value: 'onaylandi', child: Text('Onaylandı')),
                            DropdownMenuItem(value: 'red', child: Text('Reddedildi')),
                          ],
                          onChanged: (v) => setState(() => filtreDurum = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.date_range),
                        tooltip: 'Tarih Aralığı',
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDateRange: (filtreBaslangic != null && filtreBitis != null)
                                ? DateTimeRange(start: filtreBaslangic!, end: filtreBitis!)
                                : null,
                          );
                          if (picked != null) {
                            setState(() {
                              filtreBaslangic = picked.start;
                              filtreBitis = picked.end;
                            });
                          }
                        },
                      ),
                      if (filtreTur != null || filtreDurum != null || filtreBaslangic != null || filtreBitis != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Filtreleri Temizle',
                          onPressed: () => setState(() {
                            filtreTur = null;
                            filtreDurum = null;
                            filtreBaslangic = null;
                            filtreBitis = null;
                          }),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtreliOdemeler.length,
                    itemBuilder: (context, i) {
                      final o = _filtreliOdemeler[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(_odemeIcon(o.tur), color: _odemeRenk(o.tur)),
                          title: Text('${o.tur.toUpperCase()} - ${o.tutar.toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (o.aciklama.isNotEmpty) Text(o.aciklama),
                              Text('${o.tarih.day}.${o.tarih.month}.${o.tarih.year}'),
                              RichText(
                                text: TextSpan(
                                  text: 'Durum: ',
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: o.durum,
                                      style: TextStyle(
                                        color: o.durum == 'onaylandi'
                                            ? Colors.green
                                            : o.durum == 'red'
                                                ? Colors.red
                                                : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (o.onaylayanId != null) Text('Onaylayan: ${o.onaylayanId}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          trailing: FutureBuilder<bool>(
                            future: kullaniciAdminMi(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                              }
                              // Admin için onayla/sil butonları
                              if (snapshot.data == true && o.durum == 'beklemede') {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Sil',
                                      onPressed: () async {
                                        final onay = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Silme Onayı', style: TextStyle(color: Colors.blue)),
                                            content: const Text('Bu ödeme kaydını silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.blue)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (onay == true) {
                                          try {
                                            await OdemeService().deleteOdeme(o.id!);
                                            // Bildirim gönder
                                            try {
                                              final personelUserId = o.personelId;
                                              final personel = await PersonelService().getPersonelById(personelUserId);
                                              final email = personel?.email;
                                              if (email != null && email.isNotEmpty) {
                                                await Supabase.instance.client.from(DbTables.notifications).insert({
                                                  'user_id': personelUserId,
                                                  'title': 'Avans Talebiniz Silindi',
                                                  'message': 'Avans talebiniz yönetici tarafından silindi.',
                                                  'created_at': DateTime.now().toIso8601String(),
                                                  'read': false,
                                                });
                                              }
                                            } catch (bildirimHata) {
                                              debugPrint('Bildirim gönderme hatası: $bildirimHata');
                                              // Bildirim hatası olsa bile işlemi devam ettir
                                            }
                                            if (!context.mounted) return;
                                            context.showSnackBar('Ödeme kaydı başarıyla silindi!');
                                            _getOdemeler();
                                          } catch (e) {
                                            debugPrint('Ödeme silme hatası: $e');
                                            if (!context.mounted) return;
                                            context.showSnackBar('Silme hatası: $e');
                                          }
                                        }
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final currentUser = Supabase.instance.client.auth.currentUser;
                                        final userId = currentUser?.id;
                                        if (userId == null) return;
                                        try {
                                          await OdemeService().updateOdemeDurum(o.id!, 'onaylandi', onaylayanId: userId);
                                          // Bildirim: Admin onayladığında ilgili personele gönder
                                          try {
                                            final personelUserId = o.userId;
                                            await NotificationService().sendNotification(
                                              userId: personelUserId,
                                              title: 'Avans/Ödeme Talebiniz Onaylandı',
                                              message: 'Talebiniz yönetici tarafından onaylandı.',
                                            );
                                          } catch (bildirimHata) {
                                            debugPrint('Bildirim gönderme hatası: $bildirimHata');
                                            // Bildirim hatası olsa bile işlemi devam ettir
                                          }
                                          if (!context.mounted) return;
                                          context.showSnackBar('Ödeme onaylandı ve maaş hesaplamalarına dahil edildi.');
                                          _getOdemeler();
                                        } catch (e) {
                                          debugPrint('Onaylama hatası: $e');
                                          if (!context.mounted) return;
                                          context.showSnackBar('Onaylama hatası: $e');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Onayla'),
                                    ),
                                  ],
                                );
                              }
                              // Kullanıcı kendi avans kaydı için düzenle/sil butonları (personel veya admin olsun fark etmez)
                              if (o.tur == 'avans' && o.userId == currentUserId && o.durum == 'beklemede') {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      tooltip: 'Düzenle',
                                      onPressed: () async {
                                        // Avans düzenleme dialogu
                                        final tutarController = TextEditingController(text: o.tutar.toString());
                                        final aciklamaController = TextEditingController(text: o.aciklama);
                                        final formKey = GlobalKey<FormState>();
                                        final guncellenen = await showDialog<OdemeModel>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Avans Talebini Düzenle', style: TextStyle(color: Colors.blue)),
                                            content: Form(
                                              key: formKey,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextFormField(
                                                    controller: tutarController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(labelText: 'Tutar', labelStyle: TextStyle(color: Colors.blue)),
                                                    validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                                                  ),
                                                  TextFormField(
                                                    controller: aciklamaController,
                                                    decoration: const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(color: Colors.blue)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (formKey.currentState?.validate() != true) return;
                                                  final yeniTutar = double.tryParse(tutarController.text) ?? o.tutar;
                                                  final yeniAciklama = aciklamaController.text;
                                                  final guncellenenOdeme = OdemeModel(
                                                    id: o.id,
                                                    personelId: o.personelId,
                                                    userId: o.userId,
                                                    tur: o.tur,
                                                    tutar: yeniTutar,
                                                    aciklama: yeniAciklama,
                                                    tarih: o.tarih,
                                                    durum: o.durum,
                                                    onaylayanId: o.onaylayanId,
                                                  );
                                                  Navigator.pop(ctx, guncellenenOdeme);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (guncellenen != null) {
                                          try {
                                            await OdemeService().updateOdeme(o.id!, guncellenen.toMap());
                                            if (!context.mounted) return;
                                            context.showSnackBar('Avans talebi başarıyla güncellendi!');
                                            _getOdemeler();
                                          } catch (e) {
                                            debugPrint('Avans güncelleme hatası: $e');
                                            if (!context.mounted) return;
                                            context.showSnackBar('Güncelleme hatası: $e');
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Sil',
                                      onPressed: () async {
                                        final onay = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Avans Talebini Sil', style: TextStyle(color: Colors.blue)),
                                            content: const Text('Bu avans talebini silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.blue)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (onay == true) {
                                          try {
                                            await OdemeService().deleteOdeme(o.id!);
                                            if (!context.mounted) return;
                                            context.showSnackBar('Avans talebi başarıyla silindi!');
                                            _getOdemeler();
                                          } catch (e) {
                                            debugPrint('Avans silme hatası: $e');
                                            if (!context.mounted) return;
                                            context.showSnackBar('Silme hatası: $e');
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                );
                              }
                              // Admin için onaylanmış kayıtlarda düzenle/sil butonları
                              if (snapshot.data == true && o.durum == 'onaylandi') {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orange),
                                      tooltip: 'Düzenle',
                                      onPressed: () async {
                                        final tutarController = TextEditingController(text: o.tutar.toString());
                                        final aciklamaController = TextEditingController(text: o.aciklama);
                                        final formKey = GlobalKey<FormState>();
                                        final guncellenen = await showDialog<OdemeModel>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Ödeme Kaydını Düzenle', style: TextStyle(color: Colors.blue)),
                                            content: Form(
                                              key: formKey,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextFormField(
                                                    controller: tutarController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(labelText: 'Tutar', labelStyle: TextStyle(color: Colors.blue)),
                                                    validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                                                  ),
                                                  TextFormField(
                                                    controller: aciklamaController,
                                                    decoration: const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(color: Colors.blue)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (formKey.currentState?.validate() != true) return;
                                                  final yeniTutar = double.tryParse(tutarController.text) ?? o.tutar;
                                                  final yeniAciklama = aciklamaController.text;
                                                  final guncellenenOdeme = OdemeModel(
                                                    id: o.id,
                                                    personelId: o.personelId,
                                                    userId: o.userId,
                                                    tur: o.tur,
                                                    tutar: yeniTutar,
                                                    aciklama: yeniAciklama,
                                                    tarih: o.tarih,
                                                    durum: o.durum,
                                                    onaylayanId: o.onaylayanId,
                                                  );
                                                  Navigator.pop(ctx, guncellenenOdeme);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (guncellenen != null) {
                                          try {
                                            await OdemeService().updateOdeme(o.id!, guncellenen.toMap());
                                            if (!context.mounted) return;
                                            context.showSnackBar('Ödeme kaydı başarıyla güncellendi!');
                                            _getOdemeler();
                                          } catch (e) {
                                            debugPrint('Ödeme güncelleme hatası: $e');
                                            if (!context.mounted) return;
                                            context.showSnackBar('Güncelleme hatası: $e');
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Sil',
                                      onPressed: () async {
                                        final onay = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Silme Onayı', style: TextStyle(color: Colors.blue)),
                                            content: const Text('Bu onaylanmış ödeme kaydını silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.blue)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                style: TextButton.styleFrom(backgroundColor: Colors.blue),
                                                child: const Text('İptal', style: TextStyle(color: Colors.white)),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (onay == true) {
                                          try {
                                            await OdemeService().deleteOdeme(o.id!);
                                            if (!context.mounted) return;
                                            context.showSnackBar('Ödeme kaydı başarıyla silindi!');
                                            _getOdemeler();
                                          } catch (e) {
                                            debugPrint('Ödeme silme hatası: $e');
                                            if (!context.mounted) return;
                                            context.showSnackBar('Silme hatası: $e');
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _yeniOdemeEkle,
        backgroundColor: Colors.blue,
        tooltip: 'Yeni Avans/Ödeme',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MesaiOzetHesaplama extends StatelessWidget {
  final String personelId;
  final double saatlikMesaiUcreti;

  const MesaiOzetHesaplama({super.key, required this.personelId, required this.saatlikMesaiUcreti});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _getToplamMesaiSaati(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Container(
            height: 56,
            color: Colors.red.shade50,
            child: Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }
        final toplamMesaiSaati = snapshot.data ?? 0;
        final toplamMesaiUcreti = toplamMesaiSaati * saatlikMesaiUcreti;
        return Container(
          height: 56,
          color: Colors.blue.shade50,
          child: Center(
            child: Text(
              'Mesai: ${toplamMesaiSaati.toStringAsFixed(2)} saat - ${toplamMesaiUcreti.toStringAsFixed(2)} TL',
              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Future<double> _getToplamMesaiSaati() async {
    final toplamMesai = await MesaiService().getAylikFazlaMesaiSaati(personelId, DateTime.now().year, DateTime.now().month);
    return toplamMesai;
  }
}