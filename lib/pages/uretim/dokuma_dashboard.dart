import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class DokumaDashboard extends StatelessWidget {
  const DokumaDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'dokuma',
      asamaDisplayName: 'Dokuma',
      atamaTablosu: DbTables.dokumaAtamalari,
      modelDurumKolonu: 'dokuma_durumu',
      asamaRengi: Colors.brown,
      asamaIconu: Icons.grain,
    );
  }
}
