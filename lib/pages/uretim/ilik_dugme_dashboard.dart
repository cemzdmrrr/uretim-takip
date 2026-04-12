import 'package:flutter/material.dart';
import 'package:uretim_takip/config/database_tables.dart';
import 'package:uretim_takip/pages/uretim/uretim_asama_dashboard.dart';

class IlikDugmeDashboard extends StatelessWidget {
  const IlikDugmeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UretimAsamaDashboard(
      asamaAdi: 'ilik_dugme',
      asamaDisplayName: 'İlik Düğme',
      atamaTablosu: DbTables.ilikDugmeAtamalari,
      modelDurumKolonu: 'ilik_dugme_durumu',
      asamaRengi: Colors.indigo,
      asamaIconu: Icons.radio_button_checked,
    );
  }
}
