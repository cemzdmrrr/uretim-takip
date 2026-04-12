import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class UtuDashboard extends StatelessWidget {
  const UtuDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'utu',
      asamaDisplayName: 'Ütü',
      atamaTablosu: DbTables.utuAtamalari,
      modelDurumKolonu: 'utu_durumu',
      asamaRengi: Colors.amber,
      asamaIconu: Icons.iron,
    );
  }
}
