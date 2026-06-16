import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/fatura_kalemi_model.dart';
import 'package:uretim_takip/models/fatura_model.dart';
import 'package:uretim_takip/models/uyumsoft_gelen_fatura_model.dart';
import 'package:uretim_takip/services/fatura_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/services/user_role_service.dart';

class UyumsoftFaturaService {
  UyumsoftFaturaService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static String get _firmaId => TenantManager.instance.requireFirmaId;

  static bool _tabloEksikMi(Object error) {
    final text = error.toString();
    return text.contains('PGRST205') ||
        text.contains('Could not find the table') ||
        text.contains(DbTables.uyumsoftGelenFaturalar);
  }

  static Exception _migrationHatasi() {
    return Exception(
      'Uyumsoft gelen fatura tabloları bulunamadı. '
      'Supabase migration dosyasını çalıştırın: '
      'supabase/migrations/20260616000300_uyumsoft_gelen_faturalar.sql',
    );
  }

  static String _apiHatasiniTemizle(Object error) {
    final text = error.toString();
    if (text.contains('uyumsoft_yetki_yok') ||
        text.contains('gerekli yetkiniz yok') ||
        text.contains('yetkiniz yok')) {
      return 'Uyumsoft entegrasyon yetkisi yok. Uyumsoft portalında API/web servis yetkisini ve gerekiyorsa IP erişim iznini aktif edin.';
    }
    return text
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<void> _adminYetkisiniDogrula() async {
    final adminMi = TenantManager.instance.isFirmaAdmin ||
        await UserRoleService.kullaniciHerhangiBirRoleSahipMi(
          const ['admin', 'firma_admin', 'firma_sahibi'],
        );
    if (!adminMi) {
      throw Exception('Bu işlem için admin yetkisi gerekir.');
    }
  }

  static Future<int> apiIleSenkronizeEt() async {
    await _adminYetkisiniDogrula();
    try {
      final response = await _client.functions.invoke(
        'uyumsoft-gelen-faturalar-sync',
        body: {'firma_id': _firmaId},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final sayi = data['aktarilan'] ?? data['count'] ?? 0;
        return sayi is num ? sayi.toInt() : 0;
      }
      final mesaj = data is Map ? data['error']?.toString() : null;
      final code = data is Map ? data['code']?.toString() : null;
      if (code == 'uyumsoft_yetki_yok') {
        throw Exception(_apiHatasiniTemizle(mesaj ?? code!));
      }
      throw Exception(mesaj ?? 'Uyumsoft API senkronizasyonu tamamlanamadı.');
    } catch (e) {
      throw Exception(
        'Uyumsoft API senkronizasyon hatası: ${_apiHatasiniTemizle(e)}',
      );
    }
  }

  static Future<UyumsoftGelenFatura> xmlUblDosyasiYukle() async {
    await _adminYetkisiniDogrula();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xml', 'ubl'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('Dosya seçilmedi.');
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Dosya okunamadı.');
    }
    final xml = utf8.decode(bytes, allowMalformed: true);
    return xmlUblYukleVeCozumle(xml, dosyaAdi: file.name);
  }

  static Future<UyumsoftGelenFatura> xmlUblYukleVeCozumle(
    String xml, {
    String? dosyaAdi,
  }) async {
    await _adminYetkisiniDogrula();
    final parsed = _parseUblXml(xml, dosyaAdi: dosyaAdi);
    try {
      final upserted = await _client
          .from(DbTables.uyumsoftGelenFaturalar)
          .upsert(parsed.ustVeri, onConflict: 'firma_id,kaynak,ettn')
          .select('id')
          .single();
      final gelenFaturaId = upserted['id'].toString();

      await _client
          .from(DbTables.uyumsoftGelenFaturaKalemleri)
          .delete()
          .eq('firma_id', _firmaId)
          .eq('gelen_fatura_id', gelenFaturaId);

      if (parsed.kalemler.isNotEmpty) {
        await _client.from(DbTables.uyumsoftGelenFaturaKalemleri).insert(
              parsed.kalemler
                  .map((kalem) => kalem.toInsertMap(gelenFaturaId, _firmaId))
                  .toList(),
            );
      }

      final kayitlar = await bekleyenleriGetir(durum: null);
      return kayitlar.firstWhere((item) => item.id == gelenFaturaId);
    } catch (e) {
      if (_tabloEksikMi(e)) throw _migrationHatasi();
      rethrow;
    }
  }

  static Future<List<UyumsoftGelenFatura>> bekleyenleriGetir({
    String? durum = 'beklemede',
  }) async {
    try {
      var query = _client
          .from(DbTables.uyumsoftGelenFaturalar)
          .select('*, ${DbTables.uyumsoftGelenFaturaKalemleri}(*)')
          .eq('firma_id', _firmaId);
      if (durum != null && durum.isNotEmpty) {
        query = query.eq('durum', durum);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .whereType<Map<String, dynamic>>()
          .map(UyumsoftGelenFatura.fromJson)
          .toList();
    } catch (e) {
      if (_tabloEksikMi(e)) throw _migrationHatasi();
      throw Exception('Uyumsoft gelen faturalar yüklenemedi: $e');
    }
  }

  static Future<int> gelenFaturaOnayla(String gelenFaturaId) async {
    await _adminYetkisiniDogrula();
    try {
      final response = await _client
          .from(DbTables.uyumsoftGelenFaturalar)
          .select('*, ${DbTables.uyumsoftGelenFaturaKalemleri}(*)')
          .eq('firma_id', _firmaId)
          .eq('id', gelenFaturaId)
          .single();
      final gelen = UyumsoftGelenFatura.fromJson(response);

      if (gelen.faturaId != null) return gelen.faturaId!;
      if (gelen.durum == 'reddedildi') {
        throw Exception('Reddedilen fatura onaylanamaz.');
      }

      final tedarikciId =
          gelen.tedarikciId ?? await _tedarikciIdBul(gelen.vergiNo);
      final faturaNo = await _benzersizFaturaNo(gelen.faturaNo, gelen.ettn);
      final fatura = FaturaModel(
        faturaNo: faturaNo,
        faturaTuru: 'alis',
        faturaTarihi: gelen.faturaTarihi,
        tedarikciId: tedarikciId,
        cariUnvan: gelen.cariUnvan,
        faturaAdres: gelen.faturaAdres ?? '',
        vergiDairesi: gelen.vergiDairesi,
        vergiNo: gelen.vergiNo,
        araToplamTutar: gelen.araToplamTutar,
        kdvTutari: gelen.kdvTutari,
        toplamTutar: gelen.toplamTutar,
        durum: 'taslak',
        aciklama: 'Uyumsoft gelen fatura aktarımı. ETTN: ${gelen.ettn}',
        odemeDurumu: 'odenmedi',
        odenenTutar: 0,
        kur: gelen.paraBirimi,
        kurOrani: 1,
        efatturaUuid: gelen.ettn,
        efaturaTarihi: gelen.faturaTarihi,
        efaturaDurum: 'uyumsoft_aktarildi',
        olusturmaTarihi: DateTime.now(),
        olusturanKullanici: _client.auth.currentUser?.email ??
            _client.auth.currentUser?.id ??
            '',
        firmaId: _firmaId,
      );

      final kalemler = gelen.kalemler.map((kalem) {
        return FaturaKalemiModel(
          faturaId: 0,
          siraNo: kalem.siraNo,
          kategori: kalem.kategori,
          urunKodu: kalem.urunKodu,
          urunAdi: kalem.urunAdi,
          aciklama: kalem.aciklama,
          miktar: kalem.miktar,
          birim: kalem.birim,
          birimFiyat: kalem.birimFiyat,
          iskonto: kalem.iskontoOrani,
          iskontoTutar: kalem.iskontoTutari,
          kdvOrani: kalem.kdvOrani,
          kdvTutar: kalem.kdvTutari,
          satirTutar: kalem.toplamTutar,
          olusturmaTarihi: DateTime.now(),
          firmaId: _firmaId,
        );
      }).toList();

      final faturaId = await FaturaService.faturaEkle(fatura, kalemler);
      await _client
          .from(DbTables.uyumsoftGelenFaturalar)
          .update({
            'durum': 'aktarildi',
            'fatura_id': faturaId,
            'tedarikci_id': tedarikciId,
            'onaylayan_user_id': _client.auth.currentUser?.id,
            'onay_tarihi': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', _firmaId)
          .eq('id', gelenFaturaId);
      return faturaId;
    } catch (e) {
      if (_tabloEksikMi(e)) throw _migrationHatasi();
      rethrow;
    }
  }

  static Future<void> gelenFaturaReddet(
    String gelenFaturaId, {
    String? sebep,
  }) async {
    await _adminYetkisiniDogrula();
    try {
      await _client
          .from(DbTables.uyumsoftGelenFaturalar)
          .update({
            'durum': 'reddedildi',
            'red_sebebi': sebep,
            'onaylayan_user_id': _client.auth.currentUser?.id,
            'onay_tarihi': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firma_id', _firmaId)
          .eq('id', gelenFaturaId);
    } catch (e) {
      if (_tabloEksikMi(e)) throw _migrationHatasi();
      rethrow;
    }
  }

  static Future<int?> _tedarikciIdBul(String? vergiNo) async {
    final temizVergiNo = vergiNo?.trim();
    if (temizVergiNo == null || temizVergiNo.isEmpty) return null;
    try {
      final response = await _client
          .from(DbTables.tedarikciler)
          .select('id')
          .eq('firma_id', _firmaId)
          .eq('vergi_no', temizVergiNo)
          .maybeSingle();
      return (response?['id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static Future<String> _benzersizFaturaNo(String faturaNo, String ettn) async {
    final temizNo = faturaNo.trim().isEmpty ? 'UYUMSOFT' : faturaNo.trim();
    try {
      final mevcut = await _client
          .from(DbTables.faturalar)
          .select('fatura_id')
          .eq('fatura_no', temizNo)
          .maybeSingle();
      if (mevcut == null) return temizNo;
    } catch (_) {
      return temizNo;
    }

    final ek = ettn.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final suffix = ek.length > 6 ? ek.substring(ek.length - 6) : ek;
    return '$temizNo-UYS$suffix';
  }

  static _ParsedUbl _parseUblXml(String xml, {String? dosyaAdi}) {
    final supplier = _section(xml, 'AccountingSupplierParty');
    final taxTotal = _section(xml, 'TaxTotal');
    final monetaryTotal = _section(xml, 'LegalMonetaryTotal');
    final faturaNo = _text(xml, 'ID') ?? dosyaAdi ?? 'Uyumsoft Fatura';
    final faturaTarihi =
        DateTime.tryParse(_text(xml, 'IssueDate') ?? '') ?? DateTime.now();
    final araToplam = _money(_text(monetaryTotal, 'TaxExclusiveAmount')) ??
        _money(_text(monetaryTotal, 'LineExtensionAmount')) ??
        0;
    final kdvTutari = _money(_text(taxTotal, 'TaxAmount')) ?? 0;
    final toplamTutar = _money(_text(monetaryTotal, 'PayableAmount')) ??
        _money(_text(monetaryTotal, 'TaxInclusiveAmount')) ??
        araToplam + kdvTutari;
    final ettn = _text(xml, 'UUID') ??
        'XML-$faturaNo-${faturaTarihi.toIso8601String()}-$toplamTutar';

    final kalemler = _lineSections(xml).asMap().entries.map((entry) {
      final index = entry.key + 1;
      final line = entry.value;
      final item = _section(line, 'Item');
      final price = _section(line, 'Price');
      final lineTax = _section(line, 'TaxTotal');
      final miktar = _money(_text(line, 'InvoicedQuantity')) ?? 1;
      final toplam = _money(_text(line, 'LineExtensionAmount')) ?? 0;
      final birimFiyat = _money(_text(price, 'PriceAmount')) ??
          (miktar == 0 ? toplam : toplam / miktar);
      final kdv = _money(_text(lineTax, 'TaxAmount')) ?? 0;
      final kdvOrani = _money(_text(line, 'Percent')) ?? 20;
      final urunAdi = _text(item, 'Name') ?? 'Fatura kalemi $index';
      final aciklama = _text(line, 'Note');
      final kategori = _kategoriTahminEt('$urunAdi ${aciklama ?? ''}');
      return UyumsoftGelenFaturaKalemi(
        siraNo: index,
        kategori: kategori,
        urunKodu: _text(_section(item, 'SellersItemIdentification'), 'ID'),
        urunAdi: urunAdi,
        aciklama: aciklama,
        miktar: miktar,
        birim: _attribute(line, 'InvoicedQuantity', 'unitCode') ?? 'adet',
        birimFiyat: birimFiyat,
        kdvOrani: kdvOrani,
        kdvTutari: kdv,
        toplamTutar: toplam + kdv,
      );
    }).toList();

    final ustVeri = {
      'firma_id': _firmaId,
      'kaynak': 'xml',
      'durum': 'beklemede',
      'ettn': ettn,
      'fatura_no': faturaNo,
      'fatura_tarihi': faturaTarihi.toIso8601String(),
      'senaryo': _text(xml, 'ProfileID') ?? _text(xml, 'InvoiceTypeCode'),
      'cari_unvan': _text(supplier, 'Name') ?? 'Bilinmeyen Tedarikçi',
      'vergi_no': _text(supplier, 'CompanyID'),
      'vergi_dairesi': _text(_section(supplier, 'TaxScheme'), 'Name'),
      'fatura_adres': _adresOlustur(supplier),
      'para_birimi': _attribute(monetaryTotal, 'PayableAmount', 'currencyID') ??
          _attribute(xml, 'DocumentCurrencyCode', 'currencyID') ??
          'TRY',
      'ara_toplam_tutar': araToplam,
      'kdv_tutari': kdvTutari,
      'toplam_tutar': toplamTutar,
      'ham_xml': xml,
      'ham_json': {
        'dosya_adi': dosyaAdi,
        'parse_tarihi': DateTime.now().toIso8601String(),
      },
      'updated_at': DateTime.now().toIso8601String(),
    };

    return _ParsedUbl(ustVeri: ustVeri, kalemler: kalemler);
  }

  static String _kategoriTahminEt(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('iplik')) return FaturaKategori.iplik;
    if (lower.contains('aksesuar') ||
        lower.contains('düğme') ||
        lower.contains('dugme') ||
        lower.contains('fermuar')) {
      return FaturaKategori.aksesuar;
    }
    if (lower.contains('fason') ||
        lower.contains('dikim') ||
        lower.contains('yıkama') ||
        lower.contains('yikama') ||
        lower.contains('nakış') ||
        lower.contains('nakis') ||
        lower.contains('ütü') ||
        lower.contains('utu')) {
      return FaturaKategori.fasonUretim;
    }
    if (lower.contains('nakliye') || lower.contains('kargo')) {
      return FaturaKategori.nakliye;
    }
    if (lower.contains('maaş') ||
        lower.contains('maas') ||
        lower.contains('personel')) {
      return FaturaKategori.personel;
    }
    if (lower.contains('kira') ||
        lower.contains('elektrik') ||
        lower.contains('su') ||
        lower.contains('doğalgaz') ||
        lower.contains('dogalgaz')) {
      return FaturaKategori.genelGider;
    }
    return FaturaKategori.diger;
  }

  static String? _text(String xml, String localName) {
    final pattern = RegExp(
      '<(?:[A-Za-z0-9_]+:)?$localName(?:\\s[^>]*)?>([\\s\\S]*?)</(?:[A-Za-z0-9_]+:)?$localName>',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(xml);
    if (match == null) return null;
    return _xmlDecode(
        match.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim());
  }

  static String? _attribute(String xml, String localName, String attrName) {
    final pattern = RegExp(
      '<(?:[A-Za-z0-9_]+:)?$localName\\s+[^>]*$attrName=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    return _xmlDecode(pattern.firstMatch(xml)?.group(1)?.trim());
  }

  static String _section(String xml, String localName) {
    final pattern = RegExp(
      '<(?:[A-Za-z0-9_]+:)?$localName(?:\\s[^>]*)?>([\\s\\S]*?)</(?:[A-Za-z0-9_]+:)?$localName>',
      caseSensitive: false,
    );
    return pattern.firstMatch(xml)?.group(1) ?? '';
  }

  static List<String> _lineSections(String xml) {
    final pattern = RegExp(
      '<(?:[A-Za-z0-9_]+:)?InvoiceLine(?:\\s[^>]*)?>([\\s\\S]*?)</(?:[A-Za-z0-9_]+:)?InvoiceLine>',
      caseSensitive: false,
    );
    return pattern
        .allMatches(xml)
        .map((match) => match.group(1) ?? '')
        .toList();
  }

  static double? _money(String? value) {
    if (value == null) return null;
    final raw = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (raw.isEmpty) return null;
    final lastComma = raw.lastIndexOf(',');
    final lastDot = raw.lastIndexOf('.');
    String normalized;
    if (lastComma >= 0 && lastDot >= 0) {
      final decimalSeparator = lastComma > lastDot ? ',' : '.';
      final thousandsSeparator = decimalSeparator == ',' ? '.' : ',';
      normalized = raw
          .replaceAll(thousandsSeparator, '')
          .replaceAll(decimalSeparator, '.');
    } else if (lastComma >= 0) {
      normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = raw;
    }
    return double.tryParse(normalized);
  }

  static String? _xmlDecode(String? value) {
    if (value == null || value.isEmpty) return value;
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  static String _adresOlustur(String supplier) {
    final parts = [
      _text(supplier, 'StreetName'),
      _text(supplier, 'BuildingName'),
      _text(supplier, 'BuildingNumber'),
      _text(supplier, 'CitySubdivisionName'),
      _text(supplier, 'CityName'),
      _text(supplier, 'PostalZone'),
      _text(supplier, 'Name'),
    ].where((item) => item != null && item.trim().isNotEmpty).cast<String>();
    return parts.join(' ');
  }
}

class _ParsedUbl {
  final Map<String, dynamic> ustVeri;
  final List<UyumsoftGelenFaturaKalemi> kalemler;

  const _ParsedUbl({required this.ustVeri, required this.kalemler});
}
