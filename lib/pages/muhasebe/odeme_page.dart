import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/models/odeme_model.dart';
import 'package:uretim_takip/models/personel_model.dart';
import 'package:uretim_takip/services/izin_service.dart';
import 'package:uretim_takip/services/mesai_service.dart';
import 'package:uretim_takip/services/notification_service.dart';
import 'package:uretim_takip/services/odeme_service.dart';
import 'package:uretim_takip/services/personel_service.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'package:uretim_takip/widgets/donem_secici.dart';

part 'odeme_page_aksiyonlar.dart';

class OdemePage extends StatefulWidget {
  final String personelId;
  final String? initialDonem;
  final bool embedded;

  const OdemePage({
    super.key,
    required this.personelId,
    this.initialDonem,
    this.embedded = false,
  });

  @override
  State<OdemePage> createState() => _OdemePageState();
}

class _OdemePageState extends State<OdemePage> {
  List<OdemeModel> odemeler = [];
  bool yukleniyor = true;
  String? seciliDonem;

  Map<String, double> ozetBakiyeler = {
    'avans': 0,
    'prim': 0,
    DbTables.mesai: 0,
    'ikramiye': 0,
    'kesinti': 0,
  };

  String? filtreTur;
  String? filtreDurum;
  DateTime? filtreBaslangic;
  DateTime? filtreBitis;

  PersonelModel? personel;
  int? ucretsizIzinGun;

  String? currentUserRole;
  String? currentUserId;

  List<OdemeModel> get _filtreliOdemeler {
    return odemeler.where((o) {
      if (filtreTur != null && filtreTur!.isNotEmpty && o.tur != filtreTur) {
        return false;
      }
      if (filtreDurum != null &&
          filtreDurum!.isNotEmpty &&
          o.durum != filtreDurum) {
        return false;
      }
      if (filtreBaslangic != null && o.tarih.isBefore(filtreBaslangic!)) {
        return false;
      }
      if (filtreBitis != null && o.tarih.isAfter(filtreBitis!)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    seciliDonem = widget.initialDonem;
    debugPrint('OdemePage.initState: personelId=${widget.personelId}');
    _getPersonel();
    _getOdemeler();
    _getOzetBakiyeler();
    _getCurrentUserRole();
  }

  Future<void> _getCurrentUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    currentUserId = user.id;
    final response = await Supabase.instance.client
        .from(DbTables.userRoles)
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    if (!mounted) {
      return;
    }

    setState(() {
      currentUserRole = response?['role'] ?? 'user';
    });
  }

  Future<void> _getPersonel() async {
    final servis = PersonelService();
    personel = await servis.getPersonelById(widget.personelId);
    await _getEkBilgiler();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _getEkBilgiler() async {
    if (personel == null) {
      return;
    }
    final izinServis = IzinService();
    ucretsizIzinGun =
        await izinServis.getKullanilanUcretsizIzinGun(personel!.userId);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _getOdemeler() async {
    setState(() => yukleniyor = true);
    final servis = OdemeService();
    final liste = await servis.getOdemelerForPersonel(widget.personelId,
        donem: seciliDonem);
    if (!mounted) {
      return;
    }
    setState(() {
      odemeler = liste;
      yukleniyor = false;
    });
    _getOzetBakiyeler();
  }

  Future<void> _getOzetBakiyeler() async {
    final servis = OdemeService();
    final ozet =
        await servis.getOnayliBakiyeOzet(widget.personelId, donem: seciliDonem);
    if (!mounted) {
      return;
    }
    setState(() {
      ozetBakiyeler = ozet;
    });
  }

  void _donemDegisti(String? donem) {
    setState(() {
      seciliDonem = donem;
    });
    _getOdemeler();
    _getOzetBakiyeler();
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
                            _buildOdemeHeroSection(context, width),
                            const SizedBox(height: 20),
                            FutureBuilder<List<double>>(
                              future: Future.wait([
                                _getAylikToplamMesaiUcreti(),
                                _getKesintiTutari(),
                                _getAylikMesaiYemekUcreti(),
                                _getAylikYolUcreti(),
                              ]),
                              builder: (context, snapshot) {
                                final results =
                                    snapshot.data ?? const <double>[0, 0, 0, 0];
                                return _buildOdemeSummarySection(
                                  context,
                                  width,
                                  mesaiTutar: results[0],
                                  kesintiTutar: results[1],
                                  mesaiYemekUcreti: results[2],
                                  yolUcreti: results[3],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildOdemeFilterSection(context, width),
                            const SizedBox(height: 20),
                            _buildOdemeListSection(context, width),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );

    final fab = FloatingActionButton(
      onPressed: _yeniOdemeEkle,
      backgroundColor: const Color(0xFF2F6FED),
      tooltip: 'Yeni avans veya ödeme',
      child: const Icon(Icons.add),
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
        title: const Text('Avans ve Ödeme Yönetimi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: body,
      floatingActionButton: fab,
    );
  }
}

class MesaiOzetHesaplama extends StatelessWidget {
  final String personelId;
  final double saatlikMesaiUcreti;

  const MesaiOzetHesaplama({
    super.key,
    required this.personelId,
    required this.saatlikMesaiUcreti,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _getToplamMesaiSaati(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Container(
            height: 56,
            color: Colors.red.shade50,
            child: Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final toplamMesaiSaati = snapshot.data ?? 0;
        final toplamMesaiUcreti = toplamMesaiSaati * saatlikMesaiUcreti;
        return Container(
          height: 56,
          color: Colors.blue.shade50,
          child: Center(
            child: Text(
              'Mesai: ${toplamMesaiSaati.toStringAsFixed(2)} saat - ${toplamMesaiUcreti.toStringAsFixed(2)} TL',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<double> _getToplamMesaiSaati() async {
    return MesaiService().getAylikFazlaMesaiSaati(
      personelId,
      DateTime.now().year,
      DateTime.now().month,
    );
  }
}
