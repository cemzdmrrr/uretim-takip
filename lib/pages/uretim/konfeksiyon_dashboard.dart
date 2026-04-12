import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class KonfeksiyonDashboard extends StatelessWidget {
  const KonfeksiyonDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'konfeksiyon',
      asamaDisplayName: 'Konfeksiyon',
      atamaTablosu: DbTables.konfeksiyonAtamalari,
      modelDurumKolonu: 'konfeksiyon_durumu',
      asamaRengi: Colors.deepOrange,
      asamaIconu: Icons.content_cut,
    );
  }
}
