import 'package:flutter/material.dart';
import 'package:uretim_takip/services/firma_service.dart';
import 'package:uretim_takip/pages/home/ana_sayfa.dart';

/// Davet kodu ile mevcut bir firmaya katılma sayfası.
class DavetKatilPage extends StatefulWidget {
  const DavetKatilPage({super.key});

  @override
  State<DavetKatilPage> createState() => _DavetKatilPageState();
}

class _DavetKatilPageState extends State<DavetKatilPage> {
  final _controller = TextEditingController();
  bool _yukleniyor = false;
  Map<String, dynamic>? _davetBilgi;
  String? _hata;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _davetKontrol() async {
    final kod = _controller.text.trim().toUpperCase();
    if (kod.isEmpty) return;

    setState(() {
      _yukleniyor = true;
      _hata = null;
      _davetBilgi = null;
    });

    try {
      final bilgi = await FirmaService.davetDogrula(kod);
      if (bilgi == null) {
        setState(() => _hata = 'Geçersiz veya süresi dolmuş davet kodu');
      } else {
        setState(() => _davetBilgi = bilgi);
      }
    } catch (e) {
      setState(() => _hata = 'Davet doğrulama hatası: $e');
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _katil() async {
    final kod = _controller.text.trim().toUpperCase();
    setState(() => _yukleniyor = true);

    try {
      await FirmaService.davetKabulEt(kod);
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AnaSayfa()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Katılım hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmaya Katıl')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Davet Kodu ile Katılın',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Firma yöneticinizden aldığınız davet kodunu girin.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Davet Kodu',
                    hintText: 'örn. ABC12345',
                    prefixIcon: const Icon(Icons.vpn_key),
                    errorText: _hata,
                    suffixIcon: _yukleniyor
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                  ),
                  onSubmitted: (_) => _davetKontrol(),
                ),
                const SizedBox(height: 16),

                if (_davetBilgi != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _davetBilgi!['firmalar']?['firma_adi'] ?? 'Firma',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Rol: ${_davetBilgi!['rol'] ?? 'kullanici'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _yukleniyor ? null : _katil,
                      child: Text(_yukleniyor ? 'Katılınıyor...' : 'Firmaya Katıl'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _yukleniyor ? null : _davetKontrol,
                      child: const Text('Kodu Doğrula'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
