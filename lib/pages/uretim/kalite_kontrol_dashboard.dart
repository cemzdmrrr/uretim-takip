import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class KaliteKontrolDashboard extends StatelessWidget {
  const KaliteKontrolDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'kalite_kontrol',
      asamaDisplayName: 'Kalite Kontrol',
      atamaTablosu: DbTables.kaliteKontrolAtamalari,
      modelDurumKolonu: 'kalite_kontrol_durumu',
      asamaRengi: Colors.teal,
      asamaIconu: Icons.verified,
    );
  }
}
