import 'package:flutter/material.dart';
import 'package:uretim_takip/models/izin_model.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
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
  String? hataMesaji;
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
    final personelId = widget.personelId?.trim();
    if (personelId == null || personelId.isEmpty) {
      if (!mounted) return;
      setState(() {
        hataMesaji = 'Personel ID bulunamadı.';
        puantajList = [];
        yukleniyor = false;
      });
      return;
    }

    final personel = await PersonelService().getPersonelById(personelId);
    if (personel == null) {
      if (!mounted) return;
      setState(() {
        hataMesaji = 'Personel bilgisi bulunamadı.';
        puantajList = [];
        yukleniyor = false;
      });
      return;
    }

    final gunlukSaat = _pozitifDouble(personel.gunlukCalismaSaati, 8);
    final haftalikCalismaGunu =
        _pozitifInt(personel.haftalikCalismaGunu, 6).clamp(1, 7).toInt();
    final netMaas = _pozitifDouble(personel.netMaas, 0);
    final raporTarihi = _raporTarihi();
    final ay = raporTarihi.month;
    final yil = raporTarihi.year;
    final donemBaslangic = DateTime(yil, ay, 1);
    final sonrakiDonem = DateTime(yil, ay + 1, 1);
    final calisilabilirGun = _calisilabilirGunSayisi(
      donemBaslangic,
      sonrakiDonem,
      haftalikCalismaGunu,
    );

    final izinler = await IzinService().getIzinlerForPersonel(personelId);
    int izinliGun = 0;
    int raporluGun = 0;
    int devamsizlikGun = 0;
    int onayliIzinKaydi = 0;
    int bekleyenIzinKaydi = 0;

    for (final izin in izinler) {
      final kesisenGun = _izinKesisimCalismaGunu(
        izin,
        donemBaslangic,
        sonrakiDonem,
        haftalikCalismaGunu,
      );
      if (kesisenGun <= 0) continue;
      if (izin.onayDurumu != 'onaylandi') {
        bekleyenIzinKaydi++;
        continue;
      }
      onayliIzinKaydi++;
      if (izin.izinTuru == 'Yıllık İzin' || izin.izinTuru == 'Mazeret İzni') {
        izinliGun += kesisenGun;
      } else if (izin.izinTuru == 'Raporlu') {
        raporluGun += kesisenGun;
      } else if (izin.izinTuru == 'Ücretsiz İzin' ||
          izin.izinTuru == 'Devamsızlık') {
        devamsizlikGun += kesisenGun;
      }
    }

    final mesailer = await MesaiService()
        .getMesailerForPersonel(personelId, donem: seciliDonem);
    final saatlikUcret =
        netMaas > 0 && gunlukSaat > 0 ? (netMaas / 30 / gunlukSaat) : 0.0;
    double toplamFazlaMesai = 0;
    double toplamMesaiUcret = 0;
    double toplamMesaiYemekUcreti = 0;
    int onayliMesaiKaydi = 0;
    int bekleyenMesaiKaydi = 0;

    for (final mesai in mesailer) {
      if (mesai.tarih.month != ay ||
          mesai.tarih.year != yil ||
          mesai.saat == null) {
        continue;
      }
      if (mesai.onayDurumu != 'onaylandi') {
        bekleyenMesaiKaydi++;
        continue;
      }
      onayliMesaiKaydi++;
      toplamFazlaMesai += mesai.saat!;
      double hesaplananUcret = 0;
      if (mesai.mesaiTuru == 'Pazar') {
        hesaplananUcret = (netMaas / 30) * 2.0;
      } else if (mesai.mesaiTuru == 'Bayram') {
        hesaplananUcret = saatlikUcret * (mesai.carpan ?? 1.5) * mesai.saat!;
      } else if (mesai.mesaiTuru == 'Saatlik') {
        hesaplananUcret = saatlikUcret * 1.5 * mesai.saat!;
      }
      final yemekUcreti =
          (mesai.mesaiTuru == 'Pazar' || mesai.mesaiTuru == 'Bayram')
              ? (mesai.yemekUcreti ?? 0)
              : 0;
      toplamMesaiUcret += hesaplananUcret;
      toplamMesaiYemekUcreti += yemekUcreti;
    }

    final calisilanGun =
        (calisilabilirGun - izinliGun - raporluGun - devamsizlikGun)
            .clamp(0, calisilabilirGun)
            .toInt();
    final aylikCalismaSaati =
        double.parse((calisilanGun * gunlukSaat).toStringAsFixed(2));
    final gunlukUcret = netMaas / 30;
    final toplamUcretsizIzinKesinti = devamsizlikGun * gunlukUcret;
    final mesaiUcreti = double.parse(toplamMesaiUcret.toStringAsFixed(2));
    final mesaiYemekUcreti =
        double.parse(toplamMesaiYemekUcreti.toStringAsFixed(2));
    final toplamMesaiEtki = mesaiUcreti + mesaiYemekUcreti;
    final netEtki = toplamMesaiEtki - toplamUcretsizIzinKesinti;

    if (!mounted) return;
    setState(() {
      hataMesaji = null;
      yukleniyor = false;
      puantajList = [
        {
          'calisilabilirGun': calisilabilirGun,
          'calisilanGun': calisilanGun,
          'aylikCalismaSaati': aylikCalismaSaati,
          'fazlaMesai': double.parse(toplamFazlaMesai.toStringAsFixed(2)),
          'mesaiUcreti': mesaiUcreti,
          'mesaiYemekUcreti': mesaiYemekUcreti,
          'toplamMesaiEtki': toplamMesaiEtki,
          'izinliGun': izinliGun,
          'raporluGun': raporluGun,
          'devamsizlikGun': devamsizlikGun,
          'ucretsizIzinKesinti': toplamUcretsizIzinKesinti,
          'netEtki': netEtki,
          'gunlukUcret': gunlukUcret,
          'saatlikUcret': saatlikUcret,
          'netMaas': netMaas,
          'gunlukSaat': gunlukSaat,
          'haftalikCalismaGunu': haftalikCalismaGunu,
          'onayliIzinKaydi': onayliIzinKaydi,
          'bekleyenIzinKaydi': bekleyenIzinKaydi,
          'onayliMesaiKaydi': onayliMesaiKaydi,
          'bekleyenMesaiKaydi': bekleyenMesaiKaydi,
        },
      ];
    });
  }

  double _pozitifDouble(String value, double fallback) {
    final parsed = double.tryParse(value);
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  int _pozitifInt(String value, int fallback) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0 ? parsed : fallback;
  }

  int _calisilabilirGunSayisi(
    DateTime start,
    DateTime endExclusive,
    int haftalikCalismaGunu,
  ) {
    var count = 0;
    for (var day = DateTime(start.year, start.month, start.day);
        day.isBefore(endExclusive);
        day = day.add(const Duration(days: 1))) {
      if (day.weekday <= haftalikCalismaGunu) count++;
    }
    return count;
  }

  int _izinKesisimCalismaGunu(
    IzinModel izin,
    DateTime donemBaslangic,
    DateTime sonrakiDonem,
    int haftalikCalismaGunu,
  ) {
    final izinBaslangic =
        DateTime(izin.baslangic.year, izin.baslangic.month, izin.baslangic.day);
    final izinBitisDahil =
        DateTime(izin.bitis.year, izin.bitis.month, izin.bitis.day);
    final izinBitisExclusive = izinBitisDahil.add(const Duration(days: 1));
    final start =
        izinBaslangic.isAfter(donemBaslangic) ? izinBaslangic : donemBaslangic;
    final end = izinBitisExclusive.isBefore(sonrakiDonem)
        ? izinBitisExclusive
        : sonrakiDonem;
    if (!start.isBefore(end)) return 0;
    return _calisilabilirGunSayisi(start, end, haftalikCalismaGunu);
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
                      width >= 900 ? 24 : 12,
                      width >= 900 ? 16 : 12,
                      width >= 900 ? 24 : 12,
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
                              _buildDetailPanels(width, data),
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
    final compact = width < 560;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width >= 960 ? 24 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3FAE), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assessment,
                      color: Colors.white, size: 23),
                ),
                const SizedBox(height: 12),
                _buildHeroText(compact: true),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assessment,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildHeroText(compact: false)),
              ],
            ),
    );
  }

  Widget _buildHeroText({required bool compact}) {
    return Column(
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
        Text(
          'Çalışma, izin ve mesai etkisi',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.personelAd?.isNotEmpty == true
              ? widget.personelAd!
              : 'Seçili personel',
          style: const TextStyle(
            color: Color(0xFFDCE7FF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(double width) {
    final compact = width < 560;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: compact ? double.infinity : 140,
            child: const Text(
              'Dönem Filtresi',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
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
          SizedBox(
            width: compact ? double.infinity : null,
            child: OutlinedButton.icon(
              onPressed: _getPuantaj,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yenile'),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 34, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            hataMesaji ?? 'Bu dönem için onaylı izin/mesai yok.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
        'Çalışılabilir Gün',
        "${data['calisilabilirGun']} gün",
        Colors.blue,
        Icons.calendar_month
      ),
      (
        'Çalışılan Gün',
        "${data['calisilanGun']} gün",
        Colors.green,
        Icons.work
      ),
      (
        'İzinli Gün',
        "${data['izinliGun']} gün",
        Colors.teal,
        Icons.beach_access
      ),
      (
        'Devamsızlık',
        "${data['devamsizlikGun']} gün",
        Colors.red,
        Icons.warning
      ),
      (
        'Fazla Mesai',
        "${(data['fazlaMesai'] as num).toStringAsFixed(2)} saat",
        Colors.orange,
        Icons.schedule
      ),
      (
        'Net Etki',
        "${(data['netEtki'] as num).toStringAsFixed(2)} TL",
        (data['netEtki'] as num) >= 0 ? Colors.purple : Colors.red,
        Icons.account_balance_wallet
      ),
    ];
    final itemWidth = width >= 1180
        ? (width - 80) / 3
        : width >= 680
            ? (width - 40) / 2
            : double.infinity;
    return Wrap(
      spacing: width >= 680 ? 16 : 10,
      runSpacing: width >= 680 ? 16 : 10,
      children: cards
          .map((card) => SizedBox(
                width: itemWidth,
                child: _buildInfoCard(card.$1, card.$2, card.$3, card.$4),
              ))
          .toList(),
    );
  }

  Widget _buildDetailPanels(double width, Map<String, dynamic> data) {
    final panelWidth = width >= 1040 ? (width - 64) / 2 : double.infinity;
    return Wrap(
      spacing: width >= 680 ? 16 : 10,
      runSpacing: width >= 680 ? 16 : 10,
      children: [
        _buildPanel(
          width: panelWidth,
          title: 'Mesai Bilgileri',
          icon: Icons.schedule,
          child: Column(
            children: [
              _buildDetailRow(
                  'Onaylı mesai kaydı', '${data['onayliMesaiKaydi']} kayıt'),
              _buildDetailRow('Bekleyen mesai kaydı',
                  '${data['bekleyenMesaiKaydi']} kayıt'),
              _buildDetailRow(
                'Fazla mesai',
                "${(data['fazlaMesai'] as num).toStringAsFixed(2)} saat",
              ),
              _buildDetailRow(
                'Mesai ücreti',
                "${(data['mesaiUcreti'] as num).toStringAsFixed(2)} TL",
              ),
              _buildDetailRow(
                'Mesai yemek ücreti',
                "${(data['mesaiYemekUcreti'] as num).toStringAsFixed(2)} TL",
              ),
            ],
          ),
        ),
        _buildPanel(
          width: panelWidth,
          title: 'İzin ve Devam',
          icon: Icons.fact_check_outlined,
          child: Column(
            children: [
              _buildDetailRow(
                  'Onaylı izin kaydı', '${data['onayliIzinKaydi']} kayıt'),
              _buildDetailRow(
                  'Bekleyen izin kaydı', '${data['bekleyenIzinKaydi']} kayıt'),
              _buildDetailRow('Ücretli izin', '${data['izinliGun']} gün'),
              _buildDetailRow('Raporlu gün', '${data['raporluGun']} gün'),
              _buildDetailRow(
                  'Devamsızlık/ücretsiz izin', '${data['devamsizlikGun']} gün'),
            ],
          ),
        ),
        _buildPanel(
          width: panelWidth,
          title: 'Ücret Bilgileri',
          icon: Icons.payments_outlined,
          child: Column(
            children: [
              _buildDetailRow(
                'Net maaş',
                "${(data['netMaas'] as num).toStringAsFixed(2)} TL",
              ),
              _buildDetailRow(
                'Ücretsiz izin kesintisi',
                "${(data['ucretsizIzinKesinti'] as num).toStringAsFixed(2)} TL",
                isNegative: (data['ucretsizIzinKesinti'] as num) > 0,
              ),
              _buildDetailRow(
                'Mesai toplam etkisi',
                "${(data['toplamMesaiEtki'] as num).toStringAsFixed(2)} TL",
              ),
              _buildDetailRow(
                'Net etki',
                "${(data['netEtki'] as num).toStringAsFixed(2)} TL",
                isNegative: (data['netEtki'] as num) < 0,
              ),
            ],
          ),
        ),
        _buildPanel(
          width: panelWidth,
          title: 'Hesap Detayı',
          icon: Icons.info_outline,
          child: Column(
            children: [
              _buildDetailRow('Haftalık çalışma günü',
                  '${data['haftalikCalismaGunu']} gün'),
              _buildDetailRow(
                'Günlük çalışma saati',
                "${(data['gunlukSaat'] as num).toStringAsFixed(2)} saat",
              ),
              _buildDetailRow(
                'Aylık çalışma saati',
                "${(data['aylikCalismaSaati'] as num).toStringAsFixed(2)} saat",
              ),
              _buildDetailRow(
                'Günlük ücret',
                "${(data['gunlukUcret'] as num).toStringAsFixed(2)} TL",
              ),
              _buildDetailRow(
                'Saatlik baz ücret',
                "${(data['saatlikUcret'] as num).toStringAsFixed(2)} TL",
              ),
            ],
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(8),
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
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
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
