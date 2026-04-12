import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:flutter/foundation.dart';
import 'package:uretim_takip/models/puantaj_model.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

class PuantajService {
  final _client = Supabase.instance.client;
  String get _firmaId => TenantManager.instance.requireFirmaId;

  Future<List<PuantajModel>> getPuantajlar({int? ay, int? yil}) async {
    try {
      debugPrint('PuantajService.getPuantajlar: ay=$ay, yil=$yil');
      var query = _client.from(DbTables.puantaj).select().eq('firma_id', _firmaId);
      if (ay != null) query = query.eq('ay', ay);
      if (yil != null) query = query.eq('yil', yil);
      final response = await query.order('ad');
      debugPrint('PuantajService.getPuantajlar: ${(response as List).length} kayıt bulundu');
      return response.map((e) => PuantajModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('PuantajService.getPuantajlar HATA: $e');
      return [];
    }
  }

  Future<void> addPuantaj(PuantajModel p, {bool sendId = true}) async {
    final map = p.toMap();
    if (!sendId) {
      map.remove('id');
    }
    map['firma_id'] = _firmaId;
    await _client.from(DbTables.puantaj).insert(map);
  }

  Future<void> updatePuantaj(PuantajModel p) async {
    await _client.from(DbTables.puantaj).update(p.toMap()).eq('id', p.id);
  }

  Future<void> deletePuantaj(String id) async {
    await _client.from(DbTables.puantaj).delete().eq('id', id);
  }

  /// Otomatik puantaj oluşturur: izin, devamsızlık ve mesai kayıtlarından hesaplar
  Future<PuantajModel> otomatikPuantajOlustur({
    required String personelId,
    required String ad,
    required int ay,
    required int yil,
    required int gunlukCalismaSaati,
    required int toplamGun,
  }) async {
    // İzinler
    final izinler = await Supabase.instance.client
        .from(DbTables.izinler)
        .select()
        .eq('user_id', personelId)
        .eq('onay_durumu', 'onaylandi');
    int izinliGun = 0;
    int devamsizlikGun = 0;
    for (final izin in izinler) {
      final gunSayisi = (izin['gun_sayisi'] ?? 0);
      final gunInt = (gunSayisi is int) ? gunSayisi : int.tryParse(gunSayisi.toString()) ?? 0;
      if (izin['izin_turu'] == 'Yıllık İzin' || izin['izin_turu'] == 'Mazeret İzni') {
        izinliGun += gunInt;
      } else if (izin['izin_turu'] == 'Raporlu') {
        izinliGun += ((gunInt / 3).ceil());
        devamsizlikGun += (((gunInt * 2) / 3).ceil());
      } else if (izin['izin_turu'] == 'Ücretsiz İzin' || izin['izin_turu'] == 'Devamsızlık') {
        devamsizlikGun += gunInt;
      }
    }
    // Mesailer
    final mesailer = await Supabase.instance.client
        .from(DbTables.mesai)
        .select()
        .eq('user_id', personelId)
        .eq('onay_durumu', 'onaylandi');
    double toplamFazlaMesai = 0;
    for (final m in mesailer) {
      if (m['saat'] != null) {
        toplamFazlaMesai += double.tryParse(m['saat'].toString()) ?? 0;
      }
    }
    toplamFazlaMesai = double.parse(toplamFazlaMesai.toStringAsFixed(2));
    // Eksik gün hesaplama
    final int calisilanGun = toplamGun - izinliGun - devamsizlikGun;
    final int eksikGun = devamsizlikGun;
    final int aylikCalismaSaati = (calisilanGun * gunlukCalismaSaati).round();
    // PuantajModel oluştur
    return PuantajModel(
      id: '',
      personelId: personelId,
      ad: ad,
      ay: ay,
      yil: yil,
      gun: calisilanGun,
      calismaSaati: aylikCalismaSaati,
      fazlaMesai: toplamFazlaMesai.round(),
      eksikGun: eksikGun,
      devamsizlik: devamsizlikGun,
    );
  }
}
