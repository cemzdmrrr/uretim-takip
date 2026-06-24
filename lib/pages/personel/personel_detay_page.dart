import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/odeme_model.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/pages/muhasebe/izin_page.dart';
import 'package:uretim_takip/pages/muhasebe/mesai_page.dart';
import 'package:uretim_takip/pages/muhasebe/odeme_page.dart';
import 'package:uretim_takip/pages/muhasebe/puantaj_tablo_page.dart';
import 'package:uretim_takip/pages/personel/personel_arsiv_page.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/services/odeme_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/user_helper.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

enum _PersonelAction {
  duzenle,
  istenCikar,
  aktifYap,
  kaliciSil,
}

class PersonelDetayPage extends StatefulWidget {
  final String id;
  const PersonelDetayPage({super.key, required this.id});

  @override
  State<PersonelDetayPage> createState() => _PersonelDetayPageState();
}

class _PersonelDetayPageState extends State<PersonelDetayPage> {
  static const double _kidemTazminatiTavan2026IlkYari = 64948.77;

  final PersonelService _service = PersonelService();

  PersonelModel? personel;
  bool yukleniyor = true;
  bool islemYapiliyor = false;
  String? currentUserRole;
  String? seciliDonem;
  int _selectedTabIndex = 0;

  final List<_TabItem> _tabs = const [
    _TabItem('Bilgiler', Icons.person),
    _TabItem('Avans / \u00D6deme', Icons.attach_money),
    _TabItem('\u0130zin', Icons.beach_access),
    _TabItem('Mesai', Icons.access_time),
    _TabItem('Puantaj', Icons.assessment),
    _TabItem('Ar\u015Fiv', Icons.folder),
  ];

  bool get _yonetebilir =>
      currentUserRole == 'admin' ||
      currentUserRole == 'firma_admin' ||
      currentUserRole == 'firma_sahibi';

  @override
  void initState() {
    super.initState();
    _hazirla();
  }

  Future<void> _hazirla() async {
    currentUserRole = await getCurrentUserRole();
    seciliDonem = await _aktifDonemiGetir();
    await _getPersonel();
  }

  Future<String?> _aktifDonemiGetir() async {
    try {
      final response = await Supabase.instance.client
          .from(DbTables.donemler)
          .select('donem_adi')
          .eq('durum', 'aktif')
          .maybeSingle();
      return response?['donem_adi']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _getPersonel() async {
    if (!mounted) return;
    setState(() => yukleniyor = true);
    final kayit = await _service.getPersonelById(widget.id);
    if (!mounted) return;
    setState(() {
      personel = kayit;
      yukleniyor = false;
    });
  }

  Future<void> _aksiyonSec(_PersonelAction action) async {
    final kayit = personel;
    if (kayit == null || islemYapiliyor) return;

    switch (action) {
      case _PersonelAction.duzenle:
        final guncellenen = await Navigator.push<PersonelModel>(
          context,
          MaterialPageRoute(builder: (_) => PersonelEklePage(mevcut: kayit)),
        );
        if (guncellenen != null) {
          setState(() => personel = guncellenen);
          _getPersonel();
        }
        break;
      case _PersonelAction.istenCikar:
        await _istenCikarDialog(kayit);
        break;
      case _PersonelAction.aktifYap:
        await _aktifYapDialog(kayit);
        break;
      case _PersonelAction.kaliciSil:
        await _kaliciSilDialog(kayit);
        break;
    }
  }

  Future<void> _yillikIzinHakkiDuzenle(PersonelModel kayit) async {
    if (!_yonetebilir || islemYapiliyor) return;
    final controller = TextEditingController(text: kayit.yillikIzinHakki);
    final yeniHak = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yıllık izin hakkı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Gün',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 0) return;
              Navigator.pop(context, value);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (yeniHak == null) return;

    setState(() => islemYapiliyor = true);
    try {
      await Supabase.instance.client
          .from(DbTables.personel)
          .update({'yillik_izin_hakki': yeniHak})
          .eq('user_id', kayit.userId)
          .eq('tckn', kayit.tckn);
      await _getPersonel();
      if (!mounted) return;
      context.showSuccessSnackBar('Yıllık izin hakkı güncellendi.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Yıllık izin hakkı güncellenemedi: $e');
    } finally {
      if (mounted) setState(() => islemYapiliyor = false);
    }
  }

  Future<void> _istenCikarDialog(PersonelModel kayit) async {
    final nedenController = TextEditingController();
    final kidemController = TextEditingController();
    final ihbarController = TextEditingController();
    DateTime seciliTarih = DateTime.now();
    bool kidemUygula = true;
    bool ihbarUygula = true;
    double hesaplananKidem = 0;
    double hesaplananIhbar = 0;
    int calismaGunu = 0;

    void tazminatOnerisiniYenile({bool alanlariGuncelle = true}) {
      final hesap = _tazminatOnerisiniHesapla(kayit, seciliTarih);
      hesaplananKidem = hesap['kidem'] ?? 0;
      hesaplananIhbar = hesap['ihbar'] ?? 0;
      calismaGunu = (hesap['calisma_gunu'] ?? 0).round();
      if (alanlariGuncelle) {
        kidemController.text = hesaplananKidem.toStringAsFixed(2);
        ihbarController.text = hesaplananIhbar.toStringAsFixed(2);
      }
    }

    tazminatOnerisiniYenile();

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final kidemTutari =
                kidemUygula ? (_parseMoney(kidemController.text) ?? 0.0) : 0.0;
            final ihbarTutari =
                ihbarUygula ? (_parseMoney(ihbarController.text) ?? 0.0) : 0.0;
            final toplamTazminat = kidemTutari + ihbarTutari;

            return AlertDialog(
              title: const Text('Personeli \u0130\u015Ften \u00C7\u0131kar'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kayit.tamAd,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final tarih = await showDatePicker(
                          context: context,
                          initialDate: seciliTarih,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (tarih != null) {
                          setLocalState(() {
                            seciliTarih = tarih;
                            tazminatOnerisiniYenile();
                          });
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(_formatDate(seciliTarih.toIso8601String())),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nedenController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '\u00C7\u0131k\u0131\u015F nedeni',
                        hintText:
                            '\u00D6rn. s\u00F6zle\u015Fme biti\u015Fi, performans, devams\u0131zl\u0131k',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Tazminat Hesabi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calisma suresi: $calismaGunu gun',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Onerilen kidem: ${_formatMoney(hesaplananKidem.toStringAsFixed(2))}',
                    ),
                    Text(
                      'Onerilen ihbar: ${_formatMoney(hesaplananIhbar.toStringAsFixed(2))}',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kidem tazminati uygula'),
                      value: kidemUygula,
                      onChanged: (value) =>
                          setLocalState(() => kidemUygula = value),
                    ),
                    TextField(
                      controller: kidemController,
                      enabled: kidemUygula,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setLocalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Kidem tutari',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ihbar tazminati uygula'),
                      value: ihbarUygula,
                      onChanged: (value) =>
                          setLocalState(() => ihbarUygula = value),
                    ),
                    TextField(
                      controller: ihbarController,
                      enabled: ihbarUygula,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setLocalState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Ihbar tutari',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Toplam tazminat: ${_formatMoney(toplamTazminat.toStringAsFixed(2))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('\u0130ptal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nedenController.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('\u0130\u015Ften \u00C7\u0131kar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (onay != true) {
      nedenController.dispose();
      return;
    }

    setState(() => islemYapiliyor = true);
    try {
      await _service.istenCikar(
        userId: kayit.userId,
        tckn: kayit.tckn,
        neden: nedenController.text.trim(),
        cikisTarihi: seciliTarih.toIso8601String().split('T').first,
      );
      final kidemTutari =
          kidemUygula ? (_parseMoney(kidemController.text) ?? 0.0) : 0.0;
      final ihbarTutari =
          ihbarUygula ? (_parseMoney(ihbarController.text) ?? 0.0) : 0.0;
      final toplamTazminat = kidemTutari + ihbarTutari;
      if (toplamTazminat > 0) {
        await OdemeService().addOdeme(
          OdemeModel(
            personelId: kayit.userId,
            userId: kayit.userId,
            tur: 'tazminat',
            tutar: toplamTazminat,
            aciklama: _tazminatAciklamasi(
              kidemTutari: kidemTutari,
              ihbarTutari: ihbarTutari,
              hesaplananKidem: hesaplananKidem,
              hesaplananIhbar: hesaplananIhbar,
              calismaGunu: calismaGunu,
            ),
            tarih: seciliTarih,
            durum: 'beklemede',
          ),
        );
      }
      if (!mounted) return;
      context.showSuccessSnackBar(
        toplamTazminat > 0
            ? 'Personel i\u015Ften \u00E7\u0131kar\u0131ld\u0131, tazminat kayd\u0131 beklemeye al\u0131nd\u0131.'
            : 'Personel i\u015Ften \u00E7\u0131kar\u0131ld\u0131.',
      );
      await _getPersonel();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('\u0130\u015Flem ba\u015Far\u0131s\u0131z: $e');
    } finally {
      nedenController.dispose();
      kidemController.dispose();
      ihbarController.dispose();
      if (mounted) setState(() => islemYapiliyor = false);
    }
  }

  Future<void> _aktifYapDialog(PersonelModel kayit) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Aktifle\u015Ftir'),
        content: Text(
            '${kayit.tamAd} tekrar aktif personel olarak a\u00E7\u0131ls\u0131n m\u0131?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\u0130ptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aktif Yap'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    setState(() => islemYapiliyor = true);
    try {
      await _service.personelAktifYap(userId: kayit.userId, tckn: kayit.tckn);
      if (!mounted) return;
      context.showSuccessSnackBar('Personel tekrar aktif yap\u0131ld\u0131.');
      await _getPersonel();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('\u0130\u015Flem ba\u015Far\u0131s\u0131z: $e');
    } finally {
      if (mounted) setState(() => islemYapiliyor = false);
    }
  }

  Future<void> _kaliciSilDialog(PersonelModel kayit) async {
    final kontrolController = TextEditingController();
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Kal\u0131c\u0131 Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${kayit.tamAd} kayd\u0131 ve uygun ise auth hesab\u0131 kal\u0131c\u0131 olarak silinecek.'),
            const SizedBox(height: 12),
            Text(
              'Devam etmek i\u00E7in TCKN yaz\u0131n: ${kayit.tckn}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kontrolController,
              decoration: const InputDecoration(
                labelText: 'TCKN do\u011Frulama',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\u0130ptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (kontrolController.text.trim() != kayit.tckn) return;
              Navigator.pop(context, true);
            },
            child: const Text('Kal\u0131c\u0131 Sil'),
          ),
        ],
      ),
    );

    kontrolController.dispose();
    if (onay != true) return;

    setState(() => islemYapiliyor = true);
    try {
      await _service.personeliKaliciSil(userId: kayit.userId, tckn: kayit.tckn);
      if (!mounted) return;
      context.showSuccessSnackBar('Personel kal\u0131c\u0131 olarak silindi.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('\u0130\u015Flem ba\u015Far\u0131s\u0131z: $e');
    } finally {
      if (mounted) setState(() => islemYapiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (personel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Personel Detay\u0131')),
        body: const Center(child: Text('Personel bulunamad\u0131.')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 720;
    final kayit = personel!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Personel Detay\u0131',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_yonetebilir)
            PopupMenuButton<_PersonelAction>(
              onSelected: _aksiyonSec,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _PersonelAction.duzenle,
                  child: Text('D\u00FCzenle'),
                ),
                if (kayit.aktifMi)
                  const PopupMenuItem(
                    value: _PersonelAction.istenCikar,
                    child: Text('\u0130\u015Ften \u00C7\u0131kar'),
                  ),
                if (!kayit.aktifMi)
                  const PopupMenuItem(
                    value: _PersonelAction.aktifYap,
                    child: Text('Tekrar Aktif Yap'),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _PersonelAction.kaliciSil,
                  child: Text('Kal\u0131c\u0131 Sil'),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildHeader(kayit, isMobile),
                _buildTabBarContainer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildSelectedTabContent(kayit, isMobile),
                ),
              ],
            ),
          ),
          if (islemYapiliyor)
            Container(
              color: const Color(0x66000000),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(PersonelModel kayit, bool isMobile) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.fromLTRB(isMobile ? 14 : 20, 16, isMobile ? 14 : 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5EAF3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 58 : 68,
                height: isMobile ? 58 : 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(kayit),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 22,
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
                      kayit.tamAd,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kayit.departman.isEmpty ? 'Departman yok' : kayit.departman} - '
                      '${kayit.pozisyon.isEmpty ? 'Pozisyon yok' : kayit.pozisyon}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _durumBadge(kayit),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricTile(Icons.badge, 'TCKN', kayit.tckn),
              _metricTile(Icons.event, '\u0130\u015Fe Ba\u015Flang\u0131\u00E7',
                  _formatDate(kayit.iseBaslangic)),
              _metricTile(Icons.attach_money, 'Net Maa\u015F',
                  _formatMoney(kayit.netMaas)),
              if (kayit.istenCikarildiMi)
                _metricTile(Icons.warning, '\u00C7\u0131k\u0131\u015F Tarihi',
                    _formatDate(kayit.istenCikisTarihi)),
            ],
          ),
          if (kayit.istenCikarildiMi && kayit.istenCikisNedeni.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                '\u00C7\u0131k\u0131\u015F nedeni: ${kayit.istenCikisNedeni}',
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBarContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final item = _tabs[index];
            final selected = index == _selectedTabIndex;
            return Padding(
              padding:
                  EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _selectedTabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 152,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 16,
                        color:
                            selected ? Colors.white : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(PersonelModel kayit, bool isMobile) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildBilgilerTab(kayit, isMobile);
      case 1:
        return _buildTabShell(
          key: const ValueKey('odeme'),
          title: 'Avans ve \u00D6deme',
          subtitle: 'Bu personele ait \u00F6deme ve avans hareketleri',
          child: kayit.userId.trim().isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Personel ID bulunamad\u0131. Avans ve \u00F6deme i\u015Flemleri a\u00E7\u0131lam\u0131yor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : OdemePage(
                  key: ValueKey('odeme_${seciliDonem ?? 'all'}'),
                  personelId: kayit.userId,
                  initialDonem: seciliDonem,
                  embedded: true,
                ),
        );
      case 2:
        return _buildTabShell(
          key: const ValueKey('izin'),
          title: '\u0130zin Y\u00F6netimi',
          subtitle:
              '\u0130zin kay\u0131tlar\u0131 ve onay ak\u0131\u015F\u0131',
          child: IzinPage(
            key: ValueKey('izin_${seciliDonem ?? 'all'}'),
            personelId: kayit.userId,
            personelAd: kayit.tamAd,
            initialDonem: seciliDonem,
            embedded: true,
          ),
        );
      case 3:
        return _buildTabShell(
          key: const ValueKey('mesai'),
          title: 'Mesai Kay\u0131tlar\u0131',
          subtitle: 'Onayl\u0131 ve bekleyen mesai verileri',
          child: MesaiPage(
            key: ValueKey('mesai_${seciliDonem ?? 'all'}'),
            personelId: kayit.userId,
            personelAd: kayit.tamAd,
            initialDonem: seciliDonem,
            embedded: true,
          ),
        );
      case 4:
        return _buildTabShell(
          key: const ValueKey('puantaj'),
          title: 'Puantaj',
          subtitle:
              'G\u00FCnl\u00FCk \u00E7al\u0131\u015Fma ve devam bilgileri',
          child: PuantajTabloPage(
            key: ValueKey('puantaj_${seciliDonem ?? 'all'}'),
            personelId: kayit.userId,
            personelAd: kayit.tamAd,
            initialDonem: seciliDonem,
            embedded: true,
          ),
        );
      case 5:
        return _buildTabShell(
          key: const ValueKey('arsiv'),
          title: 'Ar\u015Fiv',
          subtitle:
              'Ge\u00E7mi\u015F bordro, izin, \u00F6deme ve hareket \u00F6zeti',
          child: PersonelArsivPage(
            key: ValueKey('arsiv_${seciliDonem ?? 'all'}'),
            personelId: kayit.userId,
            personelAd: kayit.tamAd,
            initialDonem: seciliDonem,
            embedded: true,
          ),
        );
      default:
        return _buildBilgilerTab(kayit, isMobile);
    }
  }

  Widget _buildBilgilerTab(PersonelModel kayit, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildInfoSection(
            title: 'Kimlik ve \u0130leti\u015Fim',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.badge, 'TCKN', kayit.tckn),
              _infoRow(Icons.email, 'E-posta', kayit.email),
              _infoRow(Icons.phone, 'Telefon', kayit.telefon),
              _infoRow(Icons.home, 'Adres', kayit.adres),
            ],
          ),
          _buildInfoSection(
            title: 'Pozisyon ve \u00C7al\u0131\u015Fma',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.work, 'Pozisyon', kayit.pozisyon),
              _infoRow(Icons.business, 'Departman', kayit.departman),
              _infoRow(Icons.event, '\u0130\u015Fe Ba\u015Flang\u0131\u00E7',
                  _formatDate(kayit.iseBaslangic)),
              _infoRow(
                  Icons.access_time,
                  'G\u00FCnl\u00FCk \u00C7al\u0131\u015Fma',
                  _formatHour(kayit.gunlukCalismaSaati)),
              _infoRow(Icons.calendar_today, 'Haftal\u0131k G\u00FCn',
                  _formatDay(kayit.haftalikCalismaGunu)),
            ],
          ),
          _buildInfoSection(
            title: 'Maa\u015F ve Yan Haklar',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.attach_money, 'Br\u00FCt Maa\u015F',
                  _formatMoney(kayit.brutMaas)),
              _infoRow(Icons.attach_money, 'Net Maa\u015F',
                  _formatMoney(kayit.netMaas)),
              _infoRow(Icons.directions_bus, 'Yol \u00DCcreti',
                  _formatMoney(kayit.yolUcreti)),
              _infoRow(Icons.restaurant, 'Yemek \u00DCcreti',
                  _formatMoney(kayit.yemekUcreti)),
              _infoRow(
                  Icons.star, 'Ekstra Prim', _formatMoney(kayit.ekstraPrim)),
              _infoRow(Icons.account_balance, 'Banka Maa\u015F\u0131',
                  _formatMoney(kayit.bankaMaas)),
              _infoRow(Icons.attach_money, 'Elden Maa\u015F',
                  _formatMoney(kayit.eldenMaas)),
            ],
          ),
          _buildInfoSection(
            title: 'Ek Bilgiler',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.info, 'SGK Sicil No', kayit.sgkSicilNo),
              _infoRow(
                Icons.beach_access,
                'Y\u0131ll\u0131k \u0130zin',
                '${kayit.yillikIzinHakki} g\u00FCn',
                trailing: _yonetebilir
                    ? IconButton(
                        tooltip: 'Yıllık izin hakkını düzenle',
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _yillikIzinHakkiDuzenle(kayit),
                      )
                    : null,
              ),
              _infoRow(Icons.list, 'Durum', _durumText(kayit)),
              if (kayit.istenCikarildiMi)
                _infoRow(Icons.event_busy, '\u00C7\u0131k\u0131\u015F Tarihi',
                    _formatDate(kayit.istenCikisTarihi)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabShell({
    Key? key,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required double width,
    required List<Widget> children,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Widget? trailing}) {
    final display = value.trim().isEmpty ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _durumBadge(PersonelModel kayit) {
    late final Color bg;
    late final Color fg;

    if (kayit.istenCikarildiMi) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
    } else if (kayit.pasifMi) {
      bg = const Color(0xFFE5E7EB);
      fg = const Color(0xFF4B5563);
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _durumText(kayit),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _durumText(PersonelModel kayit) {
    if (kayit.istenCikarildiMi) {
      return '\u0130\u015Ften \u00C7\u0131kar\u0131ld\u0131';
    }
    if (kayit.pasifMi) return 'Pasif';
    return 'Aktif';
  }

  String _initials(PersonelModel kayit) {
    final ad = kayit.ad.trim();
    final soyad = kayit.soyad.trim();
    return '${ad.isNotEmpty ? ad[0] : ''}${soyad.isNotEmpty ? soyad[0] : ''}';
  }

  Map<String, double> _tazminatOnerisiniHesapla(
    PersonelModel kayit,
    DateTime cikisTarihi,
  ) {
    final iseBaslangic = DateTime.tryParse(kayit.iseBaslangic);
    if (iseBaslangic == null || cikisTarihi.isBefore(iseBaslangic)) {
      return {'kidem': 0, 'ihbar': 0, 'calisma_gunu': 0};
    }

    final calismaGunu = cikisTarihi.difference(iseBaslangic).inDays + 1;
    final brutMaas = _parseMoney(kayit.brutMaas) ?? 0;
    final yol = _parseMoney(kayit.yolUcreti) ?? 0;
    final yemek = _parseMoney(kayit.yemekUcreti) ?? 0;
    final giydirilmisBrut = brutMaas + yol + yemek;
    if (giydirilmisBrut <= 0) {
      return {'kidem': 0, 'ihbar': 0, 'calisma_gunu': calismaGunu.toDouble()};
    }

    final kidemMatrah = giydirilmisBrut > _kidemTazminatiTavan2026IlkYari
        ? _kidemTazminatiTavan2026IlkYari
        : giydirilmisBrut;
    final kidem = calismaGunu >= 365 ? kidemMatrah * calismaGunu / 365 : 0.0;
    final ihbarGunu = _ihbarSuresiGunu(calismaGunu);
    final ihbar = giydirilmisBrut / 30 * ihbarGunu;

    return {
      'kidem': kidem,
      'ihbar': ihbar,
      'calisma_gunu': calismaGunu.toDouble(),
    };
  }

  int _ihbarSuresiGunu(int calismaGunu) {
    if (calismaGunu < 180) return 14;
    if (calismaGunu < 540) return 28;
    if (calismaGunu < 1080) return 42;
    return 56;
  }

  double? _parseMoney(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(trimmed)
            ? trimmed.replaceAll('.', '')
            : trimmed);
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _tazminatAciklamasi({
    required double kidemTutari,
    required double ihbarTutari,
    required double hesaplananKidem,
    required double hesaplananIhbar,
    required int calismaGunu,
  }) {
    final manuelKidem =
        (kidemTutari - hesaplananKidem).abs() > 0.01 ? 'manuel' : 'onerilen';
    final manuelIhbar =
        (ihbarTutari - hesaplananIhbar).abs() > 0.01 ? 'manuel' : 'onerilen';
    return 'Isten cikis tazminati. Kidem: ${kidemTutari.toStringAsFixed(2)} TL ($manuelKidem), '
        'ihbar: ${ihbarTutari.toStringAsFixed(2)} TL ($manuelIhbar), '
        'calisma suresi: $calismaGunu gun.';
  }

  String _formatMoney(String value) {
    if (value.trim().isEmpty) return '-';
    final parsed = num.tryParse(value);
    if (parsed == null) return value;
    final text = parsed
        .toStringAsFixed(2)
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\u20BA$text';
  }

  String _formatHour(String value) {
    if (value.trim().isEmpty) return '-';
    return '$value saat';
  }

  String _formatDay(String value) {
    if (value.trim().isEmpty) return '-';
    return '$value g\u00FCn';
  }

  String _formatDate(String value) {
    if (value.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }
}

class _TabItem {
  final String label;
  final IconData icon;

  const _TabItem(this.label, this.icon);
}
