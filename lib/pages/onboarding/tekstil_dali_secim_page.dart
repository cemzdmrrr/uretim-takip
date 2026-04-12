import 'package:flutter/material.dart';
import 'package:uretim_takip/config/module_registry.dart';
import 'package:uretim_takip/pages/onboarding/modul_secim_page.dart';

/// Tekstil üretim dalı/dalları seçim sayfası. Onboarding adım 2/4.
class TekstilDaliSecimPage extends StatefulWidget {
  final String firmaAdi;
  final String firmaKodu;
  final Map<String, dynamic> firmaBilgileri;

  const TekstilDaliSecimPage({
    super.key,
    required this.firmaAdi,
    required this.firmaKodu,
    required this.firmaBilgileri,
  });

  @override
  State<TekstilDaliSecimPage> createState() => _TekstilDaliSecimPageState();
}

class _TekstilDaliSecimPageState extends State<TekstilDaliSecimPage> {
  final Set<String> _secilenDallar = {};

  void _devamEt() {
    if (_secilenDallar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir üretim dalı seçmelisiniz')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModulSecimPage(
          firmaAdi: widget.firmaAdi,
          firmaKodu: widget.firmaKodu,
          firmaBilgileri: widget.firmaBilgileri,
          secilenUretimDallari: _secilenDallar.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üretim Dalı Seçimi')),
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
                    _adimGostergesi(2),
                    const SizedBox(height: 24),
                    const Text(
                      'Hangi tekstil üretim dallarında faaliyet gösteriyorsunuz?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Birden fazla dal seçebilirsiniz. Daha sonra değiştirilebilir.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: TekstilDali.values.length,
                  itemBuilder: (context, index) {
                    final dal = TekstilDali.values[index];
                    final secili = _secilenDallar.contains(dal.kod);
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
                        onTap: () => setState(() {
                          secili ? _secilenDallar.remove(dal.kod) : _secilenDallar.add(dal.kod);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Checkbox(
                                value: secili,
                                onChanged: (_) => setState(() {
                                  secili ? _secilenDallar.remove(dal.kod) : _secilenDallar.add(dal.kod);
                                }),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dal.ad, style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      dal.uretimAsamalari.join(' → '),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
