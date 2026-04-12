// ignore_for_file: invalid_use_of_protected_member
part of 'model_detay.dart';

/// Uretim durumu tab'i - uretim akis grafigi, asama detay ve atama islemleri
extension _UretimExt on _ModelDetayState {
  Widget _buildUretimDurumuTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Özet bilgiler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Toplam', '${currentModelData?['toplam_adet'] ?? 0}', Icons.inventory, Colors.blue),
                  _buildSummaryItem('Atanmış', '${_getTotalAtananAdet()}', Icons.assignment, Colors.orange),
                  _buildSummaryItem('Tamamlanan', '${_getTotalTamamlananAdet()}', Icons.check_circle, Colors.green),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Üretim Akış Grafiği
          _buildUretimAkisGrafigi(),
          
          const SizedBox(height: 16),
          
          _buildAsamaKarti('Örgü/Dokuma', orguUretimKayitlari, dokumaAtamalari, Icons.grain, 'orgu', Colors.brown),
          _buildAsamaKarti('Konfeksiyon', konfeksiyonUretimKayitlari, konfeksiyonAtamalari, Icons.content_cut, 'konfeksiyon', Colors.purple),
          _buildAsamaKarti('Nakış', nakisUretimKayitlari, nakisAtamalari, Icons.brush, 'nakis', Colors.pink),
          _buildAsamaKarti('Yıkama', yikamaUretimKayitlari, yikamaAtamalari, Icons.local_laundry_service, 'yikama', Colors.cyan),
          _buildAsamaKarti('İlik Düğme', ilikDugmeUretimKayitlari, ilikDugmeAtamalari, Icons.radio_button_unchecked, 'ilik_dugme', Colors.indigo),
          _buildAsamaKarti('Ütü', utuUretimKayitlari, utuAtamalari, Icons.iron, 'utu', Colors.red),
        ],
      ),
    );
  }
  
  /// Üretim akış grafiği - Modelin hangi aşamalardan geçtiğini gösterir
  Widget _buildUretimAkisGrafigi() {
    // Tüm aşamaların durumlarını hesapla
    final asamaDurumlari = _getAsamaDurumlari();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.teal),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Üretim Akış Durumu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAkisDetayDialog(asamaDurumlari),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Detay'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Yatay akış şeması
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildAkisAdimlari(asamaDurumlari),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Her aşamanın durumunu hesapla
  List<Map<String, dynamic>> _getAsamaDurumlari() {
    final asamalar = [
      {
        'ad': 'Dokuma',
        'kod': 'dokuma',
        'icon': Icons.grain,
        'renk': Colors.brown,
        'atamalar': dokumaAtamalari,
      },
      {
        'ad': 'Konfeksiyon',
        'kod': 'konfeksiyon',
        'icon': Icons.content_cut,
        'renk': Colors.purple,
        'atamalar': konfeksiyonAtamalari,
      },
      {
        'ad': 'Nakış',
        'kod': 'nakis',
        'icon': Icons.brush,
        'renk': Colors.pink,
        'atamalar': nakisAtamalari,
      },
      {
        'ad': 'Yıkama',
        'kod': 'yikama',
        'icon': Icons.local_laundry_service,
        'renk': Colors.cyan,
        'atamalar': yikamaAtamalari,
      },
      {
        'ad': 'İlik/Düğme',
        'kod': 'ilik_dugme',
        'icon': Icons.radio_button_unchecked,
        'renk': Colors.indigo,
        'atamalar': ilikDugmeAtamalari,
      },
      {
        'ad': 'Ütü',
        'kod': 'utu',
        'icon': Icons.iron,
        'renk': Colors.orange,
        'atamalar': utuAtamalari,
      },
      {
        'ad': 'Kalite Kontrol',
        'kod': 'kalite_kontrol',
        'icon': Icons.verified,
        'renk': Colors.teal,
        'atamalar': kaliteKontrolAtamalari,
      },
      {
        'ad': 'Paketleme',
        'kod': 'paketleme',
        'icon': Icons.inventory_2,
        'renk': Colors.green,
        'atamalar': paketlemeAtamalari,
      },
    ];
    
    return asamalar.map((asama) {
      final atamalar = asama['atamalar'] as List<dynamic>;
      String durum = 'bekliyor';
      int toplamAdet = 0;
      int tamamlananAdet = 0;
      DateTime? baslangicTarihi;
      DateTime? bitisTarihi;
      String? tedarikciAdi;
      bool tumAtamalarTamamlandi = true;
      bool enAzBirAtamaVar = false;
      bool enAzBirAtamaDevamEdiyor = false;
      
      for (var atama in atamalar) {
        enAzBirAtamaVar = true;
        final atamaAdet = (atama['adet'] ?? atama['talep_edilen_adet'] ?? atama['kontrol_edilecek_adet'] ?? 0) as int;
        final atamaTamamlanan = (atama['tamamlanan_adet'] ?? 0) as int;
        final atamaDurum = atama['durum']?.toString().toLowerCase() ?? '';
        
        toplamAdet += atamaAdet;
        tamamlananAdet += atamaTamamlanan;
        
        // Atama durumunu kontrol et
        if (atamaDurum != 'tamamlandi') {
          tumAtamalarTamamlandi = false;
        }
        if (atamaDurum == 'devam_ediyor' || atamaDurum == 'uretimde' || atamaDurum == 'baslatildi') {
          enAzBirAtamaDevamEdiyor = true;
        }
        
        // Başlangıç tarihini al
        if (atama['created_at'] != null || atama['atama_tarihi'] != null) {
          final tarihStr = atama['atama_tarihi'] ?? atama['created_at'];
          final createdAt = DateTime.tryParse(tarihStr.toString());
          if (createdAt != null && (baslangicTarihi == null || createdAt.isBefore(baslangicTarihi))) {
            baslangicTarihi = createdAt;
          }
        }
        
        // Bitiş tarihini al (tamamlanma tarihi)
        if (atamaDurum == 'tamamlandi') {
          final tarihStr = atama['tamamlama_tarihi'] ?? atama['updated_at'];
          if (tarihStr != null) {
            final updatedAt = DateTime.tryParse(tarihStr.toString());
            if (updatedAt != null && (bitisTarihi == null || updatedAt.isAfter(bitisTarihi))) {
              bitisTarihi = updatedAt;
            }
          }
        }
        
        // Tedarikçi adını al
        if (tedarikciAdi == null && atama['tedarikci_adi'] != null) {
          tedarikciAdi = atama['tedarikci_adi'].toString();
        }
      }
      
      // Durumu belirle - öncelikli olarak atama durumlarına bak
      if (!enAzBirAtamaVar) {
        durum = 'bekliyor';
      } else if (tumAtamalarTamamlandi && enAzBirAtamaVar) {
        durum = 'tamamlandi';
      } else if (enAzBirAtamaDevamEdiyor || tamamlananAdet > 0) {
        durum = 'devam_ediyor';
      } else {
        durum = 'atandi';
      }
      
      return {
        'ad': asama['ad'],
        'kod': asama['kod'],
        'icon': asama['icon'],
        'renk': asama['renk'],
        'durum': durum,
        'toplamAdet': toplamAdet,
        'tamamlananAdet': tamamlananAdet,
        'baslangicTarihi': baslangicTarihi,
        'bitisTarihi': bitisTarihi,
        'tedarikciAdi': tedarikciAdi,
        'atamalar': atamalar,
      };
    }).toList();
  }
  
  /// Akış adımlarını oluştur
  List<Widget> _buildAkisAdimlari(List<Map<String, dynamic>> asamaDurumlari) {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < asamaDurumlari.length; i++) {
      final asama = asamaDurumlari[i];
      final durum = asama['durum'] as String;
      
      // Durum rengini belirle
      Color durumRengi;
      IconData durumIkonu;
      switch (durum) {
        case 'tamamlandi':
          durumRengi = Colors.green;
          durumIkonu = Icons.check_circle;
          break;
        case 'devam_ediyor':
          durumRengi = Colors.orange;
          durumIkonu = Icons.autorenew;
          break;
        case 'atandi':
          durumRengi = Colors.blue;
          durumIkonu = Icons.assignment;
          break;
        default:
          durumRengi = Colors.grey;
          durumIkonu = Icons.schedule;
      }
      
      // Aşama kartı
      widgets.add(
        InkWell(
          onTap: () => _showAsamaDetayDialog(asama),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: durumRengi.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: durumRengi, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Icon(asama['icon'] as IconData, color: durumRengi, size: 32),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: durumRengi, width: 1),
                      ),
                      child: Icon(durumIkonu, color: durumRengi, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  asama['ad'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: durumRengi,
                  ),
                ),
                if (asama['toplamAdet'] as int > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${asama['tamamlananAdet']}/${asama['toplamAdet']}',
                    style: TextStyle(fontSize: 10, color: durumRengi),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      
      // Ok işareti (son aşama hariç)
      if (i < asamaDurumlari.length - 1) {
        final okRengi = (durum == 'tamamlandi') ? Colors.green : Colors.grey;
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              color: okRengi,
              size: 24,
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  /// Aşama detay dialog'unu göster
  void _showAsamaDetayDialog(Map<String, dynamic> asama) {
    final durum = asama['durum'] as String;
    final atamalar = asama['atamalar'] as List<dynamic>;
    
    Color durumRengi;
    String durumMetni;
    switch (durum) {
      case 'tamamlandi':
        durumRengi = Colors.green;
        durumMetni = 'Tamamlandı';
        break;
      case 'devam_ediyor':
        durumRengi = Colors.orange;
        durumMetni = 'Devam Ediyor';
        break;
      case 'atandi':
        durumRengi = Colors.blue;
        durumMetni = 'Atandı';
        break;
      default:
        durumRengi = Colors.grey;
        durumMetni = 'Bekliyor';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(asama['icon'] as IconData, color: asama['renk'] as Color),
            const SizedBox(width: 8),
            Text(asama['ad'] as String),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Durum bilgisi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: durumRengi.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: durumRengi),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: durumRengi),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Durum: $durumMetni',
                              style: TextStyle(fontWeight: FontWeight.bold, color: durumRengi),
                            ),
                            Text(
                              'Toplam: ${asama['toplamAdet']} adet, Tamamlanan: ${asama['tamamlananAdet']} adet',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tarih bilgileri
                if (asama['baslangicTarihi'] != null) ...[
                  const SizedBox(height: 16),
                  _buildDetayBilgiSatiri(
                    'Başlangıç Tarihi',
                    DateFormat('dd.MM.yyyy HH:mm').format(asama['baslangicTarihi'] as DateTime),
                    Icons.play_arrow,
                    Colors.blue,
                  ),
                ],
                
                if (asama['bitisTarihi'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetayBilgiSatiri(
                    'Bitiş Tarihi',
                    DateFormat('dd.MM.yyyy HH:mm').format(asama['bitisTarihi'] as DateTime),
                    Icons.stop,
                    Colors.green,
                  ),
                ],
                
                // Süre hesapla
                if (asama['baslangicTarihi'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetayBilgiSatiri(
                    'Geçen Süre',
                    utils.hesaplaSure(asama['baslangicTarihi'] as DateTime, asama['bitisTarihi'] as DateTime?),
                    Icons.timer,
                    Colors.purple,
                  ),
                ],
                
                // Tedarikçi bilgisi
                if (asama['tedarikciAdi'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetayBilgiSatiri(
                    'Tedarikçi',
                    asama['tedarikciAdi'] as String,
                    Icons.business,
                    Colors.teal,
                  ),
                ],
                
                // Atama listesi
                if (atamalar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Atama Geçmişi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...atamalar.map((atama) => _buildAtamaDetaySatiri(atama, asama['kod'] as String)).toList(),
                ],
                
                // Admin işlemleri
                if (kullaniciRolu == 'admin' && atamalar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Admin İşlemleri',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (durum == 'tamamlandi')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _yenidenBaslatDialog(asama);
                          },
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Yeniden Başlat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _tumAtamalariSilDialog(asama);
                        },
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Tüm Atamaları Sil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetayBilgiSatiri(String baslik, String deger, IconData icon, Color renk) {
    return Row(
      children: [
        Icon(icon, size: 18, color: renk),
        const SizedBox(width: 8),
        Text('$baslik: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(deger)),
      ],
    );
  }
  
  Widget _buildAtamaDetaySatiri(Map<String, dynamic> atama, String asamaKodu) {
    final durum = atama['durum']?.toString().toLowerCase() ?? 'bilinmiyor';
    final adet = atama['adet'] ?? atama['talep_edilen_adet'] ?? 0;
    final tamamlanan = atama['tamamlanan_adet'] ?? 0;
    final createdAt = atama['created_at'] != null 
        ? DateTime.tryParse(atama['created_at'].toString()) 
        : null;
    
    Color durumRengi;
    switch (durum) {
      case 'tamamlandi':
        durumRengi = Colors.green;
        break;
      case 'baslatildi':
      case 'uretimde':
        durumRengi = Colors.blue;
        break;
      case 'atandi':
        durumRengi = Colors.orange;
        break;
      default:
        durumRengi = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: durumRengi.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: durumRengi, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adet: $adet, Tamamlanan: $tamamlanan',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
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
            child: Text(
              utils.getStatusText(durum),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          // Admin işlemleri
          if (kullaniciRolu == 'admin') ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                Navigator.pop(context); // Dialog'u kapat
                if (value == 'durum_degistir') {
                  _tekAtamaDurumDegistirDialog(atama, asamaKodu);
                } else if (value == 'sil') {
                  _tekAtamaSilDialog(atama, asamaKodu);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'durum_degistir',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Durum Değiştir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sil',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  /// Tüm akış detay dialog'unu göster
  void _showAkisDetayDialog(List<Map<String, dynamic>> asamaDurumlari) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timeline, color: Colors.teal),
            SizedBox(width: 8),
            Text('Üretim Akış Detayları'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
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
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          backgroundColor: durumRengi.withAlpha(30),
                          child: Icon(asama['icon'] as IconData, color: asama['renk'] as Color),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: durumRengi, width: 1),
                          ),
                          child: Icon(durumIkonu, color: durumRengi, size: 12),
                        ),
                      ],
                    ),
                    title: Text(asama['ad'] as String),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(durumMetni, style: TextStyle(color: durumRengi, fontWeight: FontWeight.w500)),
                        if ((asama['toplamAdet'] as int) > 0)
                          Text(
                            '${asama['tamamlananAdet']}/${asama['toplamAdet']} adet',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (asama['baslangicTarihi'] != null)
                          Text(
                            'Başlangıç: ${DateFormat('dd.MM.yyyy').format(asama['baslangicTarihi'] as DateTime)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        if (asama['bitisTarihi'] != null)
                          Text(
                            'Bitiş: ${DateFormat('dd.MM.yyyy').format(asama['bitisTarihi'] as DateTime)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAsamaDetayDialog(asama);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showAsamaDetayDialog(asama);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildAsamaKarti(String baslik, List<dynamic> kayitlar, List<dynamic> atamaKayitlari, 
                         IconData icon, String asamaKey, Color color) {
    int toplamAdet = 0;
    int tamamlananAdet = 0;
    String durum = 'Bekliyor';
    
    // Atama durumlarını analiz et
    for (var atama in atamaKayitlari) {
      toplamAdet += (atama['adet'] ?? atama['talep_edilen_adet'] ?? 0) as int;
      tamamlananAdet += (atama['tamamlanan_adet'] ?? 0) as int;
    }
    
    if (atamaKayitlari.isEmpty) {
      durum = 'Atama Yok';
      color = Colors.grey;
    } else if (tamamlananAdet == toplamAdet && toplamAdet > 0) {
      durum = 'Tamamlandı';
      color = Colors.green;
    } else if (tamamlananAdet > 0) {
      durum = 'İşleniyor';
      color = Colors.orange;
    } else if (toplamAdet > 0) {
      durum = 'Atanmış';
      color = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baslik,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          durum,
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      utils.getDurumIkonu(durum),
                      color: color,
                      size: 20,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Adet bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Atanmış', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('$toplamAdet', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text('Tamamlanan', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('$tamamlananAdet', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Column(
                      children: [
                        Text('Kalan', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('${toplamAdet - tamamlananAdet}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Admin atama butonu
              if (kullaniciRolu == 'admin') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAtamaDialog(asamaKey),
                  icon: const Icon(Icons.add_task, size: 20),
                  label: const Text('Yeni Atama Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              
              // Atamalar listesi
              if (atamaKayitlari.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  kullaniciRolu == 'admin' ? 'Tüm Atamalar:' : 'Size Atanan İşler:',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: atamaKayitlari.length,
                  itemBuilder: (context, index) {
                    final atama = atamaKayitlari[index];
                    return _buildAtamaItem(atama, asamaKey);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtamaItem(Map<String, dynamic> atama, String asamaKey) {
    final durum = atama['durum']?.toLowerCase() ?? '';
    final adet = atama['adet'] ?? atama['talep_edilen_adet'] ?? 0;
    final tamamlanan = atama['tamamlanan_adet'] ?? 0;
    final createdAt = atama['created_at'];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: utils.getStatusColor(durum).withAlpha(20),
        border: Border(left: BorderSide(width: 3, color: utils.getStatusColor(durum))),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, size: 16, color: utils.getStatusColor(durum)),
                        const SizedBox(width: 8),
                        Text(
                          'Adet: $adet',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Tamamlanan: $tamamlanan',
                          style: TextStyle(
                            color: tamamlanan > 0 ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null)
                      Text(
                        'Atama: ${createdAt.toString().split('T')[0]}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: utils.getStatusColor(durum),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  utils.getStatusText(durum),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          // Aksiyon butonları
          if (_getUserActions(atama, asamaKey).isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _getUserActions(atama, asamaKey),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _getUserActions(Map<String, dynamic> atama, String asamaKey) {
    final List<Widget> butonlar = [];
    final durum = atama['durum']?.toLowerCase() ?? '';
    
    // Sadece kendi atamalarında işlem yapabilir (admin hariç)
    final user = supabase.auth.currentUser;
    if (user == null) return butonlar;
    
    final bool isOwnAssignment = atama['atanan_kullanici_id'] == user.id || kullaniciRolu == 'admin';
    if (!isOwnAssignment) return butonlar;
    
    // Kabul et butonu (atandı veya firma onay bekliyor durumunda)
    if (durum == 'atandi' || durum == 'firma_onay_bekliyor' || durum == '') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _atamaKabulEt(atama, asamaKey),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Kabul Et'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }
    
    // Üretime Başla butonu (onaylandı durumunda - admin için)
    if ((durum == 'onaylandi' || durum == 'kabul_edildi') && kullaniciRolu == 'admin') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _atamaUretimeAl(atama, asamaKey),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Üretime Başla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }
    
    // Tamamla butonu (üretimde durumunda)
    if (durum == 'baslatildi' || durum == 'uretimde' || durum == 'kismi_tamamlandi') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            onPressed: () => _showTamamlamaDialog(atama, asamaKey),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Tamamla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }
    
    // İptal Et butonu (admin için, tamamlanmamış tüm durumlar)
    if (kullaniciRolu == 'admin' && durum != 'tamamlandi' && durum != 'iptal') {
      butonlar.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton.icon(
            onPressed: () => _atamaIptalEt(atama, asamaKey),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('İptal Et'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      );
    }
    
    return butonlar;
  }

  Future<void> _atamaUretimeAl(Map<String, dynamic> atama, String asamaKey) async {
    try {
      final atamaId = atama['id'];
      final String tableName = utils.getTableNameForStage(asamaKey);
      
      await supabase
          .from(tableName)
          .update({
            'durum': 'uretimde',
            'uretim_baslangic_tarihi': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', atamaId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Atama üretime alındı'),
          backgroundColor: Colors.blue,
        ),
      );
      
      await _atamaKayitlariniGetir();
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }

  Future<void> _atamaIptalEt(Map<String, dynamic> atama, String asamaKey) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atamayı İptal Et'),
        content: const Text('Bu atamayı iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (onay != true) return;
    
    try {
      final atamaId = atama['id'];
      final String tableName = utils.getTableNameForStage(asamaKey);
      
      await supabase
          .from(tableName)
          .update({
            'durum': 'iptal',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', atamaId);
      
      if (!mounted) return;
      context.showErrorSnackBar('⛔ Atama iptal edildi');
      
      await _atamaKayitlariniGetir();
      
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Hata: $e');
    }
  }


}
