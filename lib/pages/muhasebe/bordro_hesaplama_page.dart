import 'package:flutter/material.dart';
import 'package:uretim_takip/services/puantaj_service.dart';

class BordroHesaplamaPage extends StatefulWidget {
  const BordroHesaplamaPage({super.key});

  @override
  State<BordroHesaplamaPage> createState() => _BordroHesaplamaPageState();
}

class _BordroHesaplamaPageState extends State<BordroHesaplamaPage> {
  final _formKey = GlobalKey<FormState>();
  double brutMaas = 0;
  double sgkIsci = 0;
  double issizlikIsci = 0;
  double gelirVergisi = 0;
  double damgaVergisi = 0;
  double netMaas = 0;
  int eksikGun = 0;
  int devamsizlik = 0;
  int fazlaMesai = 0;
  int calismaSaati = 0;
  String personelId = '';
  String ad = '';
  int ay = DateTime.now().month;
  int yil = DateTime.now().year;
  int gunlukCalismaSaati = 8;
  int toplamGun = 30;

  void hesapla() async {
    // Puantaj ve mesai/izin entegrasyonu
    final puantaj = await PuantajService().otomatikPuantajOlustur(
      personelId: personelId,
      ad: ad,
      ay: ay,
      yil: yil,
      gunlukCalismaSaati: gunlukCalismaSaati,
      toplamGun: toplamGun,
    );
    eksikGun = puantaj.eksikGun;
    devamsizlik = puantaj.devamsizlik;
    fazlaMesai = puantaj.fazlaMesai;
    calismaSaati = puantaj.calismaSaati;
    // Türkiye mevzuatına göre örnek hesaplama
    sgkIsci = brutMaas * 0.14;
    issizlikIsci = brutMaas * 0.01;
    final double vergiMatrah = brutMaas - sgkIsci - issizlikIsci;
    gelirVergisi = vergiMatrah * 0.15; // Basit örnek, dilimlere göre güncellenmeli
    damgaVergisi = brutMaas * 0.00759;
    // Fazla mesai ücreti eklenebilir (örnek: saatlik ücret * fazlaMesai * 1.5)
    final double saatlikUcret = brutMaas / (toplamGun * gunlukCalismaSaati);
    final double mesaiUcreti = saatlikUcret * fazlaMesai * 1.5;
    netMaas = brutMaas - sgkIsci - issizlikIsci - gelirVergisi - damgaVergisi + mesaiUcreti;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bordro Hesaplama'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Brüt Maaş (TL)'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setState(() {
                    brutMaas = double.tryParse(v) ?? 0;
                  });
                },
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Geçerli bir maaş girin' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() {
                      hesapla();
                    });
                  }
                },
                child: const Text('Hesapla'),
              ),
              const SizedBox(height: 24),
              if (netMaas > 0)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SGK İşçi Primi: ${sgkIsci.toStringAsFixed(2)} TL'),
                        Text('İşsizlik Sigortası (İşçi): ${issizlikIsci.toStringAsFixed(2)} TL'),
                        Text('Gelir Vergisi: ${gelirVergisi.toStringAsFixed(2)} TL'),
                        Text('Damga Vergisi: ${damgaVergisi.toStringAsFixed(2)} TL'),
                        Text('Fazla Mesai: $fazlaMesai saat'),
                        Text('Eksik Gün: $eksikGun'),
                        Text('Devamsızlık: $devamsizlik'),
                        Text('Çalışma Saati: $calismaSaati'),
                        const Divider(),
                        Text('Net Maaş: ${netMaas.toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
