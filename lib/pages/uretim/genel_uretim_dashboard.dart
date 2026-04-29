import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/config/asama_registry.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/utu_paket_dashboard.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GenelUretimDashboard extends StatefulWidget {
  const GenelUretimDashboard({super.key});

  @override
  State<GenelUretimDashboard> createState() => _GenelUretimDashboardState();
}

class _GenelUretimDashboardState extends State<GenelUretimDashboard> {
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _asamalariYukle();
  }

  Future<void> _asamalariYukle({bool force = false}) async {
    if (force) {
      AsamaRegistry.cacheTemizle();
    }

    if (mounted) {
      setState(() {
        _yukleniyor = true;
        _hata = null;
      });
    }

    try {
      await AsamaRegistry.yukle();
      if (mounted) {
        setState(() => _yukleniyor = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _hata = 'Aşamalar yüklenemedi: $e';
        });
      }
    }
  }

  Future<void> _sayfayiYenile() async {
    final tenant = context.read<TenantProvider>();
    final firmaId = tenant.firmaId;
    if (firmaId != null) {
      await tenant.firmaSecimi(firmaId);
    }
    await _asamalariYukle(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    final aktifDallar = tenant.aktifUretimDallari;

    if (_yukleniyor) {
      return _PageScaffold(
        onRefresh: () => _sayfayiYenile(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hata != null) {
      return _PageScaffold(
        onRefresh: () => _sayfayiYenile(),
        body: _StateView(
          icon: Icons.error_outline,
          title: 'Aşamalar yüklenemedi',
          message: _hata!,
          actionLabel: 'Yenile',
          onAction: () => _sayfayiYenile(),
        ),
      );
    }

    if (aktifDallar.isEmpty) {
      return _PageScaffold(
        onRefresh: () => _sayfayiYenile(),
        body: _StateView(
          icon: tenant.firmaSecildi
              ? Icons.factory_outlined
              : Icons.business_outlined,
          title:
              tenant.firmaSecildi ? 'Aktif üretim dalı yok' : 'Firma seçilmedi',
          message: tenant.firmaSecildi
              ? '${tenant.firmaAdi.isEmpty ? 'Bu firma' : tenant.firmaAdi} için aktif üretim dalı bulunamadı. Firma ayarlarından en az bir üretim dalı seçilmelidir.'
              : 'Genel üretim ekranı için önce aktif firma bağlamı yüklenmelidir.',
        ),
      );
    }

    if (aktifDallar.length == 1) {
      return _PageScaffold(
        onRefresh: () => _sayfayiYenile(),
        body: _UretimDaliDashboard(
          tekstilDali: aktifDallar.first,
          onRefresh: () => _sayfayiYenile(),
        ),
      );
    }

    return DefaultTabController(
      length: aktifDallar.length,
      child: _PageScaffold(
        onRefresh: () => _sayfayiYenile(),
        bottom: TabBar(
          isScrollable: aktifDallar.length > 3,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            for (final dal in aktifDallar)
              Tab(
                child: _DalSekmeBasligi(dalKodu: dal),
              ),
          ],
        ),
        body: TabBarView(
          children: [
            for (final dal in aktifDallar)
              _UretimDaliDashboard(
                tekstilDali: dal,
                onRefresh: () => _sayfayiYenile(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? bottom;
  final VoidCallback onRefresh;

  const _PageScaffold({
    required this.body,
    required this.onRefresh,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Üretim'),
        bottom: bottom,
        actions: [
          Tooltip(
            message: 'Model ara',
            child: IconButton(
              onPressed: () => showSearch<_UretimAramaSonucu?>(
                context: context,
                delegate: _GenelUretimAramaDelegate(),
              ),
              icon: const Icon(Icons.search),
            ),
          ),
          Tooltip(
            message: 'Yenile',
            child: IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _DalSekmeBasligi extends StatelessWidget {
  final String dalKodu;

  const _DalSekmeBasligi({required this.dalKodu});

  @override
  Widget build(BuildContext context) {
    final firmaId = context.read<TenantProvider>().firmaId;

    return FutureBuilder<_AsamaIstatistik>(
      future: _dalIstatistigiGetir(dalKodu, firmaId),
      builder: (context, snapshot) {
        final toplam = snapshot.data?.toplamIs ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_dalIkonu(dalKodu), size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _dalEtiketi(dalKodu),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (snapshot.connectionState != ConnectionState.done) ...[
              const SizedBox(width: 6),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white,
                ),
              ),
            ] else if (toplam > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$toplam',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<_AsamaIstatistik> _dalIstatistigiGetir(
    String dalKodu,
    String? firmaId,
  ) async {
    final asamalar = AsamaRegistry.dashboardAsamalari(dalKodu);
    final sonuclar = await Future.wait(
      asamalar.map(
        (asama) => _AsamaIstatistikServisi.asamaIstatistigiGetir(
          asama,
          firmaId,
        ),
      ),
    );

    if (sonuclar.any((istatistik) => istatistik.hataVar)) {
      return const _AsamaIstatistik(hataVar: true);
    }

    return _AsamaIstatistik.toplam(sonuclar);
  }
}

class _UretimDaliDashboard extends StatelessWidget {
  final String tekstilDali;
  final Future<void> Function()? onRefresh;

  const _UretimDaliDashboard({
    required this.tekstilDali,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final asamalar = AsamaRegistry.dashboardAsamalari(tekstilDali);

    if (asamalar.isEmpty) {
      return const _StateView(
        icon: Icons.view_module_outlined,
        title: 'Aşama tanımı yok',
        message: 'Bu üretim dalı için gösterilecek aşama bulunamadı.',
      );
    }

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _gridKolonSayisi(width);
        final horizontalPadding = width < 640 ? 12.0 : 20.0;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 16, horizontalPadding, 8),
              sliver: SliverToBoxAdapter(
                child: _DalOzeti(
                  dalKodu: tekstilDali,
                  asamalar: asamalar,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 8, horizontalPadding, 20),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: width < 560 ? 246 : 256,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AsamaKarti(
                    asama: asamalar[index],
                    index: index,
                    toplam: asamalar.length,
                  ),
                  childCount: asamalar.length,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (onRefresh == null) return content;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: content,
    );
  }

  int _gridKolonSayisi(double width) {
    if (width < 560) return 1;
    if (width < 900) return 2;
    if (width < 1220) return 3;
    return 4;
  }
}

class _DalOzeti extends StatelessWidget {
  final String dalKodu;
  final List<AsamaTanim> asamalar;

  const _DalOzeti({
    required this.dalKodu,
    required this.asamalar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anaRenk = asamalar.first.renk;
    final zorunluSayisi = asamalar.where((asama) => asama.zorunlu).length;
    final genelAkisSayisi =
        asamalar.where((asama) => asama.eskiTabloAdi == null).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: anaRenk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_dalIkonu(dalKodu), color: anaRenk, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dalEtiketi(dalKodu),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BilgiEtiketi(
                            icon: Icons.account_tree_outlined,
                            label: '${asamalar.length} aşama'),
                        _BilgiEtiketi(
                            icon: Icons.verified_outlined,
                            label: '$zorunluSayisi zorunlu'),
                        _BilgiEtiketi(
                          icon: genelAkisSayisi == 0
                              ? Icons.history
                              : Icons.schema_outlined,
                          label: genelAkisSayisi == 0
                              ? 'Mevcut akış'
                              : '$genelAkisSayisi genel akış',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DalKpiOzeti(asamalar: asamalar),
          const SizedBox(height: 14),
          _AsamaSeridi(asamalar: asamalar),
        ],
      ),
    );
  }
}

class _DalKpiOzeti extends StatelessWidget {
  final List<AsamaTanim> asamalar;

  const _DalKpiOzeti({required this.asamalar});

  @override
  Widget build(BuildContext context) {
    final firmaId = context.read<TenantProvider>().firmaId;

    return FutureBuilder<_AsamaIstatistik>(
      future: _dalIstatistigiGetir(asamalar, firmaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 58,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final istatistik = snapshot.data;
        if (snapshot.hasError || istatistik == null || istatistik.hataVar) {
          return const _KartUyari(label: 'Genel özet yüklenemedi');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final dar = constraints.maxWidth < 620;
            final kutular = [
              _KpiKutusu(
                icon: Icons.pending_actions,
                label: 'Bekleyen',
                value: istatistik.bekleyen,
                color: const Color(0xFF64748B),
              ),
              _KpiKutusu(
                icon: Icons.verified_outlined,
                label: 'Onaylanan',
                value: istatistik.onaylanan,
                color: const Color(0xFF7C3AED),
              ),
              _KpiKutusu(
                icon: Icons.play_circle_outline,
                label: 'İşlemde',
                value: istatistik.islemde,
                color: const Color(0xFF2563EB),
              ),
              _KpiKutusu(
                icon: Icons.check_circle_outline,
                label: 'Tamamlanan',
                value: istatistik.tamamlanan,
                color: const Color(0xFF16A34A),
              ),
              _KpiKutusu(
                icon: Icons.warning_amber_rounded,
                label: 'Geciken',
                value: istatistik.geciken,
                color: const Color(0xFFDC2626),
              ),
            ];

            if (dar) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kutu in kutular)
                    SizedBox(
                      width: (constraints.maxWidth - 8) / 2,
                      child: kutu,
                    ),
                ],
              );
            }

            return Row(
              children: [
                for (var i = 0; i < kutular.length; i++) ...[
                  Expanded(child: kutular[i]),
                  if (i != kutular.length - 1) const SizedBox(width: 8),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<_AsamaIstatistik> _dalIstatistigiGetir(
    List<AsamaTanim> asamalar,
    String? firmaId,
  ) async {
    final sonuclar = await Future.wait(
      asamalar.map(
        (asama) => _AsamaIstatistikServisi.asamaIstatistigiGetir(
          asama,
          firmaId,
        ),
      ),
    );

    if (sonuclar.any((istatistik) => istatistik.hataVar)) {
      return const _AsamaIstatistik(hataVar: true);
    }

    return _AsamaIstatistik.toplam(sonuclar);
  }
}

class _KpiKutusu extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _KpiKutusu({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
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
}

class _AsamaSeridi extends StatelessWidget {
  final List<AsamaTanim> asamalar;

  const _AsamaSeridi({required this.asamalar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: asamalar.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final asama = asamalar[index];
          return Container(
            constraints: const BoxConstraints(minWidth: 96, maxWidth: 164),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: asama.renk.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: asama.renk.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: asama.renk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    asama.asamaAdi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AsamaKarti extends StatelessWidget {
  final AsamaTanim asama;
  final int index;
  final int toplam;

  const _AsamaKarti({
    required this.asama,
    required this.index,
    required this.toplam,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final akisEtiketi =
        asama.eskiTabloAdi == null ? 'Genel akış' : 'Mevcut akış';

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _asamaDashboardAc(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: asama.renk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(asama.ikon, size: 22, color: asama.renk),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asama.asamaAdi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1}/$toplam',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Aç',
                    child: Icon(Icons.chevron_right, color: asama.renk),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AsamaSayaclari(
                asama: asama,
                onTabAc: (tabIndex) =>
                    _asamaDashboardAc(context, initialTabIndex: tabIndex),
              ),
              const Spacer(),
              Row(
                children: [
                  _DurumRozeti(
                    label: asama.zorunlu ? 'Zorunlu' : 'Opsiyonel',
                    color: asama.zorunlu
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DurumRozeti(
                      label: akisEtiketi,
                      color: asama.renk,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _asamaDashboardAc(BuildContext context, {int initialTabIndex = 0}) {
    if (asama.asamaKodu == 'utu' || asama.asamaKodu == 'paketleme') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UtuPaketDashboard()),
      );
      return;
    }

    if (asama.eskiTabloAdi != null && asama.eskiDurumKolonu != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UretimAsamaDashboard(
            asamaAdi: asama.asamaKodu,
            asamaDisplayName: asama.asamaAdi,
            atamaTablosu: asama.eskiTabloAdi!,
            modelDurumKolonu: asama.eskiDurumKolonu!,
            asamaRengi: asama.renk,
            asamaIconu: asama.ikon,
            initialTabIndex: initialTabIndex,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UretimAsamaDashboard(
          asamaAdi: asama.asamaKodu,
          asamaDisplayName: asama.asamaAdi,
          atamaTablosu: 'uretim_atamalari',
          modelDurumKolonu: '${asama.asamaKodu}_durumu',
          asamaRengi: asama.renk,
          asamaIconu: asama.ikon,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }
}

class _AsamaSayaclari extends StatelessWidget {
  final AsamaTanim asama;
  final ValueChanged<int> onTabAc;

  const _AsamaSayaclari({
    required this.asama,
    required this.onTabAc,
  });

  @override
  Widget build(BuildContext context) {
    final firmaId = context.read<TenantProvider>().firmaId;

    return FutureBuilder<_AsamaIstatistik>(
      future: _AsamaIstatistikServisi.asamaIstatistigiGetir(asama, firmaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 76,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final istatistik = snapshot.data;
        if (snapshot.hasError || istatistik == null || istatistik.hataVar) {
          return const _KartUyari(label: 'Sayaç yüklenemedi');
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SayacKutusu(
                    label: 'Bekleyen',
                    value: istatistik.bekleyen,
                    color: const Color(0xFF64748B),
                    onTap: () => onTabAc(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SayacKutusu(
                    label: 'İşlemde',
                    value: istatistik.islemde,
                    color: const Color(0xFF2563EB),
                    onTap: () => onTabAc(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SayacKutusu(
                    label: 'Onay',
                    value: istatistik.onaylanan,
                    color: const Color(0xFF7C3AED),
                    onTap: () => onTabAc(1),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SayacKutusu(
                    label: 'Tamam',
                    value: istatistik.tamamlanan,
                    color: const Color(0xFF16A34A),
                    onTap: () => onTabAc(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SayacKutusu(
                    label: 'Geciken',
                    value: istatistik.geciken,
                    color: const Color(0xFFDC2626),
                    onTap: () => onTabAc(3),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SayacKutusu extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;

  const _SayacKutusu({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsamaIstatistikServisi {
  const _AsamaIstatistikServisi._();

  static Future<_AsamaIstatistik> asamaIstatistigiGetir(
    AsamaTanim asama,
    String? firmaId,
  ) async {
    try {
      final rows = await _asamaSatirlariniGetir(asama, firmaId);
      return _AsamaIstatistik.fromRows(rows);
    } catch (e) {
      debugPrint('${asama.asamaAdi} istatistikleri yuklenemedi: $e');
      return const _AsamaIstatistik(hataVar: true);
    }
  }

  static Future<List<Map<String, dynamic>>> _asamaSatirlariniGetir(
    AsamaTanim asama,
    String? firmaId,
  ) async {
    final supabase = Supabase.instance.client;
    final tablo = asama.atamaTablosu;

    if (tablo == DbTables.uretimAtamalari) {
      final query = supabase
          .from(DbTables.uretimAtamalari)
          .select('durum, hedef_bitis, bitis_tarihi')
          .eq('uretim_dali', asama.tekstilDali)
          .eq('asama_kodu', asama.asamaKodu);
      final response =
          firmaId == null ? await query : await query.eq('firma_id', firmaId);
      return List<Map<String, dynamic>>.from(response);
    }

    try {
      final query = supabase.from(tablo).select('durum, model_id');
      final response =
          firmaId == null ? await query : await query.eq('firma_id', firmaId);
      final rows = List<Map<String, dynamic>>.from(response);
      await _trikoTerminleriniEkle(rows);
      return rows;
    } catch (_) {
      final response = await supabase.from(tablo).select('durum, model_id');
      final rows = List<Map<String, dynamic>>.from(response);
      await _trikoTerminleriniEkle(rows);
      return rows;
    }
  }

  static Future<void> _trikoTerminleriniEkle(
    List<Map<String, dynamic>> rows,
  ) async {
    final modelIds = rows
        .map((row) => row['model_id'])
        .where((id) => id != null)
        .toSet()
        .toList();

    if (modelIds.isEmpty) return;

    final response = await Supabase.instance.client
        .from(DbTables.trikoTakip)
        .select('id, termin_tarihi')
        .inFilter('id', modelIds);

    final modeller = {
      for (final model in List<Map<String, dynamic>>.from(response))
        model['id']: model,
    };

    for (final row in rows) {
      row[DbTables.trikoTakip] = modeller[row['model_id']];
    }
  }
}

class _KartUyari extends StatelessWidget {
  final String label;

  const _KartUyari({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC2410C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AsamaIstatistik {
  final int bekleyen;
  final int onaylanan;
  final int islemde;
  final int tamamlanan;
  final int geciken;
  final bool hataVar;

  const _AsamaIstatistik({
    this.bekleyen = 0,
    this.onaylanan = 0,
    this.islemde = 0,
    this.tamamlanan = 0,
    this.geciken = 0,
    this.hataVar = false,
  });

  int get toplamIs => bekleyen + onaylanan + islemde + tamamlanan;

  factory _AsamaIstatistik.fromRows(List<Map<String, dynamic>> rows) {
    var bekleyen = 0;
    var onaylanan = 0;
    var islemde = 0;
    var tamamlanan = 0;
    var geciken = 0;
    final bugun = DateTime.now();
    final bugunBaslangic = DateTime(bugun.year, bugun.month, bugun.day);

    for (final row in rows) {
      final durum = row['durum']?.toString();

      if (_bekleyenDurumlar.contains(durum)) {
        bekleyen++;
      } else if (_onaylananDurumlar.contains(durum)) {
        onaylanan++;
      } else if (_islemdeDurumlar.contains(durum)) {
        islemde++;
      } else if (_tamamlananDurumlar.contains(durum)) {
        tamamlanan++;
      }

      final termin = _terminTarihi(row);
      if (termin != null &&
          termin.isBefore(bugunBaslangic) &&
          !_tamamlananDurumlar.contains(durum)) {
        geciken++;
      }
    }

    return _AsamaIstatistik(
      bekleyen: bekleyen,
      onaylanan: onaylanan,
      islemde: islemde,
      tamamlanan: tamamlanan,
      geciken: geciken,
    );
  }

  static _AsamaIstatistik toplam(List<_AsamaIstatistik> istatistikler) {
    return _AsamaIstatistik(
      bekleyen: istatistikler.fold(0, (sum, item) => sum + item.bekleyen),
      onaylanan: istatistikler.fold(0, (sum, item) => sum + item.onaylanan),
      islemde: istatistikler.fold(0, (sum, item) => sum + item.islemde),
      tamamlanan: istatistikler.fold(0, (sum, item) => sum + item.tamamlanan),
      geciken: istatistikler.fold(0, (sum, item) => sum + item.geciken),
    );
  }

  static DateTime? _terminTarihi(Map<String, dynamic> row) {
    final model = row[DbTables.trikoTakip] as Map<String, dynamic>?;
    final value = row['hedef_bitis'] ??
        row['bitis_tarihi'] ??
        row['planlanan_bitis_tarihi'] ??
        model?['termin_tarihi'];
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static const _bekleyenDurumlar = {
    null,
    'bekleyen',
    'beklemede',
    'atandi',
    'firma_onay_bekliyor',
    'kontrol_bekliyor',
  };
  static const _onaylananDurumlar = {'onaylandi', 'kabul_edildi'};
  static const _islemdeDurumlar = {
    'uretimde',
    'devam_ediyor',
    'baslatildi',
    'basladi',
    'kismi_tamamlandi',
  };
  static const _tamamlananDurumlar = {'tamamlandi'};
}

class _GenelUretimAramaDelegate extends SearchDelegate<_UretimAramaSonucu?> {
  _GenelUretimAramaDelegate()
      : super(
          searchFieldLabel: 'Marka, model veya renk ara',
          keyboardType: TextInputType.text,
        );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Temizle',
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Geri',
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSonuclar(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSonuclar(context);

  Widget _buildSonuclar(BuildContext context) {
    final arama = query.trim();
    if (arama.length < 2) {
      return const _StateView(
        icon: Icons.search,
        title: 'Model ara',
        message: 'Arama yapmak için en az 2 karakter yazın.',
      );
    }

    final tenant = context.read<TenantProvider>();
    final aktifDallar = tenant.aktifUretimDallari;

    return FutureBuilder<List<_UretimAramaSonucu>>(
      future: _UretimAramaServisi.sonuclariGetir(
        arama: arama,
        aktifDallar: aktifDallar,
        firmaId: tenant.firmaId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _StateView(
            icon: Icons.error_outline,
            title: 'Arama yapılamadı',
            message: snapshot.error.toString(),
          );
        }

        final sonuclar = snapshot.data ?? const <_UretimAramaSonucu>[];
        if (sonuclar.isEmpty) {
          return const _StateView(
            icon: Icons.search_off,
            title: 'Sonuç yok',
            message: 'Bu arama için eşleşen üretim işi bulunamadı.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sonuclar.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final sonuc = sonuclar[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: sonuc.asama.renk.withValues(alpha: 0.12),
                child: Icon(sonuc.asama.ikon, color: sonuc.asama.renk),
              ),
              title: Text(
                '${sonuc.marka} - ${sonuc.modelKodu}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_dalEtiketi(sonuc.asama.tekstilDali)} / ${sonuc.asama.asamaAdi} • ${sonuc.renk} • ${sonuc.durumEtiketi}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                close(context, sonuc);
                _asamaPanelineGit(
                  context,
                  sonuc.asama,
                  initialTabIndex: sonuc.tabIndex,
                  initialSearchQuery: sonuc.modelKodu,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UretimAramaServisi {
  const _UretimAramaServisi._();

  static Future<List<_UretimAramaSonucu>> sonuclariGetir({
    required String arama,
    required List<String> aktifDallar,
    required String? firmaId,
  }) async {
    final asamalar = [
      for (final dal in aktifDallar) ...AsamaRegistry.dashboardAsamalari(dal),
    ];

    final tumSonuclar = await Future.wait(
      asamalar.map((asama) => _asamaSonuclariGetir(asama, firmaId)),
    );

    final aramaKucuk = arama.toLowerCase();
    final sonuclar = tumSonuclar
        .expand((liste) => liste)
        .where((sonuc) => sonuc.aramaMetni.contains(aramaKucuk))
        .toList()
      ..sort((a, b) => a.marka.compareTo(b.marka));

    return sonuclar.take(80).toList();
  }

  static Future<List<_UretimAramaSonucu>> _asamaSonuclariGetir(
    AsamaTanim asama,
    String? firmaId,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final tablo = asama.atamaTablosu;

      if (tablo == DbTables.uretimAtamalari) {
        final query = supabase
            .from(DbTables.uretimAtamalari)
            .select(
                'durum, asama_kodu, uretim_dali, modeller(id, marka, item_no, renk)')
            .eq('uretim_dali', asama.tekstilDali)
            .eq('asama_kodu', asama.asamaKodu);
        final response =
            firmaId == null ? await query : await query.eq('firma_id', firmaId);
        return _sonuclariMaple(asama, List<Map<String, dynamic>>.from(response),
            modelKey: DbTables.modeller);
      }

      final query = supabase.from(tablo).select('durum, model_id');
      final response =
          firmaId == null ? await query : await query.eq('firma_id', firmaId);
      final rows = List<Map<String, dynamic>>.from(response);
      await _trikoModelBilgileriniEkle(rows);
      return _sonuclariMaple(asama, rows, modelKey: DbTables.trikoTakip);
    } catch (e) {
      debugPrint('${asama.asamaAdi} arama sonuçları yüklenemedi: $e');
      return const <_UretimAramaSonucu>[];
    }
  }

  static Future<void> _trikoModelBilgileriniEkle(
    List<Map<String, dynamic>> rows,
  ) async {
    final modelIds = rows
        .map((row) => row['model_id'])
        .where((id) => id != null)
        .toSet()
        .toList();

    if (modelIds.isEmpty) return;

    final response = await Supabase.instance.client
        .from(DbTables.trikoTakip)
        .select('id, marka, item_no, renk')
        .inFilter('id', modelIds);

    final modeller = {
      for (final model in List<Map<String, dynamic>>.from(response))
        model['id']: model,
    };

    for (final row in rows) {
      row[DbTables.trikoTakip] = modeller[row['model_id']];
    }
  }

  static List<_UretimAramaSonucu> _sonuclariMaple(
    AsamaTanim asama,
    List<Map<String, dynamic>> rows, {
    required String modelKey,
  }) {
    return rows.map((row) {
      final model = row[modelKey] as Map<String, dynamic>? ?? const {};
      final durum = row['durum']?.toString();
      return _UretimAramaSonucu(
        asama: asama,
        marka: (model['marka'] ?? 'Bilinmeyen Marka').toString(),
        modelKodu: (model['item_no'] ?? model['id'] ?? '-').toString(),
        renk: (model['renk'] ?? '-').toString(),
        durum: durum,
      );
    }).toList();
  }
}

class _UretimAramaSonucu {
  final AsamaTanim asama;
  final String marka;
  final String modelKodu;
  final String renk;
  final String? durum;

  const _UretimAramaSonucu({
    required this.asama,
    required this.marka,
    required this.modelKodu,
    required this.renk,
    required this.durum,
  });

  String get aramaMetni => '$marka $modelKodu $renk'.toLowerCase();

  int get tabIndex {
    if (_AsamaIstatistik._bekleyenDurumlar.contains(durum)) return 0;
    if (_AsamaIstatistik._onaylananDurumlar.contains(durum)) return 1;
    if (_AsamaIstatistik._islemdeDurumlar.contains(durum)) return 2;
    return 3;
  }

  String get durumEtiketi {
    if (_AsamaIstatistik._bekleyenDurumlar.contains(durum)) return 'Bekleyen';
    if (_AsamaIstatistik._onaylananDurumlar.contains(durum)) return 'Onaylanan';
    if (_AsamaIstatistik._islemdeDurumlar.contains(durum)) return 'İşlemde';
    if (_AsamaIstatistik._tamamlananDurumlar.contains(durum)) {
      return 'Tamamlandı';
    }
    return durum ?? 'Durum yok';
  }
}

void _asamaPanelineGit(
  BuildContext context,
  AsamaTanim asama, {
  int initialTabIndex = 0,
  String? initialSearchQuery,
}) {
  if (asama.asamaKodu == 'utu' || asama.asamaKodu == 'paketleme') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UtuPaketDashboard()),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => UretimAsamaDashboard(
        asamaAdi: asama.asamaKodu,
        asamaDisplayName: asama.asamaAdi,
        atamaTablosu: asama.atamaTablosu,
        modelDurumKolonu: asama.eskiDurumKolonu ?? '${asama.asamaKodu}_durumu',
        asamaRengi: asama.renk,
        asamaIconu: asama.ikon,
        initialTabIndex: initialTabIndex,
        initialSearchQuery: initialSearchQuery,
      ),
    ),
  );
}

class _BilgiEtiketi extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BilgiEtiketi({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DurumRozeti extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const _DurumRozeti({
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _dalEtiketi(String dalKodu) {
  const etiketler = {
    'triko': 'Triko',
    'konfeksiyon': 'Konfeksiyon',
    'dokuma_kumas': 'Dokuma Kumaş',
    'orme_kumas': 'Örme Kumaş',
    'boya_terbiye': 'Boya & Terbiye',
    'baski_desen': 'Baskı & Desen',
    'iplik_uretim': 'İplik Üretim',
    'teknik_tekstil': 'Teknik Tekstil',
  };
  return etiketler[dalKodu] ?? dalKodu;
}

IconData _dalIkonu(String dalKodu) {
  const ikonlar = {
    'triko': Icons.checkroom,
    'konfeksiyon': Icons.content_cut,
    'dokuma_kumas': Icons.linear_scale,
    'orme_kumas': Icons.layers,
    'boya_terbiye': Icons.color_lens,
    'baski_desen': Icons.print,
    'iplik_uretim': Icons.category,
    'teknik_tekstil': Icons.precision_manufacturing,
  };
  return ikonlar[dalKodu] ?? Icons.factory_outlined;
}
