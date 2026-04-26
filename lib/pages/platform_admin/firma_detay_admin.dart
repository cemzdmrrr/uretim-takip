import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uretim_takip/services/platform_admin_service.dart';

class FirmaDetayAdminPage extends StatefulWidget {
  final String firmaId;

  const FirmaDetayAdminPage({super.key, required this.firmaId});

  @override
  State<FirmaDetayAdminPage> createState() => _FirmaDetayAdminPageState();
}

class _FirmaDetayAdminPageState extends State<FirmaDetayAdminPage> {
  bool _yukleniyor = true;
  bool _islemSuruyor = false;
  int _sekmeIndex = 0;

  Map<String, dynamic>? _firma;
  List<Map<String, dynamic>> _kullanicilar = [];
  List<Map<String, dynamic>> _moduller = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    if (mounted) {
      setState(() => _yukleniyor = true);
    }
    try {
      final sonuclar = await Future.wait([
        PlatformAdminService.firmaDetayGetir(widget.firmaId),
        PlatformAdminService.firmaKullanicilariGetir(widget.firmaId),
        PlatformAdminService.firmaModulleriGetir(widget.firmaId),
      ]);

      if (!mounted) return;
      setState(() {
        _firma = sonuclar[0] as Map<String, dynamic>?;
        _kullanicilar = List<Map<String, dynamic>>.from(sonuclar[1] as List);
        _moduller = List<Map<String, dynamic>>.from(sonuclar[2] as List);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firmaAdi = _firma?['firma_adi']?.toString() ?? 'Firma Detayı';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(firmaAdi),
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
          : _firma == null
              ? const Center(child: Text('Firma bulunamadı'))
              : RefreshIndicator(
                  onRefresh: _verileriYukle,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHero(),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _panelDecoration(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(
                                value: 0,
                                icon: Icon(Icons.info_outline),
                                label: Text('Genel Bilgi'),
                              ),
                              ButtonSegment(
                                value: 1,
                                icon: Icon(Icons.people_outline),
                                label: Text('Kullanıcılar'),
                              ),
                              ButtonSegment(
                                value: 2,
                                icon: Icon(Icons.grid_view_outlined),
                                label: Text('Modüller'),
                              ),
                            ],
                            selected: {_sekmeIndex},
                            onSelectionChanged: (selection) {
                              setState(() => _sekmeIndex = selection.first);
                            },
                            showSelectedIcon: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSelectedPanel(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHero() {
    final aktif = _firma?['aktif'] == true;
    final kayitTarihi =
        _formatDate(_firma?['created_at']?.toString(), withTime: true);
    final aktifModuller =
        _moduller.where((item) => item['aktif'] == true).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: aktif
              ? const [Color(0xFF1D4ED8), Color(0xFF3B82F6)]
              : const [Color(0xFF475569), Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _firma?['firma_adi']?.toString() ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _firma?['firma_kodu']?.toString() ?? '-',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _heroStat(
                  'Durum', aktif ? 'Aktif' : 'Pasif', Icons.approval_outlined),
              _heroStat('Kayıt', kayitTarihi, Icons.calendar_today_outlined),
              _heroStat(
                  'Kullanıcı', '${_kullanicilar.length}', Icons.people_outline),
              _heroStat(
                  'Aktif modül', '$aktifModuller', Icons.widgets_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _islemSuruyor ? null : () => _firmaDurumDegistir(!aktif),
                icon: Icon(
                    aktif ? Icons.block_outlined : Icons.check_circle_outline),
                label: Text(aktif ? 'Pasif Yap' : 'Aktif Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      aktif ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _islemSuruyor ? null : _firmaSilOnayDialogunuAc,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Firmayı Sil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withAlpha(180)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
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
        border: Border.all(color: Colors.white.withAlpha(28)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPanel() {
    switch (_sekmeIndex) {
      case 1:
        return _buildKullanicilar();
      case 2:
        return _buildModuller();
      case 0:
      default:
        return _buildGenelBilgi();
    }
  }

  Widget _buildGenelBilgi() {
    final bilgiler = <MapEntry<String, String>>[
      MapEntry('Firma kodu', _firma?['firma_kodu']?.toString() ?? '-'),
      MapEntry('Vergi no', _firma?['vergi_no']?.toString() ?? '-'),
      MapEntry('Vergi dairesi', _firma?['vergi_dairesi']?.toString() ?? '-'),
      MapEntry('Sektör', _firma?['sektor']?.toString() ?? '-'),
      MapEntry('Faaliyet', _firma?['faaliyet']?.toString() ?? '-'),
      MapEntry('Yetkili', _firma?['yetkili']?.toString() ?? '-'),
      MapEntry('Telefon', _firma?['telefon']?.toString() ?? '-'),
      MapEntry('E-posta', _firma?['email']?.toString() ?? '-'),
      MapEntry('Adres', _firma?['adres']?.toString() ?? '-'),
      MapEntry('Web', _firma?['web']?.toString() ?? '-'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firma Bilgileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: bilgiler
                .map((entry) => _infoBox(entry.key, entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKullanicilar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: _kullanicilar.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Bu firmada kullanıcı bulunmuyor'),
              ),
            )
          : Column(
              children: _kullanicilar.map((item) {
                final aktif = item['aktif'] == true;
                final ad = item['ad']?.toString() ?? '';
                final soyad = item['soyad']?.toString() ?? '';
                final displayName = item['display_name']?.toString() ?? '';
                final email = item['email']?.toString() ?? '-';
                final rol = item['rol']?.toString() ?? '-';
                final isim =
                    [ad, soyad].where((v) => v.isNotEmpty).join(' ').trim();
                final gorunen = isim.isNotEmpty
                    ? isim
                    : (displayName.isNotEmpty ? displayName : email);

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
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (aktif
                                ? const Color(0xFFDBEAFE)
                                : const Color(0xFFE2E8F0))
                            .withAlpha(255),
                        child: Text(
                          gorunen.isNotEmpty ? gorunen[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: aktif
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gorunen,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(rol, const Color(0xFFEDE9FE),
                              const Color(0xFF6D28D9)),
                          _pill(
                            aktif ? 'Aktif' : 'Pasif',
                            aktif
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            aktif
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildModuller() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: _moduller.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Bu firmada modül kaydı bulunmuyor'),
              ),
            )
          : Column(
              children: _moduller.map((item) {
                final aktif = item['aktif'] == true;
                final tanim = item['modul_tanimlari'];
                final modulAdi =
                    tanim is Map ? tanim['modul_adi']?.toString() ?? '-' : '-';
                final modulKodu =
                    tanim is Map ? tanim['modul_kodu']?.toString() ?? '-' : '-';
                final kategori =
                    tanim is Map ? tanim['kategori']?.toString() ?? '-' : '-';
                final aciklama =
                    tanim is Map ? tanim['aciklama']?.toString() ?? '' : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: (aktif
                                      ? const Color(0xFFEDE9FE)
                                      : const Color(0xFFE2E8F0))
                                  .withAlpha(255),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _modulIkonu(modulKodu),
                              color: aktif
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modulAdi,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$modulKodu • $kategori',
                                  style:
                                      const TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          _pill(
                            aktif ? 'Aktif' : 'Pasif',
                            aktif
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            aktif
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      if (aciklama.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          aciklama,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      width: 260,
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
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }

  IconData _modulIkonu(String kod) {
    switch (kod) {
      case 'uretim':
        return Icons.precision_manufacturing_outlined;
      case 'finans':
        return Icons.account_balance_wallet_outlined;
      case 'ik':
        return Icons.badge_outlined;
      case 'stok':
        return Icons.inventory_2_outlined;
      case 'sevkiyat':
        return Icons.local_shipping_outlined;
      case 'tedarik':
        return Icons.handshake_outlined;
      case 'musteri':
        return Icons.store_outlined;
      case 'rapor':
        return Icons.analytics_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  Future<void> _firmaDurumDegistir(bool yeniDurum) async {
    final firmaAdi = _firma?['firma_adi']?.toString() ?? '';
    final islem = yeniDurum ? 'aktif' : 'pasif';

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Firma $islem yapılsın mı?'),
        content: Text(
          '"$firmaAdi" firması $islem duruma geçirilecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(yeniDurum ? 'Aktif Yap' : 'Pasif Yap'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      setState(() => _islemSuruyor = true);
      await PlatformAdminService.firmaDurumDegistir(widget.firmaId, yeniDurum);
      await _verileriYukle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firma $islem yapıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Future<void> _firmaSilOnayDialogunuAc() async {
    if (_firma == null) return;

    final firmaAdi = _firma!['firma_adi']?.toString() ?? '';
    final firmaKodu = _firma!['firma_kodu']?.toString() ?? '';
    final dogrulama = firmaKodu.isNotEmpty ? firmaKodu : firmaAdi;
    final controller = TextEditingController();

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final eslesiyor = controller.text.trim() == dogrulama;
          return AlertDialog(
            title: const Text('Firmayı kalıcı olarak sil'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"$firmaAdi" firmasının tüm tenant verileri silinecek.'),
                  const SizedBox(height: 10),
                  const Text('Devam etmek için aşağıdaki firma kodunu yazın:'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      dogrulama,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Firma kodunu yazın',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Vazgeç'),
              ),
              ElevatedButton.icon(
                onPressed: eslesiyor ? () => Navigator.of(ctx).pop(true) : null,
                icon: const Icon(Icons.delete_forever_outlined),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                ),
                label: const Text('Kalıcı Sil'),
              ),
            ],
          );
        },
      ),
    );

    controller.dispose();

    if (onay == true) {
      await _firmayiSil();
    }
  }

  Future<void> _firmayiSil() async {
    try {
      setState(() => _islemSuruyor = true);
      final sonuc = await PlatformAdminService.firmaSil(widget.firmaId);
      if (!mounted) return;

      final silinenKullanici = sonuc['silinen_kullanici_sayisi'];
      final silinenKayit = sonuc['silinen_kayit_sayisi'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firma silindi'
            '${silinenKullanici != null ? ' • kullanıcı: $silinenKullanici' : ''}'
            '${silinenKayit != null ? ' • kayıt: $silinenKayit' : ''}',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
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

  String _formatDate(String? raw, {bool withTime = false}) {
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    return DateFormat(withTime ? 'dd.MM.yyyy HH:mm' : 'dd.MM.yyyy')
        .format(parsed);
  }
}
