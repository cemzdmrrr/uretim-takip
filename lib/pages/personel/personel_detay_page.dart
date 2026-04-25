import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/pages/muhasebe/izin_page.dart';
import 'package:uretim_takip/pages/muhasebe/mesai_page.dart';
import 'package:uretim_takip/pages/muhasebe/odeme_page.dart';
import 'package:uretim_takip/pages/muhasebe/puantaj_tablo_page.dart';
import 'package:uretim_takip/pages/personel/personel_arsiv_page.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
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

class _PersonelDetayPageState extends State<PersonelDetayPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PersonelService _service = PersonelService();

  PersonelModel? personel;
  bool yukleniyor = true;
  bool islemYapiliyor = false;
  String? currentUserRole;
  String? seciliDonem;

  final List<_TabItem> _tabs = const [
    _TabItem('Bilgiler', Icons.person),
    _TabItem('Avans / Ödeme', Icons.attach_money),
    _TabItem('İzin', Icons.beach_access),
    _TabItem('Mesai', Icons.access_time),
    _TabItem('Puantaj', Icons.assessment),
    _TabItem('Arşiv', Icons.folder),
  ];

  bool get _yonetebilir =>
      currentUserRole == 'admin' ||
      currentUserRole == 'firma_admin' ||
      currentUserRole == 'firma_sahibi';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _hazirla();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _istenCikarDialog(PersonelModel kayit) async {
    final nedenController = TextEditingController();
    DateTime seciliTarih = DateTime.now();

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Personeli İşten Çıkar'),
              content: Column(
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
                        setLocalState(() => seciliTarih = tarih);
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
                      labelText: 'Çıkış nedeni',
                      hintText: 'Örn. sözleşme bitişi, performans, devamsızlık',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nedenController.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('İşten Çıkar'),
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
      if (!mounted) return;
      context.showSuccessSnackBar('Personel işten çıkarıldı.');
      await _getPersonel();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('İşlem başarısız: $e');
    } finally {
      nedenController.dispose();
      if (mounted) setState(() => islemYapiliyor = false);
    }
  }

  Future<void> _aktifYapDialog(PersonelModel kayit) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Aktifleştir'),
        content:
            Text('${kayit.tamAd} tekrar aktif personel olarak açılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
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
      context.showSuccessSnackBar('Personel tekrar aktif yapıldı.');
      await _getPersonel();
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('İşlem başarısız: $e');
    } finally {
      if (mounted) setState(() => islemYapiliyor = false);
    }
  }

  Future<void> _kaliciSilDialog(PersonelModel kayit) async {
    final kontrolController = TextEditingController();
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Kalıcı Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${kayit.tamAd} kaydı ve uygun ise auth hesabı kalıcı olarak silinecek.'),
            const SizedBox(height: 12),
            Text(
              'Devam etmek için TCKN yazın: ${kayit.tckn}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: kontrolController,
              decoration: const InputDecoration(
                labelText: 'TCKN doğrulama',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (kontrolController.text.trim() != kayit.tckn) return;
              Navigator.pop(context, true);
            },
            child: const Text('Kalıcı Sil'),
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
      context.showSuccessSnackBar('Personel kalıcı olarak silindi.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('İşlem başarısız: $e');
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
        appBar: AppBar(title: const Text('Personel Detayı')),
        body: const Center(child: Text('Personel bulunamadı.')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 720;
    final kayit = personel!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Personel Detayı',
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
                  child: Text('Düzenle'),
                ),
                if (kayit.aktifMi)
                  const PopupMenuItem(
                    value: _PersonelAction.istenCikar,
                    child: Text('İşten Çıkar'),
                  ),
                if (!kayit.aktifMi)
                  const PopupMenuItem(
                    value: _PersonelAction.aktifYap,
                    child: Text('Tekrar Aktif Yap'),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _PersonelAction.kaliciSil,
                  child: Text('Kalıcı Sil'),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(kayit, isMobile),
              _buildTabBarContainer(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBilgilerTab(kayit, isMobile),
                    _buildTabShell(
                      title: 'Avans ve Ödeme',
                      subtitle: 'Bu personele ait ödeme ve avans hareketleri',
                      child: kayit.userId.trim().isEmpty
                          ? const Center(
                              child: Text(
                                'Personel ID bulunamadı. Avans ve ödeme işlemleri açılamıyor.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          : OdemePage(
                              key: ValueKey('odeme_${seciliDonem ?? 'all'}'),
                              personelId: kayit.userId,
                              initialDonem: seciliDonem,
                              embedded: true,
                            ),
                    ),
                    _buildTabShell(
                      title: 'İzin Yönetimi',
                      subtitle: 'İzin kayıtları ve onay akışı',
                      child: IzinPage(
                        key: ValueKey('izin_${seciliDonem ?? 'all'}'),
                        personelId: kayit.userId,
                        personelAd: kayit.tamAd,
                        initialDonem: seciliDonem,
                        embedded: true,
                      ),
                    ),
                    _buildTabShell(
                      title: 'Mesai Kayıtları',
                      subtitle: 'Onaylı ve bekleyen mesai verileri',
                      child: MesaiPage(
                        key: ValueKey('mesai_${seciliDonem ?? 'all'}'),
                        personelId: kayit.userId,
                        personelAd: kayit.tamAd,
                        initialDonem: seciliDonem,
                        embedded: true,
                      ),
                    ),
                    _buildTabShell(
                      title: 'Puantaj',
                      subtitle: 'Günlük çalışma ve devam bilgileri',
                      child: PuantajTabloPage(
                        key: ValueKey('puantaj_${seciliDonem ?? 'all'}'),
                        personelId: kayit.userId,
                        personelAd: kayit.tamAd,
                        initialDonem: seciliDonem,
                        embedded: true,
                      ),
                    ),
                    _buildTabShell(
                      title: 'Arşiv',
                      subtitle: 'Geçmiş bordro, izin, ödeme ve hareket özeti',
                      child: PersonelArsivPage(
                        key: ValueKey('arsiv_${seciliDonem ?? 'all'}'),
                        personelId: kayit.userId,
                        personelAd: kayit.tamAd,
                        initialDonem: seciliDonem,
                        embedded: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      '${kayit.departman.isEmpty ? 'Departman yok' : kayit.departman} • '
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
              _metricTile(Icons.event, 'İşe Başlangıç',
                  _formatDate(kayit.iseBaslangic)),
              _metricTile(
                  Icons.attach_money, 'Net Maaş', _formatMoney(kayit.netMaas)),
              if (kayit.istenCikarildiMi)
                _metricTile(Icons.warning, 'Çıkış Tarihi',
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
                'Çıkış nedeni: ${kayit.istenCikisNedeni}',
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
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF475569),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(14),
        ),
        tabs: _tabs
            .map(
              (item) => Tab(
                child: SizedBox(
                  width: 136,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBilgilerTab(PersonelModel kayit, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _buildInfoSection(
            title: 'Kimlik ve İletişim',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.badge, 'TCKN', kayit.tckn),
              _infoRow(Icons.email, 'E-posta', kayit.email),
              _infoRow(Icons.phone, 'Telefon', kayit.telefon),
              _infoRow(Icons.home, 'Adres', kayit.adres),
            ],
          ),
          _buildInfoSection(
            title: 'Pozisyon ve Çalışma',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.work, 'Pozisyon', kayit.pozisyon),
              _infoRow(Icons.business, 'Departman', kayit.departman),
              _infoRow(Icons.event, 'İşe Başlangıç',
                  _formatDate(kayit.iseBaslangic)),
              _infoRow(Icons.access_time, 'Günlük Çalışma',
                  _formatHour(kayit.gunlukCalismaSaati)),
              _infoRow(Icons.calendar_today, 'Haftalık Gün',
                  _formatDay(kayit.haftalikCalismaGunu)),
            ],
          ),
          _buildInfoSection(
            title: 'Maaş ve Yan Haklar',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.attach_money, 'Brüt Maaş',
                  _formatMoney(kayit.brutMaas)),
              _infoRow(
                  Icons.attach_money, 'Net Maaş', _formatMoney(kayit.netMaas)),
              _infoRow(Icons.directions_bus, 'Yol Ücreti',
                  _formatMoney(kayit.yolUcreti)),
              _infoRow(Icons.restaurant, 'Yemek Ücreti',
                  _formatMoney(kayit.yemekUcreti)),
              _infoRow(
                  Icons.star, 'Ekstra Prim', _formatMoney(kayit.ekstraPrim)),
              _infoRow(Icons.account_balance, 'Banka Maaşı',
                  _formatMoney(kayit.bankaMaas)),
              _infoRow(Icons.attach_money, 'Elden Maaş',
                  _formatMoney(kayit.eldenMaas)),
            ],
          ),
          _buildInfoSection(
            title: 'Ek Bilgiler',
            width: isMobile ? double.infinity : 460,
            children: [
              _infoRow(Icons.info, 'SGK Sicil No', kayit.sgkSicilNo),
              _infoRow(Icons.beach_access, 'Yıllık İzin',
                  '${kayit.yillikIzinHakki} gün'),
              _infoRow(Icons.list, 'Durum', _durumText(kayit)),
              if (kayit.istenCikarildiMi)
                _infoRow(Icons.event_busy, 'Çıkış Tarihi',
                    _formatDate(kayit.istenCikisTarihi)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabShell({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
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
              Expanded(child: child),
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

  Widget _infoRow(IconData icon, String label, String value) {
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
    if (kayit.istenCikarildiMi) return 'İşten Çıkarıldı';
    if (kayit.pasifMi) return 'Pasif';
    return 'Aktif';
  }

  String _initials(PersonelModel kayit) {
    final ad = kayit.ad.trim();
    final soyad = kayit.soyad.trim();
    return '${ad.isNotEmpty ? ad[0] : ''}${soyad.isNotEmpty ? soyad[0] : ''}';
  }

  String _formatMoney(String value) {
    if (value.trim().isEmpty) return '-';
    final parsed = num.tryParse(value);
    if (parsed == null) return value;
    final text = parsed
        .toStringAsFixed(2)
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '₺$text';
  }

  String _formatHour(String value) {
    if (value.trim().isEmpty) return '-';
    return '$value saat';
  }

  String _formatDay(String value) {
    if (value.trim().isEmpty) return '-';
    return '$value gün';
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
