import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uretim_takip/providers/tenant_provider.dart';
import 'package:uretim_takip/pages/home/ana_sayfa.dart';
import 'package:uretim_takip/pages/onboarding/firma_kayit_page.dart';

/// Birden fazla firmaya erişimi olan kullanıcılar için firma seçim ekranı.
class FirmaSecimPage extends StatelessWidget {
  const FirmaSecimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Seçimi'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<TenantProvider>(
        builder: (context, tenant, _) {
          final firmalar = tenant.kullaniciFirmalari;

          if (firmalar.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz bir firmaya bağlı değilsiniz.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FirmaKayitPage()),
                    ),
                    icon: const Icon(Icons.add_business),
                    label: const Text('Firma Oluştur veya Katıl'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Hangi firma ile devam etmek istiyorsunuz?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${firmalar.length} firmaya erişiminiz var.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.separated(
                        itemCount: firmalar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = firmalar[index];
                          final firma = item['firmalar'] as Map<String, dynamic>?;
                          if (firma == null) return const SizedBox.shrink();

                          final firmaAdi = firma['firma_adi'] ?? 'İsimsiz Firma';
                          final firmaKodu = firma['firma_kodu'] ?? '';
                          final rol = item['rol'] ?? '';

                          return Card(
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  firmaAdi.isNotEmpty
                                      ? firmaAdi[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              title: Text(
                                firmaAdi,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('$firmaKodu • $rol'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _firmaSecimi(context, firma['id']),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _firmaSecimi(BuildContext context, String firmaId) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<TenantProvider>().firmaSecimi(firmaId);
      if (context.mounted) {
        Navigator.of(context).pop(); // Loading kapat
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AnaSayfa()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Loading kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firma seçimi hatası: $e')),
        );
      }
    }
  }
}
