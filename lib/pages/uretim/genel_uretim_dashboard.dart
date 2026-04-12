import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/config/asama_registry.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

/// Tekstil dalına göre dinamik üretim dashboard'u.
/// Firmanın aktif üretim dallarını okur ve her dal için
/// aşama kartları gösteren tab tabanlı bir layout sunar.
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

  Future<void> _asamalariYukle() async {
    try {
      await AsamaRegistry.yukle();
      if (mounted) setState(() => _yukleniyor = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
          _hata = 'Aşamalar yüklenemedi: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    final aktifDallar = tenant.aktifUretimDallari;

    if (_yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hata != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Üretim Dashboard')),
        body: Center(child: Text(_hata!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (aktifDallar.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Üretim Dashboard')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text('Aktif üretim dalı bulunamadı.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Firma ayarlarından üretim dalı ekleyiniz.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Tek dal aktifse direkt dashboard göster
    if (aktifDallar.length == 1) {
      return _UretimDaliDashboard(tekstilDali: aktifDallar.first);
    }

    // Birden fazla dal → tab'lı görünüm
    return DefaultTabController(
      length: aktifDallar.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Üretim Dashboard'),
          bottom: TabBar(
            isScrollable: aktifDallar.length > 4,
            tabs: aktifDallar.map((dal) {
              final asamalar = AsamaRegistry.asamalariGetir(dal);
              return Tab(
                text: _dalEtiketi(dal),
                icon: asamalar.isNotEmpty
                    ? Icon(asamalar.first.ikon, size: 18)
                    : null,
              );
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: aktifDallar
              .map((dal) => _UretimDaliDashboard(tekstilDali: dal))
              .toList(),
        ),
      ),
    );
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
}

/// Belirli bir tekstil dalı için üretim aşamalarını grid olarak gösterir.
/// Her aşama kartı tıklandığında UretimAsamaDashboard'a yönlendirir.
class _UretimDaliDashboard extends StatelessWidget {
  final String tekstilDali;

  const _UretimDaliDashboard({required this.tekstilDali});

  @override
  Widget build(BuildContext context) {
    final asamalar = AsamaRegistry.dashboardAsamalari(tekstilDali);

    if (asamalar.isEmpty) {
      return const Center(
        child: Text('Bu dal için aşama tanımı bulunamadı.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: asamalar.length,
        itemBuilder: (context, index) {
          final asama = asamalar[index];
          return _AsamaKarti(asama: asama);
        },
      ),
    );
  }
}

/// Tek bir üretim aşaması kartı
class _AsamaKarti extends StatelessWidget {
  final AsamaTanim asama;

  const _AsamaKarti({required this.asama});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _asamaDashboardAc(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [asama.renk.withValues(alpha: 0.1), asama.renk.withValues(alpha: 0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: asama.renk.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(asama.ikon, size: 24, color: asama.renk),
              ),
              const SizedBox(height: 8),
              Text(
                asama.asamaAdi,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: asama.renk,
                ),
              ),
              if (asama.zorunlu)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Zorunlu Aşama',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _asamaDashboardAc(BuildContext context) {
    // eski tablo varsa mevcut UretimAsamaDashboard'u kullan (geriye uyumluluk)
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
    } else {
      // Yeni dallar için genel atama tablosu ile dashboard
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
}
