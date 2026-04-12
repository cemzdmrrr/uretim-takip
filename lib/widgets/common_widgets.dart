import 'package:flutter/material.dart';

/// Merkezi yükleme göstergesi widget'ı.
///
/// Kullanım: `LoadingWidget()` veya `LoadingWidget(mesaj: 'Yükleniyor...')`
class LoadingWidget extends StatelessWidget {
  final String? mesaj;

  const LoadingWidget({super.key, this.mesaj});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (mesaj != null) ...[
            const SizedBox(height: 16),
            Text(mesaj!, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

/// Boş durum göstergesi widget'ı.
///
/// Kullanım: `EmptyStateWidget(icon: Icons.inbox, mesaj: 'Veri bulunamadı')`
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String mesaj;
  final String? altMesaj;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.mesaj,
    this.altMesaj,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            mesaj,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          if (altMesaj != null) ...[
            const SizedBox(height: 6),
            Text(
              altMesaj!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

/// BuildContext extension for showing SnackBar messages.
///
/// Kullanım:
/// - `context.showSnackBar('Kaydedildi')`
/// - `context.showErrorSnackBar('Hata oluştu')`
/// - `context.showSuccessSnackBar('İşlem başarılı')`
extension SnackBarExtension on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
