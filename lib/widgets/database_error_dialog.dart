import 'package:flutter/material.dart';

class DatabaseErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  const DatabaseErrorDialog({
    super.key,
    this.title = 'Veritabanı Hatası',
    required this.message,
    this.onRetry,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Olası Çözümler:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Supabase Dashboard\'dan gerekli tabloları oluşturun'),
          const Text('• comprehensive_database_schema.sql dosyasını çalıştırın'),
          const Text('• test_data.sql dosyasını çalıştırın'),
          const Text('• İnternet bağlantınızı kontrol edin'),
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Tekrar Dene'),
          ),
        TextButton(
          onPressed: onClose ?? () => Navigator.of(context).pop(),
          child: const Text('Tamam'),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    String? title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DatabaseErrorDialog(
        title: title ?? 'Veritabanı Hatası',
        message: message,
        onRetry: onRetry,
        onClose: onClose,
      ),
    );
  }
}

class DatabaseSetupHelper {
  static void showSetupInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veritabanı Kurulumu'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Supabase veritabanınızı kurmak için aşağıdaki adımları izleyin:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Supabase Dashboard\'a gidin (supabase.com)'),
              SizedBox(height: 8),
              Text('2. SQL Editor\'ü açın'),
              SizedBox(height: 8),
              Text('3. comprehensive_database_schema.sql dosyasının içeriğini kopyalayın'),
              SizedBox(height: 8),
              Text('4. SQL Editor\'de çalıştırın'),
              SizedBox(height: 8),
              Text('5. test_data.sql dosyasının içeriğini de çalıştırın'),
              SizedBox(height: 8),
              Text('6. Uygulamayı yeniden başlatın'),
              SizedBox(height: 16),
              Text(
                'Bu işlemler tüm gerekli tabloları ve test verilerini oluşturacaktır.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}
