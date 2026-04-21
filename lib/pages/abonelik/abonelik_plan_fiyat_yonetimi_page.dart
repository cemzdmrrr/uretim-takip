import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uretim_takip/models/abonelik_model.dart';
import 'package:uretim_takip/services/abonelik_service.dart';

class AbonelikPlanFiyatYonetimiPage extends StatefulWidget {
  const AbonelikPlanFiyatYonetimiPage({super.key});

  @override
  State<AbonelikPlanFiyatYonetimiPage> createState() =>
      _AbonelikPlanFiyatYonetimiPageState();
}

class _AbonelikPlanFiyatYonetimiPageState
    extends State<AbonelikPlanFiyatYonetimiPage> {
  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  List<_PlanFormu> _planlar = [];

  @override
  void initState() {
    super.initState();
    _planlariYukle();
  }

  @override
  void dispose() {
    for (final plan in _planlar) {
      plan.dispose();
    }
    super.dispose();
  }

  Future<void> _planlariYukle() async {
    setState(() => _yukleniyor = true);
    try {
      final planlar = await AbonelikService.planlariGetir(sadeceAktif: false);
      if (!mounted) return;
      setState(() {
        _planlar = planlar.map(_PlanFormu.new).toList();
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Planlar yuklenemedi: $e')),
      );
    }
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    try {
      for (final form in _planlar) {
        await AbonelikService.planFiyatGuncelle(
          planId: form.plan.id,
          aylikUcret: form.aylikUcret,
          yillikUcret: form.yillikUcret,
          aktif: form.aktif,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan fiyatlari guncellendi')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayit hatasi: $e')),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Fiyatlari'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _yukleniyor || _kaydediliyor ? null : _kaydet,
            icon: _kaydediliyor
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _planlar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _planKarti(_planlar[index]),
            ),
    );
  }

  Widget _planKarti(_PlanFormu form) {
    final deneme = form.plan.denemeMi;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.plan.planAdi,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        form.plan.planKodu,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: form.aktif,
                  onChanged:
                      deneme ? null : (v) => setState(() => form.aktif = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: form.aylik,
                    enabled: !deneme,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Aylik fiyat',
                      prefixText: 'TL ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: form.yillik,
                    enabled: !deneme,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Yillik fiyat',
                      prefixText: 'TL ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanFormu {
  final AbonelikPlani plan;
  final TextEditingController aylik;
  final TextEditingController yillik;
  bool aktif;

  _PlanFormu(this.plan)
      : aylik = TextEditingController(text: plan.aylikUcret.toStringAsFixed(0)),
        yillik = TextEditingController(
          text: plan.yillikUcret?.toStringAsFixed(0) ?? '',
        ),
        aktif = plan.aktif;

  double get aylikUcret => double.tryParse(aylik.text.trim()) ?? 0;
  double? get yillikUcret {
    final text = yillik.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void dispose() {
    aylik.dispose();
    yillik.dispose();
  }
}
