import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/muhasebe/bordro_page.dart';
import 'package:uretim_takip/pages/muhasebe/izin_page.dart';
import 'package:uretim_takip/pages/muhasebe/odeme_page.dart';
import 'package:uretim_takip/pages/personel/personel_analiz_page.dart';
import 'package:uretim_takip/pages/personel/personel_ayarlar_page.dart';
import 'package:uretim_takip/pages/personel/personel_detay_page.dart';
import 'package:uretim_takip/pages/personel/personel_ekle_page.dart';
import 'package:uretim_takip/pages/personel/personel_listesi_page.dart';
import 'package:uretim_takip/services/tenant_manager.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';
import 'package:uretim_takip/widgets/yeni_donem_dialog.dart';

class PersonelAnaSayfa extends StatefulWidget {
  final String kullaniciRolu;
  const PersonelAnaSayfa({super.key, required this.kullaniciRolu});

  @override
  State<PersonelAnaSayfa> createState() => _PersonelAnaSayfaState();
}

class _PersonelAnaSayfaState extends State<PersonelAnaSayfa> {
  int toplamPersonel = 0;
  int toplamIzin = 0;
  int toplamBordro = 0;
  int toplamMesai = 0;
  double toplamMesaiSaati = 0;
  double toplamOdeme = 0;
  double bankaMaas = 0;
  double eldenMaas = 0;
  int departmanSayisi = 0;
  bool yukleniyor = true;
  String? aktifDonem;
  String? seciliDonem;

  bool get _personelMi => widget.kullaniciRolu == DbTables.personel;
  bool get _yonetebilir =>
      widget.kullaniciRolu == 'admin' || widget.kullaniciRolu == 'ik';

  @override
  void initState() {
    super.initState();
    _loadAktifDonem();
    _getDashboardData();
  }

  Future<void> _loadAktifDonem() async {
    final now = DateTime.now();
    aktifDonem = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    seciliDonem = null;
    if (mounted) setState(() {});
  }

  Future<void> _getDashboardData() async {
    setState(() => yukleniyor = true);

    try {
      final client = Supabase.instance.client;

      DateTime baslangicTarihi;
      DateTime bitisTarihi;
      if (seciliDonem != null) {
        final parts = seciliDonem!.split('-');
        final yil = int.parse(parts[0]);
        final ay = int.parse(parts[1]);
        baslangicTarihi = DateTime(yil, ay, 1);
        bitisTarihi = DateTime(yil, ay + 1, 1);
      } else {
        final now = DateTime.now();
        baslangicTarihi = DateTime(now.year - 1, now.month, 1);
        bitisTarihi = DateTime(now.year, now.month + 1, 1);
      }

      final allPersonelRes = await client
          .from(DbTables.personel)
          .select('user_id, departman, brut_maas, net_maas, banka_maas, elden_maas')
          .eq('firma_id', TenantManager.instance.requireFirmaId);

      final departmanlar = <String>{};
      double bankaMaasLocal = 0;
      double eldenMaasLocal = 0;

      for (final p in allPersonelRes) {
        if (p['departman'] != null && p['departman'].toString().trim().isNotEmpty) {
          departmanlar.add(p['departman'].toString());
        }

        final bankaMaasValue =
            double.tryParse(p['banka_maas']?.toString() ?? '0') ?? 0;
        final netMaasValue = double.tryParse(p['net_maas']?.toString() ?? '0') ?? 0;
        final eldenMaasValue = netMaasValue - bankaMaasValue;

        bankaMaasLocal += bankaMaasValue;
        eldenMaasLocal += eldenMaasValue > 0 ? eldenMaasValue : 0;
      }

      final izinRes = await client
          .from(DbTables.izinler)
          .select('id')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('baslama_tarihi', baslangicTarihi.toIso8601String().split('T')[0])
          .lt('baslama_tarihi', bitisTarihi.toIso8601String().split('T')[0])
          .eq('onay_durumu', 'onaylandi');

      final bordroQuery = client
          .from(DbTables.bordro)
          .select('id')
          .eq('firma_id', TenantManager.instance.requireFirmaId);
      final bordroRes =
          seciliDonem != null ? await bordroQuery.ilike('donem_kodu', '$seciliDonem%') : await bordroQuery;

      final mesaiRes = await client
          .from(DbTables.mesai)
          .select('id, saat')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('tarih', baslangicTarihi.toIso8601String().split('T')[0])
          .lt('tarih', bitisTarihi.toIso8601String().split('T')[0])
          .eq('onay_durumu', 'onaylandi');

      double toplamMesaiSaatiLocal = 0;
      for (final mesai in mesaiRes) {
        toplamMesaiSaatiLocal += (mesai['saat'] as num? ?? 0).toDouble();
      }

      final odemeRes = await client
          .from(DbTables.odemeKayitlari)
          .select('tutar')
          .eq('firma_id', TenantManager.instance.requireFirmaId)
          .gte('tarih', baslangicTarihi.toIso8601String().split('T')[0])
          .lt('tarih', bitisTarihi.toIso8601String().split('T')[0])
          .eq('durum', 'onaylandi');

      double toplamOdemeLocal = 0;
      for (final odeme in odemeRes) {
        toplamOdemeLocal += (odeme['tutar'] as num? ?? 0).toDouble();
      }

      if (!mounted) return;
      setState(() {
        toplamPersonel = allPersonelRes.length;
        toplamIzin = izinRes.length;
        toplamBordro = bordroRes.length;
        toplamMesai = mesaiRes.length;
        toplamMesaiSaati = toplamMesaiSaatiLocal;
        toplamOdeme = toplamOdemeLocal;
        bankaMaas = bankaMaasLocal;
        eldenMaas = eldenMaasLocal;
        departmanSayisi = departmanlar.length;
        yukleniyor = false;
      });
    } catch (e) {
      debugPrint('Dashboard veri yükleme hatası: $e');
      if (!mounted) return;
      setState(() => yukleniyor = false);
    }
  }

  String _getDonemText() {
    if (seciliDonem == null) return 'Tüm dönemler';

    final parts = seciliDonem!.split('-');
    if (parts.length != 2) return seciliDonem!;

    final yil = parts[0];
    final ay = int.tryParse(parts[1]) ?? 1;
    const aylar = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${aylar[ay]} $yil';
  }

  Future<void> _yeniDonemEkle(BuildContext context) async {
    if (!_yonetebilir) {
      context.showErrorSnackBar('Bu işlem için yönetici veya İK yetkisi gerekli.');
      return;
    }

    final kullaniciId = Supabase.instance.client.auth.currentUser?.id;
    if (kullaniciId == null) {
      context.showErrorSnackBar('Kullanıcı bilgisi alınamadı.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => YeniDonemDialog(
        kullaniciId: kullaniciId,
        onDonemEklendi: _getDashboardData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _personelMi ? 'Personel Paneli' : 'Personel Yönetimi',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _getDashboardData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: yukleniyor
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _getDashboardData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHero(isMobile),
                  ),
                  SliverToBoxAdapter(
                    child: _buildDonemPanel(isMobile),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildOzetGrid(isMobile),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _buildActionsSection(isMobile),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: _buildInfoSection(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHero(bool isMobile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D91), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x262563EB),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(),
                const SizedBox(height: 16),
                _buildHeroSide(),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: _buildHeroText()),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: _buildHeroSide()),
              ],
            ),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _personelMi ? 'Kişisel alan' : 'İnsan kaynakları merkezi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _personelMi ? 'Bilgilerinizi ve taleplerinizi tek panelden izleyin' : 'Operasyon, bordro ve ekip akışını tek ekranda yönetin',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Seçili dönem: ${_getDonemText()}',
          style: const TextStyle(
            color: Color(0xFFDCE7FF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSide() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı görünüm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildHeroMetric('Toplam personel', toplamPersonel.toString()),
          _buildHeroMetric('Onaylı izin', toplamIzin.toString()),
          _buildHeroMetric('Bordro kaydı', toplamBordro.toString()),
          _buildHeroMetric('Ödeme toplamı', _formatMoney(toplamOdeme)),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFDCE7FF),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonemPanel(bool isMobile) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Dönem',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 10),
                DonemSecici(
                  seciliDonem: seciliDonem,
                  onDonemChanged: (donem) {
                    setState(() {
                      seciliDonem = donem;
                    });
                    _getDashboardData();
                  },
                ),
              ],
            ),
          ),
          if (_yonetebilir)
            FilledButton.icon(
              onPressed: () => _yeniDonemEkle(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Yeni dönem'),
            ),
        ],
      ),
    );
  }

  Widget _buildOzetGrid(bool isMobile) {
    final kartlar = [
      _SummaryItem(Icons.groups_2_outlined, 'Toplam Personel', toplamPersonel.toString(), const Color(0xFF2563EB)),
      _SummaryItem(Icons.beach_access_outlined, 'Onaylı İzin', toplamIzin.toString(), const Color(0xFFF57C00)),
      _SummaryItem(Icons.receipt_long_outlined, 'Bordro', toplamBordro.toString(), const Color(0xFF0F9D58)),
      _SummaryItem(Icons.timer_outlined, 'Mesai', '$toplamMesai • ${toplamMesaiSaati.toStringAsFixed(1)} saat', const Color(0xFF7C3AED)),
      _SummaryItem(Icons.account_balance_wallet_outlined, 'Ödeme', _formatMoney(toplamOdeme), const Color(0xFF0891B2)),
      _SummaryItem(Icons.account_balance_outlined, 'Banka Maaşları', _formatMoney(bankaMaas), const Color(0xFF4F46E5)),
      _SummaryItem(Icons.payments_outlined, 'Elden Maaşlar', _formatMoney(eldenMaas), const Color(0xFFA16207)),
      _SummaryItem(Icons.apartment_outlined, 'Departman', departmanSayisi.toString(), const Color(0xFFDC2626)),
    ];

    if (isMobile) {
      return Column(
        children: kartlar
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSummaryCard(item, fullWidth: true),
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: kartlar
          .map((item) => SizedBox(width: 250, child: _buildSummaryCard(item)))
          .toList(),
    );
  }

  Widget _buildSummaryCard(_SummaryItem item, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
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

  Widget _buildActionsSection(bool isMobile) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final aksiyonlar = _personelMi
        ? <_ActionItem>[
            _ActionItem(
              title: 'Kişisel bilgilerim',
              subtitle: 'Profil, maaş ve durum bilgilerini görüntüle',
              icon: Icons.badge_outlined,
              color: const Color(0xFF2563EB),
              onTap: userId == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonelDetayPage(id: userId),
                        ),
                      ),
            ),
            _ActionItem(
              title: 'Avans ve ödemeler',
              subtitle: 'Kayıtlı ödeme hareketlerini aç',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF0F9D58),
              onTap: userId == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OdemePage(personelId: userId),
                        ),
                      ),
            ),
            _ActionItem(
              title: 'İzin taleplerim',
              subtitle: 'İzin kayıtlarını ve durumlarını yönet',
              icon: Icons.beach_access_outlined,
              color: const Color(0xFFF57C00),
              onTap: userId == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IzinPage(personelId: userId),
                        ),
                      ),
            ),
          ]
        : <_ActionItem>[
            _ActionItem(
              title: 'Personel listesi',
              subtitle: 'Tüm kayıtları yönetim ekranında aç',
              icon: Icons.groups_outlined,
              color: const Color(0xFF2563EB),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonelListesiPage()),
              ),
            ),
            _ActionItem(
              title: 'Yeni personel ekle',
              subtitle: 'Yeni kullanıcı ve personel kaydı oluştur',
              icon: Icons.person_add_alt_1_outlined,
              color: const Color(0xFF0F9D58),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonelEklePage()),
              ),
            ),
            _ActionItem(
              title: 'Bordro yönetimi',
              subtitle: 'Bordro, dönem ve hesap akışını aç',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF7C3AED),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BordroPage()),
              ),
            ),
            _ActionItem(
              title: 'Analiz ve raporlama',
              subtitle: 'Departman, performans ve maliyet raporları',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF0891B2),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonelAnalizPage()),
              ),
            ),
            if (_yonetebilir)
              _ActionItem(
                title: 'Ayarlar',
                subtitle: 'Şirket, SGK ve izin parametrelerini düzenle',
                icon: Icons.settings_outlined,
                color: const Color(0xFFDC2626),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonelAyarlarPage()),
                ),
              ),
          ];

    return _buildSection(
      title: 'Hızlı işlemler',
      subtitle: _personelMi
          ? 'Günlük personel işlemlerine doğrudan erişin.'
          : 'Personel modülünün temel ekranlarına kısa yoldan geçin.',
      child: isMobile
          ? Column(
              children: aksiyonlar
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActionCard(item, compact: true),
                    ),
                  )
                  .toList(),
            )
          : Wrap(
              spacing: 14,
              runSpacing: 14,
              children: aksiyonlar
                  .map((item) => SizedBox(width: 260, child: _buildActionCard(item)))
                  .toList(),
            ),
    );
  }

  Widget _buildActionCard(_ActionItem item, {bool compact = false}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildSection(
      title: 'Bilgilendirme',
      subtitle: 'Panel kullanımını kolaylaştıran kısa notlar.',
      child: Column(
        children: [
          _buildInfoCard(
            Icons.info_outline,
            'Dönem filtresi dashboard metriklerini doğrudan etkiler.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            Icons.verified_user_outlined,
            _personelMi
                ? 'Bu alanda yalnızca kendi kayıtlarınızı ve taleplerinizi görüntüleyebilirsiniz.'
                : 'Personel listesi ekranından işe çıkarma, silme ve detay işlemlerine erişebilirsiniz.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    final text = value
        .toStringAsFixed(2)
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '₺$text';
  }
}

class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _SummaryItem(this.icon, this.label, this.value, this.color);
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}
