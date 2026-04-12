import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/pages/personel/personel_ayarlar_page.dart';
import 'package:uretim_takip/pages/personel/personel_listesi_page.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/pages/muhasebe/bordro_page.dart';
import 'package:uretim_takip/pages/muhasebe/izin_page.dart';
import 'package:uretim_takip/pages/personel/personel_analiz_page.dart';
import 'package:uretim_takip/pages/personel/personel_detay_page.dart';
import 'package:uretim_takip/pages/muhasebe/odeme_page.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';
import 'package:uretim_takip/widgets/yeni_donem_dialog.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class PersonelAnaSayfa extends StatefulWidget {
  final String kullaniciRolu;
  const PersonelAnaSayfa({super.key, required this.kullaniciRolu});

  @override
  State<PersonelAnaSayfa> createState() => _PersonelAnaSayfaState();
}

class _PersonelAnaSayfaState extends State<PersonelAnaSayfa> {
  int toplamPersonel = 0;
  int toplamIzin = 0;
  int toplamBordro = 0;
  int toplamMesai = 0;
  double toplamMesaiSaati = 0;
  double toplamOdeme = 0;
  double bankaMaas = 0;
  double eldenMaas = 0;
  int departmanSayisi = 0;
  bool yukleniyor = true;
  int? hoveredMenuIndex; // Menüde hover olan butonun indexi
  String? aktifDonem;
  String? seciliDonem;

  @override
  void initState() {
    super.initState();
    _loadAktifDonem();
    _getDashboardData();
  }

  Future<void> _loadAktifDonem() async {
    try {
      // Varsayılan olarak güncel ay/yıl
      final now = DateTime.now();
      aktifDonem = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      seciliDonem = null; // Başlangıçta null yap, böylece "Tüm Dönemler" seçili olur
      setState(() {});
    } catch (e) {
      // Hata durumunda varsayılan değer kullan
      aktifDonem = DateTime.now().year.toString();
      seciliDonem = null;
      setState(() {});
    }
  }

  Future<void> _getDashboardData() async {
    setState(() => yukleniyor = true);
    
    try {
      final client = Supabase.instance.client;
      
      // Tarih aralığını belirle
      DateTime baslangicTarihi, bitisTarihi;
      if (seciliDonem != null) {
        // Seçili dönem varsa o dönemi kullan
        final parts = seciliDonem!.split('-');
        final yil = int.parse(parts[0]);
        final ay = int.parse(parts[1]);
        baslangicTarihi = DateTime(yil, ay, 1);
        bitisTarihi = DateTime(yil, ay + 1, 1);
      } else {
        // Seçili dönem yoksa "Tüm Dönemler" - son 12 ay
        final now = DateTime.now();
        baslangicTarihi = DateTime(now.year - 1, now.month, 1);
        bitisTarihi = DateTime(now.year, now.month + 1, 1);
      }
      
      // Personel sayısı ve departman bilgileri (dönemden bağımsız)
      final allPersonelRes = await client
          .from(DbTables.personel)
          .select('user_id, departman, brut_maas, net_maas, banka_maas, elden_maas')
          .eq('firma_id', TenantManager.instance.requireFirmaId);
      
      debugPrint('Personel tablosundan dönen veriler: $allPersonelRes');
      debugPrint('Toplam personel sayısı: ${allPersonelRes.length}');
      
      final departmanlar = <String>{};
      double bankaMaasLocal = 0, eldenMaasLocal = 0;
      
      for (final p in allPersonelRes) {
        if (p['departman'] != null && p['departman'].toString().trim().isNotEmpty) {
          departmanlar.add(p['departman'].toString());
        }
        
        // Maaş bilgilerini topla
        final bankaMaasValue = double.tryParse(p['banka_maas']?.toString() ?? '0') ?? 0;
        final netMaasValue = double.tryParse(p['net_maas']?.toString() ?? '0') ?? 0;
        
        // Elden maaş = Net maaş - Banka maaş (personelin banka dışında alacağı)
        final eldenMaasValue = netMaasValue - bankaMaasValue;
        
        debugPrint('Personel ${p['user_id']}: net_maas=$netMaasValue, banka_maas=$bankaMaasValue, hesaplanan_elden_maas=$eldenMaasValue');
        
        bankaMaasLocal += bankaMaasValue;
        eldenMaasLocal += eldenMaasValue > 0 ? eldenMaasValue : 0; // Negatif değerleri 0 yap
      }
      
      // Seçili dönem için izin sayısı
      final izinRes = await client
          .from(DbTables.izinler)
          .select('id')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('baslama_tarihi', baslangicTarihi.toIso8601String().split('T')[0])
          .lt('baslama_tarihi', bitisTarihi.toIso8601String().split('T')[0])
          .eq('onay_durumu', 'onaylandi');
      
      // Seçili dönem için bordro sayısı
      final bordroQuery = client.from(DbTables.bordro).select('id').eq('firma_id', TenantManager.instance.requireFirmaId);
      final bordroRes = seciliDonem != null
          ? await bordroQuery.ilike('donem_kodu', '$seciliDonem%')
          : await bordroQuery;
      
      // Seçili dönem için mesai sayısı ve toplam saat
      final mesaiRes = await client
          .from(DbTables.mesai)
          .select('id, saat')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('tarih', baslangicTarihi.toIso8601String().split('T')[0])
          .lt('tarih', bitisTarihi.toIso8601String().split('T')[0])
          .eq('onay_durumu', 'onaylandi');
      
      double toplamMesaiSaati = 0;
      for (final mesai in mesaiRes) {
        toplamMesaiSaati += (mesai['saat'] as num? ?? 0).toDouble();
      }
      
      // Seçili dönem için toplam ödeme
      final odemeRes = await client
          .from(DbTables.odemeKayitlari)
          .select('tutar')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('tarih', baslangicTarihi.toIso8601String().split('T')[0])
          .lt('tarih', bitisTarihi.toIso8601String().split('T')[0])
          .eq('durum', 'onaylandi');
      
      double toplamOdemeLocal = 0;
      for (final odeme in odemeRes) {
        toplamOdemeLocal += (odeme['tutar'] as num? ?? 0).toDouble();
      }
      
      setState(() {
        toplamPersonel = allPersonelRes.length;
        toplamIzin = izinRes.length;
        toplamBordro = bordroRes.length;
        toplamMesai = mesaiRes.length;
        this.toplamMesaiSaati = toplamMesaiSaati;
        toplamOdeme = toplamOdemeLocal; // Sadece gerçek ödemeler
        bankaMaas = bankaMaasLocal;
        eldenMaas = eldenMaasLocal;
        departmanSayisi = departmanlar.length;
        yukleniyor = false;
      });
      
    } catch (e) {
      debugPrint('Dashboard veri yükleme hatası: $e');
      setState(() {
        yukleniyor = false;
      });
    }
  }

  String _getDonemText() {
    if (seciliDonem == null) return 'Tüm Dönemler';
    
    final parts = seciliDonem!.split('-');
    if (parts.length != 2) return seciliDonem!;
    
    final yil = parts[0];
    final ay = int.tryParse(parts[1]) ?? 1;
    
    const aylar = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    return '${aylar[ay]} $yil';
  }

  Future<void> _yeniDonemEkle(BuildContext context) async {
    // Admin kontrolü - admin tüm yetkilere sahip
    if (widget.kullaniciRolu != 'admin' && widget.kullaniciRolu != 'ik') {
      context.showErrorSnackBar('Bu işlem için admin veya IK yetkisi gereklidir!');
      return;
    }

    // Kullanıcı ID'sini al
    final kullaniciId = Supabase.instance.client.auth.currentUser?.id;
    if (kullaniciId == null) {
      context.showErrorSnackBar('Kullanıcı bilgisi alınamadı!');
      return;
    }

    // Dialog'u göster
    showDialog(
      context: context,
      builder: (context) => YeniDonemDialog(
        kullaniciId: kullaniciId,
        onDonemEklendi: () {
          // Dönem eklendikten sonra dashboard'u güncelle
          _getDashboardData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kullaniciRolu = widget.kullaniciRolu;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final Widget menuWidget = _buildMenu(context, kullaniciRolu, isMobile);
    if (kullaniciRolu == DbTables.personel) {
      return Scaffold(
        backgroundColor: Colors.blueGrey.shade50,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              const Icon(Icons.dashboard_customize, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isMobile ? 'Personel' : 'Personel Paneli',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade800,
        ),
        drawer: isMobile ? Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade800,
                  width: double.infinity,
                  child: const Text('Menü', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text('Kişisel Bilgilerim'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PersonelDetayPage(id: Supabase.instance.client.auth.currentUser!.id)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.blue),
                  title: const Text('Avans Taleplerim'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OdemePage(personelId: Supabase.instance.client.auth.currentUser!.id)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.beach_access, color: Colors.blue),
                  title: const Text('İzin Taleplerim'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => IzinPage(personelId: Supabase.instance.client.auth.currentUser!.id)));
                  },
                ),
              ],
            ),
          ),
        ) : null,
        body: isMobile
            ? const Center(
                child: Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 32),
                        SizedBox(height: 12),
                        Text('Menüden işlem seçiniz.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              )
            : Row(
          children: [
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Menü', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      const SizedBox(height: 20),
                      _menuButton(context, Icons.person, 'Kişisel Bilgilerim', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PersonelDetayPage(id: Supabase.instance.client.auth.currentUser!.id)));
                      }),
                      _menuButton(context, Icons.beach_access, 'İzin Taleplerim', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => IzinPage(personelId: Supabase.instance.client.auth.currentUser!.id)));
                      }),
                    ],
                  ),
                ),
              ),
            ),
            // Orta alan boş bırakılabilir veya duyuru eklenebilir
            const Expanded(
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(24),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 32),
                        SizedBox(height: 12),
                        Text('Sadece kendi bilgilerinizi ve taleplerinizi görüntüleyebilirsiniz.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isMobile ? 'Personel Paneli' : 'Personel Yönetim Paneli',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 6,
        shadowColor: Colors.blue.shade200,
        actions: isMobile
            ? [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
              ]
            : null,
      ),
      drawer: isMobile ? Drawer(child: menuWidget) : null,
      body: yukleniyor
          ? const LoadingWidget()
          : Row(
              children: [
                if (!isMobile) menuWidget,
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      if (width > 1200) {
                      } else if (width > 900) {
                      } else if (width > 600) {
                      }
                      return SingleChildScrollView(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.withValues(alpha: 0.10),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, headerConstraints) {
                                    final isMobileHeader = headerConstraints.maxWidth < 600;
                                    
                                    if (isMobileHeader) {
                                      // Mobil görünüm - dikey düzen
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.dashboard, color: Colors.blue, size: 22),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text('Genel Bakış', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (kullaniciRolu == 'admin' || kullaniciRolu == 'ik')
                                                ElevatedButton.icon(
                                                  onPressed: () => _yeniDonemEkle(context),
                                                  icon: const Icon(Icons.add, size: 16),
                                                  label: const Text('Yeni Dönem', style: TextStyle(fontSize: 12)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green.shade600,
                                                    foregroundColor: Colors.white,
                                                    elevation: 2,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  ),
                                                ),
                                              SizedBox(
                                                width: isMobileHeader ? headerConstraints.maxWidth - (kullaniciRolu == 'admin' || kullaniciRolu == 'ik' ? 130 : 0) : null,
                                                child: DonemSecici(
                                                  seciliDonem: seciliDonem,
                                                  onDonemChanged: (donem) {
                                                    setState(() {
                                                      seciliDonem = donem;
                                                      yukleniyor = true;
                                                    });
                                                    _getDashboardData();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }
                                    
                                    // Desktop görünüm - yatay düzen
                                    return Row(
                                      children: [
                                        const Icon(Icons.dashboard, color: Colors.blue, size: 32),
                                        const SizedBox(width: 12),
                                        Text('Genel Bakış', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                        const Spacer(),
                                        if (kullaniciRolu == 'admin' || kullaniciRolu == 'ik')
                                          ElevatedButton.icon(
                                            onPressed: () => _yeniDonemEkle(context),
                                            icon: const Icon(Icons.add, size: 18),
                                            label: const Text('Yeni Dönem'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green.shade600,
                                              foregroundColor: Colors.white,
                                              elevation: 2,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                          ),
                                        if (kullaniciRolu == 'admin' || kullaniciRolu == 'ik')
                                          const SizedBox(width: 12),
                                        DonemSecici(
                                          seciliDonem: seciliDonem,
                                          onDonemChanged: (donem) {
                                            setState(() {
                                              seciliDonem = donem;
                                              yukleniyor = true;
                                            });
                                            _getDashboardData();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double maxWidth = constraints.maxWidth;
                                    int crossAxisCount = 1;
                                    if (maxWidth > 1200) {
                                      crossAxisCount = 4;
                                    } else if (maxWidth > 900) {
                                      crossAxisCount = 3;
                                    } else if (maxWidth > 600) {
                                      crossAxisCount = 2;
                                    }
                                    final double cardWidth = (maxWidth - (crossAxisCount - 1) * 24) / crossAxisCount;
                                    return Wrap(
                                      spacing: 24,
                                      runSpacing: 24,
                                      children: [
                                        _dashboardCard(Icons.people, 'Toplam Personel', '$toplamPersonel', color: Colors.blue, width: cardWidth),
                                        _dashboardCard(Icons.beach_access, seciliDonem != null ? 'İzin (${_getDonemText()})' : 'İzin (Tüm Dönemler)', '$toplamIzin', color: Colors.orange, width: cardWidth),
                                        _dashboardCard(Icons.receipt_long, seciliDonem != null ? 'Bordro (${_getDonemText()})' : 'Bordro (Tüm Dönemler)', '$toplamBordro', color: Colors.green, width: cardWidth),
                                        _dashboardCard(Icons.access_time, seciliDonem != null ? 'Mesai (${_getDonemText()})' : 'Mesai (Tüm Dönemler)', '$toplamMesai (${toplamMesaiSaati.toStringAsFixed(1)} saat)', color: Colors.purple, width: cardWidth),
                                        _dashboardCard(Icons.attach_money, seciliDonem != null ? 'Ödeme (${_getDonemText()})' : 'Ödeme (Tüm Dönemler)', '₺${toplamOdeme.toStringAsFixed(2)}', color: Colors.teal, width: cardWidth),
                                        _dashboardCard(Icons.account_balance, 'Banka Maaşları', '₺${bankaMaas.toStringAsFixed(2)}', color: Colors.indigo, width: cardWidth),
                                        _dashboardCard(Icons.money, 'Elden Maaşlar', '₺${eldenMaas.toStringAsFixed(2)}', color: Colors.brown, width: cardWidth),
                                        _dashboardCard(Icons.apartment, 'Departman Sayısı', '$departmanSayisi', color: Colors.deepOrange, width: cardWidth),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 40),
                                Text('Duyurular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                                const SizedBox(height: 12),
                                Card(
                                  color: Colors.blue.shade50,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: const ListTile(
                                    leading: Icon(Icons.announcement, color: Colors.blue),
                                    title: Text('Hoş geldiniz! Personel yönetim panelini kullanmaya başlayabilirsiniz.'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenu(BuildContext context, String kullaniciRolu, bool isMobile) {
    final menuItems = <Map<String, dynamic>>[
      {'icon': Icons.dashboard, 'title': 'Dashboard', 'onTap': null},
      if (kullaniciRolu == 'admin' || kullaniciRolu == 'ik')
        {'icon': Icons.settings, 'title': 'Ayarlar', 'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonelAyarlarPage()));
        }},
      {'icon': Icons.person_add, 'title': 'Yeni Personel Ekle', 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonelEklePage()));
      }},
      {'icon': Icons.list, 'title': 'Personel Listesi', 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonelListesiPage()));
      }},
      {'icon': Icons.receipt_long, 'title': 'Bordro Yönetimi', 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BordroPage()));
      }},
      {'icon': Icons.analytics, 'title': 'Raporlama ve Analiz', 'onTap': () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonelAnalizPage()));
      }},
    ];
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Menü', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              const SizedBox(height: 32),
              ...List.generate(menuItems.length, (index) {
                final item = menuItems[index];
                return _menuButton(context, item['icon'], item['title'], item['onTap'],
                  isMobile: isMobile,
                  index: index,
                );
              }),
              const SizedBox(height: 32),
              Divider(color: Colors.blueGrey.shade100, thickness: 1),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blueGrey, size: 18),
                    const SizedBox(width: 8),
                    Text('v1.0.0', style: TextStyle(color: Colors.blueGrey.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, IconData icon, String title, VoidCallback? onTap, {bool isMobile = false, int? index}) {
    // Menü her zaman başlıkları göstersin - hover gerekmez
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: Colors.blue.shade50,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 32,
      ),
    );
  }

  // Dashboard kartı fonksiyonu güncellendi
  Widget _dashboardCard(IconData icon, String title, String value, {Color color = Colors.blue, double? width}) {
    return SizedBox(
      width: width ?? 210,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
