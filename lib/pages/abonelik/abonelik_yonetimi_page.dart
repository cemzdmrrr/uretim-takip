import 'package:flutter/material.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/services/abonelik_service.dart';
import 'package:uretim_takip/pages/abonelik/plan_secim_page.dart';

/// Mevcut abonelik durumu, ödeme geçmişi ve plan yönetimi sayfası.
class AbonelikYonetimiPage extends StatefulWidget {
  const AbonelikYonetimiPage({super.key});

  @override
  State<AbonelikYonetimiPage> createState() => _AbonelikYonetimiPageState();
}

class _AbonelikYonetimiPageState extends State<AbonelikYonetimiPage> {
  FirmaAbonelik? _abonelik;
  List<AbonelikOdeme> _odemeler = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final abonelik = await AbonelikService.aktifAbonelikGetir();
      final odemeler = await AbonelikService.odemeGecmisiGetir();
      if (!mounted) return;
      setState(() {
        _abonelik = abonelik;
        _odemeler = odemeler;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenirken hata: $e')),
      );
    }
  }

  Future<void> _planDegistir() async {
    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlanSecimPage(mevcutAbonelik: _abonelik),
      ),
    );
    if (sonuc == true) {
      _verileriYukle();
    }
  }

  Future<void> _abonelikIptalEt() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abonelik İptali'),
        content: const Text(
          'Aboneliğinizi iptal etmek istediğinizden emin misiniz?\n\n'
          'İptal sonrası mevcut dönem sonuna kadar erişiminiz devam eder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    try {
      await AbonelikService.abonelikIptal();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abonelik iptal edildi'),
          backgroundColor: Colors.orange,
        ),
      );
      _verileriYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İptal hatası: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonelik Yönetimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _verileriYukle,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _abonelikDurumKarti(),
                  const SizedBox(height: 16),
                  _aksiyonButonlari(),
                  const SizedBox(height: 24),
                  _odemeGecmisiBolumu(),
                ],
              ),
            ),
    );
  }

  Widget _abonelikDurumKarti() {
    if (_abonelik == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Aktif abonelik bulunamadı',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Lütfen bir plan seçin.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final plan = _abonelik!.plan;
    final durum = _abonelik!.durum;

    Color durumRenk;
    IconData durumIcon;
    switch (durum) {
      case AbonelikDurum.aktif:
        durumRenk = Colors.green;
        durumIcon = Icons.check_circle;
      case AbonelikDurum.deneme:
        durumRenk = Colors.orange;
        durumIcon = Icons.hourglass_bottom;
      case AbonelikDurum.odemeBekleniyor:
        durumRenk = Colors.blue;
        durumIcon = Icons.payment;
      case AbonelikDurum.iptal:
        durumRenk = Colors.red;
        durumIcon = Icons.cancel;
      case AbonelikDurum.pasif:
        durumRenk = Colors.grey;
        durumIcon = Icons.pause_circle;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: durumRenk.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Üst bant
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: durumRenk.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(durumIcon, color: durumRenk, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan?.planAdi ?? 'Bilinmeyen Plan',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: durumRenk.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          durum.etiket,
                          style: TextStyle(
                            color: durumRenk,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Detaylar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (durum == AbonelikDurum.deneme) ...[
                  _detaySatir(
                    'Deneme Süresi',
                    _abonelik!.kalanDenemeGunu > 0
                        ? '${_abonelik!.kalanDenemeGunu} gün kaldı'
                        : 'Süre doldu',
                    _abonelik!.kalanDenemeGunu > 3
                        ? Colors.green
                        : Colors.red,
                  ),
                  if (_abonelik!.denemeBitis != null)
                    _detaySatir(
                      'Bitiş Tarihi',
                      _tarihFormat(_abonelik!.denemeBitis!),
                      null,
                    ),
                ],
                if (durum == AbonelikDurum.aktif) ...[
                  _detaySatir(
                    'Ödeme Periyodu',
                    _abonelik!.odemePeriyodu == 'yillik'
                        ? 'Yıllık'
                        : 'Aylık',
                    null,
                  ),
                  if (_abonelik!.sonrakiOdemeTarihi != null)
                    _detaySatir(
                      'Sonraki Ödeme',
                      _tarihFormat(_abonelik!.sonrakiOdemeTarihi!),
                      null,
                    ),
                ],
                if (plan != null) ...[
                  _detaySatir(
                    'Kullanıcı Limiti',
                    plan.maxKullanici != null
                        ? '${plan.maxKullanici} kullanıcı'
                        : 'Sınırsız',
                    null,
                  ),
                  _detaySatir(
                    'Modül Limiti',
                    plan.maxModul != null
                        ? '${plan.maxModul} modül'
                        : 'Tüm modüller',
                    null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detaySatir(String label, String deger, Color? degerRenk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            deger,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: degerRenk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aksiyonButonlari() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _planDegistir,
            icon: const Icon(Icons.swap_horiz),
            label: Text(
              _abonelik == null ? 'Plan Seç' : 'Plan Değiştir',
            ),
          ),
        ),
        if (_abonelik != null &&
            (_abonelik!.durum == AbonelikDurum.aktif ||
                _abonelik!.durum == AbonelikDurum.deneme)) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _abonelikIptalEt,
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text('İptal', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _odemeGecmisiBolumu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ödeme Geçmişi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_odemeler.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Henüz ödeme kaydı yok',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          )
        else
          ..._odemeler.map(_odemeKarti),
      ],
    );
  }

  Widget _odemeKarti(AbonelikOdeme odeme) {
    final basarili = odeme.durum == 'basarili';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              basarili ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            basarili ? Icons.check : Icons.close,
            color: basarili ? Colors.green : Colors.red,
          ),
        ),
        title: Text('₺${odeme.tutar.toStringAsFixed(2)}'),
        subtitle: Text(
          odeme.odemeTarihi != null
              ? _tarihFormat(odeme.odemeTarihi!)
              : '-',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              odeme.odemeYontemi ?? '-',
              style: const TextStyle(fontSize: 12),
            ),
            if (odeme.faturaNo != null)
              Text(
                odeme.faturaNo!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _tarihFormat(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }
}
