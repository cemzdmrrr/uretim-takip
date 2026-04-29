import 'package:flutter/material.dart';
import 'package:uretim_takip/pages/uretim/utu_paket_dashboard.dart';

/// Legacy route wrapper. The application has a single active ironing flow:
/// Ütü Paket.
class UtuDashboard extends StatelessWidget {
  const UtuDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const UtuPaketDashboard();
  }
}
