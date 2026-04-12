import 'package:flutter/material.dart';
import 'package:uretim_takip/pages/onboarding/firma_bilgileri_page.dart';
import 'package:uretim_takip/pages/onboarding/davet_katil_page.dart';

/// Firma oluştur veya davete katıl seçim ekranı.
class FirmaKayitPage extends StatelessWidget {
  const FirmaKayitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business, size: 72, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'TexPilot\'e Hoş Geldiniz',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Başlamak için yeni bir firma oluşturun veya mevcut bir firmaya katılın.',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FirmaBilgileriPage()),
                    ),
                    icon: const Icon(Icons.add_business),
                    label: const Text('Yeni Firma Oluştur', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DavetKatilPage()),
                    ),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Davet Kodu ile Katıl', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
