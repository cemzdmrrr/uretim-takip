import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/pages/personel/personel_detay_page.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/user_helper.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';

class PersonelListesiPage extends StatefulWidget {
  const PersonelListesiPage({super.key});

  @override
  State<PersonelListesiPage> createState() => _PersonelListesiPageState();
}

class _PersonelListesiPageState extends State<PersonelListesiPage> {
  final TextEditingController _aramaController = TextEditingController();

  List<PersonelModel> _tumPersoneller = [];
  List<PersonelModel> _filtreliPersoneller = [];
  bool _yukleniyor = true;
  String _arama = '';
  String _durumFiltresi = 'aktif';
  String? _kullaniciRolu;
  String? _kullaniciId;

  @override
  void initState() {
    super.initState();
    _hazirla();
    _aramaController.addListener(_filtreUygula);
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _hazirla() async {
    _kullaniciRolu = await getCurrentUserRole();
    _kullaniciId = await getCurrentUserId();
    await _getPersoneller();
  }

  Future<void> _getPersoneller() async {
    setState(() => _yukleniyor = true);
    try {
      final servis = PersonelService();
      final tumKayitlar = await servis.getPersoneller(sadeceAktif: false);
      var gosterilecek = tumKayitlar;

      if (_kullaniciRolu == DbTables.personel && _kullaniciId != null) {
        gosterilecek = tumKayitlar.where((p) => p.userId == _kullaniciId).toList();
      }

      if (!mounted) return;
      setState(() {
        _tumPersoneller = gosterilecek;
        _yukleniyor = false;
      });
      _filtreUygula();
    } catch (_) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
    }
  }

  void _filtreUygula() {
    final arama = _aramaController.text.trim().toLowerCase();
    List<PersonelModel> liste = List<PersonelModel>.from(_tumPersoneller);

    switch (_durumFiltresi) {
      case 'aktif':
        liste = liste.where((p) => p.aktifMi).toList();
        break;
      case 'isten_cikarildi':
        liste = liste.where((p) => p.istenCikarildiMi).toList();
        break;
      case 'pasif':
        liste = liste.where((p) => p.pasifMi).toList();
        break;
      default:
        break;
    }

    if (arama.isNotEmpty) {
      liste = liste.where((p) {
        return p.tamAd.toLowerCase().contains(arama) ||
            p.telefon.toLowerCase().contains(arama) ||
            p.pozisyon.toLowerCase().contains(arama) ||
            p.departman.toLowerCase().contains(arama) ||
            p.tckn.toLowerCase().contains(arama) ||
            p.email.toLowerCase().contains(arama);
      }).toList();
    }

    if (!mounted) return;
    setState(() {
      _arama = arama;
      _filtreliPersoneller = liste;
    });
  }

  int _say(String durum) {
    switch (durum) {
      case 'aktif':
        return _tumPersoneller.where((p) => p.aktifMi).length;
      case 'isten_cikarildi':
        return _tumPersoneller.where((p) => p.istenCikarildiMi).length;
      case 'pasif':
        return _tumPersoneller.where((p) => p.pasifMi).length;
      default:
        return _tumPersoneller.length;
    }
  }

  double _toplamNetMaas() {
    return _filtreliPersoneller.fold<double>(
      0,
      (toplam, personel) => toplam + (num.tryParse(personel.netMaas) ?? 0),
    );
  }

  int _benzersizDepartmanSayisi() {
    return _tumPersoneller
        .where((p) => p.departman.trim().isNotEmpty)
        .map((p) => p.departman.trim().toLowerCase())
        .toSet()
        .length;
  }

  Future<void> _personelDetayAc(PersonelModel personel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonelDetayPage(id: personel.userId)),
    );
    if (result == true || result == 'deleted') {
      _getPersoneller();
    }
  }

  Future<void> _personelEkleAc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonelEklePage()),
    );
    if (result == true) {
      _getPersoneller();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;
    final isTablet = width >= 760 && width < 1240;
    final canManage = _kullaniciRolu != DbTables.personel;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: Text(
          canManage ? 'Personel Yönetimi' : 'Kişisel Bilgilerim',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _getPersoneller,
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage && isMobile
          ? FloatingActionButton.extended(
              onPressed: _personelEkleAc,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Personel'),
            )
          : null,
      body: _yukleniyor
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _getPersoneller,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeroSection(isMobile, canManage),
                  ),
                  SliverToBoxAdapter(
                    child: _buildToolbar(isMobile, canManage),
                  ),
                  if (_filtreliPersoneller.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.people,
                        mesaj: 'Gösterilecek personel bulunamadı',
                        altMesaj: 'Arama veya durum filtresini değiştirin.',
                      ),
                    )
                  else if (isMobile)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      sliver: SliverList.separated(
                        itemCount: _filtreliPersoneller.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildMobileCard(_filtreliPersoneller[index]);
                        },
                      ),
                    )
                  else if (isTablet)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildTabletCard(_filtreliPersoneller[index]),
                          childCount: _filtreliPersoneller.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.45,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildDesktopTable(canManage),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection(bool isMobile, bool canManage) {
    return Container(
      margin: EdgeInsets.fromLTRB(isMobile ? 14 : 20, 16, isMobile ? 14 : 20, 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D91), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E2563EB),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(canManage),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _buildHeroStatCards(compact: true),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildHeroText(canManage)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: _buildHeroStatCards(compact: false),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroText(bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            canManage ? 'İnsan Kaynakları Paneli' : 'Personel Özeti',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          canManage
              ? 'Ekip yapısını tek ekranda yönetin'
              : 'Kendi personel bilgilerinizi izleyin',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          canManage
              ? 'Durum, maaş, departman ve erişim hareketlerini daha okunur bir operasyon ekranında takip edin.'
              : 'Kaydınız, durumunuz ve ödeme özetiniz bu panelde yer alır.',
          style: const TextStyle(
            color: Color(0xFFDCE7FF),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHeroStatCards({required bool compact}) {
    return [
      _buildHeroStatCard(
        icon: Icons.people,
        label: 'Toplam Personel',
        value: _tumPersoneller.length.toString(),
        compact: compact,
      ),
      _buildHeroStatCard(
        icon: Icons.check_circle,
        label: 'Aktif Kayıt',
        value: _say('aktif').toString(),
        compact: compact,
      ),
      _buildHeroStatCard(
        icon: Icons.business,
        label: 'Departman',
        value: _benzersizDepartmanSayisi().toString(),
        compact: compact,
      ),
      _buildHeroStatCard(
        icon: Icons.attach_money,
        label: 'Filtre Net Maaş',
        value: _formatMoney(_toplamNetMaas().toStringAsFixed(2)),
        compact: compact,
      ),
    ];
  }

  Widget _buildHeroStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool compact,
  }) {
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 150 : 172,
        maxWidth: compact ? 220 : 220,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isMobile, bool canManage) {
    return Container(
      margin: EdgeInsets.fromLTRB(isMobile ? 14 : 20, 0, isMobile ? 14 : 20, 16),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (!isMobile)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kayıtlar ${_filtreliPersoneller.length} satır gösteriyor',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (canManage)
                  FilledButton.icon(
                    onPressed: _personelEkleAc,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Personel'),
                  ),
              ],
            ),
          if (!isMobile) const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
                child: TextField(
                  controller: _aramaController,
                  decoration: InputDecoration(
                    hintText: 'İsim, TCKN, pozisyon, departman, e-posta',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _arama.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => _aramaController.clear(),
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD7DFEB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD7DFEB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              _buildFilterChip('aktif', 'Aktif', const Color(0xFF166534)),
              if (canManage)
                _buildFilterChip(
                  'isten_cikarildi',
                  'İşten Çıkarılan',
                  const Color(0xFFC2410C),
                ),
              if (canManage)
                _buildFilterChip('pasif', 'Pasif', const Color(0xFF475569)),
              if (canManage)
                _buildFilterChip('tum', 'Tümü', const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color accent) {
    final selected = _durumFiltresi == key;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() => _durumFiltresi = key);
        _filtreUygula();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? accent : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : const Color(0xFFD8E1EC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _filterIconFor(key),
              size: 16,
              color: selected ? Colors.white : accent,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _say(key).toString(),
              style: TextStyle(
                color: selected ? Colors.white : accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _filterIconFor(String key) {
    switch (key) {
      case 'aktif':
        return Icons.check_circle;
      case 'isten_cikarildi':
        return Icons.person;
      case 'pasif':
        return Icons.delete;
      default:
        return Icons.list;
    }
  }

  Widget _buildMobileCard(PersonelModel personel) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _personelDetayAc(personel),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(personel, 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personel.tamAd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bosGoster(personel.pozisyon),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDurumBadge(personel),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMicroInfo(Icons.business, personel.departman),
                  _buildMicroInfo(Icons.phone, personel.telefon),
                  _buildMicroInfo(Icons.event, _formatDate(personel.iseBaslangic)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildCompactMetric('Net Maaş', _formatMoney(personel.netMaas)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactMetric('Durum', _durumMetni(personel)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletCard(PersonelModel personel) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _personelDetayAc(personel),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(personel, 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personel.tamAd,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bosGoster(personel.pozisyon),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDurumBadge(personel),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn('Departman', _bosGoster(personel.departman)),
                  ),
                  Expanded(
                    child: _buildDetailColumn('Telefon', _bosGoster(personel.telefon)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailColumn('Net Maaş', _formatMoney(personel.netMaas)),
                  ),
                  Expanded(
                    child: _buildDetailColumn(
                      'İşe Başlangıç',
                      _formatDate(personel.iseBaslangic),
                    ),
                  ),
                ],
              ),
              if (personel.istenCikarildiMi && personel.istenCikisNedeni.isNotEmpty) ...[
                const Spacer(),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    personel.istenCikisNedeni,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(bool canManage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Expanded(flex: 24, child: _TableHeader('Personel')),
                const Expanded(flex: 16, child: _TableHeader('Departman / Pozisyon')),
                const Expanded(flex: 17, child: _TableHeader('İletişim')),
                const Expanded(flex: 12, child: _TableHeader('İşe Başlangıç')),
                const Expanded(flex: 12, child: _TableHeader('Net Maaş')),
                const Expanded(flex: 11, child: _TableHeader('Durum')),
                Expanded(
                  flex: 8,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      canManage ? 'İşlem' : 'Detay',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtreliPersoneller.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEFF3F8)),
            itemBuilder: (context, index) {
              final personel = _filtreliPersoneller[index];
              return InkWell(
                onTap: () => _personelDetayAc(personel),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(flex: 24, child: _buildDesktopIdentity(personel)),
                      Expanded(
                        flex: 16,
                        child: _buildDesktopInfoPair(
                          top: _bosGoster(personel.departman),
                          bottom: _bosGoster(personel.pozisyon),
                        ),
                      ),
                      Expanded(
                        flex: 17,
                        child: _buildDesktopInfoPair(
                          top: _bosGoster(personel.telefon),
                          bottom: _bosGoster(personel.email),
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child: Text(
                          _formatDate(personel.iseBaslangic),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 12,
                        child: Text(
                          _formatMoney(personel.netMaas),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 11,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildDurumBadge(personel),
                        ),
                      ),
                      Expanded(
                        flex: 8,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _personelDetayAc(personel),
                            tooltip: 'Detay',
                            icon: const Icon(Icons.arrow_forward_ios, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopIdentity(PersonelModel personel) {
    return Row(
      children: [
        _buildAvatar(personel, 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                personel.tamAd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'TCKN: ${_bosGoster(personel.tckn)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopInfoPair({required String top, required String bottom}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          top,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bottom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(PersonelModel personel, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0EAFF), Color(0xFFD7F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size > 52 ? 16 : 14),
      ),
      alignment: Alignment.center,
      child: Text(
        _inisyaller(personel),
        style: TextStyle(
          fontSize: size > 52 ? 19 : 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2563EB),
        ),
      ),
    );
  }

  Widget _buildMicroInfo(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              _bosGoster(value),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDurumBadge(PersonelModel personel) {
    late final Color bg;
    late final Color fg;
    late final String text;

    if (personel.istenCikarildiMi) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
      text = 'İşten Çıkarıldı';
    } else if (personel.pasifMi) {
      bg = const Color(0xFFE2E8F0);
      fg = const Color(0xFF475569);
      text = 'Pasif';
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
      text = 'Aktif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _durumMetni(PersonelModel personel) {
    if (personel.istenCikarildiMi) return 'İşten Çıkarıldı';
    if (personel.pasifMi) return 'Pasif';
    return 'Aktif';
  }

  String _bosGoster(String value) {
    return value.trim().isEmpty ? '-' : value.trim();
  }

  String _inisyaller(PersonelModel personel) {
    final ad = personel.ad.trim();
    final soyad = personel.soyad.trim();
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

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
