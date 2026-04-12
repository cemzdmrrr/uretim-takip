import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class PaketlemeDashboard extends StatelessWidget {
  const PaketlemeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'paketleme',
      asamaDisplayName: 'Paketleme',
      atamaTablosu: DbTables.paketlemeAtamalari,
      modelDurumKolonu: 'paketleme_durumu',
      asamaRengi: Colors.brown,
      asamaIconu: Icons.inventory_2,
    );
  }
}
