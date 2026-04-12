// ignore_for_file: invalid_use_of_protected_member
part of 'personel_arsiv_page.dart';

/// Personel arsiv - veri yuklem, hesaplama ve widget builder metotlari
extension _LogicExt on _PersonelArsivPageState {
  void _resetData() {
    toplamMaas = 0;
    toplamAvans = 0;
    toplamPrim = 0;
    toplamYol = 0;
    toplamYemek = 0;
    toplamNet = 0;
    toplamKesinti = 0;
    toplamMesaiSaati = 0;
    normalCalismaGunu = 0;
    izinGunu = 0;
    raporGunu = 0;
    toplamCalismaGunu = 0;
    performansPuani = 0;
    performansDurumu = 'Orta';
  }

  Future<void> _getArsiv() async {
    if (seciliDonem == null) {
      // Dönem seçili değilse verileri sıfırla
      setState(() {
        yukleniyor = false;
        _resetData();
      });
      return;
    }
    
    setState(() => yukleniyor = true);
    
    try {
      final client = Supabase.instance.client;
      
      debugPrint('=== ARŞİV VERİ YÜKLEME ===');
      debugPrint('personelId: ${widget.personelId}');
      debugPrint('seciliDonem: $seciliDonem');
      
      // Bordro verilerini çek - bordro tablosunda personel_id kullanılıyor
      final bordroResponse = await client
          .from(DbTables.bordro)
          .select()
          .eq('personel_id', widget.personelId)
          .eq('donem', seciliDonem!);
      
      debugPrint('Bordro sayısı: ${bordroResponse.length}');
      
      if (bordroResponse.isNotEmpty) {
        final bordro = bordroResponse.first;
        debugPrint('Bordro verisi: $bordro');
        toplamMaas = (bordro['brut_maas'] as num? ?? 0).toDouble();
        toplamNet = (bordro['net_maas'] as num? ?? 0).toDouble();
        toplamKesinti = (bordro['sgk_iscilik'] as num? ?? 0).toDouble() + 
                       (bordro['gelir_vergisi'] as num? ?? 0).toDouble() + 
                       (bordro['damga_vergisi'] as num? ?? 0).toDouble();
        toplamPrim = (bordro['ek_odenek'] as num? ?? 0).toDouble();
        normalCalismaGunu = bordro['normal_gun'] as int? ?? 22;
        
        // Yol ve yemek ücretlerini bordrodan al
        toplamYol = (bordro['yol_ucreti'] as num? ?? 0).toDouble();
        toplamYemek = (bordro['yemek_ucreti'] as num? ?? 0).toDouble();
      } else {
        debugPrint('Bordro bulunamadı, personel tablosundan veri çekiliyor...');
        // Eğer bordro yoksa, personel tablosundan temel maaş bilgisini al
        final personelResponse = await client
            .from(DbTables.personel)
            .select('brut_maas, net_maas, yol_ucreti, yemek_ucreti')
            .eq('user_id', widget.personelId)
            .maybeSingle();
        
        debugPrint('Personel maaş verisi: $personelResponse');
        
        if (personelResponse != null) {
          // Önce net_maas'ı dene, yoksa brut_maas'ı kullan
          final netMaasVal = personelResponse['net_maas'];
          final brutMaasVal = personelResponse['brut_maas'];
          
          toplamNet = double.tryParse(netMaasVal?.toString() ?? '0') ?? 0;
          toplamMaas = double.tryParse(brutMaasVal?.toString() ?? '0') ?? 0;
          
          // Eğer brut_maas null ise net_maas'ı kullan
          if (toplamMaas == 0 && toplamNet > 0) {
            toplamMaas = toplamNet * 1.35; // Tahmini brüt (net'in ~1.35 katı)
          }
          
          debugPrint('toplamMaas: $toplamMaas, toplamNet: $toplamNet');
          
          normalCalismaGunu = 22; // Varsayılan çalışma günü
          
          // Aylık yol ve yemek ücreti hesapla
          final gunlukYol = double.tryParse(personelResponse['yol_ucreti']?.toString() ?? '0') ?? 0;
          final gunlukYemek = double.tryParse(personelResponse['yemek_ucreti']?.toString() ?? '0') ?? 0;
          toplamYol = gunlukYol * normalCalismaGunu;
          toplamYemek = gunlukYemek * normalCalismaGunu;
          
          // Bordro yoksa kesinti hesapla (yaklaşık)
          toplamKesinti = toplamMaas > 0 ? toplamMaas * 0.20 : 0; // %20 kesinti tahmini
        }
      }
      
      // Ödeme verilerini çek - gerçek tutarlar
      debugPrint('Ödeme sorgusu: user_id=${widget.personelId}, tarih>=${seciliDonem!}-01, tarih<${_getNextMonthDate()}');
      final odemeResponse = await client
          .from(DbTables.odemeKayitlari)
          .select('tutar, odeme_turu, durum, aciklama, odeme_tarihi')
          .eq('user_id', widget.personelId)
          .gte('odeme_tarihi', '${seciliDonem!}-01')
          .lt('odeme_tarihi', _getNextMonthDate());
      
      debugPrint('Ödeme sayısı: ${odemeResponse.length}');
      if (odemeResponse.isNotEmpty) {
        debugPrint('İlk ödeme: ${odemeResponse.first}');
      }
      
      toplamAvans = 0;
      double odemePrimi = 0;
      
      for (var odeme in odemeResponse) {
        final tutar = (odeme['tutar'] as num? ?? 0).toDouble();
        final tur = odeme['odeme_turu']?.toString() ?? '';
        final durum = odeme['durum']?.toString() ?? '';
        
        // Sadece onaylanan ödemeleri say
        if (durum == 'onaylandi') {
          switch (tur) {
            case 'avans':
              toplamAvans += tutar;
              break;
            case 'prim':
            case 'ikramiye':
            case 'bonus':
              odemePrimi += tutar;
              break;
            case 'mesai_ucreti':
              odemePrimi += tutar; // Mesai ödemesi prim olarak sayılabilir
              break;
          }
        }
      }
      
      // Ödeme kayıtlarındaki primleri de topla
      toplamPrim += odemePrimi;
      
      // İzin verilerini çek
      final izinResponse = await client
          .from(DbTables.izinler)
          .select()
          .eq('user_id', widget.personelId)
          .gte('baslama_tarihi', '${seciliDonem!}-01')
          .lt('baslama_tarihi', _getNextMonthDate());
      
      debugPrint('İzin sayısı: ${izinResponse.length}');
      
      izinGunu = 0;
      for (var izin in izinResponse) {
        debugPrint('İzin kaydı: $izin');
        final onayDurumu = izin['onay_durumu']?.toString() ?? '';
        // "onaylandi" veya "approved" kabul et
        if (onayDurumu == 'onaylandi' || onayDurumu == 'approved') {
          final gunSayisi = izin['gun_sayisi'] as int? ?? 0;
          izinGunu += gunSayisi;
        }
      }
      
      // Mesai verilerini çek
      debugPrint('Mesai sorgusu: user_id=${widget.personelId}, tarih>=${seciliDonem!}-01, tarih<${_getNextMonthDate()}');
      final mesaiResponse = await client
          .from(DbTables.mesai)
          .select('saat, onay_durumu, mesai_ucret, yemek_ucreti')
          .eq('user_id', widget.personelId)
          .gte('tarih', '${seciliDonem!}-01')
          .lt('tarih', _getNextMonthDate());
      
      debugPrint('Mesai sayısı: ${mesaiResponse.length}');
      if (mesaiResponse.isNotEmpty) {
        debugPrint('İlk mesai: ${mesaiResponse.first}');
      }
      
      toplamMesaiSaati = 0;
      double mesaiUcreti = 0;
      for (var mesai in mesaiResponse) {
        debugPrint('Mesai kaydı: $mesai');
        final onayDurumu = mesai['onay_durumu']?.toString() ?? '';
        // "onaylandi" veya "approved" kabul et, ya da beklemede olanları da say
        if (onayDurumu == 'onaylandi' || onayDurumu == 'approved' || onayDurumu == 'beklemede') {
          final saatSayisi = (mesai['saat'] as num? ?? 0).toDouble();
          toplamMesaiSaati += saatSayisi;
          
          // Mesai ücretini de prim olarak ekle (sadece onaylananlar)
          if (onayDurumu == 'onaylandi' || onayDurumu == 'approved') {
            final mesaiUcret = (mesai['mesai_ucret'] as num? ?? 0).toDouble();
            final yemekUcret = (mesai['yemek_ucreti'] as num? ?? 0).toDouble();
            mesaiUcreti += mesaiUcret + yemekUcret;
          }
        }
      }
      
      // Mesai ücretlerini prim toplamına ekle
      toplamPrim += mesaiUcreti;
      
      // Puantaj verilerini çek
      if (seciliDonem!.length >= 7) {
        final parts = seciliDonem!.split('-');
        final yil = int.tryParse(parts[0]) ?? DateTime.now().year;
        final ay = int.tryParse(parts[1]) ?? DateTime.now().month;
        
        // Puantaj tablosunda personel_id kullanılıyor
        final puantajResponse = await client
            .from(DbTables.puantaj)
            .select('gun, devamsizlik, fazla_mesai, eksik_gun')
            .eq('personel_id', widget.personelId)
            .eq('yil', yil)
            .eq('ay', ay);
        
        debugPrint('Puantaj sayısı: ${puantajResponse.length}');
        
        if (puantajResponse.isNotEmpty) {
          final puantaj = puantajResponse.first;
          toplamCalismaGunu = puantaj['gun'] as int? ?? normalCalismaGunu;
          raporGunu = puantaj['devamsizlik'] as int? ?? 0;
          final fazlaMesai = puantaj['fazla_mesai'] as num? ?? 0;
          toplamMesaiSaati += fazlaMesai.toDouble();
          
          // Eksik günleri de hesaba kat
          final eksikGun = puantaj['eksik_gun'] as int? ?? 0;
          toplamCalismaGunu = (toplamCalismaGunu - eksikGun).clamp(0, 31);
        } else {
          // Puantaj yoksa varsayılan değerler
          toplamCalismaGunu = normalCalismaGunu > 0 ? normalCalismaGunu : 22;
          raporGunu = 0;
        }
      }
      
      // Final hesaplamalar
      // Eğer net maaş hesaplanmamışsa, brüt maaş - kesintiler şeklinde hesapla
      if (toplamNet == 0 && toplamMaas > 0) {
        toplamNet = toplamMaas - toplamKesinti + toplamPrim + toplamYol + toplamYemek - toplamAvans;
      }
      
      // Performans hesaplama
      _hesaplaPerformans();
      
    } catch (e, stackTrace) {
      debugPrint('Arşiv veri yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    setState(() => yukleniyor = false);
  }
  
  String _getNextMonthDate() {
    if (seciliDonem == null) return '';
    final parts = seciliDonem!.split('-');
    if (parts.length != 2) return '';
    
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    
    if (month == 12) {
      return '${year + 1}-01-01';
    } else {
      return '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    }
  }
  
  void _hesaplaPerformans() {
    double puan = 70; // Başlangıç puanı
    
    // Çalışma günü performansı
    if (normalCalismaGunu >= 22) {
      puan += 10;
    }
    else if (normalCalismaGunu >= 20) {
      puan += 5;
    }
    else if (normalCalismaGunu < 15) {
      puan -= 15;
    }
    else {
      puan -= 10;
    }
    
    // İzin kullanımı
    if (izinGunu > 5) {
      puan -= 15;
    }
    else if (izinGunu > 2) {
      puan -= 5;
    }
    
    // Mesai performansı
    if (toplamMesaiSaati > 40) {
      puan += 15;
    }
    else if (toplamMesaiSaati > 20) {
      puan += 10;
    }
    else if (toplamMesaiSaati > 10) {
      puan += 5;
    }
    
    // Rapor günü
    if (raporGunu > 3) {
      puan -= 20;
    }
    else if (raporGunu > 1) {
      puan -= 10;
    }
    
    // Toplam çalışma günü bazında da değerlendirme
    final totalWorkDays = toplamCalismaGunu + izinGunu + raporGunu;
    if (totalWorkDays >= 22) puan += 5;
    
    performansPuani = puan.clamp(0, 100);
    
    if (performansPuani >= 90) {
      performansDurumu = 'Mükemmel';
    } else if (performansPuani >= 80) {
      performansDurumu = 'Çok İyi';
    } else if (performansPuani >= 70) {
      performansDurumu = 'İyi';
    } else if (performansPuani >= 60) {
      performansDurumu = 'Orta';
    } else {
      performansDurumu = 'Düşük';
    }
  }


  Widget _buildFinancialItem(String label, double tutar, {required bool isNegative}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            '${isNegative ? '-' : '+'}${tutar.toStringAsFixed(2)} TL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkSummaryCard(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Color _getPerformanceColor() {
    if (performansPuani >= 90) return Colors.green;
    if (performansPuani >= 80) return Colors.lightGreen;
    if (performansPuani >= 70) return Colors.orange;
    if (performansPuani >= 60) return Colors.deepOrange;
    return Colors.red;
  }
  
  String _getPerformanceMessage() {
    if (performansPuani >= 90) {
      return 'Tebrikler! Mükemmel bir performans sergiliyorsunuz. Böyle devam edin!';
    } else if (performansPuani >= 80) {
      return 'Çok iyi bir performans gösteriyorsunuz. Küçük iyileştirmelerle mükemmel olabilirsiniz.';
    } else if (performansPuani >= 70) {
      return 'İyi bir performans seviyesindesiniz. Mesai ve devam konularında gelişim gösterebilirsiniz.';
    } else if (performansPuani >= 60) {
      return 'Ortalama bir performans sergiliyorsunuz. Daha düzenli çalışarak performansınızı artırabilirsiniz.';
    } else {
      return 'Performansınızı artırmak için devam, mesai ve izin kullanımınızı gözden geçirmeniz önerilir.';
    }
  }

  Future<PersonelModel?> _getPersonel() async {
    debugPrint('=== _getPersonel ===');
    debugPrint('personelId: ${widget.personelId}');
    final servis = PersonelService();
    final result = await servis.getPersonelById(widget.personelId);
    if (result != null) {
      debugPrint('Personel bulundu: ${result.ad} ${result.soyad}');
      debugPrint('netMaas: ${result.netMaas}');
      debugPrint('yolUcreti: ${result.yolUcreti}');
      debugPrint('yemekUcreti: ${result.yemekUcreti}');
    } else {
      debugPrint('Personel BULUNAMADI!');
    }
    return result;
  }

  Future<double> _getAylikToplamMesaiUcreti() async {
    debugPrint('=== _getAylikToplamMesaiUcreti ===');
    if (seciliDonem == null) {
      debugPrint('seciliDonem null, 0 dönüyor');
      return 0;
    }
    
    final parts = seciliDonem!.split('-');
    if (parts.length != 2) return 0;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    
    debugPrint('Yıl: $year, Ay: $month');
    
    final mesailer = await MesaiService().getMesailerForPersonel(widget.personelId, donem: seciliDonem);
    debugPrint('Mesai sayısı: ${mesailer.length}');
    
    final personel = await _getPersonel();
    
    if (personel == null) return 0;
    
    final netMaas = double.tryParse(personel.netMaas) ?? 0;
    final gunlukSaat = double.tryParse(personel.gunlukCalismaSaati) ?? 0;
    final saatlikUcret = netMaas > 0 && gunlukSaat > 0 ? (netMaas / 30 / gunlukSaat) : 0;
    
    double toplamMesaiUcret = 0;
    
    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      // Sadece seçili dönem içindeki mesaileri hesapla
      if (m.tarih.month == month && m.tarih.year == year) {
        if (m.saat != null) {
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
          
          // Yemek ücreti mesai hesaplamasına dahil edilmiyor, ayrı olarak finansal özette toplanacak
          toplamMesaiUcret += hesaplananUcret;
        }
      }
    }
    
    return toplamMesaiUcret;
  }

  Future<double> _getAylikMesaiYemekUcreti() async {
    if (seciliDonem == null) return 0;
    
    final parts = seciliDonem!.split('-');
    if (parts.length != 2) return 0;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    
    final mesailer = await MesaiService().getMesailerForPersonel(widget.personelId, donem: seciliDonem);
    
    double toplamYemekUcreti = 0;
    
    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      // Sadece seçili dönem içindeki mesaileri hesapla
      if (m.tarih.month == month && m.tarih.year == year) {
        // Pazar ve Bayram mesaileri için yemek ücreti var
        if (m.mesaiTuru == 'Pazar' || m.mesaiTuru == 'Bayram') {
          toplamYemekUcreti += m.yemekUcreti ?? 0;
        }
      }
    }
    
    return toplamYemekUcreti;
  }

  Future<double> _getKesintiTutari() async {
    if (seciliDonem == null) return 0;
    
    final parts = seciliDonem!.split('-');
    if (parts.length != 2) return 0;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    
    final izinler = await IzinService().getIzinlerForPersonel(widget.personelId, donem: seciliDonem);
    final personel = await _getPersonel();
    
    if (personel == null) return 0;
    
    final maas = double.tryParse(personel.netMaas) ?? 0;
    const toplamGun = 30; // Standart ay
    final gunlukUcret = maas / toplamGun;
    double toplamKesinti = 0;
    
    for (final izin in izinler) {
      if (izin.onayDurumu != 'onaylandi') continue;
      // Sadece seçili dönem içindeki izinleri hesapla
      if (izin.baslangic.month == month && izin.baslangic.year == year) {
        if (izin.izinTuru == 'Raporlu') {
          // Raporlu günler için
          final raporluGun = izin.gunSayisi;
          if (raporluGun > 2) {
            final odemeGun = raporluGun - 2;
            // IzinModel'de toplamOdeme ve tedaviSekli yok, sadece günlük ücret ve açıklama ile devam et
            // Tedavi şekli açıklamada aranacak
            double oran = 2 / 3; // Varsayılan ayakta tedavi
            if ((izin.aciklama.toLowerCase().contains('yatarak'))) {
              oran = 1 / 2;
            }
            // Ödenmeyen kısım: (1 - oran)
            toplamKesinti += odemeGun * gunlukUcret * (1 - oran);
          }
        } else if (izin.izinTuru == 'Ücretsiz İzin') {
          toplamKesinti += gunlukUcret * izin.gunSayisi;
        }
        // Diğer izin türlerinde kesinti yok
      }
    }
    
    return toplamKesinti;
  }

  Future<double> _getAylikYolUcreti() async {
    debugPrint('=== _getAylikYolUcreti ===');
    final personel = await _getPersonel();
    if (personel == null) {
      debugPrint('Personel null, 0 döndürüyor');
      return 0;
    }
    // Personel tablosundaki yol ücreti aylık tutar olarak döndürülüyor
    // Eğer günlük ise çalışma günü ile çarpılmalı
    final yolUcreti = double.tryParse(personel.yolUcreti) ?? 0;
    debugPrint('yolUcreti: $yolUcreti');
    return yolUcreti;
  }

  Future<Map<String, double>> _getOzetBakiyeler() async {
    if (seciliDonem == null) return {};
    
    debugPrint('=== _getOzetBakiyeler ===');
    debugPrint('personelId: ${widget.personelId}');
    debugPrint('seciliDonem: $seciliDonem');
    
    try {
      // OdemeService kullan - tutarlılık için
      final servis = OdemeService();
      final ozet = await servis.getOnayliBakiyeOzet(widget.personelId, donem: seciliDonem);
      debugPrint('Özet bakiyeler: $ozet');
      return ozet;
    } catch (e) {
      debugPrint('_getOzetBakiyeler HATA: $e');
      return {};
    }
  }
}