import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class YikamaDashboard extends StatelessWidget {
  const YikamaDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'yikama',
      asamaDisplayName: 'Yıkama',
      atamaTablosu: DbTables.yikamaAtamalari,
      modelDurumKolonu: 'yikama_durumu',
      asamaRengi: Colors.cyan,
      asamaIconu: Icons.local_laundry_service,
    );
  }
}
