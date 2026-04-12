import 'package:flutter/material.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/pages/auth/register_page.dart';
import 'package:uretim_takip/services/abonelik_service.dart';

/// Plan karşılaştırma ve seçim sayfası.
class PlanSecimPage extends StatefulWidget {
  /// Mevcut abonelik (varsa plan değiştirme modunda çalışır).
  final FirmaAbonelik? mevcutAbonelik;

  /// true ise sadece bilgi amaçlı görüntülenir (giriş yapılmamışken).
  final bool sadeceBilgi;

  const PlanSecimPage({super.key, this.mevcutAbonelik, this.sadeceBilgi = false});

  @override
  State<PlanSecimPage> createState() => _PlanSecimPageState();
}

class _PlanSecimPageState extends State<PlanSecimPage> {
  List<AbonelikPlani> _planlar = [];
  bool _yukleniyor = true;
  bool _yillikFiyat = false;
  bool _islemYapiliyor = false;

  @override
  void initState() {
    super.initState();
    _planlariYukle();
  }

  Future<void> _planlariYukle() async {
    try {
      final planlar = await AbonelikService.planlariGetir();
      if (!mounted) return;
      setState(() {
        _planlar = planlar;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Planlar yüklenirken hata: $e')),
      );
    }
  }

  Future<void> _planSec(AbonelikPlani plan) async {
    if (plan.enterpriseMi) {
      _enterpriseIletisim();
      return;
    }

    // Giriş yapılmamışken kayıt sayfasına yönlendir
    if (widget.sadeceBilgi) {
      final kayitGit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hesap Oluşturun'),
          content: const Text(
            'Plan seçebilmek için önce hesap oluşturmanız gerekiyor.\n\n'
            'Kayıt olduktan sonra 14 gün ücretsiz deneme ile tüm modüllere erişebilirsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kayıt Ol'),
            ),
          ],
        ),
      );
      if (kayitGit == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterPage(
              secilenPlan: plan,
              yillik: _yillikFiyat,
            ),
          ),
        );
      }
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${plan.planAdi} Planı'),
        content: Text(
          widget.mevcutAbonelik != null
              ? '${plan.planAdi} planına geçmek istiyor musunuz?\n\n'
                  '${_yillikFiyat ? "Yıllık: ₺${plan.yillikUcret?.toStringAsFixed(0)}" : "Aylık: ₺${plan.aylikUcret.toStringAsFixed(0)}"}'
              : '${plan.planAdi} planını seçmek istiyor musunuz?\n\n'
                  '${_yillikFiyat ? "Yıllık: ₺${plan.yillikUcret?.toStringAsFixed(0)}" : "Aylık: ₺${plan.aylikUcret.toStringAsFixed(0)}"}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    setState(() => _islemYapiliyor = true);
    try {
      final periyot = _yillikFiyat ? 'yillik' : 'aylik';
      final abonelik = await AbonelikService.planDegistir(
        yeniPlanId: plan.id,
        odemePeriyodu: periyot,
      );

      // Deneme planı ise doğrudan aktifle
      if (plan.denemeMi) {
        await AbonelikService.abonelikAktifle(abonelik.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plan.planAdi} planı seçildi'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan seçilirken hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _islemYapiliyor = false);
    }
  }

  void _enterpriseIletisim() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enterprise Plan'),
        content: const Text(
          'Enterprise planı için lütfen bizimle iletişime geçin.\n\n'
          'İhtiyaçlarınıza özel fiyatlandırma ve çözüm sunuyoruz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Seçimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Aylık / Yıllık toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Aylık'),
              const SizedBox(width: 8),
              Switch(
                value: _yillikFiyat,
                onChanged: (v) => setState(() => _yillikFiyat = v),
                activeTrackColor: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('Yıllık'),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '~%17 İndirim',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Plan kartları
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _planlar.length,
            itemBuilder: (_, i) => _planKarti(_planlar[i]),
          ),
        ),
      ],
    );
  }

  Widget _planKarti(AbonelikPlani plan) {
    final mevcutPlan =
        widget.mevcutAbonelik?.plan?.planKodu == plan.planKodu;
    final fiyat = _yillikFiyat
        ? (plan.yillikUcret ?? plan.aylikUcret * 12)
        : plan.aylikUcret;
    final periyotLabel = _yillikFiyat ? '/yıl' : '/ay';

    Color kartRenk;
    switch (plan.planKodu) {
      case 'deneme':
        kartRenk = Colors.grey;
      case 'baslangic':
        kartRenk = Colors.blue;
      case 'profesyonel':
        kartRenk = Colors.indigo;
      case 'kurumsal':
        kartRenk = Colors.deepPurple;
      case 'enterprise':
        kartRenk = Colors.amber.shade800;
      default:
        kartRenk = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: mevcutPlan
            ? BorderSide(color: kartRenk, width: 2)
            : BorderSide.none,
      ),
      elevation: mevcutPlan ? 4 : 1,
      child: Column(
        children: [
          // Plan başlık bandı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: kartRenk,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.planAdi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (mevcutPlan)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Mevcut',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.aciklama != null)
                  Text(
                    plan.aciklama!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 12),
                // Fiyat
                plan.enterpriseMi
                    ? const Text(
                        'Özel Fiyatlandırma',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₺${fiyat.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: kartRenk,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              periyotLabel,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                // Özellikler
                _ozellikSatir(
                  Icons.people,
                  plan.maxKullanici != null
                      ? '${plan.maxKullanici} kullanıcı'
                      : 'Sınırsız kullanıcı',
                ),
                _ozellikSatir(
                  Icons.apps,
                  plan.maxModul != null
                      ? '${plan.maxModul} modül'
                      : 'Tüm modüller',
                ),
                _ozellikSatir(
                  Icons.support_agent,
                  _destekLabel(plan.ozellikler['destek']),
                ),
                if (plan.ozellikler['export'] == true)
                  _ozellikSatir(Icons.download, 'Veri dışa aktarım'),
                if (plan.ozellikler['api_erisim'] == true)
                  _ozellikSatir(Icons.api, 'API erişimi'),
                if (plan.ozellikler['ozel_gelistirme'] == true)
                  _ozellikSatir(Icons.code, 'Özel geliştirme'),
                const SizedBox(height: 16),
                // Dahil modüller
                if (plan.dahilModuller.isNotEmpty) ...[
                  Text(
                    'Dahil Modüller:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: plan.dahilModuller
                        .map((m) => Chip(
                              label: Text(
                                _modulAdi(m),
                                style: const TextStyle(fontSize: 11),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                // Seç butonu
                SizedBox(
                  width: double.infinity,
                  child: mevcutPlan
                      ? const OutlinedButton(
                          onPressed: null,
                          child: Text('Mevcut Planınız'),
                        )
                      : FilledButton(
                          onPressed:
                              _islemYapiliyor ? null : () => _planSec(plan),
                          style: FilledButton.styleFrom(
                            backgroundColor: kartRenk,
                          ),
                          child: _islemYapiliyor
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  plan.enterpriseMi
                                      ? 'İletişime Geç'
                                      : widget.sadeceBilgi
                                          ? (plan.denemeMi ? 'Ücretsiz Başla' : 'Kayıt Ol')
                                          : 'Bu Planı Seç',
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

  Widget _ozellikSatir(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _destekLabel(dynamic destek) {
    switch (destek) {
      case 'email':
        return 'E-posta desteği';
      case 'email_telefon':
        return 'E-posta + telefon desteği';
      case 'oncelikli':
        return 'Öncelikli destek';
      case 'ozel':
        return 'Özel destek yöneticisi';
      default:
        return 'Temel destek';
    }
  }

  String _modulAdi(String kod) {
    const adlar = {
      'uretim': 'Üretim',
      'finans': 'Finans',
      'ik': 'İK',
      'stok': 'Stok',
      'sevkiyat': 'Sevkiyat',
      'tedarik': 'Tedarik',
      'musteri': 'Müşteri',
      'rapor': 'Rapor',
      'kalite': 'Kalite',
      'ayarlar': 'Ayarlar',
    };
    return adlar[kod] ?? kod;
  }
}
