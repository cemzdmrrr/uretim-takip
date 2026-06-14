import 'package:flutter/material.dart';
import 'package:uretim_takip/pages/model/model_detay.dart';
import 'package:uretim_takip/pages/muhasebe/izin_page.dart';
import 'package:uretim_takip/pages/muhasebe/mesai_page.dart';
import 'package:uretim_takip/pages/muhasebe/odeme_page.dart';
import 'package:uretim_takip/pages/stok/stok_yonetimi.dart';
import 'package:uretim_takip/widgets/yapilacaklar_popup.dart';

class BildirimNavigationService {
  BildirimNavigationService._();

  static bool navigate(BuildContext context, Map<String, dynamic> bildirim) {
    final target = _targetFrom(bildirim);
    final type = target['type']?.toString();
    final page = target['page']?.toString();
    final tip = bildirim['tip']?.toString();

    final personelId = target['personel_id']?.toString();
    if ((type == 'izin' || page == 'izin' || tip == 'izin_talebi') &&
        _hasValue(personelId)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IzinPage(personelId: personelId)),
      );
      return true;
    }

    if ((type == 'mesai' || page == 'mesai' || tip == 'mesai_talebi') &&
        _hasValue(personelId)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MesaiPage(personelId: personelId)),
      );
      return true;
    }

    if ((type == 'avans' || page == 'odeme' || tip == 'avans_talebi') &&
        _hasValue(personelId)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OdemePage(personelId: personelId!)),
      );
      return true;
    }

    if (type == 'stok' || page == 'stok' || tip == 'stok_uyari') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StokYonetimiPage()),
      );
      return true;
    }

    if (type == 'yapilacak' ||
        page == 'yapilacak_popup' ||
        tip == 'yapilacak_hatirlatici') {
      YapilacaklarPopup.openPanel(context);
      return true;
    }

    final modelId =
        target['model_id']?.toString() ?? bildirim['model_id']?.toString();
    if (_hasValue(modelId)) {
      final initialTab = target['tab']?.toString() ??
          (tip == 'termin_uyari' ? 'model_durumu' : 'uretim');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ModelDetay(
            modelId: modelId!,
            initialTab: initialTab,
          ),
        ),
      );
      return true;
    }

    return false;
  }

  static Map<String, dynamic> _targetFrom(Map<String, dynamic> bildirim) {
    final ekBilgi = bildirim['ek_bilgi'];
    if (ekBilgi is Map) {
      final target = ekBilgi['target'];
      if (target is Map) return Map<String, dynamic>.from(target);
    }
    return const {};
  }

  static bool _hasValue(String? value) =>
      value != null && value.trim().isNotEmpty;
}
