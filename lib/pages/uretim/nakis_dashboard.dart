import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class NakisDashboard extends StatelessWidget {
  const NakisDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'nakis',
      asamaDisplayName: 'Nakış',
      atamaTablosu: DbTables.nakisAtamalari,
      modelDurumKolonu: 'nakis_durumu',
      asamaRengi: Colors.pink,
      asamaIconu: Icons.brush,
    );
  }
}
