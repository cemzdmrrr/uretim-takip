import 'package:flutter/material.dart';
import 'package:uretim_takip/services/yetki_service.dart';
import 'package:uretim_takip/services/tenant_manager.dart';

/// Rol bazlı yetki matrisi yönetimi.
/// Firma sahibi/admin burada her rolün modül yetkilerini düzenleyebilir.
class RolYetkiYonetimiPage extends StatefulWidget {
  const RolYetkiYonetimiPage({super.key});

  @override
  State<RolYetkiYonetimiPage> createState() => _RolYetkiYonetimiPageState();
}

class _RolYetkiYonetimiPageState extends State<RolYetkiYonetimiPage> {
  String _secilenRol = 'kullanici';
  List<Map<String, dynamic>> _varsayilanYetkiler = [];
  List<Map<String, dynamic>> _firmaYetkileri = [];
  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  // Modül listesi (aktif modüllerden)
  List<String> get _moduller {
    final aktif = TenantManager.instance.aktifModuller;
    return aktif.isNotEmpty
        ? aktif
        : ['uretim', 'finans', 'ik', 'stok', 'sevkiyat', 'tedarik', 'musteri', 'rapor', 'kalite', 'ayarlar'];
  }

  static const _modulEtiketleri = {
    'uretim': 'Üretim',
    'finans': 'Finans',
    'ik': 'İK',
    'stok': 'Stok',
    'sevkiyat': 'Sevkiyat',
    'tedarik': 'Tedarik',
    'musteri': 'Müşteri',
    'rapor': 'Rapor',
    'kalite': 'Kalite',
    'ayarlar': 'Ayarlar',
  };

  static const _modulIkonlari = {
    'uretim': Icons.precision_manufacturing,
    'finans': Icons.account_balance_wallet,
    'ik': Icons.people_alt,
    'stok': Icons.inventory_2,
    'sevkiyat': Icons.local_shipping,
    'tedarik': Icons.shopping_cart,
    'musteri': Icons.person_pin,
    'rapor': Icons.bar_chart,
    'kalite': Icons.verified,
    'ayarlar': Icons.settings,
  };

  static const _modulRenkleri = {
    'uretim': Colors.blue,
    'finans': Colors.green,
    'ik': Colors.orange,
    'stok': Colors.purple,
    'sevkiyat': Colors.teal,
    'tedarik': Colors.brown,
    'musteri': Colors.indigo,
    'rapor': Colors.cyan,
    'kalite': Colors.amber,
    'ayarlar': Colors.grey,
  };

  static const _yetkiEtiketleri = {
    'okuma': 'Okuma',
    'yazma': 'Yazma',
    'silme': 'Silme',
    'yonetim': 'Yönetim',
    'export': 'Dışa Aktar',
  };

  static const _yetkiAciklamalari = {
    'okuma': 'Verileri görüntüleme',
    'yazma': 'Yeni kayıt ekleme ve düzenleme',
    'silme': 'Kayıtları silme',
    'yonetim': 'Modül ayarlarını yönetme',
    'export': 'Verileri dışa aktarma',
  };

  static const _yetkiIkonlari = {
    'okuma': Icons.visibility,
    'yazma': Icons.edit,
    'silme': Icons.delete_outline,
    'yonetim': Icons.admin_panel_settings,
    'export': Icons.file_download,
  };

  static const _rolAciklamalari = {
    'yonetici': 'Departman yöneticisi — kendi bölümünde geniş yetki',
    'kullanici': 'Standart kullanıcı — günlük işlem yetkisi',
    'personel': 'Sınırlı erişim — sadece temel işlemler',
    'dokumaci': 'Dokuma üretim personeli',
    'konfeksiyoncu': 'Konfeksiyon üretim personeli',
    'kalite_kontrol': 'Kalite kontrol sorumlusu',
    'sofor': 'Sevkiyat şoförü',
    'muhasebeci': 'Muhasebe personeli',
    'depocu': 'Depo sorumlusu',
  };

  @override
  void initState() {
    super.initState();
    _yetkileriYukle();
  }

  Future<void> _yetkileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final varsayilan =
          await YetkiService.varsayilanYetkilerGetir(_secilenRol);
      final firma = await YetkiService.firmaYetkiTanimlariGetir();

      if (!mounted) return;
      setState(() {
        _varsayilanYetkiler = varsayilan;
        _firmaYetkileri = firma;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yetkiler yüklenirken hata: $e')),
      );
    }
  }

  bool _yetkiAktifMi(String modulKodu, String yetki) {
    final firmaYetki = _firmaYetkileri.where((y) =>
        y['rol'] == _secilenRol &&
        y['modul_kodu'] == modulKodu &&
        y['yetki'] == yetki);
    if (firmaYetki.isNotEmpty) {
      return firmaYetki.first['aktif'] == true;
    }

    final varsayilan = _varsayilanYetkiler.where((y) =>
        y['modul_kodu'] == modulKodu && y['yetki'] == yetki);
    if (varsayilan.isNotEmpty) {
      return varsayilan.first['aktif'] == true;
    }

    return false;
  }

  Future<void> _yetkiToggle(
      String modulKodu, String yetki, bool yeniDeger) async {
    setState(() => _kaydediliyor = true);
    try {
      await YetkiService.yetkiTanimla(
        rol: _secilenRol,
        modulKodu: modulKodu,
        yetki: yetki,
        aktif: yeniDeger,
      );
      await _yetkileriYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yetki kaydedilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  int _modulAktifYetkiSayisi(String modul) {
    return YetkiService.yetkiTurleri
        .where((y) => _yetkiAktifMi(modul, y))
        .length;
  }

  Future<void> _tumYetkileriAcKapat(String modul, bool aktif) async {
    setState(() => _kaydediliyor = true);
    try {
      for (final yetki in YetkiService.yetkiTurleri) {
        await YetkiService.yetkiTanimla(
          rol: _secilenRol,
          modulKodu: modul,
          yetki: yetki,
          aktif: aktif,
        );
      }
      await _yetkileriYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yetki kaydedilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roller = YetkiService.firmaRolleri
        .where((r) => r != 'firma_sahibi' && r != 'firma_admin')
        .followedBy(YetkiService.ozelRoller)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rol & Yetki Yönetimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bilgi banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Firma sahibi ve firma admini tüm yetkilere sahiptir. '
                    'Aşağıdan diğer rollerin yetkilerini düzenleyebilirsiniz.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Rol seçimi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rol Seçin',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: roller.map((r) {
                      final secili = r == _secilenRol;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(YetkiService.rolEtiketleri[r] ?? r),
                          selected: secili,
                          onSelected: (_) {
                            setState(() => _secilenRol = r);
                            _yetkileriYukle();
                          },
                          selectedColor: Colors.blue.shade100,
                          labelStyle: TextStyle(
                            color: secili ? Colors.blue.shade800 : null,
                            fontWeight: secili ? FontWeight.bold : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_rolAciklamalari.containsKey(_secilenRol)) ...[
                  const SizedBox(height: 8),
                  Text(
                    _rolAciklamalari[_secilenRol]!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (_kaydediliyor) const LinearProgressIndicator(),
          // Modül yetki kartları
          Expanded(
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _moduller.length,
                    itemBuilder: (_, i) => _modulYetkiKarti(_moduller[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _modulYetkiKarti(String modul) {
    final renk = _modulRenkleri[modul] ?? Colors.blueGrey;
    final ikon = _modulIkonlari[modul] ?? Icons.extension;
    final etiket = _modulEtiketleri[modul] ?? modul;
    final aktifSayisi = _modulAktifYetkiSayisi(modul);
    final toplamYetki = YetkiService.yetkiTurleri.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: renk.withValues(alpha: 0.15),
          child: Icon(ikon, color: renk, size: 20),
        ),
        title: Row(
          children: [
            Text(etiket, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: aktifSayisi == 0
                    ? Colors.red.shade50
                    : aktifSayisi == toplamYetki
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$aktifSayisi / $toplamYetki',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: aktifSayisi == 0
                      ? Colors.red.shade700
                      : aktifSayisi == toplamYetki
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: [
          // Tümünü aç/kapat
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _kaydediliyor
                    ? null
                    : () => _tumYetkileriAcKapat(modul, true),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Tümünü Aç', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _kaydediliyor
                    ? null
                    : () => _tumYetkileriAcKapat(modul, false),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label:
                    const Text('Tümünü Kapat', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          const Divider(height: 1),
          ...YetkiService.yetkiTurleri.map((yetki) {
            final aktif = _yetkiAktifMi(modul, yetki);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _yetkiIkonlari[yetki] ?? Icons.security,
                color: aktif ? renk : Colors.grey.shade400,
                size: 20,
              ),
              title: Text(
                _yetkiEtiketleri[yetki] ?? yetki,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: aktif ? null : Colors.grey,
                ),
              ),
              subtitle: Text(
                _yetkiAciklamalari[yetki] ?? '',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              trailing: Switch.adaptive(
                value: aktif,
                onChanged: _kaydediliyor
                    ? null
                    : (v) => _yetkiToggle(modul, yetki, v),
                activeColor: renk,
              ),
            );
          }),
        ],
      ),
    );
  }
}
