import 'package:flutter/material.dart';
import 'package:uretim_takip/services/migration_service.dart';

class MigrasyonDurumuPage extends StatefulWidget {
  const MigrasyonDurumuPage({super.key});

  @override
  State<MigrasyonDurumuPage> createState() => _MigrasyonDurumuPageState();
}

class _MigrasyonDurumuPageState extends State<MigrasyonDurumuPage> {
  bool _yukleniyor = true;
  String? _hata;
  Map<String, dynamic>? _saglikRaporu;
  List<Map<String, dynamic>> _firmaIdKontrol = [];
  List<Map<String, dynamic>> _rlsKontrol = [];
  List<Map<String, dynamic>> _migrasyonAdimlari = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    if (mounted) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }

    try {
      final sonuclar = await Future.wait([
        MigrationService.saglikRaporu(),
        MigrationService.firmaIdKontrol(),
        MigrationService.rlsKontrol(),
        MigrationService.migrasyonAdimlari(),
      ]);

      if (!mounted) return;
      setState(() {
        _saglikRaporu = sonuclar[0] as Map<String, dynamic>;
        _firmaIdKontrol = sonuclar[1] as List<Map<String, dynamic>>;
        _rlsKontrol = sonuclar[2] as List<Map<String, dynamic>>;
        _migrasyonAdimlari = sonuclar[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Migrasyon Durumu'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
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
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHero(),
                      const SizedBox(height: 20),
                      _buildSaglikPaneli(),
                      const SizedBox(height: 20),
                      _buildMigrasyonAdimlari(),
                      const SizedBox(height: 20),
                      _buildFirmaIdKontrol(),
                      const SizedBox(height: 20),
                      _buildRlsKontrol(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHero() {
    final durum = _saglikRaporu?['saglik_durumu']?.toString() ?? 'bilinmiyor';
    final renk = _durumRenk(durum);
    final nullFirma =
        (_saglikRaporu?['null_firma_id_tablo_sayisi'] as int?) ?? 0;
    final eksikRls = (_saglikRaporu?['rls_eksik_tablo_sayisi'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _darken(renk, 0.20),
            renk,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistem Sağlığı: ${_durumEtiketi(durum)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tenant migrasyonu, veri bütünlüğü ve RLS eksikleri bu ekranda izlenir.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _heroStat(
                'Aktif firma',
                '${_saglikRaporu?['aktif_firma_sayisi'] ?? 0}',
                Icons.business_outlined,
              ),
              _heroStat(
                'Aktif kullanıcı',
                '${_saglikRaporu?['aktif_kullanici_sayisi'] ?? 0}',
                Icons.people_outline,
              ),
              _heroStat(
                'NULL firma_id',
                '$nullFirma',
                Icons.warning_amber_outlined,
              ),
              _heroStat(
                'Eksik RLS',
                '$eksikRls',
                Icons.shield_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaglikPaneli() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _kpiBox(
            'Aktif Firma',
            '${_saglikRaporu?['aktif_firma_sayisi'] ?? 0}',
            const Color(0xFF2563EB),
          ),
          _kpiBox(
            'Aktif Kullanıcı',
            '${_saglikRaporu?['aktif_kullanici_sayisi'] ?? 0}',
            const Color(0xFF15803D),
          ),
          _kpiBox(
            'Firmaya Atanmamış Kullanıcı',
            '${_saglikRaporu?['firmaya_atanmamis_kullanici'] ?? 0}',
            const Color(0xFFD97706),
          ),
          _kpiBox(
            'Aboneliksiz Firma',
            '${_saglikRaporu?['aboneligi_olmayan_firma'] ?? 0}',
            const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _kpiBox(String label, String value, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrasyonAdimlari() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Migrasyon Adımları',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          ..._migrasyonAdimlari.map((adim) {
            final durum = adim['durum']?.toString() ?? 'beklemede';
            final renk = _adimRenk(durum);
            final ikon = _adimIkonu(durum);
            final hataMesaji = adim['hata_mesaji']?.toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: renk.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(ikon, color: renk),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adim['adim_adi']?.toString() ??
                              adim['adim_kodu']?.toString() ??
                              '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _adimEtiketi(durum),
                          style: TextStyle(
                              color: renk, fontWeight: FontWeight.w700),
                        ),
                        if (hataMesaji != null && hataMesaji.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            hataMesaji,
                            style: const TextStyle(color: Color(0xFFB91C1C)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (adim['islem_sayisi'] != null &&
                      (adim['islem_sayisi'] as int? ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${adim['islem_sayisi']} işlem',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFirmaIdKontrol() {
    final sorunlu = _firmaIdKontrol
        .where((item) => (item['null_kayit_sayisi'] as int? ?? 0) > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Firma ID Kontrolü',
            sorunlu.isEmpty ? 'Temiz' : '${sorunlu.length} sorunlu',
            sorunlu.isEmpty ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
          const SizedBox(height: 14),
          if (sorunlu.isEmpty)
            const Text(
              'Tüm tablolarda firma_id alanı dolu.',
              style: TextStyle(color: Color(0xFF15803D)),
            )
          else
            ...sorunlu.map(
              (item) => _issueTile(
                icon: Icons.warning_amber_outlined,
                color: const Color(0xFFB91C1C),
                title: item['tablo_adi']?.toString() ?? '-',
                subtitle:
                    '${item['null_kayit_sayisi']} / ${item['toplam_kayit']} kayıtta firma_id boş',
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Tablo Veri Özeti',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          ..._firmaIdKontrol
              .where((item) => (item['toplam_kayit'] as int? ?? 0) > 0)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(item['tablo_adi']?.toString() ?? '-')),
                      Text(
                        '${item['toplam_kayit']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildRlsKontrol() {
    final eksik =
        _rlsKontrol.where((item) => item['rls_aktif'] != true).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'RLS Durumu',
            eksik.isEmpty ? 'Tümü aktif' : '${eksik.length} eksik',
            eksik.isEmpty ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          ),
          const SizedBox(height: 14),
          if (eksik.isEmpty)
            const Text(
              'Tüm tablolarda RLS aktif.',
              style: TextStyle(color: Color(0xFF15803D)),
            )
          else
            ...eksik.map(
              (item) => _issueTile(
                icon: Icons.shield_outlined,
                color: const Color(0xFFB91C1C),
                title: item['tablo_adi']?.toString() ?? '-',
                subtitle: 'RLS aktif değil',
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String badge, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            badge,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _issueTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'saglikli':
        return const Color(0xFF15803D);
      case 'uyari':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFB91C1C);
    }
  }

  String _durumEtiketi(String durum) {
    switch (durum) {
      case 'saglikli':
        return 'Sağlıklı';
      case 'uyari':
        return 'Uyarı';
      default:
        return 'Kritik';
    }
  }

  IconData _adimIkonu(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return Icons.check_circle_outline;
      case 'baslatildi':
        return Icons.play_circle_outline;
      case 'hata':
        return Icons.error_outline;
      case 'atlandi':
        return Icons.skip_next_outlined;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _adimRenk(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return const Color(0xFF15803D);
      case 'baslatildi':
        return const Color(0xFF2563EB);
      case 'hata':
        return const Color(0xFFB91C1C);
      case 'atlandi':
      default:
        return const Color(0xFF64748B);
    }
  }

  String _adimEtiketi(String durum) {
    switch (durum) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'baslatildi':
        return 'Başlatıldı';
      case 'hata':
        return 'Hata';
      case 'atlandi':
        return 'Atlandı';
      default:
        return 'Beklemede';
    }
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
