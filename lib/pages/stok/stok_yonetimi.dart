import 'package:flutter/material.dart';
import 'package:uretim_takip/pages/stok/iplik_stoklari.dart';
import 'package:uretim_takip/pages/stok/stok_yonetimi_aksesuarlar_coklu_beden.dart';
import 'package:uretim_takip/pages/stok/urun_depo_yonetimi.dart';

class StokYonetimiPage extends StatefulWidget {
  const StokYonetimiPage({super.key});

  @override
  State<StokYonetimiPage> createState() => _StokYonetimiPageState();
}

class _StokYonetimiPageState extends State<StokYonetimiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Yönetimi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              text: 'İplik Depo',
            ),
            Tab(
              text: 'Aksesuar Depo',
            ),
            Tab(
              text: 'Ürün Depo',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IplikStoklariPage(),
          StokYonetimiAksesuarlarCokluBeden(),
          UrunDepoYonetimiPage(),
        ],
      ),
    );
  }
}
