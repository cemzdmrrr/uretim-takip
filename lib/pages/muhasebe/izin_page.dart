import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/models/izin_model.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

class IzinKaydi {
  final String personelAd;
  final String izinTuru;
  final DateTime baslangic;
  final DateTime bitis;
  final String aciklama;

  IzinKaydi({
    required this.personelAd,
    required this.izinTuru,
    required this.baslangic,
    required this.bitis,
    required this.aciklama,
  });
}

class IzinPage extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  final String? initialDonem;
  final bool embedded;
  const IzinPage({
    super.key,
    this.personelId,
    this.personelAd,
    this.initialDonem,
    this.embedded = false,
  });

  @override
  State<IzinPage> createState() => _IzinPageState();
}

class _IzinPageState extends State<IzinPage> {
  List<IzinModel> izinler = [];
  bool yukleniyor = true;
  String? seciliDonem;
  String? currentUserId;
  String? currentUserAd;
  String? currentUserRole;

  int kalanYillikIzin = 0;
  int kullanilanYillikIzin = 0;
  int yillikIzinHakki = 14;
  int devredenIzin = 0;
  int toplamIzinHakki = 14;
  PersonelModel? personel;

  @override
  void initState() {
    super.initState();
    seciliDonem = widget.initialDonem;
    debugPrint('IzinPage.initState: personelId=${widget.personelId}');
    _getCurrentUser();
    _getIzinler();
    _getPersonel();
  }

  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id;
    if (currentUserId != null) {
      final servis = PersonelService();
      final personeller = await servis.getPersoneller();
      PersonelModel? me;
      try {
        me = personeller.firstWhere((p) => p.userId == currentUserId);
      } catch (_) {
        me = null;
      }
      currentUserAd = me?.ad;
    }
    if (currentUserId != null) {
      final response = await Supabase.instance.client
          .from(DbTables.userRoles)
          .select()
          .eq('user_id', currentUserId as Object)
          .maybeSingle();
      currentUserRole = response?['role'] ?? 'user';
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _getIzinler() async {
    if (!mounted) {
      return;
    }
    setState(() => yukleniyor = true);
    final servis = IzinService();
    if (currentUserRole == 'admin') {
      if (widget.personelId != null) {
        izinler = await servis.getIzinlerForPersonel(
          widget.personelId!,
          donem: seciliDonem,
        );
      } else {
        izinler = await servis.getTumIzinler();
      }
    } else if (widget.personelId != null) {
      izinler = await servis.getIzinlerForPersonel(
        widget.personelId!,
        donem: seciliDonem,
      );
    } else if (currentUserId != null) {
      izinler = await servis.getIzinlerForPersonel(
        currentUserId!,
        donem: seciliDonem,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => yukleniyor = false);
  }

  Future<void> _izinEkle() async {
    final yeniIzin = await showDialog<IzinModel>(
      context: context,
      builder: (context) => IzinEkleDialog(
        personelId: currentUserId,
        personelAd: currentUserAd,
        isAdmin: currentUserRole == 'admin',
        initialDonem: seciliDonem,
      ),
    );
    if (yeniIzin != null && mounted) {
      try {
        await IzinService().addIzin(yeniIzin);
        if (!mounted) {
          return;
        }
        context.showSnackBar('Izin kaydi basariyla olusturuldu!');
        await _getIzinler();
      } catch (e) {
        debugPrint('Izin ekleme hatasi: $e');
        if (!mounted) {
          return;
        }
        context.showSnackBar('Izin kaydi hatasi: $e');
      }
    }
  }

  Future<void> _getPersonel() async {
    final String? pid = widget.personelId ?? currentUserId;
    if (pid == null) {
      return;
    }
    final servis = PersonelService();
    final p = await servis.getPersonelById(pid);
    if (p != null) {
      personel = p;
      yillikIzinHakki = int.tryParse(p.yillikIzinHakki) ?? 14;
      try {
        final izinOzeti =
            await IzinService().getIzinOzeti(pid, yillikIzinHakki);
        devredenIzin = izinOzeti['devredenIzin'] ?? 0;
        toplamIzinHakki = izinOzeti['toplamHak'] ?? yillikIzinHakki;
        kullanilanYillikIzin = izinOzeti['buYilKullanilan'] ?? 0;
        kalanYillikIzin = izinOzeti['kalan'] ?? 0;
      } catch (e) {
        debugPrint('Izin ozeti hesaplanamadi: $e');
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      onPressed: _izinEkle,
      backgroundColor: const Color(0xFF2563EB),
      tooltip: '\u0130zin Kayd\u0131 Ekle',
      child: const Icon(Icons.add),
    );

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
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      width >= 900 ? 24 : 16,
                      16,
                      width >= 900 ? 24 : 16,
                      112,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: widget.embedded ? 1440 : 1320,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIzinHeroSection(width),
                            const SizedBox(height: 20),
                            _buildIzinToolbarSection(width),
                            if (personel != null) ...[
                              const SizedBox(height: 20),
                              _buildIzinSummarySection(width),
                            ],
                            const SizedBox(height: 20),
                            _buildIzinListSection(width),
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
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: fab,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0130zin ve Devams\u0131zl\u0131k Y\u00F6netimi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: body,
      floatingActionButton: fab,
    );
  }

  Widget _buildIzinHeroSection(double width) {
    final activeDonem = seciliDonem ?? 'T\u00FCm D\u00F6nemler';
    final isNarrow = width < 980;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3FAE), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isNarrow ? width : 520),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.event_available,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '\u0130zin Planlama Paneli',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '\u0130zin ak\u0131\u015F\u0131n\u0131 tek ekranda y\u00F6netin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Talep, onay, devreden hak ve kalan izin bakiyesini ayn\u0131 operasyon ak\u0131\u015F\u0131nda izleyin.',
                        style: TextStyle(
                          color: Color(0xFFDCE7FF),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktif G\u00F6r\u00FCn\u00FCm',
                  style: TextStyle(
                    color: Color(0xFFDCE7FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeDonem,
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

  Widget _buildIzinToolbarSection(double width) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, size: 18, color: Color(0xFF475569)),
                SizedBox(width: 10),
                Text(
                  'D\u00F6nem Filtresi',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: width >= 720 ? 280 : double.infinity,
            child: DonemSecici(
              seciliDonem: seciliDonem,
              onDonemChanged: (donem) {
                setState(() {
                  seciliDonem = donem;
                });
                _getIzinler();
              },
              showAll: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '\${izinler.length} kay\u0131t',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIzinSummarySection(double width) {
    final items = [
      _IzinMetricData('Y\u0131ll\u0131k Hak', '$yillikIzinHakki g\u00FCn',
          Icons.workspace_premium, const Color(0xFF2563EB)),
      _IzinMetricData('Devir', '$devredenIzin g\u00FCn', Icons.redo,
          const Color(0xFF7C3AED)),
      _IzinMetricData('Toplam Hak', '$toplamIzinHakki g\u00FCn',
          Icons.inventory_2, const Color(0xFF0F766E)),
      _IzinMetricData('Kullan\u0131lan', '$kullanilanYillikIzin g\u00FCn',
          Icons.south_east, const Color(0xFFEA580C)),
      _IzinMetricData(
          'Kalan',
          '$kalanYillikIzin g\u00FCn',
          Icons.check_circle,
          kalanYillikIzin > 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626)),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items
          .map(
            (item) => SizedBox(
              width: width >= 1280
                  ? (width - 64) / 5
                  : width >= 900
                      ? (width - 48) / 3
                      : width >= 620
                          ? (width - 32) / 2
                          : double.infinity,
              child: _buildIzinMetricCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildIzinMetricCard(_IzinMetricData item) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 18,
                    color: item.color,
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

  Widget _buildIzinListSection(double width) {
    return Container(
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fact_check,
                    color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '\u0130zin Kay\u0131tlar\u0131',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\u0130zin ge\u00E7mi\u015Fi, durum ve onay hareketleri',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (izinler.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 34, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'Hen\u00FCz izin kayd\u0131 yok.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: izinler
                  .map((izin) => _buildIzinRecordCard(izin, width))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIzinRecordCard(IzinModel izin, double width) {
    final allowEdit = !(currentUserRole == DbTables.personel &&
        izin.onayDurumu == 'onaylandi');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEAFE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.beach_access,
                    color: Color(0xFF2563EB), size: 22),
              ),
              SizedBox(
                width: width >= 720 ? width - 280 : double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\${izin.izinTuru} - \${izin.gunSayisi} g\u00FCn',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\${izin.baslangic.day}.\${izin.baslangic.month}.\${izin.baslangic.year} - \${izin.bitis.day}.\${izin.bitis.month}.\${izin.bitis.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              _buildIzinStatusChip(izin.onayDurumu),
            ],
          ),
          if (izin.aciklama.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              izin.aciklama,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (currentUserRole == 'admin' && izin.onayDurumu == 'beklemede')
                _buildIzinActionButton(
                  icon: Icons.task_alt,
                  label: 'Onayla',
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: const Color(0xFF166534),
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    final userId = user?.id;
                    if (userId == null) return;
                    await IzinService().updateIzinDurum(
                      izin.id!,
                      'onaylandi',
                      onaylayanId: userId,
                    );
                    if (!context.mounted) return;
                    context.showSnackBar('\u0130zin onayland\u0131.');
                    if (mounted) {
                      _getIzinler();
                    }
                  },
                ),
              if (allowEdit)
                _buildIzinActionButton(
                  icon: Icons.edit_outlined,
                  label: 'D\u00FCzenle',
                  backgroundColor: const Color(0xFFFFEDD5),
                  foregroundColor: const Color(0xFF9A3412),
                  onPressed: () async {
                    final guncellenen = await showDialog<IzinModel>(
                      context: context,
                      builder: (context) => IzinEkleDialog(
                        personelId: izin.personelId,
                        personelAd: widget.personelAd,
                        isAdmin: currentUserRole == 'admin',
                        initialDonem: seciliDonem,
                      ),
                    );
                    if (guncellenen != null) {
                      await IzinService().updateIzin(
                        izin.id!,
                        guncellenen.toMap(),
                      );
                      if (mounted) {
                        _getIzinler();
                      }
                    }
                  },
                ),
              if (allowEdit)
                _buildIzinActionButton(
                  icon: Icons.delete_outline,
                  label: 'Sil',
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFB91C1C),
                  onPressed: () async {
                    if (izin.id == null || izin.id!.isEmpty) {
                      context.showSnackBar(
                        'Bu kayd\u0131n ID bilgisi yok, silme yap\u0131lamaz.',
                      );
                      return;
                    }
                    final onay = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('\u0130zin Sil'),
                        content: const Text(
                          'Bu izin kayd\u0131n\u0131 silmek istedi\u011Finize emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('\u0130ptal'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                    if (onay == true) {
                      await IzinService().deleteIzin(izin.id!);
                      if (mounted) {
                        _getIzinler();
                      }
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIzinActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required Future<void> Function() onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(color: foregroundColor.withValues(alpha: 0.16)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildIzinStatusChip(String durum) {
    late final Color bg;
    late final Color fg;
    late final String label;

    switch (durum) {
      case 'onaylandi':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        label = 'Onayland\u0131';
        break;
      case 'red':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Reddedildi';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Beklemede';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IzinMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _IzinMetricData(this.label, this.value, this.icon, this.color);
}

class IzinEkleDialog extends StatefulWidget {
  final String? personelId;
  final String? personelAd;
  final bool isAdmin;
  final String? initialDonem;
  const IzinEkleDialog(
      {super.key,
      this.personelId,
      this.personelAd,
      this.isAdmin = false,
      this.initialDonem});
  @override
  State<IzinEkleDialog> createState() => _IzinEkleDialogState();
}

class _IzinEkleDialogState extends State<IzinEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  String izinTuru = 'Yıllık İzin';
  DateTime? baslangic;
  DateTime? bitis;
  String aciklama = '';
  String? seciliPersonelId;
  String? seciliPersonelAd;
  List<Map<String, String>> personelList = [];
  bool yukleniyor = true;
  String? modalDonem;

  @override
  void initState() {
    super.initState();
    modalDonem = widget.initialDonem;
    _loadPersoneller();
  }

  DateTime? _donemBaslangici() {
    final donem = modalDonem;
    if (donem == null || donem.isEmpty) {
      return null;
    }

    final parcalar = donem.split('-');
    if (parcalar.length != 2) {
      return null;
    }

    final yil = int.tryParse(parcalar[0]);
    final ay = int.tryParse(parcalar[1]);
    if (yil == null || ay == null) {
      return null;
    }

    return DateTime(yil, ay, 1);
  }

  DateTime? _donemBitisi() {
    final baslangic = _donemBaslangici();
    if (baslangic == null) {
      return null;
    }

    return DateTime(baslangic.year, baslangic.month + 1, 0);
  }

  bool _tarihDonemIleUyumlu(DateTime tarih) {
    final baslangic = _donemBaslangici();
    final bitis = _donemBitisi();
    if (baslangic == null || bitis == null) {
      return true;
    }

    final gun = DateTime(tarih.year, tarih.month, tarih.day);
    return !gun.isBefore(baslangic) && !gun.isAfter(bitis);
  }

  void _modalDonemDegistir(String? donem) {
    final oncekiBaslangic = baslangic;
    final oncekiBitis = bitis;

    setState(() {
      modalDonem = donem;

      final donemBaslangici = _donemBaslangici();
      final donemBitisi = _donemBitisi();
      if (donemBaslangici == null || donemBitisi == null) {
        return;
      }

      if (oncekiBaslangic == null || !_tarihDonemIleUyumlu(oncekiBaslangic)) {
        baslangic = donemBaslangici;
      }

      final referansBitis = oncekiBitis ?? oncekiBaslangic;
      if (referansBitis == null || !_tarihDonemIleUyumlu(referansBitis)) {
        bitis = baslangic ?? donemBaslangici;
      }

      if (bitis != null && bitis!.isBefore(baslangic!)) {
        bitis = baslangic;
      }

      if (bitis != null && bitis!.isAfter(donemBitisi)) {
        bitis = donemBitisi;
      }
    });
  }

  Future<void> _loadPersoneller() async {
    if (widget.isAdmin) {
      try {
        final servis = PersonelService();
        final personeller = await servis.getPersoneller();
        setState(() {
          personelList =
              personeller.map((p) => {'id': p.userId, 'ad': p.ad}).toList();
          if (personelList.isNotEmpty) {
            seciliPersonelId = personelList.first['id'];
            seciliPersonelAd = personelList.first['ad'];
          }
          yukleniyor = false;
        });
      } catch (e) {
        setState(() => yukleniyor = false);
      }
    } else {
      seciliPersonelId = widget.personelId;
      seciliPersonelAd = widget.personelAd;
      yukleniyor = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.beach_access,
                      color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'İzin Kaydı Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            yukleniyor
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()))
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Dönem seçici
                          DonemSecici(
                            seciliDonem: modalDonem,
                            onDonemChanged: _modalDonemDegistir,
                          ),
                          const SizedBox(height: 16),
                          widget.isAdmin
                              ? DropdownButtonFormField<String>(
                                  initialValue: seciliPersonelId,
                                  items: personelList
                                      .map((p) => DropdownMenuItem(
                                            value: p['id'],
                                            child: Text(p['ad'] ?? '',
                                                style: const TextStyle(
                                                    color: Colors.green)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      seciliPersonelId = v;
                                      seciliPersonelAd =
                                          personelList.firstWhere(
                                              (p) => p['id'] == v)['ad'];
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Personel',
                                    labelStyle:
                                        const TextStyle(color: Colors.green),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.green.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.green.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Colors.green, width: 2),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.green),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person,
                                          color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        seciliPersonelAd ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: izinTuru,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Yıllık İzin',
                                  child: Text('Yıllık İzin',
                                      style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(
                                  value: 'Mazeret İzni',
                                  child: Text('Mazeret İzni',
                                      style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(
                                  value: 'Raporlu',
                                  child: Text('Raporlu',
                                      style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(
                                  value: 'Ücretsiz İzin',
                                  child: Text('Ücretsiz İzin',
                                      style: TextStyle(color: Colors.green))),
                              DropdownMenuItem(
                                  value: 'Devamsızlık',
                                  child: Text('Devamsızlık',
                                      style: TextStyle(color: Colors.green))),
                            ],
                            onChanged: (v) =>
                                setState(() => izinTuru = v ?? 'Yıllık İzin'),
                            decoration: InputDecoration(
                              labelText: 'İzin Türü',
                              labelStyle: const TextStyle(color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.green.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.green.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.green),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final donemBaslangici =
                                        _donemBaslangici() ?? DateTime(2020);
                                    final donemBitisi =
                                        _donemBitisi() ?? DateTime(2100);
                                    final secilen = await showDatePicker(
                                      context: context,
                                      initialDate: baslangic ??
                                          _donemBaslangici() ??
                                          DateTime.now(),
                                      firstDate: donemBaslangici,
                                      lastDate: donemBitisi,
                                    );
                                    if (secilen != null)
                                      setState(() => baslangic = secilen);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          baslangic == null
                                              ? 'Başlangıç Tarihi'
                                              : '${baslangic!.day}.${baslangic!.month}.${baslangic!.year}',
                                          style: TextStyle(
                                            color: baslangic == null
                                                ? Colors.grey
                                                : Colors.green,
                                            fontWeight: baslangic == null
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final donemBaslangici =
                                        _donemBaslangici() ?? DateTime(2020);
                                    final donemBitisi =
                                        _donemBitisi() ?? DateTime(2100);
                                    final secilen = await showDatePicker(
                                      context: context,
                                      initialDate: bitis ??
                                          baslangic ??
                                          _donemBaslangici() ??
                                          DateTime.now(),
                                      firstDate: baslangic ?? donemBaslangici,
                                      lastDate: donemBitisi,
                                    );
                                    if (secilen != null)
                                      setState(() => bitis = secilen);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          bitis == null
                                              ? 'Bitiş Tarihi'
                                              : '${bitis!.day}.${bitis!.month}.${bitis!.year}',
                                          style: TextStyle(
                                            color: bitis == null
                                                ? Colors.grey
                                                : Colors.green,
                                            fontWeight: bitis == null
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Açıklama',
                              labelStyle: const TextStyle(color: Colors.green),
                              prefixIcon:
                                  const Icon(Icons.note, color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.green.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.green.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.green),
                            onChanged: (v) => aciklama = v,
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('İptal', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _izinKaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _izinKaydet() {
    if (_formKey.currentState?.validate() ?? false) {
      if (baslangic == null || bitis == null) return;
      if (!_tarihDonemIleUyumlu(baslangic!) || !_tarihDonemIleUyumlu(bitis!)) {
        context.showSnackBar('İzin tarihleri seçili dönemin içinde olmalıdır.');
        return;
      }
      if (bitis!.isBefore(baslangic!)) {
        context.showSnackBar('Bitiş tarihi başlangıç tarihinden önce olamaz.');
        return;
      }
      final gunSayisi = bitis!.difference(baslangic!).inDays + 1;
      Navigator.pop(
        context,
        IzinModel(
          id: null,
          personelId: seciliPersonelId!,
          izinTuru: izinTuru,
          baslangic: baslangic!,
          bitis: bitis!,
          aciklama: aciklama,
          onayDurumu: 'beklemede',
          onaylayanId: null,
          gunSayisi: gunSayisi,
          userId: seciliPersonelId!, // user_id ve personel_id aynı olacak
        ),
      );
    }
  }
}
