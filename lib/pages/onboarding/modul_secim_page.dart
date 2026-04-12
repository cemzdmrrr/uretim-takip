import 'package:flutter/material.dart';
import 'package:uretim_takip/config/module_registry.dart';
import 'package:uretim_takip/pages/onboarding/firma_kurulum_ozet_page.dart';

/// Modül seçim sayfası. Onboarding adım 3/4.
class ModulSecimPage extends StatefulWidget {
  final String firmaAdi;
  final String firmaKodu;
  final Map<String, dynamic> firmaBilgileri;
  final List<String> secilenUretimDallari;

  const ModulSecimPage({
    super.key,
    required this.firmaAdi,
    required this.firmaKodu,
    required this.firmaBilgileri,
    required this.secilenUretimDallari,
  });

  @override
  State<ModulSecimPage> createState() => _ModulSecimPageState();
}

class _ModulSecimPageState extends State<ModulSecimPage> {
  // uretim ve ayarlar varsayılan olarak seçili
  final Set<String> _secilenModuller = {'uretim', 'ayarlar'};

  void _devamEt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FirmaKurulumOzetPage(
          firmaAdi: widget.firmaAdi,
          firmaKodu: widget.firmaKodu,
          firmaBilgileri: widget.firmaBilgileri,
          secilenUretimDallari: widget.secilenUretimDallari,
          secilenModuller: _secilenModuller.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modül Seçimi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _adimGostergesi(3),
                    const SizedBox(height: 24),
                    const Text(
                      'Hangi modülleri kullanmak istiyorsunuz?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Daha sonra istediğiniz zaman modül ekleyip çıkarabilirsiniz.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: AppModule.values.length,
                  itemBuilder: (context, index) {
                    final modul = AppModule.values[index];
                    final secili = _secilenModuller.contains(modul.kod);
                    final zorunlu = modul.kod == 'uretim' || modul.kod == 'ayarlar';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: secili
                            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: zorunlu
                            ? null
                            : () => setState(() {
                                secili
                                    ? _secilenModuller.remove(modul.kod)
                                    : _secilenModuller.add(modul.kod);
                              }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Checkbox(
                                value: secili,
                                onChanged: zorunlu
                                    ? null
                                    : (_) => setState(() {
                                        secili
                                            ? _secilenModuller.remove(modul.kod)
                                            : _secilenModuller.add(modul.kod);
                                      }),
                              ),
                              const SizedBox(width: 8),
                              Icon(modul.ikon, size: 28, color: secili
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(modul.ad, style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600)),
                                        if (zorunlu) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Zorunlu',
                                              style: TextStyle(fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      modul.kategori.ad,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _devamEt,
                    child: const Text('Devam →', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
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
