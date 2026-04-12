import 'package:flutter/material.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/pages/onboarding/firma_kayit_page.dart';
import 'package:uretim_takip/services/abonelik_service.dart';
import 'package:intl/intl.dart';

/// Ödeme sayfası - Plan seçiminden sonra gösterilir
class OdemePage extends StatefulWidget {
  /// Seçilen plan
  final AbonelikPlani plan;
  
  /// Yıllık mı, yoksa aylık mı
  final bool yillik;

  const OdemePage({
    super.key,
    required this.plan,
    this.yillik = false,
  });

  @override
  State<OdemePage> createState() => _OdemePageState();
}

class _OdemePageState extends State<OdemePage> {
  late TextEditingController kartNumarasi;
  late TextEditingController skt;
  late TextEditingController cvv;
  late TextEditingController adSoyad;
  bool odemeYapiliyor = false;

  @override
  void initState() {
    super.initState();
    kartNumarasi = TextEditingController();
    skt = TextEditingController();
    cvv = TextEditingController();
    adSoyad = TextEditingController();
  }

  @override
  void dispose() {
    kartNumarasi.dispose();
    skt.dispose();
    cvv.dispose();
    adSoyad.dispose();
    super.dispose();
  }

  Future<void> _odemeYap() async {
    if (adSoyad.text.isEmpty ||
        kartNumarasi.text.isEmpty ||
        skt.text.isEmpty ||
        cvv.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurunuz')),
      );
      return;
    }

    setState(() => odemeYapiliyor = true);
    try {
      final periyot = widget.yillik ? 'yillik' : 'aylik';
      
      // Ödeme işlemini gerçekleştir
      await AbonelikService.planSatinAl(
        planId: widget.plan.id,
        odemePeriyodu: periyot,
        kartNumarasi: kartNumarasi.text,
        kartSCT: skt.text,
        kartCVV: cvv.text,
        kartAdSoyad: adSoyad.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme başarılı! Firma oluşturma adımına yönlendiriliyorsunuz...')),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirmaKayitPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme hatası: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => odemeYapiliyor = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fiyat = widget.yillik
        ? (widget.plan.yillikUcret ?? widget.plan.aylikUcret * 12)
        : widget.plan.aylikUcret;
    final periyotLabel = widget.yillik ? '/yıl' : '/ay';
    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan özeti
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan Özeti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.plan.planAdi),
                        Text(
                          '${currencyFormat.format(fiyat)}$periyotLabel',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Toplam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFormat.format(fiyat),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Ödeme formu
            const Text(
              'Kredi Kartı Bilgileri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Ad Soyad
            TextField(
              controller: adSoyad,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            // Kart Numarası
            TextField(
              controller: kartNumarasi,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Kart Numarası',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.credit_card),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            // SKT ve CVV
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: skt,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      labelText: 'Son Kullanma',
                      hintText: 'AA/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvv,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Güvenlik notu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ödeme bilgileriniz güvenli ve şifrelenmiş olarak işlenir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Ödeme Butonu
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: odemeYapiliyor ? null : _odemeYap,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: odemeYapiliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${currencyFormat.format(fiyat)} Ödemeyi Tamamla',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // İptal Butonu  
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: odemeYapiliyor ? null : () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
