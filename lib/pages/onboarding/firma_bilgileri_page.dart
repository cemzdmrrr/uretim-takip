import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uretim_takip/services/firma_service.dart';
import 'package:uretim_takip/pages/onboarding/tekstil_dali_secim_page.dart';

/// Firma bilgilerini giren form sayfası. Onboarding adım 1/4.
class FirmaBilgileriPage extends StatefulWidget {
  const FirmaBilgileriPage({super.key});

  @override
  State<FirmaBilgileriPage> createState() => _FirmaBilgileriPageState();
}

class _FirmaBilgileriPageState extends State<FirmaBilgileriPage> {
  final _formKey = GlobalKey<FormState>();
  final _firmaAdi = TextEditingController();
  final _firmaKodu = TextEditingController();
  final _vergiNo = TextEditingController();
  final _vergiDairesi = TextEditingController();
  final _telefon = TextEditingController();
  final _email = TextEditingController();
  final _adres = TextEditingController();
  bool _kodMusait = true;
  bool _kodKontrolEdiliyor = false;

  @override
  void dispose() {
    _firmaAdi.dispose();
    _firmaKodu.dispose();
    _vergiNo.dispose();
    _vergiDairesi.dispose();
    _telefon.dispose();
    _email.dispose();
    _adres.dispose();
    super.dispose();
  }

  /// Firma adından otomatik slug üretir.
  String _slugOlustur(String ad) {
    const trMap = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
                   'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u'};
    var slug = ad.toLowerCase();
    trMap.forEach((k, v) => slug = slug.replaceAll(k, v));
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    return slug;
  }

  Future<void> _firmaKoduKontrol() async {
    final kod = _firmaKodu.text.trim();
    if (kod.isEmpty) return;
    setState(() => _kodKontrolEdiliyor = true);
    final musait = await FirmaService.firmaKoduMusait(kod);
    if (mounted) {
      setState(() {
        _kodMusait = musait;
        _kodKontrolEdiliyor = false;
      });
    }
  }

  void _devamEt() {
    if (!_formKey.currentState!.validate()) return;
    if (!_kodMusait) return;

    final bilgiler = <String, dynamic>{
      'vergi_no': _vergiNo.text.trim(),
      'vergi_dairesi': _vergiDairesi.text.trim(),
      'telefon': _telefon.text.trim(),
      'email': _email.text.trim(),
      'adres': _adres.text.trim(),
    };
    // Boş değerleri temizle
    bilgiler.removeWhere((_, v) => v == null || v.toString().isEmpty);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TekstilDaliSecimPage(
          firmaAdi: _firmaAdi.text.trim(),
          firmaKodu: _firmaKodu.text.trim(),
          firmaBilgileri: bilgiler,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firma Bilgileri')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _adimGostergesi(1),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firmaAdi,
                  decoration: const InputDecoration(
                    labelText: 'Firma Adı *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Firma adı zorunlu' : null,
                  onChanged: (v) {
                    if (_firmaKodu.text.isEmpty || _firmaKodu.text == _slugOlustur(_firmaAdi.text)) {
                      _firmaKodu.text = _slugOlustur(v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firmaKodu,
                  decoration: InputDecoration(
                    labelText: 'Firma Kodu (URL) *',
                    prefixIcon: const Icon(Icons.link),
                    helperText: 'Benzersiz firma tanımlayıcısı',
                    suffixIcon: _kodKontrolEdiliyor
                        ? const SizedBox(width: 20, height: 20, child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2)))
                        : Icon(
                            _kodMusait ? Icons.check_circle : Icons.cancel,
                            color: _kodMusait ? Colors.green : Colors.red,
                          ),
                    errorText: !_kodMusait ? 'Bu firma kodu zaten kullanımda' : null,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9\-]'))],
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Firma kodu zorunlu' : null,
                  onChanged: (_) => _firmaKoduKontrol(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _vergiNo,
                        decoration: const InputDecoration(
                          labelText: 'Vergi No',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _vergiDairesi,
                        decoration: const InputDecoration(
                          labelText: 'Vergi Dairesi',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefon,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adres,
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _devamEt,
                    child: const Text('Devam →', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _adimGostergesi(int adim) {
    return Row(
      children: List.generate(4, (i) {
        final aktif = i < adim;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: aktif ? Theme.of(context).primaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
