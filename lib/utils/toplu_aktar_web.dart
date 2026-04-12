import 'package:flutter/material.dart';
import 'package:uretim_takip/widgets/common_widgets.dart';
import 'toplu_aktar_web_stub.dart' if (dart.library.js_interop) 'toplu_aktar_web_web.dart';

class TopluIcerAktarWebPage extends StatelessWidget {
  final Future<void> Function(List<Map<String, dynamic>> rows) onImport;

  const TopluIcerAktarWebPage({Key? key, required this.onImport}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplu İçe Aktar (Web)')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await pickExcelFile(onImport);
            } catch (e) {
              if (!context.mounted) return;
              context.showSnackBar('Hata: $e');
            }
          },
          child: const Text('Excel Dosyası Seç'),
        ),
      ),
    );
  }
}
