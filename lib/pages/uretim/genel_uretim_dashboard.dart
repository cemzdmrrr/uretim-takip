import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/config/asama_registry.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';

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
                icon: Icon(_dalIkonu(dal), size: 18),
                text: _dalEtiketi(dal),
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
                  mainAxisExtent: width < 560 ? 132 : 142,
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
          _AsamaSeridi(asamalar: asamalar),
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

  void _asamaDashboardAc(BuildContext context) {
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
        ),
      ),
    );
  }
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
