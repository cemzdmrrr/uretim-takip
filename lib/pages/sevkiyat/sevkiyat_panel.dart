import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/app_routes.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'sevkiyat_panel_widgets.dart';


class SevkiyatPanel extends StatefulWidget {
  const SevkiyatPanel({Key? key}) : super(key: key);

  @override
  State<SevkiyatPanel> createState() => _SevkiyatPanelState();
}

class _SevkiyatPanelState extends State<SevkiyatPanel> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> bekleyenSevkler = [];      // Kalite kontrolden gelen, sevk bekleyen
  List<Map<String, dynamic>> devamEdenSevkler = [];     // Sevk edilmekte olan
  List<Map<String, dynamic>> tamamlananSevkler = [];    // Tamamlanan sevkler
  
  bool yukleniyor = true;
  String aramaMetni = '';
  final TextEditingController _aramaController = TextEditingController();

  // Hedef aşamalar listesi
  final List<Map<String, dynamic>> hedefAsamalar = [
    {'key': 'nakis', 'name': 'Nakış', 'icon': Icons.design_services, 'color': Colors.purple},
    {'key': 'konfeksiyon', 'name': 'Konfeksiyon', 'icon': Icons.checkroom, 'color': Colors.blue},
    {'key': 'yikama', 'name': 'Yıkama', 'icon': Icons.local_laundry_service, 'color': Colors.cyan},
    {'key': 'utu', 'name': 'Ütü', 'icon': Icons.iron, 'color': Colors.orange},
    {'key': 'ilik_dugme', 'name': 'İlik Düğme', 'icon': Icons.radio_button_checked, 'color': Colors.teal},
    {'key': 'depo', 'name': 'Depo', 'icon': Icons.warehouse, 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verileriYukle();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    setState(() => yukleniyor = true);
    
    try {
      // Önce sevkiyat_kayitlari tablosundan veri çekmeyi dene
      final List<Map<String, dynamic>> zenginKayitlar = [];
      bool sevkiyatTablosuVar = true;
      
      try {
        // JOIN ile tek sorguda model bilgilerini al (N+1 problemi çözümü)
        final sevkiyatResponse = await supabase
            .from(DbTables.sevkiyatKayitlari)
            .select('''
              *,
              triko_takip:model_id (
                id, marka, item_no, renk, adet, termin_tarihi
              ),
              kalite_kontrol:kalite_kontrol_id (
                kontrol_edilecek_adet
              )
            ''')
            .eq('firma_id', TenantManager.instance.requireFirmaId)
            .order('created_at', ascending: false);
        
        // Model bilgisi olan kayıtları filtrele ve zenginleştir
        for (var kayit in sevkiyatResponse) {
          if (kayit[DbTables.trikoTakip] != null) {
            // Adet alanlarını uyumlu hale getir
            // alinan_adet 0 ise kalite_kontrol tablosundan kontrol_edilecek_adet çek
            final alinanAdet = kayit['alinan_adet'] ?? 0;
            final kontrolAdet = kayit['kalite_kontrol']?['kontrol_edilecek_adet'] ?? 0;
            final finalAdet = alinanAdet > 0 ? alinanAdet : kontrolAdet;
            
            kayit['adet'] = finalAdet;
            kayit['talep_edilen_adet'] = finalAdet;
            kayit['tamamlanan_adet'] = kayit['sevk_edilen_adet'];
            zenginKayitlar.add(kayit);
          }
        }
      } catch (e) {
        sevkiyatTablosuVar = false;
      }
      
      // Eğer sevkiyat_kayitlari tablosu yoksa veya boşsa, paketleme_atamalari kullan
      if (!sevkiyatTablosuVar || zenginKayitlar.isEmpty) {
        // JOIN ile tek sorguda model bilgilerini al
        final paketlemeResponse = await supabase
            .from(DbTables.paketlemeAtamalari)
            .select('''
              *,
              triko_takip:model_id (
                id, marka, item_no, renk, adet, termin_tarihi
              )
            ''')
            .eq('firma_id', TenantManager.instance.requireFirmaId)
            .order('created_at', ascending: false);

        for (var paket in paketlemeResponse) {
          if (paket[DbTables.trikoTakip] != null) {
            paket['kaynak_tablo'] = DbTables.paketlemeAtamalari;
            zenginKayitlar.add(paket);
          }
        }
      }

      setState(() {
        // Bekleyenler: beklemede, atandi durumu
        bekleyenSevkler = zenginKayitlar.where((p) => 
          p['durum'] == 'atandi' || 
          p['durum'] == 'beklemede'
        ).toList();
        
        // Devam edenler: kismen_sevk, baslandi, uretimde, sevk_ediliyor
        devamEdenSevkler = zenginKayitlar.where((p) => 
          p['durum'] == 'kismen_sevk' ||
          p['durum'] == 'baslandi' ||
          p['durum'] == 'uretimde' ||
          p['durum'] == 'sevk_ediliyor'
        ).toList();
        
        // Tamamlananlar
        tamamlananSevkler = zenginKayitlar.where((p) => 
          p['durum'] == 'tamamlandi' ||
          p['durum'] == 'sevk_edildi'
        ).toList();
        
        yukleniyor = false;
      });

    } catch (e) {
      debugPrint('❌ Sevkiyat verileri yüklenemedi: $e');
      setState(() => yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Veri yükleme hatası: $e');
      }
    }
  }

  List<Map<String, dynamic>> _filtreleListe(List<Map<String, dynamic>> liste) {
    if (aramaMetni.isEmpty) return liste;
    return liste.where((item) {
      final model = item[DbTables.trikoTakip] as Map<String, dynamic>?;
      if (model == null) return false;
      final marka = (model['marka'] ?? '').toString().toLowerCase();
      final itemNo = (model['item_no'] ?? '').toString().toLowerCase();
      final renk = (model['renk'] ?? '').toString().toLowerCase();
      final aranan = aramaMetni.toLowerCase();
      return marka.contains(aranan) || itemNo.contains(aranan) || renk.contains(aranan);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtreliBekleyenler = _filtreleListe(bekleyenSevkler);
    final filtreliDevamEdenler = _filtreleListe(devamEdenSevkler);
    final filtreliTamamlananlar = _filtreleListe(tamamlananSevkler);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sevkiyat Paneli'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showAramaDialog,
            tooltip: 'Ara',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (!context.mounted) return;
              if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            tooltip: 'Çıkış',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${filtreliBekleyenler.length}'),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Sevk Bekleyen',
            ),
            Tab(
              icon: Badge(
                label: Text('${filtreliDevamEdenler.length}'),
                backgroundColor: Colors.blue,
                child: const Icon(Icons.local_shipping),
              ),
              text: 'Sevk Ediliyor',
            ),
            Tab(
              icon: Badge(
                label: Text('${filtreliTamamlananlar.length}'),
                backgroundColor: Colors.green,
                child: const Icon(Icons.check_circle),
              ),
              text: 'Tamamlanan',
            ),
          ],
        ),
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSevkListesi(filtreliBekleyenler, 'bekleyen'),
                _buildSevkListesi(filtreliDevamEdenler, 'devam'),
                _buildSevkListesi(filtreliTamamlananlar, 'tamamlanan'),
              ],
            ),
    );
  }

}


/// Üretim aşamalarını gösteren widget
class _UretimAsamalariWidget extends StatefulWidget {
  final String modelId;
  final SupabaseClient supabase;
  
  const _UretimAsamalariWidget({
    required this.modelId,
    required this.supabase,
  });

  @override
  State<_UretimAsamalariWidget> createState() => _UretimAsamalariWidgetState();
}

class _UretimAsamalariWidgetState extends State<_UretimAsamalariWidget> {
  List<Map<String, dynamic>> asamaDurumlari = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _asamalariYukle();
  }

  Future<void> _asamalariYukle() async {
    try {
      final asamalar = [
        {'ad': 'Dokuma', 'kod': 'dokuma', 'tablo': DbTables.dokumaAtamalari, 'icon': Icons.grain, 'renk': Colors.brown},
        {'ad': 'Nakış', 'kod': 'nakis', 'tablo': DbTables.nakisAtamalari, 'icon': Icons.brush, 'renk': Colors.pink},
        {'ad': 'Konfeksiyon', 'kod': 'konfeksiyon', 'tablo': DbTables.konfeksiyonAtamalari, 'icon': Icons.content_cut, 'renk': Colors.purple},
        {'ad': 'Yıkama', 'kod': 'yikama', 'tablo': DbTables.yikamaAtamalari, 'icon': Icons.local_laundry_service, 'renk': Colors.cyan},
        {'ad': 'İlik/Düğme', 'kod': 'ilik_dugme', 'tablo': DbTables.ilikDugmeAtamalari, 'icon': Icons.radio_button_unchecked, 'renk': Colors.indigo},
        {'ad': 'Ütü', 'kod': 'utu', 'tablo': DbTables.utuAtamalari, 'icon': Icons.iron, 'renk': Colors.green},
        {'ad': 'Kalite Kontrol', 'kod': 'kalite_kontrol', 'tablo': DbTables.kaliteKontrolAtamalari, 'icon': Icons.verified, 'renk': Colors.teal},
        {'ad': 'Paketleme', 'kod': 'paketleme', 'tablo': DbTables.paketlemeAtamalari, 'icon': Icons.inventory_2, 'renk': Colors.deepOrange},
      ];

      final List<Map<String, dynamic>> sonuclar = [];

      for (var asama in asamalar) {
        try {
          final response = await widget.supabase
              .from(asama['tablo'] as String)
              .select('*')
              .eq('model_id', widget.modelId)
              .order('created_at', ascending: false);

          String durum = 'bekliyor';
          int toplamAdet = 0;
          int tamamlananAdet = 0;
          DateTime? baslangicTarihi;
          DateTime? bitisTarihi;

          for (var atama in response) {
            toplamAdet += (atama['adet'] ?? atama['talep_edilen_adet'] ?? 0) as int;
            tamamlananAdet += (atama['tamamlanan_adet'] ?? 0) as int;

            if (atama['created_at'] != null) {
              final createdAt = DateTime.tryParse(atama['created_at'].toString());
              if (createdAt != null && (baslangicTarihi == null || createdAt.isBefore(baslangicTarihi))) {
                baslangicTarihi = createdAt;
              }
            }

            if (atama['updated_at'] != null && (atama['durum']?.toString().toLowerCase() == 'tamamlandi')) {
              final updatedAt = DateTime.tryParse(atama['updated_at'].toString());
              if (updatedAt != null && (bitisTarihi == null || updatedAt.isAfter(bitisTarihi))) {
                bitisTarihi = updatedAt;
              }
            }
          }

          if (response.isEmpty) {
            durum = 'bekliyor';
          } else if (tamamlananAdet >= toplamAdet && toplamAdet > 0) {
            durum = 'tamamlandi';
          } else if (tamamlananAdet > 0) {
            durum = 'devam_ediyor';
          } else if (toplamAdet > 0) {
            durum = 'atandi';
          }

          sonuclar.add({
            'ad': asama['ad'],
            'kod': asama['kod'],
            'icon': asama['icon'],
            'renk': asama['renk'],
            'durum': durum,
            'toplamAdet': toplamAdet,
            'tamamlananAdet': tamamlananAdet,
            'baslangicTarihi': baslangicTarihi,
            'bitisTarihi': bitisTarihi,
          });
        } catch (e) {
          // Tablo yoksa veya hata varsa bekliyor olarak işaretle
          sonuclar.add({
            'ad': asama['ad'],
            'kod': asama['kod'],
            'icon': asama['icon'],
            'renk': asama['renk'],
            'durum': 'bekliyor',
            'toplamAdet': 0,
            'tamamlananAdet': 0,
            'baslangicTarihi': null,
            'bitisTarihi': null,
          });
        }
      }

      if (mounted) {
        setState(() {
          asamaDurumlari = sonuclar;
          yukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint('Aşama yükleme hatası: $e');
      if (mounted) {
        setState(() {
          yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: asamaDurumlari.map((asama) {
        final durum = asama['durum'] as String;
        Color durumRengi;
        String durumMetni;
        IconData durumIkonu;

        switch (durum) {
          case 'tamamlandi':
            durumRengi = Colors.green;
            durumMetni = 'Tamamlandı';
            durumIkonu = Icons.check_circle;
            break;
          case 'devam_ediyor':
            durumRengi = Colors.orange;
            durumMetni = 'Devam Ediyor';
            durumIkonu = Icons.autorenew;
            break;
          case 'atandi':
            durumRengi = Colors.blue;
            durumMetni = 'Atandı';
            durumIkonu = Icons.assignment;
            break;
          default:
            durumRengi = Colors.grey;
            durumMetni = 'Bekliyor';
            durumIkonu = Icons.schedule;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: durumRengi.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: durumRengi, width: 4)),
          ),
          child: Row(
            children: [
              Icon(asama['icon'] as IconData, color: asama['renk'] as Color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asama['ad'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if ((asama['toplamAdet'] as int) > 0)
                      Text(
                        '${asama['tamamlananAdet']}/${asama['toplamAdet']} adet',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    if (asama['baslangicTarihi'] != null)
                      Text(
                        'Başlangıç: ${DateFormat('dd.MM.yyyy').format(asama['baslangicTarihi'] as DateTime)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: durumRengi,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(durumIkonu, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      durumMetni,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
