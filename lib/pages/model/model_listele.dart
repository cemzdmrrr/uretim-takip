import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/config/dal_form_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/pages/model/model_detay.dart';
import 'package:uretim_takip/pages/model/model_duzenle.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/theme/app_theme.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/widgets/model_kritikleri_dialog.dart';
import 'package:uretim_takip/utils/app_exceptions.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

part 'model_listele_toplu.dart';
part 'model_listele_export.dart';

class ModelListele extends StatefulWidget {
  const ModelListele({super.key});

  @override
  State<ModelListele> createState() => _ModelListeleState();
}

class _ModelListeleState extends State<ModelListele> {
  final supabase = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;
  List<Map<String, dynamic>> modeller = [];
  bool yukleniyor = true;
  String arama = '';
  
  // Admin kontrolü - gerçek kullanıcı rolünden alınacak
  bool isAdmin = false;
  String currentUserRole = '';

  // Filtreleme seçenekleri
  String? seciliMarka;
  String? seciliModelAdi;
  String? seciliDurum;
  String? seciliUrunKategorisi;
  String? seciliCinsiyet;

  // Realtime subscription
  RealtimeChannel? _realtimeChannel;
  
  // Toplu işlem seçenekleri
  List<String> seciliIdler = [];
  bool tumunuSec = false;
  
  final List<String> durumOptions = ['Tümü', 'Beklemede', 'Planlama', 'Üretim', 'Tamamlandı', 'İptal'];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupRealtimeSubscription();
  }

  Future<void> _initializeData() async {
    await _getCurrentUserRole();
    await modelleriGetir();
  }

  Future<void> _getCurrentUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ ModelListele: Kullanıcı girişi yapılmamış');
        return;
      }

      debugPrint('🔍 ModelListele: ${user.email} için rol sorgulanıyor...');
      
      final response = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      debugPrint('📋 ModelListele: Rol sorgu sonucu: $response');

      setState(() {
        currentUserRole = response?['role'] ?? 'user';
        isAdmin = currentUserRole == 'admin';
      });
      
      debugPrint('✅ ModelListele: Rol set edildi - currentUserRole: $currentUserRole, isAdmin: $isAdmin');
    } catch (e) {
      debugPrint('❌ ModelListele: Kullanıcı rolü alınamadı: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('🔄 ModelListele didChangeDependencies çağrıldı');
    // Sayfa her göründüğünde verileri yenile - ama sadece rol set edildikten sonra
    if (currentUserRole.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        modelleriGetir();
      });
    }
  }

  Future<void> modelleriGetir() async {
    setState(() => yukleniyor = true);
    try {
      List<Map<String, dynamic>> response = [];
      
      if (currentUserRole == 'admin') {
        // Admin tüm modelleri görebilir
        final adminResponse = await supabase
            .from(DbTables.trikoTakip)
            .select('''
              id,
              marka,
              item_no,
              model_adi,
              sezon,
              koleksiyon,
              urun_kategorisi,
              triko_tipi,
              cinsiyet,
              yas_grubu,
              ana_iplik_turu,
              iplik_karisimi,
              ana_renkler,
              bedenler,
              toplam_adet,
              siparis_tarihi,
              termin_tarihi,
              durum,
              tamamlandi,
              created_at,
              updated_at,
              iplik_geldi,
              kase_onayi,
              orgu_firmasi,
              konfeksiyon_firmasi,
              utu_pres_firmasi
            ''')
            .eq('firma_id', _firmaId)
            .order('created_at', ascending: false);
        
        response = List<Map<String, dynamic>>.from(adminResponse);
      } else {
        // Diğer kullanıcılar sadece kendilerine atanan modelleri görebilir
        final user = supabase.auth.currentUser;
        if (user?.id != null) {
          final Set<String> atanmisModelIdleri = {};
          
          // Tüm atama tablolarından bu kullanıcıya atanan model ID'lerini çek
          final fId = TenantManager.instance.requireFirmaId;
          final futures = [
            supabase.from(DbTables.dokumaAtamalari).select('model_id').eq('atanan_kullanici_id', user!.id).eq('firma_id', fId),
            supabase.from(DbTables.konfeksiyonAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
            supabase.from(DbTables.nakisAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
            supabase.from(DbTables.yikamaAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
            supabase.from(DbTables.ilikDugmeAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
            supabase.from(DbTables.utuAtamalari).select('model_id').eq('atanan_kullanici_id', user.id).eq('firma_id', fId),
          ];
          
          final atamaResults = await Future.wait(futures.map((future) async {
            try {
              return await future;
            } catch (e) {
              debugPrint('Atama sorgusu hatası: $e');
              return [];
            }
          }));
          
          // Tüm atanmış model ID'lerini topla
          for (var atamaList in atamaResults) {
            for (var atama in atamaList) {
              atanmisModelIdleri.add(atama['model_id']);
            }
          }
          
          debugPrint('Atanmış model ID sayısı: ${atanmisModelIdleri.length}');
          
          if (atanmisModelIdleri.isNotEmpty) {
            // Atanmış modellerin detaylarını çek
            final modelResponse = await supabase
                .from(DbTables.trikoTakip)
                .select('''
                  id,
                  marka,
                  item_no,
                  model_adi,
                  sezon,
                  koleksiyon,
                  urun_kategorisi,
                  triko_tipi,
                  cinsiyet,
                  yas_grubu,
                  ana_iplik_turu,
                  iplik_karisimi,
                  ana_renkler,
                  bedenler,
                  toplam_adet,
                  siparis_tarihi,
                  termin_tarihi,
                  durum,
                  tamamlandi,
                  created_at,
                  updated_at,
                  iplik_geldi,
                  kase_onayi,
                  orgu_firmasi,
                  konfeksiyon_firmasi,
                  utu_pres_firmasi
                ''')
                .eq('firma_id', _firmaId)
                .filter('id', 'in', '(${atanmisModelIdleri.join(',')})')
                .order('created_at', ascending: false);
            response = List<Map<String, dynamic>>.from(modelResponse);
          }
        }
      }
      
      debugPrint('📊 Gelen veri sayısı: ${response.length}');
      
      setState(() {
        modeller = response;
        yukleniyor = false;
      });
      
      debugPrint('✅ Model listesi güncellendi');
    } catch (e) {
      debugPrint('❌ Veri çekme hatası: $e');
      setState(() => yukleniyor = false);
      if (mounted) {
        context.showErrorSnackBar('Hata: $e');
      }
    }
  }

  List<Map<String, dynamic>> get filtreliModeller {
    List<Map<String, dynamic>> filtered = List.from(modeller);
    
    // EN ÖNEMLİ: Tamamlanmış modelleri ana listeden çıkar
    debugPrint('🔍 Filtreleme başlıyor - Toplam model sayısı: ${filtered.length}');
    
    filtered = filtered.where((model) {
      final tamamlandi = model['tamamlandi'];
      bool tamamlandiMi = false;
      
      // Tüm olası veri tiplerini kontrol et
      if (tamamlandi is bool) {
        tamamlandiMi = tamamlandi;
      } else if (tamamlandi is int) {
        tamamlandiMi = tamamlandi == 1;
      } else if (tamamlandi is String) {
        tamamlandiMi = tamamlandi.toLowerCase() == 'true' || tamamlandi == '1';
      }
      
      if (tamamlandiMi) {
        debugPrint('🚫 Tamamlanmış model filtrelendi: ${model['item_no']}');
      }
      
      return !tamamlandiMi; // Tamamlanmamış olanları göster
    }).toList();
    
    debugPrint('✅ Tamamlanmamış model sayısı: ${filtered.length}');
    
    if (arama.isNotEmpty) {
      filtered = filtered.where((model) {
        final itemNo = model['item_no']?.toString().toLowerCase() ?? '';
        final marka = model['marka']?.toString().toLowerCase() ?? '';
        final modelAdi = model['model_adi']?.toString().toLowerCase() ?? '';
        final aramaKelime = arama.toLowerCase();
        
        return itemNo.contains(aramaKelime) || 
               marka.contains(aramaKelime) || 
               modelAdi.contains(aramaKelime);
      }).toList();
    }
    
    if (seciliMarka != null && seciliMarka != 'Tümü') {
      filtered = filtered.where((model) => model['marka'] == seciliMarka).toList();
    }
    
    if (seciliModelAdi != null && seciliModelAdi != 'Tümü') {
      filtered = filtered.where((model) => model['model_adi'] == seciliModelAdi).toList();
    }
    
    if (seciliDurum != null && seciliDurum != 'Tümü') {
      filtered = filtered.where((model) => model['durum'] == seciliDurum).toList();
    }
    
    if (seciliUrunKategorisi != null && seciliUrunKategorisi != 'Tümü') {
      filtered = filtered.where((model) => model['urun_kategorisi'] == seciliUrunKategorisi).toList();
    }
    
    if (seciliCinsiyet != null && seciliCinsiyet != 'Tümü') {
      filtered = filtered.where((model) => model['cinsiyet'] == seciliCinsiyet).toList();
    }
    
    debugPrint('🎯 Final filtrelenmiş model sayısı: ${filtered.length}');
    return filtered;
  }

  Set<String> get markalar {
    return modeller.map((m) => m['marka']?.toString()).where((m) => m != null).cast<String>().toSet();
  }

  Set<String> get modelAdlari {
    return modeller.map((m) => m['model_adi']?.toString()).where((m) => m != null && m.isNotEmpty).cast<String>().toSet();
  }

  Set<String> get urunKategorileri {
    return modeller.map((m) => m['urun_kategorisi']?.toString()).where((m) => m != null).cast<String>().toSet();
  }

  Set<String> get cinsiyetler {
    return modeller.map((m) => m['cinsiyet']?.toString()).where((m) => m != null && m.isNotEmpty).cast<String>().toSet();
  }

  Color getTerminRengi(String? terminTarihi) {
    return AppTheme.getTerminRengi(terminTarihi);
  }

  String formatTarih(String? tarih) {
    if (tarih == null) return '';
    final date = DateTime.tryParse(tarih);
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String formatBedenler(Map<String, dynamic>? bedenler) {
    if (bedenler == null) return '';
    
    final List<String> bedenListesi = [];
    bedenler.forEach((beden, adet) {
      if (adet != null && adet > 0) {
        bedenListesi.add('$beden: $adet');
      }
    });
    
    return bedenListesi.join(', ');
  }

  Future<void> modelKopyala(dynamic modelId, String? marka, String? itemNo) async {
    // Yeni item_no için kullanıcıdan giriş al
    final yeniItemNoController = TextEditingController(text: '${itemNo ?? ''}-KOPYA');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Kopyala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${marka ?? ''} - ${itemNo ?? ''} modelini kopyalamak istediğinizden emin misiniz?'),
            const SizedBox(height: 16),
            const Text('Yeni Model Kodu (benzersiz olmalı):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: yeniItemNoController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Yeni model kodu girin',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Not: Durum "Beklemede" olarak kopyalanacaktır. Tarihler korunacaktır.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final yeniKod = yeniItemNoController.text.trim();
              if (yeniKod.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Model kodu boş olamaz')),
                );
                return;
              }
              Navigator.pop(context, yeniKod);
            },
            child: const Text('Kopyala'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      // Orijinal modelin tüm verilerini çek
      final originalModel = await supabase
          .from(DbTables.trikoTakip)
          .select('*')
          .eq('id', modelId)
          .single();

      // Benzersiz ve sıfırlanması gereken alanları düzenle
      final yeniModel = Map<String, dynamic>.from(originalModel);
      yeniModel.remove('id');
      yeniModel.remove('created_at');
      yeniModel.remove('updated_at');
      yeniModel['item_no'] = result; // Yeni benzersiz model kodu
      yeniModel['durum'] = 'Beklemede';
      yeniModel['tamamlandi'] = false;
      // siparis_tarihi ve termin_tarihi orijinalden kopyalanır
      yeniModel['iplik_geldi'] = false;
      yeniModel['kase_onayi'] = false;

      // Yeni modeli kaydet
      final response = await supabase
          .from(DbTables.trikoTakip)
          .insert(yeniModel)
          .select('id')
          .single();
      final yeniModelId = response['id'].toString();

      // Beden dağılımını kopyala
      try {
        final bedenler = await supabase
            .from(DbTables.modelBedenDagilimi)
            .select('*')
            .eq('model_id', modelId);
        for (final beden in bedenler) {
          final yeniBeden = Map<String, dynamic>.from(beden);
          yeniBeden.remove('id');
          yeniBeden.remove('created_at');
          yeniBeden['model_id'] = yeniModelId;
          await supabase.from(DbTables.modelBedenDagilimi).insert(yeniBeden);
        }
      } catch (e) {
        debugPrint('Beden dağılımı kopyalama hatası: $e');
      }

      // Aksesuarları kopyala
      try {
        final aksesuarlar = await supabase
            .from(DbTables.modelAksesuar)
            .select('*')
            .eq('model_id', modelId);
        for (final aksesuar in aksesuarlar) {
          final yeniAksesuar = Map<String, dynamic>.from(aksesuar);
          yeniAksesuar.remove('id');
          yeniAksesuar.remove('created_at');
          yeniAksesuar['model_id'] = yeniModelId;
          await supabase.from(DbTables.modelAksesuar).insert(yeniAksesuar);
        }
      } catch (e) {
        debugPrint('Aksesuar kopyalama hatası: $e');
      }

      if (mounted) {
        context.showSuccessSnackBar('Model başarıyla kopyalandı: $result');
      }

      await modelleriGetir();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Kopyalama hatası: $e');
      }
    }
  }

  Future<void> modelSil(dynamic modelId, String? marka, String? itemNo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Sil'),
        content: Text('${marka ?? ''} - ${itemNo ?? ''} modelini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Önce ilişkili atamaları sil (foreign key constraint önlemek için)
        final atamaTablolari = [
          DbTables.dokumaAtamalari,
          DbTables.konfeksiyonAtamalari,
          DbTables.nakisAtamalari,
          DbTables.yikamaAtamalari,
          DbTables.ilikDugmeAtamalari,
          DbTables.utuAtamalari,
          DbTables.kaliteKontrolAtamalari,
          DbTables.paketlemeAtamalari,
          DbTables.sevkiyatKayitlari,
        ];
        
        for (final tablo in atamaTablolari) {
          try {
            await supabase.from(tablo).delete().eq('model_id', modelId);
          } catch (e) {
            // Tablo yoksa veya kayıt yoksa devam et
          }
        }
        
        // Modeli sil
        await supabase.from(DbTables.trikoTakip).delete().eq('id', modelId);
        
        // Önce local listeden kaldır (anında görünüm güncellemesi)
        if (!mounted) return;
        setState(() {
          modeller.removeWhere((m) => m['id'] == modelId);
          filtreliModeller.removeWhere((m) => m['id'] == modelId);
        });
        
        if (mounted) {
          context.showSuccessSnackBar('Model başarıyla silindi');
        }
        
        // Listeyi veritabanından yenile
        await modelleriGetir();
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Silme hatası: $e');
        }
      }
    }
  }

  Color _getDurumRengi(String? durum) {
    return AppTheme.getDurumRengi(durum);
  }

  void tumunuSecToggle(bool? value) {
    setState(() {
      tumunuSec = value ?? false;
      if (tumunuSec) {
        seciliIdler.clear();
        seciliIdler.addAll(filtreliModeller.map((m) => m['id'].toString()));
      } else {
        seciliIdler.clear();
      }
    });
  }

  // Toplu işlem fonksiyonu
  @override
  Widget build(BuildContext context) {
    final seciliModelSayisi = seciliIdler.length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TexPilot'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (seciliModelSayisi > 0) ...[
            // Toplu İşlemler Menüsü
            PopupMenuButton<String>(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_play, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Toplu İşlemler ($seciliModelSayisi)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              onSelected: (value) => _topluIslemYap(value),
              itemBuilder: (context) => [
                // ========== DURUM GÜNCELLEMELERİ ==========
                const PopupMenuItem(
                  enabled: false,
                  child: Text('DURUM GÜNCELLEMELERİ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const PopupMenuItem(
                  value: 'durum_guncelle',
                  child: Row(
                    children: [
                      Icon(Icons.update, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Durum Güncelle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'termin_guncelle',
                  child: Row(
                    children: [
                      Icon(Icons.date_range, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Termin Tarihi Güncelle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tamamlandi_true',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Tamamlandı Olarak İşaretle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tamamlandi_false',
                  child: Row(
                    children: [
                      Icon(Icons.replay, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Devam Ediyor Olarak İşaretle'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                
                // ========== EXCEL DIŞA AKTARMA ==========
                const PopupMenuItem(
                  enabled: false,
                  child: Text('EXCEL DIŞA AKTARMA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const PopupMenuItem(
                  value: 'excel_urun_bilgileri',
                  child: Row(
                    children: [
                      Icon(Icons.inventory, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Ürün Bilgileri Excel\'e Aktar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excel_uretim_durumu',
                  child: Row(
                    children: [
                      Icon(Icons.precision_manufacturing, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Üretim Durumu Excel\'e Aktar'),
                    ],
                  ),
                ),
                
                // Admin tüm işlem butonlarına erişebilir
                if (isAdmin || currentUserRole == 'admin') ...[
                  const PopupMenuDivider(),
                  // ========== TEDARİKÇİ ATAMA ==========
                  const PopupMenuItem(
                    enabled: false,
                    child: Text('TEDARİKÇİ ATAMA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const PopupMenuItem(
                    value: 'dokuma_tedarikci_ata',
                    child: Row(
                      children: [
                        Icon(Icons.factory, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('Üretim Tedarikçisi Ata'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'konfeksiyon_tedarikci_ata',
                    child: Row(
                      children: [
                        Icon(Icons.content_cut, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text('Konfeksiyon Tedarikçisi Ata'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'yikama_tedarikci_ata',
                    child: Row(
                      children: [
                        Icon(Icons.local_laundry_service, color: Colors.cyan),
                        SizedBox(width: 8),
                        Text('Yıkama Tedarikçisi Ata'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'nakis_tedarikci_ata',
                    child: Row(
                      children: [
                        Icon(Icons.brush, color: Colors.pink),
                        SizedBox(width: 8),
                        Text('Nakış Tedarikçisi Ata'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // ========== SİLME ==========
                  const PopupMenuItem(
                    value: 'sil',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Seçili Modelleri Sil'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              modelleriGetir();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve filtreler
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Arama çubuğu
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Model Ara',
                    hintText: 'Marka, item no, model adı...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      arama = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Toplu seçim ve filtre satırı
                Row(
                  children: [
                    // Tümünü seç checkbox'ı
                    Row(
                      children: [
                        Checkbox(
                          value: tumunuSec,
                          onChanged: tumunuSecToggle,
                        ),
                        const Text('Tümünü Seç'),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text('${filtreliModeller.length} model listeleniyor'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filtre satırı
                Row(
                  children: [
                    // Marka filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Marka',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: seciliMarka,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...markalar.map((marka) => DropdownMenuItem(
                                value: marka,
                                child: Text(marka),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            seciliMarka = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Model Adı filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Model Adı',
                          border: OutlineInputBorder(),
                        ),
                        value: seciliModelAdi,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...modelAdlari.map((ad) => DropdownMenuItem(
                                value: ad,
                                child: Text(ad),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            seciliModelAdi = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Durum filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: seciliDurum,
                        items: durumOptions.map((durum) => DropdownMenuItem(
                              value: durum == 'Tümü' ? null : durum,
                              child: Text(durum),
                            )).toList(),
                        onChanged: (value) {
                          setState(() {
                            seciliDurum = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Ürün kategorisi filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: seciliUrunKategorisi,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...urunKategorileri.map((kategori) => DropdownMenuItem(
                                value: kategori,
                                child: Text(kategori),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            seciliUrunKategorisi = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cinsiyet filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Cinsiyet',
                          border: OutlineInputBorder(),
                        ),
                        value: seciliCinsiyet,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tümü')),
                          ...cinsiyetler.map((cinsiyet) => DropdownMenuItem(
                                value: cinsiyet,
                                child: Text(cinsiyet),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            seciliCinsiyet = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: yukleniyor
                ? const LoadingWidget()
                : filtreliModeller.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz model bulunmuyor.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtreliModeller.length,
                        itemBuilder: (context, index) {
                          final model = filtreliModeller[index];
                          final secili = seciliIdler.contains(model['id'].toString());
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: getTerminRengi(model['termin_tarihi']),
                            child: InkWell(
                              onTap: () async {
                                debugPrint('Model detay sayfasına gidiliyor - ID: ${model['id']}');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ModelDetay(
                                      modelId: model['id'].toString(),
                                      modelData: model,
                                    ),
                                  ),
                                );
                                
                                debugPrint('🔄 Model detay sayfasından dönüldü - result: $result');
                                
                                // Model tamamlandıysa listeyi yenile
                                if (result == true) {
                                  debugPrint('✅ Model tamamlandı bildirimi alındı!');
                                  debugPrint('🔄 Sunucudan fresh veri çekiliyor...');
                                  await modelleriGetir();
                                  debugPrint('✅ Liste yenilendi.');
                                } else {
                                  debugPrint('ℹ️ Normal dönüş - model tamamlanmadı');
                                  // Normal durumda da listeyi yenile
                                  await modelleriGetir();
                                }
                                
                                debugPrint('🎨 UI zorla güncelleniyor...');
                                if (!mounted) return;
                                setState(() {}); // UI'yi zorla güncelle
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Checkbox - tıklamayı durdur
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (secili) {
                                            seciliIdler.remove(model['id'].toString());
                                          } else {
                                            seciliIdler.add(model['id'].toString());
                                          }
                                          tumunuSec = seciliIdler.length == filtreliModeller.length;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          secili ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: secili ? Theme.of(context).primaryColor : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Ana içerik
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Başlık
                                          Text(
                                            '${model['marka']} - ${model['item_no']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          
                                          // Özet bilgiler: Model Adı, Renk, Adet, Termin
                                          if (model['model_adi'] != null)
                                            Text(
                                              model['model_adi'],
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              if (model['renk'] != null && model['renk'].toString().isNotEmpty)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.palette, size: 14, color: Colors.grey[600]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      model['renk'],
                                                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                                                    ),
                                                  ],
                                                ),
                                              if (model['toplam_adet'] != null)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${model['toplam_adet']} adet',
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              if (model['termin_tarihi'] != null)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.event, size: 14, color: Colors.grey[600]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formatTarih(model['termin_tarihi']),
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Sağ taraf butonları
                                    Column(
                                      children: [
                                        // Durum göstergesi
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getDurumRengi(model['durum']),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            model['durum'] ?? 'Beklemede',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        
                                        // Kritikler ikonu - tüm kullanıcılar görebilir
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => ModelKritikleriDialog(
                                                    modelId: model['id'],
                                                    modelMarka: model['marka'] ?? 'Bilinmeyen',
                                                    modelItemNo: model['item_no'] ?? 'Bilinmeyen',
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[100],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.orange,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Admin butonları - admin tüm işlemleri yapabilir
                                        if (isAdmin || currentUserRole == 'admin') ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  modelKopyala(model['id'], model['marka'], model['item_no']);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  child: const Icon(Icons.copy, color: Colors.green, size: 20),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  // Model düzenleme sayfasına git
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ModelDuzenlePage(
                                                        modelId: model['id'].toString(),
                                                        modelData: model,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  modelSil(model['id'], model['marka'], model['item_no']);
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
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

  // Seçili modellerin ürün bilgilerini Excel'e aktar
  void _setupRealtimeSubscription() {
    // Model tablosu değişikliklerini dinle
    _realtimeChannel = supabase
        .channel('model_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: DbTables.trikoTakip,
          callback: (payload) {
            debugPrint('🔄 Model listesi güncellendi: ${payload.eventType}');
            // UI thread'de güncelle
            if (mounted) {
              modelleriGetir();
            }
          },
        )
        .subscribe();

    debugPrint('✅ Model listesi realtime subscription kuruldu');
  }

  void _cleanupRealtimeSubscription() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    debugPrint('🧹 Model listesi realtime subscription temizlendi');
  }

  @override
  void dispose() {
    _cleanupRealtimeSubscription();
    super.dispose();
  }
}
