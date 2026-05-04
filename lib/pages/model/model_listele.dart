import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/pages/model/model_detay.dart';
import 'package:uretim_takip/pages/model/model_duzenle.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/theme/app_theme.dart';
import 'package:uretim_takip/utils/excel_export.dart';
import 'package:uretim_takip/widgets/model_kritikleri_dialog.dart';
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
  String? seciliRenk;
  String? seciliCinsiyet;
  String seciliSiralama = 'Termin (En Yakin)';

  // Realtime subscription
  RealtimeChannel? _realtimeChannel;

  // Toplu işlem seçenekleri
  List<String> seciliIdler = [];
  bool tumunuSec = false;

  final List<String> durumOptions = [
    'Tümü',
    'Beklemede',
    'Planlama',
    'Üretim',
    'Tamamlandı',
    'İptal'
  ];

  final List<String> siralamaOptions = [
    'Termin (En Yakin)',
    'Termin (En Uzak)',
    'En Yeni Kayit',
    'En Eski Kayit',
    'Marka (A-Z)',
    'Marka (Z-A)',
    'Adet (Yuksek-Dusuk)',
    'Adet (Dusuk-Yuksek)',
  ];

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

      debugPrint(
          '✅ ModelListele: Rol set edildi - currentUserRole: $currentUserRole, isAdmin: $isAdmin');
    } catch (e) {
      debugPrint('❌ ModelListele: Kullanıcı rolü alınamadı: $e');
    }
  }

  bool _eskiAtamaSemasi(String tabloAdi) => {
        DbTables.nakisAtamalari,
        DbTables.yikamaAtamalari,
        DbTables.ilikDugmeAtamalari,
      }.contains(tabloAdi);

  Future<List<dynamic>> _atananModelIdSatirlariGetir(
    String tabloAdi,
    String userId,
    String firmaId,
  ) async {
    try {
      final query = supabase
          .from(tabloAdi)
          .select('model_id')
          .eq('atanan_kullanici_id', userId);
      final response = _eskiAtamaSemasi(tabloAdi)
          ? await query
          : await query.eq('firma_id', firmaId);
      return List<dynamic>.from(response);
    } catch (e) {
      try {
        final response = await supabase
            .from(tabloAdi)
            .select('model_id')
            .eq('atanan_kullanici_id', userId);
        return List<dynamic>.from(response);
      } catch (fallbackError) {
        debugPrint('$tabloAdi atama sorgusu hatası: $fallbackError');
        return const [];
      }
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
        final adminResponse =
            await supabase.from(DbTables.trikoTakip).select('''
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
              renk,
              renk_kombinasyonu,
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
            ''').eq('firma_id', _firmaId).order('created_at', ascending: false);

        response = List<Map<String, dynamic>>.from(adminResponse);
      } else {
        // Diğer kullanıcılar sadece kendilerine atanan modelleri görebilir
        final user = supabase.auth.currentUser;
        if (user?.id != null) {
          final Set<String> atanmisModelIdleri = {};

          // Tüm atama tablolarından bu kullanıcıya atanan model ID'lerini çek
          final fId = TenantManager.instance.requireFirmaId;
          final userId = user!.id;
          final futures = [
            DbTables.dokumaAtamalari,
            DbTables.konfeksiyonAtamalari,
            DbTables.nakisAtamalari,
            DbTables.yikamaAtamalari,
            DbTables.ilikDugmeAtamalari,
            DbTables.utuAtamalari,
          ].map((tablo) => _atananModelIdSatirlariGetir(tablo, userId, fId));

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
                  renk,
                  renk_kombinasyonu,
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
                .inFilter('id', atanmisModelIdleri.toList())
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
    debugPrint(
        '🔍 Filtreleme başlıyor - Toplam model sayısı: ${filtered.length}');

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
        final renk = _renkMetni(model).toLowerCase();
        final aramaKelime = arama.toLowerCase();

        return itemNo.contains(aramaKelime) ||
            marka.contains(aramaKelime) ||
            modelAdi.contains(aramaKelime) ||
            renk.contains(aramaKelime);
      }).toList();
    }

    if (seciliMarka != null && seciliMarka != 'Tümü') {
      filtered =
          filtered.where((model) => model['marka'] == seciliMarka).toList();
    }

    if (seciliModelAdi != null && seciliModelAdi != 'Tümü') {
      filtered = filtered
          .where((model) => model['model_adi'] == seciliModelAdi)
          .toList();
    }

    if (seciliDurum != null && seciliDurum != 'Tümü') {
      filtered =
          filtered.where((model) => model['durum'] == seciliDurum).toList();
    }

    if (seciliRenk != null && seciliRenk != 'Tümü') {
      filtered =
          filtered.where((model) => _renkMetni(model) == seciliRenk).toList();
    }

    if (seciliCinsiyet != null && seciliCinsiyet != 'Tümü') {
      filtered = filtered
          .where((model) => model['cinsiyet'] == seciliCinsiyet)
          .toList();
    }

    debugPrint('🎯 Final filtrelenmiş model sayısı: ${filtered.length}');
    _sirala(filtered);
    return filtered;
  }

  Set<String> get markalar {
    return modeller
        .map((m) => m['marka']?.toString())
        .where((m) => m != null)
        .cast<String>()
        .toSet();
  }

  Set<String> get modelAdlari {
    return modeller
        .map((m) => m['model_adi']?.toString())
        .where((m) => m != null && m.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  Set<String> get renkler {
    return modeller
        .map(_renkMetni)
        .where((m) => m.isNotEmpty && m != '-')
        .cast<String>()
        .toSet();
  }

  Set<String> get cinsiyetler {
    return modeller
        .map((m) => m['cinsiyet']?.toString())
        .where((m) => m != null && m.isNotEmpty)
        .cast<String>()
        .toSet();
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

  int _intDeger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _renkMetni(Map<String, dynamic> model) {
    final renk = _renkDegeriMetni(
        model['renk'] ?? model['renk_kombinasyonu'] ?? model['ana_renkler']);
    if (renk != null) return renk;

    final itemNoRengi = _itemNoRenkMetni(model['item_no']);
    if (itemNoRengi != null) return itemNoRengi;

    return '-';
  }

  String? _renkDegeriMetni(dynamic renk) {
    if (renk == null) return null;
    if (renk is String) {
      final temiz = renk.trim();
      if (temiz.startsWith('[') || temiz.startsWith('{')) {
        try {
          final parsed = jsonDecode(temiz);
          return _renkDegeriMetni(parsed);
        } catch (_) {}
      }
      return temiz.isEmpty ? null : temiz;
    }
    if (renk is List) {
      final values = renk
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      return values.isEmpty ? null : values.join(', ');
    }
    if (renk is Map) {
      final values = renk.values
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      return values.isEmpty ? null : values.join(', ');
    }
    final text = renk.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _itemNoRenkMetni(dynamic itemNo) {
    final text = itemNo?.toString().trim();
    if (text == null || text.isEmpty) return null;

    final parts = text
        .replaceAll(RegExp(r'[-_/]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length < 2) return null;

    final suffix =
        parts.last.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]'), '').trim();
    if (suffix.length < 2 || suffix.length > 10) return null;

    return _renkKodunuGenislet(suffix);
  }

  String _renkKodunuGenislet(String kod) {
    final normalized = kod
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');

    const renkKodlari = {
      'ANM': 'ANTRASİT MELANJ',
      'BEJ': 'BEJ',
      'BEY': 'BEYAZ',
      'BRD': 'BORDO',
      'EKR': 'EKRU',
      'GMJ': 'GRİ MELANJ',
      'GR': 'GRİ',
      'GRI': 'GRİ',
      'KAH': 'KAHVE',
      'KHV': 'KAHVE',
      'KIR': 'KIRMIZI',
      'KRM': 'KIRMIZI',
      'LAC': 'LACİVERT',
      'LACI': 'LACİVERT',
      'MAV': 'MAVİ',
      'MOR': 'MOR',
      'MVI': 'MAVİ',
      'PEM': 'PEMBE',
      'PUD': 'PUDRA',
      'SARI': 'SARI',
      'SIY': 'SİYAH',
      'SYH': 'SİYAH',
      'VIZ': 'VİZON',
      'YES': 'YEŞİL',
      'YSL': 'YEŞİL',
    };

    return renkKodlari[normalized] ?? kod.toUpperCase();
  }

  DateTime? _tarihDegeri(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '');
  }

  void _sirala(List<Map<String, dynamic>> liste) {
    int compareText(dynamic a, dynamic b, {bool asc = true}) {
      final left = (a?.toString() ?? '').toLowerCase();
      final right = (b?.toString() ?? '').toLowerCase();
      return asc ? left.compareTo(right) : right.compareTo(left);
    }

    liste.sort((a, b) {
      switch (seciliSiralama) {
        case 'Termin (En Uzak)':
          final left = _tarihDegeri(a['termin_tarihi']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final right = _tarihDegeri(b['termin_tarihi']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        case 'En Yeni Kayit':
          final left = _tarihDegeri(a['created_at']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final right = _tarihDegeri(b['created_at']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        case 'En Eski Kayit':
          final left = _tarihDegeri(a['created_at']) ?? DateTime(9999);
          final right = _tarihDegeri(b['created_at']) ?? DateTime(9999);
          return left.compareTo(right);
        case 'Marka (A-Z)':
          return compareText(a['marka'], b['marka']);
        case 'Marka (Z-A)':
          return compareText(a['marka'], b['marka'], asc: false);
        case 'Adet (Yuksek-Dusuk)':
          return _intDeger(b['toplam_adet'] ?? b['adet'])
              .compareTo(_intDeger(a['toplam_adet'] ?? a['adet']));
        case 'Adet (Dusuk-Yuksek)':
          return _intDeger(a['toplam_adet'] ?? a['adet'])
              .compareTo(_intDeger(b['toplam_adet'] ?? b['adet']));
        case 'Termin (En Yakin)':
        default:
          final left = _tarihDegeri(a['termin_tarihi']) ?? DateTime(9999);
          final right = _tarihDegeri(b['termin_tarihi']) ?? DateTime(9999);
          return left.compareTo(right);
      }
    });
  }

  Map<String, dynamic> _kopyaModelPayloadiHazirla(
    Map<String, dynamic> originalModel,
    String yeniItemNo,
  ) {
    final yeniModel = Map<String, dynamic>.from(originalModel);
    final toplamAdet = _intDeger(yeniModel['toplam_adet'] ?? yeniModel['adet']);

    yeniModel.remove('id');
    yeniModel.remove('created_at');
    yeniModel.remove('updated_at');

    yeniModel['item_no'] = yeniItemNo;
    yeniModel['durum'] = 'Beklemede';
    yeniModel['tamamlandi'] = false;
    yeniModel['iplik_geldi'] = false;
    yeniModel['kase_onayi'] = false;

    final yeniRenk = _itemNoRenkMetni(yeniItemNo);
    if (yeniRenk != null) {
      yeniModel['renk'] = yeniRenk;
      yeniModel['renk_kombinasyonu'] = yeniRenk;
      if (yeniModel.containsKey('ana_renkler')) {
        yeniModel['ana_renkler'] = null;
      }
    }

    for (final key in const [
      'yuklenen_adet',
      'gonderilen_adet',
      'tamamlanan_adet',
      'fire_adet',
    ]) {
      if (yeniModel.containsKey(key)) {
        yeniModel[key] = 0;
      }
    }

    if (yeniModel.containsKey('kalan_adet')) {
      yeniModel['kalan_adet'] = toplamAdet;
    }

    if (yeniModel.containsKey('mevcut_asama')) {
      yeniModel['mevcut_asama'] = 'beklemede';
    }

    for (final key in const [
      'dokuma_durumu',
      'orgu_durumu',
      'nakis_durumu',
      'konfeksiyon_durumu',
      'yikama_durumu',
      'ilik_dugme_durumu',
      'utu_durumu',
      'kalite_durumu',
      'kalite_kontrol_durumu',
      'paketleme_durumu',
    ]) {
      if (yeniModel.containsKey(key)) {
        yeniModel[key] = 'beklemede';
      }
    }

    for (final key in const [
      'tamamlama_tarihi',
      'gonderim_tarihi',
      'yukleme_tarihi',
      'son_islem_tarihi',
    ]) {
      if (yeniModel.containsKey(key)) {
        yeniModel[key] = null;
      }
    }

    return yeniModel;
  }

  Future<void> _iliskiliKayitlariKopyala({
    required String tableName,
    required dynamic eskiModelId,
    required String yeniModelId,
  }) async {
    final kayitlar =
        await supabase.from(tableName).select('*').eq('model_id', eskiModelId);

    final payload = List<Map<String, dynamic>>.from(kayitlar).map((kayit) {
      final yeniKayit = Map<String, dynamic>.from(kayit);
      yeniKayit.remove('id');
      yeniKayit.remove('created_at');
      yeniKayit.remove('updated_at');
      yeniKayit['model_id'] = yeniModelId;
      return yeniKayit;
    }).toList();

    if (payload.isEmpty) return;
    await supabase.from(tableName).insert(payload);
  }

  Future<void> modelKopyala(
      dynamic modelId, String? marka, String? itemNo) async {
    // Yeni item_no için kullanıcıdan giriş al
    final yeniItemNoController =
        TextEditingController(text: '${itemNo ?? ''}-KOPYA');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Kopyala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${marka ?? ''} - ${itemNo ?? ''} modelini kopyalamak istediğinizden emin misiniz?'),
            const SizedBox(height: 16),
            const Text('Yeni Model Kodu (benzersiz olmalı):',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
      final yeniModel = _kopyaModelPayloadiHazirla(originalModel, result);

      // Yeni modeli kaydet
      final response = await supabase
          .from(DbTables.trikoTakip)
          .insert(yeniModel)
          .select('id')
          .single();
      final yeniModelId = response['id'].toString();

      // Beden dağılımını kopyala
      try {
        await _iliskiliKayitlariKopyala(
          tableName: DbTables.modelBedenDagilimi,
          eskiModelId: modelId,
          yeniModelId: yeniModelId,
        );
      } catch (e) {
        debugPrint('Beden dağılımı kopyalama hatası: $e');
      }

      // Aksesuarları kopyala
      try {
        await _iliskiliKayitlariKopyala(
          tableName: DbTables.modelAksesuar,
          eskiModelId: modelId,
          yeniModelId: yeniModelId,
        );
      } catch (e) {
        debugPrint('Aksesuar kopyalama hatası: $e');
      }

      // Teknik dosya kayıtlarını kopyala
      try {
        await _iliskiliKayitlariKopyala(
          tableName: DbTables.teknikDosyalar,
          eskiModelId: modelId,
          yeniModelId: yeniModelId,
        );
      } catch (e) {
        debugPrint('Teknik dosya kopyalama hatası: $e');
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
        content: Text(
            '${marka ?? ''} - ${itemNo ?? ''} modelini silmek istediğinizden emin misiniz?'),
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

  bool _tamamlandiMi(Map<String, dynamic> model) {
    final tamamlandi = model['tamamlandi'];
    if (tamamlandi is bool) return tamamlandi;
    if (tamamlandi is int) return tamamlandi == 1;
    if (tamamlandi is String) {
      return tamamlandi.toLowerCase() == 'true' || tamamlandi == '1';
    }
    return false;
  }

  bool _geciktiMi(Map<String, dynamic> model) {
    if (_tamamlandiMi(model)) return false;
    final termin = DateTime.tryParse(model['termin_tarihi']?.toString() ?? '');
    if (termin == null) return false;
    final bugun = DateTime.now();
    final bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);
    return termin.isBefore(bugunBaslangic);
  }

  bool get _aktifFiltreVar =>
      arama.isNotEmpty ||
      seciliMarka != null ||
      seciliModelAdi != null ||
      seciliDurum != null ||
      seciliRenk != null ||
      seciliCinsiyet != null ||
      seciliSiralama != 'Termin (En Yakin)';

  void _filtreleriTemizle() {
    setState(() {
      arama = '';
      seciliMarka = null;
      seciliModelAdi = null;
      seciliDurum = null;
      seciliRenk = null;
      seciliCinsiyet = null;
      seciliSiralama = 'Termin (En Yakin)';
      tumunuSec = false;
      seciliIdler.clear();
    });
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

  void _modelSeciminiDegistir(Map<String, dynamic> model) {
    final id = model['id'].toString();
    setState(() {
      if (seciliIdler.contains(id)) {
        seciliIdler.remove(id);
      } else {
        seciliIdler.add(id);
      }
      tumunuSec = filtreliModeller.isNotEmpty &&
          seciliIdler.length == filtreliModeller.length;
    });
  }

  Future<void> _modelDetayAc(Map<String, dynamic> model) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelDetay(
          modelId: model['id'].toString(),
          modelData: model,
        ),
      ),
    );

    if (!mounted) return;
    await modelleriGetir();
    if (result == true && mounted) setState(() {});
  }

  Widget _buildTopluIslemMenu(int seciliModelSayisi) {
    return PopupMenuButton<String>(
      tooltip: 'Toplu işlemler',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.playlist_play, color: Colors.white),
          const SizedBox(width: 4),
          Text('Toplu İşlemler ($seciliModelSayisi)',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
      onSelected: (value) => _topluIslemYap(value),
      itemBuilder: (context) => [
        const PopupMenuItem(
            enabled: false,
            child: Text('DURUM',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey))),
        const PopupMenuItem(
            value: 'durum_guncelle',
            child: Row(children: [
              Icon(Icons.update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Durum Güncelle')
            ])),
        const PopupMenuItem(
            value: 'termin_guncelle',
            child: Row(children: [
              Icon(Icons.date_range, color: Colors.purple),
              SizedBox(width: 8),
              Text('Termin Tarihi Güncelle')
            ])),
        const PopupMenuItem(
            value: 'tamamlandi_true',
            child: Row(children: [
              Icon(Icons.done_all, color: Colors.green),
              SizedBox(width: 8),
              Text('Tamamlandı Olarak İşaretle')
            ])),
        const PopupMenuItem(
            value: 'tamamlandi_false',
            child: Row(children: [
              Icon(Icons.replay, color: Colors.orange),
              SizedBox(width: 8),
              Text('Devam Ediyor Olarak İşaretle')
            ])),
        const PopupMenuDivider(),
        const PopupMenuItem(
            enabled: false,
            child: Text('EXCEL',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey))),
        const PopupMenuItem(
            value: 'excel_urun_bilgileri',
            child: Row(children: [
              Icon(Icons.inventory, color: Colors.teal),
              SizedBox(width: 8),
              Text('Ürün Bilgileri Excel')
            ])),
        const PopupMenuItem(
            value: 'excel_uretim_durumu',
            child: Row(children: [
              Icon(Icons.precision_manufacturing, color: Colors.orange),
              SizedBox(width: 8),
              Text('Üretim Durumu Excel')
            ])),
        if (isAdmin || currentUserRole == 'admin') ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
              enabled: false,
              child: Text('TEDARİKÇİ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          const PopupMenuItem(
              value: 'dokuma_tedarikci_ata',
              child: Row(children: [
                Icon(Icons.factory, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Üretim Tedarikçisi Ata')
              ])),
          const PopupMenuItem(
              value: 'konfeksiyon_tedarikci_ata',
              child: Row(children: [
                Icon(Icons.content_cut, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text('Konfeksiyon Tedarikçisi Ata')
              ])),
          const PopupMenuItem(
              value: 'yikama_tedarikci_ata',
              child: Row(children: [
                Icon(Icons.local_laundry_service, color: Colors.cyan),
                SizedBox(width: 8),
                Text('Yıkama Tedarikçisi Ata')
              ])),
          const PopupMenuItem(
              value: 'nakis_tedarikci_ata',
              child: Row(children: [
                Icon(Icons.brush, color: Colors.pink),
                SizedBox(width: 8),
                Text('Nakış Tedarikçisi Ata')
              ])),
          const PopupMenuDivider(),
          const PopupMenuItem(
              value: 'sil',
              child: Row(children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Seçili Modelleri Sil')
              ])),
        ],
      ],
    );
  }

  Widget _buildMetricTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE5EE)),
          borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF607D8B),
                      fontWeight: FontWeight.w600)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 18, color: color, fontWeight: FontWeight.w800)),
            ])),
      ]),
    );
  }

  Widget _buildErpSummary(List<Map<String, dynamic>> liste) {
    final toplamAdet = liste.fold<int>(0,
        (sum, model) => sum + _intDeger(model['toplam_adet'] ?? model['adet']));
    final geciken = liste.where(_geciktiMi).length;
    final markaSayisi = liste
        .map((m) => m['marka']?.toString())
        .where((m) => m != null && m.isNotEmpty)
        .toSet()
        .length;
    final kartlar = [
      _buildMetricTile('Listelenen', '${liste.length}', Icons.view_list,
          const Color(0xFF1565C0)),
      _buildMetricTile(
          'Toplam Adet',
          NumberFormat.decimalPattern('tr_TR').format(toplamAdet),
          Icons.inventory_2,
          const Color(0xFF2E7D32)),
      _buildMetricTile('Geciken', '$geciken', Icons.priority_high,
          geciken > 0 ? const Color(0xFFC62828) : const Color(0xFF607D8B)),
      _buildMetricTile(
          'Marka', '$markaSayisi', Icons.business, const Color(0xFF6A1B9A)),
      _buildMetricTile('Seçili', '${seciliIdler.length}', Icons.checklist,
          const Color(0xFF455A64)),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: const BoxDecoration(
            color: Color(0xFFF7F9FC),
            border: Border(bottom: BorderSide(color: Color(0xFFE0E6EF)))),
        child: isMobile
            ? Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kartlar
                    .map((kart) => SizedBox(
                        width: constraints.maxWidth < 520
                            ? (constraints.maxWidth - 10) / 2
                            : 180,
                        child: kart))
                    .toList(),
              )
            : Row(
                children: [
                  for (var i = 0; i < kartlar.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: kartlar[i]),
                  ]
                ],
              ),
      );
    });
  }

  Widget _buildFilterDropdown(
      {required String label,
      required String? value,
      required List<String> values,
      required ValueChanged<String?> onChanged}) {
    return SizedBox(
      height: 42,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true),
        initialValue: value,
        isExpanded: true,
        items: [
          const DropdownMenuItem(value: null, child: Text('Tümü')),
          ...values.map((item) => DropdownMenuItem(
              value: item, child: Text(item, overflow: TextOverflow.ellipsis)))
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildErpFilters() {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 900;
      final fieldWidth = isMobile ? constraints.maxWidth - 40 : 240.0;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE0E6EF)))),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
                width: isMobile ? fieldWidth : 360,
                child: SizedBox(
                    height: 42,
                    child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'Model Ara',
                            hintText: 'Marka, item no, model adı',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true),
                        onChanged: (value) => setState(() => arama = value)))),
            SizedBox(
                width: fieldWidth,
                child: _buildFilterDropdown(
                    label: 'Marka',
                    value: seciliMarka,
                    values: markalar.toList()..sort(),
                    onChanged: (value) => setState(() => seciliMarka = value))),
            SizedBox(
                width: fieldWidth,
                child: _buildFilterDropdown(
                    label: 'Model',
                    value: seciliModelAdi,
                    values: modelAdlari.toList()..sort(),
                    onChanged: (value) =>
                        setState(() => seciliModelAdi = value))),
            SizedBox(
                width: fieldWidth,
                child: _buildFilterDropdown(
                    label: 'Durum',
                    value: seciliDurum,
                    values: durumOptions.where((d) => d != 'Tümü').toList(),
                    onChanged: (value) => setState(() => seciliDurum = value))),
            SizedBox(
                width: fieldWidth,
                child: _buildFilterDropdown(
                    label: 'Renk',
                    value: seciliRenk,
                    values: renkler.toList()..sort(),
                    onChanged: (value) => setState(() => seciliRenk = value))),
            SizedBox(
                width: fieldWidth,
                child: _buildFilterDropdown(
                    label: 'Cinsiyet',
                    value: seciliCinsiyet,
                    values: cinsiyetler.toList()..sort(),
                    onChanged: (value) =>
                        setState(() => seciliCinsiyet = value))),
            SizedBox(
                width: fieldWidth,
                child: SizedBox(
                    height: 42,
                    child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Siralama',
                            border: OutlineInputBorder(),
                            isDense: true),
                        initialValue: seciliSiralama,
                        isExpanded: true,
                        items: siralamaOptions
                            .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => seciliSiralama = value);
                        }))),
            OutlinedButton.icon(
                onPressed: _aktifFiltreVar ? _filtreleriTemizle : null,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Filtreleri Temizle'),
                style: OutlinedButton.styleFrom(
                    fixedSize: const Size(170, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)))),
            SizedBox(
                width: isMobile ? fieldWidth : 160,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Checkbox(value: tumunuSec, onChanged: tumunuSecToggle),
                  const Expanded(
                      child: Text('Tümünü seç',
                          style: TextStyle(fontWeight: FontWeight.w600)))
                ])),
          ],
        ),
      );
    });
  }

  Widget _headerCell(String text) => Text(text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 12, color: Color(0xFF455A64), fontWeight: FontWeight.w800));

  Widget _textCell(dynamic value, {bool strong = false}) =>
      Text(value?.toString() ?? '-',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF263238),
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500));

  Widget _modelCell(Map<String, dynamic> model, {int nameLines = 1}) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model['item_no']?.toString() ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43))),
            if ((model['model_adi']?.toString() ?? '').isNotEmpty)
              Text(model['model_adi'].toString(),
                  maxLines: nameLines,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF607D8B))),
          ]);

  Widget _terminCell(Map<String, dynamic> model) {
    final gecikti = _geciktiMi(model);
    final text = formatTarih(model['termin_tarihi']);
    return Row(children: [
      Icon(gecikti ? Icons.priority_high : Icons.event,
          size: 16,
          color: gecikti ? const Color(0xFFC62828) : const Color(0xFF607D8B)),
      const SizedBox(width: 4),
      Expanded(
          child: Text(text.isEmpty ? '-' : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: gecikti
                      ? const Color(0xFFC62828)
                      : const Color(0xFF263238),
                  fontWeight: gecikti ? FontWeight.w800 : FontWeight.w500))),
    ]);
  }

  Widget _durumBadge(Map<String, dynamic> model) {
    final color = _getDurumRengi(model['durum']);
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(model['durum']?.toString() ?? 'Beklemede',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800))));
  }

  Widget _rowActions(Map<String, dynamic> model) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Tooltip(
          message: 'Kritikler',
          child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 20),
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => ModelKritikleriDialog(
                      modelId: model['id'],
                      modelMarka: model['marka'] ?? 'Bilinmeyen',
                      modelItemNo: model['item_no'] ?? 'Bilinmeyen')))),
      if (isAdmin || currentUserRole == 'admin') ...[
        Tooltip(
            message: 'Kopyala',
            child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, color: Colors.green, size: 20),
                onPressed: () => modelKopyala(
                    model['id'], model['marka'], model['item_no']))),
        Tooltip(
            message: 'Düzenle',
            child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ModelDuzenlePage(
                            modelId: model['id'].toString(),
                            modelData: model))))),
        Tooltip(
            message: 'Sil',
            child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () =>
                    modelSil(model['id'], model['marka'], model['item_no']))),
      ],
    ]);
  }

  Widget _buildMobileModelCard(Map<String, dynamic> model) {
    final secili = seciliIdler.contains(model['id'].toString());
    final renk = _renkMetni(model);
    final adet = NumberFormat.decimalPattern('tr_TR')
        .format(_intDeger(model['toplam_adet'] ?? model['adet']));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: secili ? const Color(0xFFE8F1FE) : Colors.white,
          border: Border.all(color: const Color(0xFFE0E6EF)),
          borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _modelDetayAc(model),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(
                width: 32,
                child: Checkbox(
                    value: secili,
                    onChanged: (_) => _modelSeciminiDegistir(model))),
            const SizedBox(width: 8),
            Expanded(child: _modelCell(model, nameLines: 3)),
            const SizedBox(width: 8),
            _durumBadge(model),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _miniErpBilgi('Marka', model['marka']?.toString() ?? '-'),
            _miniErpBilgi('Renk', renk),
            _miniErpBilgi('Adet', adet),
            _miniErpBilgi('Termin', formatTarih(model['termin_tarihi'])),
          ]),
          const SizedBox(height: 10),
          Row(children: [Expanded(child: _rowActions(model))]),
        ]),
      ),
    );
  }

  Widget _miniErpBilgi(String label, String value) {
    return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 92, maxWidth: 220),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF607D8B))),
              const SizedBox(height: 2),
              Text(value.isEmpty ? '-' : value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF102A43))),
            ]));
  }

  Widget _buildErpTable(List<Map<String, dynamic>> liste) {
    if (yukleniyor) return const LoadingWidget();
    if (liste.isEmpty) {
      return const Center(
          child: Text('Henüz model bulunmuyor.',
              style: TextStyle(fontSize: 16, color: Colors.grey)));
    }
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: liste.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildMobileModelCard(liste[index]));
      }
      return Column(children: [
        Container(
            height: 42,
            color: const Color(0xFFEEF3F8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const SizedBox(width: 42),
              Expanded(flex: 20, child: _headerCell('Model')),
              Expanded(flex: 14, child: _headerCell('Marka')),
              Expanded(flex: 12, child: _headerCell('Renk')),
              Expanded(flex: 10, child: _headerCell('Adet')),
              Expanded(flex: 12, child: _headerCell('Termin')),
              Expanded(flex: 12, child: _headerCell('Durum')),
              SizedBox(width: 146, child: _headerCell('İşlem')),
            ])),
        Expanded(
            child: ListView.separated(
                itemCount: liste.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE7ECF2)),
                itemBuilder: (context, index) {
                  final model = liste[index];
                  final secili = seciliIdler.contains(model['id'].toString());
                  final gecikti = _geciktiMi(model);
                  final rowColor = secili
                      ? const Color(0xFFE8F1FE)
                      : gecikti
                          ? const Color(0xFFFFF4F4)
                          : index.isEven
                              ? Colors.white
                              : const Color(0xFFFAFBFD);
                  return Material(
                      color: rowColor,
                      child: InkWell(
                          onTap: () => _modelDetayAc(model),
                          child: Container(
                              constraints: const BoxConstraints(minHeight: 56),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Row(children: [
                                SizedBox(
                                    width: 42,
                                    child: Checkbox(
                                        value: secili,
                                        onChanged: (_) =>
                                            _modelSeciminiDegistir(model))),
                                Expanded(flex: 20, child: _modelCell(model)),
                                Expanded(
                                    flex: 14,
                                    child: _textCell(model['marka'] ?? '-')),
                                Expanded(
                                    flex: 12,
                                    child: _textCell(_renkMetni(model))),
                                Expanded(
                                    flex: 10,
                                    child: _textCell(
                                        NumberFormat.decimalPattern('tr_TR')
                                            .format(_intDeger(
                                                model['toplam_adet'] ??
                                                    model['adet'])),
                                        strong: true)),
                                Expanded(flex: 12, child: _terminCell(model)),
                                Expanded(flex: 12, child: _durumBadge(model)),
                                SizedBox(width: 146, child: _rowActions(model)),
                              ]))));
                })),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final seciliModelSayisi = seciliIdler.length;
    final liste = filtreliModeller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TexPilot'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (seciliModelSayisi > 0) ...[
            _buildTopluIslemMenu(seciliModelSayisi),
            const SizedBox(width: 8)
          ],
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: modelleriGetir),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(children: [
                _buildErpSummary(liste),
                _buildErpFilters(),
                SizedBox(
                  height: constraints.maxHeight,
                  child: _buildErpTable(liste),
                ),
              ]),
            ),
          );
        },
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
