import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/services/bildirim_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class YapilacakService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  String? get _userId => _client.auth.currentUser?.id;

  bool _tabloYokHatasi(Object error) {
    if (error is PostgrestException) {
      return error.code == 'PGRST205' ||
          error.message.contains(DbTables.yapilacaklar) ||
          error.message.contains(DbTables.yapilacakTamamlanmaKayitlari);
    }
    return false;
  }

  Exception _migrationEksikHatasi() {
    return Exception(
      'Yapılacaklar tablosu bulunamadı. Supabase migration dosyasını çalıştırın.',
    );
  }

  Future<List<Map<String, dynamic>>> getGecerliYapilacaklar({
    String? periyot,
    String kapsam = 'tumu',
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final dynamic response;
    try {
      var query = _client
          .from(DbTables.yapilacaklar)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('durum', 'aktif');

      if (periyot != null && periyot != 'tumu') {
        query = query.eq('periyot', periyot);
      }

      response = await query.order('created_at', ascending: false);
    } catch (e) {
      if (_tabloYokHatasi(e)) return [];
      rethrow;
    }
    final kayitlar = List<Map<String, dynamic>>.from(response).where((item) {
      final itemKapsam = item['kapsam']?.toString() ?? 'kisisel';
      final olusturan = item['olusturan_user_id']?.toString();
      final atanan = item['atanan_user_id']?.toString();

      if (itemKapsam == 'kisisel' && olusturan != userId) return false;
      if (itemKapsam == 'atanan' && atanan != userId && olusturan != userId) {
        return false;
      }
      if (kapsam == 'kisisel') return itemKapsam == 'kisisel';
      if (kapsam == 'firma') return itemKapsam == 'firma';
      return true;
    }).toList();

    final donemAnahtarlari = <String, String>{
      for (final item in kayitlar)
        item['id'].toString(): donemAnahtari(item['periyot']?.toString())
    };

    final dynamic tamamlanmaResponse;
    try {
      tamamlanmaResponse = await _client
          .from(DbTables.yapilacakTamamlanmaKayitlari)
          .select('yapilacak_id, donem_anahtari, tamamlandi')
          .eq('firma_id', _firmaId)
          .eq('user_id', userId);
    } catch (e) {
      if (_tabloYokHatasi(e)) return [];
      rethrow;
    }
    final tamamlanmalar = List<Map<String, dynamic>>.from(tamamlanmaResponse);

    return kayitlar.map((item) {
      final id = item['id'].toString();
      final donem = donemAnahtarlari[id]!;
      final tamamlandi = tamamlanmalar.any(
        (t) =>
            t['yapilacak_id']?.toString() == id &&
            t['donem_anahtari']?.toString() == donem &&
            t['tamamlandi'] == true,
      );
      return {
        ...item,
        'donem_anahtari': donem,
        'gecerli_donem_tamamlandi': tamamlandi,
      };
    }).toList();
  }

  Future<int> tamamlanmamisSayisi() async {
    final list = await getGecerliYapilacaklar();
    return list
        .where((item) => item['gecerli_donem_tamamlandi'] != true)
        .length;
  }

  Future<void> yapilacakEkle({
    required String baslik,
    String? aciklama,
    required String kapsam,
    required String periyot,
    String oncelik = 'normal',
    DateTime? hatirlaticiTarihi,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Oturum bulunamadı');

    try {
      await _client.from(DbTables.yapilacaklar).insert({
        'firma_id': _firmaId,
        'baslik': baslik.trim(),
        'aciklama': aciklama?.trim(),
        'kapsam': kapsam,
        'olusturan_user_id': userId,
        'periyot': periyot,
        'durum': 'aktif',
        'oncelik': oncelik,
        'hatirlatici_tarihi': hatirlaticiTarihi?.toIso8601String(),
      });
    } catch (e) {
      if (_tabloYokHatasi(e)) throw _migrationEksikHatasi();
      rethrow;
    }
  }

  Future<void> yapilacakGuncelle({
    required String id,
    required String baslik,
    String? aciklama,
    required String kapsam,
    required String periyot,
    String oncelik = 'normal',
    DateTime? hatirlaticiTarihi,
  }) async {
    try {
      await _client
          .from(DbTables.yapilacaklar)
          .update({
            'baslik': baslik.trim(),
            'aciklama': aciklama?.trim(),
            'kapsam': kapsam,
            'periyot': periyot,
            'oncelik': oncelik,
            'hatirlatici_tarihi': hatirlaticiTarihi?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', _firmaId)
          .eq('id', id);
    } catch (e) {
      if (_tabloYokHatasi(e)) throw _migrationEksikHatasi();
      rethrow;
    }
  }

  Future<void> yapilacakSil(String id) async {
    try {
      await _client
          .from(DbTables.yapilacaklar)
          .update({
            'durum': 'iptal',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', _firmaId)
          .eq('id', id);
    } catch (e) {
      if (_tabloYokHatasi(e)) throw _migrationEksikHatasi();
      rethrow;
    }
  }

  Future<void> donemTamamla(Map<String, dynamic> yapilacak) async {
    final userId = _userId;
    if (userId == null) throw Exception('Oturum bulunamadı');

    final yapilacakId = yapilacak['id']?.toString();
    if (yapilacakId == null || yapilacakId.isEmpty) return;

    final donem = yapilacak['donem_anahtari']?.toString() ??
        donemAnahtari(yapilacak['periyot']?.toString());
    final tamamlandi = yapilacak['gecerli_donem_tamamlandi'] == true;

    try {
      await _client.from(DbTables.yapilacakTamamlanmaKayitlari).upsert(
        {
          'firma_id': _firmaId,
          'yapilacak_id': yapilacakId,
          'user_id': userId,
          'donem_anahtari': donem,
          'tamamlandi': !tamamlandi,
          'tamamlanma_tarihi':
              !tamamlandi ? DateTime.now().toIso8601String() : null,
        },
        onConflict: 'firma_id,yapilacak_id,user_id,donem_anahtari',
      );
    } catch (e) {
      if (_tabloYokHatasi(e)) throw _migrationEksikHatasi();
      rethrow;
    }
  }

  Future<void> hatirlaticilariKontrolEt() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final response = await _client
          .from(DbTables.yapilacaklar)
          .select('*')
          .eq('firma_id', _firmaId)
          .eq('durum', 'aktif')
          .lte('hatirlatici_tarihi', now.toIso8601String());

      final kayitlar = List<Map<String, dynamic>>.from(response);
      for (final item in kayitlar) {
        final kapsam = item['kapsam']?.toString() ?? 'kisisel';
        final olusturan = item['olusturan_user_id']?.toString();
        final atanan = item['atanan_user_id']?.toString();
        if (kapsam == 'kisisel' && olusturan != userId) continue;
        if (kapsam == 'atanan' && atanan != userId && olusturan != userId) {
          continue;
        }

        final donem = donemAnahtari(item['periyot']?.toString());
        final eventKey = 'yapilacak:${item['id']}:$donem';
        await BildirimService().bildirimGonder(
          userId: userId,
          baslik: 'Yapılacak Hatırlatıcı',
          mesaj: item['baslik']?.toString() ?? 'Yapılacak iş zamanı geldi.',
          tip: 'yapilacak_hatirlatici',
          ekBilgi: {
            'target': {
              'type': 'yapilacak',
              'page': 'yapilacak_popup',
              'yapilacak_id': item['id'],
            },
          },
          eventKey: eventKey,
        );

        await _client
            .from(DbTables.yapilacaklar)
            .update({'son_hatirlatma_tarihi': now.toIso8601String()})
            .eq('firma_id', _firmaId)
            .eq('id', item['id']);
      }
    } catch (e) {
      if (_tabloYokHatasi(e)) return;
      debugPrint('Yapılacak hatırlatıcı kontrol hatası: $e');
    }
  }

  static String donemAnahtari(String? periyot, {DateTime? tarih}) {
    final date = tarih ?? DateTime.now();
    switch (periyot) {
      case 'haftalik':
        final iso = _isoWeek(date);
        return '${iso.year}-W${iso.week.toString().padLeft(2, '0')}';
      case 'aylik':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'tek_seferlik':
      case 'gunluk':
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  static ({int year, int week}) _isoWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
    final firstJanuaryThursday = DateTime(thursday.year, 1, 4);
    final firstWeekThursday = firstJanuaryThursday
        .add(Duration(days: 4 - firstJanuaryThursday.weekday));
    final week = 1 + (thursday.difference(firstWeekThursday).inDays ~/ 7);
    return (year: thursday.year, week: week);
  }
}
