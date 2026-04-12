import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/odeme_service.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'personel_arsiv_page_logic.dart';


class PersonelArsivPage extends StatefulWidget {
  final String personelId;
  final String personelAd;
  const PersonelArsivPage({super.key, required this.personelId, required this.personelAd});

  @override
  State<PersonelArsivPage> createState() => _PersonelArsivPageState();
}

class _PersonelArsivPageState extends State<PersonelArsivPage> {
  String? seciliDonem;
  bool yukleniyor = false;
  
  // Finansal veriler
  double toplamMaas = 0;
  double toplamAvans = 0;
  double toplamPrim = 0;
  double toplamYol = 0;
  double toplamYemek = 0;
  double toplamNet = 0;
  double toplamKesinti = 0;
  
  // Çalışma verileri
  double toplamMesaiSaati = 0;
  int normalCalismaGunu = 0;
  int izinGunu = 0;
  int raporGunu = 0;
  int toplamCalismaGunu = 0;
  
  // Performans verileri
  double performansPuani = 0;
  String performansDurumu = 'Orta';

  @override
  void initState() {
    super.initState();
    _initializeDonem();
  }

  Future<void> _initializeDonem() async {
    try {
      // Yeni dönem yapısını dene
      final client = Supabase.instance.client;
      final response = await client
          .from(DbTables.donemler)
          .select('donem_adi')
          .eq('durum', 'aktif')
          .maybeSingle();
      
      if (response != null && response['donem_adi'] != null) {
        seciliDonem = response['donem_adi'];
      } else {
        // Aktif dönem bulunamazsa null bırak (DonemSecici kendisi halleder)
        seciliDonem = null;
      }
    } catch (e) {
      debugPrint('Dönem başlatma hatası: $e');
      // Hata durumunda null bırak
      seciliDonem = null;
    }
    
    _getArsiv();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header ve Dönem Seçici
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.personelAd} - Dönemsel Özet',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Dönem: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        DonemSecici(
                          seciliDonem: seciliDonem,
                          onDonemChanged: (donem) {
                            setState(() {
                              seciliDonem = donem;
                            });
                            _getArsiv();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (yukleniyor)
              const LoadingWidget()
            else if (seciliDonem == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Lütfen bir dönem seçiniz.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else ...[
              // Veri durumu göstergesi
              if (toplamMaas == 0 && toplamAvans == 0 && toplamMesaiSaati == 0 && izinGunu == 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bu dönem için kayıt bulunamadı. Sadece temel personel bilgileri gösterilmektedir.',
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$seciliDonem dönemine ait veriler başarıyla yüklendi.',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Finansal Özet
              if (seciliDonem != null) Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FutureBuilder<List<dynamic>>(
                    future: Future.wait([
                      _getPersonel(),
                      _getAylikToplamMesaiUcreti(),
                      _getAylikMesaiYemekUcreti(),
                      _getAylikYolUcreti(),
                      _getKesintiTutari(),
                      _getOzetBakiyeler(),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget();
                      }
                      
                      // Hata kontrolü
                      if (snapshot.hasError) {
                        debugPrint('FutureBuilder HATA: ${snapshot.error}');
                        return Center(
                          child: Text('Veriler yüklenirken hata oluştu: ${snapshot.error}'),
                        );
                      }
                      
                      PersonelModel? personel;
                      double mesaiUcreti = 0;
                      double mesaiYemekUcreti = 0;
                      double yolUcreti = 0;
                      double kesintiTutari = 0;
                      Map<String, double> ozetBakiyeler = {};
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        final results = snapshot.data!;
                        debugPrint('=== FutureBuilder Sonuçları ===');
                        debugPrint('results.length: ${results.length}');
                        
                        personel = results[0] as PersonelModel?;
                        mesaiUcreti = results[1] as double;
                        mesaiYemekUcreti = results[2] as double;
                        yolUcreti = results[3] as double;
                        kesintiTutari = results[4] as double;
                        ozetBakiyeler = results[5] as Map<String, double>;
                        
                        debugPrint('personel: ${personel?.ad} ${personel?.soyad}');
                        debugPrint('mesaiUcreti: $mesaiUcreti');
                        debugPrint('mesaiYemekUcreti: $mesaiYemekUcreti');
                        debugPrint('yolUcreti: $yolUcreti');
                        debugPrint('kesintiTutari: $kesintiTutari');
                        debugPrint('ozetBakiyeler: $ozetBakiyeler');
                      } else {
                        debugPrint('FutureBuilder: snapshot.data NULL veya boş!');
                      }
                      
                      // Finansal hesaplamalar
                      final netMaas = personel != null ? double.tryParse(personel.netMaas) ?? 0.0 : 0.0;
                      final yemekUcreti = personel != null ? double.tryParse(personel.yemekUcreti) ?? 0.0 : 0.0;
                      final toplamYemekUcreti = yemekUcreti + mesaiYemekUcreti; // Personel yemek ücreti + mesai yemek ücretleri
                      final prim = (ozetBakiyeler['prim'] ?? 0).toDouble();
                      final ikramiye = (ozetBakiyeler['ikramiye'] ?? 0).toDouble();
                      final avans = (ozetBakiyeler['avans'] ?? 0).toDouble();
                      
                      debugPrint('=== Hesaplanan Değerler ===');
                      debugPrint('netMaas: $netMaas');
                      debugPrint('yemekUcreti: $yemekUcreti');
                      debugPrint('toplamYemekUcreti: $toplamYemekUcreti');
                      debugPrint('prim: $prim');
                      debugPrint('ikramiye: $ikramiye');
                      debugPrint('avans: $avans');
                      
                      // Toplam Kazanç = Net Maaş + Mesailer + Yemek Ücreti + Yol Ücreti + İkramiye + Prim - Toplam Kesinti - Avanslar
                      final toplamKazanc = netMaas + mesaiUcreti + toplamYemekUcreti + yolUcreti + ikramiye + prim - kesintiTutari - avans;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.summarize, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Finansal Özet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Gelirler Bölümü
                          const Text(
                            'Gelirler (+)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 8),
                          _buildFinancialItem('Net Maaş', netMaas, isNegative: false),
                          if (mesaiUcreti > 0) _buildFinancialItem('Mesailer', mesaiUcreti, isNegative: false),
                          if (toplamYemekUcreti > 0) _buildFinancialItem('Yemek Ücreti', toplamYemekUcreti, isNegative: false),
                          if (yolUcreti > 0) _buildFinancialItem('Yol Ücreti', yolUcreti, isNegative: false),
                          if (ikramiye > 0) _buildFinancialItem('İkramiye', ikramiye, isNegative: false),
                          _buildFinancialItem('Prim', prim, isNegative: false),
                          const SizedBox(height: 12),
                          // Kesintiler Bölümü
                          const Text(
                            'Kesintiler (-)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          _buildFinancialItem('Avanslar', avans, isNegative: true),
                          if (kesintiTutari > 0) _buildFinancialItem('Ücretsiz İzin', kesintiTutari, isNegative: true),
                          const SizedBox(height: 12),
                          const Divider(),
                          // Toplam Kazanç
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: toplamKazanc >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: toplamKazanc >= 0 ? Colors.green.shade200 : Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Toplam Kazanç:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                Text(
                                  '${toplamKazanc.toStringAsFixed(2)} TL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: toplamKazanc >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Çalışma Özeti
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.work, color: Colors.blue, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Çalışma Özeti',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildWorkSummaryCard(
                              'Çalışma Günü',
                              '$toplamCalismaGunu',
                              'gün',
                              Colors.blue,
                              Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWorkSummaryCard(
                              'Normal Çalışma',
                              '$normalCalismaGunu',
                              'gün',
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildWorkSummaryCard(
                              'İzin Günü',
                              '$izinGunu',
                              'gün',
                              Colors.orange,
                              Icons.beach_access,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildWorkSummaryCard(
                              'Rapor Günü',
                              '$raporGunu',
                              'gün',
                              Colors.red,
                              Icons.medical_services,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildWorkSummaryCard(
                        'Mesai Saati',
                        toplamMesaiSaati.toStringAsFixed(1),
                        'saat',
                        Colors.purple,
                        Icons.access_time,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Performans Değerlendirmesi
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Performans Değerlendirmesi',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getPerformanceColor().withValues(alpha: 0.1),
                              _getPerformanceColor().withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getPerformanceColor().withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Genel Performans:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getPerformanceColor(),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    performansDurumu,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: performansPuani / 100,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getPerformanceColor()),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${performansPuani.toStringAsFixed(0)}/100',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getPerformanceMessage(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
}