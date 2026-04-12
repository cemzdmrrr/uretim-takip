import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_package;
import 'dart:io';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/pages/stok/iplik_siparis_takip_page.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'iplik_stoklari_crud.dart';
part 'iplik_stoklari_detay.dart';
part 'iplik_stoklari_siparis.dart';

class IplikStoklariPage extends StatefulWidget {
  const IplikStoklariPage({super.key});

  @override
  State<IplikStoklariPage> createState() => _IplikStoklariPageState();
}

class _IplikStoklariPageState extends State<IplikStoklariPage> {
  final supabase = Supabase.instance.client;
  String? kullaniciRolu;
  
  // Stok ve hareket verileri
  List<Map<String, dynamic>> iplikStoklari = [];
  List<Map<String, dynamic>> filtreliStoklar = [];
  List<Map<String, dynamic>> iplikHareketleri = [];
  List<Map<String, dynamic>> tedarikciler = [];
  List<Map<String, dynamic>> iplikSiparisleri = [];
  
  // Yükleniyor durumu
  bool _yukleniyor = false;

  // Arama/filtreleme kontrolleri
  final stokAramaController = TextEditingController();

  int seciliMenu = 0; // 0: İplik Stokları, 1: İplik Hareketleri, 2: İplik Siparişi

  @override
  void initState() {
    super.initState();
    _yetkiGetir();
    _verileriYukle();
  }

  Future<void> _yetkiGetir() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final response = await supabase
          .from(DbTables.userRoles)
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      setState(() {
        kullaniciRolu = response?['role'] ?? 'kullanici';
      });
    }
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    
    try {
      final firmaId = TenantManager.instance.requireFirmaId;
      // İplik stokları - Basit sorgu ile (join olmadan)
      try {
        final stokVeri = await supabase
            .from(DbTables.iplikStoklari)
            .select('*')
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);
        
        setState(() {
          iplikStoklari = List<Map<String, dynamic>>.from(stokVeri);
          filtreliStoklar = iplikStoklari;
        });
        
        debugPrint('İplik stokları yüklendi: ${iplikStoklari.length} adet');
      } catch (e) {
        debugPrint('İplik stokları tablosu bulunamadı: $e');
        setState(() {
          iplikStoklari = [];
          filtreliStoklar = [];
        });
      }

      // İplik hareketleri - Join ile iplik bilgilerini de al
      try {
        final hareketVeri = await supabase
            .from(DbTables.iplikHareketleri)
            .select('''
              *,
              iplik_stoklari!inner(
                id,
                ad,
                renk,
                lot_no,
                birim
              )
            ''')
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);

        // Veriyi düzenle - iplik bilgilerini doğrudan kayıt seviyesine taşı
        final duzenlenmisHareketler = hareketVeri.map((hareket) {
          final iplikBilgisi = hareket[DbTables.iplikStoklari];
          return {
            ...hareket,
            'iplik': iplikBilgisi,
          };
        }).toList();

        setState(() {
          iplikHareketleri = List<Map<String, dynamic>>.from(duzenlenmisHareketler);
        });
        
        debugPrint('İplik hareketleri yüklendi: ${iplikHareketleri.length} adet');
      } catch (e) {
        debugPrint('İplik hareketleri join hatası, basit sorgu deneniyor: $e');
        // Join başarısız olursa basit sorgu ile dene
        try {
          final hareketVeri = await supabase
              .from(DbTables.iplikHareketleri)
              .select('*')
              .eq('firma_id', firmaId)
              .order('created_at', ascending: false);

          setState(() {
            iplikHareketleri = List<Map<String, dynamic>>.from(hareketVeri);
          });
          
          debugPrint('İplik hareketleri basit sorgu ile yüklendi: ${iplikHareketleri.length} adet');
        } catch (e2) {
          debugPrint('İplik hareketleri tablosu bulunamadı: $e2');
          setState(() {
            iplikHareketleri = [];
          });
        }
      }

      // Tedarikciler
      try {
        final tedarikciVeri = await supabase
            .from(DbTables.tedarikciler)
            .select('id, ad, sirket, telefon, tedarikci_turu, faaliyet, faaliyet_alani')
            .eq('firma_id', firmaId)
            .order('sirket');

        setState(() {
          tedarikciler = List<Map<String, dynamic>>.from(tedarikciVeri);
        });
        
        debugPrint('Tedarikciler yüklendi: ${tedarikciler.length} adet');
      } catch (e) {
        debugPrint('Tedarikciler tablosu bulunamadı: $e');
        setState(() {
          tedarikciler = [];
        });
      }

      // İplik siparişleri - Basit sorgu ile (join olmadan)
      try {
        final siparisVeri = await supabase
            .from(DbTables.iplikSiparisleri)
            .select('*')
            .eq('firma_id', firmaId)
            .order('created_at', ascending: false);

        setState(() {
          iplikSiparisleri = List<Map<String, dynamic>>.from(siparisVeri);
        });
        
        debugPrint('İplik siparişleri yüklendi: ${iplikSiparisleri.length} adet');
      } catch (e) {
        debugPrint('İplik siparişleri tablosu bulunamadı: $e');
        setState(() {
          iplikSiparisleri = [];
        });
      }

    } catch (e) {
      debugPrint('Genel veri yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veri yükleme hatası: Lütfen Supabase tablolarının oluşturulduğundan emin olun'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  void _stokFiltrele(String arama) {
    if (arama.isEmpty) {
      setState(() => filtreliStoklar = iplikStoklari);
      return;
    }

    final sonuc = iplikStoklari.where((stok) {
      final metin = '${stok['ad']} ${stok['renk']} ${stok['lot_no']}'.toLowerCase();
      return metin.contains(arama.toLowerCase());
    }).toList();

    setState(() => filtreliStoklar = sonuc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<int>(
              value: seciliMenu,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text('İplik Stokları')),
                DropdownMenuItem(value: 1, child: Text('İplik Hareketleri')),
                DropdownMenuItem(value: 2, child: Text('İplik Siparişi Oluştur')),
                DropdownMenuItem(value: 3, child: Text('Sipariş Takip Sistemi')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => seciliMenu = value);
              },
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (seciliMenu == 0) {
                  // İplik Stokları
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stokAramaController,
                                decoration: const InputDecoration(
                                  labelText: 'İplik Ara (ad, renk, lot no)',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: _stokFiltrele,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => exportToExcel(iplikStoklari, fileName: 'Iplik_Stoklari'),
                              icon: const Icon(Icons.file_download),
                              label: const Text('Excel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD2B48C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _yukleniyor
                          ? const LoadingWidget()
                          : filtreliStoklar.isEmpty
                            ? const Center(child: Text('Stok bulunamadı'))
                            : ListView.builder(
                                itemCount: filtreliStoklar.length,
                                itemBuilder: (context, index) {
                                  final stok = filtreliStoklar[index];
                                  final miktar = (stok['miktar'] as num?)?.toDouble() ?? 0.0;
                                  final kritikStok = miktar < 10;
                                  final tedarikciAdi = stok[DbTables.tedarikciler]?['sirket'] ?? stok[DbTables.tedarikciler]?['ad'] ?? 'Bilinmiyor';
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        "${stok['ad']} - ${stok['renk'] ?? 'Renk Yok'}",
                                        style: TextStyle(
                                          color: kritikStok ? Colors.red : null,
                                          fontWeight: kritikStok ? FontWeight.bold : null,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Lot: ${stok['lot_no'] ?? '-'}'),
                                          Text('Kalan: ${miktar.toStringAsFixed(2)} ${stok['birim'] ?? 'kg'}'),
                                          Text('Tedarikçi: $tedarikciAdi'),
                                          if (stok['birim_fiyat'] != null)
                                            Text('Birim Fiyat: ${_getParaBirimiSembolu(stok['para_birimi'])}${(stok['birim_fiyat'] as num).toStringAsFixed(2)}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (kritikStok)
                                            const Icon(Icons.warning, color: Colors.red, size: 20),
                                          IconButton(
                                            icon: const Icon(Icons.info_outline),
                                            color: Colors.blue,
                                            onPressed: () => _iplikDetayGoster(stok),
                                            tooltip: 'İplik Detayları',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.call_made),
                                            color: Colors.red,
                                            onPressed: () => _cikisModalGoster(stok),
                                            tooltip: 'Çıkış/Sarf Yap',
                                          ),
                                          if (kullaniciRolu == 'admin')
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              color: Colors.blue,
                                              onPressed: () => _stokDuzenle(stok),
                                              tooltip: 'Düzenle',
                                            ),
                                          if (kullaniciRolu == 'admin')
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              onPressed: () => _stokSil(stok),
                                              tooltip: 'Sil',
                                            ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                } else if (seciliMenu == 1) {
                  // İplik Hareketleri
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _verileriYukle,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Yenile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD2B48C),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => exportToExcel(iplikHareketleri, fileName: 'Iplik_Hareketleri'),
                                icon: const Icon(Icons.file_download),
                                label: const Text('Excel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD2B48C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _yukleniyor
                          ? const LoadingWidget()
                          : iplikHareketleri.isEmpty
                            ? const Center(child: Text('Hareket kaydı bulunamadı'))
                            : ListView.builder(
                                itemCount: iplikHareketleri.length,
                                itemBuilder: (context, index) {
                                  final kayit = iplikHareketleri[index];
                                  final iplik = kayit['iplik'] ?? {};
                                  final model = kayit['model'];
                                  final tarih = DateTime.tryParse(kayit['created_at'] ?? '');
                                  
                                  // Eğer iplik bilgisi yoksa iplik_id ile ara
                                  String iplikAdi = iplik['ad'] ?? 'İplik';
                                  String iplikRenk = iplik['renk'] ?? 'Renk Yok';
                                  String iplikLot = iplik['lot_no'] ?? '-';
                                  String iplikBirim = iplik['birim'] ?? 'kg';
                                  
                                  // Join başarısız olduysa iplik bilgilerini manuel olarak bul
                                  if (iplik.isEmpty && kayit['iplik_id'] != null) {
                                    final bulunanIplik = iplikStoklari.where(
                                      (stok) => stok['id'] == kayit['iplik_id']
                                    ).isNotEmpty 
                                      ? iplikStoklari.firstWhere(
                                          (stok) => stok['id'] == kayit['iplik_id']
                                        )
                                      : null;
                                    
                                    if (bulunanIplik != null) {
                                      iplikAdi = bulunanIplik['ad'] ?? 'İplik';
                                      iplikRenk = bulunanIplik['renk'] ?? 'Renk Yok';
                                      iplikLot = bulunanIplik['lot_no'] ?? '-';
                                      iplikBirim = bulunanIplik['birim'] ?? 'kg';
                                    }
                                  }
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: ListTile(
                                      leading: Icon(
                                        kayit['hareket_tipi'] == 'giris' 
                                          ? Icons.arrow_downward 
                                          : kayit['hareket_tipi'] == 'cikis'
                                            ? Icons.arrow_upward
                                            : Icons.compare_arrows,
                                        color: kayit['hareket_tipi'] == 'giris' 
                                          ? Colors.green 
                                          : kayit['hareket_tipi'] == 'cikis'
                                            ? Colors.red
                                            : Colors.blue,
                                      ),
                                      title: Text('$iplikAdi${iplikRenk != 'Renk Yok' ? ' - $iplikRenk' : ''}'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (iplikLot != '-')
                                            Text('Lot: $iplikLot'),
                                          Text('Miktar: ${kayit['miktar']} $iplikBirim'),
                                          Text('Hareket: ${_getHareketBaslik(kayit['hareket_tipi'] ?? 'bilinmiyor')}'),
                                          if (model != null)
                                            Text('Model: ${model['marka']} ${model['item_no']} - ${model['renk']}'),
                                          if (kayit['aciklama'] != null && kayit['aciklama'].toString().isNotEmpty)
                                            Text('Açıklama: ${kayit['aciklama']}'),
                                          Text('Tarih: ${tarih != null ? DateFormat('dd.MM.yyyy HH:mm').format(tarih) : "-"}'),
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                } else if (seciliMenu == 2) {
                  // İplik Siparişi Oluştur
                  return _buildSiparisOlusturSayfasi();
                } else if (seciliMenu == 3) {
                  // Yeni Sipariş Takip Sistemi
                  return const IplikSiparisTakipPage();
                } else {
                  return const Center(child: Text('Bilinmeyen sayfa'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: seciliMenu == 0 
        ? FloatingActionButton(
            backgroundColor: const Color(0xFFD2B48C),
            onPressed: _yeniIplikGirisi,
            tooltip: 'Yeni İplik Girişi',
            child: const Icon(Icons.add),
          )
        : null,
    );
  }

  Widget _buildSiparisOlusturSayfasi() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kartı
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: 32,
                      color: Color(0xFFD2B48C),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İplik Siparişi Oluştur',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD2B48C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tedarikçilerinize hızlı ve düzenli sipariş verin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Ana sipariş formu
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş Bilgileri',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD2B48C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Sipariş formu burada geliştirilecek
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _yeniSiparisOlustur,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Tekli Sipariş Oluştur'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD2B48C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _topluSiparisOlustur,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Toplu Sipariş (Excel)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Excel şablon indirme
                    Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.download,
                                  color: Color(0xFFD2B48C),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Excel Şablon İndirme',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD2B48C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toplu sipariş oluşturmak için Excel şablonunu indirin, doldurun ve yükleyin.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _excelSablonIndir,
                              icon: const Icon(Icons.file_download),
                              label: const Text('Excel Şablon İndir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Özellikler kartı
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.featured_play_list,
                          color: Color(0xFFD2B48C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sipariş Sistemi Özellikleri',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD2B48C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildOzellikSatiri(Icons.business, 'Tedarikçi Seçimi', 'İplik firmalarından tedarikçi seçin'),
                    _buildOzellikSatiri(Icons.category, 'İplik Detayları', 'İplik türü, renk, miktar ve özellikleri'),
                    _buildOzellikSatiri(Icons.schedule, 'Termin Takibi', 'Teslimat tarihi belirleme ve takip'),
                    _buildOzellikSatiri(Icons.attach_money, 'Fiyat Yönetimi', 'Birim fiyat ve toplam tutar hesaplama'),
                    _buildOzellikSatiri(Icons.track_changes, 'Sipariş Takibi', 'Sipariş durumu ve süreç takibi'),
                    _buildOzellikSatiri(Icons.email, 'Bildirimler', 'E-posta ve SMS ile otomatik bildirim'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOzellikSatiri(IconData icon, String baslik, String aciklama) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD2B48C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFD2B48C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  aciklama,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
