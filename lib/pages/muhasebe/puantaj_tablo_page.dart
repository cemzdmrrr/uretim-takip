import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

class PuantajTabloPage extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  const PuantajTabloPage({super.key, this.personelId, this.personelAd});

  @override
  State<PuantajTabloPage> createState() => _PuantajTabloPageState();
}

class _PuantajTabloPageState extends State<PuantajTabloPage> {
  bool yukleniyor = true;
  String? seciliDonem; // Dönem seçici için
  List<Map<String, dynamic>> puantajList = [];

  @override
  void initState() {
    super.initState();
    debugPrint('PuantajTabloPage.initState: personelId=${widget.personelId}');
    _getPuantaj();
  }

  Future<void> _getPuantaj() async {
    setState(() => yukleniyor = true);
    if (widget.personelId == null) return;
    
    // Personel bilgisi
    final personel = await PersonelService().getPersonelById(widget.personelId!);
    final gunlukSaat = double.tryParse(personel?.gunlukCalismaSaati ?? '8') ?? 8;
    final ad = personel?.ad ?? '';
    final netMaas = double.tryParse(personel?.netMaas ?? '0') ?? 0;
    
    final now = DateTime.now();
    final ay = now.month;
    final yil = now.year;
    final daysInMonth = DateTime(yil, ay + 1, 0).day; // Ayın gerçek gün sayısı
    
    // İzinler
    final izinler = await IzinService().getIzinlerForPersonel(widget.personelId!, donem: seciliDonem);
    int izinliGun = 0;
    int devamsizlikGun = 0;
    int raporluGun = 0;
    
    for (final izin in izinler) {
      if (izin.onayDurumu != 'onaylandi') continue;
      // Sadece bu ay içindeki izinleri hesapla
      if (izin.baslangic.month == ay && izin.baslangic.year == yil) {
        if (izin.izinTuru == 'Yıllık İzin' || izin.izinTuru == 'Mazeret İzni') {
          izinliGun += izin.gunSayisi;
        } else if (izin.izinTuru == 'Raporlu') {
          raporluGun += izin.gunSayisi;
        } else if (izin.izinTuru == 'Ücretsiz İzin' || izin.izinTuru == 'Devamsızlık') {
          devamsizlikGun += izin.gunSayisi;
        }
      }
    }
    
    // Mesailer
    final mesailer = await MesaiService().getMesailerForPersonel(widget.personelId!, donem: seciliDonem);
    double toplamFazlaMesai = 0;
    double toplamMesaiUcret = 0;
    
    // Mesai ücreti hesaplamak için personel bilgilerine ihtiyaç var
    final saatlikUcret = netMaas > 0 && gunlukSaat > 0 ? (netMaas / 30 / gunlukSaat) : 0;
    
    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      // Sadece bu ay içindeki mesaileri hesapla
      if (m.tarih.month == ay && m.tarih.year == yil) {
        if (m.saat != null) {
          toplamFazlaMesai += m.saat!;
          
          // Mesai ücretini hesapla - türe göre farklı hesaplama yöntemleri
          double hesaplananUcret = 0;
          
          if (m.mesaiTuru == 'Pazar') {
            // Pazar mesaisi: Günlük net maaş x 2 (saat bazında değil, günlük sabit ücret)
            final gunlukNetMaas = netMaas / 30;
            hesaplananUcret = gunlukNetMaas * 2.0;
          } else if (m.mesaiTuru == 'Bayram') {
            // Bayram mesaisi: Saatlik ücret x database'den gelen çarpan x saat
            final carpan = m.carpan ?? 1.5;
            hesaplananUcret = saatlikUcret * carpan * m.saat!;
          } else if (m.mesaiTuru == 'Saatlik') {
            // Saatlik mesai: Saatlik ücret x 1.5 x saat
            hesaplananUcret = saatlikUcret * 1.5 * m.saat!;
          }
          
          final yemekUcreti = (m.mesaiTuru == 'Pazar' || m.mesaiTuru == 'Bayram') ? (m.yemekUcreti ?? 0) : 0;
          toplamMesaiUcret += hesaplananUcret + yemekUcreti;
        }
      }
    }
    
    toplamFazlaMesai = double.parse(toplamFazlaMesai.toStringAsFixed(2));
    toplamMesaiUcret = double.parse(toplamMesaiUcret.toStringAsFixed(2));
    
    // Çalışılan gün hesaplama
    int calisilanGun = daysInMonth - izinliGun - devamsizlikGun - raporluGun;
    if (calisilanGun < 0) calisilanGun = 0;
    
    final int aylikCalismaSaati = (calisilanGun * gunlukSaat).round();
    
    // Günlük ücret hesaplama
    final gunlukUcret = netMaas / 30;
    final toplamUcretsizIzinKesinti = devamsizlikGun * gunlukUcret;
    
    // Tabloya ekle
    puantajList = [
      {
        'ad': ad,
        'calisilanGun': calisilanGun,
        'aylikCalismaSaati': aylikCalismaSaati,
        'fazlaMesai': toplamFazlaMesai,
        'mesaiUcreti': toplamMesaiUcret,
        'izinliGun': izinliGun,
        'raporluGun': raporluGun,
        'devamsizlikGun': devamsizlikGun,
        'ucretsizIzinKesinti': toplamUcretsizIzinKesinti,
        'gunlukUcret': gunlukUcret,
        'netMaas': netMaas,
      }
    ];
    setState(() => yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantaj Tablosu'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _getPuantaj,
          ),
        ],
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
                            _getPuantaj(); // Yeni döneme göre puantajı getir
                          },
                          showAll: true,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ana içerik
                Expanded(
                  child: puantajList.isEmpty
                      ? const Center(child: Text('Puantaj verisi bulunamadı.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Özet kartları
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildInfoCard(
                                    'Çalışılan Gün',
                                    '${puantajList.first['calisilanGun']} gün',
                                    Colors.blue,
                                    Icons.work,
                                  ),
                                  _buildInfoCard(
                                    'İzinli Gün',
                                    '${puantajList.first['izinliGun']} gün',
                                    Colors.green,
                                    Icons.beach_access,
                                  ),
                                  _buildInfoCard(
                                    'Raporlu Gün',
                                    '${puantajList.first['raporluGun']} gün',
                                    Colors.orange,
                                    Icons.local_hospital,
                                  ),
                                  _buildInfoCard(
                                    'Devamsızlık',
                                    '${puantajList.first['devamsizlikGun']} gün',
                                    Colors.red,
                                    Icons.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Mesai bilgileri
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mesai Bilgileri',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildDetailRow('Aylık Çalışma Saati', '${puantajList.first['aylikCalismaSaati']} saat'),
                                      _buildDetailRow('Fazla Mesai', '${puantajList.first['fazlaMesai']} saat'),
                                      _buildDetailRow('Mesai Ücreti', '${puantajList.first['mesaiUcreti'].toStringAsFixed(2)} TL'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                      
                      // Ücret bilgileri
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ücret Bilgileri',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow('Net Maaş', '${puantajList.first['netMaas'].toStringAsFixed(2)} TL'),
                              _buildDetailRow('Günlük Ücret', '${puantajList.first['gunlukUcret'].toStringAsFixed(2)} TL'),
                              _buildDetailRow('Ücretsiz İzin Kesinti', '${puantajList.first['ucretsizIzinKesinti'].toStringAsFixed(2)} TL', 
                                isNegative: puantajList.first['ucretsizIzinKesinti'] > 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      );
    
  }

  Widget _buildInfoCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
