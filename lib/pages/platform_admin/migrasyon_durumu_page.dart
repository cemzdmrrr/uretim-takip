import 'package:flutter/material.dart';
import 'package:uretim_takip/services/migration_service.dart';

class MigrasyonDurumuPage extends StatefulWidget {
  const MigrasyonDurumuPage({super.key});

  @override
  State<MigrasyonDurumuPage> createState() => _MigrasyonDurumuPageState();
}

class _MigrasyonDurumuPageState extends State<MigrasyonDurumuPage> {
  bool _yukleniyor = true;
  Map<String, dynamic>? _saglikRaporu;
  List<Map<String, dynamic>> _firmaIdKontrol = [];
  List<Map<String, dynamic>> _rlsKontrol = [];
  List<Map<String, dynamic>> _migrasyonAdimlari = [];
  String? _hata;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final sonuclar = await Future.wait([
        MigrationService.saglikRaporu(),
        MigrationService.firmaIdKontrol(),
        MigrationService.rlsKontrol(),
        MigrationService.migrasyonAdimlari(),
      ]);

      setState(() {
        _saglikRaporu = sonuclar[0] as Map<String, dynamic>;
        _firmaIdKontrol = sonuclar[1] as List<Map<String, dynamic>>;
        _rlsKontrol = sonuclar[2] as List<Map<String, dynamic>>;
        _migrasyonAdimlari = sonuclar[3] as List<Map<String, dynamic>>;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrasyon Durumu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(child: Text('Hata: $_hata'))
              : RefreshIndicator(
                  onRefresh: _verileriYukle,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSaglikKarti(),
                      const SizedBox(height: 16),
                      _buildMigrasyonAdimlari(),
                      const SizedBox(height: 16),
                      _buildFirmaIdKontrol(),
                      const SizedBox(height: 16),
                      _buildRlsKontrol(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSaglikKarti() {
    if (_saglikRaporu == null) return const SizedBox.shrink();

    final durum = _saglikRaporu!['saglik_durumu'] as String? ?? 'bilinmiyor';
    final renk = durum == 'saglikli'
        ? Colors.green
        : durum == 'uyari'
            ? Colors.orange
            : Colors.red;
    final ikon = durum == 'saglikli'
        ? Icons.check_circle
        : durum == 'uyari'
            ? Icons.warning
            : Icons.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ikon, color: renk, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Sistem Sağlığı: ${durum.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: renk,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSaglikSatir('Aktif Firma', _saglikRaporu!['aktif_firma_sayisi']),
            _buildSaglikSatir('Aktif Kullanıcı', _saglikRaporu!['aktif_kullanici_sayisi']),
            _buildSaglikSatir(
              'NULL firma_id Tablo',
              _saglikRaporu!['null_firma_id_tablo_sayisi'],
              kritik: (_saglikRaporu!['null_firma_id_tablo_sayisi'] as int? ?? 0) > 0,
            ),
            _buildSaglikSatir(
              'RLS Eksik Tablo',
              _saglikRaporu!['rls_eksik_tablo_sayisi'],
              kritik: (_saglikRaporu!['rls_eksik_tablo_sayisi'] as int? ?? 0) > 0,
            ),
            _buildSaglikSatir(
              'Firmaya Atanmamış Kullanıcı',
              _saglikRaporu!['firmaya_atanmamis_kullanici'],
              uyari: (_saglikRaporu!['firmaya_atanmamis_kullanici'] as int? ?? 0) > 0,
            ),
            _buildSaglikSatir(
              'Aboneliksiz Firma',
              _saglikRaporu!['aboneligi_olmayan_firma'],
              uyari: (_saglikRaporu!['aboneligi_olmayan_firma'] as int? ?? 0) > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaglikSatir(String etiket, dynamic deger, {bool kritik = false, bool uyari = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiket, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: kritik
                  ? Colors.red.shade50
                  : uyari
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$deger',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kritik ? Colors.red : uyari ? Colors.orange : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrasyonAdimlari() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Migrasyon Adımları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._migrasyonAdimlari.map((adim) {
              final durum = adim['durum'] as String? ?? 'beklemede';
              IconData ikon;
              Color renk;

              switch (durum) {
                case 'tamamlandi':
                  ikon = Icons.check_circle;
                  renk = Colors.green;
                  break;
                case 'baslatildi':
                  ikon = Icons.play_circle;
                  renk = Colors.blue;
                  break;
                case 'hata':
                  ikon = Icons.error;
                  renk = Colors.red;
                  break;
                case 'atlandi':
                  ikon = Icons.skip_next;
                  renk = Colors.grey;
                  break;
                default:
                  ikon = Icons.radio_button_unchecked;
                  renk = Colors.grey;
              }

              return ListTile(
                leading: Icon(ikon, color: renk),
                title: Text(adim['adim_adi'] ?? adim['adim_kodu'] ?? ''),
                subtitle: adim['hata_mesaji'] != null
                    ? Text(
                        adim['hata_mesaji'],
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      )
                    : null,
                trailing: adim['islem_sayisi'] != null && (adim['islem_sayisi'] as int) > 0
                    ? Chip(label: Text('${adim['islem_sayisi']} işlem'))
                    : null,
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmaIdKontrol() {
    final sorunluTablolar = _firmaIdKontrol
        .where((t) => (t['null_kayit_sayisi'] as int? ?? 0) > 0)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Firma ID Kontrol',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (sorunluTablolar.isEmpty)
                  const Chip(
                    label: Text('Temiz', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  )
                else
                  Chip(
                    label: Text('${sorunluTablolar.length} Sorunlu',
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (sorunluTablolar.isEmpty)
              const Text('Tüm tablolarda firma_id dolu.',
                  style: TextStyle(color: Colors.green))
            else
              ...sorunluTablolar.map(
                (t) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(t['tablo_adi'] ?? ''),
                  subtitle: Text('${t['null_kayit_sayisi']} / ${t['toplam_kayit']} kayıtta firma_id NULL'),
                  dense: true,
                ),
              ),
            const Divider(),
            const Text(
              'Tablo Veri Özeti',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._firmaIdKontrol
                .where((t) => (t['toplam_kayit'] as int? ?? 0) > 0)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t['tablo_adi'] ?? '', style: const TextStyle(fontSize: 13)),
                        Text('${t['toplam_kayit']}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRlsKontrol() {
    final eksikRls = _rlsKontrol.where((t) => t['rls_aktif'] != true).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'RLS (Row Level Security) Durumu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (eksikRls.isEmpty)
                  const Chip(
                    label: Text('Tümü Aktif', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  )
                else
                  Chip(
                    label: Text('${eksikRls.length} Eksik',
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (eksikRls.isEmpty)
              const Text('Tüm tablolarda RLS aktif.',
                  style: TextStyle(color: Colors.green))
            else
              ...eksikRls.map(
                (t) => ListTile(
                  leading: const Icon(Icons.shield, color: Colors.red),
                  title: Text(t['tablo_adi'] ?? ''),
                  subtitle: const Text('RLS aktif DEĞİL!'),
                  dense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
