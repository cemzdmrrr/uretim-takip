import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'personel_analiz_widgets.dart';


class PersonelAnalizPage extends StatefulWidget {
  const PersonelAnalizPage({super.key});

  @override
  State<PersonelAnalizPage> createState() => _PersonelAnalizPageState();
}

class _PersonelAnalizPageState extends State<PersonelAnalizPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool yukleniyor = true;
  String? hata;
  String? seciliDonem;
  String raporTipi = 'all'; // 'all', 'monthly', 'yearly'
  int seciliYil = DateTime.now().year;
  int seciliAy = DateTime.now().month;
  
  // Genel İstatistikler
  int toplamPersonel = 0;
  int aktifPersonel = 0;
  int pasifPersonel = 0;
  double ortalamaKidem = 0; // yıl cinsinden
  double ortalamaYas = 0;
  double ortalamaNetMaas = 0;
  double toplamMaasBedeli = 0;
  
  // Departman Analizi
  final Map<String, Map<String, dynamic>> departmanIstatistikleri = {};
  
  // Maaş Analizi
  double enDusukMaas = 0;
  double enYuksekMaas = 0;
  double medyanMaas = 0;
  final Map<String, int> maasDilimleri = {};
  
  // İzin Analizi
  double ortalamaIzinKullanimOrani = 0;
  int toplamKullanilanIzin = 0;
  int toplamKalanIzin = 0;
  final List<Map<String, dynamic>> enCokIzinKullananlar = [];
  
  // Mesai Analizi
  double toplamMesaiSaati = 0;
  double ortalamaMesaiSaati = 0;
  final List<Map<String, dynamic>> enCokMesaiYapanlar = [];
  
  // Performans Analizi
  final List<Map<String, dynamic>> personelPerformans = [];
  
  // Trend Verileri
  final List<Map<String, dynamic>> aylikPersonelSayisi = [];
  final List<Map<String, dynamic>> aylikMaasTrendi = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalizData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalizData() async {
    setState(() {
      yukleniyor = true;
      hata = null;
    });
    
    try {
      final client = Supabase.instance.client;
      
      // 1. TÜM PERSONELLERİ YÜKLE (aktif ve pasif)
      final personelRes = await client
          .from(DbTables.personel)
          .select('*')
          .eq('firma_id', TenantManager.instance.requireFirmaId);
      
      toplamPersonel = personelRes.length;
      aktifPersonel = 0;
      pasifPersonel = 0;
      
      final maaslar = <double>[];
      double toplamKidemYil = 0;
      int kidemSayisi = 0;
      double toplamYasToplam = 0;
      int yasSayisi = 0;
      departmanIstatistikleri.clear();
      
      for (final personel in personelRes) {
        // Durum kontrolü
        final durum = personel['durum']?.toString() ?? 'aktif';
        if (durum == 'aktif' || durum.isEmpty) {
          aktifPersonel++;
        } else {
          pasifPersonel++;
        }
        
        // Maaş hesaplamaları
        final netMaas = double.tryParse(personel['net_maas']?.toString() ?? '0') ?? 0;
        final brutMaas = double.tryParse(personel['brut_maas']?.toString() ?? '0') ?? 0;
        // Eğer brut_maas yoksa net_maas'ı kullan
        final hesaplanacakMaas = brutMaas > 0 ? brutMaas : netMaas;
        if (netMaas > 0) {
          maaslar.add(netMaas);
        }
        toplamMaasBedeli += hesaplanacakMaas;
        
        // Kıdem hesaplaması
        final iseBaslangic = DateTime.tryParse(personel['ise_baslangic']?.toString() ?? '');
        if (iseBaslangic != null) {
          final kidemGun = DateTime.now().difference(iseBaslangic).inDays;
          toplamKidemYil += kidemGun / 365.0;
          kidemSayisi++;
        }
        
        // Yaş hesaplaması (dogum_tarihi varsa)
        final dogumTarihi = DateTime.tryParse(personel['dogum_tarihi']?.toString() ?? '');
        if (dogumTarihi != null) {
          final yas = DateTime.now().difference(dogumTarihi).inDays / 365.0;
          toplamYasToplam += yas;
          yasSayisi++;
        }
        
        // Departman bazlı istatistikler
        final departman = personel['departman']?.toString() ?? 
                         personel['pozisyon']?.toString() ?? 'Genel';
        if (!departmanIstatistikleri.containsKey(departman)) {
          departmanIstatistikleri[departman] = {
            'sayi': 0,
            'toplamMaas': 0.0,
            'toplamKidem': 0.0,
            'aktif': 0,
            'pasif': 0,
          };
        }
        departmanIstatistikleri[departman]!['sayi'] = 
            (departmanIstatistikleri[departman]!['sayi'] as int) + 1;
        departmanIstatistikleri[departman]!['toplamMaas'] = 
            (departmanIstatistikleri[departman]!['toplamMaas'] as double) + hesaplanacakMaas;
        if (iseBaslangic != null) {
          final kidemYil = DateTime.now().difference(iseBaslangic).inDays / 365.0;
          departmanIstatistikleri[departman]!['toplamKidem'] = 
              (departmanIstatistikleri[departman]!['toplamKidem'] as double) + kidemYil;
        }
        if (durum == 'aktif' || durum.isEmpty) {
          departmanIstatistikleri[departman]!['aktif'] = 
              (departmanIstatistikleri[departman]!['aktif'] as int) + 1;
        } else {
          departmanIstatistikleri[departman]!['pasif'] = 
              (departmanIstatistikleri[departman]!['pasif'] as int) + 1;
        }
      }
      
      // Ortalama hesaplamaları
      if (kidemSayisi > 0) {
        ortalamaKidem = toplamKidemYil / kidemSayisi;
      }
      if (yasSayisi > 0) {
        ortalamaYas = toplamYasToplam / yasSayisi;
      }
      
      // Maaş istatistikleri
      if (maaslar.isNotEmpty) {
        maaslar.sort();
        enDusukMaas = maaslar.first;
        enYuksekMaas = maaslar.last;
        ortalamaNetMaas = maaslar.reduce((a, b) => a + b) / maaslar.length;
        medyanMaas = maaslar.length % 2 == 0
            ? (maaslar[maaslar.length ~/ 2 - 1] + maaslar[maaslar.length ~/ 2]) / 2
            : maaslar[maaslar.length ~/ 2];
        
        // Maaş dilimleri
        maasDilimleri.clear();
        maasDilimleri['0-20K'] = maaslar.where((m) => m < 20000).length;
        maasDilimleri['20K-30K'] = maaslar.where((m) => m >= 20000 && m < 30000).length;
        maasDilimleri['30K-40K'] = maaslar.where((m) => m >= 30000 && m < 40000).length;
        maasDilimleri['40K-50K'] = maaslar.where((m) => m >= 40000 && m < 50000).length;
        maasDilimleri['50K+'] = maaslar.where((m) => m >= 50000).length;
      }
      
      // 2. İZİN VERİLERİ
      await _loadIzinVerileri(client, personelRes);
      
      // 3. MESAİ VERİLERİ
      await _loadMesaiVerileri(client, personelRes);
      
      // 4. PERFORMANS VERİLERİ
      await _loadPerformansVerileri(client, personelRes);
      
      // 5. TREND VERİLERİ
      await _loadTrendVerileri(client);
      
    } catch (e) {
      debugPrint('Analiz verisi yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        hata = 'Veriler yüklenirken bir hata oluştu: ${e.toString()}';
      });
    }
    
    setState(() => yukleniyor = false);
  }
  
  Future<void> _loadIzinVerileri(SupabaseClient client, List<dynamic> personelRes) async {
    try {
      // Tarih aralığını rapor tipine göre belirle
      DateTime baslangicTarih;
      DateTime bitisTarih;
      final now = DateTime.now();
      
      if (raporTipi == 'monthly') {
        baslangicTarih = DateTime(seciliYil, seciliAy, 1);
        bitisTarih = DateTime(seciliYil, seciliAy + 1, 0);
      } else if (raporTipi == 'yearly') {
        baslangicTarih = DateTime(seciliYil, 1, 1);
        bitisTarih = DateTime(seciliYil, 12, 31);
      } else {
        // Tümü - son 12 ay
        baslangicTarih = DateTime(now.year - 1, now.month, 1);
        bitisTarih = now;
      }
      
      final izinRes = await client
          .from(DbTables.izinler)
          .select('user_id, gun_sayisi, onay_durumu')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('baslama_tarihi', baslangicTarih.toIso8601String().split('T')[0])
          .lte('baslama_tarihi', bitisTarih.toIso8601String().split('T')[0])
          .eq('onay_durumu', 'onaylandi');
      
      // Personel başına izin kullanımı
      final personelIzinMap = <String, int>{};
      for (final izin in izinRes) {
        final personelId = izin['user_id']?.toString() ?? '';
        final gunSayisi = izin['gun_sayisi'] as int? ?? 0;
        personelIzinMap[personelId] = (personelIzinMap[personelId] ?? 0) + gunSayisi;
      }
      
      toplamKullanilanIzin = personelIzinMap.values.fold(0, (a, b) => a + b);
      
      // Yıllık izin hakları toplamı
      toplamKalanIzin = 0;
      for (final personel in personelRes) {
        final yillikIzin = int.tryParse(personel['yillik_izin_hakki']?.toString() ?? '14') ?? 14;
        toplamKalanIzin += yillikIzin;
      }
      toplamKalanIzin = toplamKalanIzin - toplamKullanilanIzin;
      if (toplamKalanIzin < 0) toplamKalanIzin = 0;
      
      // Ortalama izin kullanım oranı
      if (personelRes.isNotEmpty) {
        final toplamHak = personelRes.length * 14; // Ortalama 14 gün varsayalım
        ortalamaIzinKullanimOrani = (toplamKullanilanIzin / toplamHak) * 100;
        if (ortalamaIzinKullanimOrani > 100) ortalamaIzinKullanimOrani = 100;
      }
      
      // En çok izin kullananlar (top 5)
      enCokIzinKullananlar.clear();
      final sortedIzin = personelIzinMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (var i = 0; i < sortedIzin.length && i < 5; i++) {
        final personelId = sortedIzin[i].key;
        final personel = personelRes.firstWhere(
          (p) => p['user_id']?.toString() == personelId,
          orElse: () => null,
        );
        if (personel != null) {
          enCokIzinKullananlar.add({
            'ad': '${personel['ad'] ?? ''} ${personel['soyad'] ?? ''}'.trim(),
            'gunSayisi': sortedIzin[i].value,
          });
        }
      }
    } catch (e) {
      debugPrint('İzin verileri yüklenemedi: $e');
    }
  }
  
  Future<void> _loadMesaiVerileri(SupabaseClient client, List<dynamic> personelRes) async {
    try {
      // Tarih aralığını rapor tipine göre belirle
      DateTime baslangicTarih;
      DateTime bitisTarih;
      final now = DateTime.now();
      
      if (raporTipi == 'monthly') {
        baslangicTarih = DateTime(seciliYil, seciliAy, 1);
        bitisTarih = DateTime(seciliYil, seciliAy + 1, 0);
      } else if (raporTipi == 'yearly') {
        baslangicTarih = DateTime(seciliYil, 1, 1);
        bitisTarih = DateTime(seciliYil, 12, 31);
      } else {
        // Tümü - son 12 ay
        baslangicTarih = DateTime(now.year - 1, now.month, 1);
        bitisTarih = now;
      }
      
      final mesaiRes = await client
          .from(DbTables.mesai)
          .select('user_id, saat, onay_durumu')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('tarih', baslangicTarih.toIso8601String().split('T')[0])
          .lte('tarih', bitisTarih.toIso8601String().split('T')[0])
          .eq('onay_durumu', 'onaylandi');
      
      // Personel başına mesai
      final personelMesaiMap = <String, double>{};
      toplamMesaiSaati = 0;
      
      for (final mesai in mesaiRes) {
        final personelId = mesai['user_id']?.toString() ?? '';
        final saatSayisi = (mesai['saat'] as num? ?? 0).toDouble();
        personelMesaiMap[personelId] = (personelMesaiMap[personelId] ?? 0) + saatSayisi;
        toplamMesaiSaati += saatSayisi;
      }
      
      // Ortalama mesai
      if (personelRes.isNotEmpty) {
        ortalamaMesaiSaati = toplamMesaiSaati / personelRes.length;
      }
      
      // En çok mesai yapanlar (top 5)
      enCokMesaiYapanlar.clear();
      final sortedMesai = personelMesaiMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (var i = 0; i < sortedMesai.length && i < 5; i++) {
        final personelId = sortedMesai[i].key;
        final personel = personelRes.firstWhere(
          (p) => p['user_id']?.toString() == personelId,
          orElse: () => null,
        );
        if (personel != null) {
          enCokMesaiYapanlar.add({
            'ad': '${personel['ad'] ?? ''} ${personel['soyad'] ?? ''}'.trim(),
            'saat': sortedMesai[i].value,
          });
        }
      }
    } catch (e) {
      debugPrint('Mesai verileri yüklenemedi: $e');
    }
  }
  
  Future<void> _loadPerformansVerileri(SupabaseClient client, List<dynamic> personelRes) async {
    try {
      final now = DateTime.now();
      personelPerformans.clear();
      
      for (final personel in personelRes) {
        final personelId = personel['user_id']?.toString() ?? '';
        if (personelId.isEmpty) continue;
        
        // Puantaj verisi
        int calismaGunu = 0;
        int devamsizlik = 0;
        double fazlaMesai = 0;
        
        try {
          final puantajRes = await client
              .from(DbTables.puantaj)
              .select('gun, devamsizlik, fazla_mesai')
              .eq('user_id', personelId)
              .eq('yil', now.year);
          
          for (final p in puantajRes) {
            calismaGunu += (p['gun'] as int? ?? 0);
            devamsizlik += (p['devamsizlik'] as int? ?? 0);
            fazlaMesai += (p['fazla_mesai'] as num? ?? 0).toDouble();
          }
        } catch (e) {
          // Puantaj verisi yoksa devam et
        }
        
        // Performans puanı hesapla (basit formül)
        // - Devamsızlık azaltır
        // - Fazla mesai artırır (aşırı değilse)
        double performansPuani = 70; // Base puan
        
        // Devamsızlık etkisi (her gün -3 puan)
        performansPuani -= devamsizlik * 3;
        
        // Fazla mesai etkisi (aylık ortalamaya göre)
        final aylikFazlaMesai = fazlaMesai / 12;
        if (aylikFazlaMesai > 0 && aylikFazlaMesai <= 20) {
          performansPuani += aylikFazlaMesai * 0.5; // Makul mesai bonus
        } else if (aylikFazlaMesai > 20) {
          performansPuani += 10; // Max bonus
        }
        
        // Kıdem bonusu
        final iseBaslangic = DateTime.tryParse(personel['ise_baslangic']?.toString() ?? '');
        if (iseBaslangic != null) {
          final kidemYil = DateTime.now().difference(iseBaslangic).inDays / 365.0;
          performansPuani += kidemYil * 2; // Her yıl için +2 puan
        }
        
        // Sınırla
        if (performansPuani > 100) performansPuani = 100;
        if (performansPuani < 0) performansPuani = 0;
        
        String performansDurumu;
        Color performansRenk;
        if (performansPuani >= 80) {
          performansDurumu = 'Yüksek';
          performansRenk = Colors.green;
        } else if (performansPuani >= 60) {
          performansDurumu = 'Orta';
          performansRenk = Colors.orange;
        } else {
          performansDurumu = 'Düşük';
          performansRenk = Colors.red;
        }
        
        personelPerformans.add({
          'ad': '${personel['ad'] ?? ''} ${personel['soyad'] ?? ''}'.trim(),
          'departman': personel['departman'] ?? personel['pozisyon'] ?? 'Genel',
          'puan': performansPuani,
          'durum': performansDurumu,
          'renk': performansRenk,
          'calismaGunu': calismaGunu,
          'devamsizlik': devamsizlik,
          'fazlaMesai': fazlaMesai,
        });
      }
      
      // Puana göre sırala
      personelPerformans.sort((a, b) => (b['puan'] as double).compareTo(a['puan'] as double));
      
    } catch (e) {
      debugPrint('Performans verileri yüklenemedi: $e');
    }
  }
  
  Future<void> _loadTrendVerileri(SupabaseClient client) async {
    try {
      // Son 12 aylık personel sayısı trendi (işe başlayanlara göre)
      aylikPersonelSayisi.clear();
      aylikMaasTrendi.clear();
      
      for (int i = 11; i >= 0; i--) {
        final tarih = DateTime.now().subtract(Duration(days: i * 30));
        final aySonu = DateTime(tarih.year, tarih.month + 1, 0);
        
        // O ay sonuna kadar işe başlamış personeller
        final personelRes = await client
            .from(DbTables.personel)
            .select('id, brut_maas, net_maas')
            .eq('firma_id', TenantManager.instance.requireFirmaId)
            .lte('ise_baslangic', aySonu.toIso8601String().split('T')[0]);
        
        double toplamMaas = 0;
        for (final p in personelRes) {
          final brutMaas = double.tryParse(p['brut_maas']?.toString() ?? '0') ?? 0;
          final netMaas = double.tryParse(p['net_maas']?.toString() ?? '0') ?? 0;
          // Eğer brut_maas yoksa net_maas'ı kullan
          toplamMaas += brutMaas > 0 ? brutMaas : netMaas;
        }
        
        aylikPersonelSayisi.add({
          'ay': '${tarih.month}/${tarih.year % 100}',
          'sayi': personelRes.length,
        });
        
        aylikMaasTrendi.add({
          'ay': '${tarih.month}/${tarih.year % 100}',
          'tutar': toplamMaas,
        });
      }
    } catch (e) {
      debugPrint('Trend verileri yüklenemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Analiz & Raporlama', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalizData,
            tooltip: 'Yenile',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Dışa Aktar',
            onSelected: _exportData,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv_ozet', child: Text('Özet Rapor (CSV)')),
              const PopupMenuItem(value: 'csv_personel', child: Text('Personel Listesi (CSV)')),
              const PopupMenuItem(value: 'csv_performans', child: Text('Performans Raporu (CSV)')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Genel'),
            Tab(icon: Icon(Icons.business), text: 'Departman'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Maaş'),
            Tab(icon: Icon(Icons.beach_access), text: 'İzin & Mesai'),
            Tab(icon: Icon(Icons.trending_up), text: 'Performans'),
          ],
        ),
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : hata != null
              ? _buildHataWidget()
              : Column(
                  children: [
                    // Dönem filtresi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        border: Border(bottom: BorderSide(color: Colors.indigo.shade200)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt, color: Colors.indigo),
                          const SizedBox(width: 12),
                          const Text('Rapor Tipi:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Tümü'),
                            selected: raporTipi == 'all',
                            selectedColor: Colors.indigo.shade200,
                            onSelected: (v) {
                              setState(() => raporTipi = 'all');
                              _loadAnalizData();
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Aylık'),
                            selected: raporTipi == 'monthly',
                            selectedColor: Colors.indigo.shade200,
                            onSelected: (v) {
                              setState(() => raporTipi = 'monthly');
                              _loadAnalizData();
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Yıllık'),
                            selected: raporTipi == 'yearly',
                            selectedColor: Colors.indigo.shade200,
                            onSelected: (v) {
                              setState(() => raporTipi = 'yearly');
                              _loadAnalizData();
                            },
                          ),
                          const SizedBox(width: 16),
                          if (raporTipi == 'monthly' || raporTipi == 'yearly')
                            DropdownButton<int>(
                              value: seciliYil,
                              items: List.generate(5, (i) => DateTime.now().year - i)
                                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                  .toList(),
                              onChanged: (v) {
                                setState(() => seciliYil = v!);
                                _loadAnalizData();
                              },
                            ),
                          if (raporTipi == 'monthly')
                            const SizedBox(width: 8),
                          if (raporTipi == 'monthly')
                            DropdownButton<int>(
                              value: seciliAy,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Ocak')),
                                DropdownMenuItem(value: 2, child: Text('Şubat')),
                                DropdownMenuItem(value: 3, child: Text('Mart')),
                                DropdownMenuItem(value: 4, child: Text('Nisan')),
                                DropdownMenuItem(value: 5, child: Text('Mayıs')),
                                DropdownMenuItem(value: 6, child: Text('Haziran')),
                                DropdownMenuItem(value: 7, child: Text('Temmuz')),
                                DropdownMenuItem(value: 8, child: Text('Ağustos')),
                                DropdownMenuItem(value: 9, child: Text('Eylül')),
                                DropdownMenuItem(value: 10, child: Text('Ekim')),
                                DropdownMenuItem(value: 11, child: Text('Kasım')),
                                DropdownMenuItem(value: 12, child: Text('Aralık')),
                              ],
                              onChanged: (v) {
                                setState(() => seciliAy = v!);
                                _loadAnalizData();
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGenelTab(),
                          _buildDepartmanTab(),
                          _buildMaasTab(),
                          _buildIzinMesaiTab(),
                          _buildPerformansTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
}
