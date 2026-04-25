import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

class PuantajTabloPage extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  final String? initialDonem;
  final bool embedded;
  const PuantajTabloPage({
    super.key,
    this.personelId,
    this.personelAd,
    this.initialDonem,
    this.embedded = false,
  });

  @override
  State<PuantajTabloPage> createState() => _PuantajTabloPageState();
}

class _PuantajTabloPageState extends State<PuantajTabloPage> {
  bool yukleniyor = true;
  String? seciliDonem;
  List<Map<String, dynamic>> puantajList = [];

  @override
  void initState() {
    super.initState();
    seciliDonem = widget.initialDonem;
    debugPrint('PuantajTabloPage.initState: personelId=${widget.personelId}');
    _getPuantaj();
  }

  DateTime _raporTarihi() {
    final donem = seciliDonem;
    if (donem != null) {
      final match = RegExp(r'^(\d{4})-(\d{2})').firstMatch(donem);
      if (match != null) {
        final yil = int.tryParse(match.group(1)!);
        final ay = int.tryParse(match.group(2)!);
        if (yil != null && ay != null) {
          return DateTime(yil, ay, 1);
        }
      }
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Future<void> _getPuantaj() async {
    setState(() => yukleniyor = true);
    if (widget.personelId == null) return;

    final personel =
        await PersonelService().getPersonelById(widget.personelId!);
    final gunlukSaat =
        double.tryParse(personel?.gunlukCalismaSaati ?? '8') ?? 8;
    final netMaas = double.tryParse(personel?.netMaas ?? '0') ?? 0;

    final now = _raporTarihi();
    final ay = now.month;
    final yil = now.year;
    final daysInMonth = DateTime(yil, ay + 1, 0).day;

    final izinler = await IzinService()
        .getIzinlerForPersonel(widget.personelId!, donem: seciliDonem);
    int izinliGun = 0;
    int devamsizlikGun = 0;
    int raporluGun = 0;

    for (final izin in izinler) {
      if (izin.onayDurumu != 'onaylandi') continue;
      if (izin.baslangic.month == ay && izin.baslangic.year == yil) {
        if (izin.izinTuru == 'Y\u0131ll\u0131k \u0130zin' ||
            izin.izinTuru == 'Mazeret \u0130zni') {
          izinliGun += izin.gunSayisi;
        } else if (izin.izinTuru == 'Raporlu') {
          raporluGun += izin.gunSayisi;
        } else if (izin.izinTuru == '\u00DCcretsiz \u0130zin' ||
            izin.izinTuru == 'Devams\u0131zl\u0131k') {
          devamsizlikGun += izin.gunSayisi;
        }
      }
    }

    final mesailer = await MesaiService()
        .getMesailerForPersonel(widget.personelId!, donem: seciliDonem);
    double toplamFazlaMesai = 0;
    double toplamMesaiUcret = 0;
    final saatlikUcret =
        netMaas > 0 && gunlukSaat > 0 ? (netMaas / 30 / gunlukSaat) : 0;

    for (final m in mesailer) {
      if (m.onayDurumu != 'onaylandi') continue;
      if (m.tarih.month == ay && m.tarih.year == yil && m.saat != null) {
        toplamFazlaMesai += m.saat!;
        double hesaplananUcret = 0;
        if (m.mesaiTuru == 'Pazar') {
          hesaplananUcret = (netMaas / 30) * 2.0;
        } else if (m.mesaiTuru == 'Bayram') {
          final carpan = m.carpan ?? 1.5;
          hesaplananUcret = saatlikUcret * carpan * m.saat!;
        } else if (m.mesaiTuru == 'Saatlik') {
          hesaplananUcret = saatlikUcret * 1.5 * m.saat!;
        }
        final yemekUcreti = (m.mesaiTuru == 'Pazar' || m.mesaiTuru == 'Bayram')
            ? (m.yemekUcreti ?? 0)
            : 0;
        toplamMesaiUcret += hesaplananUcret + yemekUcreti;
      }
    }

    toplamFazlaMesai = double.parse(toplamFazlaMesai.toStringAsFixed(2));
    toplamMesaiUcret = double.parse(toplamMesaiUcret.toStringAsFixed(2));
    int calisilanGun = daysInMonth - izinliGun - devamsizlikGun - raporluGun;
    if (calisilanGun < 0) calisilanGun = 0;
    final aylikCalismaSaati = (calisilanGun * gunlukSaat).round();
    final gunlukUcret = netMaas / 30;
    final toplamUcretsizIzinKesinti = devamsizlikGun * gunlukUcret;

    puantajList = [
      {
        'calisilanGun': calisilanGun,
        'aylikCalismaSaati': aylikCalismaSaati,
        'fazlaMesai': toplamFazlaMesai,
        'mesaiUcreti': toplamMesaiUcret,
        'izinliGun': izinliGun,
        'raporluGun': raporluGun,
        'devamsizlikGun': devamsizlikGun,
        'ucretsizIzinKesinti': toplamUcretsizIzinKesinti,
        'gunlukUcret': gunlukUcret,
        'netMaas': netMaas,
      }
    ];
    if (!mounted) return;
    setState(() => yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: const Color(0xFFF4F7FB),
      child: SafeArea(
        top: widget.embedded,
        bottom: false,
        child: yukleniyor
            ? const LoadingWidget()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final data = puantajList.isEmpty ? null : puantajList.first;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      width >= 900 ? 24 : 16,
                      16,
                      width >= 900 ? 24 : 16,
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
                            if (data == null)
                              _buildEmptyState()
                            else ...[
                              _buildSummaryGrid(width, data),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  _buildPanel(
                                    width: width >= 1100
                                        ? (width - 64) / 2
                                        : double.infinity,
                                    title: 'Mesai Bilgileri',
                                    icon: Icons.schedule,
                                    child: Column(
                                      children: [
                                        _buildDetailRow(
                                          'Ayl\u0131k \u00C7al\u0131\u015Fma Saati',
                                          "${data['aylikCalismaSaati']} saat",
                                        ),
                                        _buildDetailRow(
                                          'Fazla Mesai',
                                          "${data['fazlaMesai']} saat",
                                        ),
                                        _buildDetailRow(
                                          'Mesai \u00DCcreti',
                                          "${(data['mesaiUcreti'] as num).toStringAsFixed(2)} TL",
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildPanel(
                                    width: width >= 1100
                                        ? (width - 64) / 2
                                        : double.infinity,
                                    title: '\u00DCcret Bilgileri',
                                    icon: Icons.payments_outlined,
                                    child: Column(
                                      children: [
                                        _buildDetailRow(
                                          'Net Maa\u015F',
                                          "${(data['netMaas'] as num).toStringAsFixed(2)} TL",
                                        ),
                                        _buildDetailRow(
                                          'G\u00FCnl\u00FCk \u00DCcret',
                                          "${(data['gunlukUcret'] as num).toStringAsFixed(2)} TL",
                                        ),
                                        _buildDetailRow(
                                          '\u00DCcretsiz \u0130zin Kesintisi',
                                          "${(data['ucretsizIzinKesinti'] as num).toStringAsFixed(2)} TL",
                                          isNegative:
                                              (data['ucretsizIzinKesinti']
                                                      as num) >
                                                  0,
                                        ),
                                      ],
                                    ),
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

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantaj Tablosu'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _getPuantaj,
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.assessment, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Puantaj Operasyon Paneli',
                  style: TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\u00C7al\u0131\u015Fma ve kesinti \u00F6zetini tek ekranda izleyin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.personelAd?.isNotEmpty == true
                      ? widget.personelAd!
                      : 'Se\u00E7ili personel',
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
            'D\u00F6nem Filtresi',
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
                _getPuantaj();
              },
              showAll: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 34, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Puantaj verisi bulunamad\u0131.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(double width, Map<String, dynamic> data) {
    final cards = [
      (
        '\u00C7al\u0131\u015F\u0131lan G\u00FCn',
        "${data['calisilanGun']} g\u00FCn",
        Colors.blue,
        Icons.work
      ),
      (
        '\u0130zinli G\u00FCn',
        "${data['izinliGun']} g\u00FCn",
        Colors.green,
        Icons.beach_access
      ),
      (
        'Raporlu G\u00FCn',
        "${data['raporluGun']} g\u00FCn",
        Colors.orange,
        Icons.local_hospital
      ),
      (
        'Devams\u0131zl\u0131k',
        "${data['devamsizlikGun']} g\u00FCn",
        Colors.red,
        Icons.warning
      ),
    ];
    final itemWidth = width >= 1280
        ? (width - 72) / 4
        : width >= 900
            ? (width - 56) / 2
            : double.infinity;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map((card) => SizedBox(
                width: itemWidth,
                child: _buildInfoCard(card.$1, card.$2, card.$3, card.$4),
              ))
          .toList(),
    );
  }

  Widget _buildPanel({
    required double width,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      child: Container(
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
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
