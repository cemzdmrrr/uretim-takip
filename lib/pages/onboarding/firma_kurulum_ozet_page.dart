import 'package:flutter/material.dart';
import 'package:uretim_takip/config/module_registry.dart';
import 'package:uretim_takip/services/firma_service.dart';
import 'package:uretim_takip/services/abonelik_service.dart';
import 'package:uretim_takip/pages/home/ana_sayfa.dart';

/// Firma kurulum özeti ve onay sayfası. Onboarding adım 4/4.
class FirmaKurulumOzetPage extends StatefulWidget {
  final String firmaAdi;
  final String firmaKodu;
  final Map<String, dynamic> firmaBilgileri;
  final List<String> secilenUretimDallari;
  final List<String> secilenModuller;

  const FirmaKurulumOzetPage({
    super.key,
    required this.firmaAdi,
    required this.firmaKodu,
    required this.firmaBilgileri,
    required this.secilenUretimDallari,
    required this.secilenModuller,
  });

  @override
  State<FirmaKurulumOzetPage> createState() => _FirmaKurulumOzetPageState();
}

class _FirmaKurulumOzetPageState extends State<FirmaKurulumOzetPage> {
  bool _yukleniyor = false;

  Future<void> _firmaOlustur() async {
    setState(() => _yukleniyor = true);
    try {
      final firmaId = await FirmaService.firmaOlustur(
        firmaAdi: widget.firmaAdi,
        firmaKodu: widget.firmaKodu,
        firmaBilgileri: widget.firmaBilgileri,
        secilenModuller: widget.secilenModuller,
        secilenUretimDallari: widget.secilenUretimDallari,
      );

      // Yeni firma için 14 günlük deneme aboneliği başlat
      await AbonelikService.denemeSuresiBaslat(firmaId);

      if (!mounted) return;
      // Onboarding tamamlandı — ana sayfaya git
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AnaSayfa()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firma oluşturulurken hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kurulum Özeti')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _adimGostergesi(4),
              const SizedBox(height: 24),
              const Text(
                'Her şey hazır!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Aşağıdaki bilgileri kontrol edin ve firmanızı oluşturun.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),

              // Firma bilgileri kartı
              _ozetKart(
                icon: Icons.business,
                baslik: 'Firma Bilgileri',
                icerik: [
                  _bilgiSatiri('Ad', widget.firmaAdi),
                  _bilgiSatiri('Kod', widget.firmaKodu),
                  if (widget.firmaBilgileri['vergi_no']?.toString().isNotEmpty == true)
                    _bilgiSatiri('Vergi No', widget.firmaBilgileri['vergi_no']),
                  if (widget.firmaBilgileri['telefon']?.toString().isNotEmpty == true)
                    _bilgiSatiri('Telefon', widget.firmaBilgileri['telefon']),
                ],
              ),
              const SizedBox(height: 12),

              // Üretim dalları kartı
              _ozetKart(
                icon: Icons.factory,
                baslik: 'Üretim Dalları',
                icerik: widget.secilenUretimDallari.map((kod) {
                  final dal = TekstilDali.fromKod(kod);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(dal?.ad ?? kod),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Modüller kartı
              _ozetKart(
                icon: Icons.extension,
                baslik: 'Aktif Modüller',
                icerik: widget.secilenModuller.map((kod) {
                  final modul = AppModule.fromKod(kod);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(modul?.ikon ?? Icons.check, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(modul?.ad ?? kod),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _yukleniyor ? null : _firmaOlustur,
                  icon: _yukleniyor
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch),
                  label: Text(
                    _yukleniyor ? 'Oluşturuluyor...' : 'Firmayı Oluştur',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ozetKart({required IconData icon, required String baslik, required List<Widget> icerik}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            ...icerik,
          ],
        ),
      ),
    );
  }

  Widget _bilgiSatiri(String etiket, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(etiket, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(deger, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
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
