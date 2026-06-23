import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/izin_model.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/services/odeme_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

part 'personel_arsiv_page_logic.dart';

class PersonelArsivPage extends StatefulWidget {
  final String personelId;
  final String personelAd;
  final String? initialDonem;
  final bool embedded;

  const PersonelArsivPage({
    super.key,
    required this.personelId,
    required this.personelAd,
    this.initialDonem,
    this.embedded = false,
  });

  @override
  State<PersonelArsivPage> createState() => _PersonelArsivPageState();
}

class _PersonelArsivPageState extends State<PersonelArsivPage> {
  String? seciliDonem;
  bool yukleniyor = false;

  double toplamMaas = 0;
  double toplamAvans = 0;
  double toplamPrim = 0;
  double toplamYol = 0;
  double toplamYemek = 0;
  double toplamNet = 0;
  double toplamKesinti = 0;

  double toplamMesaiSaati = 0;
  int normalCalismaGunu = 0;
  int izinGunu = 0;
  int raporGunu = 0;
  int devamsizlikGunu = 0;
  int toplamCalismaGunu = 0;

  double performansPuani = 0;
  String performansDurumu = 'Orta';

  @override
  void initState() {
    super.initState();
    _initializeDonem();
  }

  Future<void> _initializeDonem() async {
    if (widget.initialDonem != null) {
      seciliDonem = widget.initialDonem;
      _getArsiv();
      return;
    }

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from(DbTables.donemler)
          .select('donem_adi')
          .eq('durum', 'aktif')
          .maybeSingle();

      seciliDonem = response?['donem_adi']?.toString();
    } catch (e) {
      debugPrint('Donem baslatma hatasi: $e');
      seciliDonem = null;
    }

    _getArsiv();
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        top: widget.embedded,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 900 ? 24.0 : 16.0;
            final panelWidth = width >= 1200
                ? (width - (horizontalPadding * 2) - 16) / 2
                : double.infinity;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.embedded ? 1440 : 1320,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(width),
                      const SizedBox(height: 20),
                      _buildToolbar(width),
                      const SizedBox(height: 20),
                      if (yukleniyor)
                        const LoadingWidget()
                      else if (seciliDonem == null)
                        _buildNoticePanel(
                          icon: Icons.event_busy,
                          tone: _PanelTone.warning,
                          title: 'Donem secimi gerekli',
                          message: 'Lutfen bir donem secin.',
                        )
                      else ...[
                        _buildDataStateBanner(),
                        const SizedBox(height: 20),
                        _buildSummaryGrid(width),
                        const SizedBox(height: 20),
                        _buildFinancialPanel(width),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: panelWidth,
                              child: _buildWorkPanel(),
                            ),
                            SizedBox(
                              width: panelWidth,
                              child: _buildPerformancePanel(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Personel Ar\u015Fiv'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _getArsiv,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildHero(double width) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width >= 960 ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3FAE), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.folder_open, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personel Arsiv Merkezi',
                  style: TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Donemsel bordro, izin ve hareket ozetini tek ekranda yonetin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.personelAd,
                  style: const TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(double width) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Donem Filtresi',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: width >= 720 ? 280 : double.infinity,
            child: DonemSecici(
              seciliDonem: seciliDonem,
              onDonemChanged: (donem) {
                setState(() => seciliDonem = donem);
                _getArsiv();
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _getArsiv,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStateBanner() {
    final hasAnyData = toplamMaas > 0 ||
        toplamAvans > 0 ||
        toplamMesaiSaati > 0 ||
        izinGunu > 0 ||
        raporGunu > 0;

    if (!hasAnyData) {
      return _buildNoticePanel(
        icon: Icons.info_outline,
        tone: _PanelTone.warning,
        title: 'Kayit bulunamadi',
        message:
            'Secilen donem icin hareket kaydi bulunamadi. Temel personel bilgileri gosteriliyor.',
      );
    }

    return _buildNoticePanel(
      icon: Icons.check_circle,
      tone: _PanelTone.success,
      title: 'Veriler yuklendi',
      message: '$seciliDonem donemine ait arsiv verileri hazir.',
    );
  }

  Widget _buildNoticePanel({
    required IconData icon,
    required _PanelTone tone,
    required String title,
    required String message,
  }) {
    final config = switch (tone) {
      _PanelTone.success => (
          background: const Color(0xFFF0FDF4),
          border: const Color(0xFFBBF7D0),
          foreground: const Color(0xFF166534)
        ),
      _PanelTone.warning => (
          background: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          foreground: const Color(0xFF92400E)
        ),
      _PanelTone.error => (
          background: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          foreground: const Color(0xFF991B1B)
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: config.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: config.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: config.foreground,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(double width) {
    final cards = [
      (
        'Net Odeme',
        _formatMoney(toplamNet),
        const Color(0xFF2563EB),
        Icons.account_balance_wallet
      ),
      (
        'Toplam Avans',
        _formatMoney(toplamAvans),
        const Color(0xFFF97316),
        Icons.payments_outlined
      ),
      (
        'Mesai Saati',
        '${toplamMesaiSaati.toStringAsFixed(1)} saat',
        const Color(0xFF7C3AED),
        Icons.schedule
      ),
      (
        'Performans',
        '${performansPuani.toStringAsFixed(0)}/100',
        const Color(0xFF059669),
        Icons.trending_up
      ),
    ];

    final itemWidth = width >= 1280
        ? (width - 48) / 4
        : width >= 900
            ? (width - 16) / 2
            : double.infinity;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map(
            (card) => SizedBox(
              width: itemWidth,
              child: _buildSummaryCard(
                title: card.$1,
                value: card.$2,
                color: card.$3,
                icon: card.$4,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

  Widget _buildFinancialPanel(double width) {
    return _buildPanel(
      title: 'Finansal Ozet',
      icon: Icons.summarize,
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _getPersonel(),
          _getAylikToplamMesaiUcreti(),
          _getAylikMesaiYemekUcreti(),
          _getAylikYolUcreti(),
          _getKesintiTutari(),
          _getOzetBakiyeler(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildNoticePanel(
              icon: Icons.error_outline,
              tone: _PanelTone.error,
              title: 'Finansal veriler yuklenemedi',
              message: '${snapshot.error}',
            );
          }

          final results = snapshot.data ?? const [];
          final personel =
              results.isNotEmpty ? results[0] as PersonelModel? : null;
          final mesaiUcreti = results.length > 1 ? results[1] as double : 0.0;
          final mesaiYemekUcreti =
              results.length > 2 ? results[2] as double : 0.0;
          final yolUcreti = results.length > 3 ? results[3] as double : 0.0;
          final kesintiTutari = results.length > 4 ? results[4] as double : 0.0;
          final ozetBakiyeler =
              results.length > 5 ? results[5] as Map<String, double> : {};

          final netMaas =
              personel != null ? double.tryParse(personel.netMaas) ?? 0.0 : 0.0;
          final yemekUcreti = personel != null
              ? double.tryParse(personel.yemekUcreti) ?? 0.0
              : 0.0;
          final toplamYemekUcreti = yemekUcreti + mesaiYemekUcreti;
          final prim = (ozetBakiyeler['prim'] ?? 0).toDouble();
          final ikramiye = (ozetBakiyeler['ikramiye'] ?? 0).toDouble();
          final avans = (ozetBakiyeler['avans'] ?? 0).toDouble();

          final toplamKazanc = netMaas +
              mesaiUcreti +
              toplamYemekUcreti +
              yolUcreti +
              ikramiye +
              prim -
              kesintiTutari -
              avans;

          final isWide = width >= 1080;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: toplamKazanc >= 0
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: toplamKazanc >= 0
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      toplamKazanc >= 0
                          ? Icons.account_balance_wallet
                          : Icons.warning_amber_rounded,
                      color: toplamKazanc >= 0
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Donem Sonucu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _formatMoney(toplamKazanc),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFinanceColumn(
                        title: 'Gelirler',
                        color: const Color(0xFF059669),
                        items: [
                          ('Net Maas', netMaas, false),
                          ('Mesai Ucreti', mesaiUcreti, false),
                          ('Yemek Ucreti', toplamYemekUcreti, false),
                          ('Yol Ucreti', yolUcreti, false),
                          ('Ikramiye', ikramiye, false),
                          ('Prim', prim, false),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _buildFinanceColumn(
                        title: 'Kesintiler',
                        color: const Color(0xFFDC2626),
                        items: [
                          ('Avans', avans, true),
                          ('Ucretsiz Izin', kesintiTutari, true),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _buildFinanceColumn(
                  title: 'Gelirler',
                  color: const Color(0xFF059669),
                  items: [
                    ('Net Maas', netMaas, false),
                    ('Mesai Ucreti', mesaiUcreti, false),
                    ('Yemek Ucreti', toplamYemekUcreti, false),
                    ('Yol Ucreti', yolUcreti, false),
                    ('Ikramiye', ikramiye, false),
                    ('Prim', prim, false),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFinanceColumn(
                  title: 'Kesintiler',
                  color: const Color(0xFFDC2626),
                  items: [
                    ('Avans', avans, true),
                    ('Ucretsiz Izin', kesintiTutari, true),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinanceColumn({
    required String title,
    required Color color,
    required List<(String, double, bool)> items,
  }) {
    final visibleItems = items.where((item) => item.$2 != 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (visibleItems.isEmpty)
            const Text(
              'Kayit bulunmuyor.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...visibleItems.map(
              (item) => _buildMetricRow(
                item.$1,
                _formatSignedMoney(item.$2, isNegative: item.$3),
                valueColor: item.$3 ? const Color(0xFFDC2626) : color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkPanel() {
    return _buildPanel(
      title: 'Calisma Ozeti',
      icon: Icons.work_outline,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMiniStat(
                'Calisilan Gun',
                '$toplamCalismaGunu gun',
                const Color(0xFF2563EB),
                Icons.calendar_today,
              ),
              _buildMiniStat(
                'Calisilabilir Gun',
                '$normalCalismaGunu gun',
                const Color(0xFF059669),
                Icons.check_circle,
              ),
              _buildMiniStat(
                'Izin',
                '$izinGunu gun',
                const Color(0xFFF59E0B),
                Icons.beach_access,
              ),
              _buildMiniStat(
                'Rapor',
                '$raporGunu gun',
                const Color(0xFFDC2626),
                Icons.local_hospital,
              ),
              _buildMiniStat(
                'Devamsizlik',
                '$devamsizlikGunu gun',
                const Color(0xFFB45309),
                Icons.warning_amber,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildMetricRow(
            'Toplam Mesai Saati',
            '${toplamMesaiSaati.toStringAsFixed(1)} saat',
          ),
          _buildMetricRow(
            'Toplam Kesinti',
            _formatMoney(toplamKesinti),
            valueColor: const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePanel() {
    final clampedValue = (performansPuani / 100).clamp(0.0, 1.0);

    return _buildPanel(
      title: 'Performans Degerlendirmesi',
      icon: Icons.trending_up,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Genel Durum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      performansDurumu,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getPerformanceColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${performansPuani.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    color: _getPerformanceColor(),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: clampedValue,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(_getPerformanceColor()),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _getPerformanceMessage(),
            style: const TextStyle(
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
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

  Widget _buildPanel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF0F172A),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(num value) {
    final text = value
        .toStringAsFixed(2)
        .replaceAll('.', ',')
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '\u20BA$text';
  }

  String _formatSignedMoney(num value, {required bool isNegative}) {
    final prefix = isNegative ? '-' : '+';
    return '$prefix${_formatMoney(value).replaceFirst('\u20BA', '\u20BA ')}';
  }
}

enum _PanelTone { success, warning, error }
